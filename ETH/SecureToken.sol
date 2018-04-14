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
contract SecureToken{
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    
    uint256  private activeUsers;
    
    address[9] phonebook = [0x3dc9E794EeA03FA621f071554D1781AD790aab37,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0];
    
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public accountID;
    mapping (uint256 => address) public accountFromID;
    mapping (address => bool) public isRegistered;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferNeo(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Log(string t);
    event Log32(bytes32);
    event LogA(address);

    modifier registered {
        require(isRegistered[msg.sender]);
        _;
    }
    function SecureToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = 9*totalSupply/10;
        uint i;
        for(i=0;i<9;i++){
            balanceOf[phonebook[i]] = totalSupply/90;
        }
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
    function registerAccount(address user)internal{
        if(!isRegistered[user]){
            isRegistered[user] = true;
            activeUsers+=1;
            accountID[user] = activeUsers;
            accountFromID[activeUsers] = user;
        }
    }
    function registerAccountExternal()external{
        registerAccount(msg.sender);
    }
    function transfer(address to, uint256 val)public payable{
        _transfer(msg.sender,to,val);
    }
    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    function burn(uint256 val)public{
        burnFrom(msg.sender,val);
    }
}
