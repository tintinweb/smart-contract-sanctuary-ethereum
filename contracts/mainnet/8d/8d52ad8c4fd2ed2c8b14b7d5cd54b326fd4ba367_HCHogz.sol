/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* 
Hostile Crypto Inc. Presents;

 ██░ ██  ▄████▄      ██░ ██  ▒█████    ▄████ ▒███████▒
▓██░ ██▒▒██▀ ▀█     ▓██░ ██▒▒██▒  ██▒ ██▒ ▀█▒▒ ▒ ▒ ▄▀░
▒██▀▀██░▒▓█    ▄    ▒██▀▀██░▒██░  ██▒▒██░▄▄▄░░ ▒ ▄▀▒░ 
░▓█ ░██ ▒▓▓▄ ▄██▒   ░▓█ ░██ ▒██   ██░░▓█  ██▓  ▄▀▒   ░
░▓█▒░██▓▒ ▓███▀ ░   ░▓█▒░██▓░ ████▓▒░░▒▓███▀▒▒███████▒
 ▒ ░░▒░▒░ ░▒ ▒  ░    ▒ ░░▒░▒░ ▒░▒░▒░  ░▒   ▒ ░▒▒ ▓░▒░▒
 ▒ ░▒░ ░  ░  ▒       ▒ ░▒░ ░  ░ ▒ ▒░   ░   ░ ░░▒ ▒ ░ ▒
 ░  ░░ ░░            ░  ░░ ░░ ░ ░ ▒  ░ ░   ░ ░ ░ ░ ░ ░
 ░  ░  ░░ ░          ░  ░  ░    ░ ░        ░   ░ ░    
        ░                                    ░        

HC Hogz is fighting its way to become bigger than just an NFT project. Our vision is to become the leading badass brand in the metaverse. Not your typical Apes or Hippo’s, HC’s are on a warpath to mark their digital territory.

HC’s Hogz will start with a collection of 9,666 NFT’s, that will have utility in the digital realm. Owning a Hog NFT will grant you access to fight in our video game, enter you in a draw to win prizes, and become a member of our HC’s digital Club house.
Learn more at www.hchogz.com

Managed by Hostile Crypto Inc. www.hostilecrypto.com
Art by Luminous4D. www.luminous4d.com
Marketing by Duco Media. www.ducomedia.ca
Developed by Co-Labs Studio. www.co-labs.studio
*/

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

contract HCHogz is ERC721A, Shareholders, DefaultOperatorFilterer {
    using Strings for uint;
    address internal NFTPay = 0xDDEC0a2a1bec87B227268B86ffe6094e24465CE0;
    string public _baseTokenURI;
    uint public maxPerWallet = 50;
    uint public maxPerWalletPresale = 50;
    uint public publicCost = 0.29 ether;
    uint public presaleCost = 0.19 ether;
    uint public presaleSupply = 4000;
    uint public presaleUsed = 0;
    uint public maxSupply = 9666;
    bool public revealed = false;
    bool public presaleOnly = true;
    bool public paused = true;
    bytes32 public merkleRoot;
    mapping(address => uint) public addressMintedBalance;
  constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseUri_ 
    ) ERC721A(name_, symbol_)payable{
        _baseTokenURI = baseUri_;
        _mint(msg.sender, 50);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused.");
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(tx.origin == msg.sender, "No contracts!");
        _;
    }

    function publicMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(presaleOnly == false, "Presale Only");
        require(msg.value >= publicCost*quantity, "Amount of Ether sent too small");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        require(presaleOnly == true, "Presale has ended.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWalletPresale, "You can't mint this many during presale.");
        require(msg.value >= presaleCost * quantity, "Amount of Ether sent too small");
        require(quantity <= presaleSupply - presaleUsed, "Presale sold out. You'll have to wait until public sale.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
        presaleUsed += quantity;
    }

    function ownerMint(uint256 quantity) external payable onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        _mint(msg.sender, quantity);
    }

    function NFTPayMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(msg.sender == NFTPay, "This function is for NFT Pay only.");
        require(presaleOnly == false, "Presale Only");
        require(quantity <= maxPerWallet, "Cannot mint this many at a time.");
        require(msg.value >= publicCost*quantity, "Amount of Ether sent too small");
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) 
    {
        return _exists(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) 
    {
    string memory currentBaseURI = _baseURI();
    if(revealed == true) {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    } else {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI))
        : "";
    }
    
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
    merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;//set to false for main mint
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner 
    {
    revealed = _state;
    _baseTokenURI = baseURI;
    }

    function pause(bool _state) external onlyOwner 
    {
    paused = _state;
    }

    function changeSaleDetails(uint _publicCost, uint _presaleCost, uint _maxPerWallet, uint _maxPerWalletPresale) external onlyOwner {
        publicCost = _publicCost;
        presaleCost = _presaleCost;
        maxPerWallet = _maxPerWallet;
        maxPerWalletPresale = _maxPerWalletPresale;
    }

    function updateNFTPay(address _newAddress) external onlyOwner {
        NFTPay = _newAddress;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

   
    
}