// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;
import {GelatoBytes} from "./gelato/GelatoBytes.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface ISequencer {
    struct WorkableJob {
        address job;
        bool canWork;
        bytes args;
    }

    function getNextJobs(
        bytes32 network,
        uint256 startIndex,
        uint256 endIndexExcl
    ) external returns (WorkableJob[] memory);

    function numJobs() external view returns (uint256);
}

interface IJob {
    function work(bytes32 network, bytes calldata args) external;

    function workable(bytes32 network)
        external
        returns (bool canWork, bytes memory args);
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines
    function checker(
        address _sequencer,
        bytes32 _network,
        uint256 _startIndex,
        uint256 _endIndex
    ) external returns (bool, bytes memory) {
        ISequencer sequencer = ISequencer(_sequencer);
        uint256 numJobs = sequencer.numJobs();

        if (numJobs == 0)
            return (false, bytes("GelatoMakerJob: No jobs listed"));
        if (_startIndex >= numJobs) {
            bytes memory msg1 = bytes.concat(
                "GelatoMakerJob: Only jobs available up to index ",
                bytes(Strings.toString(numJobs - 1))
            );

            bytes memory msg2 = bytes.concat(
                ", inputted startIndex is ",
                bytes(Strings.toString(_startIndex))
            );
            return (false, bytes.concat(msg1, msg2));
        }

        uint256 endIndex = _endIndex > numJobs ? numJobs : _endIndex;

        ISequencer.WorkableJob[] memory jobs = ISequencer(_sequencer)
            .getNextJobs(_network, _startIndex, endIndex);

        uint256 numWorkable;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) numWorkable++;
        }

        if (numWorkable == 0)
            return (false, bytes("GelatoMakerJob: No workable jobs"));

        address[] memory tos = new address[](numWorkable);
        bytes[] memory datas = new bytes[](numWorkable);

        uint256 wIndex;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) {
                tos[wIndex] = jobs[i].job;
                datas[wIndex] = abi.encodeWithSelector(
                    IJob.work.selector,
                    _network,
                    jobs[i].args
                );
                wIndex++;
            }
        }

        bytes memory execPayload = abi.encodeWithSelector(
            this.doJobs.selector,
            tos,
            datas
        );

        return (true, execPayload);
    }

    function doJobs(address[] calldata _tos, bytes[] calldata _datas) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");
        require(
            _tos.length == _datas.length,
            "GelatoMakerJob: Length mismatch"
        );

        for (uint256 i; i < _tos.length; i++) {
            _doJob(_tos[i], _datas[i]);
        }
    }

    function _doJob(address _to, bytes memory _data) private {
        (bool success, bytes memory returnData) = _to.call(_data);
        if (!success) returnData.revertWithError("GelatoMakerJob: ");
    }
}

// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}