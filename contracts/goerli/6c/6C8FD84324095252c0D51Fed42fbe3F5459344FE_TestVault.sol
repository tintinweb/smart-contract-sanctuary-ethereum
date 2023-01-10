// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

contract TestVault {
    
    // Global vars

    uint256 public vaultBalance;
    uint256 public vaultCap;

    // Events

    event SpaceRequested(uint256 _space);

    // event BalanceChanged(uint256 _balance);

    // Functions

    constructor(uint256 _vaultCap) {
        vaultCap = _vaultCap;
    }

    // Returns space left before hitting cap
    function getSpaceView() public view returns (uint256) {
        uint256 space = vaultCap - vaultBalance;
        return space;
    }

    function emitSpaceEvent() public {
        uint256 space = vaultCap - vaultBalance;
        emit SpaceRequested(space);
    }

    function changeVaultBalance(uint256 _newBalance) public {
        vaultBalance = _newBalance;
        // emit BalanceChanged(_newBalance);
    }
}