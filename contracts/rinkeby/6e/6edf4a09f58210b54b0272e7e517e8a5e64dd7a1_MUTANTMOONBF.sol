// SPDX-License-Identifier: MIT
// creator: twitter.com/mutatoshibird

/* _____ ______   ___  ___  _________  ________  _________  ________  ________  ___  ___  ___     
|\   _ \  _   \|\  \|\  \|\___   ___\\   __  \|\___   ___\\   __  \|\   ____\|\  \|\  \|\  \    
\ \  \\\__\ \  \ \  \\\  \|___ \  \_\ \  \|\  \|___ \  \_\ \  \|\  \ \  \___|\ \  \\\  \ \  \   
 \ \  \\|__| \  \ \  \\\  \   \ \  \ \ \   __  \   \ \  \ \ \  \\\  \ \_____  \ \   __  \ \  \  
  \ \  \    \ \  \ \  \\\  \   \ \  \ \ \  \ \  \   \ \  \ \ \  \\\  \|____|\  \ \  \ \  \ \  \ 
   \ \__\    \ \__\ \_______\   \ \__\ \ \__\ \__\   \ \__\ \ \_______\____\_\  \ \__\ \__\ \__\
    \|__|     \|__|\|_______|    \|__|  \|__|\|__|    \|__|  \|_______|\_________\|__|\|__|\|__|
                                                                      \|_________|              */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract MUTANTMOONBF is ERC721A, Ownable, ReentrancyGuard {

    using MerkleProof for bytes32[];
    using SafeMath for uint256;
    using Strings for uint256;

    string private _baseTokenURI;
    bool private _saleStatus = false;
    bool public revealed = false;
    uint256 private _salePrice = 0.02 ether;
    
	bytes32 private _claimMerkleRoot;



    mapping(address => bool) private _mintedClaim;

    uint256 private MAX_MINTS_PER_TX = 20;
    uint256 private MINT_PER_FREE_TX = 1;
	
    uint256 public MAX_SUPPLY = 4269;
    uint256 public FREE_SUPPLY = 269;

    string public notRevealedUri = "ipfs://QmU6csiGp7rh5NAKUVEUZh9hFP6qYyUzQLNKUynNqgukuR/hidden.json";
    string public baseURI = "ipfs://QmZZBUdpoRqPS3Pt6VKPsAdXTDhPsJWp4AQXcAvwtx7SCs/";

    constructor() ERC721A("MMOONBF", "MMBF") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier verify(
        address account,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            merkleProof.verify(
                merkleRoot,
                keccak256(abi.encodePacked(account))
            ),
            "Address not listed"
        );
        _;
    }

     function reveal() public onlyOwner {
      revealed = true;
  }

    

    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, (tokenId).toString(), ".json"))
        : "";
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        withdraw(0x657270615dc17498b58F4BA37a3109e7D059CF3B, address(this).balance);
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
        callerIsUser
        verify(msg.sender, merkleProof, _claimMerkleRoot)
    {
        if (!isSaleActive()) revert("Sale not started");
        if (hasMintedClaim(msg.sender)) revert("Amount exceeds claim limit");
        if (totalSupply() + MINT_PER_FREE_TX > (MAX_SUPPLY - FREE_SUPPLY)) revert("Amount exceeds supply");
        _mintedClaim[msg.sender] = true;
        _safeMint(msg.sender, MINT_PER_FREE_TX);
    }

    function saleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
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