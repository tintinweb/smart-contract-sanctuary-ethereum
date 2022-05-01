/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity ^0.8.13;
// pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BalanceChecker {

  struct tokeninfo {
    address token_address;
    uint256 balance;
    address approve_address;
    uint256 approve_amount;
  }

  struct addressinfo {
    address owner_address;
    uint256 eth_balance;
    tokeninfo[] tokens;
  }
  function tokenBalance(address user, address tokenAddress,address appove_address) public view returns (tokeninfo memory) {
    IERC20 token = IERC20(tokenAddress);
    tokeninfo memory _tokeninfo = tokeninfo(tokenAddress,token.balanceOf(user),appove_address,token.allowance(user,appove_address));
    return _tokeninfo;
  }


  
  function balances(address user, address[] memory tokens,address[] memory appove_address_items) external view returns (addressinfo memory) {
    
        tokeninfo[] memory tokeninfos = new tokeninfo[](tokens.length);
        for (uint j = 0; j < tokens.length; j++) {
            tokeninfos[j] = tokenBalance(user, tokens[j],appove_address_items[j]);
        }
        addressinfo memory addressinfo = addressinfo(user,user.balance, tokeninfos);
  
        return addressinfo;
  }

}