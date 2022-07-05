// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './base/BaseStrategy.sol';

import '../interfaces/euler/IEulerEToken.sol';

// This contract contains logic for depositing staker funds into Euler as a yield strategy
// https://docs.euler.finance/developers/integration-guide#deposit-and-withdraw

// EUL rewards are not integrated as it's only for accounts that borrow.
// We don't borrow in this strategy.

contract EulerStrategy is BaseStrategy {
  using SafeERC20 for IERC20;

  // Sub account used for Euler interactions
  uint256 private constant SUB_ACCOUNT = 0;

  // https://docs.euler.finance/protocol/addresses
  address public constant EULER = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
  // https://github.com/euler-xyz/euler-contracts/blob/master/contracts/modules/EToken.sol
  IEulerEToken public constant EUSDC = IEulerEToken(0xEb91861f8A4e1C12333F42DCE8fB0Ecdc28dA716);

  /// @param _initialParent Contract that will be the parent in the tree structure
  constructor(IMaster _initialParent) BaseNode(_initialParent) {
    // Approve Euler max amount of USDC
    want.safeIncreaseAllowance(EULER, type(uint256).max);
  }

  /// @notice Signal if strategy is ready to be used
  /// @return Boolean indicating if strategy is ready
  function setupCompleted() external view override returns (bool) {
    return true;
  }

  /// @notice View the current balance of this strategy in USDC
  /// @dev Will return wrong balance if this contract somehow has USDC instead of only eUSDC
  /// @return Amount of USDC in this strategy
  function _balanceOf() internal view override returns (uint256) {
    return EUSDC.balanceOfUnderlying(address(this));
  }

  /// @notice Deposit all USDC in this contract in Euler
  /// @notice Works under the assumption this contract contains USDC
  function _deposit() internal override whenNotPaused {
    // Deposit all current balance into euler
    // https://github.com/euler-xyz/euler-contracts/blob/master/contracts/modules/EToken.sol#L148
    EUSDC.deposit(SUB_ACCOUNT, type(uint256).max);
  }

  /// @notice Withdraw all USDC from Euler and send all USDC in contract to core
  /// @return amount Amount of USDC withdrawn
  function _withdrawAll() internal override returns (uint256 amount) {
    // If eUSDC.balanceOf(this) != 0, we can start to withdraw the eUSDC
    if (EUSDC.balanceOf(address(this)) != 0) {
      // Withdraw all underlying using max, this will translate to the full balance
      // https://github.com/euler-xyz/euler-contracts/blob/master/contracts/BaseLogic.sol#L387
      EUSDC.withdraw(SUB_ACCOUNT, type(uint256).max);
    }

    // Amount of USDC in the contract
    // This can be >0 even if eUSDC balance = 0
    // As it could have been transferred to this contract by accident
    amount = want.balanceOf(address(this));
    // Transfer USDC to core
    if (amount != 0) want.safeTransfer(core, amount);
  }

  /// @notice Withdraw `_amount` USDC from Euler and send to core
  /// @param _amount Amount of USDC to withdraw
  function _withdraw(uint256 _amount) internal override {
    // Don't allow to withdraw max (reserved with withdrawAll call)
    if (_amount == type(uint256).max) revert InvalidArg();

    // Call withdraw with underlying amount of tokens (USDC instead of eUSDC)
    // https://github.com/euler-xyz/euler-contracts/blob/master/contracts/modules/EToken.sol#L177
    EUSDC.withdraw(SUB_ACCOUNT, _amount);

    // Transfer USDC to core
    want.safeTransfer(core, _amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../../interfaces/strategy/INode.sol';
import '../../interfaces/strategy/IStrategy.sol';
import './BaseNode.sol';

abstract contract BaseStrategy is IStrategy, BaseNode, Pausable {
  using SafeERC20 for IERC20;

  /// @dev Return balance of this strategy
  function prepareBalanceCache() external override onlyParent returns (uint256) {
    return _balanceOf();
  }

  /// @dev No cache is used in strategies
  function expireBalanceCache() external override onlyParent {}

  function pause() external virtual onlyOwner {
    _pause();
  }

  function unpause() external virtual onlyOwner {
    _unpause();
  }

  function remove() external virtual override onlyOwner {
    _withdrawAll();
    if (_balanceOf() != 0) revert NonZeroBalance();
    parent.childRemoved();
  }

  function replace(INode _newNode) external virtual override onlyOwner {
    _withdrawAll();
    if (_balanceOf() != 0) revert NonZeroBalance();
    _replace(_newNode);
  }

  function replaceForce(INode _newNode) external virtual override onlyOwner {
    _replace(_newNode);
    emit ForceReplace();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IEulerEToken {
  function balanceOfUnderlying(address account) external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function withdraw(uint256 subAccountId, uint256 amount) external;

  function deposit(uint256 subAccountId, uint256 amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface INode {
  event AdminWithdraw(uint256 amount);
  event ReplaceAsChild();
  event ParentUpdate(IMaster previous, IMaster current);
  event Obsolete(INode implementation);
  event ForceReplace();
  event Replace(INode newAddress);

  error NotImplemented(bytes4 func);
  error SenderNotParent();
  error SenderNotChild();
  error InvalidParent();
  error InvalidCore();
  error InvalidWant();
  error InvalidState();
  error ZeroArg();
  error InvalidArg();
  error NotSetup();
  error IsMaster();
  error BothChild();
  error NotChild();
  error InvalidParentAddress();
  error SetupNotCompleted(INode instance);
  error NonZeroBalance();

  /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR VARIABLES
  //////////////////////////////////////////////////////////////*/

  /// @return Returns the token type being deposited into a node
  function want() external view returns (IERC20);

  /// @notice Parent will always inherit IMaster interface.
  /// @notice Parent of root node will inherit IStrategyManager
  function parent() external view returns (IMaster);

  /// @notice View core controller of funds
  function core() external view returns (address);

  /*//////////////////////////////////////////////////////////////
                        TREE STRUCTURE LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Replace the node
  /// @notice If this is executed on a strategy, the funds will be withdrawn
  /// @notice If this is executed on a splitter, the children are expected to be the same
  function replace(INode _node) external;

  /// @notice Replace the node
  /// @notice If this is executed on a strategy, attempt is made to withdraw the funds
  /// @notice If this is executed on a splitter, check of children is skipped
  function replaceForce(INode _node) external;

  function setupCompleted() external view returns (bool);

  /// @notice Move the current node as the child of `_node`
  function replaceAsChild(ISplitter _node) external;

  /// @notice Update parent of node
  /// @dev Can only be called by current parent
  function updateParent(IMaster _node) external;

  function siblingRemoved() external;

  /*//////////////////////////////////////////////////////////////
                        YIELD STRATEGY LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @return Returns the token balance managed by this contract
  /// @dev For Splitter this will be the sum of balances of the children
  function balanceOf() external view returns (uint256);

  /// @notice Withdraws all tokens back into core.
  /// @return The final amount withdrawn
  function withdrawAll() external returns (uint256);

  /// @notice Withdraws all token from the node back into core
  /// @return The final amount withdrawn
  function withdrawAllByAdmin() external returns (uint256);

  /// @notice Withdraws a specific amount of tokens from the node back into core
  /// @param _amount Amount of tokens to withdraw
  function withdraw(uint256 _amount) external;

  /// @notice Withdraws a specific amount of tokens from the node back into core
  /// @param _amount Amount of tokens to withdraw
  function withdrawByAdmin(uint256 _amount) external;

  /// @notice Deposits all tokens held in this contract into the children on strategy
  /// @dev Splitter will deposit the tokens in their children
  /// @dev Strategy will deposit the tokens into a yield strategy
  function deposit() external;

  function prepareBalanceCache() external returns (uint256);

  function expireBalanceCache() external;
}

interface IMaster is INode {
  event ChildOneUpdate(INode previous, INode current);

  /// @notice Call by child if it's needs to be updated
  function updateChild(INode _node) external;

  /// @notice Call by child if removed
  function childRemoved() external;

  function isMaster() external view returns (bool);

  function childOne() external view returns (INode);

  function setInitialChildOne(INode _child) external;
}

interface ISplitter is IMaster {
  event ChildTwoUpdate(INode previous, INode current);

  error InvalidChildOne();
  error InvalidChildTwo();

  function childTwo() external view returns (INode);

  function setInitialChildTwo(INode _child) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './INode.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStrategy is INode {
  /// @notice remove a strategy
  function remove() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../interfaces/strategy/INode.sol';

// Interface used by every node
abstract contract BaseNode is INode, Ownable {
  using SafeERC20 for IERC20;

  // Parent node
  IMaster public override parent;
  // Which token the strategy uses (USDC)
  IERC20 public immutable override want;
  // Reference to core (Sherlock.sol)
  address public immutable override core;

  /// @param _initialParent The initial parent of this node
  constructor(IMaster _initialParent) {
    if (address(_initialParent) == address(0)) revert ZeroArg();

    IERC20 _want = _initialParent.want();
    address _core = _initialParent.core();

    if (address(_want) == address(0)) revert InvalidWant();
    if (address(_core) == address(0)) revert InvalidCore();

    want = _want;
    core = _core;
    parent = _initialParent;

    emit ParentUpdate(IMaster(address(0)), _initialParent);
  }

  modifier onlyParent() {
    if (msg.sender != address(parent)) revert SenderNotParent();
    _;
  }

  /*//////////////////////////////////////////////////////////////
                        TREE STRUCTURE LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Replace this node to be a child of `_newParent`
  /// @param _newParent address of the new parent
  /// @dev Replace as child ensures that (this) is the child of the `_newParent`
  /// @dev It will also enfore a `_executeParentUpdate` to make that relation bi-directional
  /// @dev For the other child is does minimal checks, it only checks if it isn't the same as address(this)
  function replaceAsChild(ISplitter _newParent) external virtual override onlyOwner {
    /*
          m
          |
        this

          m
          |
          1
         / \
        z  this
    */

    // Gas savings
    IMaster _currentParent = parent;

    // Revert is parent is master
    // The master is always at the root of the tree
    if (_newParent.isMaster()) revert IsMaster();

    // Verify if the new parent has the right connections
    _verifyParentUpdate(_currentParent, _newParent);
    // Verify is childs of newParent are correct
    INode otherChild = _verifyNewParent(_newParent);

    // Revert if otherchild = 0
    // Revert if the other child has the right parent reference too
    // Check if `z` has the right parent (referencing comment on top function)
    if (otherChild.parent() != _newParent) revert InvalidParent();

    // Check if `_newParent` references our currentParent as their parent
    // Check if `m` == `1`.parent() (referencing comment on top function)
    if (_currentParent != _newParent.parent()) revert InvalidParent();

    // Make sure the parent recognizes the new child
    // Make sure `m` references `1` as it's child (referencing comment on top function)
    _currentParent.updateChild(_newParent);

    // Update parent
    _executeParentUpdate(_currentParent, _newParent);

    emit ReplaceAsChild();
  }

  /// @notice Replace parent of this node
  /// @param _newParent Address of the new parent
  /// @dev Only callable by current parent
  function updateParent(IMaster _newParent) external virtual override onlyParent {
    // Verify if the parent can be updated
    _verifyParentUpdate(IMaster(msg.sender), _newParent);
    _verifyNewParent(_newParent);

    // Update parent
    _executeParentUpdate(IMaster(msg.sender), _newParent);
  }

  /// @notice Get notified by parent that your sibling is removed
  /// @dev This contract will take the position of the parent
  /// @dev Only callable by current parent
  function siblingRemoved() external override onlyParent {
    // Get current parent of parent
    IMaster _newParent = parent.parent();

    // Take position of current parent
    _verifyParentUpdate(IMaster(msg.sender), _newParent);
    // NOTE: _verifyNewParent() is skipped on this call
    // As address(this) should be added as a child after the function returns
    _executeParentUpdate(IMaster(msg.sender), _newParent);
  }

  /// @notice Verify if `_newParent` is able to be our new parent
  /// @param _newParent Address of the new parent
  /// @return otherChild Address of the child that isn't address(this)
  function _verifyNewParent(IMaster _newParent) internal view returns (INode otherChild) {
    // The setup needs to be completed of parent
    if (_newParent.setupCompleted() == false) revert SetupNotCompleted(_newParent);

    // get first child
    INode firstChild = _newParent.childOne();
    INode secondChild;

    // is address(this) childOne?
    bool isFirstChild = address(firstChild) == address(this);
    bool isSecondChild = false;

    // Parent only has a childTwo if it isn't master
    if (!_newParent.isMaster()) {
      // get second child
      secondChild = ISplitter(address(_newParent)).childTwo();
      // is address(this) childTwo?
      isSecondChild = address(secondChild) == address(this);
    }

    // Check if address(this) is referenced as both childs
    if (isFirstChild && isSecondChild) revert BothChild();
    // Check if address(this) isn't referenced at all
    if (!isFirstChild && !isSecondChild) revert NotChild();

    // return child that isn't address(this)
    if (isFirstChild) {
      return secondChild;
    }
    return firstChild;
  }

  /// @notice Verify if `_newParent` can replace `_currentParent`
  /// @param _currentParent Address of our current `parent`
  /// @param _newParent Address of our future `parent`
  function _verifyParentUpdate(IMaster _currentParent, IMaster _newParent) internal view {
    // Revert if it's the same address
    if (address(_newParent) == address(this)) revert InvalidParentAddress();
    // Revert if the address is parent
    if (address(_newParent) == address(_currentParent)) revert InvalidParentAddress();
    // Revert if core is invalid
    if (_currentParent.core() != _newParent.core()) revert InvalidCore();
    // Revert if want is invalid
    if (_currentParent.want() != _newParent.want()) revert InvalidWant();
  }

  /// @notice Set parent in storage
  /// @param _currentParent Address of our current `parent`
  /// @param _newParent Address of our future `parent`
  function _executeParentUpdate(IMaster _currentParent, IMaster _newParent) internal {
    // Make `_newParent` our new parent
    parent = _newParent;
    emit ParentUpdate(_currentParent, _newParent);
  }

  /// @notice Replace address(this) with `_newNode`
  function _replace(INode _newNode) internal {
    if (address(_newNode) == address(0)) revert ZeroArg();
    if (_newNode.setupCompleted() == false) revert SetupNotCompleted(_newNode);
    if (address(_newNode) == address(this)) revert InvalidArg();
    if (_newNode.parent() != parent) revert InvalidParent();
    if (_newNode.core() != core) revert InvalidCore();
    if (_newNode.want() != want) revert InvalidWant();

    // Make sure our parent references `_newNode` as it's child
    parent.updateChild(_newNode);

    emit Replace(_newNode);
    emit Obsolete(INode(address(this)));
  }

  /*//////////////////////////////////////////////////////////////
                        YIELD STRATEGY LOGIC
  //////////////////////////////////////////////////////////////*/

  function balanceOf() external view override returns (uint256 amount) {
    return _balanceOf();
  }

  function withdrawAll() external override onlyParent returns (uint256 amount) {
    amount = _withdrawAll();
  }

  function withdrawAllByAdmin() external override onlyOwner returns (uint256 amount) {
    amount = _withdrawAll();
    emit AdminWithdraw(amount);
  }

  function withdraw(uint256 _amount) external override onlyParent {
    if (_amount == 0) revert ZeroArg();

    _withdraw(_amount);
  }

  function withdrawByAdmin(uint256 _amount) external override onlyOwner {
    if (_amount == 0) revert ZeroArg();

    _withdraw(_amount);
    emit AdminWithdraw(_amount);
  }

  function deposit() external override onlyParent {
    _deposit();
  }

  function _balanceOf() internal view virtual returns (uint256 amount) {}

  function _withdrawAll() internal virtual returns (uint256 amount) {}

  function _withdraw(uint256 _amount) internal virtual {}

  function _deposit() internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}