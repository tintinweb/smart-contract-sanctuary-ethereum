/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// File: contracts/SafeMath.sol



pragma solidity >= 0.8.0 < 9.0.0;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/UpstreamMultisig.sol


pragma solidity 0.8.17;




/**
* @author Horizon Globex GmbH on behalf of https://upstream.exchange/
*
* @notice (i) This is the Upstream USDC hot-wallet cryptocurrency-bridge contract that accepts Upstream user's
*         USDC transfers-in and mints 1-for-1 the corresponding amount of US Dollars on Upstream for trading.
*
*         (ii) This contract also allows an Upstream user to withdraw their US Dollar funds back to USDC.
*
*         The fees parameter associated with each multisig withdrawal approval-step is the gas-cost in Eth
*         of the confirmation transactions which the user pays at the end when completing their withdrawal.
*         That is, Upstream multisig-wallets used for withdrawals pay the gas up-front and the user reimburses
*         that amount at the end, making the entire process a net zero cost for Upstream, with no USDC
*         withdrawal fees for the user.
*/
contract UpstreamMultisig is Ownable {
    using SafeMath for uint256;

  /**
   * @notice The type used to track withdrawal requests.
   */
  struct Withdrawal {
    uint256 amount;
    uint256 fee; // in wei (ETH)
    
    // 2 of the 4 potential signers is enough
    address signer1;
    address signer2;
  }

  /**
   * @notice The well-known public USDC contract.
   *
   * @dev During dev/test an ERC20 contract will be created to act like this contract, that
   *      is why it is not hard-coded.  But once the address is set it can't change.
   */
  IERC20Metadata public usdc;

  /**
   * @notice Upstream wallet that is used to create Withdrawal objects and to move
   *         Eth to back signer wallets so they can keep signing transactions.
   */
  address public upstreamWallet;

  // The full set of all signers, only 2 are needed to complete a withdrawal.
  address public signer1;
  address public signer2;
  address public signer3;
  address public signer4;

  function decimals() public view returns (uint256) {
    return usdc.decimals();
  }

  /**
   * The current limit for each approval account.  For larger withdrawals
   * the limits will be temporarily increased before being reduced back to
   * a smaller/safer limit.  This process requires back office coordination.
   */
  mapping (address => uint256) public limits;

  /**
   * @notice The collection of all pending withdrawals, only one can be active
   *         per wallet at a time.
   */
  mapping (address => Withdrawal) public withdrawals;

  modifier onlyUpstream {
    require(_msgSender() == upstreamWallet, "You are not Upstream.");
    _;
  }

  // The three events to cover the lifecycle of a withdrawal.  Approved happens for
  // each approver, in this contract that will be at least twice.
  event WithdrawalCreated(address indexed who, uint256 quantity, uint256 fee);
  event WithdrawalApproved(address indexed who, address indexed approver, uint256 fee);
  event WithdrawalComplete(address indexed who, uint256 quantity, uint256 fee);
  event WithdrawalCancelled(address indexed who);

  /**
   * @notice Create an instance of this contract.
   *
   * @param usdcAddress The address of the well-known USDC contract, cannot be changed after contract creation.
   * @param upstream Initial Upstream wallet used to initiate the withdrawal.
   * @param addr1 The first address that can approve a withdrawal.
   * @param addr2 The second address that can approve a withdrawal.
   * @param addr3 The third address that can approve a withdrawal.
   * @param addr4 The fourth address that can approve a withdrawal.
   */
  constructor(address usdcAddress, address upstream, address addr1, address addr2, address addr3, address addr4) {
    usdc = IERC20Metadata(usdcAddress);
    upstreamWallet = upstream;

    signer1 = addr1;
    limits[signer1] = 500 * (10**usdc.decimals());

    signer2 = addr2;
    limits[signer2] = 500  * (10**usdc.decimals());
    
    signer3 = addr3;
    limits[signer3] = 500  * (10**usdc.decimals());

    signer4 = addr4;
    limits[signer4] = 500  * (10**usdc.decimals());
  }

  /**
   * @param addr The new address to give the Upstream wallet.
   */
  function setUpstreamWallet(address addr) external onlyOwner
  {
    upstreamWallet = addr;
  }

  /**
   * @param addr The new address to give the first approval wallet.
   * @param limit The approval limit for this account.
   *
   * @dev No need to protect against duplicate addresses, the logic of the other functions
   *      prevents a single wallet fully approving a withdrawal.
   */
  function setSigner1(address addr, uint256 limit) external onlyOwner
  {
    signer1 = addr;
    limits[signer1] = limit;
  }

  /**
   * @param addr The new address to give the second approval wallet.
   * @param limit The approval limit for this account.
   */
  function setSigner2(address addr, uint256 limit) external onlyOwner
  {
    signer2 = addr;
    limits[signer2] = limit;
  }

  /**
   * @param addr The new address to give the third approval wallet.
   * @param limit The approval limit for this account.
   */
  function setSigner3(address addr, uint256 limit) external onlyOwner
  {
    signer3 = addr;
    limits[signer3] = limit;
  }

  /**
   * @param addr The new address to give the fourth approval wallet.
   * @param limit The approval limit for this account.
   */
  function setSigner4(address addr, uint256 limit) external onlyOwner
  {
    signer4 = addr;
    limits[signer4] = limit;
  }

  /**
   * @notice Get the withdrawal amount pending for the caller.
   */
  function getAmount() public view returns (uint256) {
    return getAmountFor(_msgSender());
  }

  /**
   * @notice Get the withdrawal amount pending for the specified address.
   */
  function getAmountFor(address payee) public view returns (uint256) {
    require(withdrawals[payee].amount != 0, "No withdrawal pending.");
    Withdrawal memory withdrawal = withdrawals[payee];
    return withdrawal.amount;
  }

  /**
   * @notice Get the withdrawal fee pending for the caller.
   */
  function getFee() public view returns (uint256) {
    return getFeeFor(_msgSender());
  }

  /**
   * @notice Get the withdrawal fee pending for the specified address.
   */
  function getFeeFor(address payee) public view returns (uint256) {
    require(withdrawals[payee].amount != 0, "No withdrawal pending.");
    Withdrawal memory withdrawal = withdrawals[payee];
    return withdrawal.fee;
  }

  /**
   * @notice Get the number of approvals remaining before the withdrawal can complete
   *         for the current wallet.
   */
  function getRemainingConfirmations() public view returns (uint256) {
    return getRemainingConfirmationsFor(_msgSender());
  }

  /**
   * @notice Get the number of approvals remaining before the withdrawal can complete
   *         for the specified wallet.
   */
  function getRemainingConfirmationsFor(address payee) public view returns (uint256) {
    require(withdrawals[payee].amount != 0, "No withdrawal pending.");

    Withdrawal memory withdrawal = withdrawals[payee];
    if (withdrawal.signer1 == address(0)) return 2;
    if (withdrawal.signer2 == address(0)) return 1;
    return 0;
  }

  /**
   * @notice Create a new withdrawal for the payee.  One must not already exist (no overwrite
   *         and no multiple withdrawals in parallel).
   *
   * @param payee The recipient of the withdrawal.
   * @param amount The amount of USDC to withdraw.
   * @param fee The Eth transaction cost (gas Gwei * gas used) to create this withdrawal.
   */
  function createWithdrawal(address payee, uint256 amount, uint256 fee) external onlyUpstream {
    require(withdrawals[payee].amount == 0, "One payment to a payee at a time.");
    require(amount > 0, "Invalid amount.");
    require(fee > 0, "Invalid fee.");

    withdrawals[payee] = Withdrawal(amount, fee, address(0), address(0));

    emit WithdrawalCreated(payee, amount, fee);
  }  

  /**
   * @notice One of the four multisig wallets confirms that this is a valid withdrawal.
   *         Only after two separate multisig wallets confirm will user be able to withdraw USDC.
   *
   * @param payee The address performing the withdrawal.
   * @param fee The Eth transaction cost (gas Gwei * gas used) to confirm this withdrawal.
   */
  function confirm(address payee, uint256 fee) external {
    require(_msgSender() == signer1 || _msgSender() == signer2 ||
            _msgSender() == signer3 || _msgSender() == signer4, "Invalid approver.");
    require(withdrawals[payee].amount != 0, "No withdrawal pending.");
    Withdrawal memory withdrawal = withdrawals[payee];
    require(limits[_msgSender()] >= withdrawal.amount, "Amount above approval limit.");
    require(withdrawal.signer1 == address(0) || withdrawal.signer2 == address(0), "Withdrawal already confirmed.");
    require(fee > 0, "Invalid fee.");

    if (withdrawal.signer1 == address(0)) {
      withdrawals[payee].signer1 = _msgSender();
    } else if (withdrawal.signer1 == _msgSender()) {
      revert("Address already approved this withdrawal.");
    } else if (withdrawal.signer2 == address(0)) {
      withdrawals[payee].signer2 = _msgSender();
    }
    withdrawals[payee].fee = withdrawals[payee].fee.add(fee);
    
    emit WithdrawalApproved(payee, _msgSender(), fee);
  }

  /**
   * @notice The user completes the withdrawal after 2 multisigs.
   *
   * @dev Note the fee is paid directly by the caller, not subtracted from the amount to protect
   *      the user from excessive fees.
   */
  function withdraw() external payable {
    require(withdrawals[_msgSender()].amount != 0, "No withdrawal pending.");
    Withdrawal memory withdrawal = withdrawals[_msgSender()];
    require(withdrawal.signer1 != address(0) && withdrawal.signer2 != address(0), "Pending confirmation.");
    require(msg.value >= withdrawal.fee, "Insufficient fee.");
    require(usdc.balanceOf(address(this)) >= withdrawal.amount, "Insufficient USDC, please try later.");

    uint256 amount = withdrawal.amount;
    withdrawals[_msgSender()] = Withdrawal(0, 0, address(0), address(0));
    usdc.transfer(_msgSender(), amount);

    emit WithdrawalComplete(_msgSender(), amount, withdrawal.fee);
  }

  /**
   * @notice Cancel a pending withdrawal.  Upstream back-office admin function.
   *
   * @param payee The address of the payee having the withdrawal cancelled.
   */
  function cancel(address payee) external onlyUpstream {
    require(withdrawals[payee].amount != 0, "No withdrawal pending.");

    withdrawals[payee] = Withdrawal(0, 0, address(0), address(0));

    emit WithdrawalCancelled(payee);
  }

  /**
   * @notice Transfer the paid-in Eth fees back out to signers wallets.
   *
   * @param to The address to send the Ether from this contract to.
   * @param amount The amount of Eth to transfer.
   */
  function transfer(address payable to, uint256 amount) external onlyUpstream { 
     to.transfer(amount);
  }  
}