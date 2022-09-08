// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility

function _call(
    address _add,
    bytes memory _data,
    uint256 _value,
    bool _revertOnFailure,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.call{value: _value}(_data);

    if (!success && _revertOnFailure)
        GelatoBytes.revertWithError(returnData, _tracingInfo);
}

function _delegateCall(
    address _add,
    bytes memory _data,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.delegatecall(_data);

    if (!success) GelatoBytes.revertWithError(returnData, _tracingInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxy {
    /**
     * @notice Emitted when proxy calls a contract successfully in `executeCall`
     *
     * @param target Address of contract that is called
     * @param data Data used in the call.
     * @param value Native token value used in the call.
     * @param returnData Data returned by the call.
     */
    event ExecuteCall(
        address indexed target,
        bytes data,
        uint256 value,
        bytes returnData
    );

    /**
     * @notice Multicall to different contracts with different datas.
     *
     * @param targets Addresses of contracts to be called.
     * @param datas Datas for each contract call.
     * @param values Native token value for each contract call.
     */
    function batchExecuteCall(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values
    ) external payable;

    /**
     * @notice Call to a single contract.
     *
     * @param target Address of contracts to be called.
     * @param data Data for contract call.
     * @param value Native token value for contract call.
     */
    function executeCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external payable;

    /**
     * @return address Ops smart contract address
     */
    function ops() external view returns (address);

    /**
     * @return address Owner of the proxy
     */
    function owner() external view returns (address);

    /**
     * @return uint256 version of OpsProxy.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Proxied} from "../vendor/proxy/EIP173/Proxied.sol";
import {_call} from "../functions/FExec.sol";
import {IOpsProxy} from "../interfaces/IOpsProxy.sol";

contract OpsProxy is Proxied, IOpsProxy {
    // solhint-disable const-name-snakecase
    uint256 public constant override version = 1;
    address public immutable override ops;

    modifier onlyAuth() {
        address proxyOwner = owner();
        if (msg.sender != proxyOwner) {
            require(msg.sender == ops, "OpsProxy: Not authorised");
            require(
                _getTaskCreator() == proxyOwner,
                "OpsProxy: Only tasks created by owner"
            );
        } // else msg.sender == proxyOwner
        _;
    }

    // solhint-disable no-empty-blocks
    constructor(address _ops) {
        ops = _ops;
    }

    receive() external payable {}

    ///@inheritdoc IOpsProxy
    function batchExecuteCall(
        address[] calldata _targets,
        bytes[] calldata _datas,
        uint256[] calldata _values
    ) external payable override onlyAuth {
        uint256 length = _targets.length;
        require(
            length == _datas.length && length == _values.length,
            "OpsProxy: Length mismatch"
        );

        for (uint256 i; i < length; i++)
            _executeCall(_targets[i], _datas[i], _values[i]);
    }

    ///@inheritdoc IOpsProxy
    function executeCall(
        address _target,
        bytes calldata _data,
        uint256 _value
    ) external payable override onlyAuth {
        _executeCall(_target, _data, _value);
    }

    function owner() public view returns (address) {
        return _proxyAdmin();
    }

    function _executeCall(
        address _target,
        bytes calldata _data,
        uint256 _value
    ) private {
        (, bytes memory returnData) = _call(
            _target,
            _data,
            _value,
            true,
            "OpsProxy.executeCall: "
        );

        emit ExecuteCall(_target, _data, _value, returnData);
    }

    function _getTaskCreator() private pure returns (address taskCreator) {
        assembly {
            taskCreator := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}