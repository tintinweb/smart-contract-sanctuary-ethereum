//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/ISheeshaRetroSHVault.sol";

contract SheeshaTestSHVault is ISheeshaRetroSHVault {
    address public override sheesha;
    mapping(address => uint256) private _stakers;

    constructor(address sheesha_) {
        sheesha = sheesha_;
    }

    function userInfo(
        uint256 /*id*/,
        address user
    ) external view override returns (uint256, uint256) {
        uint256 amount = _stakers[user];
        return (amount, 0);
    }

    function stake(uint256 amount) external override {
        _stakers[msg.sender] = amount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaRetroSHVault {
    function sheesha() external view returns (address);
    function userInfo(uint256 id, address user) external view returns (uint256, uint256);
    function stake(uint256) external;
}