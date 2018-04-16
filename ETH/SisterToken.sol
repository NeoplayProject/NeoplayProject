pragma solidity ^0.4.21;
contract owned {
    address public owner;
    event Log(string s);

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
    function isOwner()public{
        if(msg.sender==owner)emit Log("Owner");
        else{
            emit Log("Not Owner");
        }
    }
}
contract SisterToken is owned{
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    uint256 public buyPrice;
    
    uint256 private activeUsers;
    
    address[9] phonebook = [0x3dc9E794EeA03FA621f071554D1781AD790aab37,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0];
    address public sister;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public accountID;
    mapping (uint256 => address) public accountFromID;
    mapping (address => bool) public isRegistered;
    mapping (address => bool) public isTrusted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferNeo(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Log(string t);
    event Log32(bytes32);
    event LogA(address);
    event Multiplier(uint m);
    event isSender(address user,bool confirm);
    event isTrusted(address user,bool confirm);
    event Value(uint v);

    modifier registered {
        require(isRegistered[msg.sender]);
        _;
    }
    modifier trusted {
        require(isTrusted[msg.sender]);
        _;
    }
    modifier isAfterRelease{
        require(block.timestamp>1525550400);
        _;
    }
    function SisterToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public payable{
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[owner] = 9*totalSupply/10;
        uint i;
        for(i=0;i<9;i++){
            balanceOf[phonebook[i]] = totalSupply/90;
            registerAccount(phonebook[i]);
        }
        name = tokenName;
        symbol = tokenSymbol;
    }
//----------------------------------------------------------------------ACCESSOR FUNCTIONS------------------------------------------------------------------------------//
    function getbuyPrice()public view returns(uint256){
        return(buyPrice);
    }
    function getMultiplier()public view returns(uint256){
        uint256 multiplier;
        if(block.timestamp>1525550400){
            if(block.timestamp < 1525636800){
                multiplier = 150;
            }else if(block.timestamp < 1526155200){
                multiplier = 140;
            }else if(block.timestamp <1526760000){
                multiplier = 125;
            }else if(block.timestamp <1527364800){
                multiplier = 115;
            }else if(block.timestamp <1527969600){
                multiplier = 105;
            }
        }else{
            multiplier=100;
        }
        return(multiplier);
    }
//---------------------------------------------------------------------MUTATOR FUNCTIONS---------------------------------------------------------------------------//
    function trustContract(address contract1)public onlyOwner{
        isTrusted[contract1]=true;
    }
    function untrustContract(address contract1)public onlyOwner{
        isTrusted[contract1]=false;
    }
    function setPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    function setSister(address sibling)public onlyOwner{
        sister = sibling;
        trustContract(sibling);
        emit LogA(sibling);
    }
//-------------------------------------------------------------------INTERNAL FUNCTIONS--------------------------------------------------------------------------//
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
    function registerAccount(address user)internal{
        if(!isRegistered[user]){
            isRegistered[user] = true;
            activeUsers+=1;
            accountID[user] = activeUsers;
            accountFromID[activeUsers] = user;
        }
    }
    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    function trasnferFromOwner(address to,uint value)internal {
        _transfer(owner,to,value);
    }
    function givetoOwner()public payable{
        owner.transfer(msg.value);
    }
    function _buy(address user)external payable trusted isAfterRelease{
        require(owner.balance > 0);
        emit isTrusted(user,isTrusted[msg.sender]||msg.sender==user);
        uint256 amount = (getMultiplier()*2*msg.value/buyPrice)/100;
        emit Value(amount);
        trasnferFromOwner(user,amount);
        owner.transfer(msg.value);
    }
//------------------------------------------------------------------EXTERNAL FUNCTIONS-------------------------------------------------------------------------//
    function registerExternal()external{
        registerAccount(msg.sender);
    }
    function contractBurn(address _for,uint256 value)external trusted{
        burnFrom(_for,value);
    }
//----------------------------------------------------------------PUBLIC USER FUNCTIONS-----------------------------------------------------------------------//
    function transfer(address to, uint256 val)public payable{
        _transfer(msg.sender,to,val);
    }
    function burn(uint256 val)public{
        burnFrom(msg.sender,val);
    }
    function register() public {
        registerAccount(msg.sender);
    }
    function testConnection() external {
        emit Log(name);
    }
}
