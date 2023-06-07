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

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }


    constructor() {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external onlyMiner {
        frogFellowToken.mint(account, amount);
    }

    function setFrogFellowToken(address _address) external onlyOwner {
        frogFellowToken = IMiner(_address);
    }

    function setMiner(address _address) external onlyOwner {
        miner[_address] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMiner {
    function mint(address account, uint256 amount) external;
}