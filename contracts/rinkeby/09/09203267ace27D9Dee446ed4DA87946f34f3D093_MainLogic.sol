// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ValidateLib.sol";


contract MainLogic {

    uint256 storeData;

    constructor(uint256 _storeData) {
        storeData = _storeData;
    }

    function testFun1(uint256 _storeData) public {
        storeData = _storeData;
    }

    function testFun2() public pure returns(uint256) {
        return ValidateLib.getValidateData();
    }
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


library ValidateLib {

    function getValidateData() public pure returns(uint256) {
        return 8;
    }
	
}