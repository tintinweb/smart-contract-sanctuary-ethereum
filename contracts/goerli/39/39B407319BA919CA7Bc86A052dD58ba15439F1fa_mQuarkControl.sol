// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {Collection, SellOrder, BuyOrder, CreateCollectionParams, MintBatchParams, MintIdParams} from "../lib/mQuarkStructs.sol";
import "../lib/ERC721.sol";
import {DefaultOperatorFilterer} from "../lib/DefaultOperatorFilterer.sol";
import {ImQuark} from "../interfaces/mQuark/ImQuark.sol";
import "../interfaces/mQuark/ImQuarkControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title mQuark
/// @dev mQuark is an ERC721-compliant non-fungible token (NFT) contract for the mQuark protocol.
/// It is called by the mQuark Control contract to create templates and manage NFTs.
contract mQuark is ImQuark, ERC721, IERC2981, DefaultOperatorFilterer, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  //* ===================================================================================================
  //*                                          STATE VARIABLES
  //* ===================================================================================================

  /// @dev Stores the registered ERC721 Collection addresses to the contract
  EnumerableSet.AddressSet private registeredExternalCollections;

  /// @dev The mQuark Control address, used to check if the caller is mQuark Control when modifying functions
  ImQuarkControl public immutable mQuarkControl;

  /// @dev The address of the royalty receiver, used when a second-hand sale happens on a marketplace
  address public royaltyReceiver;

  /// @dev The percentage of the sale price that goes to the royalty receiver
  uint256 public royaltyPercentage;

  /// @dev Used during collection creation to determine which token id can be assigned as the
  /// minimum-mintable-first token id. After the last collection is created, its maximum-mintable-last
  /// token id is assigned to this variable.
  uint256 public globalTokenIdVariable;

  //* =========================== MAPPINGS ==============================================================

  /// @dev Mapping from a 'token id' and 'project id' to a 'project slot URI'
  mapping(address => mapping(uint256 => mapping(uint256 => string))) private _tokenProjectURIs;

  /// @dev Mapping from a 'token id' to a 'token URI'
  mapping(uint256 => string) private _tokenIdURIs;

  /// @dev Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private _inoperativeSignatures;

  /// @dev Mapping from a 'project id' and 'template id' to a 'collection id'
  mapping(uint256 => mapping(uint256 => uint256)) private _projectCollectionIds;

  /// @dev Mapping from a 'template id', 'project id', and 'collection id' to a 'collection'
  mapping(uint256 => mapping(uint256 => mapping(uint256 => Collection))) private _projectCollections;

  /// @dev Mapping from a 'token id' to a 'boolean'
  mapping(uint256 => bool) private freeMintTokenIds;

  /// @dev Mapping from a 'external ERC721 collection address' to 'template uri'
  mapping(address => string) private externalCollectionTemplateUris;

  //* ======================== MODIFIERS ================================================================

  /// @dev Prevents modified functions from being called other than the mQuark Control contract.
  modifier onlymQuarkControl() {
    _onlymQuarkControl();
    _;
  }

  //* ==================================================================================================
  //*                                           CONSTRUCTOR
  //* ==================================================================================================

  /// @notice Initializes the contract by setting the deployer as the 'admin' and the mQuark Control address.
  /// @param mQuarkControl_ The deployed mQuark Control contract address.
  constructor(ImQuarkControl mQuarkControl_) ERC721("mQuark", "QRK") {
    mQuarkControl = mQuarkControl_;
  }

  //* ==================================================================================================
  //*                                         EXTERNAL Functions
  //* =================================================================================================

  //* ======================MINTING Functions============================================================

  /// @notice Performs a single NFT mint without any slots.
  /// @param to The address of the token receiver.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mint(address to, MintIdParams calldata mintIdParams, uint256 variationId) external onlymQuarkControl {

    if (mintIdParams.templateId == 0) revert InvalidTemplateId();
    Collection memory _tempData = _projectCollections[mintIdParams.templateId][mintIdParams.projectId][
      mintIdParams.collectionId
    ];
    if (_tempData.collectionURIs.length <= variationId) revert InvalidVariation();
    if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();
    if (_tempData.mintCount >= _tempData.totalSupply) revert NotEnoughSupply();

    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;
    _mint(to, _tokenId);
    _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationId];
    ++_projectCollections[mintIdParams.templateId][mintIdParams.projectId][mintIdParams.collectionId].mintCount;

    emit NFTMinted(
      mintIdParams.projectId,
      mintIdParams.templateId,
      mintIdParams.collectionId,
      variationId,
      _tokenId,
      _tempData.collectionURIs[variationId],
      to
    );
  }

  /// Performs single free mint. NFT is locked to upgradability. It can be unlocked on the Control Contract.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mintFree(MintIdParams calldata mintIdParams, uint256 variationId) external {
    if (mintIdParams.templateId == 0) revert InvalidTemplateId();
    
    Collection memory _tempData = _projectCollections[mintIdParams.templateId][mintIdParams.projectId][
      mintIdParams.collectionId
    ];

    if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();
    if (_tempData.mintCount >= _tempData.totalSupply) revert NotEnoughSupply();
    if (
      mQuarkControl.getProjectCollectionPrice(
        mintIdParams.projectId,
        mintIdParams.templateId,
        mintIdParams.collectionId
      ) != 0
    ) revert CollectionIsNotFreeForMint();
    if (_tempData.collectionURIs.length <= variationId) revert InvalidVariation();
    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;
    _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationId];
    ++_projectCollections[mintIdParams.templateId][mintIdParams.projectId][mintIdParams.collectionId].mintCount;
    freeMintTokenIds[_tokenId] = true;
    _mint(msg.sender, _tokenId);

    emit NFTMintedFree(
      mintIdParams.projectId,
      mintIdParams.templateId,
      mintIdParams.collectionId,
      int256(variationId),
      _tokenId,
      _tempData.collectionURIs[variationId],
      msg.sender
    );
  }

  /// Performs single free mint. NFT is locked to upgradability. It can be unlocked on the Control Contract.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature The signed data for the NFT URI, using the project's registered wallet.
  /// @param uri The URI that will be assigned to the NFT
  function mintFreeWithURI(
    address signer,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external {
    if (mintIdParams.templateId == 0) revert InvalidTemplateId();
    Collection memory _tempData = _projectCollections[mintIdParams.templateId][mintIdParams.projectId][
      mintIdParams.collectionId
    ];
    if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();
    if (_tempData.mintCount >= _tempData.totalSupply) revert NotEnoughSupply();
    if (
      mQuarkControl.getProjectCollectionPrice(
        mintIdParams.projectId,
        mintIdParams.templateId,
        mintIdParams.collectionId
      ) != 0
    ) revert CollectionIsNotFreeForMint();
    if (
      !_verifyCollectionURIEditSignature(
        signature,
        signer,
        mintIdParams.projectId,
        mintIdParams.templateId,
        mintIdParams.collectionId,
        uri
      )
    ) revert VerificationFailed();
    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;
    _tokenIdURIs[_tokenId] = uri;
    ++_projectCollections[mintIdParams.templateId][mintIdParams.projectId][mintIdParams.collectionId].mintCount;
    freeMintTokenIds[_tokenId] = true;
    _mint(msg.sender, _tokenId);

    emit NFTMintedFree(
      mintIdParams.projectId,
      mintIdParams.templateId,
      mintIdParams.collectionId,
      (-1),
      _tokenId,
      uri,
      msg.sender
    );
  }

  /// @notice Performs a single NFT mint without any slots.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param to The address of the token receiver.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature The signed data for the NFT URI, using the project's registered wallet.
  /// @param uri The URI that will be assigned to the NFT
  function mintWithPreURI(
    address signer,
    address to,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external onlymQuarkControl {

    if (mintIdParams.templateId == 0) revert InvalidTemplateId();

    if (
      !_verifyCollectionURIEditSignature(
        signature,
        signer,
        mintIdParams.projectId,
        mintIdParams.templateId,
        mintIdParams.collectionId,
        uri
      )
    ) revert VerificationFailed();

    Collection memory _tempData = _projectCollections[mintIdParams.templateId][mintIdParams.projectId][
      mintIdParams.collectionId
    ];

    if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();

    if (_tempData.mintCount >= _tempData.totalSupply) revert NotEnoughSupply();

    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;

    _mint(to, _tokenId);

    _tokenIdURIs[_tokenId] = uri;

    ++_projectCollections[mintIdParams.templateId][mintIdParams.projectId][mintIdParams.collectionId].mintCount;

    emit NFTMintedWithPreUri(
      mintIdParams.projectId,
      mintIdParams.templateId,
      mintIdParams.collectionId,
      uri,
      _tokenId,
      to
    );
  }

  /// @notice Performs a batch mint operation without any URI slots.
  /// @param to The address of the token receiver.
  /// @param mintBatchParams Packed parameters
  /// * projectId The collection owner's project ID.
  /// * _templateIds The collection's inherited template's ID.
  /// * collectionIds The collection ID for its template.
  /// * totalSupplies The number of mint amounts from each collection.
  function mintBatch(address to, MintBatchParams calldata mintBatchParams) external onlymQuarkControl {
    if (mintBatchParams.templateIds.length != mintBatchParams.collectionIds.length) revert LengthMismatch();
    if (mintBatchParams.templateIds.length != mintBatchParams.totalSupplies.length) revert LengthMismatch();

    Collection memory _tempData;
    uint256 _tokenId;

    uint8 _templateIdsLength = uint8(mintBatchParams.templateIds.length);
    for (uint8 i = 0; i < _templateIdsLength; ) {

      if (mintBatchParams.totalSupplies[i] > 10) revert ExceedsLimit();

      uint8 _mintAmount = mintBatchParams.totalSupplies[i];

      if (mintBatchParams.templateIds[i] == 0 || _mintAmount == 0) revert InvalidIdAmount();

      _tempData = _projectCollections[mintBatchParams.templateIds[i]][mintBatchParams.projectId][
        mintBatchParams.collectionIds[i]
      ];

      if (_tempData.collectionURIs.length <= mintBatchParams.variationIds[i]) revert InvalidVariation();
      if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();
      if ((_tempData.mintCount + _mintAmount) > (_tempData.totalSupply)) revert NotEnoughSupply();


      for (uint8 ii = 0; ii < _mintAmount; ) {

        _tokenId = _tempData.minTokenId + _tempData.mintCount;

        _mint(to, _tokenId);

        ++_tempData.mintCount;

        _tokenIdURIs[_tokenId] = _tempData.collectionURIs[mintBatchParams.variationIds[i]];

        emit NFTMinted(
          mintBatchParams.projectId,
          mintBatchParams.templateIds[i],
          mintBatchParams.collectionIds[i],
          mintBatchParams.variationIds[i],
          _tokenId,
          _tempData.collectionURIs[mintBatchParams.variationIds[i]],
          to
        );

        unchecked {
          ++ii;
        }
      }

      _projectCollections[mintBatchParams.templateIds[i]][mintBatchParams.projectId][mintBatchParams.collectionIds[i]]
        .mintCount += _mintAmount;

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Performs batch mint operation with single given project URI slot for every token
  /// @notice Reverts if the number of given templates are more than 256
  /// @param to token receiver
  /// @param mintBatchParams Packed parameters
  /// * projectId The collection owner's project ID.
  /// * templateIds The collection's inherited template's ID.
  /// * collectionIds The collection ID for its template.
  /// * totalSupplies The number of mint amounts from each collection.
  /// @param projectDefaultUri project slot will be pre-initialized with the project's default slot URI
  function mintBatchWithURISlot(
    address to,
    MintBatchParams calldata mintBatchParams,
    string calldata projectDefaultUri
  ) external onlymQuarkControl {
    if (mintBatchParams.templateIds.length > 256) revert ExceedsLimit();
    if (mintBatchParams.templateIds.length != mintBatchParams.collectionIds.length) revert LengthMismatch();
    if (mintBatchParams.totalSupplies.length != mintBatchParams.collectionIds.length) revert LengthMismatch();
    Collection memory _tempData;
    uint256 _tokenId;
    uint8 templateIdsLength = uint8(mintBatchParams.templateIds.length);

    for (uint8 i = 0; i < templateIdsLength; ) {
      if (mintBatchParams.templateIds[i] == 0 || mintBatchParams.collectionIds[i] == 0) revert InvalidId(mintBatchParams.templateIds[i],mintBatchParams.collectionIds[i]);

      _tempData = _projectCollections[mintBatchParams.templateIds[i]][mintBatchParams.projectId][
        mintBatchParams.collectionIds[i]
      ];

      if (_tempData.collectionURIs.length <= mintBatchParams.variationIds[i]) revert InvalidVariation();
      if (_tempData.minTokenId == 0) revert UnexsistingTokenMint();
      if ((_tempData.mintCount) >= (_tempData.totalSupply)) revert NotEnoughSupply();

      _tokenId = _tempData.minTokenId + _tempData.mintCount;

      uint8 _mintAmounts = mintBatchParams.totalSupplies[i];
      _tokenId = _tempData.minTokenId + _tempData.mintCount;
      for (uint8 ii = 0; ii < _mintAmounts; ) {
        _mint(to, _tokenId);
        _tokenProjectURIs[address(this)][_tokenId][mintBatchParams.projectId] = projectDefaultUri;
        _tokenIdURIs[_tokenId] = _tempData.collectionURIs[mintBatchParams.variationIds[i]];


        emit NFTMinted(
          mintBatchParams.projectId,
          mintBatchParams.templateIds[i],
          mintBatchParams.collectionIds[i],
          mintBatchParams.variationIds[i],
          _tokenId,
          _tempData.collectionURIs[mintBatchParams.variationIds[i]],
          to
        );
        emit ProjectURISlotAdded(_tokenId, mintBatchParams.projectId, projectDefaultUri);
        ++_tokenId;
        ++_tempData.mintCount;
        unchecked {
          ++ii;
        }
      }

      _projectCollections[mintBatchParams.templateIds[i]][mintBatchParams.projectId][mintBatchParams.collectionIds[i]]
        .mintCount += _mintAmounts;

      unchecked {
        ++i;
      }
    }
  }

  /// Mints a single non-fungible token (NFT) with multiple metadata slots.
  /// Initializes the metadata slots with the given project's URI.
  /// @notice Reverts if the number of given templates is more than 256.
  /// @param to The address of the token receiver.
  /// @param templateId The ID of the collection's inherited template.
  /// @param collectionId The ID of the collection for its template.
  /// @param projectIds The IDs of the collection owner's project.
  /// @param projectSlotDefaultUris The project slot will be pre-initialized with the project's default slot URI.
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external onlymQuarkControl {
    if (templateId == 0) revert InvalidTemplateId();
    Collection memory _tempData = _projectCollections[templateId][projectIds[0]][collectionId];
    if (_tempData.collectionURIs.length <= variationId) revert InvalidVariation();
    if (_tempData.mintCount >= _tempData.totalSupply) revert NotEnoughSupply();
    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;
    _mint(to, _tokenId);
    _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationId];
    ++_projectCollections[templateId][projectIds[0]][collectionId].mintCount;
    addBatchURISlotsToNFT(to, address(this), _tokenId, projectIds, projectSlotDefaultUris);

    emit NFTMinted(
      projectIds[0],
      templateId,
      collectionId,
      variationId,
      _tokenId,
      _tempData.collectionURIs[variationId],
      to
    );
  }

  //* =========================== URI SLOT Functions ==========================================

  /// Adds a single URI slot to a single non-fungible token (NFT).
  /// Initializes the added slot with the given project's default URI.
  /// @notice Reverts if the number of given projects is more than 256.
  /// @notice The added slot's initial state will be pre-filled with the project's default URI.
  /// @param owner The owner of the token.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token to which the slot will be added.
  /// @param projectId The ID of the slot's project.
  /// @param projectSlotDefaultUri The project's default URI that will be set to the added slot.
  function addURISlotToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectSlotDefaultUri
  ) public onlymQuarkControl {
    bool isMainContract = address(this) == tokenContract;
    if (!(registeredExternalCollections.contains(tokenContract) || isMainContract)) revert InvalidContractAddress();
    if (IERC721(tokenContract).ownerOf(tokenId) != owner) revert NotOwner();
    if (isMainContract && freeMintTokenIds[tokenId]) revert LockedNFT(tokenId);
    if (!_compareStrings(_tokenProjectURIs[tokenContract][tokenId][projectId], "")) revert AddedSlot();

    _tokenProjectURIs[tokenContract][tokenId][projectId] = projectSlotDefaultUri;

    emit ProjectURISlotAdded(tokenId, projectId, projectSlotDefaultUri);
  }

  /// Adds multiple URI slots to a single token in a batch operation.
  /// @notice Reverts if the number of projects is more than 256.
  /// @notice Slots' initial state will be pre-filled with the given default URI values.
  /// @param owner The owner of the token.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token to which the slots will be added.
  /// @param projectIds An array of IDs for the slots that will be added.
  /// @param projectSlotDefaultUris An array of default URI values for the added
  function addBatchURISlotsToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) public onlymQuarkControl {
    uint256 projectCount = projectIds.length;
    if (projectCount > 255) revert ExceedsLimit();
    for (uint256 i = 0; i < projectCount; ) {
      addURISlotToNFT(owner, tokenContract, tokenId, projectIds[i], projectSlotDefaultUris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// Adds the same URI slot to multiple tokens in a batch operation.
  /// @notice Reverts if the number of tokens is more than 20.
  /// @notice Slots' initial state will be pre-filled with the given default URI value.
  /// @param owner The owner of the tokens.
  /// @param tokensContracts The contract address of each token
  /// @param tokenIds An array of IDs for the tokens to which the slot will be added.
  /// @param projectId The ID of the project for the slot that will be added.
  /// @param projectDefaultUris The default URI value for the added slot.
  function addBatchURISlotToNFTs(
    address owner,
    address[] calldata tokensContracts,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectDefaultUris
  ) public onlymQuarkControl {
    uint256 mintingLength = tokenIds.length;
    if (mintingLength > 20) revert ExceedsLimit();
    for (uint8 i = 0; i < mintingLength; ) {
      addURISlotToNFT(owner, tokensContracts[i], tokenIds[i], projectId, projectDefaultUris);
      unchecked {
        ++i;
      }
    }
  }

  /// Updates the URI slot of a single token.
  /// @notice The project must sign the new URI with its private key.
  /// @param owner The address of the owner of the token.
  /// @param signature The signed data for the updated URI, using the project's private key.
  /// @param project The address of the project.
  /// @param projectId The ID of the project.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token.
  /// @param updatedUri The updated, signed URI value.
  function updateURISlot(
    address owner,
    bytes calldata signature,
    address project,
    uint256 projectId,
    address tokenContract,
    uint256 tokenId,
    string calldata updatedUri
  ) external onlymQuarkControl {
    if (IERC721(tokenContract).ownerOf(tokenId) != owner) revert NotOwner();
    if (_compareStrings(_tokenProjectURIs[tokenContract][tokenId][projectId], "")) revert UriSLotUnexist();
    if (!_verifyUpdateTokenURISignature(signature, project, projectId, tokenId, updatedUri))
      revert VerificationFailed();
    _inoperativeSignatures[signature] = true;
    _tokenProjectURIs[tokenContract][tokenId][projectId] = updatedUri;

    emit ProjectURIUpdated(signature, projectId, tokenId, updatedUri);
  }

  /// Transfers the URI slot of a single token to another token's URI slot for the same project.
  /// Also resets the URI slot of the sold token to the default URI value for the project.
  /// @notice Reverts if slots are not added for both tokens.
  /// @notice Reverts if the URI to be sold doesn't match the current URI of the token.
  /// @notice Reverts if one of the tokens is not owned by the seller or buyer.
  /// @param seller A struct containing details about the sell order.
  /// @param buyer A struct containing details about the buy order.
  /// @param projectDefaultUri The default URI value for the project.
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    string calldata projectDefaultUri
  ) external onlymQuarkControl {
    if (IERC721(seller.fromContractAddress).ownerOf(seller.fromTokenId) != seller.seller) revert SellerIsNotOwner();
    if (IERC721(buyer.toContractAddress).ownerOf(buyer.toTokenId) != buyer.buyer) revert BuyerIsNotOwner();
    if (
      !_compareStrings(
        _tokenProjectURIs[seller.fromContractAddress][seller.fromTokenId][seller.projectId],
        seller.slotUri
      )
    ) revert SellerGivenURIMismatch();

    _tokenProjectURIs[buyer.toContractAddress][buyer.toTokenId][buyer.projectId] = seller.slotUri;

    _tokenProjectURIs[seller.fromContractAddress][seller.fromTokenId][seller.projectId] = projectDefaultUri;
  }

  //* ================================================================================================

  //* ==================================COLLECTION Creation Functions=================================

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param createCollectionParams Packed parameters
  /// * templateIds The IDs of the selected templates to use for creating the collections.
  /// * collectionIds The IDs of the next collections ids for the templates
  /// * totalSupplies The total supplies of tokens for the new collections.
  /// @param signatures The signatures created using the given parameters and signed by the signer.
  /// Second dimension includes, each signatures of each variation.
  /// @param uris The URIs that will be assigned to the collections. Second dimension includes variations.
  function createCollections(
    uint256 projectId,
    address signer,
    CreateCollectionParams calldata createCollectionParams,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external onlymQuarkControl {
    uint256 _lastUsedTokenId = globalTokenIdVariable;
    uint256 _collectionId;
    bool isVerified;
    uint256 templateCount = createCollectionParams.templateIds.length;
    for (uint256 i = 0; i < templateCount; ) {
      _collectionId = ++_projectCollectionIds[projectId][createCollectionParams.templateIds[i]];
      if (_collectionId != createCollectionParams.collectionIds[i]) revert InvalidCollectionId();
      for (uint256 j = 0; j < signatures[i].length; ) {
        isVerified = _verifyCollectionURIEditSignature(
          signatures[i][j],
          signer,
          projectId,
          createCollectionParams.templateIds[i],
          _collectionId,
          uris[i][j]
        );
        if (!isVerified) revert VerificationFailed();
        _inoperativeSignatures[signatures[i][j]] = true;
        unchecked {
          ++j;
        }
      }
      Collection memory _tempData = _projectCollections[createCollectionParams.templateIds[i]][projectId][
        _collectionId
      ];

      _tempData = Collection(
        projectId,
        createCollectionParams.templateIds[i],
        _collectionId,
        createCollectionParams.totalSupplies[i],
        (_lastUsedTokenId + 1),
        _lastUsedTokenId + createCollectionParams.totalSupplies[i],
        0,
        uris[i]
      );

      _lastUsedTokenId += createCollectionParams.totalSupplies[i];

      _projectCollections[createCollectionParams.templateIds[i]][projectId][_collectionId] = _tempData;

      emit CollectionCreated(
        projectId,
        createCollectionParams.templateIds[i],
        _collectionId,
        createCollectionParams.totalSupplies[i],
        _tempData.minTokenId,
        _tempData.maxTokenId,
        uris[i]
      );

      unchecked {
        ++i;
      }
    }

    globalTokenIdVariable = _lastUsedTokenId;
  }

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param templateIds_ The IDs of the selected templates to use for creating the collections.
  /// @param totalSupplies The total supplies of tokens for the new collections.
  function createCollectionsWithoutURIs(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint16[] calldata totalSupplies
  ) external onlymQuarkControl {
    uint256 _lastUsedTokenId = globalTokenIdVariable;
    uint256 _collectionId;

    uint256 templateCount = templateIds_.length;
    for (uint256 i = 0; i < templateCount; ) {
      _collectionId = ++_projectCollectionIds[projectId][templateIds_[i]];
      string[] memory tempUri = new string[](1);

      Collection memory _tempData = _projectCollections[templateIds_[i]][projectId][_collectionId];

      _tempData = Collection(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        (_lastUsedTokenId + 1),
        _lastUsedTokenId + totalSupplies[i],
        0,
        tempUri
      );


      _lastUsedTokenId += totalSupplies[i];

      _projectCollections[templateIds_[i]][projectId][_collectionId] = _tempData;

      emit CollectionCreated(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        _tempData.minTokenId,
        _tempData.maxTokenId,
        tempUri
      );

      unchecked {
        ++i;
      }
    }

    // Update the global token ID variable with the new last used token ID.
    globalTokenIdVariable = _lastUsedTokenId;
  }

  //* =================================================================================================

  //* ================================UTILITY Functions================================================

  /// @dev See EIP 2981
  function setRoyalty(address _receiver, uint256 _royaltyPercentage) external onlyOwner {
    royaltyReceiver = _receiver;
    royaltyPercentage = _royaltyPercentage;
    emit RoyaltySet(_receiver, _royaltyPercentage);
  }

  /// Registers ERC721-Collections to the contract. URI slots to can be added to the NFTs.
  /// Collection has to be represented by a chosen template.
  /// @param tokenContract ERC721 contract address
  /// @param templateUri Chosen template URI that represents the collection.
  function registerExternalCollection(address tokenContract, string calldata templateUri) external onlymQuarkControl {
    if (IERC721(tokenContract).supportsInterface(type(IERC721).interfaceId)) revert NonERC721Implementer();
    if (registeredExternalCollections.contains(tokenContract)) registeredExternalCollections.add(tokenContract);
    externalCollectionTemplateUris[tokenContract] = templateUri;
  }

  /// Removes the lock on the NFT that prevents to have slots.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param tokenId token id
  function unlockFreeMintNFT(MintIdParams calldata mintIdParams, uint256 tokenId) external onlymQuarkControl {
    Collection memory _tempData = _projectCollections[mintIdParams.templateId][mintIdParams.projectId][
      mintIdParams.collectionId
    ];
    if (!(_tempData.minTokenId <= tokenId && _tempData.maxTokenId >= tokenId)) revert InvalidTokenId();
    delete freeMintTokenIds[tokenId];
  }

  //* ================================================================================================
  //*                                          VIEW Functions
  //* ================================================================================================

  /// @return token uri, for the given token id
  function tokenURI(uint256 tokenId) public view override(ImQuark, ERC721) returns (string memory) {
    _requireMinted(tokenId);
    return _tokenIdURIs[tokenId];
  }

  /// Every project will be able to place a slot to tokens if owners want
  /// These slots will store the uri that refers 'something' on the project
  /// Slots are viewable by other projects but modifiable only by the owner of the token who has a valid signature by the project
  /// @notice Returns the project URI for the given token ID
  /// @param tokenId The ID of the token whose project URI is to be returned
  /// @param projectId The ID of the project associated with the given token
  /// @return The URI of the given token's project slot
  function tokenProjectURI(
    address tokenContract,
    uint256 tokenId,
    uint256 projectId
  ) external view returns (string memory) {
    if (!(registeredExternalCollections.contains(tokenContract) || address(this) == tokenContract))
      revert GivenTokenAddressNotRegistered();
    return _tokenProjectURIs[tokenContract][tokenId][projectId];
  }

  /// @return Collection template uri
  function externalCollectionURI(address collectionAddress) external view returns (string memory) {
    if (!registeredExternalCollections.contains(collectionAddress)) revert InvalidTokenAddress();
    return externalCollectionTemplateUris[collectionAddress];
  }

  /// @return receiver is the royalty receiver address
  /// @return royaltyAmount the percentage of royalty
  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view override(ImQuark, IERC2981) returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyReceiver;
    royaltyAmount = (royaltyPercentage * _salePrice) / 100;
  }

  /// @notice This function returns the last collection ID for a given project and template.
  /// @param projectId The ID of the project to get the last collection ID for
  /// @param templateId The ID of the template to get the last collection ID for
  /// @return The last collection ID for the given project and template
  function getProjectLastCollectionId(uint256 projectId, uint256 templateId) external view returns (uint256) {
    return _projectCollectionIds[projectId][templateId];
  }

  /// @notice This function checks whether a given token has been assigned a slot for a given project.
  /// @param tokenId The ID of the token to check
  /// @param projectId The ID of the project to check
  /// @return isAdded true if the given token has been assigned a slot for the given project, false otherwise
  function isSlotAddedForProject(
    address contractAddress,
    uint256 tokenId,
    uint256 projectId
  ) external view returns (bool isAdded) {
    string memory slot = _tokenProjectURIs[contractAddress][tokenId][projectId];
    isAdded = !_compareStrings(slot, "");
  }

  /// @return Returns true if the token is minted for free.
  function getIsFreeMinted(uint256 tokenId) external view returns (bool) {
    return freeMintTokenIds[tokenId];
  }

  /// The function getProjectCollection is used to retrieve the details of a specific collection that was created by a registered project.
  /// @param templateId The ID of the template used to create the collection.
  /// @param projectId The ID of the project that created the collection.
  /// @param collectionId  The ID of the collection.
  /// @return _projectId The ID of the project that created the collection.
  /// @return _templateId The ID of the template used to create the collection.
  /// @return _totalSupply The total number of tokens in the collection.
  /// @return _collectionId The ID of the collection.
  /// @return _minTokenId The minimum token ID in the collection.
  /// @return _maxTokenId The maximum token ID in the collection.
  /// @return _mintCount The number of tokens that have been minted for this collection.
  /// @return _collectionURI The URI associated with the collection.
  function getProjectCollection(
    uint256 templateId,
    uint256 projectId,
    uint256 collectionId
  )
    external
    view
    returns (
      uint256 _projectId,
      uint256 _templateId,
      uint256 _totalSupply,
      uint256 _collectionId,
      uint256 _minTokenId,
      uint256 _maxTokenId,
      uint256 _mintCount,
      string[] memory _collectionURI
    )
  {
    Collection memory _collection = _projectCollections[templateId][projectId][collectionId];

    return (
      _collection.projectId,
      _collection.templateId,
      _collection.totalSupply,
      _collection.collectionId,
      _collection.minTokenId,
      _collection.maxTokenId,
      _collection.mintCount,
      _collection.collectionURIs
    );
  }

  /// @dev See ERC 165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, ImQuark) returns (bool) {
    return
      (interfaceId == type(IERC2981).interfaceId) ||
      (interfaceId == type(ImQuark).interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  //* ================================================================================================
  //*                                       INTERNAL Functions
  //* ================================================================================================

  /// @return _signer the singer of the given signature
  function _getHashSigner(bytes32 _hash, bytes memory signature) internal pure returns (address _signer) {
    bytes32 _signed = ECDSA.toEthSignedMessageHash(_hash);
    _signer = ECDSA.recover(_signed, signature);
  }

  /// @notice This function checks the validity of a given signature by verifying that it is signed by the given signer.
  /// @param signature The signature to verify
  /// @param signer The signer of the signature
  /// @param projectId The ID of the project associated with the signature
  /// @param templateId The ID of the template associated with the signature
  /// @param collectionId The ID of the collection associated with the signature
  /// @param uri The URI associated with the signature
  /// @return true if the signature is valid, false otherwise
  function _verifyCollectionURIEditSignature(
    bytes memory signature,
    address signer,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    string memory uri
  ) internal view returns (bool) {
    if (_inoperativeSignatures[signature]) revert UsedSignature();
    bytes32 _messageHash = keccak256(abi.encode(signer, projectId, templateId, collectionId, uri));
    address _signer = _getHashSigner(_messageHash, signature);
    return (_signer == signer);
  }

  /// @notice This function checks the validity of a given signature by verifying that it is signed by the given project address.
  /// @param signature The signature to verify
  /// @param project The address of the project that signed the signature
  /// @param projectId The ID of the project associated with the signature
  /// @param tokenId The ID of the token associated with the signature
  /// @param _uri The URI associated with the signature
  /// @return true if the signature is valid, false otherwise
  function _verifyUpdateTokenURISignature(
    bytes memory signature,
    address project,
    uint256 projectId,
    uint256 tokenId,
    string memory _uri
  ) internal view returns (bool) {
    if (_inoperativeSignatures[signature]) revert UsedSignature();
    bytes32 _messageHash = keccak256(abi.encode(project, projectId, tokenId, _uri));
    address _signer = _getHashSigner(_messageHash, signature);

    return (project == _signer);
  }

  /// @notice This function compares two strings and returns true if they are equal.
  /// @param firstStr The first string to compare
  /// @param secondStr The second string to compare
  /// @return true if the strings are equal, false otherwise
  function _compareStrings(string memory firstStr, string memory secondStr) internal pure returns (bool) {
    return (keccak256(abi.encodePacked(firstStr)) == keccak256(abi.encodePacked(secondStr)));
  }

  /// @notice This function checks if the caller of the function is the mQuark Control contract.
  /// @dev This function should be called at the beginning of functions that are only allowed to be called by the mQuark Control contract.
  function _onlymQuarkControl() internal view {
    if (ImQuarkControl(msg.sender) != mQuarkControl) revert CallerNotAuthorized();
  }

  //* ===============================ON-CHAIN ENFORCERER==============================================

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /**
   * @dev See {IERC721-approve}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /**
   * @dev See {IERC721-transferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Project {
  // The wallet address of the project
  address wallet;
  // The wallet address of the project's creator
  address creator;
  // The unique ID of the project
  uint256 id;
  // The balance of the project
  uint256 balance;
  // The name of the project
  string name;
  // The description of the project
  string description;
  // The thumbnail image of the project
  string thumbnail;
  // The default URI for the project's tokens
  string projectSlotDefaultURI;
}

struct Collection {
  // the id of the project that the collection belongs to. This id is assigned by the contract.
  uint256 projectId;
  // the id of the template that the collection inherits from.
  uint256 templateId;
  // the created collection's id for a template id
  uint256 collectionId;
  // the total supply of the collection
  uint256 totalSupply;
  // the minimum token id that can be minted from the collection
  uint256 minTokenId;
  // the maximum token id that can be minted from the collection
  uint256 maxTokenId;
  // the number of minted tokens from the collection
  uint256 mintCount;
  // the URIs of the collection (minted tokens inherit one of the URI)
  string[] collectionURIs;
}

struct SellOrder {
  // the order maker (the person selling the URI)
  address payable seller;

  address fromContractAddress;
  // the token id whose project URI will be sold
  uint256 fromTokenId;
  // the project's id whose owner is selling the URI
  uint256 projectId;
  // the URI that will be sold
  string slotUri;
  // the price required for the URI
  uint256 sellPrice;
}
struct BuyOrder {
  // the order executer (the person buying the URI)
  address buyer;
  // the order maker (the person selling the URI)
  address seller;
  // the token id whose project URI will be bought
  address fromContractAddress;
  // the token id whose project URI will be sold
  uint256 fromTokenId;
  // the token id whose project URI will be updated with the sold URI
  address toContractAddress;
  // the token id whose project URI will be sold
  uint256 toTokenId;
  // the project's id whose owner is selling the URI
  uint256 projectId;
  // the URI that will be bought
  string slotUri;
  // the price required for the URI
  uint256 buyPrice;
}

struct CreateCollectionParams {
  uint256[] templateIds;
  uint256[] collectionIds;
  uint16[] totalSupplies;
}

struct MintBatchParams {
  uint256 projectId;
  uint256[] templateIds;
  uint256[] collectionIds;
  uint256[] variationIds;
  uint8[] totalSupplies;
}

struct MintIdParams {
  uint256 projectId;
  uint256 templateId;
  uint256 collectionId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    // using EnumerableSet for EnumerableSet.UintSet;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    // mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // mapping (address => EnumerableSet.UintSet) private _ownerTokens;
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

    // /**
    //  * @dev See {IERC721-balanceOf}.
    //  */
    // function balanceOf(address owner) public view virtual override returns (uint256) {
    //     require(owner != address(0), "ERC721: address zero is not a valid owner");
    //     // return _balances[owner];
    // }

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

    // function ownerTokens(address owner) public view returns(uint256[] memory) {
    //     return _ownerTokens[owner].values();
    // }

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
        // require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId);

        // _balances[to] += 1;
        _owners[tokenId] = to;
       emit Transfer(address(0), to, tokenId);

        // _afterTokenTransfer(address(0), to, tokenId);
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
    // function _burn(uint256 tokenId) internal virtual {
    //     address owner = ERC721.ownerOf(tokenId);

    //     // _beforeTokenTransfer(owner, address(0), tokenId);

    //     // Clear approvals
    //     _approve(address(0), tokenId);

    //     // _balances[owner] -= 1;
    //     delete _owners[tokenId];

    //     emit Transfer(owner, address(0), tokenId);

    //     // _afterTokenTransfer(owner, address(0), tokenId);
    // }

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

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // _balances[from] -= 1;
        // _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        // _afterTokenTransfer(from, to, tokenId);
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
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual {}

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
    // function _afterTokenTransfer(
    //    address from,
    //    address to,
    //    uint256 tokenId
    // ) internal virtual {
    //     if(from != address(0)) {
    //         _ownerTokens[to].add(tokenId);
    //         _ownerTokens[from].remove(tokenId);
    //     }
    //     else  _ownerTokens[to].add(tokenId);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {CreateCollectionParams, MintBatchParams, MintIdParams, Collection, SellOrder, BuyOrder} from "../../lib/mQuarkStructs.sol";

interface ImQuark {
  // Event for when categories are set for a template
  event CategoriesSet(string category, uint256[] templateIds);
  // Event for when a category is removed from a template
  event CategoryRemoved(string category, uint256 templateId);
  // Event for when a collection is created
  event CollectionCreated(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint16 totalSupply,
    uint256 minId,
    uint256 maxId,
    // string collectionUri
    // string[] collectionUri
    string[] collectionUris
  );
  // Event for when an NFT is minted
  event NFTMinted(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256 tokenId,
    string uri,
    address to
  );
  event NFTMintedFree(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    int256 variationId,
    uint256 tokenId,
    string uri,
    address to
  );
  event NFTMintedWithPreUri(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    string uri,
    uint256 tokenId,
    address to
  );
  // Event for when a URI slot is added for a project for a token
  event ProjectURISlotAdded(uint256 tokenId, uint256 projectId, string uri);
  // Event for when a URI slot is reset for a project for a token
  event ProjectSlotURIReset(uint256 tokenId, uint256 projectId);
  // Event for when a URI is updated for a project for a token
  event ProjectURIUpdated(bytes signature, uint256 projectId, uint256 tokenId, string updatedUri);
  // Event for when the royalty rate is set
  event RoyaltySet(address reciever, uint256 royaltyAmount);
  // Event for when a template is created
  event TemplateCreated(uint256 templateId, string uri);

  /// @notice Performs a single NFT mint without any slots.
  /// @param to The address of the token receiver.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mint(
    address to,
    MintIdParams calldata mintIdParams,
    uint256 variationId
  ) external;

  /// Performs single free mint. NFT is locked to upgradability. It can be unlocked on the Control Contract.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mintFree(MintIdParams calldata mintIdParams, uint256 variationId) external;

  /// Performs single free mint. NFT is locked to upgradability. It can be unlocked on the Control Contract.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature The signed data for the NFT URI, using the project's registered wallet.
  /// @param uri The URI that will be assigned to the NFT
  function mintFreeWithURI(
    address signer,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external;

  /// @notice Performs a single NFT mint without any slots.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param to The address of the token receiver.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature The signed data for the NFT URI, using the project's registered wallet.
  /// @param uri The URI that will be assigned to the NFT
  function mintWithPreURI(
    address signer,
    address to,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external;

  /// @notice Performs a batch mint operation without any URI slots.
  /// @param to The address of the token receiver.
  /// @param mintBatchParams Packed parameters
  /// * projectId The collection owner's project ID.
  /// * _templateIds The collection's inherited template's ID.
  /// * collectionIds The collection ID for its template.
  /// * totalSupplies The number of mint amounts from each collection.
  function mintBatch(address to, MintBatchParams calldata mintBatchParams) external;

  /// @dev Performs batch mint operation with single given project URI slot for every token
  /// @notice Reverts if the number of given templates are more than 256
  /// @param to token receiver
  /// @param mintBatchParams Packed parameters
  /// * projectId The collection owner's project ID.
  /// * _templateIds The collection's inherited template's ID.
  /// * collectionIds The collection ID for its template.
  /// * totalSupplies The number of mint amounts from each collection.
  /// @param projectDefaultUri project slot will be pre-initialized with the project's default slot URI
  function mintBatchWithURISlot(
    address to,
    MintBatchParams calldata mintBatchParams,
    string calldata projectDefaultUri
  ) external;

  /// Mints a single non-fungible token (NFT) with multiple metadata slots.
  /// Initializes the metadata slots with the given project's URI.
  /// @notice Reverts if the number of given templates is more than 256.
  /// @param to The address of the token receiver.
  /// @param templateId The ID of the collection's inherited template.
  /// @param collectionId The ID of the collection for its template.
  /// @param projectIds The IDs of the collection owner's project.
  /// @param projectSlotDefaultUris The project slot will be pre-initialized with the project's default slot URI.
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

  /// Adds a single URI slot to a single non-fungible token (NFT).
  /// Initializes the added slot with the given project's default URI.
  /// @notice Reverts if the number of given projects is more than 256.
  /// @notice The added slot's initial state will be pre-filled with the project's default URI.
  /// @param owner The owner of the token.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token to which the slot will be added.
  /// @param projectId The ID of the slot's project.
  /// @param projectSlotDefaultUri The project's default URI that will be set to the added slot.
  function addURISlotToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectSlotDefaultUri
  ) external;

  /// Adds multiple URI slots to a single token in a batch operation.
  /// @notice Reverts if the number of projects is more than 256.
  /// @notice Slots' initial state will be pre-filled with the given default URI values.
  /// @param owner The owner of the token.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token to which the slots will be added.
  /// @param projectIds An array of IDs for the slots that will be added.
  /// @param projectSlotDefaultUris An array of default URI values for the added
  function addBatchURISlotsToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

  /// Adds the same URI slot to multiple tokens in a batch operation.
  /// @notice Reverts if the number of tokens is more than 20.
  /// @notice Slots' initial state will be pre-filled with the given default URI value.
  /// @param owner The owner of the tokens.
  /// @param tokensContracts The contract address of each token
  /// @param tokenIds An array of IDs for the tokens to which the slot will be added.
  /// @param projectId The ID of the project for the slot that will be added.
  /// @param projectDefaultUris The default URI value for the added slot.
  function addBatchURISlotToNFTs(
    address owner,
    address[] calldata tokensContracts,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectDefaultUris
  ) external;

  /// Updates the URI slot of a single token.
  /// @notice The project must sign the new URI with its private key.
  /// @param owner The address of the owner of the token.
  /// @param signature The signed data for the updated URI, using the project's private key.
  /// @param project The address of the project.
  /// @param projectId The ID of the project.
  /// @param tokenContract The contract address of the token
  /// @param tokenId The ID of the token.
  /// @param updatedUri The updated, signed URI value.
  function updateURISlot(
    address owner,
    bytes calldata signature,
    address project,
    uint256 projectId,
    address tokenContract,
    uint256 tokenId,
    string calldata updatedUri
  ) external;

  /// Transfers the URI slot of a single token to another token's URI slot for the same project.
  /// Also resets the URI slot of the sold token to the default URI value for the project.
  /// @notice Reverts if slots are not added for both tokens.
  /// @notice Reverts if the URI to be sold doesn't match the current URI of the token.
  /// @notice Reverts if one of the tokens is not owned by the seller or buyer.
  /// @param seller A struct containing details about the sell order.
  /// @param buyer A struct containing details about the buy order.
  /// @param projectDefaultUri The default URI value for the project.
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    string calldata projectDefaultUri
  ) external;

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param createCollectionParams Packed parameters
  /// * templateIds The IDs of the selected templates to use for creating the collections.
  /// * collectionIds The IDs of the next collections ids for the templates
  /// * totalSupplies The total supplies of tokens for the new collections.
  /// @param signatures The signatures created using the given parameters and signed by the signer.
  /// Second dimension includes, each signatures of each variation.
  /// @param uris The URIs that will be assigned to the collections. Second dimension includes variations.
  function createCollections(
    uint256 projectId,
    address signer,
    CreateCollectionParams calldata createCollectionParams,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external;

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param templateIds The IDs of the selected templates to use for creating the collections.
  /// @param totalSupplies The total supplies of tokens for the new collections.
  function createCollectionsWithoutURIs(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint16[] calldata totalSupplies
  ) external;

  /// Registers ERC721-Collections to the contract. URI slots to can be added to the NFTs.
  /// Collection has to be represented by a chosen template.
  /// @param tokenContract ERC721 contract address
  /// @param templateUri Chosen template URI that represents the collection.
  function registerExternalCollection(address tokenContract, string calldata templateUri) external;

  /// Removes the lock on the NFT that prevents to have slots.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param tokenId token id
  function unlockFreeMintNFT(MintIdParams calldata mintIdParams, uint256 tokenId) external;

  /// @return token uri, for the given token id
  function tokenURI(uint256 tokenId) external view returns (string memory);

  /// Every project will be able to place a slot to tokens if owners want
  /// These slots will store the uri that refers 'something' on the project
  /// Slots are viewable by other projects but modifiable only by the owner of the token who has a valid signature by the project
  /// @notice Returns the project URI for the given token ID
  /// @param tokenId The ID of the token whose project URI is to be returned
  /// @param projectId The ID of the project associated with the given token
  /// @return The URI of the given token's project slot
  function tokenProjectURI(
    address collectionAddress,
    uint256 tokenId,
    uint256 projectId
  ) external returns (string memory);

  /// @return Collection template uri
  function externalCollectionURI(address collectionAddress) external view returns (string memory);

  /// @return receiver is the royalty receiver address
  /// @return royaltyAmount the percentage of royalty
  function royaltyInfo(
    uint256, /*_tokenId*/
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);

  /// @notice This function returns the last collection ID for a given project and template.
  /// @param projectId The ID of the project to get the last collection ID for
  /// @param templateId The ID of the template to get the last collection ID for
  /// @return The last collection ID for the given project and template
  function getProjectLastCollectionId(uint256 projectId, uint256 templateId) external view returns (uint256);

  /// @notice This function checks whether a given token has been assigned a slot for a given project.
  /// @param tokenId The ID of the token to check
  /// @param projectId The ID of the project to check
  /// @return isAdded true if the given token has been assigned a slot for the given project, false otherwise
  function isSlotAddedForProject(
    address contractAddress,
    uint256 tokenId,
    uint256 projectId
  ) external view returns (bool isAdded);

  /// @return Returns true if the token is minted for free.
  function getIsFreeMinted(uint256 tokenId) external view returns (bool);

  /// The function getProjectCollection is used to retrieve the details of a specific collection that was created by a registered project.
  /// @param templateId The ID of the template used to create the collection.
  /// @param projectId The ID of the project that created the collection.
  /// @param collectionId  The ID of the collection.
  /// @return _projectId The ID of the project that created the collection.
  /// @return _templateId The ID of the template used to create the collection.
  /// @return _totalSupply The total number of tokens in the collection.
  /// @return _collectionId The ID of the collection.
  /// @return _minTokenId The minimum token ID in the collection.
  /// @return _maxTokenId The maximum token ID in the collection.
  /// @return _mintCount The number of tokens that have been minted for this collection.
  /// @return _collectionURI The URI associated with the collection.
  function getProjectCollection(
    uint256 templateId,
    uint256 projectId,
    uint256 collectionId
  )
    external
    view
    returns (
      uint256 _projectId,
      uint256 _templateId,
      uint256 _totalSupply,
      uint256 _collectionId,
      uint256 _minTokenId,
      uint256 _maxTokenId,
      uint256 _mintCount,
      string[] memory _collectionURI
    );

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  error ExceedsLimit();
  error InvalidTemplateId();
  error InvalidVariation();
  error UnexsistingTokenMint();
  error NotEnoughSupply();
  error VerificationFailed();
  error InvalidIdAmount();
  error InvalidId(uint256 templateId, uint256 collectionId);
  error UnexistingToken();
  error NotOwner();
  error ProjectIdZero();
  error AddedSlot();
  error UriSLotUnexist();
  error UsedSignature();
  error CallerNotAuthorized();
  error InvalidCollectionId();
  error InvalidContractAddress();
  error LockedNFT(uint256 tokenId);
  error SellerIsNotOwner();
  error BuyerIsNotOwner();
  error InvalidTokenAddress();
  error NonERC721Implementer();
  error InvalidTokenId();
  error GivenTokenAddressNotRegistered();
  error SellerGivenURIMismatch();
  error CollectionIsNotFreeForMint();
  error LengthMismatch();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {CreateCollectionParams, MintBatchParams, MintIdParams, SellOrder, BuyOrder} from "../../lib/mQuarkStructs.sol";

interface ImQuarkControl {
  event AdminWalletSet(address admin, uint256 time);
  // Emitted when a wallet is authorized or unauthorized to register projects
  event AuthorizedToRegisterWalletSet(address wallet, bool isAuthorized);
  // Emitted when funds are deposited into multiple projects at once
  event BatchSlotFundsDeposit(
    uint256 amount,
    uint256 projectPercentage,
    uint256[] projectIds,
    uint256[] projectsShares
  );
  // Emitted when the creator's percentage is set
  event CreatorPercentageSet(uint256 percentage);
  // Emitted when funds are deposited into a project
  event FundsDeposit(uint256 amount, uint256 projectPercentage, uint256 projectId);
  // Emitted when funds are withdrawn from the protocol
  event FundsWithdrawn(address mquark, uint256 amount);
  // Emitted when mQuark tokens are minted and deposited into multiple projects at once
  event MintBatchSlotFundsDeposit(
    uint256 amount,
    uint256 projectPercentage,
    uint256[] projectIds,
    uint256[] projectsShares
  );
  // Emitted when the mQuark contract is set
  event MQuarkSet(address mquark);
  // Emitted when a project is registered
  event ProjectRegistered(
    address project,
    address creator,
    uint256 projectId,
    string projectName,
    string creatorName,
    string description,
    string thumbnail,
    string projectDefaultSlotURI,
    uint256 slotPrice
  );
  // Emitted when funds are withdrawn from a project
  event ProjectFundsWithdrawn(uint256 projectId, uint256 amount);
  // Emitted when a project is removed
  event ProjectRemoved(uint256 projectId);
  // Emitted when the price of a slot is set
  event SlotPriceSet(uint256 projectId, uint256 price);
  // Emitted when the prices of templates are set
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);
  // Event for when a template is created
  event TemplateCreated(uint256 templateId, string uri);
  // Emitted when a token is transferred from one project to another with a URI
  event TokenProjectUriTransferred(
    uint256 fromTokenId,
    uint256 toTokenId,
    uint256 projectId,
    uint256 price,
    string uri,
    address from,
    address to
  );
  event NFTUnlocked(uint256 projectId, uint256 templateId, uint256 collectionId, uint256 tokenId);

  /// @notice Creates a new template with the given URI, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uri The metadata URI that will represent the template.
  function createTemplate(string calldata uri) external;

  /// @notice Creates multiple templates with the given URIs, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uris The metadata URIs that will represent the templates.
  function createBatchTemplate(string[] calldata uris) external;

  /// Checks the validity of given parameters and whether paid ETH amount is valid
  /// Makes a call to mQuark contract to mint single NFT.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mint(MintIdParams calldata mintIdParams, uint256 variationId) external payable;

  /// Checks the validity of given parameters and whether paid ETH amount is valid
  /// Makes a call to mQuark contract to mint single NFT with given validated URI.
  /// @param signer registered project address of the given collection
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature the signed data includes the required parameters
  /// @param uri the uri for the NFT
  function mintWithURI(
    address signer,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external payable;

  /// Makes a call to mQuark contract to mint multiple NFT.
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param mintBatchParams Struct for the mint batch functions
  /// * projectId collection owner's project id
  /// * templateIds_ collection's inherited template's id
  /// * collectionIds collection id for its template
  /// * variationIds collection's variation id
  /// * totalSupplies the number of mint amounts from each collection
  function mintBatch(MintBatchParams calldata mintBatchParams) external payable;

  /// Makes a call to mQuark contract to mint multiple NFTs with a single specified uri slot
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param mintBatchParams Struct for the mint batch functions
  /// * projectId collection owner's project id
  /// * templateIds_ collection's inherited template's id
  /// * collectionIds collection id for its template
  /// * variationIds collection's variation id
  /// * totalSupplies the number of mint amounts from each collection
  function mintBatchWithURISlot(MintBatchParams calldata mintBatchParams) external payable;

  /// Makes a call to mQuark contract to mint single NFT with multiple specified metadata slots.
  /// Performs mint operation with a single given projects uri slots for every token.
  /// @dev mint price is considered at zero index!
  /// @param projectIds collection owner's project id
  /// @param templateId collection's inherited template's id
  /// @param collectionId collection id for its template
  /// @param variationId collection's variation id
  function mintWithURISlots(
    uint256[] calldata projectIds,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external payable;

  /// Makes a call to mQuark contract to add single NFT uri slot to a single NFT
  /// @notice Slot's initial state will be pre-filled with project's default uri
  /// @param tokenId the token id to which the slot will be added
  /// @param projectId slot's project's id
  function addURISlotToNFT(
    address tokenContract,
    uint256 tokenId,
    uint256 projectId
  ) external payable;

  /// Makes a call to mQuark contract to add multiple metadata slots to single NFT
  /// Adds different multiple uri slots to a single token
  /// @notice Reverts the number of given projects are more than 256
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenContract contract address of the given token.(External contract or mQuark)
  /// @param tokenId the token id to which the slot will be added
  /// @param projectIds slots' project ids
  function addBatchURISlotsToNFT(
    address tokenContract,
    uint256 tokenId,
    uint256[] calldata projectIds
  ) external payable;

  /// Makes a call to mQuark contract to add the same single uri slot to multiple NFTs
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenContracts contract addresess of the given tokens.(External contract or mQuark)
  /// @param tokenIds the token ids to which the slot will be added
  /// @param projectId slot's project's id
  function addBatchURISlotToNFTs(
    address[] calldata tokenContracts,
    uint256[] calldata tokenIds,
    uint256 projectId
  ) external payable;

  /// "updateInfo" is used as bytes because token owners will have only one parameter rather than five parameters.
  /// Makes a call to mQuark contract to update a given uri slot
  /// Updates the project's slot uri of a single token
  /// @notice Project should sign the upated URI with their private key
  /// @param signature signed data by project's private key
  /// @param updateInfo encoded data
  /// * project address of the project that is responsible for the slot
  /// * projectId id of the project
  /// * tokenContract contract address of the given token.(External contract or mQuark)
  /// * tokenId token id
  /// * updatedUri the newly generated URI for the token
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external;

  /// Makes a call to mQuark tı transfers a project slot uri of a single token to another token's the same project slot
  /// @notice If orders doesn't match, it reverts
  /// @param seller the struct that contains sell order details
  /// @param buyer the struct that contains buy order details
  /// @param sellerSignature signed data by seller's private key
  /// @param buyerSignature signed data by buyer's private key
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable;

  /// Makes a call to mQuark contract to create collections
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId project id of the collection creator.(registered to the contract)
  /// @param createCollectionParams Struct for the function parameters
  /// * templateIds selected template ids to create the collections
  /// * collectionIds next generated collection ids
  /// * totalSupplies collections' total supplies
  /// @param collectionPrices mint prices for the collection, can't be lower than their templates prices
  /// @param signatures signatures that are created by given parameters signed by signer
  /// @param uris the uris that will be assigned to collections
  function createCollections(
    uint256 projectId,
    CreateCollectionParams calldata createCollectionParams,
    uint256[] calldata collectionPrices,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external;

  /// Makes a call to mQuark contract to create collections without given collection URI
  /// Users can mint unlimited number of variations from the collection
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId project id of the collection creator.(registered to the contract)
  /// @param createCollectionParams Struct for the function parameters
  /// * templateIds selected template ids to create the collections
  /// * collectionIds next generated collection ids
  /// * totalSupplies collections' total supplies
  /// @param collectionPrices mint prices for the collection, can't be lower than their templates prices
  function createBatchCollectionWithoutURIs(
    uint256 projectId,
    CreateCollectionParams calldata createCollectionParams,
    uint256[] calldata collectionPrices
  ) external;

  /// Projets are registered to the contract
  /// @param project wallet address
  /// @param creator creator wallet of the project
  /// @param projectName project name
  /// @param creatorName creator name of the project
  /// @param thumbnail thumbnail url
  /// @param projectSlotDefaultURI the uri that will be assigned to project slot initially
   /// @param slotPrice slot price for the project
  function registerProject(
    address project,
    address creator,
    string calldata projectName,
    string calldata creatorName,
    string calldata description,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI,
    uint256 slotPrice
  ) external;

  /// Removes the registered project from the contract
  /// @param projectId if of the registered project
  function removeProject(uint256 projectId) external;

  /// External ERC721-NFT Contracts can be registered to the contract to get tokens upgradable.
  /// @param externalCollectionContract address of the ERC721-NFT collection
  /// @param templateId the selected template for their entire collection.
  function registerExternalCollection(address externalCollectionContract, uint256 templateId) external;

  /// Sets the contract address of deployed mQuark contract
  /// @param mQuarkAddr address of mQuark Contract
  function setmQuark(address mQuarkAddr) external;

  /// Sets a wallet as an authorized or unauthorized to register projects
  /// @param wallet wallet address that will be set
  /// @param isAuthorized boolean value(true is authorized, false is unauthorized)
  function setAuthorizedToRegister(address wallet, bool isAuthorized) external;

  /// Sets Templates mint prices(wei)
  /// @notice Collections inherit the template's mint price
  /// @param templateIds_: IDs of Templates which are categorized NFTs
  /// @param prices: Prices of each given templates in wei unit
  function setTemplatePrices(uint256[] calldata templateIds_, uint256[] calldata prices) external;

  /// Sets projects percantage from minting and uri slot purchases
  /// @notice percentage should be between 0-100
  /// @param percentage: Percantage amount
  function setCreatorPercentage(uint256 percentage) external;

  /// Sets a project's uri slot price for every NFT minted
  /// @param projectId project id
  /// @param price slot price in wei
  function setProjectURISlotPrice(uint256 projectId, uint256 price) external;

  /// Sets given address as verifier, this address is sent to mQuark contract to verify signatures
  function setVerifierAddress(address addr) external;

  /// Sets admin wallet address
  function setAdminWallet(address addr) external;

  /// Unlocks a free minted NFT's upgradability.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param tokenId token id
  function unlockFreeMintNFT(MintIdParams calldata mintIdParams, uint256 tokenId) external payable;

  /// Contract admin transfers its balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param amount amount of funds that will be transferred in wei
  function transferFunds(uint256 amount) external;

  /// Projects transfers their balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param project project registered wallet address
  /// @param amount amount of funds that will be transferred in wei
  function projectTransferFunds(
    address payable project,
    uint256 projectId,
    uint256 amount
  ) external;

  /// Calculates mint base price
  /// @param templateIds_ template id of tokens
  /// @param amounts amount of each template ids
  /// @return totalPrice calculated total price amount of ids for a project
  function totalPriceMintBatch(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external view returns (uint256 totalPrice);

  /// Calculates total price of batch same slot uri purchases
  /// @param tokenAmounts token amounts for each template
  /// @param projectId slot's project Id
  function totalPriceBatchAddProjectSlot(uint256 projectId, uint8[] calldata tokenAmounts)
    external
    view
    returns (uint256 totalPrice);

  /// Multiple (tokens^slot))
  /// Calculate total price of mint batch tokens with single slot uri
  /// @param projectId slot's project Id
  /// @param templateIds_ template id of tokens
  /// @param amounts amount of each template ids
  function totalPriceMintBatchWithSingleSlotForEach(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external view returns (uint256);

  /// Single (token^slots)
  /// Calculates total price of a mint with multiple slots
  function totalPriceMintWithSlots(uint256[] calldata projectIds, uint256 templateId) external view returns (uint256);

  /// Returns project's balance
  function getProjectBalance(uint256 projectId) external view returns (uint256);

  /// Returns project's collection price
  function getProjectCollectionPrice(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId
  ) external view returns (uint256);

  /// Returns registered project
  /// @return wallet project wallet address
  /// @return creator project creator address
  /// @return id project id
  /// @return balance project balance
  /// @return name project name
  /// @return thumbnail project thumbnail
  /// @return projectSlotDefaultURI project slot default uri
  function getRegisteredProject(uint256 projectId)
    external
    view
    returns (
      address wallet,
      address creator,
      uint256 id,
      uint256 balance,
      string memory name,
      string memory thumbnail,
      string memory projectSlotDefaultURI
    );

  /// Templates defines what a token is. Every template id has its own properties and attributes.
  /// Collections are created by templates. Inherits the properties and attributes of the template.
  /// @param templateId template id
  /// @return template's uri
  function templateUri(uint256 templateId) external view returns (string memory);

  /// Returns given project's id
  /// @param projectAddr project wallet address
  function getProjectId(address projectAddr) external view returns (uint256);

  /// Returns whethere a given address is authorized to register a project
  function getAuthorizedToRegisterProject(address addr) external view returns (bool);

  /// Returns template mint price
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256);

  /// Returns project slot price
  function getProjectSlotPrice(uint256 projectId) external view returns (uint256);

  /// @notice This function returns the total number of templates that have been created.
  /// @return The total number of templates that have been created
  function getCreatedTemplateIds() external view returns (uint256);

  error NotImQuarkContract();
  error NotOwner();
  error ExceedsLimit();
  error CallerNotAuthorized();
  error GivenProjectIdNotExist();
  error SentAmountIsZero();
  error InvalidSentAmount();
  error ProjectIdAndSignerMismatch();
  error TemplatesExceedsMintLimit();
  error MintingMoreThanLimit();
  error InvalidProjectAddress();
  error InvalidProjectId();
  error UnauthorizedToTransfer();
  error PriceMismatch();
  error TokenMismatch();
  error GivenProjectIdMismatch();
  error SellerAddressMismatch();
  error UriMismatch();
  error SellerIsNotTheSigner();
  error BuyerIsNotTheSigner();
  error FailedToSentEther();
  error TemplatesExceedsLimit();
  error ArrayLengthMismatch();
  error InvalidCollectionPrice();
  error InvalidTemplate(uint256 templateId);
  error InvalidTotalSupply(uint256 totalSupply);
  error ProjectAlreadyRegistered(address projectAddress);
  error AlreadySet(address mQuark);
  error InvalidPercentage();
  error InsufficientBalance();
  error InvalidZeroValue();
  error SlotValueIsZero();
  error MintingFreeNFT();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

    // /**
    //  * @dev Returns the number of tokens in ``owner``'s account.
    //  */
    // function balanceOf(address owner) external view returns (uint256 balance);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.17;

import "./IERC721.sol";

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
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../interfaces/IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {CreateCollectionParams, MintBatchParams, MintIdParams, Project} from "../lib/mQuarkStructs.sol";
import "../interfaces/mQuark/ImQuark.sol";
import "../interfaces/mQuark/ImQuarkControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title mQuark Control
/// mQuark protocol's Wapper contract. Registers projects, manages balances and withdrawals.
/// @notice Projects are registered here. This contract is the only one that can mint mQuark tokens.
/// @notice This contract is also the only one that can withdraw funds from the protocol.
contract mQuarkControl is ImQuarkControl, ReentrancyGuard, PullPayment, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  //* ===================================================================================================
  //*                                          STATE VARIABLES
  //* ===================================================================================================

  /// @dev The admin address of the contract
  address public adminWallet;

  /// @dev The last registered project ID
  uint256 public projectIdIndex;

  /// @dev The percentage of funds that go to projects from mints and slot purchases
  uint256 public projectPercentage;

  /// @dev The percentage of funds that go to the contract admin from mints and slot purchases
  uint256 public adminPercentage;

  /// @dev Keeps track of the last created template id
  uint256 public templateIdCounter;

  /// @dev Limits the selected templates to prevent out of gas errors
  uint32 constant MAX_SELECTING_LIMIT = 100000;

  /// @dev The ERC721 contract interface
  ImQuark public mQuark;

  /// @dev The wallet addresses of projects registered with the contract
  EnumerableSet.AddressSet private projectWallets;

  /// @dev Stores the ids of created templates
  EnumerableSet.UintSet private templateIds;

  /// @dev The address of the verifier, who signs collection URIs
  address public verifier;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  /// @dev This role grants access to register projects
  bytes32 public constant AUTHORIZED_REGISTERER_ROLE = keccak256("AUTHORIZED_REGISTERER");

  /// @dev This role is the admin of the CONTROL_ROLE
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @dev This role has access to control the contract configurations.
  bytes32 public constant CONTROL_ROLE = keccak256("CONTROL_ROLE");

  //* =========================== MAPPINGS ==============================================================

  // mapping from 'admin address' to balance
  mapping(address => uint256) public adminBalance;

  // mapping from 'project id' to 'project struct'
  mapping(uint256 => Project) private _registeredProjects;

  // mapping from project address to 'project id'
  mapping(address => uint256) private _projectIds;

  // mapping from 'template id' to 'mint price' in wei
  mapping(uint256 => uint256) private _templateMintPrices;

  // mapping from 'project id' to 'project uri slot price' in wei
  mapping(uint256 => uint256) private _projectSlotPrices;

  mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _collectionPrices;

  /// @dev Mapping from a 'template id' to a 'template URI'
  mapping(uint256 => string) private _templateURIs;

  //* ======================== MODIFIERS ================================================================

  modifier onlyOwners(uint256 projectId) {
    if (_registeredProjects[projectId].creator != msg.sender && _registeredProjects[projectId].wallet != msg.sender)
      revert NotOwner();
    _;
  }

  //* ==================================================================================================
  //*                                           CONSTRUCTOR
  //* ==================================================================================================

  constructor() {
    adminWallet = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(CONTROL_ROLE, msg.sender);
    _setRoleAdmin(CONTROL_ROLE, ADMIN_ROLE);
  }

  //* ======================= TEMPLATE Creation ========================================================

  //* ===================================================================================================

  /// @notice Creates a new template with the given URI, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uri The metadata URI that will represent the template.
  function createTemplate(string calldata uri) external onlyRole(CONTROL_ROLE) {
    uint256 _templateId = ++templateIdCounter;

    _templateURIs[_templateId] = uri;

    templateIds.add(_templateId);

    emit TemplateCreated(_templateId, uri);
  }

  /// @notice Creates multiple templates with the given URIs, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uris The metadata URIs that will represent the templates.
  function createBatchTemplate(string[] calldata uris) external onlyRole(CONTROL_ROLE) {

    uint256 _urisLength = uris.length;
    if (_urisLength > 255) revert ExceedsLimit();


    uint256 _templateId = templateIdCounter;

    for (uint8 i = 0; i < _urisLength; ) {
      ++_templateId;

      _templateURIs[_templateId] = uris[i];

      templateIds.add(_templateId);

      emit TemplateCreated(_templateId, uris[i]);

      unchecked {
        ++i;
      }
    }

    templateIdCounter = _templateId;
  }

  //* ==================================================================================================
  //*                                         EXTERNAL Functions
  //* ==================================================================================================

  /// Checks the validity of given parameters and whether paid ETH amount is valid
  /// Makes a call to mQuark contract to mint single NFT.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param variationId variation id for the collection. (0 for the static typed collection)
  function mint(MintIdParams calldata mintIdParams, uint256 variationId) external payable nonReentrant {
    if (_registeredProjects[mintIdParams.projectId].id == 0) revert GivenProjectIdNotExist();
    if (msg.value == 0) revert SentAmountIsZero();
    if (msg.value != _collectionPrices[mintIdParams.projectId][mintIdParams.templateId][mintIdParams.collectionId])
      revert InvalidSentAmount();

    mQuark.mint(msg.sender, mintIdParams, variationId);

    _registeredProjects[mintIdParams.projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, projectPercentage, mintIdParams.projectId);
  }

  /// Checks the validity of given parameters and whether paid ETH amount is valid
  /// Makes a call to mQuark contract to mint single NFT with given validated URI.
  /// @param signer registered project address of the given collection
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param signature the signed data includes the required parameters
  /// @param uri the uri for the NFT
  function mintWithURI(
    address signer,
    MintIdParams calldata mintIdParams,
    bytes calldata signature,
    string calldata uri
  ) external payable nonReentrant {
    if (_registeredProjects[mintIdParams.projectId].id == 0) revert GivenProjectIdNotExist();
    if (_projectIds[signer] != mintIdParams.projectId) revert ProjectIdAndSignerMismatch();
    if (msg.value == 0) revert SentAmountIsZero();
    if (msg.value != _collectionPrices[mintIdParams.projectId][mintIdParams.templateId][mintIdParams.collectionId])
      revert InvalidSentAmount();

    mQuark.mintWithPreURI(signer, msg.sender, mintIdParams, signature, uri);

    _registeredProjects[mintIdParams.projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, projectPercentage, mintIdParams.projectId);
  }

  /// Makes a call to mQuark contract to mint multiple NFT.
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param mintBatchParams Struct for the mint batch functions
  /// * projectId collection owner's project id
  /// * templateIds_ collection's inherited template's id
  /// * collectionIds collection id for its template
  /// * variationIds collection's variation id
  /// * totalSupplies the number of mint amounts from each collection
  function mintBatch(MintBatchParams calldata mintBatchParams) external payable nonReentrant {
    if (_registeredProjects[mintBatchParams.projectId].id == 0) revert GivenProjectIdNotExist();
    if (mintBatchParams.templateIds.length != mintBatchParams.totalSupplies.length) revert ArrayLengthMismatch();
    if (mintBatchParams.templateIds.length > 20) revert TemplatesExceedsMintLimit();
    if (
      this.totalPriceMintBatch(
        mintBatchParams.projectId,
        mintBatchParams.templateIds,
        mintBatchParams.collectionIds,
        mintBatchParams.totalSupplies
      ) != msg.value
    ) revert InvalidSentAmount();
    if (msg.value == 0) revert SentAmountIsZero();

    mQuark.mintBatch(msg.sender, mintBatchParams);
    _registeredProjects[mintBatchParams.projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[adminWallet] += (msg.value * (adminPercentage)) / 100;

    emit FundsDeposit(msg.value, projectPercentage, mintBatchParams.projectId);
  }

  /// Makes a call to mQuark contract to mint multiple NFTs with a single specified uri slot
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param mintBatchParams Struct for the mint batch functions
  /// * projectId collection owner's project id
  /// * templateIds_ collection's inherited template's id
  /// * collectionIds collection id for its template
  /// * variationIds collection's variation id
  /// * totalSupplies the number of mint amounts from each collection
  function mintBatchWithURISlot(MintBatchParams calldata mintBatchParams) external payable nonReentrant {
    if (mintBatchParams.templateIds.length != mintBatchParams.collectionIds.length) revert ArrayLengthMismatch();
    if (mintBatchParams.templateIds.length != mintBatchParams.totalSupplies.length) revert ArrayLengthMismatch();
    if (_registeredProjects[mintBatchParams.projectId].id == 0) revert GivenProjectIdNotExist();
    if (
      this.totalPriceMintBatchWithSingleSlotForEach(
        mintBatchParams.projectId,
        mintBatchParams.templateIds,
        mintBatchParams.collectionIds,
        mintBatchParams.totalSupplies
      ) != msg.value
    ) revert InvalidSentAmount();

    mQuark.mintBatchWithURISlot(
      msg.sender,
      mintBatchParams,
      _registeredProjects[mintBatchParams.projectId].projectSlotDefaultURI
    );

    _registeredProjects[mintBatchParams.projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[adminWallet] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, projectPercentage, mintBatchParams.projectId);
  }

  /// Makes a call to mQuark contract to mint single NFT with multiple specified metadata slots.
  /// Performs mint operation with a single given projects uri slots for every token.
  /// @dev mint price is considered at zero index!
  /// @param projectIds collection owner's project id
  /// @param templateId collection's inherited template's id
  /// @param collectionId collection id for its template
  /// @param variationId collection's variation id
  function mintWithURISlots(
    uint256[] calldata projectIds,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external payable nonReentrant {
    if (projectIds.length > 255) revert MintingMoreThanLimit();
    if (_collectionPrices[projectIds[0]][templateId][collectionId] == 0) revert MintingFreeNFT();

    string[] memory _projectSlotDefaultUris = new string[](projectIds.length);
    uint256 _totalPriceUriSlots;
    uint256 _priceUriSlot;
    uint256[] memory _projectsMetedataPriceShares = new uint256[](projectIds.length);
    uint256 projectCount = projectIds.length;

    for (uint8 i = 0; i < projectCount; ) {
      if (_registeredProjects[projectIds[i]].id == 0) revert GivenProjectIdNotExist();
      _priceUriSlot = _projectSlotPrices[projectIds[i]];
      _projectSlotDefaultUris[i] = (_registeredProjects[projectIds[i]].projectSlotDefaultURI);
      if(_priceUriSlot != 0) {
        _totalPriceUriSlots += _priceUriSlot;
        _registeredProjects[projectIds[i]].balance += (_priceUriSlot * projectPercentage) / 100;
      }
      _projectsMetedataPriceShares[i] = _priceUriSlot;
      unchecked {
        ++i;
      }
    }

    uint256 _mintCost = _collectionPrices[projectIds[0]][templateId][collectionId];

    if (msg.value != (_totalPriceUriSlots + _mintCost)) revert InvalidSentAmount();

    mQuark.mintWithURISlots(msg.sender, templateId, collectionId, variationId, projectIds, _projectSlotDefaultUris);
    _registeredProjects[projectIds[0]].balance += ((_mintCost * projectPercentage) / 100);
    adminBalance[adminWallet] += ((msg.value * adminPercentage) / 100);

    emit MintBatchSlotFundsDeposit(msg.value, projectPercentage, projectIds, _projectsMetedataPriceShares);
  }

  //* ================================================================================================

  //* =========================== URI SLOT Functions =================================================

  /// Makes a call to mQuark contract to add single NFT uri slot to a single NFT
  /// @notice Slot's initial state will be pre-filled with project's default uri
  /// @param tokenId the token id to which the slot will be added
  /// @param projectId slot's project's id
  function addURISlotToNFT(
    address tokenContract,
    uint256 tokenId,
    uint256 projectId
  ) external payable nonReentrant {
    if (_registeredProjects[projectId].id == 0) revert GivenProjectIdNotExist();
    if (_projectSlotPrices[projectId] != msg.value) revert InvalidSentAmount();
    mQuark.addURISlotToNFT(
      msg.sender,
      tokenContract,
      tokenId,
      projectId,
      _registeredProjects[projectId].projectSlotDefaultURI
    );
    if(msg.value != 0) {
      _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
      adminBalance[adminWallet] += (msg.value * adminPercentage) / 100;
    }
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to add multiple metadata slots to single NFT
  /// Adds different multiple uri slots to a single token
  /// @notice Reverts the number of given projects are more than 256
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenContract contract address of the given token.(External contract or mQuark)
  /// @param tokenId the token id to which the slot will be added
  /// @param projectIds slots' project ids
  function addBatchURISlotsToNFT(
    address tokenContract,
    uint256 tokenId,
    uint256[] calldata projectIds
  ) external payable nonReentrant {
    string[] memory projectSlotDefaultUris = new string[](projectIds.length);
    uint256 _price;
    uint256 _totalAmount;
    uint256[] memory _projectsShares = new uint256[](projectIds.length);
    uint256 _projects = projectIds.length;

    for (uint256 i = 0; i < _projects; ) {
      if (_registeredProjects[projectIds[i]].id == 0) revert GivenProjectIdNotExist();

      _price = _projectSlotPrices[projectIds[i]];
      projectSlotDefaultUris[i] = (_registeredProjects[projectIds[i]].projectSlotDefaultURI);
      if(_price != 0) {
        _totalAmount += _price;
        _registeredProjects[projectIds[i]].balance += (_price * projectPercentage) / 100;
      }
      _projectsShares[i] = _price;
      unchecked {
        ++i;
      }
    }

    if(msg.value != _totalAmount) revert InvalidSentAmount();
    mQuark.addBatchURISlotsToNFT(msg.sender, tokenContract, tokenId, projectIds, projectSlotDefaultUris);
    if(msg.value != 0) {
      adminBalance[adminWallet] += (msg.value * adminPercentage) / 100;
    }
    emit BatchSlotFundsDeposit(msg.value, projectPercentage, projectIds, _projectsShares);
  }

  /// Makes a call to mQuark contract to add the same single uri slot to multiple NFTs
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenContracts contract addresess of the given tokens.(External contract or mQuark)
  /// @param tokenIds the token ids to which the slot will be added
  /// @param projectId slot's project's id
  function addBatchURISlotToNFTs(
    address[] calldata tokenContracts,
    uint256[] calldata tokenIds,
    uint256 projectId
  ) external payable nonReentrant {
    if (_registeredProjects[projectId].id == 0) revert GivenProjectIdNotExist();
    if ((_projectSlotPrices[projectId] * tokenIds.length) != msg.value) revert InvalidSentAmount();

    mQuark.addBatchURISlotToNFTs(
      msg.sender,
      tokenContracts,
      tokenIds,
      projectId,
      _registeredProjects[projectId].projectSlotDefaultURI
    );
    if(msg.value != 0) {
      _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
      adminBalance[adminWallet] += (msg.value * adminPercentage) / 100;
    }
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// "updateInfo" is used as bytes because token owners will have only one parameter rather than five parameters.
  /// Makes a call to mQuark contract to update a given uri slot
  /// Updates the project's slot uri of a single token
  /// @notice Project should sign the upated URI with their wallet
  /// @param signature signed data by project's wallet
  /// @param updateInfo encoded data
  /// * project address of the project that is responsible for the slot
  /// * projectId id of the project
  /// * tokenContract contract address of the given token.(External contract or mQuark)
  /// * tokenId token id
  /// * updatedUri the newly generated URI for the token
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external {
    (address project, uint256 projectId, address tokenContract, uint256 tokenId, string memory updatedUri) = abi.decode(
      updateInfo,
      (address, uint, address, uint, string)
    );
    Project memory _registeredProject = _registeredProjects[projectId];

    if (_registeredProject.id == 0) revert InvalidProjectId();
    if (_registeredProject.wallet != project) revert InvalidProjectAddress();

    mQuark.updateURISlot(msg.sender, signature, project, projectId, tokenContract, tokenId, updatedUri);
  }

  /// Makes a call to mQuark tı transfers a project slot uri of a single token to another token's the same project slot
  /// @notice If orders doesn't match, it reverts
  /// @param seller the struct that contains sell order details
  /// @param buyer the struct that contains buy order details
  /// @param sellerSignature signed data by seller's wallet
  /// @param buyerSignature signed data by buyer's wallet
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable nonReentrant {
    if (msg.sender != buyer.buyer) revert UnauthorizedToTransfer();
    if (seller.sellPrice != buyer.buyPrice) revert PriceMismatch();
    if (msg.value != buyer.buyPrice) revert InvalidSentAmount();
    if (seller.fromTokenId != buyer.fromTokenId) revert TokenMismatch();
    if (seller.projectId != buyer.projectId) revert GivenProjectIdMismatch();
    if (seller.seller != buyer.seller) revert SellerAddressMismatch();
    // Check that the URI values for the sell and buy orders match.
    if (keccak256(abi.encodePacked(seller.slotUri)) != keccak256(abi.encodePacked(buyer.slotUri))) revert UriMismatch();

    // Calculate the message hash for the sell order using the `keccak256` function.
    bytes32 _messageHash = keccak256(
      abi.encode(
        seller.seller,
        seller.fromContractAddress,
        seller.fromTokenId,
        seller.projectId,
        seller.slotUri,
        seller.sellPrice
      )
    );

    bytes32 _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    address _signer = ECDSA.recover(_signed, sellerSignature);

    if (seller.seller != _signer) revert SellerIsNotTheSigner();
    // Calculate the message hash for the sell order using the `keccak256` function.
    _messageHash = keccak256(
      abi.encode(
        buyer.buyer,
        buyer.seller,
        buyer.fromContractAddress,
        buyer.fromTokenId,
        buyer.toContractAddress,
        buyer.toTokenId,
        buyer.projectId,
        buyer.slotUri,
        buyer.buyPrice
      )
    );

    _signed = ECDSA.toEthSignedMessageHash(_messageHash);
    _signer = ECDSA.recover(_signed, buyerSignature);
    if (buyer.buyer != _signer) revert BuyerIsNotTheSigner();

    string memory defualtProjectSlotUri = _registeredProjects[seller.projectId].projectSlotDefaultURI;

    mQuark.transferTokenProjectURI(seller, buyer, defualtProjectSlotUri);

    (bool sent, ) = seller.seller.call{value: msg.value}("");
    if (!sent) revert FailedToSentEther();

    emit TokenProjectUriTransferred(
      seller.fromTokenId,
      buyer.toTokenId,
      seller.projectId,
      seller.sellPrice,
      seller.slotUri,
      seller.seller,
      buyer.buyer
    );
  }

  //* ================================================================================================

  //* ==================================COLLECTION Creation===========================================

  /// Makes a call to mQuark contract to create collections
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId project id of the collection creator.(registered to the contract)
  /// @param createCollectionParams Struct for the function parameters
  /// * templateIds selected template ids to create the collections
  /// * collectionIds next generated collection ids
  /// * totalSupplies collections' total supplies
  /// @param collectionPrices mint prices for the collection, can't be lower than their templates prices
  /// @param signatures signatures that are created by given parameters signed by signer
  /// @param uris the uris that will be assigned to collections
  function createCollections(
    uint256 projectId,
    CreateCollectionParams calldata createCollectionParams,
    uint256[] calldata collectionPrices,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external onlyOwners(projectId) {
    uint256 _templatesLength = createCollectionParams.templateIds.length;
    if (_templatesLength > 50) revert TemplatesExceedsLimit();
    if (_templatesLength != createCollectionParams.totalSupplies.length) revert ArrayLengthMismatch();
    if (_templatesLength != createCollectionParams.collectionIds.length) revert ArrayLengthMismatch();
    if (_templatesLength != signatures.length) revert ArrayLengthMismatch();
    if (_templatesLength != uris.length) revert ArrayLengthMismatch();
    if (_templatesLength != collectionPrices.length) revert ArrayLengthMismatch();

    uint32 _maxSelectingLimit = MAX_SELECTING_LIMIT;
    for (uint256 i = 0; i < _templatesLength; ) {
      if (
        (collectionPrices[i] < _templateMintPrices[createCollectionParams.templateIds[i]]) && (collectionPrices[i] != 0)
      ) revert InvalidCollectionPrice();
      if (_templateMintPrices[createCollectionParams.templateIds[i]] == 0)
        revert InvalidTemplate(createCollectionParams.templateIds[i]);
      if (createCollectionParams.totalSupplies[i] > _maxSelectingLimit)
        revert InvalidTotalSupply(createCollectionParams.totalSupplies[i]);
      if (signatures[i].length != uris[i].length) revert ArrayLengthMismatch();

      _collectionPrices[projectId][createCollectionParams.templateIds[i]][
        createCollectionParams.collectionIds[i]
      ] = collectionPrices[i];

      unchecked {
        ++i;
      }
    }

    mQuark.createCollections(projectId, verifier, createCollectionParams, signatures, uris);
  }

  /// Makes a call to mQuark contract to create collections without given collection URI
  /// Users can mint unlimited number of variations from the collection
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId project id of the collection creator.(registered to the contract)
  /// @param createCollectionParams Struct for the function parameters
  /// * templateIds selected template ids to create the collections
  /// * collectionIds next generated collection ids
  /// * totalSupplies collections' total supplies
  /// @param collectionPrices mint prices for the collection, can't be lower than their templates prices
  function createBatchCollectionWithoutURIs(
    uint256 projectId,
    CreateCollectionParams calldata createCollectionParams,
    uint256[] calldata collectionPrices
  ) external onlyOwners(projectId) {
    uint256 _templatesLength = createCollectionParams.templateIds.length;
    if (_templatesLength > 50) revert TemplatesExceedsLimit();
    if (_templatesLength != createCollectionParams.totalSupplies.length) revert ArrayLengthMismatch();
    if (_templatesLength != createCollectionParams.collectionIds.length) revert ArrayLengthMismatch();
    if (_templatesLength != collectionPrices.length) revert ArrayLengthMismatch();

    uint32 _maxSelectingLimit = MAX_SELECTING_LIMIT;
    for (uint256 i = 0; i < _templatesLength; ) {
      if (
        (collectionPrices[i] < _templateMintPrices[createCollectionParams.templateIds[i]]) && (collectionPrices[i] != 0)
      ) revert InvalidCollectionPrice();
      if (_templateMintPrices[createCollectionParams.templateIds[i]] == 0)
        revert InvalidTemplate(createCollectionParams.templateIds[i]);
      if (createCollectionParams.totalSupplies[i] > _maxSelectingLimit)
        revert InvalidTotalSupply(createCollectionParams.totalSupplies[i]);

      _collectionPrices[projectId][createCollectionParams.templateIds[i]][
        createCollectionParams.collectionIds[i]
      ] = collectionPrices[i];

      unchecked {
        ++i;
      }
    }

    mQuark.createCollectionsWithoutURIs(
      projectId,
      createCollectionParams.templateIds,
      createCollectionParams.totalSupplies
    );
  }

  //* ================================================================================================

  //* =========================== Project Registration ===============================================

  /// Projets are registered to the contract
  /// @param project wallet address
  /// @param creator creator wallet of the project
  /// @param projectName project name
  /// @param creatorName creator name of the project
  /// @param thumbnail thumbnail url
  /// @param projectSlotDefaultURI the uri that will be assigned to project slot initially
  /// @param slotPrice slot price for the project
  function registerProject(
    address project,
    address creator,
    string calldata projectName,
    string calldata creatorName,
    string calldata description,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI,
    uint256 slotPrice
  ) external onlyRole(AUTHORIZED_REGISTERER_ROLE) {
    if (projectWallets.contains(project)) revert ProjectAlreadyRegistered(project);

    unchecked {
      uint256 _projectId = ++projectIdIndex;
      _registeredProjects[_projectId] = Project(
        project,
        creator,
        _projectId,
        _registeredProjects[_projectId].balance,
        projectName,
        description,
        thumbnail,
        projectSlotDefaultURI
      );
      projectWallets.add(project);
      _projectIds[project] = _projectId;
      _projectSlotPrices[_projectId] = slotPrice;
      emit ProjectRegistered(
        project,
        creator,
        _projectId,
        projectName,
        creatorName,
        description,
        thumbnail,
        projectSlotDefaultURI,
        slotPrice
      );
    }
  }

  /// Removes the registered project from the contract
  /// @param projectId if of the registered project
  function removeProject(uint256 projectId) external onlyRole(CONTROL_ROLE) {
    if (_registeredProjects[projectId].id == 0) revert GivenProjectIdNotExist();

    // _registeredProjects[projectId].wallet = address(0);
    _registeredProjects[projectId].creator = address(0);
    _registeredProjects[projectId].id = 0;
    _registeredProjects[projectId].name = "";
    _registeredProjects[projectId].thumbnail = "";
    _registeredProjects[projectId].projectSlotDefaultURI = "";
    projectWallets.remove(_registeredProjects[projectId].wallet);

    emit ProjectRemoved(projectId);
  }

  /// External ERC721-NFT Contracts can be registered to the contract to get tokens upgradable.
  /// @param externalCollectionContract address of the ERC721-NFT collection
  /// @param templateId the selected template for their entire collection.
  function registerExternalCollection(address externalCollectionContract, uint256 templateId)
    external
    onlyRole(CONTROL_ROLE)
  {
    if (!templateIds.contains(templateId)) revert("wrong template id");
    mQuark.registerExternalCollection(externalCollectionContract, _templateURIs[templateId]);
  }

  //* ================================================================================================

  //* ====================== SET Functions ===========================================================

  /// Sets the contract address of deployed mQuark contract
  /// @param mQuarkAddr address of mQuark Contract
  function setmQuark(address mQuarkAddr) external onlyRole(CONTROL_ROLE) {
    if (!ImQuark(mQuarkAddr).supportsInterface(type(ImQuark).interfaceId)) revert NotImQuarkContract();
    if (address(mQuark) != address(0)) revert AlreadySet(address(mQuark));
    mQuark = ImQuark(mQuarkAddr);
    emit MQuarkSet(mQuarkAddr);
  }

  /// Sets a wallet as an authorized or unauthorized to register projects
  /// @param wallet wallet address that will be set
  /// @param isAuthorized boolean value(true is authorized, false is unauthorized)
  function setAuthorizedToRegister(address wallet, bool isAuthorized) external onlyRole(CONTROL_ROLE) {
    if (isAuthorized) grantRole(AUTHORIZED_REGISTERER_ROLE, wallet);
    else revokeRole(AUTHORIZED_REGISTERER_ROLE, wallet);
    emit AuthorizedToRegisterWalletSet(wallet, isAuthorized);
  }

  /// Sets Templates mint prices(wei)
  /// @notice Collections inherit the template's mint price
  /// @param templateIds_: IDs of Templates which are categorized NFTs
  /// @param prices: Prices of each given templates in wei unit
  function setTemplatePrices(uint256[] calldata templateIds_, uint256[] calldata prices)
    external
    onlyRole(CONTROL_ROLE)
  {
    if (templateIds_.length != prices.length) revert ArrayLengthMismatch();
    uint256 _templateIdsLength = templateIds_.length;
    for (uint256 i = 0; i < _templateIdsLength; ) {
      _templateMintPrices[templateIds_[i]] = prices[i];
      unchecked {
        ++i;
      }
    }
    emit TemplatePricesSet(templateIds_, prices);
  }

  /// Sets projects percantage from minting and uri slot purchases
  /// @notice percentage should be between 0-100
  /// @param percentage: Percantage amount
  function setCreatorPercentage(uint256 percentage) external onlyRole(CONTROL_ROLE) {
    if (percentage > 100) revert InvalidPercentage();
    projectPercentage = percentage;
    adminPercentage = (100 - percentage);
    emit CreatorPercentageSet(percentage);
  }

  /// Sets a project's uri slot price for every NFT minted
  /// @param projectId project id
  /// @param price slot price in wei
  function setProjectURISlotPrice(uint256 projectId, uint256 price) external onlyOwners(projectId) {
    _projectSlotPrices[projectId] = price;
    emit SlotPriceSet(projectId, price);
  }

  /// Sets given address as verifier, this address is sent to mQuark contract to verify signatures
  function setVerifierAddress(address addr) external onlyRole(CONTROL_ROLE) {
    verifier = addr;
  }

  /// Sets admin wallet address
  function setAdminWallet(address addr) external onlyRole(CONTROL_ROLE) {
    adminWallet = addr;
    emit AdminWalletSet(addr, block.timestamp);
  }

  /// Unlocks a free minted NFT's upgradability.
  /// @param mintIdParams Struct for the mint functions
  /// * projectId collection owner's project id
  /// * templateId collection's inherited template's id
  /// * collectionId collection id for its template
  /// @param tokenId token id
  function unlockFreeMintNFT(MintIdParams calldata mintIdParams, uint256 tokenId) external payable {
    if (this.getProjectCollectionPrice(mintIdParams.projectId, mintIdParams.templateId, mintIdParams.collectionId) != 0)
      revert("not free collection");
    if (msg.value != _templateMintPrices[mintIdParams.templateId]) revert("wrong sent amount");

    mQuark.unlockFreeMintNFT(mintIdParams, tokenId);
    _registeredProjects[mintIdParams.projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[adminWallet] += (msg.value * adminPercentage) / 100;

    emit NFTUnlocked(mintIdParams.projectId, mintIdParams.templateId, mintIdParams.collectionId, tokenId);
  }

  //* ================================================================================================

  //* ===================== FUND Transfers ===========================================================

  /// Contract admin transfers its balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param amount amount of funds that will be transferred in wei
  function transferFunds(uint256 amount) external onlyRole(CONTROL_ROLE) {
    if (amount > adminBalance[msg.sender]) revert InsufficientBalance();
    adminBalance[msg.sender] -= amount;
    _asyncTransfer(msg.sender, amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  /// Projects transfers their balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param project project registered wallet address
  /// @param amount amount of funds that will be transferred in wei
  function projectTransferFunds(
    address payable project,
    uint256 projectId,
    uint256 amount
  ) external onlyOwners(projectId) {
    if (amount > _registeredProjects[projectId].balance) revert InsufficientBalance();
    _registeredProjects[projectId].balance -= amount;
    _asyncTransfer(project, amount);
    emit ProjectFundsWithdrawn(projectId, amount);
  }

  //* ================================================================================================

  //* ================================================================================================
  //*                                          VIEW Functions
  //* ================================================================================================

  /// Calculates mint base price
  /// @param templateIds_ template id of tokens
  /// @param amounts amount of each template ids
  /// @return totalPrice calculated total price amount of ids for a project
  function totalPriceMintBatch(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external view returns (uint256 totalPrice) {
    uint256 _templateIdsLength = templateIds_.length;
    for (uint8 i = 0; i < _templateIdsLength; ) {
      uint256 _collectionPrice = _collectionPrices[projectId][templateIds_[i]][collectionIds[i]];
      if (templateIds_[i] == 0 || amounts[i] == 0 || _collectionPrice == 0) revert InvalidZeroValue();
      totalPrice += (_collectionPrice * amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// Calculates total price of batch same slot uri purchases
  /// @param tokenAmounts token amounts for each template
  /// @param projectId slot's project Id
  function totalPriceBatchAddProjectSlot(uint256 projectId, uint8[] calldata tokenAmounts)
    external
    view
    returns (uint256 totalPrice)
  {
    // if (_projectSlotPrices[projectId] == 0) revert SlotValueIsZero();
    if (_projectSlotPrices[projectId] == 0) return 0;
    uint256 _amountsLength = tokenAmounts.length;
    for (uint8 i = 0; i < _amountsLength; ) {
      totalPrice += (_projectSlotPrices[projectId] * tokenAmounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// Multiple (tokens^slot))
  /// Calculate total price of mint batch tokens with single slot uri
  /// @param projectId slot's project Id
  /// @param templateIds_ template id of tokens
  /// @param amounts amount of each template ids
  function totalPriceMintBatchWithSingleSlotForEach(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts
  ) external view returns (uint256) {
    uint256 _slotPrice = this.totalPriceBatchAddProjectSlot(projectId, amounts);
    uint256 _mintPrices = this.totalPriceMintBatch(projectId, templateIds_, collectionIds, amounts);
    return (_slotPrice + _mintPrices);
  }

  /// Single (token^slots)
  /// Calculates total price of a mint with multiple slots
  function totalPriceMintWithSlots(uint256[] calldata projectIds, uint256 templateId) public view returns (uint256) {
    uint256 _mintPrice = _templateMintPrices[templateId];
    uint256 _slotPrices;
    for (uint256 i = 0; i < projectIds.length; i++) _slotPrices += _projectSlotPrices[projectIds[i]];
    return (_mintPrice + _slotPrices);
  }

  /// Returns project's balance
  function getProjectBalance(uint256 projectId) external view returns (uint256) {
    return _registeredProjects[projectId].balance;
  }
  /// Returns project's collection price
  function getProjectCollectionPrice(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId
  ) external view returns (uint256) {
    return _collectionPrices[projectId][templateId][collectionId];
  }

  /// Returns registered project
  /// @return wallet project wallet address
  /// @return creator project creator address
  /// @return id project id
  /// @return balance project balance
  /// @return name project name
  /// @return thumbnail project thumbnail
  /// @return projectSlotDefaultURI project slot default uri
  function getRegisteredProject(uint256 projectId)
    external
    view
    returns (
      address wallet,
      address creator,
      uint256 id,
      uint256 balance,
      string memory name,
      string memory thumbnail,
      string memory projectSlotDefaultURI
    )
  {
    Project memory _project = _registeredProjects[projectId];
    return (
      _project.wallet,
      _project.creator,
      _project.id,
      _project.balance,
      _project.name,
      _project.thumbnail,
      _project.projectSlotDefaultURI
    );
  }

  /// Templates defines what a token is. Every template id has its own properties and attributes.
  /// Collections are created by templates. Inherits the properties and attributes of the template.
  /// @param templateId template id
  /// @return template's uri
  function templateUri(uint256 templateId) external view returns (string memory) {
    return _templateURIs[templateId];
  }

  /// Returns given project's id
  /// @param projectAddr project wallet address
  function getProjectId(address projectAddr) external view returns (uint256) {
    return _projectIds[projectAddr];
  }

  /// Returns whethere a given address is authorized to register a project
  function getAuthorizedToRegisterProject(address addr) external view returns (bool) {
    return hasRole(AUTHORIZED_REGISTERER_ROLE, addr);
  }

  /// Returns template mint price
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256) {
    return _templateMintPrices[templateId];
  }

  /// Returns project slot price
  function getProjectSlotPrice(uint256 projectId) external view returns (uint256) {
    return _projectSlotPrices[projectId];
  }

  /// @notice This function returns the total number of templates that have been created.
  /// @return The total number of templates that have been created
  function getCreatedTemplateIds() external view returns (uint256) {
    // Return the length of the template IDs array, which is the total number of templates that have been created
    return templateIds.length();
  }

  //* ================================================================================================
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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