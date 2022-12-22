// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Optimized.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract ElKrtel is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant Total_KRTLs = 6969;
    uint256 public maxPerWallet = 10;
    uint256 public mintPrice = 4200000000000000;
    uint256 public maxFree = 100;
    uint256 public freeCount = 0;
    string public _baseKRTLURI;

    struct AddressData {
        uint64 numberMinted;
        uint64 numberFree;
    }

    mapping(address => AddressData) private _addressData;

    event KRTLMinted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Optimized("El Krtel", "KRTL") {
        _baseKRTLURI = baseURI;
        _owners.push(address(0));
    }

    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
        require((totalSupply() + numberOfTokens) <= Total_KRTLs, "No NFTs left!");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(to);
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseKRTLURI = newuri;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "KRTL price must be greater than zero");
        mintPrice = newPrice;
    }

    function setMaxPerWallet(uint256 newMax) public onlyOwner {
        require(newMax > 0, "KRTL limit must be greater than zero");
        maxPerWallet = newMax;
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }
    function _numberFree(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberFree);
    }

    function mintPublic(uint256 numberOfTokens) public payable nonReentrant {
        require(block.timestamp >= 1672867200, "Minting not live yet!"); // Jan 04 2023 16:20:00 GMT-0500
        require(numberOfTokens <= maxPerWallet, "Too many per tx!");
        require(_numberMinted(msg.sender) + numberOfTokens <= maxPerWallet, "Too many per wallet!");
        require((totalSupply() + numberOfTokens) <= Total_KRTLs, "No NFTs left!");

        if (numberOfTokens == 1 && _numberFree(msg.sender) < 1 && freeCount < maxFree)
        {
            _addressData[msg.sender].numberFree += uint64(numberOfTokens);
            freeCount++;
        }
        else
        {
            require((mintPrice * numberOfTokens) <= msg.value, "not enough Ether!");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(_msgSender());
        }
        _addressData[msg.sender].numberMinted += uint64(numberOfTokens);
    }

    function createCollectible(address mintAddress) private {
        uint256 mintIndex = totalSupply() + 1;
        if (mintIndex <= Total_KRTLs) {
            _safeMint(mintAddress, mintIndex);
            emit KRTLMinted(mintAddress, mintIndex);
        }
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function _baseURI() internal view virtual returns (string memory) {
	    return _baseKRTLURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}