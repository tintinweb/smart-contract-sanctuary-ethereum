// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract CodeHyperium is ERC721A, EIP712, Payment, Ownable {  
    using Strings for uint256;
    string public _baseURIextended;

    //signature
    string private constant SINGING_DOMAIN = "HYPERIUM";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 555;
	bool public phase1Status = false;
	bool public phase2Status = false;
    bool public publicStatus = false;
	uint256 private price = 0.077 ether;
	uint256 private adminminting = 55; 
	uint256 private maxMintPerTxPhase1 = 2;
    uint256 private maxMintPerWalletPhase1 = 2;
	uint256 private maxMintPerTxPhase2 = 1; 
    uint256 private maxMintPerWalletPhase2 = 1; 
	uint256 private maxMintPerTxPublic= 2; 
    
    //shares
	address[] private addressList = [
	0xeE07d159f065bB02A98Aca2055Ce4A9ebBBE2C8A,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5,
	0xd1462980eB0028318e0F0646c8bB8fBcF74d1A56,
	0xE815C8c1fD64C06367649a749EA8DAbf681e48BA
	];

	uint[] private shareList = [
	70,
	20,
	7,
	3
	];

	//mappings
    mapping(address => uint256) private mintCountMapPhase1;
    mapping(address => uint256) public allowedMintCountMapPhase1;
    mapping(address => uint256) private mintCountMapPhase2;
    mapping(address => uint256) public allowedMintCountMapPhase2;
	
	constructor(
        	string memory _name,
			string memory _symbol,
			string memory _uri
			    ) 
   			ERC721A(_name, _symbol) 
    		EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) 
   			Payment(addressList, shareList)
			   {
		    setBaseURI(_uri); 
   		 }

 	function mintPhase1(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	    uint256 s = totalSupply();
       require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase1Status,"Presale sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(_tokenAmount <= maxMintPerTxPhase1);
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountPhase1(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
	   updateMintCountPhase1(msg.sender, _tokenAmount);
    }

 	function mintPhase2(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	    uint256 s = totalSupply();
       require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase2Status,"Presale sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(_tokenAmount <= maxMintPerTxPhase2);
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountPhase2(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
	   updateMintCountPhase2(msg.sender, _tokenAmount);
    }

 	function mintPublic(uint256 _tokenAmount) public payable {
		uint256 s = totalSupply();
	    require(publicStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxPublic);
		require( s + _tokenAmount <= maxSupply , "Mint less");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
    }

    // admin minting
	function reserve(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
	    require(s + _tokenAmount <= maxSupply, "Mint less");
            _safeMint(addr, _tokenAmount);
    }

	function updateMintCountPhase1(address minter, uint256 count) private {
    mintCountMapPhase1[minter] += count;
    }

    function allowedMintCountPhase1(address minter) public view returns (uint256) {
    return maxMintPerWalletPhase1 - mintCountMapPhase1[minter];
    }

	function updateMintCountPhase2(address minter, uint256 count) private {
    mintCountMapPhase2[minter] += count;
    }

    function allowedMintCountPhase2(address minter) public view returns (uint256) {
    return maxMintPerWalletPhase2 - mintCountMapPhase2[minter];
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

    //price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
	}

    //onoff switch
	function setPhase1(bool _status) public onlyOwner {
		phase1Status = _status;
	}
	function setPhase2(bool _status) public onlyOwner {
		phase2Status = _status;
	}
	function setPublic(bool _status) public onlyOwner {
		publicStatus = _status;
	}

	//write metadata
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

	//max switches
	function setMaxPerWalletPhase1(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletPhase1 = _newMaxMintAmount;
	}
	function setMaxPerTxPhase1(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPhase1 = _newMaxAmount;
	}
	function setMaxPerWalletPhase2(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletPhase2 = _newMaxMintAmount;
	}
	function setMaxPerTxPhase2(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPhase2 = _newMaxAmount;
	}

	function setMaxPerTxPublic(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPublic= _newMaxAmount;
	}
    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}