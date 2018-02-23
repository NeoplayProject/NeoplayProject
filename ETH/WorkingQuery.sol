pragma solidity ^0.4.18;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract OQ is usingOraclize{
    event Log(string);
    event LogRandom(uint);
    event LogRand2(uint);
    uint randomInt;
    bool callbackRan;
    bytes32 recentQ;
    string recentR;
    uint recentRand1;
    function OQ() public payable{
        callbackRan = false;
    }
    function update() public payable{
        string memory RUE = "BNouQWfBk6t/2/tQDJ1a7BPnbIBuiAqBmC400dqipcJnV+3BLtktk6O0zQZg4YLLTfLPDpldT1OXNsNBgIBAMOlmIZclUEodeZlD/pO3Eer7fuLbPnZh8J4N5Cbg8GRsemrB8bNoqkal/uN5jBcDaOIpEy/r/krzHxQd4m+S+VHIk8nSfHsIZxO0cqTO5UkdhVDLww==";
        string memory RDE = "BOJPJZDfiNa2l/TLKkUuZ1c2Rvuqm9Jl+ZaX08mmSsC7yX9zOq6PrbA4qrZxDF++pH8EzfJkaiYdiofd8nhxPq7pnjik3Slcau6QipnIdpJDWuzDy8zvEyK+x38t0x6lRf7uELeFZV77r+aPFssYmVV1wKUdEhRBwQiSkp8oSo/Sy38u2YmvcNj7JqAB6KHmH8BK2CA/D6b+Yap+EGXjimrubZS6bgUrAv2yC9QF3ZQ2YJgDBQ62eVHAEY7v3+m/iDdTtgyVxM4KapKA7CWzgv74alQCKLL5JLo=";
        oraclize_query(60,"URL",RUE,RDE);
    }
    function __callback(bytes32 myid, string result)public {
        callbackRan=true;
        uint rand1 = parseInt(result);
        uint rand2 = uint(keccak256(rand1))%99;
        randomInt = rand2;
        recentRand1 = rand1;
        recentR=result;
        myid;
    }
    function check()public{
        if(callbackRan){
            Log("CallbackRan");
        }else{
            Log("CallbackNoRan");
        }
        Log(recentR);
        LogRand2(recentRand1);
        LogRandom(randomInt);
    }
}
