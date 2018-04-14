interface EP {function buyFromNplay(address user,uint val)external payable;}
contract NP is owned, SecureToken, usingOraclize {
    using strings for *;
    uint256 public buyPrice;
    address private GameContract;
    address public EPLAY=owner;
    
    bool isReady = false;
    bool callbackran=false;
    
    string private XBSQueryURL;
    string public message;
    
    address cb;
//----------------------------------------------CONSTRUCTOR-----------------------------------------------//
    function NP(
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
    modifier isEPLAY{
        require(msg.sender == EPLAY);
        _;
    }
//--------------------------------------TYPECAST FUNCTIONS---------------------------------------------------//
    function appendUintToString(string inStr, uint v)internal pure returns (string str) {
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
    function makeXID(uint v)private pure returns (string str){
        str = appendUintToString("XID",v);
    }
    function stringToUint(string s)internal pure returns (uint256 result) {
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
        if(owner==msg.sender)emit Log("Owner");
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
    function setXQU(string newQU) onlyOwner public{
        XBSQueryURL=newQU;
    }
    function toggleReady() onlyOwner public{
        isReady = !isReady;
    }
    function setEPLAY(address newAddy) onlyOwner public{
        EPLAY = newAddy;
        toggleReady();
    }
//----------------------------------------TRANSFER FUNCTIONS------------------------------------------//
    function buy()public payable {//isAfterRelease
        require(owner.balance >0);
        uint256 multiplier=100;
        if(isReady){
            EP EE = EP(EPLAY);
            EE.buyFromNplay(msg.sender,msg.value);
            multiplier = getMultiplier();
        }
        uint amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, multiplier*amount/100);
    }
    function buyFromEplay(address user,uint val)external payable{/*isAfterRelease*/
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
//-------------------------------------------SISTER TOKEN FUNCTIONS-------------------------------------//
    function sendLink(string xid,string Nb,string Na)internal{
        string memory url = getXQU();
        string memory data = strConcat(strConcat("{\"XID\":\"",xid,"\",\"NB\":\"",Nb),strConcat("\",\"NA\":\"",Na,"\"}"));
        emit Log(data);
        oraclize_query("URL",url,data);
    }
    function link(address EtherAddress,string NeoAddress)external registered {
        if(balanceOf[EtherAddress]==0)revert();
        string memory xid = makeXID(accountID[EtherAddress]);
        string memory nBalance = appendUintToString("B",balanceOf[EtherAddress]);
        sendLink(xid,nBalance,NeoAddress);
    }   
    function __callback(bytes32 myid, string result)public{
       if(msg.sender != oraclize_cbAddress()){
           cb = 0x0;
           message = "it reverted";
           revert();
       }
       callbackran=true;
       message = result;
       //result should come back as "XID{id}B{balance}"
       strings.slice memory id = (result.toSlice()).beyond("XID".toSlice());
       strings.slice memory nbalance = (result.toSlice()).beyond("B".toSlice());
       burnFrom(accountFromID[stringToUint(id.toString())],stringToUint(nbalance.toString()));
       myid;
    }
    function check() public{
        if(callbackran){
            emit Log("CallbackRan");
            emit LogA(cb);
            emit Log(message);
        }else{
            emit Log("CallbackNoRan");
            emit Log(message);
        }
    }
}
