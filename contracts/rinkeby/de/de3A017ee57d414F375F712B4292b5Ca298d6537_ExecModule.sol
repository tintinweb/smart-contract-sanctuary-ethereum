/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/IActionWhitelist.sol


pragma solidity 0.8.9;

interface IActionWhitelist
{
	function checkAction(address _module, bytes4 _selector) external view returns (bool _whitelisted);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// File contracts/IFractionsCore.sol


pragma solidity 0.8.9;

interface IFractionsCore
{
	function __transfer(address _from, address _to, uint256 _amount) external;
	function __mint(address _to, uint256 _amount) external;
	function __burn(address _from, uint256 _amount) external;
	function __approve(address _owner, address _spender, uint256 _amount) external;
	function __pause() external;
	function __unpause() external;
	function __snapshot() external returns (uint256 _snapshotId);
	function __delegate(address _delegator, address _delegatee) external;
	function __addContext(address _context) external;
	function __removeContext(address _context) external;
	function __scheduleAction(bytes32 _actionId, uint256 _available) external;
	function __unscheduleAction(bytes32 _actionId) external;
	function __executeAction(address _module, uint256 _value, bytes calldata _calldata, uint256 _deadline) external returns (bytes memory _returndata);
	function __invalidateAction(bytes32 _actionId) external;
	function __externalCall(address _target, uint256 _value, bytes calldata _calldata) external returns (bytes memory _returndata);
}


// File contracts/IFractions.sol


pragma solidity 0.8.9;


interface IFractions is IERC20Metadata, IERC165, IFractionsCore
{
	function calcActionId(address _module, uint256 _value, bytes calldata _calldata, uint256 _deadline) external view returns (bytes32 _actionId);

	function paused() external view returns (bool _paused);

	function balanceOfAt(address _account, uint256 _snapshotId) external view returns (uint256 _balance);
	function totalSupplyAt(uint256 _snapshotId) external view returns (uint256 _totalSupply);

	function delegates(address _account) external view returns (address _delegates);
	function getVotes(address _account) external view returns (uint256 _votes);
	function delegate(address _newDelegate) external;
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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


// File contracts/Module.sol


pragma solidity 0.8.9;

abstract contract Module is ReentrancyGuard
{
	mapping(address => bool) public installed;

	modifier notInstalled
	{
		require(!installed[msg.sender], "already installed");
		_;
	}

	modifier onlyInstalled
	{
		require(installed[msg.sender], "not installed");
		_;
	}

	modifier installedOn(address payable _fractions)
	{
		require(installed[_fractions], "not installed");
		_;
	}

	function action_install() external notInstalled
	{
		IFractions(msg.sender).__addContext(address(this));
		installed[msg.sender] = true;
		_init();
		emit ModuleInstalled(msg.sender);
	}

	function action_uninstall() external onlyInstalled
	{
		IFractions(msg.sender).__removeContext(address(this));
		installed[msg.sender] = false;
		_done();
		emit ModuleUninstalled(msg.sender);
	}

	function _init() internal virtual {}
	function _done() internal virtual {}

	event ModuleInstalled(address indexed _fractions);
	event ModuleUninstalled(address indexed _fractions);
}


// File contracts/modules/ExecModule.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;



contract ExecModule is Module
{
	struct Data {
		address whitelist;
	}

	address public constant DEFAULT_WHITELIST = 0x835e6D95241e2A387643FEc48E625a6edDBC6194;

	mapping (address => Data) public data;

	modifier singleOwner(address payable _fractions)
	{
		require(IFractions(_fractions).balanceOf(msg.sender) == IFractions(_fractions).totalSupply(), "access denied");
		_;
	}

	function _init() internal override
	{
		Data storage _data = data[msg.sender];
		_data.whitelist = DEFAULT_WHITELIST;
	}

	function _done() internal override
	{
		Data storage _data = data[msg.sender];
		_data.whitelist = address(0);
	}

	// ----- BEGIN: actions

	function actions_multicall(address[] calldata _modules, uint256[] calldata _values, bytes[] calldata _calldatas) external nonReentrant onlyInstalled
	{
		Data storage _data = data[msg.sender];
		address _whitelist = _data.whitelist;
		if (_whitelist != address(0)) {
			for (uint256 _i = 0; _i < _modules.length; _i++) {
				address _module = _modules[_i];
				bytes memory _calldata = _calldatas[_i];
				bytes4 _selector = bytes4(_calldata);
				require(IActionWhitelist(_whitelist).checkAction(_module, _selector), "not whitelisted");
				IFractions(msg.sender).__externalCall(_module, _values[_i], _calldata);
			}
		} else {
			for (uint256 _i = 0; _i < _modules.length; _i++) {
				IFractions(msg.sender).__externalCall(_modules[_i], _values[_i], _calldatas[_i]);
			}
		}
	}

	function action_setWhitelist(address _newWhitelist) external onlyInstalled
	{
		Data storage _data = data[msg.sender];
		address _oldWhitelist = _data.whitelist;
		_data.whitelist = _newWhitelist;
		emit WhitelistChanged(msg.sender, _oldWhitelist, _newWhitelist);
	}

	// ----- END: actions

	function executeAction(address payable _fractions, address _module, uint256 _value, bytes calldata _calldata) external nonReentrant installedOn(_fractions) singleOwner(_fractions) returns (bytes memory _returndata)
	{
		Data storage _data = data[_fractions];
		address _whitelist = _data.whitelist;
		if (_whitelist != address(0)) {
			bytes4 _selector = bytes4(_calldata);
			require(IActionWhitelist(_whitelist).checkAction(_module, _selector), "not whitelisted");
		}
		bytes32 _actionId = IFractions(_fractions).calcActionId(_module, _value, _calldata, block.timestamp);
		IFractions(_fractions).__scheduleAction(_actionId, block.timestamp);
		IFractions(_fractions).__addContext(_module);
		_returndata = IFractions(_fractions).__executeAction(_module, _value, _calldata, block.timestamp);
		IFractions(_fractions).__removeContext(_module);
		return _returndata;
	}

	function executeAction(address payable _fractions, address _module, uint256 _value, bytes calldata _calldata, uint256 _deadline) external nonReentrant installedOn(_fractions) returns (bytes memory _returndata)
	{
		Data storage _data = data[_fractions];
		address _whitelist = _data.whitelist;
		if (_whitelist != address(0)) {
			bytes4 _selector = bytes4(_calldata);
			require(IActionWhitelist(_whitelist).checkAction(_module, _selector), "not whitelisted");
		}
		IFractions(_fractions).__addContext(_module);
		_returndata = IFractions(_fractions).__executeAction(_module, _value, _calldata, _deadline);
		IFractions(_fractions).__removeContext(_module);
		return _returndata;
	}

	event WhitelistChanged(address indexed _fractions, address indexed _oldWhitelist, address indexed _newWhitelist);
}