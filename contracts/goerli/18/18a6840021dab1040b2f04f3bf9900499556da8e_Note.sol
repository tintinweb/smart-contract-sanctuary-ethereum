/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface INote {
    function note1() external returns (uint256);

    function note2() external returns (uint256);

    function note3() external returns (uint256);

    function note4() external returns (uint256);

    function setAllNote(
        uint256 _note1,
        uint256 _note2,
        uint256 _note3,
        uint256 _note4
    ) external;

    function setNote1(uint256 _note1) external;

    function setNote12(uint256 _note1, uint256 _note2) external;

    function setNote123(
        uint256 _note1,
        uint256 _note2,
        uint256 _note3
    ) external;
}

contract Note is Ownable, INote {
    // errors
    error Note1Over1e18();
    error Note2Over1e18();
    error Note3Over1e18();
    error Note4Over1e18();

    //states
    uint256 public note1;
    uint256 public note2;
    uint256 public note3;
    uint256 public note4;

    function setAllNote(
        uint256 _note1,
        uint256 _note2,
        uint256 _note3,
        uint256 _note4
    ) external {
        if (_note1 > 1 ether) {
            revert Note1Over1e18();
        }
        if (_note2 > 1 ether) {
            revert Note2Over1e18();
        }
        if (_note3 > 1 ether) {
            revert Note3Over1e18();
        }
        if (_note4 > 1 ether) {
            revert Note4Over1e18();
        }
        note1 = _note1;
        note2 = _note2;
        note3 = _note3;
        note4 = _note4;
    }

    function setNote1(uint256 _note1) external {
        if (_note1 > 1 ether) {
            revert Note1Over1e18();
        }
        note1 = _note1;
    }

    function setNote12(uint256 _note1, uint256 _note2) external {
        if (_note1 > 1 ether) {
            revert Note1Over1e18();
        }
        if (_note2 > 1 ether) {
            revert Note2Over1e18();
        }
        note1 = _note1;
        note2 = _note2;
    }

    function setNote123(
        uint256 _note1,
        uint256 _note2,
        uint256 _note3
    ) external {
        if (_note1 > 1 ether) {
            revert Note1Over1e18();
        }
        if (_note2 > 1 ether) {
            revert Note2Over1e18();
        }
        if (_note3 > 1 ether) {
            revert Note3Over1e18();
        }
        note1 = _note1;
        note2 = _note2;
        note3 = _note3;
    }
}