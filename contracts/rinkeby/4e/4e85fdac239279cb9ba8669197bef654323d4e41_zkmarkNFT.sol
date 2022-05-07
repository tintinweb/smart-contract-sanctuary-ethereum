// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./ERC721A.sol";


contract zkmarkNFT is ERC721A, Ownable {
    string public baseURI = "ipfs://QmbvfDkyPukMd1MCiQBqq1vzYJtKfRBow39c9dwY1peXcQ/";
    uint256 public MAX_SUPPLY = 10000;
    uint256 public cost = 0.05 ether;
    uint256 public maxPerWallet = 1;

    // 用于验证白名单
    bytes32 public whitelistMerkleRoot;

    bool public whitelistSale; // isAllowListActive
    bool public publicSale; // isMainSaleActive


    //
    mapping(address => uint256) public walletCap;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // 确定NFT全名和缩写
    constructor() ERC721A("zkmark NFT", "ZMTN") {
        whitelistSale = false;
        publicSale = false;
    }

    // 验证默克尔根
    modifier isValidMerkleProof(bytes32 [] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    //
    modifier isCorrectPayment(uint256 price) {
        require(
            price == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    // =============== 公售mint功能 ===============
    /**
        为每个白名单地址铸造1个代币，不收取费用
    */
    function mintAllowlist(bytes32[] calldata merkleProof) public payable
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    isCorrectPayment(cost)
    {
        require(whitelistSale && !publicSale, "Whitelist must be active to mint NFT");
        require(walletCap[msg.sender] +1 <= maxPerWallet, "Purchase would exceed max number of mints per wallet.");// 购买硬币将超过每个钱包的最大数量
        require(_tokenSupply.current() +1 <= MAX_SUPPLY, "Purchase would exceed max number of tokens");
        _tokenSupply.increment();
        //_mint(msg.sender, _tokenSupply.current());
        _safeMint(msg.sender, _tokenSupply.current());
        walletCap[msg.sender] += 1;
    }

    /**
    * @dev mints specified # of tokens to sender address 向发送者地址生成指定的令牌号
    */
    function mint() public payable isCorrectPayment(cost) {
        require(!whitelistSale && publicSale, "Public sale must be active to mint NFT");
        require(walletCap[msg.sender] +1 <= maxPerWallet, "Purchase would exceed max number of mints per wallet.");// 购买硬币将超过每个钱包的最大数量
        require(_tokenSupply.current() +1 <= MAX_SUPPLY, "Purchase would exceed max number of tokens");
        _tokenSupply.increment();
        // _mint(msg.sender, _tokenSupply.current());
        _safeMint(msg.sender, _tokenSupply.current());
        walletCap[msg.sender] += 1;
    }

    // ================ PUBLIC READ-ONLY FUNCTIONS ================= 公共只读功能
    function tokenURI(uint256 tokenID) public view virtual override returns (string memory){
        require(_exists(tokenID), "ERC721Metadata: query for nonexistent token"); // 查询不存在的token
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID), ".json"));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenSupply.current();
    }

    // ================ OWNER-ONLY ADMIN FUNCTIONS ================= owner管理功能
    // 为公司预留的私有mint function。
    // _to :the user receiving the tokens
    // _mintAmount : The number of tokens to distribute

    function mintToAddress(address _to, uint256 _mintAmount) external onlyOwner {
        require(_mintAmount > 0, "You can only mint more than 0 tokens");
        require(_tokenSupply.current() + _mintAmount <= MAX_SUPPLY, "Can't mint more than max supply");
        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenSupply.increment();
            // _mint(_to, _tokenSupply.current());
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setwhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function setpublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost; // 设置新的NFT价格
    }


    /**
     * @dev Distribution of sales 销售的分配
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}