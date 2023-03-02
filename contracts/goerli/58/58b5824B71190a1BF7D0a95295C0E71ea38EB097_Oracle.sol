// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICaller {
    function callBack(uint256 _result) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ICaller} from "../interface/ICaller.sol";

contract Oracle {
    ICaller public caller;

    constructor(address _caller) {
        caller = ICaller(_caller);
    }

    function requestConvertToUint(string memory _input) public {
        emit RequestConvertToUint(_input);
    }

    function convertToUint(uint256 _result) public {
        // do something
        caller.callBack(_result);
    }

    event RequestConvertToUint(string _input);
}