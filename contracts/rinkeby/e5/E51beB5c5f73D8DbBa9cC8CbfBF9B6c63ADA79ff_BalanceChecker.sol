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
  }

  struct addressinfo {
    address owner_address;
    uint256 eth_balance;
    tokeninfo[] tokens;
  }

//   function() public payable {
//     revert("BalanceChecker does not accept payments");
//   }

  function tokenBalance(address user, address tokenAddress) public view returns (uint) {
    // check if token is actually a contract
    IERC20 token = IERC20(tokenAddress);
    return token.balanceOf(user);

    // uint256 tokenCode;
    // assembly { tokenCode := extcodesize(token) } // contract code size
  
    // // is it a contract and does it implement balanceOf 
    // if (tokenCode > 0 && token.call(bytes4(0x70a08231), user)) {  
    //   return Token(token).balanceOf(user);
    // } else {
    //   return 0;
    // }
  }

  
  function balances(address user, address[] memory tokens) external view returns (addressinfo memory) {
    
    // for(uint i = 0; i < users.length; i++) {
       //addressinfo[] memory addressinfos = new addressinfo[](users.length);
       tokeninfo[] memory tokeninfos = new tokeninfo[](tokens.length);
      for (uint j = 0; j < tokens.length; j++) {
        //uint addrIdx = j + tokens.length ;
        if (tokens[j] != address(0x0)) { 
          tokeninfos[j] = tokeninfo(tokens[j],tokenBalance(user, tokens[j]));
        } else {
          tokeninfos[j] = tokeninfo(tokens[j],0);
        }
        
      }
      addressinfo memory addressinfo = addressinfo(user,user.balance, tokeninfos);
    // }
  
    return addressinfo;
  }

}