/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);   
}

contract MyContract {

    IERC20 MTK = IERC20(address(0x9B060Ff92A74444A844B39E66b146eae5A45360E));
    
    function sendUSDT(address _to, uint256 _amount) external {        
        MTK.transfer(_to, _amount);
    }
}