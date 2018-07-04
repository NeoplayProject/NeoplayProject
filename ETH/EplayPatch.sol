pragma solidity ^0.4.22;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract owned {
    address public owner;
    
    event Log(string s);
    
    constructor() public payable{
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
contract ERC20 is ERC20Interface,owned{

    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint8 public constant decimals = 4;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor(uint256 _totalSupply,string tokenName,string tokenSymbol) public {
        symbol = tokenSymbol;
        name = tokenName;
        totalSupply = _totalSupply;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function totalSupply() public view returns (uint){
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender ]- tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - (tokens);
        balances[to] = balances[to]+(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract EPLAY is ERC20 {
    
    address[64] playbook = [
        0xab90cb176709558ba5d2dda8aeb1f65e24f2409f,
        0xa450877812d120315f343aec62b5cf1ad39e8468,
        0xf14228fbd920145d9f4d4d5e38760d9410e99775,
        0xcccc551e9701c2a5d07a3062a604972fa12226e8,
        0xaf9cd61b3b5c4c07376141ef8f718bb0893ab371,
        0x80f395fd4e1dde020d774fab983b8a9d0dcca516,
        0xceb646336bba29a9e8106a44065561d495166230,
        0x97d1352b2a2e0175471ca730cb6510d0164bfb0b,
        0x5a53d72e763b2d3e2f2f347ed774aaae872861a4,
        0x8ccc39c1516ef25ac0e6bc1a6bb7cf159d28fd71,
        0x2c0cac04a9ffee0d496e45023c907b71049ed0f0,
        0xdce66f4a697a88d00fbb3fddc6d44fd757852394,
        0x208379d7ac59eb79553bce816d1f8639d9bacdd8,
        0x7f3d32c56b94a9b7878fdfac4f40aaa2a6e11edf,
        0x4ddbd2f3887ad296b5b7c2ddcaebeaff7fa09453,
        0xc6e773a432e24aa71c608ff7f6caafef6196794e,
        0x43ab31857192b338b677551b34759a7ba190d551,
        0x90a64ed7b118631520ac1d71f348ff213ca51817,
        0x16b45750f0e7d4beae4b2e9ead87f683815ac3c7,
        0xfae8c1c08360a9b4465ec3244c6a04881b422ed5,
        0x6f7c2459af51b4cee22a66192a3892beba9624ce,
        0xe9b35ff25e182a3b38e1a2395ea4194824c290d8,
        0x01d95406787463b7c6e8091bfe6324556acf1ad8,
        0x8c3194da5aa896e59013f432b41e3714b23ca848,
        0x02082526872ac686196ba39bbe3c816bf370ba94,
        0xca9d1c84b8c8de6373d061004d36ad36f14e49c7,
        0x5e0c70268cbeb964d7f1cc137b93c9707da4c587,
        0x9e40ae22fb186c0e67162f63b81fb1cef16e0bcf,
        0xcfdd51faf1f5e17601500692488ab8336b13c55e,
        0x7c2556d8442fbe4d0fda60cf022898aa4c2854af,
        0x71444ab65dd17271b2dd962f56f8aa0f16b3998a,
        0xce3c502055bf1c88ed987d68e15012c98c7ac757,
        0x88b0979cf646a2930d2d159828c2d124405e4e2d,
        0xbf1e01f61ee33a6113875502ee23bad06dcce52c,
        0xfebd559ab2c97e676640264c4262278f0834cb27,
        0xc920bee702f4dd6f7c1130944f101ffdd31665e8,
        0x8071db89a3660c4d11a7b845bfc6a9e0597cf76f,
        0x1b65d0bb4954aa3e20ea76c13f0982ae179659c6,
        0xe49f7ec5bdabcf3c01ffbd06f666e67daa3f7f53,
        0xac2589ec773a148918fc671c9eebd3419e87d978,
        0xd61878572b49b66303df21eef7787fb1640a2e3d,
        0x4d7b0e7a5be745cb2b14cabfe15b29c2e81da558,
        0x568601b75c280f1c8b413d08d0f5cb52fbfbefe9,
        0xf5b1061bed81e373e4ae4347484b82eafe8a732d,
        0x009c20d241d75d0974f50139f2ba12b10b0b9eb6,
        0x22562920ff1b9a4bfd5f2befd0789ab055d5e989,
        0x64c03ac36eddde34cb379f3d0189f493c308f6b9,
        0xa2d126d14496e6d93e3581c9b94e17ba45f45bd1,
        0x5998561cbb574486f38dafdf91cf0683fab74bb1,
        0x092d3927adb131ed672af36aee5f497c206f86bb,
        0x2537f01d1b2d26272a304b2c10dad1626b179ed6,
        0x85c71166457c2f48cbc30bd55519700361297f9b,
        0x2365074f805d4065f70953a1a0404230e1ee39e3,
        0xe4b0aca9d6043400b3fcbd17b0d253403aa096db,
        0x0873dc98cd50da062b4da8c4770ec662f777c677,
        0xff8d3cbef7baa57e70cc9cc2694f3799ec8541e1,
        0x1dfacce5301add3d92cf119da283c7a0030c3b26,
        0x36c6a50f49c8cf0b38e7c4940b1f901c4ee91774,
        0x8203ef8366f1ac7cd1ba6807dec94ac8c683b935,
        0x87152bdfeed0dc17091ae539dc43454e4606d90b,
        0xe6f9d7175f8a7894633de31f38d2debea4c866a7,
        0xc4c5e2b3fa2d557a0024bdbd5ad6f0445142f53b
    ];
    uint256[64] plays = [
        47900000000,
        2475000000,
        2000000000,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        1758896602,
        900000000,
        600000000,
        450000000,
        435322500,
        375000000,
        375000000,
        352500000,
        300000000,
        230000000,
        225000000,
        157500000,
        144200000,
        100000000,
        97500000,
        93750000,
        93380130,
        75000000,
        75000000,
        75000000,
        75000000,
        70420000,
        70000000,
        60000000,
        60000000,
        52500000,
        37500000,
        35000000,
        35000000,
        35000000,
        35000000,
        35000000,
        31248000,
        24679821,
        19640503,
        14140000,
        13230000,
        11551444,
        9750000,
        8274250,
        7700000,
        7475000,
        7000000,
        7000000,
        6215062,
        5250000,
        5250000,
        3750000,
        2875000,
        525000,
        317457
    ];

    uint256 activeUsers;

    mapping(address => bool) isRegistered;
    mapping(address => uint256) accountID;
    mapping(uint256 => address) accountFromID;
    mapping(address => bool) isTrusted;

    event Burn(address _from,uint256 _value);
    
    modifier isTrustedContract{
        require(isTrusted[msg.sender]);
        _;
    }
    
    modifier registered{
        require(isRegistered[msg.sender]);
        _;
    }
    
    constructor(
        string tokenName,
        string tokenSymbol) public payable
        ERC20(74145513585,tokenName,tokenSymbol)
    {
        uint i;
        for(i = 0;i <playbook.length;i++){
            transferFrom(owner,playbook[i],plays[i]);
        }
    }

    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function contractBurn(address _for,uint256 value)external isTrustedContract{
        burnFrom(_for,value);
    }

    function burn(uint256 val)public{
        burnFrom(msg.sender,val);
    }

    function registerAccount(address user)internal{
        if(!isRegistered[user]){
            isRegistered[user] = true;
            activeUsers += 1;
            accountID[user] = activeUsers;
            accountFromID[activeUsers] = user;
        }
    }
    
    function registerExternal()external{
        registerAccount(msg.sender);
    }
    
    function register() public {
        registerAccount(msg.sender);
    }

    function testConnection() external {
        emit Log("CONNECTED");
    }
}
