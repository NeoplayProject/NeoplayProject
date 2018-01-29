pragma solidity ^0.4.11;

import "https://github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract getOdds is usingOraclize {
 
    uint private odds;
    event Log(string text);

    function getOdds() public{
        update();
    }
    
    function getOdd() public returns (uint){
        return odds;
    }
    function update_odds() public {
        Log('Updating Odds');
        update();
    }
    function __callback(bytes32 _myid,string _result) public{
        require (msg.sender == oraclize_cbAddress());
        Log(_result);
        odds = parseInt(_result);
    }
    function update() public payable{
        Log('Oraclize Query was sent, awaiting your bet');
        oraclize_query("URL",'THIS IS WHERE THE URL SHOULD BE');
    }
    
}

contract getReRoll is usingOraclize {
    //this checks if we recieved tokens and then deposists them to us
}
contract NEOPLAYdice is usingOraclize {
    struct Party{
        address ass;
        uint balance;
    }
    
    uint public HouseEdge = 1; //written in percentage
    uint public random;
    uint private wamount;
    uint public min_value=1 finney;
    uint private rerolls;
    uint256 private preval;
    uint256 private newval;
    uint256 private fee;
    uint private odd;
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    Party private house = Party(0x123, 30);
    Party public client = Party(msg.sender, msg.sender.balance);

    mapping (address => uint) pendingWithdrawals;
    
    modifier bnr_checked {
        if (client.balance >msg.value && msg.value > min_value && msg.value < houseReserve()/8){
            _;
        }
    }
    function houseAddy() private returns (address){
        return house.ass;
    }
    function houseReserve() private returns (uint){
        return house.balance;
    }
    function getAmount() private returns (uint){
        return wamount;
    }
    
    function setAmount(uint new_amount) private returns (uint){
        wamount = new_amount;
    }
    
    function uprerollCount() private{
        rerolls+=1;
    }
    
    function houseDeposit(uint val) public payable bnr_checked  {
        pendingWithdrawals[client.ass] = val;
        setAmount(pendingWithdrawals[client.ass]);
        houseAddy().transfer(getAmount());
        pendingWithdrawals[client.ass]=0;
    }

    function NEOPLAYdice() public payable bnr_checked{
        oraclize_setProof(proofType_Ledger); //sets the ledger authenticity proof in constructor
        update(); //asks for N random bytes on contract
        play();
           
    }
    function __callback(bytes32 _queryId, string _result, bytes _proof) public returns (uint){ 
        if (msg.sender != oraclize_cbAddress())revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
            revert();
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            
            newRandomNumber_bytes(bytes(_result)); // this is  the resulting random number (bytes)
            
            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            uint randomNumber = uint(keccak256(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
            
            newRandomNumber_uint(randomNumber);
            random = randomNumber%99; // this is the resulting random number (uint)
        }
    }

    function update() public payable {
        uint N = 7;
        uint delay = 0;
        uint callbackGas = 200000;
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }
    
    function play() public payable{
        odd = new getOdds().getOdd();
        preval = msg.value;
        fee = preval*(HouseEdge)/100;
        newval = preval*(100-HouseEdge)/100;
        houseDeposit(fee);
        if(odd<random){
            //they win
            client.ass.transfer(newval);
        }else{
            //we win
            reroll();
        }
    }

    function rerollprice() public returns(uint256) {
        return preval**rerolls;
    }

    function reroll() public payable{
        //if (getReRoll()){
            update();
            preval = newval;
            fee = preval*(HouseEdge)/100;
            newval = newval*(100-HouseEdge)/100;
            houseDeposit(fee);
            if(odd<random){
                client.ass.transfer(newval);
            }else{
                reroll();
            }
        //}
    }
}