/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// File: contracts/Greeter.sol



pragma solidity >=0.8.13;

contract Greeter {
    /* Main function */

    uint8 number;

    function changeNumber(uint8 n) public {
        number = n;
    }

    function getNumber() public view returns (uint8) {
        return number;
    }

    function changeCalldata(bytes4 selector, uint8 n) public pure returns (bytes memory){
       return abi.encodeWithSelector(selector, n);
    }

    function getSelector(string calldata _func) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }
}