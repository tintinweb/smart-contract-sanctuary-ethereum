pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";

interface IPCCore {

  function getIpc(uint256 ipcId)
    external view returns (

    string calldata name,
    bytes32 attributeSeed,
    bytes32 dna,
    uint128 experience,
    uint128 timeOfBirth);

  struct IpcMarketInfo {

    uint32 sellPrice;
    uint32 beneficiaryPrice;
    address beneficiaryAddress;
    address approvalAddress;
  }

  function ipcToMarketInfo(uint key) external view returns (IpcMarketInfo memory);
  function ownerOf(uint256 tokenId) external view returns (address);
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
  function totalSupply() external view returns (uint256);
  function setIpcPrice(uint tokenId, uint newPrice) external;
  function changeIpcName(uint tokenId, string calldata newName) external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId)
    external payable;
}

contract IPCWrapper is Ownable, IERC721Receiver, ERC721 {

  using Strings for uint256;

  struct t_properties {

    address contractAdress;
    string tokenURI;
    string contractURI;
    uint256 maxPrice;
    uint256 tokenLimit;
    bool marketPlaceEnabled;
  }

  struct t_raw_ipc {
    uint256 tokenId;
    string name;
    bytes32 attributeSeed;
    bytes32 dna;
    uint128 experience;
    uint128 timeOfBirth;
    address owner;
    uint256 price;
  }

  string _tokenURI;
  string _contractURI;

  address contractAddress;
  uint256 maxPrice;
  uint256 tokenLimit;
  bool marketPlaceEnabled;

  mapping(address => uint256[]) tokensOfOwner;

  event Wrapped(uint256 tokenId, address owner);
  event Unwrapped(uint256 tokenId, address owner);
  event WrapX(address owner, bool wrapTokens, uint256 totalTokens);
  
  constructor(address _contractAddress) ERC721("Immortal Player Characters v0", "IPCV0") {

    contractAddress = _contractAddress;

    _tokenURI = "ipfs://bafybeiew3tzikhkjjczicycey6dgmddemmrbp3clsw7u5zdxgjsn4ss4yi/";
    _contractURI = "ipfs://bafybeiew3tzikhkjjczicycey6dgmddemmrbp3clsw7u5zdxgjsn4ss4yi/contract.json";

    maxPrice = 1000000;
    tokenLimit = 1000;
    marketPlaceEnabled = true;
  }

  function _removeOwnersToken(address owner, uint256 tokenId) 
    private {

      uint256 total = tokensOfOwner[owner].length;
      for (uint256 index = 0; index < total; index++) {

        if (tokensOfOwner[owner][index] == tokenId) {

          tokensOfOwner[owner][index] = tokensOfOwner[owner][total - 1];
  	  tokensOfOwner[owner].pop();

	  break;
        }
      }
  }

  function _swapTokenOwner(address from, address to, uint256 tokenId)
    private {

      if (from == address(0))
        return;

      _removeOwnersToken(from, tokenId);
      tokensOfOwner[to].push(tokenId);
  }

  // Wrap function doesn't work without prior approval.
  function wrap(uint256 tokenId) public {

      if (tokenId > tokenLimit)
        revert("TOKEN_LIMIT_REACHED");

      address wrappedOwner = wOwnerOf(tokenId);

      if (_exists(tokenId)) {
        
	if (wrappedOwner != address(this))
	  revert("TOKEN_ALREADY_WRAPPED");
      }

      address sourceOwner = uwOwnerOf(tokenId);
      if (sourceOwner != msg.sender)
        revert("WRAPPED_NOT_OWNER");

      IPCCore(contractAddress).safeTransferFrom(
        msg.sender,
	address(this),
	tokenId
      );

      if (marketPlaceEnabled)
        IPCCore(contractAddress)
          .setIpcPrice(tokenId, maxPrice);

      if (_exists(tokenId)) {
 
        _internalTransfer(
          address(this),
	  msg.sender,
	  tokenId
	);
      }
      else
        _safeMint(msg.sender, tokenId);

      emit Wrapped(tokenId, msg.sender);
  }

  function unwrap(uint256 tokenId) public {

    if (_exists(tokenId) == false)
      revert("TOKEN_NOT_WRAPPED");

    address wrappedOwner = wOwnerOf(tokenId);

    if (wrappedOwner == address(this))
      revert("TOKEN_NOT_WRAPPED");

    else if (wrappedOwner != msg.sender)
      revert("UNWRAPPED_NOT_OWNER");

    address sourceOwner = uwOwnerOf(tokenId);

    if (sourceOwner != address(this))
      revert("TOKEN_STOLEN");

    IPCCore(contractAddress).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );

    _internalTransfer(
      msg.sender,
      address(this),
      tokenId
    );

    emit Unwrapped(tokenId, msg.sender);
  }

  function wrapX(uint256 totalTokens, bool wrapTokens)
    external {

    uint256[] memory ownersTokenIds;
   
    if (wrapTokens == true)
      ownersTokenIds = uwGetTokenIdsOfOwner(msg.sender);
    else
      ownersTokenIds = wGetTokenIdsOfOwner(msg.sender);

    uint256 tokenId;

    if (totalTokens == 0 || totalTokens >= ownersTokenIds.length)
      totalTokens = ownersTokenIds.length;

    for (uint256 index = 0; index < totalTokens; index++) {

      tokenId = ownersTokenIds[index];
      if (tokenId <= 0)
        continue;
     
      if (wrapTokens == true)
        wrap(tokenId);
      else
        unwrap(tokenId);
    }

    emit WrapX(msg.sender, wrapTokens, totalTokens);
  }

