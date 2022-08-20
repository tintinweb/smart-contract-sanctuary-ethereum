// SPDX-License-Identifier: MIT
/*

                     /$$                                     /$$                
                    |__/                                    | $$                
  /$$$$$$$ /$$   /$$ /$$        /$$$$$$  /$$   /$$ /$$$$$$$ | $$   /$$  /$$$$$$$
 /$$_____/| $$  | $$| $$       /$$__  $$| $$  | $$| $$__  $$| $$  /$$/ /$$_____/
|  $$$$$$ | $$  | $$| $$      | $$  \ $$| $$  | $$| $$  \ $$| $$$$$$/ |  $$$$$$ 
 \____  $$| $$  | $$| $$      | $$  | $$| $$  | $$| $$  | $$| $$_  $$  \____  $$
 /$$$$$$$/|  $$$$$$/| $$      | $$$$$$$/|  $$$$$$/| $$  | $$| $$ \  $$ /$$$$$$$/
|_______/  \______/ |__/      | $$____/  \______/ |__/  |__/|__/  \__/|_______/ 
                              | $$                                              
                              | $$                                              
                              |__/                                              

*/                                    
                             

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract SuiPunks is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_PAID_MINTS = 5;
    uint256 public MAX_WL_MINTS = 3;

    uint256 public WL_PRICE = 0.0075 ether;
    uint256 public PAID_PRICE = 0.015 ether;

    uint256 public PAID_SUPPLY = 993;
    uint256 public WL_SUPPLY = 1999;

    uint256 private WL_MINTED = 0;


    bool public publicSaleStarted = false;
    bool public wlSaleStarted = false;

    bool public revealed = false;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) private _mintedClaim;
    mapping(address => uint256) private _mintedMint;


    bytes32 public root;

    string public notRevealedUri = "notrevealeduri";

    // /baseURI will be changed before reveal
    string public baseURI = "revealeduri";



    constructor() ERC721A("Sui Punks", "SUIP") {
    }

    function toggleAllSales() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
        wlSaleStarted = !wlSaleStarted;

    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function togglewlSaleStarted() external onlyOwner {
        wlSaleStarted = !wlSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        revealed = true;
    }

    function setnotRevealedUri(string memory _newnotRevealedURI) external onlyOwner {
        notRevealedUri = _newnotRevealedURI;
    }

    function setWlPrice(uint256 _newWlPrice) external onlyOwner {
        WL_PRICE = _newWlPrice * (1 ether);
    }

    function setmaxMints(uint256 _newmaxMints) external onlyOwner {
        MAX_PAID_MINTS = _newmaxMints;
    }

    function setmaxwlMints(uint256 _newmaxwlMints) external onlyOwner {
        MAX_WL_MINTS = _newmaxwlMints;
    }

    function setpaidSupply(uint256 _newPaidSupply) public onlyOwner {
	    PAID_SUPPLY = _newPaidSupply;
	}

    function setWLSupply(uint256 _newWLSupply) public onlyOwner {
	    WL_SUPPLY = _newWLSupply;
	}



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function howManyMintedMint(address account) public view returns (uint256) {
        return _mintedMint[account];
    }

    /// TokenURI Function

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

  /// Reveal Function
  function reveal() public onlyOwner {
      revealed = !revealed;
  }

    /// Normal Mint Functions
    function mint(uint256 tokens) external payable {
        if (howManyMintedMint(msg.sender)>= MAX_PAID_MINTS) revert("Amount exceeds claim limit");    
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + tokens <= (PAID_SUPPLY), "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(PAID_PRICE * tokens <= msg.value, "ETH amount is incorrect");
        _safeMint(_msgSender(), tokens);
        _mintedMint[msg.sender]+=tokens;

    }

    /// Wl Mint Functions

    function setRoot(bytes32 newroot) external onlyOwner {
        root = newroot;
    }
    
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function wlMint(bytes32[] memory proof ,uint256 tokens)
        external
        payable
    {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        if (howManyMintedClaim(msg.sender)>= MAX_WL_MINTS) revert("Amount exceeds claim limit");
        if (!wlSaleStarted) revert("Sale not started");
        if (WL_MINTED + tokens > (WL_SUPPLY))
            revert("Amount exceeds supply");
        if (0 * 1 > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, tokens);
        WL_MINTED+=tokens;
        _mintedClaim[msg.sender]+=tokens;

    }

    function howManyMintedClaim(address account) public view returns (uint256) {
        return _mintedClaim[account];
    }

    /// Owner only mint function
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(tokens > 0, "Must at least one token");
        _safeMint(to, tokens);
    }

    /// Withdraw function
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}