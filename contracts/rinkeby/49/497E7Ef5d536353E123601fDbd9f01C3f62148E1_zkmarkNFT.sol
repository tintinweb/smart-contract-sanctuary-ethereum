// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./ERC721A.sol";


contract zkmarkNFT is ERC721A, Ownable {
    string public baseURI = "ipfs://QmbvfDkyPukMd1MCiQBqq1vzYJtKfRBow39c9dwY1peXcQ/";
    uint256 public MAX_SUPPLY = 10;
    uint256 public cost = 0.05 ether;
    uint256 public maxPerWallet = 1;
    bool public publicSale; // isMainSaleActive
    mapping(address => uint256) public walletCap;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // 确定NFT全名和缩写
    constructor() ERC721A("zkmark NFT", "ZMTN") {
        publicSale = true;
    }

    modifier isCorrectPayment(uint256 price) {
        require(price == msg.value, "Incorrect ETH value sent");
        _;
    }

    /**
    * @dev mints specified # of tokens to sender address 向发送者地址生成指定的令牌号
    */
    function mint() public payable isCorrectPayment(cost) {
        require(publicSale, "Public sale must be active to mint NFT");
        require(walletCap[msg.sender] +1 <= maxPerWallet, "Purchase would exceed max number of mints per wallet.");// 购买硬币将超过每个钱包的最大数量
        require(_tokenSupply.current() +1 <= MAX_SUPPLY, "Purchase would exceed max number of tokens");
        _tokenSupply.increment();
        // _mint(msg.sender, _tokenSupply.current());
        _safeMint(msg.sender, _tokenSupply.current());
        walletCap[msg.sender] += 1;
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

    /**
     * @dev Distribution of sales 销售的分配
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}