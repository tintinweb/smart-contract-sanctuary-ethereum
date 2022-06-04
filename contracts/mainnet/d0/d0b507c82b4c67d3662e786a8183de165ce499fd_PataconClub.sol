// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Optimized.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract PataconClub is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_PTCC = 10000;
    uint256 public constant GIVEAWAY_PTCC = 500;
    uint256 public maxPTCCPerWallet = 10;
    uint256 public maxPTCCPurchase = 20;
    uint256 public PTCCPrice = 1000000000000000;
    string public _basePTCCURI;

    struct AddressData {
        uint64 numberMinted;
    }

    mapping(address => AddressData) private _addressData;

    event PTCCMinted(address indexed mintAddress, uint256 indexed tokenId);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Optimized("Patacon Club", "PTCC") {
        _basePTCCURI = baseURI;
    }

    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
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
        _basePTCCURI = newuri;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "PTCC price must be greater than zero");
        PTCCPrice = newPrice;
    }

    function setMaxPerWallet(uint256 newMax) public onlyOwner {
        require(newMax > 0, "PTCC limit must be greater than zero");
        maxPTCCPerWallet = newMax;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    function mintPTCC(uint256 numberOfTokens) public payable nonReentrant {
        require((totalSupply()) >= GIVEAWAY_PTCC, "Public minting not live yet");
        require(numberOfTokens <= maxPTCCPurchase, "You can not mint this many per transaction");
        require(_numberMinted(msg.sender) + numberOfTokens <= maxPTCCPerWallet, "You can not mint this many");
        require((totalSupply() + numberOfTokens) <= MAX_PTCC, "Purchase would exceed max supply of PTCCs");
        require((PTCCPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(_msgSender());
        }
        _addressData[msg.sender].numberMinted += uint64(numberOfTokens);
    }

    function createCollectible(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < MAX_PTCC) {
            _safeMint(mintAddress, mintIndex);
            emit PTCCMinted(mintAddress, mintIndex);
        }
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function _baseURI() internal view virtual returns (string memory) {
	    return _basePTCCURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}