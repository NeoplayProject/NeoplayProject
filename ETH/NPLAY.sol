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
    mapping (address => string) private linkedAccount;
    mapping (address => uint256) public NeoBalance;
    mapping (address => bool) public frozenAccount;
    mapping (address => request) public activeRequests;
    mapping (address=>bool) public isRegistered;
    mapping (address => uint256) public accountID;
    mapping (uint256 => address) public accountFromID;
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
    modifier registered {
        require(isRegistered[msg.sender]);
        _;
    }
//--------------------------------------TYPECAST FUNCTIONS---------------------------------------------------//
    function uintToString(uint256 v)public constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
    function appendUintToString(string inStr, uint v)public constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }
    function makeXID(uint v)private constant returns (string str){
        str = appendUintToString("XID",v);
    }
    function stringToUint(string s)public constant returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
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
    function getXQU()internal view returns(string){
        return(XBSQueryURL);
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
    function setXQU(string newQU) onlyOwner public{
        XBSQueryURL=newQU;
    }
    
//----------------------------------------TRANSFER FUNCTIONS------------------------------------------//

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require (NeoBalance[_from] >= _value);               
        require (NeoBalance[_to] + _value > NeoBalance[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        
        NeoBalance[_from] -=_value;
        NeoBalance[_from] += _value;
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
    function mintToken(address target, uint256 mintedAmount) onlyOwner external {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

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
//-------------------------------------------SISTER TOKEN FUNCTIONS-------------------------------------//
    function confirmRequest(address requestor)internal{
        if(activeRequests[requestor].action!=0){
            request memory r = activeRequests[requestor];
            require(r.from == requestor);
            if(r.action==1){
                _transfer(requestor,r.to,r.value);
            }else if(r.action==2){
                burnFrom(requestor,r.value);
            }else if(r.action==3){
                if(!isRegistered[requestor]){
                    isRegistered[requestor]=true;
                    accountID[requestor] = r.value;
                    accountFromID[r.value] = requestor;
                }
            }
            else{
                revert();
            }
        }
        activeRequests[requestor].action=0;
    }
    function registerData(address from, address to, uint256 action,uint256 value)internal {
        request memory r = request(from,to,action,value);
        activeRequests[msg.sender] = r;
    }
    function sendXBS(string from,string to,string action,string value)public{
        string memory url = getXQU();
        oraclize_query("URL",url,
            strConcat(
                strConcat(
                    "{\"from\":\"",
                    from,
                    "\",\"to\":\"",
                    to
                    ),
                strConcat(
                    "\",\"action\":\"",
                    action,
                    "\",\"value\":\"",
                    value
                    ),
                "\"}"
                )
            );
    }
    function __callback(bytes32 myid, string result)public {
        if(msg.sender != oraclize_cbAddress())revert();
        strings.slice memory id = (result.toSlice()).beyond("XID".toSlice());
        uint256 I = stringToUint(id.toString());
        confirmRequest(accountFromID[I]);
        callbackran=true;
        cb = accountFromID[I];
        myid;
    }
    function check() public{
        if(callbackran){
            emit Log("CallbackRan");
            emit LogA(cb);
        }else{
            emit Log("CallbackNoRan");
        }
    }
    function sendRequest(address _from,address _to,uint256 _action,uint256 _value)internal registered{
        registerData(_from,_to,_action,_value);
        string memory from = makeXID(accountID[_from]);
        string memory to = makeXID(accountID[_to]);
        string memory action = uintToString(_action);
        string memory value = uintToString(_value);
        sendXBS(from,to,action,value);
        emit Log("Request Logged");
        emit Log(from);//logs the requestor
    }
    function burn(uint256 value)external registered{
        sendRequest(msg.sender,0x0,2,value);
    }
    function transfer(address to,uint256 value)external registered{
        sendRequest(msg.sender,to,1,value);
    }
    function registerAccount()external {
        if(!isRegistered[msg.sender]){
            activeUsers+=1;
            sendRequest(msg.sender,0x0,3,activeUsers);
        }
    }
}
