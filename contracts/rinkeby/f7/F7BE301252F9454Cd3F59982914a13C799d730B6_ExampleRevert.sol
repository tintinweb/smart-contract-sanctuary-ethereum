/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

pragma solidity 0.8.7;

contract ExampleRevert{
 uint256 constant INIT=0;
    function release()public pure{
        require(INIT>0,"Revert error message from SC");
    }

}