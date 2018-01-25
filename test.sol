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

        if(oraclize_randomDS_proofVerify__returnCode(_queryID, _result, _proof) != 0){
            //verification failed, returns money to wallet i suppose?
        }  else {
            newRandomNumber_bytes(bytes(_result));
            uint maxRange = 99;
            uint randomNumber = uint(sha3(_result)) % maxRange;
            newRandomNumber_unit(randomNumber);

        }
    }

    function update() payable {
        uint N = 7;
        uint delay = 0;
        uint callbackGas = 200000;
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId

    }
}