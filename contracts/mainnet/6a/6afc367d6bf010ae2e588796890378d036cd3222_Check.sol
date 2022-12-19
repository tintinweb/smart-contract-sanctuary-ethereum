/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Token {
    function balanceOf(address account) external view returns (uint256);
}

contract Check {
    function balanceOf(address contract_address, address[] memory owners) public view returns (uint256[] memory balances){
        balances = new uint256[](owners.length);
        if(contract_address!=address(0)){
            Token token = Token(contract_address);
            for(uint256 i=0;i<owners.length;i++){
                balances[i] = token.balanceOf(owners[i]);
            }
        }else{
            for(uint256 i=0;i<owners.length;i++){
                balances[i] = address(owners[i]).balance;
            }
        }
    }
}