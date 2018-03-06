pragma solidity ^0.4.20;
import "github.com/NEOPLAYdev/NEOPLAY/ETH/Reroll.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
contract NPMk2 is Reroll{
    
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
    address private tokenAddress = 0x2071BE63B623B087C16c924a3464dAA9c349C25f;
    address private rerollAddress = 0xA3bB52b77dEf948DFc09F43a6F8499b3D718ECFA;
    
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
        oraclize_query("URL",RUE,RDE);
    }
    function roll(uint256 rollUnder)public payable{
        betOdds = rollUnder;
        betValue = msg.value;
        player = msg.sender;
        upValOdds(msg.sender,msg.value,rollUnder);
        if(rollUnder==0||rollUnder>=100)revert();
        if(100*betValue/betOdds>house.balance/8)revert();
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
    function upValOdds(address sender,uint256 value, uint256 rollUnder)internal{
        Reroll R = Reroll(rerollAddress);
        R.updateValOdds(sender,value,rollUnder);
    }
    function connect(string t)public{
        Reroll R = Reroll(rerollAddress);
        R.test(t);
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
