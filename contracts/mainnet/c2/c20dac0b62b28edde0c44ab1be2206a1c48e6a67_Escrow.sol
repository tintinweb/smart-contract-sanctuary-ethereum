// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Escrow {
    address public owner;
    address public claimer;

    error OnlyOwner();
    error OnlyClaimer();
    event Claimed(uint256 balance);
    event ClaimerChanged(address oldClaimer, address newClaimer);
    event Received(uint256 amount);

    constructor(address _owner, address _claimer) {
        owner = _owner;
        claimer = _claimer;
    }

    function claim(address recipient) public returns (bool) {
        if (msg.sender != claimer) {
            revert OnlyClaimer();
        }
        emit Claimed(address(this).balance);
        (bool success, ) = recipient.call{ value: address(this).balance }("");
        return success;
    }

    function setClaimer(address _claimer) public {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }

        claimer = _claimer;
    }

    receive() external payable {
        emit Received(msg.value);
    }
}