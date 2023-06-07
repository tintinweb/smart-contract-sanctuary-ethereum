// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import '../interfaces/IUFarmCore.sol';
import './UFarmFund.sol';
import '../shared/UFarmErrors.sol';
import '../shared/UFarmPermissionsModel.sol';

contract UFarmCorePermissions {
	using PermissionCoreLib for PermissionCoreLib.Member;

	enum UFarmPermissions {
		PermissionsManager, // 2^0
		MemberCreator, // 2^1
		FundApprover, // 2^2
		FundModerator, // 2^3
		InvestorManager, // 2^4
		Pauser // 2^5
	}

	mapping(address => PermissionCoreLib.Member) private __ufarmEmployees;

	event UFarmEmployeeAdded(address indexed employee);
	event UFarmEmployeeRemoved(address indexed employee);
	event UFarmEmployeePermissionGranted(address indexed employee, UFarmPermissions permission);
	event UFarmEmployeePermissionRevoked(address indexed employee, UFarmPermissions permission);

	error NonUFarmMember(address account);
	error NonUFarmRole(address account, UFarmPermissions role);
	error UFarmEmployeeAlreadyExists(address account);
	error UFarmPermissionWasNotGranted(address account, UFarmPermissions permission);
	error UFarmPermissionAlreadyGranted(address account, UFarmPermissions permission);

	modifier onlyUFarmMember(address account) {
		if (!__ufarmEmployees[account].isMember()) {
			revert NonUFarmMember(account);
		}
		_;
	}

	modifier onlyUFarmRole(address account, UFarmPermissions role) {
		if (!__ufarmEmployees[account].isMember()) {
			revert NonUFarmMember(account);
		}
		if (!__ufarmEmployees[account].hasPermission(uint8(role))) {
			revert NonUFarmRole(account, role);
		}
		_;
	}

	constructor() {
		PermissionCoreLib.Member storage owner = __ufarmEmployees[msg.sender];
		owner.grantMembership();
		// Grans basic admin permissions to the owner
		owner.grantPermission(uint8(UFarmPermissions.PermissionsManager));
		owner.grantPermission(uint8(UFarmPermissions.MemberCreator));
	}

	function isUFarmMember(address _account) public view returns (bool) {
		return __ufarmEmployees[_account].isMember();
	}

	function testAddEmployee(address _employee) public returns (bool) {
		return __ufarmEmployees[_employee].grantMembership();
	}

	function testGrantPermission(
		address _employee,
		UFarmPermissions _permission
	) public returns (bool) {
		return __ufarmEmployees[_employee]._grantPermission(uint8(_permission));
	}

	function addUFarmEmployee(
		address _employee,
		UFarmPermissions[] calldata _permissions
	) public onlyUFarmRole(msg.sender, UFarmPermissions.MemberCreator) {
		if (!__ufarmEmployees[_employee].grantMembership()) {
			revert UFarmEmployeeAlreadyExists(_employee);
		}
		_addPermissions(_employee, _permissions);

		emit UFarmEmployeeAdded(_employee);
	}

	function removeUFarmEmployee(
		address _employee
	) public onlyUFarmRole(msg.sender, UFarmPermissions.MemberCreator) {
		if (!__ufarmEmployees[_employee].revokeMembership()) {
			revert UFarmEmployeeAlreadyExists(_employee);
		}

		emit UFarmEmployeeRemoved(_employee);
	}

	function addUFarmPermissions(
		address _employee,
		UFarmPermissions[] calldata _permissions
	) public onlyUFarmRole(msg.sender, UFarmPermissions.PermissionsManager) {
		uint256 permissionsCount = _permissions.length;
		for (uint256 i = 0; i < permissionsCount; ++i) {
			UFarmPermissions permission = _permissions[i];
			if (!__ufarmEmployees[_employee]._grantPermission(uint8(permission))) {
				revert UFarmPermissionAlreadyGranted(_employee, permission);
			}
			emit UFarmEmployeePermissionGranted(_employee, permission);
		}
	}

	function removeUFarmPermission(
		address _employee,
		UFarmPermissions _permission
	) public onlyUFarmRole(msg.sender, UFarmPermissions.PermissionsManager) {
		if (!__ufarmEmployees[_employee]._revokePermission(uint8(_permission))) {
			revert UFarmPermissionWasNotGranted(_employee, _permission);
		}

		emit UFarmEmployeePermissionRevoked(_employee, _permission);
	}

	function hasUFarmPermission(
		address _employee,
		UFarmPermissions _permission
	) public view returns (bool) {
		return __ufarmEmployees[_employee].hasPermission(uint8(_permission));
	}

	function _addPermissions(address _employee, UFarmPermissions[] calldata _permissions) internal {
		uint256 permissionsCount = _permissions.length;
		for (uint256 i = 0; i < permissionsCount; ++i) {
			__ufarmEmployees[_employee]._grantPermission(uint8(_permissions[i]));
		}
	}
}

