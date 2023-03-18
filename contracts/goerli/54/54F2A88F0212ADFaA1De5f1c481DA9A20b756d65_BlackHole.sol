// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";

contract BlackHole is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    
    uint256 MAX_AMOUNT = 10000;
    string uri = 'https://ipfs.filebase.io/ipfs/QmfDXNCkzjbSv3kC5T6BEeQm36Z5VbdczVTxUT5aCmK1C9';
    bool public mintWindow = false;
    bool public burnWindow = false;
    event Log(string);
    event Log(uint256);

    constructor() ERC721("GenesisHole", "GH") {}

    function mint(uint256 amount) public payable {
        require(mintWindow, "Mint is not open yet.");
        require(totalSupply() < MAX_AMOUNT, "NFT is sold out");
        if (totalSupply() > 500){
            if (500 - (totalSupply() + amount) < 0) {
                amount = totalSupply() + amount - 500;
            }
            uint256 money = amount * 6000000;
            require(msg.value == money, "The mint price of Genesis-Hole is 0.006 ether per.");
        }
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, uri);
        }
  
    }

    function setMintWindow(bool _mintOpen) public onlyOwner {
        mintWindow = _mintOpen;
    }

    function setBurnWindow(bool _burnOpen) public onlyOwner {
        burnWindow = _burnOpen;
    }

      function getNFTTokenIds(address _owner) public view returns (uint256[] memory) {
        // 获取指定地址所持有的ERC721 NFT数量
        uint256 nftCount = balanceOf(_owner);

        // 创建一个动态数组来存储NFT Token ID
        uint256[] memory tokenIds = new uint256[](nftCount);

        // 循环查询每个NFT的Token ID并存储到数组中
        for (uint256 i = 0; i < nftCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        // 返回NFT Token ID数组
        return tokenIds;
    }
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function saftBurn() public {
        require(burnWindow, "Burn is not open yet.");
        require(balanceOf(address(msg.sender)) > 1, "You need to hold at least two NFTs.");
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds = getNFTTokenIds(address(msg.sender));
        _burn(tokenIds[0]);
        _burn(tokenIds[1]);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(burnWindow, "Burn is not open yet.");
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfacXeId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfacXeId);
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }
}