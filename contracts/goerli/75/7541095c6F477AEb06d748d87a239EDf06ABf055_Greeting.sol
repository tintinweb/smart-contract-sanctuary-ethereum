// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Greeting {
    string public greeting = "hello";
    
    // greetingを読むだけの関数。初期値は"hello"。
    function sayHello() external view returns (string memory) {
        return greeting;
    }
    // 今のgreetingを編集する関数。編集するのでガス代が発生する。
    function updateGreeting(string calldata _greeting) external {
        greeting = _greeting;
    }
}