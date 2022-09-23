// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CharityVerification {
    struct Charity {
        string charityName;
        string charityId;
        bool verified;
        bool approved;
    }
    Charity[] public charities;

    function verifyCharity(
        string calldata _charityName, 
        string calldata _charitId, 
        bool _verified, 
        bool _approved
    ) public {
        charities.push(
            Charity({
                charityName: _charityName, 
                charityId: _charitId, 
                verified: _verified, 
                approved: _approved
            })
        );
    }
}