// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721A.sol";
import "./OperatorFilterer.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Updated is ERC721A, OperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public frenslistMintEnabled = false;
    bool public publicMintEnabled = false;
    bool public teamMintClaimed = false;
    bool public operatorFilteringEnabled;

    uint256 public maxSupply = 1069;
    uint256 public teamMintLimit = 50;
    uint256 public frenslistMintCost = 0.007 ether;
    uint256 public publicMintCost = 0.007 ether;
    uint256 public maxFreeFrenslistMintLimit = 2;
    uint256 public maxFrenslistMintLimit = 5;
    uint256 public maxPublicMintLimit = 5;

    bytes32 public merkleRoot;
    string public baseURI;

    constructor(string memory _initBaseURI) ERC721A("SOtest", "SO") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        setBaseURI(_initBaseURI);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setMaxSupply(uint256  newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setfrenslistMintCost(uint256 newPrice) external onlyOwner {
        frenslistMintCost = newPrice;
    }

   function setpublicMintCost(uint256 newPrice) external onlyOwner {
        publicMintCost = newPrice;
    }
    function setPublicMintEnabled(bool _state) public onlyOwner {
        publicMintEnabled = _state;
    }

    function setFrenslistMintEnabled(bool _state) public onlyOwner {
        frenslistMintEnabled = _state;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist!");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked("ipfs://", baseURI, "/", tokenId.toString(), ".json")) : "";
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "Contracts not allowed to mint!");
        _;
    }
    
    modifier mintCompliance(uint256 _mintAmount) {
        require(balanceOf(msg.sender) <= 5, "You have already minted 5!");
        require(_mintAmount <= 5, "Max mint per transaction is 5!");
        require(_mintAmount <= 5 - (balanceOf(msg.sender)), "You cannot mint this many tokens.");
        require(totalSupply() + _mintAmount <= maxSupply, "Max Supply Exceeded!");
        _;
    }

    function mintForAddress(uint256 _mintAmount, address _to) external onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max Supply Exceeded!");
        _mint(_to, _mintAmount);
    }

    function teamMint() external onlyOwner {
        require(!teamMintClaimed, "Team already claimed!");
        _safeMint(owner(), teamMintLimit);
        teamMintClaimed = true;
    }

    function amIOnTheFrenslist(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
    
    function frenslistMint(uint256 _mintAmount, bytes32[] calldata proof) public payable mintCompliance(_mintAmount) nonReentrant {
        require(frenslistMintEnabled, "Frenslist minting hasn't started!");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You're not on the frenslist!");

        if(balanceOf(_msgSender()) > 1) {
            require(msg.value >= _mintAmount * frenslistMintCost, "Insufficient Funds1!");
        } else {
            require(msg.value >= (_mintAmount - 2) * frenslistMintCost, "Insufficient Funds2!");
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
        require(publicMintEnabled, "Public minting hasn't started!");
        if(balanceOf(_msgSender()) >= 0) {
            require(msg.value >= _mintAmount * publicMintCost, "Insufficient Funds3!"); 
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function withdraw() external onlyOwner {
        (bool hs,) = payable(owner()).call{
            value: (address(this).balance)}("");
        require(hs);
    }
}