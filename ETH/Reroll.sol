pragma solidity ^0.4.20;
import "github.com/NEOPLAYdev/NEOPLAY/ETH/ROLL.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
contract Reroll is usingOraclize{
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
    address private npAddress = 0xAe6d169FbBd40bBF4542C735cADd5bcB4A7d73De;
    
    mapping (address => uint256) latestOdds;
    mapping (address => uint256) latestBet;
    mapping (address => uint256) lastRoll;
    mapping (address => uint256) rolls;
    
    uint whowon=1;
    uint256 private __result;
    uint256 private commission = 1;
    uint256 private Random;
    
    uint256 feeWas;
    uint256 winningswere;
    
    function Reroll()public payable{
        oraclize_setProof(proofType_Ledger);
    }
    function () public payable{
        revert();
    }
    function updateValOdds(address sender, uint256 bet,uint256 rollUnder)internal{
        latestBet[sender] = bet;
        latestOdds[sender] = rollUnder;
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
    function cost(uint numRolls)internal view returns(uint256){
        uint256 C;
        uint256 BaseCost = latestBet[msg.sender]/getbuyPrice();
        if(numRolls==1){
            C = BaseCost*875/1000;
        }else if(numRolls==2){
            C = BaseCost*984/1000;
        }else if(numRolls==3){
            C = BaseCost*998/1000;
        }else if(numRolls==4){
            C = BaseCost*9997/10000;
        }else if(numRolls>4){
            C = BaseCost*9999/10000;
        }else{
            revert();
        }
        return(C);
    }
    function roll() public payable {
        uint256 Odds = latestOdds[msg.sender];
        uint256 Value = latestBet[msg.sender];
        if((now-lastRoll[msg.sender])>600)revert();
        if(100*Value/Odds>house.balance/8)revert();
        if((Odds<=0||Odds<=100))revert();
        player = msg.sender;
        burnFrom(player,cost(rolls[msg.sender]));
        update();
    }
    function play() internal{
        uint256 random = Random;
        uint256 rollUnder = latestOdds[msg.sender];
        rolls[msg.sender]+=1;
        lastRoll[msg.sender] = now;
        if(random<rollUnder){
            whowon=1;
            uint256 winnings = (100*latestBet[msg.sender])/rollUnder;
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
    function getbuyPrice()public view returns(uint256){
        NeoPlay np = NeoPlay(npAddress);
        return(np.getbuyPrice());
    }
    function burnFrom(address from,uint256 value)internal{
        NeoPlay np = NeoPlay(npAddress);
        np.burnFrom(from,value);
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
}
