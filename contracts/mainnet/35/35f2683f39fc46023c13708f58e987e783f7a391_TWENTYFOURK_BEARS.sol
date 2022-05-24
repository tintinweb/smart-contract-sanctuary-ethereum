// SPDX-License-Identifier: MIT
/*

________    _____  __     __________                            
\_____  \  /  |  ||  | __ \______   \ ____ _____ _______  ______
 /  ____/ /   |  ||  |/ /  |    |  _// __ \\__  \\_  __ \/  ___/
/       \/    ^   /    <   |    |   \  ___/ / __ \|  | \/\___ \ 
\_______ \____   ||__|_ \  |______  /\___  >____  /__|  /____  >
        \/    |__|     \/         \/     \/     \/           \/ 


*/                                    
                             
// 24K Bears - ERC721A contract

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TWENTYFOURK_BEARS is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS_PER_TX = 50;
    uint256 public price = 0.005 ether;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public FREE_SUPPLY = 3000;
    uint256 public FREE_MINTED = 0;

    mapping(address => bool) private _mintedClaim;

    bool public publicSaleStarted = false;
    bool public revealed = false;


    string public notRevealedUri = "ipfs://QmRGVuQyswUaAa2k4MgJRokSeWgXSYdKVXAdWwrNcMu9UV/hidden.json";
    string public baseURI = "ipfs://willbereplaced/";


    address private constant _deployer = 0x3d8bE5Df40fB5Fc056427e801850DF36Bd819bDb;

    constructor() ERC721A("24K Bears", "24K") {
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
    function freemint() external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + 1 <= (FREE_SUPPLY), "Minting would exceed max supply");
        if (hasMintedClaim(msg.sender)) revert("Amount exceeds claim limit");

        _mintedClaim[msg.sender] = true;
        _safeMint(_msgSender(), 1);
        FREE_MINTED++;
    }


    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }

    


    /// Owner only mint function
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Withdraw function
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(_deployer, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}