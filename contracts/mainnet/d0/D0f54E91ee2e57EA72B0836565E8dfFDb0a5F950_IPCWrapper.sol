// SPDX-License-Identifier: MIT
// Creator: Johnny L. de Alba

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

interface IPCCore {

  event Logging(address sender);

  function getIpc(uint256 ipcId)
    external view returns (
    string calldata name,
    bytes32 attributeSeed,
    bytes32 dna,
    uint128 experience,
    uint128 timeOfBirth);

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

contract IPCWrapper is Ownable, ERC721A__IERC721Receiver, ERC721A {

  using Strings for uint256;

  struct t_properties {

    address contractAdress;
    string tokenURI;
    string contractURI;
    uint256 maxPrice;
    uint256 tokenLimit;
  }

  struct t_token {
    uint tokenId;
    address owner;
  }

  struct t_raw_ipc {
    uint256 tokenId;
    string name;
    bytes32 attributeSeed;
    bytes32 dna;
    uint128 experience;
    uint128 timeOfBirth;
    address owner;
  }

  address contractAddress;

  string _tokenURI;
  string _contractURI;

  uint256 maxPrice;
  uint256 tokenLimit;

  mapping(uint256 => t_token) tokens;
  mapping(uint256 => uint256) tokenIndexList;
  mapping(address => uint256[]) tokensOfOwner;

  event Wrapped(uint256, uint256, address);
  event Unwrapped(uint256, uint256, address);
  event nameChangeOK(uint256, string);

  constructor() ERC721A("Immortal Player Characters v0", "IPCV0") {

    contractAddress = 0xACE8AA6699F1E71f07622135A93140cA296D610a;
    _tokenURI = "https://nexusultima.com/ipcv0/tokens/";
    _contractURI = "https://nexusultima.com/ipcv0/contract/";

    maxPrice = 1000000;
    tokenLimit = 1000;
  }

  function _removeOwnersToken(address owner, uint256 tokenId) 
    private {

      uint256 total = tokensOfOwner[owner].length;
      for (uint256 index = 0; index < total; index++) {

        if (tokensOfOwner[owner][index] == tokenId) {

          tokensOfOwner[owner][index] = tokensOfOwner[owner][total - 1];
  	  tokensOfOwner[owner].pop();
        }
      }
  }

  function _swapTokenOwner(address from, address to, uint256 tokenId)
    private {

      if (from == address(0))
        return;

      uint256 tokenIndex = getTokenIndex(tokenId);

      tokens[tokenIndex].owner = to;
      _removeOwnersToken(from, tokenId);

      tokensOfOwner[to].push(tokenId);
  }

  function getTokenIndex(uint256 tokenId)
    public view returns (uint256) {
      return tokenIndexList[tokenId];
  }

  // Wrap function doesn't work without prior approval.
  function wrap(uint256 tokenId)
    external {

      uint256 tokenIndex = getTokenIndex(tokenId);

      if (_nextTokenId() >= (2**256 - 1))
        revert("UNABLE_TO_WRAP_TOKEN");

      if (tokenId > tokenLimit && tokenIndex == 0)
        revert("TOKEN_LIMIT_REACHED");

      address sender = _msgSenderERC721A();

      // If the token was stolen tokenIndex will not be equal to 0. We want the function to wrap
      // reguardless, otherwise the database could get corrupted.

      if (tokenIndex != 0) {

        if (tokens[tokenIndex].owner != sender) {
          revert("NOT_OWNERS_TOKEN");
        }
	else {
	  revert("TOKEN_ALREADY_WRAPPED");
	}
      }
      else {
        tokenIndex = _nextTokenId();
      }

      address sourceOwner = ownerOf(tokenId);
      if (sourceOwner != sender)
        revert("NOT_OWNERS_TOKEN");

      IPCCore(contractAddress).safeTransferFrom(
        sender,
	address(this),
	tokenId
      );

      IPCCore(contractAddress).setIpcPrice(tokenId, maxPrice);

      tokens[tokenIndex] = t_token(tokenId, sender);
      tokenIndexList[tokenId] = tokenIndex;
      tokensOfOwner[sender].push(tokenId);

      _safeMint(sender, 1);

      emit Transfer(address(0), sender, tokenId);   
      emit Wrapped(tokenIndex, tokenId, sender);
  }

  function unwrap(uint256 tokenId) public {

    uint256 tokenIndex = getTokenIndex(tokenId);

    if (tokenIndex == 0) {
      revert("TOKEN_NOT_WRAPPED");
    }

    address sender = _msgSenderERC721A();

    if (tokens[tokenIndex].owner != sender) {
      revert("NOT_OWNERS_TOKEN");
    }

    delete tokenIndexList[tokenId];
    delete tokens[tokenIndex];

    address sourceOwner = ownerOf(tokenId);

    _removeOwnersToken(sender, tokenId);
    _burn(tokenIndex);

    // If sourceOwner is not equal to contract then the token was stolen and the function will unwrap anyways. 
    if (sourceOwner == address(this)) {

      IPCCore(contractAddress).safeTransferFrom(
        address(this),
        sender,
        tokenId
      );
    }

    emit Transfer(sender, address(0), tokenId);   
    emit Unwrapped(tokenIndex, tokenId, sender);
  }

  // changeIpcName only works on wrapped tokens.
  function changeIpcName(uint tokenId, string calldata newName)
    external payable {

      uint256 tokenIndex = getTokenIndex(tokenId);

      if (tokens[tokenIndex].owner != msg.sender)
        revert("TOKEN_NOT_OWNER");

      IPCCore(contractAddress).changeIpcName{value: msg.value}(tokenId, newName);
      emit nameChangeOK(tokenId, newName);
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

      address owner = ownerOf(tokenId);
      t_raw_ipc memory token = t_raw_ipc(	  
        tokenId,
        name,
        attributeSeed,
        dna,
        experience,
        timeOfBirth,
        owner
      );

      return token;
  }

  function getTokensOfOwner(address owner, uint256 startIndex, uint256 total)
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

  function uwOwnerOf(uint256 tokenId)
    public view returns (address) {
        return IPCCore(contractAddress).ownerOf(tokenId); 
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

  function uwBalanceOf(address owner)
    public view
    returns(uint256){

      uint256[] memory ownersTokens = IPCCore(contractAddress).tokensOfOwner(owner);
      return ownersTokens.length;
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

  function setProperties(
    uint256 _maxPrice,
    uint256 _tokenLimit,
    string calldata __tokenURI,
    string calldata __contractURI
  ) public onlyOwner {

      maxPrice = _maxPrice;
      tokenLimit = _tokenLimit;

      _tokenURI = __tokenURI;
      _contractURI = __contractURI;
  }

  function getProperties()
    public view onlyOwner
    returns (t_properties memory) {

      t_properties memory status = t_properties(
        contractAddress,
        _tokenURI,
        _contractURI,
        maxPrice,
        tokenLimit
      );

    return status;
  }

  function withdrawalVault()
    external
    onlyOwner {

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "VAULT_TRANSFER_FAILED");
  }

  function _startTokenId()
    internal view virtual override
    returns (uint256) { return 1; }

  function _baseURI() internal view override returns (string memory) {
    return _tokenURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

    t_raw_ipc memory ipc = getIpc(tokenId);

    if (ipc.tokenId == 0)
      revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
      return ERC721A__IERC721Receiver.onERC721Received.selector;
  }

  // Required in order to be compatible with the IPC contract.
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
      return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
  }

  function totalSupply() public view override returns (uint256) {
    return IPCCore(contractAddress).totalSupply();
  }

  function balanceOf(address owner)
    public view override returns(uint256){

      if (owner == address(0)) revert BalanceQueryForZeroAddress();
      return tokensOfOwner[owner].length;
  }

  function ownerOf(uint256 tokenId)
    public view override returns (address) {

      uint256 tokenIndex = getTokenIndex(tokenId);
      if (tokenIndex == 0) {
        return IPCCore(contractAddress).ownerOf(tokenId); 
      }

      address owner = tokens[tokenIndex].owner;
      return owner;
  }

  function approve(address to, uint256 tokenId)
    public override {

    uint256 tokenIndex = getTokenIndex(tokenId);

    if (tokenIndex == 0)
      revert("TOKEN_NOT_WRAPPED");

    address owner = ownerOf(tokenId);

    if (_msgSenderERC721A() != owner) {

      if (!isApprovedForAll(owner, _msgSenderERC721A())) {
        revert ApprovalCallerNotOwnerNorApproved();
      }
    }

    _approve(to, tokenIndex);
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public view override returns (address) {

      uint256 tokenIndex = getTokenIndex(tokenId);
      return super.getApproved(tokenIndex);
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {

      uint256 tokenId = tokens[startTokenId].tokenId;
      _swapTokenOwner(from, to, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
  
      uint256 tokenIndex = getTokenIndex(tokenId);

      super.transferFrom(from, to, tokenIndex);
      emit Transfer(from, to, tokenId);
  }
}