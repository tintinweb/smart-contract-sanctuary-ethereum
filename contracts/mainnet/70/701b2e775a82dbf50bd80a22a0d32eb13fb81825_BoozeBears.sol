// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract BoozeBears is ERC721A,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "BOOZEBEARS";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 3333;
	bool public whitelistStatus = false;
	bool public publicStatus = false;
	uint256 private price = 0.03 ether;
	uint256 public maxMintPerTxPublic = 5;
    uint256 public maxMintPerWalletPublic = 20;
	uint256 public maxMintPerTxWhitelist = 2;
    uint256 public maxMintPerWalletWhitelist = 2;

    //mappings
     mapping(address => uint256) private mintCountMapWhitelist;
     mapping(address => uint256) private allowedMintCountMapWhitelist;
	 mapping(address => uint256) private mintCountMapPublic;
     mapping(address => uint256) private allowedMintCountMapPublic;

    	//shares
	address[] private addressList = [
		0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5,
		0x1f301d288FAd9E11E1Ca8411500720a375154764,
		0xEa66DB6c0aA43387aa2A5828428Da71fb6305122,
		0x4892cfe386f14Cf8640F6CA124E0F97DC1b7af57,
		0x6E8c8B9E868dA7aC2a46403C7F530e565CbFB762,
		0x25bC5dCb73E4C800bF95adCCb95451a3fBf434f6,
		0x2A27E3B5e8194cf7bd329759B7ED8e2bEBE77Cb1,
		0x5C610C2371c82B7bad631c3F13A80307cDF99762,
		0x34275F6fc1635A15546ce6696Eb298423bcc5E6b,
		0x00F8085B11b09dDDde756Cb5C3bCa6BC5EfBf37F,
		0xe558bcCbA1Ee470d07d42E09817eeC622A78FeAD,
		0x9b3b9eaf47647C28a842520d1757Da190eDf6648
	];
	uint[] private shareList = [10,
    							10,
								3,
								3,
								4,
								3,
								5,
								20,
								8,
								28,
								5,
								1];

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

    function mintWhitelist(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelistStatus,"Whitelist sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
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
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
        require(allowedMintCountPublic(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
             _safeMint(msg.sender, s + i, "");
       	}
        delete s;
	    updateMintCountPublic(msg.sender, _tokenAmount);
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

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(tokenId <= maxSupply);
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

    function updateMintCountWhitelist(address minter, uint256 count) private {
    mintCountMapWhitelist[minter] += count;
     }

    function allowedMintCountWhitelist(address minter) public view returns (uint256) {
    return maxMintPerWalletWhitelist - mintCountMapWhitelist[minter];
    }

	function updateMintCountPublic(address minter, uint256 count) private {
    mintCountMapPublic[minter] += count;
     }

    function allowedMintCountPublic(address minter) public view returns (uint256) {
    return maxMintPerWalletPublic - mintCountMapPublic[minter];
    }

    //price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
	price = _newPrice;
	}

	//max switch
	function setMaxPerTxWhitelist(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerTxWhitelist = _newMaxMintAmount;
	}
		//max switch
	function setMaxPerTxPublic(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerTxPublic = _newMaxMintAmount;
	}

    //max switch
	function setMaxPerWalletWhitelist(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletWhitelist = _newMaxMintAmount;
	}
	function setMaxPerWalletPublic(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWalletPublic = _newMaxMintAmount;
	}

    	//onoff switch
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