// SPDX-License-Identifier: MIT
/*

 ____  _  _  ____    ____  _  _  ____  __ _  ____ 
(_  _)/ )( \(  __)  (_  _)/ )( \(  _ \(  / )/ ___)
  )(  ) __ ( ) _)     )(  ) \/ ( )   / )  ( \___ \
 (__) \_)(_/(____)   (__) \____/(__\_)(__\_)(____/

*/                                    
                             

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TheTurks is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS = 5;
    uint256 public value = 0.002 ether;
    uint256 public MAX_SUPPLY = 10000;

    bool public publicSaleStarted = false;
    bool public revealed = false;


    string public notRevealedUri = "ipfs://QmeviG7dYLREseXzcS9B3sU9YkWprbqvZsGED7xc6oumXc/hidden.json";

    // /baseURI will be changed before reveal
    string public baseURI = "";



    constructor() ERC721A("The Turks NFT", "TURKO") {
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

    function setValue(uint256 _newValue) external onlyOwner {
        value = _newValue * (1 ether);
    }

    function setmaxMints(uint256 _newmaxMints) external onlyOwner {
        MAX_MINTS = _newmaxMints;
    }


    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    MAX_SUPPLY = _newMaxSupply;
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
        require(tokens <= MAX_MINTS, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= (MAX_SUPPLY), "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(value * tokens <= msg.value, "ETH amount is incorrect");
        _safeMint(_msgSender(), tokens);
    }


    /// Owner only mint function
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
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