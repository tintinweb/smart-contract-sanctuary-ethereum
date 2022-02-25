/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File contracts/interfaces/IERC20.sol
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


// File contracts/libraries/SafeERC20.sol
pragma solidity >=0.7.5;

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


// File contracts/interfaces/ITreasury.sol
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


// File contracts/interfaces/IUniswapV2Router.sol
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


// File contracts/interfaces/IOlympusAuthority.sol
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


// File contracts/types/OlympusAccessControlled.sol
pragma solidity >=0.7.5;

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


// File contracts/migration/GelatoLiquidityMigrator.sol

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;


interface IGUniRouter {
    function addLiquidity(
        address pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external;
}

contract GelatoOHMFRAXLiquidityMigrator is OlympusAccessControlled {
    using SafeERC20 for IERC20;

    // GUni Router
    IGUniRouter internal immutable gUniRouter = IGUniRouter(0x513E0a261af2D33B46F98b81FED547608fA2a03d);

    // Olympus Treasury
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef);

    // Uniswap Router
    IUniswapV2Router internal immutable router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal immutable OHMFRAXGUniPool = 0x61a0C8d4945A61bF26c13e07c30AF1f1ca67b473;
    address internal immutable OHMFRAXLP = 0xB612c37688861f1f90761DC7F382C2aF3a50Cc39;
    address internal immutable OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    address internal immutable FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

    /**
     * @notice Removes liquidity from OHM/FRAX LP, then adds liquidty to
     * OHM/FRAX GUni
     */
    function moveLiquidity(
        uint256 _amountOHMFRAX,
        uint256[2] calldata _minOHMFRAXLP,
        uint256[2] calldata _minOHMFRAXGUni,
        uint256 _deadline
    ) external onlyGuardian {
        // Manage LP from treasury
        treasury.manage(OHMFRAXLP, _amountOHMFRAX);

        // Approve LP to be spent by the uni router
        IERC20(OHMFRAXLP).approve(address(router), _amountOHMFRAX);

        // Remove specified liquidity from OHM/FRAX LP
        (uint256 amountOHM, uint256 amountFRAX) = router.removeLiquidity(
            OHM,
            FRAX,
            _amountOHMFRAX,
            _minOHMFRAXLP[0],
            _minOHMFRAXLP[1],
            address(this),
            _deadline
        );

        // Approve Balancer vault to spend tokens
        IERC20(OHM).approve(address(gUniRouter), amountOHM);
        IERC20(FRAX).approve(address(gUniRouter), amountFRAX);

        gUniRouter.addLiquidity(OHMFRAXGUniPool, amountOHM, amountFRAX, _minOHMFRAXGUni[0], _minOHMFRAXGUni[1], address(treasury));

        // Send any leftover OHM back to guardian and FRAX to treasury
        IERC20(OHM).safeTransfer(authority.guardian(), IERC20(OHM).balanceOf(address(this)));
        IERC20(FRAX).safeTransfer(address(treasury), IERC20(FRAX).balanceOf(address(this)));
    }
}