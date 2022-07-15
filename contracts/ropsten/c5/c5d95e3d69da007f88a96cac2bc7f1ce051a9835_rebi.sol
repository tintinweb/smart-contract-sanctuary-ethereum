/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity ^0.4.0;

contract rebi{
    mapping(address => uint256) public balanceOf;
    function mytoken(uint256 _supply) public {
        if(_supply ==0)_supply = 10000;
        balanceOf[tx.origin] = _supply;
    }

    function transfer(address _to,uint _value) public {
        if(balanceOf[tx.origin] < _value) return;
        if(balanceOf[_to]+_value < balanceOf[_to]) return;
        balanceOf[tx.origin] -= _value;
        balanceOf[_to] += _value;
    }
}