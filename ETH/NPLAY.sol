pragma solidity ^0.4.21;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

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
    function transfer(address _to, uint256 _value) external{
        _transfer(msg.sender, _to, _value);
    }
    function burn(uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}
contract NP is owned, TokenERC20, usingOraclize {
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
    string private XBSQueryDATA;
    string private key = "c984bb84715718f37a76f5e3de35d20ac9e92f9a57c07e398dc28146d8cdb183";
    
    uint confirm1;
    mapping (address => string) private linkedAccount;
    mapping (address => uint256) public NeoOwed;
    mapping (address => bool) public frozenAccount;
    mapping (address => request) public activeRequests;
    mapping (bytes32 => address) public toAddress;
    event FrozenFunds(address target, bool frozen);

    function NP(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )TokenERC20(initialSupply, tokenName, tokenSymbol) public payable{
        //oraclize_setProof(proofType_TLSNotary);
    }
//--------------------------------------TYPECAST FUNCTIONS---------------------------------------------------//
    function toString(address x)public pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    function uintToString (uint dta)public pure returns (string) {
        bytes32 data = bytes32(dta);
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    function stringToBytes32(string memory source)public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
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
    }function getXQD()public view returns(string){
        return(XBSQueryDATA);
    }
    function getXQDfromOutside()external view returns(string){
        return(XBSQueryDATA);
    }
    function getXQUfromOutside()external view returns(string){
        return(XBSQueryURL);
    }
    function getXQU()public view returns(string){
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
    function setXQD(string newQD) onlyOwner public{
        XBSQueryDATA=newQD;
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
    //These are simply to trasnfer owed Neo
    //All values are to become 0 upon the neo creation
    function _transferNeo(address _from, address _to,uint _value) internal {
        require (_to != 0x0);
        require (NeoOwed[_from] >= _value);               
        require (NeoOwed[_to] + _value > NeoOwed[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
       
        NeoOwed[_from] -= _value;                         
        NeoOwed[_to] += _value;
        emit TransferNeo(_from, _to, _value);
    }
    function transferNeo(address to,uint256 value)external{
        _transferNeo(msg.sender,to,value);
    }
    function transferBoth(address to,uint256 value)external{
        _transfer(msg.sender,to,value);
        _transferNeo(msg.sender,to,value);
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

    function burnFromContract(address tokenHolder,uint256 value)external{
        require(msg.sender == GameContract);
        burnFrom(tokenHolder,value);
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
            }else{
                revert();
            }
        }
        activeRequests[requestor].action=0;
    }
    function registerData(address from, address to, uint256 action,uint256 value)external {
        request memory r = request(from,to,action,value);
        activeRequests[msg.sender] = r;
        string memory data = strConcat(strConcat("{from:",toString(from),",to:",toString(to)),strConcat(",action:",uintToString(action),",value:",uintToString(value)),"}");
        //sendXBS(data);
    }
    function sendXBS(string data)internal{
        string memory url = getXQU();
        oraclize_query("URL",url,data);
    }
    function __callback(bytes32 myid, string result,bytes32 proof)public {
        if(msg.sender != oraclize_cbAddress())revert();
        confirmRequest(toAddress[stringToBytes32(result)]);
        emit Log32(myid);
        emit Log32(proof);
        
    }
}
