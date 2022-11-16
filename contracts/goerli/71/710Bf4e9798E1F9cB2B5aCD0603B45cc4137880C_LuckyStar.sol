/**
 *Submitted for verification at BscScan.com on 2022-07-15
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev This contract provides services for the permanent storage of
 * LuckyStar DApp's participation records and the claim of winning information.
 */
contract LuckyStar is Ownable {
    struct Awards {
        address addr;
        string period;
        string winCode;
        bool isUsed;
    }

    struct Record {
        string hash;
        bool isUsed;
    }

    mapping(string => Record) public orders;
    mapping(string => Awards) public awards;

    /**
     * @dev Archive the `hash` value of all participating records in the current round (`period`).
     */
    function archive(string calldata period, string calldata hash)
        public
        onlyOwner
    {
        require(!orders[period].isUsed, "Record was archived.");
        require(bytes(hash).length != 0, "Invalid hash value");
        orders[period] = Record({hash: hash, isUsed: true});
    }

    /**
     * @dev Archive the current round (`period`) lottery result information, including winner address (`addr`) and winning code (`winCode`).
     */
    function claim(
        string calldata period,
        address addr,
        string calldata winCode
    ) public onlyOwner {
        require(!awards[period].isUsed, "Awards was claimed.");
        require(addr != address(0), "Winner address is the zero address");
        require(bytes(period).length != 0, "Parameter period is null");
        require(bytes(winCode).length != 0, "Parameter winCode is null");
        awards[period] = Awards({
            addr: addr,
            period: period,
            winCode: winCode,
            isUsed: true
        });
    }
}