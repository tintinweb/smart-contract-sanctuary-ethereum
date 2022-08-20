// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract SimplifiedLoopedExec {
    // The base amount of percentage function
    uint256 public constant PERCENTAGE_BASE = 1 ether;

    event Start_Initiate();
    event End_Initiate();
    event LogBegin(
        address indexed handler,
        bytes4 indexed selector,
        bytes payload
    );
    event LogEnd(
        address indexed handler,
        bytes4 indexed selector,
        bytes result
    );

    function initiate(address[] calldata tos, bytes[] memory datas) external {
        // emit event to signify that the request was received
        emit Start_Initiate();
        // loop over contract addresses and execute the desired function call
        _execs(tos, datas);
        // emit event to signify end of request on this chain
        emit End_Initiate();
    }

    /**
     * @notice The execution phase.
     * @param tos The handlers of combo.
     * @param datas The combo datas.
     */
    function _execs(address[] memory tos, bytes[] memory datas) internal {
        uint256 counter;

        require(
            tos.length == datas.length,
            "Tos and datas length inconsistent"
        );
        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            bytes memory data = datas[i];
            // Check if the data contains dynamic parameter
            // if (!config.isStatic()) {
            //     // If so, trim the exectution data base on the configuration and stack content
            //     _trim(data, config, localStack, index);
            // }
            // Emit the execution log before call
            bytes4 selector = _getSelector(data);
            emit LogBegin(to, selector, data);

            // Check if the output will be referenced afterwards
            bytes memory result = _exec(to, data, counter);
            counter++;

            // Emit the execution log after call
            emit LogEnd(to, selector, result);

            // if (config.isReferenced()) {
            //     // If so, parse the output and place it into local stack
            //     uint256 num = config.getReturnNum();
            //     uint256 newIndex = _parse(localStack, result, index);
            //     require(
            //         newIndex == index + num,
            //         "Return num and parsed return num not matched"
            //     );
            //     index = newIndex;
            // }

            // Setup the process to be triggered in the post-process phase
            // _setPostProcess(to);
        }
    }

    /// @notice Get payload function selector.
    function _getSelector(bytes memory payload)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            payload[0] |
            (bytes4(payload[1]) >> 8) |
            (bytes4(payload[2]) >> 16) |
            (bytes4(payload[3]) >> 24);
    }

    /**
     * @notice Parse the return data to the local stack.
     * @param localStack The local stack to place the return values.
     * @param ret The return data.
     * @param index The current tail.
     */
    function _parse(
        bytes32[256] memory localStack,
        bytes memory ret,
        uint256 index
    ) internal pure returns (uint256 newIndex) {
        uint256 len = ret.length;
        // The return value should be multiple of 32-bytes to be parsed.
        require(len % 32 == 0, "illegal length for _parse");
        // Estimate the tail after the process.
        newIndex = index + len / 32;
        require(newIndex <= 256, "stack overflow");
        assembly {
            let offset := shl(5, index)
            // Store the data into localStack
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(localStack, add(i, offset)),
                    mload(add(add(ret, i), 0x20))
                )
            }
        }
    }

    /**
     * @notice The execution of a single cube.
     * @param _to The handler of cube.
     * @param _data The cube execution data.
     * @param _counter The current counter of the cube.
     */
    function _exec(
        address _to,
        bytes memory _data,
        uint256 _counter
    ) internal returns (bytes memory result) {
        // require(_isValidHandler(_to), "Invalid handler");
        bool success;
        assembly {
            success := delegatecall(
                sub(gas(), 5000),
                _to,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            result := mload(0x40)
            mstore(
                0x40,
                add(result, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(result, size)
            returndatacopy(add(result, 0x20), 0, size)
        }

        if (!success) {
            if (result.length < 68) revert("_exec");
            assembly {
                result := add(result, 0x04)
            }

            if (_counter == type(uint256).max) {
                revert(abi.decode(result, (string))); // Don't prepend counter
            } else {
                revert(
                    string(
                        abi.encodePacked(
                            _counter,
                            "_",
                            abi.decode(result, (string))
                        )
                    )
                );
            }
        }
    }
}