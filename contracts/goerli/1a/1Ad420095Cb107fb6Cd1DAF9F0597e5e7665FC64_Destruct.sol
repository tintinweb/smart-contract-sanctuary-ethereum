pragma solidity 0.8.14;

contract Destruct {
    constructor() payable {}

    receive() external payable {}

    function destruct() public {
        selfdestruct(payable(msg.sender));
    }
}