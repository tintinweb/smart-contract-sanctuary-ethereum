/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity >=0.8.4;

contract AddCal {
    uint256 a=0;
    uint256 b=0;
    uint256 c=0;
    function giveInputs(uint256 x, uint256 y) public {
        a=x;
        b=y;
        c=a+b;
    }
    function giveAns() public view returns(uint256)
    {
        return c;
    }
}