contract UFarmInvestorPermissions is UFarmCorePermissions, UFarmErrors {
	using PermissionCoreLib for PermissionCoreLib.Member;

	uint256 public investorsCount;
	mapping(address => PermissionCoreLib.Member) private __investors;

	event NewInvestor(address indexed investor);

	error InvestorAlreadyRegistered();

	modifier onlyInvestor(address account) {
		if (__investors[account].isBanned()) {
			revert NonAuthorized();
		}
		if (!__investors[account].isMember()) {
			_registerInvestor(account);
		}
		_;
	}

	constructor() {}

	function registerInvestor(address _investor) public {
		if (__investors[_investor].isBanned()) {
			revert NonAuthorized();
		}
		if (__investors[_investor].isMember()) {
			revert InvestorAlreadyRegistered();
		}
		_registerInvestor(_investor);
	}

	function _banInvestors(address[] calldata _investors) internal {
		for (uint256 i = 0; i < _investors.length; ++i) {
			__investors[_investors[i]].revokeMembership();
		}
	}

	function _registerInvestor(address _investor) private {
		__investors[_investor].grantMembership();
		investorsCount++;

		// Future logic should be added here...

		emit NewInvestor(_investor);
	}

	function investor(address _investor) public view returns (PermissionCoreLib.Member memory) {
		return __investors[_investor];
	}
}

