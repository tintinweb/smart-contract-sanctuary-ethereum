/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity  >=0.7.0 <0.9.0;

contract my_test
{
    uint256 m_int;
    function set_int(uint256 v_int) public
    {
        m_int = v_int;
    }

    function get_int() public returns(uint256)
    {
        return m_int;
    }
}