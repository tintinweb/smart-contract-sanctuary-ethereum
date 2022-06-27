//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

// Merkle tree
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/**
 * @title GameOfTheKing
 */
contract GameOfTheKing is ERC721A, Ownable {
    using SafeMath for uint256;
    // price is 0.022 ETH 22000000000000000
    uint256 public constant kingPrice = 0.022 ether; 
    //KING的总数量
    uint256 public constant MAX_KINGS = 10000;

    //保留KING的数量
    uint256 public constant RESERVE_KING = 103;

    // 启动销售
    bool public saleIsActive = false;

    // 保留KING只能调用一次
    bool public reserveForOnce = true;

    // 最多一次能mint 10个
    uint256 public immutable maxPerMint = 10;

    // metadata URI
    string private _baseTokenURI;

    // 构造函数，定义最多mint 103个，总数10000个
    constructor(string memory  baseURI) ERC721A("GameOfTheKing", "KING") {
        _baseTokenURI = baseURI;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed.");
    }

    /**
     * Set some kings aside
     */
    function reserveKings() public onlyOwner {        
        if (reserveForOnce == true) {
            _safeMint(msg.sender, RESERVE_KING);
            reserveForOnce = false;
        }
    }

    /**
     * return baseuri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * set baseuri
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // 获取公开销售状态
    function getPublicSaleStatus() external view returns(bool){
        return saleIsActive;
    }

    /*
    * owner minted number
    */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicKingsMint(uint256 quantity) external payable {
        // check sales status
        require(saleIsActive, "please wait the sale");
        // check quantity
        require(totalSupply() + quantity <= MAX_KINGS, "reached max supply");
        // check quantity max
        require(quantity <= maxPerMint, "reached max per mint max amount");
        // check wallet amount
        require(kingPrice.mul(quantity) <= msg.value, "ETH not enough.");
        _safeMint(msg.sender, quantity);
    }

    // 白名单mint配置
    bool private allowListStatus = false;
    uint256 private allowListMaxAmount = 1000;
    uint256 private whitelistMintedAmount = 0;
    uint256 public immutable maxPerAddressDuringMint = 2;

    bytes32 private merkleRoot;

    mapping(address => bool) public addressAppeared;
    mapping(address => uint256) public addressMintStock;

    // 白名单mint
    function whitelistMint(uint256 quantity, bytes32[] memory proof) external payable {

        require(tx.origin == msg.sender, "The caller is another contract");
        require(allowListStatus, "allowList sale has not begun yet");
        require(totalSupply() + quantity <= MAX_KINGS, "reached max supply");
        // 检查白名单是否足够
        require(whitelistMintedAmount + quantity <= allowListMaxAmount, "whilt list is not enough");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Proof.");


        if(!addressAppeared[msg.sender]){
            addressAppeared[msg.sender] = true;
            addressMintStock[msg.sender] = maxPerAddressDuringMint;
        }
        require(addressMintStock[msg.sender] >= quantity, "reached allow list per address mint amount");
        addressMintStock[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);

        // mint之后要增加已经mint的白名单数量
        whitelistMintedAmount += quantity;
    }

    // 设置树根
    function setAllowList(bytes32 root_) external onlyOwner{
        merkleRoot = root_;
    }

    // 设置白名单mint状态
    function flipWhiteListSaleState() external onlyOwner {
        allowListStatus = !allowListStatus;
    }
    // 获取白名单销售状态
    function getWhiteListSaleStatus() external view returns(bool){
        return allowListStatus;
    }
}