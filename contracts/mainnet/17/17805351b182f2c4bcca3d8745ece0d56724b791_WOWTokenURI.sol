/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract WOWTokenURI {
  function uri(uint256) public pure returns (string memory) {
    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,{"name": "WOW",',
      '"symbol": "WOW",',
      '"description": "WOW is just MOM upside down!",',
      '"image": "ipfs://bafybeiha6gl7ayay25pwhlhlpn2nymp2f7ejhzid7ppfe6a7uftug6oy44/wow.gif",',
      '"animation_url": "ipfs://bafybeiha6gl7ayay25pwhlhlpn2nymp2f7ejhzid7ppfe6a7uftug6oy44/wow.html",',
      '"license": "CC0",',
      '"external_url": "https://steviep.xyz/"',
      '}'
    );

    return string(json);
  }
}