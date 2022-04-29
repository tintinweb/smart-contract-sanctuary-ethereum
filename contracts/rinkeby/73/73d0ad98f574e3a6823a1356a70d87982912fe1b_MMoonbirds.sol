// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract MMoonbirds is ERC721A, Ownable, ReentrancyGuard {

    using MerkleProof for bytes32[];

    string private _baseTokenURI;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.02 ether;
    
	bytes32 private _claimMerkleRoot;

    mapping(address => bool) private _mintedClaim;

    uint256 private MAX_MINTS_PER_TX = 20;
    uint256 private MINT_PER_FREE_TX = 1;
	
    uint256 public MAX_SUPPLY = 4269;
    uint256 public FREE_SUPPLY = 420;
	

    constructor() ERC721A("MMoonbirds", "MUTANTMB") {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setClaimMerkleRoot(bytes32 root) external onlyOwner {
        _claimMerkleRoot = root;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }
    
    function setFreeSupply(uint256 newSupply) external onlyOwner {
        if (newSupply >= FREE_SUPPLY) {
            revert("New supply exceed previous free supply");
        }
        FREE_SUPPLY = newSupply;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function withdrawAll() external onlyOwner {
 
        withdraw(0x1Ffa6d70fb19E680799cAF596C08664577b3d9D7, address(this).balance);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function claimMint(bytes32[] calldata merkleProof)
        external
        nonReentrant
        isValidMerkleProof(merkleProof, _claimMerkleRoot)
    {
        if (!isSaleActive()) revert("Sale not started");
        if (totalSupply() + MINT_PER_FREE_TX > (MAX_SUPPLY - FREE_SUPPLY)) revert("Amount exceeds supply");
        _mintedClaim[msg.sender] = true;
        _safeMint(msg.sender, MINT_PER_FREE_TX);
    }

    function saleMint(uint256 quantity)
        external
        payable
        nonReentrant
        
        
    {
        if (!isSaleActive()) revert("Sale not started");
        if (quantity > MAX_MINTS_PER_TX)
            revert("Amount exceeds transaction limit");
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");
        if (getSalePrice() * quantity > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function getClaimMerkleRoot() external view returns (bytes32) {
        return _claimMerkleRoot;
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }
}