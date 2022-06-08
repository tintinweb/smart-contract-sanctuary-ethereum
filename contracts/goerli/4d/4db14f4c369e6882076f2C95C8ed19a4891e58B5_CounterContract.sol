pragma solidity ^0.6.6;
contract CounterContract {    
    uint256 public _counter;
    
    event Counted(uint256 _counter);
    function countMe() public {
        _counter++;
        emit Counted(_counter);
    }
    function currentCount() public view returns(uint256) {
        return _counter;
    }
}