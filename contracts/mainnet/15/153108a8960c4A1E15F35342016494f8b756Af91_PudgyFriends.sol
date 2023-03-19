// SPDX-License-Identifier: GPL-3.0

/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    Genfty.com will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract PudgyFriends is ERC721Enumerable, Ownable{
  using Strings for uint256;


  string public baseURI;
  string public baseExtension = "";
  uint256 public cost = 0.04 ether;
  uint256 public publicCost = 0.05 ether ;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmountPublic = 10;
  uint256 public maxMintAmountWhitelist = 5;
  mapping(address => bool) public whitelisted;
  uint256 public  createTime ;
  uint256 public timetoGoMint =  67 hours + 55 minutes ;
  uint256 public timeToGoPublicMint = 6 hours ;
  bool publicmint = false ;

  

  
  constructor() ERC721("Pudgy Friends", "PUDGYFRIENDS") {
    setBaseURI("https://cdn.pudgyfriends.io/wp-content/nft-metadata/pre-reveal/json/");
    createTime = block.timestamp;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function time () public view returns(uint256){
    return block.timestamp ;
  }
  


  function getpublicmint () public view returns (bool) {
    return publicmint ;
  }
  

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require( owner() == msg.sender || block.timestamp >= createTime + timetoGoMint , "for mint you must wait");
    require(supply + _mintAmount <= maxSupply);
    if (whitelisted[msg.sender]) {
     require(balanceOf(msg.sender) <= maxMintAmountWhitelist , "you can't mint because now have 10 nft "  ); 
    }else {
     require(balanceOf(msg.sender) <= maxMintAmountPublic , "you can't mint because now have 5 nft "  ); 
    }

    if (block.timestamp >= timetoGoMint + timeToGoPublicMint) {
        if (publicmint == false) {
          publicmint = true ;
        }
        // going to public mint 
        
        if (msg.sender != owner()){
           require(_mintAmount <= maxMintAmountPublic);
           require(msg.value >= publicCost * _mintAmount , "value is lower of cost");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(_to, supply + i);
        }

    }else {
      // going to whitelist mint only 
       if (msg.sender != owner()) {
        if(whitelisted[msg.sender] == true) {
          require(_mintAmount <= maxMintAmountWhitelist);
          require(msg.value >= cost * _mintAmount , "value is lower of cost");
        }else {
          revert("mint only for whitlisted ");
        }
    }
    
        for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(_to, supply + i);
        }
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

    string memory currentBaseURI = _baseURI();
    uint256 newTokenId = tokenId -= 1 ;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, newTokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmountPublic = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }


 
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function addWhiteListArray ( address [] memory _array) public onlyOwner {
    for (uint i = 0 ; i < _array.length ; i++) 
    {
      whitelisted[_array[i]] = true ;
    }
  }

}