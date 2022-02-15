// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract FiHP is ERC721A,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "FIHP";
    string private constant SIGNATURE_VERSION = "4";

    //settings
  	uint256 public maxSupply = 1000;
	bool public genesisStatus = false;
	bool public phase1Status = false;
    bool public phase2Status = false;
	bool public phase3Status = false;
	bool private phase1Whitelist = false;
	bool private phase2Whitelist = false;
	bool private phase3Whitelist = false;
	uint256 private priceGenesis = 1.0 ether;
	uint256 private pricePhase1 = 2.0 ether;
	uint256 private pricePhase2 = 2.0 ether; //subject to change
	uint256 private pricePhase3 = 2.0 ether; //subject to change
	uint256 private genesisSupply = 100; //less 1 for token 0
	uint256 private phase1Supply = 300;
	uint256 private phase2Supply = 300;
	uint256 private phase3Supply = 300;
	uint256 public maxMintPerTx = 1;
    uint256 public maxMintPerWallet = 1;
	uint256 public totalGenesis;
	uint256 public totalPhase1;
	uint256 public totalPhase2;
	uint256 public totalPhase3;
    
    //shares
	address[] private addressList = [0xb794a625303Ad37BD9690F60527233Cb02fe0E83];

	uint[] private shareList = [100];

	 //mappings
    mapping(address => uint256) private mintCountMap;
    mapping(address => uint256) private allowedMintCountMap;

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
		require(_tokenAmount <= maxMintPerTx);
		require(totalGenesis + _tokenAmount <= genesisSupply,"This phase is sold out");
	    require(msg.value >= priceGenesis * _tokenAmount, "ETH input is wrong");
		require(allowedMintCount(msg.sender) >= 1,"You minted too many");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
       	}
	   totalGenesis += _tokenAmount;
	   updateMintCount(msg.sender, _tokenAmount);
    }

 	function mintPhase1(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(!phase1Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase1Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	   	require(_tokenAmount <= maxMintPerTx);
	    require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase1 + _tokenAmount <= phase1Supply,"This phase is sold out");
	    require(msg.value >= pricePhase1 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCount(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase1 += _tokenAmount;
		updateMintCount(msg.sender, _tokenAmount);
    }

 	function mintPhase2(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(!phase2Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase2Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTx);
		require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase2 + _tokenAmount <= phase2Supply,"This phase is sold out");
	    require(msg.value >= pricePhase2 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCount(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase2 += _tokenAmount;
		updateMintCount(msg.sender, _tokenAmount);
    }

  	function mintPhase3(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(!phase3Whitelist || check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
	    require(phase3Status,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTx);
		require( s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase3 + _tokenAmount <= phase3Supply,"This phase is sold out");
	    require(msg.value >= pricePhase3 * _tokenAmount, "ETH input is wrong");
		require(allowedMintCount(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
		totalPhase3 += _tokenAmount;
		updateMintCount(msg.sender, _tokenAmount);
    }

    // admin minting
	function giftGenesis(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalGenesis + _tokenAmount <= genesisSupply,"This phase is sold out");
		require(allowedMintCount(msg.sender) >= 1,"You minted too many");
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
	function giftPhase13(uint256 _tokenAmount, address addr) public onlyOwner {
  	    uint256 s = totalSupply();
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(s + _tokenAmount <= maxSupply, "Mint less");
		require(totalPhase3 + _tokenAmount <= phase3Supply,"This phase is sold out");
            for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(addr, s + i, "");
       	}
	   totalPhase3 += _tokenAmount;
    }

	function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
    }

    function allowedMintCount(address minter) public view returns (uint256) {
    return maxMintPerWallet - mintCountMap[minter];
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

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	//max switches
	function setMaxPerWallet(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet = _newMaxMintAmount;
	}
	function setMaxPerTx(uint256 _newMaxAmount) public onlyOwner {
	maxMintPerTx = _newMaxAmount;
	}

    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}