//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./Administrable.sol";
import "./interfaces/IPermissionControl.sol";
import "./Globals.sol";

contract PermissionControl is Administrable, IPermissionControl {
    constructor() {
        _setStatus(_msgSender(), Globals.UserStatus.WHITELISTED);
    }

    mapping(address => Globals.UserStatus) _userStatus;

    function getStatus(address addr)
        public
        view
        override
        returns (Globals.UserStatus)
    {
        return _userStatus[addr];
    }

    function whitelist(address addr) external override returns (bool) {
        return _setStatus(addr, Globals.UserStatus.WHITELISTED);
    }

    function bulkWhitelist(address[] memory addresses)
        external
        override
        returns (bool)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _setStatus(addresses[i], Globals.UserStatus.WHITELISTED);
        }
        return true;
    }

    function limit(address addr) external override returns (bool) {
        return _setStatus(addr, Globals.UserStatus.LIMITED);
    }

    function blacklist(address addr) external override returns (bool) {
        return _setStatus(addr, Globals.UserStatus.BLACKLISTED);
    }

    function bulkBlacklist(address[] memory addresses)
        external
        override
        returns (bool)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _setStatus(addresses[i], Globals.UserStatus.BLACKLISTED);
        }
        return true;
    }

    function _setStatus(address addr, Globals.UserStatus status)
        internal
        onlyAdmin
        returns (bool)
    {
        emit UserStatusChanged(addr, _userStatus[addr], status);
        _userStatus[addr] = status;
        _emitEvent(addr, status);
        return true;
    }

    function _emitEvent(address addr, Globals.UserStatus status) internal {
        if (status == Globals.UserStatus.WHITELISTED) {
            emit Whitelisted(addr);
            return;
        }
        if (status == Globals.UserStatus.LIMITED) {
            emit Limited(addr);
            return;
        }
        if (status == Globals.UserStatus.BLACKLISTED) {
            emit Blacklised(addr);
            return;
        }
    }

    function addAdmin(address addr) public override onlyAdmin returns (bool) {
        if (super.addAdmin(addr)) {
            return _setStatus(addr, Globals.UserStatus.WHITELISTED);
        } else {
            return false;
        }
    }

    event UserStatusChanged(
        address indexed addr,
        Globals.UserStatus lastStatus,
        Globals.UserStatus currentStatus
    );
    event Whitelisted(address indexed addr);
    event Limited(address indexed addr);
    event Blacklised(address indexed addr);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/Pausable.sol";
import "./Globals.sol";

contract Administrable is Pausable {
    modifier onlyAdmin() {
        require(
            isAdmin(_msgSender()),
            "Administrable: Caller is not administrator"
        );
        _;
    }
    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "Adminstrable: Caller is not operator"
        );
        _;
    }

    constructor() {
        _addAdmin(_msgSender());
    }

    function isAdmin(address addr) public view returns (bool) {
        return _roles[Globals.Roles.ADMIN][addr];
    }

    function isOperator(address addr) public view returns (bool) {
        return _roles[Globals.Roles.OPERATOR][addr];
    }

    mapping(Globals.Roles => mapping(address => bool)) _roles;

    /**
     * @dev Allows an administrator to add new administrator address `addr`.
     * Returns bool which indicates success of operation.
     * Sender must be administrator.
     * `addr` can't be address(0)
     */
    function addAdmin(address addr) public virtual onlyAdmin returns (bool) {
        return _addAdmin(addr);
    }

    function _addAdmin(address addr) internal returns (bool) {
        require(addr != address(0));
        _roles[Globals.Roles.ADMIN][addr] = true;
        emit AdminChanged(
            uint256(Globals.StateOperation.ADD),
            addr,
            address(_msgSender())
        );
        return true;
    }

    function addOperator(address addr) public virtual onlyAdmin returns (bool) {
        require(addr != address(0));
        _roles[Globals.Roles.OPERATOR][addr] = true;
        emit OperatorChanged(
            uint256(Globals.StateOperation.REMOVE),
            addr,
            address(_msgSender())
        );
        return true;
    }

    /**
     * @dev   Allows an administrator to remove an existing administrator identified by address `addr`.
     * Administrators can’t remove `owner` from the list of administrators.
     * Sender must be administrator.
     * Returns bool, which indicates the success of the operation.
     */
    function removeAdmin(address addr) external onlyOwner returns (bool) {
        require(addr != owner() || _msgSender() == owner(), "Not allowed");
        _roles[Globals.Roles.ADMIN][addr] = false;
        emit AdminChanged(
            uint256(Globals.StateOperation.REMOVE),
            addr,
            address(_msgSender())
        );
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        addAdmin(newOwner);
        _roles[Globals.Roles.ADMIN][_msgSender()] = false;
        super.transferOwnership(newOwner);
    }

    event AdminChanged(
        uint256 stateChange,
        address indexed addr,
        address indexed from
    );
    event OperatorChanged(
        uint256 stateChange,
        address indexed addr,
        address indexed from
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Globals.sol";

interface IPermissionControl {
    function getStatus(address addr) external view returns (Globals.UserStatus);

    function whitelist(address addr) external returns (bool);

    function limit(address addr) external returns (bool);

    function blacklist(address addr) external returns (bool);

    function bulkWhitelist(address[] memory addresses) external returns (bool);

    function bulkBlacklist(address[] memory addresses) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./openzeppelin/IERC20.sol";
contract Globals {
    /**   Alternative Enum
     * enum UserStatus{
     *    NONE,
     *    APPROVED,
     *    SUSPENDED,
     *    BLOCKED
     *  }
     */

    enum UserStatus {
        NONE,
        WHITELISTED,
        LIMITED,
        BLACKLISTED
    }

    enum ERC20s {
        NONE,
        USDC,
        DXTA
    }
    enum Roles {
        NONE,
        OPERATOR,
        ADMIN
    }

    struct Yield {
        uint256 timestamp;
        uint256 apr;
    }

    struct Contribution {
        uint256 amount;
        uint256 burnableAfter;
        ERC20s depositedIn;
        uint256 nextYieldIndex;
        bool locked;
    }

    struct ContributionLite {
        uint256 amount;
        uint256 burnableAfter;
        IERC20 depositedIn;
        bool locked;
    }

    enum StateOperation{
        NONE,
        ADD,
        REMOVE,
        UPDATE
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (Pausable.sol)

pragma solidity ^0.8.1;

import "./Ownable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
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
    function pause() public whenNotPaused onlyOwner {
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
    function unpause() public whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (Ownable.sol)

pragma solidity ^0.8.1;

import "./Context.sol";

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
pragma solidity ^0.8.1;
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.1;

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