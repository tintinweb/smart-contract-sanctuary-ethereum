// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/ICollectionContractInitializer.sol";
import "./interfaces/ICollectionFactory.sol";
import "./interfaces/IGetRoyalties.sol";
import "./interfaces/IProxyCall.sol";
import "./interfaces/ITokenCreator.sol";
import "./interfaces/IGetFees.sol";
import "./interfaces/IRoyaltyInfo.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./libraries/AccountMigrationLibrary.sol";
import "./libraries/ProxyCall.sol";
import "./libraries/BytesLibrary.sol";

/**
 * @title A collection of NFTs by a single creator.
 * @notice All NFTs from this contract are minted by the same creator.
 * A 10% royalty to the creator is included which may be split with collaborators on a per-NFT basis.
 */
contract CollectionContract is
  ICollectionContractInitializer,
  IGetRoyalties,
  IGetFees,
  IRoyaltyInfo,
  ITokenCreator,
  ERC721BurnableUpgradeable
{
  using AccountMigrationLibrary for address;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using ProxyCall for IProxyCall;

  uint256 private constant ROYALTY_IN_BASIS_POINTS = 1000;
  uint256 private constant ROYALTY_RATIO = 10;

  /**
   * @notice The baseURI to use for the tokenURI, if undefined then `ipfs://` is used.
   */
  string private baseURI_;

  /**
   * @dev Stores hashes minted to prevent duplicates.
   */
  mapping(string => bool) private cidToMinted;

  /**
   * @notice The factory which was used to create this collection.
   * @dev This is used to read common config.
   */
  ICollectionFactory public immutable collectionFactory;

  /**
   * @notice The tokenId of the most recently created NFT.
   * @dev Minting starts at tokenId 1. Each mint will use this value + 1.
   */
  uint256 public latestTokenId;

  /**
   * @notice The max tokenId which can be minted, or 0 if there's no limit.
   * @dev This value may be set at any time, but once set it cannot be increased.
   */
  uint256 public maxTokenId;

  /**
   * @notice The owner/creator of this NFT collection.
   */
  address payable public owner;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   * The target address may be a contract which could split or escrow payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  /**
   * @dev Tracks how many tokens have been burned, used to calc the total supply efficiently.
   */
  uint256 private burnCounter;

  /**
   * @dev Stores a CID for each NFT.
   */
  mapping(uint256 => string) private _tokenCIDs;

  /**
   * @notice Emitted when the owner changes the base URI to be used for NFTs in this collection.
   * @param baseURI The new base URI to use.
   */
  event BaseURIUpdated(string baseURI);
  /**
   * @notice Emitted when the owner of this collection is changed through account migration.
   * @param originalAddress The address which was previously the owner.
   * @param newAddress The new address which is now the owner.
   */
  event CreatorMigrated(address indexed originalAddress, address indexed newAddress);
  /**
   * @notice Emitted when the max tokenId supported by this collection is defined.
   * @param maxTokenId The new max tokenId. All NFTs in this collection will have a tokenId less than
   * or equal to this value.
   */
  event MaxTokenIdUpdated(uint256 indexed maxTokenId);
  /**
   * @notice Emitted when a new NFT is minted.
   * @param creator The address of the collection owner at this time this NFT was minted.
   * @param tokenId The tokenId of the newly minted NFT.
   * @param indexedTokenCID The CID of the newly minted NFT, indexed to enable watching for mint events by the tokenCID.
   * @param tokenCID The actual CID of the newly minted NFT.
   */
  event Minted(address indexed creator, uint256 indexed tokenId, string indexed indexedTokenCID, string tokenCID);
  /**
   * @notice Emitted when the owner of an NFT is changed through account migration.
   * @param tokenId The tokenId of the NFT which was transferred.
   * @param originalAddress The address which was previously the owner.
   * @param newAddress The new address which is now the owner.
   */
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  /**
   * @notice Emitted when the payment address for an NFT is changed through account migration.
   * @param tokenId The tokenId of the NFT which had the payment address changed.
   * @param originalAddress The original recipient address for royalties that is being migrated.
   * @param newAddress The new recipient address for royalties.
   * @param originalPaymentAddress The original payment address for royalty payments.
   * @param newPaymentAddress The new payment address used to split royalty payments.
   */
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );
  /**
   * @notice Emitted when this collection is self destructed by the owner.
   * @param owner The collection owner at the time this collection was self destructed.
   */
  event SelfDestruct(address indexed owner);
  /**
   * @notice Emitted when the payment address for creator royalties is set.
   * @param fromPaymentAddress The original address used for royalty payments.
   * @param toPaymentAddress The new address used for royalty payments.
   * @param tokenId The NFT which had the royalty payment address updated.
   */
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "CollectionContract: Caller is not owner");
    _;
  }

  modifier onlyOperator() {
    require(collectionFactory.rolesContract().isOperator(msg.sender), "CollectionContract: Caller is not an operator");
    _;
  }

  /**
   * @notice Initialize the template's immutable variables.
   * @param _collectionFactory The factory which will be used to create collection contracts.
   */
  constructor(address _collectionFactory) {
    require(_collectionFactory.isContract(), "CollectionContract: collectionFactory is not a contract");
    collectionFactory = ICollectionFactory(_collectionFactory);
  }

  /**
   * @notice Called by the factory on creation.
   * @param _creator The creator of this collection contract.
   * @param _name The name of this collection.
   * @param _symbol The symbol for this collection.
   */
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external initializer {
    require(msg.sender == address(collectionFactory), "CollectionContract: Collection must be created via the factory");

    __ERC721_init_unchained(_name, _symbol);

    owner = _creator;
  }

  /**
   * @notice Allows an NFT owner or creator and Foundation to work together in order to update the creator
   * to a new account and/or transfer NFTs to that account.
   * @param ownedTokenIds The tokenIds of the NFTs owned by the original address to be migrated to the new account.
   * @param originalAddress The original account address to be migrated.
   * @param newAddress The new address for the account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any NFTs that have been burned or transferred.
   */
  function adminAccountMigration(
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external onlyOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);

    for (uint256 i = 0; i < ownedTokenIds.length; ++i) {
      uint256 tokenId = ownedTokenIds[i];
      // Check that the token exists and still is owned by the originalAddress
      // so that frontrunning a burn or transfer will not cause the entire tx to revert
      if (_exists(tokenId) && ownerOf(tokenId) == originalAddress) {
        _transfer(originalAddress, newAddress, tokenId);
        emit NFTOwnerMigrated(tokenId, originalAddress, newAddress);
      }
    }

    if (owner == originalAddress) {
      owner = newAddress;
      emit CreatorMigrated(originalAddress, newAddress);
    }
  }

  /**
   * @notice Allows a split recipient and Foundation to work together in order to update the payment address
   * to a new account.
   * @param paymentAddressTokenIds The token IDs for the NFTs to have their payment address migrated.
   * @param paymentAddressFactory The contract which was used to generate the payment address being migrated.
   * @param paymentAddressCallData The original call data used to generate the payment address being migrated.
   * @param addressLocationInCallData The position where the account to migrate begins in the call data.
   * @param originalAddress The original account address to be migrated.
   * @param newAddress The new address for the account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external onlyOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   * @param tokenId The tokenId of the NFT to burn.
   */
  function burn(uint256 tokenId) public override onlyOwner {
    super.burn(tokenId);
  }

  /**
   * @notice Allows the owner to mint an NFT defined by its metadata path.
   * @param tokenCID The CID of the NFT to mint.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mint(string calldata tokenCID) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
  }

  /**
   * @notice Allows the owner to mint and sets approval for all for the provided operator.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   * @param tokenCID The CID of the NFT to mint.
   * @param operator The address to set as the operator for this collection contract.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintAndApprove(string calldata tokenCID, address operator) external returns (uint256 tokenId) {
    tokenId = _mint(tokenCID);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * @param tokenCID The CID of the NFT to mint.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddress(string calldata tokenCID, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "CollectionContract: tokenCreatorPaymentAddress is required");
    tokenId = _mint(tokenCID);
    _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * Also sets approval for all for the provided operator.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   * @param tokenCID The CID of the NFT to mint.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @param operator The address to set as the operator for this collection contract.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddressAndApprove(
    string calldata tokenCID,
    address payable tokenCreatorPaymentAddress,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * @param tokenCID The CID of the NFT to mint.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactory(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData
  ) public returns (uint256 tokenId) {
    address payable tokenCreatorPaymentAddress = collectionFactory
      .proxyCallContract()
      .proxyCallAndReturnContractAddress(paymentAddressFactory, paymentAddressCallData);
    tokenId = mintWithCreatorPaymentAddress(tokenCID, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows the owner to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * Also sets approval for all for the provided operator.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate approval
   * transaction before starting an auction.
   * @param tokenCID The CID of the NFT to mint.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * @param operator The address to set as the operator for this collection contract.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactoryAndApprove(
    string calldata tokenCID,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData,
    address operator
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentFactory(tokenCID, paymentAddressFactory, paymentAddressCallData);
    setApprovalForAll(operator, true);
  }

  /**
   * @notice Allows the owner to assign a baseURI to use for the tokenURI instead of the default `ipfs://`.
   * @param baseURIOverride The new base URI to use for all NFTs in this collection.
   */
  function updateBaseURI(string calldata baseURIOverride) external onlyOwner {
    baseURI_ = baseURIOverride;

    emit BaseURIUpdated(baseURIOverride);
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract, if applicable.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   * @param _maxTokenId The max tokenId to set, all NFTs must have a tokenId less than or equal to this value.
   */
  function updateMaxTokenId(uint256 _maxTokenId) external onlyOwner {
    require(_maxTokenId != 0, "CollectionContract: Max token ID may not be cleared");
    require(maxTokenId == 0 || _maxTokenId < maxTokenId, "CollectionContract: Max token ID may not increase");
    require(latestTokenId + 1 <= _maxTokenId, "CollectionContract: Max token ID must be greater than last mint");
    maxTokenId = _maxTokenId;

    emit MaxTokenIdUpdated(_maxTokenId);
  }

  /**
   * @notice Allows the collection owner to destroy this contract only if
   * no NFTs have been minted yet.
   */
  function selfDestruct() external onlyOwner {
    require(totalSupply() == 0, "CollectionContract: Any NFTs minted must be burned first");
    emit SelfDestruct(msg.sender);
    selfdestruct(payable(msg.sender));
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = collectionFactory.proxyCallContract().proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = collectionFactory.proxyCallContract().proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // For each token, confirm the expected payment address and then update to the new one
    unchecked {
      // The array length cannot overflow 256 bits.
      for (uint256 i = 0; i < paymentAddressTokenIds.length; ++i) {
        uint256 tokenId = paymentAddressTokenIds[i];
        require(
          tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
          "CollectionContract: Payment address is not the expected value"
        );

        _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
        emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
      }
    }
  }

  function _burn(uint256 tokenId) internal override {
    delete cidToMinted[_tokenCIDs[tokenId]];
    delete tokenIdToCreatorPaymentAddress[tokenId];
    delete _tokenCIDs[tokenId];
    unchecked {
      // Number of burned tokens cannot overflow 256 bits.
      ++burnCounter;
    }
    super._burn(tokenId);
  }

  function _mint(string calldata tokenCID) private onlyOwner returns (uint256 tokenId) {
    require(bytes(tokenCID).length != 0, "CollectionContract: tokenCID is required");
    require(!cidToMinted[tokenCID], "CollectionContract: NFT was already minted");
    unchecked {
      // Number of tokens cannot overflow 256 bits.
      tokenId = ++latestTokenId;
      require(maxTokenId == 0 || tokenId <= maxTokenId, "CollectionContract: Max token count has already been minted");
      cidToMinted[tokenCID] = true;
      _tokenCIDs[tokenId] = tokenCID;
      _mint(msg.sender, tokenId);
      emit Minted(msg.sender, tokenId, tokenCID, tokenCID);
    }
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  /**
   * @notice Get the base URI used for all NFTs in this collection.
   * @return uri The base URI.
   */
  function baseURI() external view returns (string memory uri) {
    uri = _baseURI();
  }

  /**
   * @notice Returns an array of recipient addresses to which royalties for secondary sales should be sent.
   * The expected royalty amount is communicated with `getFeeBps`.
   * @param tokenId The tokenId of the NFT to get the royalty recipients for.
   * @return recipients An array of addresses to which royalties should be sent.
   */
  function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory recipients) {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
  }

  /**
   * @notice Returns an array of royalties to be sent for secondary sales in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   * @dev The tokenId param is ignored since all NFTs return the same value.
   * @return feesInBasisPoints The array of fees to be sent to each recipient, in basis points.
   */
  function getFeeBps(
    uint256 /* tokenId */
  ) external pure returns (uint256[] memory feesInBasisPoints) {
    feesInBasisPoints = new uint256[](1);
    feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice Checks if the creator has already minted a given NFT using this collection contract.
   * @param tokenCID The CID to check for.
   * @return hasBeenMinted True if the creator has already minted an NFT with this CID.
   */
  function getHasMintedCID(string calldata tokenCID) external view returns (bool hasBeenMinted) {
    hasBeenMinted = cidToMinted[tokenCID];
  }

  /**
   * @notice Returns an array of royalties to be sent for secondary sales.
   * @dev The data is the same as when calling getFeeRecipients and getFeeBps separately.
   * @param tokenId The tokenId of the NFT to get the royalties for.
   * @return recipients An array of addresses to which royalties should be sent.
   * @return feesInBasisPoints The array of fees to be sent to each recipient address.
   */
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints)
  {
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
    feesInBasisPoints = new uint256[](1);
    feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice Returns the desired payment address to be used for any transfers to the creator.
   * @dev The payment address may be assigned for each individual NFT, if not defined the collection owner is returned.
   * @param tokenId The tokenId of the NFT to get the royalties for.
   * @return tokenCreatorPaymentAddress The address to use for royalty payments for sales of this NFT.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = owner;
    }
  }

  /**
   * @notice Returns the receiver and the amount to be sent for a secondary sale.
   * @param tokenId The tokenId of the NFT to get the royalty recipient and amount for.
   * @param salePrice The total price of the sale.
   * @return receiver The royalty recipient address for this sale.
   * @return royaltyAmount The total amount that should be sent to the `receiver`.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = getTokenCreatorPaymentAddress(tokenId);
    unchecked {
      royaltyAmount = salePrice / ROYALTY_RATIO;
    }
  }

  /**
   * @notice Returns the creator of this NFT collection.
   * @dev The tokenId param is ignored since all NFTs return the same value.
   * @return creator The creator of this collection.
   */
  function tokenCreator(
    uint256 /* tokenId */
  ) external view returns (address payable creator) {
    creator = owner;
  }

  /**
   * @inheritdoc ERC165Upgradeable
   * @dev Checks the supported royalty interfaces.
   */
  function supportsInterface(bytes4 interfaceId) public view override returns (bool interfaceSupported) {
    if (
      interfaceId == type(IRoyaltyInfo).interfaceId ||
      interfaceId == type(ITokenCreator).interfaceId ||
      interfaceId == type(IGetRoyalties).interfaceId ||
      interfaceId == type(IGetFees).interfaceId
    ) {
      interfaceSupported = true;
    } else {
      interfaceSupported = super.supportsInterface(interfaceId);
    }
  }

  /**
   * @notice A distinct URI to the asset for a given NFT.
   * @param tokenId The tokenId of the NFT to get the URI for.
   * @return uri The URI for this NFT.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
    require(_exists(tokenId), "CollectionContract: URI query for nonexistent token");

    uri = string(abi.encodePacked(_baseURI(), _tokenCIDs[tokenId]));
  }

  /**
   * @notice Count of NFTs tracked by this contract.
   * @dev From the ERC-721 enumerable standard.
   * @return supply The total number of NFTs still tracked by this contract.
   */
  function totalSupply() public view returns (uint256 supply) {
    unchecked {
      // Number of tokens is always >= burned tokens.
      supply = latestTokenId - burnCounter;
    }
  }

  function _baseURI() internal view override returns (string memory) {
    if (bytes(baseURI_).length != 0) {
      return baseURI_;
    }
    return "ipfs://";
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICollectionContractInitializer {
  function initialize(
    address payable _creator,
    string memory _name,
    string memory _symbol
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface ICollectionFactory {
  function rolesContract() external returns (IRoles);

  function proxyCallContract() external returns (IProxyCall);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IGetRoyalties {
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IProxyCall {
  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    returns (address payable result);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ITokenCreator {
  function tokenCreator(uint256 tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
interface IGetFees {
  function getFeeRecipients(uint256 id) external view returns (address payable[] memory);

  function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for EIP-2981: NFT Royalty Standard.
 * For more see: https://eips.ethereum.org/EIPS/eip-2981.
 */
interface IRoyaltyInfo {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
error AccountMigrationLibrary_Signature_Verification_Failed();

/**
 * @title A library which confirms account migration signatures.
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT contracts and FNDNFTMarket, and the same signature authorizes both.
 */
library AccountMigrationLibrary {
  using ECDSA for bytes;
  using SignatureChecker for address;
  using Strings for uint256;

  /**
   * @notice Confirms the msg.sender is a Foundation operator and that the signature provided is valid.
   * @param originalAddress The address of the account to be migrated.
   * @param newAddress The new address representing this account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function requireAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes calldata signature
  ) internal view {
    if (originalAddress == newAddress) {
      revert AccountMigrationLibrary_Cannot_Migrate_Account_To_Itself();
    }
    bytes32 hash = abi
      .encodePacked("I authorize Foundation to migrate my account to ", _toAsciiString(newAddress))
      .toEthSignedMessageHash();
    if (!originalAddress.isValidSignatureNow(hash, signature)) {
      revert AccountMigrationLibrary_Signature_Verification_Failed();
    }
  }

  /**
   * @notice Converts an address into a string.
   * @dev From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
   */
  function _toAsciiString(address x) private pure returns (string memory) {
    unchecked {
      bytes memory s = new bytes(42);
      s[0] = "0";
      s[1] = "x";
      for (uint256 i = 0; i < 20; ++i) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
      }
      return string(s);
    }
  }

  /**
   * @notice Converts a byte to a UTF-8 character.
   */
  function _char(bytes1 b) private pure returns (bytes1 c) {
    unchecked {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IProxyCall.sol";

/**
 * @title A library which forwards arbitrary calls to an external contract to be processed.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 */
library ProxyCall {
  using AddressUpgradeable for address payable;

  /**
   * @dev Used by other mixins to make external calls through the proxy contract.
   * This will fail if the proxyCall address is address(0).
   */
  function proxyCallAndReturnContractAddress(
    IProxyCall proxyCall,
    address externalContract,
    bytes memory callData
  ) internal returns (address payable result) {
    result = proxyCall.proxyCallAndReturnAddress(externalContract, callData);
    require(result.isContract(), "ProxyCall: address returned is not a contract");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

error BytesLibrary_Expected_Address_Not_Found();

/**
 * @title A library for manipulation of byte arrays.
 */
library BytesLibrary {
  /**
   * @dev Replace the address at the given location in a byte array if the contents at that location
   * match the expected address.
   */
  function replaceAtIf(
    bytes memory data,
    uint256 startLocation,
    address expectedAddress,
    address newAddress
  ) internal pure {
    bytes memory expectedData = abi.encodePacked(expectedAddress);
    bytes memory newData = abi.encodePacked(newAddress);
    unchecked {
      // An address is 20 bytes long
      for (uint256 i = 0; i < 20; ++i) {
        uint256 dataLocation = startLocation + i;
        if (data[dataLocation] != expectedData[i]) {
          revert BytesLibrary_Expected_Address_Not_Found();
        }
        data[dataLocation] = newData[i];
      }
    }
  }

  /**
   * @dev Checks if the call data starts with the given function signature.
   */
  function startsWith(bytes memory callData, bytes4 functionSig) internal pure returns (bool) {
    // A signature is 4 bytes long
    if (callData.length < 4) {
      return false;
    }
    unchecked {
      for (uint256 i = 0; i < 4; ++i) {
        if (callData[i] != functionSig[i]) {
          return false;
        }
      }
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which implements admin roles.
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./FNDNFTMarket.sol";
import "./PercentSplitETH.sol";
import "./CollectionContract.sol";
import "./mixins/Constants.sol";
import "./FETH.sol";
import "./interfaces/ens/IENS.sol";
import "./interfaces/ens/IPublicResolver.sol";
import "./interfaces/ens/IReverseRegistrar.sol";

error FNDMiddleware_Contract_Is_Not_ERC721();
error FNDMiddleware_No_Royalty_Recipients_Defined();
error FNDMiddleware_Royalty_Recipient_Address_0();
error FNDMiddleware_Royalty_Recipient_Not_Receivable(address recipient);

/**
 * @title Convenience methods to ease integration with other contracts.
 * @notice This will aggregate calls and format the output per the needs of our frontend or other consumers.
 */
contract FNDMiddleware is Constants {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Strings for uint256;
  using OZERC165Checker for address;

  struct Fee {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
  }
  struct FeeWithRecipient {
    uint256 percentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }
  struct RevSplit {
    uint256 relativePercentInBasisPoints;
    uint256 absolutePercentInBasisPoints;
    uint256 amountInWei;
    address payable recipient;
  }

  FNDNFTMarket private immutable market;
  FETH private immutable feth;
  IENS private immutable ens;

  constructor(
    address payable _market,
    address payable _feth,
    address _ens
  ) {
    market = FNDNFTMarket(_market);
    feth = FETH(_feth);
    ens = IENS(_ens);
  }

  // solhint-disable-next-line code-complexity
  function getFees(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    public
    view
    returns (
      FeeWithRecipient memory foundation,
      Fee memory creator,
      FeeWithRecipient memory owner,
      RevSplit[] memory creatorRevSplit
    )
  {
    foundation.recipient = market.getFoundationTreasury();
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;
    uint256 creatorRev;
    {
      address payable ownerAddress;
      uint256 foundationFee;
      uint256 ownerRev;
      (foundationFee, creatorRev, creatorRecipients, creatorShares, ownerRev, ownerAddress) = market
        .getFeesAndRecipients(nftContract, tokenId, price);
      foundation.amountInWei = foundationFee;
      creator.amountInWei = creatorRev;
      owner.amountInWei = ownerRev;
      owner.recipient = ownerAddress;
      if (creatorShares.length == 0) {
        creatorShares = new uint256[](creatorRecipients.length);
        if (creatorShares.length == 1) {
          creatorShares[0] = BASIS_POINTS;
        }
      }
    }
    uint256 creatorRevBP;
    {
      uint256 foundationFeeBP;
      uint256 ownerRevBP;
      (foundationFeeBP, creatorRevBP, , , ownerRevBP, ) = market.getFeesAndRecipients(
        nftContract,
        tokenId,
        BASIS_POINTS
      );
      foundation.percentInBasisPoints = foundationFeeBP;
      creator.percentInBasisPoints = creatorRevBP;
      owner.percentInBasisPoints = ownerRevBP;
    }

    // Normalize shares to 10%
    {
      uint256 totalShares = 0;
      for (uint256 i = 0; i < creatorShares.length; ++i) {
        // TODO handle ignore if > 100% (like the market would)
        totalShares += creatorShares[i];
      }

      for (uint256 i = 0; i < creatorShares.length; ++i) {
        creatorShares[i] = (BASIS_POINTS * creatorShares[i]) / totalShares;
      }
    }

    // Count creators and split recipients
    {
      uint256 creatorCount = creatorRecipients.length;
      for (uint256 i = 0; i < creatorRecipients.length; ++i) {
        // Check if the address is a percent split
        if (address(creatorRecipients[i]).isContract()) {
          try PercentSplitETH(creatorRecipients[i]).getShareLength{ gas: READ_ONLY_GAS_LIMIT }() returns (
            uint256 recipientCount
          ) {
            creatorCount += recipientCount - 1;
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Not a Foundation percent split
          }
        }
      }
      creatorRevSplit = new RevSplit[](creatorCount);
    }

    // Populate rev splits, including any percent splits
    uint256 revSplitIndex = 0;
    for (uint256 i = 0; i < creatorRecipients.length; ++i) {
      if (address(creatorRecipients[i]).isContract()) {
        try PercentSplitETH(creatorRecipients[i]).getShareLength{ gas: READ_ONLY_GAS_LIMIT }() returns (
          uint256 recipientCount
        ) {
          uint256 totalSplitShares;
          for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
            uint256 share = PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex);
            totalSplitShares += share;
          }
          for (uint256 splitIndex = 0; splitIndex < recipientCount; ++splitIndex) {
            uint256 splitShare = (PercentSplitETH(creatorRecipients[i]).getPercentInBasisPointsByIndex(splitIndex) *
              BASIS_POINTS) / totalSplitShares;
            splitShare = (splitShare * creatorShares[i]) / BASIS_POINTS;
            creatorRevSplit[revSplitIndex++] = _calcRevSplit(
              price,
              splitShare,
              creatorRevBP,
              PercentSplitETH(creatorRecipients[i]).getShareRecipientByIndex(splitIndex)
            );
          }
          continue;
        } catch // solhint-disable-next-line no-empty-blocks
        {
          // Not a Foundation percent split
        }
      }
      {
        creatorRevSplit[revSplitIndex++] = _calcRevSplit(price, creatorShares[i], creatorRevBP, creatorRecipients[i]);
      }
    }

    // Bubble the creator to the first position in `creatorRevSplit`
    {
      address creatorAddress;
      try ITokenCreator(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable _creator
      ) {
        creatorAddress = _creator;
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }

      // 7th priority: owner from contract or override
      try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address _owner) {
        if (_owner != address(0)) {
          creatorAddress = _owner;
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
      if (creatorAddress != address(0)) {
        for (uint256 i = 1; i < creatorRevSplit.length; ++i) {
          if (creatorRevSplit[i].recipient == creatorAddress) {
            (creatorRevSplit[i], creatorRevSplit[0]) = (creatorRevSplit[0], creatorRevSplit[i]);
            break;
          }
        }
      }
    }
  }

  /**
   * @notice Checks an NFT to confirm it will function correctly with our marketplace.
   * @dev This should be called with as `call` to simulate the tx; never `sendTransaction`.
   */
  function probeNFT(address nftContract, uint256 tokenId) external payable {
    if (!nftContract.supportsInterface(type(IERC721).interfaceId)) {
      revert FNDMiddleware_Contract_Is_Not_ERC721();
    }
    (, , , RevSplit[] memory creatorRevSplit) = getFees(nftContract, tokenId, BASIS_POINTS);
    if (creatorRevSplit.length == 0) {
      revert FNDMiddleware_No_Royalty_Recipients_Defined();
    }
    for (uint256 i = 0; i < creatorRevSplit.length; ++i) {
      address recipient = creatorRevSplit[i].recipient;
      if (recipient == address(0)) {
        revert FNDMiddleware_Royalty_Recipient_Address_0();
      }
      // Sending > 1 to help confirm when the recipient is a contract forwarding to other addresses
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = recipient.call{ value: 10, gas: SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS }("");
      if (!success) {
        revert FNDMiddleware_Royalty_Recipient_Not_Receivable(recipient);
      }
    }
  }

  function getAccountInfo(address account)
    external
    view
    returns (
      uint256 ethBalance,
      uint256 availableFethBalance,
      uint256 lockedFethBalance,
      string memory ensName
    )
  {
    ethBalance = account.balance;
    availableFethBalance = feth.balanceOf(account);
    lockedFethBalance = feth.totalBalanceOf(account) - availableFethBalance;

    // Lookup ENS name, if one was registered
    ensName = _getENSName(account);
  }

  /**
   * @notice Retrieves details related to the NFT in the FND Market.
   * @param nftContract The address of the contract for the NFT
   * @param tokenId The id for the NFT in the contract.
   */
  function getNFTDetails(address nftContract, uint256 tokenId)
    public
    view
    returns (
      address owner,
      bool isInEscrow,
      address auctionBidder,
      uint256 auctionEndTime,
      uint256 auctionPrice,
      uint256 auctionId,
      uint256 buyPrice,
      uint256 offerAmount,
      address offerBuyer,
      uint256 offerExpiration
    )
  {
    (owner, buyPrice) = market.getBuyPrice(nftContract, tokenId);
    (offerBuyer, offerExpiration, offerAmount) = market.getOffer(nftContract, tokenId);
    auctionId = market.getReserveAuctionIdFor(nftContract, tokenId);
    if (auctionId != 0) {
      NFTMarketReserveAuction.ReserveAuction memory auction = market.getReserveAuction(auctionId);
      auctionEndTime = auction.endTime;
      auctionPrice = auction.amount;
      auctionBidder = auction.bidder;
      owner = auction.seller;
    }

    if (owner == address(0)) {
      owner = payable(IERC721(nftContract).ownerOf(tokenId));
      isInEscrow = false;
    } else {
      isInEscrow = true;
    }
  }

  // solhint-disable-next-line code-complexity
  function getNFTDetailString(address nftContract, uint256 tokenId) external view returns (string memory details) {
    (
      address owner,
      bool isInEscrow,
      address auctionBidder,
      uint256 auctionEndTime,
      uint256 auctionPrice,
      uint256 auctionId,
      uint256 buyPrice,
      uint256 offerAmount,
      address offerBuyer,
      uint256 offerExpiration
    ) = getNFTDetails(nftContract, tokenId);
    details = _getAddressAndName(owner);
    if (isInEscrow) {
      if (auctionEndTime > 0) {
        if (auctionEndTime >= block.timestamp) {
          // Active auction
          details = string.concat(
            details,
            " has it in active auction going for ",
            _getETHString(auctionPrice),
            ", bid from ",
            _getAddressAndName(auctionBidder),
            " and ends in ",
            _getDeltaTimeString(auctionEndTime - block.timestamp),
            " [auctionId: ",
            auctionId.toString(),
            "]"
          );
        } else {
          // Auction ended, pending finalization
          details = string.concat(
            details,
            " sold it in auction for ",
            _getETHString(auctionPrice),
            " to ",
            _getAddressAndName(auctionBidder),
            " ",
            _getDeltaTimeString(block.timestamp - auctionEndTime),
            " ago [pending settlement / auctionId: ",
            auctionId.toString(),
            "]"
          );
        }
      } else {
        // Buy now and/or reserve price
        details = string.concat(details, " listed for ");
        if (buyPrice < type(uint256).max) {
          details = string.concat(details, "buy now at ", _getETHString(buyPrice));
        }
        if (buyPrice < type(uint256).max && auctionPrice > 0) {
          details = string.concat(details, " or ");
        }
        if (auctionPrice > 0) {
          details = string.concat(
            details,
            "reserve price of ",
            _getETHString(auctionPrice),
            " [auctionId: ",
            auctionId.toString(),
            "]"
          );
        }
      }

      if (offerAmount > 0) {
        // With an offer too
        details = string.concat(
          details,
          " with an offer of ",
          _getOfferString(offerAmount, offerBuyer, offerExpiration)
        );
      }
    } else if (offerAmount > 0) {
      // Just an offer
      details = string.concat(details, " has an offer for ", _getOfferString(offerAmount, offerBuyer, offerExpiration));
    } else {
      // Nothing
      details = string.concat(details, " has not listed nor gotten an offer");
    }
  }

  function _calcRevSplit(
    uint256 price,
    uint256 share,
    uint256 creatorRevBP,
    address payable recipient
  ) private pure returns (RevSplit memory) {
    uint256 absoluteShare = (share * creatorRevBP) / BASIS_POINTS;
    uint256 amount = (absoluteShare * price) / BASIS_POINTS;
    return RevSplit(share, absoluteShare, amount, recipient);
  }

  function _getAddressAndName(address account) private view returns (string memory name) {
    string memory ensName = _getENSName(account);
    if (bytes(ensName).length > 0) {
      name = string.concat(_toAsciiString(account), " (", ensName, ")");
    } else {
      name = _toAsciiString(account);
    }
  }

  // solhint-disable-next-line code-complexity
  function _getDeltaTimeString(uint256 timeRemaining) private pure returns (string memory delta) {
    uint256 secondsRemaining = timeRemaining;
    // Days
    if (timeRemaining >= 1 days) {
      uint256 day = secondsRemaining / (1 days);
      if (day == 1) {
        delta = "1 day";
      } else {
        delta = string.concat(day.toString(), " days");
      }
      secondsRemaining -= day * 1 days;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Hours
    if (timeRemaining >= 1 hours) {
      uint256 hrs = secondsRemaining / (1 hours);
      if (hrs == 1) {
        delta = string.concat(delta, "1 hour");
      } else {
        delta = string.concat(delta, hrs.toString(), " hours");
      }
      secondsRemaining -= hrs * 1 hours;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Minutes
    if (timeRemaining >= 1 minutes) {
      uint256 mins = secondsRemaining / (1 minutes);
      if (mins == 1) {
        delta = string.concat(delta, "1 min");
      } else {
        delta = string.concat(delta, mins.toString(), " mins");
      }
      secondsRemaining -= mins * 1 minutes;
      if (secondsRemaining == 0) {
        return delta;
      } else {
        delta = string.concat(delta, " ");
      }
    }
    // Seconds
    if (secondsRemaining == 1) {
      delta = string.concat(delta, "1 sec");
    } else {
      delta = string.concat(delta, secondsRemaining.toString(), " secs");
    }
  }

  // solhint-disable-next-line code-complexity
  function _getETHString(uint256 amount) private pure returns (string memory eth) {
    string memory amountString = amount.toString();
    uint256 printedCount = 0;
    if (bytes(amountString).length > 18) {
      for (uint256 i = 0; i < bytes(amountString).length - 18; ++i) {
        bytes memory byteArray = new bytes(1);
        byteArray[0] = bytes(amountString)[i];
        eth = string.concat(eth, string(byteArray));
        printedCount++;
      }
    } else {
      eth = "0";
    }
    uint256 endingZeros = 0;
    for (uint256 i = bytes(amountString).length - 1; i > 0; --i) {
      if (bytes(amountString)[i] == bytes("0")[0]) {
        ++endingZeros;
      } else {
        break;
      }
    }
    if (endingZeros < 18) {
      eth = string.concat(eth, ".");

      if (bytes(amountString).length < 18) {
        // add leading zeros
        for (uint256 i = 0; i < 18 - bytes(amountString).length; ++i) {
          eth = string.concat(eth, "0");
        }
      }
      for (; printedCount < bytes(amountString).length - endingZeros; ++printedCount) {
        bytes memory byteArray = new bytes(1);
        byteArray[0] = bytes(amountString)[printedCount];
        eth = string.concat(eth, string(byteArray));
      }
    }

    eth = string.concat(eth, " ETH");
  }

  function _getENSName(address account) private view returns (string memory ensName) {
    IReverseRegistrar reverseRegistrar = IReverseRegistrar(
      ens.owner(
        keccak256(
          abi.encodePacked(keccak256(abi.encodePacked(abi.encode(bytes32(0)), keccak256("reverse"))), keccak256("addr"))
        )
      )
    );
    bytes32 node = reverseRegistrar.node(account);
    if (node != bytes32(0)) {
      IPublicResolver resolver = IPublicResolver(ens.resolver(node));

      // The standard call style is reverting when no results are found
      (bool success, bytes memory data) = address(resolver).staticcall(abi.encodeWithSignature("name(bytes32)", node));

      if (success && data.length > 0) {
        ensName = resolver.name(node);

        // TODO this only works for .eth names, subdomains and others will be ignored
        bytes32 nameNode = keccak256(
          abi.encodePacked(
            keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))),
            keccak256(_substring(ensName, 0, bytes(ensName).length - 4))
          )
        );

        // Validate ownership
        address owner = ens.owner(nameNode);
        if (owner != account) {
          // Invalid reverse registration
          ensName = "";
        }
      }
    }
  }

  function _getOfferString(
    uint256 amount,
    address buyer,
    uint256 expiration
  ) private view returns (string memory offer) {
    offer = string.concat(
      _getETHString(amount),
      " from ",
      _getAddressAndName(buyer),
      " that expires in ",
      _getDeltaTimeString(expiration - block.timestamp)
    );
  }

  function _substring(
    string memory str,
    uint256 startIndex,
    uint256 endIndex
  ) private pure returns (bytes memory result) {
    bytes memory strBytes = bytes(str);
    result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; ++i) {
      result[i - startIndex] = strBytes[i];
    }
  }

  /**
   * @notice Converts an address into a string.
   * @dev From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
   */
  function _toAsciiString(address x) private pure returns (string memory) {
    unchecked {
      bytes memory s = new bytes(42);
      s[0] = "0";
      s[1] = "x";
      for (uint256 i = 0; i < 20; ++i) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
      }
      return string(s);
    }
  }

  /**
   * @notice Converts a byte to a UTF-8 character.
   */
  function _char(bytes1 b) private pure returns (bytes1 c) {
    unchecked {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/Constants.sol";
import "./mixins/FoundationTreasuryNode.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketBuyPrice.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketOffer.sol";
import "./mixins/NFTMarketPrivateSale.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";

/**
 * @title A market for NFTs on Foundation.
 * @notice The Foundation marketplace is a contract which allows traders to buy and sell NFTs.
 * It supports buying and selling via auctions, private sales, buy price, and offers.
 * @dev All sales in the Foundation market will pay the creator 10% royalties on secondary sales. This is not specific
 * to NFTs minted on Foundation, it should work for any NFT. If royalty information was not defined when the NFT was
 * originally deployed, it may be added using the [Royalty Registry](https://royaltyregistry.xyz/) which will be
 * respected by our market contract.
 */
contract FNDNFTMarket is
  Constants,
  Initializable,
  FoundationTreasuryNode,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction,
  NFTMarketPrivateSale,
  NFTMarketBuyPrice,
  NFTMarketOffer
{
  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The Foundation Treasury contract address.
   * @param feth The FETH ERC-20 token contract address.
   * @param royaltyRegistry The Royalty Registry contract address.
   * @param duration The duration of the auction in seconds.
   * @param marketProxyAddress The address of the proxy fronting this contract.
   */
  constructor(
    address payable treasury,
    address feth,
    address royaltyRegistry,
    uint256 duration,
    address marketProxyAddress
  )
    FoundationTreasuryNode(treasury)
    NFTMarketCore(feth)
    NFTMarketCreators(royaltyRegistry)
    NFTMarketReserveAuction(duration)
    NFTMarketPrivateSale(marketProxyAddress) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external initializer {
    NFTMarketAuction._initializeNFTMarketAuction();
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketBuyPrice, NFTMarketOffer)
  {
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice) {
    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice) {
    super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
  {
    super._transferToEscrow(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    override(NFTMarketCore, NFTMarketReserveAuction, NFTMarketBuyPrice)
    returns (address payable seller)
  {
    seller = super._getSellerFor(nftContract, tokenId);
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC20Approve.sol";
import "./interfaces/IERC20IncreaseAllowance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/BytesLibrary.sol";

/**
 * @title Auto-forward ETH to a pre-determined list of addresses.
 * @notice Deploys contracts which auto-forwards any ETH sent to it to a list of recipients
 * considering their percent share of the payment received.
 * ERC-20 tokens are also supported and may be split on demand by calling `splitERC20Tokens`.
 * If another asset type is sent to this contract address such as an NFT, arbitrary calls may be made by one
 * of the split recipients in order to recover them.
 * @dev Uses create2 counterfactual addresses so that the destination is known from the terms of the split.
 */
contract PercentSplitETH is Initializable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;
  using BytesLibrary for bytes;
  using SafeMath for uint256;

  /// @notice A representation of shares using 16-bits for efficient storage.
  /// @dev This is only used internally.
  struct ShareCompressed {
    address payable recipient;
    uint16 percentInBasisPoints;
  }

  /// @notice A representation of shares using 256-bits to ease integration.
  struct Share {
    address payable recipient;
    uint256 percentInBasisPoints;
  }

  ShareCompressed[] private _shares;

  uint256 private constant BASIS_POINTS = 10000;

  /**
   * @notice Emitted when an ERC20 token is transferred to a recipient through this split contract.
   * @param erc20Contract The address of the ERC20 token contract.
   * @param account The account which received payment.
   * @param amount The amount of ERC20 tokens sent to this recipient.
   */
  event ERC20Transferred(address indexed erc20Contract, address indexed account, uint256 amount);
  /**
   * @notice Emitted when ETH is transferred to a recipient through this split contract.
   * @param account The account which received payment.
   * @param amount The amount of ETH payment sent to this recipient.
   */
  event ETHTransferred(address indexed account, uint256 amount);
  /**
   * @notice Emitted when a new percent split contract is created from this factory.
   * @param contractAddress The address of the new percent split contract.
   */
  event PercentSplitCreated(address indexed contractAddress);
  /**
   * @notice Emitted for each share of the split being defined.
   * @param recipient The address of the recipient when payment to the split is received.
   * @param percentInBasisPoints The percent of the payment received by the recipient, in basis points.
   */
  event PercentSplitShare(address indexed recipient, uint256 percentInBasisPoints);

  /**
   * @dev Requires that the msg.sender is one of the recipients in this split.
   */
  modifier onlyRecipient() {
    for (uint256 i = 0; i < _shares.length; ++i) {
      if (_shares[i].recipient == msg.sender) {
        _;
        return;
      }
    }
    revert("Split: Can only be called by one of the recipients");
  }

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This will be called by `createSplit` after deploying the proxy so it should never be called directly.
   * @param shares The list of recipients and their share of the payment for the template to use.
   */
  function initialize(Share[] memory shares) external initializer {
    require(shares.length >= 2, "Split: Too few recipients");
    require(shares.length <= 5, "Split: Too many recipients");
    uint256 total;
    unchecked {
      // The array length cannot overflow 256 bits.
      for (uint256 i = 0; i < shares.length; ++i) {
        require(shares[i].percentInBasisPoints < BASIS_POINTS, "Split: Share must be less than 100%");
        // Require above ensures total will not overflow.
        total += shares[i].percentInBasisPoints;
        _shares.push(
          ShareCompressed({
            recipient: shares[i].recipient,
            percentInBasisPoints: uint16(shares[i].percentInBasisPoints)
          })
        );
        emit PercentSplitShare(shares[i].recipient, shares[i].percentInBasisPoints);
      }
    }
    require(total == BASIS_POINTS, "Split: Total amount must equal 100%");
  }

  /**
   * @notice Forwards any ETH received to the recipients in this split.
   * @dev Each recipient increases the gas required to split
   * and contract recipients may significantly increase the gas required.
   */
  receive() external payable {
    _splitETH(msg.value);
  }

  /**
   * @notice Creates a new minimal proxy contract and initializes it with the given split terms.
   * If the contract had already been created, its address is returned.
   * This must be called on the original implementation and not a proxy created previously.
   * @param shares The list of recipients and their share of the payment for this split.
   * @return splitInstance The contract address for the split contract created.
   */
  function createSplit(Share[] memory shares) external returns (PercentSplitETH splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    address clone = Clones.predictDeterministicAddress(address(this), salt);
    splitInstance = PercentSplitETH(payable(clone));
    if (!clone.isContract()) {
      emit PercentSplitCreated(clone);
      Clones.cloneDeterministic(address(this), salt);
      splitInstance.initialize(shares);
    }
  }

  /**
   * @notice Allows the split recipients to make an arbitrary contract call.
   * @dev This is provided to allow recovering from unexpected scenarios,
   * such as receiving an NFT at this address.
   *
   * It will first attempt a fair split of ERC20 tokens before proceeding.
   *
   * This contract is built to split ETH payments. The ability to attempt to make other calls is here
   * just in case other assets were also sent so that they don't get locked forever in the contract.
   * @param target The address of the contract to call.
   * @param callData The data to send to the `target` contract.
   */
  function proxyCall(address payable target, bytes memory callData) external onlyRecipient {
    require(
      !callData.startsWith(type(IERC20Approve).interfaceId) &&
        !callData.startsWith(type(IERC20IncreaseAllowance).interfaceId),
      "Split: ERC20 tokens must be split"
    );
    _splitERC20Tokens(IERC20(target));
    target.functionCall(callData);
  }

  /**
   * @notice Allows any ETH stored by the contract to be split among recipients.
   * @dev Normally ETH is forwarded as it comes in, but a balance in this contract
   * is possible if it was sent before the contract was created or if self destruct was used.
   */
  function splitETH() external {
    _splitETH(address(this).balance);
  }

  /**
   * @notice Anyone can call this function to split all available tokens at the provided address between the recipients.
   * @dev This contract is built to split ETH payments. The ability to attempt to split ERC20 tokens is here
   * just in case tokens were also sent so that they don't get locked forever in the contract.
   * @param erc20Contract The address of the ERC20 token contract to split tokens for.
   */
  function splitERC20Tokens(IERC20 erc20Contract) external {
    require(_splitERC20Tokens(erc20Contract), "Split: ERC20 split failed");
  }

  function _splitERC20Tokens(IERC20 erc20Contract) private returns (bool) {
    try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
      if (balance == 0) {
        return false;
      }
      uint256 amountToSend;
      uint256 totalSent;
      unchecked {
        for (uint256 i = _shares.length - 1; i != 0; i--) {
          ShareCompressed memory share = _shares[i];
          bool success;
          (success, amountToSend) = balance.tryMul(share.percentInBasisPoints);
          if (!success) {
            return false;
          }
          amountToSend /= BASIS_POINTS;
          totalSent += amountToSend;
          try erc20Contract.transfer(share.recipient, amountToSend) {
            emit ERC20Transferred(address(erc20Contract), share.recipient, amountToSend);
          } catch {
            return false;
          }
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = balance - totalSent;
      }
      try erc20Contract.transfer(_shares[0].recipient, amountToSend) {
        emit ERC20Transferred(address(erc20Contract), _shares[0].recipient, amountToSend);
      } catch {
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  function _splitETH(uint256 value) private {
    if (value != 0) {
      uint256 totalSent;
      uint256 amountToSend;
      unchecked {
        for (uint256 i = _shares.length - 1; i != 0; i--) {
          ShareCompressed memory share = _shares[i];
          amountToSend = (value * share.percentInBasisPoints) / BASIS_POINTS;
          totalSent += amountToSend;
          share.recipient.sendValue(amountToSend);
          emit ETHTransferred(share.recipient, amountToSend);
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = value - totalSent;
      }
      _shares[0].recipient.sendValue(amountToSend);
      emit ETHTransferred(_shares[0].recipient, amountToSend);
    }
  }

  /**
   * @notice Returns a recipient's percent share in basis points.
   * @param index The index of the recipient to get the share of.
   * @return percentInBasisPoints The percent of the payment received by the recipient, in basis points.
   */
  function getPercentInBasisPointsByIndex(uint256 index) external view returns (uint256 percentInBasisPoints) {
    percentInBasisPoints = _shares[index].percentInBasisPoints;
  }

  /**
   * @notice Returns the address for the proxy contract which would represent the given split terms.
   * @dev The contract may or may not already be deployed at the address returned.
   * Ensure that it is deployed before sending funds to this address.
   * @param shares The list of recipients and their share of the payment for this split.
   * @return splitInstance The contract address for the split contract created.
   */
  function getPredictedSplitAddress(Share[] memory shares) external view returns (address splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    splitInstance = Clones.predictDeterministicAddress(address(this), salt);
  }

  /**
   * @notice Returns how many recipients are part of this split.
   * @return length The number of recipients in this split.
   */
  function getShareLength() external view returns (uint256 length) {
    length = _shares.length;
  }

  /**
   * @notice Returns a recipient in this split.
   * @param index The index of the recipient to get.
   * @return recipient The recipient at the given index.
   */
  function getShareRecipientByIndex(uint256 index) external view returns (address payable recipient) {
    recipient = _shares[index].recipient;
  }

  /**
   * @notice Returns a tuple with the terms of this split.
   * @return shares The list of recipients and their share of the payment for this split.
   */
  function getShares() external view returns (Share[] memory shares) {
    shares = new Share[](_shares.length);
    for (uint256 i = 0; i < shares.length; ++i) {
      shares[i] = Share({ recipient: _shares[i].recipient, percentInBasisPoints: _shares[i].percentInBasisPoints });
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Constant values shared across mixins.
 */
abstract contract Constants {
  /**
   * @notice 100% in basis points.
   */
  uint256 internal constant BASIS_POINTS = 10000;

  /**
   * @notice Cap the number of royalty recipients to 5.
   * @dev A cap is required to ensure gas costs are not too high when a sale is settled.
   */
  uint256 internal constant MAX_ROYALTY_RECIPIENTS_INDEX = 4;

  /**
   * @notice The minimum increase of 10% required when making an offer or placing a bid.
   */
  uint256 internal constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1000;

  /**
   * @notice The gas limit used when making external read-only calls.
   * @dev This helps to ensure that external calls does not prevent the market from executing.
   */
  uint256 internal constant READ_ONLY_GAS_LIMIT = 40000;

  /**
   * @notice The gas limit to send ETH to multiple recipients, enough for a 5-way split.
   */
  uint256 internal constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210000;

  /**
   * @notice The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
   */
  uint256 internal constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./libraries/LockedBalance.sol";

error FETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
error FETH_Cannot_Deposit_To_Address_Zero();
error FETH_Cannot_Deposit_To_FETH();
error FETH_Cannot_Withdraw_To_Address_Zero();
error FETH_Cannot_Withdraw_To_FETH();
error FETH_Cannot_Withdraw_To_Market();
error FETH_Escrow_Expired();
error FETH_Escrow_Not_Found();
error FETH_Expiration_Too_Far_In_Future();
/// @param amount The current allowed amount the spender is authorized to transact for this account.
error FETH_Insufficient_Allowance(uint256 amount);
/// @param amount The current available (unlocked) token count of this account.
error FETH_Insufficient_Available_Funds(uint256 amount);
/// @param amount The current number of tokens this account has for the given lockup expiry bucket.
error FETH_Insufficient_Escrow(uint256 amount);
error FETH_Invalid_Lockup_Duration();
error FETH_Market_Must_Be_A_Contract();
error FETH_Must_Deposit_Non_Zero_Amount();
error FETH_Must_Lockup_Non_Zero_Amount();
error FETH_No_Funds_To_Withdraw();
error FETH_Only_FND_Market_Allowed();
error FETH_Too_Much_ETH_Provided();
error FETH_Transfer_To_Address_Zero_Not_Allowed();
error FETH_Transfer_To_FETH_Not_Allowed();

/**
 * @title An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 * @notice FETH is an [ERC-20 token](https://eips.ethereum.org/EIPS/eip-20) modeled after
 * [WETH9](https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code).
 * It has the added ability to lockup tokens for 24-25 hours - during this time they may not be
 * transferred or withdrawn, except by our market contract which requested the lockup in the first place.
 * @dev Locked balances are rounded up to the next hour.
 * They are grouped by the expiration time of the lockup into what we refer to as a lockup "bucket".
 * At any time there may be up to 25 buckets but never more than that which prevents loops from exhausting gas limits.
 * FETH is an upgradeable contract. Overtime we will progressively decentralize, potentially giving upgrade permissions
 * to a DOA ownership or removing the permissions entirely.
 */
contract FETH {
  using AddressUpgradeable for address payable;
  using LockedBalance for LockedBalance.Lockups;
  using Math for uint256;

  /// @notice Tracks an account's info.
  struct AccountInfo {
    /// @notice The number of tokens which have been unlocked already.
    uint96 freedBalance;
    /// @notice The first applicable lockup bucket for this account.
    uint32 lockupStartIndex;
    /// @notice Stores up to 25 buckets of locked balance for a user, one per hour.
    LockedBalance.Lockups lockups;
    /// @notice Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  /// @notice Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The Foundation market contract with permissions to manage lockups.
  address payable private immutable foundationMarket;

  // ERC-20 metadata fields
  /**
   * @notice The number of decimals the token uses.
   * @dev This method can be used to improve usability when displaying token amounts, but all interactions
   * with this contract use whole amounts not considering decimals.
   * @return 18
   */
  uint8 public constant decimals = 18;
  /**
   * @notice The name of the token.
   * @return Foundation ETH
   */
  string public constant name = "Foundation ETH";
  /**
   * @notice The symbol of the token.
   * @return FETH
   */
  string public constant symbol = "FETH";

  // ERC-20 events
  /**
   * @notice Emitted when the allowance for a spender account is updated.
   * @param from The account the spender is authorized to transact for.
   * @param spender The account with permissions to manage FETH tokens for the `from` account.
   * @param amount The max amount of tokens which can be spent by the `spender` account.
   */
  event Approval(address indexed from, address indexed spender, uint256 amount);
  /**
   * @notice Emitted when a transfer of FETH tokens is made from one account to another.
   * @param from The account which is sending FETH tokens.
   * @param to The account which is receiving FETH tokens.
   * @param amount The number of FETH tokens which were sent.
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  /**
   * @notice Emitted when FETH tokens are locked up by the Foundation market for 24-25 hours
   * and may include newly deposited ETH which is added to the account's total FETH balance.
   * @param account The account which has access to the FETH after the `expiration`.
   * @param expiration The time at which the `from` account will have access to the locked FETH.
   * @param amount The number of FETH tokens which where locked up.
   * @param valueDeposited The amount of ETH added to their account's total FETH balance,
   * this may be lower than `amount` if available FETH was leveraged.
   */
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount, uint256 valueDeposited);
  /**
   * @notice Emitted when FETH tokens are unlocked by the Foundation market.
   * @dev This event will not be emitted when lockups expire,
   * it's only for tokens which are unlocked before their expiry.
   * @param account The account which had locked FETH freed before expiration.
   * @param expiration The time this balance was originally scheduled to be unlocked.
   * @param amount The number of FETH tokens which were unlocked.
   */
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);
  /**
   * @notice Emitted when ETH is withdrawn from a user's account.
   * @dev This may be triggered by the user, an approved operator, or the Foundation market.
   * @param from The account from which FETH was deducted in order to send the ETH.
   * @param to The address the ETH was sent to.
   * @param amount The number of tokens which were deducted from the user's FETH balance and transferred as ETH.
   */
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);

  /// @dev Allows the Foundation market permission to manage lockups for a user.
  modifier onlyFoundationMarket() {
    if (msg.sender != foundationMarket) {
      revert FETH_Only_FND_Market_Allowed();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param _foundationMarket The address of the Foundation NFT marketplace.
   * @param _lockupDuration The minimum length of time to lockup tokens for when `BalanceLocked`, in seconds.
   */
  constructor(address payable _foundationMarket, uint256 _lockupDuration) {
    if (!_foundationMarket.isContract()) {
      revert FETH_Market_Must_Be_A_Contract();
    }
    foundationMarket = _foundationMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert FETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH (via `msg.value`) to the contract performs a `deposit` into the user's account.
   */
  receive() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Approves a `spender` as an operator with permissions to transfer from your account.
   * @dev To prevent attack vectors, clients SHOULD make sure to create user interfaces in such a way
   * that they set the allowance first to 0 before setting it to another value for the same spender.
   * We will add support for `increaseAllowance` in the future.
   * @param spender The address of the operator account that has approval to spend funds
   * from the `msg.sender`'s account.
   * @param amount The max number of FETH tokens from `msg.sender`'s account that this spender is
   * allowed to transact with.
   * @return success Always true.
   */
  function approve(address spender, uint256 amount) external returns (bool success) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and receive the equivalent amount in FETH tokens.
   * These tokens are not subject to any lockup period.
   */
  function deposit() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and credit the `account` provided with the equivalent amount in FETH tokens.
   * These tokens are not subject to any lockup period.
   * @dev This may be used by the Foundation market to credit a user's account with FETH tokens.
   * @param account The account to credit with FETH tokens.
   */
  function depositFor(address account) public payable {
    if (msg.value == 0) {
      revert FETH_Must_Deposit_Non_Zero_Amount();
    } else if (account == address(0)) {
      revert FETH_Cannot_Deposit_To_Address_Zero();
    } else if (account == address(this)) {
      revert FETH_Cannot_Deposit_To_FETH();
    }
    AccountInfo storage accountInfo = accountToInfo[account];
    // ETH value cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(msg.value);
    }
    emit Transfer(address(0), account, msg.value);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup and then create a new lockup, potentially for a different account.
   * @dev Used by the market when an offer for an NFT is increased.
   * This may be for a single account (increasing their offer)
   * or two different accounts (outbidding someone elses offer).
   * @param unlockFrom The account whose lockup is to be removed.
   * @param unlockExpiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param unlockAmount The number of tokens to be unlocked from `unlockFrom`'s account.
   * This will revert if the tokens were previously unlocked.
   * @param lockupFor The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param lockupAmount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `lockupAmount` and any delta will be taken from the account's available FETH balance.
   * @return expiration The expiration timestamp for the FETH tokens that were locked.
   */
  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address lockupFor,
    uint256 lockupAmount
  ) external payable onlyFoundationMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketLockupFor(lockupFor, lockupAmount);
  }

  /**
   * @notice Used by the market contract only:
   * Lockup an account's FETH tokens for 24-25 hours.
   * @dev Used by the market when a new offer for an NFT is made.
   * @param account The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param amount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available FETH balance.
   * @return expiration The expiration timestamp for the FETH tokens that were locked.
   */
  function marketLockupFor(address account, uint256 amount)
    external
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    return _marketLockupFor(account, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup, making the FETH tokens available for transfer or withdrawal.
   * @dev Used by the market when an offer is invalidated, which occurs when an auction for the same NFT
   * receives its first bid or the buyer purchased the NFT another way, such as with `buy`.
   * @param account The account whose lockup is to be unlocked.
   * @param expiration The original lockup expiration for the tokens to be unlocked unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked from `account`.
   * This will revert if the tokens were previously unlocked.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes tokens from the user's available balance and returns ETH to the caller.
   * @dev Used by the market when a user's available FETH balance is used to make a purchase
   * including accepting a buy price or a private sale, or placing a bid in an auction.
   * @param from The account whose available balance is to be withdrawn from.
   * @param amount The number of tokens to be deducted from `unlockFrom`'s available balance and transferred as ETH.
   * This will revert if the tokens were previously unlocked.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyFoundationMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes a lockup from the user's account and then returns ETH to the caller.
   * @dev Used by the market to extract unexpired funds as ETH to distribute for
   * a sale when the user's offer is accepted.
   * @param account The account whose lockup is to be removed.
   * @param expiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked and withdrawn as ETH.
   */
  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Transfers an amount from your account.
   * @param to The address of the account which the tokens are transferred from.
   * @param amount The number of FETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds).
   */
  function transfer(address to, uint256 amount) external returns (bool success) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified if the `msg.sender` has approval.
   * @param from The address from which the available tokens are transferred from.
   * @param to The address to which the tokens are to be transferred.
   * @param amount The number of FETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds or not approved).
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool success) {
    if (to == address(0)) {
      revert FETH_Transfer_To_Address_Zero_Not_Allowed();
    } else if (to == address(this)) {
      revert FETH_Transfer_To_FETH_Not_Allowed();
    }
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(fromAccountInfo, amount, from);
    }
    _deductBalanceFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      toAccountInfo.freedBalance += uint96(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @notice Withdraw all tokens available in your account and receive ETH.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified number of tokens from the `from` accounts available balance
   * and send ETH to the destination address, if the `msg.sender` has approval.
   * @param from The address from which the available funds are to be withdrawn.
   * @param to The destination address for the ETH to be transferred to.
   * @param amount The number of tokens to be withdrawn and transferred as ETH.
   */
  function withdrawFrom(
    address from,
    address payable to,
    uint256 amount
  ) external {
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    } else if (to == address(0)) {
      revert FETH_Cannot_Withdraw_To_Address_Zero();
    } else if (to == address(this)) {
      revert FETH_Cannot_Withdraw_To_FETH();
    } else if (to == address(foundationMarket)) {
      revert FETH_Cannot_Withdraw_To_Market();
    }

    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(accountInfo, amount, from);
    }
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowanceFrom(
    AccountInfo storage accountInfo,
    uint256 amount,
    address from
  ) private {
    uint256 spenderAllowance = accountInfo.allowance[msg.sender];
    if (spenderAllowance != type(uint256).max) {
      if (spenderAllowance < amount) {
        revert FETH_Insufficient_Allowance(spenderAllowance);
      }
      // The check above ensures allowance cannot underflow.
      unchecked {
        spenderAllowance -= amount;
      }
      accountInfo.allowance[msg.sender] = spenderAllowance;
      emit Approval(from, msg.sender, spenderAllowance);
    }
  }

  /**
   * @dev Removes an amount from the account's available FETH balance.
   */
  function _deductBalanceFrom(AccountInfo storage accountInfo, uint256 amount) private {
    uint96 freedBalance = accountInfo.freedBalance;
    // Free from escrow in order to consider any expired escrow balance
    if (freedBalance < amount) {
      revert FETH_Insufficient_Available_Funds(freedBalance);
    }
    // The check above ensures balance cannot underflow.
    unchecked {
      accountInfo.freedBalance = freedBalance - uint96(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   * Sets the next bucket that hasn't expired as the new start index.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    // If the first bucket (the oldest) is empty or not yet expired, no change to escrowStartIndex is required
    if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
      return accountInfo;
    }

    while (true) {
      // Total ETH cannot realistically overflow 96 bits.
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        accountInfo.lockups.del(escrowIndex);
        // Escrow index cannot overflow 32 bits.
        escrow = accountInfo.lockups.get(escrowIndex + 1);
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      // Escrow index cannot overflow 32 bits.
      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        ++escrowIndex;
      }

      // If the next bucket is expired, that's the new start index
      if (escrow.expiration >= block.timestamp) {
        break;
      }
    }

    // Escrow index cannot overflow 32 bits.
    unchecked {
      accountInfo.lockupStartIndex = uint32(escrowIndex);
    }
    return accountInfo;
  }

  /**
   * @notice Lockup an account's FETH tokens for 24-25 hours.
   */
  /* solhint-disable-next-line code-complexity */
  function _marketLockupFor(address account, uint256 amount) private returns (uint256 expiration) {
    if (account == address(0)) {
      revert FETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
    }
    if (amount == 0) {
      revert FETH_Must_Lockup_Non_Zero_Amount();
    }

    // Block timestamp in seconds is small enough to never overflow
    unchecked {
      // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
      expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
    }

    // Update available escrow
    // Always free from escrow to ensure the max bucket count is <= 25
    AccountInfo storage accountInfo = _freeFromEscrow(account);
    if (msg.value < amount) {
      unchecked {
        // The if check above prevents an underflow here
        _deductBalanceFrom(accountInfo, amount - msg.value);
      }
    } else if (msg.value != amount) {
      // There's no reason to send msg.value more than the amount being locked up
      revert FETH_Too_Much_ETH_Provided();
    }

    // Add to locked escrow
    unchecked {
      // The number of buckets is always < 256 bits.
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          if (expiration > type(uint32).max) {
            revert FETH_Expiration_Too_Far_In_Future();
          }
          // Amount (ETH) will always be < 96 bits.
          accountInfo.lockups.set(escrowIndex, expiration, amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 96 bits.
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount, msg.value);
  }

  /**
   * @notice Remove an account's lockup, making the FETH tokens available for transfer or withdrawal.
   */
  function _marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(amount);
    }
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  /* solhint-disable-next-line code-complexity */
  function _removeFromLockedBalance(
    address account,
    uint256 expiration,
    uint256 amount
  ) private returns (AccountInfo storage) {
    if (expiration < block.timestamp) {
      revert FETH_Escrow_Expired();
    }

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        accountInfo.lockups.del(escrowIndex);

        // Bump the escrow start index unless it's the last one
        unchecked {
          if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
            // The number of escrow buckets will never overflow 32 bits.
            ++accountInfo.lockupStartIndex;
          }
        }
      } else {
        if (escrow.totalAmount < amount) {
          revert FETH_Insufficient_Escrow(escrow.totalAmount);
        }
        // The require above ensures balance will not underflow.
        unchecked {
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 32 bits.
        unchecked {
          ++escrowIndex;
        }
        escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == expiration) {
          if (amount > escrow.totalAmount) {
            revert FETH_Insufficient_Escrow(escrow.totalAmount);
          }
          // The require above ensures balance will not underflow.
          unchecked {
            accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        if (escrow.expiration == 0) {
          revert FETH_Escrow_Not_Found();
        }
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to transact from the `account`'s balance.
   * @param account The owner of the funds.
   * @param operator The address with approval to spend from the `account`'s balance.
   * @return amount The number of tokens the `operator` is still allowed to transact with.
   */
  function allowance(address account, address operator) external view returns (uint256 amount) {
    AccountInfo storage accountInfo = accountToInfo[account];
    amount = accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account which is available to transfer or withdraw.
   * @dev This will automatically increase as soon as locked tokens reach their expiry date.
   * @param account The account to query the available balance of.
   * @return balance The available balance of the account.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Gets the Foundation market address which has permissions to manage lockups.
   * @return market The Foundation market contract address.
   */
  function getFoundationMarket() external view returns (address market) {
    market = foundationMarket;
  }

  /**
   * @notice Returns the balance and each outstanding (unexpired) lockup bucket for an account, grouped by expiry.
   * @dev `expires.length` == `amounts.length`
   * and `amounts[i]` is the number of tokens which will expire at `expires[i]`.
   * The results returned are sorted by expiry, with the earliest expiry date first.
   * @param account The account to query the locked balance of.
   * @return expiries The time at which each outstanding lockup bucket expires.
   * @return amounts The number of FETH tokens which will expire for each outstanding lockup bucket.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
          // Lockup count will never overflow 256 bits.
          ++lockedCount;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          ++i;
        }
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked FETH tokens.
   * @dev Use `balanceOf` to get the number of tokens available for transfer or withdrawal.
   * @param account The account to query the total balance of.
   * @return balance The total FETH balance tracked for this account.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   * @return supply The total amount of ETH locked in this contract.
   * @dev It is possible for this to diverge from the total token count by transferring ETH on self destruct
   * but this is on-par with the WETH implementation and done for gas savings.
   */
  function totalSupply() external view returns (uint256 supply) {
    return address(this).balance;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Interface for the main ENS contract
 */
interface IENS {
  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external returns (bytes32);

  function setResolver(bytes32 node, address resolver) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Interface for the main ENS resolver contract.
 */
interface IPublicResolver {
  function setAddr(bytes32 node, address a) external;

  function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Interface for the main ENS reverse registrar contract.
 */
interface IReverseRegistrar {
  function setName(string memory name) external;

  function node(address addr) external pure returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAdminRole.sol";
import "../interfaces/IOperatorRole.sol";

error FoundationTreasuryNode_Address_Is_Not_A_Contract();
error FoundationTreasuryNode_Caller_Not_Admin();
error FoundationTreasuryNode_Caller_Not_Operator();

/**
 * @title A mixin that stores a reference to the Foundation treasury contract.
 * @notice The treasury collects fees and defines admin/operator roles.
 */
abstract contract FoundationTreasuryNode is Initializable {
  using AddressUpgradeable for address payable;

  /// @dev This value was replaced with an immutable version.
  address payable private __gap_was_treasury;

  /// @notice The address of the treasury contract.
  address payable private immutable treasury;

  /// @notice Requires the caller is a Foundation admin.
  modifier onlyFoundationAdmin() {
    if (!IAdminRole(treasury).isAdmin(msg.sender)) {
      revert FoundationTreasuryNode_Caller_Not_Admin();
    }
    _;
  }

  /// @notice Requires the caller is a Foundation operator.
  modifier onlyFoundationOperator() {
    if (!IOperatorRole(treasury).isOperator(msg.sender)) {
      revert FoundationTreasuryNode_Caller_Not_Operator();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Assigns the treasury contract address.
   */
  constructor(address payable _treasury) {
    if (!_treasury.isContract()) {
      revert FoundationTreasuryNode_Address_Is_Not_A_Contract();
    }
    treasury = _treasury;
  }

  /**
   * @notice Gets the Foundation treasury contract.
   * @dev This call is used in the royalty registry contract.
   * @return treasuryAddress The address of the Foundation treasury contract.
   */
  function getFoundationTreasury() public view returns (address payable treasuryAddress) {
    return treasury;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction is Initializable {
  /**
   * @notice A global id for auctions of any type.
   */
  uint256 private nextAuctionId;

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This sets the initial auction id to 1, making the first auction cheaper
   * and id 0 represents no auction found.
   */
  function _initializeNFTMarketAuction() internal onlyInitializing {
    nextAuctionId = 1;
  }

  /**
   * @notice Returns id to assign to the next auction.
   */
  function _getNextAndIncrementAuctionId() internal returns (uint256) {
    // AuctionId cannot overflow 256 bits.
    unchecked {
      return nextAuctionId++;
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";

/// @param buyPrice The current buy price set for this NFT.
error NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
error NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
error NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyPrice_Price_Already_Set();
error NFTMarketBuyPrice_Price_Too_High();
/// @param seller The current owner of this NFT.
error NFTMarketBuyPrice_Seller_Mismatch(address seller);

/**
 * @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a buy price set are escrowed in the market contract.
 */
abstract contract NFTMarketBuyPrice is NFTMarketCore, NFTMarketFees {
  using AddressUpgradeable for address payable;

  /// @notice Stores the buy price details for a specific NFT.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct BuyPrice {
    /// @notice The current owner of this NFT which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this NFT.
    uint96 price;
  }

  /// @notice Stores the current buy price for each NFT.
  mapping(address => mapping(uint256 => BuyPrice)) private nftContractToTokenIdToBuyPrice;

  /**
   * @notice Emitted when an NFT is bought by accepting the buy price,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `f8nFee` + `creatorFee` + `ownerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that purchased the NFT using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param f8nFee The amount of ETH that was sent to Foundation for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param ownerRev The amount of ETH that was sent to the owner for this sale.
   */
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  /**
   * @notice Emitted when the buy price is removed by the owner of an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is invalidated due to other market activity.
   * @dev This occurs when the buy price is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when a buy price is set by the owner of an NFT.
   * @dev The NFT is transferred into the market contract for escrow unless it was already escrowed,
   * e.g. for auction listing.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param seller The address of the NFT owner which set the buy price.
   * @param price The price of the NFT.
   */
  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);

  /**
   * @notice Buy the NFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param maxPrice The maximum price to pay for the NFT.
   */
  function buy(
    address nftContract,
    uint256 tokenId,
    uint256 maxPrice
  ) external payable {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.price > maxPrice) {
      revert NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.price);
    } else if (buyPrice.seller == address(0)) {
      revert NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }

    _buy(nftContract, tokenId);
  }

  /**
   * @notice Removes the buy price set for an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  function cancelBuyPrice(address nftContract, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Transfer the NFT back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(nftContract, tokenId, msg.sender);

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Sets the buy price for an NFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function setBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) external nonReentrant {
    // If there is a valid offer at this price or higher, accept that instead.
    if (_autoAcceptOffer(nftContract, tokenId, price)) {
      return;
    }

    if (price > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert NFTMarketBuyPrice_Price_Too_High();
    }

    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.price == price && seller != address(0)) {
      revert NFTMarketBuyPrice_Price_Already_Set();
    }

    // Store the new price for this NFT.
    buyPrice.price = uint96(price);

    if (seller == address(0)) {
      // Transfer the NFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      _transferToEscrow(nftContract, tokenId);

      // The price was not previously set for this NFT, store the seller.
      buyPrice.seller = payable(msg.sender);
    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert NFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit BuyPriceSet(nftContract, tokenId, msg.sender, price);
  }

  /**
   * @notice If there is a buy price at this price or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 maxPrice
  ) internal override returns (bool) {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller == address(0) || buyPrice.price > maxPrice) {
      // No buy price was found, or the price is too high.
      return false;
    }

    _buy(nftContract, tokenId);
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price on a auction start, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    BuyPrice storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.seller != address(0)) {
      // A buy price was set for this NFT, invalidate it.
      _invalidateBuyPrice(nftContract, tokenId);
    }
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @notice Process the purchase of an NFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _buy(address nftContract, uint256 tokenId) private nonReentrant {
    BuyPrice memory buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Remove the buy now price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    _cancelSendersOffer(nftContract, tokenId);

    if (buyPrice.price > msg.value) {
      // Withdraw additional ETH required from their available FETH balance.

      unchecked {
        // The if above ensures delta will not underflow.
        uint256 delta = buyPrice.price - msg.value;
        // Withdraw ETH from the buyer's account in the FETH token contract,
        // making the ETH available for `_distributeFunds` below.
        feth.marketWithdrawFrom(msg.sender, delta);
      }
    } else if (buyPrice.price < msg.value) {
      // Return any surplus funds to the buyer.

      unchecked {
        // The if above ensures this will not underflow
        payable(msg.sender).sendValue(msg.value - buyPrice.price);
      }
    }

    // Transfer the NFT to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(nftContract, tokenId, msg.sender, address(0));

    // Distribute revenue for this sale.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      nftContract,
      tokenId,
      buyPrice.seller,
      buyPrice.price
    );

    emit BuyPriceAccepted(nftContract, tokenId, buyPrice.seller, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address nftContract, uint256 tokenId) private {
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    emit BuyPriceInvalidated(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price if one is found before transferring the NFT.
   * This will revert if there is a buy price set but the `authorizeSeller` is not the owner.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller != address(0)) {
      // A buy price was set for this NFT.
      // `authorizeSeller != address(0) &&` could be added when other mixins use this flow.
      // ATM that additional check would never return false.
      if (seller != authorizeSeller) {
        // When there is a buy price set, the `buyPrice.seller` is the owner of the NFT.
        revert NFTMarketBuyPrice_Seller_Mismatch(seller);
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

      // Invalidate the buy price as the NFT will no longer be in escrow.
      _invalidateBuyPrice(nftContract, tokenId);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this NFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if the NFT is already in escrow for buy now.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // The NFT is not in escrow for buy now.
      super._transferToEscrow(nftContract, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the NFT.
      revert NFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The address of the owner that listed a buy price for this NFT.
   * Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   * Returns `0` if there is no buy price set for this NFT.
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = nftContractToTokenIdToBuyPrice[nftContract][tokenId].price;
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Returns the seller if there is a buy price set for this NFT, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerFor(nftContract, tokenId);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./Constants.sol";

import "../interfaces/IFethMarket.sol";

error NFTMarketCore_FETH_Address_Is_Not_A_Contract();
error NFTMarketCore_Only_FETH_Can_Transfer_ETH();
error NFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is Constants {
  using AddressUpgradeable for address;

  /// @notice The FETH ERC-20 token for managing escrow and lockup.
  IFethMarket internal immutable feth;

  constructor(address _feth) {
    if (!_feth.isContract()) {
      revert NFTMarketCore_FETH_Address_Is_Not_A_Contract();
    }
    feth = IFethMarket(_feth);
  }

  /**
   * @notice Only used by FETH. Any direct transfer from users will revert.
   */
  receive() external payable {
    if (msg.sender != address(feth)) {
      revert NFTMarketCore_Only_FETH_Can_Transfer_ETH();
    }
  }

  /**
   * @notice If there is a buy price at this amount or lower, accept that and return true.
   */
  function _autoAcceptBuyPrice(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) internal virtual returns (bool);

  /**
   * @notice If there is a valid offer at the given price or higher, accept that and return true.
   */
  function _autoAcceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) internal virtual returns (bool);

  /**
   * @notice Notify implementors when an auction has received its first bid.
   * Once a bid is received the sale is guaranteed to the auction winner
   * and other sale mechanisms become unavailable.
   * @dev Implementors of this interface should update internal state to reflect an auction has been kicked off.
   */
  function _beforeAuctionStarted(
    address, /*nftContract*/
    uint256 /*tokenId*/ // solhint-disable-next-line no-empty-blocks
  ) internal virtual {
    // No-op
  }

  /**
   * @notice Cancel the `msg.sender`'s offer if there is one, freeing up their FETH balance.
   * @dev This should be used when it does not make sense to keep the original offer around,
   * e.g. if a collector accepts a Buy Price then keeping the offer around is not necessary.
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal virtual;

  /**
   * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual {
    if (authorizeSeller != address(0)) {
      revert NFTMarketCore_Seller_Not_Found();
    }
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual {
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers an NFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this NFT.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual {
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  /**
   * @notice Gets the FETH contract used to escrow offer funds.
   * @return fethAddress The FETH contract address.
   */
  function getFethAddress() external view returns (address fethAddress) {
    fethAddress = address(feth);
  }

  /**
   * @dev Determines the minimum amount when increasing an existing offer or bid.
   */
  function _getMinIncrement(uint256 currentAmount) internal pure returns (uint256) {
    uint256 minIncrement = currentAmount;
    unchecked {
      minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
    }
    if (minIncrement == 0) {
      // Since minIncrement reduces from the currentAmount, this cannot overflow.
      // The next amount must be at least 1 wei greater than the current.
      return currentAmount + 1;
    }

    return minIncrement + currentAmount;
  }

  /**
   * @notice Checks who the seller for an NFT is, checking escrow or return the current owner if not in escrow.
   * @dev If the NFT did not have an escrowed seller to return, fall back to return the current owner.
   */
  function _getSellerFor(address nftContract, uint256 tokenId) internal view virtual returns (address payable seller) {
    seller = payable(IERC721(nftContract).ownerOf(tokenId));
  }

  /**
   * @notice Checks if an escrowed NFT is currently in active auction.
   * @return Returns false if the auction has ended, even if it has not yet been settled.
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view virtual returns (bool);

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 50 slots were consumed by adding `ReentrancyGuard`.
   */
  uint256[950] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./OZ/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";

import "../interfaces/IGetFees.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IRoyaltyInfo.sol";
import "../interfaces/ITokenCreator.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";

error NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();

/**
 * @title A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
  Constants,
  ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
  using OZERC165Checker for address;

  IRoyaltyRegistry private immutable royaltyRegistry;

  /**
   * @notice Configures the registry allowing for royalty overrides to be defined.
   * @param _royaltyRegistry The registry to use for royalty overrides.
   */
  constructor(address _royaltyRegistry) {
    if (!_royaltyRegistry.supportsInterface(type(IRoyaltyRegistry).interfaceId)) {
      revert NFTMarketCreators_Address_Does_Not_Support_IRoyaltyRegistry();
    }
    royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
  }

  /**
   * @notice Looks up the royalty payment configuration for a given NFT.
   * If more than 5 royalty recipients are defined, only the first 5 are sent royalties - the others are ignored.
   * The percents distributed will always be normalized to exactly 10%, when multiple recipients are defined
   * we use the values returned to determine how much of that 10% each recipient should get.
   * @dev This will check various royalty APIs on the NFT and the royalty override
   * if one was registered with the royalty registry. This aims to send royalties
   * in the manner requested by the NFT owner, regardless of where the NFT was minted.
   */
  // solhint-disable-next-line code-complexity
  function _getCreatorPaymentInfo(address nftContract, uint256 tokenId)
    internal
    view
    returns (address payable[] memory recipients, uint256[] memory splitPerRecipientInBasisPoints)
  {
    // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented

    // 1st priority: ERC-2981
    if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
      try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
        address receiver,
        uint256 royaltyAmount
      ) {
        // Manifold contracts return (address(this), 0) when royalties are not defined
        // - so ignore results when the amount is 0
        if (royaltyAmount > 0) {
          recipients = new address payable[](1);
          recipients[0] = payable(receiver);
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
          return (recipients, splitPerRecipientInBasisPoints);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 2nd priority: getRoyalties
    if (nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
      try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients,
        uint256[] memory recipientBasisPoints
      ) {
        uint256 recipientLen = _recipients.length;
        if (recipientLen != 0 && recipientLen == recipientBasisPoints.length) {
          return (_recipients, recipientBasisPoints);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    /* Overrides must support ERC-165 when registered, except for overrides defined by the registry owner.
       If that results in an override w/o 165 we may need to upgrade the market to support or ignore that override. */
    // The registry requires overrides are not 0 and contracts when set.
    // If no override is set, the nftContract address is returned.

    try royaltyRegistry.getRoyaltyLookupAddress{ gas: READ_ONLY_GAS_LIMIT }(nftContract) returns (
      address overrideContract
    ) {
      if (overrideContract != nftContract) {
        nftContract = overrideContract;

        // The functions above are repeated here if an override is set.

        // 3rd priority: ERC-2981 override
        if (nftContract.supportsERC165Interface(type(IRoyaltyInfo).interfaceId)) {
          try IRoyaltyInfo(nftContract).royaltyInfo{ gas: READ_ONLY_GAS_LIMIT }(tokenId, BASIS_POINTS) returns (
            address receiver,
            uint256 /* royaltyAmount */
          ) {
            recipients = new address payable[](1);
            recipients[0] = payable(receiver);
            // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
            return (recipients, splitPerRecipientInBasisPoints);
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }

        // 4th priority: getRoyalties override
        if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
          try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            address payable[] memory _recipients,
            uint256[] memory recipientBasisPoints
          ) {
            uint256 recipientLen = _recipients.length;
            if (recipientLen != 0 && recipientLen == recipientBasisPoints.length) {
              return (_recipients, recipientBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Ignore out of gas errors and continue using the nftContract address
    }

    // 5th priority: getFee* from contract or override
    if (nftContract.supportsERC165Interface(type(IGetFees).interfaceId)) {
      try IGetFees(nftContract).getFeeRecipients{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients
      ) {
        uint256 recipientLen = _recipients.length;
        if (recipientLen != 0) {
          try IGetFees(nftContract).getFeeBps{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            uint256[] memory recipientBasisPoints
          ) {
            if (recipientLen == recipientBasisPoints.length) {
              return (_recipients, recipientBasisPoints);
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 6th priority: tokenCreator w/ or w/o requiring 165 from contract or override
    try ITokenCreator(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
      address payable _creator
    ) {
      // Only pay the tokenCreator if there wasn't another royalty defined
      recipients = new address payable[](1);
      recipients[0] = _creator;
      // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
      return (recipients, splitPerRecipientInBasisPoints);
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // 7th priority: owner from contract or override
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
      // Only pay the owner if there wasn't another royalty defined
      recipients = new address payable[](1);
      recipients[0] = payable(owner);
      // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
      return (recipients, splitPerRecipientInBasisPoints);
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }

  /**
   * @notice Returns the address of the registry allowing for royalty configuration overrides.
   * @return registry The address of the royalty registry contract.
   */
  function getRoyaltyRegistry() public view returns (address registry) {
    return address(royaltyRegistry);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 500 slots were consumed with the addition of `SendValueWithFallbackWithdraw`.
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Constants.sol";
import "./FoundationTreasuryNode.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @title A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is Constants, Initializable, FoundationTreasuryNode, SendValueWithFallbackWithdraw {
  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * uint256 private _primaryFoundationFeeBasisPoints;
   * uint256 private _secondaryFoundationFeeBasisPoints;
   * uint256 private _secondaryCreatorFeeBasisPoints;
   * mapping(address => mapping(uint256 => bool)) private _nftContractToTokenIdToFirstSaleCompleted;
   */
  uint256[4] private __gap_was_fees;

  /// @notice The royalties sent to creator recipients on secondary sales.
  uint256 private constant CREATOR_ROYALTY_DENOMINATOR = BASIS_POINTS / 1000; // 10%
  /// @notice The fee collected by Foundation for sales facilitated by this market contract.
  uint256 private constant FOUNDATION_FEE_DENOMINATOR = BASIS_POINTS / 500; // 5%

  /**
   * @notice Distributes funds to foundation, creator recipients, and NFT owner after a sale.
   */
  // solhint-disable-next-line code-complexity
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 foundationFee,
      uint256 creatorFee,
      uint256 ownerRev
    )
  {
    address payable[] memory creatorRecipients;
    uint256[] memory creatorShares;

    address payable ownerRevTo;
    (foundationFee, creatorRecipients, creatorShares, creatorFee, ownerRevTo, ownerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );

    _sendValueWithFallbackWithdraw(getFoundationTreasury(), foundationFee, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    if (creatorFee != 0) {
      if (creatorRecipients.length > 1) {
        uint256 maxCreatorIndex = creatorRecipients.length;
        unchecked {
          // maxCreatorIndex cannot underflow due to the if above
          --maxCreatorIndex;
        }

        if (maxCreatorIndex > MAX_ROYALTY_RECIPIENTS_INDEX) {
          maxCreatorIndex = MAX_ROYALTY_RECIPIENTS_INDEX;
        }

        // Determine the total shares defined so it can be leveraged to distribute below
        uint256 totalShares;
        unchecked {
          // The array length cannot overflow 256 bits.
          for (uint256 i = 0; i <= maxCreatorIndex; ++i) {
            if (creatorShares[i] > BASIS_POINTS) {
              // If the numbers are >100% we ignore the fee recipients and pay just the first instead
              maxCreatorIndex = 0;
              break;
            }
            // The check above ensures totalShares wont overflow.
            totalShares += creatorShares[i];
          }
        }
        if (totalShares == 0) {
          maxCreatorIndex = 0;
        }

        // Send payouts to each additional recipient if more than 1 was defined
        uint256 totalRoyaltiesDistributed;
        for (uint256 i = 1; i <= maxCreatorIndex; ) {
          uint256 royalty = (creatorFee * creatorShares[i]) / totalShares;
          totalRoyaltiesDistributed += royalty;
          _sendValueWithFallbackWithdraw(creatorRecipients[i], royalty, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
          unchecked {
            ++i;
          }
        }

        // Send the remainder to the 1st creator, rounding in their favor
        _sendValueWithFallbackWithdraw(
          creatorRecipients[0],
          creatorFee - totalRoyaltiesDistributed,
          SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS
        );
      } else {
        _sendValueWithFallbackWithdraw(creatorRecipients[0], creatorFee, SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS);
      }
    }
    _sendValueWithFallbackWithdraw(ownerRevTo, ownerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
  }

  /**
   * @notice Returns how funds will be distributed for a sale at the given price point.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The sale price to calculate the fees for.
   * @return foundationFee How much will be sent to the Foundation treasury.
   * @return creatorRev How much will be sent across all the `creatorRecipients` defined.
   * @return creatorRecipients The addresses of the recipients to receive a portion of the creator fee.
   * @return creatorShares The percentage of the creator fee to be distributed to each `creatorRecipient`.
   * If there is only one `creatorRecipient`, this may be an empty array.
   * Otherwise `creatorShares.length` == `creatorRecipients.length`.
   * @return ownerRev How much will be sent to the owner/seller of the NFT.
   * If the NFT is being sold by the creator, this may be 0 and the full revenue will appear as `creatorRev`.
   * @return owner The address of the owner of the NFT.
   * If `ownerRev` is 0, this may be `address(0)`.
   */
  function getFeesAndRecipients(
    address nftContract,
    uint256 tokenId,
    uint256 price
  )
    external
    view
    returns (
      uint256 foundationFee,
      uint256 creatorRev,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 ownerRev,
      address payable owner
    )
  {
    address payable seller = _getSellerFor(nftContract, tokenId);
    (foundationFee, creatorRecipients, creatorShares, creatorRev, owner, ownerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );
  }

  /**
   * @notice Calculates how funds should be distributed for the given sale details.
   * @dev When the NFT is being sold by the `tokenCreator`, all the seller revenue will
   * be split with the royalty recipients defined for that NFT.
   */
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    private
    view
    returns (
      uint256 foundationFee,
      address payable[] memory creatorRecipients,
      uint256[] memory creatorShares,
      uint256 creatorRev,
      address payable ownerRevTo,
      uint256 ownerRev
    )
  {
    bool isCreator = false;
    // lookup for tokenCreator
    try ITokenCreator(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
      address payable _creator
    ) {
      isCreator = _creator == seller;
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    (creatorRecipients, creatorShares) = _getCreatorPaymentInfo(nftContract, tokenId);

    // Calculate the Foundation fee
    unchecked {
      // SafeMath is not required when dividing by a non-zero constant.
      foundationFee = price / FOUNDATION_FEE_DENOMINATOR;
    }

    if (creatorRecipients.length != 0) {
      if (isCreator || (creatorRecipients.length == 1 && seller == creatorRecipients[0])) {
        // When sold by the creator, all revenue is split if applicable.
        unchecked {
          // foundationFee is always < price.
          creatorRev = price - foundationFee;
        }
      } else {
        // Rounding favors the owner first, then creator, and foundation last.
        unchecked {
          // SafeMath is not required when dividing by a non-zero constant.
          creatorRev = price / CREATOR_ROYALTY_DENOMINATOR;
        }
        ownerRevTo = seller;
        ownerRev = price - foundationFee - creatorRev;
      }
    } else {
      // No royalty recipients found.
      ownerRevTo = seller;
      unchecked {
        // foundationFee is always < price.
        ownerRev = price - foundationFee;
      }
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./FoundationTreasuryNode.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
/// @param currentOfferAmount The current highest offer available for this NFT.
error NFTMarketOffer_Offer_Below_Min_Amount(uint256 currentOfferAmount);
/// @param expiry The time at which the offer had expired.
error NFTMarketOffer_Offer_Expired(uint256 expiry);
/// @param currentOfferFrom The address of the collector which has made the current highest offer.
error NFTMarketOffer_Offer_From_Does_Not_Match(address currentOfferFrom);
/// @param minOfferAmount The minimum amount that must be offered in order for it to be accepted.
error NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(uint256 minOfferAmount);
error NFTMarketOffer_Reason_Required();
error NFTMarketOffer_Provided_Contract_And_TokenId_Count_Must_Match();

/**
 * @title Allows collectors to make an offer for an NFT, valid for 24-25 hours.
 * @notice Funds are escrowed in the FETH ERC-20 token contract.
 */
abstract contract NFTMarketOffer is FoundationTreasuryNode, NFTMarketCore, ReentrancyGuardUpgradeable, NFTMarketFees {
  using AddressUpgradeable for address;

  /// @notice Stores offer details for a specific NFT.
  struct Offer {
    // Slot 1: When increasing an offer, only this slot is updated.
    /// @notice The expiration timestamp of when this offer expires.
    uint32 expiration;
    /// @notice The amount, in wei, of the highest offer.
    uint96 amount;
    // 128 bits are available in slot 1

    // Slot 2: When the buyer changes, both slots need updating
    /// @notice The address of the collector who made this offer.
    address buyer;
  }

  /// @notice Stores the highest offer for each NFT.
  mapping(address => mapping(uint256 => Offer)) private nftContractToIdToOffer;

  /**
   * @notice Emitted when an offer is accepted,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The accepted total offer amount is `f8nFee` + `creatorFee` + `ownerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer which was accepted.
   * @param seller The address of the seller which accepted the offer.
   * @param f8nFee The amount of ETH that was sent to Foundation for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param ownerRev The amount of ETH that was sent to the owner for this sale.
   */
  event OfferAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  /**
   * @notice Emitted when an offer is canceled by a Foundation admin.
   * @dev This should only be used for extreme cases such as DMCA takedown requests.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reason The reason for the cancellation (a required field).
   */
  event OfferCanceledByAdmin(address indexed nftContract, uint256 indexed tokenId, string reason);
  /**
   * @notice Emitted when an offer is invalidated due to other market activity.
   * When this occurs, the collector which made the offer has their FETH balance unlocked
   * and the funds are available to place other offers or to be withdrawn.
   * @dev This occurs when the offer is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event OfferInvalidated(address indexed nftContract, uint256 indexed tokenId);
  /**
   * @notice Emitted when an offer is made.
   * @dev The `amount` of the offer is locked in the FETH ERC-20 contract, guaranteeing that the funds
   * remain available until the `expiration` date.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that made the offer to buy this NFT.
   * @param amount The amount, in wei, of the offer.
   * @param expiration The expiration timestamp for the offer.
   */
  event OfferMade(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 amount,
    uint256 expiration
  );

  /**
   * @notice Accept the highest offer for an NFT.
   * @dev The offer must not be expired and the NFT owned + approved by the seller or
   * available in the market contract's escrow.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param offerFrom The address of the collector that you wish to sell to.
   * If the current highest offer is not from this user, the transaction will revert.
   * This could happen if a last minute offer was made by another collector,
   * and would require the seller to try accepting again.
   * @param minAmount The minimum value of the highest offer for it to be accepted.
   * If the value is less than this amount, the transaction will revert.
   * This could happen if the original offer expires and is replaced with a smaller offer.
   */
  function acceptOffer(
    address nftContract,
    uint256 tokenId,
    address offerFrom,
    uint256 minAmount
  ) external nonReentrant {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    // Validate offer expiry and amount
    if (offer.expiration < block.timestamp) {
      revert NFTMarketOffer_Offer_Expired(offer.expiration);
    } else if (offer.amount < minAmount) {
      revert NFTMarketOffer_Offer_Below_Min_Amount(offer.amount);
    }
    // Validate the buyer
    if (offer.buyer != offerFrom) {
      revert NFTMarketOffer_Offer_From_Does_Not_Match(offer.buyer);
    }

    _acceptOffer(nftContract, tokenId);
  }

  /**
   * @notice Allows Foundation to cancel offers.
   * This will unlock the funds in the FETH ERC-20 contract for the highest offer
   * and prevent the offer from being accepted.
   * @dev This should only be used for extreme cases such as DMCA takedown requests.
   * @param nftContracts The addresses of the NFT contracts to cancel. This must be the same length as `tokenIds`.
   * @param tokenIds The ids of the NFTs to cancel. This must be the same length as `nftContracts`.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelOffers(
    address[] calldata nftContracts,
    uint256[] calldata tokenIds,
    string calldata reason
  ) external onlyFoundationAdmin nonReentrant {
    if (bytes(reason).length == 0) {
      revert NFTMarketOffer_Reason_Required();
    }
    if (nftContracts.length != tokenIds.length) {
      revert NFTMarketOffer_Provided_Contract_And_TokenId_Count_Must_Match();
    }

    // The array length cannot overflow 256 bits
    unchecked {
      for (uint256 i = 0; i < nftContracts.length; ++i) {
        Offer memory offer = nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];
        delete nftContractToIdToOffer[nftContracts[i]][tokenIds[i]];

        if (offer.expiration >= block.timestamp) {
          // Unlock from escrow and emit an event only if the offer is still active
          feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);
          emit OfferCanceledByAdmin(nftContracts[i], tokenIds[i], reason);
        }
        // Else continue on so the rest of the batch transaction can process successfully
      }
    }
  }

  /**
   * @notice Make an offer for any NFT which is valid for 24-25 hours.
   * The funds will be locked in the FETH token contract and become available once the offer is outbid or has expired.
   * @dev An offer may be made for an NFT before it is minted, although we generally not recommend you do that.
   * If there is a buy price set at this price or lower, that will be accepted instead of making an offer.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available FETH balance.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param amount The amount to offer for this NFT.
   * @return expiration The timestamp for when this offer will expire.
   * This is provided as a return value in case another contract would like to leverage this information,
   * user's should refer to the expiration in the `OfferMade` event log.
   * If the buy price is accepted instead, `0` is returned as the expiration since that's n/a.
   */
  function makeOffer(
    address nftContract,
    uint256 tokenId,
    uint256 amount
  ) external payable returns (uint256 expiration) {
    // If there is a buy price set at this price or lower, accept that instead.
    if (_autoAcceptBuyPrice(nftContract, tokenId, amount)) {
      // If the buy price is accepted, `0` is returned as the expiration since that's n/a.
      return 0;
    }

    if (_isInActiveAuction(nftContract, tokenId)) {
      revert NFTMarketOffer_Cannot_Be_Made_While_In_Auction();
    }

    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];

    if (offer.expiration < block.timestamp) {
      // This is a new offer for the NFT (no other offer found or the previous offer expired)

      // Lock the offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketLockupFor{ value: msg.value }(msg.sender, amount);
    } else {
      // A previous offer exists and has not expired

      uint256 minIncrement = _getMinIncrement(offer.amount);
      if (amount < minIncrement) {
        // A non-trivial increase in price is required to avoid sniping
        revert NFTMarketOffer_Offer_Must_Be_At_Least_Min_Amount(minIncrement);
      }

      // Unlock the previous offer so that the FETH tokens are available for other offers or to transfer / withdraw
      // and lock the new offer amount in FETH until the offer expires in 24-25 hours.
      expiration = feth.marketChangeLockup{ value: msg.value }(
        offer.buyer,
        offer.expiration,
        offer.amount,
        msg.sender,
        amount
      );
    }

    // Record offer details
    offer.buyer = msg.sender;
    // The FETH contract guarantees that the expiration fits into 32 bits.
    offer.expiration = uint32(expiration);
    // `amount` is capped by the ETH provided, which cannot realistically overflow 96 bits.
    offer.amount = uint96(amount);

    emit OfferMade(nftContract, tokenId, msg.sender, amount, expiration);
  }

  /**
   * @notice Accept the highest offer for an NFT from the `msg.sender` account.
   * The NFT will be transferred to the buyer and revenue from the sale will be distributed.
   * @dev The caller must validate the expiry and amount before calling this helper.
   * This may invalidate other market tools, such as clearing the buy price if set.
   */
  function _acceptOffer(address nftContract, uint256 tokenId) private {
    Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

    // Remove offer
    delete nftContractToIdToOffer[nftContract][tokenId];
    // Withdraw ETH from the buyer's account in the FETH token contract.
    feth.marketWithdrawLocked(offer.buyer, offer.expiration, offer.amount);

    // Transfer the NFT to the buyer.
    try
      IERC721(nftContract).transferFrom(msg.sender, offer.buyer, tokenId) // solhint-disable-next-line no-empty-blocks
    {
      // NFT was in the seller's wallet so the transfer is complete.
    } catch {
      // If the transfer fails then attempt to transfer from escrow instead.
      // This should revert if `msg.sender` is not the owner of this NFT.
      _transferFromEscrow(nftContract, tokenId, offer.buyer, msg.sender);
    }

    // Distribute revenue for this sale leveraging the ETH received from the FETH contract in the line above.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      nftContract,
      tokenId,
      payable(msg.sender),
      offer.amount
    );

    emit OfferAccepted(nftContract, tokenId, offer.buyer, msg.sender, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the highest offer when an auction is kicked off, if one is found.
   */
  function _beforeAuctionStarted(address nftContract, uint256 tokenId) internal virtual override {
    _invalidateOffer(nftContract, tokenId);
    super._beforeAuctionStarted(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _autoAcceptOffer(
    address nftContract,
    uint256 tokenId,
    uint256 minAmount
  ) internal override returns (bool) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp || offer.amount < minAmount) {
      // No offer found, the most recent offer is now expired, or the highest offer is below the minimum amount.
      return false;
    }

    _acceptOffer(nftContract, tokenId);
    return true;
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _cancelSendersOffer(address nftContract, uint256 tokenId) internal override {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.buyer == msg.sender) {
      _invalidateOffer(nftContract, tokenId);
    }
  }

  /**
   * @notice Invalidates the offer and frees ETH from escrow, if the offer has not already expired.
   * @dev Offers are not invalidated when the NFT is purchased by accepting the buy price unless it
   * was purchased by the same user.
   * The user which just purchased the NFT may have buyer's remorse and promptly decide they want a fast exit,
   * accepting a small loss to limit their exposure.
   */
  function _invalidateOffer(address nftContract, uint256 tokenId) private {
    if (nftContractToIdToOffer[nftContract][tokenId].expiration >= block.timestamp) {
      // An offer was found and it has not already expired
      Offer memory offer = nftContractToIdToOffer[nftContract][tokenId];

      // Remove offer
      delete nftContractToIdToOffer[nftContract][tokenId];

      // Unlock the offer so that the FETH tokens are available for other offers or to transfer / withdraw
      feth.marketUnlockFor(offer.buyer, offer.expiration, offer.amount);

      emit OfferInvalidated(nftContract, tokenId);
    }
  }

  /**
   * @notice Returns the minimum amount a collector must offer for this NFT in order for the offer to be valid.
   * @dev Offers for this NFT which are less than this value will revert.
   * Once the previous offer has expired smaller offers can be made.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return minimum The minimum amount that must be offered for this NFT.
   */
  function getMinOfferAmount(address nftContract, uint256 tokenId) external view returns (uint256 minimum) {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration >= block.timestamp) {
      return _getMinIncrement(offer.amount);
    }
    // Absolute min is anything > 0
    return 1;
  }

  /**
   * @notice Returns details about the current highest offer for an NFT.
   * @dev Default values are returned if there is no offer or the offer has expired.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return buyer The address of the buyer that made the current highest offer.
   * Returns `address(0)` if there is no offer or the most recent offer has expired.
   * @return expiration The timestamp that the current highest offer expires.
   * Returns `0` if there is no offer or the most recent offer has expired.
   * @return amount The amount being offered for this NFT.
   * Returns `0` if there is no offer or the most recent offer has expired.
   */
  function getOffer(address nftContract, uint256 tokenId)
    external
    view
    returns (
      address buyer,
      uint256 expiration,
      uint256 amount
    )
  {
    Offer storage offer = nftContractToIdToOffer[nftContract][tokenId];
    if (offer.expiration < block.timestamp) {
      // Offer not found or has expired
      return (address(0), 0, 0);
    }

    // An offer was found and it has not yet expired.
    return (offer.buyer, offer.expiration, offer.amount);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./NFTMarketFees.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketPrivateSale_Can_Be_Offered_For_24Hrs_Max();
error NFTMarketPrivateSale_Signature_Canceled_Or_Already_Claimed();
error NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
error NFTMarketPrivateSale_Sale_Expired();
error NFTMarketPrivateSale_Signature_Verification_Failed();
error NFTMarketPrivateSale_Too_Much_Value_Provided();

/**
 * @title Allows owners to offer an NFT for sale to a specific collector.
 * @notice Private sales are authorized by the seller with an EIP-712 signature.
 * @dev Private sale offers must be accepted by the buyer before they expire, typically in 24 hours.
 */
abstract contract NFTMarketPrivateSale is NFTMarketFees {
  using AddressUpgradeable for address;
  using ECDSA for bytes32;

  /// @dev This value was replaced with an immutable version.
  bytes32 private __gap_was_DOMAIN_SEPARATOR;

  /// @notice Tracks if a private sale has already been used.
  /// @dev Maps nftContract -> tokenId -> buyer -> seller -> amount -> deadline -> invalidated.
  // solhint-disable-next-line max-line-length
  mapping(address => mapping(uint256 => mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => bool))))))
    private privateSaleInvalidated;

  /// @notice The domain used in EIP-712 signatures.
  /// @dev It is not a constant so that the chainId can be determined dynamically.
  /// If multiple classes use EIP-712 signatures in the future this can move to a shared file.
  bytes32 private immutable DOMAIN_SEPARATOR;

  /// @notice The hash of the private sale method signature used for EIP-712 signatures.
  bytes32 private constant BUY_FROM_PRIVATE_SALE_TYPEHASH =
    keccak256("BuyFromPrivateSale(address nftContract,uint256 tokenId,address buyer,uint256 price,uint256 deadline)");
  /// @notice The name used in the EIP-712 domain.
  /// @dev If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
  string private constant NAME = "FNDNFTMarket";

  /**
   * @notice Emitted when an NFT is sold in a private sale.
   * @dev The total amount of this sale is `f8nFee` + `creatorFee` + `ownerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The ID of the NFT.
   * @param seller The address of the seller.
   * @param buyer The address of the buyer.
   * @param f8nFee The amount of ETH that was sent to Foundation for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param ownerRev The amount of ETH that was sent to the owner for this sale.
   * @param deadline When the private sale offer was set to expire.
   */
  event PrivateSaleFinalized(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev,
    uint256 deadline
  );

  /**
   * @notice Configures the contract to accept EIP-712 signatures.
   * @param marketProxyAddress The address of the proxy contract which will be called when accepting a private sale.
   */
  constructor(address marketProxyAddress) {
    if (!marketProxyAddress.isContract()) {
      revert NFTMarketPrivateSale_Proxy_Address_Is_Not_A_Contract();
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(NAME)),
        // Incrementing the version can be used to invalidate previously signed messages.
        keccak256(bytes("1")),
        block.chainid,
        marketProxyAddress
      )
    );
  }

  /**
   * @notice Buy an NFT from a private sale.
   * @dev This API is deprecated and will be removed in the future, `buyFromPrivateSaleFor` should be used instead.
   * The seller signs a message approving the sale and then the buyer calls this function
   * with the `msg.value` equal to the agreed upon price.
   * If the seller is no longer the `ownerOf` this NFT or has removed approval for this contract,
   * attempts to purchase from private sale will revert.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The ID of the NFT.
   * @param deadline The timestamp at which the offer to sell will expire.
   * @param v The v value of the EIP-712 signature.
   * @param r The r value of the EIP-712 signature.
   * @param s The s value of the EIP-712 signature.
   */
  function buyFromPrivateSale(
    address nftContract,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable {
    buyFromPrivateSaleFor(nftContract, tokenId, msg.value, deadline, v, r, s);
  }

  /**
   * @notice Buy an NFT from a private sale.
   * @dev The seller signs a message approving the sale and then the buyer calls this function
   * with the `amount` equal to the agreed upon price.
   * If the seller is no longer the `ownerOf` this NFT or has removed approval for this contract,
   * attempts to purchase from private sale will revert.
   * @dev `amount` - `msg.value` is withdrawn from the bidder's FETH balance.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The ID of the NFT.
   * @param amount The amount to buy for, if this is more than `msg.value` funds will be
   * withdrawn from your FETH balance.
   * @param deadline The timestamp at which the offer to sell will expire.
   * @param v The v value of the EIP-712 signature.
   * @param r The r value of the EIP-712 signature.
   * @param s The s value of the EIP-712 signature.
   */
  function buyFromPrivateSaleFor(
    address nftContract,
    uint256 tokenId,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable nonReentrant {
    // now + 2 days cannot overflow
    unchecked {
      if (deadline < block.timestamp) {
        // The signed message from the seller has expired.
        revert NFTMarketPrivateSale_Sale_Expired();
      } else if (deadline > block.timestamp + 2 days) {
        // Private sales typically expire in 24 hours, but 2 days is used here in order to ensure
        // that transactions do not fail due to a minor timezone error or similar during signing.

        // This prevents malicious actors from requesting signatures that never expire.
        revert NFTMarketPrivateSale_Can_Be_Offered_For_24Hrs_Max();
      }
    }

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    _cancelSendersOffer(address(nftContract), tokenId);

    if (amount > msg.value) {
      // Withdraw additional ETH required from their available FETH balance.

      unchecked {
        // The if above ensures delta will not underflow
        feth.marketWithdrawFrom(msg.sender, amount - msg.value);
      }
    } else if (amount < msg.value) {
      // The terms of the sale cannot change, so if too much ETH is sent then something went wrong.
      revert NFTMarketPrivateSale_Too_Much_Value_Provided();
    }

    // The seller must have the NFT in their wallet when this function is called,
    // otherwise the signature verification below will fail.
    address payable seller = payable(IERC721(nftContract).ownerOf(tokenId));

    // Ensure that the offer can only be accepted once.
    if (privateSaleInvalidated[nftContract][tokenId][msg.sender][seller][amount][deadline]) {
      revert NFTMarketPrivateSale_Signature_Canceled_Or_Already_Claimed();
    }
    privateSaleInvalidated[nftContract][tokenId][msg.sender][seller][amount][deadline] = true;

    // Scoping this block to avoid a stack too deep error
    {
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(BUY_FROM_PRIVATE_SALE_TYPEHASH, nftContract, tokenId, msg.sender, amount, deadline))
        )
      );

      // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
      if (digest.recover(v, r, s) != seller) {
        revert NFTMarketPrivateSale_Signature_Verification_Failed();
      }
    }

    // This should revert if the seller has not given the market contract approval.
    IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);

    // Distribute revenue for this sale.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(nftContract, tokenId, seller, amount);

    emit PrivateSaleFinalized(nftContract, tokenId, seller, msg.sender, f8nFee, creatorFee, ownerRev, deadline);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 1 slot was consumed by privateSaleInvalidated.
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./FoundationTreasuryNode.sol";
import "./NFTMarketAuction.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";
import "./SendValueWithFallbackWithdraw.sol";

/// @param auctionId The already listed auctionId for this NFT.
error NFTMarketReserveAuction_Already_Listed(uint256 auctionId);
/// @param minAmount The minimum amount that must be bid in order for it to be accepted.
error NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(uint256 minAmount);
error NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
/// @param reservePrice The current reserve price.
error NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(uint256 reservePrice);
/// @param endTime The timestamp at which the auction had ended.
error NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
error NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
/// @param endTime The timestamp at which the auction will end.
error NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(uint256 endTime);
error NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
error NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
/// @param maxDuration The maximum configuration for a duration of the auction, in seconds.
error NFTMarketReserveAuction_Exceeds_Max_Duration(uint256 maxDuration);
/// @param extensionDuration The extension duration, in seconds.
error NFTMarketReserveAuction_Less_Than_Extension_Duration(uint256 extensionDuration);
error NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
/// @param seller The current owner of the NFT.
error NFTMarketReserveAuction_Not_Matching_Seller(address seller);
/// @param owner The current owner of the NFT.
error NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(address owner);
error NFTMarketReserveAuction_Price_Already_Set();
error NFTMarketReserveAuction_Too_Much_Value_Provided();

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 * @dev There is room to optimize the storage for auctions, significantly reducing gas costs.
 * This may be done in the future, but for now it will remain as is in order to ease upgrade compatibility.
 */
abstract contract NFTMarketReserveAuction is
  Constants,
  FoundationTreasuryNode,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction
{
  /// @notice Stores the auction configuration for a specific NFT.
  struct ReserveAuction {
    /// @notice The address of the NFT contract.
    address nftContract;
    /// @notice The id of the NFT.
    uint256 tokenId;
    /// @notice The owner of the NFT which listed it in auction.
    address payable seller;
    /// @notice The duration for this auction.
    uint256 duration;
    /// @notice The extension window for this auction.
    uint256 extensionDuration;
    /// @notice The time at which this auction will not accept any new bids.
    /// @dev This is `0` until the first bid is placed.
    uint256 endTime;
    /// @notice The current highest bidder in this auction.
    /// @dev This is `address(0)` until the first bid is placed.
    address payable bidder;
    /// @notice The latest price of the NFT in this auction.
    /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
    uint256 amount;
  }

  /// @notice The auction configuration for a specific auction id.
  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToAuctionId;
  /// @notice The auction id for a specific NFT.
  /// @dev This is deleted when an auction is finalized or canceled.
  mapping(uint256 => ReserveAuction) private auctionIdToAuction;

  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * uint256 private __gap_was_minPercentIncrementInBasisPoints;
   * uint256 private __gap_was_maxBidIncrementRequirement;
   * uint256 private __gap_was_duration;
   * uint256 private __gap_was_extensionDuration;
   * uint256 private __gap_was_goLiveDate;
   */
  uint256[5] private __gap_was_config;

  /// @notice How long an auction lasts for once the first bid has been received.
  uint256 private immutable DURATION;

  /// @notice The window for auction extensions, any bid placed in the final 15 minutes
  /// of an auction will reset the time remaining to 15 minutes.
  uint256 private constant EXTENSION_DURATION = 15 minutes;

  /// @notice Caps the max duration that may be configured so that overflows will not occur.
  uint256 private constant MAX_MAX_DURATION = 1000 days;

  /**
   * @notice Emitted when a bid is placed.
   * @param auctionId The id of the auction this bid was for.
   * @param bidder The address of the bidder.
   * @param amount The amount of the bid.
   * @param endTime The new end time of the auction (which may have been set or extended by this bid).
   */
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  /**
   * @notice Emitted when an auction is cancelled.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was cancelled.
   */
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  /**
   * @notice Emitted when an auction is canceled by a Foundation admin.
   * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
   * @param auctionId The id of the auction that was cancelled.
   * @param reason The reason for the cancellation.
   */
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  /**
   * @notice Emitted when an NFT is listed for auction.
   * @param seller The address of the seller.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param duration The duration of the auction (always 24-hours).
   * @param extensionDuration The duration of the auction extension window (always 15-minutes).
   * @param reservePrice The reserve price to kick off the auction.
   * @param auctionId The id of the auction that was created.
   */
  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  /**
   * @notice Emitted when an auction that has already ended is finalized,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The amount of the highest bid / final sale price for this auction is `f8nFee` + `creatorFee` + `ownerRev`.
   * @param auctionId The id of the auction that was finalized.
   * @param seller The address of the seller.
   * @param bidder The address of the highest bidder that won the NFT.
   * @param f8nFee The amount of ETH that was sent to Foundation for this sale.
   * @param creatorFee The amount of ETH that was sent to the creator for this sale.
   * @param ownerRev The amount of ETH that was sent to the owner for this sale.
   */
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 f8nFee,
    uint256 creatorFee,
    uint256 ownerRev
  );
  /**
   * @notice Emitted when an auction is invalidated due to other market activity.
   * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
   * @param auctionId The id of the auction that was invalidated.
   */
  event ReserveAuctionInvalidated(uint256 indexed auctionId);
  /**
   * @notice Emitted when the auction's reserve price is changed.
   * @dev This is only possible if the auction has not received any bids.
   * @param auctionId The id of the auction that was updated.
   * @param reservePrice The new reserve price for the auction.
   */
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

  /// @notice Confirms that the reserve price is not zero.
  modifier onlyValidAuctionConfig(uint256 reservePrice) {
    if (reservePrice == 0) {
      revert NFTMarketReserveAuction_Must_Set_Non_Zero_Reserve_Price();
    }
    _;
  }

  /**
   * @notice Configures the duration for auctions.
   * @param duration The duration for auctions, in seconds.
   */
  constructor(uint256 duration) {
    if (duration > MAX_MAX_DURATION) {
      // This ensures that math in this file will not overflow due to a huge duration.
      revert NFTMarketReserveAuction_Exceeds_Max_Duration(MAX_MAX_DURATION);
    }
    if (duration < EXTENSION_DURATION) {
      // The auction duration configuration must be greater than the extension window of 15 minutes
      revert NFTMarketReserveAuction_Less_Than_Extension_Duration(EXTENSION_DURATION);
    }
    DURATION = duration;
  }

  /**
   * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
   * the seller (if not active buy price set).
   * This should only be used for extreme cases such as DMCA takedown requests.
   * @param auctionId The id of the auction to cancel.
   * @param reason The reason for the cancellation (a required field).
   */
  function adminCancelReserveAuction(uint256 auctionId, string calldata reason)
    external
    onlyFoundationAdmin
    nonReentrant
  {
    if (bytes(reason).length == 0) {
      revert NFTMarketReserveAuction_Cannot_Admin_Cancel_Without_Reason();
    }
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.amount == 0) {
      revert NFTMarketReserveAuction_Cannot_Cancel_Nonexistent_Auction();
    }

    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    // Return the NFT to the owner.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenId, auction.seller);

    if (auction.bidder != address(0)) {
      // Refund the highest bidder if any bids were placed in this auction.
      _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    emit ReserveAuctionCanceledByAdmin(auctionId, reason);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
   * @dev The NFT is transferred back to the owner unless there is still a buy price set.
   * @param auctionId The id of the auction to cancel.
   */
  function cancelReserveAuction(uint256 auctionId) external nonReentrant {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    }
    if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    // Transfer the NFT unless it still has a buy price set.
    _transferFromEscrowIfAvailable(auction.nftContract, auction.tokenId, auction.seller);

    emit ReserveAuctionCanceled(auctionId);
  }

  /**
   * @notice Creates an auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param reservePrice The initial reserve price for the auction.
   */
  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
    uint256 auctionId = _getNextAndIncrementAuctionId();

    // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
    _transferToEscrow(nftContract, tokenId);

    // This check must be after _transferToEscrow in case auto-settle was required
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] != 0) {
      revert NFTMarketReserveAuction_Already_Listed(nftContractToTokenIdToAuctionId[nftContract][tokenId]);
    }

    // Store the auction details
    nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
    auctionIdToAuction[auctionId] = ReserveAuction(
      nftContract,
      tokenId,
      payable(msg.sender),
      DURATION,
      EXTENSION_DURATION,
      0, // endTime is only known once the reserve price is met
      payable(0), // bidder is only known once a bid has been placed
      reservePrice
    );

    emit ReserveAuctionCreated(msg.sender, nftContract, tokenId, DURATION, EXTENSION_DURATION, reservePrice, auctionId);
  }

  /**
   * @notice Once the countdown has expired for an auction, anyone can settle the auction.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param auctionId The id of the auction to settle.
   */
  function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
    if (auctionIdToAuction[auctionId].endTime == 0) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Already_Settled_Auction();
    }
    _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
  }

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev This API is deprecated and will be removed in the future, `placeBidOf` should be used instead.
   * @param auctionId The id of the auction to bid on.
   */
  function placeBid(uint256 auctionId) external payable {
    placeBidOf(auctionId, msg.value);
  }

  /**
   * @notice Place a bid in an auction.
   * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
   * If this is the first bid on the auction, the countdown will begin.
   * If there is already an outstanding bid, the previous bidder will be refunded at this time
   * and if the bid is placed in the final moments of the auction, the countdown may be extended.
   * @dev `amount` - `msg.value` is withdrawn from the bidder's FETH balance.
   * @param auctionId The id of the auction to bid on.
   * @param amount The amount to bid, if this is more than `msg.value` funds will be withdrawn from your FETH balance.
   */
  /* solhint-disable-next-line code-complexity */
  function placeBidOf(uint256 auctionId, uint256 amount) public payable nonReentrant {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];

    if (auction.amount == 0) {
      // No auction found
      revert NFTMarketReserveAuction_Cannot_Bid_On_Nonexistent_Auction();
    } else if (amount < msg.value) {
      // The amount is specified by the bidder, so if too much ETH is sent then something went wrong.
      revert NFTMarketReserveAuction_Too_Much_Value_Provided();
    }

    uint256 endTime = auction.endTime;
    if (endTime == 0) {
      // This is the first bid, kicking off the auction.

      if (amount < auction.amount) {
        // The bid must be >= the reserve price.
        revert NFTMarketReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price(auction.amount);
      }

      // Notify other market tools that an auction for this NFT has been kicked off.
      // The only state change before this call is potentially withdrawing funds from FETH.
      _beforeAuctionStarted(auction.nftContract, auction.tokenId);

      // Store the bid details.
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      // On the first bid, set the endTime to now + duration.
      unchecked {
        // Duration is always set to 24hrs so the below can't overflow.
        endTime = block.timestamp + DURATION;
      }
      auction.endTime = endTime;
    } else {
      if (endTime < block.timestamp) {
        // The auction has already ended.
        revert NFTMarketReserveAuction_Cannot_Bid_On_Ended_Auction(endTime);
      } else if (auction.bidder == msg.sender) {
        // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
        revert NFTMarketReserveAuction_Cannot_Rebid_Over_Outstanding_Bid();
      } else {
        uint256 minIncrement = _getMinIncrement(auction.amount);
        if (amount < minIncrement) {
          // If this bid outbids another, it must be at least 10% greater than the last bid.
          revert NFTMarketReserveAuction_Bid_Must_Be_At_Least_Min_Amount(minIncrement);
        }
      }

      // Cache and update bidder state
      uint256 originalAmount = auction.amount;
      address payable originalBidder = auction.bidder;
      auction.amount = amount;
      auction.bidder = payable(msg.sender);

      unchecked {
        // When a bid outbids another, check to see if a time extension should apply.
        // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
        // Current time plus extension duration (always 15 mins) cannot overflow.
        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
          endTime = endTimeWithExtension;
          auction.endTime = endTime;
        }
      }

      // Refund the previous bidder
      _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
    }

    // Withdraw last in order to leverage freed FETH balance.
    if (amount > msg.value) {
      // Withdraw additional ETH required from their available FETH balance.

      unchecked {
        // The if above ensures delta will not underflow.
        // Withdraw ETH from the buyer's account in the FETH token contract.
        feth.marketWithdrawFrom(msg.sender, amount - msg.value);
      }
    }

    emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
  }

  /**
   * @notice If an auction has been created but has not yet received bids, the reservePrice may be
   * changed by the seller.
   * @param auctionId The id of the auction to change.
   * @param reservePrice The new reserve price for this auction.
   */
  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external onlyValidAuctionConfig(reservePrice) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.seller != msg.sender) {
      revert NFTMarketReserveAuction_Only_Owner_Can_Update_Auction(auction.seller);
    } else if (auction.endTime != 0) {
      revert NFTMarketReserveAuction_Cannot_Update_Auction_In_Progress();
    } else if (auction.amount == reservePrice) {
      revert NFTMarketReserveAuction_Price_Already_Set();
    }

    // Update the current reserve price.
    auction.amount = reservePrice;

    emit ReserveAuctionUpdated(auctionId, reservePrice);
  }

  /**
   * @notice Settle an auction that has already ended.
   * This will send the NFT to the highest bidder and distribute revenue for this sale.
   * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
   * redundant transfers if the NFT should remain in escrow, such as when the new owner
   * sets a buy price or lists it in a new auction.
   */
  function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) private {
    ReserveAuction memory auction = auctionIdToAuction[auctionId];

    if (auction.endTime >= block.timestamp) {
      revert NFTMarketReserveAuction_Cannot_Finalize_Auction_In_Progress(auction.endTime);
    }

    // Remove the auction.
    delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
    delete auctionIdToAuction[auctionId];

    if (!keepInEscrow) {
      // The seller was authorized when the auction was originally created
      super._transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder, address(0));
    }

    // Distribute revenue for this sale.
    (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
      auction.nftContract,
      auction.tokenId,
      auction.seller,
      auction.amount
    );

    emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, f8nFee, creatorFee, ownerRev);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev If an auction is found:
   *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
   *  - If the auction has not received a bid, it will invalidate the auction.
   *  - If the auction is in progress, this will revert.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId != 0) {
      ReserveAuction storage auction = auctionIdToAuction[auctionId];
      if (auction.endTime == 0) {
        // The auction has not received any bids yet so it may be invalided.

        if (authorizeSeller != address(0) && auction.seller != authorizeSeller) {
          // The account trying to transfer the NFT is not the current owner.
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
        delete auctionIdToAuction[auctionId];

        emit ReserveAuctionInvalidated(auctionId);
      } else {
        // If the auction has ended, the highest bidder will be the new owner
        // and if the auction is in progress, this will revert.

        // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
        // through this path to know who the authorized seller should be.
        if (auction.bidder != authorizeSeller) {
          revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
        }

        // Finalization will revert if the auction has not yet ended.
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    if (nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0) {
      // No auction was found

      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    if (auctionId == 0) {
      // NFT is not in auction
      super._transferToEscrow(nftContract, tokenId);
      return;
    }
    // Using storage saves gas since most of the data is not needed
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      // Reserve price set, confirm the seller is a match
      if (auction.seller != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.seller);
      }
    } else {
      // Auction in progress, confirm the highest bidder is a match
      if (auction.bidder != msg.sender) {
        revert NFTMarketReserveAuction_Not_Matching_Seller(auction.bidder);
      }

      // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
      _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
    }
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   * Bids must be greater than or equal to this value or they will revert.
   * @param auctionId The id of the auction to check.
   * @return minimum The minimum amount for a bid to be accepted.
   */
  function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
    ReserveAuction storage auction = auctionIdToAuction[auctionId];
    if (auction.endTime == 0) {
      return auction.amount;
    }
    return _getMinIncrement(auction.amount);
  }

  /**
   * @notice Returns auction details for a given auctionId.
   * @param auctionId The id of the auction to lookup.
   * @return auction The auction details.
   */
  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
    return auctionIdToAuction[auctionId];
  }

  /**
   * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
   * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return auctionId The id of the auction, or 0 if no auction is found.
   */
  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
    auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Returns the seller that has the given NFT in escrow for an auction,
   * or bubbles the call up for other considerations.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  {
    seller = auctionIdToAuction[nftContractToTokenIdToAuctionId[nftContract][tokenId]].seller;
    if (seller == address(0)) {
      seller = super._getSellerFor(nftContract, tokenId);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _isInActiveAuction(address nftContract, uint256 tokenId) internal view override returns (bool) {
    uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    return auctionId != 0 && auctionIdToAuction[auctionId].endTime >= block.timestamp;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./FoundationTreasuryNode.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";

error SendValueWithFallbackWithdraw_No_Funds_Available();

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the FETH token contract for future withdrawal instead.
 * @dev This mixin was recently switched to escrow funds in FETH.
 * Once we have confirmed all pending balances have been withdrawn, we can remove the escrow tracking here.
 */
abstract contract SendValueWithFallbackWithdraw is
  FoundationTreasuryNode,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators
{
  using AddressUpgradeable for address payable;

  /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
  mapping(address => uint256) private __gap_was_pendingWithdrawals;

  /**
   * @notice Emitted when escrowed funds are withdrawn to FETH.
   * @param user The account which has withdrawn ETH.
   * @param amount The amount of ETH which has been withdrawn.
   */
  event WithdrawalToFETH(address indexed user, uint256 amount);

  /**
   * @dev Attempt to send a user or contract ETH and
   * if it fails store the amount owned for later withdrawal in FETH.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Store the funds that failed to send for the user in the FETH token
      feth.depositFor{ value: amount }(user);
      emit WithdrawalToFETH(user, amount);
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[499] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
  function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses in FETH.
 */
interface IFethMarket {
  function depositFor(address account) external payable;

  function marketLockupFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable returns (uint256 expiration);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol
 * Modified to allow checking multiple interfaces w/o checking general 165 support.
 */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Library to query ERC165 support.
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library OZERC165Checker {
  // As per the EIP-165 spec, no interface should ever match 0xffffffff
  bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

  /**
   * @dev Returns true if `account` supports the {IERC165} interface,
   */
  function supportsERC165(address account) internal view returns (bool) {
    // Any contract that implements ERC165 must explicitly indicate support of
    // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
    return
      supportsERC165Interface(account, type(IERC165).interfaceId) &&
      !supportsERC165Interface(account, _INTERFACE_ID_INVALID);
  }

  /**
   * @dev Returns true if `account` supports the interface defined by
   * `interfaceId`. Support for {IERC165} itself is queried automatically.
   *
   * See {IERC165-supportsInterface}.
   */
  function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
    // query support of both ERC165 as per the spec and support of _interfaceId
    return supportsERC165(account) && supportsERC165Interface(account, interfaceId);
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
  function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
    // an array of booleans corresponding to interfaceIds and whether they're supported or not
    bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

    // query support of ERC165 itself
    if (supportsERC165(account)) {
      // query support of each interface in interfaceIds
      unchecked {
        for (uint256 i = 0; i < interfaceIds.length; ++i) {
          interfaceIdsSupported[i] = supportsERC165Interface(account, interfaceIds[i]);
        }
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

    // query support of each interface in _interfaceIds
    unchecked {
      for (uint256 i = 0; i < interfaceIds.length; ++i) {
        if (!supportsERC165Interface(account, interfaceIds[i])) {
          return false;
        }
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
   * Interface identification is specified in ERC-165.
   */
  function supportsERC165Interface(address account, bytes4 interfaceId) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
    (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {

     event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     * 
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external;

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns(address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns(bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IERC20Approve {
  function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IERC20IncreaseAllowance {
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Library that handles locked balances efficiently using bit packing.
 */
library LockedBalance {
  /// @dev Tracks an account's total lockup per expiration time.
  struct Lockup {
    uint32 expiration;
    uint96 totalAmount;
  }

  struct Lockups {
    /// @dev Mapping from key to lockups.
    /// i) A key represents 2 lockups. The key for a lockup is `index / 2`.
    ///     For instance, elements with index 25 and 24 would map to the same key.
    /// ii) The `value` for the `key` is split into two 128bits which are used to store the metadata for a lockup.
    mapping(uint256 => uint256) lockups;
  }

  // Masks used to split a uint256 into two equal pieces which represent two individual Lockups.
  uint256 private constant last128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant first128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

  // Masks used to retrieve or set the totalAmount value of a single Lockup.
  uint256 private constant firstAmountBitsMask = 0xFFFFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant secondAmountBitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

  /**
   * @notice Clears the lockup at the index.
   */
  function del(Lockups storage lockups, uint256 index) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask);
      }
    }
  }

  /**
   * @notice Sets the Lockup at the provided index.
   */
  function set(
    Lockups storage lockups,
    uint256 index,
    uint256 expiration,
    uint256 totalAmount
  ) internal {
    unchecked {
      uint256 lockedBalanceBits = totalAmount | (expiration << 96);
      if (index % 2 == 0) {
        // set first 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask) | (lockedBalanceBits << 128);
      } else {
        // set last 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask) | lockedBalanceBits;
      }
    }
  }

  /**
   * @notice Sets only the totalAmount for a lockup at the index.
   */
  function setTotalAmount(
    Lockups storage lockups,
    uint256 index,
    uint256 totalAmount
  ) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & firstAmountBitsMask) | (totalAmount << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & secondAmountBitsMask) | totalAmount;
      }
    }
  }

  /**
   * @notice Returns the Lockup at the provided index.
   * @dev To get the lockup stored in the *first* 128 bits (first slot/lockup):
   *       - we remove the last 128 bits (done by >> 128)
   *      To get the lockup stored in the *last* 128 bits (second slot/lockup):
   *       - we take the last 128 bits (done by % (2**128))
   *      Once the lockup is obtained:
   *       - get `expiration` by peaking at the first 32 bits (done by >> 96)
   *       - get `totalAmount` by peaking at the last 96 bits (done by % (2**96))
   */
  function get(Lockups storage lockups, uint256 index) internal view returns (Lockup memory balance) {
    unchecked {
      uint256 lockupMetadata = lockups.lockups[index / 2];
      if (lockupMetadata == 0) {
        return balance;
      }
      uint128 lockedBalanceBits;
      if (index % 2 == 0) {
        // use first 128 bits.
        lockedBalanceBits = uint128(lockupMetadata >> 128);
      } else {
        // use last 128 bits.
        lockedBalanceBits = uint128(lockupMetadata % (2**128));
      }
      // unpack the bits to retrieve the Lockup.
      balance.expiration = uint32(lockedBalanceBits >> 96);
      balance.totalAmount = uint96(lockedBalanceBits % (2**96));
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/LockedBalance.sol";

contract LockedBalanceMock {
  using LockedBalance for LockedBalance.Lockups;
  LockedBalance.Lockups private lockups;

  function get(uint256 index) public view returns (LockedBalance.Lockup memory) {
    return lockups.get(index);
  }

  function set(
    uint256 index,
    uint256 expiration,
    uint256 totalAmount
  ) public {
    lockups.set(index, expiration, totalAmount);
  }

  function setTotalAmount(uint256 index, uint256 totalAmount) public {
    lockups.setTotalAmount(index, totalAmount);
  }

  function del(uint256 index) public {
    lockups.del(index);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "./IRoyaltyRegistry.sol";
import "./specs/INiftyGateway.sol";
import "./specs/IFoundation.sol";
import "./specs/IDigitalax.sol";
import "./specs/IArtBlocks.sol";

/**
 * @dev Registry to lookup royalty configurations
 */
contract RoyaltyRegistry is ERC165, OwnableUpgradeable, IRoyaltyRegistry {
    using AddressUpgradeable for address;

    // Override addresses
    mapping (address => address) private _overrides;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRegistry-getRoyaltyLookupAddress}.
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view override returns(address) {
        address override_ = _overrides[tokenAddress];
        if (override_ != address(0)) return override_;
        return tokenAddress;
    }

    /**
     * @dev See {IRegistry-setRoyaltyLookupAddress}.
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyLookupAddress) public override {
        require(tokenAddress.isContract() && (royaltyLookupAddress.isContract() || royaltyLookupAddress == address(0)), "Invalid input");
        require(overrideAllowed(tokenAddress), "Permission denied");
        _overrides[tokenAddress] = royaltyLookupAddress;
        emit RoyaltyOverride(_msgSender(), tokenAddress, royaltyLookupAddress);
    }

    /**
     * @dev See {IRegistry-overrideAllowed}.
     */
    function overrideAllowed(address tokenAddress) public view override returns(bool) {
        if (owner() == _msgSender()) return true;

        if (ERC165Checker.supportsInterface(tokenAddress, type(IAdminControl).interfaceId)
            && IAdminControl(tokenAddress).isAdmin(_msgSender())) {
            return true;
        }

        try OwnableUpgradeable(tokenAddress).owner() returns (address owner) {
            if (owner == _msgSender()) return true;
        } catch {}

        try IAccessControlUpgradeable(tokenAddress).hasRole(0x00, _msgSender()) returns (bool hasRole) {
            if (hasRole) return true;
        } catch {}

        // Nifty Gateway overrides
        try INiftyBuilderInstance(tokenAddress).niftyRegistryContract() returns (address niftyRegistry) {
            try INiftyRegistry(niftyRegistry).isValidNiftySender(_msgSender()) returns (bool valid) {
                return valid;
            } catch {}
        } catch {}

        // OpenSea overrides
        // Tokens already support Ownable

        // Foundation overrides
        try IFoundationTreasuryNode(tokenAddress).getFoundationTreasury() returns (address payable foundationTreasury) {
            try IFoundationTreasury(foundationTreasury).isAdmin(_msgSender()) returns (bool isAdmin) {
                return isAdmin;
            } catch {}
        } catch {}

        // DIGITALAX overrides
        try IDigitalax(tokenAddress).accessControls() returns (address externalAccessControls){
            try IDigitalaxAccessControls(externalAccessControls).hasAdminRole(_msgSender()) returns (bool hasRole) {
                if (hasRole) return true;
            } catch {}
        } catch {}

        // Art Blocks overrides
        try IArtBlocks(tokenAddress).admin() returns (address admin) {
            if (admin == _msgSender()) return true;
        } catch {}

        // Superrare overrides
        // Tokens and registry already support Ownable

        // Rarible overrides
        // Tokens already support Ownable

        return false;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Nifty builder instance
 */
interface INiftyBuilderInstance {
   function niftyRegistryContract() external view returns (address);
}

/**
 * @dev Nifty registry
 */
interface INiftyRegistry {
    /**
     * @dev function to see if sending key is valid
     */
    function isValidNiftySender(address sending_key) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Digitalax nfts
 */
interface IDigitalax {
   function accessControls() external view returns (address);
}

/**
 * @dev Digitalax Access Controls Simple
 */
interface IDigitalaxAccessControls {
   function hasAdminRole(address _account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Art Blocks nfts
 */
interface IArtBlocks {
   // document getter function of public variable
   function admin() external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyRegistry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MockRoyaltyRegistry is IRoyaltyRegistry, ERC165 {
  function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress)
    external
    virtual
  // solhint-disable-next-line no-empty-blocks
  {

  }

  function getRoyaltyLookupAddress(address tokenAddress) external view virtual returns (address) {
    return tokenAddress;
  }

  function overrideAllowed(
    address /* tokenAddress */
  ) external view virtual returns (bool) {
    return true;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IRoyaltyRegistry).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./MockRoyaltyRegistry.sol";

contract MockRoyaltyRegistryOutOfGas is MockRoyaltyRegistry {
  function getRoyaltyLookupAddress(address tokenAddress) external pure override returns (address) {
    // solhint-disable no-empty-blocks
    while (true) {
      // Waste gas
    }
    return tokenAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRoyaltyOverride.sol";
import "../specs/IEIP2981.sol";

/**
 * Simple EIP2981 reference override implementation
 */
abstract contract EIP2981RoyaltyOverrideCore is IEIP2981, IEIP2981RoyaltyOverride, ERC165 {
    using EnumerableSet for EnumerableSet.UintSet;

    TokenRoyalty public defaultRoyalty;
    mapping(uint256 => TokenRoyalty) private _tokenRoyalties;
    EnumerableSet.UintSet private _tokensWithRoyalties;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || interfaceId == type(IEIP2981RoyaltyOverride).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets token royalties. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setTokenRoyalties(TokenRoyaltyConfig[] memory royaltyConfigs) internal {
        for (uint i = 0; i < royaltyConfigs.length; i++) {
            TokenRoyaltyConfig memory royaltyConfig = royaltyConfigs[i];
            require(royaltyConfig.bps < 10000, "Invalid bps");
            if (royaltyConfig.recipient == address(0)) {
                delete _tokenRoyalties[royaltyConfig.tokenId];
                _tokensWithRoyalties.remove(royaltyConfig.tokenId);
                emit TokenRoyaltyRemoved(royaltyConfig.tokenId);
            } else {
                _tokenRoyalties[royaltyConfig.tokenId] = TokenRoyalty(royaltyConfig.recipient, royaltyConfig.bps);
                _tokensWithRoyalties.add(royaltyConfig.tokenId);
                emit TokenRoyaltySet(royaltyConfig.tokenId, royaltyConfig.recipient, royaltyConfig.bps);
            }
        }
    }

    /**
     * @dev Sets default royalty. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setDefaultRoyalty(TokenRoyalty memory royalty) internal {
        require(royalty.bps < 10000, "Invalid bps");
        defaultRoyalty = TokenRoyalty(royalty.recipient, royalty.bps);
        emit DefaultRoyaltySet(royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltiesCount}.
     */
    function getTokenRoyaltiesCount() external override view returns(uint256) {
        return _tokensWithRoyalties.length();
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltyByIndex}.
     */
    function getTokenRoyaltyByIndex(uint256 index) external override view returns(TokenRoyaltyConfig memory) {
        uint256 tokenId = _tokensWithRoyalties.at(index);
        TokenRoyalty memory royalty = _tokenRoyalties[tokenId];
        return TokenRoyaltyConfig(tokenId, royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) public override view returns (address, uint256) {
        if (_tokenRoyalties[tokenId].recipient != address(0)) {
            return (_tokenRoyalties[tokenId].recipient, value*_tokenRoyalties[tokenId].bps/10000);
        }
        if (defaultRoyalty.recipient != address(0) && defaultRoyalty.bps != 0) {
            return (defaultRoyalty.recipient, value*defaultRoyalty.bps/10000);
        }
        return (address(0), 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Simple EIP2981 reference override implementation
 */
interface IEIP2981RoyaltyOverride is IERC165 {

    event TokenRoyaltyRemoved(uint256 tokenId);
    event TokenRoyaltySet(uint256 tokenId, address recipient, uint16 bps);
    event DefaultRoyaltySet(address recipient, uint16 bps);

    struct TokenRoyalty {
        address recipient;
        uint16 bps;
    }

    struct TokenRoyaltyConfig {
        uint256 tokenId;
        address recipient;
        uint16 bps;
    }

    /**
     * @dev Set per token royalties.  Passing a recipient of address(0) will delete any existing configuration
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royalties) external;

    /**
     * @dev Get the number of token specific overrides.  Used to enumerate over all configurations
     */
    function getTokenRoyaltiesCount() external view returns(uint256);

    /**
     * @dev Get a token royalty configuration by index.  Use in conjunction with getTokenRoyaltiesCount to get all per token configurations
     */
    function getTokenRoyaltyByIndex(uint256 index) external view returns(TokenRoyaltyConfig memory);

    /**
     * @dev Set a default royalty configuration.  Will be used if no token specific configuration is set
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BasicERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./../interfaces/ITokenCreator.sol";

// solhint-disable-next-line no-empty-blocks
contract OwnableERC721Mock is BasicERC721, Ownable, ITokenCreator {
  address private _tokenCreator;

  function setTokenCreator(address creator) public {
    _tokenCreator = creator;
  }

  // ITokenCreator interface is included so that primary sale tests can be honored.
  function tokenCreator(
    uint256 /* tokenId */
  ) external view returns (address payable) {
    return payable(_tokenCreator);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A contract implementing just the minimum 721 requirements.
 * @dev Scaled back from OZ to remove the metadata extension and add a public mint function:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/ERC721.sol
 */
contract BasicERC721 is ERC165, IERC721 {
  using AddressUpgradeable for address;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

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
    return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256 balance) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
    owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address operator) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != msg.sender, "ERC721: approve to caller");

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
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
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

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
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @notice Allow anyone to mint any unused tokenId for easy testing.
   */
  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
   *   which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
   *   which is called upon a safe transfer.
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
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
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

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
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
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./NFT721Core.sol";
import "./NFT721Creator.sol";

/**
 * @title A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT721Metadata is NFT721Creator {
  using Strings for uint256;

  /// @notice Stores hashes minted by a creator to prevent duplicates.
  mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;

  /**
   * @notice Emitted when the base URI used by NFTs created by this contract is updated.
   * @param baseURI The new base URI to use for all NFTs created by this contract.
   */
  event BaseURIUpdated(string baseURI);

  /**
   * @notice Returns the IPFS path to the metadata JSON file for a given NFT.
   * @param tokenId The NFT to get the CID path for.
   * @return path The IPFS path to the metadata JSON file, without the base URI prefix.
   */
  function getTokenIPFSPath(uint256 tokenId) external view returns (string memory path) {
    path = _tokenURIs[tokenId];
  }

  /**
   * @notice Checks if the creator has already minted a given NFT.
   * @param creator The creator which may have minted this NFT already.
   * @param tokenIPFSPath The IPFS path to the metadata JSON file, without the base URI prefix.
   * @return hasMinted True if the creator has already minted this NFT.
   */
  function getHasCreatorMintedIPFSHash(address creator, string calldata tokenIPFSPath)
    external
    view
    returns (bool hasMinted)
  {
    hasMinted = creatorToIPFSHashToMinted[creator][tokenIPFSPath];
  }

  /**
   * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete creatorToIPFSHashToMinted[msg.sender][_tokenURIs[tokenId]];
    super._burn(tokenId);
  }

  /**
   * @dev The IPFS path should be the CID + file.extension, e.g.
   * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
   */
  function _setTokenIPFSPath(uint256 tokenId, string calldata _tokenIPFSPath) internal {
    // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
    require(bytes(_tokenIPFSPath).length >= 46, "NFT721Metadata: Invalid IPFS path");
    require(!creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath], "NFT721Metadata: NFT was already minted");

    creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
    _setTokenURI(tokenId, _tokenIPFSPath);
  }

  function _updateBaseURI(string calldata _baseURI) internal {
    _setBaseURI(_baseURI);

    emit BaseURIUpdated(_baseURI);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 1 slot was used with the addition of `creatorToIPFSHashToMinted`.
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title A place for common modifiers and functions used by various NFT721 mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFT721Core {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 100 slots used when adding `NFT721ProxyCall`.
   */
  uint256[900] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./OZ/ERC721Upgradeable.sol";
import "../libraries/BytesLibrary.sol";
import "./NFT721ProxyCall.sol";
import "../interfaces/ITokenCreator.sol";
import "../libraries/AccountMigrationLibrary.sol";
import "./FoundationTreasuryNode.sol";

/**
 * @title Allows each token to be associated with a creator.
 * @notice Also manages the payment address for each NFT, allowing royalties to be split with collaborators.
 */
abstract contract NFT721Creator is FoundationTreasuryNode, OZERC721Upgradeable, ITokenCreator, NFT721ProxyCall {
  using AccountMigrationLibrary for address;
  using BytesLibrary for bytes;

  /**
   * @notice Stores the creator address for each NFT.
   */
  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @notice Stores an optional alternate address to receive creator revenue and royalty payments.
   * The target address may be a contract which could split or escrow payments.
   * @dev This is address(0) when not applicable and royalties should be sent to the creator instead.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  /**
   * @notice Emitted when the creator for an NFT is set.
   * @param fromCreator The original creator address for this NFT.
   * @param toCreator The new creator address for this NFT.
   * @param tokenId The token ID for the NFT which was updated.
   */
  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
  /**
   * @notice Emitted when the creator payment address for an NFT is set.
   * @param fromPaymentAddress The original creator payment address for this NFT.
   * @param toPaymentAddress The new creator payment address for this NFT.
   * @param tokenId The token ID for the NFT which was updated.
   */
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );
  /**
   * @notice Emitted when the creator for an NFT is changed through account migration.
   * @param tokenId The tokenId of the NFT which had the creator changed.
   * @param originalAddress The original creator address for this NFT.
   * @param newAddress The new creator address for this NFT.
   */
  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  /**
   * @notice Emitted when the owner of an NFT is changed through account migration.
   * @param tokenId The tokenId of the NFT which had the owner changed.
   * @param originalAddress The original owner address for this NFT.
   * @param newAddress The new owner address for this NFT.
   */
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  /**
   * @notice Emitted when the payment address for an NFT is changed through account migration.
   * @param tokenId The tokenId of the NFT which had the payment address changed.
   * @param originalAddress The original recipient address for royalties that is being migrated.
   * @param newAddress The new recipient address for royalties.
   * @param originalPaymentAddress The original payment address for royalty payments.
   * @param newPaymentAddress The new payment address used to split royalty payments.
   */
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  /**
   * @notice Allows an NFT owner or creator and Foundation to work together in order to update the creator
   * to a new account and/or transfer NFTs to that account.
   * @dev This will gracefully skip any NFTs that have been burned or transferred.
   * @param createdTokenIds The tokenIds of the NFTs which were created by the original address.
   * @param ownedTokenIds The tokenIds of the NFTs owned by the original address to be migrated to the new account.
   * @param originalAddress The original account address to be migrated.
   * @param newAddress The new address for the account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigration(
    uint256[] calldata createdTokenIds,
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external onlyFoundationOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    unchecked {
      // The array length cannot overflow 256 bits.
      for (uint256 i = 0; i < ownedTokenIds.length; ++i) {
        uint256 tokenId = ownedTokenIds[i];
        // Check that the token exists and still owned by the originalAddress
        // so that frontrunning a burn or transfer will not cause the entire tx to revert
        if (_exists(tokenId) && ownerOf(tokenId) == originalAddress) {
          _transfer(originalAddress, newAddress, tokenId);
          emit NFTOwnerMigrated(tokenId, originalAddress, newAddress);
        }
      }

      for (uint256 i = 0; i < createdTokenIds.length; ++i) {
        uint256 tokenId = createdTokenIds[i];
        // The creator would be 0 if the token was burned before this call
        if (tokenIdToCreator[tokenId] != address(0)) {
          require(
            tokenIdToCreator[tokenId] == originalAddress,
            "NFT721Creator: Token was not created by the given address"
          );
          _updateTokenCreator(tokenId, newAddress);
          emit NFTCreatorMigrated(tokenId, originalAddress, newAddress);
        }
      }
    }
  }

  /**
   * @notice Allows a split recipient and Foundation to work together in order to update the payment address
   * to a new account.
   * @param paymentAddressTokenIds The token IDs for the NFTs to have their payment address migrated.
   * @param paymentAddressFactory The contract which was used to generate the payment address being migrated.
   * @param paymentAddressCallData The original call data used to generate the payment address being migrated.
   * @param addressLocationInCallData The position where the account to migrate begins in the call data.
   * @param originalAddress The original account address to be migrated.
   * @param newAddress The new address for the account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external onlyFoundationOperator {
    originalAddress.requireAuthorizedAccountMigration(newAddress, signature);
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   * @param tokenId The tokenId of the NFT to be burned.
   */
  function burn(uint256 tokenId) external {
    require(tokenIdToCreator[tokenId] == msg.sender, "NFT721Creator: Caller is not creator");
    require(_isApprovedOrOwner(msg.sender, tokenId), "NFT721Creator: Caller is not owner nor approved");
    _burn(tokenId);
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // For each token, confirm the expected payment address and then update to the new one
    unchecked {
      // The array length cannot overflow 256 bits.
      for (uint256 i = 0; i < paymentAddressTokenIds.length; ++i) {
        uint256 tokenId = paymentAddressTokenIds[i];
        require(
          tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
          "NFT721Creator: Payment address is not the expected value"
        );

        _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
        emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
      }
    }
  }

  /**
   * @dev Remove the creator and payment address records when burned.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete tokenIdToCreator[tokenId];
    delete tokenIdToCreatorPaymentAddress[tokenId];

    // Delete the NFT details.
    super._burn(tokenId);
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   * @param tokenId The tokenId of the NFT to get the payment address for.
   * @return tokenCreatorPaymentAddress The address to which royalties should be sent for this NFT.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  /**
   * @inheritdoc ERC165
   * @dev Checks the ITokenCreator interface.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (interfaceId == type(ITokenCreator).interfaceId) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   * @param tokenId The tokenId of the NFT to get the creator for.
   * @return creator The creator's address for the given tokenId.
   */
  function tokenCreator(uint256 tokenId) external view override returns (address payable creator) {
    creator = tokenIdToCreator[tokenId];
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev 1 slot was using with the addition of `tokenIdToCreatorPaymentAddress`.
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/token/ERC721/ERC721Upgradeable.sol
 * Modified in order to:
 *  - make `_tokenURIs` internal instead of private.
 *  - replace ERC165Upgradeable with ERC165.
 *  - set the name/symbol with constants.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../ERC165UpgradeableGap.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract OZERC721Upgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165UpgradeableGap,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using AddressUpgradeable for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using OZEnumerableMap for OZEnumerableMap.UintToAddressMap;
  using Strings for uint256;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping(address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  OZEnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Removing old unused variables in an upgrade safe way. Was:
   * string private __gap_was_name;
   * string private __gap_was_symbol;
   */
  uint256[2] private __gap_was_metadata;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal _tokenURIs;

  // Base URI
  string private _baseURI;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function __ERC721_init() internal onlyInitializing {
    __Context_init_unchained();
  }

  /**
   * @inheritdoc ERC165
   * @dev Checks the ERC721 interfaces.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    if (
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId
    ) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");

    return _holderTokens[owner].length();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public pure virtual override returns (string memory) {
    return "Foundation";
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public pure virtual override returns (string memory) {
    return "FND";
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];

    // If there is no base URI, return the token URI.
    if (bytes(_baseURI).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length != 0) {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }
    // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(_baseURI, tokenId.toString()));
  }

  /**
   * @dev Returns the base URI set via {_setBaseURI}. This will be
   * automatically added as a prefix in {tokenURI} to each token's URI, or
   * to the token ID if no specific URI is set for that token ID.
   */
  function baseURI() public view returns (string memory) {
    return _baseURI;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    return _holderTokens[owner].at(index);
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
    return _tokenOwners.length();
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    (uint256 tokenId, ) = _tokenOwners.at(index);
    return tokenId;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _tokenOwners.contains(tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
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

    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(address(0), to, tokenId);
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
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }

    _holderTokens[owner].remove(tokenId);

    _tokenOwners.remove(tokenId);

    emit Transfer(owner, address(0), tokenId);
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
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _holderTokens[from].remove(tokenId);
    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _baseURI = baseURI_;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (!to.isContract()) {
      return true;
    }
    bytes memory returndata = to.functionCall(
      abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector, _msgSender(), from, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
    bytes4 retval = abi.decode(returndata, (bytes4));
    return (retval == type(IERC721Receiver).interfaceId);
  }

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
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
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/IProxyCall.sol";

/**
 * @title Forwards arbitrary calls to an external contract to be processed.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 */
abstract contract NFT721ProxyCall {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;

  /// @notice The address for a contract which forwards arbitrary proxy calls.
  /// @dev This is used to improve security, so that the msg.sender is not the NFT's address.
  IProxyCall private proxyCall;

  /**
   * @notice Emitted when the proxy call contract is updated.
   * @param proxyCallContract The new proxy call contract address.
   */
  event ProxyCallContractUpdated(address indexed proxyCallContract);

  /**
   * @dev Used by other mixins to make external calls through the proxy contract.
   * This will fail if the proxyCall address is address(0).
   */
  function _proxyCallAndReturnContractAddress(address externalContract, bytes memory callData)
    internal
    returns (address payable result)
  {
    result = proxyCall.proxyCallAndReturnAddress(externalContract, callData);
    require(result.isContract(), "NFT721ProxyCall: address returned is not a contract");
  }

  /**
   * @dev Called by the adminUpdateConfig function to set the address of the proxy call contract.
   */
  function _updateProxyCall(address proxyCallContract) internal {
    require(proxyCallContract.isContract(), "NFT721ProxyCall: Proxy call address is not a contract");
    proxyCall = IProxyCall(proxyCallContract);

    emit ProxyCallContractUpdated(proxyCallContract);
  }

  /**
   * @notice Returns the address of the current proxy call contract.
   * @return contractAddress The address of the current proxy call contract.
   */
  function proxyCallAddress() external view returns (address contractAddress) {
    contractAddress = address(proxyCall);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[99] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 * From https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.2-solc-0.7
 * Modified to support solc 8.
 * Using this due to storage slot changes in OZ 4.*
 */

pragma solidity ^0.8.0;

/**
 * @title Library for an enumerable mapping type.
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library OZEnumerableMap {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct MapEntry {
    bytes32 _key;
    bytes32 _value;
  }

  struct Map {
    // Storage of map keys and values
    MapEntry[] _entries;
    // Position of the entry defined by a key in the `entries` array, plus 1
    // because index 0 means a key is not in the map.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function _set(
    Map storage map,
    bytes32 key,
    bytes32 value
  ) private returns (bool) {
    // We read and store the key's index to prevent multiple reads from the same storage slot
    uint256 keyIndex = map._indexes[key];

    if (keyIndex == 0) {
      // Equivalent to !contains(map, key)
      map._entries.push(MapEntry({ _key: key, _value: value }));
      // The entry is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      map._indexes[key] = map._entries.length;
      return true;
    } else {
      unchecked {
        map._entries[keyIndex - 1]._value = value;
      }
      return false;
    }
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function _remove(Map storage map, bytes32 key) private returns (bool) {
    // We read and store the key's index to prevent multiple reads from the same storage slot
    uint256 keyIndex = map._indexes[key];

    if (keyIndex != 0) {
      unchecked {
        // Equivalent to contains(map, key)
        // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
        // in the array, and then remove the last entry (sometimes called as 'swap and pop').
        // This modifies the order of the array, as noted in {at}.

        uint256 toDeleteIndex = keyIndex - 1;
        uint256 lastIndex = map._entries.length - 1;

        // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
        // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

        MapEntry storage lastEntry = map._entries[lastIndex];

        // Move the last entry to the index where the entry to delete is
        map._entries[toDeleteIndex] = lastEntry;
        // Update the index for the moved entry
        map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based
      }

      // Delete the slot where the moved entry was stored
      map._entries.pop();

      // Delete the index for the deleted slot
      delete map._indexes[key];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function _contains(Map storage map, bytes32 key) private view returns (bool) {
    return map._indexes[key] != 0;
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
   */
  function _length(Map storage map) private view returns (uint256) {
    return map._entries.length;
  }

  /**
   * @dev Returns the key-value pair stored at position `index` in the map. O(1).
   *
   * Note that there are no guarantees on the ordering of entries inside the
   * array, and it may change when more entries are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
    require(map._entries.length > index, "EnumerableMap: index out of bounds");

    MapEntry storage entry = map._entries[index];
    return (entry._key, entry._value);
  }

  /**
   * @dev Tries to returns the value associated with `key`.  O(1).
   * Does not revert if `key` is not in the map.
   */
  function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
    uint256 keyIndex = map._indexes[key];
    if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
    return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
  }

  /**
   * @dev Returns the value associated with `key`.  O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function _get(Map storage map, bytes32 key) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
    unchecked {
      return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
  }

  /**
   * @dev Same as {_get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {_tryGet}.
   */
  function _get(
    Map storage map,
    bytes32 key,
    string memory errorMessage
  ) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
    unchecked {
      return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
  }

  // UintToAddressMap

  struct UintToAddressMap {
    Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
    return _remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
    return _contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(UintToAddressMap storage map) internal view returns (uint256) {
    return _length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
    (bytes32 key, bytes32 value) = _at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  /**
   * @dev Tries to returns the value associated with `key`.  O(1).
   * Does not revert if `key` is not in the map.
   *
   * _Available since v3.4._
   */
  function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
    (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  /**
   * @dev Returns the value associated with `key`.  O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
    return address(uint160(uint256(_get(map._inner, bytes32(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title A gap to represent the space previously consumed by the use of ERC165Upgradeable.
 */
abstract contract ERC165UpgradeableGap {
  /// @notice The size of the ERC165Upgradeable contract which is no longer used.
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./OZ/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./NFT721Creator.sol";
import "./NFT721Market.sol";
import "./NFT721Metadata.sol";
import "./NFT721ProxyCall.sol";

/**
 * @title Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is
  Initializable,
  OZERC721Upgradeable,
  NFT721ProxyCall,
  NFT721Creator,
  NFT721Market,
  NFT721Metadata
{
  /// @notice A sequence ID to use for the next minted NFT.
  uint256 private nextTokenId;

  /**
   * @notice Emitted when a new NFT is minted.
   * @param creator The address of the creator & owner at this time this NFT was minted.
   * @param tokenId The tokenId of the newly minted NFT.
   * @param indexedTokenIPFSPath The CID of the newly minted NFT, indexed to enable watching
   * for mint events by the tokenCID.
   * @param tokenIPFSPath The actual CID of the newly minted NFT.
   */
  event Minted(
    address indexed creator,
    uint256 indexed tokenId,
    string indexed indexedTokenIPFSPath,
    string tokenIPFSPath
  );

  /**
   * @dev Called once after the initial deployment to set the initial tokenId.
   */
  function _initializeNFT721Mint() internal onlyInitializing {
    // Use ID 1 for the first NFT tokenId
    nextTokenId = 1;
  }

  /**
   * @notice Allows a creator to mint an NFT.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mint(string calldata tokenIPFSPath) public returns (uint256 tokenId) {
    unchecked {
      // Number of tokens cannot overflow 256 bits.
      tokenId = nextTokenId++;
    }
    _mint(msg.sender, tokenId);
    _updateTokenCreator(tokenId, payable(msg.sender));
    _setTokenIPFSPath(tokenId, tokenIPFSPath);
    emit Minted(msg.sender, tokenId, tokenIPFSPath, tokenIPFSPath);
  }

  /**
   * @notice Allows a creator to mint an NFT and set approval for the Foundation marketplace.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintAndApproveMarket(string calldata tokenIPFSPath) external returns (uint256 tokenId) {
    tokenId = mint(tokenIPFSPath);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddress(string calldata tokenIPFSPath, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "NFT721Mint: tokenCreatorPaymentAddress is required");
    tokenId = mint(tokenIPFSPath);
    _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * Also sets approval for the Foundation marketplace.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @param tokenCreatorPaymentAddress The royalty recipient address to use for this NFT.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentAddressAndApproveMarket(
    string calldata tokenIPFSPath,
    address payable tokenCreatorPaymentAddress
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, tokenCreatorPaymentAddress);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactory(
    string calldata tokenIPFSPath,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData
  ) public returns (uint256 tokenId) {
    address payable tokenCreatorPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );
    tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * Also sets approval for the Foundation marketplace.
   * @dev This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   * @param tokenIPFSPath The IPFS path for the NFT to mint, without the leading base URI.
   * @param paymentAddressFactory The contract to call which will return the address to use for payments.
   * @param paymentAddressCallData The call details to sent to the factory provided.
   * @return tokenId The tokenId of the newly minted NFT.
   */
  function mintWithCreatorPaymentFactoryAndApproveMarket(
    string calldata tokenIPFSPath,
    address paymentAddressFactory,
    bytes calldata paymentAddressCallData
  ) external returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentFactory(tokenIPFSPath, paymentAddressFactory, paymentAddressCallData);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burn(uint256 tokenId) internal virtual override(OZERC721Upgradeable, NFT721Creator, NFT721Metadata) {
    super._burn(tokenId);
  }

  /**
   * @notice Gets the tokenId of the next NFT minted.
   * @return tokenId The ID that the next NFT minted will use.
   */
  function getNextTokenId() external view returns (uint256 tokenId) {
    tokenId = nextTokenId;
  }

  /**
   * @inheritdoc ERC165
   * @dev This is required to avoid compile errors.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(OZERC721Upgradeable, NFT721Creator, NFT721Market)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IGetFees.sol";
import "../interfaces/IRoyaltyInfo.sol";

import "./FoundationTreasuryNode.sol";
import "./NFT721Creator.sol";
import "./Constants.sol";

/**
 * @title Holds a reference to the Foundation Market and communicates fees to marketplaces.
 */
abstract contract NFT721Market is
  IGetRoyalties,
  IGetFees,
  IRoyaltyInfo,
  Constants,
  FoundationTreasuryNode,
  NFT721Creator
{
  using AddressUpgradeable for address;

  /// @dev 10% of sales should go to the creator of the NFT.
  uint256 private constant ROYALTY_IN_BASIS_POINTS = 1000;
  /// @dev 10%, expressed as a denominator for more efficient calculations.
  uint256 private constant ROYALTY_RATIO = BASIS_POINTS / ROYALTY_IN_BASIS_POINTS;
  /// @notice The Foundation market contract address.
  address private nftMarket;

  /**
   * @notice Emitted when the market contract address used for approvals is updated.
   * @param nftMarket The new market contract address.
   */
  event NFTMarketUpdated(address indexed nftMarket);

  function _updateNFTMarket(address _nftMarket) internal {
    require(_nftMarket.isContract(), "NFT721Market: Market address is not a contract");
    nftMarket = _nftMarket;

    emit NFTMarketUpdated(_nftMarket);
  }

  /**
   * @notice Returns an array of fees in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   * @dev The tokenId param is ignored since all NFTs return the same value.
   * @return feesInBasisPoints The array of fees to be sent to each recipient, in basis points.
   */
  function getFeeBps(
    uint256 /* id */
  ) external pure override returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = ROYALTY_IN_BASIS_POINTS;
    return result;
  }

  /**
   * @notice Returns an array of recipient addresses to which fees should be sent.
   * The expected fee amount is communicated with `getFeeBps`.
   * @param tokenId The tokenId of the NFT to get the royalty recipients for.
   * @return recipients An array of addresses to which royalties should be sent.
   */
  function getFeeRecipients(uint256 tokenId) external view override returns (address payable[] memory) {
    require(_exists(tokenId), "ERC721Metadata: Query for nonexistent token");

    address payable[] memory result = new address payable[](1);
    result[0] = getTokenCreatorPaymentAddress(tokenId);
    return result;
  }

  /**
   * @notice Get fee recipients and fees in a single call.
   * @dev The data is the same as when calling getFeeRecipients and getFeeBps separately.
   * @param tokenId The tokenId of the NFT to get the royalties for.
   * @return recipients An array of addresses to which royalties should be sent.
   * @return feesInBasisPoints The array of fees to be sent to each recipient address.
   */
  function getRoyalties(uint256 tokenId)
    external
    view
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints)
  {
    require(_exists(tokenId), "ERC721Metadata: Query for nonexistent token");
    recipients = new address payable[](1);
    recipients[0] = getTokenCreatorPaymentAddress(tokenId);
    feesInBasisPoints = new uint256[](1);
    feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
  }

  /**
   * @notice Returns the address of the Foundation market contract.
   * @return market The Foundation market contract address.
   */
  function getNFTMarket() public view returns (address market) {
    market = address(nftMarket);
  }

  /**
   * @notice Returns the receiver and the amount to be sent for a secondary sale.
   * @param tokenId The tokenId of the NFT to get the royalty recipient and amount for.
   * @param salePrice The total price of the sale.
   * @return receiver The royalty recipient address for this sale.
   * @return royaltyAmount The total amount that should be sent to the `receiver`.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = getTokenCreatorPaymentAddress(tokenId);
    unchecked {
      royaltyAmount = salePrice / ROYALTY_RATIO;
    }
  }

  /**
   * @inheritdoc ERC165
   * @dev Checks the supported royalty interfaces.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (
      interfaceId == type(IRoyaltyInfo).interfaceId ||
      interfaceId == type(IGetRoyalties).interfaceId ||
      interfaceId == type(IGetFees).interfaceId
    ) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/ICollectionContractInitializer.sol";
import "./interfaces/ICollectionFactory.sol";
import "./interfaces/IProxyCall.sol";
import "./interfaces/IRoles.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create an NFT collection contract managed by a single creator.
 * @dev This creates and initializes an ERC-1165 minimal proxy pointing to the NFT collection contract template.
 */
contract FNDCollectionFactory is ICollectionFactory {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Clones for address;
  using Strings for uint256;

  /**
   * @notice The contract address which manages common roles.
   * @dev Used by the collections for a shared operator definition.
   */
  IRoles public rolesContract;

  /**
   * @notice The address of the template all new collections will leverage.
   */
  address public implementation;

  /**
   * @notice The address of the proxy call contract implementation.
   * @dev Used by the collections to safely call another contract with arbitrary call data.
   */
  IProxyCall public proxyCallContract;

  /**
   * @notice The implementation version new collections will use.
   * @dev This is auto-incremented each time the implementation is changed.
   */
  uint256 public version;

  /**
   * @notice Emitted when a new collection is created from this factory.
   * @param collectionContract The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event CollectionCreated(
    address indexed collectionContract,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );
  /**
   * @notice Emitted when the implementation contract used by new collections is updated.
   * @param implementation The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event ImplementationUpdated(address indexed implementation, uint256 indexed version);
  /**
   * @notice Emitted when the proxy call contract used by collections is updated.
   * @param proxyCallContract The new proxy call contract address.
   */
  event ProxyCallContractUpdated(address indexed proxyCallContract);
  /**
   * @notice Emitted when the contract defining roles is updated.
   * @param rolesContract The new roles contract address.
   */
  event RolesContractUpdated(address indexed rolesContract);

  modifier onlyAdmin() {
    require(rolesContract.isAdmin(msg.sender), "FNDCollectionFactory: Caller does not have the Admin role");
    _;
  }

  /**
   * @notice Defines requirements for the collection factory at deployment time.
   * @param _proxyCallContract The address of the proxy call contract implementation.
   * @param _rolesContract The address of the contract defining roles for collections to use.
   */
  constructor(address _proxyCallContract, address _rolesContract) {
    _updateRolesContract(_rolesContract);
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Allows Foundation to change the collection implementation used for future collections.
   * This call will auto-increment the version.
   * Existing collections are not impacted.
   * @param _implementation The new collection implementation address.
   */
  function adminUpdateImplementation(address _implementation) external onlyAdmin {
    _updateImplementation(_implementation);
  }

  /**
   * @notice Allows Foundation to change the proxy call contract address.
   * @param _proxyCallContract The new proxy call contract address.
   */
  function adminUpdateProxyCallContract(address _proxyCallContract) external onlyAdmin {
    _updateProxyCallContract(_proxyCallContract);
  }

  /**
   * @notice Allows Foundation to change the admin role contract address.
   * @param _rolesContract The new admin role contract address.
   */
  function adminUpdateRolesContract(address _rolesContract) external onlyAdmin {
    _updateRolesContract(_rolesContract);
  }

  /**
   * @notice Create a new collection contract.
   * @dev The nonce is required and must be unique for the msg.sender + implementation version,
   * otherwise this call will revert.
   * @param name The name for the new collection being created.
   * @param symbol The symbol for the new collection being created.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return collectionAddress The address of the new collection contract.
   */
  function createCollection(
    string calldata name,
    string calldata symbol,
    uint256 nonce
  ) external returns (address collectionAddress) {
    require(bytes(symbol).length != 0, "FNDCollectionFactory: Symbol is required");

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collectionAddress = implementation.cloneDeterministic(_getSalt(msg.sender, nonce));

    ICollectionContractInitializer(collectionAddress).initialize(payable(msg.sender), name, symbol);

    emit CollectionCreated(collectionAddress, msg.sender, version, name, symbol, nonce);
  }

  function _updateRolesContract(address _rolesContract) private {
    require(_rolesContract.isContract(), "FNDCollectionFactory: RolesContract is not a contract");
    rolesContract = IRoles(_rolesContract);

    emit RolesContractUpdated(_rolesContract);
  }

  /**
   * @dev Updates the implementation address, increments the version, and initializes the template.
   * Since the template is initialized when set, implementations cannot be re-used.
   * To downgrade the implementation, deploy the same bytecode again and then update to that.
   */
  function _updateImplementation(address _implementation) private {
    require(_implementation.isContract(), "FNDCollectionFactory: Implementation is not a contract");
    implementation = _implementation;
    unchecked {
      // Version cannot overflow 256 bits.
      version++;
    }

    // The implementation is initialized when assigned so that others may not claim it as their own.
    ICollectionContractInitializer(_implementation).initialize(
      payable(address(rolesContract)),
      string(abi.encodePacked("Foundation Collection Template v", version.toString())),
      string(abi.encodePacked("FCTv", version.toString()))
    );

    emit ImplementationUpdated(_implementation, version);
  }

  function _updateProxyCallContract(address _proxyCallContract) private {
    require(_proxyCallContract.isContract(), "FNDCollectionFactory: Proxy call address is not a contract");
    proxyCallContract = IProxyCall(_proxyCallContract);

    emit ProxyCallContractUpdated(_proxyCallContract);
  }

  /**
   * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
   * This will return the same address whether the collection has already been created or not.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections.
   * @return collectionAddress The address of the collection contract that would be created by this nonce.
   */
  function predictCollectionAddress(address creator, uint256 nonce) external view returns (address collectionAddress) {
    collectionAddress = implementation.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  function _getSalt(address creator, uint256 nonce) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(creator, nonce));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RoyaltyOverrideCloneable.sol";

/**
 * Clone Factory for EIP2981 reference override implementation
 */
contract EIP2981RoyaltyOverrideFactory {

  address public originAddress;

  event EIP2981RoyaltyOverrideCreated(address newEIP2981RoyaltyOverride);

  constructor(address origin) {
      originAddress = origin;
  }

  function createOverride() public returns (address) {
      address clone = Clones.clone(originAddress);
      EIP2981RoyaltyOverrideCloneable(clone).initialize();
      EIP2981RoyaltyOverrideCloneable(clone).transferOwnership(msg.sender);
      emit EIP2981RoyaltyOverrideCreated(clone);
      return clone;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./RoyaltyOverrideCore.sol";

/**
 * Simple EIP2981 reference override implementation
 */
contract EIP2981RoyaltyOverrideCloneable is EIP2981RoyaltyOverrideCore, OwnableUpgradeable {

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../OZ/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Defines a role for Foundation operator accounts.
 * @dev Wraps a role from OpenZeppelin's AccessControl for easy integration.
 */
abstract contract OperatorRole is Initializable, OZAccessControlUpgradeable {
  bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /**
   * @notice Adds the account to the list of approved operators.
   * @dev Only callable by admins as enforced by `grantRole`.
   * @param account The address to be approved.
   */
  function grantOperator(address account) external {
    grantRole(OPERATOR_ROLE, account);
  }

  /**
   * @notice Removes the account from the list of approved operators.
   * @dev Only callable by admins as enforced by `revokeRole`.
   * @param account The address to be removed from the approved list.
   */
  function revokeOperator(address account) external {
    revokeRole(OPERATOR_ROLE, account);
  }

  /**
   * @notice Returns one of the operator by index.
   * @param index The index of the operator to return from 0 to getOperatorMemberCount() - 1.
   * @return account The address of the operator.
   */
  function getOperatorMember(uint256 index) external view returns (address account) {
    account = getRoleMember(OPERATOR_ROLE, index);
  }

  /**
   * @notice Checks how many accounts have been granted operator access.
   * @return count The number of accounts with operator access.
   */
  function getOperatorMemberCount() external view returns (uint256 count) {
    count = getRoleMemberCount(OPERATOR_ROLE);
  }

  /**
   * @notice Checks if the account provided is an operator.
   * @param account The address to check.
   * @return approved True if the account is an operator.
   */
  function isOperator(address account) external view returns (bool approved) {
    approved = hasRole(OPERATOR_ROLE, account);
  }
}

// SPDX-License-Identifier: MIT

/**
 * Copied from https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v3.4.2-solc-0.7
 * Modified to support solc-8.
 * Using this instead of the new OZ implementation due to a change in storage slots used.
 * Also limited access of several functions as we will be using convenience wrappers.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// solhint-disable

/**
 * @title Implements role-based access control mechanisms.
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract OZAccessControlUpgradeable is Initializable, ContextUpgradeable {
  function __AccessControl_init() internal onlyInitializing {
    __Context_init_unchained();
    __AccessControl_init_unchained();
  }

  function __AccessControl_init_unchained() internal onlyInitializing {}

  using EnumerableSet for EnumerableSet.AddressSet;
  using AddressUpgradeable for address;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

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
   * bearer except when using {_setupRole}.
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
  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return _roles[role].members.contains(account);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) internal view returns (uint256) {
    return _roles[role].members.length();
  }

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) internal view returns (address) {
    return _roles[role].members.at(index);
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
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
   */
  function grantRole(bytes32 role, address account) internal virtual {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
   */
  function revokeRole(bytes32 role, address account) internal virtual {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

    _revokeRole(role, account);
  }

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
  function renounceRole(bytes32 role, address account) internal virtual {
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
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   */
  function _setupRole(bytes32 role, address account) internal {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) private {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../../interfaces/IRoyaltyInfo.sol";
import "../../mixins/Constants.sol";

contract MockRoyaltyERC2981Override is IRoyaltyInfo, Constants, ERC165 {
  address private _receiver;
  uint256 private _royaltyBasisPoints;

  constructor(address receiver, uint256 royaltyBasisPoints) {
    _receiver = receiver;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  function royaltyInfo(
    uint256, /* _tokenId */
    uint256 _salePrice
  ) external view virtual returns (address receiver, uint256 royaltyAmount) {
    return (_receiver, (_salePrice * _royaltyBasisPoints) / BASIS_POINTS);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IRoyaltyInfo).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./MockRoyaltyERC2981Override.sol";

contract MockRoyaltyERC2981OverrideOutOfGas is MockRoyaltyERC2981Override {
  constructor()
    MockRoyaltyERC2981Override(address(0), 0) // solhint-disable-next-line no-empty-blocks
  {}

  function royaltyInfo(
    uint256, /* _tokenId */
    uint256 _salePrice
  ) external pure override returns (address receiver, uint256 royaltyAmount) {
    // solhint-disable no-empty-blocks
    while (true) {
      // Waste gas
    }
    return (0x1337Ac082b17a7FE8059251c9caD2dc1733CC940, _salePrice);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BasicERC721.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IGetFees.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IRoyaltyInfo.sol";

/**
 * @dev This mock contains APIs for testing with no return values.
 * Those can be inserted using Waffle mocks in the tests themselves.
 */
contract MockERC721Fees is BasicERC721, IGetFees, ITokenCreator, IOwnable, IGetRoyalties, IRoyaltyInfo {
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  // solhint-disable-next-line no-empty-blocks
  function tokenCreator(uint256 tokenId) external view override returns (address payable) {}

  // solhint-disable-next-line no-empty-blocks
  function getFeeRecipients(uint256 id) external view override returns (address payable[] memory) {}

  // solhint-disable-next-line no-empty-blocks
  function getFeeBps(uint256 id) external view override returns (uint256[] memory) {}

  // solhint-disable-next-line no-empty-blocks
  function owner() external view override returns (address) {}

  function getRoyalties(uint256 tokenId)
    external
    view
    override
    returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints)
  // solhint-disable-next-line no-empty-blocks
  {

  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../../interfaces/IGetRoyalties.sol";

contract MockRoyaltyGetRoyaltiesOverride is IGetRoyalties, ERC165 {
  address payable[] private _receivers;
  uint256[] private _royaltyBasisPoints;

  constructor(address payable[] memory receivers, uint256[] memory royaltyBasisPoints) {
    _receivers = receivers;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  function getRoyalties(
    uint256 /* tokenId */
  ) external view returns (address payable[] memory recipients, uint256[] memory feesInBasisPoints) {
    recipients = new address payable[](_receivers.length);
    feesInBasisPoints = new uint256[](_royaltyBasisPoints.length);
    for (uint256 i = 0; i < _receivers.length; i++) {
      recipients[i] = _receivers[i];
    }
    for (uint256 i = 0; i < _royaltyBasisPoints.length; i++) {
      feesInBasisPoints[i] = _royaltyBasisPoints[i];
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IGetRoyalties).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BasicERC721.sol";

contract BasicERC721WithAccessControlMock is BasicERC721, AccessControl {
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view override(BasicERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IFethMarket.sol";

contract FETHMarketMock {
  IFethMarket public feth;

  receive() external payable {
    require(msg.sender == address(feth), "Only receive from FETH");
  }

  function setFeth(address _feth) public {
    feth = IFethMarket(_feth);
  }

  function marketLockupFor(address account, uint256 amount) public payable {
    feth.marketLockupFor{ value: msg.value }(account, amount);
  }

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) public {
    feth.marketWithdrawLocked(account, expiration, amount);
  }

  function marketWithdrawFrom(address account, uint256 amount) public {
    feth.marketWithdrawFrom(account, amount);
  }

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) public {
    feth.marketUnlockFor(account, expiration, amount);
  }

  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable {
    feth.marketChangeLockup{ value: msg.value }(unlockFrom, unlockExpiration, unlockAmount, depositFor, depositAmount);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract Mock1271 is IERC1271, Ownable {
  bytes4 internal constant MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  function isValidSignature(bytes32 hash, bytes memory signature) external view override returns (bytes4 magicValue) {
    if (ECDSA.recover(hash, signature) == owner()) {
      return MAGIC_VALUE;
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../libraries/BytesLibrary.sol";

contract BytesMock {
  using BytesLibrary for bytes;

  function replaceAtIf(
    bytes memory data,
    uint256 startLocation,
    address expectedAddress,
    address newAddress
  ) public pure returns (bytes memory) {
    data.replaceAtIf(startLocation, expectedAddress, newAddress);
    return data;
  }

  function startsWith(bytes memory data, bytes4 functionSig) public pure returns (bool) {
    return data.startsWith(functionSig);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title The ERC-20 token for Foundation.
 * @dev Includes ERC20 (from OpenZeppelin incl increase/decreaseAllowance), burn, and EIP-2612 (permit).
 */
contract FND is ERC20Burnable, ERC20Permit {
  string private constant _name = "Foundation";
  string private constant _symbol = "FND";

  constructor(address initialAccount, uint256 initialBalance) ERC20(_name, _symbol) ERC20Permit(_name) {
    _mint(initialAccount, initialBalance);
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./mixins/OZ/ERC721Upgradeable.sol";

import "./mixins/FoundationTreasuryNode.sol";
import "./mixins/NFT721Core.sol";
import "./mixins/NFT721Market.sol";
import "./mixins/NFT721Creator.sol";
import "./mixins/NFT721Metadata.sol";
import "./mixins/NFT721Mint.sol";
import "./mixins/NFT721ProxyCall.sol";
import "./mixins/ERC165UpgradeableGap.sol";

/**
 * @title Foundation NFTs implemented using the ERC-721 standard.
 */
contract FNDNFT721 is
  Initializable,
  FoundationTreasuryNode,
  ERC165UpgradeableGap,
  ERC165,
  OZERC721Upgradeable,
  NFT721Core,
  NFT721ProxyCall,
  NFT721Creator,
  NFT721Market,
  NFT721Metadata,
  NFT721Mint
{
  constructor(address payable treasury)
    FoundationTreasuryNode(treasury) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize() external initializer {
    OZERC721Upgradeable.__ERC721_init();
    NFT721Mint._initializeNFT721Mint();
  }

  /**
   * @notice Allows a Foundation admin to update NFT config variables.
   * @dev This must be called right after the initial call to `initialize`.
   */
  function adminUpdateConfig(
    address _nftMarket,
    string calldata baseURI,
    address proxyCallContract
  ) external onlyFoundationAdmin {
    _updateNFTMarket(_nftMarket);
    _updateBaseURI(baseURI);
    _updateProxyCall(proxyCallContract);
  }

  /**
   * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
   */
  function _burn(uint256 tokenId) internal override(OZERC721Upgradeable, NFT721Creator, NFT721Metadata, NFT721Mint) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165, NFT721Mint, OZERC721Upgradeable, NFT721Creator, NFT721Market)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "../OZ/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Defines a role for Foundation admin accounts.
 * @dev Wraps the default admin role from OpenZeppelin's AccessControl for easy integration.
 */
abstract contract AdminRole is Initializable, OZAccessControlUpgradeable {
  function _initializeAdminRole(address admin) internal onlyInitializing {
    OZAccessControlUpgradeable.__AccessControl_init();
    // Grant the role to a specified account
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AdminRole: caller does not have the Admin role");
    _;
  }

  /**
   * @notice Adds the account to the list of approved admins.
   * @dev Only callable by admins as enforced by `grantRole`.
   * @param account The address to be approved.
   */
  function grantAdmin(address account) external {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Removes the account from the list of approved admins.
   * @dev Only callable by admins as enforced by `revokeRole`.
   * @param account The address to be removed from the approved list.
   */
  function revokeAdmin(address account) external {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice Returns one of the admins by index.
   * @param index The index of the admin to return from 0 to getAdminMemberCount() - 1.
   * @return account The address of the admin.
   */
  function getAdminMember(uint256 index) external view returns (address account) {
    account = getRoleMember(DEFAULT_ADMIN_ROLE, index);
  }

  /**
   * @notice Checks how many accounts have been granted admin access.
   * @return count The number of accounts with admin access.
   */
  function getAdminMemberCount() external view returns (uint256 count) {
    count = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
  }

  /**
   * @notice Checks if the account provided is an admin.
   * @param account The address to check.
   * @return approved True if the account is an admin.
   * @dev This call is used by the royalty registry contract.
   */
  function isAdmin(address account) external view returns (bool approved) {
    approved = hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../mixins/roles/AdminRole.sol";

error CollateralManagement_Cannot_Withdraw_To_Address_Zero();
error CollateralManagement_Cannot_Withdraw_To_Self();

/**
 * @title Enables deposits and withdrawals.
 */
abstract contract CollateralManagement is AdminRole {
  using AddressUpgradeable for address payable;

  /**
   * @notice Emitted when funds are withdrawn from this contract.
   * @param to The address which received the ETH withdrawn.
   * @param amount The amount of ETH which was withdrawn.
   */
  event FundsWithdrawn(address indexed to, uint256 amount);

  /**
   * @notice Accept native currency payments (i.e. fees)
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Allows an admin to withdraw funds.
   * @param to        Address to receive the withdrawn funds
   * @param amount    Amount to withdrawal or 0 to withdraw all available funds
   */
  function withdrawFunds(address payable to, uint256 amount) external onlyAdmin {
    if (amount == 0) {
      amount = address(this).balance;
    }
    if (to == address(0)) {
      revert CollateralManagement_Cannot_Withdraw_To_Address_Zero();
    } else if (to == address(this)) {
      revert CollateralManagement_Cannot_Withdraw_To_Self();
    }
    to.sendValue(amount);

    emit FundsWithdrawn(to, amount);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[1000] private __gap;
}

/*                                                                               
  ･
   *　★ 
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　* 
　　　 *　★   ｡
                      `                     .-:::::-.`              `-::---...```                   
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:        
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy        
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy        
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy        
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy        
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy        
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy        
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy        
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy        
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy        
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy        
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo        
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo            
                                              `````       
   *　 
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./mixins/roles/AdminRole.sol";
import "./mixins/roles/OperatorRole.sol";
import "./mixins/CollateralManagement.sol";

/**
 * @title Manage revenue and roles for Foundation.
 * @notice All fees generated by the market are forwarded to this contract.
 * It also defines the Admin and Operator roles which are used in other contracts.
 */
contract FoundationTreasury is AdminRole, OperatorRole, CollateralManagement {
  /**
   * @notice Called one time after deployment to initialize the contract.
   * @param admin The account to add as the initial admin.
   */
  function initialize(address admin) external initializer {
    AdminRole._initializeAdminRole(admin);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@manifoldxyz/royalty-registry-solidity/contracts/RoyaltyRegistry.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideFactory.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCloneable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Imports the RoyaltyRegistry contracts so they are available for deploying on testnet

// solhint-disable-next-line no-empty-blocks
contract RoyaltyRegistryImport is RoyaltyRegistry {

}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IProxyCall.sol";

/**
 * @title Forwards arbitrary calls to an external contract.
 * @notice DO NOT approve this contract to transfer any ERC-20 or ERC-721,
 * or grant any other permissions for another contract.
 * @dev This is used so that the from address of the calling contract does not have
 * any special permissions (e.g. ERC-20 transfer).
 * Other return types and call structures may be added in the future.
 */
contract ExternalProxyCall is IProxyCall {
  using AddressUpgradeable for address;

  function proxyCallAndReturnAddress(address externalContract, bytes memory callData)
    external
    override
    returns (address payable result)
  {
    bytes memory returnData = externalContract.functionCall(callData);

    // Skip the length at the start of the bytes array and return the data, casted to an address
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(add(returnData, 32))
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract NonReceivableMock {
  using AddressUpgradeable for address;

  function callContract(address _contract, bytes memory _callData) public payable {
    _contract.functionCallWithValue(_callData, msg.value);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./SimpleContractMock.sol";

contract GasConsumingPayableMock {
  using AddressUpgradeable for address;

  SimpleContractMock public myContract;

  constructor(address _address) {
    myContract = SimpleContractMock(_address);
  }

  function callContract(address _contract, bytes memory _callData) public payable {
    _contract.functionCallWithValue(_callData, msg.value);
  }

  receive() external payable {
    myContract.setVariable("hello");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

contract SimpleContractMock {
  string public variable;

  constructor(string memory _variable) {
    variable = _variable;
  }

  function getVariable() public view returns (string memory) {
    return variable;
  }

  function setVariable(string memory _variable) public {
    variable = _variable;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract FailingReceivableMock {
  using AddressUpgradeable for address;
  bool public revertOnReceive;
  bool public loopOnReceive;

  receive() external payable {
    if (revertOnReceive) {
      revert("FAIL");
    }

    // solhint-disable no-empty-blocks
    while (loopOnReceive) {
      // Waste gas
    }
  }

  function callContract(address _contract, bytes memory _callData) public payable {
    _contract.functionCallWithValue(_callData, msg.value);
  }

  function updateRevertOnReceive(bool _revertOnReceive) public {
    revertOnReceive = _revertOnReceive;
  }

  function updateLoopOnReceive(bool _loopOnReceive) public {
    loopOnReceive = _loopOnReceive;
  }
}