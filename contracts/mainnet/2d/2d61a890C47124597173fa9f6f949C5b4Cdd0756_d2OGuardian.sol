// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AuthAdmin.sol";

interface d2OLike {
    function setTransferBlockRelease(address, uint256) external;
    function deny(address) external;
    function cage(uint256) external;
}

contract d2OGuardian is AuthAdmin("d2OGuardian", msg.sender) {

    //HYP, LZ, etc -> address deployed on this chain
    mapping (bytes32 => address) public pipeAddresses;
    address public immutable d2OContract;

    event SetPipeAddress(bytes32 indexed pipeName, address pipeAddress);
    event HaltedPipe(bytes32 indexed pipe);
    event CagedUser(address indexed user);
    event CagedDeuterium();
    

    constructor(address _d2OContract) {
        require(_d2OContract != address(0), "d2OGuardian/invalid address");
        d2OContract = _d2OContract;
    }

    function setPipeAddress(bytes32 pipeName, address pipeAddress) external auth {
        pipeAddresses[pipeName] = pipeAddress;
        emit SetPipeAddress(pipeName, pipeAddress);
    }

    function removeConnectorAdmin(bytes32 pipeName) external auth {
        d2OLike(d2OContract).deny(pipeAddresses[pipeName]);
        emit HaltedPipe(pipeName);
    }

    function cageDeuterium() external auth {
        d2OLike(d2OContract).cage(0);
        emit CagedDeuterium();
    }

    function cageUser(address user) external auth {
        d2OLike(d2OContract).setTransferBlockRelease(user, 2**256 - 1);
        emit CagedUser(user);
    }


}