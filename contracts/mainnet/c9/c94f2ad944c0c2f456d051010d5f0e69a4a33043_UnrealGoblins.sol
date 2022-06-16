// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////                    /////////////                    ////////                         //////////////
///////////                          ///////                          /////                            ///////////
//////////          ////////          /////          ////////          ////        ///////////          //////////
/////////         ////////////         ///         ////////////         ///        /////////////         /////////
/////////        //////////////////////////         ///////////////////////        //////////////        /////////
/////////        ///////////////////////////                 //////////////        //////////////        /////////
/////////        ///////               ////////                    ////////        //////////////        /////////
/////////        ///////               ///////////////                /////        //////////////        /////////
/////////        //////////////        ///////////////////////         ////        //////////////        /////////
/////////         ////////////         ///         ////////////         ///        /////////////         /////////
//////////          ////////          /////          ////////          ////        ///////////          //////////
///////////                          ///////                          /////                            ///////////
//////////////                    /////////////                    ////////                         //////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract UnrealGoblins is ERC721A, Ownable {
  string _baseTokenURI;
  
  bool public isActive = false;
  uint256 public mintPrice = 0 ether;
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public MAX_PER_WALLET = 3;
  uint256 public MAX_PER_TX = 3;
  uint256 public  constant TEAM_RESERVE = 721;

  constructor(string memory baseURI) ERC721A("Unreal Goblins", "UG") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }


  function toggleSale() public onlyAuthorized {
    isActive = !isActive;
  }

  function TeamAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i], _count);
    }
  }


  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function freeMint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
    }

    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= MAX_PER_TX, "Exceeds maximum allowed tokens");
    require(balanceOf(msg.sender) + _count <= MAX_PER_WALLET, "Exceeds maximum allowed tokens per wallet");

    _safeMint(msg.sender, _count);

  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}