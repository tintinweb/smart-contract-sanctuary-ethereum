// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../LendingPoolToken.sol";
import "./Util.sol";

/// @title Funding contract
/// @dev this library contains all funcionality related to the funding mechanism
/// A borrower creates a new funding request to fund an amount of Lending Pool Token (LPT)
/// A whitelisted primary funder buys LPT from the open funding request with own USDC
/// The treasury wallet is a MultiSig wallet
/// The funding request can be cancelled by the borrower

library Funding {
    /// @dev Emitted when a funding request is added
    /// @param fundingRequestId id of the funding request
    /// @param borrower borrower / creator of the funding request
    /// @param amount amount raised in LendingPoolTokens
    /// @param durationDays duration of the underlying loan
    /// @param interestRate interest rate of the underlying loan
    event FundingRequestAdded(uint256 fundingRequestId, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);

    /// @dev Emitted when a funding request is cancelled
    /// @param fundingRequestId id of the funding request
    event FundingRequestCancelled(uint256 fundingRequestId);

    /// @dev Emitted when a funding request is (partially) filled
    /// @param funder the funder
    /// @param fundingToken the token used to fund
    /// @param fundingTokenAmount the amount funded
    /// @param lendingPoolTokenAmount the amount of LendingPoolTokens the funder received
    event Funded(address indexed funder, IERC20 fundingToken, uint256 fundingTokenAmount, uint256 lendingPoolTokenAmount);

    /// @dev Emitted when a token is added or removed as funding token
    /// @param token the token
    /// @param accepted whether it can be used to fund
    event FundingTokenUpdated(IERC20 token, bool accepted);

    /// @dev Emitted when an address primaryFunder status changes
    /// @param primaryFunder the address
    /// @param accepted whether the address can fund loans
    event PrimaryFunderUpdated(address primaryFunder, bool accepted);

    /// @dev Emitted when an address borrower status changes
    /// @param borrower the address
    /// @param accepted whether the address can borrow from the pool
    event BorrowerUpdated(address borrower, bool accepted);

    /// @dev Contains all state data pertaining to funding
    struct FundingStorage {
        mapping(uint256 => FundingRequest) fundingRequests; //FundingRequest.id => FundingRequest
        uint256 currentFundingRequestId; //id of the next FundingRequest to be proccessed
        uint256 lastFundingRequestId; //id of the last FundingRequest in the
        mapping(address => bool) primaryFunders; //address => whether its allowed to fund loans
        mapping(IERC20 => bool) fundingTokens; //token => whether it can be used to fund loans
        IERC20[] _fundingTokens; //all fundingTokens that can be used to fund loans
        mapping(address => bool) borrowers; //address => whether its allowed to act as borrower / create FundingRequests
        mapping(IERC20 => AggregatorV3Interface) fundingTokenChainLinkFeeds; //fudingToken => ChainLink feed which provides a conversion rate for the fundingToken to the pools loans base currency (e.g. USDC => EURSUD)
        mapping(IERC20 => bool) invertChainLinkFeedAnswer; //fudingToken => whether the data provided by the ChainLink feed should be inverted (not all ChainLink feeds are Token->BaseCurrency, some could be BaseCurrency->Token)
        bool disablePrimaryFunderCheck;
    }
    /// @dev A FundingRequest represents a borrowers desire to raise funds for a loan. (Double linked list)
    struct FundingRequest {
        uint256 id; //id of the funding request
        address borrower; //the borrower who created the funding request
        uint256 amount; //the amount to be raised denominated in LendingPoolTokens
        uint256 durationDays; //duration of the underlying loan in days
        uint256 interestRate; //interest rate of the underlying  loan (2 decimals)
        uint256 amountFilled; //amount that has already been filled by primary funders
        FundingRequestState state; //state of the funding request
        uint256 next; //id of the next funding request
        uint256 prev; //id of the previous funding request
    }

    /// @dev State of a FundingRequest
    enum FundingRequestState {
        OPEN, //the funding request is open and ready to be filled
        FILLED, //the funding request has been filled completely
        CANCELLED //the funding request has been cancelled
    }

    /// @dev modifier to make function callable by borrower only
    modifier onlyBorrower(FundingStorage storage fundingStorage) {
        require(fundingStorage.borrowers[msg.sender], "caller address is no borrower");
        _;
    }

    /// @dev Get all open FundingRequests
    /// @param fundingStorage FundingStorage
    /// @return all open FundingRequests
    function getOpenFundingRequests(FundingStorage storage fundingStorage) external view returns (FundingRequest[] memory) {
        FundingRequest[] memory fundingRequests = new FundingRequest[](fundingStorage.lastFundingRequestId - fundingStorage.currentFundingRequestId + 1);
        uint256 i = fundingStorage.currentFundingRequestId;
        for (; i <= fundingStorage.lastFundingRequestId; i++) {
            fundingRequests[i - fundingStorage.currentFundingRequestId] = fundingStorage.fundingRequests[i];
        }
        return fundingRequests;
    }

    /// @dev Allows borrowers to submit a FundingRequest
    /// @param fundingStorage FundingStorage
    /// @param amount the amount to be raised denominated in LendingPoolTokens
    /// @param durationDays duration of the underlying loan in days
    /// @param interestRate interest rate of the underlying loan (2 decimals)
    function addFundingRequest(
        FundingStorage storage fundingStorage,
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public onlyBorrower(fundingStorage) {
        require(amount > 0 && durationDays > 0 && interestRate > 0, "invalid funding request data");

        uint256 previousFundingRequestId = fundingStorage.lastFundingRequestId;

        uint256 fundingRequestId = ++fundingStorage.lastFundingRequestId;

        if (previousFundingRequestId != 0) {
            fundingStorage.fundingRequests[previousFundingRequestId].next = fundingRequestId;
        }

        emit FundingRequestAdded(fundingRequestId, msg.sender, amount, durationDays, interestRate);

        fundingStorage.fundingRequests[fundingRequestId] = FundingRequest(
            fundingRequestId,
            msg.sender,
            amount,
            durationDays,
            interestRate,
            0,
            FundingRequestState.OPEN,
            0,
            previousFundingRequestId
        );

        if (fundingStorage.currentFundingRequestId == 0) {
            fundingStorage.currentFundingRequestId = fundingStorage.lastFundingRequestId;
        }
    }

    /// @dev Allows borrowers to cancel their own funding request as long as it has not been partially or fully filled
    /// @param fundingStorage FundingStorage
    /// @param fundingRequestId the id of the funding request to cancel
    function cancelFundingRequest(FundingStorage storage fundingStorage, uint256 fundingRequestId) public {
        require(fundingStorage.fundingRequests[fundingRequestId].id != 0, "funding request not found");

        emit FundingRequestCancelled(fundingRequestId);

        fundingStorage.fundingRequests[fundingRequestId].state = FundingRequestState.CANCELLED;

        FundingRequest storage currentRequest = fundingStorage.fundingRequests[fundingRequestId];

        if (currentRequest.prev != 0) {
            fundingStorage.fundingRequests[currentRequest.prev].next = currentRequest.next;
        }

        if (currentRequest.next != 0) {
            fundingStorage.fundingRequests[currentRequest.next].prev = currentRequest.prev;
        }

        uint256 saveNext = fundingStorage.fundingRequests[fundingRequestId].next;
        fundingStorage.fundingRequests[fundingRequestId].prev = 0;
        fundingStorage.fundingRequests[fundingRequestId].next = 0;

        if (fundingStorage.currentFundingRequestId == fundingRequestId) {
            fundingStorage.currentFundingRequestId = saveNext; // can be zero which is fine
        }
    }

    /// @dev Allows primary funders to fund borrowers fundingRequests. In return for their
    ///      funding they receive LendingPoolTokens based on the rate provided by the configured ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken token used for the funding (e.g. USDC)
    /// @param fundingTokenAmount funding amount
    /// @param lendingPoolToken the LendingPoolToken which will be minted to the funders wallet in return
    function fund(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        LendingPoolToken lendingPoolToken
    ) public {
        require(fundingStorage.primaryFunders[msg.sender] || fundingStorage.disablePrimaryFunderCheck, "address is not primary funder");
        require(fundingStorage.fundingTokens[fundingToken], "unrecognized funding token");
        require(fundingStorage.currentFundingRequestId != 0, "no active funding request");

        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getExchangeRate(fundingStorage, fundingToken);

        FundingRequest storage currentFundingRequest = fundingStorage.fundingRequests[fundingStorage.currentFundingRequestId];
        uint256 currentFundingNeedInLPT = currentFundingRequest.amount - currentFundingRequest.amountFilled;

        uint256 currentFundingNeedInFundingToken = (Util.convertDecimalsERC20(currentFundingNeedInLPT, lendingPoolToken, fundingToken) * exchangeRate) /
            (uint256(10)**exchangeRateDecimals);

        uint256 lendingPoolTokenAmount = 0;

        if (fundingTokenAmount > currentFundingNeedInFundingToken) {
            fundingTokenAmount = currentFundingNeedInFundingToken;
            lendingPoolTokenAmount = currentFundingNeedInLPT;
        } else {
            lendingPoolTokenAmount = ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, lendingPoolToken) * (uint256(10)**exchangeRateDecimals)) / exchangeRate);
        }

        Util.checkedTransferFrom(fundingToken, msg.sender, currentFundingRequest.borrower, fundingTokenAmount);
        currentFundingRequest.amountFilled += lendingPoolTokenAmount;

        if (currentFundingRequest.amount == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;

            fundingStorage.currentFundingRequestId = currentFundingRequest.next; // this can be zero which is ok
        }

        lendingPoolToken.mint(msg.sender, lendingPoolTokenAmount);
        emit Funded(msg.sender, fundingToken, fundingTokenAmount, lendingPoolTokenAmount);
    }

    /// @dev Returns an exchange rate to convert from a funding token to the pools underlying loan currency
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(FundingStorage storage fundingStorage, IERC20 fundingToken) public view returns (uint256, uint8) {
        require(address(fundingStorage.fundingTokenChainLinkFeeds[fundingToken]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingStorage.fundingTokenChainLinkFeeds[fundingToken].decimals();

        if (fundingStorage.invertChainLinkFeedAnswer[fundingToken]) {
            exchangeRate = int256(10**(exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    /// @dev Maps a funding token to a ChainLinkFeed
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the fundingToken
    /// @param fundingTokenChainLinkFeed the ChainLink price feed
    /// @param invertChainLinkFeedAnswer whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setFundingTokenChainLinkFeed(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        AggregatorV3Interface fundingTokenChainLinkFeed,
        bool invertChainLinkFeedAnswer
    ) external {
        fundingStorage.fundingTokenChainLinkFeeds[fundingToken] = fundingTokenChainLinkFeed;
        fundingStorage.invertChainLinkFeedAnswer[fundingToken] = invertChainLinkFeedAnswer;
    }

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingStorage FundingStorage
    /// @param fundingToken the token
    /// @param accepted whether it is accepted
    function setFundingToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        bool accepted
    ) public {
        if (fundingStorage.fundingTokens[fundingToken] != accepted) {
            fundingStorage.fundingTokens[fundingToken] = accepted;
            emit FundingTokenUpdated(fundingToken, accepted);
            if (accepted) {
                fundingStorage._fundingTokens.push(fundingToken);
            } else {
                Util.removeValueFromArray(fundingToken, fundingStorage._fundingTokens);
            }
        }
    }

    /// @dev Change primaryFunder status of an address
    /// @param fundingStorage FundingStorage
    /// @param primaryFunder the address
    /// @param accepted whether its accepted as primaryFunder
    function setPrimaryFunder(
        FundingStorage storage fundingStorage,
        address primaryFunder,
        bool accepted
    ) public {
        if (fundingStorage.primaryFunders[primaryFunder] != accepted) {
            fundingStorage.primaryFunders[primaryFunder] = accepted;
            emit PrimaryFunderUpdated(primaryFunder, accepted);
        }
    }

    /// @dev Change borrower status of an address
    /// @param fundingStorage FundingStorage
    /// @param borrower the borrower address
    /// @param accepted whether the address is a borrower
    function setBorrower(
        FundingStorage storage fundingStorage,
        address borrower,
        bool accepted
    ) public {
        if (fundingStorage.borrowers[borrower] != accepted) {
            fundingStorage.borrowers[borrower] = accepted;
            emit BorrowerUpdated(borrower, accepted);
            if (fundingStorage.borrowers[msg.sender]) {
                fundingStorage.borrowers[msg.sender] = false;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LendingPoolToken
/// @author Florence Finance
/// @dev Every LendingPool has its own LendingPoolToken which can be minted and burned by the LendingPool
contract LendingPoolToken is ERC20, Ownable {
    /// @dev
    /// @param _lendingPoolId (uint256) id of the LendingPool this token belongs to
    /// @param _name (string) name of the token (see ERC20)
    /// @param _symbol (string) symbol of the token (see ERC20)
    // solhint-disable-next-line
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @dev Allows owner to mint tokens.
    /// @param _receiver (address) receiver of the minted tokens
    /// @param _amount (uint256) the amount to mint (18 decimals)
    function mint(address _receiver, uint256 _amount) external onlyOwner {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _mint(_receiver, _amount);
    }

    /// @dev Allows owner to burn tokens.
    /// @param _amount (uint256) the amount to burn (18 decimals)
    function burn(uint256 _amount) external {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _burn(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library Util {
    /// @dev Return the decimals of an ERC20 token (if the implementations offers it)
    /// @param _token (IERC20) the ERC20 token
    /// @return  (uint8) the decimals
    function getERC20Decimals(IERC20 _token) internal view returns (uint8) {
        return IERC20Metadata(address(_token)).decimals();
    }

    function checkedTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransferFrom: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transferFrom(from, to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransferFrom: not amount");
        return receivedAmount;
    }

    /// @dev A checked Token transfer; raises if the token transfer amount is not equal to the transferred amount
    /// this might happen if the token ERC20 contract is hacked
    /// @param token (address) the address of the ERC20 token to transfer
    /// @param to (address) receiver address
    /// @param amount (uint256) the desired amount to transfer
    /// @return  (uint256) the received amount that was transferred
    /// IMPORTANT: the return value will only be returned to another smart contract,
    /// but never to the testing environment, because if the transaction goes through,
    /// a receipt is returned and not a (uint256)
    function checkedTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        require(amount > 0, "checkedTransfer: amount zero");
        uint256 balanceBefore = token.balanceOf(to);
        token.transfer(to, amount);
        uint256 receivedAmount = token.balanceOf(to) - balanceBefore;
        require(receivedAmount == amount, "checkedTransfer: not amount");
        return receivedAmount;
    }

    /// @dev Converts a number from one decimal precision to the other
    /// @param _number (uint256) the number
    /// @param _currentDecimals (uint256) the current decimals of the number
    /// @param _targetDecimals (uint256) the desired decimals for the number
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimals(
        uint256 _number,
        uint256 _currentDecimals,
        uint256 _targetDecimals
    ) internal pure returns (uint256) {
        uint256 diffDecimals;

        uint256 amountCorrected = _number;

        if (_targetDecimals < _currentDecimals) {
            diffDecimals = _currentDecimals - _targetDecimals;
            amountCorrected = _number / (uint256(10)**diffDecimals);
        } else if (_targetDecimals > _currentDecimals) {
            diffDecimals = _targetDecimals - _currentDecimals;
            amountCorrected = _number * (uint256(10)**diffDecimals);
        }

        return (amountCorrected);
    }

    /// @dev Converts a number from one decimal precision to the other based on two ERC20 Tokens
    /// @param _number (uint256) the number
    /// @param _sourceToken (address) the source ERC20 Token
    /// @param _targetToken (address) the target ERC20 Token
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimalsERC20(
        uint256 _number,
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) internal view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function removeValueFromArray(IERC20 value, IERC20[] storage array) internal {
        bool shift = false;
        uint256 i = 0;
        while (i < array.length - 1) {
            if (array[i] == value) shift = true;
            if (shift) {
                array[i] = array[i + 1];
            }
            i++;
        }
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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