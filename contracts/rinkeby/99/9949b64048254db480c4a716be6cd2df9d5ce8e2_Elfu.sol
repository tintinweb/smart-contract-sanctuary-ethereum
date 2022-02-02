// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract MintingPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
}

contract Elfu is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    MintingPass mintpass;

    uint256 private tokenId;

    bool public presaleActive = true;

    string internal baseURI;

    uint256 public presalePrice = 0.07 ether;
    uint256 public publicSalePrice = 0.08 ether;

    uint public maxSupply = 10000;
    uint public maxPerTransaction = 20;
        
    event ElfMinted(address owner, uint256 quantity);
    event Withdraw(uint256 amount);

    constructor(address _address) ERC721("ELF Princess", "ELF") {
        mintpass = MintingPass(_address);
    }

    function setPrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }
    
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setMaxPerTransaction(uint value) external onlyOwner {
        maxPerTransaction = value;
    }

    function closePresale() external onlyOwner {
        presaleActive = false;
    }

    function getMaxPerTransaction(uint _id) public view returns (uint256) {
       if(presaleActive)
       {
           if(_id==1)
            {
                return 100;
            }else if(_id==2)
            {
                return 25;
            }else{
                return 10;
            }
       }else{
           return maxPerTransaction;
       }
    }

    function mint(uint256 quantity,uint256 passId) external payable {
        require(quantity>0 && quantity <= getMaxPerTransaction(passId) , "Quantity greater than max mint allowed");
        require(tokenId.add(quantity) <= maxSupply, "Max supply exceeds");
        address minter=msg.sender;
      
        if(presaleActive)
        {
          require(mintpass.balanceOf(minter, passId) > 0,"Missing mint pass");
          if(passId==1)
          {
            require(balanceOf(minter) <= 100,"You have already minted 100 nfts");
          }else if(passId==2)
          {
            require(balanceOf(minter) <= 25,"You have already minted 25 nfts");
          }else{
            require(balanceOf(minter) <= 10,"You have already minted 10 nfts");
          }
          require(msg.value == presalePrice.mul(quantity), "Invalid value");
        }else
        {
            require(msg.value == publicSalePrice.mul(quantity), "Invalid value");
        }
        for(uint256 i = 0; i < quantity; i++){
            safeMint(minter);
        }
        emit ElfMinted(minter, quantity);
    }

    function withdraw() public onlyOwner
    {
        uint256 amount=address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Withdraw(amount);
    }

    function safeMint(address to) internal {
        tokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId), '.json'));
    }
}