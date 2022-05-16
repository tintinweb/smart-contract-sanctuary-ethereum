//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Greeter {
    
    constructor () {
    }

    function testFunction() external pure returns(string memory) {
        return "Hey, funcionou!";
    }

    function useFunction(address _to) external returns(bytes memory retorno) {
        (bool success, bytes memory retorno) = _to.call(abi.encodeWithSignature("testFunction()"));
    }

    function retornarSelector() external view returns(bytes4) {
        return bytes4(keccak256(bytes("testFunction()")));
    }
    
}