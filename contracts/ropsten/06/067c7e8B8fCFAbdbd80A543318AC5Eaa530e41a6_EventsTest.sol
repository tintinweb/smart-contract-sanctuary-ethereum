/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity >=0.7.0 <0.9.0;

contract EventsTest {

    event MyEvent (
        uint value
    );

    function doStuff(uint val) external {
        emit MyEvent(val);
    }
}