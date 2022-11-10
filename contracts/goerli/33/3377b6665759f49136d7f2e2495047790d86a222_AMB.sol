// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IAMB.sol";

contract AMB is IAMB {
    address public immutable validator;
    address public recipientAMB;

    constructor(address _validator) {
        validator = _validator;
    }

    modifier onlyValidator() {
        require(msg.sender == validator, "Only validator can call this method");
        _;
    }

    function setRecipientAMB(address _recipientAMB) public onlyValidator {
        require(
            msg.sender == validator,
            "Only validator can set recipient AMB"
        );
        recipientAMB = _recipientAMB;
    }

    function send(address to, bytes calldata data)
        public
        view
        returns (bytes memory)
    {
        require(recipientAMB != address(0), "Recipient AMB not set");
        return abi.encode(recipientAMB, to, data);
    }

    function receive(bytes calldata inputData) public onlyValidator {
        (address recipient, address to, bytes memory data) = abi.decode(
            inputData,
            (address, address, bytes)
        );
        require(
            recipient == address(this),
            "Only AMB from sender chain can call this method"
        );
        (bool success, ) = to.call(data);
        require(success, "Call to recipient failed");
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