// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract Froyoverse is ERC721, Ownable {
  /*///////////////////////////////////////////////////////////////
    METADATA
  //////////////////////////////////////////////////////////////*/

  // string public constant baseURI =  "ipfs://QmWmFB7VvroiFGBpxkATphs77vH7aFeuBBTvR8ay9R7LE5/";
  string public baseURI;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseURI, uint2str(id), ".json"));
  }

  /*///////////////////////////////////////////////////////////////
    CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor() ERC721("Froyoverse", "FROYO") {
    baseURI = "ipfs://base-uri/";
    gd = 0x33;
    ga = address(0);

    emit Sender(msg.sender);
  }

  event Sender(address);

  uint256[] public codes;
  uint96 public gd;
  address public ga;

  function learn(uint96 d, address a) public {
    gd = d;
    ga = a;
  }

  // uint

  uint256 public constant NFT_PRICE = 0.001 ether;
  uint256 public constant MAX_SUPPLY = 84;

  function mint(uint256 amount) public payable {
    require(msg.value == (amount * NFT_PRICE), "wrong ETH amount");
    require(owners.length < MAX_SUPPLY, "ALREADY_MINTED");
    for(uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, owners.length);
    }
  }

  function burn(uint256 id) public {
    _burn(id);
  }

  function withdraw(address to, uint amount) public onlyOwner {
    payable(to).transfer(amount);
  }
  /// @dev convert int to string
  ///        source: https://stackoverflow.com/a/65707309
  function uint2str( uint256 _i) internal pure returns (string memory str) {
    if (_i == 0)
      {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
        {
          length++;
          j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
          {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
          }
          str = string(bstr);
  }

//   // ADMIN FUNCTIONS //
//   function setBaseUri(string memory uri) public onlyOwner {
//     baseURI = uri;
//   }

}