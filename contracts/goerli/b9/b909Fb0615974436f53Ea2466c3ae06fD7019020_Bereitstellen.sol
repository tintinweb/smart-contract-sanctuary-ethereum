// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;
contract Bereitstellen {
    string public color;
    // owner - is a state to save the deployer address
    address public owner;

    // constructor - need to be implemented because this fuction only runs once and at the first.
    constructor() {
        owner = msg.sender;
    }

    event ColorChanged(address by, string color);

    function setColor(string memory _yourNewColor) public {
        // require - because we need to put some message, so we have to use it as validator
        require(msg.sender == owner, "Can only called by deployer");
        color = _yourNewColor;
        emit ColorChanged(msg.sender, _yourNewColor);
    }
}