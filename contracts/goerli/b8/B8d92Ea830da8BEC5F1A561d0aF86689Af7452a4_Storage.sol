// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 public number;
    event StoreEvent(
        address indexed seller,
        uint256 timestamp
    );
    event RetrieveEvent(
        address indexed seller,
        uint256 timestamp
    );

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        emit StoreEvent(msg.sender, block.timestamp);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public returns (uint256){
        emit RetrieveEvent(msg.sender, block.timestamp);
        return number;
    }
}