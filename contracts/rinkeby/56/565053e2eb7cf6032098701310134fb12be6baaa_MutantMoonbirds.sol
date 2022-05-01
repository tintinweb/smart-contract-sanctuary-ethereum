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

contract MutantMoonbirds is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS_PER_TX = 20;

    uint256 public price = 0.01 ether;

    uint256 public MAX_SUPPLY = 4269;
    uint256 public FREE_SUPPLY = 420;

    bool public publicSaleStarted = false;
    bool public revealed = false;

    bytes32 public whitelistMerkleRoot;

    mapping(address => bool) private _mintedClaim;

    bytes32 public root;


    string public notRevealedUri = "ipfs://QmU6csiGp7rh5NAKUVEUZh9hFP6qYyUzQLNKUynNqgukuR/hidden.json";
    string public baseURI = "ipfs://ZORT/";

    constructor() ERC721A("Mutant Moonbirds TEST", "MUTANT") {
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    MAX_SUPPLY = _newMaxSupply;
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

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(tokens <= MAX_MINTS_PER_TX, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }


    /// Free Mint Functions

    function setRoot(bytes32 newroot) external onlyOwner {
        root = newroot;
    }
    
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function freeMint(bytes32[] memory proof)
        external
        payable
    {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        if (hasMintedClaim(msg.sender)) revert("Amount exceeds claim limit");
        if (!publicSaleStarted) revert("Sale not started");
        if (totalSupply() + 1 > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");
        if (0 * 1 > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, 1);
        _mintedClaim[msg.sender] = true;
    }

    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }

    

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
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
}