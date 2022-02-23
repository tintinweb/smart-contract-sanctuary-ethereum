/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.4.26;

interface Token {
  function balanceOf(address who) external view returns (uint256);
}

contract AddressBalance {
  function() external payable {
    revert("AddressBalance does not accept payments");
  }

  function balances(address[] users, address[] tokens) external view returns (uint256[] memory) {
    uint256[] memory addrBalances = new uint256[](tokens.length * users.length);
    
    for(uint i = 0; i < users.length; i++) {
      for (uint j = 0; j < tokens.length; j++) {
        uint addrIdx = j + tokens.length * i;
        if (tokens[j] != address(0x0)) {
          Token erc20 = Token(tokens[j]);
          addrBalances[addrIdx] = erc20.balanceOf(users[i]);
        } else {
          addrBalances[addrIdx] = users[i].balance;
        }
      }  
    }
  
    return addrBalances;
  }
}