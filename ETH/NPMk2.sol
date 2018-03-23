pragma solidity ^0.4.18;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
interface NP {function burnFromContract(address tokenHolder,uint256 value)external;}
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract NPMk2 is usingOraclize,owned{
    
    event LogRand(uint);
    event LogWinner(string);
    event LogWinnings(uint);
    event LogFee(uint);
    event Log(string);
    event LogOdds(uint);
    event LB32(bytes32);
    event LB(bytes);
    
    bool callbackRan = false;
    
    address private house = 0xd315815ABB305200D9C98eDbE4c906b6E4cDCFE6;
    address private token = 0xE3761CEb14DF16E0cA7E7dA4a0687f4E9d9aDe3f;
    address private player;
    string whowon;
    uint RAND;
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
    function setToken(address tokenAddress)public onlyOwner{
        token = tokenAddress;
    }
    function getToken()public view returns(address){
        return(token);
    }
    function __callback(bytes32 myid, string result)public {
        if(msg.sender != oraclize_cbAddress()){revert();}
        callbackRan=true;
        uint rand1 = uint(parseInt(result));
        uint rand2 = uint(keccak256(rand1))%99+1;
        setRandom(rand2,player);
        RAND = rand2;
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
    function reroll() public payable{
        address tokenAddy = getToken();
        NP coin = NP(tokenAddy);
        coin.burnFromContract(msg.sender,1000);
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
        emit LogRand(RAND);
        emit LogOdds(getOdds(player));
        emit LogWinner(whowon);
        emit LogWinnings(getWinnings(player));
    }
}
