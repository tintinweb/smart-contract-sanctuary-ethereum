//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import {IBouncerKYC, Statuses} from "../library/IBouncerKYC.sol";

/**
 * @dev This is a mock. Don't use in production.
 */
contract MockBouncerKYC is IBouncerKYC {
    mapping(address => Statuses) internal statuses;

    function setStatus(address _user, Statuses _status) external {
        statuses[_user] = _status;
    }

    function getStatus(address _user) external view override(IBouncerKYC) returns (Statuses) {
        return statuses[_user];
    }
}

pragma solidity 0.6.12;

enum Statuses {
    Failed,
    Verified
}

interface IBouncerKYC {
    function getStatus(address _user) external view returns (Statuses);
}

contract Verifiable {
    IBouncerKYC kyc;

    modifier isVerified() {
        require(kyc.getStatus(msg.sender) == Statuses.Verified, "Verifiable: sender is not KYCed");
        _;
    }
}