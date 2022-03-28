// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract c0ntraband is ERC721A, EIP712, Payment, Ownable {  
    using Strings for uint256;
    string public _baseURIextended;

    //signature
    string private constant SINGING_DOMAIN = "BCE";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 4207;
	bool public presaleStatus = false;
    bool public publicStatus = false;
	uint256 private price = 0.0369 ether;
	uint256 private maxMintPerTxPresale = 10;
    uint256 private maxMintPerWalletPresale = 10;
	uint256 private maxMintPerTxPublic= 10; 
    
    //shares
	address[] private addressList = [
	0x656B48B53aAE8Ffa968992aE274deBDB63Ab81cE,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];

	uint[] private shareList = [
	80,
	20
	];

	//mappings
    mapping(address => uint256) private mintCountMapPresale;
    mapping(address => uint256) public allowedMintCountMapPresale;
	mapping(address => bool) private allowed;
	
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

 	function mintPresale(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
		uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(presaleStatus,"Presale sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(_tokenAmount <= maxMintPerTxPresale);
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountPresale(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
	   updateMintCountPresale(msg.sender, _tokenAmount);
	 }

 	function mintAllowlist(uint256 _tokenAmount) public payable {
  	    uint256 s = totalSupply();
        require(allowed[msg.sender],"Address is not on the presale"); //check presale list
	    require(presaleStatus,"Presale sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(_tokenAmount <= maxMintPerTxPresale);
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountPresale(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
	   updateMintCountPresale(msg.sender, _tokenAmount);
    }


 	function mintPublic(uint256 _tokenAmount) public payable {
		uint256 s = totalSupply();
	    require(publicStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxPublic);
		require( s + _tokenAmount <= maxSupply, "Mint less");
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

	function updateMintCountPresale(address minter, uint256 count) private {
    mintCountMapPresale[minter] += count;
    }

    function allowedMintCountPresale(address minter) public view returns (uint256) {
    return maxMintPerWalletPresale - mintCountMapPresale[minter];
    }

    //price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
	}

    //onoff switch
	function setPresale(bool _status) public onlyOwner {
		presaleStatus = _status;
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

	function setAllowed(address[] calldata contracts) public onlyOwner {
        for (uint256 i; i < contracts.length; i++) {
            allowed[contracts[i]] = true;
        }
    }

    function checkAllowed(address addr) public view returns (bool) {
      return allowed[addr];
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

	//max switches
	function setMaxPerWalletPresale(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletPresale = _newMaxMintAmount;
	}
	function setMaxPerTxPresale(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPresale = _newMaxAmount;
	}
	function setMaxPerTxPublic(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPublic= _newMaxAmount;
	}

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}