// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./MerkleProof.sol";

contract APSTest is ERC721AQueryable, Ownable{

    uint public maxSupply = 3333;
    uint public maxPerWallet = 2;

    bool public wlMintOpen = false;
    bool public mintOpen = false;

    string internal baseTokenURI = "";
    bytes32 public merkleRoot = "";

    constructor() ERC721A("APS Test", "APSTest") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toggleMint() external onlyOwner {
        wlMintOpen = false;
        mintOpen = !mintOpen;
    }

    function toggleWhitelistMint() external onlyOwner {
        mintOpen = false;
        wlMintOpen = !wlMintOpen;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }
    
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return _baseURI();
    }

    function mintAdmin(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function mint(uint qty) external payable {
        require(mintOpen, "Public sale not active");
        _mintCheck(qty);
    }

    function whitelistMint(uint qty, bytes32[] calldata proof) external payable {
        require(wlMintOpen, "Whitelist sale not active");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted!");
        _mintCheck(qty);
    }

    function _mintCheck(uint qty) internal {
        require(qty > 0, "Can't mint 0");
        require(qty + _numberMinted(_msgSender()) <= maxPerWallet, "Max mint per wallet reached");
        _mintTo(_msgSender(), qty);                
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() + _totalBurned() <= maxSupply, "Exceeds total supply");
        _mint(to, qty);
    }
	
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }
	
    function mintedBySender() external view returns (uint256) {
        return _numberMinted(_msgSender());
    }
	
    function burnedByOwner(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }
    
	function melt(uint256 tokenId) external {
        _burn(tokenId, true);
	}
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}