contract UFarmCore is IUFarmCore, UFarmInvestorPermissions, NZAGuard {
	/// @notice Return count of the funds
	uint256 public fundsCount;

	/// @notice Return the address of the fund by it's number
	mapping(uint256 => address) public funds;

	/// EVENTS
	event FundCreated(uint256 fundId, address fund, string name);

	/// ERRORS

	/**
	 * @notice Creates a new fund
	 * @param _name - name of the fund (e.g. "Goldman Sachs")
	 * @param _fundManager - address of the fund manager
	 */
	function createFund(
		string memory _name,
		address _fundManager
	) external onlyUFarmRole(msg.sender, UFarmPermissions.FundApprover) {
		_createFund(_name, _fundManager);
	}

	function testCreateFund(string memory _name, address _fundManager) external {
		_createFund(_name, _fundManager);
	}

	function approveFund(
		address _fund
	) external onlyUFarmRole(msg.sender, UFarmPermissions.FundApprover) {
		_approveFund(_fund);
	}

	function testApproveFund(address _fund) external {
		_approveFund(_fund);
	}

	function _approveFund(address _fund) internal {
		IUFarmFund(_fund).UFarmFundApprove();
	}

	function _createFund(string memory _name, address _fundManager) private {
		fundsCount++;
		address fund = address(new UFarmFund(_name, _fundManager));

		funds[fundsCount] = fund;

		emit FundCreated(fundsCount, fund, _name);
	}

	function banUsers(
		address[] calldata _users
	) external onlyUFarmRole(msg.sender, UFarmPermissions.InvestorManager) {
		_banInvestors(_users);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

pragma solidity 0.8.20;

import '../interfaces/IUFarmFund.sol';
import '../interfaces/IUFarmCore.sol';

import '../contracts/UFarmPool.sol';

import '../shared/UFarmErrors.sol';

contract UFarmFundPermissions {

}

contract UFarmFund is IUFarmFund, UFarmErrors {
	// TODO to add status transition diagram
	enum FundStatus {
		Draft,
		Active,
		Paused,
		Inactive
	}

	FundStatus public status;

	string public name;
	string public symbol;
	address public manager;

	IUFarmPool[] private pools;

	address public ufarmCore;

    event PoolCreated(
        address indexed pool,
        uint256 indexed poolId
    );

	event FundStatusChanged(FundStatus indexed status);

	constructor(string memory _name, address _manager) {
		name = _name;
		manager = _manager;

		ufarmCore = msg.sender;
	}

	function createPool(
		string memory _name,
		string memory _symbol,
		uint256 _totalSupply,
		uint256 _minInvestment,
		uint256 _maxInvestment,
		uint256 _fee
	) public {
		UFarmPool pool = new UFarmPool(
			_name,
			_symbol,
			_totalSupply,
			_minInvestment,
			_maxInvestment,
			_fee,
			manager
		);
        uint256 poolId = pools.length;
        pools.push(pool);
        emit PoolCreated(address(pool), poolId);
	}

	function UFarmFundApprove() external override {
		if (msg.sender != ufarmCore) {
			revert UFarmErrors.NonAuthorized();
		}
		status = FundStatus.Active;
		emit FundStatusChanged(status);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import '../interfaces/IUFarmPool.sol';

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract UFarmPool is IUFarmPool, ERC20 {
	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _totalSupply,
		uint256 _minInvestment,
		uint256 _maxInvestment,
		uint256 _fee,
		address _manager
	) ERC20(
        string(abi.encodePacked('UFarm ', _name)),
        string(abi.encodePacked('u', _symbol))
    ){}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IUFarmCore {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IUFarmFund {
    function UFarmFundApprove() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC20, IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IUFarmPool is IERC20Metadata {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract UFarmErrors {
	error NonAuthorized();
	// error UFarmErrors(string message);
}

/// @title NZAGuard contract contains modifiers to check inputs for non-zero address, non-zero value, non-same address, non-same value, and non-more-than-one
abstract contract NZAGuard {
	error ZeroAddress();
	error ZeroValue();
	error SameAddress();
	error SameValue();
	error MoreThanOne();

	modifier nonZeroAddress(address _address) {
		if (_address == address(0)) {
			revert ZeroAddress();
		}
		_;
	}
	modifier nonZeroValue(uint256 _value) {
		if (_value == 0) {
			revert ZeroValue();
		}
		_;
	}
	modifier nonSameValue(uint256 _value1, uint256 _value2) {
		if (_value1 == _value2) {
			revert SameValue();
		}
		_;
	}
	modifier nonSameAddress(address _address1, address _address2) {
		if (_address1 == _address2) {
			revert SameAddress();
		}
		_;
	}
	modifier nonMoreThenOne(uint256 _value) {
		if (_value > 1e18) {
			revert MoreThanOne();
		}
		_;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

contract PermissionContract {
	using PermissionCoreLib for PermissionCoreLib.Member;

	enum FundPermissions {
		PermissionsManager, // 2^0
		DescriptionManager, // 2^1
		MemberCreator, // 2^2
		PoolPermissionsManager, // 2^3
		PoolCreator, // 2^4
		PoolAdmin, // 2^5
		PoolTopupApprover // 2^6
	}

	enum UFarmPermissions {
		PermissionsManager, // 2^0
		MemberCreator, // 2^1
		FundApprover, // 2^2
		FundModerator, // 2^3
		InvestorManager, // 2^4
		Pauser // 2^5
	}

	mapping(address => PermissionCoreLib.Member) private _ufarmStaff;

	error NonMember(address account);

	modifier onlyMember(address account) {
		if (PermissionCoreLib.isMember(_ufarmStaff[account])) {
			_;
		} else {
			revert NonMember(account);
		}
	}

	// modifier onlyRole(bytes32 role) {

	// }

	constructor() {}
}

/// @notice PermissionCoreLib is a library that provides the basic functionality for managing permissions
library PermissionCoreLib {
	enum Status {
		NotMember,
		Active,
		Banned
	}
	/// @dev The PermissionCoreLib struct
	struct Member {
		uint256 permissions;
		Status membership;
	}

	/**
	 * @notice Add permission to the given user's permissions
	 * @param member The user
	 * @param permissionToAdd The permission to be added
	 */
	function grantPermission(Member storage member, uint8 permissionToAdd) internal returns (bool) {
		if (hasPermission(member, permissionToAdd)) {
			return false;
		} else {
			return _grantPermission(member, permissionToAdd);
		}
	}

	function _grantPermission(Member storage member, uint8 permissionToAdd) internal returns (bool) {
		member.permissions = member.permissions | (1 << permissionToAdd);
		return true;
	}

	/**
	 * @notice Remove permission from the given user's permissions
	 * @param member The user
	 * @param permissionToRemove The permission to be removed
	 */
	function revokePermission(
		Member storage member,
		uint8 permissionToRemove
	) internal returns (bool) {
		if (!hasPermission(member, permissionToRemove)) {
			return false;
		} else {
			return _revokePermission(member, permissionToRemove);
		}
	}

	function _revokePermission(
		Member storage member,
		uint8 permissionToRemove
	) internal returns (bool) {
		member.permissions = member.permissions & ~(1 << permissionToRemove);
		return true;
	}

	/**
	 * @notice Check if the given user has the given permission
	 * @param member The user
	 * @param permissionToCheck The permission to be checked
	 */
	function hasPermission(
		Member storage member,
		uint8 permissionToCheck
	) internal view returns (bool) {
		return (member.permissions & (1 << permissionToCheck)) != 0;
	}

	function isMember(Member storage member) internal view returns (bool) {
		return member.membership == Status.Active;
	}

	function isBanned(Member storage member) internal view returns (bool) {
		return member.membership == Status.Banned;
	}

	function grantMembership(Member storage member) internal returns (bool) {
		if (isMember(member)) {
			return false;
		} else {
			return _grantMembership(member);
		}
	}

	function _grantMembership(Member storage member) internal returns (bool) {
		member.membership = Status.Active;
		return true;
	}

	/**
	 * @notice Revoke membership from the given user
	 * @param member The user
	 */
	function revokeMembership(Member storage member) internal returns (bool) {
		if (!isMember(member)) {
			return false;
		} else {
			return _revokeMembership(member);
		}
	}

	function _revokeMembership(Member storage member) internal returns (bool) {
		member.membership = Status.Banned;
		return true;
	}
}