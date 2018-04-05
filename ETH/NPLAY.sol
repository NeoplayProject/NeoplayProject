pragma solidity ^0.4.21;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
import "github.com/Arachnid/solidity-stringutils/src/strings.sol";

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
contract TokenERC20{
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferNeo(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Log(string t);
    event Log32(bytes32);
    event LogA(address);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
}
contract NP is owned, TokenERC20, usingOraclize {
    using strings for *;
    struct request {
        address from;
        address to;
        uint256 action;
        uint256 value;
    }
    uint256 public sellPrice;
    uint256 public buyPrice;
    address private GameContract;
    
    string private XBSQueryURL;
    
    address cb;
    
    uint256  private activeUsers;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    bool callbackran=false;

    function NP(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )TokenERC20(initialSupply, tokenName, tokenSymbol) public payable{
        //oraclize_setProof(proofType_TLSNotary);
        activeUsers=0;
    }
//-------------------------------------------MODIFIERS-------------------------------------------------------//
    modifier isGame {
        require(msg.sender == GameContract);
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
    function getsellPrice()external view returns(uint256){
        return(sellPrice);
    }
//----------------------------------------MUTATOR FUNCTIONS-------------------------------------------//
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner external {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function setGC(address newAddy) onlyOwner public{
        GameContract = newAddy;
    }
//----------------------------------------TRANSFER FUNCTIONS------------------------------------------//
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    function buy() payable external {
        uint amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, amount);
    }

    function sell(uint256 amount) external payable {
        require(owner.balance >= amount * sellPrice);
        _transfer(msg.sender, owner, amount);
    }
//-----------------------------------------------OTHER FUNCTIONS---------------------------------------//
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    function burn(uint256 val) external{
        burnFrom(msg.sender,val);
    }
    function burnFromContract(address user,uint256 val)external isGame{
        burnFrom(user,val);
    }
}
