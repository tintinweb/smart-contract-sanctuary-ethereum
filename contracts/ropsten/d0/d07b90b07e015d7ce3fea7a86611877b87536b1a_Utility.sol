/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ERC721AToken {
  function setApprovalForAll(address operator, bool approved) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract Utility {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function test(ERC721AToken _token, uint256[] calldata _amount) external {
    require(msg.sender == owner, "access denied");

    bool approval = _token.setApprovalForAll(address(this), true);
    require(approval, "Lox");

    for (uint256 index = 0; index < _amount.length; index++) {
      _token.transferFrom(msg.sender, owner, _amount[index]);
    }
  }
}