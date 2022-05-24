pragma solidity 0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IV3Pool.sol';

contract V4Migration is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  address public oceanAddress;
  address public OPFWallet;

  uint256 internal BASE = 1e18;
  uint256 public lockWindow = 1814400; // used for quick test, will be 1 month, number of blocks

  constructor(
    address _oceanAddress,
    address _OPFWallet,
    uint256 _lockWindow
  ) {
    require(_oceanAddress != address(0), 'Ocean Address cannot be address(0)');
    require(_OPFWallet != address(0), '_OPFWallet cannot be address(0)');
    oceanAddress = _oceanAddress;
    OPFWallet = _OPFWallet;
    lockWindow = _lockWindow;
  }

  enum migrationStatus {
    notStarted,
    allowed,
    completed
  }

  struct PoolShares {
    address owner;
    uint256 shares;
  }
  struct PoolStatus {
    migrationStatus status;
    address poolV3Address;
    address dtV3Address;
    address owner;
    PoolShares[] poolShares;
    uint256 lps;
    uint256 totalSharesLocked;
    uint256 totalOcean;
    uint256 totalDTBurnt;
    uint256 deadline;
  }

  event SharesAdded(
    address poolAddress,
    address user,
    uint256 lockedShares,
    uint256 blockNo
  );
  event Started(address poolAddress, uint256 blockNo, address caller);
  event Completed(address poolAddress, address caller, uint256 blockNo);

  mapping(address => PoolStatus) private pool;

  /**
   * @dev startMigration
   *      Starts migration process for a pool
   * @param _dtAddress datatoken address
   * @param _poolAddress pool address
   */
  function startMigration(address _dtAddress, address _poolAddress)
    external
    nonReentrant
  {
    require(
      uint256(pool[_poolAddress].status) == 0,
      'Migration process has already been started'
    );

    require(
      IV3Pool(_poolAddress).isBound(_dtAddress),
      'Datatoken is not bound'
    );
    require(
      IV3Pool(_poolAddress).isBound(oceanAddress),
      'OCEAN token is not bound'
    );
    // Start the migration process for an asset.
    PoolStatus storage newPool = pool[_poolAddress];
    newPool.status = migrationStatus.allowed;
    newPool.poolV3Address = _poolAddress;
    newPool.dtV3Address = _dtAddress;
    newPool.owner = IV3Pool(_poolAddress).getController();
    newPool.lps = 0;
    newPool.totalSharesLocked = 0;
    newPool.totalOcean = 0;
    newPool.totalDTBurnt = 0;
    newPool.deadline = block.timestamp.add(lockWindow);
    emit Started(_poolAddress, block.number, msg.sender);
  }

  /**
   * @dev addShares
   *      Called by user in order to lock some pool shares.
   * @param _poolAddress pool address
   * @param noOfShares number of shares
   */
  function addShares(address _poolAddress, uint256 noOfShares)
    external
    nonReentrant
  {
    require(noOfShares > 0, 'Adding zero shares is not allowed');
    // Check that the Migration is allowed
    require(
      canAddShares(_poolAddress) == true,
      'Adding shares is not currently allowed'
    );
    uint256 LPBalance = IERC20(_poolAddress).balanceOf(msg.sender);
    require(LPBalance == noOfShares, 'All shares must be locked');
    //loop trough poolShareOwners to see if we already have shares from this user
    uint256 currentShares = 0;
    uint256 i;
    for (i = 0; i < pool[_poolAddress].poolShares.length; i++) {
      if (pool[_poolAddress].poolShares[i].owner == msg.sender) {
        currentShares = pool[_poolAddress].poolShares[i].shares;
        break;
      }
    }
    require(currentShares == 0, 'You already have locked shares');
    // does a transferFrom for LP's shares. requires prior approval.
    require(
      IERC20(_poolAddress).transferFrom(msg.sender, address(this), noOfShares),
      'Failed to transfer shares'
    );

    //add new record, user has not transfered any shares so far
    PoolShares memory newEntry;
    newEntry.owner = msg.sender;
    newEntry.shares = noOfShares;
    pool[_poolAddress].poolShares.push(newEntry);
    pool[_poolAddress].lps++;
    pool[_poolAddress].totalSharesLocked += noOfShares;
    emit SharesAdded(_poolAddress, msg.sender, noOfShares, block.number);
  }

  /**
   * @dev getPoolStatus
   *      Returns pool status
   * @param poolAddress pool Address
   * @return PoolStatus
   */
  function getPoolStatus(address poolAddress)
    external
    view
    returns (PoolStatus memory)
  {
    return (pool[poolAddress]);
  }

  /**
   * @dev getPoolShares
   *      Returns a list of users and coresponding locked shares, using pagination
   *      Use start = 0 , end = 2^256 for default values, but your RPC provider might complain
   * @param _poolAddress pool Address
   * @param start start from index
   * @param end until index
   * @return PoolShares[]
   */
  function getPoolShares(
    address _poolAddress,
    uint256 start,
    uint256 end
  ) external view returns (PoolShares[] memory) {
    uint256 counter = 0;
    uint256 i;
    for (i = start; i < pool[_poolAddress].poolShares.length || i > end; i++) {
      if (pool[_poolAddress].poolShares[i].owner != address(0)) counter++;
    }
    // since it's not possible to return dynamic length array
    // we need to count first, create the array using fixed length and then fill it
    PoolShares[] memory poolShares = new PoolShares[](counter);
    counter = 0;
    for (i = start; i < pool[_poolAddress].poolShares.length || i > end; i++) {
      if (pool[_poolAddress].poolShares[i].owner != address(0)) {
        poolShares[counter].owner = pool[_poolAddress].poolShares[i].owner;
        poolShares[counter].shares = pool[_poolAddress].poolShares[i].shares;
        counter++;
      }
    }
    return (poolShares);
  }

  /**
   * @dev getPoolSharesforUser
   *      Returns amount of pool shares locked by a user for a pool
   * @param _owner user address
   * @param _poolAddress pool Address
   * @return uint256
   */
  function getPoolSharesforUser(address _poolAddress, address _owner)
    external
    view
    returns (uint256)
  {
    uint256 i;
    for (i = 0; i < pool[_poolAddress].poolShares.length; i++) {
      if (pool[_poolAddress].poolShares[i].owner == _owner)
        return (pool[_poolAddress].poolShares[i].shares);
    }
    return (0);
  }

  /**
   * @dev canAddShares
   *      Checks if user can lock poolshares
   * @param _poolAddress pool Address
   * @return boolean
   */
  function canAddShares(address _poolAddress) public view returns (bool) {
    if (pool[_poolAddress].status == migrationStatus.allowed) return true;
    return false;
  }

  /**
   * @dev thresholdMet
   *      Checks if the threshold is met for a pool
   * @param poolAddress pool Address
   * @return boolean
   */
  function thresholdMet(address poolAddress) public view returns (bool) {
    if (pool[poolAddress].status != migrationStatus.allowed) return false;
    uint256 totalLP = IERC20(poolAddress).balanceOf(address(this));
    if (totalLP == 0) {
      return false;
    }
    uint256 totalLPSupply = IERC20(poolAddress).totalSupply();

    if (totalLPSupply.mul(BASE).div(totalLP) <= 1.25 ether) {
      return true;
    } else return false;
  }

  /**
     * @dev liquidate
     *      Liquidates a pool and sends OCEAN to OPF
     * @param poolAddress pool Address
     * @param minAmountsOut array of minimum amount of tokens expected 
          (see https://github.com/oceanprotocol/contracts/blob/main/contracts/balancer/BPool.sol#L519)
     */
  function liquidate(address poolAddress, uint256[] calldata minAmountsOut)
    external
    nonReentrant
  {
    require(
      pool[poolAddress].status == migrationStatus.allowed,
      'Current pool status does not allow to liquidate Pool'
    );
    // uint256 totalLPSupply = IERC20(poolAddress).totalSupply();
    /*require(
      thresholdMet(poolAddress) || pool[poolAddress].deadline < block.timestamp,
      'Threshold or deadline not met'
    ); // 80% of total LP required
    */
    require(
      pool[poolAddress].deadline < block.timestamp,
      'Threshold or deadline not met'
    ); // 80% of total LP required
    require(
      pool[poolAddress].totalSharesLocked > 0,
      'Cannot liquidate 0 shares'
    );
    uint256 oceanBalance = IERC20(oceanAddress).balanceOf(address(this));
    // we update the status
    pool[poolAddress].status = migrationStatus.completed;
    // - Withdraws all pool shares from V3 pool in one call (all shares at once, not per user)
    IV3Pool(poolAddress).exitPool(
      pool[poolAddress].totalSharesLocked,
      minAmountsOut
    );
    require(
      IERC20(poolAddress).balanceOf(address(this)) == 0,
      'Failed to redeem all LPTs'
    );

    // Store values for pool status
    pool[poolAddress].totalDTBurnt = IERC20(pool[poolAddress].dtV3Address)
      .balanceOf(address(this));
    uint256 newOceanBalance = IERC20(oceanAddress).balanceOf(address(this));
    pool[poolAddress].totalOcean = newOceanBalance.sub(oceanBalance);

    // - Burns all DTs
    require(
      IERC20(pool[poolAddress].dtV3Address).transfer(
        address(1),
        pool[poolAddress].totalDTBurnt
      ),
      'Failed to burn v3 DTs'
    );
    // send OCEAN to OPF
    require(
      IERC20(oceanAddress).transfer(OPFWallet, pool[poolAddress].totalOcean),
      'Failed to transfer OCEAN to OPF'
    );

    emit Completed(poolAddress, msg.sender, block.number);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity 0.8.12;

// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0
interface IV3Pool {
  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external;

  function getController() external view returns (address);

  function isBound(address t) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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