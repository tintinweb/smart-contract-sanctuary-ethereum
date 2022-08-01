// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EtherDisperser is Ownable {
  /// @notice Addresses which will be able to claim their ether rewards
  address[] public targets;

  /// @notice Amounts of ether each address can claim
  uint256[] public amounts;

  /// @notice Mapping from address to amount of ether they can claim
  mapping(address => uint256) public balances;

  /// @notice An event emitted when ether gets deposited to the contract
  event Deposit(address indexed sender, uint256 amount);

  /// @notice An event emitted when the balance for a particular address is set
  event SetBalance(address indexed target, uint256 balance);

  /// @notice An event emitted when a particular address claims their ether rewards
  event Claim(address indexed target, uint256 amount);

  constructor() {}

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  /**
   * @notice Sets the claimable ETH balances of the contest winners
   * @param _targets address[] memory
   * @param _amounts uint256[] memory
   * @dev Only owner can call it
   */
  function updateBalances(address[] memory _targets, uint256[] memory _amounts) external onlyOwner {
    require(_targets.length == _amounts.length, "EtherDisperser: Targets and amounts must be the same length.");
    require(_targets.length > 0, "EtherDisperser: Targets must be non-empty.");
    require(_amounts.length > 0, "EtherDisperser: Amounts must be non-empty.");

    targets = _targets;
    amounts = _amounts;

    for (uint256 i = 0; i < targets.length; i++) {
      balances[targets[i]] = amounts[i];
      emit SetBalance(targets[i], amounts[i]);
    }
  }

  /**
   * @notice Allows users to claim their ETH rewards
   * @dev Only users that won rewards can claim them
   */
  function claim() external {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "EtherDisperser: You have no ether to withdraw.");

    balances[msg.sender] = 0;

    (bool sent, ) = msg.sender.call{value: userBalance}("");
    require(sent, "EtherDisperser: Could not send ether to you.");

    emit Claim(msg.sender, userBalance);
  }

  /// @notice Returns the target addresses of the contest winners
  function getTargets() external view returns (address[] memory) {
    return targets;
  }

  /// @notice Returns the claimable ether balances of the contest winners
  function getAmounts() external view returns (uint256[] memory) {
    return amounts;
  }

  /**
   * @notice Added to support recovering ether trapped in the contract
   * @dev Only owner can call it
   */
  function recoverEther() external onlyOwner {
    (bool sent, ) = owner().call{value: address(this).balance}("");
    require(sent, "EtherDisperser: Couldn't send ether to you.");
  }

  /**
   * @notice Added to support recovering ERC20 tokens trapped in the contract
   * @param _tokenAddress address
   * @dev Only owner can call it
   */
  function recoverERC20(address _tokenAddress) external onlyOwner {
    IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
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