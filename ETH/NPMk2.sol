
pragma solidity ^0.4.18;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
import "github.com/NEOPLAYdev/NEOPLAY/ETH/Reroll.sol";
import "github.com/NEOPLAYdev/NEOPLAY/ETH/ROLL.sol";
contract NPMk2 is usingOraclize {
    
    event LogRand(uint256);
    event LogWinner(uint256);
    event LogWinnings(uint256);
    event LogFee(uint256);
    event Log(string);
    event LB32(bytes32);
    event LB(bytes);
    
    bool callbackRan = false;
    
    address house = 0xd315815ABB305200D9C98eDbE4c906b6E4cDCFE6;
    address private player;
    
    uint whowon=1;
    uint256 private __result;
    uint256 private commission = 1;
    uint256 private betOdds;
    uint256 private betValue;
    uint256 private Random;
    
    uint256 feeWas;
    uint256 winningswere;
    
    function NPMk2()public payable{
        oraclize_setProof(proofType_Ledger);
    }
    function __callback(bytes32 myid, string result)public {
        callbackRan=true;
        uint256 rand1 = parseInt(result);
        uint256 rand2 = uint(keccak256(rand1))%99;
        __result = rand2;
        Random = rand2;
        play();
        myid;
    }
    function update() public payable{
        string memory RUE = "BJDHZ4vte2wenn5EcLFaR6VOzyaxAUflNGNYx0noHhQZ/JLd2Nx1lsUbLTtRhkWCuAmHC+GU0VVKNCxDKnrdOrTIpdSHx1dsCRMud2jQ7Kkq9wV/aTi+NrU5kF5A3PVSAB8Ps63IEPovWvUCLwnBnvDXY85IRKaKgpD2nNhqyVFeBayY+IR6k/WPwV80lzYR12OknA==";
        string memory RDE = "BIGIhanJ4kMt41bjFy1zmEMwXrTYuQMP0jAE81fhK81lU9QfeTApU1XcxrFF9cgX50d8HpA8TkyupNJ/A5lNHiqK6vNcndQVNjI5gGowMaF4stsu07EP0qcpbqj3VJTEjK72APvh/yO26dZ/vNyzMnnVtwpRPohxDv+PErnm9lInlg1PCxCMZZ/L5UqzoRRVqO7G1OklZ4z40ugaO8b+rPD+ZS9bC3rbieEbr//+S2ehflVVQNorIuRZlgCEWpHucIXLOmsDPmOrrYhWufUx7YvbrYU4D1OblESnhI+4cPM29zCUgTfl9QnbJyCWeatDGAzF3aNM";
        //string memory RU = "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0";
        //string memory RD = '\n{"jsonrpc":"2.0","method":"generateIntegers","params":{"apiKey":"45e90a83-8879-4727-a036-460be2a350aa","n":1,"min":0,"max":99},"id":42}';
        oraclize_query(10,"URL",RUE,RDE);
        //oraclize_query(60,"URL",RU,RD);
    }
    function roll(uint256 rollUnder)public payable{
        betOdds = rollUnder;
        betValue = msg.value;
        player = msg.sender;
        if(rollUnder==0||rollUnder>=100)revert();
        if(100*Value/Odds>house.balance/8)revert();
        update();
    }
    function play() internal{
        uint256 random = Random;
        uint256 rollUnder = betOdds;
        if(random<rollUnder){
            whowon=1;
            uint256 winnings = (100*betValue)/rollUnder;
            uint256 fee = commission*(winnings/100);
            feeWas=fee;
            winningswere=winnings;
            payout(player,winnings-fee);
            payout(house,fee);
        }else if(random>=rollUnder){
            whowon=0;
            payout(house,msg.value);
        }else{
            //some error
            Log("A type Error Occurred");
            revert();
        }
    }
    function payout(address to,uint256 value)public payable{
        to.transfer(value);
    }
    function check()public{
        if(callbackRan){
            Log("CallbackRan");
        }else{
            Log("CallbackNoRan");
        }
        LogRand(__result);
        LogWinner(whowon);
        LogFee(feeWas);
        LogWinnings(winningswere);
    }
    function ()public payable{
        house.transfer(msg.value);
    }
}
