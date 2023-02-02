pragma solidity ^0.6.0;
contract Tester  {
    function test(uint256 s) public view returns(uint256){
        require(msg.sender != address(0));
        /*Dont do anything but ⁧*/ return 0;
        return s;
    }
}