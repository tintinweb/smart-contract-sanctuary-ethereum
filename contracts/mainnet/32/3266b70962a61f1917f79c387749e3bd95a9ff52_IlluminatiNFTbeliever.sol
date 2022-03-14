// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract IlluminatiNFTbeliever is ERC1155, Ownable {
	using Strings for string;

	mapping(uint256 => uint256) private _totalSupply;

	//constants	
	uint256 public burnedCounter;
	uint256 public totalMinted;

	uint256 constant nft1 = 1;

	event Redeemed(address indexed from, uint256 id, uint256 uuid);

	string public _baseURI;
	string public _contractURI;

	bool saleLive = false;
	bool burnLive = false;

	constructor() ERC1155(_baseURI) {}

	   // airdrop function
    function airdrop(uint256[] calldata qty, address[] calldata addr) public onlyOwner {
        for(uint256 i = 0; i < addr.length; i++) {
            _mint(addr[i], nft1, qty[i], "");
        }
    }

	//redeem function
	function burn(
		address account,
		uint256 id,
		uint256 qty,
		uint256 uuid
	) public virtual {
		require(burnLive, "burn is not enabled");
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		require(balanceOf(account, id) >= qty, "balance too low");

		burnedCounter = burnedCounter + qty;
		_burn(account, id, qty);
		emit Redeemed(account, id, uuid);
	}

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

	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	// enables burn
	function setBurnLive(bool _burnLive) external onlyOwner {
		burnLive = _burnLive;
	}

	function withdrawToOwner() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}