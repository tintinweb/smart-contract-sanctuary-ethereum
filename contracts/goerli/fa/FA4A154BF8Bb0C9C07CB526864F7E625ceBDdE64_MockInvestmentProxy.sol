// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract AdminStructure {
    address public superAdmin;
    address[] private adminList;
    mapping(address => bool) public isAdmin;

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "sender is not superAdmin");
        _;
    }

    modifier isValidAdmin() {
        require(msg.sender == superAdmin || isAdmin[msg.sender], "sender is not admin");
        _;
    }

    constructor() {
        superAdmin = msg.sender;
    }

    function transferSuperAdmin(address _superAdmin) external onlySuperAdmin {
        superAdmin = _superAdmin;
    }

    function addAdmins(address[] memory _admins) external onlySuperAdmin {
        for (uint256 i; i < _admins.length; i++) {
            require(!isAdmin[_admins[i]], "admin was already added");
            isAdmin[_admins[i]] = true;
            adminList.push(_admins[i]);
        }
    }

    function removeAdmins(address[] memory _admins) external onlySuperAdmin {
        for (uint i = 0; i < _admins.length; i++) {
            for (uint j = 0; j < adminList.length; j++) {
                if (_admins[i] == adminList[j]) {
                    // Remove the matching admin address from the list
                    adminList[j] = adminList[adminList.length - 1];
                    adminList.pop();
                    delete isAdmin[_admins[i]];
                    break;
                }
            }
        }
    }

    function getAllAdmins() public view returns (address[] memory) {
        return adminList;
    }
}

contract MockInvestmentProxy is AdminStructure {
    address[] private strategies;
    mapping(address => bool) public isActiveStrategy;

    constructor() {}

    function addStrategies(address[] memory _strategies) external isValidAdmin {
        for (uint256 i; i < _strategies.length; i++) {
            require(!isActiveStrategy[_strategies[i]], "strategy was already added");
            isActiveStrategy[_strategies[i]] = true;
            strategies.push(_strategies[i]);
        }
    }

    function disableStrategies(address[] memory _strategies) public isValidAdmin {
        for (uint i = 0; i < _strategies.length; i++) {
            for (uint j = 0; j < strategies.length; j++) {
                if (_strategies[i] == strategies[j]) {
                    isActiveStrategy[_strategies[i]] = false;
                    break;
                }
            }
        }
    }

    function toggleStrategies(address[] memory _strategies, bool[] memory _status) public isValidAdmin {
        require(_strategies.length == _status.length, "Invalid inputs length");
        for (uint i = 0; i < _strategies.length; i++) {
            for (uint j = 0; j < strategies.length; j++) {
                if (_strategies[i] == strategies[j]) {
                    isActiveStrategy[_strategies[i]] = _status[i];
                    break;
                }
            }
        }
    }

    function removeStrategies(address[] memory _strategies) public isValidAdmin {
        for (uint i = 0; i < _strategies.length; i++) {
            for (uint j = 0; j < strategies.length; j++) {
                if (_strategies[i] == strategies[j]) {
                    // Remove the matching strategy address from the list
                    strategies[j] = strategies[strategies.length - 1];
                    strategies.pop();
                    delete isActiveStrategy[_strategies[i]];
                    break;
                }
            }
        }
    }

    function getAllStrategies() public view returns (address[] memory) {
        return strategies;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4