// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";
import "Strings.sol";
import "Payment.sol";

//                                              |                             |                                                
//   .7~   ~!.                                 /#\                 ^!.  :~.  /#\       ~~                                      
//   .5?  7Y:                             ?7    V                  J5: ^J^    V       .5J                                      
//   :5? !?.    ^^ ^~  ~^   ^~  :~.:~^   ~YJ^  .~.    :~!^.        ?5 ^?.    .^.   :~^^5?    .^:.                              
//   :5J7P^     YP?~^  !P^ ^P!  ~P7!YP7  ^5J:  :5^  .J5~~Y?        ?5!5!     ^P^  :55^~57   !7::!^                             
//   :5P??5.   .5P^     JY J5   ^P: :5Y  .P7   :5:  ^G?   .        ?P5?5:    :P^  7P? .57   ?J^.                               
//   .5?  JY.  :PP:     .5?P!   ^P:  5J  .PJ   :P:  ^G?            J5. ?5    ^P^  ?G?  5?    .:~?~                             
//    5?  .5Y  :GG^      !G5.   ~G7.~G?   ?GJ: ~G^  .YP~~?~        Y5   5J   ^G^  ~G5:!G?  .!!::YJ                             
//    7~   :7: .7?^      :G!    !G^^!7:    ^?^ :7:   .~!~^         !!   :J:  :7.   !7~^7~   ^7J?!                              
//                      .~YJ     !G:                                                                                            
//                      .!^      ^?.                                                                                            

contract KrypticKids is Ownable, ERC721A, ReentrancyGuard, Payment {
    using Strings for uint256;
    string public baseURI;

  	//Settings
  	uint256 public maxSupply = 8128;
	uint256 private packPrice = 0.023 ether;
	bool public publicStatus = false;
	mapping(address => uint256) public packCounter;
    
    //Number for random
	uint256 nonce;

	//Max Mint
	uint256 public maxPack = 5; 

	//Shares
	address[] private addressList = [0x8B9789ce9745721Dfd2aD9D06Ae7c1662eB7B105, 0xa2A874524A8d90c3CEAb01369196D23CDee8C038];
	uint[] private shareList = [50, 50];

	//Token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721A(_name, _symbol, 100, maxSupply)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
	}

    // Public Mint
    function publicMintPack() nonReentrant public payable {
		uint256 s = totalSupply();
		uint256 mintAmount = 0;
		require(s + 3 <= maxSupply, "Mint less");
		require(packCounter[msg.sender] <= maxPack, "Minted max amount of packs");
		require(msg.value >= packPrice, "ETH input is wrong");
		require(publicStatus == true, "Public sale is not live");
        
		mintAmount = 2 + getRandPack();
		_safeMint(msg.sender, mintAmount, "");    

		packCounter[msg.sender] += 1;
		delete s;
		delete mintAmount;
    }

	// Owner Mint
    function ownerMint(uint256 _mintAmount) public onlyOwner payable {
		uint256 s = totalSupply();
		require(s + _mintAmount <= maxSupply, "Mint less");
         
		_safeMint(msg.sender, _mintAmount, "");    
		delete s;
    }

	//Random Pseudo-Number Generation 
	function getRandPack() internal returns (uint) { 
		uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100; //0-99
        nonce++;
	   if(randomnumber < 89) {
		  randomnumber = 0;
        }
	   if(randomnumber >= 89) {
		  randomnumber = 1;
	   }
        require(randomnumber < 2, "Extra card greater than 1");
  		return randomnumber;
    }

	// Read Metadata
	function _baseURI() internal view virtual override returns (string memory) {
	   return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	   require(tokenId <= maxSupply);
	   string memory currentBaseURI = _baseURI();
	   return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//Max Switch
	function setMaxPack(uint256 _newMaxPackAmount) public onlyOwner {
	   maxPack = _newMaxPackAmount;
	}
	
	//Write Metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	   baseURI = _newBaseURI;
	}

	//price switch
	function setPackPrice(uint256 _newPackPrice) public onlyOwner {
		packPrice = _newPackPrice;
	}

	//Set Public Status
	function setP(bool _pstatus) public onlyOwner {
		publicStatus = _pstatus;
	}
	
	function withdraw() public payable onlyOwner {
	   (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	   require(success);
	}
}