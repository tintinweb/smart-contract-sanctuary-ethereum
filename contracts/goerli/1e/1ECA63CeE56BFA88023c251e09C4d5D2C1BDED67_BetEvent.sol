// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC20.sol";
import "AllowTokens.sol";
import "TokenValue.sol";

contract BetEvent is AllowTokens, TokenValue {
    enum OPERATOR {
        GREATER,
        LESSER
    }

    enum STATE {
        OPEN,
        MATCHED,
        CLOSED
    }

    // INFO odds expressed with 2 decimals
    // es: 2,25 -> 225
    struct Bet {
        uint256 id;
        uint256 betAmount;
        address betToken;
        uint256 odds;
        uint256 pricePrediction;
        address tokenPrediction;
        OPERATOR operator;
        STATE state;
        uint256 creationTime;
        uint256 stopBetTime;
        uint256 endTime;
        address backer;
        address layer;
    }

    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) public user_betIds;

    uint256 public betCounter;
    uint256 public totalValueLocked;
    // INFO protocolCommissions expressed with 2 decimals
    uint256 public protocolCommission;

    event BetCreated(
        address backer,
        uint256 id,
        uint256 betAmount,
        address betToken,
        uint256 odds,
        uint256 pricePrediction,
        address tokenPrediction,
        OPERATOR operator,
        uint256 creationTime,
        uint256 stopBetTime,
        uint256 endTime
    );
    event BetMatched(uint256 betId, address layer, uint256 layAmount);
    event BetNotMatched(uint256 betId);
    event BetClosed(
        uint256 betId,
        uint256 backerProfit,
        uint256 layerProfit,
        uint256 commission
    );

    constructor() {
        betCounter = 0;
        totalValueLocked = 0;
        protocolCommission = 300;
    }

    function createBet(
        uint256 betAmount,
        address betToken,
        uint256 odds,
        uint256 pricePrediction,
        address tokenPrediction,
        OPERATOR operator,
        uint256 timeDuration
    ) external {
        require(
            isTokenAllowed(betToken),
            "Cannot bet pay your Bet with this token. Token not allowed"
        );
        require(
            isTokenAllowed(tokenPrediction),
            "Cannot bet on this token. Token not allowed"
        );
        require(
            odds > 100 && odds <= 10000,
            "Odds must be between 100 and 10000"
        );
        require(pricePrediction > 0, "Price prediction must be more than 0");
        require(betAmount > 0, "Bet amount must be more than 0");

        Bet memory bet = Bet(
            betCounter,
            betAmount,
            betToken,
            odds,
            pricePrediction,
            tokenPrediction,
            operator,
            STATE.OPEN,
            block.timestamp,
            block.timestamp + timeDuration / 2,
            block.timestamp + timeDuration,
            msg.sender,
            address(0)
        );

        bets[betCounter] = bet;
        user_betIds[msg.sender].push(betCounter);
        betCounter++;
        totalValueLocked += getValueFromToken(betAmount, betToken);

        IERC20(betToken).transferFrom(msg.sender, address(this), betAmount);

        emit BetCreated(
            msg.sender,
            betCounter,
            betAmount,
            betToken,
            odds,
            pricePrediction,
            tokenPrediction,
            operator,
            block.timestamp,
            block.timestamp + timeDuration / 2,
            block.timestamp + timeDuration
        );
    }

    function matchBet(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(bet.state == STATE.OPEN, "Bet is not open");
        require(
            block.timestamp < bet.endTime,
            "Cannot match bet after end time"
        );
        require(
            block.timestamp < bet.stopBetTime,
            "Cannot match bet after stop bet time"
        );

        uint256 layAmount = (bet.betAmount * 100) / (bet.odds - 100);
        bet.state = STATE.MATCHED;
        bet.layer = msg.sender;
        user_betIds[msg.sender].push(betId);
        totalValueLocked += layAmount;

        IERC20(bet.betToken).transferFrom(msg.sender, address(this), layAmount);

        emit BetMatched(betId, msg.sender, layAmount);
    }

    // INFO backer can withdraw his bet if bet is not matched
    function stopBetting(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(bet.state == STATE.OPEN, "Bet is not open");
        require(
            block.timestamp >= bet.stopBetTime,
            "Cannot stop betting before stop bet time"
        );

        if (bet.state == STATE.OPEN) {
            bet.state = STATE.CLOSED;
            totalValueLocked -= bet.betAmount;
            IERC20(bet.betToken).transfer(bet.backer, bet.betAmount);
            emit BetNotMatched(betId);
        }
    }

    function closeBet(uint256 betId) external onlyOwner {
        Bet storage bet = bets[betId];
        require(bet.state == STATE.MATCHED, "Bet is not matched");
        require(
            block.timestamp >= bet.endTime,
            "Cannot close bet before end time"
        );

        uint256 price = getValueFromToken(1 ether, bet.betToken);
        uint256 backerProfit;
        uint256 layerProfit;
        uint256 protocolProfit;

        uint256 layPrice = (bet.betAmount * 100) / (bet.odds - 100);
        uint256 layCommissionPrice = (layPrice * protocolCommission) / 100;
        uint256 backCommissionPrice = (bet.betAmount * protocolCommission) /
            100;

        bet.state = STATE.CLOSED;
        totalValueLocked -= backerProfit + layerProfit + protocolProfit;
        for (uint256 i = 0; i < user_betIds[bet.backer].length; i++) {
            if (user_betIds[bet.backer][i] == betId) {
                user_betIds[bet.backer][i] = user_betIds[bet.backer][
                    user_betIds[bet.backer].length - 1
                ];
                user_betIds[bet.backer].pop();
                break;
            }
        }
        for (uint256 i = 0; i < user_betIds[bet.layer].length; i++) {
            if (user_betIds[bet.layer][i] == betId) {
                user_betIds[bet.layer][i] = user_betIds[bet.layer][
                    user_betIds[bet.layer].length - 1
                ];
                user_betIds[bet.layer].pop();
                break;
            }
        }

        if (bet.operator == OPERATOR.GREATER) {
            if (price > bet.pricePrediction) {
                backerProfit = layPrice - layCommissionPrice;
                IERC20(bet.betToken).transfer(bet.backer, backerProfit);
                protocolProfit = layCommissionPrice;
            } else {
                layerProfit = bet.betAmount - backCommissionPrice;
                IERC20(bet.betToken).transfer(bet.layer, layerProfit);
                protocolProfit = backCommissionPrice;
            }
        } else {
            if (price < bet.pricePrediction) {
                backerProfit = layPrice - layCommissionPrice;
                IERC20(bet.betToken).transfer(bet.backer, backerProfit);
                protocolProfit = layCommissionPrice;
            } else {
                layerProfit = bet.betAmount - backCommissionPrice;
                IERC20(bet.betToken).transfer(bet.layer, layerProfit);
                protocolProfit = backCommissionPrice;
            }
        }

        IERC20(bet.betToken).transfer(msg.sender, protocolProfit);

        emit BetClosed(betId, backerProfit, layerProfit, protocolProfit);
    }

    function setCommission(uint256 _protocolCommission) external onlyOwner {
        require(
            _protocolCommission <= 10000,
            "Commission must be less than or equal to 100%"
        );
        protocolCommission = _protocolCommission;
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
pragma solidity ^0.8.0;

import "IAllowTokens.sol";
import "Ownable.sol";

contract AllowTokens is IAllowTokens, Ownable {
    address[] public allowedTokens;

    event AllowToken(address admin, address token);
    event DisallowToken(address admin, address token);

    function addAllowedToken(address token) external override onlyOwner {
        bool exists = false;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                exists = true;
                break;
            }
        }
        require(!exists, "The token is already allowed");

        allowedTokens.push(token);
        emit AllowToken(msg.sender, token);
    }

    function removeAllowedToken(address token) external override onlyOwner {
        uint256 tokenIndex = allowedTokens.length;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                tokenIndex = i;
                break;
            }
        }
        require(
            tokenIndex < allowedTokens.length,
            "The token is already unallowed"
        );

        allowedTokens[tokenIndex] = allowedTokens[allowedTokens.length - 1];
        allowedTokens.pop();
        emit DisallowToken(msg.sender, token);
    }

    function isTokenAllowed(address token) public view override returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAllowTokens {
    function addAllowedToken(address _token) external;

    function removeAllowedToken(address _token) external;

    function isTokenAllowed(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
import "ITokenValue.sol";

contract TokenValue is ITokenValue {
    mapping(address => address) public token_priceFeed;

    event AddedPriceFeed(address admin, address token, address priceFeed);
    event RemovedPriceFeed(address admin, address token);

    function setTokenPriceFeed(address token, address priceFeed)
        public
        virtual
        override
    {
        token_priceFeed[token] = priceFeed;
        emit AddedPriceFeed(msg.sender, token, priceFeed);
    }

    function removeTokenPriceFeed(address token) external virtual override {
        delete token_priceFeed[token];
        emit RemovedPriceFeed(msg.sender, token);
    }

    function getValueFromToken(uint256 amount, address token)
        public
        view
        override
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = getTokenValue(token);
        return (amount * price) / 10**(decimals);
    }

    function getTokenFromValue(uint256 amount, address token)
        public
        view
        override
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = getTokenValue(token);
        return (amount * 10**decimals) / price;
    }

    function getTokenValue(address token)
        public
        view
        override
        returns (uint256, uint256)
    {
        address tokenPriceFeed = token_priceFeed[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenPriceFeed);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();

        return (uint256(price), decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
pragma solidity ^0.8.0;

interface ITokenValue {
    function setTokenPriceFeed(address token, address priceFeed) external;

    function removeTokenPriceFeed(address token) external;

    function getValueFromToken(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getTokenFromValue(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getTokenValue(address token)
        external
        view
        returns (uint256, uint256);
}