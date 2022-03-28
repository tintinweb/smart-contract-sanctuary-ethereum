// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";

contract chickens is ERC721A, Ownable {  
    using Strings for uint256;
    string public _baseURIextended;

    //settings
  	uint256 public maxSupply = 1407;

	constructor(string memory _name, string memory _symbol, string memory _uri) ERC721A(_name, _symbol){setBaseURI(_uri);}

    // admin minting
	function reserve(uint256[] calldata _tokenAmount, address[] calldata addr) public onlyOwner {
  	    for(uint i=0; i<addr.length; i++){
        uint256 s = totalSupply();
	    require(s + _tokenAmount[i] <= maxSupply, "Reserve less");
        _safeMint(addr[i], _tokenAmount[i]);
        }
    }

	//write metadata
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}