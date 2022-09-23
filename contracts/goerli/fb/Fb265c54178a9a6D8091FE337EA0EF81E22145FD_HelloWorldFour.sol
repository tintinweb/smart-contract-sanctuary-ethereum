// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface HelloWorldFourInterface {
    function pureText() external pure returns (string memory);

    function isPure() external view returns (bool _returnValue);

    function restore() external returns (bool);

    function helloWorld() external view returns (string memory);

    function setText(string calldata newText) external;

    function transferOwnership(address newOwner) external;
}

contract HelloWorldFour is HelloWorldFourInterface {
    string private text;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        text = pureText();
        owner = msg.sender;
    }

    function pureText() public pure override returns (string memory) {
        return "Testing Hello World For the First Time ";
    }

    function _isPure() internal view returns (bool _check) {
        _check = keccak256(bytes(text)) == keccak256(bytes(pureText()));
    }

    function isPure() public view override returns (bool _returnValue) {
        _returnValue = _isPure();
    }

    function _restore() internal {
        text = pureText();
    }

    function restore() public override onlyOwner returns (bool) {
        if (_isPure()) return false;
        _restore();
        return true;
    }

    function helloWorld() public view override returns (string memory) {
        return text;
    }

    function setText(string calldata newText) public override onlyOwner {
        text = newText;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        owner = newOwner;
    }
}