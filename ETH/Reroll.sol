pragma solidity ^0.4.11;

//import "github.com/oraclize/ethereum-api/blob/master/oraclizeAPi_0.5.sol";
import "browser/Oraclize.sol";
import "browser/NeoPlay.sol";
contract Reroll is usingOraclize{
    
    event Log(string text);
    event newRandom(uint num);
    event LogByte(bytes1 b);
    event LogBytes(bytes32 b);
    event onCallback(string result);

    address houseaddr;
    uint private randomInt;
    uint public HouseEdge;

    mapping(address => uint) private betVals;
    mapping(address => uint) private betOdds; 
    mapping(address => bool) private isSafe;
    modifier bnr_checked{
        if((msg.sender.balance > msg.value)&&(msg.value >= houseaddr.balance/8)){
            _;
        }
    }
    function Reroll() public bnr_checked{
        houseaddr = 0xC4d57523b537cA61dD3a872650eCA0827Dd04649;
        randomInt;
        HouseEdge=1;
    }
    function addData(address addr, uint256 betvals,uint256 betodds) public {
        betVals[addr]=betvals;
        betOdds[addr]=betodds;
        isSafe[addr]=true;
    }
    function play() public payable bnr_checked{
        address betAddr = msg.sender;
        uint betvals = betVals[msg.sender];
        //---------------------------------------------
       if(betvals >= houseaddr.balance/8){
           oraclize_setNetwork(networkID_consensys);
           update();
           rollit();
       }
        //----------------------------------------------
        isSafe[betAddr]=false;
    }
    function __callback(bytes32 myid, string result)public {
        onCallback(result);
        if (msg.sender != oraclize_cbAddress()) revert();
        randomInt = parseInt(result);
        newRandom(randomInt);
        myid;
    }
    function update()public {
        oraclize_query("URL", "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0", '\n{"jsonrpc":"2.0","method":"generateIntegers","params":{"apiKey":"45e90a83-8879-4727-a036-460be2a350aa","n":1,"min":0,"max":99,"replacement":true,"base":10},"id":1}');
    }
    function rollit() public payable{
        uint odds = betOdds[msg.sender];
        uint multiplier = 100/odds;
        if(isSafe[msg.sender]){
            if(randomInt > odds){
                //house wins
                houseaddr.transfer(msg.value);
            }else{
                //they win
                uint beforeTaxWinnings = msg.value*multiplier;
                uint fee = beforeTaxWinnings*HouseEdge/100;
                uint newval = beforeTaxWinnings-fee;
                msg.sender.transfer(newval);
                houseaddr.transfer(fee);
            }  
        }else{
            revert();
        }
    }
}
