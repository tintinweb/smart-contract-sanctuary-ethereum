// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GOONYFRENS is ERC1155, Ownable {
	using Strings for string;

	mapping(uint256 => uint256) private _totalSupply;

	//constants	

	uint256 constant nft1 = 1;
	uint256 constant nft2 = 2;
	uint256 constant nft3 = 3;
	uint256 constant nft4 = 4;
	uint256 constant nft5 = 5;
	uint256 constant nft6 = 6;
	uint256 constant nft7 = 7;
	uint256 constant nft8 = 8;
	uint256 constant nft9 = 9;
	uint256 constant nft10 = 10;
	uint256 constant nft11 = 11;
	uint256 constant nft12 = 12;
	uint256 constant nft13 = 13;
	uint256 constant nft14 = 14;
	uint256 constant nft15 = 15;

	uint256 public nft1s;
    uint256 public nft2s;
	uint256 public nft3s;
	uint256 public nft4s;
	uint256 public nft5s;
	uint256 public nft6s;
	uint256 public nft7s;
	uint256 public nft8s;
	uint256 public nft9s;
	uint256 public nft10s;
	uint256 public nft11s;
	uint256 public nft12s;
	uint256 public nft13s;
	uint256 public nft14s;
	uint256 public nft15s;

	uint256 public supplyPerNFT = 500;

	string public _baseURI;
	string public _contractURI;

	bool saleLive = false;

    //mappings
    mapping(address => uint256) private mintCountMap1;
    mapping(address => uint256) public allowedMintCountMap1;
    uint256 private maxMintPerWallet1 = 1;
    mapping(address => uint256) private mintCountMap2;
    mapping(address => uint256) public allowedMintCountMap2;
    uint256 private maxMintPerWallet2 = 1;
    mapping(address => uint256) private mintCountMap3;
    mapping(address => uint256) public allowedMintCountMap3;
    uint256 private maxMintPerWallet3 = 1;
    mapping(address => uint256) private mintCountMap4;
    mapping(address => uint256) public allowedMintCountMap4;
    uint256 private maxMintPerWallet4 = 1;
    mapping(address => uint256) private mintCountMap5;
    mapping(address => uint256) public allowedMintCountMap5;
    uint256 private maxMintPerWallet5 = 1;
    mapping(address => uint256) private mintCountMap6;
    mapping(address => uint256) public allowedMintCountMap6;
    uint256 private maxMintPerWallet6 = 1;
    mapping(address => uint256) private mintCountMap7;
    mapping(address => uint256) public allowedMintCountMap7;
    uint256 private maxMintPerWallet7 = 1;
    mapping(address => uint256) private mintCountMap8;
    mapping(address => uint256) public allowedMintCountMap8;
    uint256 private maxMintPerWallet8 = 1;
    mapping(address => uint256) private mintCountMap9;
    mapping(address => uint256) public allowedMintCountMap9;
    uint256 private maxMintPerWallet9 = 1;
    mapping(address => uint256) private mintCountMap10;
    mapping(address => uint256) public allowedMintCountMap10;
    uint256 private maxMintPerWallet10 = 1;
    mapping(address => uint256) private mintCountMap11;
    mapping(address => uint256) public allowedMintCountMap11;
    uint256 private maxMintPerWallet11 = 1;
    mapping(address => uint256) private mintCountMap12;
    mapping(address => uint256) public allowedMintCountMap12;
    uint256 private maxMintPerWallet12 = 1;
    mapping(address => uint256) private mintCountMap13;
    mapping(address => uint256) public allowedMintCountMap13;
    uint256 private maxMintPerWallet13 = 1;
    mapping(address => uint256) private mintCountMap14;
    mapping(address => uint256) public allowedMintCountMap14;
    uint256 private maxMintPerWallet14 = 1;
    mapping(address => uint256) private mintCountMap15;
    mapping(address => uint256) public allowedMintCountMap15;
    uint256 private maxMintPerWallet15 = 1;

	constructor() ERC1155(_baseURI) {}

	// claim functions
    function claimnft1(uint256 qty) public  { //bmc
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount1(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft1s <= supplyPerNFT);
        _mint(msg.sender, nft1, qty, "");
   	    updateMintCount1(msg.sender, qty);
        nft1s += qty;
    }
    function claimnft2(uint256 qty) public  { //bomb
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount2(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft2s <= supplyPerNFT);
        _mint(msg.sender, nft2, qty, "");
   	    updateMintCount2(msg.sender, qty);
          nft2s += qty;
    }
   function claimnft3(uint256 qty) public  { //boss
       require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount3(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
            require(nft3s <= supplyPerNFT);
        _mint(msg.sender, nft3, qty, "");
   	    updateMintCount3(msg.sender, qty);
        nft3s += qty;
    }
   function claimnft4(uint256 qty) public  { //chainrun
       require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount4(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft4s <= supplyPerNFT);
        _mint(msg.sender, nft4, qty, "");
   	    updateMintCount4(msg.sender, qty);
        nft4s += qty;
    }
   function claimnft5(uint256 qty) public  { //cryptoon
       require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount5(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft5s <= supplyPerNFT);
        _mint(msg.sender, nft5, qty, "");
   	    updateMintCount5(msg.sender, qty);
        nft5s += qty;
    }
   function claimnft6(uint256 qty) public  { //dead
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount6(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
           require(nft6s <= supplyPerNFT);
        _mint(msg.sender, nft6, qty, "");
   	    updateMintCount6(msg.sender, qty);
           nft6s += qty;
    }
   function claimnft7(uint256 qty) public  { //deebies
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount7(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
            require(nft7s <= supplyPerNFT);
        _mint(msg.sender, nft7, qty, "");
   	    updateMintCount7(msg.sender, qty);
             nft7s += qty;
    }
   function claimnft8(uint256 qty) public  { //dizzy
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount8(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft8s <= supplyPerNFT);
        _mint(msg.sender, nft8, qty, "");
   	    updateMintCount8(msg.sender, qty);
               nft8s += qty;
    }
   function claimnft9(uint256 qty) public  { //doodles
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount9(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft9s <= supplyPerNFT);
        _mint(msg.sender, nft9, qty, "");
   	    updateMintCount9(msg.sender, qty);
              nft9s += qty;
    }
   function claimnft10(uint256 qty) public  { //evol
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount10(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft10s <= supplyPerNFT);
        _mint(msg.sender, nft10, qty, "");
   	    updateMintCount10(msg.sender, qty);
             nft10s += qty;
    }
   function claimnft11(uint256 qty) public  { //galatic
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount11(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft11s <= supplyPerNFT);
        _mint(msg.sender, nft11, qty, "");
   	    updateMintCount11(msg.sender, qty);
             nft11s += qty;
   }
   function claimnft12(uint256 qty) public  { //melted
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount12(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft12s <= supplyPerNFT);
        _mint(msg.sender, nft12, qty, "");
   	    updateMintCount12(msg.sender, qty);
            nft12s += qty;
    }
   function claimnft13(uint256 qty) public  { //smilesss
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount13(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft13s <= supplyPerNFT);
        _mint(msg.sender, nft13, qty, "");
   	    updateMintCount13(msg.sender, qty);
              nft13s += qty;
    }
   function claimnft14(uint256 qty) public  { //woodies
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount14(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft14s <= supplyPerNFT);
        _mint(msg.sender, nft14, qty, "");
   	    updateMintCount14(msg.sender, qty);
            nft14s += qty;
    }
   function claimnft15(uint256 qty) public  { //wow
        require(saleLive,"Sale is not live yet");
        require(qty == 1,"You can only mint 1");
      	require(allowedMintCount15(msg.sender) >= qty,"You already claimed");
  		require(tx.origin == msg.sender);  //stop contract buying
        require(nft15s <= supplyPerNFT);
        _mint(msg.sender, nft15, qty, "");
   	    updateMintCount15(msg.sender, qty);
         nft15s += qty;
    }

    //mapping logic
    function updateMintCount1(address minter, uint256 count) private {
    mintCountMap1[minter] += count;
    }
    function allowedMintCount1(address minter) public view returns (uint256) {
    return maxMintPerWallet1 - mintCountMap1[minter];
    }
	function setMaxPerWallet1(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet1 = _newMaxMintAmount;
	}
    
    function updateMintCount2(address minter, uint256 count) private {
    mintCountMap2[minter] += count;
    }
    function allowedMintCount2(address minter) public view returns (uint256) {
    return maxMintPerWallet2 - mintCountMap2[minter];
    }
	function setMaxPerWallet2(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet2 = _newMaxMintAmount;
	}

    function updateMintCount3(address minter, uint256 count) private {
    mintCountMap3[minter] += count;
    }
    function allowedMintCount3(address minter) public view returns (uint256) {
    return maxMintPerWallet3 - mintCountMap3[minter];
    }
	function setMaxPerWallet3(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet3 = _newMaxMintAmount;
	}

    function updateMintCount4(address minter, uint256 count) private {
    mintCountMap4[minter] += count;
    }
    function allowedMintCount4(address minter) public view returns (uint256) {
    return maxMintPerWallet4 - mintCountMap4[minter];
    }
	function setMaxPerWallet4(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet4 = _newMaxMintAmount;
	}

    function updateMintCount5(address minter, uint256 count) private {
    mintCountMap5[minter] += count;
    }
    function allowedMintCount5(address minter) public view returns (uint256) {
    return maxMintPerWallet5 - mintCountMap5[minter];
    }
	function setMaxPerWallet5(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet5 = _newMaxMintAmount;
	}

    function updateMintCount6(address minter, uint256 count) private {
    mintCountMap6[minter] += count;
    }
    function allowedMintCount6(address minter) public view returns (uint256) {
    return maxMintPerWallet6 - mintCountMap6[minter];
    }
	function setMaxPerWallet6(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet6 = _newMaxMintAmount;
	}

    function updateMintCount7(address minter, uint256 count) private {
    mintCountMap7[minter] += count;
    }
    function allowedMintCount7(address minter) public view returns (uint256) {
    return maxMintPerWallet7 - mintCountMap7[minter];
    }
	function setMaxPerWallet7(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet7 = _newMaxMintAmount;
	}

    function updateMintCount8(address minter, uint256 count) private {
    mintCountMap8[minter] += count;
    }
    function allowedMintCount8(address minter) public view returns (uint256) {
    return maxMintPerWallet8 - mintCountMap8[minter];
    }
	function setMaxPerWallet8(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet8 = _newMaxMintAmount;
	}

    function updateMintCount9(address minter, uint256 count) private {
    mintCountMap9[minter] += count;
    }
    function allowedMintCount9(address minter) public view returns (uint256) {
    return maxMintPerWallet9 - mintCountMap9[minter];
    }
	function setMaxPerWallet9(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet9 = _newMaxMintAmount;
	}

    function updateMintCount10(address minter, uint256 count) private {
    mintCountMap10[minter] += count;
    }
    function allowedMintCount10(address minter) public view returns (uint256) {
    return maxMintPerWallet10 - mintCountMap10[minter];
    }
	function setMaxPerWallet10(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet10 = _newMaxMintAmount;
	}

    function updateMintCount11(address minter, uint256 count) private {
    mintCountMap11[minter] += count;
    }
    function allowedMintCount11(address minter) public view returns (uint256) {
    return maxMintPerWallet11 - mintCountMap11[minter];
    }
	function setMaxPerWallet11(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet11 = _newMaxMintAmount;
	}

    function updateMintCount12(address minter, uint256 count) private {
    mintCountMap12[minter] += count;
    }
    function allowedMintCount12(address minter) public view returns (uint256) {
    return maxMintPerWallet12 - mintCountMap12[minter];
    }
	function setMaxPerWallet12(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet12 = _newMaxMintAmount;
	}

    function updateMintCount13(address minter, uint256 count) private {
    mintCountMap13[minter] += count;
    }
    function allowedMintCount13(address minter) public view returns (uint256) {
    return maxMintPerWallet13 - mintCountMap13[minter];
    }
	function setMaxPerWallet13(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet13 = _newMaxMintAmount;
	}

    function updateMintCount14(address minter, uint256 count) private {
    mintCountMap14[minter] += count;
    }
    function allowedMintCount14(address minter) public view returns (uint256) {
    return maxMintPerWallet14 - mintCountMap14[minter];
    }
	function setMaxPerWallet14(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet14 = _newMaxMintAmount;
	}


    function updateMintCount15(address minter, uint256 count) private {
    mintCountMap15[minter] += count;
    }
    function allowedMintCount15(address minter) public view returns (uint256) {
    return maxMintPerWallet15 - mintCountMap15[minter];
    }
	function setMaxPerWallet15(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet15 = _newMaxMintAmount;
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}
	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function setMaxPerNFT(uint256 _newMaxAmount) public onlyOwner {
	supplyPerNFT = _newMaxAmount;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}
	function contractURI() public view returns (string memory) {
		return _contractURI;
	}
	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {return "0";}
			uint256 j = _i;
			uint256 len;
		while (j != 0) {len++; j /= 10;}
			bytes memory bstr = new bytes(len);
			uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

    function setSale(bool _status) public onlyOwner {
		saleLive = _status;
	}

	function withdrawToOwner() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}