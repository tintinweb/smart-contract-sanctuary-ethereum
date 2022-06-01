/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @dev minimum ERC20 interface
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract BatchBalance {
   function getBalances(address[] memory _tokens, address _address) view public returns (uint256[] memory) {
       uint256[] memory balances = new uint[](_tokens.length);
        for (uint16 i=0; i < _tokens.length; i++) {
            IERC20 iERC20 = IERC20(_tokens[i]);
            balances[i] = iERC20.balanceOf(_address);
        }

        balances[balances.length] = _address.balance;

        return balances;
   }
}