/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity ^0.5.1;

contract Count {
    address payable owner;
    uint public count;
    event DidCountUp(uint currentCount, address sender);
    event DidCountDown(uint currentCount, address sender);
    event DidAddValue(uint currentCount, uint value, address sender);
    event DidSubValue(uint currentCount, uint value, address sender);
    
    constructor ()
        public
    {
        owner = msg.sender;
    }
    
    function getCount()
        public
        view
        returns(uint)
    {
        return count;
    }
    
    function countUp()
        public
    {
        count += 1;
        emit DidCountUp(count, msg.sender);
    }
    
    function countDown()
        public
    {
        count -= 1;
        emit DidCountDown(count, msg.sender);
    }
    
    function addCount(uint val) 
        public
    {
        count += val;
        emit DidAddValue(count, val, msg.sender);
    }
    
    function subCount(uint val)
        public
    {
        count -= val;
        emit DidSubValue(count, val, msg.sender);
    }
    
    function destroy() 
        public
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

}