// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract IKNFT is Ownable, ERC721A, ReentrancyGuard {

	uint256 public SALE_NFT = 2950;
	uint256 public PRESALE_NFT = 2000;
	uint256 public GIVEAWAY_NFT = 50;
	
	uint256 public MAX_MINT_PRESALE = 25;
	uint256 public MAX_MINT_SALE = 25;
	
	uint256 public MAX_BY_MINT_IN_TRANSACTION_PRESALE = 5;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 8;
	
	uint256 public PRESALE_PRICE = 4 * 10**16;
	uint256 public SALE_PRICE = 5 * 10**16;
	
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	uint256 public GIVEAWAY_MINTED;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	bytes32 public merkleRoot;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
	}
	mapping (address => User) public users;
	string public _baseTokenURI;
  
  constructor() ERC721A("Invisible Kids NFT", "IKNFT") {
  }
  
  function mintGiveawayNFT(address _to, uint256 _count) public onlyOwner{
		require(
            GIVEAWAY_MINTED + _count <= GIVEAWAY_NFT, 
            "Max limit"
        );
		_safeMint(_to, _count);
		GIVEAWAY_MINTED = GIVEAWAY_MINTED + _count;
   }

  function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof) public payable{
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			presaleEnable, 
			"Pre-sale is not enable"
		);
        require(
			PRESALE_MINTED + _count <= PRESALE_NFT, 
			"Exceeds max limit"
		);
	    require(
		   MerkleProof.verify(merkleProof, merkleRoot, node), 
		   "MerkleDistributor: Invalid proof."
	    );
		require(
			users[msg.sender].presalemint + _count <= MAX_MINT_PRESALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION_PRESALE,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= PRESALE_PRICE * _count,
			"Value below price"
		);
		_safeMint(msg.sender, _count);
		PRESALE_MINTED = PRESALE_MINTED + _count;
		users[msg.sender].presalemint = users[msg.sender].presalemint + _count;
   }
	
   function mintSaleNFT(uint256 _count) public payable{
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
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }
	
	function setSaleStatus(bool status) public onlyOwner {
        require(saleEnable != status);
		saleEnable = status;
    }
	
	function setPreSaleStatus(bool status) public onlyOwner {
	   require(presaleEnable != status);
       presaleEnable = status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(PRESALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_PRESALE = newLimit;
    }
	
	function updateSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= SALE_MINTED, "Incorrect value");
        SALE_NFT = newSupply;
    }
	
	function updatePreSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= PRESALE_MINTED, "Incorrect value");
        PRESALE_NFT = newSupply;
    }
	
	function updateGiveawaySupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= GIVEAWAY_MINTED, "Incorrect value");
        GIVEAWAY_NFT = newSupply;
    }
	
	function updateMintLimitPerTransectionPreSale(uint256 newLimit) external onlyOwner {
	    require(PRESALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_PRESALE = newLimit;
    }
	
	function updateMintLimitPerTransectionSale(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_SALE = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
}