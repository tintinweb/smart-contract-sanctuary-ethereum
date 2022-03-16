/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.24;


contract BatchTransfer {


    function multisendEther(address[] _contributors, uint256[] _balances) public payable{
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }


}