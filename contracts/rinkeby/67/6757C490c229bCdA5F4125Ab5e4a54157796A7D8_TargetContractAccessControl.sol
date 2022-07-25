/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

contract TargetContractAccessControl {
    struct TupleParams {
        address tokenIn;
        address recipient;
        uint24 fee;
    }

    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    mapping(address => bool) _tokenWhitelist;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule!= address(0), "invalid module address");
        // 我们需要绑定该 ACL Contract 对应的 Gnosis Safe 地址和 Cobo Safe Module 地址
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        // 币种白名单，我们的需求中只需要白名单中有 Rinkeby 上的 USDT
        _tokenWhitelist[0x045144F7532E498694d7Aae2d88E176c42c0ff97] = true;
    }

    modifier onlySelf() {
        // 下方的 ACL methods 只可以内部调用
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        // 只有 Cobo Safe Module 才可以调用 check 方法
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function check(bytes32 _role, uint256 _value, bytes calldata data) external onlyModule returns (bool) {
        // 记录下当前 Member 的 Role
        _checkedRole = _role;
        // 记录下当前 Transaction 的 value
        _checkedValue = _value;
        // 调用 ACL methods
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    fallback() external {
        // 出于安全考虑，当调用到本合约中没有出现的 ACL Method 都会被拒绝
        revert("Unauthorized access");
    }

    // ACL methods
    function method1(uint24 param1) external view onlySelf {
        require(param1 > 0, "param1 is invalid");
    }

    function method2(TupleParams calldata params) external view onlySelf {
        require(_tokenWhitelist[params.tokenIn], "Token is not allowed");
        require(params.recipient == safeAddress, "Recipient is not allowed");
    }

    function method3() external view onlySelf {
        require(_checkedRole == 0x6861727665737465727300000000000000000000000000000000000000000000, "Require harvester");
        require(_checkedValue == 0, "Invalid value");
    }
}