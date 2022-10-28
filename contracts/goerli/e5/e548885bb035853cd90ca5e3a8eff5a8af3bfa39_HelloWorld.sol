// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ITestInterface {
    function helloWorld() external view returns (string memory);

    function potato() external returns (string memory);
}

contract HelloWorld {
    string private text;
    address public owner;

    constructor() {
        text = pureText();
        owner = msg.sender;
    }

    function helloWorld() public view returns (string memory)  {
        return text;
    }

    function setText(string calldata newText) public {
        text = newText;
    }

    function transferOwnership(address newOwner) public {
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function pureText() public pure virtual returns (string memory) {
        return "Hello World";
    }

    fallback() external {
        text = "ERROR!";
    }
}

contract InvokeGreeting {
    function getHello(address target) public view returns (string memory){
        return HelloWorld(target).helloWorld();
    }

    function setHello(address target, string calldata newText) public {
        HelloWorld(target).setText(newText);
    }

    function makeItFail(address target) public {
        ITestInterface(target).potato();
    }
}