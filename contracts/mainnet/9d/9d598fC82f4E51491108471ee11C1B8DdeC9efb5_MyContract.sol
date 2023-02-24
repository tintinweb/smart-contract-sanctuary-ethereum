/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

pragma solidity 0.8.9;

library ExternalLib{
    uint private constant  CONST = 1000;

    function getConst() external pure returns (uint){
        return CONST;
    }
}

contract MyContract {
    function getConst() public pure returns (uint){
        return ExternalLib.getConst();
    }
}