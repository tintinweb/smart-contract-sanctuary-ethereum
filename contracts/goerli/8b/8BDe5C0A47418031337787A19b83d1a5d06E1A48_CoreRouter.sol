// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract CoreRouter {
    address payable private immutable _this;
    address private _admin;
    address private _core;

    event SetRouterAdmin(address admin);
    event SetCore(address core);

    modifier onlyAdmin() {
        require(_admin == msg.sender, "Caller is not an admin.");
        _;
    }

    constructor(address core) {
        _admin = msg.sender;
        _core = core;
        _this = payable(address(this));
    }

    /// @notice Changes the admin of the router.
    /// @param admin Address of the new admin.
    function setRouterAdmin(address admin) external onlyAdmin {
        _admin = admin;
        emit SetRouterAdmin(admin);
    }

    /// @notice Returns an admin address of the router.
    /// @return Address of the current admin.
    function getRouterAdmin() external view returns (address) {
        return _admin;
    }

    /// @notice Changes the address of the core contract.
    ///     Note: Changing the core address will affect to all wallets.
    /// @param core Address of the new core contract.
    function setCore(address core) external onlyAdmin {
        _core = core;
        emit SetCore(core);
    }

    /// @notice Returns the address of the core contract.
    /// @return Address of the current core contract.
    function getCore() external view returns (address) {
        return _core;
    }

    /// @notice Delegates all transcations to the core contract.
    fallback() external payable {
        address core = CoreRouter(_this).getCore();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), core, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}