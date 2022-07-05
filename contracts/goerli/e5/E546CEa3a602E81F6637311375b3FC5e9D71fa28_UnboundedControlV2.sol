//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUnboundedV4.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UnboundedControlV2 is ReentrancyGuard {
  event MetaverseRegistered(address metaverse, uint256 metaverseId, string metaverseName, string metaverseMetadata);
  event MetaverseRemoved(address metaverse);
  event FundsWithdrawn(address metaverse, uint256 amount);
  event MetaverseFundsWithdrawn(address metaverse, uint256 amount);
  event FundsDeposit(uint256 amount, uint256 clientPercantage, address metaverse);
  event TemplatePricesSet(uint256[] baseIds, uint256[] prices, address metaverse);
  event ClientPercentageSet(uint256 percentage);
  event SlotPriceSet(address metaverse, uint256 price);

  modifier onlyAdmin() {
    require(admin == msg.sender, "Not Authorized");
    _;
  }

  struct Metaverse {
    address wallet;
    uint256 id;
    uint256 balance;
    string name;
    string metaverseMetadataTemplate;
  }

  address public admin;
  uint256 public metaverseIDs;
  uint256 public clientPercantage;
  IUnboundedV4 public unbounded;

  mapping(address => Metaverse) public registeredMetaverses;

  //metaverse address => baseId => price
  mapping(address => mapping(uint256 => uint256)) public metaverseBaseIdPrice;

  mapping(address => uint256) public metaverseMetadataAddPrice;

  constructor() {
    admin = msg.sender;
  }

  function setUnbounded(address _unboundedAddress) external onlyAdmin {
    unbounded = IUnboundedV4(_unboundedAddress);
  }

  function mint(uint256 _baseId, address payable _metaverse) external payable nonReentrant {
    require(_baseId != 0, "Invalid ID!");
    require(registeredMetaverses[_metaverse].id != 0, "Unregistered Metaverse");
    require(msg.value == metaverseBaseIdPrice[_metaverse][_baseId], "Please send the required amount!");
    unbounded.mint(msg.sender, _baseId);
    //_metaverse.transfer((msg.value * clientPercantage)/100);
    registeredMetaverses[_metaverse].balance += (msg.value * clientPercantage) / 100;
    emit FundsDeposit(msg.value, clientPercantage, _metaverse);
  }

  function mintBatch(
    uint256[] calldata _baseIds,
    uint256[] calldata _amounts,
    address payable _metaverse
  ) external payable nonReentrant {
    require(_baseIds.length == _amounts.length, "Specify equal number of Base IDs and their amounts!");
    require(_baseIds.length <= 5, "You can't mint more than 5 different templates!");
    require(this.calculateBatchPrice(_baseIds, _amounts, _metaverse) == msg.value, "Please send the required amount!");
    unbounded.mintBatch(msg.sender, _baseIds, _amounts);
    //_metaverse.transfer((msg.value * clientPercantage)/100);
    registeredMetaverses[_metaverse].balance += (msg.value * clientPercantage) / 100;
    emit FundsDeposit(msg.value, clientPercantage, _metaverse);
  }

  //Multiple Token with single metadata slot
  function mintBatchWithMetadataSlot(
    uint256[] calldata _baseIds,
    uint256[] calldata _amounts,
    address payable _metaverseWallet,
    uint256 _metaverseId
  ) external payable nonReentrant {
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Metaverse wallet and id mismatch!");
    require(_baseIds.length == _amounts.length, "Specify equal number of Base IDs and and its amounts!");
    require(_baseIds.length <= 5, "You can't mint more than 5 different templates!");
    require(
      (this.calculateBatchPrice(_baseIds, _amounts, _metaverseWallet) + this.calculateBatchSlotPrice(_amounts, _metaverseWallet)) ==
        msg.value,
      "Please send the required amount!"
    );
    unbounded.mintBatchWithMetadataSlot(
      msg.sender,
      _baseIds,
      _amounts,
      _metaverseId,
      registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate
    );
    // _metaverseWallet.transfer((msg.value * clientPercantage)/100);
    registeredMetaverses[_metaverseWallet].balance += (msg.value * clientPercantage) / 100;
    emit FundsDeposit(msg.value, clientPercantage, _metaverseWallet);
  }

  //=======================no transfer===================================
  //Single Token with multiple Metadata slots
  function mintWithMetadaSlots(
    uint256 _baseId,
    uint256[] calldata _metaverseIds,
    address[] calldata _metaverseWallets
  ) external payable nonReentrant {
    require(_baseId != 0, "Invalid ID!");
    require(_metaverseIds.length == _metaverseWallets.length, "Wrong given number of parameters!");
    string[] memory _metaverseMetadataTemplate = new string[](_metaverseIds.length);
    uint256 _totalAmount;
    for (uint256 i; i < _metaverseIds.length; i++) {
      require(registeredMetaverses[_metaverseWallets[i]].id == _metaverseIds[i], "Metaverse wallet and ID mismatch!");
      _metaverseMetadataTemplate[i] = (registeredMetaverses[_metaverseWallets[i]].metaverseMetadataTemplate);
      _totalAmount += metaverseMetadataAddPrice[_metaverseWallets[i]];
    }
    // require(msg.value == (_totalAmount + metaverseBaseIdPrice[_metaverseWallets[0]][_baseId]),"Please send the required amount!");

    unbounded.mintWithMetadaSlots(msg.sender, _baseId, _metaverseIds, _metaverseMetadataTemplate);

  }

  function addMetadataSlotToTemplate(
    uint256 _tokenId,
    uint256 _metaverseId,
    address payable _metaverseWallet
  ) external payable nonReentrant {
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Metaverse wallet and id mismatch!");
    require(metaverseMetadataAddPrice[_metaverseWallet] == msg.value, "Please send the required amount!");
    unbounded.addMetadataSlotToTemplate(
      msg.sender,
      _tokenId,
      _metaverseId,
      registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate
    );
    //_metaverseWallet.transfer((msg.value * clientPercantage)/100);
    registeredMetaverses[_metaverseWallet].balance += (msg.value * clientPercantage) / 100;
    emit FundsDeposit(msg.value, clientPercantage, _metaverseWallet);
  }

  //*************************no transfer****************************************** */
  //Single Token => Multiple Metaverses
  function addBatchMetaverseSlotsToTemplate(
    uint256 _tokenId,
    uint256[] calldata _metaverseIds,
    address[] calldata _metaverseWallets
  ) external nonReentrant {
    require(_metaverseIds.length == _metaverseWallets.length, "Wrong given number of parameters!");
    string[] memory _metaverseMetadataTemplate = new string[](_metaverseIds.length);
    for (uint256 i; i < _metaverseIds.length; i++) {
      require(registeredMetaverses[_metaverseWallets[i]].id == _metaverseIds[i], "Metaverse wallet and ID mismatch!");
      _metaverseMetadataTemplate[i] = (registeredMetaverses[_metaverseWallets[i]].metaverseMetadataTemplate);
    }
    unbounded.addBatchMetaverseSlotsToTemplate(msg.sender, _tokenId, _metaverseIds, _metaverseMetadataTemplate);
  }

  //************************************************************************* */

  //Multiple Tokens => Single Metaverse
  function addBatchMetaverseSlotToTemplates(
    uint256[] calldata _tokenIds,
    uint256 _metaverseId,
    address payable _metaverseWallet
  ) external payable nonReentrant {
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Metaverse wallet and ID mismatch!");
    require(_tokenIds.length <= 20, "Token numbers should be less then 20!");
    require((metaverseMetadataAddPrice[_metaverseWallet] * _tokenIds.length) == msg.value, "Please send the required amount!");
    unbounded.addBatchMetaverseSlotToTemplates(
      msg.sender,
      _tokenIds,
      _metaverseId,
      registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate
    );
    //_metaverseWallet.transfer((msg.value * clientPercantage) / 100);
    registeredMetaverses[_metaverseWallet].balance += (msg.value * clientPercantage) / 100;
  }

  function updateURI(
    bytes calldata _signature,
    address _metaverseWallet,
    uint256 _metaverseId,
    uint256 _tokenId,
    string calldata _newURI,
    bytes calldata _salt
  ) external {
    Metaverse memory _registeredMetaverse = registeredMetaverses[_metaverseWallet];
    require(_registeredMetaverse.id == _metaverseId, "Not authorized!");
    require(_registeredMetaverse.wallet != address(0), "Unregistered Metaverse");
    unbounded.updateURI(_signature, _metaverseWallet, _metaverseId, _tokenId, _newURI, _salt);
  }

  function resetMetaverseURI(
    uint256 _tokenId,
    address _metaverseWallet,
    uint256 _metaverseId
  ) external {
    require(msg.sender == registeredMetaverses[_metaverseWallet].wallet, "");
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Invalid Metaverse Parameters!");
    unbounded.resetMetaverseURI(_tokenId, _metaverseId, registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate);
  }

  /**
   *Via this function Metaverses can be registered to the contract.
   *@param _wallet: Metaverse Wallet
   *@param _name: Metaverse Name
   *@param _metaverseMetadataTemplate: Metaverse Metadata
   */
  function registerMetaverse(
    address _wallet,
    string calldata _name,
    string calldata _metaverseMetadataTemplate
  ) external onlyAdmin {
    require(registeredMetaverses[_wallet].wallet == address(0), "This Metaverse has already registered!");
    unchecked {
      uint256 id = ++metaverseIDs;
      registeredMetaverses[_wallet] = Metaverse(_wallet, id, registeredMetaverses[_wallet].balance, _name, _metaverseMetadataTemplate);
      emit MetaverseRegistered(_wallet, id, _name, _metaverseMetadataTemplate);
    }
  }

  function removeMetaverse(address _wallet) external onlyAdmin {
    require(registeredMetaverses[_wallet].wallet != address(0), "Can't delete an un-registered Metaverse");
    registeredMetaverses[_wallet].wallet = address(0);
    registeredMetaverses[_wallet].id = 0;
    registeredMetaverses[_wallet].name = "";
    registeredMetaverses[_wallet].metaverseMetadataTemplate = "";

    emit MetaverseRemoved(_wallet);
  }

  //==============================================================================================================
  function setTemplatePrices(
    uint256[] calldata _baseIds,
    uint256[] calldata _prices,
    address _metaverse
  ) external onlyAdmin {
    require(_baseIds.length == _prices.length, "Wrong given number of parameters!");
    require(registeredMetaverses[_metaverse].id != 0, "Unregistered metaverse wallet!");
    for (uint256 i; i < _baseIds.length; i++) {
      metaverseBaseIdPrice[_metaverse][_baseIds[i]] = _prices[i];
    }
    emit TemplatePricesSet(_baseIds, _prices, _metaverse);
  }

  function setClientPercentage(uint256 _amount) external onlyAdmin {
    require(_amount <= 100, "Can't be higher than 100!");
    clientPercantage = _amount;
    emit ClientPercentageSet(_amount);
  }

  function setSlotAddPrice(address _metaverse, uint256 _price) external onlyAdmin {
    metaverseMetadataAddPrice[_metaverse] = _price;
    emit SlotPriceSet(_metaverse, _price);
  }

  function calculateBatchPrice(
    uint256[] calldata _baseIds,
    uint256[] calldata _amounts,
    address _metaverse
  ) external view returns (uint256 _totalAmount) {
    for (uint256 i; i < _baseIds.length; i++) _totalAmount += (metaverseBaseIdPrice[_metaverse][_baseIds[i]] * _amounts[i]);
  }

  function calculateBatchSlotPrice(uint256[] calldata _amounts, address _metaverse) external view returns (uint256 _totalAmount) {
    for (uint256 i; i < _amounts.length; i++) _totalAmount += (metaverseMetadataAddPrice[_metaverse] * _amounts[i]);
  }

  function calculateBatchMetaversePrice(uint256 _baseId, address[] calldata _metaverses) public view returns (uint256 _totalAmount) {
    for (uint256 i; i < _metaverses.length; i++) _totalAmount += metaverseBaseIdPrice[_metaverses[i]][_baseId];
  }

  function getFunds(uint256 _amount, address payable _wallet) external onlyAdmin {
    uint256 _balanceOfContract = address(this).balance;
    uint256 _withdrawableAmount = (_balanceOfContract - (_balanceOfContract * clientPercantage) / 100);
    require(_amount <= _withdrawableAmount, "Insufficient balance");
    _wallet.transfer(_amount);
    emit FundsWithdrawn(_wallet, _amount);
  }

  function metaverseGetFunds(address payable _metaverse, uint256 _amount) external {
    require(registeredMetaverses[_metaverse].wallet == msg.sender, "Unauthorizaed Access");
    require(_amount <= registeredMetaverses[_metaverse].balance, "Insufficient balance");
    registeredMetaverses[_metaverse].balance -= _amount;
    _metaverse.transfer(_amount);
    emit MetaverseFundsWithdrawn(_metaverse, _amount);
  }

  //==============================================================================================================
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUnboundedV4 {
  
  event NewItemtemplateCreated(uint256 baseId, uint256 minId, uint256 maxId, string uri);
  event TemplateEdited(uint256 baseId, uint256 minId, uint256 maxId, string uri);
  event MetaverseURIAdded(uint256 tokenId, uint256 metaverseId, string uri);
  event MetaverseURIReset(uint256 tokenId, uint256 metaverseId);
  event MetaverseURIUpdated(bytes signature, uint256 metaverseId, uint256 tokenId, string newUri);
  event ItemMinted(uint256 baseId, uint256 count);

  function setAuthorizedContract(address _contractAddress) external;

  function setRoyalty(address _receiver, uint256 _royaltyPercentage) external;

  function removeAuthorizedContract(address _contractAddress) external;

  function createTemplate(
    uint256 _minId,
    uint256 _maxId,
    string calldata _uri
  ) external;

  function createBatchTemplate(
    uint256[] calldata _minIds,
    uint256[] calldata _maxIds,
    string[] calldata _uris
  ) external;

  function editTemplate(
    uint256 _baseID,
    uint256 _minTokenID,
    uint256 _maxTokenID,
    string calldata _uri
  ) external;
  
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
    uint256 _tokenID,
    uint256 _amount,
    bool _isERC1155
  ) external;

  //Single minting with no metadata
  function mint(address _to, uint256 _baseId) external;
  
  //Multiple Tokens with no metadata
  function mintBatch(address _to, uint256[] calldata _baseIds, uint256[] calldata _amounts) external;

  //Single Token with multiple Metadata slots
  function mintWithMetadaSlots(
    address _to,
    uint256 _baseId,
    uint256[] calldata _metaverseIds,
    string [] calldata _metaverseMetadataTemplate
  ) external;

  //Multiple Token with single metadata slot
  function mintBatchWithMetadataSlot(
    address _to,
    uint256[] calldata _baseIds,
    uint256[] calldata _amounts,
    uint256 _metaverseId,
    string calldata _metaverseMetadataTemplate
  ) external;

  function uri(uint256 _tokenId) external view returns (string memory);

  function checkItemBaseId(uint256 _tokenId) external view returns (uint256 _baseID);

  function getCreatedBaseIds() external view returns (uint256[] memory);

  function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);
  
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