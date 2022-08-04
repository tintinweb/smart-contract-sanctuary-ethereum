//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * @dev Message Validation Interface
 */
interface IMessageValidator {
    /**
     * @dev Validation Result.
     * Contains the result and error message. If the given string value is valid, `message` should be empty.
     */
    struct Result {
        bool isValid;
        string message;
    }

    /**
     * @dev Validates given string value and returns validation result.
     */
    function validate(string memory _msg) external view returns (Result memory);
}

import {IMessageValidator} from "../interface/IMessageValidator.sol";

contract AlwaysNoValidator is IMessageValidator {
    function validate(string memory) external override view returns (Result memory) {
        return Result({ isValid: false, message: "AlwaysNoValidator" });
    }
}

contract AlwaysYesValidator is IMessageValidator {
    function validate(string memory) external override view returns (Result memory) {
        return Result({ isValid: true, message: "AlwaysYesValidator" });
    }
}

contract EvenLengthValidator is IMessageValidator {
    function validate(string memory _message) external override view returns (Result memory) {
        uint256 length = bytes(_message).length;
        return Result({ isValid: length % 2 == 0, message: "EvenLengthValidator" });
    }
}