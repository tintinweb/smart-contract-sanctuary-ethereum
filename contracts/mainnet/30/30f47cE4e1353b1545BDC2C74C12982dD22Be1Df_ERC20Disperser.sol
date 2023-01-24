// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ERC20Disperser is Ownable {
  /// @notice The address of the MAJR ERC20 token
  address public immutable majrErc20Token;

  /// @notice The total amount of tokens that has been rewarded since the start of the MAJR flights
  uint256 public totalTokensRewarded;

  /// @notice The amount of tokens that's left to be claimed by the current contest winners
  uint256 public leftToBeClaimed;

  /// @notice Mapping from address to amount of tokens they can claim
  mapping(address => uint256) public balances;

  /// @notice An event emitted when tokens get deposited to the contract
  event Deposit(address indexed sender, uint256 amount);

  /// @notice An event emitted when the balance for a particular address is updated
  event SetBalance(address indexed target, uint256 balance);

  /// @notice An event emitted when a particular address claims their token rewards
  event Claim(address indexed target, uint256 amount);

  /**
   * @notice Constructor
   * @param _majrErc20Token address
   */
  constructor(address _majrErc20Token) {
    majrErc20Token = _majrErc20Token;
  }

  /**
   * @notice Sets the claimable token balances of the contest winners and makes sure that the contract has enough tokens to support all the claims by the contest winners
   * @param _targets address[] calldata
   * @param _amounts uint256[] calldata
   * @dev Only owner can call it
   */
  function addBalances(
    address[] calldata _targets,
    uint256[] calldata _amounts
  ) external onlyOwner {
    require(
      _targets.length == _amounts.length,
      "ERC20Disperser: Targets and amounts must be of the same length."
    );
    require(_targets.length > 0, "ERC20Disperser: Targets must be non-empty.");

    address _owner = owner();
    uint256 _totalTokenAmount = _getTotalTokenAmount(_amounts);
    require(
      IERC20(majrErc20Token).balanceOf(_owner) >= _totalTokenAmount,
      "ERC20Disperser: Not enough token balance for the contest winners to be claimed."
    );

    totalTokensRewarded += _totalTokenAmount;
    leftToBeClaimed += _totalTokenAmount;

    bool sent = IERC20(majrErc20Token).transferFrom(
      _owner,
      address(this),
      _totalTokenAmount
    );
    require(
      sent,
      "ERC20Disperser: Failed to transfer tokens from the owner to the disperser contract."
    );

    emit Deposit(_owner, _totalTokenAmount);

    for (uint256 i = 0; i < _targets.length; i++) {
      balances[_targets[i]] += _amounts[i];
      emit SetBalance(_targets[i], balances[_targets[i]]);
    }
  }

  /**
   * @notice Sets the claimable balances of the addresses added by mistake to 0 and returns their respective claimable token balances back to the owner
   * @param _targets address[] calldata
   * @dev Only owner can call it
   */
  function removeBalances(address[] calldata _targets) external onlyOwner {
    require(_targets.length > 0, "ERC20Disperser: Targets must be non-empty.");

    address _owner = owner();

    for (uint256 i = 0; i < _targets.length; i++) {
      uint256 _balance = balances[_targets[i]];

      totalTokensRewarded -= _balance;
      leftToBeClaimed -= _balance;

      bool sent = IERC20(majrErc20Token).transfer(_owner, _balance);
      require(sent, "ERC20Disperser: Couldn't send tokens to you.");

      balances[_targets[i]] = 0;
      emit SetBalance(_targets[i], 0);
    }
  }

  /**
   * @notice Allows users to claim their token rewards
   * @dev Only users that won rewards can claim them and only when the token is transferable
   */
  function claim() external {
    uint256 _userBalance = balances[msg.sender];
    require(_userBalance > 0, "ERC20Disperser: You have no tokens to claim.");

    balances[msg.sender] = 0;
    leftToBeClaimed -= _userBalance;

    bool sent = IERC20(majrErc20Token).transfer(msg.sender, _userBalance);
    require(sent, "ERC20Disperser: Couldn't send tokens to you.");

    emit Claim(msg.sender, _userBalance);
  }

  /**
   * @notice Added to support recovering the excess tokens trapped in the contract (i.e. tokens that were not awarded to any contest winner or were transferred to the contract by mistake)
   * @dev Only owner can call it
   */
  function recoverTokens() external onlyOwner {
    uint256 _amount = IERC20(majrErc20Token).balanceOf(address(this)) -
      leftToBeClaimed;
    require(_amount > 0, "ERC20Disperser: No tokens to be recovered.");

    bool sent = IERC20(majrErc20Token).transfer(owner(), _amount);
    require(sent, "ERC20Disperser: Couldn't send tokens to you.");
  }

  /**
   * @notice Gets the total amount from the array of different amounts
   * @param _amounts uint256[] calldata
   * @return uint256
   * @dev Internal utility function used in the addBalances method
   */
  function _getTotalTokenAmount(
    uint256[] calldata _amounts
  ) internal pure returns (uint256) {
    uint256 total;

    for (uint256 i = 0; i < _amounts.length; i++) {
      total += _amounts[i];
    }

    return total;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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