// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBullFarm.sol";

contract LineManager {
    uint[3] lines = [0.1 ether, 0.5 ether, 1 ether];
    mapping(address => uint) deposit;
    mapping(address => bool) migrated;
    IBullFarm public farm;

    event Deposit(address account, uint value);
    event Migration(address, uint value);

    constructor(IBullFarm _farm) {
        farm = _farm;
    }

    receive() external payable {
        require(deposit[msg.sender] == 0, "Deposit already made");

        uint openLines = calcOpenLines(msg.value);
        require(openLines > 0, "Invalid deposit value");

        deposit[msg.sender] = msg.value;
        farm.setOpenLines(msg.sender, openLines);

        emit Deposit(msg.sender, msg.value);
    }

    function migrate() external {
        require(!migrated[msg.sender], "Already migrated");
        require(deposit[msg.sender] > 0, "Deposit is required");
        migrated[msg.sender] = true;
        farm.migrate{value: deposit[msg.sender]}(msg.sender);
        emit Migration(msg.sender, deposit[msg.sender]);
    }

    function getDeposit(address account) external view returns(uint) {
        return deposit[account];
    }

    function isMigrated(address account) external view returns(bool) {
        return migrated[account];
    }

    function calcOpenLines(uint dep) public view returns(uint) {
        if (dep == lines[2]) {
            return 3;
        } else if (dep == lines[1]) {
            return 2;
        } else if (dep == lines[0]) {
            return 1;
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IBullFarm {
    function setOpenLines(address account, uint lines) external;
    function migrate(address account) external payable;
}