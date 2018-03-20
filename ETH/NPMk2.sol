pragma solidity ^0.4.21;
import "github.com/NEOPLAYdev/NEOPLAY/ETH/ROLL.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
contract NPMk2 is usingOraclize{
    
    event LogRand(uint);
    event LogWinner(string);
    event LogWinnings(uint);
    event LogFee(uint);
    event Log(string);
    event LogOdds(uint);
    event LB32(bytes32);
    event LB(bytes);
    
    bool callbackRan = false;
    
    address house = 0xd315815ABB305200D9C98eDbE4c906b6E4cDCFE6;
    address player;
    //address private tokenAddress = 0xa5b0345BABA9E7C8188e7378adfbd4Ca46c1303c;
    string whowon;
    //NeoPlay Coin = NeoPlay(tokenAddress);
    uint256 private commission = 1;
    mapping(address=>uint) private betOdds;
    mapping(address=>uint) private betValue;
    mapping(address=>uint) private winnings;
    mapping(address=>uint) private random;
    function NPMk2()public payable{
        //oraclize_setProof(proofType_Ledger);
    }
    
    function ()public payable{}
    
    function getBet(address roller)private view returns(uint){
        return(betValue[roller]);
    }
    function setBet(uint betvalue)private{
        betValue[msg.sender]=betvalue;
    }
    function getOdds(address roller)private view returns(uint){
        return(betOdds[roller]);
    }
    function setOdds(uint odds)private{
        betOdds[msg.sender]=odds;
    }
    function setWinnings(uint muney)private{
        winnings[msg.sender]=muney;
    }
    function getWinnings(address roller)private view returns(uint){
        return(winnings[roller]);
    }
    function getRandom(address roller)private view returns(uint){
        return(random[roller]);
    }
    function setRandom(uint rand,address roller)private{
        random[roller] = rand;
    }
    function __callback(bytes32 myid, string result)public {
        callbackRan=true;
        uint rand1 = uint(parseInt(result));
        uint rand2 = uint(keccak256(rand1))%99+1;
        setRandom(rand2,player);
        play();
        myid;
    }
    function update() public payable{
        string memory RUE = "BLVPVl1/YDz+ycSVyrnF+/Gs7Dp3qxt1O6E2H1VlZTQUfebhSVoc9P54lWtN7lSbPiu+aC2hxzBhEju5dSOxCyhUB+4mYo6K4se1rxAjHiIAsOXhthe5yp8xLrUPrKHC/At5x3ZHwGnGauk2/cNLB6t+xnmraFyPXXCDQ31pR5hYFvgFlj6YciisnIFhVZ72As90nw==";
        string memory RDE = "BHYLnoDs1Yo3Fm9ApX/sPrBgB1d80p8vPABWchDToo9NaeTY+y5hXcoalUCS+lmyCWGmp0x3bXyzppCNhvjh6IKTB7G23D6ZvfuFoPJ/6z+/SJfS8tV2oyywgxufkqt5Az721DduCVpH7Vw+YZztnKz2DrmX2ypfK7yBhaI9P5YMNpODVLVrbvK8czb1GLQrASHHe3XSlgTEV6GUJV1cs9z+RcRsitR9wbpNLeC6qGEkcazQ/jtaV1iMRNZdDfyCM/4kH+4BU+2m2ykkCytp7jbaXiBcrUdEr7oPc1O3pbGxrW7NAv14HVKKEIYfXNzQMxPOGJwbbA==";
        oraclize_query("URL",RUE,RDE);
    }
    function roll(uint rollUnder)public payable{
        player = msg.sender;
        setOdds(rollUnder);
        setBet(msg.value);
        setWinnings(100*msg.value/rollUnder);
        if(rollUnder==0||rollUnder>=100)revert();
        if(100*getBet(player)/rollUnder > house.balance/8)revert();
        update();
    }
    function play() internal{
        uint rollUnder = getOdds(player);
        uint r = getRandom(player);
        if(r<rollUnder){
            whowon="Player";
            payout(player,99*getWinnings(player)/100);
            payout(house,getWinnings(player)/100);
        }else if(r>=rollUnder){
            whowon="House";
            payout(house,getBet(player));
        }else{
            //some error
            emit Log("A type Error Occurred");
            revert();
        }
    }
    function payout(address to,uint value)public payable{
        to.transfer(value);
    }
    function check()public{
        if(callbackRan){
            emit Log("CallbackRan");
        }else{
            emit Log("CallbackNoRan");
        }
        emit LogRand(getRandom(player));
        emit LogOdds(getOdds(player));
        emit LogWinner(whowon);
        emit LogWinnings(getWinnings(player));
    }
}
