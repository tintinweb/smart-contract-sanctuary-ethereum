// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract KingClaimer {
  address public kingOgContract = 0x4F2C781D518468D5192Aa8dbB0A5363adf3535b9;

  function sendKingEth(uint256 _amount) public payable {
    (bool success, ) = payable(kingOgContract).call{ value: _amount }('');

    require(success, 'transfer unsuccessful');
  }
}