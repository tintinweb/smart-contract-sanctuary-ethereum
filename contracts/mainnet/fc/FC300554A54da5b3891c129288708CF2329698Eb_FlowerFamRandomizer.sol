// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./libraries/SimpleAccess.sol";

contract FlowerFamRandomizer is SimpleAccess {

    uint256 private seed;

    /**
     * @dev Each flower's species
     * is denoted by 8 bits. Each uint256
     * can hold the species data of 32 flowers.
     * In total we need to fill the array up with
     * 218 integers to accomodate 6969 species.
     *
     * To find the species of a flower with ID x we first
     * need to find the 32 species slot it falls in. The
     * formula for this is: slot = (x - 1) * 8 / 256.
     * 
     * To find the 8 bits in the 256 bits within the slot of
     * flower with ID x we need to use the following formula:
     * offset = (x - 1) * 8 % 256. Then we left shift the integer (<<)
     * with the offset and take the next 8 bits. The number we get
     * is the species.
     */
    mapping(uint256 => uint256) private species;

    constructor(uint256 _seed) {
        seed = _seed;
    }

    function rng(address _address) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, seed, _address)));
    }

    function rngDecision(address _address, uint256 probability, uint256 base) external view returns (bool) {
        uint256 randNum = rng(_address);

        uint256 decisionNum = randNum % base;

        return decisionNum < probability;
    }

    function _getSlotOfId(uint256 id)  internal pure returns (uint256) {
        return (id - 1) * 8 / 256;
    }

    function _getOffsetOfId(uint256 id) internal pure returns (uint256) {
        return (id - 1) * 8 % 256;
    }

    function getSpeciesOfId(uint256 id) external view returns (uint8) {
        require(id > 0, "Id must be greater than 0");
        
        uint256 slot = _getSlotOfId(id);
        uint256 offset = _getOffsetOfId(id);

        uint256 slotData = species[slot];
        return uint8(slotData >> offset);
    }

    function setSlotData(uint256[] calldata slots, uint256[] calldata datas) external onlyOwner {
        require(slots.length > 0, "Please provide a filled array");
        require(slots.length == datas.length, "Slots & data lengths not the same");

        for (uint i = 0; i < slots.length; i++) {
            species[slots[i]] = datas[i];
        }
    }

    function getSlotOfId(uint256 id)  external pure returns (uint256) {
        _getSlotOfId(id);
    }

    function getOffsetOfId(uint256 id) external pure returns (uint256) {
        return _getOffsetOfId(id);
    }

    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SimpleAccess is Ownable {
    
    constructor() Ownable() {}
    
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || msg.sender == owner(),
            "Sender is not authorized"
        );
        _;
    }

    function setAuthorized(address _auth, bool _isAuth) external virtual onlyOwner {
        authorized[_auth] = _isAuth;
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