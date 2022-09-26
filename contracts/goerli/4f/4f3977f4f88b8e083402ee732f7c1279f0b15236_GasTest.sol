/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.8.17;

contract GasTest {
    event Yo(uint256 gasLeft);

    function foo1() external {
        uint256 g;
        assembly {
            g := gas()
            sstore(timestamp(), 1)
            pop(sload(timestamp()))
            g := sub(g, gas())
        }
        emit Yo(g);
    }

    function foo2() external {
        uint256 g;
        assembly {
            g := gas()
            pop(sload(timestamp()))
            g := sub(g, gas())
        }
        emit Yo(g);
    }

    function foo3() external {
        uint256 g;
        assembly {
            g := gas()
            pop(sload(timestamp()))
            pop(sload(timestamp()))
            g := sub(g, gas())
        }
        emit Yo(g);
    }
}