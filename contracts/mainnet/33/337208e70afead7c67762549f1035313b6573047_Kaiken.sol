/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

pragma solidity 0.5.16;


contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused external {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused external {
      paused = false;
      emit Unpause();
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}


contract Kaiken is Pausable {


    using SafeMath for uint256;
    address public  busdAddress; 
    uint256 public gleanWhitelistFixedBUSDAllowed;

    mapping (address => bool) public gleanWhiteListedUsers;
    mapping (address => uint256) public allParticipants;
    mapping (address => bool) public isParticipant;
    mapping (address => uint256) public amountAllowed;


    address public wallet;

    uint256 public totalInvestment;
    uint256 public totalUsdtExpected;
    bool public SaleOpenForEveryone;
    uint256 public perUserAfterOpenForall;
    mapping (address => bool) public fcfsParticipant;
    uint256 public totalNoOfInvestors;
    
    event IDOInvestment(address indexed from, uint256, uint256);    


    constructor(address usdt, address walletAddress) public Owned(msg.sender) {

      busdAddress = usdt;
      gleanWhitelistFixedBUSDAllowed = 500 *10**18;
      wallet = walletAddress;
      totalUsdtExpected = 69000 *10**18; 
      SaleOpenForEveryone = false;

    }


    function authorizeGleanUsers(address[] calldata addrs) external onlyOwner whenNotPaused returns (bool success) {
        uint arrayLength = addrs.length;
        for (uint x = 0; x < arrayLength; x++) {
            gleanWhiteListedUsers[addrs[x]] = true;
            amountAllowed[addrs[x]] = 500 *10**18; 
        }

        return true;
    }
    

    function authorizeAllocationUsers(address[] calldata addrs, uint256[] calldata amount) external onlyOwner whenNotPaused returns (bool success) {
        uint arrayLength = addrs.length;
        for (uint x = 0; x < arrayLength; x++) {
            gleanWhiteListedUsers[addrs[x]] = true;
            amountAllowed[addrs[x]] = amount[x] *10**18;
        }

        return true;
    }


    function openInvestmentForAll (uint256 _perUserAfterOpenForall) external whenNotPaused onlyOwner  returns (bool){

        SaleOpenForEveryone = true;
        perUserAfterOpenForall = _perUserAfterOpenForall;
        return true;        
    }    

    function closeInvestmentForAll () external whenNotPaused onlyOwner  returns (bool){

        SaleOpenForEveryone = false;
        return true;
        
    }    


    function depositIDO (uint256 usdt_Amount)  external whenNotPaused returns (bool){
        

        if (SaleOpenForEveryone) {
            
            require(!fcfsParticipant[msg.sender], "You have already participated in open for all round");
            require (usdt_Amount == perUserAfterOpenForall, "Amount allowed not same for open all");
            totalInvestment = totalInvestment.add(usdt_Amount);
            allParticipants[msg.sender] = allParticipants[msg.sender].add(usdt_Amount);
            isParticipant[msg.sender] = true;
            fcfsParticipant[msg.sender] = true;
            totalNoOfInvestors = totalNoOfInvestors.add(1); 
            require(totalInvestment <= totalUsdtExpected, "Over investemnet");
            require(IERC20(busdAddress).transferFrom(msg.sender,wallet,usdt_Amount), "transfer failed");            
         

        } else  {   
            
            
            require (!isParticipant[msg.sender], "already participatd");
            require(amountAllowed[msg.sender] == usdt_Amount, "amount is different from what allowed");     
            require(gleanWhiteListedUsers[msg.sender] == true, "Not a valid user in sale before open for all");
            totalInvestment = totalInvestment.add(usdt_Amount);
            allParticipants[msg.sender] = allParticipants[msg.sender].add(usdt_Amount);
            isParticipant[msg.sender] = true;
            totalNoOfInvestors = totalNoOfInvestors.add(1); 
            require(totalInvestment <= totalUsdtExpected, "Over investemnet");
            require(IERC20(busdAddress).transferFrom(msg.sender,wallet,usdt_Amount), "transfer failed");            

            
        }


    }


   function userDetails (address userAddress) public view returns (bool, bool, bool, uint256, uint256) {
       
    return (fcfsParticipant[userAddress], isParticipant[userAddress], gleanWhiteListedUsers[userAddress], allParticipants[userAddress], amountAllowed[userAddress]);   
       
   } 


   function generalStats () public view returns (bool,uint256,uint256, uint256) {
       
      
    return (SaleOpenForEveryone, totalInvestment, totalUsdtExpected, totalNoOfInvestors);   
       
       
   } 
 

    function transferAnyERC20Token(address tokenAddress, uint tokens) external whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        return IERC20(tokenAddress).transfer(owner, tokens);
    }





}