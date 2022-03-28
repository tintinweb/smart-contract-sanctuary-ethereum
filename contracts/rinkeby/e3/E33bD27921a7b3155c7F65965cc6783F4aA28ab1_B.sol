// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }

    function bFunc(uint256 _num) public view returns (uint256) {
        uint256 res = num;
        for(uint i = 0; i <= 400; i++){
            res += 2;
        }
        return res;
    }

    function bFuncNotV(uint256 _num) public returns (uint256) {
        uint256 res = num;
        for(uint i = 0; i <= 400; i++){
            res += 2;
        }
        return res;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    function callView(address _contract, string memory _sig) public {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature(_sig, 5)
        );
    }

    function callViewAn(address _contract, string memory _sig) public {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature(_sig, 5)
        );
    }
}