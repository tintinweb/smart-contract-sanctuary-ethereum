//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract Greeter {
    string private greeting;
    uint256 public wow;
    uint256 public hehe;
    uint256 public lintme;

    // float public ww; // no floating number in solidity native support
    // solhint-disable-next-line
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    /// @dev hello
    /// @param ee wow
    /// @return Documents the return variables of a contract’s function state variable
    function greet(uint256 ee) public view returns (string memory) {
        ee + 3;
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function empty() public pure returns (bool) {
        // throw; // should be checked by linter
        return true;
    }
}