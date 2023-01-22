/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT
// compiled with 0.8.17
pragma solidity >=0.4.22 <0.9.0;

contract tmpFactory {
  // Factory
  function allPairs(uint) public view returns (address pair) {}
  function allPairsLength() public view returns (uint) {}
}
contract tmpPair {
  // Pair
  function getReserves() public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {}
  function token0() public view returns (address) {}
  function token1() public view returns (address) {}
}


contract middleMan {
  // Pour une add de FactoryV2 donnée :
  // - get_list_pair(address) -> address[] list_pair
  // - get_list_token(address) -> (address[] list_pair, address[] list_token0, address[] list_token1)
  // - get_list_reserve(address) -> (uint[] list_reserve0, uint[] list_reserve1)

  function get_list_pair(address add) public view returns (address[] memory) {
    uint n = tmpFactory(add).allPairsLength();
    address[] memory list_pair = new address[](n);

    for (uint i=0; i<n; i++) {
      list_pair[i] = tmpFactory(add).allPairs(i);
    }
    return list_pair;
  }

  function get_list_token(address add) external view returns (address[] memory, address[] memory, address[] memory) {
    uint n = tmpFactory(add).allPairsLength();
    address[] memory list_pair = get_list_pair(add);
    address[] memory list_token0 = new address[](n);
    address[] memory list_token1 = new address[](n);

    for (uint i=0; i<n; i++) {
      list_token0[i] = tmpPair(list_pair[i]).token0();
      list_token1[i] = tmpPair(list_pair[i]).token1();
    }
    return (list_pair, list_token0, list_token1);
  }

  function get_list_reserve(address add) external view returns (uint[] memory, uint[] memory) {
    uint n = tmpFactory(add).allPairsLength();
    address[] memory list_pair = get_list_pair(add);
    uint[] memory list_reserve0 = new uint[](n);
    uint[] memory list_reserve1 = new uint[](n);

    uint112 r0;
    uint112 r1;
    uint32 bTLast;
    for (uint i=0; i<n; i++) {
      (r0, r1, bTLast) = tmpPair(list_pair[i]).getReserves();
      list_reserve0[i] = r0;
      list_reserve1[i] = r1;
    }
    return (list_reserve0, list_reserve1);
  }
}