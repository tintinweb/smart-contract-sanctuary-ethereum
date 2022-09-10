/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
	function users(address owner) external view returns (uint256 nftminted);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
	
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
	
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
	
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		
        _status = _ENTERED;

        _;
		
        _status = _NOT_ENTERED;
    }
}

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}

contract EXERAD is Ownable, ReentrancyGuard {
	
	uint256 public MAX_MINT_NFT = 2;
	uint256 public MAX_BY_MINT_PER_TRANSACTION = 2;
	
    bool public whitelistSaleEnable = false;
	bool public publicSaleEnable = false;
	
	bytes32 public merkleRoot;
	uint256 public NFT_MINTED;
	
	struct User {
		uint256 nftminted;
    }
	
	IERC721 public EXERADNFT = IERC721(0x557E05005E541FDDBc27692750088A928d41a8F0);
	address public sender = address(0x9Ed1135cB4c953a18b76DCCdA4e2dA60dD9c161E);
	
	mapping (address => User) public users;
	
	function mintWhitelistNFT(uint256 _count, bytes32[] calldata merkleProof) external nonReentrant{
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		
		require(
			whitelistSaleEnable, 
			"WhitelistSale is not enable"
		);
        require(
		   _count <=  EXERADNFT.balanceOf(sender), 
		   "Exceeds max limit"
		);
		require(
			MerkleProof.verify(merkleProof, merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
		require(
			EXERADNFT.users(msg.sender) + users[msg.sender].nftminted + _count <= MAX_MINT_NFT,
		    "Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_PER_TRANSACTION,
			"Exceeds max mint limit per txn"
		);
		for (uint256 i = 0; i < _count; i++) {
		   uint256 tokenID = EXERADNFT.tokenOfOwnerByIndex(sender, 0);
           EXERADNFT.safeTransferFrom(sender, msg.sender, tokenID, "");
		   NFT_MINTED++;
        }
		users[msg.sender].nftminted += _count;
    }
	
	function mintPublicSaleNFT(uint256 _count) external nonReentrant{
		require(
			publicSaleEnable, 
			"Sale is not enable"
		);
        require(
		   _count <= EXERADNFT.balanceOf(sender), 
		   "Exceeds max limit"
		);
		require(
			EXERADNFT.users(msg.sender) + users[msg.sender].nftminted + _count <= MAX_MINT_NFT,
			"Exceeds max mint limit per wallet"
		);
		require(
			_count <= MAX_BY_MINT_PER_TRANSACTION,
			"Exceeds max mint limit per txn"
		);
		for (uint256 i = 0; i < _count; i++)
		{
		   uint256 tokenID = EXERADNFT.tokenOfOwnerByIndex(sender, 0);
           EXERADNFT.safeTransferFrom(sender, msg.sender, tokenID, "");
		   NFT_MINTED++;
        }
		users[msg.sender].nftminted += _count;
    }
	
	function setPublicSaleStatus(bool status) external onlyOwner {
        require(publicSaleEnable != status);
		publicSaleEnable = status;
    }
	
	function setWhitelistSaleStatus(bool status) external onlyOwner {
	   require(whitelistSaleEnable != status);
       whitelistSaleEnable = status;
    }
	
	function updateMintLimitPerWallet(uint256 newLimit) external onlyOwner {
        MAX_MINT_NFT = newLimit;
    }
	
	function updateMintLimitPerTransaction(uint256 newLimit) external onlyOwner {
        MAX_BY_MINT_PER_TRANSACTION = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
	
	function updateSender(address newSender) external onlyOwner {
	   require(newSender != address(0),  "Zero-Address");
	   sender = newSender;
	}
	
	function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}