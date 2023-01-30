/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ~0.8.8;

contract SendETH {
    bool success;

    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    function sendETH(address payable _to, uint256 amount) external payable{
        success = _to.send(amount);
    }
    
    function callETH(address payable _to, uint256 amount, bytes calldata callData) external payable{
        (bool success1,) = _to.call{value: amount}(callData);
        require(success1, 'callFailed');
    }
}