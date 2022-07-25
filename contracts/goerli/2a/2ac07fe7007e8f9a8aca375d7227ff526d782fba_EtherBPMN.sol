/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title EtherBPMN
 * @dev Store business process data on the blockchain
 */
contract EtherBPMN {
    struct BusinessProcess {
        string name;
        uint256 activities;
        uint256 flows;
        uint256 common;
        uint256 total;
    }

    mapping(uint256 => BusinessProcess) public businessProcesses;

    constructor() {
        // Define business processes
        storeBusinessProcess(0, "Flexible savings", 5, 4, 6, 35);
        storeBusinessProcess(1, "Locked savings", 5, 4, 6, 34);
        storeBusinessProcess(2, "Locked staking", 8, 8, 8, 35);
        storeBusinessProcess(3, "Liquidity pools", 6, 5, 3, 72);
        storeBusinessProcess(4, "Dual investment", 8, 8, 9, 41);
    }

    /**
     * @dev Store a business process
     */
    function storeBusinessProcess(
        uint256 _id,
        string memory _name,
        uint256 _activities,
        uint256 _flows,
        uint256 _common,
        uint256 _total
    ) public {
        businessProcesses[_id] = BusinessProcess(
            _name,
            _activities,
            _flows,
            _common,
            _total
        );
    }
}