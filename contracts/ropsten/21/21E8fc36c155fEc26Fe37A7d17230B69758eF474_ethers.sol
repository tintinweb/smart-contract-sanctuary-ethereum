//SPDX - License -Identifier : MIT

pragma solidity 0.8.4;

contract ethers {
    error insufficiennt();
    uint256 public constant PRICE = 0.50 ether;

    function mint() external payable {
        if (msg.value <= PRICE) revert insufficiennt();

    }

    receive() external payable {}

}