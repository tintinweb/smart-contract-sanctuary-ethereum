// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IAMB.sol";

contract Counter {
    address public AMB;
    address public sendingCounter;
    address public receivingCounter;
    uint256 public counter;

    constructor(address _AMB) {
        AMB = _AMB;
        sendingCounter = address(this);
    }

    function setReceivingCounter(address _receivingCounter) public {
        receivingCounter = _receivingCounter;
    }

    function send() public view returns (bytes memory) {
        require(receivingCounter != address(0), "Receiving counter not set");
        return IAMB(AMB).send(receivingCounter, abi.encodeWithSignature("increment()"));
        //  data;
        // IAMB.send(...) // TODO: figure out data to send
    }

    function increment() public {
        // ... // TODO: validation of message call
        counter++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IAMB {
    function setRecipientAMB(address _recipientAMB) external;

    function send(address to, bytes calldata data)
        external
        view
        returns (bytes memory);

    function receive(bytes calldata inputData) external;
}