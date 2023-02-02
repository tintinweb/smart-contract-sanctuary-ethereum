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

    uint256 public MAX_MINTS = 3;

    uint256 public PRICE = 0 ether;

    uint256 public TOTAL_SUPPLY = 4200;

    bool public SaleStarted = false;

    bool public revealed = false;


    mapping(address => uint256) private _mintedClaim;


    string public notRevealedUri = "ipfs://QmZVnUP2XktTg3pM2SPJ7eMfjwkgZwfB5PDqcdax28Jcp1/hidden.json";

    // /baseURI will be changed before reveal
    string public baseURI = "revealeduri";



    constructor() ERC721A("DickPigz", "DICKPIG") {
    }

    function toggleSale() external onlyOwner {
        SaleStarted = !SaleStarted;

    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        revealed = true;
    }

    function setnotRevealedUri(string memory _newnotRevealedURI) external onlyOwner {
        notRevealedUri = _newnotRevealedURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice * (1 ether);
    }


    function setmaxMints(uint256 _newmaxMints) external onlyOwner {
        MAX_MINTS = _newmaxMints;
    }

    function settotalSupply(uint256 _newTotalSupply) public onlyOwner {
	    TOTAL_SUPPLY = _newTotalSupply;
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
        require(SaleStarted, "Public sale has not started");
        require(totalSupply() + tokens <= (TOTAL_SUPPLY), "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(PRICE * tokens <= msg.value, "ETH amount is incorrect");
        require(tokens <= MAX_MINTS, "Too Many Mints");
        _safeMint(_msgSender(), tokens);
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