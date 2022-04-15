//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./console.sol";

contract NftUnmasked is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    string public baseExtension = ".json";
    uint256 public alpha_cost = 0.33 ether;
    uint256 public presale_cost = 0.38 ether;
    uint256 public cost = 0.45 ether;
    uint256 public maxSupply = 333;
    uint256 public maxMintAmount = 3;
    uint256 public presaleDuration = 14400;
    uint256 public presaleEndTimestamp;

    string public URI = "https://gateway.pinata.cloud/ipfs/QmSbd5o7to8GGwpCmRpa7z4Xno4LqiLYu38dyUhnYzaHB2/";

    bool public paused = true;
    bool public presale = false;
    bool public alpha = false;

    mapping(address => bool) public presaleWhitelist;
    mapping(address => bool) public alphaWhitelist;

    constructor(
    ) ERC721("NFT Unmasked", "UNM") {
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function mintNFT(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount, "Cannot mint more than 3 tokens");
        require(supply + _mintAmount <= maxSupply, "No more tokens left");
        if (msg.sender != owner()) {
            require(!paused, "Sale is not open");
            if (isPresale()) {
                require(validatePresalePeriod(), "Presale period is over");
                require(validateUserInPresale(), "User not in presale whitelist");
            }

            require(msg.value * (1 ether) >= (cost * _mintAmount * (1 ether)), "Not enough to mint");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            // mints new token to requester of transaction with token id of supply+i
            _safeMint(msg.sender, supply + i);
        }
    }

    function openPresale(uint256 presaleDurationInMinutes) public onlyOwner {
        require(validatePresalePeriod(), "Already in whitelist presale");
        require(presaleDurationInMinutes <= presaleDuration); // 10 days
        paused = false;
        presale = true;
        presaleEndTimestamp = block.timestamp + presaleDurationInMinutes * 60;
        setCost(presale_cost);
    }

    function openAlpha(uint256 presaleDurationInMinutes) public onlyOwner {
        require(validatePresalePeriod(), "Already in alpha presale");
        require(presaleDurationInMinutes <= presaleDuration); // 10 days
        paused = false;
        alpha = true;
        presaleEndTimestamp = block.timestamp + presaleDurationInMinutes * 60;
        setCost(alpha_cost);
    }

    function openPublicMint() public onlyOwner {
        paused = false;
        alpha = false;
        presale = false;
        setCost(cost);
    }

    function closePresale() public onlyOwner {
        presale = false;
        alpha = false;
        paused = true;
    }

    function setTokenURI(string memory tokenURI) public onlyOwner {
        URI = tokenURI;
    }

    function validatePresalePeriod() internal returns (bool) {
        if (presale) {
            if (presaleEndTimestamp <= block.timestamp) {
                closePresale();
                return false;
            }
            return true;
        }
        return true;
    }

	function isUserInPresale(address userAddress) public view returns (bool) {
		if (alphaWhitelist[userAddress] || presaleWhitelist[userAddress]) {
			return true;
		} else {
			return false;
		}
    }

    function validateUserInPresale() internal view returns (bool) {
        if (alphaWhitelist[msg.sender] || presaleWhitelist[msg.sender]) {
            return true;
        } else {
            return false;
        }
    }

    function isPresale() internal view returns (bool) {
        return alpha || presale;
    }

    function addToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleWhitelist[addresses[i]] = true;
        }
    }

    function addToAlpha(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            alphaWhitelist[addresses[i]] = true;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(URI, tokenId.toString(), baseExtension));
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}