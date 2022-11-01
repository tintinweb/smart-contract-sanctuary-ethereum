// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";

contract MORTI is ERC721AQueryable {

    bool public mintEnabled = false;
    address public deployer;
    string public baseUri;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public startTokenId;

    // Merkle Tree
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    constructor(string memory name_, string memory symbol_,
        string memory _baseUri) ERC721A(name_, symbol_) {
        // @todo Mint to specific wallet addresses
        deployer = msg.sender;

        baseUri = _baseUri;
    }
    
    function setMerkleRoot(bytes32 _root) public {
        require(msg.sender == deployer, "Only deployer can set the Merkle Root");
        merkleRoot = _root;
    }

    function getMintEnabled() public view returns (bool) {
        return mintEnabled;
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function updateBaseURI(string memory _baseUri) external {
        require(msg.sender == deployer, "Only deployer can update base URI");
        baseUri = _baseUri;
    }

    function toggleMintEnabled(bool toggle) external {
        require(msg.sender == deployer, "Only deployer can toggle minting");
        mintEnabled = toggle;
    }

    function setMintEnabled() external {
        require(msg.sender == deployer, "Only deployer can set minting");
        mintEnabled = true;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public {
        _initializeOwnershipAt(index);
    }

    function claimTo(address _addr, uint256 _amnt, bytes32[] calldata merkleProof) external {
        require(totalSupply() + 1 < MAX_SUPPLY, "ExceedMaxSupply");
        require(getMintEnabled(), "Claiming is not enabled");
        require(!claimed[_addr], "Already claimed");

        bytes32 node = keccak256(abi.encodePacked(_addr, _amnt));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

        _mint(_addr, _amnt);
        claimed[_addr] = true;
    }
}

// await ctr.claimTo('0xBF9d7541915Ae295e09C70ea341ad5A25a76f4f9', 61, '0x6c9a736ed610d0855629b78a7b177c4df3c66cd4a0921e2a7d30364c9c29cf5b',