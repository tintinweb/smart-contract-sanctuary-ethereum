/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.8.17;

contract InvalidTest {
    event Yo(uint256 gasLeft);

    function foo1() external {
        try this.explode1() {
            revert('supposed to fail');
        } catch {
            emit Yo(gasleft());
        }
    }

    function foo2() external {
        try this.explode2() {
            revert('supposed to fail');
        } catch {
            emit Yo(gasleft());
        }
    }

    function foo3() external {
        try this.explode3() {
            revert('supposed to fail');
        } catch {
            emit Yo(gasleft());
        }
    }

    function foo4() external {
        try this.explode4() {
            revert('supposed to fail');
        } catch {
            emit Yo(gasleft());
        }
    }

    function foo5() external {
        try this.explode5() {
            revert('supposed to fail');
        } catch {
            emit Yo(gasleft());
        }
    }

    function explode1() external {
        assembly { invalid() }
    }

    function explode2() external {
        address(123).call{value: address(this).balance + 1}("");
        revert();
    }

    function explode3() external {
        assembly {
            pop(call(gas(), 123, balance(address()), 0x00, 0, 0x00, 0))
        }
        revert();
    }

    function explode4() external {
        address(this).staticcall(abi.encodeCall(this.writeState, ()));
        revert();
    }

    function explode5() external {
        revert();
    }

    function writeState() external {
        assembly { sstore(0, add(sload(0), 1)) }
    }
}