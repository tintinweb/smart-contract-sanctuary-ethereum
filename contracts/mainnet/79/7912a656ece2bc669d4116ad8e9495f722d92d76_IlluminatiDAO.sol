// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

abstract contract ILLUMINATI {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
  function tokensOfOwner(address owner) public virtual view returns (uint256[] memory);
}

contract IlluminatiDAO is ERC1155, Ownable {
	using Strings for string;

	mapping(uint256 => bool) public claimTracker;

	ILLUMINATI private illuminati;

	uint256 constant nft1 = 1;
	uint constant maxSupply = 8128;

	string public _baseURI;
	string public _contractURI;

	bool public claimLive = false;

	constructor(address illuminatiContractAddress) 
		ERC1155(_baseURI) {
		illuminati = ILLUMINATI(illuminatiContractAddress);
	}

	// claim function
    function claim(uint256[] calldata illuminatiIDs) external {		

		//initial checks
		require(claimLive,"Claim Window is not live");
		require(illuminatiIDs.length > 0,"You must claim at least 1 token"); // you must claim
	
		//owner checks
		for(uint256 x = 0; x < illuminatiIDs.length; x++) {
		require(illuminati.ownerOf(illuminatiIDs[x]) == msg.sender,"You do not own these Illuminati"); //check inputted balance
		require(claimTracker[illuminatiIDs[x]] == false,"An inputted token was already claimed"); //check if inputted tokens claimed
		}
		//mint + store claim
        for(uint256 i = 0; i < illuminatiIDs.length; i++) {
            _mint(msg.sender, nft1, 1, ""); //mint 1 per
			claimTracker[illuminatiIDs[i]] = true; //track claims
        }
    }

	// admin claim (token 0)
    function claim(uint256 illuminatiID) external onlyOwner {		
		require(illuminatiID == 0,"You must claimtoken 0"); // you must claim
         _mint(msg.sender, nft1, 1, ""); //mint 1 per
		claimTracker[illuminatiID] = true; //track claims
    }

	//metadata
	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {return "0";}
			uint256 j = _i;
			uint256 len;
		while (j != 0) {len++; j /= 10;}
			bytes memory bstr = new bytes(len);
			uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	// enables claim
	function setClaimLive(bool _live) external onlyOwner {
		claimLive = _live;
	}

	//check claim by token
	function checkClaimed(uint256 tokenId) public view returns (bool) {
		return claimTracker[tokenId];
	}

	//check Illuminati Tokens
	function checkIlluminatiTokens(address owner) public view returns (uint256[] memory){
		uint256 tokenCount = illuminati.balanceOf(owner);
		uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = illuminati.tokenOfOwnerByIndex(owner, i);
        }
		return tokenIds;
	}

	//withdraw any funds
	function withdrawToOwner() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}