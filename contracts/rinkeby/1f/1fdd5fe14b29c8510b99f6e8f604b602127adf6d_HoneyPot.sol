// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract HoneyPot {
    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public {
        if (equal(_action, "Withdraw")) {
            revert("It's a trap");
        }
    }

    // Function to compare strings using keccak256
    function equal(string memory _a, string memory _b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encode(_a)) == keccak256(abi.encode(_b));
    }
}

contract Logger {
    event Log(address caller, uint amount, string action);

    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public {
        emit Log(_caller, _amount, _action);
    }
}