// Specifies the version of Solidity, using semantic versioning.
// SPDX-License-Identifier: UNLICENSED
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

contract Contract {
    struct ContractInfo {
        string contractId;
        string signedAt;
    }

    ContractInfo public _contractInfo;

    function setData(ContractInfo memory contractInfo) public {
        _contractInfo = contractInfo;
    }

    function getData() public view returns (ContractInfo memory) {
        return _contractInfo;
    }
}