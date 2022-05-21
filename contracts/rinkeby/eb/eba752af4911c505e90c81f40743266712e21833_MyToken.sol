/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.0;
contract MyToken{
    mapping (address => uint256) public balanceOf;
    function Mytoken(uint256 _supply) public {
        if (_supply ==0)_supply =10000;
        balanceOf[tx.origin] = _supply;
    }
    function transfer(address _to,uint256 _value)public {
        if (balanceOf[tx.origin] < _value) return;
        if (balanceOf[_to] + _value < balanceOf[_to]) return;
        
        balanceOf[tx.origin] -= _value;
        balanceOf[_to] += _value;
    }
}