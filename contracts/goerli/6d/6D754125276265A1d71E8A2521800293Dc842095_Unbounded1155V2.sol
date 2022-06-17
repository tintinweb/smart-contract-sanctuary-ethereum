// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IERC1155721.sol";

// import "./lzApp/NonblockingLzApp.sol";
// import "./interfaces/IONFT1155.sol";

// import "./lib/Controller.sol";

// contract Unbounded1155V2 is ERC1155, NonblockingLzApp, IERC1155Receiver, IONFT1155 {
contract Unbounded1155V2 is ERC1155, IERC1155Receiver {
  // Add the library methods

  using EnumerableSet for EnumerableSet.UintSet;

  /*==================================================== Events =============================================================*/
  event MetaverseRegistered(address metaverse, uint256 metaverseId, string metaverseName, string metaverseMetadata);
  event MetaverseRemoved(address metaverse);
  event NewItemtemplateCreated(uint256 baseId, uint256 minId, uint256 maxId, string uri);
  event TemplateEdited(uint256 baseId,uint256 minId, uint256 maxId, string uri);
  event MetaverseURIAdded(uint256 baseId, uint256 tokenId, uint256 metaverseId, string uri);
  event MetaverseURIReset(uint256 tokenId, uint256 metaverseId);
  event MetaverseURIUpdated(bytes signature, uint256 metaverseId, uint256 tokenId, string newUri);
  event ItemMinted(uint256 baseId, uint256 count);

  /*==================================================== Modifiers =========================================================*/
  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }
  /*==================================================== State Variables ====================================================*/

  /**
    *Struct for the NFT Item Template
    *@param baseId: Id of the Item
    *@param minTokenId: Minimum mintable Token Id of the NFT
    *@param maxTokenId: Maximum mintable Token Id of the NFT
    *@param mintCount: Minted Count of the NFT
    *@param templateURI: Template URI for the NFT

    *@notice
    *1      - 10.000 => pen    //same baseURI  //baseID = 1
    *10.001 - 20.000 => house  //same baseURI  //baseID = 2
    *20.001 - 30.000 => car    //same baseURI  //baseID = 3
    *30.001 - 40.000 => sword  //same baseURI  //baseID = 4
   */
  struct TemplateData {
    uint256 baseID;
    uint256 minTokenID;
    uint256 maxTokenID;
    uint256 mintCount;
    string templateURI;
  }

  //To prevent stack too deep error in solidity!
  struct SendParameters {
    address sender;
    uint16 dstChainId;
    bytes toAddress;
    uint256 tokenId;
    uint256 baseId;
    uint256 amount;
    address payable refundAddress;
    address zroPaymentAddress;
    bytes adapterParam;
  }

  /**
   *@param wallet: Wallet Address of the Metaverse
   *@param id: Metaverse Id given by the contract
   *@param name: Metaverse Name
   *@param metaverseTemplateMetadata: Metaverses Standart Uri Schema
   */
  struct Metaverse {
    address wallet;
    uint256 id;
    string name;
    string metaverseMetadataTemplate;
  }

  struct TransferredToken {
    uint256 tokenID;
    uint256 baseID;
    bytes identifier;
    bool isLocked;
  }

  EnumerableSet.UintSet private metaverses;
  EnumerableSet.UintSet private itemBaseIds;

  //Base URI address("https://metada-uri.s3.eu-central-1.amazonaws.com/template/")
  string public baseURI;

  string public name;

  string public symbol;

  //Admin of this Contract
  address public admin;

  //Counts the created NFT Item Templates
  uint256 public templateBaseIDCount;

  //Counts the Metaverse IDs, every registration increase this value by one.
  uint256 public metaverseIDs;

  bytes32 public constant METAVERSE_ROLE = keccak256("METAVERSE_ROLE");

  //Stores registered metaverses to the contract // Metaverse wallet => Metaverse Struct
  mapping(address => Metaverse) public registeredMetaverses;

  //Stores NFT's Metaverse URI //NFT Token ID => Metaverse ID => Metaverse URI
  mapping(uint256 => mapping(uint256 => string)) public tokenMetaverseURI;

  //Stores NFT Template Information//NFT Base ID => BaseUriMinMax Struct
  mapping(uint256 => TemplateData) public templateInfo;

  // //Stores Token URIs *****Deprecated******
  // mapping(uint256 => string[]) public tokenURIs;

  //Stores the Template Token URI
  mapping(uint256 => string) public tokenURI;

  //Stores the used signatures, prevents using multiple times the same signature.
  mapping(bytes => bool) private inoperativeSignatures;

  //Stores a locked token information that is transferred to another chain.
  mapping(uint256 => bytes) public sendToken;
  mapping(bytes => uint256) public recievedToken;

  mapping(uint256 => uint256) public transferredBaseIDCount;

  // mapping(bytes => uint256) public globaltransferredId;

  /*==================================================== Constructor ========================================================*/
  /**
   Sets admin address, Market Place address and base URI for NFT Metadata.
  */
  //_uri ="https://metada-uri.s3.eu-central-1.amazonaws.com/{id}.json"

  // constructor(string memory uri_, address _lzEndpoint) ERC1155(uri_) NonblockingLzApp(_lzEndpoint) {
  constructor(string memory uri_) ERC1155(uri_) {
    admin = msg.sender;
    name = "mQuark";
    symbol ="MQRK";
    // _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    baseURI = uri_;//"https://metada-uri.s3.eu-central-1.amazonaws.com/template/"
  }

  /*==================================================== FUNCTIONS ==========================================================*/
  /*==================================================== External-Public Functions ==========================================*/

  /**
   *Users can mint among created NFT Templates with a given Base ID, it stores template URI and increases mint count for the Base Id
   *@param _baseId: The Base Id of the NFT that will be minted by the user
  */
  //with given _baseId it mints NFT to people and stores its created version URI.
  function mint(uint256 _baseId) external {
    TemplateData memory _item = templateInfo[_baseId];
    require(_baseId != 0, "Invalid ID!");
    require(_item.maxTokenID != 0,"Can't mint an unexisting token!");
    require(_item.mintCount <= (_item.maxTokenID - _item.minTokenID), "Can't mint anymore, please contact admins!");
    unchecked {
      uint256 mintId = _item.minTokenID + _item.mintCount;

      _mint(msg.sender, mintId, 1, "");

    // tokenURI[mintId] = _item.templateURI;
      templateInfo[_baseId].mintCount += 1;
      emit ItemMinted(_baseId, mintId);
    }
  }

  function mintBatch(uint256[] calldata _baseIds, uint256[] calldata _amounts) external {

    require(_baseIds.length == _amounts.length, "Specify equal number of Base IDs and and its amounts!");
    require(_baseIds.length <= 5, "You can't mint more than 5 different templates!");

    for (uint256 i; i < _baseIds.length; i++) {

      TemplateData memory _item = templateInfo[_baseIds[i]];

      require(_baseIds[i] != 0 && _amounts[i] != 0, "Invalid Base ID or amount!");
      require(_amounts[i] <= 10, "Can't mint more than 10!");
      require(_item.maxTokenID != 0,"Can't mint an unexisting token!");
      unchecked{require((_item.mintCount + _amounts[i]) <= (_item.maxTokenID - _item.minTokenID + 1), "Can't mint this amount, please contact admins!");}
      uint256 _amount = _amounts[i];

      for (uint256 j; j < _amount; j++) {
        unchecked {
          uint256 mintId = _item.minTokenID + _item.mintCount;
          _mint(msg.sender, mintId, 1, "");
         // tokenURI[mintId] = _item.templateURI;
          _item.mintCount++;
          emit ItemMinted(_baseIds[i], mintId);
        }
      }
      unchecked {templateInfo[_baseIds[i]].mintCount += _amounts[i];}
    }
  }

  function mintWithMetadaSlots(uint256 _baseId, uint256[] calldata _metaverseIds, address[] calldata _metaverseWallets) external {
    TemplateData memory _item = templateInfo[_baseId];
    require(_baseId != 0, "Invalid ID!");
    require(_item.mintCount <= (_item.maxTokenID - _item.minTokenID), "Can't mint anymore, please contact admins!");
    unchecked {
      uint256 mintId = _item.minTokenID + _item.mintCount;

      _mint(msg.sender, mintId, 1, "");

      //tokenURI[mintId] = _item.templateURI;
      templateInfo[_baseId].mintCount++;

      addBatchMetaverseSlotsToTemplate(_baseId,mintId,_metaverseIds,_metaverseWallets);

      emit ItemMinted(_baseId, mintId);
    }
    
  }

  // function mintAfterTransfer(
  //   uint256 _tokenId,
  //   uint256 _baseId,
  //   address _toAddress
  // ) internal returns (uint256 _mintId) {
  //   _mintId = (_baseId * 1000000) + transferredBaseIDCount[_baseId];
  //   _mint(_toAddress, _mintId, 1, "");
  //   tokenURI[_mintId] = templateInfo[_baseId].templateURI;
  //   transferredBaseIDCount[_baseId]++;
  // }

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

    unchecked{
      uint256 id = ++metaverseIDs;
      registeredMetaverses[_wallet] = Metaverse(_wallet,id,_name,_metaverseMetadataTemplate);
      emit MetaverseRegistered(_wallet, id, _name, _metaverseMetadataTemplate);
    }
    
  }

  function removeMetaverse(address _wallet) external onlyAdmin {
    require(registeredMetaverses[_wallet].wallet != address(0), "Can't delete an un-registered Metaverse");
    delete registeredMetaverses[_wallet];
    // _revokeRole(METAVERSE_ROLE,_wallet);

    emit MetaverseRemoved(_wallet);
  }

  /**
   *Creates a new NFT Item Template
   *@param _minId: Minimum mintable Token Id of the NFT
   *@param _maxId: Maximum mintable Token Id of the NFT
   *@param _uri: Template URI for the NFT
   */
  function createTemplate(
    uint256 _minId,
    uint256 _maxId,
    string calldata _uri
  ) external onlyAdmin {
    uint256 baseIDCount = ++templateBaseIDCount;
    _storeBaseUri(baseIDCount, _minId, _maxId, _uri);
    emit NewItemtemplateCreated(baseIDCount, _minId, _maxId, _uri);
  }

  /**
   *Creates new NFT Item Templates
   *@param _minIds: Minimum mintable Token Ids of the NFT
   *@param _maxIds: Maximum mintable Token Ids of the NFT
   *@param _uris: Template URIs for the NFT
   */
  function createBatchTemplate(
    uint256[] calldata _minIds,
    uint256[] calldata _maxIds,
    string[] calldata _uris
  ) external onlyAdmin {
    require(_minIds.length <= 100,"Invalid amount of template creation!");
    require(_minIds.length == _maxIds.length, "Length mismatch!");
    require(_maxIds.length == _uris.length, "Length mismatch!");
    uint256 baseIDCount = templateBaseIDCount;
    for (uint256 i = 0; i < _minIds.length; i++) {
      unchecked {baseIDCount++;}
      _storeBaseUri(baseIDCount, _minIds[i], _maxIds[i], _uris[i]);
      emit NewItemtemplateCreated(baseIDCount,_minIds[i], _maxIds[i], _uris[i]);
    }
    templateBaseIDCount = baseIDCount;
  }


  //*@notice to keep mintCount balance, changing min token id will create a dead zone !(there might not be happening any mint event for some token ids)
  function editTemplate(
    uint256 _baseID,
    uint256 _minTokenID,
    uint256 _maxTokenID,
    string calldata _uri
  ) external onlyAdmin {
    TemplateData memory _template = templateInfo[_baseID];
    unchecked {
      require(_maxTokenID > _minTokenID,"Max Token ID should be bigger than Min token ID!");
      require((_maxTokenID - _minTokenID) >= _template.mintCount,"Invalid min and max token ID parameters!");
    }
    _template.minTokenID = _minTokenID;
    _template.maxTokenID = _maxTokenID;
    _template.templateURI = _uri;
    templateInfo[_baseID] = _template;
    emit TemplateEdited(_baseID,_minTokenID,_maxTokenID,_uri);
  }

  /**
   *Users can create a new URI for the Metaverses
   *@param _baseId: Base Id of the NFT
   *@param _tokenId: NFT Token Id
   *@param _metaverseId: Metaverse Id which is given when registration
   *@param _metaverseWallet: Metaverse Wallet
   */
  function addMetadataSlotToTemplate(
    uint256 _baseId,
    uint256 _tokenId,
    uint256 _metaverseId,
    address _metaverseWallet
  ) public {
    require(balanceOf(msg.sender, _tokenId) == 1, "You don't have the token!");
    require(_metaverseId > 0, "ID can't be zero!");
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Metaverse wallet and id mismatch!");

    string memory metaverseMetadataTemplate = registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate;

    tokenMetaverseURI[_tokenId][_metaverseId] = metaverseMetadataTemplate;

    emit MetaverseURIAdded(_baseId, _tokenId, _metaverseId, metaverseMetadataTemplate);
  }

  function addBatchMetaverseSlotsToTemplate(
    uint256  _baseId,
    uint256  _tokenId,
    uint256[] calldata _metaverseIds,
    address[] calldata _metaverseWallets
  ) public {

    require(_metaverseIds.length == _metaverseWallets.length, "Wrong given number of parameters!");
    for (uint256 i = 0; i < _metaverseIds.length; i++) {
      require(_metaverseIds[i] > 0, "ID can't be zero!");
      require(registeredMetaverses[_metaverseWallets[i]].id == _metaverseIds[i], "Metaverse wallet and ID mismatch!");
      addMetadataSlotToTemplate(_baseId, _tokenId, _metaverseIds[i], _metaverseWallets[i]);
    }
  }

  /**
   *Users can update their metaverse metadata with a signed data by the metaverse
   *@param _signature: Signed Data by the Registered Metaverse Wallet Address
   *@param _metaverseWallet: Metaverse wallet address
   *@param _metaverseId: Metaverse Id which is given when registration
   *@param _tokenId: NFT Token Id
   *@param _newURI: New URI which will be replaced with the current URI
   *@param _salt: Salt of the signature
   */
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

    bool isVerified = _verify(_signature, _metaverseWallet, _metaverseId, _tokenId, _newURI, _salt);
    if (isVerified) {
      tokenMetaverseURI[_tokenId][_metaverseId] = _newURI;
      inoperativeSignatures[_signature] = true;

      emit MetaverseURIUpdated(_signature, _metaverseId, _tokenId, _newURI);
    } else revert("Can't verify the signature!");
  }


  function resetMetaverseURI(uint256 _tokenId,address _metaverseWallet, uint256 _metaverseId) external {
    require(msg.sender == registeredMetaverses[_metaverseWallet].wallet,"");
    require(registeredMetaverses[_metaverseWallet].id == _metaverseId, "Invalid Metaverse Parameters!");
    tokenMetaverseURI[_tokenId][_metaverseId] = registeredMetaverses[_metaverseWallet].metaverseMetadataTemplate;
    emit MetaverseURIReset(_tokenId,_metaverseId);
  }


  function recoverNFT(
    address contractAddress,
    uint256 _tokenID,
    uint256 _amount,
    bool _isERC1155
  ) external onlyAdmin {
    _isERC1155
      ? IERC1155721(contractAddress).safeTransferFrom(address(this), msg.sender, _tokenID, _amount, "")
      : IERC1155721(contractAddress).safeTransferFrom(address(this), msg.sender, _tokenID, "");
  }

  /*==================================================== Read Functions =====================================================*/
  // /**
  //  *Returns Token URI, for the specific ID.
  //  *@param _tokenId: ID of the NFT
  //  *@return URI for the ID
  //  */
  function uri (uint256 tokenId) override public view returns (string memory) {
    uint256 templateId = this.checkItemBaseId(tokenId);
    return (string(abi.encodePacked(baseURI, Strings.toString(templateId),".json")));
  }

  // /**
  //  *Returns Token URIs, for the specific ID.
  //  *@param _tokenId: ID of the NFT
  //  */
  // function getURIsForID(uint256 _tokenId) external view returns (string[] memory _uris) {
  //   _uris = tokenURIs[_tokenId];
  // }

  /**
   *Returns NFT Base Id with given NFT Token Id
   *@param _tokenId: NFT Token Id
   */
  function checkItemBaseId(uint256 _tokenId) external view returns (uint256 _baseID) {
    for (uint256 i = 1; i < (templateBaseIDCount + 1); i++) {
      if (templateInfo[i].minTokenID <= _tokenId && _tokenId <= templateInfo[i].maxTokenID) {
        return templateInfo[i].baseID;
      }
    }
    return 0;
  }

  function getCreatedBaseIds() external view returns (uint256[] memory) {
    return itemBaseIds.values();
  }

  /*==================================================== Internal Functions =================================================*/

  function _storeBaseUri(
    uint256 _baseId,
    uint256 _minId,
    uint256 _maxId,
    string calldata _uri
  ) internal {
    // require(!itemBaseIds.contains(_baseId), "This Item Base id has already stored!");
    require(_minId <= _maxId, "Wrong given parameters!");
    itemBaseIds.add(_baseId);
    templateInfo[_baseId] = TemplateData(_baseId,_minId,_maxId,0,_uri);
  }

  /**
   *Checks whether a signature is valid with given parameters
   *@param signature: The signed data by the Signer
   *@param metaverse: Metaverse Address
   *@param metaverseId: Metaverse Id which is given by the contract
   *@param tokenId: NFT Token Id
   *@param _uri: URI
   *@param salt: Salt for the uniqueness
   */
  function _verify(
    bytes memory signature,
    address metaverse,
    uint256 metaverseId,
    uint256 tokenId,
    string memory _uri,
    bytes memory salt
  ) internal view returns (bool) {
    require(!inoperativeSignatures[signature], "already given");
    bytes32 messageHash = keccak256(abi.encode(metaverse, metaverseId, tokenId, _uri, salt));
    bytes32 signed = ECDSA.toEthSignedMessageHash(messageHash);
    address signer = ECDSA.recover(signed, signature);
    return (metaverse == signer);
  }

  function _onlyAdmin() internal view {
    require(admin == msg.sender, "You are not allowed!");
  }

  function supportsInterface(bytes4 interfaceId) public pure override(ERC1155, IERC165) returns (bool) {
    return (interfaceId == type(IERC1155Receiver).interfaceId);
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    // require(Controller.equals(data, magicData), "No direct transfer!");
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return 0x00;
  }

  /*==================================================== Layer Zero ====================================================*/

  // function estimateSendFee(
  //   uint16 _dstChainId,
  //   bytes calldata, /*_toAddress*/
  //   uint256, /*_tokenId*/
  //   uint256, /*_amount*/
  //   bool _useZro,
  //   bytes calldata _adapterParams
  // ) external view virtual override returns (uint256 nativeFee, uint256 zroFee) {
  //   // by sending a uint array, we can decode the payload on the other side the same way regardless if its a batch
  //   uint256[] memory tokenIds = new uint256[](1);
  //   uint256[] memory amounts = new uint256[](1);
  //   tokenIds[0] = 0;
  //   amounts[0] = 0;
  //   bytes memory payload = abi.encode(address(0x0), tokenIds, amounts);

  //   return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
  // }

  // function estimateSendBatchFee(
  //   uint16 _dstChainId,
  //   bytes calldata, /*_toAddress*/
  //   uint256[] memory _tokenIds,
  //   uint256[] memory _amounts,
  //   bool _useZro,
  //   bytes calldata _adapterParams
  // ) external view virtual override returns (uint256 nativeFee, uint256 zroFee) {
  //   bytes memory payload = abi.encode(address(0x0), _tokenIds, _amounts);
  //   return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
  // }

  // // function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, uint _amount, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParam) external payable virtual {
  // //   _send(_from, _dstChainId, _toAddress, _tokenId, _amount, _refundAddress, _zroPaymentAddress, _adapterParam);
  // // }

  // function sendBatchFrom(
  //   address _from,
  //   uint16 _dstChainId,
  //   bytes calldata _toAddress,
  //   uint256[] memory _tokenIds,
  //   uint256[] memory _amounts,
  //   address payable _refundAddress,
  //   address _zroPaymentAddress,
  //   bytes calldata _adapterParam
  // ) external payable virtual {
  //   _sendBatch(_from, _dstChainId, _toAddress, _tokenIds, _amounts, _refundAddress, _zroPaymentAddress, _adapterParam);
  // }

  // function send(
  //   uint16 _dstChainId,
  //   bytes calldata _toAddress,
  //   uint256 _tokenId,
  //   uint256 _baseId,
  //   uint256 _amount,
  //   address payable _refundAddress,
  //   address _zroPaymentAddress,
  //   bytes calldata _adapterParam
  // ) external payable virtual override {
  //   SendParameters memory _sendParams = SendParameters(
  //     _msgSender(),
  //     _dstChainId,
  //     _toAddress,
  //     _tokenId,
  //     _baseId,
  //     _amount,
  //     _refundAddress,
  //     _zroPaymentAddress,
  //     _adapterParam
  //   );
  //   _send(_sendParams);
  // }

  // function sendBatch(
  //   uint16 _dstChainId,
  //   bytes calldata _toAddress,
  //   uint256[] memory _tokenIds,
  //   uint256[] memory _amounts,
  //   address payable _refundAddress,
  //   address _zroPaymentAddress,
  //   bytes calldata _adapterParam
  // ) external payable virtual override {
  //   _sendBatch(_msgSender(), _dstChainId, _toAddress, _tokenIds, _amounts, _refundAddress, _zroPaymentAddress, _adapterParam);
  // }

  // function _send(SendParameters memory _sendParams) internal virtual {
  //   require(_msgSender() == _sendParams.sender || isApprovedForAll(_sendParams.sender, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
  //   uint16 _srcChainId = lzEndpoint.getChainId();

  //   // on the src chain we burn the tokens before sending
  //   bytes memory _identifier = _beforeSend(_sendParams.sender, _srcChainId, _sendParams.toAddress, _sendParams.tokenId, _sendParams.amount);

  //   // by sending a uint array, we can decode the payload on the other side the same way regardless if its a batch
  //   uint256[] memory tokenIds = new uint256[](1);
  //   uint256[] memory amounts = new uint256[](1);
  //   tokenIds[0] = _sendParams.tokenId;
  //   amounts[0] = _sendParams.amount;

  //   bytes memory payload = abi.encode(_sendParams.toAddress, _identifier, tokenIds, _sendParams.baseId, amounts);

  //   // push the tx to L0
  //   _lzSend(_sendParams.dstChainId, payload, _sendParams.refundAddress, _sendParams.zroPaymentAddress, _sendParams.adapterParam);

  //   uint64 nonce = lzEndpoint.getOutboundNonce(_sendParams.dstChainId, address(this));
  //   emit SendToChain(_sendParams.sender, _sendParams.dstChainId, _sendParams.toAddress, _sendParams.tokenId, _sendParams.amount, nonce);

  //   // _afterSend(_from, _dstChainId, _toAddress, _tokenId, _amount);
  // }

  // function _sendBatch(
  //   address _from,
  //   uint16 _dstChainId,
  //   bytes memory _toAddress,
  //   uint256[] memory _tokenIds,
  //   uint256[] memory _amounts,
  //   address payable _refundAddress,
  //   address _zroPaymentAddress,
  //   bytes calldata _adapterParam
  // ) internal virtual {
  //   require(_tokenIds.length == _amounts.length, "ONFT1155: ids and amounts must be same length");
  //   require(_msgSender() == _from || isApprovedForAll(_from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");

  //   // on the src chain we burn the tokens before sending
  //   // _beforeSendBatch(_from, _dstChainId, _toAddress, _tokenIds, _amounts);

  //   bytes memory payload = abi.encode(_toAddress, _tokenIds, _amounts);
  //   _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParam);

  //   uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
  //   emit SendBatchToChain(_from, _dstChainId, _toAddress, _tokenIds, _amounts, nonce);
  //   // _afterSendBatch(_from, _dstChainId, _toAddress, _tokenIds, _amounts);
  // }

  // function _nonblockingLzReceive(
  //   uint16 _srcChainId,
  //   bytes memory,
  //   uint64 _nonce,
  //   bytes memory _payload
  // ) internal virtual override {
  //   // _beforeReceive(_srcChainId, _srcAddress, _payload);

  //   // decode and load the toAddress
  //   (bytes memory toAddress, bytes memory _identifier, uint256[] memory tokenIds, uint256 baseId, uint256[] memory amounts) = abi.decode(
  //     _payload,
  //     (bytes, bytes, uint256[], uint256, uint256[])
  //   );
  //   address localToAddress;
  //   assembly {
  //     localToAddress := mload(add(toAddress, 20))
  //   }

  //   // mint the tokens on the dst chain
  //   if (tokenIds.length == 1) {
  //     // _afterReceive(_srcChainId, localToAddress, tokenIds[0], baseId);
  //     _afterReceive(_identifier, localToAddress, tokenIds[0], baseId);
  //     emit ReceiveFromChain(_srcChainId, localToAddress, tokenIds[0], amounts[0], _nonce);
  //   } else if (tokenIds.length > 1) {
  //     // _afterReceiveBatch(_srcChainId, localToAddress, tokenIds, amounts);
  //     emit ReceiveBatchFromChain(_srcChainId, localToAddress, tokenIds, amounts, _nonce);
  //   }
  // }

  // function _beforeSend(
  //   address _from,
  //   uint16 _srcChainId, /* _dstChainId */
  //   bytes memory, /* _toAddress */
  //   uint256 _tokenId,
  //   uint256 _amount
  // ) internal virtual returns (bytes memory identifier) {
  //   // _burn(_from, _tokenId, _amount);
  //   safeTransferFrom(_from, address(this), _tokenId, _amount, "");

  //   //if this token is being transferred for the first time
  //   if (equals(sendToken[_tokenId], "")) {
  //     identifier = abi.encode(_srcChainId, _tokenId);
  //     sendToken[_tokenId] = identifier;
  //     recievedToken[identifier] = _tokenId;
  //   } else {
  //     identifier = sendToken[_tokenId];
  //   }
  // }

  // function _afterReceive(
  //   bytes memory _identifier, /* _srcChainId */
  //   address _toAddress,
  //   uint256 _tokenId,
  //   uint256 _baseId
  // ) internal virtual // uint _amount
  // {
  //   if (recievedToken[_identifier] == 0) {
  //     uint256 _mintedId = mintAfterTransfer(_tokenId, _baseId, _toAddress);
  //     sendToken[_mintedId] = _identifier;
  //     recievedToken[_identifier] = _mintedId;
  //   } else {
  //     safeTransferFrom(address(this), _toAddress, recievedToken[_identifier], 1, "");
  //   }
  // }

  //=====================================================Utility Functions ==================================================
  // function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
  //   if (self.length != other.length) {
  //     return false;
  //   }
  //   uint256 addr;
  //   uint256 addr2;
  //   assembly {
  //     addr := add(
  //       self,
  //       /*BYTES_HEADER_SIZE*/
  //       32
  //     )
  //     addr2 := add(
  //       other,
  //       /*BYTES_HEADER_SIZE*/
  //       32
  //     )
  //   }
  //   equal = memoryEquals(addr, addr2, self.length);
  // }

  // function memoryEquals(
  //   uint256 addr,
  //   uint256 addr2,
  //   uint256 len
  // ) internal pure returns (bool equal) {
  //   assembly {
  //     equal := eq(keccak256(addr, len), keccak256(addr2, len))
  //   }
  // }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

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
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
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

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
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
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
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

        address operator = _msgSender();
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

        address operator = _msgSender();

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
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
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

        address operator = _msgSender();
        // uint256[] memory ids = _asSingletonArray(id);
        // uint256[] memory amounts = _asSingletonArray(amount);

        // _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += 1;
        emit TransferSingle(operator, address(0), to, id, 1);

        // _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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

        address operator = _msgSender();

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

        address operator = _msgSender();
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

        address operator = _msgSender();

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
     * Emits a {ApprovalForAll} event.
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155721 { 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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