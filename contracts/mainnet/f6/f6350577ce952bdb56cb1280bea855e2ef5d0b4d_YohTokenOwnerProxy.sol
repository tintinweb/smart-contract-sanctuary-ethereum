// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract YohTokenOwnerProxy {
  address yoh = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;

  constructor() public {
    yoh = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;
  }

  function balanceOf(address owner) external view returns (uint256 balance){
    uint256[] memory tokens = IYohToken(yoh).getTokensStaked(owner);
    balance = tokens.length;
  }

}


interface IYohToken {
  function getTokensStaked(address _sender) external view returns (uint256[] memory);
}