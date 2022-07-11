// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "SeraphProtectedDev.sol";

contract Demo is SeraphProtectedDev {

    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferOwnership(address _newAddress) external onlyOwner withSeraph() {
        owner = _newAddress;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0 <=0.9.0;

interface ISeraph {
    function checkEnter(address, bytes4, bytes calldata, uint256) external;
    function checkLeave(bytes4) external;
}

abstract contract SeraphProtectedDev {

    ISeraph public seraph;

    modifier withSeraph() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, 0);
        _;
        seraph.checkLeave(msg.sig);
    }

    modifier withSeraphPayable() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, msg.value);
        _;
        seraph.checkLeave(msg.sig);
    }

    function setSeraph (address _seraph) public {
        seraph = ISeraph(_seraph);
    }
}