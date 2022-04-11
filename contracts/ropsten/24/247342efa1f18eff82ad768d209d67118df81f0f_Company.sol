/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Company{
    string public boss_name;
    address payable public boss_address;
    uint256 time_star = block.timestamp;

    function Time_() public view returns(uint256) {
    return block.timestamp-time_star;
    }

    constructor(string memory name){
    boss_name = name;
    boss_address = payable(msg.sender);
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
    }

    function Destroy() external{
        if (Time_() < 31536000 )
            return ;
        else
            selfdestruct(boss_address);
    }

}