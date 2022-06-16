// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./zeppelin/Pausable.sol";

abstract contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(
        bytes32 _id,
        address _contractAddress,
        bytes20 _gitCommitHash
    ) external virtual;

    function updateController(bytes32 _id, address _controller) external virtual;

    function getContract(bytes32 _id) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IManager.sol";
import "./IController.sol";

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        _onlyControllerOwner();
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        _whenSystemNotPaused();
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        _whenSystemPaused();
        _;
    }

    constructor(address _controller) {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }

    function _onlyController() private view {
        require(msg.sender == address(controller), "caller must be Controller");
    }

    function _onlyControllerOwner() private view {
        require(msg.sender == controller.owner(), "caller must be Controller owner");
    }

    function _whenSystemNotPaused() private view {
        require(!controller.paused(), "system is paused");
    }

    function _whenSystemPaused() private view {
        require(controller.paused(), "system is not paused");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for BondingManager
 * TODO: switch to interface type
 */
interface IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 rewardCut, uint256 feeShare);
    event TranscoderActivated(address indexed transcoder, uint256 activationRound);
    event TranscoderDeactivated(address indexed transcoder, uint256 deactivationRound);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(
        address indexed newDelegate,
        address indexed oldDelegate,
        address indexed delegator,
        uint256 additionalAmount,
        uint256 bondedAmount
    );
    event Unbond(
        address indexed delegate,
        address indexed delegator,
        uint256 unbondingLockId,
        uint256 amount,
        uint256 withdrawRound
    );
    event Rebond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount);
    event TransferBond(
        address indexed oldDelegator,
        address indexed newDelegator,
        uint256 oldUnbondingLockId,
        uint256 newUnbondingLockId,
        uint256 amount
    );
    event WithdrawStake(address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event WithdrawFees(address indexed delegator, address recipient, uint256 amount);
    event EarningsClaimed(
        address indexed delegate,
        address indexed delegator,
        uint256 rewards,
        uint256 fees,
        uint256 startRound,
        uint256 endRound
    );

    // Deprecated events
    // These event signatures can be used to construct the appropriate topic hashes to filter for past logs corresponding
    // to these deprecated events.
    // event Bond(address indexed delegate, address indexed delegator);
    // event Unbond(address indexed delegate, address indexed delegator);
    // event WithdrawStake(address indexed delegator);
    // event TranscoderUpdate(address indexed transcoder, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment, bool registered);
    // event TranscoderEvicted(address indexed transcoder);
    // event TranscoderResigned(address indexed transcoder);

    // External functions
    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    ) external;

    function slashTranscoder(
        address _transcoder,
        address _finder,
        uint256 _slashAmount,
        uint256 _finderFee
    ) external;

    function setCurrentRoundTotalActiveStake() external;

    // Public functions
    function getTranscoderPoolSize() external view returns (uint256);

    function transcoderTotalStake(address _transcoder) external view returns (uint256);

    function isActiveTranscoder(address _transcoder) external view returns (bool);

    function getTotalBonded() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library MathUtils {
    using SafeMath for uint256;

    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 1000000000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(
        uint256 _amount,
        uint256 _fracNum,
        uint256 _fracDenom
    ) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title RoundsManager interface
 */
interface IRoundsManager {
    // Events
    event NewRound(uint256 indexed round, bytes32 blockHash);

    // Deprecated events
    // These event signatures can be used to construct the appropriate topic hashes to filter for past logs corresponding
    // to these deprecated events.
    // event NewRound(uint256 round)

    // External functions
    function initializeRound() external;

    function lipUpgradeRound(uint256 _lip) external view returns (uint256);

    // Public functions
    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function blockHashForRound(uint256 _round) external view returns (bytes32);

    function currentRound() external view returns (uint256);

    function currentRoundStartBlock() external view returns (uint256);

    function currentRoundInitialized() external view returns (bool);

    function currentRoundLocked() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILivepeerToken is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IController.sol";

/**
 * @title Minter interface
 */
interface IMinter {
    // Events
    event SetCurrentRewardTokens(uint256 currentMintableTokens, uint256 currentInflation);

    // External functions
    function createReward(uint256 _fracNum, uint256 _fracDenom) external returns (uint256);

    function trustedTransferTokens(address _to, uint256 _amount) external;

    function trustedBurnTokens(uint256 _amount) external;

    function trustedWithdrawETH(address payable _to, uint256 _amount) external;

    function depositETH() external payable returns (bool);

    function setCurrentRewardTokens() external;

    function currentMintableTokens() external view returns (uint256);

    function currentMintedTokens() external view returns (uint256);

    // Public functions
    function getController() external view returns (IController);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../Manager.sol";
import "./IMinter.sol";
import "./ILivepeerToken.sol";
import "../rounds/IRoundsManager.sol";
import "../bonding/IBondingManager.sol";
import "../libraries/MathUtilsV2.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IL2LPTDataCache {
    function l1CirculatingSupply() external view returns (uint256);
}

/**
 * @title Minter
 * @dev Manages inflation rate and the minting of new tokens for each round of the Livepeer protocol
 */
contract Minter is Manager, IMinter {
    using SafeMath for uint256;

    // Per round inflation rate
    uint256 public inflation;
    // Change in inflation rate per round until the target bonding rate is achieved
    uint256 public inflationChange;
    // Target bonding rate
    uint256 public targetBondingRate;

    // Current number of mintable tokens. Reset every round
    uint256 public currentMintableTokens;
    // Current number of minted tokens. Reset every round
    uint256 public currentMintedTokens;

    // Checks if caller is BondingManager
    modifier onlyBondingManager() {
        require(msg.sender == controller.getContract(keccak256("BondingManager")), "msg.sender not BondingManager");
        _;
    }

    // Checks if caller is RoundsManager
    modifier onlyRoundsManager() {
        require(msg.sender == controller.getContract(keccak256("RoundsManager")), "msg.sender not RoundsManager");
        _;
    }

    // Checks if caller is either BondingManager or JobsManager
    modifier onlyBondingManagerOrJobsManager() {
        require(
            msg.sender == controller.getContract(keccak256("BondingManager")) ||
                msg.sender == controller.getContract(keccak256("JobsManager")),
            "msg.sender not BondingManager or JobsManager"
        );
        _;
    }

    // Checks if caller is either the currently registered Minter or JobsManager
    modifier onlyMinterOrJobsManager() {
        require(
            msg.sender == controller.getContract(keccak256("Minter")) ||
                msg.sender == controller.getContract(keccak256("JobsManager")),
            "msg.sender not Minter or JobsManager"
        );
        _;
    }

    /**
     * @notice Minter constructor
     * @param _inflation Base inflation rate as a percentage of current total token supply
     * @param _inflationChange Change in inflation rate each round (increase or decrease) if target bonding rate is not achieved
     * @param _targetBondingRate Target bonding rate as a percentage of total bonded tokens / total token supply
     */
    constructor(
        address _controller,
        uint256 _inflation,
        uint256 _inflationChange,
        uint256 _targetBondingRate
    ) Manager(_controller) {
        // Inflation must be valid percentage
        require(MathUtils.validPerc(_inflation), "_inflation is invalid percentage");
        // Inflation change must be valid percentage
        require(MathUtils.validPerc(_inflationChange), "_inflationChange is invalid percentage");
        // Target bonding rate must be valid percentage
        require(MathUtils.validPerc(_targetBondingRate), "_targetBondingRate is invalid percentage");

        inflation = _inflation;
        inflationChange = _inflationChange;
        targetBondingRate = _targetBondingRate;
    }

    /**
     * @notice Set targetBondingRate. Only callable by Controller owner
     * @param _targetBondingRate Target bonding rate as a percentage of total bonded tokens / total token supply
     */
    function setTargetBondingRate(uint256 _targetBondingRate) external onlyControllerOwner {
        // Must be valid percentage
        require(MathUtils.validPerc(_targetBondingRate), "_targetBondingRate is invalid percentage");

        targetBondingRate = _targetBondingRate;

        emit ParameterUpdate("targetBondingRate");
    }

    /**
     * @notice Set inflationChange. Only callable by Controller owner
     * @param _inflationChange Inflation change as a percentage of total token supply
     */
    function setInflationChange(uint256 _inflationChange) external onlyControllerOwner {
        // Must be valid percentage
        require(MathUtils.validPerc(_inflationChange), "_inflationChange is invalid percentage");

        inflationChange = _inflationChange;

        emit ParameterUpdate("inflationChange");
    }

    /**
     * @notice Migrate to a new Minter by transferring the current Minter's LPT + ETH balance to the new Minter
     * @dev Only callable by Controller owner
     * @param _newMinter Address of new Minter
     */
    function migrateToNewMinter(IMinter _newMinter) external onlyControllerOwner {
        // New Minter cannot be the current Minter
        require(_newMinter != this, "new Minter cannot be current Minter");
        // Check for null address
        require(address(_newMinter) != address(0), "new Minter cannot be null address");

        IController newMinterController = _newMinter.getController();
        // New Minter must have same Controller as current Minter
        require(newMinterController == controller, "new Minter Controller must be current Controller");
        // New Minter's Controller must have the current Minter registered
        require(newMinterController.getContract(keccak256("Minter")) == address(this), "new Minter must be registered");

        // Transfer current Minter's token balance to new Minter
        livepeerToken().transfer(address(_newMinter), livepeerToken().balanceOf(address(this)));
        // Transfer current Minter's ETH balance to new Minter
        _newMinter.depositETH{ value: address(this).balance }();
    }

    /**
     * @notice Create reward based on a fractional portion of the mintable tokens for the current round
     * @param _fracNum Numerator of fraction (active transcoder's stake)
     * @param _fracDenom Denominator of fraction (total active stake)
     */
    function createReward(uint256 _fracNum, uint256 _fracDenom)
        external
        onlyBondingManager
        whenSystemNotPaused
        returns (uint256)
    {
        // Compute and mint fraction of mintable tokens to include in reward
        uint256 mintAmount = MathUtils.percOf(currentMintableTokens, _fracNum, _fracDenom);
        // Update amount of minted tokens for round
        currentMintedTokens = currentMintedTokens.add(mintAmount);
        // Minted tokens must not exceed mintable tokens
        require(currentMintedTokens <= currentMintableTokens, "minted tokens cannot exceed mintable tokens");
        // Mint new tokens
        livepeerToken().mint(address(this), mintAmount);

        // Reward = minted tokens
        return mintAmount;
    }

    /**
     * @notice Transfer tokens to a receipient. Only callable by BondingManager - always trusts BondingManager
     * @param _to Recipient address
     * @param _amount Amount of tokens
     */
    function trustedTransferTokens(address _to, uint256 _amount) external onlyBondingManager whenSystemNotPaused {
        livepeerToken().transfer(_to, _amount);
    }

    /**
     * @notice Burn tokens. Only callable by BondingManager - always trusts BondingManager
     * @param _amount Amount of tokens to burn
     */
    function trustedBurnTokens(uint256 _amount) external onlyBondingManager whenSystemNotPaused {
        livepeerToken().burn(_amount);
    }

    /**
     * @notice Withdraw ETH to a recipient. Only callable by BondingManager or TicketBroker - always trusts these two contracts
     * @param _to Recipient address
     * @param _amount Amount of ETH
     */
    function trustedWithdrawETH(address payable _to, uint256 _amount)
        external
        onlyBondingManagerOrJobsManager
        whenSystemNotPaused
    {
        _to.transfer(_amount);
    }

    /**
     * @notice Deposit ETH to this contract. Only callable by the currently registered Minter or JobsManager
     */
    function depositETH() external payable onlyMinterOrJobsManager returns (bool) {
        return true;
    }

    /**
     * @notice Set inflation and mintable tokens for the round. Only callable by the RoundsManager
     */
    function setCurrentRewardTokens() external onlyRoundsManager whenSystemNotPaused {
        setInflation();

        // Set mintable tokens based upon current inflation and current total token supply
        currentMintableTokens = MathUtils.percOf(getGlobalTotalSupply(), inflation);
        currentMintedTokens = 0;

        emit SetCurrentRewardTokens(currentMintableTokens, inflation);
    }

    /**
     * @dev Returns Controller interface
     */
    function getController() public view returns (IController) {
        return controller;
    }

    /**
     * @notice Calculate and return global LPT total supply
     * @return Global LPT total supply
     */
    function getGlobalTotalSupply() public view returns (uint256) {
        // Global total supply = L2 total supply + L1 circulating supply
        return livepeerToken().totalSupply().add(l2LPTDataCache().l1CirculatingSupply());
    }

    /**
     * @dev Set inflation based upon the current bonding rate and target bonding rate
     */
    function setInflation() internal {
        uint256 currentBondingRate;
        uint256 totalSupply = getGlobalTotalSupply();

        if (totalSupply > 0) {
            uint256 totalBonded = bondingManager().getTotalBonded();
            currentBondingRate = MathUtils.percPoints(totalBonded, totalSupply);
        }

        if (currentBondingRate < targetBondingRate) {
            // Bonding rate is below the target - increase inflation
            inflation = inflation.add(inflationChange);
        } else if (currentBondingRate > targetBondingRate) {
            // Bonding rate is above the target - decrease inflation
            if (inflationChange > inflation) {
                inflation = 0;
            } else {
                inflation = inflation.sub(inflationChange);
            }
        }
    }

    /**
     * @dev Returns LivepeerToken interface
     */
    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }

    /**
     * @dev Returns BondingManager interface
     */
    function bondingManager() internal view returns (IBondingManager) {
        return IBondingManager(controller.getContract(keccak256("BondingManager")));
    }

    /**
     * @dev Returns L2LPTDataCache interface
     */
    function l2LPTDataCache() internal view returns (IL2LPTDataCache) {
        return IL2LPTDataCache(controller.getContract(keccak256("L2LPTDataCache")));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}