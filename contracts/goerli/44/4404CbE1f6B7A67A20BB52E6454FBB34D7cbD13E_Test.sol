// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test  {
    struct MyStruct {
        uint256 number;
        address from;
    }


    event TestEvent(MyStruct);
    constructor() {
    }
  
    
    function testFn(uint256 num) external {

        MyStruct memory newStruct = MyStruct({
            number:num,
            from: msg.sender
          });
        emit TestEvent(newStruct
        );
    }
}