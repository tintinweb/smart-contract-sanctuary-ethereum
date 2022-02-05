// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract ELEMENTAL is ERC721Enumerable,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "ELEMENTAL";
    string private constant SIGNATURE_VERSION = "4";

    //settings
  	uint256 public maxSupply = 2022;
	bool public OGStatus = false;
	bool public whitelistStatus = false;
	bool public publicStatus = false;
	uint256 private priceOG = 0.2 ether;
	uint256 private priceWhitelist = 0.2 ether;
	uint256 private pricePublic = 0.3 ether;
	uint256 public maxMintPerTxPublic = 5;
	uint256 public maxMintPerTxOG = 2;
	uint256 public maxMintPerTxWhitelist = 1;
    uint256 public maxMintPerWalletOG = 2;
	uint256 public maxMintPerWalletWhitelist = 1;

    //mappings
     mapping(address => uint256) private mintCountMapOG;
     mapping(address => uint256) private allowedMintCountMapOG;
     mapping(address => uint256) private mintCountMapWhitelist;
     mapping(address => uint256) private allowedMintCountMapWhitelist;
    	//shares
	address[] private addressList = [
		0xb1270a3D1F50440B32d62D088Aa30556Dcc8F950,
		0x41Fb9227c703086B2d908E177A692EdCD3d7DE2C,
		0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];
	uint[] private shareList = [75,
								20,
								5];

    constructor(
        	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
    ) 
    ERC721(_name, _symbol) 
    EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) 
    Payment(addressList, shareList) {
          setURI(_initBaseURI); 
    }


 	function mintOG(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(OGStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxOG, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= priceOG * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountOG(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
        delete s;
        updateMintCountOG(msg.sender, _tokenAmount);
    }

    function mintWhitelist(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelistStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= priceOG * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountWhitelist(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
        delete s;
        updateMintCountWhitelist(msg.sender, _tokenAmount);
    }
 
 

    function mintPublic(uint256 _tokenAmount) public payable {
  	uint256 s = totalSupply();
        require(publicStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxPublic, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= pricePublic * _tokenAmount, "ETH input is wrong");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
             _safeMint(msg.sender, s + i, "");
       	}
        delete s;
    }

    	// admin minting
	function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
	require(gifts.length == recipient.length);
		uint g = 0;
		uint256 s = totalSupply();
			for(uint i = 0; i < gifts.length; ++i){
			g += gifts[i];
		}
	require( s + g <= maxSupply, "Too many" );
		delete g;
			for(uint i = 0; i < recipient.length; ++i){
			for(uint j = 0; j < gifts[i]; ++j){
		_safeMint( recipient[i], s++, "" );
			}
		}
		delete s;	
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

	//allow list + max per wallet counters
    function allowedMintCountOG(address minter) public view returns (uint256) {
    	return maxMintPerWalletOG - mintCountMapOG[minter];
     }
	function allowedMintCountWhitelist(address minter) public view returns (uint256) {
    	return maxMintPerWalletWhitelist - mintCountMapWhitelist[minter];
     }
    function updateMintCountOG(address minter, uint256 count) private {
    	mintCountMapOG[minter] += count;
     }
	 function updateMintCountWhitelist(address minter, uint256 count) private {
    	mintCountMapWhitelist[minter] += count;
     }

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
		return baseURI;
	}
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(tokenId <= maxSupply);
		string memory currentBaseURI = _baseURI();
			return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}


    //price switch

	function setPriceOG(uint256 _newPrice) public onlyOwner {
		priceOG = _newPrice;
	}
	function setPriceWL(uint256 _newPrice) public onlyOwner {
		priceWhitelist = _newPrice;
	}
	function setPricePublic(uint256 _newPrice) public onlyOwner {
		pricePublic = _newPrice;
	}

	//max switch
	function setMaxPerTxWhitelist(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxWhitelist = _newMaxMintAmount;
	}
	function setMaxPerTxOG(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxOG = _newMaxMintAmount;
	}
	function setMaxPerTxPublic(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxPublic = _newMaxMintAmount;
	}

    //max switch
	function setMaxPerWalletOG(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletOG = _newMaxMintAmount;
	}
	function setMaxPerWalletWhitelist(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletWhitelist = _newMaxMintAmount;
	}

    //onoff switch
	function setOG(bool _wlstatus) public onlyOwner {
		OGStatus = _wlstatus;
	}
	function setWL(bool _wlstatus) public onlyOwner {
		whitelistStatus = _wlstatus;
	}
	function setP(bool _pstatus) public onlyOwner {
		publicStatus = _pstatus;
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}