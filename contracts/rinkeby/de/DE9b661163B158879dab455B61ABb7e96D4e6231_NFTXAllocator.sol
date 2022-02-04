// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "../libraries/Address.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITreasury.sol";

import "../interfaces/allocators/IAllocator.sol";
import "../interfaces/allocators/INFTXInventoryStaking.sol";
import "../interfaces/allocators/INFTXLPStaking.sol";

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

    /**
     * @notice describes the dividend token minted from staking token.
     */

    struct dividendTokenData {
        address underlying; // stakingToken
        address xToken; // dividendToken
        uint256 deployed;
    }


    // NFTX Inventory Staking contract
    INFTXInventoryStaking internal inventoryStaking;

    // NFTX Liquidity Staking contract
    INFTXLPStaking internal liquidityStaking;

    // Floor Treasury contract
    ITreasury internal treasury;

    // Corresponding NFTX token vault data for tokens
    mapping (address => stakingTokenData) public stakingTokenInfo;

    // Corresponding xTokens for tokens
    mapping (address => dividendTokenData) public dividendTokenInfo;


    /**
     * @notice initialises the construct with no additional logic.
     */

    constructor (
        IFloorAuthority _authority,
        address _inventoryStaking,
        address _liquidityStaking,
        address _treasury
    ) FloorAccessControlled(_authority) {
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

    function harvestAll(address _token) override external {
        // We only want to allow harvesting from a specified liquidity pool mapping
        require(stakingTokenInfo[_token].exists, 'Unsupported token');
        require(stakingTokenInfo[_token].isLiquidityPool, 'Must be liquidity staking token');

        // Trigger our rewards to be claimed
        liquidityStaking.claimRewards(stakingTokenInfo[_token].vaultId);

        // Get the reward token for this stakingToken
        address _rewardToken = stakingTokenInfo[_token].rewardToken;
        
        // Deposit the harvested rewards into the treasury
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        uint256 value = treasury.tokenValue(_rewardToken, balance);

        // Approve and deposit asset into treasury
        IERC20(_rewardToken).approve(address(treasury), balance);

        // Pass the tokenValue as profit to stop the treasury minting FLOOR
        treasury.deposit(balance, _rewardToken, value);
    }


    /**
     * @notice sends any ERC20 token in the contract to caller.
     */

    function rescue(address _token) external override onlyGovernor {
        // If the token is known, then we shouldn't be able to rescue it
        require(!stakingTokenInfo[_token].exists, 'Known token cannot be rescued');

        // Get the amount of token held on contract
        uint256 _amount = IERC20(_token).balanceOf(address(this));

        // Confirm that we hold some of the specified token
        require(_amount > 0, 'Token not held in contract');

        // Send to Governor
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }


    /**
     * @notice withdraws asset from treasury, deposits asset into lending pool,
     * then deposits xToken into treasury.
     */

    function deposit(address _token, uint256 _amount) external override onlyPolicy {
        require(stakingTokenInfo[_token].exists, 'Unsupported token');

        // Retrieve amount of asset from treasury
        treasury.allocatorWithdraw(_amount, _token);

        // Approve and deposit into inventory pool, returning xToken
        if (stakingTokenInfo[_token].isLiquidityPool) {
            IERC20(_token).approve(address(liquidityStaking), _amount);
            liquidityStaking.deposit(stakingTokenInfo[_token].vaultId, _amount);
        } else {
            IERC20(_token).approve(address(inventoryStaking), _amount);
            inventoryStaking.deposit(stakingTokenInfo[_token].vaultId, _amount);
        }

        // Account for deposit
        accountingFor(_token, _amount, true); 
    }


    /**
     * @notice Withdraws from lending pool, and deposits asset into treasury.
     */

    function withdraw(address _token, uint256 _amount) external override onlyPolicy {
        require(stakingTokenInfo[_token].exists, 'Unsupported token');

        // approve and withdraw from lending pool, returning asset

        if (stakingTokenInfo[_token].isLiquidityPool) {
            IERC20(dividendTokenInfo[_token].xToken).approve(address(liquidityStaking), _amount);
            liquidityStaking.withdraw(stakingTokenInfo[_token].vaultId, _amount); 
        } else {
            IERC20(dividendTokenInfo[_token].xToken).approve(address(inventoryStaking), _amount);
            inventoryStaking.withdraw(stakingTokenInfo[_token].vaultId, _amount); 
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 base = balance;
        uint256 gain;

        if (balance > dividendTokenInfo[_token].deployed) {
            base = dividendTokenInfo[_token].deployed;
            gain = balance - base;
        }

        // Account for withdrawal
        accountingFor(_token, balance, false);

        // Approve and deposit asset into treasury
        IERC20(_token).approve(address(treasury), balance);

        // Deposit the tokens into the treasury without affecting total reserves
        treasury.allocatorDeposit(base, _token);

        // If we have additional returns then we need to deposit the additional value
        // into the treasury via the standard function call.
        if (gain > 0) {
            uint256 gain_value = treasury.tokenValue(_token, balance);
            treasury.deposit(gain, _token, gain_value);
        }
    }


    /**
     * @notice adds asset and corresponding xToken to mapping
     */

    function addDividendToken(address _token, address _xToken) external override onlyPolicy {
        require(_token != address(0), 'Token: Zero address');
        require(_xToken != address(0), 'xToken: Zero address');
        require(dividendTokenInfo[_token].deployed == 0, 'Token already added');

        dividendTokenInfo[_token] = dividendTokenData({
            underlying: _token,
            xToken: _xToken,
            deployed: 0
        });
    }


    /**
     * @notice set vault mapping.
     */

    function setStakingToken(address _token, address _rewardToken, uint256 _vaultId, bool _isLiquidityPool) external override onlyPolicy {
        require(_token != address(0), 'Cannot set vault for NULL token');

        // Set up our vault mapping information
        stakingTokenInfo[_token].vaultId = _vaultId;
        stakingTokenInfo[_token].isLiquidityPool = _isLiquidityPool;
        stakingTokenInfo[_token].rewardToken = _rewardToken;
        stakingTokenInfo[_token].exists = true;
    }


    /**
     * @notice remove vault mapping.
     */

    function removeStakingToken(address _token) external override onlyPolicy {
        delete stakingTokenInfo[_token];
    }


    /**
     * @notice accounting of deposit / withdrawal of assets.
     */

    function accountingFor(
        address token,
        uint256 amount,
        bool add
    ) internal {
        if (add) {
            // track amount allocated into pool
            dividendTokenInfo[token].deployed = dividendTokenInfo[token].deployed.add(amount);
        }
        else {
            // track amount allocated into pool
            dividendTokenInfo[token].deployed = (amount < dividendTokenInfo[token].deployed) ? dividendTokenInfo[token].deployed.sub(amount) : 0;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;


// TODO(zx): replace with OZ implementation.
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

  /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

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
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function allocatorDeposit(uint256 _amount, address _token) external;

    function allocatorWithdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);
    
    function riskOffValuation(address _token) external view returns (uint256);

    function baseSupply() external view returns (uint256);
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
    function addDividendToken(address _token, address _xToken) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface INFTXInventoryStaking {
    function deposit(uint256 vaultId, uint256 _amount) external;
    function withdraw(uint256 vaultId, uint256 _share) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface INFTXLPStaking {
    function deposit(uint256 vaultId, uint256 amount) external;
    function exit(uint256 vaultId, uint256 amount) external;
    function withdraw(uint256 vaultId, uint256 amount) external;
    function claimRewards(uint256 vaultId) external;
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