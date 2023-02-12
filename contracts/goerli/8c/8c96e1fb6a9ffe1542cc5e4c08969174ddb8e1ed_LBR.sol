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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract LBR is Ownable {
    address public activeContract;
    address public inactiveContract;

    bool public activeSet;
    bool public inactiveSet;

    mapping(uint256 => uint256) private _heartLiqs;
    mapping(uint256 => uint256) private _activeWithdrawn;

    modifier onlyActive {
        require(msg.sender == activeContract, "na");
        _;
    }

    modifier onlyInactive {
        require(msg.sender == inactiveContract, "ia");
        _;
    }

    modifier onlyHearts {
        require(msg.sender == activeContract || msg.sender == inactiveContract, "na");
        _;
    }

    /********/

    constructor (
        address _activeContract,
        address _inactiveContract
    ) {
        activeContract = _activeContract;
        inactiveContract = _inactiveContract;
    }

    /********/

    function _storeReward(uint256 heartId, uint256 msgValue) private {
        uint256 liqPortion = (msgValue*7)/10;
        _heartLiqs[heartId] += liqPortion + ((msgValue - liqPortion)<<128);
    }

    function storeReward(uint256 heartId) public payable onlyHearts {
//        uint256 liqPortion = (msg.value*7)/10;
//        _heartLiqs[heartId] += liqPortion + ((msg.value - liqPortion)<<128);
        _storeReward(heartId, msg.value);
    }

    function disburseLiquidationReward(uint256 heartId, address to) public onlyActive {
        uint256 toPay = _heartLiqs[heartId]%(1<<128);
        (bool success, ) = payable(to).call{value: toPay}("");
        require(success, "pf");
        _heartLiqs[heartId] -= toPay;
    }

    function disburseBurnReward(uint256 heartId, address to) public onlyInactive {
        uint256 toPay = _heartLiqs[heartId]>>128;
        (bool success, ) = payable(to).call{value: toPay}("");
        require(success, "pf");
        _heartLiqs[heartId] -= (toPay<<128);
    }

    function batchStoreReward(uint256[] calldata heartIds) public payable onlyHearts {
        uint256 remToDistribute = msg.value;
        uint256 perHeart = msg.value/heartIds.length;

        for (uint256 i = 0; i < (heartIds.length - 1); i++) {
            _storeReward(heartIds[i], perHeart);
            remToDistribute -= perHeart;
        }

        _storeReward(heartIds[heartIds.length - 1], remToDistribute);
    }

    function batchDisburseLiquidationReward(uint256[] calldata heartIds, address to) public onlyActive {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            amtToDisburse += _heartLiqs[heartId]%(1<<128);
            _heartLiqs[heartId] -= _heartLiqs[heartId]%(1<<128);
        }

        (bool success, ) = payable(to).call{value: amtToDisburse}("");
        require(success, "pf");
    }

    function batchDisburseBurnReward(uint256[] calldata heartIds, address to) public onlyInactive {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            uint256 amtToAdd = _heartLiqs[heartId]>>128;
            amtToDisburse += amtToAdd;
            _heartLiqs[heartId] -= amtToAdd<<128;
        }

        (bool success, ) = payable(to).call{value: amtToDisburse}("");
        require(success, "pf");
    }

    /********/

//    function setActiveContract() public {
//        require(tx.origin == owner(), "origin");
//        require(!activeSet, "as");
//        activeContract = msg.sender;
//        activeSet = true;
//    }
//
//    function setInactiveContract() public {
//        require(tx.origin == owner(), "origin");
//        require(!inactiveSet, "is");
//        inactiveContract = msg.sender;
//        inactiveSet = true;
//    }
}

////////////////////////////////////////