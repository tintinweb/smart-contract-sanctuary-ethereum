// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './Manager.sol';
import '../interfaces/managers/IStrategyManager.sol';
import '../interfaces/strategy/IStrategy.sol';
import '../interfaces/strategy/INode.sol';
import '../strategy/base/BaseMaster.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract InfoStorage {
  IERC20 public immutable want;
  address public immutable core;

  constructor(IERC20 _want, address _core) {
    want = _want;
    core = _core;
  }
}

// This contract is not desgined to hold funds (except during runtime)
// If it does (by someone sending funds directly) it will not be reflected in the balanceOf()
// On `deposit()` the funds will be added to the balance
// As an observer, if the TVL is 10m and this contract contains 10m, you can easily double your money if you
// enter the pool before `deposit()` is called.
contract MasterStrategy is
  BaseMaster,
  Manager /* IStrategyManager */
{
  using SafeERC20 for IERC20;

  constructor(IMaster _initialParent) BaseNode(_initialParent) {
    sherlockCore = ISherlock(core);

    emit SherlockCoreSet(ISherlock(core));
  }

  /*//////////////////////////////////////////////////////////////
                        TREE STRUCTURE LOGIC
  //////////////////////////////////////////////////////////////*/

  function isMaster() external view override returns (bool) {
    return true;
  }

  function setupCompleted() external view override returns (bool) {
    return address(childOne) != address(0);
  }

  function childRemoved() external override {
    // not implemented as the system can not function without `childOne` in this contract
    revert NotImplemented(msg.sig);
  }

  function replaceAsChild(ISplitter _newParent) external override {
    revert NotImplemented(msg.sig);
  }

  function replace(INode _node) external override {
    revert NotImplemented(msg.sig);
  }

  function replaceForce(INode _node) external override {
    revert NotImplemented(msg.sig);
  }

  function updateChild(INode _newChild) external override {
    address _childOne = address(childOne);
    if (_childOne == address(0)) revert NotSetup();
    if (_childOne != msg.sender) revert InvalidSender();

    _verifySetChild(INode(msg.sender), _newChild);
    _setChildOne(INode(msg.sender), _newChild);
  }

  function updateParent(IMaster _node) external override {
    // not implemented as the parent can not be updated by the tree system
    revert NotImplemented(msg.sig);
  }

  /*//////////////////////////////////////////////////////////////
                        YIELD STRATEGY LOGIC
  //////////////////////////////////////////////////////////////*/

  modifier balanceCache() {
    childOne.prepareBalanceCache();
    _;
    childOne.expireBalanceCache();
  }

  function prepareBalanceCache() external override returns (uint256) {
    revert NotImplemented(msg.sig);
  }

  function expireBalanceCache() external override {
    revert NotImplemented(msg.sig);
  }

  function balanceOf()
    public
    view
    override(
      /*IStrategyManager, */
      INode
    )
    returns (uint256)
  {
    return childOne.balanceOf();
  }

  function deposit()
    external
    override(
      /*IStrategyManager, */
      INode
    )
    whenNotPaused
    onlySherlockCore
    balanceCache
  {
    uint256 balance = want.balanceOf(address(this));
    if (balance == 0) revert InvalidConditions();

    want.safeTransfer(address(childOne), balance);

    childOne.deposit();
  }

  function withdrawAllByAdmin() external override onlyOwner balanceCache returns (uint256 amount) {
    amount = childOne.withdrawAll();
    emit AdminWithdraw(amount);
  }

  function withdrawAll()
    external
    override(
      /*IStrategyManager, */
      INode
    )
    onlySherlockCore
    balanceCache
    returns (uint256)
  {
    return childOne.withdrawAll();
  }

  function withdrawByAdmin(uint256 _amount) external override onlyOwner balanceCache {
    if (_amount == 0) revert ZeroArg();

    childOne.withdraw(_amount);
    emit AdminWithdraw(_amount);
  }

  function withdraw(uint256 _amount)
    external
    override(
      /*IStrategyManager, */
      INode
    )
    onlySherlockCore
    balanceCache
  {
    if (_amount == 0) revert ZeroArg();

    childOne.withdraw(_amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../interfaces/managers/IManager.sol';

abstract contract Manager is IManager, Ownable, Pausable {
  using SafeERC20 for IERC20;

  address private constant DEPLOYER = 0x1C11bE636415973520DdDf1b03822b4e2930D94A;
  ISherlock internal sherlockCore;

  modifier onlySherlockCore() {
    if (msg.sender != address(sherlockCore)) revert InvalidSender();
    _;
  }

  /// @notice Set sherlock core address
  /// @param _sherlock Current core contract
  /// @dev Only deployer is able to set core address on all chains except Hardhat network
  /// @dev One time function, will revert once `sherlock` != address(0)
  /// @dev This contract will be deployed first, passed on as argument in core constuctor
  /// @dev emits `SherlockCoreSet`
  function setSherlockCoreAddress(ISherlock _sherlock) external override {
    if (address(_sherlock) == address(0)) revert ZeroArgument();
    // 31337 is of the Hardhat network blockchain
    if (block.chainid != 31337 && msg.sender != DEPLOYER) revert InvalidSender();

    if (address(sherlockCore) != address(0)) revert InvalidConditions();
    sherlockCore = _sherlock;

    emit SherlockCoreSet(_sherlock);
  }

  // Internal function to send tokens remaining in a contract to the receiver address
  function _sweep(address _receiver, IERC20[] memory _extraTokens) internal {
    // Loops through the extra tokens (ERC20) provided and sends all of them to the receiver address
    for (uint256 i; i < _extraTokens.length; i++) {
      IERC20 token = _extraTokens[i];
      token.safeTransfer(_receiver, token.balanceOf(address(this)));
    }
    // Sends any remaining ETH to the receiver address (as long as receiver address is payable)
    (bool success, ) = _receiver.call{ value: address(this).balance }('');
    if (success == false) revert InvalidConditions();
  }

  function pause() external virtual onlySherlockCore {
    _pause();
  }

  function unpause() external virtual onlySherlockCore {
    _unpause();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStrategyManager is IManager {
  /// @return Returns the token type being deposited into a strategy
  function want() external view returns (IERC20);

  /// @notice Withdraws all USDC from the strategy back into the Sherlock core contract
  /// @dev Only callable by the Sherlock core contract
  /// @return The final amount withdrawn
  function withdrawAll() external returns (uint256);

  /// @notice Withdraws a specific amount of USDC from the strategy back into the Sherlock core contract
  /// @param _amount Amount of USDC to withdraw
  function withdraw(uint256 _amount) external;

  /// @notice Deposits all USDC held in this contract into the strategy
  function deposit() external;

  /// @return Returns the USDC balance in this contract
  function balanceOf() external view returns (uint256);
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

import '@openzeppelin/contracts/access/Ownable.sol';

import '../../interfaces/strategy/INode.sol';
import '../../interfaces/strategy/INode.sol';
import './BaseNode.sol';

// Interface used by the MasterStrategy, the contract core will reference as `yieldStrategy`
abstract contract BaseMaster is IMaster, BaseNode {
  // ChildNode
  INode public override childOne;

  /// @notice Verify if `_newChild` is able to replace `_currentChild` without doing same parent check
  /// @param _currentChild Node that is the current child
  /// @param _newChild Node that is the new child
  function _verifySetChildSkipParentCheck(INode _currentChild, INode _newChild) internal {
    if (address(_newChild) == address(0)) revert ZeroArg();
    if (_newChild.setupCompleted() == false) revert SetupNotCompleted(_newChild);

    if (_newChild == _currentChild) revert InvalidArg();
    if (core != _newChild.core()) revert InvalidCore();
    if (want != _newChild.want()) revert InvalidWant();
  }

  /// @notice Verify if `_newChild` is able to replace `_currentChild`
  /// @param _currentChild Node that is the current child
  /// @param _newChild Node that is the new child
  function _verifySetChild(INode _currentChild, INode _newChild) internal {
    _verifySetChildSkipParentCheck(_currentChild, _newChild);
    // NOTE this check is basically one here for the `updateChild` call in splitter
    if (address(_newChild.parent()) != address(this)) revert InvalidParent();
  }

  /// @notice Set childOne in storage
  /// @param _currentChild The `childOne` currently stored
  /// @param _newChild The `childOne` that is stored after this call
  function _setChildOne(INode _currentChild, INode _newChild) internal {
    childOne = _newChild;
    emit ChildOneUpdate(_currentChild, _newChild);
  }

  /// @notice Set initial childOne
  /// @param _newChild Address of the initial child
  function setInitialChildOne(INode _newChild) external override onlyOwner {
    if (address(childOne) != address(0)) revert InvalidState();

    _verifySetChild(INode(address(0)), _newChild);
    _setChildOne(INode(address(0)), _newChild);
  }
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

import '../ISherlock.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IManager {
  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // If a required condition for executing the function is not met, it reverts and throws this error
  error InvalidConditions();

  // Throws if the msg.sender is not the required address
  error InvalidSender();

  event SherlockCoreSet(ISherlock sherlock);

  /// @notice Set sherlock core address where premiums should be send too
  /// @param _sherlock Current core contract
  /// @dev Only deployer is able to set core address on all chains except Hardhat network
  /// @dev One time function, will revert once `sherlock` != address(0)
  /// @dev This contract will be deployed first, passed on as argument in core constuctor
  /// @dev ^ that's needed for tvl accounting, once core is deployed this function is called
  /// @dev emits `SherlockCoreSet`
  function setSherlockCoreAddress(ISherlock _sherlock) external;

  /// @notice Pause external functions in contract
  function pause() external;

  /// @notice Unpause external functions in contract
  function unpause() external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './ISherlockStake.sol';
import './ISherlockGov.sol';
import './ISherlockPayout.sol';
import './ISherlockStrategy.sol';

interface ISherlock is ISherlockStake, ISherlockGov, ISherlockPayout, ISherlockStrategy, IERC721 {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // Required conditions are not true/met
  error InvalidConditions();

  // If the SHER tokens held in a contract are not the value they are supposed to be
  error InvalidSherAmount(uint256 expected, uint256 actual);

  // Checks the ERC-721 functions _exists() to see if an NFT ID actually exists and errors if not
  error NonExistent();

  event ArbRestaked(uint256 indexed tokenID, uint256 reward);

  event Restaked(uint256 indexed tokenID);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock core interface for stakers
/// @author Evert Kors
interface ISherlockStake {
  /// @notice View the current lockup end timestamp of `_tokenID`
  /// @return Timestamp when NFT position unlocks
  function lockupEnd(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current SHER reward of `_tokenID`
  /// @return Amount of SHER rewarded to owner upon reaching the end of the lockup
  function sherRewards(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current token balance claimable upon reaching end of the lockup
  /// @return Amount of tokens assigned to owner when unstaking position
  function tokenBalanceOf(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current TVL for all stakers
  /// @return Total amount of tokens staked
  /// @dev Adds principal + strategy + premiums
  /// @dev Will calculate the most up to date value for each piece
  function totalTokenBalanceStakers() external view returns (uint256);

  /// @notice Stakes `_amount` of tokens and locks up for `_period` seconds, `_receiver` will receive the NFT receipt
  /// @param _amount Amount of tokens to stake
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @param _receiver Address that will receive the NFT representing the position
  /// @return _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to this ID after `_period` ends
  /// @dev `_period` needs to be whitelisted
  function initialStake(
    uint256 _amount,
    uint256 _period,
    address _receiver
  ) external returns (uint256 _id, uint256 _sher);

  /// @notice Redeem NFT `_id` and receive `_amount` of tokens
  /// @param _id TokenID of the position
  /// @return _amount Amount of tokens (USDC) owed to NFT ID
  /// @dev Only the owner of `_id` will be able to redeem their position
  /// @dev The SHER rewards are sent to the NFT owner
  /// @dev Can only be called after lockup `_period` has ended
  function redeemNFT(uint256 _id) external returns (uint256 _amount);

  /// @notice Owner restakes position with ID: `_id` for `_period` seconds
  /// @param _id ID of the position
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @return _sher Amount of SHER tokens to be released to owner address after `_period` ends
  /// @dev Only the owner of `_id` will be able to restake their position using this call
  /// @dev `_period` needs to be whitelisted
  /// @dev Can only be called after lockup `_period` has ended
  function ownerRestake(uint256 _id, uint256 _period) external returns (uint256 _sher);

  /// @notice Allows someone who doesn't own the position (an arbitrager) to restake the position for 26 weeks (ARB_RESTAKE_PERIOD)
  /// @param _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to position owner on expiry of the 26 weeks lockup
  /// @return _arbReward Amount of tokens (USDC) sent to caller (the arbitrager) in return for calling the function
  /// @dev Can only be called after lockup `_period` is more than 2 weeks in the past (assuming ARB_RESTAKE_WAIT_TIME is 2 weeks)
  /// @dev Max 20% (ARB_RESTAKE_MAX_PERCENTAGE) of tokens associated with a position are used to incentivize arbs (x)
  /// @dev During a 2 week period the reward ratio will move from 0% to 100% (* x)
  function arbRestake(uint256 _id) external returns (uint256 _sher, uint256 _arbReward);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/ISherDistributionManager.sol';
import './managers/ISherlockProtocolManager.sol';
import './managers/ISherlockClaimManager.sol';
import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for governance
/// @author Evert Kors
interface ISherlockGov {
  event ClaimPayout(address receiver, uint256 amount);
  event YieldStrategyUpdateWithdrawAllError(bytes error);
  event YieldStrategyUpdated(IStrategyManager previous, IStrategyManager current);
  event ProtocolManagerUpdated(ISherlockProtocolManager previous, ISherlockProtocolManager current);
  event ClaimManagerUpdated(ISherlockClaimManager previous, ISherlockClaimManager current);
  event NonStakerAddressUpdated(address previous, address current);
  event SherDistributionManagerUpdated(
    ISherDistributionManager previous,
    ISherDistributionManager current
  );

  event StakingPeriodEnabled(uint256 period);

  event StakingPeriodDisabled(uint256 period);

  /// @notice Allows stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already enabled
  function enableStakingPeriod(uint256 _period) external;

  /// @notice Disallow stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already disabled
  function disableStakingPeriod(uint256 _period) external;

  /// @notice View if `_period` is a valid period
  /// @return Boolean indicating if period is valid
  function stakingPeriods(uint256 _period) external view returns (bool);

  /// @notice Update SHER distribution manager contract
  /// @param _sherDistributionManager New adddress of the manager
  function updateSherDistributionManager(ISherDistributionManager _sherDistributionManager)
    external;

  /// @notice Deletes the SHER distribution manager altogether (if Sherlock decides to no longer pay out SHER rewards)
  function removeSherDistributionManager() external;

  /// @notice Read SHER distribution manager
  /// @return Address of current SHER distribution manager
  function sherDistributionManager() external view returns (ISherDistributionManager);

  /// @notice Update address eligible for non staker rewards from protocol premiums
  /// @param _nonStakers Address eligible for non staker rewards
  function updateNonStakersAddress(address _nonStakers) external;

  /// @notice View current non stakers address
  /// @return Current non staker address
  /// @dev Is able to pull funds out of the contract
  function nonStakersAddress() external view returns (address);

  /// @notice View current address able to manage protocols
  /// @return Protocol manager implemenation
  function sherlockProtocolManager() external view returns (ISherlockProtocolManager);

  /// @notice Transfer protocol manager implementation address
  /// @param _protocolManager new implementation address
  function updateSherlockProtocolManager(ISherlockProtocolManager _protocolManager) external;

  /// @notice View current address able to pull payouts
  /// @return Address able to pull payouts
  function sherlockClaimManager() external view returns (ISherlockClaimManager);

  /// @notice Transfer claim manager role to different address
  /// @param _claimManager New address of claim manager
  function updateSherlockClaimManager(ISherlockClaimManager _claimManager) external;

  /// @notice Update yield strategy
  /// @param _yieldStrategy New address of the strategy
  /// @dev try a yieldStrategyWithdrawAll() on old, ignore failure
  function updateYieldStrategy(IStrategyManager _yieldStrategy) external;

  /// @notice Update yield strategy ignoring current state
  /// @param _yieldStrategy New address of the strategy
  /// @dev tries a yieldStrategyWithdrawAll() on old strategy, ignore failure
  function updateYieldStrategyForce(IStrategyManager _yieldStrategy) external;

  /// @notice Read current strategy
  /// @return Address of current strategy
  /// @dev can never be address(0)
  function yieldStrategy() external view returns (IStrategyManager);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock interface for payout manager
/// @author Evert Kors
interface ISherlockPayout {
  /// @notice Initiate a payout of `_amount` to `_receiver`
  /// @param _receiver Receiver of payout
  /// @param _amount Amount to send
  /// @dev only payout manager should call this
  /// @dev should pull money out of strategy
  function payoutClaim(address _receiver, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for yield strategy
/// @author Evert Kors
interface ISherlockStrategy {
  /// @notice Deposit `_amount` into active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyDeposit(uint256 _amount) external;

  /// @notice Withdraw `_amount` from active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyWithdraw(uint256 _amount) external;

  /// @notice Withdraw all funds from active strategy
  /// @dev gov only
  function yieldStrategyWithdrawAll() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IManager.sol';

interface ISherDistributionManager is IManager {
  // anyone can just send token to this contract to fund rewards

  event Initialized(uint256 maxRewardsEndTVL, uint256 zeroRewardsStartTVL, uint256 maxRewardRate);

  /// @notice Caller will receive `_sher` SHER tokens based on `_amount` and `_period`
  /// @param _amount Amount of tokens (in USDC) staked
  /// @param _period Period of time for stake, in seconds
  /// @param _id ID for this NFT position
  /// @param _receiver Address that will be linked to this position
  /// @return _sher Amount of SHER tokens sent to Sherlock core contract
  /// @dev Calling contract will depend on before + after balance diff and return value
  /// @dev INCLUDES stake in calculation, function expects the `_amount` to be deposited already
  /// @dev If tvl=50 and amount=50, this means it is calculating SHER rewards for the first 50 tokens going in
  function pullReward(
    uint256 _amount,
    uint256 _period,
    uint256 _id,
    address _receiver
  ) external returns (uint256 _sher);

  /// @notice Calculates how many `_sher` SHER tokens are owed to a stake position based on `_amount` and `_period`
  /// @param _tvl TVL to use for reward calculation (pre-stake TVL)
  /// @param _amount Amount of tokens (USDC) staked
  /// @param _period Stake period (in seconds)
  /// @return _sher Amount of SHER tokens owed to this stake position
  /// @dev EXCLUDES `_amount` of stake, this will be added on top of TVL (_tvl is excluding _amount)
  /// @dev If tvl=0 and amount=50, it would calculate for the first 50 tokens going in (different from pullReward())
  function calcReward(
    uint256 _tvl,
    uint256 _amount,
    uint256 _period
  ) external view returns (uint256 _sher);

  /// @notice Function used to check if this is the current active distribution manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

/// @title Sherlock core interface for protocols
/// @author Evert Kors
interface ISherlockProtocolManager is IManager {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // If a protocol was never instantiated or was removed and the claim deadline has passed, this error is returned
  error ProtocolNotExists(bytes32 protocol);

  // When comparing two arrays and the lengths are not equal (but are supposed to be equal)
  error UnequalArrayLength();

  // If there is not enough balance in the contract for the amount requested (after any requirements are met), this is returned
  error InsufficientBalance(bytes32 protocol);

  event MinBalance(uint256 previous, uint256 current);

  event AccountingError(bytes32 indexed protocol, uint256 amount, uint256 insufficientTokens);

  event ProtocolAdded(bytes32 indexed protocol);

  event ProtocolRemovedByArb(bytes32 indexed protocol, address arb, uint256 profit);

  event ProtocolRemoved(bytes32 indexed protocol);

  event ProtocolUpdated(
    bytes32 indexed protocol,
    bytes32 coverage,
    uint256 nonStakers,
    uint256 coverageAmount
  );

  event ProtocolAgentTransfer(bytes32 indexed protocol, address from, address to);

  event ProtocolBalanceDeposited(bytes32 indexed protocol, uint256 amount);

  event ProtocolBalanceWithdrawn(bytes32 indexed protocol, uint256 amount);

  event ProtocolPremiumChanged(bytes32 indexed protocol, uint256 oldPremium, uint256 newPremium);

  /// @notice View current amount of all premiums that are owed to stakers
  /// @return Premiums claimable
  /// @dev Will increase every block
  /// @dev base + (now - last_settled) * ps
  function claimablePremiums() external view returns (uint256);

  /// @notice Transfer current claimable premiums (for stakers) to core Sherlock address
  /// @dev Callable by everyone
  /// @dev Funds will be transferred to Sherlock core contract
  function claimPremiumsForStakers() external;

  /// @notice View current protocolAgent of `_protocol`
  /// @param _protocol Protocol identifier
  /// @return Address able to submit claims
  function protocolAgent(bytes32 _protocol) external view returns (address);

  /// @notice View current premium of protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of premium `_protocol` pays per second
  function premium(bytes32 _protocol) external view returns (uint256);

  /// @notice View current active balance of covered protocol
  /// @param _protocol Protocol identifier
  /// @return Active balance
  /// @dev Accrued debt is subtracted from the stored active balance
  function activeBalance(bytes32 _protocol) external view returns (uint256);

  /// @notice View seconds of coverage left for `_protocol` before it runs out of active balance
  /// @param _protocol Protocol identifier
  /// @return Seconds of coverage left
  function secondsOfCoverageLeft(bytes32 _protocol) external view returns (uint256);

  /// @notice Add a new protocol to Sherlock
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Address able to submit a claim on behalf of the protocol
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Adding a protocol allows the `_protocolAgent` to submit a claim
  /// @dev Coverage is not started yet as the protocol doesn't pay a premium at this point
  /// @dev `_nonStakers` is scaled by 10**18
  /// @dev Only callable by governance
  function protocolAdd(
    bytes32 _protocol,
    address _protocolAgent,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Update info regarding a protocol
  /// @param _protocol Protocol identifier
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Only callable by governance
  function protocolUpdate(
    bytes32 _protocol,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Remove a protocol from coverage
  /// @param _protocol Protocol identifier
  /// @dev Before removing a protocol the premium must be 0
  /// @dev Removing a protocol basically stops the `_protocolAgent` from being active (can still submit claims until claim deadline though)
  /// @dev Pays off debt + sends remaining balance to protocol agent
  /// @dev This call should be subject to a timelock
  /// @dev Only callable by governance
  function protocolRemove(bytes32 _protocol) external;

  /// @notice Remove a protocol with insufficient active balance
  /// @param _protocol Protocol identifier
  function forceRemoveByActiveBalance(bytes32 _protocol) external;

  /// @notice Removes a protocol with insufficent seconds of coverage left
  /// @param _protocol Protocol identifier
  function forceRemoveBySecondsOfCoverage(bytes32 _protocol) external;

  /// @notice View minimal balance needed before liquidation can start
  /// @return Minimal balance needed
  function minActiveBalance() external view returns (uint256);

  /// @notice Sets the minimum active balance before an arb can remove a protocol
  /// @param _minActiveBalance Minimum balance needed (in USDC)
  /// @dev Only gov
  function setMinActiveBalance(uint256 _minActiveBalance) external;

  /// @notice Set premium of `_protocol` to `_premium`
  /// @param _protocol Protocol identifier
  /// @param _premium Amount of premium `_protocol` pays per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremium(bytes32 _protocol, uint256 _premium) external;

  /// @notice Set premium of multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _premium Array of premium amounts protocols pay per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremiums(bytes32[] calldata _protocol, uint256[] calldata _premium) external;

  /// @notice Deposits `_amount` of token to the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to deposit
  /// @dev Approval should be made before calling
  function depositToActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Withdraws `_amount` of token from the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to withdraw
  /// @dev Only protocol agent is able to withdraw
  /// @dev Balance can be withdrawn up until 7 days worth of active balance
  function withdrawActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Transfer protocol agent role
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Account able to submit a claim on behalf of the protocol
  /// @dev Only the active protocolAgent is able to transfer the role
  function transferProtocolAgent(bytes32 _protocol, address _protocolAgent) external;

  /// @notice View the amount nonstakers can claim from this protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of tokens claimable by nonstakers
  /// @dev this reads from a storage variable + (now-lastsettled) * premiums
  function nonStakersClaimable(bytes32 _protocol) external view returns (uint256);

  /// @notice Choose an `_amount` of tokens that nonstakers (`_receiver` address) will receive from `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address to receive tokens
  /// @dev Only callable by nonstakers role
  function nonStakersClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver
  ) external;

  /// @param _protocol Protocol identifier
  /// @return current and previous are the current and previous coverage amounts for this protocol
  function coverageAmounts(bytes32 _protocol)
    external
    view
    returns (uint256 current, uint256 previous);

  /// @notice Function used to check if this is the current active protocol manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './callbacks/ISherlockClaimManagerCallbackReceiver.sol';
import '../UMAprotocol/OptimisticRequester.sol';
import './IManager.sol';

interface ISherlockClaimManager is IManager, OptimisticRequester {
  // Doesn't allow a new claim to be submitted by a protocol agent if a claim is already active for that protocol
  error ClaimActive();

  // If the current state of a claim does not match the expected state, this error is thrown
  error InvalidState();

  event ClaimCreated(
    uint256 claimID,
    bytes32 indexed protocol,
    uint256 amount,
    address receiver,
    bool previousCoverageUsed
  );

  event CallbackAdded(ISherlockClaimManagerCallbackReceiver callback);

  event CallbackRemoved(ISherlockClaimManagerCallbackReceiver callback);

  event ClaimStatusChanged(uint256 indexed claimID, State previousState, State currentState);

  event ClaimPayout(uint256 claimID, address receiver, uint256 amount);

  event ClaimHalted(uint256 claimID);

  event UMAHORenounced();

  enum State {
    NonExistent, // Claim doesn't exist (this is the default state on creation)
    SpccPending, // Claim is created, SPCC is able to set state to valid
    SpccApproved, // Final state, claim is valid
    SpccDenied, // Claim denied by SPCC, claim can be escalated within 4 weeks
    UmaPriceProposed, // Price is proposed but not escalated
    ReadyToProposeUmaDispute, // Price is proposed, callback received, ready to submit dispute
    UmaDisputeProposed, // Escalation is done, waiting for confirmation
    UmaPending, // Claim is escalated, in case Spcc denied or didn't act within 7 days.
    UmaApproved, // Final state, claim is valid, claim can be enacted after 1 day, umaHaltOperator has 1 day to change to denied
    UmaDenied, // Final state, claim is invalid
    Halted, // UMAHO can halt claim if state is UmaApproved
    Cleaned // Claim is removed by protocol agent
  }

  struct Claim {
    uint256 created;
    uint256 updated;
    address initiator;
    bytes32 protocol;
    uint256 amount;
    address receiver;
    uint32 timestamp;
    State state;
    bytes ancillaryData;
  }

  // requestAndProposePriceFor() --> proposer = sherlockCore (address to receive BOND if UMA denies claim)
  // disputePriceFor() --> disputer = protocolAgent
  // priceSettled will be the the callback that contains the main data

  // Assume BOND = 9600, UMA's final fee = 1500.
  // Claim initiator (Sherlock) has to pay 22.2k to dispute a claim,
  // so we will execute a safeTransferFrom(claimInitiator, address(this), 22.2k).
  // We need to approve the contract 22.2k as it will be transferred from address(this).

  // The 22.2k consists of 2 * (BOND + final fee charged by UMA), as follows:
  // 1. On requestAndProposePriceFor(), the fee will be 10k: 9600 BOND + 1500 UMA's final fee;
  // 2. On disputePriceFor(), the fee will be the same 10k.
  // note that half of the BOND (4800) + UMA's final fee (1500) is "burnt" and sent to UMA

  // UMA's final fee can be changed in the future, which may result in lower or higher required staked amounts for escalating a claim.

  // On settle, either the protocolAgent (dispute success) or sherlockCore (dispute failure)
  // will receive 9600 + 4800 + 1500 = 15900. In addition, the protocolAgent will be entitled to
  // the claimAmount if the dispute is successful/

  // lastClaimID <-- starts with 0, so initial id = 1
  // have claim counter, easy to identify certain claims by their number
  // but use hash(callback.request.propose + callback.timestamp) as the internal UUID to handle the callbacks

  // So SPCC and UMAHO are hardcoded (UMAHO can be renounced)
  // In case these need to be updated, deploy different contract and upgrade it on the sherlock gov side.

  // On price proposed callback --> call disputePriceFor with callbackdata + sherlock.strategyManager() and address(this)

  /// @notice `SHERLOCK_CLAIM` in utf8
  function UMA_IDENTIFIER() external view returns (bytes32);

  function sherlockProtocolClaimsCommittee() external view returns (address);

  /// @notice operator is able to deny approved UMA claims
  function umaHaltOperator() external view returns (address);

  /// @notice gov is able to renounce the role
  function renounceUmaHaltOperator() external;

  function claim(uint256 _claimID) external view returns (Claim memory);

  /// @notice Initiate a claim for a specific protocol as the protocol agent
  /// @param _protocol protocol ID (different from the internal or public claim ID fields)
  /// @param _amount amount of USDC which is being claimed by the protocol
  /// @param _receiver address to receive the amount of USDC being claimed
  /// @param _timestamp timestamp at which the exploit first occurred
  /// @param ancillaryData other data associated with the claim, such as the coverage agreement
  /// @dev The protocol agent that starts a claim will be the protocol agent during the claims lifecycle
  /// @dev Even if the protocol agent role is tranferred during the lifecycle
  function startClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    uint32 _timestamp,
    bytes memory ancillaryData
  ) external;

  function spccApprove(uint256 _claimID) external;

  function spccRefuse(uint256 _claimID) external;

  /// @notice Callable by protocol agent
  /// @param _claimID Public claim ID
  /// @param _amount Bond amount sent by protocol agent
  /// @dev Use hardcoded USDC address
  /// @dev Use hardcoded bond amount
  /// @dev Use hardcoded liveness 7200 (2 hours)
  /// @dev proposedPrice = _amount
  function escalate(uint256 _claimID, uint256 _amount) external;

  /// @notice Execute claim, storage will be removed after
  /// @param _claimID Public ID of the claim
  /// @dev Needs to be SpccApproved or UmaApproved && >UMAHO_TIME
  /// @dev Funds will be pulled from core
  function payoutClaim(uint256 _claimID) external;

  /// @notice UMAHO is able to execute a halt if the state is UmaApproved and state was updated less than UMAHO_TIME ago
  function executeHalt(uint256 _claimID) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

interface ISherlockClaimManagerCallbackReceiver {
  /// @notice Calls this function on approved contracts and passes args
  /// @param _protocol The protocol that is receiving the payout
  /// @param _claimID The claim ID that is receiving the payout
  /// @param _amount The amount of USDC being paid out for this claim
  function PreCorePayoutCallback(
    bytes32 _protocol,
    uint256 _claimID,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import './SkinnyOptimisticOracleInterface.sol';

/**
 * @title Optimistic Requester.
 * @notice Optional interface that requesters can implement to receive callbacks.
 * @dev This contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
interface OptimisticRequester {
  /**
   * @notice Callback for proposals.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after proposal.
   */
  function priceProposed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for disputes.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after dispute.
   */
  function priceDisputed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for settlement.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after settlement.
   */
  function priceSettled(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './OptimisticOracleInterface.sol';

/**
 * @title Interface for the gas-cost-reduced version of the OptimisticOracle.
 * @notice Differences from normal OptimisticOracle:
 * - refundOnDispute: flag is removed, by default there are no refunds on disputes.
 * - customizing request parameters: In the OptimisticOracle, parameters like `bond` and `customLiveness` can be reset
 *   after a request is already made via `requestPrice`. In the SkinnyOptimisticOracle, these parameters can only be
 *   set in `requestPrice`, which has an expanded input set.
 * - settleAndGetPrice: Replaced by `settle`, which can only be called once per settleable request. The resolved price
 *   can be fetched via the `Settle` event or the return value of `settle`.
 * - general changes to interface: Functions that interact with existing requests all require the parameters of the
 *   request to modify to be passed as input. These parameters must match with the existing request parameters or the
 *   function will revert. This change reflects the internal refactor to store hashed request parameters instead of the
 *   full request struct.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract SkinnyOptimisticOracleInterface {
  event RequestPrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event ProposePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event DisputePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event Settle(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  // Struct representing a price request. Note that this differs from the OptimisticOracleInterface's Request struct
  // in that refundOnDispute is removed.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @return totalBond default bond + final fee that the proposer and disputer will be required to pay.
   */
  function requestPrice(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address proposer,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value where caller is the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Combines logic of requestPrice and proposePrice while taking advantage of gas savings from not having to
   * overwrite Request params that a normal requestPrice() => proposePrice() flow would entail. Note: The proposer
   * will receive any rewards that come from this proposal. However, any bonds are pulled from the caller.
   * @dev The caller is the requester, but the proposer can be customized.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function requestAndProposePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness,
    address proposer,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address disputer,
    address requester
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal where caller is the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * settle.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   * @return resolvedPrice the price that the request settled to.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 payout, int256 resolvedPrice);

  /**
   * @notice Computes the current state of a price request. See the State enum for more details.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters.
   * @return the State.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (OptimisticOracleInterface.State);

  /**
   * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters. The hash of these parameters must match with the request hash that is
   * associated with the price request unique ID {requester, identifier, timestamp, ancillaryData}, or this method
   * will revert.
   * @return boolean indicating true if price exists and false if not.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) public virtual returns (bool);

  /**
   * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
   * @param ancillaryData ancillary data of the price being requested.
   * @param requester sender of the initial price request.
   * @return the stamped ancillary bytes.
   */
  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    pure
    virtual
    returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
  // Struct representing the state of a price request.
  enum State {
    Invalid, // Never requested.
    Requested, // Requested, no other actions taken.
    Proposed, // Proposed, but not expired or disputed yet.
    Expired, // Proposed, not disputed, past liveness.
    Disputed, // Disputed, but no DVM price returned yet.
    Resolved, // Disputed and DVM price is available.
    Settled // Final price has been set in the contract (can get here from Expired or Resolved).
  }

  // Struct representing a price request.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
   * This can be changed with a subsequent call to setBond().
   */
  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Set the proposal bond associated with a price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param bond custom bond amount to set.
   * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
   * changed again with a subsequent call to setBond().
   */
  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
   * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
   * bond, so there is still profit to be made even if the reward is refunded.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   */
  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual;

  /**
   * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
   * being auto-resolved.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param customLiveness new custom liveness.
   */
  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external virtual;

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param proposer address to set as the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value for an existing price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was value (the proposal was incorrect).
   */
  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price value for an existing price request with an active proposal.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
   * or settleable. Note: this method is not view so that this call may actually settle the price request if it
   * hasn't been settled.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return resolved price.
   */
  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (int256);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 payout);

  /**
   * @notice Gets the current data structure containing all information about a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the Request data structure.
   */
  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (Request memory);

  /**
   * @notice Returns the state of a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the State enum value.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (State);

  /**
   * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return true if price has resolved or settled, false otherwise.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    view
    virtual
    returns (bytes memory);
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