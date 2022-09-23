//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IWETH} from "../interfaces/IWETH.sol";
import {IDomainSettings} from "../settings/IDomainSettings.sol";
import {IDomainERC20} from "../erc20/IDomainERC20.sol";

contract DomainPresale is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    struct PresaleInfo {
        address curator;
        uint256 remainAmount;
        uint256 originalAmount;
        uint256 saleAmount;
        uint256 price;
        address currency;
        uint256 startTime;
        uint256 endTime;
    }

    address public immutable WETH;

    address public domainSettings;

    // erc20 => PresaleInfo
    mapping(address => PresaleInfo) public presaleMapping;

    event Issue(address indexed curator, address erc20, address currency, uint256 price, uint256 amount, uint256 startTime, uint256 endTime);
    event Buy(address indexed buyer, address erc20, uint256 amount);
    event Withdraw(address indexed curator, address erc20, uint256 amount);

    constructor(address _domainSettings, address _WETH) {
        domainSettings = _domainSettings;
        WETH = _WETH;
    }

    /**
     * @notice Issue presale
     * @param erc20 Fragment address
     * @param amount Purchase amount
     * @param currency Payment currency address
     * @param price Fragment unit price
     * @param startTime StartTime in timestamp
     * @param endTime EndTime in timestamp
     * @param deadline Deadline in timestamp
     * @param v Signature parameter (27 or 28)
     * @param r Signature parameter
     * @param s Signature parameter
     */
    function issueWithPermit(
        address erc20,
        uint256 amount,
        address currency,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) external {
        IDomainERC20(erc20).permit(msg.sender, address(this), _toWithPower(erc20, amount), deadline, v, r, s);
        issue(erc20, amount, currency, price, startTime, endTime);
    }

    /**
     * @notice Issue presale
     * @param erc20 Fragment address
     * @param amount Purchase amount
     * @param currency Payment currency address
     * @param price Fragment unit price
     * @param startTime StartTime in timestamp
     * @param endTime EndTime in timestamp
     */
    function issue(
        address erc20,
        uint256 amount,
        address currency,
        uint256 price,
        uint256 startTime,
        uint256 endTime) public whenNotPaused {

        PresaleInfo storage presaleInfo = presaleMapping[erc20];

        //1. 100%
        require(IERC20Metadata(erc20).totalSupply() == IERC20Metadata(erc20).balanceOf(_msgSender()), "DomainPresale: you must owner token's all supply");

        //2. not exist
        require(presaleInfo.endTime < block.timestamp, "DomainPresale: token presale unclosed");

        //3.
        require(amount > 0, "DomainPresale: presale amount is too few");

        //4.
        require(price > 0, "DomainPresale: price is too low");

        //5. duration
        uint256 presaleDuration = endTime.sub(startTime);
        require(presaleDuration >= IDomainSettings(domainSettings).minPresaleDuration(), "DomainPresale: presale duration too low");
        require(presaleDuration <= IDomainSettings(domainSettings).maxPresaleDuration(), "DomainPresale: presale duration too high");

        //6. time
        require(startTime > 1500000000 && startTime < 2500000000, "DomainPresale: presale start time invalid");
        require(endTime > 1500000000 && endTime < 2500000000, "DomainPresale: presale start time invalid");
        require(startTime > block.timestamp, "DomainPresale: presale start time must greater than current time");
        require(endTime > block.timestamp, "DomainPresale: presale end time must greater than current time");

        //7. info mapping
        presaleInfo.saleAmount = 0;
        presaleInfo.currency = currency;
        presaleInfo.curator = _msgSender();
        presaleInfo.remainAmount = amount;
        presaleInfo.originalAmount = amount;
        presaleInfo.price = price;
        presaleInfo.startTime = startTime;
        presaleInfo.endTime = endTime;
        presaleMapping[erc20] = presaleInfo;

        emit Issue(_msgSender(), erc20, currency, price, _toWithPower(erc20, amount), startTime, endTime);
    }

    /**
     * @notice Purchase presale fragment
     * @param erc20 Fragment address
     * @param amount Purchase amount
     */
    function buy(address erc20, uint256 amount) external whenNotPaused nonReentrant {

        PresaleInfo storage presaleInfo = presaleMapping[erc20];

        //1. curator
        require(presaleInfo.curator != address(0), "DomainPresale: token presale nonexistent");

        //2. startTime
        require(presaleInfo.startTime <= block.timestamp, "DomainPresale: token presale not started");

        //3. endTime
        require(presaleInfo.endTime > block.timestamp, "DomainPresale: token presale close");

        //4. remainAmount
        require(presaleInfo.remainAmount > 0, "DomainPresale: token presale sell out");

        //5. purchasableAmountWithoutPower
        uint256 purchasableAmountWithoutPower = presaleInfo.remainAmount > amount ? amount : presaleInfo.remainAmount;

        //6. paymentFunds
        uint256 paymentFunds = purchasableAmountWithoutPower.mul(presaleInfo.price);

        //7. transfer from
        uint256 purchasableAmountWithPower = _toWithPower(erc20, purchasableAmountWithoutPower);
        IERC20Metadata(erc20).transferFrom(presaleInfo.curator, _msgSender(), purchasableAmountWithPower);

        //8. transfer from
        IERC20Metadata(presaleInfo.currency).transferFrom(msg.sender, presaleInfo.curator, paymentFunds);

        //9. subtract presale erc20 remain amount
        presaleInfo.remainAmount = presaleInfo.remainAmount.sub(purchasableAmountWithoutPower);

        //10. sale amount
        presaleInfo.saleAmount = presaleInfo.saleAmount.add(purchasableAmountWithoutPower);

        emit Buy(_msgSender(), erc20, purchasableAmountWithPower);
    }

    /**
     * @notice Purchase presale fragment
     * @param erc20 Fragment address
     * @param amount Purchase amount
     */
    function buyUsingETHAndWETH(address erc20, uint256 amount) payable external whenNotPaused nonReentrant {

        PresaleInfo storage presaleInfo = presaleMapping[erc20];

        //1. curator
        require(presaleInfo.curator != address(0), "DomainPresale: token presale nonexistent");

        //2. startTime
        require(presaleInfo.startTime <= block.timestamp, "DomainPresale: token presale not started");

        //3. endTime
        require(presaleInfo.endTime > block.timestamp, "DomainPresale: token presale close");

        //4. remainAmount
        require(presaleInfo.remainAmount > 0, "DomainPresale: token presale sell out");

        //5. currency
        require(presaleInfo.currency == WETH, "DomainPresale: currency must be WETH");

        //5. purchasableAmountWithoutPower
        uint256 purchasableAmountWithoutPower = presaleInfo.remainAmount > amount ? amount : presaleInfo.remainAmount;

        //7. paymentFunds
        uint256 paymentFunds = purchasableAmountWithoutPower.mul(presaleInfo.price);
        if (paymentFunds > msg.value) {
            IWETH(WETH).transferFrom(msg.sender, address(this), (paymentFunds - msg.value));
        } else {
            require(paymentFunds == msg.value, "DomainPresale: Msg.value too high");
        }
        IWETH(WETH).deposit{value : msg.value}();

        //8. transfer from
        uint256 purchasableAmountWithPower = _toWithPower(erc20, purchasableAmountWithoutPower);
        IERC20Metadata(erc20).transferFrom(presaleInfo.curator, _msgSender(), purchasableAmountWithPower);

        //9. transfer from
        IWETH(WETH).transfer(presaleInfo.curator, paymentFunds);

        //10. subtract presale erc20 remain amount
        presaleInfo.remainAmount = presaleInfo.remainAmount.sub(purchasableAmountWithoutPower);

        //11. sale amount
        presaleInfo.saleAmount = presaleInfo.saleAmount.add(presaleInfo.remainAmount);

        emit Buy(_msgSender(), erc20, purchasableAmountWithPower);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDomainSettings(address domainSettings_) external onlyOwner {
        domainSettings = domainSettings_;
    }

    function _toWithPower(address erc20, uint256 amount) internal view returns (uint256){
        uint8 decimals_ = IERC20Metadata(erc20).decimals();
        uint256 pow_ = uint256(10) ** decimals_;
        return amount.mul(pow_);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {

    function deposit() external payable;

    function withdraw(uint) external;

    function approve(address, uint) external returns(bool);

    function transfer(address, uint) external returns(bool);

    function transferFrom(address, address, uint) external returns(bool);

    function balanceOf(address) external view returns(uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDomainSettings {

    //最小投票时长
    function minVoteDuration() external returns (uint256);

    //最大投票时长
    function maxVoteDuration() external returns (uint256);

    //投票百分百
    function votePercentage() external returns (uint256);

    //最小拍卖时长
    function minAuctionDuration() external returns (uint256);

    //最大拍卖时长
    function maxAuctionDuration() external returns (uint256);

    //竞拍加价百分百
    function bidIncreasePercentage() external returns (uint256);

    //最小预售时长
    function minPresaleDuration() external returns (uint256);

    //最大预售时长
    function maxPresaleDuration() external returns (uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20WithPermiteUpgradeable} from './IERC20WithPermiteUpgradeable.sol';

interface IDomainERC20 is IERC20WithPermiteUpgradeable {

    function domainVault() external view returns (address);

    function originalTotalSupply() external view returns (uint256);

    function burnForDomainVault(uint256 amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20WithPermiteUpgradeable {

    /// @notice The permit typehash used in the permit signature
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}