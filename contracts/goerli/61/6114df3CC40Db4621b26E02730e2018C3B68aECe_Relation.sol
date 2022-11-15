// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Relation is Ownable {
    struct User {
        bool active; //激活
        address referrer; //上级
        uint256 subNum; //下级数量
        address[] subordinates; //下级所有地址
    }

    mapping(address => User) public userMap;
    mapping(address => bool) public operators; //
    address[] public allUsers;

    event BindRelationship(address account, address referrer);

    modifier onlyOperator() {
        require(
            operators[_msgSender()],
            "Relation: Caller is not the operator"
        );
        _;
    }

    function bind(address _account, address _referrer) external onlyOperator {
        if (userMap[_account].active) return;
        //全局
        allUsers.push(_account);
        //用户信息
        User storage userInfo = userMap[_account];
        userInfo.active = true;
        userInfo.referrer = _referrer;
        emit BindRelationship(_account, _referrer);
        //上级信息
        if (_referrer == address(0)) return;
        User storage referrerInfo = userMap[_referrer];
        referrerInfo.subordinates.push(_account);
        referrerInfo.subNum++;
    }

    function getReferrer(address account) external view returns (address) {
        return userMap[account].referrer;
    }

    function getAccountActive(address account) external view returns (bool) {
        return userMap[account].active;
    }

    function getSubordinates(address account)
        external
        view
        returns (address[] memory)
    {
        return userMap[account].subordinates;
    }

    function getSubNum(address account) external view returns (uint256) {
        return userMap[account].subNum;
    }

    function getTotalUserLen() external view returns (uint256) {
        return allUsers.length;
    }

    function setOperator(address[] memory operatorList, bool flag)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < operatorList.length; index++) {
            operators[operatorList[index]] = flag;
        }
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