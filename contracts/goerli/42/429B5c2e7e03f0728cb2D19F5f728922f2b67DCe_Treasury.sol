// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IMiner.sol";

contract Treasury {
    address public owner;

    IMiner public frogFellowToken;

    mapping(address => bool) public miner;

    modifier onlyMiner() {
        require(miner[msg.sender], "Only miner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external onlyMiner {
        frogFellowToken.mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMiner {
    function mint(address account, uint256 amount) external;
}