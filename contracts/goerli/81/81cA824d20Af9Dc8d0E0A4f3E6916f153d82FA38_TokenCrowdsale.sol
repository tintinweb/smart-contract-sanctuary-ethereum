pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenCrowdsale is ReentrancyGuard {
    using SafeMath for uint256;

    struct CrowdsaleObject {
        uint256 rate;
        address tokenOwnerAddress;
        address payable receivingWalletAddress;
        ERC20 token;
        uint256 cap;
        uint256 openingTime;
        uint256 closingTime;
        bool whitelistable;
        bool trackContributions;
        uint256 investorMinCap;
        uint256 investorHardCap;
        uint256 crowdsaleTokenSupply;
        uint256 weiRaised;
        bool finalized;
        mapping(address => bool) whitelist;
        mapping(address => uint256) contributions;
        mapping(address => uint256) tokenBalances; 
    }

    uint256 public crowdsaleId;
    uint256[] public allCrowdsaleIds;
    mapping (uint256 => CrowdsaleObject) public crowdsales;
    mapping (address => uint256[]) public crowdsalesByOwnerAddress;
    

    event TokensPurchased(uint256 _id, address indexed purchaser, uint256 value, uint256 amount, uint weiRaised);
    event CrowdsaleExtended(uint256 _id, uint256 prevClosingTime, uint256 newClosingTime);
    event CrowdsaleFinalized(uint256 _id);
    event LogCrowdsale(uint256 _id, uint256 _rate, address _tokenOwnerAddress, address _receivingWalletAddress, address _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime, bool _whitelistable, bool _trackContributions, uint256 _investorMinCap, uint256 _investorHardCap, bool _finalized, uint timestamp);

    function createCrowdsale(
        uint256 _rate,
        address payable _receivingWalletAddress,
        ERC20 _token,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        bool _whitelistable,
        bool _trackContributions,
        uint256 _investorMinCap,
        uint256 _investorHardCap,
        uint256 _crowdsaleTokenSupply) external returns (uint256 _id) {
        
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_receivingWalletAddress != address(0), "Crowdsale: Receiving wallet is the zero address");
        require(address(_token) != address(0), "Crowdsale: token is the zero address");
        require(_cap > 0, "Crowdsale: cap is 0");
        require(_openingTime >= block.timestamp, "Crowdsale: opening time is before current time");
        require(_closingTime > _openingTime, "Crowdsale: opening time is not before closing time");
        require(_crowdsaleTokenSupply >= _cap.div(1e18).mul(_rate).mul(10 ** _token.decimals()), "Crowdsale: token supply less than ether cap. Ensure rate, cap and supply amount are correct.");

        _id = ++crowdsaleId;        
        crowdsales[_id].rate = _rate;
        crowdsales[_id].tokenOwnerAddress = msg.sender;
        crowdsales[_id].receivingWalletAddress = _receivingWalletAddress;
        crowdsales[_id].token = _token;
        crowdsales[_id].cap = _cap;
        crowdsales[_id].openingTime = _openingTime;
        crowdsales[_id].closingTime = _closingTime;
        crowdsales[_id].whitelistable = _whitelistable;
        crowdsales[_id].trackContributions = _trackContributions;
        crowdsales[_id].investorMinCap = _investorMinCap;
        crowdsales[_id].investorHardCap = _investorHardCap;
        crowdsales[_id].crowdsaleTokenSupply = _crowdsaleTokenSupply;
        crowdsales[_id].finalized = false;

        if (_whitelistable) {
            crowdsales[_id].whitelist[msg.sender] = true;
        }        

        crowdsales[_id].token.transferFrom(msg.sender, address(this), _crowdsaleTokenSupply);

        allCrowdsaleIds.push(_id);
        crowdsalesByOwnerAddress[msg.sender].push(_id);

        emit LogCrowdsale(_id, _rate, msg.sender, _receivingWalletAddress, address(_token), _cap, _openingTime, _closingTime, _whitelistable, _trackContributions, _investorMinCap, _investorHardCap, false, block.timestamp);
    }

    function token(uint256 _id) external view returns (ERC20) {
        return crowdsales[_id].token;
    }

    function receivingWalletAddress(uint256 _id) external view returns (address payable) {
        return crowdsales[_id].receivingWalletAddress;
    }

    function rate(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].rate;
    }

    function weiRaised(uint256 _id) public view returns (uint256) {
        return crowdsales[_id].weiRaised;
    }

    receive() external payable {}

    function buyTokens(uint256 _id) external nonReentrant payable {
        uint256 _weiAmount = msg.value;
        _preValidatePurchase(_id, _weiAmount);

        // calculate token amount to be created
        uint256 _tokens = _getTokenAmount(_id, _weiAmount);

        _processPurchase(_id, _tokens);

        _updatePurchasingState(_id, _weiAmount, _tokens);

        emit TokensPurchased(_id, msg.sender, _weiAmount, _tokens, crowdsales[_id].weiRaised);

        _forwardFunds(_id);
    }

    function _preValidatePurchase(uint256 _id, uint256 _weiAmount) internal view {
        require(msg.sender != address(0), "Crowdsale: beneficiary is the zero address");
        require(_weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(isOpen(_id), "Crowdsale: Crowdsale is either closed or has not being opened yet. Thus, no purchasing allowed at this moment.");
        if (crowdsales[_id].whitelistable) {
            require(crowdsales[_id].whitelist[msg.sender], "Crowdsale: purchaser address not whitelisted to participate in this crowdsale");
        }
        if (crowdsales[_id].trackContributions) {
            uint256 _newContribution = crowdsales[_id].contributions[msg.sender].add(_weiAmount);
            require(_newContribution >= crowdsales[_id].investorMinCap && _newContribution <= crowdsales[_id].investorHardCap, "Investor cannot initially buy below below or have a total investment above preset caps. Use getInvestorMinimumCap() or getInvestorMaximumCap() to view caps.");
        }
        require(weiRaised(_id).add(_weiAmount) <= crowdsales[_id].cap, "Crowdsale:Capped cap exceeded");
    }

    function _deliverTokens(uint256 _id, uint256 _tokenAmount) internal {
        crowdsales[_id].token.transfer(msg.sender, _tokenAmount);
    }

    function _processPurchase(uint256 _id, uint256 _tokenAmount) internal {
        _deliverTokens(_id, _tokenAmount);
    }

    function _updatePurchasingState(uint _id, uint _weiAmount, uint _tokens) internal {
        if (crowdsales[_id].trackContributions) {
            crowdsales[_id].contributions[msg.sender] = crowdsales[_id].contributions[msg.sender] + _weiAmount;
        }
        crowdsales[_id].weiRaised = crowdsales[_id].weiRaised.add(_weiAmount);
        crowdsales[_id].tokenBalances[msg.sender] = crowdsales[_id].tokenBalances[msg.sender].add(_tokens);
    }

    function _getTokenAmount(uint256 _id, uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.div(1e18).mul(crowdsales[_id].rate).mul(10 ** crowdsales[_id].token.decimals());
    }

    function _forwardFunds(uint256 _id) internal {
        crowdsales[_id].receivingWalletAddress.transfer(msg.value);
    }

    function cap(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].cap;
    }

    function capReached(uint256 _id) external view returns (bool) {
        return weiRaised(_id) >= crowdsales[_id].cap;
    }

    function openingTime(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].openingTime;
    }

    function closingTime(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].closingTime;
    }

    function isOpen(uint256 _id) public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= crowdsales[_id].openingTime && block.timestamp <= crowdsales[_id].closingTime;
    }

    function hasClosed(uint256 _id) public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > crowdsales[_id].closingTime;
    }

    function extendTime(uint256 _id, uint256 newClosingTime) external {
        require(crowdsales[_id].tokenOwnerAddress == msg.sender, "Crowdsale: Only owner can extend the closing time");
        require(!hasClosed(_id), "Crowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > crowdsales[_id].closingTime, "Crowdsale: new closing time is before current closing time");

        emit CrowdsaleExtended(_id, crowdsales[_id].closingTime, newClosingTime);
        crowdsales[_id].closingTime = newClosingTime;
    }

    function getUserETHContribution(uint256 _id, address _beneficiary) external view returns (uint256) {
        return crowdsales[_id].contributions[_beneficiary];
    }

    function getUserTokenContribution(uint256 _id, address _beneficiary) external view returns (uint) {
        return crowdsales[_id].tokenBalances[_beneficiary];
    }

    function checkIfUserIsWhitelisted(uint256 _id, address _userAddress) external view returns (bool) {
        if (!crowdsales[_id].whitelistable) {
            return true;
        } else {
            return crowdsales[_id].whitelist[_userAddress];
        }
    }

    function grantManyWhitelistRoles(uint256 _id, address[] memory _accounts) external {
        require(crowdsales[_id].tokenOwnerAddress == msg.sender, "Crowdsale: Only owner can grant whitelist previleges");
        if (crowdsales[_id].whitelistable) {
            for (uint256 i = 0; i < _accounts.length; i++) {
                crowdsales[_id].whitelist[_accounts[i]] = true;
            }
        }
    }

    function getInvestorMinimumCap(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].investorMinCap;
    }

    function getInvestorMaximumCap(uint256 _id) external view returns (uint256) {
        return crowdsales[_id].investorHardCap;
    }

    function isPrivate(uint256 _id) external view returns (bool) {
        return crowdsales[_id].whitelistable;
    }

    function getAllCrowdsaleIds() external view returns (uint256[] memory) {
        return allCrowdsaleIds;
    }

    function getCrowdsaleDetailsPartA(uint256 _id) external view returns (uint256 _rate, uint256 _cap, uint256 _weiRaised, uint256 _openingTime, uint256 _closingTime, uint256 _remainingTokenSupply, bool finalized) {
        return (
            crowdsales[_id].rate,
            crowdsales[_id].cap,
            crowdsales[_id].weiRaised,
            crowdsales[_id].openingTime,
            crowdsales[_id].closingTime,
            crowdsales[_id].token.balanceOf(address(this)),
            crowdsales[_id].finalized
        );
    }

    function getCrowdsaleDetailsPartB(uint256 _id) external view returns ( bool _whitelistable, bool _trackContributions, uint256 _investorMinCap, uint256 _investorHardCap, address _tokenOwnerAddress, address _receivingWalletAddress, address _token) {
        return (
            crowdsales[_id].whitelistable,
            crowdsales[_id].trackContributions,
            crowdsales[_id].investorMinCap,
            crowdsales[_id].investorHardCap,
            crowdsales[_id].tokenOwnerAddress,
            crowdsales[_id].receivingWalletAddress,
            address(crowdsales[_id].token)
        );
    }

    function getCrowdsalesByOwnerAddress(address _ownerAddress) external view returns (uint256[] memory) {
        return crowdsalesByOwnerAddress[_ownerAddress];
    }

    function isFinalized(uint256 _id) public view returns (bool) {
        return crowdsales[_id].finalized;
    }

    function finalize(uint256 _id) external {
        require(crowdsales[_id].tokenOwnerAddress == msg.sender, "Crowdsale: Only owner can finalize the crowdsale");
        require(!isFinalized(_id), "Crowdsale: Crowdsale already finalized");
        require(hasClosed(_id), "Crowdsale: Crowdsale not closed");

        crowdsales[_id].finalized = true;
        emit CrowdsaleFinalized(_id);
    }

    function withdrawRemainingTokens(uint256 _id) external nonReentrant {
        require(crowdsales[_id].tokenOwnerAddress == msg.sender, "Crowdsale: Only owner can withdraw tks");
        require(crowdsales[_id].finalized,  "Crowdsale: Crowdsale not finalized yet");
        uint amount = _getTokenAmount(_id, crowdsales[_id].cap.sub(crowdsales[_id].weiRaised));
        _deliverTokens(_id, amount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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