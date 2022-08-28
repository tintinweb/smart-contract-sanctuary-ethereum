/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


contract CallerLVL1 {
    address public target;
    
    constructor (address _target)  {
    target = _target;
      
}

    function call_mint() public {
        (bool success,) = target.call(abi.encodeWithSignature("mint(address,uint256)",
        address(this),10));
        require (success);
    }

    function call_transfer() public {
        (bool success,) = target.call(abi.encodeWithSignature("transfer(address,uint256)",
        msg.sender,10));
        require (success);
    }

receive() external payable { }
}