//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './BaseAldanContract.sol';
import './IAldanTypes.sol';

contract Aldan_1Y_Collateral_Contract is BaseAldanContract {

    // 1Y
    uint private _collateralDuration = 31536000;
    // 1Y
    uint private _collateralExtend = 31536000;


    /************ CONSTRUCTOR ***************************/
    constructor(string memory version) {
        _version = version;
    }

    function getCollateralDuration() public override(BaseAldanContract) view returns (uint) {
        return _collateralDuration;
    }

    function getCollateralExtend() public override(BaseAldanContract) view returns (uint)     {
        return _collateralExtend;
    }

}