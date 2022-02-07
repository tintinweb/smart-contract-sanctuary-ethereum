// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract ANONMODE is ERC721Enumerable,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "ANONMODE";
    string private constant SIGNATURE_VERSION = "4";

    //settings
  	uint256 public maxSupply = 8888;
	bool public whitelist1Status = false;
	bool public whitelist2Status = false;
    bool public whitelist3Status = false;
	bool public publicStatus = false;
	uint256 private priceWhitelist1 = 0.035 ether;
	uint256 private priceWhitelist2 = 0.045 ether;
	uint256 private priceWhitelist3 = 0.055 ether;
	uint256 private pricePublic = 0.07 ether;
	uint256 public maxMintPerTxWhitelist1 = 7;
	uint256 public maxMintPerTxWhitelist2 = 7;
	uint256 public maxMintPerTxWhitelist3 = 7;
	uint256 public maxMintPerTxPublic = 7;
    uint256 public maxMintPerWalletWhitelist1 = 7;
	uint256 public maxMintPerWalletWhitelist2 = 7;
	uint256 public maxMintPerWalletWhitelist3 = 7;

    //mappings
     mapping(address => uint256) private mintCountMapWhitelist1;
     mapping(address => uint256) private allowedMintCountMapWhitelist1;
     mapping(address => uint256) private mintCountMapWhitelist2;
     mapping(address => uint256) private allowedMintCountMapWhitelist2;
     mapping(address => uint256) private mintCountMapWhitelist3;
     mapping(address => uint256) private allowedMintCountMapWhitelist3;
    
    //shares
	address[] private addressList = [
		0x355c000d78F087821517378e5be3f13dB29b9014,
		0x5a1a77e341D751451793B8E061dC47AFD24a1092,
		0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];
    
	uint[] private shareList = [73,
								7,
								20];

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

 	function mintWhitelist1(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	    uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelist1Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist1, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= priceWhitelist1 * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountWhitelist1(msg.sender) == maxMintPerWalletWhitelist1,"You already minted"); //check if already minted
            for (uint256 i = 0; i < _tokenAmount + 1; ++i) {
            _safeMint(msg.sender, s + i, "");
       	}
    }

 	function mintWhitelist2(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelist2Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist2, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= priceWhitelist2 * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountWhitelist2(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
        delete s;
        updateMintCountWhitelist2(msg.sender, _tokenAmount);
    }

 	function mintWhitelist3(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelist3Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist3, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= priceWhitelist3 * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountWhitelist3(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
        delete s;
        updateMintCountWhitelist3(msg.sender, _tokenAmount);
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
    function allowedMintCountWhitelist1(address minter) public view returns (uint256) {
    	return maxMintPerWalletWhitelist1 - mintCountMapWhitelist1[minter];
     }
    function allowedMintCountWhitelist2(address minter) public view returns (uint256) {
    	return maxMintPerWalletWhitelist2 - mintCountMapWhitelist2[minter];
     }
    function allowedMintCountWhitelist3(address minter) public view returns (uint256) {
    	return maxMintPerWalletWhitelist3 - mintCountMapWhitelist3[minter];
     }
    function updateMintCountWhitelist1(address minter, uint256 count) private {
    	mintCountMapWhitelist1[minter] += count;
     }
    function updateMintCountWhitelist2(address minter, uint256 count) private {
    	mintCountMapWhitelist2[minter] += count;
     }
    function updateMintCountWhitelist3(address minter, uint256 count) private {
    	mintCountMapWhitelist3[minter] += count;
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

	function setPriceWL1(uint256 _newPrice) public onlyOwner {
		priceWhitelist1 = _newPrice;
	}
	function setPriceWL2(uint256 _newPrice) public onlyOwner {
		priceWhitelist2 = _newPrice;
	}
	function setPriceWL3(uint256 _newPrice) public onlyOwner {
		priceWhitelist3 = _newPrice;
	}
	function setPricePublic(uint256 _newPrice) public onlyOwner {
		pricePublic = _newPrice;
	}

	//max switch
	function setMaxPerTxWhitelist1(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxWhitelist1 = _newMaxMintAmount;
	}
	function setMaxPerTxWhitelist2(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxWhitelist2 = _newMaxMintAmount;
	}
	function setMaxPerTxWhitelist3(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxWhitelist3 = _newMaxMintAmount;
	}
	function setMaxPerTxPublic(uint256 _newMaxMintAmount) public onlyOwner {
		maxMintPerTxPublic = _newMaxMintAmount;
	}

    //max switch
	function setMaxPerWalletWhitelist1(uint256 _newMaxMintAmount) public onlyOwner {
	    maxMintPerWalletWhitelist1 = _newMaxMintAmount;
	}
	function setMaxPerWalletWhitelist2(uint256 _newMaxMintAmount) public onlyOwner {
	    maxMintPerWalletWhitelist2 = _newMaxMintAmount;
	}
	function setMaxPerWalletWhitelist3(uint256 _newMaxMintAmount) public onlyOwner {
    	maxMintPerWalletWhitelist3 = _newMaxMintAmount;
	}

    //onoff switch
	function setWhitelist1(bool _wlstatus) public onlyOwner {
		whitelist1Status = _wlstatus;
	}
	function setWhitelist2(bool _wlstatus) public onlyOwner {
		whitelist2Status = _wlstatus;
	}
	function setWhitelist3(bool _wlstatus) public onlyOwner {
		whitelist3Status = _wlstatus;
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