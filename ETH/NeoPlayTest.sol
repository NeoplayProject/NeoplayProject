pragma solidity ^0.4.11;

import "https://github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract NEOPLAYdice is usingOraclize {
    
    uint public HouseEdge = 1; //written in percentage
    uint public random;
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);

    function NEOPLAYdice() public{
        oraclize_setProof(proofType_Ledger); //sets the ledger authenticity proof in constructor
        update(); //asks for N random bytes on contract 
    }

    function __callback(bytes32 _queryId, string _result, bytes _proof) public{ 
        if (msg.sender != oraclize_cbAddress())revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            
            newRandomNumber_bytes(bytes(_result)); // this is  the resulting random number (bytes)
            
            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            uint randomNumber = uint(keccak256(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
            
            newRandomNumber_uint(randomNumber);
            random = randomNumber; // this is the resulting random number (uint)
        }
    }

    function update() public payable {
        uint N = 7;
        uint delay = 0;
        uint callbackGas = 200000;
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId

    }

}
contract getOdds is usingOraclize {
    uint public odds;
    
    event Log(string text);
    
    function update_odds() public{
        Log('Updating Odds');
        update();
    }
    function __callback(bytes32 _myid,string _result) public{
        require (msg.sender == oraclize_cbAddress());
        Log(_result);
        odds = parseInt(_result);
    }
    function update() public payable{
        Log('Oraclize Query was sent, awaiting your bet');
        oraclize_query("URL",'THIS IS WHERE THE URL SHOULD BE');
    }
    
}