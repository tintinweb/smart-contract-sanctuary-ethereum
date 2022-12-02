// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBiplesAddressRegistry {
    function erc721Factory() external view returns (address);

    function erc1155Factory() external view returns (address);
}

interface IBiplesFactory {
    function exists(address) external view returns (bool);
}

contract BiplesRoyaltyRegistry is Ownable {
    struct CollectionRoyalty {
        address creator;
        address royaltyRecipient;
        uint16 royaltyPercent;
    }

    /// @notice CollectionAddress -> CollectionRoyalty
    mapping(address => CollectionRoyalty) public collectionRoyalties;

    /// @notice Address registry
    IBiplesAddressRegistry public addressRegistry;

    function setCollectionCreator(
        address _nftAddress,
        address _collectionCreator
    ) external {
        require(
            _msgSender() == addressRegistry.erc721Factory() ||
                _msgSender() == addressRegistry.erc1155Factory() ||
                _msgSender() == owner()
        );
        require(_nftAddress != address(0), "Invalid collection address");
        require(_collectionCreator != address(0), "Invalid creator address");
        collectionRoyalties[_nftAddress].creator = _collectionCreator;
    }

    /// @notice Method for setting royalty
    /// @param _nftAddress NFT contract address
    /// @param _royaltyPercent Royalty
    function setCollectionRoyalty(
        address _nftAddress,
        uint16 _royaltyPercent,
        address _royaltyRecipient
    ) external {
        require(_nftAddress != address(0), "Invalid creator address");
        require(
            collectionRoyalties[_nftAddress].creator == _msgSender(),
            "Not a collection creator"
        );
        require(_royaltyPercent <= 10000, "Royalty too high");
        require(
            _royaltyPercent == 0 || _royaltyRecipient != address(0),
            "Invalid royalty percent and recipient address"
        );
        require(!_isBiplesNFT(_nftAddress), "Not registered NFT address");

        CollectionRoyalty storage collectionRoyalty = collectionRoyalties[
            _nftAddress
        ];

        collectionRoyalty.royaltyRecipient = _royaltyRecipient;
        collectionRoyalty.royaltyPercent = _royaltyPercent;
    }

    function _isBiplesNFT(address _nftAddress) internal view returns (bool) {
        return
            IBiplesFactory(addressRegistry.erc721Factory()).exists(
                _nftAddress
            ) ||
            IBiplesFactory(addressRegistry.erc1155Factory()).exists(
                _nftAddress
            );
    }

    function royaltyInfo(address _nftAddress, uint256 _salePrice)
        external
        view
        returns (address _royaltyRecipient, uint256 _royaltyAmount)
    {
        CollectionRoyalty memory royalty = collectionRoyalties[_nftAddress];

        _royaltyRecipient = royalty.royaltyRecipient;
        _royaltyAmount = (_salePrice * royalty.royaltyPercent) / 10000;

        return (_royaltyRecipient, _royaltyAmount);
    }

    /**
     @notice Update BiplesAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IBiplesAddressRegistry(_registry);
    }
}

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