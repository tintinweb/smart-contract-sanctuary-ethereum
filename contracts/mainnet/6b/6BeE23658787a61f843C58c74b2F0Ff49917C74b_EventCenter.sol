// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AccountCenterInterface} from "./interfaces/IAccountCenter.sol";

contract EventCenter is Ownable {
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => uint256) public weight; // token wieght

    mapping(uint256 => uint256) public rewardAmount; // token wieght

    uint256 public epochStart;
    uint256 public epochEnd;
    uint256 public epochInterval = 1 minutes; //for test only
    uint256 public epochRound;

    address rewardCenter;
    address internal accountCenter;

    event CreateAccount(address EOA, address account);

    event UseFlashLoanForLeverage(
        address indexed EOA,
        address indexed account,
        address token,
        uint256 amount,
        uint256 epochRound,
        bool inEpoch
    );

    event AddFlashLoanScore(
        address indexed EOA,
        address indexed account,
        address token,
        uint256 amount,
        uint256 epochRound
    );

    event OpenLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event OpenShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event CloseLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event CloseShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event AddMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken,
        uint256 epochRound
    );

    event WithDraw(
        address EOA,
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 epochRound
    );

    event Repay(
        address EOA,
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 epochRound
    );

    event RemoveMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken,
        uint256 epochRound
    );

    event AddPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore,
        uint256 epochRound
    );

    event SubPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore,
        uint256 epochRound
    );

    event ReleasePositionReward(
        address indexed owner,
        uint256 epochRound,
        bytes32 merkelRoot
    );

    event ClaimPositionReward(
        address indexed EOA,
        uint256 epochRound,
        uint256 amount
    );

    event ClaimOpenAccountReward(
        address indexed EOA,
        address indexed account,
        uint256 amount
    );

    event StartEpoch(
        address indexed owner,
        uint256 epochRound,
        uint256 start,
        uint256 end,
        uint256 rewardAmount
    );

    event ResetScore(address indexed owner, uint256 epochRound);

    event SetAssetWeight(address indexed token, uint256 indexed weight);

    event SetEpochInterval(uint256 epochInterval);

    event ToggleEpochAutoStart(address indexed owner, bool indexed autoEpoch);

    event SetRewardCenter(address indexed owner, address indexed rewardCenter);

    modifier onlyAccountDSA() {
        require(
            accountCenter != address(0),
            "CHFRY: accountCenter not setup 1"
        );
        require(
            AccountCenterInterface(accountCenter).isSmartAccountofTypeN(
                msg.sender,
                1
            ) ||
                AccountCenterInterface(accountCenter).isSmartAccountofTypeN(
                    msg.sender,
                    2
                ),
            "CHFRY: only SmartAccount could emit Event in EventCenter"
        );
        _;
    }
    modifier onlyRewardCenter() {
        require(msg.sender == rewardCenter, "CHFRY: accountCenter not setup 1");
        _;
    }

    modifier notInEpoch() {
        require(epochEnd < block.timestamp, "CHFRY: In Epoch");
        _;
    }

    constructor(address _accountCenter) {
        accountCenter = _accountCenter;
    }

    function setRewardCenter(address _rewardCenter) public onlyOwner {
        require(
            _rewardCenter != address(0),
            "CHFRY: EventCenter address should not be 0"
        );
        rewardCenter = _rewardCenter;
        emit SetRewardCenter(msg.sender, rewardCenter);
    }

    function setEpochInterval(uint256 _epochInterval)
        external
        onlyOwner
        notInEpoch
    {
        epochInterval = _epochInterval;
        emit SetEpochInterval(_epochInterval);
    }

    function startEpoch(uint256 _rewardAmount) external notInEpoch {
        require(
            msg.sender == rewardCenter,
            "CHFRY: only Reward Center could start new Epoch"
        );
        epochRound = epochRound + 1;
        epochStart = block.timestamp;
        epochEnd = epochStart + epochInterval;
        rewardAmount[epochRound] = _rewardAmount;
        emit StartEpoch(
            msg.sender,
            epochRound,
            epochStart,
            epochEnd,
            _rewardAmount
        );
    }

    function setWeight(address _token, uint256 _weight)
        external
        onlyOwner
        notInEpoch
    {
        require(_token != address(0), "CHFRY: address shoud not be 0");
        weight[_token] = _weight;
        emit SetAssetWeight(_token, _weight);
    }

    function getWeight(address _token) external view returns (uint256) {
        return weight[_token];
    }

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        bool inRewardEpoch = __isInRewardEpoch();
        uint256 tokenWeight = weight[token];
        bool notOverflow;
        uint256 score;
        emit UseFlashLoanForLeverage(
            EOA,
            account,
            token,
            amount,
            epochRound,
            inRewardEpoch
        );
        if (inRewardEpoch == true) {

            (notOverflow, score) = SafeMath.tryMul(score, tokenWeight);

            require(notOverflow == true, "CHFRY: You are so rich!");

            uint256 decimal;

            if (token == ethAddr) {
                decimal = 18;
            } else {
                decimal = IERC20Metadata(token).decimals();
            }
            (notOverflow, score) = SafeMath.tryDiv(score, 10**(decimal));
            
            require(notOverflow == true, "CHFRY: You are so rich!");

            emit AddFlashLoanScore(EOA, account, token, score, epochRound);
        }
    }

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 1);
        emit OpenLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 1);
        emit CloseLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountRepay,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 2);
        emit OpenShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 4);
        emit CloseShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountWithDraw,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit AddMargin(
            EOA,
            account,
            leverageToken,
            amountLeverageToken,
            epochRound
        );
    }

    function emitWithDrawEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit WithDraw(EOA, account, token, amount, epochRound);
    }

    function emitRepayEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit Repay(EOA, account, token, amount, epochRound);
    }

    function emitRemoveMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit RemoveMargin(
            EOA,
            account,
            leverageToken,
            amountLeverageToken,
            epochRound
        );
    }

    function emitReleasePositionRewardEvent(
        address owner,
        uint256 _epochRound,
        bytes32 merkelRoot
    ) external onlyRewardCenter {
        emit ReleasePositionReward(owner, _epochRound, merkelRoot);
    }

    function emitClaimPositionRewardEvent(
        address EOA,
        uint256 _epochRound,
        uint256 amount
    ) external onlyRewardCenter {
        emit ClaimPositionReward(EOA, _epochRound, amount);
    }

    function emitClaimOpenAccountRewardEvent(
        address EOA,
        address account,
        uint256 amount
    ) external onlyRewardCenter {
        emit ClaimOpenAccountReward(EOA, account, amount);
    }

    function addScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;

        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);
        require(notOverflow == true, "CHFRY: You are so rich!");
        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        uint256 decimal;

        if (token == ethAddr) {
            decimal = 18;
        } else {
            decimal = IERC20Metadata(token).decimals();
        }
        (notOverflow, positionScore) = SafeMath.tryDiv(
            positionScore,
            10**(decimal)
        );

        require(notOverflow == true, "CHFRY: overflow");

        emit AddPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore,
            epochRound
        );
    }

    function subScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;
        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);

        require(notOverflow == true, "CHFRY: You are so rich!");

        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        uint256 decimal;

        if (token == ethAddr) {
            decimal = 18;
        } else {
            decimal = IERC20Metadata(token).decimals();
        }
        (notOverflow, positionScore) = SafeMath.tryDiv(
            positionScore,
            10**(decimal)
        );
        require(notOverflow == true, "CHFRY: overflow");

        emit SubPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore,
            epochRound
        );
    }

    function secToEpochEnd() external view returns (uint256 _secToEpochEnd) {
        if (epochEnd < block.timestamp) {
            _secToEpochEnd = 0;
        } else {
            _secToEpochEnd = epochEnd - block.timestamp;
        }
    }

    function isInRewardEpoch() external view returns (bool _isInRewardEpoch) {
        _isInRewardEpoch = __isInRewardEpoch();
    }

    function __isInRewardEpoch() internal view returns (bool _isInRewardEpoch) {
        if (epochEnd < block.timestamp) {
            _isInRewardEpoch = false;
        } else {
            _isInRewardEpoch = true;
        }
    }

    function convertToWei(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        bool notOverflow;
        (notOverflow, amt) = SafeMath.tryDiv(_amt, 10**(_dec));
        require(notOverflow == true, "CHFRY: convertToWei overflow");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account)
        external
        view
        returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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