/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// File: contracts/IReferBook.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IReferBook {
    function addReferForNoExist(address referral, address referrer) external;

    function getRefer(address referee) external view returns (address);
}

// File: contracts/ReferBook.sol

pragma solidity >=0.4.22 <0.9.0;

contract ReferBook is IReferBook {
    mapping(address => address) private _refermap;
    event ReferSaved(address referral, address referrer);

    function addReferForNoExist(address referral, address referrer) public override {
        if (_refermap[referral] == address(0)) {
            require(referral != referrer, "NO_SELF_REFER");
            _refermap[referral] = referrer;
            emit ReferSaved(referral, referrer);
        }
    }

    function getRefer(address referee) public override view returns (address) {
        return _refermap[referee];
    }
}