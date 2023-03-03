// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ==========================================================
// ====================== Owned ========================
// ==========================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../Sweep/ISweep.sol";

contract Owned {
    address public sweep_address;
    ISweep public SWEEP;

    // Events
    event SetSweep(address indexed sweep_address);

    // Errors
    error OnlyAdmin();
    error OnlyCollateralAgent();
    error ZeroAddressDetected();

    constructor(address _sweep_address) {
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);
    }

    modifier onlyAdmin() {
        if (msg.sender != SWEEP.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlyCollateralAgent() {
        if (msg.sender != SWEEP.collateral_agency())
            revert OnlyCollateralAgent();
        _;
    }

    /**
     * @notice setSweep
     * @param _sweep_address.
     */
    function setSweep(address _sweep_address) external onlyAdmin {
        if (_sweep_address == address(0)) revert ZeroAddressDetected();
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);

        emit SetSweep(_sweep_address);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSDX(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ====================================================================
// ======================= Transfer Approver ======================
// ====================================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../../Common/Owned.sol";

/**
 * @title Sweep Transfer Approver
 * @dev Allows accounts to be whitelisted by admin role
 */
contract TransferApproverWhitelist is Owned {
    address public admin;
    mapping(address => bool) internal whitelisted;

    event Whitelisted(address indexed _account);
    event UnWhitelisted(address indexed _account);
    event AdminChanged(address indexed _newAdmin);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _sweep) Owned(_sweep) {}

    /**
     * @notice Returns token transferability
     * @param _from sender address
     * @param _to beneficiary address
     * @return (bool) true - allowance, false - denial
     */
    function checkTransfer(address _from, address _to)
        external
        view
        returns (bool)
    {
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
}