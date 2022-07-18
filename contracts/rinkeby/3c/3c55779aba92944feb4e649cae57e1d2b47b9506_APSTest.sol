// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";

contract APSTest is ERC721A, Ownable{

    uint public maxSupply = 3333;
    uint public maxPerWallet = 3;

    bool private mintOpen = false;

    string internal baseTokenURI = "https://apstest3333.000webhostapp.com/";

    constructor() ERC721A("APS Test", "APSTest") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxPerWallet(uint newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function mintTo(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function mint(uint qty) external payable {
        require(mintOpen, "Sale not active");
        _mintCheck(qty);
    }

    function _mintCheck(uint qty) internal {
        require(qty <= maxPerWallet && qty > 0, "Not Allowed");
        uint leftPerWallet = maxPerWallet - balanceOf(_msgSender());
        require(qty <= leftPerWallet && qty > 0, "Not Allowed");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "Exceeds Total Supply");
        _mint(to, qty);
    }
	
	function melt(uint tokenId) external {
		_burn(tokenId);
	}
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}