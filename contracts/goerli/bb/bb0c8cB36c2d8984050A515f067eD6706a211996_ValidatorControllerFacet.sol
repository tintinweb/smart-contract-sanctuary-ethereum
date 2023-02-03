// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibValidatorController } from "../libraries/LibValidatorController.sol";
import { IValidatorController } from "../interfaces/IValidatorController.sol";

contract ValidatorControllerFacet is IValidatorController {
    function setValidator(address _newValidator) external {
        // Only validator
        LibValidatorController.enforceIsValidator();
        LibValidatorController.setValidator(_newValidator);
    }

    function validator() external view returns (address) {
        return LibValidatorController.validator();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IValidatorController {
    event ValidatorTransferred(address indexed previousOwner, address indexed newOwner);

    function setValidator(address _newValidator) external;

    function validator() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibValidatorController {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("validatorController.storage");

    struct ValidatorControllerStorage {
        address validator;
    }

    function diamondStorage() internal pure returns (ValidatorControllerStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event ValidatorTransferred(address indexed previousOwner, address indexed newOwner);

    function enforceIsValidator() internal view {
        require(
            msg.sender == diamondStorage().validator,
            "LibValidatorController: Must be validator"
        );
    }

    function setValidator(address _newValidator) internal {
        ValidatorControllerStorage storage ds = diamondStorage();
        address previousValidator = ds.validator;
        ds.validator = _newValidator;
        emit ValidatorTransferred(previousValidator, _newValidator);
    }

    function validator() internal view returns (address) {
        return diamondStorage().validator;
    }
}