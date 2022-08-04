/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/interfaces/IRoleAccess.sol

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}


// File contracts/interfaces/IDataLog.sol

// : BUSL-1.1

pragma solidity 0.8.11;


enum DataSource {
    Campaign,
    MarketPlace,
    SuperFarm,
    Swap
}

enum DataAction {
    Buy,
    Refund,
    ClaimDeed,
    List,
    Unlist,
    AddLp,
    RemoveLp,
    Swap
}

interface IDataLog {
    
    function log(address fromContract, address fromUser, DataSource source, DataAction action, uint data1, uint data2) external;

}


// File contracts/DataLogger.sol

// : BUSL-1.1

pragma solidity 0.8.11;
contract DataLogger is IDataLog {

    // Access rights control
    IRoleAccess private _roles;
    mapping (address => bool) public allowedSource;
    
    event SetSource(address source, bool allowed);
    
    event Log(address indexed fromContract, address indexed fromUser, DataSource indexed source, DataAction action, uint data1, uint data2);

    modifier onlyAdmin() {
        require(_roles.isAdmin(msg.sender), "Not Admin");
        _;
    }

    constructor(IRoleAccess rolesRegistry)
    {
        _roles = rolesRegistry;
    }

    function setSource(address source, bool allowed) external onlyAdmin {
        allowedSource[source] = allowed;
        emit SetSource(source, allowed);
    }

    function log(address fromContract, address fromUser, DataSource source, DataAction action, uint data1, uint data2) external {
        require(allowedSource[msg.sender], "Not allowed to log");
        emit Log(fromContract, fromUser, source, action, data1, data2);
    }
}