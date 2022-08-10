/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// File: contracts/test2.sol

//SPDX-License-Identifier: GPL-3.0
     
    pragma solidity >=0.5.0 <0.9.0;

   interface IERC20 {
        
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
   }
        
    contract BulkAirDrop{
        constructor(){}

        function bulkAirdropERC20(IERC20 _token, address[]  calldata _to, uint256[] calldata _value) public {
            require (_to.length == _value.length);
            for(uint i = 0; i<= _to.length ; i++){
                require (_token.transferFrom(msg.sender, _to[i], _value[i] ));
            }
        }
    }