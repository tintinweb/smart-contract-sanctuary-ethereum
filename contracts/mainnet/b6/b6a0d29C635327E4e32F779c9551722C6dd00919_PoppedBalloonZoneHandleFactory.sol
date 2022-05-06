/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: AGPL-3.0

// (C) 2021 Intellectual Property Collectors and Managers, Inc
// (C) 2018 GroupTrap Labs
// (C) 2017 Popped Balloon Intellectual Property Corporation
// (C) 2015 [email protected]

pragma solidity ^0.8.13;

interface Dmap {
    function set(bytes32 name, bytes32 meta, bytes32 data) external;
}

contract ZoneHandle {
    Dmap immutable public dmap;
    address        public owner;

    event Give(address indexed whom);

    constructor(Dmap d) {
        dmap = d;
    }
    function give(address whom) external {
        require(msg.sender == owner, 'ERR_OWNER');
        owner = whom;
        emit Give(whom);
    }
    function set(bytes32 name, bytes32 meta, bytes32 data) external {
        require(msg.sender == owner, 'ERR_OWNER');
        dmap.set(name, meta, data);
    }
}

abstract contract PoppedBalloonEVMSmartContractExecutionContext {
    function _getCallerOfCurrentFunction() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract DmapHaverAbstractBaseContract {
    Dmap localDmapReferenceSavedInStorage;
    constructor(Dmap dmapAddressProvidedToConstructorAtDeployTime) {
        localDmapReferenceSavedInStorage = dmapAddressProvidedToConstructorAtDeployTime;
    }
}

contract PoppedBalloonZoneHandleFactory is DmapHaverAbstractBaseContract, PoppedBalloonEVMSmartContractExecutionContext {
    event ThisContractBuiltAZoneHandle(address indexed theAddressOfTheZoneHandleThatWasBuilt, address indexed theCallerOfTheBuildAZoneHandleAndReturnItFunction);
    constructor(Dmap dmapAddressProvidedToConstructorAtDeployTime) DmapHaverAbstractBaseContract(dmapAddressProvidedToConstructorAtDeployTime) {

    }
    function buildAZoneHandleAndReturnIt() external returns (ZoneHandle) {
        ZoneHandle newZoneHandleContractObject = new ZoneHandle(localDmapReferenceSavedInStorage);
        newZoneHandleContractObject.give(_getCallerOfCurrentFunction()); // this is an alias for transferZoneToAddress
        emit ThisContractBuiltAZoneHandle(_getCallerOfCurrentFunction(), address(newZoneHandleContractObject));
        return newZoneHandleContractObject; // return newZoneProxContractObject to caller
    }
}