// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IOlympusAuthority.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IOHM.sol";
import "../interfaces/IsOHM.sol";
import "../types/OlympusAccessControlled.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";

contract LiquidityMigrator is OlympusAccessControlled {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ITreasury internal immutable oldTreasury = ITreasury(0x31F8Cc382c9898b273eff4e0b7626a6987C846E8);
    ITreasury internal immutable newTreasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);
    IOHM internal immutable oldOHM = IOHM(0x383518188C0C6d7730D91b2c03a03C837814a899);
    IERC20 internal immutable newOHM = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);
    IsOHM internal immutable oldsohm = IsOHM(0x04F2694C8fcee23e8Fd0dfEA1d4f5Bb8c352111F);
    IsOHM internal immutable newsohm = IsOHM(0x04906695D6D12CF5459975d7C3C03356E4Ccd460);

    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

    function remove(
        uint256 amount,
        IERC20 pair,
        IUniswapV2Router router,
        IERC20 token,
        uint256 minToken,
        uint256 minOhm,
        uint256 deadline
    ) external onlyGovernor {
        // Fetch the treasury balance of the given liquidity pair
        uint256 max = pair.balanceOf(address(oldTreasury));
        uint256 lpAmount = amount < max ? amount : max;
        oldTreasury.manage(address(pair), lpAmount);

        // Remove the liquidity
        pair.approve(address(router), lpAmount);
        router.removeLiquidity(
            address(token),
            address(oldOHM),
            lpAmount,
            minToken,
            minOhm,
            address(this),
            deadline
        );
        
        // deposit the paired token into the new treasury
        uint256 amountToken = token.balanceOf(address(this));
        token.approve(address(newTreasury), amountToken);
        newTreasury.deposit(amountToken, address(token), newTreasury.tokenValue(address(token), amountToken));

        // burn the OHM
        oldOHM.burn(oldOHM.balanceOf(address(this)));
    }

    function migrate(
        uint256 amount,
        IERC20 pair,
        IUniswapV2Router router,
        IERC20 token,
        uint256 minToken,
        uint256 minOhm,
        uint256 deadline
    ) external onlyGovernor {
        // Fetch the treasury balance of the given liquidity pair
        uint256 max = pair.balanceOf(address(oldTreasury));
        uint256 lpAmount = amount < max ? amount : max;
        oldTreasury.manage(address(pair), lpAmount);

        // Remove the liquidity
        pair.approve(address(router), lpAmount);
        router.removeLiquidity(
            address(token),
            address(oldOHM),
            lpAmount,
            minToken,
            minOhm,
            address(this),
            deadline
        );
        
        // deposit the paired token into the new treasury
        uint256 amountToken = token.balanceOf(address(this));

        // burn the old OHM
        uint256 amountOld = oldOHM.balanceOf(address(this));
        oldOHM.burn(amountOld);

        // mint new OHM after converting to new supply
        uint256 amountNew = amountOld.mul(newsohm.index()).div(oldsohm.index());
        newTreasury.mint(address(this), amountNew);

        newOHM.approve(address(router), amountNew);
        token.approve(address(router), amountToken);

        router.addLiquidity(
            address(token), 
            address(newOHM), 
            amountToken, 
            amountNew, 
            amountToken * 99 / 100, 
            amountNew * 99 / 100, 
            address(newTreasury), 
            deadline
        );
    }
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

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
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

import "./IERC20.sol";

interface IOHM is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IsOHM is IERC20 {
    function rebase(uint256 ohmProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
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
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}