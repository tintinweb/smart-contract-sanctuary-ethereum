// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct MultiCall {
    address target;
    bytes callData;
}

library MultiCallOps {
    function copyMulticall(MultiCall memory call)
        internal
        pure
        returns (MultiCall memory)
    {
        return MultiCall({ target: call.target, callData: call.callData });
    }

    function trim(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory trimmed)
    {
        uint256 len = calls.length;

        if (len == 0) return calls;

        uint256 foundLen;
        while (calls[foundLen].target != address(0)) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return calls;
            }
        }

        if (foundLen > 0) return copy(calls, foundLen);
    }

    function copy(MultiCall[] memory calls, uint256 len)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        res = new MultiCall[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        return copy(calls, calls.length);
    }

    function append(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
        res[len] = copyMulticall(newCall);
    }

    function prepend(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        res[0] = copyMulticall(newCall);

        for (uint256 i = 1; i < len + 1; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function concat(MultiCall[] memory calls1, MultiCall[] memory calls2)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len1 = calls1.length;
        uint256 lenTotal = len1 + calls2.length;

        if (lenTotal == calls1.length) return clone(calls1);
        if (lenTotal == calls2.length) return clone(calls2);

        res = new MultiCall[](lenTotal);

        for (uint256 i; i < lenTotal; ) {
            res[i] = (i < len1)
                ? copyMulticall(calls1[i])
                : copyMulticall(calls2[i - len1]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {
    MultiCall
} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";

interface ICreditFacade {
    function botMulticall(address target, bytes calldata _calldata) external;
}

// solhint-disable not-rely-on-time
// solhint-disable no-empty-blocks
contract GearboxCounterExample {
    mapping(address => uint256) lastExecuted;
    mapping(address => uint256) counter;
    address immutable facade;

    constructor(address _facade) {
        facade = _facade;
    }

    function increaseCount(uint256 amount) external {
        counter[msg.sender] += amount;
        lastExecuted[msg.sender] = block.timestamp;
    }

    function checker(address _borrower)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecutedMem = lastExecuted[_borrower];

        canExec = (block.timestamp - lastExecutedMem) > 180;

        execPayload = abi.encodeWithSelector(
            this.incrementCounterViaCreditAccount.selector,
            _borrower
        );
    }

    /// @notice Increments counter with credit account being the msg.sender.
    function incrementCounterViaCreditAccount() external {
        ICreditFacade(facade).botMulticall(
            address(this),
            abi.encodeWithSelector(
                GearboxCounterExample.increaseCount.selector,
                uint256(69)
            )
        );
    }
}