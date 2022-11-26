// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";

enum MintStatus {
    NotStarted,
    WhiteList,
    PublicSale
}

contract Sexg is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public _wlPrice = 0.003 ether;
    uint256 public _publicPrice = 0.007 ether;
    uint32 public immutable _maxSupply = 5555;
    uint32 public immutable _walletLimit = 5;
    uint32 public _maxMintAmount = 5;
    uint32 public _wlMinted;
    MintStatus public _mintStatus = MintStatus.NotStarted;
    string public _metadataURI;
    bytes32 public _saleMerkleRoot;
    bool public _rootabi = false;

    constructor(string memory metadataURI) ERC721A("Sexy Girl", "sexg") {
        _metadataURI = metadataURI;
        setFeeNumerator(700);
    }

    event MINTFINISH(uint32 totalMinted);
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root, bool rootabi) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender)),
                rootabi
            ),
            "Address does not exist in list"
        );
        _;
    }

    function mint(uint32 amount) external payable {
        require(_mintStatus == MintStatus.PublicSale, "SG  : Public sale is not started yet");
        uint32 totalMint = uint32(_totalMinted());
        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + totalMint <= _maxSupply, "SG : Exceed max supply");
        require(amount + minted <= _walletLimit, "SG : Exceed wallet limit");
        require(msg.value >= amount * _publicPrice, "SG: Insufficient fund");
        _safeMint(msg.sender, amount);
    }
    
    function mintWL(uint32 amount,bytes32[] calldata merkleProof) external payable isValidMerkleProof(merkleProof, _saleMerkleRoot, _rootabi) {
        require(_mintStatus == MintStatus.WhiteList, "SG: WhiteList sale is not started yet");
        uint32 minted = uint32(_numberMinted(msg.sender));
        uint32 totalMint = uint32(_totalMinted());
        require(minted + amount <= _walletLimit,"SG: Exceed WhiteList max supply");
        require(amount + totalMint <= _maxSupply,"SG: Exceed max supply");
        require(msg.value >= amount * _wlPrice, "SG: Insufficient fund");
        _safeMint(msg.sender, amount);
        _wlMinted += amount;
        emit MINTFINISH(uint32(_totalMinted()));
    }
    
    function publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _wlMinted;
    }

    function publicSupply() public view returns (uint32) {
        return _maxSupply - _wlMinted;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _saleMerkleRoot = merkleRoot;
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setrootabi(bool abip) public onlyOwner {
        _rootabi = abip;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }
    
    function setMaxMintAmount(uint32 amount) external onlyOwner {
        _maxMintAmount = amount;
    }

    function setWLPrice(uint256 price) external onlyOwner {
        _wlPrice = price;
    }

    function setPublicPrice(uint256 price) external  onlyOwner {
        _publicPrice = price;
    }

    function setMintStatus(MintStatus status) external onlyOwner {
        _mintStatus = status;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}