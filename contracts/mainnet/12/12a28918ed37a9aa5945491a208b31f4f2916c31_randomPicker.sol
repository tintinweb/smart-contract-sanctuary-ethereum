/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/randomPicker.sol




pragma solidity 0.8.7;

contract randomPicker is Ownable {
    bool called = false;
    uint[] tokenIds = [13093,13094,13095,13096,13097,13098,13099,13100,13101,13102,13103,13104,13105];
    mapping (address => uint) addressToAllowance;
    uint[] tempAllowance;
    address[] tempAddresses;
    address[9] Addresses = [0x8DE0A7F3B9789921bE6934fa132049790A9D8b59,0x019aCCBe7f0823598eA968b7271f39735016DA9B,0x01Fe13639b3C0B9127412b6f8210e4753ac1Da37,0xf17cD420B438529C27eafF9E0ba10eF3aC2560aC,
    0x6b7a381c4B3E03A25772D91B95EEC51C12207E72,0xD66F3fd0f89f59409adAF7bDca536016A765670D,0x14F97F92Da702AF1eD4f09c5612Dd0Fd590403A0,0x7aC3a31b933575Abd7e249B8f391290A6c1844B9,
    0xB0216d1b4BBE34FD82C786364707188fdcdd9363];
    uint[] Allowances = [1,1,4,1,1,2,1,1,1];
    mapping (address => uint[]) addressToTokenIds;
    uint blockTimeStamp;
    struct result{
        address _ad;
        uint[] tokenIds;
    }

    constructor() { 
        for (uint i; i< Addresses.length;i++){
            addressToAllowance[Addresses[i]] = Allowances[i];
            tempAllowance.push(Allowances[i]);
            tempAddresses.push(Addresses[i]);
        }
    }

    function runPicker() external onlyOwner {
        require (called == false, "already runned");
        blockTimeStamp = block.timestamp; // store the block hash used as seed for the picker
        for (uint i; i<tokenIds.length;i++){

            uint random = randomNum(blockTimeStamp, i); // get a random number based on the remaining addresses with positive allowance

            addressToTokenIds[tempAddresses[random]].push(tokenIds[i]); // push the tokenId to the picked address 
            tempAllowance[random]--; // decrement the temporary allowance storage

            if (tempAllowance[random] ==0 && tempAddresses.length >1) // if the remaining allowance = 0, then delete the address from the array so it can't pick it anymore
                remove(random);
        }
        called = true;
    }

    function randomNum(uint _BTS, uint256 _tokenId) public view returns(uint256) { // return a number between 0 and the number of remaining addresses
      if (tempAddresses.length == 1) return 0;
      uint256 num = uint(keccak256(abi.encodePacked(_BTS, _tokenId))) % tempAddresses.length;
      return num;
    }

    function getAllowanceForAddress(address _ad) public view returns (uint) { // return the initial allowance of a specific address
        return addressToAllowance[_ad];
    }

    function remove(uint index) internal { // remove an address from the array
        for (uint i = index; i<(tempAddresses.length-1); i++){
                tempAddresses[i] = tempAddresses[i+1];
                tempAllowance[i] = tempAllowance[i+1];
        }
        tempAddresses.pop();
        tempAllowance.pop();
    }

    function getResults() external view returns (result[9] memory){ // get the results of the picker
        result[9] memory results;
        for (uint i;i<9;i++){
            results[i]._ad = Addresses[i];
            results[i].tokenIds = addressToTokenIds[Addresses[i]];
        }
        return results;
    }

    function getUsedTimestamp () external view returns (uint){ // return the hash used as seed
        return blockTimeStamp;
    }
}