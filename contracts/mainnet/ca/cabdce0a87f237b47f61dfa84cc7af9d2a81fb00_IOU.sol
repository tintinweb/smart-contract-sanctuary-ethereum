// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";

contract IOU is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string public baseURI;
	bool public mintActive = false;
	string public baseExtension = ".json";
	uint256 public constant maxSupply = 500;
	uint256 public mintCount = 0;
	uint256 public cost = 0.1 ether;

    address public ownerAddress = 0x52892f8574336EaAe60F87eC191776597b1fFDe2;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

	// override _startTokenId() function ~ line 100 of ERC721A
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	// override _baseURI() function  ~ line 240 of ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

	// override tokenURI() function ~ line 228 of ERC721A
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
	}

	// ---Helper Functions / Modifiers---
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

	modifier mintCompliance(uint256 _mintAmount) {
		// validate amount is more than 0 and maxSupply has/will not be exceeded
		require(totalSupply() + _mintAmount <= maxSupply, "Mint will exceed max collection supply.");
        // Check if owner before checking mint status
        if(msg.sender != owner()) {
            // check mintActive
            require(mintActive, "Public mint has not started.");
		}
		_;
	}

	modifier mintPriceCompliance(uint256 _mintAmount) {
        // Check if owner before calculating price
        if(msg.sender != owner()) {
			require(msg.value >= cost * _mintAmount, "Insufficient funds!");
			uint256 totalMintCost = _mintAmount * cost;
            // sender has passed >= funds
            require(msg.value >= totalMintCost, "Insufficient funds to mint.");
            // sendFunds
            sendFunds(msg.value);
		}
		_;
	}

	function publicMint(uint256 _quantity) external payable callerIsUser mintCompliance(_quantity) mintPriceCompliance(_quantity) {
		// _safeMint function
		_safeMint(msg.sender, _quantity);

        // track mints
        mintCount += _quantity;
	}

	// sendFunds function
	function sendFunds(uint256 _totalMsgValue) public payable {
		(bool s1, ) = payable(ownerAddress).call{value:  _totalMsgValue}("");
		require(s1 , "Transfer failed.");
	}

	// ---onlyOwner 

	// setBaseURI (must be public)
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	// setPublicActive
	function setMintActive() external onlyOwner {
		mintActive = true;
	}

	// setcost
	function setcost(uint256 _newcost) external onlyOwner {
		cost = _newcost;
	}

	// withdraw
	function withdraw() external onlyOwner nonReentrant {
		sendFunds(address(this).balance);
	}

	// recieve
	receive() external payable {
		sendFunds(address(this).balance);
	}

	// fallback
	fallback() external payable {
		sendFunds(address(this).balance);
	}

}