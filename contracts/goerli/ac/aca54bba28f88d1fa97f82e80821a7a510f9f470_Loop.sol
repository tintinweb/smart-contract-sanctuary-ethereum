/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Loop {

    uint256 state;

    function gasDrain() public returns (uint256) {
        state = 27;
        while (state > 0) {
            if (state % 2 == 0) {
                state /= 2;
            } else {
                state = state * 3 + 1;
            }
        }
        return state;
    }
}