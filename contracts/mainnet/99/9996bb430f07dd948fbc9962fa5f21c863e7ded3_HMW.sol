// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract HMW is Ownable, ERC721A, ReentrancyGuard {

	uint256 public SALE_NFT = 5405;
	uint256 public GIVEAWAY_NFT = 150;
	
	uint256 public MAX_MINT_ALPHA = 3;
	uint256 public MAX_MINT_SALE = 3;
	
	uint256 public MAX_BY_MINT_IN_TRANSACTION_ALPHA = 3;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 3;
	
	uint256 public ALPHA_ONE_PRICE = 0.068 ether;
	uint256 public SALE_PRICE = 0.088 ether;
	
	uint256 public SALE_MINTED;
	uint256 public GIVEAWAY_MINTED;
	
	bool public alphaListOneEnable = false;
	bool public alphaListTwoEnable = false;
	bool public saleEnable = false;
	
	bytes32 public alphaListOne;
	bytes32 public alphaListTwo;
	
	struct User {
		uint256 salemint;
		uint256 alphalistonemint;
		uint256 alphalisttwolimit;
		uint256 alphalisttwomint;
	}
	mapping (address => User) public users;
	string public _baseTokenURI;
  
  constructor() ERC721A("Howling Meta Wolves", "HMW") {}
  
  function giveaway(address _to, uint256 _count) public onlyOwner{
		require(
           GIVEAWAY_MINTED + _count <= GIVEAWAY_NFT, 
           "Max limit"
        );
		_safeMint(_to, _count);
		GIVEAWAY_MINTED = GIVEAWAY_MINTED + _count;
  }
  
  function AlphaMint(uint256 _count, bytes32[] calldata merkleProof) public payable{
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			alphaListOneEnable, 
			"Alphalist is not enable"
		);
        require(
			SALE_MINTED + _count <= SALE_NFT, 
			"Exceeds max limit"
		);
	    require(
		   MerkleProof.verify(merkleProof, alphaListOne, node), 
		   "MerkleDistributor: Invalid proof."
	    );
		require(
			users[msg.sender].alphalistonemint + _count <= MAX_MINT_ALPHA,
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION_ALPHA,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= ALPHA_ONE_PRICE * _count,
			"Value below price"
		);
		_safeMint(msg.sender, _count);
		SALE_MINTED = SALE_MINTED + _count;
		users[msg.sender].alphalistonemint = users[msg.sender].alphalistonemint + _count;
   }
   
   function OmegaMint(uint256 _count, uint256 _limit, bytes32[] calldata merkleProof) public payable {
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			alphaListTwoEnable, 
			"Alphalist is not enable"
		);
        require(
            SALE_MINTED + _count <= SALE_NFT,
			"Exceeds max limit"
		);
	    require(
		   MerkleProof.verify(merkleProof, alphaListTwo, node), 
		   "MerkleDistributor: Invalid proof."
	    );
		if(users[msg.sender].alphalisttwolimit == 0)
		{
		    users[msg.sender].alphalisttwolimit = _limit;
		}
		require(
			users[msg.sender].alphalisttwomint + _count <= users[msg.sender].alphalisttwolimit,
			"Exceeds max mint limit per wallet"
		);
		_safeMint(msg.sender, _count);
		SALE_MINTED = SALE_MINTED + _count;
		users[msg.sender].alphalisttwomint = users[msg.sender].alphalisttwomint + _count;
   }
   
   function HMWMint(uint256 _count) public payable{
		require(
			 saleEnable, 
			"Sale is not enable"
		);
        require(
			SALE_MINTED + _count <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			users[msg.sender].salemint + _count <= MAX_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION_SALE,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= SALE_PRICE * _count,
			"Value below price"
		);
		_safeMint(msg.sender, _count);
	    SALE_MINTED = SALE_MINTED + _count;
		users[msg.sender].salemint = users[msg.sender].salemint + _count;
   }
	
    function _baseURI() internal view virtual override returns (string memory) {
	   return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
	    _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
       uint256 balance = address(this).balance;
       payable(msg.sender).transfer(balance);
    }
	
    function numberMinted(address owner) public view returns (uint256) {
	   return _numberMinted(owner);
    }

	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
	   return ownershipOf(tokenId);
	}
	
	function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function updateAlphaListOnePrice(uint256 newPrice) external onlyOwner {
        ALPHA_ONE_PRICE = newPrice;
    }
	
	function setSaleStatus(bool status) public onlyOwner {
        require(saleEnable != status);
		saleEnable = status;
    }
	
	function setAlphaListOneStatus(bool status) public onlyOwner {
	   require(alphaListOneEnable != status);
       alphaListOneEnable = status;
    }
	
	function setAlphaListTwoStatus(bool status) public onlyOwner {
	   require(alphaListTwoEnable != status);
       alphaListTwoEnable = status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updateAlphaListOneMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_ALPHA = newLimit;
    }
	
	function updateSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= SALE_MINTED, "Incorrect value");
        SALE_NFT = newSupply;
    }
	
	function updateGiveawaySupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= GIVEAWAY_MINTED, "Incorrect value");
        GIVEAWAY_NFT = newSupply;
    }
	
	function updateMintLimitPerTransectionAlphaListOne(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_ALPHA = newLimit;
    }
	
	function updateMintLimitPerTransectionSale(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_SALE = newLimit;
    }
	
	function updateAlphaList(bytes32 newAlphaListOne, bytes32 newAlphaListTwo) external onlyOwner {
	   alphaListOne = newAlphaListOne;
	   alphaListTwo = newAlphaListTwo;
	}
}