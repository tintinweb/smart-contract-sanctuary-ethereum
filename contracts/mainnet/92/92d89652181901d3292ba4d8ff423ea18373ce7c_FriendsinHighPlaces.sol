// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract FriendsinHighPlaces is ERC721A,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "FIHP";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 1000;
	bool private genesisStatus = false;
	bool private phase1Status = false;
    bool private phase2Status = false;
	bool private phase3Status = false;
	bool private phase1Whitelist = false;
	bool private phase2Whitelist = false;
	bool private phase3Whitelist = false;
	uint256 private priceGenesis = 1.0 ether;
	uint256 private pricePhase1 = 2.0 ether;
	uint256 private pricePhase2 = 2.0 ether; //subject to change
	uint256 private pricePhase3 = 2.0 ether; //subject to change
	uint256 private genesisSupply = 100; 
	uint256 private phase1Supply = 300;
	uint256 private phase2Supply = 300;
	uint256 private phase3Supply = 300;
	uint256 private maxMintPerTxGenesis = 2;
    uint256 private maxMintPerWalletGenesis = 2;
	uint256 private maxMintPerTxWhitelist1 = 2;  //subject to change
    uint256 private maxMintPerWalletWhitelist1 = 2;  //subject to change
	uint256 private maxMintPerTxWhitelist2 = 2;  //subject to change
    uint256 private maxMintPerWalletWhitelist2 = 2;  //subject to change
	uint256 private maxMintPerTxWhitelist3 = 2;  //subject to change
    uint256 private maxMintPerWalletWhitelist3 = 2;  //subject to change
	uint256 public totalGenesis;
	uint256 public totalPhase1;
	uint256 public totalPhase2;
	uint256 public totalPhase3;
    
    //shares
	address[] private addressList = [0x8364F26C0C68a187eDf763883E52B21aF6F93924];

	uint[] private shareList = [100];

	//mappings
    mapping(address => uint256) private mintCountMapGenesis;
    mapping(address => uint256) private allowedMintCountMapGenesis;
    mapping(address => uint256) private mintCountMapWhitelist1;
    mapping(address => uint256) private allowedMintCountMapWhitelist1;
    mapping(address => uint256) private mintCountMapWhitelist2;
    mapping(address => uint256) private allowedMintCountMapWhitelist2;
    mapping(address => uint256) private mintCountMapWhitelist3;
    mapping(address => uint256) private allowedMintCountMapWhitelist3;
	
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

 	function mintGenesis(uint256 _tokenAmount) public payable {
  	    uint256 s = totalSupply();
        require(genesisStatus,"Genesis sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(_tokenAmount <= maxMintPerTxGenesis);
		require(totalGenesis + _tokenAmount <= genesisSupply,"This phase is sold out");
	    require(msg.value >= priceGenesis * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountGenesis(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
       	}
	   totalGenesis += _tokenAmount;
	   updateMintCountGenesis(msg.sender, _tokenAmount);
    }

 	function mintPhase1(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  		uint256 s = totalSupply();
        require(!phase1Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase1Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	   	require(_tokenAmount <= maxMintPerTxWhitelist1);
	    require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase1 + _tokenAmount <= phase1Supply,"This phase is sold out");
	    require(msg.value >= pricePhase1 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountWhitelist1(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase1 += _tokenAmount;
		updateMintCountWhitelist1(msg.sender, _tokenAmount);
    }

 	function mintPhase2(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  		uint256 s = totalSupply();
        require(!phase2Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase2Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist2);
		require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase2 + _tokenAmount <= phase2Supply,"This phase is sold out");
	    require(msg.value >= pricePhase2 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountWhitelist2(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase2 += _tokenAmount;
		updateMintCountWhitelist2(msg.sender, _tokenAmount);
    }

  	function mintPhase3(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  		uint256 s = totalSupply();
        require(!phase3Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase3Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist3);
		require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase3 + _tokenAmount <= phase3Supply,"This phase is sold out");
	    require(msg.value >= pricePhase3 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountWhitelist3(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase3 += _tokenAmount;
		updateMintCountWhitelist3(msg.sender, _tokenAmount);
    }

    // admin minting
	function giftGenesis(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalGenesis + _tokenAmount <= genesisSupply,"This phase is sold out");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(addr, s + i, "");
       	}
	   totalGenesis += _tokenAmount;
    }
	function giftPhase1(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase1 + _tokenAmount <= phase1Supply,"This phase is sold out");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(addr, s + i, "");
       	}
	   totalPhase1 += _tokenAmount;
    }
	function giftPhase2(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase2 + _tokenAmount <= phase2Supply,"This phase is sold out");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(addr, s + i, "");
       	}
	   totalPhase2 += _tokenAmount;
    }
	function giftPhase3(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase3 + _tokenAmount <= phase3Supply,"This phase is sold out");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(addr, s + i, "");
       	}
	   totalPhase3 += _tokenAmount;
    }

	function updateMintCountGenesis(address minter, uint256 count) private {
    mintCountMapGenesis[minter] += count;
    }

    function allowedMintCountGenesis(address minter) public view returns (uint256) {
    return maxMintPerWalletGenesis - mintCountMapGenesis[minter];
    }

	function updateMintCountWhitelist1(address minter, uint256 count) private {
    mintCountMapWhitelist1[minter] += count;
    }

    function allowedMintCountWhitelist1(address minter) public view returns (uint256) {
    return maxMintPerWalletWhitelist1 - mintCountMapWhitelist1[minter];
    }

	function updateMintCountWhitelist2(address minter, uint256 count) private {
    mintCountMapWhitelist2[minter] += count;
    }

    function allowedMintCountWhitelist2(address minter) public view returns (uint256) {
    return maxMintPerWalletWhitelist2 - mintCountMapWhitelist2[minter];
    }

	function updateMintCountWhitelist3(address minter, uint256 count) private {
    mintCountMapWhitelist3[minter] += count;
    }

    function allowedMintCountWhitelist3(address minter) public view returns (uint256) {
    return maxMintPerWalletWhitelist3 - mintCountMapWhitelist3[minter];
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
	function setGenesisPrice(uint256 _newPrice) public onlyOwner {
		priceGenesis = _newPrice;
	}
	function setPhase1Price(uint256 _newPrice) public onlyOwner {
		pricePhase1 = _newPrice;
	}
	function setPhase2Price(uint256 _newPrice) public onlyOwner {
		pricePhase2 = _newPrice;
	}
	function setPhase3Price(uint256 _newPrice) public onlyOwner {
		pricePhase3 = _newPrice;
	}

    //onoff switch
	function setGenesis(bool _status) public onlyOwner {
		genesisStatus = _status;
	}
	function setPhase1(bool _status) public onlyOwner {
		phase1Status = _status;
	}
	function setPhase2(bool _status) public onlyOwner {
		phase2Status = _status;
	}
	function setPhase3(bool _status) public onlyOwner {
		phase3Status = _status;
	}

	 //whitelist switch
	function setPhase1Whitelist(bool _status) public onlyOwner {
		phase1Whitelist = _status;
	}
	function setPhase2Whitelist(bool _status) public onlyOwner {
		phase2Whitelist = _status;
	}
	function setPhase3Whitelist(bool _status) public onlyOwner {
		phase3Whitelist = _status;
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	//max switches
	function setMaxPerWalletGenesis(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletGenesis = _newMaxMintAmount;
	}
	function setMaxPerTxGenesis(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxGenesis = _newMaxAmount;
	}
	function setMaxPerWalletWhitelist1(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletWhitelist1 = _newMaxMintAmount;
	}
	function setMaxPerTxWhitelist1(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxWhitelist1 = _newMaxAmount;
	}
	function setMaxPerWalletWhitelist2(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletWhitelist2 = _newMaxMintAmount;
	}
	function setMaxPerTxWhitelist2(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxWhitelist2 = _newMaxAmount;
	}
	function setMaxPerWalletWhitelist3(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletWhitelist3 = _newMaxMintAmount;
	}
	function setMaxPerTxWhitelist3(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxWhitelist3 = _newMaxAmount;
	}

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}