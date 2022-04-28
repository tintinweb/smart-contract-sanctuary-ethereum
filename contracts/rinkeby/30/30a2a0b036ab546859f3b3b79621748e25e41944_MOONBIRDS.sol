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
                                                                      


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";



contract MOONBIRDS is ERC721A, Ownable {
    using MerkleProof for bytes32[];   
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_PER_MINT = 20;
    uint256 private MINT_PER_FREE_TX = 1;

    uint256 public price = 0.02 ether;
    uint256 public maxSupply = 4269;
    uint256 public freeSUPPLY = 269;

    bool public publicSaleStarted = false;
    bool public revealed = false;

    bytes32 public root;

    mapping(address => bool) private _mintedClaim;


    string public notRevealedUri = "ipfs://QmU6csiGp7rh5NAKUVEUZh9hFP6qYyUzQLNKUynNqgukuR/hidden.json";
    string public baseURI = "ipfs://MAMCITAzor";

    constructor() ERC721A("MBFLTESTCOLLTESTEST", "FLMUTANT", 500) {
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns(bool){

        return MerkleProof.verify(proof,root,leaf);
        
    }





    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setroot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        revealed = true;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    maxSupply = _newMaxSupply;
	}

    function setFreeSupply(uint256 newSupply) external onlyOwner {
        if (newSupply >= freeSUPPLY) {
            revert("New supply exceed previous free supply");
        }
        freeSUPPLY = newSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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


    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(tokens <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    function freeMint(bytes32[] memory proof)
        public
        
        callerIsUser
    {
        if (!isSaleActive()) revert("Sale not started");
        if (hasMintedClaim(msg.sender)) revert("Amount exceeds claim limit");
        if (totalSupply() + MINT_PER_FREE_TX > (maxSupply - freeSUPPLY)) revert("Amount exceeds supply");

        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))),"Not a part of FL");

        _mintedClaim[msg.sender] = true;
        _safeMint(msg.sender, MINT_PER_FREE_TX);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(0x657270615dc17498b58F4BA37a3109e7D059CF3B, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }
    function isSaleActive() public view returns (bool) {
        return publicSaleStarted;
    }

}