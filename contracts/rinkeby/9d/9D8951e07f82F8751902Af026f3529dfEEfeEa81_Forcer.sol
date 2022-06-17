// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Forcer {
    address payable forceAddress = payable(0xC75b4288736e47602F8Cf27EcB443ee87CFb6F56);

    function forceTransfer (address payable _to, uint256 _amount) public {
        _to.transfer( _amount);
    }

    receive() external payable {
    }

    fallback() external payable {
        forceAddress.transfer(msg.value);
    }
}