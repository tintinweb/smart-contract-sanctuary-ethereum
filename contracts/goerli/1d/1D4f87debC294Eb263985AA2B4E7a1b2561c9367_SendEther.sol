/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// File: transfer.sol


pragma solidity ^0.8.0;

contract SendEther {
    constructor() payable{}

    function transferEth(address payable _to, uint256 _value) external payable {
        _to.transfer(_value);
    }

    function transferEthToMulti(
        address payable[] calldata _to, 
        uint256 _value
    ) external payable {
        for (uint8 i = 0; i < _to.length; i++) {
            _to[i].transfer(_value);
        }
    }
        

}