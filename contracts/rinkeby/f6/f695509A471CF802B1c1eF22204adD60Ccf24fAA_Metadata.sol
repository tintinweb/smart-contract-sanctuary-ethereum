/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

pragma solidity ^0.7.6;

// a2646970667358221220
// 8506c51294c7f246c2cf43937a15c891
// b14f8a2e4d2da6f21e4ddf16283b2e6964736f6c6343
// 0007060033

// a2
// 64 69706673 5822 12208506c51294c7f246c2cf43937a15c891b14f8a2e4d2da6f21e4ddf16283b2e69
// 64 736f6c63 43 000706 
// 0033
contract Metadata {
  function example() external pure returns (bytes memory) {
    bytes8 x = 0xa264697066735822;
    bytes2 xx = 0x00;
    bytes32 y = 0x0000000000000000000000123456789000000000000000000000001234567890;
    bytes9 z = 0x64736f6c6343000706;

    return abi.encodePacked(x, xx, y, z);
  } 
}