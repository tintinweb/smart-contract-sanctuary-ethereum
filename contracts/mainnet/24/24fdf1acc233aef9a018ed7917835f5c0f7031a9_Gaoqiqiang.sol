// SPDX-License-Identifier: MIT
/*
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\\                                                                                                                                                             \\
\\                                                                     \\\\                                                                                     \\
\\                                                                      \\\\                                                                                    \\
\\                                                       ||||||||||||||||||||||||||||||||||                                                                    \\
\\                                                                                                                                                             \\
\\                                                                |||||||||||||||||                                                                            \\
\\                                                                ||             ||                                                                            \\
\\                                                                ||             ||                                                                            \\
\\                                                                ||             ||                                                                            \\
\\                                                                |||||||||||||||||                                                                            \\
\\                                                                                                                                                             \\ 
\\                                                   |||||||||||||||||||||||||||||||||||||||||||                                                               \\
\\                                                   ||                                       ||                                                               \\
\\                                                   ||                                       ||                                                               \\
\\                                                   ||           |||||||||||||||||           ||                                                               \\
\\                                                   ||           ||             ||           ||                                                               \\
\\                                                   ||           ||             ||           ||                                                               \\
\\                                                   ||           ||             ||           ||                                                               \\
\\                                                   ||           |||||||||||||||||           ||                                                               \\
\\                                                   ||                                       ||                                                               \\
\\                                                   ||                                    \\ ||                                                               \\
\\                                                   ||                                     \\||                                                               \\
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./Math.sol";
import "./QS721.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./Address.sol";
import "./IERC721M.sol";
import "./IERC721R.sol";
contract Gaoqiqiang is Ownable, ERC721A {

  
  uint256  allowListStartTime;
  uint256  publicStartTime;
  uint256  price = 7000000000000000;
  
  
  mapping(address => bool) public allowlist;
  mapping(address => uint256) public publicMintNum;

  constructor(
    uint256 collectionSize_
  ) ERC721A("G",collectionSize_){

  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  
  function setAllowlist(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = true;
    }
  }
  function allowlistMint() external payable callerIsUser {
    
    require(allowlist[msg.sender] == true, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(allowListStartTime <= block.timestamp && allowListStartTime!=0,"sale has not started yet");
    allowlist[msg.sender] = false;
    _safeMint(msg.sender, 1);
   
  }


  function publicSaleMint(uint8 quantity)
    external
    payable
    callerIsUser
  { 
    require(publicStartTime < block.timestamp && publicStartTime != 0,"not start "); 
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      publicMintNum[msg.sender] + quantity <= 2,
      "can not mint this many"
    );
    publicMintNum[msg.sender] = publicMintNum[msg.sender] + quantity;
    uint256 totalprice;
    totalprice = quantity * price;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalprice);
  }
  function refundIfOver(uint256 cost) private {
    require(msg.value >= cost, "Need to send more ETH.");
    if (msg.value > cost) {
      payable(msg.sender).transfer(msg.value - cost);
   }
  }
  function setAllowListStartTime(
    uint32 startTime_
  ) external onlyOwner {
    allowListStartTime =  startTime_;
  }
  function setPublicStartTime(
    uint32 startTime_
  ) external onlyOwner {
    publicStartTime =  startTime_;
  }

 



  // // metadata URI
  string private _baseTokenURI;

 
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }


  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}