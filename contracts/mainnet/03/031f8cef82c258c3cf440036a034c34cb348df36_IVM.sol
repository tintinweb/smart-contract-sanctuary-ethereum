// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";


contract IVM is ERC721A, Ownable {
    using SafeMath for uint256;

    bytes32 private whitelistHash = 0x0e73c52114d4194e74408fcf466bc866014c0b91ed7336172b68832c1f201804;

    uint256 public MAX_TOKENS;
    uint256 public MAX_MINT = 2;
    uint256 public MAX_WHITELIST_MINT = 2;
    uint256 public PRICE = 0.079 ether;

    address public treasury;
    string private baseTokenURI;

    mapping(address => uint256) private publicMintMap;
    mapping(address => uint256) private whitelistMintMap; 

    bool public openPublicMint = false;
    bool public openWhiteListMint = false;

    constructor(
        address _treasury,
        uint256 _max_tokens,
        uint256 _maxBatchSize,
        uint256 _collectionSize
    ) ERC721A("invisible mate", "IVM", _maxBatchSize, _collectionSize) {
        treasury = _treasury;
        MAX_TOKENS = _max_tokens;
    }

    function publicMint(uint256 num) external payable {
        require(openPublicMint, "Public sales not active");
        uint256 supply = totalSupply();
        require(publicMintMap[_msgSender()].add(num) <= MAX_MINT, "Reached max per transaction");
        require(supply.add(num) <= MAX_TOKENS, "Fully minted");
        require(msg.value >= num * PRICE, "Invalid price");

        publicMintMap[_msgSender()] += num;
        _safeMint(_msgSender(), num);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 num) external payable {
        require(openWhiteListMint, "whitelist mint not active");
        require(whitelistMintMap[_msgSender()].add(num) <= MAX_WHITELIST_MINT, "Reached max per transaction");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(proof, whitelistHash, leaf));
        uint256 supply = totalSupply();
        require(supply.add(num) <= MAX_TOKENS, "Fully minted");
        require(msg.value >= num * PRICE, "Invalid price");

        whitelistMintMap[_msgSender()] += num;
        _safeMint(_msgSender(), num);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        payable(treasury).transfer(address(this).balance);
    }

    function setMint(bool _publicMint, bool _whitelistMint) external onlyOwner {
        openPublicMint = _publicMint;
        openWhiteListMint = _whitelistMint;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function getHash() public view onlyOwner returns (bytes32) {
        return whitelistHash;
    }

    function setWL(bytes32 _whitelistHash, uint256 _max_whitelist_mint) external onlyOwner {
        whitelistHash = _whitelistHash;
        MAX_WHITELIST_MINT = _max_whitelist_mint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setParams(
        uint256 _max_token,
        uint256 _max_public_mint
    ) external onlyOwner {
        MAX_TOKENS = _max_token;
        MAX_MINT = _max_public_mint;
    }
}