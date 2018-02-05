pragma solidity ^0.4.11;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
contract RollToken is owned, TokenERC20{

    string public name = "RollToken";
    string public symbol = "ROLL";
    string public decimals = 18;
    uint256 public totalSupply = initialSupply*10**decimals;//update this
    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => uint256) public balanceOf;
    mapping(address => bool) public isFrozen;
    //allowance describes how much each account is allowed to send to another account

    event Trasfer(address indexed from, uint256 value);
    event Burn(address indexed from,uint256 value);

    function RollToken(uint256 initialSupply,string tokenName,string tokenSymbol) TokenERC20(initialSupply,tokenName,tokenSymbol){
    }
    function _transfer(address _from,address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from] && !frozenAccount[_to]);
        uint previous = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from,_to,_value);
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
    }
    function burn(uint256 _value) public returns (bool succ){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -=_value;
        Burn(msg.sender,_value);//event
    }
    function burnFrom(address _from, uint256 _value)p ublic returns (bool success){
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -=_value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from,_value);
        return true;
    }
    function buy() payable public{
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }
    function sell(uint256 amount) payable public{
        require(this.balance >= amount*sellPrice);
        _transfer(msg.sender,this,amount);
        msg.sender.transfer(amount*sellPrice);
    }
}
