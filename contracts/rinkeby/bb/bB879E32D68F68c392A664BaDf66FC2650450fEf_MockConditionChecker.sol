// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

interface IConditionChecker {
    function check(address _checkingAddress, bytes calldata _checkData) external view returns(bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.12;

import { IConditionChecker } from "../common/emission/interfaces/IConditionChecker.sol";

contract MockConditionChecker is IConditionChecker {
    mapping(address => bool) public flag;

    function set(address _checkingAddress, bool _value) external {
        flag[_checkingAddress] = _value;
    }

    function check(address _checkingAddress, bytes calldata) external override view returns(bool) {
        return flag[_checkingAddress];
    }
}