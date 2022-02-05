// SPDX-License-Identifier: MIT
/*

    _            ___              _                   
   /_\__ ____ _ / __|_ _ ___ __ _| |_ _  _ _ _ ___ ___
  / _ \ V / _` | (__| '_/ -_) _` |  _| || | '_/ -_|_-<
 /_/ \_\_/\__, |\___|_| \___\__,_|\__|\_,_|_| \___/__/
          |___/                                       

*/
pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract AverageCreatures is ERC721Enum, Ownable, ReentrancyGuard {
	using Strings for uint256;
	string public baseURI;
	uint256 public _price = 0.07 ether;
	uint256 public maxSupply = 7734;
	uint256 public _reserved = 84;
    // To be removed
    // uint256 public nftPerAddressLimit = 3;
    // To be removed
    // uint256 public maxMintAmount = 20;
	bool public _paused = false;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;
    address t1 = 0xb1b2698089A238DBa899CFe0F4F1eE14F23Fa6BC;

    CollectionContract private _toyboogers = CollectionContract(0x425816A1A6CD75ED79100245e591d9c4e5D5621c);
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) ERC721P(_name, _symbol)
	{
	setBaseURI(_initBaseURI);	
	}
	// internal
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}
	function GoAverage(uint256 _mintAmount) public payable nonReentrant{
		uint256 s = totalSupply();
		require( !_paused,  "Sale paused" );
		require(_mintAmount > 0, "You need to mint at least 1 Average Creature!" );		
		require(s + _mintAmount <= maxSupply - _reserved, "Exceeds Max supply" );		
		

        if(msg.sender != owner()){
            if(onlyWhitelisted == true){
                require(isWhitelisted(msg.sender) || _toyboogers.balanceOf(msg.sender) > 0, "You're not in the Average List!");
                // To be removed
                // uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                // To be removed
                // require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            }
            require(msg.value >= _price * _mintAmount, "Insufficient Funds!");
        }

		for (uint256 i = 0; i < _mintAmount; ++i) {
			_safeMint(msg.sender, s + i, "");
		}
		delete s;
	}
	function AverageGiveaway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }
        _reserved -= _amount;
    }
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
	function setPrice(uint256 _newPrice) public onlyOwner {
		_price = _newPrice;
	}
	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
		maxSupply = _newMaxSupply;
	}
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}
	function setReserved(uint256 _newReserved) public onlyOwner {
        _reserved = _newReserved;
    }
    // To be removed
    // function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    //     nftPerAddressLimit = _limit;
    // }
    // To be removed
    // function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    //     maxMintAmount = _newmaxMintAmount;
    // }
    // WhiteList Functions
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
        if (whitelistedAddresses[i] == _user || _toyboogers.balanceOf(msg.sender) > 0) {
            return true;
        }
        }
        return false;
    }
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }
	function pause(bool val) public onlyOwner {
        _paused = val;
    }	
	function AverageWage()
    external onlyOwner
    {
        uint256 _each = address(this).balance / 100 ;
        require(payable(t1).send(_each * 100));
    }
}