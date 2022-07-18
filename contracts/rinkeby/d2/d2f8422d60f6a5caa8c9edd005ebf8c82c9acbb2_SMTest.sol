// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./APS.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract SMTest is ERC721A, Ownable{

    uint public maxSupply = 1111;
    uint public maxTx = 1;

    bool private mintOpen = false;

    string internal baseTokenURI = "";

    APSTest private immutable APSTestContract;

	constructor(address _APSTestAddress) ERC721A("SM Test", "SMTest") {
	  APSTestContract = APSTest(_APSTestAddress);
	}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function mintTo(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function mint(uint tokenId1, uint tokenId2, uint tokenId3) external payable {
        require(mintOpen, "Sale not active");
        _buy(tokenId1, tokenId2, tokenId3);
    }

    function _buy(uint tokenId1, uint tokenId2, uint tokenId3) internal {
        uint qty = balanceOf(_msgSender()) == 0 ? 1 : 0;
        require(qty > 0, "Invalid Value");
		require(APSTestContract.ownerOf(tokenId1) == msg.sender,"Not APS owner");
		require(APSTestContract.ownerOf(tokenId2) == msg.sender,"Not APS owner");
		require(APSTestContract.ownerOf(tokenId3) == msg.sender,"Not APS owner");
        APSTestContract.melt(tokenId1);
        APSTestContract.melt(tokenId2);
        APSTestContract.melt(tokenId3);
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "Exceeds Total Supply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}