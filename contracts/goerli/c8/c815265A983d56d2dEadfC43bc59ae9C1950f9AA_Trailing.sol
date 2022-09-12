pragma solidity ^0.8.0;

contract Trailing {
    function foo() public {
        address externalContract = address(0xA64CfD1BaD88C2153E15E7194b81a43f265d7b36);
        (bool success, bytes memory returnedData) = externalContract.call{value: 0}(abi.encodeWithSignature("Hack()"));
    }
}