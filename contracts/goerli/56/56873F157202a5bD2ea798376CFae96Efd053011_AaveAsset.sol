// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

// Original at https://etherscan.io/address/0xc6845a5c768bf8d7681249f8927877efda425baf#code
// Address [0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9] used is a proxy
// Some functions were omitted for brevity. See the contract for details

interface IAAVELendingPool_Partial {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
        address asset,
        uint256 amount,
        address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== AaveAsset.sol ============================
// ====================================================================
// Intergrated with Aave V2

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "./Aave/IAAVELendingPool_Partial.sol";
import "../Utils/Uniswap/V2/TransferHelper.sol";
import "../Common/Owned.sol";
import "../Common/ERC20/IERC20.sol";

contract AaveAsset is Owned {
    // Variables
    address public stabilizer;
    bool public defaulted;

    // Tokens
    IERC20 public USDX;
    IERC20 private aaveUSDX_Token;

    // Pools
    IAAVELendingPool_Partial private aaveLending_Pool;

    // Events
    event Deposit(address collateral_address, uint256 amount);
    event Withdraw(address collateral_address, uint256 amount);
    event WithdrawRewards(uint256 stkAave_amount, uint256 aave_amount);

    constructor(
        address _owner_address,
        address _stabilizer_address,
        address _aave_lending_pool_address,
        address _usdx_address,
        address _aave_usdx_address
    ) Owned(_owner_address) {
        stabilizer = _stabilizer_address;
        aaveLending_Pool = IAAVELendingPool_Partial(_aave_lending_pool_address);
        USDX = IERC20(_usdx_address);
        aaveUSDX_Token = IERC20(_aave_usdx_address);
    }

    /* ========== Modifies ========== */

    modifier onlyStabilizer() {
        require(msg.sender == stabilizer, "only stabilizer");
        _;
    }

    /* ========== Views ========== */

    /**
     * @notice Gets the current value in USDX of this OnChainAsset
     * @return the current usdx amount
     */
    function currentValue() public view returns (uint256) {
        // All numbers given are in USDX unless otherwise stated
        return aaveUSDX_Token.balanceOf(address(this));
    }

    /**
     * @notice isDefaulted
     * @return bool True: is defaulted, False: not defaulted.
     */
    function isDefaulted() public view returns (bool) {
        return defaulted;
    }

    /* ========== Actions ========== */

    /**
     * @notice setDefaulted
     * @param _defaulted True: is defaulted, False: not defaulted.
     */
    function setDefaulted(bool _defaulted) public onlyOwner {
        defaulted = _defaulted;
    }

    /**
     * @notice Function to deposit USDX from Stabilizer to AMO
     * @param token USDX address
     * @param amount Amount of asset to be deposited - E18
     */
    function deposit(address token, uint256 amount) public onlyStabilizer {
        require(token == address(USDX), "Invalid Token");
        TransferHelper.safeTransferFrom(
            address(USDX),
            msg.sender,
            address(this),
            amount
        );
        TransferHelper.safeApprove(
            address(USDX),
            address(aaveLending_Pool),
            amount
        );
        aaveLending_Pool.deposit(address(USDX), amount, address(this), 0);

        emit Deposit(address(USDX), amount);
    }

    /**
     * @notice Function to withdraw USDX from AMO to Stabilizer
     * @param amount Amount of asset to be withdrawed - E18
     */
    function withdraw(uint256 amount) public onlyStabilizer {
        aaveLending_Pool.withdraw(address(USDX), amount, msg.sender);

        emit Withdraw(address(USDX), amount);
    }

    /**
     * @notice Function to Recover Erc20 token to Stablizer
     * @param token token address to be recovered
     * @param amount token amount to be recovered
     */
    function recoverERC20(address token, uint256 amount)
        external
        onlyStabilizer
    {
        TransferHelper.safeTransfer(address(token), msg.sender, amount);
    }

    /**
     * @notice compliance with the IAsset.sol
     */
    function withdrawRewards(address) external pure {}

    function updateValue(uint256) external pure {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity 0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        
        emit OwnerChanged(address(0), _owner);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
        _;
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        owner = nominatedOwner;
        nominatedOwner = address(0);

        emit OwnerChanged(owner, nominatedOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}