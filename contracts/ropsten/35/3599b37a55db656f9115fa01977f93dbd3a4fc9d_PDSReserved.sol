// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract PDSReserved is ERC721, ERC721Enumerable, Ownable {

bool public saleIsActive = false;
string private _baseURIextended;

address  PDSWallet = 0x4C53E1DF995Aefec0d3723fCaFE9edffD4CC5Bcf; 
address  HatchlingzWallet = 0x44D4C4C2197F69aA276c74037f2ce6ebBC5e489E;

uint PDSPay = 70; //will be divided by 100 and leave some room for infinite division
uint HatchlingzPay = 295; //will be divided by 1000


uint256 public constant MAX_SUPPLY = 1000;


uint256 public constant PRICE_FOR_ONE = 0.06 ether;
uint256 public constant PRICE_FOR_THREE = 0.1425 ether;
uint256 public constant PRICE_FOR_FIVE = 0.175 ether;


mapping(address => bool) public approvedBurnAddresses;

constructor() ERC721("PDS Reserved", "PDSR") { }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function reserve(uint256 n) public onlyOwner {
    uint supply = totalSupply();
    uint i;
    for (i = 0; i < n; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function setSaleState(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function mintOne() public payable {
    uint256 ts = totalSupply();
    require(saleIsActive, "Sale must be active to mint tokens");
    require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_FOR_ONE <= msg.value, "Ether value sent is not correct");

    _safeMint(msg.sender, ts);
  }

  function mintThree() public payable {
    uint256 ts = totalSupply();
    require(saleIsActive, "Sale must be active to mint tokens");
    require(ts + 3 <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_FOR_THREE <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < 3; ++i) {
      _safeMint(msg.sender, ts + i);
    }
  }

  function mintFive() public payable {
    uint256 ts = totalSupply();
    require(saleIsActive, "Sale must be active to mint tokens");
    require(ts + 5 <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(PRICE_FOR_FIVE <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < 5; ++i) {
      _safeMint(msg.sender, ts + i);
    }
  }

  function burn(address from, uint256 tokenId) public {
    require(approvedBurnAddresses[msg.sender], "Not approved to burn");
    require( from == ownerOf(tokenId), "You need to be the owner of the token to burn it");

    _burn( tokenId);

  }

  function isAddressApprovedToBurn (address check) external view returns (bool){
    return approvedBurnAddresses[check];
  }

  function setApprovedBurnAddresses (address burnApprovedAddress, bool newState) public onlyOwner {
    approvedBurnAddresses[burnApprovedAddress] = newState;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    uint PDSPayout = balance*PDSPay/100;
    uint hatchlingzPayout = balance*HatchlingzPay/1000;
    payable(PDSWallet).transfer(PDSPayout);
    payable(HatchlingzWallet).transfer(hatchlingzPayout);
    }
}