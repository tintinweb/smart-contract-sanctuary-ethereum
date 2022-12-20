/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-31
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SandWichAttack {
    uint256 public sandwich_attack_cnt = 0;

    receive() external payable {}

    function sandwichAttack(uint256 _ethAmountToCoinbase) external {
        sandwich_attack_cnt++;

        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}