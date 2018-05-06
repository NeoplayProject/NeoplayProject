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
contract SimpleWallet {
    address owner;
    struct WithdrawlStruct {
        address to;
        uint amount;
    }
    struct Senders {
        bool allowed;
        uint amount_sends;
        mapping(uint => WithdrawlStruct) withdrawls;
    }

    mapping(address => Senders) isAllowedToSendFundsMapping;

    event Deposit(address _sender, uint amount);
    event Withdraw(address _sender, uint amount, address _beneficiary);

    function SimpleWallet() {
        owner = msg.sender;
    }

    modifier allowedToSend() {
        require(isAllowedToSend(msg.sender));
        require(now > 1557086400);
        _;
    }

    function() allowedToSend payable {
        Deposit(msg.sender, msg.value);
    }
    function sendFunds(uint amount, address receiver) allowedToSend returns (uint) {
        require(this.balance >= amount);
        receiver.transfer(amount);
        Withdraw(msg.sender, amount, receiver);
        isAllowedToSendFundsMapping[msg.sender].amount_sends++;
        isAllowedToSendFundsMapping[msg.sender].withdrawls[
        isAllowedToSendFundsMapping[msg.sender].amount_sends ] = WithdrawlStruct(receiver, amount);
        return this.balance;
    }
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    function allowAddressToSendMoney(address _address) isOwner {
        isAllowedToSendFundsMapping[_address].allowed = true;
    }
    function disallowAddressToSendMoney(address _address) isOwner {
        isAllowedToSendFundsMapping[_address].allowed = false;
    }
    function isAllowedToSend(address _address) constant returns (bool) {
        return isAllowedToSendFundsMapping[_address].allowed || _address == owner;
    }
    function killWallet() isOwner {
        suicide(owner);
    }
} 