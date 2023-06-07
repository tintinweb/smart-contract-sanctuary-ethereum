// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721CreatorImplementation.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155CreatorImplementation.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/ICreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPolyOneCore.sol";
import "../interfaces/IPolyOneDrop.sol";
import "../libraries/PolyOneLibrary.sol";

/**
 * @title PolyOne Core
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs core functionality to faciliate the creation of drops, listings and administrative functions
 */
contract PolyOneCore is IPolyOneCore, AccessControl {
  bytes32 public constant override POLY_ONE_ADMIN_ROLE = keccak256("POLY_ONE_ADMIN_ROLE");
  bytes32 public constant override POLY_ONE_CREATOR_ROLE = keccak256("POLY_ONE_CREATOR_ROLE");

  mapping(address dropContractAddress => bool isRegistered) public dropContracts;
  mapping(address collectionAddress => Collection collectionParameters) public collections;
  mapping(uint256 dropId => uint256 tokenId) public dropTokenIds;

  uint256 public dropCounter = 0;

  address payable public feeWallet;
  uint16 public defaultPrimaryFee = 250;
  uint16 public defaultSecondaryFee = 250;

  constructor(address _superUser, address payable _feeWallet) {
    PolyOneLibrary.checkZeroAddress(_superUser, "super user");
    PolyOneLibrary.checkZeroAddress(_feeWallet, "fee wallet");
    _setupRole(DEFAULT_ADMIN_ROLE, _superUser);
    _setupRole(POLY_ONE_ADMIN_ROLE, _superUser);
    feeWallet = _feeWallet;
  }

  function allowCreator(address _creator) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_creator, "creator");
    grantRole(POLY_ONE_CREATOR_ROLE, _creator);
    emit CreatorAllowed(_creator);
  }

  function revokeCreator(address _creator) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_creator, "creator");
    revokeRole(POLY_ONE_CREATOR_ROLE, _creator);
    emit CreatorRevoked(_creator);
  }

  function registerDropContract(address _dropContract) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_dropContract, "drop contract");
    PolyOneLibrary.validateDropContract(_dropContract);
    if (dropContracts[_dropContract]) {
      revert AddressAlreadyRegistered(_dropContract);
    }

    dropContracts[_dropContract] = true;
    emit DropContractRegistered(_dropContract);
  }

  function registerCollection(address _collection, bool _isERC721) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    PolyOneLibrary.checkZeroAddress(_collection, "collection");
    PolyOneLibrary.validateProxyCreatorContract(_collection, _isERC721);
    PolyOneLibrary.validateContractOwner(_collection, address(this));
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);

    if (collections[_collection].registered) {
      revert AddressAlreadyRegistered(_collection);
    }

    collections[_collection] = Collection(true, _isERC721);
    emit CollectionRegistered(_collection, msg.sender, _isERC721);
  }

  function createDrop(
    address _dropContract,
    IPolyOneDrop.Drop calldata _drop,
    bytes calldata _data
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    PolyOneLibrary.validateContractCreator(_drop.collection, msg.sender);
    _validateDropContract(_dropContract);
    _validateCollectionRegistered(_drop.collection);
    _validateRoyaltyReceivers(_drop.royalties.saleReceivers, _drop.royalties.saleBasisPoints, defaultPrimaryFee);
    _validateRoyaltyReceivers(_drop.royalties.royaltyReceivers, _drop.royalties.royaltyBasisPoints, defaultSecondaryFee);
    PolyOneLibrary.validateArrayTotal(_drop.royalties.saleBasisPoints, 10000);

    uint256 dropId = ++dropCounter;
    emit DropCreated(_dropContract, dropId);
    IPolyOneDrop(_dropContract).createDrop(dropId, _drop, _data);
  }

  function updateDrop(
    uint256 _dropId,
    address _dropContract,
    IPolyOneDrop.Drop calldata _drop,
    bytes calldata _data
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    PolyOneLibrary.validateContractCreator(_drop.collection, msg.sender);
    _validateDropContract(_dropContract);
    _validateRoyaltyReceivers(_drop.royalties.saleReceivers, _drop.royalties.saleBasisPoints, defaultPrimaryFee);
    _validateRoyaltyReceivers(_drop.royalties.royaltyReceivers, _drop.royalties.royaltyBasisPoints, defaultSecondaryFee);
    PolyOneLibrary.validateArrayTotal(_drop.royalties.saleBasisPoints, 10000);

    emit DropUpdated(_dropContract, _dropId);
    IPolyOneDrop(_dropContract).updateDrop(_dropId, _drop, _data);
  }

  function updateDropRoyalties(
    uint256 _dropId,
    address _dropContract,
    IPolyOneDrop.Royalties calldata _royalties
  ) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    _validateDropContract(_dropContract);
    PolyOneLibrary.validateArrayTotal(_royalties.saleBasisPoints, 10000);

    emit DropUpdated(_dropContract, _dropId);
    IPolyOneDrop(_dropContract).updateDropRoyalties(_dropId, _royalties);
  }

  function registerPurchaseIntent(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external payable {
    _validateDropContract(_dropContract);

    emit PurchaseIntentRegistered(_dropContract, _dropId, _tokenIndex, msg.sender, msg.value);

    (bool instantClaim, address collection, string memory tokenURI, IPolyOneDrop.Royalties memory royalties) = IPolyOneDrop(_dropContract)
      .registerPurchaseIntent(_dropId, _tokenIndex, msg.sender, msg.value, _data);

    if (instantClaim) {
      _claimToken(collection, _dropId, _tokenIndex, msg.sender, tokenURI, msg.value, royalties);
    }
  }

  function claimToken(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external {
    _validateDropContract(_dropContract);

    (address collection, string memory tokenURI, IPolyOneDrop.Bid memory claim, IPolyOneDrop.Royalties memory royalties) = IPolyOneDrop(
      _dropContract
    ).validateTokenClaim(_dropId, _tokenIndex, msg.sender, _data);
    _claimToken(collection, _dropId, _tokenIndex, claim.bidder, tokenURI, claim.amount, royalties);
  }

  function mintTokensERC721(
    address _collection,
    address _recipient,
    uint256 _qty,
    string calldata _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    _validateCollectionRegistered(_collection);
    _validateCollectionType(_collection, true);
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);
    _validateRoyaltyReceivers(_royaltyReceivers, _royaltyBasisPoints, defaultSecondaryFee);

    for (uint256 i = 1; i <= _qty; i++) {
      _mintTokenERC721(_collection, i, _recipient, _baseTokenURI, _royaltyReceivers, _royaltyBasisPoints);
    }
  }

  function mintTokensERC1155(
    address _collection,
    string[] calldata _tokenURIs,
    uint256[] calldata _tokenIds,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] calldata _receivers,
    uint256[] calldata _amounts,
    bool _existingTokens
  ) external onlyRole(POLY_ONE_CREATOR_ROLE) {
    _validateCollectionRegistered(_collection);
    _validateCollectionType(_collection, false);
    PolyOneLibrary.validateContractCreator(_collection, msg.sender);

    if (_existingTokens) {
      _mintTokensERC1155Existing(_collection, _tokenIds, _receivers, _amounts);
    } else {
      _validateRoyaltyReceivers(_royaltyReceivers, _royaltyBasisPoints, defaultSecondaryFee);
      _mintTokensERC1155New(_collection, _tokenURIs, _royaltyReceivers, _royaltyBasisPoints, _receivers, _amounts);
    }
  }

  function callCollectionContract(address _collection, bytes calldata _data) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    _validateCollectionRegistered(_collection);

    emit CollectionContractCalled(_collection, msg.sender, _data);

    (bool success, bytes memory responseData) = _collection.call(_data);
    if (!success) {
      revert CallCollectionFailed(responseData);
    }
  }

  function setFeeWallet(address payable _feeWallet) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    PolyOneLibrary.checkZeroAddress(_feeWallet, "fee wallet");
    emit FeeWalletUpdated(_feeWallet);
    feeWallet = _feeWallet;
  }

  function setDefaultPrimaryFee(uint16 _newFee) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    emit DefaultFeesUpdated(_newFee, defaultSecondaryFee);
    defaultPrimaryFee = _newFee;
  }

  function setDefaultSecondaryFee(uint16 _newFee) external onlyRole(POLY_ONE_ADMIN_ROLE) {
    emit DefaultFeesUpdated(defaultPrimaryFee, _newFee);
    defaultSecondaryFee = _newFee;
  }

  function transferEth(address _destination, uint256 _amount) external onlyDropContract {
    PolyOneLibrary.checkZeroAddress(_destination, "destination");
    if (_amount == 0) {
      revert InvalidEthAmount();
    }

    (bool success, ) = _destination.call{value: _amount}("");
    if (!success) {
      revert EthTransferFailed(_destination, _amount);
    }
  }

  /**
   * @dev Initiate a token claim
   * @param _collection The address of the token collection contract
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   * @param _recipient The recipient of the tokens
   * @param _tokenURI The base of the tokenURI to use for the newly minted token
   * @param _amount The value of the token purchase being claimed
   * @param _royalties The royalties data for initial sale distribution and secondary royalties
   */
  function _claimToken(
    address _collection,
    uint256 _dropId,
    uint256 _tokenIndex,
    address _recipient,
    string memory _tokenURI,
    uint256 _amount,
    IPolyOneDrop.Royalties memory _royalties
  ) internal {
    _distributeFunds(_amount, _royalties.saleReceivers, _royalties.saleBasisPoints);
    _validateCollectionRegistered(_collection);
    PolyOneLibrary.checkZeroAddress(_recipient, "recipient");

    if (collections[_collection].isERC721) {
      uint256 tokenId = _mintTokenERC721(
        _collection,
        _tokenIndex,
        _recipient,
        _tokenURI,
        _royalties.royaltyReceivers,
        _royalties.royaltyBasisPoints
      );
      emit TokenClaimed(_collection, tokenId, _dropId, _tokenIndex, _recipient);
    } else {
      uint256 tokenId = dropTokenIds[_dropId];

      if (tokenId == 0) {
        uint256 newTokenId = _mintTokensERC1155New(
          _collection,
          PolyOneLibrary.stringToStringArray(_tokenURI),
          _royalties.royaltyReceivers,
          _royalties.royaltyBasisPoints,
          PolyOneLibrary.addressToAddressArray(_recipient),
          PolyOneLibrary.uintToUintArray(1)
        )[0];
        dropTokenIds[_dropId] = newTokenId;
        emit TokenClaimed(_collection, newTokenId, _dropId, _tokenIndex, _recipient);
      } else {
        _mintTokensERC1155Existing(
          _collection,
          PolyOneLibrary.uintToUintArray(tokenId),
          PolyOneLibrary.addressToAddressArray(_recipient),
          PolyOneLibrary.uintToUintArray(1)
        );
        emit TokenClaimed(_collection, tokenId, _dropId, _tokenIndex, _recipient);
      }
    }
  }

  /**
   * @dev Mint a single ERC721 token to a recipient
   * @param _collection The address of the token collection contract
   * @param _tokenIndex The index of the token in the drop
   * @param _recipient The address of the recipient
   * @param _baseTokenURI The base URI of the token
   * @param _royaltyReceivers The addresses of the royalty receivers
   * @param _royaltyBasisPoints The royalty basis points for each receiver
   * @return The newly minted token ID
   */
  function _mintTokenERC721(
    address _collection,
    uint256 _tokenIndex,
    address _recipient,
    string memory _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) internal returns (uint256) {
    ERC721CreatorImplementation collection = ERC721CreatorImplementation(_collection);
    string memory tokenURI = string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenIndex)));
    uint256 tokenId = collection.mintBase(_recipient, tokenURI);
    collection.setRoyalties(tokenId, _royaltyReceivers, _royaltyBasisPoints);
    return tokenId;
  }

  /**
   * @dev Mint a batch of new ERC1155 tokens to recipients and set royalties
   * @param _collection The address of the token collection contract
   * @param _tokenURIs The base tokenURI for each new token to be minted
   * @param _royaltyReceivers The addresses of the royalty receivers
   * @param _royaltyBasisPoints The royalty basis points for each receiver
   * @param _recipients The address of the recipients
   * @param _amounts The amount of the token to mint to each recipient
   * @return The tokenIds of the newly minted tokens
   */
  function _mintTokensERC1155New(
    address _collection,
    string[] memory _tokenURIs,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) internal returns (uint256[] memory) {
    ERC1155CreatorImplementation collection = ERC1155CreatorImplementation(_collection);
    uint256[] memory tokenIds = collection.mintBaseNew(_recipients, _amounts, _tokenURIs);
    for (uint i = 0; i < tokenIds.length; i++) {
      collection.setRoyalties(tokenIds[i], _royaltyReceivers, _royaltyBasisPoints);
    }
    return tokenIds;
  }

  /**
   * @dev Mint a batch of new ERC1155 tokens with existing tokenIds to a batch of recipients
   * @param _collection The address of the token collection contract
   * @param _tokenIds The ids of the tokens to mint
   * @param _recipients The address of the recipients
   * @param _amounts The amount of the token to mint to each recipient
   * @return The tokenIds of the newly minted tokens
   */
  function _mintTokensERC1155Existing(
    address _collection,
    uint256[] memory _tokenIds,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) internal returns (uint256[] memory) {
    ERC1155CreatorImplementation collection = ERC1155CreatorImplementation(_collection);
    collection.mintBaseExisting(_recipients, _tokenIds, _amounts);
    return _tokenIds;
  }

  /**
   * @dev Distribute funds to the primary sale recipients
   * @param _amount The amount to distribute
   * @param _receivers The addresses of the receivers
   * @param _receiverBasisPoints The basis points for each receiver
   */
  function _distributeFunds(uint256 _amount, address payable[] memory _receivers, uint256[] memory _receiverBasisPoints) internal {
    for (uint256 i = 0; i < _receivers.length; i++) {
      uint256 amount = (_amount * _receiverBasisPoints[i]) / 10000;
      (bool success, ) = _receivers[i].call{value: amount}("");
      if (!success) {
        revert EthTransferFailed(_receivers[i], amount);
      }
    }
  }

  /**
   * @dev Validate that a drop contract has already been registered
   * @param _dropContract The address of the drop contract
   */
  function _validateDropContract(address _dropContract) internal view {
    if (!dropContracts[_dropContract]) {
      revert DropContractNotRegistered(_dropContract);
    }
  }

  /**
   * @dev Validate that a token collection has already been registered
   * @param _collection The address of the collection
   */
  function _validateCollectionRegistered(address _collection) internal view {
    if (!collections[_collection].registered) {
      revert CollectionNotRegistered(_collection);
    }
  }

  /**
   * @dev Validate that a token collection is of the expected type (ERC721 or ERC1155)
   * @param _collection The address of the collection
   * @param _isERC721 Whether the collection is expected to be ERC721 (true) or ERC1155 (false)
   */
  function _validateCollectionType(address _collection, bool _isERC721) internal view {
    if (collections[_collection].isERC721 != _isERC721) {
      revert CollectionTypeMismatch(_collection);
    }
  }

  /**
   * @dev Validate that the secondary sale royalties are appriopriately formatted with PolyOne fees as the first item in each array
   * @param _royaltyReceivers The addresses of the royalty receivers (PolyOne fee wallet should be the first item in this array)
   * @param _royaltyBasisPoints The royalty basis points for each receiver (PolyOne fee should be the first item in this array)
   * @param _minimumFee The minimum fee that must be paid to PolyOne
   */
  function _validateRoyaltyReceivers(
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    uint16 _minimumFee
  ) internal view {
    if (_royaltyReceivers.length != _royaltyBasisPoints.length) {
      revert InvalidRoyaltySettings();
    }
    if (_royaltyReceivers[0] != feeWallet) {
      revert FeeWalletNotIncluded();
    }
    if (_royaltyBasisPoints[0] < _minimumFee) {
      revert InvalidPolyOneFee();
    }
  }

  /**
   * @dev Functions with the onlyDropContract modifier attached should only be callable by a registered PolyOneDrop contract
   */
  modifier onlyDropContract() {
    if (!dropContracts[msg.sender]) {
      revert PolyOneLibrary.InvalidCaller(msg.sender);
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../extensions/ICreatorExtensionTokenURI.sol";
import "../extensions/ICreatorExtensionRoyalties.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ReentrancyGuard, ICreatorCore, ERC165 {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressUpgradeable for address;

    uint256 internal _tokenCount = 0;

    // Base approve transfers address location
    address internal _approveTransferBase;

    // Track registered extensions data
    EnumerableSet.AddressSet internal _extensions;
    EnumerableSet.AddressSet internal _blacklistedExtensions;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;
    mapping (address => bool) private _extensionBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping (address => string) private _extensionURIPrefix;

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;

    // Royalty configurations
    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }
    mapping (address => RoyaltyConfig[]) internal _extensionRoyalty;
    mapping (uint256 => RoyaltyConfig[]) internal _tokenRoyalty;

    bytes4 private constant _CREATOR_CORE_V1 = 0x28f10a21;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorCore).interfaceId || interfaceId == _CREATOR_CORE_V1 || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    function requireExtension() internal view {
        require(_extensions.contains(msg.sender), "Must be registered extension");
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    function requireNonBlacklist(address extension) internal view {
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }   

    /**
     * @dev See {ICreatorCore-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i; i < _extensions.length();) {
            extensions[i] = _extensions.at(i);
            unchecked { ++i; }
        }
        return extensions;
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal virtual {
        require(extension != address(this) && extension.isContract(), "Invalid");
        emit ExtensionRegistered(extension, msg.sender);
        _extensionBaseURI[extension] = baseURI;
        _extensionBaseURIIdentical[extension] = baseURIIdentical;
        _extensions.add(extension);
        _setApproveTransferExtension(extension, true);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override {
        requireExtension();
        _setApproveTransferExtension(msg.sender, enabled);
    }

    /**
     * @dev Set whether or not tokens minted by the extension defers transfer approvals to the extension
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal virtual;

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address extension) internal {
        emit ExtensionUnregistered(extension, msg.sender);
        _extensions.remove(extension);
    }

    /**
     * @dev Blacklist an extension
     */
    function _blacklistExtension(address extension) internal {
       require(extension != address(0) && extension != address(this), "Cannot blacklist yourself");
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
       if (!_blacklistedExtensions.contains(extension)) {
           emit ExtensionBlacklisted(extension, msg.sender);
           _blacklistedExtensions.add(extension);
       }
    }

    /**
     * @dev Set base token uri for an extension
     */
    function _setBaseTokenURIExtension(string calldata uri, bool identical) internal {
        _extensionBaseURI[msg.sender] = uri;
        _extensionBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev Set token uri prefix for an extension
     */
    function _setTokenURIPrefixExtension(string calldata prefix) internal {
        _extensionURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev Set token uri for a token of an extension
     */
    function _setTokenURIExtension(uint256 tokenId, string calldata uri) internal {
        require(_tokenExtension(tokenId) == msg.sender, "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Set base token uri for tokens with no extension
     */
    function _setBaseTokenURI(string calldata uri) internal {
        _extensionBaseURI[address(0)] = uri;
    }

    /**
     * @dev Set token uri prefix for tokens with no extension
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _extensionURIPrefix[address(0)] = prefix;
    }


    /**
     * @dev Set token uri for a token with no extension
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        require(tokenId > 0 && tokenId <= _tokenCount && _tokenExtension(tokenId) == address(0), "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");

        address extension = _tokenExtension(tokenId);
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_extensionURIPrefix[extension]).length != 0) {
                return string(abi.encodePacked(_extensionURIPrefix[extension], _tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionTokenURI).interfaceId)) {
            return ICreatorExtensionTokenURI(extension).tokenURI(address(this), tokenId);
        }

        if (!_extensionBaseURIIdentical[extension]) {
            return string(abi.encodePacked(_extensionBaseURI[extension], tokenId.toString()));
        } else {
            return _extensionBaseURI[extension];
        }
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] memory receivers, uint256[] memory bps) {

        // Get token level royalties
        RoyaltyConfig[] memory royalties = _tokenRoyalty[tokenId];
        if (royalties.length == 0) {
            // Get extension specific royalties
            address extension = _tokenExtension(tokenId);
            if (extension != address(0)) {
                if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionRoyalties).interfaceId)) {
                    (receivers, bps) = ICreatorExtensionRoyalties(extension).getRoyalties(address(this), tokenId);
                    // Extension override exists, just return that
                    if (receivers.length > 0) return (receivers, bps);
                }
                royalties = _extensionRoyalty[extension];
            }
        }
        if (royalties.length == 0) {
            // Get the default royalty
            royalties = _extensionRoyalty[address(0)];
        }
        
        if (royalties.length > 0) {
            receivers = new address payable[](royalties.length);
            bps = new uint256[](royalties.length);
            for (uint i; i < royalties.length;) {
                receivers[i] = royalties[i].receiver;
                bps[i] = royalties[i].bps;
                unchecked { ++i; }
            }
        }
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] memory recievers) {
        (recievers, ) = _getRoyalties(tokenId);
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] memory bps) {
        (, bps) = _getRoyalties(tokenId);
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        (address payable[] memory receivers, uint256[] memory bps) = _getRoyalties(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");
        
        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], bps[0]*value/10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
       _checkRoyalties(receivers, basisPoints);
        delete _tokenRoyalty[tokenId];
        _setRoyalties(receivers, basisPoints, _tokenRoyalty[tokenId]);
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        _checkRoyalties(receivers, basisPoints);
        delete _extensionRoyalty[extension];
        _setRoyalties(receivers, basisPoints, _extensionRoyalty[extension]);
        if (extension == address(0)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ExtensionRoyaltiesUpdated(extension, receivers, basisPoints);
        }
    }

    /**
     * Helper function to check that royalties provided are valid
     */
    function _checkRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) private pure {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i; i < basisPoints.length;) {
            totalBasisPoints += basisPoints[i];
            unchecked { ++i; }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    /**
     * Helper function to set royalties
     */
    function _setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints, RoyaltyConfig[] storage royalties) private {
        for (uint i; i < basisPoints.length;) {
            royalties.push(
                RoyaltyConfig(
                    {
                        receiver: receivers[i],
                        bps: uint16(basisPoints[i])
                    }
                )
            );
            unchecked { ++i; }
        }
    }

    /**
     * @dev Set the base contract's approve transfer contract location
     */
    function _setApproveTransferBase(address extension) internal {
        _approveTransferBase = extension;
        emit ApproveTransferUpdated(extension);
    }

    /**
     * @dev See {ICreatorCore-getApproveTransfer}.
     */
    function getApproveTransfer() external view override returns (address) {
        return _approveTransferBase;
    }

    /**
     * @dev Get the extension for the given token
     */
    function _tokenExtension(uint256 tokenId) internal virtual view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC1155/IERC1155CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC1155/IERC1155CreatorExtensionBurnable.sol";
import "../permissions/ERC1155/IERC1155CreatorMintPermissions.sol";
import "./IERC1155CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator implementation
 */
abstract contract ERC1155CreatorCore is CreatorCore, IERC1155CreatorCore {

    uint256 constant public VERSION = 3;

    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered extensions data
    mapping (address => bool) internal _extensionApproveTransfers;
    mapping (address => address) internal _extensionPermissions;

    // For tracking which extension a token was minted by
    mapping (uint256 => address) internal _tokensExtension;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC1155CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {CreatorCore-_setApproveTransferExtension}
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal override {
        if (ERC165Checker.supportsInterface(extension, type(IERC1155CreatorExtensionApproveTransfer).interfaceId)) {
            _extensionApproveTransfers[extension] = enabled;
            emit ExtensionApproveTransferUpdated(extension, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "Invalid extension");
        require(permissions == address(0) || ERC165Checker.supportsInterface(permissions, type(IERC1155CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * If mint permissions have been set for an extension (extensions can mint by default),
     * check if an extension can mint via the permission contract's approveMint function.
     */
    function _checkMintPermissions(address[] memory to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        if (_extensionPermissions[msg.sender] != address(0)) {
            IERC1155CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenIds, amounts);
        }
    }

    /**
     * Post burn actions
     */
    function _postBurn(address owner, uint256[] calldata tokenIds, uint256[] calldata amounts) internal virtual {
        require(tokenIds.length > 0, "Invalid input");
        address extension = _tokensExtension[tokenIds[0]];
        for (uint i; i < tokenIds.length;) {
            require(_tokensExtension[tokenIds[i]] == extension, "Mismatched token originators");
            unchecked { ++i; }
        }
        // Callback to originating extension if needed
        if (extension != address(0)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC1155CreatorExtensionBurnable).interfaceId)) {
               IERC1155CreatorExtensionBurnable(extension).onBurn(owner, tokenIds, amounts);
           }
        }
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        address extension = _tokensExtension[tokenIds[0]];

        for (uint i; i < tokenIds.length;) {
            require(_tokensExtension[tokenIds[i]] == extension, "Mismatched token originators");
            unchecked { ++i; }
        }
        if (extension != address(0) && _extensionApproveTransfers[extension]) {
            require(IERC1155CreatorExtensionApproveTransfer(extension).approveTransfer(msg.sender, from, to, tokenIds, amounts), "Extension approval failure");
        } else if (_approveTransferBase != address(0)) {
            require(IERC1155CreatorExtensionApproveTransfer(_approveTransferBase).approveTransfer(msg.sender, from, to, tokenIds, amounts), "Extension approval failure");
        }
    }

    function _tokenExtension(uint256 tokenId) internal view override returns(address) {
        return _tokensExtension[tokenId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import "../permissions/ERC721/IERC721CreatorMintPermissions.sol";
import "./IERC721CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC721 creator implementation
 */
abstract contract ERC721CreatorCore is CreatorCore, IERC721CreatorCore {

    uint256 constant public VERSION = 3;

    bytes4 private constant _ERC721_CREATOR_CORE_V1 = 0x9088c207;

    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered extensions data
    mapping (address => bool) internal _extensionApproveTransfers;
    mapping (address => address) internal _extensionPermissions;

    // For tracking extension indices
    uint16 private _extensionCounter;
    mapping (address => uint16) internal _extensionToIndex;    
    mapping (uint16 => address) internal _indexToExtension;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCore).interfaceId || interfaceId == _ERC721_CREATOR_CORE_V1 || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {CreatorCore-_setApproveTransferExtension}
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal override {
        if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionApproveTransfer).interfaceId)) {
            _extensionApproveTransfers[extension] = enabled;
            emit ExtensionApproveTransferUpdated(extension, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "CreatorCore: Invalid extension");
        require(permissions == address(0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * If mint permissions have been set for an extension (extensions can mint by default),
     * check if an extension can mint via the permission contract's approveMint function.
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_extensionPermissions[msg.sender] != address(0)) {
            IERC721CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenId);
        }
    }

    /**
     * Override for pre mint actions
     */
    function _preMintBase(address, uint256) internal virtual {}

    
    /**
     * Override for pre mint actions for _mintExtension
     */
    function _preMintExtension(address, uint256) internal virtual {}

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId, address extension) internal virtual {
        // Callback to originating extension if needed
        if (extension != address(0)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionBurnable).interfaceId)) {
               IERC721CreatorExtensionBurnable(extension).onBurn(owner, tokenId);
           }
        }
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        } 
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256 tokenId) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        _approveTransfer(from, to, tokenId, _tokenExtension(tokenId));
    }

    function _approveTransfer(address from, address to, uint256 tokenId, uint16 extensionIndex) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        _approveTransfer(from, to, tokenId, _indexToExtension[extensionIndex]);
    }

    function _approveTransfer(address from, address to, uint256 tokenId, address extension) internal {
        // Do not need to approve mints
        if (from == address(0)) return;

        if (extension != address(0) && _extensionApproveTransfers[extension]) {
            require(IERC721CreatorExtensionApproveTransfer(extension).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
        } else if (_approveTransferBase != address(0)) {
           require(IERC721CreatorExtensionApproveTransfer(_approveTransferBase).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
        }
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal override {
        require(_extensionCounter < 0xFFFF, "Too many extensions");
        if (_extensionToIndex[extension] == 0) {
            ++_extensionCounter;
            _extensionToIndex[extension] = _extensionCounter;
            _indexToExtension[_extensionCounter] = extension;
        }
        super._registerExtension(extension, baseURI, baseURIIdentical);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ApproveTransferUpdated(address extension);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

    /**
     * @dev Set the default approve transfer contract location.
     */
    function setApproveTransfer(address extension) external; 

    /**
     * @dev Get the default approve transfer contract location.
     */
    function getApproveTransfer() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator interface
 */
interface IERC1155CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintBaseNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token with no extension. Can only be called by an admin.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintBaseExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev mint a token from an extension. Can only be called by a registered extension.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintExtensionNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token from extension. Can only be called by a registered extension.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev burn tokens. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev Total amount of tokens in with a given tokenId.
     */
    function totalSupply(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, uint80 data) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, uint80[] calldata data) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev get token data
     */
    function tokenData(uint256 tokenId) external view returns (uint80);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./core/ERC1155CreatorCore.sol";
import "./token/ERC1155/ERC1155Upgradeable.sol";

/**
 * @dev ERC1155Creator implementation
 */
contract ERC1155CreatorImplementation is AdminControlUpgradeable, ERC1155Upgradeable, ERC1155CreatorCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => uint256) private _totalSupply;

    /**
     * Initializer
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC1155_init(_name, _symbol);
        __Ownable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Core, ERC1155CreatorCore, AdminControlUpgradeable) returns (bool) {
        return ERC1155CreatorCore.supportsInterface(interfaceId) || ERC1155Core.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) internal virtual override {
        _approveTransfer(from, to, ids, amounts);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri_, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri_, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri_) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] calldata tokenIds, string[] calldata uris) external override {
        requireExtension();
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri_) external override adminRequired {
        _setBaseTokenURI(uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {
        _setTokenURI(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseNew}.
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory) {
        return _mintNew(address(0), to, amounts, uris);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseExisting}.
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant adminRequired {
        for (uint i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");
            require(_tokenExtension(tokenId) == address(0), "Token created by extension");
            unchecked { ++i; }
        }
        _mintExisting(address(0), to, tokenIds, amounts);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionNew}.
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        return _mintNew(msg.sender, to, amounts, uris);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionExisting}.
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant {
        requireExtension();
        for (uint i; i < tokenIds.length;) {
            require(_tokenExtension(tokenIds[i]) == address(msg.sender), "Token not created by this extension");
            unchecked { ++i; }
        }
        _mintExisting(msg.sender, to, tokenIds, amounts);
    }

    /**
     * @dev Mint new tokens
     */
    function _mintNew(address extension, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) internal returns(uint256[] memory tokenIds) {
        if (to.length > 1) {
            // Multiple receiver.  Give every receiver the same new token
            tokenIds = new uint256[](1);
            require(uris.length <= 1 && (amounts.length == 1 || to.length == amounts.length), "Invalid input");
        } else {
            // Single receiver.  Generating multiple tokens
            tokenIds = new uint256[](amounts.length);
            require(uris.length == 0 || amounts.length == uris.length, "Invalid input");
        }

        // Assign tokenIds
        for (uint i; i < tokenIds.length;) {
            ++_tokenCount;
            tokenIds[i] = _tokenCount;
            // Track the extension that minted the token
            _tokensExtension[_tokenCount] = extension;
            unchecked { ++i; }
        }

        if (extension != address(0)) {
            _checkMintPermissions(to, tokenIds, amounts);
        }

        if (to.length == 1 && tokenIds.length == 1) {
           // Single mint
           _mint(to[0], tokenIds[0], amounts[0], new bytes(0));
        } else if (to.length > 1) {
            // Multiple receivers.  Receiving the same token
            if (amounts.length == 1) {
                // Everyone receiving the same amount
                for (uint i; i < to.length;) {
                    _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
                    unchecked { ++i; }
                }
            } else {
                // Everyone receiving different amounts
                for (uint i; i < to.length;) {
                    _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
                    unchecked { ++i; }
                }
            }
        } else {
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        }

        for (uint i; i < tokenIds.length;) {
            if (i < uris.length && bytes(uris[i]).length > 0) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev Mint existing tokens
     */
    function _mintExisting(address extension, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) internal {
        if (extension != address(0)) {
            _checkMintPermissions(to, tokenIds, amounts);
        }

        if (to.length == 1 && tokenIds.length == 1 && amounts.length == 1) {
             // Single mint
            _mint(to[0], tokenIds[0], amounts[0], new bytes(0));            
        } else if (to.length == 1 && tokenIds.length == amounts.length) {
            // Batch mint to same receiver
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        } else if (tokenIds.length == 1 && amounts.length == 1) {
            // Mint of the same token/token amounts to various receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
                unchecked { ++i; }
            }
        } else if (tokenIds.length == 1 && to.length == amounts.length) {
            // Mint of the same token with different amounts to different receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
                unchecked { ++i; }
            }
        } else if (to.length == tokenIds.length && to.length == amounts.length) {
            // Mint of different tokens and different amounts to different receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[i], amounts[i], new bytes(0));
                unchecked { ++i; }
            }
        } else {
            revert("Invalid input");
        }
    }

    /**
     * @dev See {IERC1155CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address extension) {
        extension = _tokenExtension(tokenId);
        require(extension != address(0), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }

    /**
     * @dev See {IERC1155CreatorCore-burn}.
     */
    function burn(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner or approved");
        require(tokenIds.length == amounts.length, "Invalid input");
        if (tokenIds.length == 1) {
            _burn(account, tokenIds[0], amounts[0]);
        } else {
            _burnBatch(account, tokenIds, amounts);
        }
        _postBurn(account, tokenIds, amounts);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURI(tokenId);
    }
    
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] += amounts[i];
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] -= amounts[i];
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./core/ERC721CreatorCore.sol";
import "./token/ERC721/ERC721Upgradeable.sol";

