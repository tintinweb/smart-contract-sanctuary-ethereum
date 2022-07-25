//SPDX - License -Identifier : MIT

pragma solidity 0.8.4;

contract eroneous {
    error insufficiennt();
    uint256 public constant PRICE = 0.50 ether;
    string public name;

    function mint() external payable {
        if (msg.value <= PRICE) revert insufficiennt();
        name = "Pedro";


    }

    receive() external payable {}

}