// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract Goony is ERC721A, EIP712, Payment, Ownable {  
    using Strings for uint256;
    string public _baseURIextended;

    //signature
    string private constant SINGING_DOMAIN = "GOONY";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 6555;
	bool public presaleStatus = false;
	bool public expressStatus = false;
    bool public publicStatus = false;
	uint256 private price = 0.1 ether;
	uint256 private presaleSupply = 3090;
	uint256 private expressSupply = 1650;
	uint256 private publicSupply = 1650;
	uint256 private adminminting = 155; //155 presale
	uint256 private adminminting2 = 10; // 10 at end
	uint256 private maxMintPerTxPresale = 2;
    uint256 private maxMintPerWalletPresale = 2;
	uint256 private maxMintPerTxExpress = 2; 
    uint256 private maxMintPerWalletExpress = 2; 
	uint256 private maxMintPerTxPublic= 5; 
    
    //shares
	address[] private addressList = [
	0xE584197e8feD912e22BbcB880a8dAC6949ccb990,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5,
	0xFF755FAfD67F65Ae9Cc9E3bE755323503deb5D34,
	0x20b2ea382e9C6d82673fc276543Db0574DcB510C,
	0xB3B85E05B35514963Bc441BEcA39b7E19179FD80,
	0x417D8FDA9cc2F83415FDa095457ADFd6Bdc0d7ca
	];

	uint[] private shareList = [
	52,
	16,
	12,
	10,
	5,
	5
	];

	//mappings
    mapping(address => uint256) private mintCountMapPresale;
    mapping(address => uint256) public allowedMintCountMapPresale;
    mapping(address => uint256) private mintCountMapExpress;
    mapping(address => uint256) public allowedMintCountMapExpress;
	
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
	    require(s + _tokenAmount <= (maxSupply - adminminting2), "Mint less");
		require(_tokenAmount <= maxMintPerTxPresale);
		require(s + _tokenAmount <= (presaleSupply + adminminting),"Presale is sold out");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountPresale(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
	   updateMintCountPresale(msg.sender, _tokenAmount);
    }

 	function mintExpress(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  		uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(expressStatus,"Express sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	   	require(_tokenAmount <= maxMintPerTxExpress);
	    require(s + _tokenAmount <= (maxSupply - adminminting2), "Mint less");
		require(s + _tokenAmount <= (expressSupply + presaleSupply + adminminting),"Express is sold out");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
		require(allowedMintCountExpress(msg.sender) >= _tokenAmount,"You minted too many");
		require(tx.origin == msg.sender);  //stop contract buying
       _safeMint(msg.sender, _tokenAmount);
		updateMintCountExpress(msg.sender, _tokenAmount);
	}

 	function mintPublic(uint256 _tokenAmount) public payable {
		uint256 s = totalSupply();
	    require(publicStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxPublic);
		require( s + _tokenAmount <= (maxSupply - adminminting2), "Mint less");
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

	function updateMintCountExpress(address minter, uint256 count) private {
    mintCountMapExpress[minter] += count;
    }

    function allowedMintCountExpress(address minter) public view returns (uint256) {
    return maxMintPerWalletExpress - mintCountMapExpress[minter];
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
	function setPresale(bool _status) public onlyOwner {
		presaleStatus = _status;
	}
	function setExpress(bool _status) public onlyOwner {
		expressStatus = _status;
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
	function setMaxPerWalletPresale(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletPresale = _newMaxMintAmount;
	}
	function setMaxPerTxPresale(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPresale = _newMaxAmount;
	}
	function setMaxPerWalletExpress(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletExpress = _newMaxMintAmount;
	}
	function setMaxPerTxExpress(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxExpress = _newMaxAmount;
	}
	function setMaxPerTxPublic(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTxPublic= _newMaxAmount;
	}

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}