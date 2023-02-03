/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

pragma solidity ^0.4.24;

contract Max {
    uint256 public constant UNLIMITED_REBASE = uint256(-1);

    function initLimiterState( uint256 _rebaseLimit) public {
        require(_rebaseLimit <= UNLIMITED_REBASE, "WRONG_REBASE_LIMIT");
    }
}