/* Removed to reduce contract size so it can be deployable.

   // changeIpcName only works on wrapped tokens.
  function changeIpcName(uint256 tokenId, string calldata newName)
    external payable {

      if (wOwnerOf(tokenId) != msg.sender)
        revert("NAMECHANGE_NOT_OWNER");

      if (marketPlaceEnabled == false)
        revert("NAMECHANGE_DISABLED");

      IPCCore(contractAddress).changeIpcName{value: msg.value}(tokenId, newName);
      emit nameChangeOK(tokenId, newName);
  }
*/

  function totalSupply() public view returns (uint256) {
    return IPCCore(contractAddress).totalSupply();
  }

  function getIpc(uint256 tokenId)
    public view
    returns (t_raw_ipc memory) {
        
      (
        string memory name,
        bytes32 attributeSeed,
	bytes32 dna,
	uint128 experience,
	uint128 timeOfBirth
      ) = IPCCore(contractAddress).getIpc(tokenId);

      IPCCore.IpcMarketInfo memory marketInfo = IPCCore(contractAddress).ipcToMarketInfo(tokenId);

      address owner = wuwOwnerOf(tokenId);
      t_raw_ipc memory token = t_raw_ipc(	  
        tokenId,
        name,
        attributeSeed,
        dna,
        experience,
        timeOfBirth,
        owner,
	marketInfo.sellPrice
      );

      return token;
  }

  function wOwnerOf(uint256 tokenId)
    public view returns (address) {

    address owner = _owners[tokenId];
    return owner; 
  }

  function uwOwnerOf(uint256 tokenId)
    public view returns (address) {
        return IPCCore(contractAddress).ownerOf(tokenId); 
  }

  function wuwOwnerOf(uint256 tokenId)
    public view returns (address) {

      if (_exists(tokenId) == false ||
        wOwnerOf(tokenId) == address(this))
          return IPCCore(contractAddress).ownerOf(tokenId); 

      return wOwnerOf(tokenId);
  }

  function wBalanceOf(address owner)
    public view
    returns (uint256) {
      return _balances[owner];
  }

  function uwBalanceOf(address owner)
    public view
    returns(uint256){

      uint256[] memory ownersTokens = IPCCore(contractAddress).tokensOfOwner(owner);
      return ownersTokens.length;
  }

  function wGetTokenIdsOfOwner(address owner)
    public view
    returns(uint256[] memory){

      uint256[] memory ownersTokens = tokensOfOwner[owner];
      return ownersTokens;
  }
 
  function uwGetTokenIdsOfOwner(address owner)
    public view
    returns(uint256[] memory){

      uint256[] memory ownersTokens = IPCCore(contractAddress).tokensOfOwner(owner);
      return ownersTokens;
  }

  function uwGetAllTokens(uint256 startIndex, uint256 total)
    public view
    returns(t_raw_ipc[] memory) {

      uint256 totalTokens = totalSupply();

      if (startIndex == 0 || startIndex > totalTokens)
        startIndex = 1;

      if (totalTokens > 0) {

        if (total == 0 || total > totalTokens + 1 - startIndex)
          total = totalTokens - startIndex;
      }
      else {

        totalTokens = 0;
	total = 1;
      }

      t_raw_ipc[] memory tokensList = new t_raw_ipc[](total);
      if (totalTokens == 0)
        return tokensList;

      uint256 index;
      for (index = 0; index < total; index++) {

        uint256 tokenId = startIndex + index;
        t_raw_ipc memory token = getIpc(tokenId);

        tokensList[index] = token;
      }

      return tokensList;
  }

  function wGetTokensOfOwner(address owner, uint256 startIndex, uint256 total)
    public view
    returns(t_raw_ipc[] memory){

      uint256[] memory ownersTokens = tokensOfOwner[owner];
      uint256 totalTokens = ownersTokens.length;

      if (startIndex > totalTokens)
        startIndex = 0;

      if (totalTokens > 0) {

        if (total == 0 || total > totalTokens - startIndex)
          total = totalTokens - startIndex;
      }
      else {

        totalTokens = 0;
	total = 1;
      }

      t_raw_ipc[] memory tokensList = new t_raw_ipc[](total);
      if (totalTokens == 0)
        return tokensList;

      uint256 index;
      uint256 tokenId;

      t_raw_ipc memory token;

      for (index = 0; index < total; index++) {

        tokenId = ownersTokens[startIndex + index];
        token = getIpc(tokenId);

	tokensList[index] = token;
      }

      return tokensList;
  }

  function uwGetTokensOfOwner(address owner, uint256 startIndex, uint256 total)
    public view
    returns(t_raw_ipc[] memory){

      uint256[] memory ownersTokens = IPCCore(contractAddress).tokensOfOwner(owner);
      uint256 totalTokens = ownersTokens.length;
  
      if (startIndex > totalTokens)
        startIndex = 0;

      if (totalTokens > 0) {

        if (total == 0 || total > totalTokens - startIndex)
          total = totalTokens - startIndex;
     }
     else {

       totalTokens = 0;
       total = 1;
     }

      t_raw_ipc[] memory tokensList = new t_raw_ipc[](total);
      if (totalTokens == 0)
        return tokensList;

      uint256 index;
      uint256 tokenId;
      t_raw_ipc memory token;

      for (index = 0; index < total; index++) {

        tokenId = ownersTokens[startIndex + index];
        token = getIpc(tokenId);

	tokensList[index] = token;
      }

      return tokensList;
  }

  function setContractAddress(address _contractAddress) public onlyOwner {
    contractAddress = _contractAddress;
  }

  function setTokenomics(
    uint256 _maxPrice,
    uint256 _tokenLimit,
    bool _marketPlaceEnabled
  ) public onlyOwner {

      maxPrice = _maxPrice;
      tokenLimit = _tokenLimit;
      marketPlaceEnabled = _marketPlaceEnabled;
  }

   function setMetaDataURIs(
    string calldata __tokenURI,
    string calldata __contractURI
  ) public onlyOwner {

      _tokenURI = __tokenURI;
      _contractURI = __contractURI;
  }

  function getProperties()
    public view onlyOwner
    returns (t_properties memory) {

      t_properties memory properties = t_properties(
        contractAddress,
        _tokenURI,
        _contractURI,
        maxPrice,
        tokenLimit,
	marketPlaceEnabled
      );

      return properties;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function withdrawalVault()
    external
    onlyOwner {

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "VAULT_TRANSFER_FAILED");
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenURI;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {

      // mint
      if (from == address(0))
        tokensOfOwner[to].push(tokenId);
      // burn
      else if (to == address(0))
        _removeOwnersToken(from, tokenId);
      // transfer
      else
        _swapTokenOwner(from, to, tokenId);
  }

  function _internalTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {

      _beforeTokenTransfer(from, to, tokenId);

      delete _tokenApprovals[tokenId];

      unchecked {

        _balances[from] -= 1;
        _balances[to] += 1;
      }
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);
      _afterTokenTransfer(from, to, tokenId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
  }

  // Required by the IPC contract.
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
      return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
  }

}