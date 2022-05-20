/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract mintTools {

    function _recall(address _target, uint256 _etherSpend, bytes memory _data) public  {
        _target.call{value:_etherSpend}(_data);
    }

    function recall(address _target, uint256 _eachTimeEtherSpend, bytes memory _data, uint256 _times)payable  public  {

        require(msg.value >= _eachTimeEtherSpend * _times,"NO_ENOUGH_FUND");
        require(_data.length >= _times,"NO_ENOUGH_DATA");

        for(uint256 i = 0; i < _times; i++){
            _recall(_target, _eachTimeEtherSpend, _data);
        }
        
    }

}