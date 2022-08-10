// SPDX-License-Identifier: MIT
//    ______ __          _            __                __
//   / ___(_) /____ ____(_)_ ____ _  / /  ___  ___  ___/ /
//  / /__/ / __/ -_) __/ / // /  ' \/ /__/ _ `/ _ \/ _  / 
//  \___/_/\__/\__/_/ /_/\_,_/_/_/_/____/\_,_/_//_/\_,_/
//
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract CiteriumLand is ERC721A {
    constructor() ERC721A("CiteriumLand", "CL") {}

    string private baseURI = "https://citerium.art/metadata/"; 
    mapping(address => bool) public hasMinted;
    bool private _swFreeMint = false;
    mapping(address => uint8) private _allowList;
    uint256 public freemint = 0;
    uint256 public freewl = 0;

    function _baseURI() internal view override returns (string memory) {
          return baseURI;
      }

    function setBaseURI(string memory URI) external {
          require(0x0227D61B9633fe4dDf4b9c3Ed9236dD4Ab2cdF2b == msg.sender, "OnlyOwner");
          baseURI = URI;
      }

    function setActivate(uint256 _value) public {
        require(0x0227D61B9633fe4dDf4b9c3Ed9236dD4Ab2cdF2b == msg.sender, "OnlyOwner");
        _swFreeMint = _value==1;
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

    function whitelistMint() external payable {
        require(freewl <= 1000);
        require(_swFreeMint);
        require(1 <= _allowList[msg.sender], "Exceeded max available to purchase"); 
        freewl += 1;
        _allowList[msg.sender] -= 1;
        _mint(msg.sender, 1);
    }

    function setAllowList(address[] calldata addresses) public{
        require(0x0227D61B9633fe4dDf4b9c3Ed9236dD4Ab2cdF2b == msg.sender, "OnlyOwner");
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 1;
         }
        }

}