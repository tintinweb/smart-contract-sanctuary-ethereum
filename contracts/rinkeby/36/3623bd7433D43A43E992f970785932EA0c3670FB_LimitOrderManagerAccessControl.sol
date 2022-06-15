// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;


interface LimitOrderManager {
    
    struct AddLimOrderParam {
        address tokenX;
        address tokenY;
        uint24 fee;
        int24 pt;
        uint128 amount;
        bool sellXEarnY;
        uint256 deadline;
    }
        
}
                

// for cobo safe module v0.4.0
contract LimitOrderManagerWithValueAccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBNB
        _tokenWhitelist[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = true;
        // BUSD
        _tokenWhitelist[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
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

    // ACL methods
    function newLimOrder(uint256 idx, LimitOrderManager.AddLimOrderParam calldata addLimitOrderParam) external view onlySelf {
        // use 'require' to check the access
        require(_tokenWhitelist[addLimitOrderParam.tokenX], "Token is not allowed");
        require(_tokenWhitelist[addLimitOrderParam.tokenY], "Token is not allowed");
    }


    function collectLimOrder(address recipient, uint256 orderIdx, uint128 collectDec, uint128 collectEarn) external view onlySelf {
        // use 'require' to check the access
        require(recipient == safeAddress, "Recipient is not allowed");
    }


    function decLimOrder(uint256 orderIdx, uint128 amount, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
    }
}


// for cobo safe module v0.3.0
contract LimitOrderManagerAccessControl {

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // WBNB
        _tokenWhitelist[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = true;
        // BUSD
        _tokenWhitelist[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
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
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        revert("Unauthorized access");
    }

    // ACL methods


    function newLimOrder(uint256 idx, LimitOrderManager.AddLimOrderParam calldata addLimitOrderParam) external view onlySelf {
        // use 'require' to check the access
        require(_tokenWhitelist[addLimitOrderParam.tokenX], "Token is not allowed");
        require(_tokenWhitelist[addLimitOrderParam.tokenY], "Token is not allowed");
    }


    function collectLimOrder(address recipient, uint256 orderIdx, uint128 collectDec, uint128 collectEarn) external view onlySelf {
        // use 'require' to check the access
        require(recipient == safeAddress, "Recipient is not allowed");
    }


    function decLimOrder(uint256 orderIdx, uint128 amount, uint256 deadline) external view onlySelf {
        // use 'require' to check the access
    }
}