/**
 * @dev ERC721Creator implementation
 */
contract ERC721CreatorImplementation is AdminControlUpgradeable, ERC721Upgradeable, ERC721CreatorCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Initializer
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Core, ERC721CreatorCore, AdminControlUpgradeable) returns (bool) {
        return ERC721CreatorCore.supportsInterface(interfaceId) || ERC721Core.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint96 data) internal virtual override {
        _approveTransfer(from, to, tokenId, uint16(data));
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] calldata tokenIds, string[] calldata uris) external override {
        requireExtension();
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, "", 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to, string calldata uri) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, uri, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += count;

        for (uint i; i < count;) {
            tokenIds[i] = _mintBase(to, "", firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += uris.length;

        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintBase(to, uris[i], firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBase(address to, string memory uri, uint256 tokenId) internal virtual returns(uint256) {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        // Call pre mint
        _preMintBase(to, tokenId);

        _safeMint(to, tokenId, 0);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, "", 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, uri, 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, uint80 data) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, "", data, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += count;

        for (uint i; i < count;) {
            tokenIds[i] = _mintExtension(to, "", 0, firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += uris.length;

        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintExtension(to, uris[i], 0, firstTokenId+i);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint80[] calldata data) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](data.length);
        uint256 firstTokenId = _tokenCount+1;
        _tokenCount += data.length;

        for (uint i; i < data.length;) {
            tokenIds[i] = _mintExtension(to, "", data[i], firstTokenId+i);
            unchecked { ++i; }
        }
    }
    
    /**
     * @dev Mint token via extension
     */
    function _mintExtension(address to, string memory uri, uint80 data, uint256 tokenId) internal virtual returns(uint256) {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        _checkMintPermissions(to, tokenId);
        // Call pre mint
        _preMintExtension(to, tokenId);

        _safeMint(to, tokenId, data << 16 | _extensionToIndex[msg.sender]);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address extension) {
        require(_exists(tokenId), "Nonexistent token");
        extension = _tokenExtension(tokenId);
        require(extension != address(0), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }

    /**
     * @dev See {IERC721CreatorCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        address owner = ownerOf(tokenId);
        address extension = _tokenExtension(tokenId);
        _burn(tokenId);
        _postBurn(owner, tokenId, extension);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        require(_exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
    }

    function _tokenExtension(uint256 tokenId) internal view override returns(address) {
        uint16 extensionIndex = uint16(_tokenData[tokenId].data);
        if (extensionIndex == 0) return address(0);
        return _indexToExtension[extensionIndex];
    }

    /**
     * @dev See {IERC721CreatorCore-tokenData}.
     */
    function tokenData(uint256 tokenId) external view returns (uint80) {
        return uint80(_tokenData[tokenId].data >> 16);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC1155CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator contract will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address operator, address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC1155CreatorExtensionBurnable is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC721CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address operator, address from, address to, uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC721CreatorExtensionBurnable is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable royalties
 */
interface ICreatorExtensionRoyalties is IERC165 {

    /**
     * Get the royalties for a given creator/tokenId
     */
    function getRoyalties(address creator, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155Creator compliant extension contracts.
 */
interface IERC1155CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Core is ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Core.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Non-Fungible Token Standard,
 */
abstract contract ERC1155Upgradeable is Initializable, ERC1155Core {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC1155_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC1155_init_unchained(name_, symbol_);
    }

    function __ERC1155_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 */
abstract contract ERC721Core is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    struct TokenData {
        address owner;
        uint96 data;
    }

    // Mapping from token ID to token data
    mapping(uint256 => TokenData) internal _tokenData;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
        address owner = _tokenData[tokenId].owner;
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Core.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
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
        _setApprovalForAll(msg.sender, operator, approved);
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
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
        return _tokenData[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Core.ownerOf(tokenId);
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
    function _safeMint(address to, uint256 tokenId, uint96 tokenData) internal virtual {
        _safeMint(to, tokenId, tokenData, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        uint96 tokenData,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, tokenData);

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _tokenData[tokenId] = TokenData({
            owner: to,
            data: tokenData
        });
        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, tokenData);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        TokenData memory tokenData = _tokenData[tokenId];
        address owner = tokenData.owner;
        uint96 data = tokenData.data;

        _beforeTokenTransfer(owner, address(0), tokenId, data);

        // Clear approvals
        _approve(address(0), tokenId);

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _tokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, data);
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
        TokenData memory tokenData = _tokenData[tokenId];
        address owner = tokenData.owner;
        require(owner == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint96 data = tokenData.data;

        _beforeTokenTransfer(from, to, tokenId, data);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _tokenData[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Core.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint96 tokenData
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint96 tokenData
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Core.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 */
abstract contract ERC721Upgradeable is Initializable, ERC721Core {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IAdminControl.sol";

abstract contract AdminControlUpgradeable is OwnableUpgradeable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title Interface for PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Interface for the PolyOneCreator Proxy contract
 */
interface IPolyOneCreator {
  /**
   * @notice The original creator of the contract. This is the only address that can reclaim ownership of the contract from PolyOneCore
   * @return The address of the creator
   */
  function creator() external view returns (address);

  /**
   * @notice The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @return The address of the implementation contract
   */
  function implementation() external view returns (address);
}

/**
 * @title PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @custom:contributor manifoldxyz (manifold.xyz)
 * @notice Deployable Proxy contract that delagates implementation to Manifold Core and registers the PolyOneCore contract as administrator
 */
contract PolyOneCreator is Proxy, IPolyOneCreator {
  address public immutable creator;

  /**
   * @param _name The name of the collection
   * @param _symbol The symbol for the collection
   * @param _implementationContract The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @param _polyOneCore The address of the PolyOneCore contract
   */
  constructor(string memory _name, string memory _symbol, address _implementationContract, address _polyOneCore) {
    assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _implementationContract;

    require(_implementationContract != address(0), "Implementation cannot be 0x0");
    (bool initSuccess, ) = _implementationContract.delegatecall(abi.encodeWithSignature("initialize(string,string)", _name, _symbol));
    require(initSuccess, "Initialization failed");

    require(_polyOneCore != address(0), "PolyOneCore cannot be 0x0");
    (bool approvePolyOneSuccess, ) = _implementationContract.delegatecall(
      abi.encodeWithSignature("transferOwnership(address)", _polyOneCore)
    );
    require(approvePolyOneSuccess, "PolyOneCore transfer failed");

    creator = msg.sender;
  }

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function implementation() public view returns (address) {
    return _implementation();
  }

  function _implementation() internal view override returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../interfaces/IPolyOneDrop.sol";

/**
 * @title Interface for PolyOne Core
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs core functionality to faciliate the creation of drops, listings and administrative functions
 */
interface IPolyOneCore {
  /**
   * @dev Structure of the parameters required for the registering of a new collection
   * @param registered Whether the collection is registered
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   * @param tokenIds Mapping of dropIds to tokenIds for ERC1155 collections. (Set by the first token mint for a drop)
   */
  struct Collection {
    bool registered;
    bool isERC721;
  }

  /**
   * @notice Thrown if a contract address is already registered
   * @param contractAddress The address of the contract
   */
  error AddressAlreadyRegistered(address contractAddress);

  /**
   * @notice Thrown if a collection was expected to be registered but currently isn't
   * @param collection The address of the collection contract
   */
  error CollectionNotRegistered(address collection);

  /**
   * @notice Thrown if an unregistered contract is being used to create a drop
   * @param dropContract The address of the unregistered contract
   */
  error DropContractNotRegistered(address dropContract);

  /**
   * @dev Thrown if a transfer of eth fails
   * @param destination The intented recipient
   * @param amount The amount of eth to be transferred
   */
  error EthTransferFailed(address destination, uint256 amount);

  /**
   * @dev Thrown if attempting to transfer an invalid eth amount
   */
  error InvalidEthAmount();

  /**
   * @dev Thrown if attempting to interact with a collection that is not of the expected type
   * @param collection The address of the collection contract
   */
  error CollectionTypeMismatch(address collection);

  /**
   * @dev Thrown if attempting to create or update a drop with invalid royalty settings
   */
  error InvalidRoyaltySettings();

  /**
   * @dev Thrown if attempting to create or update a drop with invalid PolyOne fee settings
   */
  error InvalidPolyOneFee();

  /**
   * @dev Thrown if attempting to create or udpate a drop without including the PolyOne fee wallet
   */
  error FeeWalletNotIncluded();

  /**
   * @dev Thrown if an arbitrary call to a collection contract fails
   * @param error The error thrown by the contract being called
   */
  error CallCollectionFailed(bytes error);

  /**
   * @notice Emitted when a creator is allowed to access the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorAllowed(address indexed creator);

  /**
   * @notice Emitted when a creator is revoked access to the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorRevoked(address indexed creator);

  /**
   * @notice Emitted when a drop contract is registered
   * @param dropContract The address of the drop contract implementation
   */
  event DropContractRegistered(address indexed dropContract);

  /**
   * @notice Emitted when a new token collection is registered
   * @param collection The address of the collection contract
   * @param creator The address of the creator who owns the contract
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  event CollectionRegistered(address indexed collection, address indexed creator, bool isERC721);

  /**
   * @notice Emitted when a new drop is created for a collection
   * @param dropContract The address of the drop contract for which the drop was created
   * @param dropId the id of the newly created drop
   */
  event DropCreated(address indexed dropContract, uint256 dropId);

  /**
   * @notice Emitted when a purchase intent is created for an auction or fixed price drop
   * @param dropContract The address of the drop contract for which the purchase intent was created
   * @param dropId The id of the drop for which the purchase intent was created
   * @param tokenIndex The index of the token in the drop for which the purchase intent was created
   * @param bidder The address of the bidder who registered the purchase intent
   * @param amount The amount of the purchase
   */
  event PurchaseIntentRegistered(address indexed dropContract, uint256 dropId, uint256 tokenIndex, address indexed bidder, uint256 amount);

  /**
   * @notice Emitted when a token is claimed by a claimant
   * @param collection The address of the token contract
   * @param tokenId The id of the newly minted token
   * @param dropId The id of the drop from which the token was minted
   * @param tokenIndex The index of the token in the drop
   * @param claimant The address of the claimant
   */
  event TokenClaimed(address indexed collection, uint256 tokenId, uint256 dropId, uint256 tokenIndex, address indexed claimant);

  /**
   * @notice Emitted when an existing drop is updated
   * @param dropContract The address of the drop contract for which teh drop was updated
   * @param _dropId The id of the drop that was updated
   */
  event DropUpdated(address indexed dropContract, uint256 _dropId);

  /**
   * @notice Emitted when the PolyOne fee wallet is updated
   * @param feeWallet The new PolyOne fee wallet
   */
  event FeeWalletUpdated(address feeWallet);

  /**
   * @notice Emitted when the PolyOne default primary or secondary fees are updated
   * @param primaryFee The new primary sale fee
   * @param secondaryFee The new secondary sale fee
   */
  event DefaultFeesUpdated(uint16 primaryFee, uint16 secondaryFee);

  /**
   * @notice Emitted when a collection contract is called with arbitrary calldata
   * @param collection The address of the collection contract
   * @param caller The address of the caller
   * @param data The data passed to the collection contract
   */
  event CollectionContractCalled(address indexed collection, address indexed caller, bytes data);

  /**
   * @notice Allow a creator to access the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorAllowed} event
   * @param _creator address of the creator
   */
  function allowCreator(address _creator) external;

  /**
   * @notice Revoke creator access from the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorRevoked} event
   * @param _creator address of the creator
   */
  function revokeCreator(address _creator) external;

  /**
   * @notice Register a new drop contract implementation to be used for Poly One token drops
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {DropContractRegistered} event
   *      _dropContract must implement the IPolyOneDrop interface
   * @param _dropContract The address of the drop contract implementation
   */
  function registerDropContract(address _dropContract) external;

  /**
   * @notice Register an ERC721 or ERC1155 collection to the PolyOne ecosystem
   * @dev The contract must extend the ERC721Creator or ERC1155Creator contracts to be compatible.
   *      Only callable by the POLY_ONE_CREATOR_ROLE, and caller must be the contract owner.
   *      The PolyOneCore contract must be assigned as an admin in the collection contract.
   *      Emits a {CollectionRegistered} event.
   * @param _collection The address of the token contract to register
   * @param _isERC721 Is the contract an ERC721 standard (true) or ERC1155 (false)
   */
  function registerCollection(address _collection, bool _isERC721) external;

  /**
   * @notice Create a new drop for an already registered collection and tokens that are already minted
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropCreated} event
   * @param _dropContract The implementation contract for the drop to be created
   * @param _drop The drop parameters (see {NewDrop} struct)
   * @param _data Any additional data that should be passed to the drop contract
   * */
  function createDrop(address _dropContract, IPolyOneDrop.Drop memory _drop, bytes calldata _data) external;

  /**
   * @notice Update an existing drop.
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropUpdated} event
   *      The collection address will be excluded from the update
   *      The drop must not have started yet
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _drop The updated drop information (not that collection address will be excluded)
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(uint256 _dropId, address _dropContract, IPolyOneDrop.Drop memory _drop, bytes calldata _data) external;

  /**
   * @notice Update the royalties
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Emits a {DropUpdatedEvent}
   *      The drop must not have started yet
   *      Only the total of saleReceivers are validated, there is not validation that PolyOne fees are included
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _royalties The updated royalties information
   */
  function updateDropRoyalties(uint256 _dropId, address _dropContract, IPolyOneDrop.Royalties memory _royalties) external;

  /**
   * @notice Register a bid for an existing drop
   * @dev Will call to an external contract for the bidding implementation depending on the drop type
   *      Emits a {PurchaseIntentRegistered} event
   * @param _dropId The id of the drop to register a bid for
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index of the token in the drop to bid on
   * @param _data Any additional data that should be passed to the drop contract
   */
  function registerPurchaseIntent(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external payable;

  /**
   * @notice Claim a token that has been won in an auction style drop
   * @dev This will always revert for fixed price (instant) style drops as the token has already been claimed
   *      Only callable by the winner of the sale
   * @param _dropId The id of the drop to claim a token from
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index in the drop of the token to claim
   * @param _data Any additional data that should be passed to the drop contract
   */
  function claimToken(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external;

  /**
   * @notice Mint new tokens to an existing registered ERC721 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _recipient The recipient of the tokens
   * @param _qty The number of tokens being minted
   * @param _baseTokenURI The base tokenURI the tokens to be minted
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   */
  function mintTokensERC721(
    address _collection,
    address _recipient,
    uint256 _qty,
    string calldata _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) external;

  /**
   * @notice Mint new tokens to an existing registered ERC1155 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _tokenURIs The base tokenURI for each new token to be minted
   * @param _tokenIds The ids of the tokens to mint
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   * @param _receivers The addresses to mint tokens to
   * @param _amounts The amounts of tokens to mint to each address
   * @param _existingTokens Is the set of tokens already existing in the collection (true) or a new batch of tokens (false). Cannot be mixed
   */
  function mintTokensERC1155(
    address _collection,
    string[] calldata _tokenURIs,
    uint256[] calldata _tokenIds,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] calldata _receivers,
    uint256[] calldata _amounts,
    bool _existingTokens
  ) external;

  /**
   * @notice Make an arbitrary contract call to the collection contract
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CollectionContractCalled} event
   * @param _data The data to call the collection contract with
   */
  function callCollectionContract(address _collection, bytes calldata _data) external;

  /**
   * @notice Mapping of drop contracts to whether they are registered
   * @param _dropContract The address of the drop contract
   * @return A boolean indicating whether the drop contract is registered
   */
  function dropContracts(address _dropContract) external view returns (bool);

  /**
   * @notice Mapping of token contract addresses to their collection data
   * @param _collection The address of the collection token contract
   * @return registered Whether the collection is registered
   * @return isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  function collections(address _collection) external view returns (bool registered, bool isERC721);

  /**
   * @notice Mapping of dropIds to the tokenId assigned to the drop for ERC1155 mints to differentiate between new and existing mint cases
   * @param _dropId The id of the drop to get the token id for
   * @return The tokenId assigned to the drop
   */
  function dropTokenIds(uint256 _dropId) external view returns (uint256);

  /**
   * @notice The number of drops that have been created. This counter is used to create incremental ids for each new drop registered
   * @dev The counter is incremented before the new drop is created, hence the first drop is always 1
   */
  function dropCounter() external view returns (uint256);

  /**
   * @notice The PolyOne fee wallet to collection primary and secondary sales
   */
  function feeWallet() external view returns (address payable);

  /**
   * @notice The default primary sale fee to apply to new collections and drops (in bps)
   */
  function defaultPrimaryFee() external view returns (uint16);

  /**
   * @notice The default secondary sale fee to apply to new collections and drops (in bps)
   */
  function defaultSecondaryFee() external view returns (uint16);

  /**
   * @notice Set the address for PolyOne fees from primary and secondary sales to be sent to
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _feeWallet The new fee wallet
   */
  function setFeeWallet(address payable _feeWallet) external;

  /**
   * @notice Set the default primary fee that is applied to new collections
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultPrimaryFee(uint16 _newFee) external;

  /**
   * @notice Set the default secondary fee that is applied to new collection
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultSecondaryFee(uint16 _newFee) external;

  /**
   * @notice Send eth to an address including error handling
   * @dev Only callable internally or by registered PolyOneDrop contracts
   * @param _destination The address to send the amount to
   * @param _amount The amount to send (in wei)
   */
  function transferEth(address _destination, uint256 _amount) external;

  /**
   * @notice Poly One Administrators allowed to perform administrative functions
   * @return The bytes32 representation of the POLY_ONE_ADMIN_ROLE
   */
  function POLY_ONE_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Poly One Creators allowed to mint new collections and create listings for their tokens
   * @return The bytes32 representation of the POLY_ONE_CREATOR_ROLE
   */
  function POLY_ONE_CREATOR_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title Interface for PolyOne Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Base interface for the creation of PolyOne drop listing contracts
 */
interface IPolyOneDrop {
  /**
   * @dev Structure of parameters required for the creation of a new drop
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  struct Drop {
    uint256 startingPrice;
    uint128 bidIncrement;
    uint128 qty;
    uint64 startDate;
    uint64 dropLength;
    address collection;
    string baseTokenURI;
    Royalties royalties;
  }

  /**
   * @dev Structure of parameters required for primary sale and secondary royalties
   *      This must include PolyOne's primary sale and secondary royalties
   *      The secondary royalties are optional but the primary sale royalties are not (they must total 100% in bps)
   * @param royaltyReceivers The addresses of the secondary royalty receivers. The PolyOne fee wallet should be the first in the array
   * @param royaltyBasisPoints The basis points of each of the secondary royalty receivers
   * @param saleReceivers The addresses of the primary sale receivers. The PolyOne fee wallet should be the first in the array
   * @param saleBasisPoints The basis points of each of the primary sale receivers
   */
  struct Royalties {
    address payable[] royaltyReceivers;
    uint256[] royaltyBasisPoints;
    address payable[] saleReceivers;
    uint256[] saleBasisPoints;
  }

  /**
   * @dev Structure of parameters required for a bid on a drop
   * @param bidder The address of the bidder
   * @param amount The value of the bid in wei
   */
  struct Bid {
    address bidder;
    uint256 amount;
  }

  /**
   * @dev Thrown if a drop is being access that does not exist on the drop contract
   * @param dropId The id of the drop that does not exist
   */
  error DropNotFound(uint256 dropId);

  /**
   * @dev Thrown if a token is being accessed that does not exist in a drop (i.e token index out of the drop range)
   * @param dropId The id of the drop being accessed
   * @param tokenIndex The index of the token being accessed
   */
  error TokenNotFoundInDrop(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if a drop is being created that already exists on the drop contract
   * @param dropId The id of the drop that already exists
   */
  error DropAlreadyExists(uint256 dropId);

  /**
   * @dev Thrown when attempting to modify a date that is not permitted (e.g a date in the past)
   * @param date The date that is invalid
   */
  error InvalidDate(uint256 date);

  /**
   * @dev Thrown if attempting to purchase a drop which has not started yet
   * @param dropId The id of the drop
   */
  error DropNotStarted(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase a drop which has already finished
   * @param dropId The id of the drop
   */
  error DropFinished(uint256 dropId);

  /**
   * @dev Thrown if attempting to claim a drop which has not yet finished
   * @param dropId The id of the drop
   */
  error DropInProgress(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase or bid on a token with an invalid amount
   * @param price The price that was attempted to be paid
   */
  error InvalidPurchasePrice(uint256 price);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token in the drop
   */
  error TokenAlreadyClaimed(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed or is not claimable by the caller
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token
   * @param claimant The address attempting to claim a token
   */
  error InvalidClaim(uint256 dropId, uint256 tokenIndex, address claimant);

  /**
   * @notice Registers a new upcoming drop
   * @param _dropId The id of the new drop to create
   * @param _drop The parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function createDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update an existing drop
   * @param _dropId The id of the existing drop
   * @param _drop The updated parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update the royalties for an existing drop
   * @param _dropId The id of the existing drop
   * @param _royalties The updated royalties for the drop
   */
  function updateDropRoyalties(uint256 _dropId, Royalties calldata _royalties) external;

  /**
   * @notice Register a bid (or intent to purchase) a token from PolyOne
   * @dev For fixed price drops, the amount must be equal to the starting price, and the token will be transferred instantly.
   *      For auction style drops, the amount must be greater than the starting price.
   * @param _dropId The id of the drop to place a purchase for
   * @param _tokenIndex The index of the token to purchase in this drop
   * @param _bidder The address of the bidder
   * @param _amount The amount of the purchase intent (in wei)
   * @param _data Any additional data that should be passed to the drop contract
   * @return instantClaim Whether this should be an instant claim (for fixed priced drop) or not (for auction style drops)
   * @return collection The collection address of the new token to be minted (if instant claim is also true)
   * @return tokenURI The token URI of the new token to be minted (if instant claim is also true)
   * @return royalties The royalties for the new token to be minted (if instant claim is also true)
   */
  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _bidder,
    uint256 _amount,
    bytes calldata _data
  ) external payable returns (bool instantClaim, address collection, string memory tokenURI, Royalties memory royalties);

  /**
   * @notice Validates that a token is allowed to be claimed by the claimant based on the status of the drop
   * @dev This will always revert for fixed price drops (where the bid increment is zero)
   *      This will return the claim data for fixed price drops if the token has been won by the claimaint and the auction has ended
   * @param _dropId The id of the drop to claim a token from
   * @param _tokenIndex The index of the token to claim
   * @param _caller The address of the claimant
   * @param _data Any additional data that should be passed to the drop contract
   * @return collection The collection address of the new token to be minted
   * @return tokenURI The token URI of the new token to be minted
   * @return claim The winning claim information (bidder and bid amount)
   * @return royalties The royalties for the new token to be minted
   */
  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _caller,
    bytes calldata _data
  ) external returns (address collection, string memory tokenURI, Bid memory claim, Royalties memory royalties);

  /**
   * @notice Mapping of drop ids to the drop parameters
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  function drops(
    uint256 _id
  )
    external
    view
    returns (
      uint256 startingPrice,
      uint128 bidIncrement,
      uint128 qty,
      uint64 startDate,
      uint64 dropLength,
      address collection,
      string memory baseTokenURI,
      Royalties memory royalties
    );

  /**
   * @notice Check if there is a currently active listing for a token
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingActive(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check if a token was previously listed and it has now ended either due to time or being claimed
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingEnded(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check the current claimed status of a listing
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@manifoldxyz/creator-core-solidity/contracts/core/ICreatorCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../implementations/PolyOneCreator.sol";
import "../interfaces/IPolyOneDrop.sol";

/**
 * @notice Shared helpers for Poly One contracts
 */
library PolyOneLibrary {
  /**
   * @dev Thrown whenever a zero-address check fails
   * @param field The name of the field on which the zero-address check failed
   */
  error ZeroAddress(string field);

  /**
   * @notice Thrown when attempting to validate a collection which is not of the expected ERC721Creator or ERC1155Creator type
   */
  error InvalidContractType();

  /**
   * @notice Throw if the caller is not the expected caller
   * @param _caller The caller of the function
   */
  error InvalidCaller(address _caller);

  /**
   * @notice Thrown if the total sale distribution percentage is not 100
   */
  error InvalidSaleDistribution();

  /**
   * @notice Thrown if an array total does not match
   */
  error ArrayTotalMismatch();

  /**
   * @notice Check if a field is the zero address, if so revert with the field name
   * @param _address The address to check
   * @param _field The name of the field to check
   */
  function checkZeroAddress(address _address, string memory _field) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }

  bytes4 constant ERC721_INTERFACE_ID = type(IERC721Metadata).interfaceId;
  bytes4 constant ERC1155_INTERFACE_ID = type(IERC1155MetadataURI).interfaceId;
  bytes4 constant CREATOR_CORE_INTERFACE_ID = type(ICreatorCore).interfaceId;

  /**
   * @notice Validate that a contract conforms to the expected standard by validating the interface support of an implementation contract
   *         via ERC165 `supportInterface` (see https://eips.ethereum.org/EIPS/eip-165)
   * @dev This will throw an unexpected error if the contract does not support ERC165
   * @param _contractAddress The address of the contract to validate
   * @param _isERC721 Whether the contract is an ERC721 (true) or ERC1155 (false)
   */
  function validateProxyCreatorContract(address _contractAddress, bool _isERC721) internal view {
    bytes4 expectedInterfaceId = _isERC721 ? ERC721_INTERFACE_ID : ERC1155_INTERFACE_ID;
    IERC165 implementation = IERC165(IPolyOneCreator(_contractAddress).implementation());
    if (!implementation.supportsInterface(expectedInterfaceId) || !implementation.supportsInterface(CREATOR_CORE_INTERFACE_ID)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a contract implements the IPolyOneDrop interface
   * @param _contractAddress The address of the contract to validate
   */
  function validateDropContract(address _contractAddress) internal view {
    IERC165 implementation = IERC165(_contractAddress);
    if (!implementation.supportsInterface(type(IPolyOneDrop).interfaceId)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a caller is the owner of a collection
   * @dev The contract address being check must inerit the OpenZeppelin Ownable standard
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the owner to validate
   * @return True if the caller is the owner of the contract
   */
  function validateContractOwner(address _contractAddress, address _caller) internal view returns (bool) {
    address owner = Ownable(_contractAddress).owner();
    if (owner != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Validate that a caller is the creator of a PolyOneCreator contract
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the caller to validate
   * @return True if the caller is the creator of the contract
   */
  function validateContractCreator(address _contractAddress, address _caller) internal view returns (bool) {
    address creator = IPolyOneCreator(_contractAddress).creator();
    if (creator != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Check if a date is in the past (before the current block timestamp)
   *         If the timestamps are equal, this is considered to be in the future
   */
  function isDateInPast(uint256 _date) internal view returns (bool) {
    return block.timestamp > _date;
  }

  /**
   * @dev Validate that the sum of all items in a uint array is equal to a given total
   * @param _array The array to validate
   * @param _total The total to validate against
   */
  function validateArrayTotal(uint256[] memory _array, uint256 _total) internal pure {
    uint256 total = 0;
    for (uint i = 0; i < _array.length; i++) {
      total += _array[i];
    }
    if (total != _total) {
      revert ArrayTotalMismatch();
    }
  }

  /**
   * @dev Convert an address to an array of length 1 with a single address
   * @param _address The address to convert
   * @return A length 1 array containing _address
   */
  function addressToAddressArray(address _address) internal pure returns (address[] memory) {
    address[] memory array = new address[](1);
    array[0] = _address;
    return array;
  }

  /**
   * @dev Convert a uint to an array of length 1 with a single address
   * @param _uint The uint to convert
   * @return A length 1 array containing _uint
   */
  function uintToUintArray(uint256 _uint) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _uint;
    return array;
  }

  /**
   * @dev Convert a string array to an array of length 1 with a single string
   * @param _string The string to convert
   * @return A length 1 array containing _string
   */
  function stringToStringArray(string memory _string) internal pure returns (string[] memory) {
    string[] memory array = new string[](1);
    array[0] = _string;
    return array;
  }
}