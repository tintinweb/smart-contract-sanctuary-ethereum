// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
pragma solidity 0.8.17;

/**
 * @title Investment Fund interface
 */
interface IInvestmentFund {
    /**
     * @dev Emitted when user invests in fund
     * @param investor Investor address
     * @param currency Currency used for investment
     * @param value Amount of tokens spent for investment
     * @param fee Amount of tokens spent for fee
     */
    event Invested(address indexed investor, address indexed currency, uint256 value, uint256 fee);

    /**
     * @dev Emitted when investment cap is reached
     * @param investor Investor address
     * @param currency Currency used for investment
     * @param amount Amount of tokens invested
     * @param cap Cap value
     */
    event CapReached(address indexed investor, address currency, uint256 amount, uint256 cap);

    /**
     * @dev Invests `amount` number of USD Coin tokens to investment fund.
     *
     * Requirements:
     * - `amount` must be greater than zero.
     * - Caller must have been allowed in USD Coin to move this token by {approve}.
     *
     * Emits a {Invested} event.
     *
     * @param amount Amount of tokens to be invested
     */
    function invest(uint240 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestmentNFT {
    function mint(address to, uint256 value) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IInvestmentFund.sol";
import "./IInvestmentNFT.sol";
import "./LibFund.sol";
import "./StateMachine.sol";

/**
 * @title Investment Fund contract
 */
contract InvestmentFund is StateMachine, IInvestmentFund, ReentrancyGuard {
    string public name;
    IERC20 public currency;
    IInvestmentNFT public investmentNft;
    address public treasuryWallet;
    uint16 public managementFee;
    uint256 public cap;

    /**
     * @dev Emitted when currency is changed
     * @param caller Address that changes currency
     * @param oldCurrency Old currency
     * @param newCurrency New currency
     */
    event CurrencyChanged(address indexed caller, address indexed oldCurrency, address indexed newCurrency);

    /**
     * @dev Emitted when Investment NFT contract is changed
     * @param caller Address that changes contract
     * @param oldNFT Old investment NFT contract
     * @param newNFT New investment NFT contract
     */
    event InvestmentNFTChanged(address indexed caller, address indexed oldNFT, address indexed newNFT);

    /**
     * @dev Initializes the contract by setting a `name`, `currency` and `investment NFT` to investment fund
     * @param name_ Investment fund name
     * @param currency_ Address of currency for investments
     * @param investmentNft_ Address of investment NFT contract
     */
    constructor(
        string memory name_,
        address currency_,
        address investmentNft_,
        address treasuryWallet_,
        uint16 managementFee_,
        uint256 cap_
    ) StateMachine(LibFund.STATE_EMPTY) {
        require(currency_ != address(0), "Invalid currency address");
        require(investmentNft_ != address(0), "Invalid NFT address");
        require(treasuryWallet_ != address(0), "Invalid treasury wallet address");
        require(managementFee_ < 10000, "Invalid management fee");
        require(cap_ > 0, "Invalid investment cap");

        name = name_;
        currency = IERC20(currency_);
        investmentNft = IInvestmentNFT(investmentNft_);
        treasuryWallet = treasuryWallet_;
        managementFee = managementFee_;
        cap = cap_;

        initializeStates();
    }

    /**
     * @dev Sets currency address
     * @param currency_ New currency address
     */
    function setCurrency(address currency_) external {
        address oldCurrency = address(currency);
        currency = IERC20(currency_);
        emit CurrencyChanged(msg.sender, oldCurrency, currency_);
    }

    /**
     * @dev Sets investment NFT address
     * @param nft_ New Investment NFT address
     */
    function setInvestmentNft(address nft_) external {
        address oldNFT = address(investmentNft);
        investmentNft = IInvestmentNFT(nft_);
        emit InvestmentNFTChanged(msg.sender, oldNFT, nft_);
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function invest(uint240 amount) external override onlyAllowedStates nonReentrant {
        require(amount > 0, "Invalid amount invested");

        uint256 fee = (uint256(amount) * managementFee) / LibFund.FEE_DIVISOR;
        uint256 investment = amount - fee;
        uint256 newTotalInvested = currency.balanceOf(address(this)) + investment;
        require(newTotalInvested <= cap, "Total invested funds exceed cap");

        if (newTotalInvested >= cap) {
            currentState = LibFund.STATE_CAP_REACHED;
            emit CapReached(msg.sender, address(currency), investment, cap);
        }

        _makeInvestment(msg.sender, investment, fee);
    }

    function addProject() external onlyAllowedStates {
        // todo: limit access
    }

    function startCollectingFunds() external onlyAllowedStates {
        // todo: limit access
        currentState = LibFund.STATE_FUNDS_IN;
    }

    function stopCollectingFunds() external onlyAllowedStates {
        // todo: limit access
        currentState = LibFund.STATE_CAP_REACHED;
    }

    function deployFunds() external onlyAllowedStates {
        // todo: limit access
        currentState = LibFund.STATE_FUNDS_DEPLOYED;
    }

    function activateFund() external onlyAllowedStates {
        // todo: limit access
        currentState = LibFund.STATE_ACTIVE;
    }

    function provideProfits() external onlyAllowedStates {
        // todo: limit access
        // todo: if breakeven reached go to Breakeven state
    }

    function closeFund() external onlyAllowedStates {
        // todo: limit access
        currentState = LibFund.STATE_CLOSED;
    }

    function initializeStates() internal {
        allowFunction(LibFund.STATE_EMPTY, this.addProject.selector);
        allowFunction(LibFund.STATE_EMPTY, this.startCollectingFunds.selector);
        allowFunction(LibFund.STATE_FUNDS_IN, this.invest.selector);
        allowFunction(LibFund.STATE_FUNDS_IN, this.stopCollectingFunds.selector);
        allowFunction(LibFund.STATE_CAP_REACHED, this.deployFunds.selector);
        allowFunction(LibFund.STATE_FUNDS_DEPLOYED, this.activateFund.selector);
        allowFunction(LibFund.STATE_ACTIVE, this.provideProfits.selector);
        allowFunction(LibFund.STATE_ACTIVE, this.closeFund.selector);
        allowFunction(LibFund.STATE_BREAKEVEN, this.provideProfits.selector);
        allowFunction(LibFund.STATE_BREAKEVEN, this.closeFund.selector);
    }

    function _makeInvestment(address investor, uint256 value, uint256 fee) internal {
        emit Invested(msg.sender, address(currency), value, fee);

        require(currency.transferFrom(investor, treasuryWallet, fee), "Currency fee transfer failed");
        require(currency.transferFrom(investor, address(this), value), "Currency transfer failed");
        investmentNft.mint(investor, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibFund {
    uint256 public constant FEE_DIVISOR = 10000;

    bytes32 public constant STATE_EMPTY = "Empty";
    bytes32 public constant STATE_FUNDS_IN = "FundsIn";
    bytes32 public constant STATE_CAP_REACHED = "CapReached";
    bytes32 public constant STATE_FUNDS_DEPLOYED = "FundsDeployed";
    bytes32 public constant STATE_ACTIVE = "Active";
    bytes32 public constant STATE_BREAKEVEN = "Breakeven";
    bytes32 public constant STATE_CLOSED = "Closed";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IInvestmentFund.sol";
import "./IInvestmentNFT.sol";
import "./LibFund.sol";

contract StateMachine {
    bytes32 public currentState;
    mapping(bytes32 => mapping(bytes4 => bool)) internal functionsAllowed;

    /**
     * @dev Limits access for current state
     * @dev Only functions allowed using allowFunction are permitted
     */
    modifier onlyAllowedStates() {
        require(functionsAllowed[currentState][msg.sig], "Not allowed in current state");
        _;
    }

    constructor(bytes32 initialState) {
        currentState = initialState;
    }

    function allowFunction(bytes32 state, bytes4 selector) internal {
        functionsAllowed[state][selector] = true;
    }
}