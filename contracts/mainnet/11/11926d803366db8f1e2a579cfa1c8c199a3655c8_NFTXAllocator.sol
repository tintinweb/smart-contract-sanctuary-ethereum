// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/INFTXInventoryStaking.sol";
import "../interfaces/INFTXLPStaking.sol";

import "../interfaces/allocators/IAllocator.sol";

import "../types/FloorAccessControlled.sol";


/**
 * Contract deploys reserves from treasury into NFTX vaults,
 * earning interest and rewards.
 */

contract NFTXAllocator is IAllocator, FloorAccessControlled {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @notice describes the token used for staking in NFTX.
     */

    struct stakingTokenData {
        uint256 vaultId;
        address rewardToken;
        bool isLiquidityPool;
        bool exists;
    }

    event TreasuryAssetDeployed(address token, uint256 amount, uint256 value);
    event TreasuryAssetReturned(address token, uint256 amount, uint256 value);

    // NFTX Inventory Staking contract
    INFTXInventoryStaking internal immutable inventoryStaking;

    // NFTX Liquidity Staking contract
    INFTXLPStaking internal immutable liquidityStaking;

    // Floor Treasury contract
    ITreasury internal immutable treasury;

    // Corresponding NFTX token vault data for tokens
    mapping (address => stakingTokenData) public stakingTokenInfo;

    // Corresponding xTokens for tokens
    mapping (address => address) public dividendTokenMapping;


    /**
     * @notice initialises the construct with no additional logic.
     */

    constructor (
        address _authority,
        address _inventoryStaking,
        address _liquidityStaking,
        address _treasury
    ) FloorAccessControlled(IFloorAuthority(_authority)) {
        inventoryStaking = INFTXInventoryStaking(_inventoryStaking);
        liquidityStaking = INFTXLPStaking(_liquidityStaking);

        treasury = ITreasury(_treasury);
    }


    /**
     * Deprecated in favour of harvestAll(address _token).
     */

    function harvest(address _token, uint256 _amount) external override {
        revert("Method is deprecated in favour of harvestAll(address _token)");
    }


    /**
     * @notice claims rewards from the vault.
     */

    function harvestAll(address _token) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];

        // We only want to allow harvesting from a specified liquidity pool mapping
        require(stakingToken.exists, "Unsupported token");
        require(stakingToken.isLiquidityPool, "Must be liquidity staking token");

        // Send a request to the treasury to claim rewards from the NFTX liquidity staking pool
        treasury.claimNFTXRewards(
            address(liquidityStaking),
            stakingToken.vaultId,
            stakingToken.rewardToken
        );
    }


    /**
     * @notice sends any ERC20 token in the contract to caller.
     */

    function rescue(address _token) external override onlyGovernor {
        // If the token is known, then we shouldn't be able to rescue it
        require(!stakingTokenInfo[_token].exists, "Known token cannot be rescued");

        // Get the amount of token held on contract
        uint256 _amount = IERC20(_token).balanceOf(address(this));

        // Confirm that we hold some of the specified token
        require(_amount > 0, "Token not held in contract");

        // Send to Governor
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }


    /**
     * @notice There should be no rewards held in the allocator, but any dust has formed
     * then we can use this check to claim rewards to the allocator and transfer it
     * to the governor.
     * 
     * @param _token address Address of the staking token
     */

    function rescueRewards(address _token) external onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];

        // We only want to allow harvesting from a specified liquidity pool mapping
        require(stakingToken.exists, "Unsupported token");
        require(stakingToken.isLiquidityPool, "Must be liquidity staking token");

        INFTXLPStaking(address(liquidityStaking)).claimRewards(stakingToken.vaultId);

        uint256 rewardTokenBalance = IERC20(stakingToken.rewardToken).balanceOf(address(this));
        if (rewardTokenBalance > 0) {
            IERC20(stakingToken.rewardToken).safeTransfer(msg.sender, rewardTokenBalance);
        }
    }


    /**
     * @notice withdraws asset from treasury, deposits asset into NFTX staking.
     */

    function deposit(address _token, uint256 _amount) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Ensure that a calculator exists for the `dividendToken`
        require(treasury.bondCalculator(dividendToken) != address(0), "Unsupported xToken calculator");

        // Retrieve amount of asset from treasury, decreasing total reserves
        treasury.allocatorManage(_token, _amount);

        uint256 value = treasury.tokenValue(_token, _amount);
        emit TreasuryAssetDeployed(_token, _amount, value);

        // Approve and deposit into inventory pool, returning xToken
        if (stakingToken.isLiquidityPool) {
            IERC20(_token).safeApprove(address(liquidityStaking), _amount);
            liquidityStaking.deposit(stakingToken.vaultId, _amount);
        } else {
            IERC20(_token).safeApprove(address(inventoryStaking), _amount);
            inventoryStaking.deposit(stakingToken.vaultId, _amount);
        }
    }

    /**
     * @notice Withdraws from staking pool, and deposits asset into treasury.
     */

    function withdraw(address _token, uint256 _amount) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Retrieve amount of asset from treasury, decreasing total reserves
        treasury.allocatorManage(dividendToken, _amount);

        uint256 valueWithdrawn = treasury.tokenValue(dividendToken, _amount);
        emit TreasuryAssetDeployed(dividendToken, _amount, valueWithdrawn);

        // Approve and withdraw from staking pool, returning asset and potentially reward tokens
        if (stakingToken.isLiquidityPool) {
            IERC20(dividendToken).safeApprove(address(liquidityStaking), _amount);
            liquidityStaking.withdraw(stakingToken.vaultId, _amount);
        } else {
            IERC20(dividendToken).safeApprove(address(inventoryStaking), _amount);
            inventoryStaking.withdraw(stakingToken.vaultId, _amount); 
        }

        // Get the balance of the returned vToken or vTokenWeth
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 value = treasury.tokenValue(_token, balance);

        // Deposit the token back into the treasury, increasing total reserves and minting 0 FLOOR
        IERC20(_token).safeApprove(address(treasury), balance);
        treasury.deposit(balance, _token, value);

        emit TreasuryAssetReturned(_token, balance, value);
    }

    /**
     * @notice Staked positions return an xToken which should be regularly deposited
     * back into the Treasury to account for their value. This cannot be done
     * in the same transaction as `deposit()` because of a 2 second timelock in NFTX.
     */

    function depositXTokenToTreasury(address _token) external onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Get the balance of the xToken
        uint256 balance = IERC20(dividendToken).balanceOf(address(this));
        uint256 value = treasury.tokenValue(dividendToken, balance);

        // Deposit the xToken back into the treasury, increasing total reserves and minting 0 FLOOR
        IERC20(dividendToken).safeApprove(address(treasury), balance);
        treasury.deposit(balance, dividendToken, value);

        emit TreasuryAssetReturned(dividendToken, balance, value);
    }

    /**
     * @notice adds asset and corresponding xToken to mapping
     */

    function setDividendToken(address _token, address _xToken) external override onlyGovernor {
        require(_token != address(0), "Token: Zero address");
        require(_xToken != address(0), "xToken: Zero address");

        dividendTokenMapping[_token] = _xToken;
    }


    /**
     * @notice remove xToken mapping
     */

    function removeDividendToken(address _token) external override onlyGovernor {
        delete dividendTokenMapping[_token];
    }


    /**
     * @notice set vault mapping
     */

    function setStakingToken(address _token, address _rewardToken, uint256 _vaultId, bool _isLiquidityPool) external override onlyGovernor {
        require(_token != address(0), "Cannot set vault for NULL token");

        // Set up our vault mapping information
        stakingTokenInfo[_token] = stakingTokenData({
            vaultId: _vaultId,
            isLiquidityPool: _isLiquidityPool,
            rewardToken: _rewardToken,
            exists: true
        });
    }


    /**
     * @notice remove vault mapping
     */

    function removeStakingToken(address _token) external override onlyGovernor {
        delete stakingTokenInfo[_token];
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface ITreasury {
    function bondCalculator(address _address) external view returns (address);

    function deposit(uint256 _amount, address _token, uint256 _profit) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function depositERC721(address _token, uint256 _tokenId) external;

    function withdrawERC721(address _token, uint256 _tokenId) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function allocatorManage(address _token, uint256 _amount) external;

    function claimNFTXRewards(address _liquidityStaking, uint256 _vaultId, address _rewardToken) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);
    
    function riskOffValuation(address _token) external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface INFTXInventoryStaking {
    function deposit(uint256 vaultId, uint256 _amount) external;
    function withdraw(uint256 vaultId, uint256 _share) external;
    function xTokenShareValue(uint256 vaultId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface INFTXLPStaking {
    struct StakingPool {
      address stakingToken;
      address rewardToken;
    }

    function deposit(uint256 vaultId, uint256 amount) external;
    function exit(uint256 vaultId, uint256 amount) external;
    function withdraw(uint256 vaultId, uint256 amount) external;
    function claimRewards(uint256 vaultId) external;
    function vaultStakingInfo(uint256 vaultId) external view returns (StakingPool memory stakingPool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IAllocator {
    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _token, uint256 _amount) external;

    // claims any claimable rewards for this token and sends back to Treasury
    function harvest(address _token, uint256 _amount) external;

    // claims all available rewards for this token and sends back to Treasury
    function harvestAll(address _token) external;

    // onlyGovernor sends any ERC20 token in the contract to treasury
    function rescue(address _token) external; 

    // NFTX Vault mapping utility
    function setStakingToken(address _token, address _rewardToken, uint256 vaultId, bool _isLiquidityPool) external;
    function removeStakingToken(address _token) external;
    function setDividendToken(address _token, address _xToken) external;
    function removeDividendToken(address _token) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IFloorAuthority.sol";

abstract contract FloorAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IFloorAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IFloorAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IFloorAuthority _authority) {
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
    
    function setAuthority(IFloorAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IFloorAuthority {
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