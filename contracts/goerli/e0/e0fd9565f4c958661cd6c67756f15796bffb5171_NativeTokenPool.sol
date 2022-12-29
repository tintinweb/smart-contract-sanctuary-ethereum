/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/token/ERC20/NativeTokenPool.sol

pragma solidity 0.8.13;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}



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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface PoolInterface {
  error ExceedsTokenLimit(uint256 currentLimit, uint256 requested);
  error PermissionsError();

  /**
   * @notice Lock or burn the token in the pool
   * @param amount Amount to lock or burn
   * @dev only called by onRamp
   */
  function lockOrBurn(uint256 amount) external;

  /**
   * @notice Release or mint tokens fromm the pool to the recipient
   * @param recipient Recipient address
   * @param amount Amount to release or mint to the recipient
   * @dev only called by offRamp
   */
  function releaseOrMint(address recipient, uint256 amount) external;

  function getToken() external view returns (IERC20 token);
}

/**
 * @notice Base abstract class with common functions for all token pools
 */
abstract contract TokenPool is PoolInterface, Ownable {
  IERC20 internal immutable i_token;
  mapping(address => bool) internal s_onRamps;
  mapping(address => bool) internal s_offRamps;

  constructor(IERC20 token) {
    i_token = token;
  }

  /**
   * @notice Set an onRamp's permissions
   * @dev Only callable by the owner
   * @param onRamp The onRamp
   * @param permission Whether or not the onRamp has onRamp permissions on this contract
   */
  function setOnRamp(address onRamp, bool permission) public onlyOwner {
    s_onRamps[onRamp] = permission;
  }

  /**
   * @notice Set an offRamp's permissions
   * @dev Only callable by the owner
   * @param offRamp The offRamp
   * @param permission Whether or not the offRamp has offRamp permissions on this contract
   */
  function setOffRamp(address offRamp, bool permission) public onlyOwner {
    s_offRamps[offRamp] = permission;
  }

  /**
   * @notice Checks whether something is a permissioned onRamp on this contract
   * @return boolean
   */
  function isOnRamp(address onRamp) public view returns (bool) {
    return s_onRamps[onRamp];
  }

  /**
   * @notice Checks whether something is a permissioned offRamp on this contract
   * @return boolean
   */
  function isOffRamp(address offRamp) public view returns (bool) {
    return s_offRamps[offRamp];
  }

  /**
   * @notice Gets the underlying token
   * @return token
   */
  function getToken() public view override returns (IERC20 token) {
    return i_token;
  }

  /**
   * @notice Checks whether the msg.sender is either the owner, or a permissioned onRamp on this contract
   * @dev Reverts with a PermissionsError if check fails
   */
  function _validateOwnerOrOnRamp() internal view {
    if (msg.sender != owner() && !isOnRamp(msg.sender)) revert PermissionsError();
  }

  /**
   * @notice Checks whether the msg.sender is either the owner, or a permissioned offRamp on this contract
   * @dev Reverts with a PermissionsError if check fails
   */
  function _validateOwnerOrOffRamp() internal view {
    if (msg.sender != owner() && !isOffRamp(msg.sender)) revert PermissionsError();
  }

  /**
   * @notice Check permissions and limits of a lock or burn
   */
  modifier assertLockOrBurn() {
    _validateOwnerOrOnRamp();
    _;
  }

  /**
   * @notice Check permissions and limits of a lock or burn
   */
  modifier assertReleaseOrMint() {
    _validateOwnerOrOffRamp();
    _;
  }
}

contract NativeTokenPool is TokenPool {
  event Moved(address indexed sender, uint256 amount);
  event Locked(address indexed sender, uint256 amount);
  event Released(address indexed sender, address indexed recipient, uint256 amount);

  constructor(address token) TokenPool(IERC20(token)) {}

  /**
   * @notice Locks the token in the pool
   * @param amount Amount to lock
   */
  function lockOrBurn(uint256 amount) external override assertLockOrBurn {
    getToken().transferFrom(msg.sender, address(this), amount); // moves the assets from user.
    emit Locked(msg.sender, amount);
  }

  /**
   * @notice Move tokens out of this pool in case we need them.
   * @param amount Amount to move out.
   */
  function moveTokens(uint256 amount) external onlyOwner {
    getToken().transfer(msg.sender, amount);
    emit Moved(msg.sender, amount);
  }

  /**
   * @notice Release tokens fromm the pool to the recipient
   * @param recipient Recipient address
   * @param amount Amount to release
   */
  function releaseOrMint(address recipient, uint256 amount) external override assertReleaseOrMint {
    getToken().transfer(recipient, amount);
    emit Released(msg.sender, recipient, amount);
  }
}