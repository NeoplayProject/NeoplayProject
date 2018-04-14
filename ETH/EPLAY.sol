pragma solidity ^0.4.21;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
import "github.com/Arachnid/solidity-stringutils/src/strings.sol";
interface NP {function buyFromEplay(address user,uint val)external payable;}
contract EP is owned, SecureToken, usingOraclize {
    using strings for *;
    uint256 public buyPrice;
    address private GameContract;
    address public NPLAY=owner;
    
    bool private isReady = false;
    
    address cb;
    bool callbackran=false;
//----------------------------------------------CONSTRUCTOR-----------------------------------------------//
    function EP(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )SecureToken(initialSupply, tokenName, tokenSymbol) public payable{
        //oraclize_setProof(proofType_TLSNotary);
        registerAccount(owner);
        uint i;
        for(i=0;i<9;i++){
            registerAccount(phonebook[i]);
        }
    }
//-------------------------------------------MODIFIERS-------------------------------------------------------//
    modifier isGame {
        require(msg.sender == GameContract);
        _;
    }
    modifier isAfterRelease{
        require(block.timestamp>1525550400);
        _;
    }
    modifier isNPLAY {
        require(msg.sender == NPLAY);
        _;
    }
//--------------------------------------ACCESSOR FUNCTIONS--------------------------------------------------//
    function getbuyPrice()public view returns(uint256){
        return(buyPrice);
    }
    function isOwner()public{
        if(msg.sender==owner)emit Log("Owner");
        else{
            emit Log("Not Owner");
        }
    }
    function getGC()external view returns(address){
        return(GameContract);
    }
    function getMultiplier()public view returns(uint256){
        uint256 multiplier;
        if(block.timestamp < 1525636800){
            multiplier = 150;
        }else if(block.timestamp < 1526155200){
            multiplier = 140;
        }else if(block.timestamp <1526760000){
            multiplier = 120;
        }else if(block.timestamp <1527364800){
            multiplier = 115;
        }else if(block.timestamp <1527969600){
            multiplier = 105;
        }else{
            multiplier=100;
        }
        return(multiplier);
    }
//----------------------------------------MUTATOR FUNCTIONS-------------------------------------------//
    function setPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    function setGC(address newAddy) onlyOwner public{
        GameContract = newAddy;
    }
    function toggleReady() onlyOwner public{
        isReady = !isReady;
    }
    function setNPLAY(address newAddy) onlyOwner public{
        NPLAY = newAddy;
        toggleReady();
    }
//----------------------------------------TRANSFER FUNCTIONS------------------------------------------//
    function buy()public payable{// isAfterRelease {
        require(owner.balance >0);
        uint multiplier = 100;
        if(isReady){
            NP NN = NP(NPLAY);
            NN.buyFromEplay(msg.sender,msg.value);
            multiplier = getMultiplier();
        }
        uint amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, multiplier*amount/100);
    }
    function buyFromNplay(address user,uint val)external payable {
        require(owner.balance>0);
        uint256 multiplier=100;
        if(isReady){
            multiplier = getMultiplier();
        }
        uint amount = val/buyPrice;
        _transfer(owner,user, multiplier*amount/100);
    }
//-----------------------------------------------OTHER FUNCTIONS---------------------------------------//
    function burnFromContract(address user,uint256 val)external isGame{
        burnFrom(user,val);
    }
}
