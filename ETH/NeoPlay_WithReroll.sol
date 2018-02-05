pragma solidity ^0.4.11;
//import "github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol";
//import "github.com/NEOPLAYdev/NEOPLAY/tree/master/ETH/Reroll.sol";
import "browser/Oraclize.sol";
import "browser/Reroll.sol";
contract NEOPLAYdice is usingOraclize,Reroll{
    
    event Log(string text);
    event newRandom(uint num);
    event LogByte(bytes1 b);
    event LogBytes(bytes32 b);
    event onCallback(string result);
    
    address houseaddr = 0xC4d57523b537cA61dD3a872650eCA0827Dd04649;
    uint256 public randomInt;
    uint public HouseEdge=1;
    
    mapping(address => uint) betVals;
    mapping(address => uint) betOdds;
    
    modifier bnr_checked{
        if((msg.sender.balance > msg.value)&&(msg.value >= houseaddr.balance/8)){
            _;
        }
    }
    function NEOPLAYdice(uint odds) public payable bnr_checked{
        oraclize_setNetwork(networkID_consensys);
        update();
        play(odds);
        Reroll rerollAdd = new Reroll();
        rerollAdd.addData(msg.sender,msg.value,odds);


    }
    function () public payable{
        revert();
    }
    function play(uint rollUnder) public payable bnr_checked{
        uint odds = rollUnder;
        uint rand = randomInt;
        uint multiplier = 100/odds;        
        betVals[msg.sender] = msg.value;
        betOdds[msg.sender] = odds;
        if(odds<rand){
            houseaddr.transfer(msg.value);
            //Log('house wins');
        }else{
            uint beforeTaxWinnings = msg.value*multiplier;
            uint fee = beforeTaxWinnings*HouseEdge/100;
            uint newval = beforeTaxWinnings-fee;
            msg.sender.transfer(newval);
            houseaddr.transfer(fee);
            //Log('they win');
        }
    }
    function __callback(bytes32 myid, string result)public {
        onCallback(result);
        if (msg.sender != oraclize_cbAddress()) revert();
        randomInt = uint(keccak256(parseInt(result)))%99;
        newRandom(randomInt);
        myid;
    }
    function update()public {
        oraclize_query("URL", "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0", '\n{"jsonrpc":"2.0","method":"generateIntegers","params":{"apiKey":"45e90a83-8879-4727-a036-460be2a350aa","n":1,"min":0,"max":99,"replacement":true,"base":10},"id":1}');
    }
    
}
