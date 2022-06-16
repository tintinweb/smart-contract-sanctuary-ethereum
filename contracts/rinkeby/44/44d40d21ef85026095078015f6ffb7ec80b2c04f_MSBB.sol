// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract MSBB is ERC721, Ownable {
    using Strings for uint256;

    // Change these
    address private memberOne = 0x5ba59A26750069F4bcfabf8e5EC2122Cb8f0B7C1;
    address private memberTwo = 0x9a96D6BD28434B8aa91FE0A72419A93Bf5cBCA00;
    address private memberThree = 0xf603367A0f460152A3F88C0acC29C46A569ABa39;
    address private memberFour = 0xa7309D079D027c26B449C5FB7e04757e4d5480f5;
    address private memberFive = 0xa7220815974B659a795213b1226545f9D2BeD80f;
    uint256 public constant NFT_MAX = 3500;
    uint256 public constant NFT_LIVE_MAX = 3333;
    uint256 public PUBLIC_PRICE = 0.07 ether;
    uint256 public WHITELIST_PRICE = 0.04 ether;
    uint256 public constant NFTS_PER_MINT = 10;
    string private _tokenBaseURI = "https://gateway.pinata.cloud/ipfs/QmZm6zEyJbDLgMBiFVKDncJYSJAT3tbuGuTWBfDWi971U8/";
    string private _mysteryURI = "https://gateway.pinata.cloud/ipfs/QmZm6zEyJbDLgMBiFVKDncJYSJAT3tbuGuTWBfDWi971U8/mystery.json";

    mapping(address => bool) private _whiteList;

    bool public mintLive;
    bool public revealed;

    uint256 public totalSupply;

    constructor() ERC721("Mrs. Bigfoot Baddie", "MSBB") {}

    function ownerMint(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function publicMint(
        uint256 tokenQuantity
    ) external payable {
        require(mintLive, "SALE_CLOSED");
        require(totalSupply < NFT_LIVE_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_LIVE_MAX, "EXCEED_STOCK");
        require(PUBLIC_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function whitelistMint(
        uint256 tokenQuantity
    ) external payable {
        require(mintLive, "SALE_CLOSED");
        require(totalSupply < NFT_LIVE_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_LIVE_MAX, "EXCEED_STOCK");
        require(_whiteList[msg.sender], "NOT_WHITELISTED");
        require(WHITELIST_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(memberOne).transfer((currentBalance * 200) / 1000);
        payable(memberTwo).transfer((currentBalance * 200) / 1000);
        payable(memberThree).transfer((currentBalance * 200) / 1000);
        payable(memberFour).transfer((currentBalance * 50) / 1000);
        payable(memberFive).transfer((currentBalance * 350) / 1000);
    }

    function isWhitelisted(address wallet) public view returns (bool) {
        return _whiteList[wallet];
    }

    function mintStatus() public view returns (bool) {
        return totalSupply < NFT_LIVE_MAX;
    }

    function setWhitelist(address[] memory addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = true;
        }
    }

    function removeWhitelist(address[] memory addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = false;
        }
    }

    function toggleMintLive() external onlyOwner {
        mintLive = !mintLive;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        // 70000000000000000 = .07 eth
        PUBLIC_PRICE = price;
    }

    function setWhitelistPrice(uint256 price) external onlyOwner {
        // 40000000000000000 = .04 eth
        WHITELIST_PRICE = price;
    }

    function setTokenBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenBaseURI() public view returns (string memory) {
        return _tokenBaseURI;
    }

    function setMisteryURI(string calldata URI) external onlyOwner {
        _mysteryURI = URI;
    }

    function mysteryURI() public view returns (string memory) {
        return _mysteryURI;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setMembers(address _memberOne, address _memeberTwo, address _memberThree, address _memberFour, address _memberFive) external onlyOwner {
        memberOne = _memberOne;
        memberTwo = _memeberTwo;
        memberThree = _memberThree;
        memberFour = _memberFour;
        memberFive = _memberFive;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}