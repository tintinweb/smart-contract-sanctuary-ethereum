// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Replay {
    address public replayAddr = 0x69697d483fC7eCF3753DF589CA9a1264F31C543d;
    address public replayAddr2 = 0x66679ea3F86f9E9B6A0a734ae9749097e44dC43c;
    address public replayAddr3 = 0x007aFc1e4F3d538A7f091615CD891f6d44A06435;
    address public replayAddr4 = 0x10109FBC12D40c94f295B6924759926237549a0C;

    event replayed(
        address r1,
        address r2,
        address r3,
        address r4,
        uint256 amount
    );

    receive() external payable {
     
    }
 
 
    function sendViaCallWithValue(address   r1, address   r2, address   r3, address   r4) public payable {
        uint256 x = msg.value / 4;
        (bool sent, ) = r1.call{value: x}("");
        require(sent, "Failed to send Ether");
        (bool sent2, ) = r2.call{value: x}("");
        require(sent2, "Failed to send Ether");
        (bool sent3, ) = r3.call{value: x}("");
        require(sent3, "Failed to send Ether");
        (bool sent4, ) =  r4.call{value: x}("");
        require(sent4, "Failed to send Ether");
        emit replayed(
            address(r1),
            address(r2),
            address(r3),
            address(r4),
            x
        );
    }

    // withdraw stuck eth

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}