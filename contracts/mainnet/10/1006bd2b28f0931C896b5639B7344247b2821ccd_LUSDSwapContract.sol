// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../libraries/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/ITreasuryV1.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IOlympusAuthority.sol";

import "../types/OlympusAccessControlled.sol";

interface ICurveFactory {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

/// @title   LUSD Swap Contract
/// @notice  Swaps LUSD from treasury v1 to DAI then sends to treasury v2
/// @author  JeffX
contract LUSDSwapContract is OlympusAccessControlled {
    using SafeERC20 for IERC20;

    /// ERRORS ///

    /// @notice Error for if more DAI than 1:1 backing is attempted to be sent
    error OverOHMV1Backing();

    /// STATE VARIABLES ///

    /// @notice Curve Factory
    ICurveFactory internal immutable curveFactory = ICurveFactory(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    /// @notice Olympus Treasury V1
    ITreasuryV1 internal immutable treasuryV1 = ITreasuryV1(0x31F8Cc382c9898b273eff4e0b7626a6987C846E8);
    /// @notice Olympus Treasury V2
    ITreasury internal immutable treasuryV2 = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    /// @notice Olympus Token V1
    IERC20 internal immutable OHMV1 = IERC20(0x383518188C0C6d7730D91b2c03a03C837814a899);
    /// @notice LUSD
    address internal immutable LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    /// @notice DAI
    address internal immutable DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /// @notice Remaining amount of DAI to have each OHM V1 backed by 1 DAI;
    uint256 public OHMV1BackingInDAIRemaining;

    /// CONSTRUCTOR ///

    /// @param _authority  Address of the Olympus Authority contract
    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {
        OHMV1BackingInDAIRemaining = OHMV1.totalSupply() * 1e9;
    }

    /// POLICY FUNCTIONS ///

    /// @notice                        Manages LUSD from treasury V1 and swaps for LUSD
    /// @param _amountLUSD             Amount of LUSD that will be managed from treasury V1 and swapped
    /// @param _minAmountDAI           Minimum amount of DAI to receive
    /// @param _amountDAIToV1Treasury  Amount of DAI that was received from swap to be sent to V1 treasury
    function swapLUSDForDAI(
        uint256 _amountLUSD,
        uint256 _minAmountDAI,
        uint256 _amountDAIToV1Treasury
    ) external onlyGuardian {
        // Manage LUSD from v1 treasury
        treasuryV1.manage(LUSD, _amountLUSD);

        // Approve LUSD to be spent by the  Curve pool
        IERC20(LUSD).approve(address(curveFactory), _amountLUSD);

        // Swap specified LUSD for DAI
        uint256 daiReceived = curveFactory.exchange_underlying(0, 1, _amountLUSD, _minAmountDAI);

        if (_amountDAIToV1Treasury > 0) {
            if (OHMV1BackingInDAIRemaining < _amountDAIToV1Treasury) revert OverOHMV1Backing();
            IERC20(DAI).safeTransfer(address(treasuryV1), _amountDAIToV1Treasury);
            OHMV1BackingInDAIRemaining -= _amountDAIToV1Treasury;
            daiReceived -= _amountDAIToV1Treasury;
        }

        IERC20(DAI).approve(address(treasuryV2), daiReceived);

        // Deposit DAI into v2 treasury, all as profit
        treasuryV2.deposit(daiReceived, DAI, treasuryV2.tokenValue(DAI, daiReceived));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasuryV1 {
    function withdraw(uint256 amount, address token) external;

    function manage(address token, uint256 amount) external;

    function valueOf(address token, uint256 amount) external view returns (uint256);

    function excessReserves() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}