// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IOracle {
    function requestConvertToUint(string memory _input) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IOracle} from "../interface/IOracle.sol";

contract Caller {
    IOracle public oracle;
    uint256 public result;

    function requestConvertToUint(string memory _input) public {
        oracle.requestConvertToUint(_input);
    }

    function callBack(uint256 _result) external {
        result = _result;
    }

    function setOracle(address _oracle) public {
        oracle = IOracle(_oracle);
    }
}