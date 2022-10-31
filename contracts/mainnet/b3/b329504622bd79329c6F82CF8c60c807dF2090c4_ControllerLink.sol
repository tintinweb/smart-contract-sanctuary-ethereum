// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../timelock/TimelockCallable.sol";
import "./IAccount.sol";

contract ControllerLink is TimelockCallable, Ownable {
    // Smart Account Count.
    uint256 public accounts;
    mapping(address => uint256) public accountID;
    mapping(uint256 => address) public accountAddr;
    mapping(address => UserLink) public userLink;
    mapping(address => mapping(uint256 => UserList)) public userList;

    address public trustFactory;
    address public timeLock;

    event NewAccount(address owner, address account);
    event DelAccount(address owner, address account);

    struct UserLink {
        uint256 first;
        uint256 last;
        uint256 count;
    }
    struct UserList {
        uint256 prev;
        uint256 next;
    }

    mapping(uint256 => AccountLink) public accountLink;
    mapping(uint256 => mapping(address => AccountList)) public accountList;

    struct AccountLink {
        address first;
        address last;
        uint256 count;
    }
    struct AccountList {
        address prev;
        address next;
    }

    constructor(address _timelock) TimelockCallable(_timelock) {}

    function initialize(address _trustFactory) external onlyTimelock {
        trustFactory = _trustFactory;
    }

    modifier onlyFactory() {
        require(msg.sender == trustFactory, "!trustFactory");
        _;
    }

    function accountVerification(address _owner, address _account)
        internal
        view
        returns (bool)
    {
        return IAccount(_account).owner() == _owner;
    }

    function addAuth(address _owner, address _account) external onlyFactory {
        require(
            accountVerification(_owner, _account),
            "Account addition verification failed!"
        );
        accounts++;
        accountID[_account] = accounts;
        accountAddr[accounts] = _account;
        addAccount(_owner, accounts);
        addUser(_owner, accounts);

        emit NewAccount(_owner, _account);
    }

    function removeAuth(address _owner, address _account) external {
        uint256 removeAccountID = accountID[_account];
        require(removeAccountID != 0, "not-account");
        require(
            accountVerification(_owner, _account) && msg.sender == _account,
            "Account deletion verification failed!"
        );
        removeAccount(_owner, removeAccountID);
        removeUser(_owner, removeAccountID);
        accountID[_account] = 0;

        emit DelAccount(_owner, _account);
    }

    function addAccount(address _owner, uint256 _account) internal {
        if (userLink[_owner].last != 0) {
            userList[_owner][_account].prev = userLink[_owner].last;
            userList[_owner][userLink[_owner].last].next = _account;
        }
        if (userLink[_owner].first == 0) userLink[_owner].first = _account;
        userLink[_owner].last = _account;
        userLink[_owner].count++;
    }

    function addUser(address _owner, uint256 _account) internal {
        if (accountLink[_account].last != address(0)) {
            accountList[_account][_owner].prev = accountLink[_account].last;
            accountList[_account][accountLink[_account].last].next = _owner;
        }
        if (accountLink[_account].first == address(0))
            accountLink[_account].first = _owner;
        accountLink[_account].last = _owner;
        accountLink[_account].count++;
    }

    function removeAccount(address _owner, uint256 _account) internal {
        uint256 _prev = userList[_owner][_account].prev;
        uint256 _next = userList[_owner][_account].next;
        if (_prev != 0) userList[_owner][_prev].next = _next;
        if (_next != 0) userList[_owner][_next].prev = _prev;
        if (_prev == 0) userLink[_owner].first = _next;
        if (_next == 0) userLink[_owner].last = _prev;
        userLink[_owner].count--;
        delete userList[_owner][_account];
    }

    function removeUser(address _owner, uint256 _account) internal {
        address _prev = accountList[_account][_owner].prev;
        address _next = accountList[_account][_owner].next;
        if (_prev != address(0)) accountList[_account][_prev].next = _next;
        if (_next != address(0)) accountList[_account][_next].prev = _prev;
        if (_prev == address(0)) accountLink[_account].first = _next;
        if (_next == address(0)) accountLink[_account].last = _prev;
        accountLink[_account].count--;
        delete accountList[_account][_owner];
    }

    function existing(address _account) external view returns (bool) {
        if (accountID[_account] == 0) {
            return false;
        } else {
            return true;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAccount {
    function owner() external view returns (address);

    function createSubAccount(bytes memory _data, uint256 _costETH)
        external
        payable
        returns (address newSubAccount);

    function executeOnAdapter(bytes calldata _callBytes, bool _callType)
        external
        payable
        returns (bytes memory);

    function multiCall(
        bool[] calldata _callType,
        bytes[] calldata _callArgs,
        bool[] calldata _isNeedCallback
    ) external;

    function setAdvancedOption(bool val) external;

    function callOnSubAccount(
        address _target,
        bytes calldata _callArgs,
        uint256 amountETH
    ) external;

    function withdrawAssets(
        address[] calldata _tokens,
        address _receiver,
        uint256[] calldata _amounts
    ) external;

    function approve(
        address tokenAddr,
        address to,
        uint256 amount
    ) external;

    function approveTokens(
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts
    ) external;

    function isSubAccount(address subAccount) external view returns (bool);
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