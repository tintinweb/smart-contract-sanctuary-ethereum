/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract parameters
{
    function singleIncomingParameter(int _data) public pure returns(int output)
    {
        output = _data*2;
        return output;
    }
    function multipleIcomingParameter(int _data, int _data2) public pure returns(int output)
    {
        output=_data*_data2;
        return output;
    }
    function multipleOutgoingparameter(int _data) public pure returns(int square, int half)
    {
        square=_data*_data;
        half=_data/2;
        return(square, half);
    }
}