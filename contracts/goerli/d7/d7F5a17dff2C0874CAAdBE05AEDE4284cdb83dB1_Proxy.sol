// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../abstract/Admin.sol";

contract Proxy is Admin {
    /// @dev Implementation contract address
    address public implementation;

    /// @dev Contract name
    string public CONTRACT_NAME;

    constructor(string memory _contractName) {
        admin = msg.sender;
        CONTRACT_NAME = _contractName;
    }

    /// @dev Set Implementation contract address
    function setImplementation(address _imp) external onlyAdmin {
        implementation = _imp;
    }

    /// @dev Delegate contract call
    function _delegate(address _imp) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}

    fallback() external payable {
        _delegate(implementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Admin {

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    // Admin Address
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    function setAdmin(address adminAddress) external onlyAdmin {
        require(adminAddress != ZERO_ADDRESS, "Admin: Cannot set to Zero Address");
        admin = adminAddress;
    }
}