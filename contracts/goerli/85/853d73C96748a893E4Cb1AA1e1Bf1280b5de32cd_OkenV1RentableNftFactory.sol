// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/OkenV1Errors.sol";
import "../token/OkenV1RentableNft.sol";
import "./interfaces/IOkenV1RentableNftFactory.sol";

/// @title Rentable NFT Factory Contract
/// @notice This contract can be used to deploy `OkenV1RentableNft` contracts.
contract OkenV1RentableNftFactory is Ownable, IOkenV1RentableNftFactory {
    //--------------------------------- state variables

    // Address of `OkenV1RentMarketplace` contract
    address private _rentMarketplace;

    // Address of `OkenV1SellMarketplace` contract
    address private _sellMarketplace;

    // Fee to deploy a `OkenV1RentableNft` contract
    uint256 private _platformFee;

    // Address the fees are transferred to
    address payable _feeRecipient;

    // `OkenV1RentableNft` address -> exists in the factory
    mapping(address => bool) private _exists;

    // interface id of ERC4907
    bytes4 internal constant INTERFACE_ID_ERC4907 = 0xad092b5c;

    //--------------------------------- constructor

    constructor(
        address rentMarketplace,
        address sellMarketplace,
        uint256 platformFee,
        address payable feeRecipient
    ) {
        _rentMarketplace = rentMarketplace;
        _sellMarketplace = sellMarketplace;
        _platformFee = platformFee;
        _feeRecipient = feeRecipient;
    }

    //--------------------------------- factory functions

    /// @inheritdoc IOkenV1RentableNftFactory
    function deployNftContract(
        string memory name,
        string memory symbol,
        uint256 mintFee,
        address payable feeRecipient
    ) external payable override returns (address) {
        // require fees are paid
        if (msg.value < _platformFee) revert InsufficientFunds(_platformFee, msg.value);
        // send fees to fee recipient
        (bool success, ) = _feeRecipient.call{value: msg.value, gas: 2300}("");
        if (!success) revert TransferFailed();

        // deploy new `OkenV1RentableNft` contract
        OkenV1RentableNft nft = new OkenV1RentableNft(
            name,
            symbol,
            _rentMarketplace,
            _sellMarketplace,
            mintFee,
            feeRecipient
        );
        nft.transferOwnership(_msgSender());

        // update exists
        _exists[address(nft)] = true;
        emit NftContractAdded(_msgSender(), address(nft));
        return address(nft);
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function addNftContract(address nftContract) external override onlyOwner {
        // require not already added
        if (_exists[nftContract]) revert ContractAlreadyExists(nftContract);

        // check if contract is ERC4907
        if (!IERC165(nftContract).supportsInterface(INTERFACE_ID_ERC4907))
            revert InvalidNftAddress(nftContract);

        // update exists
        _exists[nftContract] = true;
        emit NftContractAdded(_msgSender(), nftContract);
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function removeNftContract(address nftContract) external override onlyOwner {
        // require contract exists
        if (!_exists[nftContract]) revert ContractNotExists(nftContract);

        // update exists
        _exists[nftContract] = false;
        emit NftContractRemoved(_msgSender(), nftContract);
    }

    //--------------------------------- accessors

    /// @inheritdoc IOkenV1RentableNftFactory
    function getExists(address nftContract) external view override returns (bool) {
        return _exists[nftContract];
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function getRentMarketplace() external view override returns (address) {
        return _rentMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function setRentMarketplace(address newRentMarketplace) external override onlyOwner {
        _rentMarketplace = newRentMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function getSellMarketplace() external view override returns (address) {
        return _sellMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function setSellMarketplace(address newSellMarketplace) external override onlyOwner {
        _sellMarketplace = newSellMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function getPlatformFee() external view override returns (uint256) {
        return _platformFee;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function setPlatformFee(uint256 newFee) external override onlyOwner {
        _platformFee = newFee;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function getFeeRecipient() external view override returns (address payable) {
        return _feeRecipient;
    }

    /// @inheritdoc IOkenV1RentableNftFactory
    function setFeeRecipient(address payable newRecipient) external override onlyOwner {
        _feeRecipient = newRecipient;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/OkenV1Errors.sol";
import "../token/ERC4907URIStorage.sol";
import "./interfaces/IOkenV1RentableNft.sol";

contract OkenV1RentableNft is ERC4907URIStorage, IOkenV1RentableNft, Ownable {
    //--------------------------------- state variables

    // variable to assign to token ID
    uint256 private _tokenCounter;

    // address of the `OkenV1RentMarketplace` contract
    address private _rentMarketplace;

    // address of the `OkenV1SellMarketplace` contract
    address private _sellMarketplace;

    // mint fee in WEI
    uint256 private _platformFee;

    // address the fees are transferred to
    address payable private _feeRecipient;

    //--------------------------------- constructor

    constructor(
        string memory name_,
        string memory symbol_,
        address rentMarketplace,
        address sellMarketplace,
        uint256 platformFee,
        address payable feeRecipient
    ) ERC721(name_, symbol_) {
        _tokenCounter = 0;
        _rentMarketplace = rentMarketplace;
        _sellMarketplace = sellMarketplace;
        _platformFee = platformFee;
        emit PlatformFeeUpdated(platformFee);
        _feeRecipient = feeRecipient;
        emit FeeRecipientUpdated(feeRecipient);
    }

    //--------------------------------- nft functions

    /// @inheritdoc IOkenV1RentableNft
    function mint(address to, string calldata uri) external payable override {
        // require fees are paid
        if (msg.value < _platformFee) revert InsufficientFunds(_platformFee, msg.value);

        // mint new rentable NFT
        uint256 tokenId = _tokenCounter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenCounter += 1;

        // send fee to fee recipient
        (bool success, ) = _feeRecipient.call{value: msg.value, gas: 2300}("");
        if (!success) revert TransferFailed();

        emit Minted(tokenId, to, _msgSender());
    }

    /// @inheritdoc IOkenV1RentableNft
    function burn(uint256 tokenId) external override {
        // require is owner or approved
        address operator = _msgSender();
        if ((ownerOf(tokenId) != operator) && (!isApproved(tokenId, operator)))
            revert NotOwnerNorApproved(operator);

        // burn token
        _burn(tokenId);
        emit Burned(tokenId, operator);
    }

    /// @inheritdoc IOkenV1RentableNft
    function isApproved(uint256 tokenId, address operator) public view override returns (bool) {
        return isApprovedForAll(ownerOf(tokenId), operator) || getApproved(tokenId) == operator;
    }

    /// @dev Override `isApprovedForAll()` to whitelist Oken contracts to enable gas-less listings
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if ((_rentMarketplace == operator) || (_sellMarketplace == operator)) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Override `_isApprovedOrOwner()` to whitelist Oken contracts to enable gas-less listings
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert NotExists(tokenId);
        address owner = ERC721.ownerOf(tokenId);
        if (isApprovedForAll(owner, spender)) return true;
        return super._isApprovedOrOwner(spender, tokenId);
    }

    //--------------------------------- accessors

    /// @inheritdoc IOkenV1RentableNft
    function getTokenCounter() external view override returns (uint256) {
        return _tokenCounter;
    }

    /// @inheritdoc IOkenV1RentableNft
    function getExists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc IOkenV1RentableNft
    function getRentMarketplace() external view override returns (address) {
        return _rentMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNft
    function getSellMarketplace() external view override returns (address) {
        return _sellMarketplace;
    }

    /// @inheritdoc IOkenV1RentableNft
    function getPlatformFee() external view override returns (uint256) {
        return _platformFee;
    }

    /// @inheritdoc IOkenV1RentableNft
    function setPlatformFee(uint256 newFee) external override onlyOwner {
        _platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    /// @inheritdoc IOkenV1RentableNft
    function getFeeRecipient() external view override returns (address payable) {
        return _feeRecipient;
    }

    /// @inheritdoc IOkenV1RentableNft
    function setFeeRecipient(address payable newRecipient) external override onlyOwner {
        _feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//------------------------------------- ETH transfer

/// @dev Thrown when not enough ETH is transferred
/// @param expected k
error InsufficientFunds(uint256 expected, uint256 actual);

/// @dev Thrown if `address.call{value: value}("")` returns false
error TransferFailed();

error InvalidCall(bytes data);

//------------------------------------- Nft

/// @dev Thrown if token ID does NOT exist
error NotExists(uint256 tokenId);

error NotOwner(address operator);

error NotApproved(address nftAddress, uint256 tokenId);

/// @dev Thrown if `operator` is neither owner nor approved for token ID nor approved for all
error NotOwnerNorApproved(address operator);

error InvalidNftAddress(address nftAddress);

error ContractAlreadyExists(address nftAddress);

error ContractNotExists(address nftAddress);

//------------------------------------- Marketplace

/// @notice Thrown when a transaction requires an item to be listed in the marketplace.
/// @param nftAddress Address of the NFT contract of the item
/// @param tokenId Token ID of the NFT item
/// @param owner Owner of the NFT item
error NotListed(address nftAddress, uint256 tokenId, address owner);

/// @notice Thrown when a transaction requires an item NOT to be listed in the marketplace.
/// @param nftAddress Address of the NFT contract
/// @param tokenId Token ID of the NFT item
/// @param owner Owner of the NFT item
error AlreadyListed(address nftAddress, uint256 tokenId, address owner);

error CurrentlyRented(address nftAddress, uint256 tokenId);

error InvalidExpires(uint64 expires);

error InvalidTimestamps(uint256 start, uint256 end);

error InvalidAmount(uint256 price);

error InvalidPayToken(address payToken);

error NoProceeds(address operator, address token);

error NotRedeemable(address nftAddress, uint256 tokenId);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Rentable NFT Factory Contract
/// @notice This contract can be used to deploy `OkenV1Nft` contracts.
interface IOkenV1RentableNftFactory {
    //--------------------------------- events

    /// @notice Emitted when a `OkenV1RentableNft` contract is deployed or added to this factory.
    /// @param operator Sender deploying or adding the contract
    /// @param nftContract `OkenV1RentableNft` contract added
    event NftContractAdded(address indexed operator, address indexed nftContract);

    /// @notice Emitted when a `OkenV1RentableNft` contract is removed from this factory.
    /// @param operator Sender removing the contract
    /// @param nftContract `OkenV1RentableNft` contract removed
    event NftContractRemoved(address indexed operator, address indexed nftContract);

    //--------------------------------- factory functions

    /// @notice Deploys a `OkenV1RentableNft` contract.
    /// @dev The transaction will revert if the ETH balance sent does not pay for the platform fee. A `NftContractAdded` event is emitted.
    /// @param name NFT contract name
    /// @param symbol NFT contract symbol
    /// @param mintFee Fee to mint a new NFT from the NFT contract
    /// @param feeRecipient Address the mint fees will be transferred to
    /// @return Address of the newly deployed `OkenV1RentableNft` contract
    function deployNftContract(
        string memory name,
        string memory symbol,
        uint256 mintFee,
        address payable feeRecipient
    ) external payable returns (address);

    /// @notice Adds an already deployed ERC4907 contract to the factory.
    /// @dev The transaction will revert if the contract is not ERC4907 or has already been added to the factory.
    /// `msg.sender` must be the contract owner.
    /// A `NftContractAdded` event is be emitted.
    /// @param nftContract Address of the ERC4907 contract
    function addNftContract(address nftContract) external;

    /// @notice Removes a `OkenV1RentableNft` contract from the factory.
    /// @dev The transaction will revert if the contract doesn't exist in the factory.
    /// `msg.sender` must be the contract owner.
    /// A `NftContractRemoved` event is be emitted.
    /// @param nftContract Address of the ERC4907 contract
    function removeNftContract(address nftContract) external;

    //--------------------------------- accessors

    /// @notice Returns `true` if `nftContract` exists in the factory.
    /// @param nftContract Address of the `OkenV1RentableNft` contract
    /// @return Exists in factory
    function getExists(address nftContract) external view returns (bool);

    /// @notice Returns the address of the `OkenV1RentMarketplace` contract.
    /// @return Address of the `OkenV1RentMarketplace` contract
    function getRentMarketplace() external view returns (address);

    /// @notice Modifies the address of the `OkenV1RentMarketplace` contract.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newRentMarketplace New `OkenV1RentMarketplace` contract address
    function setRentMarketplace(address newRentMarketplace) external;

    /// @notice Returns the address of the `OkenV1SellMarketplace` contract.
    /// @return Address of the `OkenV1SellMarketplace` contract
    function getSellMarketplace() external view returns (address);

    /// @notice Modify the address of the `OkenV1SellMarketplace` contract.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newSellMarketplace New `OkenV1SellMarketplace` contract address
    function setSellMarketplace(address newSellMarketplace) external;

    /// @notice Returns the platform fee, fee to deploy a new `OkenV1RentableNft` contract.
    /// @return Platform fee in WEI
    function getPlatformFee() external view returns (uint256);

    /// @notice Modify the platform fee, fee to deploy a new `OkenV1RentableNft` contract.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newFee New platform fee in WEI
    function setPlatformFee(uint256 newFee) external;

    /// @notice Returns the fee recipient, address the platform fees are transferred to.
    /// @return Fee recipient
    function getFeeRecipient() external view returns (address payable);

    /// @notice Modify the fee recipient, address the platform fees are transferred to.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newRecipient New fee recipient
    function setFeeRecipient(address payable newRecipient) external;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IERC4907.sol";

abstract contract ERC4907URIStorage is ERC721URIStorage, IERC4907 {
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;

    /// @notice set the user and expires of a Nft
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid Nft
    /// @param user  The new user of the Nft
    /// @param expires  UNIX timestamp, The new user could use the Nft before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get the user address of an Nft
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The Nft to get the user address for
    /// @return The user address for this Nft
    function userOf(uint256 tokenId) public view virtual override returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /// @notice Get the user expires of an Nft
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The Nft to get the user expires for
    /// @return The user expires for this Nft
    function userExpires(uint256 tokenId) public view virtual override returns (uint256) {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to) {
            _users[tokenId].user = address(0);
            _users[tokenId].expires = 0;
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC4907 Rentable NFT Contract
/// @notice This contract can be used to mint and burn rentable NFTs.
/// It implements the [ERC721](https://eips.ethereum.org/EIPS/eip-721), [ERC721Metadata](https://eips.ethereum.org/EIPS/eip-721), and [ERC4907](https://eips.ethereum.org/EIPS/eip-4907) interfaces.
/// The `OkenV1RentMarketplace` and `OkenV1SellMarketplace` are approved on all NFTs to enable gas-less listings.
interface IOkenV1RentableNft {
    //--------------------------------- events

    /// @notice Emitted when a rentable NFT is minted.
    /// @param tokenId Token ID of the newly minted NFT
    /// @param owner Owner of the newly minted NFT
    /// @param minter `msg.sender` minting the NFT
    event Minted(uint256 indexed tokenId, address indexed owner, address indexed minter);

    /// @notice Emitted when a rentable NFT is burned.
    /// @param tokenId Token ID of the burned NFT
    /// @param operator `msg.sender` burning the NFT
    event Burned(uint256 indexed tokenId, address indexed operator);

    /// @notice Emitted when the platform fee is modified.
    /// @param newFee New platform fee
    event PlatformFeeUpdated(uint256 indexed newFee);

    /// @notice Emitted when the fee recipient is modified.
    /// @param newRecipient New fee recipient
    event FeeRecipientUpdated(address payable indexed newRecipient);

    //--------------------------------- nft functions

    /// @notice Mints a new rentable NFT to `to` with token URI `uri`.
    /// @dev The ETH amount sent must pay for the platform fee. The token ID assigned to the NFT corresponds to the value of the token counter at the state of the transaction.
    /// This function emits a `Minted` event.
    /// @param to Owner of the newly minted NFT
    /// @param uri Token URI of the newly minted NFT
    function mint(address to, string calldata uri) external payable;

    /// @notice Burns the rentable NFT with token ID `tokenId`.
    /// @dev This function will revert if `msg.sender` isn't one of:
    /// - NFT owner
    /// - approved for NFT
    /// - approved for all on NFT owner
    /// - `OkenV1RentMarketplace` or `OkenV1SellMarketplace`
    /// @param tokenId Token ID of the NFT to burn
    function burn(uint256 tokenId) external;

    /// @notice Returns `true` if `operator` is either approved on NFT or approved for all on NFT owner.
    /// @param tokenId Token ID of the NFT
    /// @param operator Address to check approval for
    /// @return `operator` is either approved on NFT or approved for all on NFT owner
    function isApproved(uint256 tokenId, address operator) external view returns (bool);

    //--------------------------------- accessors

    /// @notice Returns the amount of rentable NFTs ever minted.
    /// @return Amount of NFTs ever minted
    function getTokenCounter() external view returns (uint256);

    /// @notice This function returns `true` if the rentable NFT with token ID `tokenId` exists.
    /// @param tokenId Token ID of the NFT
    /// @return NFT exists
    function getExists(uint256 tokenId) external view returns (bool);

    /// @notice Returns the address of the `OkenV1RentMarketplace` contract.
    /// @return Address of the `OkenV1RentMarketplace` contract
    function getRentMarketplace() external view returns (address);

    /// @notice Returns the address of the `OkenV1SellMarketplace` contract.
    /// @return Address of the `OkenV1SellMarketplace` contract
    function getSellMarketplace() external view returns (address);

    /// @notice Returns the platform fee for minting rentable NFTs in WEI.
    /// @return Platform fee in WEI
    function getPlatformFee() external view returns (uint256);

    /// @notice Modifies the platform fee for minting rentable NFTs.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newFee New platform fee in WEI
    function setPlatformFee(uint256 newFee) external;

    /// @notice Returns the fee recipient, address who the platform fees are transferred to.
    /// @return Fee recipient
    function getFeeRecipient() external view returns (address payable);

    /// @notice Modifies the fee recipient, address who the fees are transferred to.
    /// @dev The transaction will revert if `msg.sender` is not the contract owner.
    /// @param newRecipient New fee recipient
    function setFeeRecipient(address payable newRecipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an Nft or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a Nft
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid Nft
    /// @param user  The new user of the Nft
    /// @param expires  UNIX timestamp, The new user could use the Nft before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /// @notice Get the user address of an Nft
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The Nft to get the user address for
    /// @return The user address for this Nft
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an Nft
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The Nft to get the user expires for
    /// @return The user expires for this Nft
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}