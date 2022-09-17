/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;


contract FrameMultipleChoices{

    mapping(uint256 => address) _choices;

    function choice1() external view returns(address c1){
        return _choices[0];
    }

    function choice2() external view returns(address c2){
        return _choices[1];
    }

    function choice3() external view returns(address c3){
        return _choices[2];
    }

    function setChoices(address c1, address c2, address c3) external{
        _choices[0] = c1;
        _choices[1] = c2;
        _choices[2] = c3;
    }

}