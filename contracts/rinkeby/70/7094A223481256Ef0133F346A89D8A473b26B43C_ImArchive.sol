// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGovernance.sol";

/**
   @title ImArchive contract
   @dev This contract archives IDs that were requested in the Import Contract
*/
contract ImArchive {
    //  Address of Governance Contract
    IGovernance public gov;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    //  A list of imported RequestID
    mapping(uint256 => bool) public requestIDs;

    modifier onlyAuthorize() {
        require(
            gov.iService() == msg.sender, "Unauthorized "
        );
        _;
    }

    modifier onlyManager() {
        require(
			gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager"
		);
        _;
    }

    constructor(address _gov) {
        gov = IGovernance(_gov);
    }

    /**
        @notice Change a new Manager contract
        @dev Caller must be Owner
        @param _newGov       Address of new Governance Contract
    */
    function setGov(address _newGov) external onlyManager {
        require(_newGov != address(0), "Set zero address");
        gov = IGovernance(_newGov);
    }

    /**
        @notice Save ID of request that has been used in the Import Contract
        @dev Caller must be Import Contract
        @param _id       A number of requested ID
    */
    function saveId(uint256 _id) external onlyAuthorize {
        //  Not need to check if `_requestId` existed before storing
        //  already verified
        requestIDs[_id] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title IGovernance contract
    @dev Provide interface methods that other contracts can interact to Governance Contract
*/
interface IGovernance {
    function iService() external view returns (address);
    function eService() external view returns (address);
    function locked() external view returns (bool);
    function exports(address _token) external view returns (bool);
    function imports(address _token) external view returns (bool);
    function networks(uint256 networkId) external view returns (bool);
    function hasRole(bytes32 _role, address _addr) external view returns (bool);
}