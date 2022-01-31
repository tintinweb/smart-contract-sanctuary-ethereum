/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.11;

contract FakeOutbox {
    address public owner = msg.sender;
    address public l2ToL1Sender;
    function setL2ToL1Sender(address _l2ToL1Sender) external {
        require(msg.sender == owner, "not owner");
        l2ToL1Sender = _l2ToL1Sender;
    }

}

contract FakeBridge  {
    FakeOutbox public activeOutbox;
    constructor() public {
        activeOutbox = new FakeOutbox();
    }

    function callContract(address _l2ToL1Sender, address _target, bytes calldata _data) external returns (bytes memory res) {
        activeOutbox.setL2ToL1Sender(_l2ToL1Sender);
        bool success;
        (success, res) = _target.call(_data);
        activeOutbox.setL2ToL1Sender(address(0));
        if(!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}