// SPDX-License-Identifier: MIT
/*


   __        __          _______________
  / /  ___ _/ /  __ __  / __/_  __/ ___/
 / _ \/ _ `/ _ \/ // / / _/  / / / /__  
/_.__/\_,_/_.__/\_, / /_/   /_/  \___/  
               /___/                    


*/                                    
                             

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract babyftc is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS_PER_TX = 10;
    uint256 public price = 0.003 ether;
    uint256 public freealllowance = 10;

    uint256 public MAX_SUPPLY = 3000;
    uint256 public FREE_SUPPLY = 2000;

    uint256 public FREE_MINTED = 0;

    mapping (address => uint) addressToMintCount;

    bool public publicSaleStarted = false;
    bool public revealed = false;


    string public notRevealedUri = "https://babyftc.mypinata.cloud/ipfs/QmQsnuXSHoBvHyRs2zAcqZiAuNZFyU4pD6r66wD11YvmDU/hidden.json";

    // /baseURI will be changed before reveal
    string public baseURI = "";



    constructor() ERC721A("Baby FTC", "BFTC") {
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        revealed = true;
    }

    function setnotRevealedUri(string memory _newnotRevealedURI) external onlyOwner {
        notRevealedUri = _newnotRevealedURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setAllowance(uint256 _newallowance) external onlyOwner {
        freealllowance = _newallowance;
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    MAX_SUPPLY = _newMaxSupply;
	}

    function setfreeSupply(uint256 _newfreeSupply) public onlyOwner {
	    FREE_SUPPLY = _newfreeSupply;
	}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
        require(tokens <= MAX_MINTS_PER_TX, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= (MAX_SUPPLY), "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens <= msg.value, "ETH amount is incorrect");
        _safeMint(_msgSender(), tokens);
    }


    /// Free Mint Functions
    function freemint(uint256 amountfree) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(FREE_MINTED + amountfree <= (FREE_SUPPLY), "Minting would exceed free supply");
        require(addressToMintCount[msg.sender] + amountfree <= freealllowance, "Exceeds allowance");
        _safeMint(_msgSender(), amountfree);
        addressToMintCount[msg.sender] += amountfree;
        FREE_MINTED += amountfree;
    }

    function howManyFreeMinted(address account) public view returns (uint256) {
        return addressToMintCount[account];
    }

    /// Owner only mint function
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        FREE_MINTED += tokens;
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