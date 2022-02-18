// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

contract MerchMintPass is ERC1155, EIP712, Ownable {
	using Strings for string;

	mapping(uint256 => uint256) private _totalSupply;

 	 //signature
    string private constant SINGING_DOMAIN = "MINTPASS";
    string private constant SIGNATURE_VERSION = "1";

	//constants	
	uint256 public burnedCounter;
	uint256 public totalMinted;
    uint256 public maxMintPerWallet = 1;
    uint256 public maxMintPerWalletPuzzler = 1;

	//mappings
	mapping(uint256 => bool) private soldOut;
    mapping(address => uint256) private mintCountMap;
	mapping(address => uint256) private allowedMintCountMap;
    mapping(address => uint256) private mintCountMapPuzzler;
	mapping(address => uint256) private allowedMintCountMapPuzzler;

	uint256 constant level1 = 1;
	uint256 constant level2 = 2;
	uint256 constant level3 = 3;
	uint256 constant puzzler = 4;

	event Redeemed(address indexed from, uint256 id, uint256 uuid);

	string public _baseURI;
	string public _contractURI;

	bool saleLive = false;
	bool burnLive = false;

	constructor() 
	ERC1155(_baseURI) 
    EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) 
	{}

	function mintLevel1(uint256 qty, string memory name, bytes memory signature) public {
	    require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
		require(saleLive, "sale is not live");
		require(soldOut[level1] == false, "item out of stock");
        require(allowedMintCount(msg.sender) >= 1,"You minted too many");
	
		totalMinted = totalMinted + qty;
		_totalSupply[level1] = _totalSupply[level1] + qty;
		_mint(msg.sender, level1, qty, "0x0000");
		updateMintCount(msg.sender);
	}

	function mintLevel2(uint256 qty, string memory name, bytes memory signature) public {
	    require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
		require(saleLive, "sale is not live");
		require(soldOut[level2] == false, "item out of stock");
        require(allowedMintCount(msg.sender) >= 1,"You minted too many");
		
		totalMinted = totalMinted + qty;
		_totalSupply[level2] = _totalSupply[level2] + qty;
		_mint(msg.sender, level1, qty, "0x0000");
		_mint(msg.sender, level2, qty, "0x0000");
		updateMintCount(msg.sender);
	}

    function mintLevel3(uint256 qty, string memory name, bytes memory signature) public {
	    require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
		require(saleLive, "sale is not live");
		require(soldOut[level3] == false, "item out of stock");
	    require(allowedMintCount(msg.sender) >= 1,"You already minted");
		
		totalMinted = totalMinted + qty;
		_totalSupply[level3] = _totalSupply[level3] + qty;
		_mint(msg.sender, level1, qty, "0x0000");
		_mint(msg.sender, level2, qty, "0x0000");
		_mint(msg.sender, level3, qty, "0x0000");
		updateMintCount(msg.sender);
	}

	function mintPuzzler(uint256 qty, string memory name, bytes memory signature) public {
	    require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
		require(saleLive, "sale is not live");
		require(soldOut[puzzler] == false, "item out of stock");
	    require(allowedMintCountPuzzler(msg.sender) >= 1,"You already minted");
		
		totalMinted = totalMinted + qty;
		_totalSupply[puzzler] = _totalSupply[puzzler] + qty;
		_mint(msg.sender, puzzler, qty, "0x0000");
		updateMintCountPuzzler(msg.sender);
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
	
    function check(string memory name, bytes memory signature) public view returns (address) {
        return _verify( name, signature);
    }

    function _verify(string memory name, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(name);
        return ECDSA.recover(digest, signature);
    }

    function _hash(string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(string name)"),
            keccak256(bytes(name))
        )));
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

	function allowedMintCount(address minter) public view returns (uint256) {
    return maxMintPerWallet - mintCountMap[minter];
     }
	
	function updateMintCount(address minter) private {
    mintCountMap[minter] += 1;
    }

	function allowedMintCountPuzzler(address minter) public view returns (uint256) {
    return maxMintPerWalletPuzzler - mintCountMapPuzzler[minter];
    }
	
	function updateMintCountPuzzler(address minter) private {
    mintCountMapPuzzler[minter] += 1;
    }

	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	// sets soldout
	function setSoldOut(uint256 _id, bool isSoldOut) external onlyOwner {
		soldOut[_id] = isSoldOut;
	}

	// enables sales
	function setSaleLive(bool _saleLive) external onlyOwner {
		saleLive = _saleLive;
	}

	//max switch
	function setMaxPerWallet(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet = _newMaxMintAmount;
	}
	function setMaxPerWalletPuzzler(uint256 _newMaxMintAmount) public onlyOwner {	
	maxMintPerWalletPuzzler = _newMaxMintAmount;
	}

	// enables burn
	function setBurnLive(bool _burnLive) external onlyOwner {
		burnLive = _burnLive;
	}

	function withdrawToOwner() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}