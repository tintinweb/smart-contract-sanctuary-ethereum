/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

contract SushiMasterChefACL {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(uint256 => bool) _pidWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // pool whitelist: Sushi-LP for WETH-USDC
        _pidWhitelist[1] = true;
        // pool whitelist: Sushi-LP for WETH-SUSHI
        _pidWhitelist[12] = true;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ===== ACL Function =====
    function deposit(uint256 _pid, uint256 _amount) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_pidWhitelist[_pid], "PID is not allowed");
    }

    function withdraw(uint256 _pid, uint256 _amount) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_pidWhitelist[_pid], "PID is not allowed");
    }
}