// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

import "./Ownable.sol";

contract MannyPacquiaoNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 10000;
    uint256 public reserved = 200;
    uint256 public presaleSupply;
    uint256 public presalePrice = 0.001 ether;
    uint256 public salePrice = 0.01 ether;
    uint256 public MINT_CAP = 21;
    address vault; //address to withdraw to
    
    bool public presale;
    bool public drop;
    bool public revealed;

    string public defaultURI;

    constructor(string memory _defaultURI, uint256 _presaleSupply, address _vaultAddress) ERC721('MannyPacquiaoNFT', 'MPN')
    {
        defaultURI = _defaultURI;
        presaleSupply = _presaleSupply;
        vault = _vaultAddress;
    }

    function _mintNFT(uint256 num) internal returns (bool) {
        for (uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_NFTS) _safeMint(_msgSender(), tokenIndex);
        }
        return true;
    }

    function presaleNFT(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(presale, 'The pre-sale have NOT started, please be patient.');
        require(num < MINT_CAP,'You are trying to mint too many at a time');
        require(currentSupply + num < presaleSupply, 'Exceeded pre-sale supply');
        require(msg.value >= presalePrice * num,'Ether value sent is not sufficient');
        return _mintNFT(num);
    }

    function saleNFT(uint256 num) public payable returns (bool) {
        uint256 currentSupply = totalSupply();
        require(drop, 'the drop have NOT started, please be patient.');
        require(num < MINT_CAP,'You are trying to mint too many at a time');
        require(currentSupply + num < MAX_NFTS - reserved, 'Exceeded total supply');
        require(msg.value >= salePrice * num,'Ether value sent is not sufficient');

        return _mintNFT(num);
    }

    function tokensOfOwner(address _owner)external view returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");
 
        // show default image before reveal
        if (!revealed) {
            return defaultURI;
        }

        string memory _tokenURI = _tokenUriMapping[tokenId];

        //return tokenURI if it is set
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        //If tokenURI is not set, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    /*
     * Only the owner can do these things
     */
    function toggleDrop() public onlyOwner {
        drop = !drop;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setPresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
    }

    function setPreSalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }

    function setMintCap(uint256 _mintCap) public onlyOwner {
        MINT_CAP = _mintCap;
    }

    function setVault(address _vaultAddress) public onlyOwner {
        vault = _vaultAddress;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(vault).send(address(this).balance));
    }

    function reserve(uint256 num) public onlyOwner {
        require(num <= reserved, "Exceeds reserved NFT supply" );
        for (uint256 i; i < num; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        reserved -= num;
    }
}