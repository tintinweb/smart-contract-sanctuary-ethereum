pragma solidity ^0.8.14;

contract SushiMasterChefACL {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
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
        require(_pid == 1, "Pool is not allowed");
    }

    function withdraw(uint256 _pid, uint256 _amount) external view onlySelf {
        require(_checkedValue == 0, "invalid value");
        require(_pid == 1, "Pool is not allowed");
    }
}