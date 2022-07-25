/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.8.15;



// // SPDX-License-Identifier: MIT
// // OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



// // CAUTION
// // This version of SafeMath should only be used with Solidity 0.8 or later,
// // because it relies on the compiler's built in overflow checks.

// /**
//  * @dev Wrappers over Solidity's arithmetic operations.
//  *
//  * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
//  * now has built in overflow checking.
//  */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
   
   contract VOMOICO {
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
    mapping (address => uint256) private balances;
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
    balances[_buyer] += newTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
   emit Transfer(msg.sender, _buyer,  newTokens);
   balances[msg.sender] = PRESALE_TOKEN_SOFT_CAP - numTokens;
      
    balSoftcap = balances[msg.sender];
    
    
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
    balances[_buyer] += newTokens;
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

    
 function redeem(address _buyer) public payable {  
    
    // require(block.timestamp >= Vesting_timestamp);
    require(msg.value != 0);
    
    require(PRESALE_TOKEN_SOFT_CAP !=0);
    
    uint256 ethvalue = (msg.value/625);
    
    uint256 def = (ethvalue/100)*90;
     payable (_buyer).transfer(def);
  

    //  uint256 vomoValue = initialToken;
    //  balances[_buyer] -= vomoValue;
     emit Transfer(_buyer, escrow, msg.value);
      balances[escrow] += msg.value;
    
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    }
    }