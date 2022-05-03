// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ILendingPoolToken.sol";
import "./Util.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Funding contract
/// @dev this library contains all funcionality related to the funding mechanism
/// A borrower creates a new funding request to fund an amount of Lending Pool Token (LPT)
/// A whitelisted primary funder buys LPT from the open funding request with own USDC
/// The treasury wallet is a MultiSig wallet
/// The funding request can be cancelled by the borrower

library Funding {
    event FundingRequestAdded(uint256 id, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);
    event FundingRequestCancelled(
        uint256 fundingRequestId,
        uint256 fundingRequestAmount,
        uint256 fundingRequestAmountFilled,
        uint256 latestFundingRequestId
    );
    event Funded(
        address indexed funder,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        uint256 lendingPoolTokenAmount
    );
    event LendingPoolTokensRedeemed(
        address redeemer,
        uint256 lendingPoolTokenAmount,
        IERC20 principalToken,
        uint256 principalTokenAmount
    );

    event PrincipalDeposited(address depositor, uint256 amount);

    event PrincipalTransferedToTreasury(uint256 amount);

    event FundingTokenUpdated(IERC20 token, bool accepted);

    event PrimaryFunderUpdated(address primaryFunder, bool accepted);

    event BorrowerUpdated(address borrower, bool accepted);

    enum FundingRequestState {
        OPEN,
        FILLED,
        CANCELLED
    }

    struct FundingRequest {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 durationDays;
        uint256 interestRate;
        uint256 amountFilled;
        FundingRequestState state;
        uint256 next; // ID of next exntry
        uint256 prev; // ID of previous entry
    }

    struct FundingStorage {
        mapping(uint256 => FundingRequest) fundingRequests;
        uint256 currentID; // current funding request ID
        uint256 lastID; // last given funding request ID
        /// @dev addresses of primary funders and their whitelist status
        mapping(address => bool) primaryFunders;
        /// @dev tokens the pool can be funded with
        mapping(IERC20 => bool) fundingTokens;
        IERC20[] _fundingTokens;
        /// @dev amount of principal capital ready to be used for LendingPoolToken redemption
        uint256 availablePrincipal;
        /// @dev token the of the principal capital
        IERC20 principalToken;
        /// @dev addresses of borrowers and their status
        mapping(address => bool) borrowers;
        /// @dev
        mapping(IERC20 => AggregatorV3Interface) tokenChainlinkFeedMapping;
        /// @dev
        mapping(IERC20 => bool) invertExchangeRate;
    }

    /// @dev get array of funding requests
    /// @param fundingStorage pointer to funding storage struct
    /// @return Array including all funding request structs
    function getFundingRequests(FundingStorage storage fundingStorage) external view returns (FundingRequest[] memory) {
        uint256 amountFundingRequests = fundingStorage.lastID - fundingStorage.currentID;
        FundingRequest[] memory fundingRequestArray = new FundingRequest[](amountFundingRequests + 1);
        uint256 j = 0;
        for (uint256 i = fundingStorage.currentID; i <= fundingStorage.lastID; i++) {
            FundingRequest storage fundingRequest = fundingStorage.fundingRequests[i];
            fundingRequestArray[j++] = fundingRequest;
        }
        return fundingRequestArray;
    }

    /// @dev Add funding request
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount total amount of LPT to request funding for
    /// @param durationDays the duration of the funding request (e.g. three months)
    /// @param interestRate the announced interest rate for the funding
    function addFundingRequest(
        FundingStorage storage fundingStorage,
        uint256 amount,
        uint256 durationDays,
        uint256 interestRate
    ) public {
        require(amount > 0 && durationDays > 0 && interestRate > 0, "invalid funding request data");

        uint256 prevLastID = fundingStorage.lastID;

        fundingStorage.lastID++;

        if (prevLastID != 0) {
            fundingStorage.fundingRequests[prevLastID].next = fundingStorage.lastID;
        }

        emit FundingRequestAdded(fundingStorage.lastID, msg.sender, amount, durationDays, interestRate);

        fundingStorage.fundingRequests[fundingStorage.lastID] = FundingRequest(
            fundingStorage.lastID,
            msg.sender,
            amount,
            durationDays,
            interestRate,
            0,
            FundingRequestState.OPEN,
            0, // next ID
            prevLastID // prev ID
        );

        if (fundingStorage.currentID == 0) {
            fundingStorage.currentID = fundingStorage.lastID;
        }
    }

    /// @dev Cancel a funding request
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingRequestId the id of the funding request to cancel
    function cancelFundingRequest(FundingStorage storage fundingStorage, uint256 fundingRequestId) public {
        require(fundingStorage.fundingRequests[fundingRequestId].id != 0, "funding request not found");
        require(
            fundingStorage.fundingRequests[fundingRequestId].state == FundingRequestState.OPEN,
            "funding request already processing"
        );

        emit FundingRequestCancelled(
            fundingRequestId,
            fundingStorage.fundingRequests[fundingRequestId].amount,
            fundingStorage.fundingRequests[fundingRequestId].amountFilled,
            fundingStorage.lastID
        );

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

        if (fundingStorage.currentID == fundingRequestId) {
            fundingStorage.currentID = saveNext; // can be zero which is fine
        }
    }

    /// @dev Allows primary funders to fund the pool
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingToken token used for the funding (e.g. USDC)
    /// @param fundingTokenAmount funding amount
    /// @param lendingPoolToken the Lending Pool Token
    function fund(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        ILendingPoolToken lendingPoolToken
    ) public {
        require(fundingStorage.primaryFunders[msg.sender], "address is not primary funder");
        require(fundingStorage.fundingTokens[fundingToken], "unrecognized funding token");
        require(fundingStorage.currentID != 0, "no active funding request");

        uint256 lendingPoolTokenAmount = convertFundingTokenToLendingPoolToken(
            fundingStorage,
            fundingToken,
            fundingTokenAmount,
            lendingPoolToken
        );

        FundingRequest storage currentFundingRequest = fundingStorage.fundingRequests[fundingStorage.currentID];
        uint256 currentFundingNeed = currentFundingRequest.amount - currentFundingRequest.amountFilled;

        require(lendingPoolTokenAmount <= currentFundingNeed, "amount exceeds requested funding");
        Util.checkedTransferFrom(fundingToken, msg.sender, currentFundingRequest.borrower, fundingTokenAmount);
        currentFundingRequest.amountFilled += lendingPoolTokenAmount;

        if (currentFundingRequest.amount == currentFundingRequest.amountFilled) {
            currentFundingRequest.state = FundingRequestState.FILLED;

            fundingStorage.currentID = currentFundingRequest.next; // this can be zero which is ok
        }

        lendingPoolToken.mint(msg.sender, lendingPoolTokenAmount);
        emit Funded(msg.sender, fundingToken, fundingTokenAmount, lendingPoolTokenAmount);
    }

    /// @dev Get an exchange rate for an ERC20<>Currnecy conversion
    /// @param fundingStorage pointer to funding storage struct
    /// @param token the token
    /// @return the exchange rate and the decimals of the exchange rate
    function getExchangeRate(FundingStorage storage fundingStorage, IERC20 token) public view returns (uint256, uint8) {
        require(address(fundingStorage.tokenChainlinkFeedMapping[token]) != address(0), "no exchange rate available");

        (, int256 exchangeRate, , , ) = fundingStorage.tokenChainlinkFeedMapping[token].latestRoundData();
        require(exchangeRate != 0, "zero exchange rate");

        uint8 exchangeRateDecimals = fundingStorage.tokenChainlinkFeedMapping[token].decimals();

        if (fundingStorage.invertExchangeRate[token]) {
            exchangeRate = int256(10**(exchangeRateDecimals * 2)) / exchangeRate;
        }

        return (uint256(exchangeRate), exchangeRateDecimals);
    }

    /// @dev Adds a mapping between a token, currency and ChainLink price feed
    /// @param fundingStorage pointer to funding storage struct
    /// @param token the token
    /// @param chainLinkFeed the ChainLink price feed
    /// @param _invertExchangeRate whether the rate returned by the chainLinkFeed needs to be inverted to match the token-currency pair order
    function setTokenChainLinkFeedMapping(
        FundingStorage storage fundingStorage,
        IERC20 token,
        AggregatorV3Interface chainLinkFeed,
        bool _invertExchangeRate
    ) external {
        fundingStorage.tokenChainlinkFeedMapping[token] = chainLinkFeed;
        fundingStorage.invertExchangeRate[token] = _invertExchangeRate;
    }

    /// @dev Converts amount of fundingToken to LendingPoolToken using ExchangeRateProvider
    /// @param fundingStorage pointer to funding storage struct
    /// @param fundingToken the funding token
    /// @param fundingTokenAmount the amount to be converted
    /// @param lendingPoolToken the Lending Pool Token
    /// @return the amount of lendingPoolTokens (LendingPoolToken decimals (18))
    function convertFundingTokenToLendingPoolToken(
        FundingStorage storage fundingStorage,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        ILendingPoolToken lendingPoolToken
    ) private view returns (uint256) {
        (uint256 exchangeRate, uint256 exchangeRateDecimals) = getExchangeRate(fundingStorage, fundingToken);
        return ((Util.convertDecimalsERC20(fundingTokenAmount, fundingToken, lendingPoolToken) *
            (uint256(10)**exchangeRateDecimals)) / exchangeRate);
    }

    /// @dev Allows the deposit of principal funds. This is usually used by the borrower or treasury
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount the amount of principal (principalToken decimals)
    function depositPrincipal(FundingStorage storage fundingStorage, uint256 amount) public {
        fundingStorage.availablePrincipal += Util.checkedTransferFrom(
            fundingStorage.principalToken,
            msg.sender,
            address(this),
            amount
        );
        emit PrincipalDeposited(msg.sender, amount);
    }

    /// @dev Allows the withdrawal of principal funds to the treasury
    /// @param fundingStorage pointer to funding storage struct
    /// @param amount the amount to be withdrawn
    /// @param treasury the treasury address
    function transferPrincipalToTreasury(
        FundingStorage storage fundingStorage,
        uint256 amount,
        address treasury
    ) public {
        require(amount <= fundingStorage.availablePrincipal, "amount exceeds available principal");
        fundingStorage.availablePrincipal -= Util.checkedTransfer(fundingStorage.principalToken, treasury, amount);
        emit PrincipalTransferedToTreasury(amount);
    }

    /// @dev Set whether a token should be accepted for funding the pool
    /// @param fundingStorage pointer to funding storage struct
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
    /// @param fundingStorage pointer to funding storage struct
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
    /// @param fundingStorage pointer to funding storage struct
    /// @param borrower the borrower address
    /// @param accepted whether its accepted as primaryFunder (true or false)
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the Lending Pool contract and IERC20 standard as defined in the EIP.
 */
interface ILendingPoolToken is IERC20Metadata {
    function mint(address _address, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/ILendingPool.sol";

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

    function checkedTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) public returns (uint256) {
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
    ) public pure returns (uint256) {
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

    function convertDecimalsERC20(
        uint256 _number,
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) public view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function percent(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) public pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = numerator * 10**(precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function removeValueFromArray(IERC20 value, IERC20[] storage array) public {
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

// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the Lending Pool contract and IERC20 standard as defined in the EIP.
 */
interface ILendingPool {
    event LendingPoolInitialized(address _address, string id, address lendingPoolToken);
    event FundingTokenUpdated(IERC20 token, bool accepted);
    event PrimaryFunderUpdated(address primaryFunder, bool accepted);
    event BorrowerUpdated(address borrower, bool accepted);
    event FundingRequestAdded(uint256 id, address borrower, uint256 amount, uint256 durationDays, uint256 interestRate);
    event FundingRequestCancelled(
        uint256 fundingRequestId,
        uint256 fundingRequestAmount,
        uint256 fundingRequestAmountFilled,
        uint256 latestFundingRequestId
    );

    event RewardTokensPerBlockUpdated(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 oldRewardTokensPerBlock,
        uint256 newRewardTokensPerBlock
    );
    event RewardsLockedUpdated(IERC20 stakedToken, IERC20 rewardToken, bool rewardsLocked);

    event Funded(
        address indexed funder,
        IERC20 fundingToken,
        uint256 fundingTokenAmount,
        uint256 lendingPoolTokenAmount
    );
    event PrincipalDeposited(address depositor, uint256 amount);
    event RewardsDeposited(address depositor, IERC20 rewardToken, uint256 amount);

    event PrincipalTransferedToTreasury(uint256 amount);
    event RewardsTransferedToTreasury(IERC20 rewardToken, uint256 amount);
    event LendingPoolTokensRedeemed(
        address redeemer,
        uint256 lendingPoolTokenAmount,
        IERC20 principalToken,
        uint256 principalTokenAmount
    );

    event StakedLinear(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedLinear(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsLinear(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);

    event StakedPeriod(address indexed staker, IERC20 indexed stakableToken, uint256 amount);
    event UnstakedPeriod(address indexed unstaker, IERC20 indexed stakedToken, uint256 amount);
    event ClaimedRewardsPeriod(address indexed claimer, IERC20 stakedToken, IERC20 rewardToken, uint256 amount);
}