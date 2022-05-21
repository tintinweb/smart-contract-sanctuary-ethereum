// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILogics.sol";
import "./ILogicsMiddleware.sol";
import "./Middleware.sol";

contract LogicsMiddleware is ILogicsMiddleware, Middleware {

    /**
     * @notice Initialize basic functions
     * @param setup A setup contract address with basic functions implementations
     */
    constructor(address setup) {
        require(setup != address(0x00), "Logics Middleware: Empty setup address");
        _initializationOwnerAddress = msg.sender;

        _methodsImplementations[ILogics(address(0x00)).setMsg_.selector] = setup;
        _methodsImplementations[ILogics(address(0x00)).getMsg_.selector] = setup;
    }


    function setMsg(bytes32 message) external override {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSelector(ILogics(address(0x00)).setMsg_.selector, message));
    }

    function getMsg() external override view returns (bytes32 message) {
        message;
        bytes memory data = abi.encode(ILogics(address(0x00)).getMsg_.selector);
        // ERC20Interface staticcalls himself so balanceOf_ won't be found and will be executed via delegatecall to implementation
        // If we will make implementation have balanceOf, not balanceOf_, then it will create a cycle in proxies:
        // main proxy receives balanceOf, delegates to interface with balanceOf, interface staticcalls proxy balanceOf and its looped
        _staticCall(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyStorage {
    address internal _initializationOwnerAddress;
    address internal _middlewareAddress;
    mapping(bytes4 => address) internal _methodsImplementations;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyStorage.sol";

contract Middleware is ProxyStorage {
    error UnknownMethod();

    // solhint-disable-next-line comprehensive-interface
    receive() external payable virtual {}

    // solhint-disable-next-line comprehensive-interface
    fallback() external payable {
        _delegateCall();
    }

    function _delegateCall() internal {
        address impl = _methodsImplementations[msg.sig];
        if (impl == address(0x00)) revert UnknownMethod();

        assembly {
            let p := mload(0x40)
            calldatacopy(p, 0x00, calldatasize())
            let result := delegatecall(gas(), impl, p, calldatasize(), 0x00, 0x00)
            let size := returndatasize()
            returndatacopy(p, 0x00, size)

            switch result
            case 0x00 {
                revert(p, size)
            }
            default {
                return(p, size)
            }
        }
    }

    function _staticCall(bytes memory payload) internal view {
        (bool result, bytes memory data) = address(this).staticcall(payload);

        assembly {
            switch result
            case 0x00 {
                revert(add(data, 32), returndatasize())
            }
            default {
                return(add(data, 32), returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILogicsMiddleware {
    function setMsg(bytes32 message) external;
    function getMsg() external view returns (bytes32 message);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILogics {
    function setMsg_(bytes32 message) external;
    function getMsg_() external view returns (bytes32 message);
}