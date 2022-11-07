/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract SubscriptionTest {

    uint256 public value;

    event ValueChanged(uint256 _newValue);

    function updateValue(uint256 _newValue) external {
        value = _newValue;
        emit ValueChanged(_newValue);
    }

}