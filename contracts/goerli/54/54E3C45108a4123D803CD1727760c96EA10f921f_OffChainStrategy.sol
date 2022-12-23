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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity 0.8.16;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== OffChainStrategy.sol ========================
// ====================================================================

/**
 * @title Off Chain Strategy
 * @author MAXOS Team - https://maxos.finance/
 * @dev Representation of an off-chain investment
 */
import "../Sweep/ISweep.sol";
import "../Utils/Uniswap/V2/TransferHelper.sol";
import "../Common/Owned.sol";
import "../Common/ERC20/IERC20Metadata.sol";

contract OffChainStrategy is Owned {
    IERC20Metadata public usdx;
    ISweep public sweep;

    // Variables
    bool public redeem_mode;
    uint256 public redeem_amount;
    uint256 public redeem_time;
    uint8 public delay; // Days 
    uint256 public current_value;
    uint256 public valuation_time;
    address public stabilizer;
    address public wallet;
    string public link;

    // Constants
    uint256 private constant DAY_TIMESTAMP = 24 * 60 * 60;

    // Events
    event Deposit(address token, uint256 amount);
    event Withdraw(uint256 amount);
    event Payback(address token, uint256 amount);

    constructor(
        address _owner,
        address _wallet,
        address _stabilizer,
        string memory _link,
        address _sweep_address,
        address _usdx_address
    ) Owned(_owner) {
        wallet = _wallet;
        stabilizer = _stabilizer;
        link = _link;
        sweep = ISweep(_sweep_address);
        usdx = IERC20Metadata(_usdx_address);
        redeem_mode = false;
    }

    modifier onlyStabilizer() {
        require(msg.sender == stabilizer, "only stabilizer");
        _;
    }

    /**
     * @notice Current Value of investment.
     */
    function currentValue() external view returns (uint256) {
        return current_value;
    }

    /**
     * @notice isDefaulted
     * Check whether the redeem is executed.
     * @return bool True: is defaulted, False: not defaulted.
     */
    function isDefaulted() public view returns (bool) {
        bool isPassed = redeem_time + (delay * DAY_TIMESTAMP) < block.timestamp;

        return redeem_mode && isPassed;
    }

    /**
     * @notice Update wallet to send the investment to.
     * @param _wallet New wallet address.
     */
    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    /**
     * @notice Update Link
     * @param _link New link.
     */
    function setLink(string calldata _link) external onlyOwner {
        link = _link;
    }

    /**
     * @notice Set Delay
     * @param _delay Days for delay.
     */
    function setDelay(uint8 _delay) external onlyOwner {
        delay = _delay;
    }

    /**
     * @notice Deposit stable coins into Off Chain strategy.
     * @param token token address to deposit. USDX, SWEEP ...
     * @param amount The amount of usdx to deposit in the strategy.
     * @dev tracks the time when current_value was updated.
     */
    function deposit(address token, uint256 amount) public onlyStabilizer {
        require(wallet != address(0), "Invaild Address");

        TransferHelper.safeTransferFrom(
            address(token),
            stabilizer,
            wallet,
            amount
        );

        if(token == address(sweep)) {
            uint256 sweep_in_usdx = SWEEPinUSDX(amount, sweep.target_price());
            current_value += sweep_in_usdx;
        } else {
            current_value += amount;
        }
        valuation_time = block.timestamp;

        emit Deposit(token, amount);
    }

    /**
     * @notice Payback stable coins to Stabilizer
     * @param token token address to payback. USDX, SWEEP ...
     * @param amount The amount of usdx to payback.
     */
    function payback(address token, uint256 amount) public {
        require(token == address(sweep) || token == address(usdx), "Invalid Token");

        if(token == address(sweep)) {
            amount = SWEEPinUSDX(amount, sweep.target_price());
        }
        require(redeem_amount <= amount, "Not enough amount");

        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            stabilizer,
            amount
        );

        current_value -= amount;
        redeem_mode = false;
        redeem_amount = 0;

        emit Payback(token, amount);
    }

    /**
     * @notice Withdraw usdx tokens from the asset.
     * @param amount The amount to withdraw.
     * @dev tracks the time when current_value was updated.
     */
    function withdraw(uint256 amount) public onlyStabilizer {
        redeem_amount = amount;
        redeem_mode = true;
        redeem_time = block.timestamp;

        emit Withdraw(amount);
    }

    /**
     * @notice Update Value of investment.
     * @param _value New value of investment.
     * @dev tracks the time when current_value was updated.
     */
    function updateValue(uint256 _value) public onlyOwner {
        current_value = _value;
        valuation_time = block.timestamp;
    }

    /**
     * @notice Reset the redeem mode.
     */
    function resetRedeem() public onlyOwner {
        redeem_amount = 0;
        redeem_mode = false;
    }

    /**
     * @notice SWEEP in USDX
     * Calculate the amount of USDX that are equivalent to the SWEEP input.
     * @param amount Amount of SWEEP.
     * @param price Price of Sweep in USDX. This value is obtained from the AMM.
     * @return amount of USDX.
     * @dev 1e6 = PRICE_PRECISION
     */
    function SWEEPinUSDX(uint256 amount, uint256 price)
        internal
        view
        returns (uint256)
    {
        return (amount * price * (10**usdx.decimals())) / (10**sweep.decimals() * 1e6);
    }

    /**
     * @notice Withdraw Rewards.
     * @dev this function was added to generate compatibility with On Chain investment.
     */
    function withdrawRewards(address _owner) public {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        bool is_listed;
        uint256 max_mint_amount;
        uint256 minted_amount;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function GENESIS_SUPPLY() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function current_target_price() external view returns (uint256);

    function target_price() external view returns (uint256);

    function refreshTargetPrice(uint256 _amm_price) external;

    function setPriceTarget(uint256 _new_price_target) external;

    function setUniswapOracle(address _uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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