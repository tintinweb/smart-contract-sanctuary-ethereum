/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/PoRAddressList.sol


pragma solidity ^0.8.0;

interface IPoRAddressList {
    /// @notice Get total number of addresses in the list.
    function getPoRAddressListLength() external view returns (uint256);

    /**
     * @notice Get a batch of human-readable addresses from the address list.
     * @dev Due to limitations of gas usage in off-chain calls, we need to support fetching the addresses in batches.
     * EVM addresses need to be converted to human-readable strings. The address strings need to be in the same format
     * that would be used when querying the balance of that address.
     * @param startIndex The index of the first address in the batch.
     * @param endIndex The index of the last address in the batch. If `endIndex > getPoRAddressListLength()-1`,
     * endIndex need to default to `getPoRAddressListLength()-1`. If `endIndex < startIndex`, the result would be an
     * empty array.
     * @return Array of addresses as strings.
     */
    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (string[] memory);
}

contract PoRAddressList is IPoRAddressList, Ownable {
    string[] private addresses;

    constructor(string[] memory _addresses) {
        addresses = _addresses;
    }

    function getPoRAddressListLength()
        external
        view
        override
        returns (uint256)
    {
        return addresses.length;
    }

    function setPoRAddressList(string[] memory _addresses) public onlyOwner {
        addresses = _addresses;
    }

    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        override
        returns (string[] memory)
    {
        if (startIndex > endIndex) {
            return new string[](0);
        }
        endIndex = endIndex > addresses.length - 1
            ? addresses.length - 1
            : endIndex;
        string[] memory stringAddresses = new string[](
            endIndex - startIndex + 1
        );
        uint256 currIdx = startIndex;
        uint256 strAddrIdx = 0;
        while (currIdx <= endIndex) {
            stringAddresses[strAddrIdx] = addresses[currIdx];
            strAddrIdx++;
            currIdx++;
        }
        return stringAddresses;
    }
}