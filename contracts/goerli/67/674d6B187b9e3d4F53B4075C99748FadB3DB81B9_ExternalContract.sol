/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

pragma solidity 0.8.11;

contract ExternalContract {
    uint256 public number;

    function test(uint256 num) public {
        number = num;
    }
}

interface IExternalContract {
    function test(uint256 num) external;
}

contract CallContract {
    uint256 public number;

    address public externalAddr;

    constructor(address _externalAddr) {
        externalAddr = _externalAddr;
    }

    function usingCall(uint256 num) public {
       (bool success, ) = externalAddr.call(abi.encodeWithSignature("test(uint256)", num));
       require(success);
    }

    function usingDelegatecall(uint256 num) public {
        (bool success, ) = externalAddr.delegatecall(abi.encodeWithSignature("test(uint256)", num));
        require(success);
    }

    function directlyCall(uint256 num) public {
        IExternalContract(externalAddr).test(num);
    }
}