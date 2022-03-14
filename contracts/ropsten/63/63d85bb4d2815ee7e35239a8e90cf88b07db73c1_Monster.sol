/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: unlicensed

// We gonna continue the 'selfdestruct' keyword usage

pragma solidity ^0.8.7;

contract Kill {

    constructor () payable {}

    function kill() external {
        selfdestruct (payable(msg.sender));

    }
    function testCall () external pure returns (uint) {
        return 5555;
    }
}

contract Monster {

    event shoMsg(string mesg);

    address public owner = msg.sender; 

    function getBal() external view returns (uint) {
        require(msg.sender == owner, "Only owner can call this" );
        return address (this).balance;
    }

    function performAttack(Kill _performAttack ) external {

        _performAttack.kill();
        emit shoMsg("Kill Success, Balance been hacked");

    }


}