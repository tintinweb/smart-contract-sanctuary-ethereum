// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TinyKingdoms
 * @dev Another attempt to reduce the cost using calldata
 */
import "@openzeppelin/contracts/access/Ownable.sol";

contract TinyKingdomsMetadatav2 is Ownable{
    
    // mapping(uint8 => bytes) private kingdoms;
    bytes[] private flags;
    
    /**
     * @notice Batch add Flags.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyFlags(bytes[] calldata _flags) external onlyOwner {
        for (uint256 i = 0; i < _flags.length; i++) {
            _addFlag(_flags[i]);
        }
    }
    // ["0x", "0x536f6369616c6973742043616e796f6e204d6f756e7461696e73", "0x4672656520426f6720576f6f6473", "0x4e657720437265656b204c616b6573", "0x416e6369656e742052657075626c6963206f662053747265616d20576f6f6473", "0x5374617465206f662042697264736f6e67204c616b65", "0x43656e7472616c205061747465726e205061726b", "0x4b696e67646f6d206f66204d757368726f6f6d20537072696e6773", "0x43656e7472616c2057617465722043697479"]
    


    /**
     * @notice Add a flag.
     */
    function _addFlag(bytes calldata _flag) internal {
        flags.push(_flag);
    }

    /**
     * @notice Get the number of available flags.
     */
    function flagCount() external view returns (uint256) {
        return flags.length;
    }

    function getFlag(uint8 index) public view returns (string memory){
        return string(flags[index]);
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