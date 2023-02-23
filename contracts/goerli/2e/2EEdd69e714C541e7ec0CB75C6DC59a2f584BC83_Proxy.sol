// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

contract Proxy {
    // EIP1967
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 private constant adminPosition = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // EIP1967
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 private constant implementationPosition =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // EIP1967
    event AdminChanged(address previousAdmin, address newAdmin);
    event Upgraded(address indexed implementation);

    constructor(address _implementation) {
        _setAdmin(address(0), msg.sender);
        setImplementation(_implementation);
    }

    function implementation() public view returns (address _implementation) {
        assembly {
            _implementation := sload(implementationPosition)
        }
    }

    function setImplementation(address _implementation) public {
        require(msg.sender == admin(), 'PX00');
        require(_implementation != implementation(), 'PX01');
        require(_implementation != address(0), 'PX02');

        assembly {
            sstore(implementationPosition, _implementation)
        }

        emit Upgraded(_implementation);
    }

    function admin() public view returns (address _admin) {
        assembly {
            _admin := sload(adminPosition)
        }
    }

    function setAdmin(address _admin) external {
        address currentAdmin = admin();
        require(msg.sender == currentAdmin, 'PX00');
        require(_admin != currentAdmin, 'PX01');
        require(_admin != address(0), 'PX02');

        _setAdmin(currentAdmin, _admin);
    }

    function _setAdmin(address currentAdmin, address newAdmin) internal {
        assembly {
            sstore(adminPosition, newAdmin)
        }

        emit AdminChanged(currentAdmin, newAdmin);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        address _implementation = implementation();

        assembly {
            // Copy msg.data.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}