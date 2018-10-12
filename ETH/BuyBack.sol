pragma solidity ^0.4.25;

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

interface EPLAY {function balanceOf(address tokenOwner) public view returns (uint balance);}

contract BuyBack is owned{
    EPLAY public eplay;
    uint256 public sellPrice; //100000000000000
    
    uint256 max = 47900000000;
    
    event Transfer(address reciever, uint256 amount);
    
    modifier isValid {
        require(msg.value <= max);
        _;
    }
    
    constructor(address eplayAddress) public payable{
        setEplay(eplayAddress);
        setPrice(480000000);
        deposit();
    }
    
    function refund() public payable isValid {
        address reciever = msg.sender;
        uint256 balance = eplay.balanceOf(reciever);
        if(balance <= 0) {
            revert();
        }else {
            emit Transfer(reciever,balance*sellPrice);
            reciever.transfer(balance*sellPrice);
        }
    }
    
    function setEplay(address eplayAddress) public onlyOwner {
        eplay = EPLAY(eplayAddress);
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        sellPrice = newPrice;
    }
    
    function deposit() public payable {
        address(this).transfer(msg.value);
    }
    
    function close() public payable onlyOwner {
        owner.transfer(address(this).balance);
    }
    function getBalance(address addr) public view returns (uint256 bal) {
        bal = eplay.balanceOf(addr);
        return bal;
    }
    
    function getSenderBalance() public view returns (uint256 bal) {
        return getBalance(msg.sender);
    }
    
    function getOwed() public view returns (uint256 val) {
        val = getSenderBalance()*sellPrice;
    }
}
