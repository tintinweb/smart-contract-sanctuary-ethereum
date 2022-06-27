// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ERC721A.sol';
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

//  _     ___   ___   _  _   ___     _     ___
// | |   |_ _| / _ \ | \| | |   \   /_\   / _ \
// | |__  | | | (_) || .` | | |) | / _ \ | (_) |
// |____||___| \___/ |_|\_| |___/ /_/ \_\ \___/


contract LionDAO is Ownable, EIP712, ERC721A {

	using SafeMath for uint256;
	using Strings for uint256;

	// Sales variables
	// ------------------------------------------------------------------------
	uint256 public MAX_LION = 10000;
	uint256 public STAGE_LIMIT = 434;
	uint256 public PRICE = 0.8 ether;
	uint256 public numWhitelistSale = 0;
	uint256 public numGiveaway = 0;
	uint256 public whitelistSaleTimestamp = 1647198840; 
	bool public hasWhitelistSaleStarted = true;
	string private _baseTokenURI = "http://api.liondaonft.com/Metadata/";
	address public treasury = 0x3D8752231B74D6119C8D45939b1c3828511FC100;

	mapping (address => uint256) public hasMinted;

	// Events
	// ------------------------------------------------------------------------
	event mintEvent(address owner, uint256 quantity, uint256 totalSupply);
	
	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	EIP712("LIONDAO", "1.0.0")
	ERC721A("LION DAO", "LION"){
		_safeMint(treasury, 173);
	}  

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyWhitelistSale() {
		require(hasWhitelistSaleStarted == true, "WHITELIST_NOT_ACTIVE");
        require(block.timestamp >= whitelistSaleTimestamp, "NOT_IN_WHITELIST_TIME");
        _;
    }

	// Verify functions
	// ------------------------------------------------------------------------
	function verify(uint256 maxQuantity, bytes memory SIGNATURE) public view returns (bool){
		address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);

		return owner() == recoveredAddr;
	}

	// Whitelist functions
	// ------------------------------------------------------------------------
	function mintWhitelistLion(uint256 quantity, uint256 maxQuantity, bytes memory SIGNATURE) external payable onlyWhitelistSale{
		require(totalSupply().add(quantity) <= STAGE_LIMIT, "This stage is sold out!");
		require(verify(maxQuantity, SIGNATURE), "Not eligible for whitelist.");
		require(quantity > 0 && hasMinted[msg.sender].add(quantity) <= maxQuantity, "Exceeds max whitelist number.");
		require(totalSupply().add(quantity) <= MAX_LION, "Exceeds MAX_LION.");
		require(msg.value == PRICE.mul(quantity), "Ether value sent is not equal the price.");

		_safeMint(msg.sender, quantity);

		numWhitelistSale = numWhitelistSale.add(quantity);
		hasMinted[msg.sender] = hasMinted[msg.sender].add(quantity);

		emit mintEvent(msg.sender, quantity, totalSupply());
	}

	// Giveaway functions
	// ------------------------------------------------------------------------
	function giveawayLion(address _to, uint256 quantity) external onlyOwner{
		require(totalSupply().add(quantity) <= MAX_LION, "Exceeds MAX_LION.");

		_safeMint(_to, quantity);

		numGiveaway = numGiveaway.add(quantity);
		emit mintEvent(_to, quantity, totalSupply());
	}

	// Base URI Functions
	// ------------------------------------------------------------------------
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

    // Burn Functions
    // ------------------------------------------------------------------------
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

	// setting functions
	// ------------------------------------------------------------------------
	function setURI(string calldata _tokenURI) external onlyOwner {
		_baseTokenURI = _tokenURI;
	}

	function setSTAGE_LIMIT(uint _STAGE_LIMIT) external onlyOwner {
		STAGE_LIMIT = _STAGE_LIMIT;
	}

	function setMAX_LION(uint _MAX_num) external onlyOwner {
		MAX_LION = _MAX_num;
	}

	function set_PRICE(uint _price) external onlyOwner {
		PRICE = _price;
	}

    function setWhitelistSale(bool _hasWhitelistSaleStarted,uint256 _whitelistSaleTimestamp) external onlyOwner {
        hasWhitelistSaleStarted = _hasWhitelistSaleStarted;
        whitelistSaleTimestamp = _whitelistSaleTimestamp;
    }

	// Withdrawal functions
	// ------------------------------------------------------------------------
    function setTreasury(address _treasury) external onlyOwner {
        require(treasury != address(0), "SETTING_ZERO_ADDRESS");
        treasury = _treasury;
    }

	function withdrawAll() public payable onlyOwner {
		require(payable(treasury).send(address(this).balance));
	}
}