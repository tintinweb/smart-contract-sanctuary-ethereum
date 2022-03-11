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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CacheItemReceiver {
    function handleReceive(
        address _from,
        address _to,
        uint256 _type,
        uint256 _id,
        uint256 _ethValue,
        uint256 _primeValue,
        uint256[] memory _nftIds,
        uint256[] memory _nftQuantities,
        bytes memory _data
    ) external virtual;
}

contract ReceiverRouter is Ownable {
    address public parallelAuxiliaryItemsContractAddress =
        0x38398a2d7A4278b8d83967E0D235164335A0394A;
    mapping(uint256 => address) public typeToReceiver;

    function handleReceive(
        address userAddress,
        address receiverAddress,
        uint256 _type,
        uint256 id,
        uint256 ethValue,
        uint256 primeValue,
        uint256[] memory cardIds,
        uint256[] memory cardQuantities,
        bytes memory data
    ) public onlyParallelAuxiliaryItemsContract {
        require(
            typeToReceiver[_type] != address(0),
            "receiver address not set"
        );

        CacheItemReceiver(typeToReceiver[_type]).handleReceive(
            userAddress,
            receiverAddress,
            _type,
            id,
            ethValue,
            primeValue,
            cardIds,
            cardQuantities,
            data
        );
    }

    function setReceiver(uint256 _type, address receiverAddress)
        public
        onlyOwner
    {
        require(
            receiverAddress != address(0),
            "receiver address cannot be 0 address"
        );
        typeToReceiver[_type] = receiverAddress;
    }

    function setParallelAuxiliaryItemsContractAddress(address newAddr) public onlyOwner {
        require(
            newAddr != address(0),
            "PAI contract address cannot be 0 address"
        );
        parallelAuxiliaryItemsContractAddress = newAddr;
    }

    modifier onlyParallelAuxiliaryItemsContract() {
        require(
            msg.sender == parallelAuxiliaryItemsContractAddress,
            "only callable by PAI"
        );
        _;
    }
}