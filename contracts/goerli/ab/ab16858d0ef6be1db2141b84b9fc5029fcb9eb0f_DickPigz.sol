// SPDX-License-Identifier: MIT
/*


████████▄   ▄█   ▄████████    ▄█   ▄█▄    ▄███████▄  ▄█     ▄██████▄   ▄███████▄  
███   ▀███ ███  ███    ███   ███ ▄███▀   ███    ███ ███    ███    ███ ██▀     ▄██ 
███    ███ ███▌ ███    █▀    ███▐██▀     ███    ███ ███▌   ███    █▀        ▄███▀ 
███    ███ ███▌ ███         ▄█████▀      ███    ███ ███▌  ▄███         ▀█▀▄███▀▄▄ 
███    ███ ███▌ ███        ▀▀█████▄    ▀█████████▀  ███▌ ▀▀███ ████▄    ▄███▀   ▀ 
███    ███ ███  ███    █▄    ███▐██▄     ███        ███    ███    ███ ▄███▀       
███   ▄███ ███  ███    ███   ███ ▀███▄   ███        ███    ███    ███ ███▄     ▄█ 
████████▀  █▀   ████████▀    ███   ▀█▀  ▄████▀      █▀     ████████▀   ▀████████▀ 
                             ▀                                                    
                                           

*/                                    
                             

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract DickPigz is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_WL_MINTS = 3;

    uint256 public WL_PRICE = 0 ether;
    uint256 public PAID_PRICE = 0.0042 ether;

    uint256 public TOTAL_SUPPLY = 4444;
    uint256 public WL_SUPPLY = 3333;

    uint256 private WL_MINTED = 0;


    bool public publicSaleStarted = false;
    bool public wlSaleStarted = false;

    bool public revealed = false;


    mapping(address => uint256) private _mintedClaim;
    mapping(address => uint256) private _mintedMint;


    bytes32 public root;

    string public notRevealedUri = "notrevealeduri";

    // /baseURI will be changed before reveal
    string public baseURI = "revealeduri";



    constructor() ERC721A("DickPigz", "DPIG") {
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



    function setmaxwlMints(uint256 _newmaxwlMints) external onlyOwner {
        MAX_WL_MINTS = _newmaxwlMints;
    }

    function settotalSupply(uint256 _newTotalSupply) public onlyOwner {
	    TOTAL_SUPPLY = _newTotalSupply;
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
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + tokens <= (TOTAL_SUPPLY), "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(PAID_PRICE * tokens <= msg.value, "ETH amount is incorrect");
        _safeMint(_msgSender(), tokens);
        _mintedMint[msg.sender]+=tokens;

    }

    /// Wl Mint Functions 

    
    

    function freeMint(uint256 tokens)
        external
        payable
    {
        if (howManyMintedClaim(msg.sender) + tokens >= MAX_WL_MINTS) revert("Amount exceeds claim limit");
        if (!wlSaleStarted) revert("Sale not started");
        if (WL_MINTED + tokens > (WL_SUPPLY))
            revert("Amount exceeds supply");
        if (WL_PRICE * tokens > msg.value)
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