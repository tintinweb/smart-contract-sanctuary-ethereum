/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity ^0.8.0;

contract Test {
    uint public count;
    event Received(address, uint);

    function testGas() public {
        count = count + 1;
        uint256 fee = block.basefee * 2 / 100;
        (bool success, ) = address(msg.sender).call{value: fee}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}