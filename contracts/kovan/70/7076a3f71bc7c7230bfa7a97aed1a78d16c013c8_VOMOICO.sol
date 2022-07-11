/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.7.0;




// // // SPDX-License-Identifier: MIT
// // // OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



// // // CAUTION
// // // This version of SafeMath should only be used with Solidity 0.8 or later,
// // // because it relies on the compiler's built in overflow checks.

// // /**
// //  * @dev Wrappers over Solidity's arithmetic operations.
// //  *
// //  * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
// //  * now has built in overflow checking.
// //  */


 
  library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
   
   contract VOMOICO {
      using SafeMath for uint256;
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "Vomo";
    uint public constant decimals = 18;  
    // uint public constant PRICE = 100; 
    uint public constant PRICE = 147; // per 1 Ether
    uint256 public constant PRESALE_TOKEN_SOFT_CAP = 4200000000000000000000000;
    uint256 public constant SOFTCAP_RATE = 625;
    uint256 public constant PRESALE_TOKEN_HARD_CAP = 9450000000000000000000000;
    uint256 public constant  HARDCAP_RATE= 277;
    uint256 public start_timestamp;
    // uint256 public extTime = 7776000;
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
    mapping (address => uint256) private balance;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
    constructor(address _escrow, uint256 start_timestamp) public {
    start_timestamp = start_timestamp;
    //require(_escrow != 0);
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
   emit Transfer(msg.sender, _buyer,  newTokens);
   balance[msg.sender] = PRESALE_TOKEN_SOFT_CAP - numTokens;
      
    balSoftcap = balance[msg.sender];
     // if(this.balance > 0) {
    // require(escrow.send(this.balance));
    // }
    if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
     //console.log(address(this).balance,"address(this).balance");
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
   emit Transfer(msg.sender, _buyer, newTokens);
    
    // if(this.balance > 0) {
    // require(escrow.send(this.balance));
    // }
    if(address(this).balance > 0) {
    payable (escrow).send(address(this).balance);
    }
    }
//Listing_Price
    if (harddays<= block.timestamp){
    require(msg.value != 0);
    newTokens = msg.value * SOFTCAP_RATE;
    require(initialToken + newTokens <= totalSupply_);
    balance[_buyer] += newTokens;
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
        return balance[_owner];
    }

    function getPrice() public view virtual returns(uint) {
    return PRICE;
    }
    address public owner;
    
    // Transfer Ownership
    function Ownable() public  {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
    owner = newOwner;
    }
    }

     // Default fallback function
    function fallback() external payable {
    buyTokens(msg.sender);
    }
 


    
 function redeem(address _buyer) external payable onlyOwner{  
    require(block.timestamp >= Vesting_timestamp);
    require(msg.value != 0);
    
    require(PRESALE_TOKEN_SOFT_CAP !=0);
    
    uint256 ethvalue = (msg.value/625);
     uint256 def = (ethvalue/100)*90;
     payable (_buyer).send(def);
      uint256 vomoValue = initialToken;
      balance[_buyer] -= vomoValue;
      

     emit Transfer(_buyer,msg.sender,vomoValue);
    balance[msg.sender] += vomoValue;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    }
    }