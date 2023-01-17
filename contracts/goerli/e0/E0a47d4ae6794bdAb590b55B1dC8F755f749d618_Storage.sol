// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    mapping (address => uint256) public savings;
    uint openingTime;


    constructor()  {
        openingTime = block.timestamp;
    }

    receive() external payable {
        savings[msg.sender] += msg.value;
    }

    function redeem() public {
        require(block.timestamp > openingTime + 5 minutes);
        payable(msg.sender).transfer(savings[msg.sender]);
        savings[msg.sender] = 0;
    }

}