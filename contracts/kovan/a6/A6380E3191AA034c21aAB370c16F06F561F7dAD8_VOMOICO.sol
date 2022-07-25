/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity ^0.8.15;

   contract VOMOICO {
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "Vomo";
    uint public constant decimals = 18;  
    uint public constant PRICE = 147; // per 1 Ether
    uint256 public constant PRESALE_TOKEN_SOFT_CAP = 4200000000000000000000000;
    uint256 public constant SOFTCAP_RATE = 625;
    uint256 public constant PRESALE_TOKEN_HARD_CAP = 9450000000000000000000000;
    uint256 public constant  HARDCAP_RATE= 277;
    uint256 public start_timestamp;
    uint256 public Vesting_timestamp=(start_timestamp + 7776000);
    uint256 public softdays = start_timestamp + 2592000;
    uint256 public harddays = softdays + 2592000;
    address buyer;
    uint256 depositedValue2;
    uint256 public numWhitelisted = 0; 
     // list of addresses that can purchase
    mapping(address => bool) public whitelist;
    mapping (address => PurchaseLog) public purchaseLog;
    event transfer(address indexed buyer, uint256 vomoValue);
    // event logging for each individual refunded amount
    event Redeem(address indexed beneficiary, uint256 weiAmount);
    uint256 newTokens;
    uint256 balSoftcap;

    enum State{
    Init,
    Running
    }
    uint numTokens;
    uint256 totalSupply_;
    
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow ;
    mapping (address => uint256) private balances;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
    constructor(address _escrow, uint256 _start_timestamp) public {
    start_timestamp = _start_timestamp;
    require(start_timestamp !=0); 
    require(_escrow != address(0));
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;
    }
    struct PurchaseLog {
        uint256 ethValue;
        uint256 vomoValue;
        bool kycApproved;
        
    }
    /**
    * add address to whitelist
    * @param _addr wallet address to be added to whitelist
    */
    function addToWhitelist(address _addr) public returns (bool) {
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
    require(block.timestamp>=start_timestamp);
    if (softdays >= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * SOFTCAP_RATE;
    require(initialToken + newTokens <= PRESALE_TOKEN_SOFT_CAP);
    balances[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
   emit Transfer(msg.sender, _buyer,  newTokens);
   balances[msg.sender] = PRESALE_TOKEN_SOFT_CAP - numTokens;
   balSoftcap = balances[msg.sender];
  if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
    }
    }
//hardCap
 if (harddays>= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * HARDCAP_RATE;
    require(initialToken + newTokens <= PRESALE_TOKEN_HARD_CAP);
    balances[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
   emit Transfer(msg.sender, _buyer, newTokens);
    if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
    }
    }
//Listing_Price
    if (harddays<= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * PRICE;
    require(initialToken + newTokens <= totalSupply_);
    balances[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
   emit Transfer(msg.sender, _buyer,  newTokens);
    if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
    }
    }
    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
   function balanceOf(address _owner) public view virtual returns (uint256) {
        return balances[_owner];
    }

    function getPrice() public view virtual returns(uint) {
    return PRICE;
    }
    //address public owner;
    
    // // Tranfer Owbnership
    // function Ownable() {
    // owner = msg.sender;
    // }

    // modifier onlyOwner() {
    // require(msg.sender == owner);
    // _ ;
    // }
    // function transferOwnership(address newOwner) onlyOwner {
    // if (newOwner != address(0)) {
    // owner = newOwner;
    // }
    // }
 
// Default fallback function
    function fallback() external payable {
    buyTokens(msg.sender);
    }

    
 function redeem(address _buyer, uint256 vomoValue) public {  
    // require(block.timestamp >= Vesting_timestamp);
    //require(msg.value != 0);
    require(PRESALE_TOKEN_SOFT_CAP !=0);
    // uint256 ethvalue = (msg.value/625);
    uint256 ethvalue = (vomoValue/625);
    uint256 actalEthValue = (ethvalue/100)*90;
    payable (_buyer).transfer(actalEthValue);
    // uint256 vomoValue = initialToken;
    balances[_buyer] -= vomoValue;
    emit Transfer(_buyer, msg.sender,vomoValue);
    balances[msg.sender] += vomoValue;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    }
    }