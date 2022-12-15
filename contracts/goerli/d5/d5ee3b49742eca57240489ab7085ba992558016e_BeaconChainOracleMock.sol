// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../contracts/interfaces/IBeaconChainOracle.sol";



contract BeaconChainOracleMock is IBeaconChainOracle {

    bytes32 public mockBeaconChainStateRoot;

    function getBeaconChainStateRoot() external view returns(bytes32){
        return mockBeaconChainStateRoot;
    }

    function setBeaconChainStateRoot(bytes32 beaconChainStateRoot) external {
        mockBeaconChainStateRoot = beaconChainStateRoot;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IBeaconChainOracle {

    function getBeaconChainStateRoot() external view returns(bytes32);
    function setBeaconChainStateRoot(bytes32 beaconChainStateRoot) external;

}