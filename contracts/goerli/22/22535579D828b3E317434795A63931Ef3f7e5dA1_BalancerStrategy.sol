// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../../interfaces/IERC20.sol";
import "../../libraries/SafeERC20.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IBalancerVault.sol";

error BalancerStrategy_NotIncurDebtAddress();
error BalancerStrategy_AmountDoesNotMatch();
error BalancerStrategy_LPTokenDoesNotMatch();
error BalancerStrategy_OhmAddressNotFound();

/**
    @title BalancerStrategy
    @notice This contract provides liquidity to balancer on behalf of IncurDebt contract.
 */
contract BalancerStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IVault vault;

    address incurDebtAddress;
    address ohmAddress;

    constructor(
        address _vault,
        address _incurDebtAddress,
        address _ohmAddress
    ) {
        vault = IVault(_vault);
        incurDebtAddress = _incurDebtAddress;
        ohmAddress = _ohmAddress;

        IERC20(ohmAddress).approve(_vault, type(uint256).max);
    }

    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        )
    {
        if (msg.sender != incurDebtAddress) revert BalancerStrategy_NotIncurDebtAddress();
        (
            bytes32 poolId,
            address[] memory assets,
            uint256[] memory maxAmountsIn,
            uint256 minimumBPT,
            bool fromInternalBalance
        ) = abi.decode(_data, (bytes32, address[], uint256[], uint256, bool));

        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == ohmAddress) {
                index = i;
            }
        }

        if (index == type(uint256).max) revert BalancerStrategy_OhmAddressNotFound();
        if (maxAmountsIn[index] != _ohmAmount) revert BalancerStrategy_AmountDoesNotMatch();

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == ohmAddress) {
                IERC20(ohmAddress).safeTransferFrom(incurDebtAddress, address(this), maxAmountsIn[i]);
            } else {
                IERC20(assets[i]).safeTransferFrom(_user, address(this), maxAmountsIn[i]);
                IERC20(assets[i]).approve(address(vault), maxAmountsIn[i]);
            }
        }

        (lpTokenAddress, ) = vault.getPool(poolId);
        uint256 lpBalanceBeforeJoin = IERC20(lpTokenAddress).balanceOf(incurDebtAddress);
        bytes memory userData = abi.encode(1, maxAmountsIn, minimumBPT);

        vault.joinPool(
            poolId,
            address(this),
            incurDebtAddress,
            JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                userData: userData,
                fromInternalBalance: fromInternalBalance
            })
        );

        uint256 lpBalanceAfterJoin = IERC20(lpTokenAddress).balanceOf(incurDebtAddress);
        liquidity = lpBalanceAfterJoin - lpBalanceBeforeJoin;
    }

    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved) {
        if (msg.sender != incurDebtAddress) revert BalancerStrategy_NotIncurDebtAddress();
        (bytes32 poolId, address[] memory assets, uint256[] memory minAmountsOut, bool toInternalBalance) = abi.decode(
            _data,
            (bytes32, address[], uint256[], bool)
        );

        (address lpTokenAddress, ) = vault.getPool(poolId);
        if (_lpTokenAddress != lpTokenAddress) revert BalancerStrategy_LPTokenDoesNotMatch();

        bytes memory userData = abi.encode(1, _liquidity);

        vault.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            ExitPoolRequest({
                assets: assets,
                minAmountsOut: minAmountsOut,
                userData: userData,
                toInternalBalance: toInternalBalance
            })
        );

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == ohmAddress) {
                ohmRecieved = IERC20(ohmAddress).balanceOf(address(this));
                IERC20(ohmAddress).safeTransfer(incurDebtAddress, ohmRecieved);
            } else {
                uint256 balance = IERC20(assets[i]).balanceOf(address(this));
                IERC20(assets[i]).safeTransfer(_user, balance);
            }
        }
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
pragma solidity ^0.8.10;

/**
    @title IStrategy
    @notice This interface is implemented by strategy contracts to provide liquidity on behalf of incurdebt contract.
 */
interface IStrategy {
    /**
        @notice Add liquidity to the dex using this strategy.
        @dev Some strategies like uniswap will have tokens left over which is either sent back to 
        incur debt contract (OHM) or back to LPer's wallet address (pair token). Other strategies like
        curve will have no leftover tokens.
        This function is also only for LPing for pools with two tokens. Do not use this for pools with more than 2 tokens.
        @param _data Data needed to input into external call to add liquidity. Different for different strategies.
        @param _ohmAmount amount of OHM to LP 
        @param _user address of user that called incur debt function to do this operation.
        @return liquidity : total amount of lp tokens gained.
        ohmUnused : total amount of ohm unused in LP process and sent back to incur debt address.
        lpTokenAddress : address of LP token gained.
    */
    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        );

    /**
        @notice Remove liquidity to the dex using this strategy.
        @param _data Data needed to input into external call to remove liquidity. Different for different strategies.
        @param _liquidity amount of LP tokens to remove liquidity from.
        @param _lpTokenAddress address of LP token to remove.
        @param _user address of user that called incur debt function to do this operation.
        @return ohmRecieved : total amount of ohm recieved from removing the LP. Send back to incurdebt contract.
    */
    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved);
}

pragma solidity ^0.8.10;

interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPool(bytes32 poolId) external view returns (address, uint8);
}

struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);

    event PoolCreated(address indexed pool);
}

interface IWeightedPool {
    function getPoolId() external returns (bytes32);
}