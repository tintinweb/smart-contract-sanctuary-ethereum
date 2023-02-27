/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

pragma solidity >=0.7.0 <0.9.0;

contract TestDepth {
    uint256 public x;

    function depth(uint256 y) public {
        // bool result;
        if (y > 0) {
            bytes memory call = abi.encodeWithSignature("depth(uint256)", --y);
            (bool result,) = address(this).delegatecall(call);
            require(result);
        }
        else {
            // Save the remaining gas in storage so that we can access it later
            x = gasleft();
        }
    }
}