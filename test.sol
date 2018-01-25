pragma solidity ^0.4.0;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract NEOPLAYdice is usingOraclize {

    event newRandomNumber_bytes(bytes);
    event newRandomNumber_unit(uint);

    function NEOPLAYdice() {
        oraclize_setProof(proofType_Ledger); //sets the ledger authenticity proof in constructor
        update(); //asks for N random bytes on contract 
    }

    function __callback(bytes32 _queryID, string _result, bytes _proof){

        if(msg.sender != oraclize_cbAddress()){ 
            throw; //if the sender of the current call isnt oraclize_cbAddress
        }

        if(oraclize_randomDNS_proofVerfiy__returnCode(_queryID, _result, _proof) != 0){
            //verification failed, returns money to wallet i suppose?
        }  else {
            newRandomNumber_bytes(bytes(__result));
            uint maxRange = 99;
            uint randomNumber = uint(sha3(__result)) % maxRange
            newRandomNumber_unit(randomNumber);

        }
    }

    function update() payable {
        uint N = 7;
        uint delay = 0;
        uint callbackGas = 200000
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId

    }

    /// Delegate your vote to the voter $(to).
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return;
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        if (to == msg.sender) return;
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted)
            proposals[delegateTo.vote].voteCount += sender.weight;
        else
            delegateTo.weight += sender.weight;
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
    }
}