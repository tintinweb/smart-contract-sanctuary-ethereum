// SPDX-License-Identifier: MIT
/*


  ________ ________  .____     ________  ___________ _______    _____________________   _____ __________  _________
 /  _____/ \_____  \ |    |    \______ \ \_   _____/ \      \   \______   \_   _____/  /  _  \\______   \/   _____/
/   \  ___  /   |   \|    |     |    |  \ |    __)_  /   |   \   |    |  _/|    __)_  /  /_\  \|       _/\_____  \ 
\    \_\  \/    |    \    |___  |    `   \|        \/    |    \  |    |   \|        \/    |    \    |   \/        \
 \______  /\_______  /_______ \/_______  /_______  /\____|__  /  |______  /_______  /\____|__  /____|_  /_______  /
        \/         \/        \/        \/        \/         \/          \/        \/         \/       \/        \/ 

*/                                    
                             
// Golden Bears - ERC721A contract

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract GoldenBears is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_MINTS_PER_TX = 50;
    uint256 public price = 0.01 ether;

    uint256 public MAX_SUPPLY = 1000;

    bool public publicSaleStarted = false;
    bool public revealed = false;


    string public notRevealedUri = "ipfs://QmYaRBvmFef3nCwtDA4jLYvTDx5s5D5Phm2vVHAGkE8Kkz/hidden.json";

    // /baseURI will be changed before reveal
    string public baseURI = "ipfs://willbereplaced/";


    /// Wallet address of the deployer
    address private constant _deployer = 0x24BCfeB1337a84393687919a11e0290B4bd47E46;

    constructor() ERC721A("Golden  Bears", "GB") {
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