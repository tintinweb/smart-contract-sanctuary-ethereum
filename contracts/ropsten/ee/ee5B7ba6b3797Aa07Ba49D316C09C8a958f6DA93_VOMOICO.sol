/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.4.17;
 
   
   contract VOMOICO {
/// Fields:


    string public constant name = "VOMO";
    string public constant symbol = "VZT";
    uint public constant decimals = 18;  
    // uint public constant PRICE = 100; 
    uint public constant PRICE = 147; // per 1 Ether
    uint256 public constant PRESALE_TOKEN_SOFT_CAP = 4200000000000000000000000;
    uint256 public constant SOFTCAP_RATE = 625;
    uint256 public constant PRESALE_TOKEN_HARD_CAP = 9450000000000000000000000;
    uint256 public constant  HARDCAP_RATE= 277;
    uint256 public start_timestamp;
    // uint256 public extTime = 7776000;
    uint256 public constant  Vesting_timestamp=(start_timestamp + 7776000);
    uint256 public constant softdays = start_timestamp + 2592000;
    uint256 public constant harddays = softdays + 2592000;
    //address funder1 = 0x69e56D0aF44380BC3B0D666c4207BBF910f0ADC9;
   //uint256 doRefund;
    //capture refunds
    mapping (address => bool) public refundLog;
    address buyer;
    uint256 depositedValue2;
    uint256 public numWhitelisted = 0; 
     // list of addresses that can purchase
    mapping(address => bool) public whitelist;
     mapping (address => PurchaseLog) public purchaseLog;
    //   mapping (address => uint256) private depositedValue;
     // event logging for each individual refunded amount 
    event transfer(address indexed buyer, uint256 VomoValue);

    // event logging for funds transfered to VectorZilla multi-sig wallet
    event FundsTransferred();
    // event logging for each individual refunded amount
    event Redeem(address indexed beneficiary, uint256 weiAmount);
    // ETH to refund
    //uint256 depositedValue = buyer.ethValue;
    uint256 newTokens;
    uint256 balSoftcap;

    enum State{
    Init,
    Running
    }
    // uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow = 0;
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
/// @dev Constructor
    function VOMOICO(address _escrow, uint256 start_timestamp) public {
    start_timestamp = start_timestamp;
    require(_escrow != 0);
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;
    }
    struct PurchaseLog {
        uint256 ethValue;
        uint256 VztValue;
        bool kycApproved;
        
    }


    /**
    * add address to whitelist
    * @param _addr wallet address to be added to whitelist
    */
    function addToWhitelist(address _addr) public onlyOwner returns (bool) {
        require(_addr != address(0));
        if(!whitelist[_addr]) {
            whitelist[_addr] = true;
            numWhitelisted++;
        }
        purchaseLog[_addr].kycApproved = true;
        
        return true;
    }


//buy

    function buyTokens(address _buyer) public payable onlyInState(State.Running) {
     //Softcap
    
    if (softdays >= block.timestamp){
    require(msg.value != 0);
    //require(!refundLog[_buyer]);
    newTokens = msg.value * SOFTCAP_RATE;
   
    require(initialToken + newTokens <= PRESALE_TOKEN_SOFT_CAP);
    balance[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(msg.sender, _buyer,  newTokens);
   // Transfer(_buyer, msg.sender, msg.value);
   // balance[msg.sender] -= PRESALE_TOKEN_SOFT_CAP;
   balance[msg.sender] = PRESALE_TOKEN_SOFT_CAP - numTokens;
      
    balSoftcap = balance[msg.sender];
    
    
    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }
//hardCap
 if (harddays>= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * HARDCAP_RATE;
    require(initialToken + newTokens <= PRESALE_TOKEN_HARD_CAP);
    balance[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(msg.sender, _buyer, newTokens);
    
    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }
//Listing_Price
    if (harddays<= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * SOFTCAP_RATE;
    //console.log("newToken");
    require(initialToken + newTokens <= totalSupply_);
    balance[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    Transfer(msg.sender, _buyer,  newTokens);
    if(this.balance > 0) {
    require(escrow.send(this.balance));
    }
    }
    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }

    function getPrice() constant returns(uint) {
    return PRICE;
    }
    address public owner;
    
    // Tranfer Owbnership
    function Ownable() {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
    owner = newOwner;
    }
    }
 
// Default fallback function
    function() payable {
    buyTokens(msg.sender);
    }

    
 function redeem(address _buyer) external payable onlyOwner{  
    
  
    // require(block.timestamp >= Vesting_timestamp);
    require(msg.value != 0);
    
    require(PRESALE_TOKEN_SOFT_CAP !=0);
    uint256 abc = (msg.value/625);
    //uint256 abc = msg.value;
    // uint ethValue = (numTokens /625); 
    //  abc += ethValue;
    _buyer.send(abc);
    // console.log(abc);
    // console.log(_buyer.send(abc));
     



    // _buyer.send(msg.value);
    // console.log(msg.value);
    // console.log(_buyer.send(msg.value));
       // ETH to refund
    //   uint256 depositedValue = ethValue;
       //initialToken to revert
       
      uint256 vztValue = initialToken;
     
      
      
    //   balance[msg.sender] = msg.value - depositedValue;
    //   Transfer(msg.sender,_buyer, depositedValue);
       
      balance[_buyer] -= vztValue;
      Transfer(_buyer, msg.sender,vztValue);
    
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    
//    this.balance = depositedValue;
   
    
}
// function Execution () {
//     buyer.send(depositedValue2);
//     console.log(buyer.send(depositedValue2));
// }


       
 }