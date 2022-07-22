// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CallFunction {

    bytes public bytesOutput;

    function callFunction(
        address addrOfContract, 
        string memory _name
    ) external payable returns(string memory, string memory) {

        // (bool success, bytes memory dataReturned) = addrOfContract.call{value: 200, gas: 100000}
        // (
        //     abi.encodeWithSignature("returnNumber10(string)", _name)
        // );
        // require(success, "the call failed miserably");
        // bytesOutput = dataReturned;

        bytesOutput = abi.encodeWithSignature("returnNumber10(string)", _name);

        return ("Hello", _name);
    }

    
}

contract A {

    string public name;

    function returnNumber10(string memory _name) external payable returns(uint) {
        name = _name;
        return 10;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {}
}