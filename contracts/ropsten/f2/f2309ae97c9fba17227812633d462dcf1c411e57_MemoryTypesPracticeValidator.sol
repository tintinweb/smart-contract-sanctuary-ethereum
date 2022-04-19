// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMemoryTypesPractice {
    function setA(uint256 _a) external;
    function setB(uint256 _b) external;
    function setC(uint256 _c) external;
    function calc1() external view returns(uint256);
    function calc2() external view returns(uint256);
    function claimRewards(address _user) external;
    function addNewMan(
        uint256 _edge, 
        uint8 _dickSize, 
        bytes32 _idOfSecretBluetoothVacinationChip, 
        uint32 _iq
    ) external;
    function getMiddleDickSize() external view returns(uint256);
    function numberOfOldMenWithHighIq() external view returns(uint256);

    function userInfo() external view returns(address);
    function rewardsClaimed(address) external view returns(bool);
}

interface IUserInfo {
    struct User {
        uint256 balance;
        uint256 unlockTime;
    }

    function addUser(address _user, uint256 _balance, uint256 _unlockTime) external;
    function getUserInfo(address _user) external view returns(User memory);
}

contract MemoryTypesPracticeValidator {
    function validate(IMemoryTypesPractice _practice) external returns(bool) {
        if (
            !validate1(_practice) ||
            !validate2(_practice) ||
            !validate3(_practice) ||
            !validate4(_practice) ||
            !validate5(_practice) ||
            !validate6(_practice)
        ) return false;

        return true;
    }

    function validate1(IMemoryTypesPractice _practice) public returns(bool) {
        _practice.setA(21);
        _practice.setB(5);
        _practice.setC(8);
        require(_practice.calc1{gas: 785}() == 173, "MemoryTypesPracticeValidator: Wrong calc1");

        return true;
    }

    function validate2(IMemoryTypesPractice _practice) public view returns(bool) {
        require(_practice.calc2{gas: 10000}() == 522, "MemoryTypesPracticeValidator: Wrong calc2");

        return true;
    }

    function validate3(IMemoryTypesPractice _practice) public returns(bool) {
        IUserInfo ui = IUserInfo(_practice.userInfo());

        ui.addUser(address(this), 13000, 1);

        _practice.claimRewards{gas:24772}(address(this));
        require(_practice.rewardsClaimed(address(this)), "MemoryTypesPracticeValidator: Wrong claimReward");
        return true;
    }

    function validate4(IMemoryTypesPractice _practice) public returns(bool) {
        _practice.addNewMan{gas: 80000}(20, 15, bytes32("0x1"), 110);
        _practice.addNewMan{gas: 80000}(60, 13, bytes32("0x2"), 137);
        _practice.addNewMan{gas: 80000}(25, 50, bytes32("0x3"), 32);
        _practice.addNewMan{gas: 80000}(19, 21, bytes32("0x4"), 94);

        return true;
    }

    function validate5(IMemoryTypesPractice _practice) public view returns(bool) {
        require(_practice.getMiddleDickSize{gas: 15500}() == 20,
            "MemoryTypesPracticeValidator: wrong getMiddleDickSize");

        return true;
    }

    function validate6(IMemoryTypesPractice _practice) public view returns(bool) {
        require(_practice.numberOfOldMenWithHighIq{gas: 20012}() == 1,
            "MemoryTypesPracticeValidator: wrong numberOfOldMenWithHighIq");

        return true;
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