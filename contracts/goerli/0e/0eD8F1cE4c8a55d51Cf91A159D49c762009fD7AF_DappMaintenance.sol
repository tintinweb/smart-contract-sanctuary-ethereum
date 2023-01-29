// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/dappmaintenance

/**
 * @title DappMaintenance contract.
 * @dev When the Synthetix system is on maintenance (upgrade, release...etc) the dApps also need
 * to be put on maintenance so no transactions can be done. The DappMaintenance contract is here to keep a state of
 * the dApps which indicates if yes or no, they should be up or down.
 */
contract DappMaintenance is Owned {
    bool public isPausedStaking = false;
    bool public isPausedSX = false;

    /**
     * @dev Constructor
     */
    constructor(address _owner) Owned(_owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function setMaintenanceModeAll(bool isPaused) external onlyOwner {
        isPausedStaking = isPaused;
        isPausedSX = isPaused;
        emit StakingMaintenance(isPaused);
        emit SXMaintenance(isPaused);
    }

    function setMaintenanceModeStaking(bool isPaused) external onlyOwner {
        isPausedStaking = isPaused;
        emit StakingMaintenance(isPausedStaking);
    }

    function setMaintenanceModeSX(bool isPaused) external onlyOwner {
        isPausedSX = isPaused;
        emit SXMaintenance(isPausedSX);
    }

    event StakingMaintenance(bool isPaused);
    event SXMaintenance(bool isPaused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}