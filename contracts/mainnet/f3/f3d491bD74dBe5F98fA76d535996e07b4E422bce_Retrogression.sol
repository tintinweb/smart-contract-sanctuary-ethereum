// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Ownable.sol';
import './Address.sol';
import './MerkleProof.sol';
import './Strings.sol';
import './SafeMath.sol';
import './ERC721A.sol';
import './ERC2981.sol';

error PublicSaleNotLive();
error WhiteListNotLive();
error OgListNotLive();
error ExceededLimit();
error NotEnoughTokensLeft();
error WrongEther();
error InvalidMerkle();
error OgListUsed();
error WhitelistUsed();
error MintZeroQuantity();

contract Retrogression is ERC721A, ERC2981, Ownable {
  using Address for address;
  using SafeMath for uint256;
  using MerkleProof for bytes32[];

  bytes32 public whiteListMerkleRoot; // root hash for verying whitelist address
  uint256 public whiteListMaxMint; // max mint each address can mint
  uint256 public totalMaxSupply; // total max supply
  uint256 public ogMaxSupply; // og max supply
  uint256 public whiteListMaxSupply; // white list max supply
  uint256 public mintRate; // 150USD worth of ETH
  uint256 public whitelistMintRate; // 150USD worth of ETH
  uint256 public totalOgSupply; // og minted supply
  uint256 public totalWhiteListSupply; // whitelist minted supply
  string public baseExtension = '.json';
  string public baseURI = ''; // ipfs://<LIVE_CID>/
  string public baseHiddenUri = ''; // unreveal url
  bool public isWhitelistSale; // a boolean to handle stages of whitelist sale
  bool public isPublicSale; // a boolean to handle stages of public sale
  bool public revealed; // a boolean to indicate revealing of token.
  address payable public feeCollecter;

  /**
   * @dev a mapping to check the max mint for each address.
   */
  mapping(address => uint256) public whiteListUsedAddresses;

  constructor() ERC721A('RETROGRESSION - Rise of the Dark Army', 'RTGN') {
    mintRate = 150000000000000000; // 0.15eth tbc
    whitelistMintRate = 150000000000000000; // 0.15eth tbc
    whiteListMaxMint = 2;
    totalMaxSupply = 5462; // OG/EI and Character NFT
    ogMaxSupply = 412;
    whiteListMaxSupply = 200;
    isWhitelistSale = false;
    isPublicSale = false;
    revealed = false;
    feeCollecter = payable(0x02A522D98EC2D2c3bBe91AcC29ee7fD32ab880ab);
    baseHiddenUri = 'ipfs://QmegkArmJMKAWXGFFKETuoCFJAfsE6hoJRM2khgkZCvf5y/';
    whiteListMerkleRoot = 0x1e833049290a0843af727836cc7627d8742335ddd0073243c21f9186c5b3ba9d;

    // @dev setting the royalty fee for retrogression address.
    _setDefaultRoyalty(0xb8623497431893Fc4820eC708003f27DE086FEF1, 250);
  }

  modifier isPublicLive() {
    if (!isPublicSale) revert PublicSaleNotLive();
    _;
  }

  modifier isWhiteListLive() {
    if (!isWhitelistSale) revert WhiteListNotLive();
    _;
  }

  modifier isEnoughTokensLeft(uint256 _quantity) {
    if (_quantity.add(totalSupply()) > totalMaxSupply)
      revert NotEnoughTokensLeft();
    _;
  }

  modifier isAddressVerified(bytes32[] calldata _proof, bytes32 _rootHash) {
    if (!MerkleProof.verify(_proof, _rootHash, leaf(msg.sender)))
      revert InvalidMerkle();
    _;
  }

  modifier isWithinOgMintLimit(uint256 _quantity) {
    if (_quantity > ogMaxSupply) revert ExceededLimit();
    _;
  }

  modifier isWithinWhiteListMintLimit(uint256 _quantity) {
    if (_quantity > whiteListMaxSupply) revert ExceededLimit();
    _;
  }

  modifier isCorrectPayment(uint256 _quantity, uint256 _mintRate) {
    if (_quantity <= 0) revert MintZeroQuantity();
    if (_mintRate.mul(_quantity) != msg.value) revert WrongEther();
    _;
  }

  modifier checkQuantity(uint256 _quantity) {
    if (_quantity <= 0) revert MintZeroQuantity();
    _;
  }

  event SendFee(address from, address to, uint256 amount);

  /**
   * @dev a function to send 10% to dev account.
   */
  function sendFee() internal {
    uint256 fee = msg.value.mul(10).div(100); // deduct 10% from minting and send to mintable account
    require(address(this).balance >= fee, 'Address: insufficient balance');
    feeCollecter.transfer(fee);
    emit SendFee(address(this), feeCollecter, fee);
  }

  /**
   * @dev overrides contract supportInterface
   */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(_interfaceId) ||
      ERC2981.supportsInterface(_interfaceId);
  }

  /**
   * @dev a function that uses ERC721A is an improved implementation of the
   * IERC721 standard that supports minting multiple tokens for close to the cost of one
   *
   * handle oglist mint
   */
  function ogMint(uint256 _quantity)
    external
    payable
    onlyOwner
    checkQuantity(_quantity)
    isWithinOgMintLimit(_quantity)
    isEnoughTokensLeft(_quantity)
  {
    totalOgSupply = totalOgSupply.add(_quantity);
    sendFee();
    _mint(msg.sender, _quantity);
  }

  /**
   * @dev a function that uses ERC721A is an improved implementation of the
   * IERC721 standard that supports minting multiple tokens for close to the cost of one
   *
   * handle whitelist mint
   */
  function whiteListMint(uint256 _quantity, bytes32[] calldata _proof)
    external
    payable
    isWhiteListLive
    isAddressVerified(_proof, whiteListMerkleRoot)
    isWithinWhiteListMintLimit(_quantity)
    isEnoughTokensLeft(_quantity)
    isCorrectPayment(_quantity, whitelistMintRate)
  {
    if (_quantity.add(whiteListUsedAddresses[msg.sender]) > whiteListMaxMint) {
      revert WhitelistUsed();
    }

    whiteListUsedAddresses[msg.sender] = _quantity.add(
      whiteListUsedAddresses[msg.sender]
    );
    totalWhiteListSupply = _quantity.add(totalWhiteListSupply);

    sendFee();
    _mint(msg.sender, _quantity);
  }

  /**
   * @dev a function that uses ERC721A is an improved implementation of the
   * IERC721 standard that supports minting multiple tokens for close to the cost of one
   */
  function mint(uint256 _quantity)
    external
    payable
    isPublicLive
    isEnoughTokensLeft(_quantity)
    isCorrectPayment(_quantity, mintRate)
  {
    sendFee();
    _mint(msg.sender, _quantity);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'ERC721a: token nonexistent!');

    if (!revealed) {
      string memory currentHiddenBaseURI = _baseHiddenURI();

      return
        bytes(currentHiddenBaseURI).length > 0
          ? string(
            abi.encodePacked(
              currentHiddenBaseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
          )
          : '';
    }

    // added reveal
    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(
            currentBaseURI,
            Strings.toString(_tokenId),
            baseExtension
          )
        )
        : '';
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _baseHiddenURI() internal view returns (string memory) {
    return baseHiddenUri;
  }

  function leaf(address _account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account));
  }

  function setWhiteListMerkleRoot(bytes32 _root) external onlyOwner {
    whiteListMerkleRoot = _root;
  }

  function toggleWhitelistSale() public onlyOwner {
    isWhitelistSale = !isWhitelistSale;
  }

  function togglePublicSale() public onlyOwner {
    isPublicSale = !isPublicSale;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    revealed = !revealed;
  }

  function withdraw() external payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}