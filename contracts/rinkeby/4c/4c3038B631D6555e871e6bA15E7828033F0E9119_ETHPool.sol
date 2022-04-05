/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ETHPool is Ownable {
    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    uint256 totalBalance;

    mapping(address => uint256) public depositAmount;
    mapping(address => uint256) public epochTime;
    address[] public users;

    modifier Sync() {
        _;
        totalBalance = address(this).balance;
    }

    function depositReward() external payable onlyOwner Sync {
        require(msg.value > 0, "must deposit");
        require(
            block.timestamp > epochTime[msg.sender],
            "can deposit once per week"
        );
        uint256 amount = msg.value;
        for (uint256 i = 0; i < users.length; i++) {
            depositAmount[users[i]] +=
                (amount * depositAmount[users[i]]) /
                totalBalance;
        }
        epochTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function deposit() external payable Sync {
        require(msg.value > 0, "must deposit");
        depositAmount[msg.sender] += msg.value;
        epochTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function withdraw() external nonReentrant {
        require(depositAmount[msg.sender] > 0, "must deposit before withdraw");
        require(
            epochTime[msg.sender] < block.timestamp,
            "You can withdraw after a week"
        );
        payable(msg.sender).transfer(depositAmount[msg.sender]);
    }
}