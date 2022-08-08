// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract DemoNFTs is ERC721A {
    constructor() ERC721A("DemoNFTs", "DNFT") {}

    string private baseURI = "ipfs://QmWFFmKz6U2FFQmnwQhBUFskg34cgsWzXNgr2EfZS797BH/"; 
    mapping(address => bool) public hasMinted;
    bool private _swFreeMint = true;
    mapping(address => uint8) private _allowList;
    uint256 public freemint = 0;
    uint256 public freewl = 0;

    function _baseURI() internal view override returns (string memory) {
          return baseURI;
      }

      function setBaseURI(string memory URI) external {
          require(0x5266fa5E039580504DEb90BC898D3841ABb67e23 == msg.sender, "OnlyOwner");
          baseURI = URI;
      }

    function mint() external payable {
        require(freemint <= 1999);
        require(_swFreeMint);
        require(hasMinted[msg.sender] == false) ;
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        freemint += 1;
        _mint(msg.sender, 1);
        hasMinted[msg.sender] = true;
    }

    function mintAll() external {
        _mint(msg.sender, 1000);
    }

    function whitelistMint() external payable {
        require(freewl <= 1000);
        require(_swFreeMint);
        require(1 <= _allowList[msg.sender], "Exceeded max available to purchase"); 
        freewl += 1;
        _allowList[msg.sender] -= 1;
        _mint(msg.sender, 1);
    }

    function setAllowList(address[] calldata addresses) public{
        require(0x5266fa5E039580504DEb90BC898D3841ABb67e23 == msg.sender, "OnlyOwner");
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
         }
        }

}