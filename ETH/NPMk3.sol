pragma solidity ^0.4.20;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
interface NP {function contractBurn(address to,uint256 value)external;}
interface EP {function contractBurn(address to,uint256 value)external;}
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
contract NPMk3 is usingOraclize,owned{
//-----------------------------------------------------------OBJECTS-----------------------------------------------------------//
    struct action{
        address player;
        uint256 bet;
        uint256 odds;
        bool rerolled;
        uint256 random;
    }
//-----------------------------------------------------------EVENTS------------------------------------------------------------//
    event LogRand(uint);
    event LogWinner(string);
    event LogWinnings(uint);
    event LogFee(uint);
    event Log(string);
    event LogOdds(uint);
    event LB32(bytes32);
    event LB(bytes);
//---------------------------------------------------------VARIABLES-------------------------------------------------------//    
    address private house = 0xd315815ABB305200D9C98eDbE4c906b6E4cDCFE6;
    address private EPLAY;
    address private NPLAY;
    string private playKey;
    string private salt;
    string whowon;
    uint256 private commission = 1;
    string private randomStore = "essketit";
    mapping(address=>action) private rolls;
//---------------------------------------------------CONSTRUCTOR AND FALLBACK---------------------------------------------//
    function NPMk3()public payable{
        //oraclize_setProof(proofType_Ledger);
    }
    function ()public payable{}
//-------------------------------------------------------------ACCESSORS-------------------------------------------------------//
    function getBet(address roller)private view returns(uint){
        return(rolls[roller].bet);
    }
    function getOdds(address roller)private view returns(uint){
        return(rolls[roller].odds);
    }
    function getRandom(address roller)private view returns(uint){
        return(rolls[roller].random);
    }
    function getWinnings(address roller)private view returns(uint){
        return((100*rolls[roller].bet)/rolls[roller].odds);
    }
    function getEPLAY()public view returns(address){
        return(EPLAY);
    }
    function getNPLAY()public view returns(address){
        return(NPLAY);
    }
//-------------------------------------------------------------MUTATORS-----------------------------------------------------------//
    function newRoll(address roller,uint256 bet,uint256 odds,uint256 random)private {
        rolls[roller] = action(roller,bet,odds,false,random);

    }
    function setEPLAY(address tokenAddress)public onlyOwner{
        EPLAY = tokenAddress;}
    function setNPLAY(address tokenAddress)public onlyOwner{
        NPLAY = tokenAddress;
    }
    function setPlayKey(string newKey)public onlyOwner{
        playKey = newKey;
    }
    function setSalt(string newSalt)public onlyOwner{
        salt = newSalt;
    }
//-------------------------------------------------------------ORACLE--------------------------------------------------------------//
    function __callback(bytes32 myid, string result)public {
        if(msg.sender != oraclize_cbAddress())revert();
        randomStore = result;
        myid;
    }
    function update() public payable{
        string memory RUE = "BLVPVl1/YDz+ycSVyrnF+/Gs7Dp3qxt1O6E2H1VlZTQUfebhSVoc9P54lWtN7lSbPiu+aC2hxzBhEju5dSOxCyhUB+4mYo6K4se1rxAjHiIAsOXhthe5yp8xLrUPrKHC/At5x3ZHwGnGauk2/cNLB6t+xnmraFyPXXCDQ31pR5hYFvgFlj6YciisnIFhVZ72As90nw==";
        string memory RDE = "BHYLnoDs1Yo3Fm9ApX/sPrBgB1d80p8vPABWchDToo9NaeTY+y5hXcoalUCS+lmyCWGmp0x3bXyzppCNhvjh6IKTB7G23D6ZvfuFoPJ/6z+/SJfS8tV2oyywgxufkqt5Az721DduCVpH7Vw+YZztnKz2DrmX2ypfK7yBhaI9P5YMNpODVLVrbvK8czb1GLQrASHHe3XSlgTEV6GUJV1cs9z+RcRsitR9wbpNLeC6qGEkcazQ/jtaV1iMRNZdDfyCM/4kH+4BU+2m2ykkCytp7jbaXiBcrUdEr7oPc1O3pbGxrW7NAv14HVKKEIYfXNzQMxPOGJwbbA==";
        oraclize_query("URL",RUE,RDE,500000);
    }
//------------------------------------------------------------GAMING---------------------------------------------------//
    function roll(uint rollUnder)public payable{
        if(rollUnder==0||rollUnder>=100)revert();
        //if(100*getBet(msg.sender)/rollUnder > house.balance/8)revert();
        string memory salted = strConcat(salt,randomStore,salt);
        Log(salted);
        newRoll(msg.sender,msg.value,rollUnder,uint256(keccak256(salted))%99);
        update();
        play(playKey);
    }
    function rerollEPLAY() public payable{
        EP coin = EP(EPLAY);
        string memory salted = strConcat(salt,salt,randomStore,salt);
        action storage prevRoll = rolls[msg.sender];
        if(prevRoll.rerolled)revert();
        coin.contractBurn(msg.sender,1000);
        newRoll(msg.sender,prevRoll.bet,prevRoll.odds,uint256(keccak256(salted))%99);
        rolls[msg.sender].rerolled = true;
        update();
        play(playKey);
    }
    function rerollNPLAY() public payable{
        NP coin = NP(NPLAY);
        string memory salted = strConcat(salt,salt,randomStore,salt);
        action storage prevRoll = rolls[msg.sender];
        if(prevRoll.rerolled)revert();
        coin.contractBurn(msg.sender,1000);
        newRoll(msg.sender,prevRoll.bet,prevRoll.odds,uint256(keccak256(salted))%99);
        rolls[msg.sender].rerolled = true;
        update();
        play(playKey);
    }
    function play(string key) internal{
        if(keccak256(key)!=keccak256(playKey))revert();
        action storage current = rolls[msg.sender];
        if(current.random<current.odds){
            whowon="Player";
            payout(current.player,99*getWinnings(current.player)/100);
            payout(house,getWinnings(current.player)/100);
        }else if(current.random>=current.odds){
            whowon="House";
            payout(house,getBet(current.player));
        }else{
            revert();
        }
    }
    function payout(address to,uint value)public payable{
        to.transfer(value);
    }
//---------------------------------------------------------CHECKS-----------------------------------------------------//    
    function check(address player)public{
        LogRand(rolls[player].random);
        LogOdds(getOdds(player));
        LogWinner(whowon);
        LogWinnings(getWinnings(player));
    }
    function logRoll(address sender)public{
        LogOdds(rolls[sender].odds);
        LogRand(rolls[sender].random);
        LogWinnings(rolls[sender].bet);
    }
}
