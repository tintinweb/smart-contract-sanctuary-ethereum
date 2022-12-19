// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ====================================================================
// ======================= Transfer Approver ======================
// ====================================================================

// Primary Author(s)
// Che Jin: https://github.com/topdev104

/**
 * @title Sweep Transfer Approver
 * @dev Allows accounts to be whitelisted by admin role
 */
contract TransferApproverWhitelist {
    address public admin;
    mapping(address => bool) internal whitelisted;

    event Whitelisted(address indexed _account);
    event UnWhitelisted(address indexed _account);
    event AdminChanged(address indexed _newAdmin);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _adminAddress) {
        admin = _adminAddress;
    }

    /**
     * @dev Throws if called by any account other than admin
     */
    modifier onlyAdmin {
        require(
            msg.sender == admin,
            "Caller is not admin"
        );
        _;
    }

    /**
    * @notice Returns token transferability
    * @param _from sender address
    * @param _to beneficiary address
    * @return (bool) true - allowance, false - denial
    */
    function checkTransfer(address _from, address _to) external view returns (bool) {
        if (_from == address(0) || _to == address(0)) return true;

        return whitelisted[_to] ? true : false;
    }

    /**
     * @dev Checks if account is whitelisted
     * @param _account The address to check
     */
    function isWhitelisted(address _account) external view returns (bool) {
        return whitelisted[_account];
    }

    /**
     * @dev Adds account to whitelist
     * @param _account The address to whitelist
     */
    function whitelist(address _account) external onlyAdmin {
        whitelisted[_account] = true;
        emit Whitelisted(_account);
    }

    /**
     * @dev Removes account from whitelist
     * @param _account The address to remove from the blacklist
     */
    function unWhitelist(address _account) external onlyAdmin {
        whitelisted[_account] = false;
        emit UnWhitelisted(_account);
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        require(
            _newAdmin != address(0),
            "new admin is the zero address"
        );
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }
}