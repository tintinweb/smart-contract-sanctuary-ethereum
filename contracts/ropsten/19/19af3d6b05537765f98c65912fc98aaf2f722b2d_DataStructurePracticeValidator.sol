// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IDataStructurePractice {
    struct User {
        string name;
        uint256 balance;
        bool isActive;
    }

    function setNewUser(address _userAdr, User calldata _newUser) external;
    function getUser(address _user) external view returns(User memory);
    function getMyInfo() external view returns(User memory);
}

contract DataStructurePracticeValidator {
    function validate(address _toValidate) external returns(bool) {
        require(Ownable(_toValidate).owner() == address(this), "DataStructurePracticeValidator: invalid owner");

        IDataStructurePractice _practice = IDataStructurePractice(_toValidate);

        address _myAddress = 0x9eCd08Fc708cDb77a33AFd83eb7f5ca4E4344766;

        IDataStructurePractice.User memory _me = IDataStructurePractice.User("Krasotulia", 42, true);
        IDataStructurePractice.User memory _this = 
            IDataStructurePractice.User("Honorable Mr Validator", 100500, true);

        _practice.setNewUser(_myAddress, _me);

        IDataStructurePractice.User memory _toCompare1 = _practice.getUser(_myAddress);

        require(_toCompare1.balance == _me.balance, "DataStructurePracticeValidator: getUser invalid balance");
        require(_toCompare1.isActive == _me.isActive, "DataStructurePracticeValidator: getUser invalid isActive");
        require(
            ((keccak256(abi.encodePacked((_toCompare1.name))) 
            == keccak256(abi.encodePacked((_me.name))))), 
            "DataStructurePracticeValidator: getUser invalid name"
        );

        IDataStructurePractice.User memory _toCompare2 = _practice.getUser(address(this));

        require(_toCompare2.balance == _this.balance, "DataStructurePracticeValidator: getUser invalid balance");
        require(_toCompare2.isActive == _this.isActive, "DataStructurePracticeValidator: getUser invalid isActive");
        require(
            ((keccak256(abi.encodePacked((_toCompare2.name))) 
            == keccak256(abi.encodePacked((_this.name))))), 
            "DataStructurePracticeValidator: getUser invalid name"
        );

        IDataStructurePractice.User memory _toCompare3 = _practice.getMyInfo();

        require(_toCompare3.balance == _this.balance, "DataStructurePracticeValidator: getMyInfo invalid balance");
        require(_toCompare3.isActive == _this.isActive, "DataStructurePracticeValidator: getMyInfo invalid isActive");
        require(
            ((keccak256(abi.encodePacked((_toCompare3.name))) 
            == keccak256(abi.encodePacked((_this.name))))), 
            "DataStructurePracticeValidator: getMyInfo invalid name"
        );

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