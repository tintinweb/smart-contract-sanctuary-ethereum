//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/mQuarkV5/ImQuarkV5.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";

///@notice protect withdrawPayment with nonReentrant modifier in PullPayment
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract mQuarkControlV5 is ReentrancyGuard, PullPayment {

  using EnumerableSet for EnumerableSet.AddressSet;

  ///=============================================================
  //                        Events
  //==============================================================

  event FundsWithdrawn(address metaverse, uint256 amount);
  event MetaverseFundsWithdrawn(address metaverse, uint256 amount);
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);
  event ClientPercentageSet(uint256 percentage);
  event SlotPriceSet(address metaverse, uint256 price);
  event AuthorizedToRegisterWalletSet(address wallet, bool isAuthorized);
  event MetaverseRemoved(address metaverse);
  event FundsDeposit(uint256 amount, uint256 clientPercentage, address metaverse);
  event MintBatchSlotFundsDeposit(
    uint256 amount,
    uint256 clientPercentage,
    address[] metaverses,
    uint256[] metaversesShares
  );
  event BatchSlotFundsDeposit(
    uint256 amount,
    uint256 clientPercentage,
    address[] metaverses,
    uint256[] metaversesShares
  );
  event TemplatesSelected(address metaverse, uint256[] templateIds, uint256[] amounts, uint256 globalTokenIdVariable);
  event TemplatesUnselected(address metaverse, uint256[] templateIds, uint256[] collectionIndexes);
  event MetaverseRegistered(
    address metaverse,
    address company,
    uint256 metaverseId,
    string metaverseName,
    string companyName,
    string thumbnail,
    string metaverseMetadata
  );

  ///=============================================================
  //                        Modifiers
  //==============================================================

  modifier onlyAdmin() {
    require(admin == msg.sender, "not authorized");
    _;
  }

  modifier onlyAuthorized() {
    require(authorizedToRegisterMetaverse[msg.sender] == true, "not authorized");
    _;
  }

  ///=============================================================
  //                        State Variables
  //==============================================================
  /**
   * Struct of Registered Metaverse
   * @param wallet: Wallet address of metaverse
   * @param companyOwner: Company Owner wallet address
   * @param id: Unique id
   * @param metaverseMetadataTemplate: Metaverse default metadata schema
   */
  struct Metaverse {
    address wallet;
    address companyOwner;
    uint256 id;
    uint256 balance;
    string name;
    string thumbnail;
    string metaverseMetadataTemplate;
  }

  ///@dev Stores admin address of the contract
  address public admin;

  ///@dev The last registered metaverse id
  uint256 public metaverseIndexId;

  ///@dev Percentage of clients from minting or add,ing metadata slot
  uint256 public clientPercentage;

  ///@dev Percentage of admin from minting or adding metadata slot
  uint256 public adminPercentage;

  ///@dev Limits the select of the templates to the amount to prevent out of gas error
  uint16 constant MAX_SELECTING_LIMIT = 350;

  ///@dev ERC721 contract interface
  ImQuarkV5 public mQuark;

  ///@dev Stores metaverses wallet address that are registered to the metaverse
  EnumerableSet.AddressSet private metaverseWallets;

  ///=============================================================
  //                         Mappings
  //==============================================================

  /**
   *  @dev Mapping from 'admin address' to balance
   **/
  mapping(address => uint256) public adminBalance;

  /**
   *  @dev Mapping from 'Metaverse address' to Metaverse Struct
   **/
  mapping(address => Metaverse) public registeredMetaverses;

  /**
   *  @dev Mapping from 'Metaverse address' to a boolean
   **/
  ///@dev This approved wallets can register metaverses
  mapping(address => bool) public authorizedToRegisterMetaverse;


  // /**DEPRECATED**
  //  *  @dev Mapping from 'Metaverse address' => 'Template ID' to Metaverse Mint Price
  //  **/
  // /*metaverse address => baseId => price
  //  *Stores minting price info for each metaverses for each base ids(templates)
  //  *given metaverse address and baseId, returns minting price
  // */
  // mapping(address => mapping(uint256 => uint256)) public metaverseTemplateMintPrices;

  /**
   *  @dev Mapping from 'Template ID' to Mint Price in Wei
   **/
  mapping(uint256 => uint256) public templateMintPrices;

  /**
   *  @dev Mapping from 'Metaverse Address' to Metadata Add Price
   **/
  mapping(address => uint256) public metaverseSlotAddPrices;

  ///=============================================================
  //                        CONSTRUCTOR
  //==============================================================

  constructor() {
    admin = msg.sender;
  }

  ///=============================================================
  //                        EXTERNALS
  //==============================================================

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint single NFT.
   *@param metaverse: Metaverse wallet address
   *@param templateId: Template ID of selected collection
   *@param collectionIndex: Index of selected collection
   */
  function mint(
    address payable metaverse,
    uint256 templateId,
    uint256 collectionIndex
  ) external payable nonReentrant {
    require(templateId != 0, "invalid ID");
    require(registeredMetaverses[metaverse].id != 0, "unregistered metaverse");
    require(msg.value == templateMintPrices[templateId], "send the required amount");
    require(msg.value != 0, "ether value is zero");
    mQuark.mint(msg.sender, metaverse, templateId, collectionIndex);

    registeredMetaverses[metaverse].balance += (msg.value * clientPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, clientPercentage, metaverse);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint multiple NFT.
   *
   *@param metaverse: Metaverse wallet address
   *@param mintParams:  struct MintParams {
   *                       uint256[] _templateIds : Selected Template IDs
   *                       uint256[] _collectionIndexes : Indexes of selected Template IDs in the metaverse;
   *                       uint256[] _amounts: Selected Amount for each Template;
   *                     }
   *@dev Each index will be matched to each other in given arrays, thus order of array indexes matters.
   */
  function mintBatch(address payable metaverse, ParamsLib.MintParams calldata mintParams)
    external
    payable
    nonReentrant
  {
    require(registeredMetaverses[metaverse].id != 0, "unregistered metaverse");
    require(mintParams._templateIds.length == mintParams._collectionIndexes.length, "IDs and indexes mismatch");
    require(mintParams._templateIds.length <= 20, "mint more than 20");
    require(
      this.calculateBatchPrice(mintParams._templateIds, mintParams._amounts) == msg.value,
      "send the required amount"
    );
    require(msg.value != 0, "ether value is zero");

    // mQuark.mintBatch(msg.sender, _metaverse, _mintParams._templateIds, _mintParams._collectionIndexes, _mintParams._amounts);
    mQuark.mintBatch(msg.sender, metaverse, mintParams);
    registeredMetaverses[metaverse].balance += (msg.value * clientPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, clientPercentage, metaverse);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint multiple NFTs with a single specified metadata slot
   *@param metaverse:Metaverse wallet address
   *@param mintParams:  struct MintParams {
   *                       uint256[] _templateIds : Selected Template IDs
   *                       uint256[] _collectionIndexes : Indexes of selected Template IDs in the metaverse;
   *                       uint256[] _amounts: Selected Amount for each Template;
   *                     }
   *@dev Each index will be matched to each other in given arrays, thus order of array indexes matters.
   */
  function mintBatchWithMetadataSlot(
    address payable metaverse,
    uint256 metaverseId,
    ParamsLib.MintParams calldata mintParams
  ) external payable nonReentrant {
    require(mintParams._templateIds.length == mintParams._collectionIndexes.length, "template ID and index mismatch");
    require(mintParams._amounts.length == mintParams._collectionIndexes.length, "Amount and index mismathc!");
    require(registeredMetaverses[metaverse].id != 0, "unregistered metaverse");
    require(registeredMetaverses[metaverse].id == metaverseId, "metaverse id mismatch");
    require(registeredMetaverses[metaverse].wallet == metaverse, "metaverse wallet mismatch");
    require(
      (this.calculateBatchPrice(mintParams._templateIds, mintParams._amounts) +
        this.calculateBatchSlotPrice(mintParams._amounts, metaverse)) == msg.value,
      "Please send the required amount!"
    );

    mQuark.mintBatchWithMetadataSlot(
      msg.sender,
      metaverse,
      metaverseId,
      mintParams,
      registeredMetaverses[metaverse].metaverseMetadataTemplate
    );

    registeredMetaverses[metaverse].balance += (msg.value * clientPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    emit FundsDeposit(msg.value, clientPercentage, metaverse);
  }

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to mint single NFT with multiple specified metadata slots
   *@param templateId: IDs of Templates which are categorized NFTs
   *@param metaverseIds: Number of mint from each IDs
   *@param metaverses:Metaverse wallet addresses(Address at index zero, gets the mint price)
   */
  function mintWithMetadaSlots(
    uint256 templateId,
    uint256 collectionIndex,
    uint256[] calldata metaverseIds,
    address[] calldata metaverses
  ) external payable nonReentrant {
    require(templateId != 0, "invalid ID!");
    require(metaverseIds.length == metaverses.length, "wrong given number of parameters");
    require(templateMintPrices[templateId] > 0, "can't mint this NFT in this metaverse");
    string[] memory metaverseMetadataTemplate = new string[](metaverseIds.length);
    uint256 _totalMetadataSlotPriceAmount;
    uint256 _metadataSlotPrice;
    uint256[] memory _metaversesMetedataPriceShares = new uint256[](metaverses.length);
    for (uint256 i; i < metaverseIds.length; i++) {
      require(registeredMetaverses[metaverses[i]].id == metaverseIds[i], "metaverse wallet and ID mismatch");
      require(metaverseSlotAddPrices[metaverses[i]] > 0, "slot for one of the selected metaverses can't be added");
      _metadataSlotPrice = metaverseSlotAddPrices[metaverses[i]];
      metaverseMetadataTemplate[i] = (registeredMetaverses[metaverses[i]].metaverseMetadataTemplate);
      _totalMetadataSlotPriceAmount += _metadataSlotPrice;
      registeredMetaverses[metaverses[i]].balance += (_metadataSlotPrice * clientPercentage) / 100;
      _metaversesMetedataPriceShares[i] = _metadataSlotPrice;
    }

    uint256 _templateMintPrice = templateMintPrices[templateId];
    require(msg.value == (_totalMetadataSlotPriceAmount + _templateMintPrice), "send the required amount");

    registeredMetaverses[metaverses[0]].balance += ((_templateMintPrice * clientPercentage) / 100);
    adminBalance[admin] += ((_templateMintPrice * adminPercentage) / 100);
    mQuark.mintWithMetadaSlots(
      msg.sender,
      templateId,
      collectionIndex,
      metaverses,
      metaverseIds,
      metaverseMetadataTemplate
    );

    /** @notice Base mint price should be considered at zero index! */
    emit MintBatchSlotFundsDeposit(msg.value, clientPercentage, metaverses, _metaversesMetedataPriceShares);
  }

  ///=============================================================
  //                        METADATA
  //==============================================================

  /**
   *@notice Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add single NFT metadata slot to single NFT
   *@param tokenId: Token ID of the NFT
   *@param metaverseId: Number of mint from each ID
   *@param metaverse:Metaverse wallet address
   */
  function addMetadataSlotToTemplate(
    uint256 tokenId,
    uint256 metaverseId,
    address payable metaverse
  ) external payable nonReentrant {
    require(registeredMetaverses[metaverse].id == metaverseId, "metaverse wallet and ID mismatch");
    require(metaverseSlotAddPrices[metaverse] == msg.value, "send the required amount!");
    require(msg.value != 0, "ether value is zero");

    mQuark.addMetadataSlotToTemplate(
      msg.sender,
      tokenId,
      metaverseId,
      registeredMetaverses[metaverse].metaverseMetadataTemplate
    );
    registeredMetaverses[metaverse].balance += (msg.value * clientPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, clientPercentage, metaverse);
  }

  /** Single Token => Multiple Metaverses
   *Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add multiple metadata slots to single NFT
   *@param tokenId: Token ID of the NFT
   *@param metaverseIds: Number of mint from each IDs
   *@param metaverses:Metaverse wallet addresses
   *@notice If reverts, costs gas!
   */
  function addBatchMetaverseSlotsToTemplate(
    uint256 tokenId,
    uint256[] calldata metaverseIds,
    address[] calldata metaverses
  ) external payable nonReentrant {
    require(metaverseIds.length == metaverses.length, "wrong given number of parameters");
    // require(msg.value != 0,"Ether value should be more than zero!");
    string[] memory _metaverseMetadataTemplate = new string[](metaverseIds.length);
    uint256 price;
    uint256 totalAmount;
    uint256[] memory metaversesShares = new uint256[](metaverses.length);
    for (uint256 i; i < metaverseIds.length; i++) {
      require(registeredMetaverses[metaverses[i]].id == metaverseIds[i], "wallet and ID mismatch");
      require(metaverseSlotAddPrices[metaverses[i]] > 0, "slot for one of the selected Metaverses can't be added");
      price = metaverseSlotAddPrices[metaverses[i]];
      _metaverseMetadataTemplate[i] = (registeredMetaverses[metaverses[i]].metaverseMetadataTemplate);
      totalAmount += price;
      registeredMetaverses[metaverses[i]].balance += (price * clientPercentage) / 100;
      metaversesShares[i] = price;
    }
    require(msg.value == totalAmount, "send the required amount");

    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    mQuark.addBatchMetaverseSlotsToTemplate(msg.sender, tokenId, metaverseIds, _metaverseMetadataTemplate);
    emit BatchSlotFundsDeposit(msg.value, clientPercentage, metaverses, metaversesShares);
  }

  /**Multiple Tokens => Single Metaverse
   *Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add the same single metadata slot to multiple NFTs
   *@param tokenIds: Token IDs of NFTs
   *@param metaverseId: Number of mint from each IDs
   *@param metaverse:Metaverse wallet addresses
   */
  function addBatchMetaverseSlotToTemplates(
    uint256[] calldata tokenIds,
    uint256 metaverseId,
    address payable metaverse
  ) external payable nonReentrant {
    require(registeredMetaverses[metaverse].id == metaverseId, "wallet and ID mismatch");
    require(tokenIds.length <= 20, "token numbers should be less then 20");
    require((metaverseSlotAddPrices[metaverse] * tokenIds.length) == msg.value, "send the required amount");
    require(msg.value != 0, "ether value is zero");
    mQuark.addBatchMetaverseSlotToTemplates(
      msg.sender,
      tokenIds,
      metaverseId,
      registeredMetaverses[metaverse].metaverseMetadataTemplate
    );
    registeredMetaverses[metaverse].balance += (msg.value * clientPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, clientPercentage, metaverse);
  }

  /*============================================================================================================*/

  /**Multiple Tokens => Single Metaverse
   *Checks the validity of given parameters and whether paid ETH amount is valid
   *It makes call to NFT contract to add the same single metadata slot to multiple NFTs
   *@param signature: IDs of Templates which are categorized NFTs
   *@param metaverseWallet: Metaverse wallet addresses
   *@param metaverseId: Number of mint from each IDs
   *@param tokenId: Token ID of the NFT
   *@param newURI: New URI which will be replaced with old URI
   *@param salt: Unique salt value
   */
  function updateURI(
    bytes calldata signature,
    address metaverseWallet,
    uint256 metaverseId,
    uint256 tokenId,
    string calldata newURI,
    bytes calldata salt
  ) external {
    Metaverse memory registeredMetaverse = registeredMetaverses[metaverseWallet];
    require(registeredMetaverse.wallet == metaverseWallet, "not authorized");
    require(registeredMetaverse.id == metaverseId, "not authorized");
    require(registeredMetaverse.wallet != address(0), "unregistered metaverse");
    mQuark.updateURI(signature, metaverseWallet, metaverseId, tokenId, newURI, salt);
  }

  /**
   *Resets NFT's metaverse metadata URI to default
   *@notice This function is not completed yet!
   */
  function resetMetaverseURI(
    uint256 tokenId,
    address metaverse,
    uint256 metaverseId
  ) external {
    require(msg.sender == registeredMetaverses[metaverse].wallet, "");
    require(registeredMetaverses[metaverse].id == metaverseId, "invalid parameters");
    mQuark.resetMetaverseURI(tokenId, metaverseId, registeredMetaverses[metaverse].metaverseMetadataTemplate);
  }

  /**
   *Via this function Metaverses can be registered to the contract.
   *@param wallet: Metaverse Wallet
   *@param companyWallet: Owner wallet of the metaverse
   *@param name: Metaverse Name
   *@param companyName: Company name of the metaverse
   *@param thumbnail: Image URL
   *@param metaverseMetadataTemplate: Metaverse default metadata.It will be used when a m
   */
  function registerMetaverse(
    address wallet,
    address companyWallet,
    string calldata name,
    string calldata companyName,
    string calldata thumbnail,
    string calldata metaverseMetadataTemplate
  ) external onlyAuthorized {
    require(!metaverseWallets.contains(wallet), "already registered");
    unchecked {
      uint256 id = ++metaverseIndexId;
      registeredMetaverses[wallet] = Metaverse(
        wallet,
        companyWallet,
        id,
        registeredMetaverses[wallet].balance,
        name,
        thumbnail,
        metaverseMetadataTemplate
      );
      metaverseWallets.add(wallet);
      emit MetaverseRegistered(wallet, companyWallet, id, name, companyName, thumbnail, metaverseMetadataTemplate);
    }
  }

  /**
   *Removes registered metaverse from the contract
   *@param wallet: Wallet address of registered metaverse
   */
  function removeMetaverse(address wallet) external onlyAdmin {
    require(registeredMetaverses[wallet].wallet != address(0), "deleting an un-registered metaverse");
    registeredMetaverses[wallet].wallet = address(0);
    registeredMetaverses[wallet].companyOwner = address(0);
    registeredMetaverses[wallet].id = 0;
    registeredMetaverses[wallet].name = "";
    registeredMetaverses[wallet].thumbnail = "";
    registeredMetaverses[wallet].metaverseMetadataTemplate = "";
    metaverseWallets.remove(wallet);
    emit MetaverseRemoved(wallet);
  }

  ///=============================================================
  //                        SET-SELECT
  //==============================================================

  /**
   *Sets the address of deployed NFT contract
   *@param _mQuarkAddress: Contract address of NFT Contract
   */
  function setUnbounded(address _mQuarkAddress) external onlyAdmin {
    mQuark = ImQuarkV5(_mQuarkAddress);
  }

  /**
    Sets a wallet as authorized or unauthorized to register metaverses
    *@param wallet: Wallet address that will be set
    *@param isAuthorized: Boolean value whet
  */
  function setAuthorizedToRegister(address wallet, bool isAuthorized) external onlyAdmin {
    authorizedToRegisterMetaverse[wallet] = isAuthorized;
    emit AuthorizedToRegisterWalletSet(wallet, isAuthorized);
  }

  /**
   *Sets Templates mint prices for metaverses
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param prices: Prices of each given templates in wei unit
   */
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices) external onlyAdmin {
    require(templateIds.length == prices.length, "wrong given number of parameters");
    for (uint256 i; i < templateIds.length; i++) templateMintPrices[templateIds[i]] = prices[i];

    emit TemplatePricesSet(templateIds, prices);
  }

  function setNameForCollection(
    bytes[] calldata signatures,
    address _admin,
    address metaverse,
    uint256[] memory templateIds,
    uint256[] memory collectionIds,
    string[] calldata uris
  ) external nonReentrant {
    require(registeredMetaverses[metaverse].id != 0, "unauthorized access");

    mQuark.setNameForCollection(signatures, _admin, metaverse, templateIds, collectionIds, uris);
  }

  /**
   *Sets Templates mint prices for metaverses
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param amounts: Amount of selected templates
   */
  function selectTemplates(uint256[] calldata templateIds, uint256[] calldata amounts) external {
    require(registeredMetaverses[msg.sender].id != 0, "unregistered metaverse wallet");
    require(templateIds.length < 100, "selected more than 100 templates");
    require(templateIds.length == amounts.length, "IDs and amounts mismatch");

    for (uint256 i; i < templateIds.length; i++) {
      require(templateMintPrices[templateIds[i]] > 0, "selected unset template");
      require(amounts[i] < MAX_SELECTING_LIMIT, "selected more than 350 amount for a template");
    }

    mQuark.selectTemplates(msg.sender, registeredMetaverses[msg.sender].id, templateIds, amounts);
  }

  /**
   *Sets metaverses percantage from minting and metadata slot purchases
   *@param percentage: Percantage amount
   *@notice Amount should be between 0-100
   */
  function setClientPercentage(uint256 percentage) external onlyAdmin {
    require(percentage <= 100, "percentage is higher than 100");
    clientPercentage = percentage;
    adminPercentage = (100 - percentage);
    emit ClientPercentageSet(percentage);
  }

  /**
   *Sets a metaverse's metadata slot adding price for each template
   *@param metaverse: Metaverse wallet address
   *@param price: Price in wei unit
   *@notice Amount should be between 0-100
   */
  function setSlotAddPrice(address metaverse, uint256 price) external onlyAdmin {
    metaverseSlotAddPrices[metaverse] = price;
    emit SlotPriceSet(metaverse, price);
  }

    /**
   *Sets Templates mint prices for metaverses
   *@param _templateIds: IDs of Templates which are categorized NFTs
   */
  // function unSelectTemplates(uint256[] calldata _templateIds, uint256[] calldata _collectionIndexes) external {
  //   require(registeredMetaverses[msg.sender].id != 0, "Unregistered metaverse wallet!");
  //   for (uint256 i; i < _templateIds.length; i++) {
  //     // delete metaverseTemplateMintPrices[msg.sender][_baseIds[i]];
  //     // delete metaverseTemplates[msg.sender][_templateIds[i]][_collectionIndexes[i]];
  //   }
  //   emit TemplatesUnselected(msg.sender, _templateIds, _collectionIndexes);
  // }

  ///=============================================================
  //                        TRANSFERS
  //==============================================================

  /**
   *@dev Admin of this contract transfers the amount. Uses {PullPayment} method of Oppenzeppelin.
   *@param amount: Amount of funds that will be withdrawn in wei
   */
  function transferFunds(uint256 amount) external onlyAdmin {
    require(amount <= adminBalance[admin], "insufficient balance");
    adminBalance[admin] -= amount;
    _asyncTransfer(msg.sender, amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  /**
   *Metaverses can withdraw their balance using this function
   *@param metaverse: Metaverse registered wallet address
   *@param amount: Amount of funds that will be withdrawn in wei
   */
  function metaverseTransferFunds(address payable metaverse, uint256 amount) external {
    require(registeredMetaverses[metaverse].wallet == msg.sender, "unauthorizaed access");
    require(amount <= registeredMetaverses[metaverse].balance, "insufficient balance");
    registeredMetaverses[metaverse].balance -= amount;
    // _metaverse.transfer(_amount);
    _asyncTransfer(metaverse, amount);
    emit MetaverseFundsWithdrawn(metaverse, amount);
  }

  ///=============================================================
  //                        VIEWS
  //==============================================================

  /**
   *Calculates and returns templates batch mint price
   *@param templateIds: IDs of Templates which are categorized NFTs
   *@param amounts: Amount of each IDs
   *@return totalAmount Calculated total amount of IDs for a metaverse
   */
  function calculateBatchPrice(uint256[] calldata templateIds, uint256[] calldata amounts)
    external
    view
    returns (uint256 totalAmount)
  {
    for (uint256 i; i < templateIds.length; i++) {
      require(templateIds[i] > 0, "can't mint one of the selected NFTs for this metaverse");
      // _totalAmount += (metaverseTemplateMintPrices[_metaverse][_baseIds[i]] * _amounts[i]);
      totalAmount += (templateMintPrices[templateIds[i]] * amounts[i]);
    }
  }

  /**
   *Calculates and returns metaverse matadata slots
   *@param amounts: Amounts of tokens
   *@param metaverse: Metaverse wallet address
   */
  function calculateBatchSlotPrice(uint256[] calldata amounts, address metaverse)
    external
    view
    returns (uint256 totalAmount)
  {
    require(metaverseSlotAddPrices[metaverse] > 0, "slot for this metaverse can't be added");
    for (uint256 i; i < amounts.length; i++) {
      totalAmount += (metaverseSlotAddPrices[metaverse] * amounts[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "../../mQuarkV5/ParamsLib.sol";

library ParamsLib {
    struct MintParams {
      uint256[] _templateIds;
      uint256[] _collectionIndexes;
      uint256[] _amounts;
    }
}

interface ImQuarkV5 {

  event NewItemtemplateCreated(uint256 baseId, uint256 minId, uint256 maxId, string uri);
  event TemplateEdited(uint256 baseId, uint256 minId, uint256 maxId, string uri);
  event MetaverseURIAdded(uint256 tokenId, uint256 metaverseId, string uri);
  event MetaverseURIReset(uint256 tokenId, uint256 metaverseId);
  event MetaverseURIUpdated(bytes signature, uint256 metaverseId, uint256 tokenId, string newUri);
  event ItemMinted(uint256 baseId, uint256 count);

  function setAuthorizedContract(address _contractAddress) external;

  function setRoyalty(address _receiver, uint256 _royaltyPercentage) external;

  function removeAuthorizedContract(address _contractAddress) external;

  function createTemplate(uint256 _amount, string calldata _uri) external;

  function createBatchTemplate(uint256[] calldata _amounts, string[] calldata _uris) external;

  // function editTemplate(
  //   uint256 _baseID,
  //   uint256 _minTokenID,
  //   uint256 _maxTokenID,
  //   string calldata _uri
  // ) external;

  //Single Token => Single Metaverse
  function addMetadataSlotToTemplate(
    address _owner,
    uint256 _tokenId,
    uint256 _metaverseId,
    string calldata _metaverseMetadataTemplate
  ) external;

  //Single Token => Multiple Metaverses
  function addBatchMetaverseSlotsToTemplate(
    address _owner,
    uint256 _tokenId,
    uint256[] calldata _metaverseIds,
    string[] calldata _metaverseMetadataTemplate
  ) external;

  //Multiple Tokens => Single Metaverse
  function addBatchMetaverseSlotToTemplates(
    address _owner,
    uint256[] calldata _tokenIds,
    uint256 _metaverseId,
    string calldata _metaverseMetadataTemplate
  ) external;

  function updateURI(
    bytes calldata _signature,
    address _metaverseWallet,
    uint256 _metaverseId,
    uint256 _tokenId,
    string calldata _newURI,
    bytes calldata _salt
  ) external;

  function resetMetaverseURI(
    uint256 _tokenId,
    uint256 _metaverseId,
    string calldata _metaverseTemplate
  ) external;

  function recoverNFT(
    address contractAddress,
    uint256 _tokenId,
    uint256 _amount,
    bool _isERC1155
  ) external;

  //Single minting with no metadata
  function mint(
    address _to,
    address _metaverse,
    uint256 _templateId,
    uint256 _collectionIndex
  ) external;


  // function mintBatch(
  //   address _to,
  //   address _metaverse,
  //   uint256[] memory _templateIds,
  //   uint256[] calldata _collectionIndexes,
  //   uint256[] calldata _amount
  // ) external;
  //Multiple Tokens with no metadata
  function mintBatch(
    address _to,
    address _metaverse,
    ParamsLib.MintParams calldata _mintParams
  ) external;

 
  // function mintBatchWithMetadataSlot(
  //   address _to,
  //   address _metaverse,
  //   uint256 _metaverseId,
  //   uint256[] calldata _templateIds,
  //   uint256[] calldata _collectionIndexes,
  //   uint256[] calldata _amounts,
  //   string calldata _metaverseMetadataTemplate
  // ) external;
  //Multiple Token with single metadata slot
  function mintBatchWithMetadataSlot(
    address _to,
    address _metaverse,
    uint256 _metaverseId,
    ParamsLib.MintParams calldata _mintParams,
    string calldata _metaverseMetadataTemplate
  ) external;



  //Single Token with multiple Metadata slots
  function mintWithMetadaSlots(
    address _to,
    uint256 _templateId,
    uint256 _collectionIndex,
    address[] calldata _metaverses,
    uint256[] calldata _metaverseIds,
    string[] calldata _metaverseMetadataTemplate
  ) external;

 

  function selectTemplates(address _metaverse, uint256 _metaverseUniqueId, uint256[] calldata _templateIds, uint256[] calldata _amounts) external;

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function setNameForCollection(
    bytes[] calldata _signatures,
    address _admin,
    address _metaverse,
    uint256[] memory _templateIds,
    uint256[] memory _collectionIds,
    string[] calldata _uris
  ) external ;

  function checkItemBaseId(uint256 _tokenId) external view returns (uint256 _baseID);

  function getCreatedBaseIds() external view returns (uint256[] memory);

  function royaltyInfo(
    uint256, /*_tokenId*/
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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