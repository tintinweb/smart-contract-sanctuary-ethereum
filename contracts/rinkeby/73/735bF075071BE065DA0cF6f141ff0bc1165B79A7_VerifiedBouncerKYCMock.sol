//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IBouncerKYC, Statuses} from "../interfaces/IBouncerKYC.sol";

/**
 * @dev This is a mock. Don't use in production.
 */
contract BouncerKYCMock is IBouncerKYC {
    mapping(address => Statuses) internal statuses;

    function setStatus(address _user, Statuses _status) external {
        statuses[_user] = _status;
    }

    function getStatus(address _user) external view override(IBouncerKYC) returns (Statuses) {
        return statuses[_user];
    }
}

/**
 * @dev This is a mock. Don't use in production.
 */
contract VerifiedBouncerKYCMock is IBouncerKYC {
    function getStatus(address) external pure override(IBouncerKYC) returns (Statuses) {
        return Statuses.Verified;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum Statuses {
    Failed, // default status
    Verified
}

interface IBouncerKYC {
    function getStatus(address _user) external view returns (Statuses);
}