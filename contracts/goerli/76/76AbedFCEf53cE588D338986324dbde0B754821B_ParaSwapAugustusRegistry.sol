/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

pragma solidity ^0.8.10;

interface IParaSwapAugustusRegistry {
  function isValidAugustus(address augustus) external view returns (bool);
}
// File: contracts/MockParaSwap.sol/MockParaSwapAugustusRegistry.sol


pragma solidity ^0.8.10;


contract ParaSwapAugustusRegistry is IParaSwapAugustusRegistry {
  address immutable AUGUSTUS;

  constructor(address augustus) {
    AUGUSTUS = augustus;
  }

  function isValidAugustus(address augustus) external view override returns (bool) {
    return augustus == AUGUSTUS;
  }
}