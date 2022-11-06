/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IHelloWorld {
    function helloWorld() external view returns (string memory);
    function setText(string calldata) external;
}

/// @title Hello World
/// @notice This is an example Hello World implementation for education
contract HelloWorld {
    /// @notice Storage for text that persists between calls
    /// @dev The value of this variable can be read from the storage of this contract directly
    string private text;

    /// @notice stores contract owner address
    address public owner;

    /// @dev Initial method to set up the contract. Called only once at deployment
    constructor() {
        owner = msg.sender;
        text = pureText();
    }

    function helloWorld() public view returns (string memory) {
        return text;
    }

    /**
     * @dev State changing call. This function costs gas to call.
     * Can also receive ETH
     */
    function setText(string calldata newText) public onlyOwner {
        text = newText;
    }

    function pureText() public pure returns (string memory) {
        return "Hello World";
    }

    function _isPure() internal view returns (bool check_) {
        check_ = keccak256(bytes(text)) == keccak256(bytes(pureText()));
    }

    function isPure() public view returns (bool returnValue_) {
        returnValue_ = _isPure();
    }

    function _restore() internal {
        text = pureText();
    }

    modifier onlyWhenNotPure() {
        require(!_isPure(), "The text value is already pure");
        _;
    }

    function restore() public onlyWhenNotPure {
        _restore();
    }

    function sample() public view returns (address) {
        return tx.origin;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}