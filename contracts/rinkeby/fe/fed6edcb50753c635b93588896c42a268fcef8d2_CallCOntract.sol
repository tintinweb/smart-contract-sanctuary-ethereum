/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity 0.8.11;

contract ExternalContract {
    uint256 public number;

    function test(uint256 num) public {
        number = num;
    }
}

contract CallCOntract {
    uint256 public number;

    address public externalAddr;

    constructor(address _externalAddr) {
        externalAddr = _externalAddr;
    }

    function usingCall(uint256 num) public {
        (bool success,) = externalAddr.call(abi.encodeWithSignature("test(uint256)", num));
        require (success);
    }

    function usingDelegate(uint256 num) public {
        (bool success,) = externalAddr.delegatecall(abi.encodeWithSignature("test(uint256)", num));
        require (success);
    }
}