//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

contract BatchCall {
    struct Call {
        address target;
        uint256 value;
        bytes input;
    }

    function batchCall(Call[] memory calls) external payable returns (bytes[] memory ret) {
        ret = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            require(calls[i].target != address(0), "invalid address");
            // solhint-disable avoid-low-level-calls
            (bool success, bytes memory returndata) = calls[i].target.call{value: calls[i].value}(calls[i].input);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable reason-string
                if (returndata.length < 68) revert();
                // solhint-disable no-inline-assembly
                assembly {
                    returndata := add(returndata, 0x04)
                }
                revert(abi.decode(returndata, (string)));
            }
            ret[i] = returndata;
        }
    }
}