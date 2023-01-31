// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract sample {
    address public withdrawAddress = 0x5D6Da076E82260aC6E7454Fac40f6B37577d4BBF;

    function withdraw() external payable {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setWithdrawAddress(address addr) external {
        withdrawAddress = addr;
    }

    function hoge() payable public {}

    function demo() external pure returns(string memory) {
        return "test";
    }
}