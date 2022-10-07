/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract External{
    uint public x;
    error Low(string);

    function setX(uint _x) external {
        // revert("abc");
        // require(0 > 1, "abc");
        revert Low("abc");
        x = _x;
    }

    function setXInternal(uint _x) external {
        // this.setX(_x);
        (bool _success, ) = address(this).call(abi.encodeWithSelector(this.setX.selector, _x));
        require(_success, "failed");
    }

}