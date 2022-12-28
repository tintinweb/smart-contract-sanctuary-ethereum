import "./Dependencies.sol";
import "./TokenURI.sol";
// import "./FutureHistoricals.sol";
import "./ProxyERC721.sol";
import "./BaseERC721.sol";

pragma solidity ^0.8.11;


contract FutureHistoricalBase is ERC721, Ownable {
  string public license = 'CC BY-NC 4.0';

  mapping(uint256 => address) public tokenIdToAddress;

  TokenURI private _tokenURIContract;
  uint256 private _totalSupply = 1;

  uint256 private _parentTokenId;

  address private minter;
  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 1000;

  address private _refContract;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  // SETUP
  constructor() ERC721('Future Historicals', 'FUTURE') {
    minter = msg.sender;
    royaltyBenificiary = msg.sender;
    _tokenURIContract = new TokenURI('TODO: replace with something cooler');

    _refContract = address(new BaseERC721(0));

    _mint(msg.sender, 0);
  }


  // BASE FUNCTIONALITY
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function mint(address to) external {
    require(minter == msg.sender, 'Caller is not the minting address');

    _mint(to, _totalSupply);

    ProxyERC721 proxy = new ProxyERC721(_refContract, _totalSupply);
    tokenIdToAddress[_totalSupply] = address(proxy);

    _totalSupply += 1;
  }


  // Events
  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(_msgSender(), eventType, content);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    BaseERC721(tokenIdToAddress[tokenId]).transferOwnership(from, to);
    return super._transfer(from, to, tokenId);
  }


  // Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIContract.tokenURI(tokenId);
  }

  function setTokenURIContract(address _tokenURIAddress) external onlyOwner {
    _tokenURIContract = TokenURI(_tokenURIAddress);
  }

  function tokenURIContract() external view returns (address) {
    return address(_tokenURIContract);
  }


  // Contract owner actions
  function updateLicense(string calldata newLicense) external onlyOwner {
    license = newLicense;
  }

  // Royalty Info
  function setRoyaltyInfo(
    address _royaltyBenificiary,
    uint16 _royaltyBasisPoints
  ) external onlyOwner {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}