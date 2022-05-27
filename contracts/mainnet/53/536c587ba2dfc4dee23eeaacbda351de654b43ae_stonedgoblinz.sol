// SPDX-License-Identifier: MIT
/*


                        hh      hh      hh      hh      hh      hh      hh      hh      hh      hh      
  aa aa uu   uu  gggggg hh      hh      hh      hh      hh      hh      hh      hh      hh      hh      
 aa aaa uu   uu gg   gg hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  hhhhhh  
aa  aaa uu   uu ggggggg hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh 
 aaa aa  uuuu u      gg hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh hh   hh 
                 ggggg                                                                                  


*/                                    
                             
// stonedgoblintown.wtf - ERC721A contract

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract stonedgoblinz is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS_PER_TX = 50;
    uint256 public price = 0.0042069 ether;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public FREE_SUPPLY = 4200;
    uint256 public FREE_MINTED = 0;

    mapping (address => uint) addressToMintCount;

    bool public publicSaleStarted = false;
    bool public revealed = false;


    string public notRevealedUri = "ipfs://QmRGVuQyswUaAa2k4MgJRokSeWgXSYdKVXAdWwrNcMu9UV/hidden.json";

    // /baseURI will be changed before reveal
    string public baseURI = "ipfs://willbereplaced/";


    /// Wallet address of the deployer
    address private constant _deployer = 0xA5d27E28c29836F6881Ae27439d958011A062C28;

    constructor() ERC721A("stonedgoblinz.wtf", "swtf") {
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

    function freemint(uint256 amountfree) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + 1 <= (FREE_SUPPLY), "Minting would exceed max supply");
        require(addressToMintCount[msg.sender] + amountfree <= 2, "Exceeds allowance");

        _safeMint(_msgSender(), amountfree);
        addressToMintCount[msg.sender] += amountfree;
        FREE_MINTED++;

    }


    
    function hasMintedClaim(address account) public view returns (bool) {
        if (addressToMintCount[account]==2){
            return true;
        }
        else {
            return false;
        }
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