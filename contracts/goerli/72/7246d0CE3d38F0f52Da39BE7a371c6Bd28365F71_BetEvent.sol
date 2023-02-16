// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AutomationRegistryInterface, State, Config} from "AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "LinkTokenInterface.sol";
import "IERC20.sol";
import "Strings.sol";
import "AllowTokens.sol";
import "TokenValue.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

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
        uint256 layAmount;
    }

    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) public user_betIds;
    mapping(uint256 => uint256) public betId_upkeepId;

    uint256 public betCounter;
    // INFO protocolCommissions expressed with 2 decimals
    uint256 public protocolCommission;

    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    event BetCreated(
        address backer,
        uint256 id,
        uint256 upkeepId,
        uint256 betAmount,
        uint256 layAmount,
        address betToken,
        uint256 odds,
        uint256 pricePrediction,
        address tokenPrediction,
        OPERATOR operator,
        uint256 creationTime,
        uint256 stopBetTime,
        uint256 endTime
    );
    event BetMatched(uint256 betId, address layer);
    event StopBetting(uint256 betId);
    event BetNotMatched(uint256 betId);
    event BetClosed(
        uint256 betId,
        address winner,
        uint256 payout,
        uint256 commission
    );
    event CommissionChanged(uint256 newCommission);

    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
    ) {
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        betCounter = 0;
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
            "Cannot pay your bet with this token. Token not allowed"
        );
        require(
            isTokenAllowed(tokenPrediction),
            "Cannot bet on this token. Token not allowed"
        );
        require(
            odds > 100 && odds <= 10000,
            "Odds must be between 100 and 10000"
        );
        require(betAmount > 0, "Bet amount must be more than 0");

        uint256 upkeepId = registerUpkeeper(
            string.concat("BetEvent ", Strings.toString(betCounter)),
            20000000000000000000
        );

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
            address(0),
            (betAmount * 100) / (odds - 100)
        );

        bets[betCounter] = bet;
        betId_upkeepId[betCounter] = upkeepId;
        user_betIds[msg.sender].push(betCounter);
        betCounter++;

        IERC20(betToken).transferFrom(msg.sender, address(this), betAmount);

        emit BetCreated(
            bet.backer,
            bet.id,
            upkeepId,
            bet.betAmount,
            bet.layAmount,
            bet.betToken,
            bet.odds,
            bet.pricePrediction,
            bet.tokenPrediction,
            bet.operator,
            bet.creationTime,
            bet.stopBetTime,
            bet.endTime
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

        bet.state = STATE.MATCHED;
        bet.layer = msg.sender;
        user_betIds[msg.sender].push(betId);

        IERC20(bet.betToken).transferFrom(
            msg.sender,
            address(this),
            bet.layAmount
        );

        emit BetMatched(betId, msg.sender);
    }

    // INFO backer can withdraw his bet if bet is not matched
    function stopBetting(uint256 betId) public {
        Bet storage bet = bets[betId];
        require(bet.state != STATE.CLOSED, "Bet is closed");
        require(
            block.timestamp >= bet.stopBetTime,
            "Cannot stop betting before stop bet time"
        );

        if (bet.state == STATE.OPEN) {
            bet.state = STATE.CLOSED;
            IERC20(bet.betToken).transfer(bet.backer, bet.betAmount);
            emit BetNotMatched(betId);
        }

        emit StopBetting(betId);
    }

    function closeBet(uint256 betId) public {
        Bet storage bet = bets[betId];
        require(bet.state == STATE.MATCHED, "Bet is not matched");
        require(
            block.timestamp >= bet.endTime,
            "Cannot close bet before end time"
        );

        uint256 stake = bet.betAmount + bet.layAmount;
        uint256 price = getValueFromToken(1 ether, bet.betToken);

        address winner;
        uint256 feeableAmount;

        if (bet.operator == OPERATOR.GREATER) {
            if (price > bet.pricePrediction) {
                winner = bet.backer;
                feeableAmount = bet.layAmount;
            } else {
                winner = bet.layer;
                feeableAmount = bet.betAmount;
            }
        } else {
            if (price < bet.pricePrediction) {
                winner = bet.backer;
                feeableAmount = bet.layAmount;
            } else {
                winner = bet.layer;
                feeableAmount = bet.betAmount;
            }
        }

        uint256 protocolProfit = (feeableAmount * protocolCommission) / 10000;
        uint256 payout = stake - protocolProfit;

        bet.state = STATE.CLOSED;

        removeUserBetId(betId, bet.backer);
        removeUserBetId(betId, bet.layer);

        IERC20(bet.betToken).transfer(winner, payout);
        IERC20(bet.betToken).transfer(owner(), protocolProfit);

        //todo cancel upkeep and withdraw link

        emit BetClosed(betId, winner, payout, protocolProfit);
    }

    function setCommission(uint256 _protocolCommission) external onlyOwner {
        require(
            _protocolCommission <= 10000,
            "Commission must be <= than 100%"
        );
        protocolCommission = _protocolCommission;

        emit CommissionChanged(_protocolCommission);
    }

    function registerUpkeeper(string memory name, uint256 amount)
        private
        returns (uint256)
    {
        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;
        bytes memory checkData = abi.encodePacked(betCounter);
        bytes memory payload = abi.encode(
            name,
            "0x", // email
            address(this),
            999999, // gaslimit
            address(msg.sender), // owner
            checkData,
            amount, // funded link
            0,
            address(this) // contract to upkeep
        );

        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            // DEV - Use the upkeepID however you see fit
            //---
            return upkeepID;
            //---
        } else {
            revert("auto-approve disabled");
        }
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 betId = abi.decode(checkData, (uint256));
        Bet memory bet = bets[betId];
        upkeepNeeded =
            ((bet.state == STATE.OPEN) &&
                (block.timestamp >= bet.stopBetTime)) ||
            ((bet.state == STATE.MATCHED) && (block.timestamp >= bet.endTime));
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external {
        uint256 betId = abi.decode(performData, (uint256));
        Bet memory bet = bets[betId];
        if ((bet.state == STATE.OPEN) && (block.timestamp >= bet.stopBetTime)) {
            stopBetting(betId);
        } else if (
            (bet.state == STATE.MATCHED) && (block.timestamp >= bet.endTime)
        ) {
            closeBet(betId);
        }
    }

    function totalValueLocked() external view returns (uint256) {
        uint256 tvl = 0;
        for (uint256 i = 0; i < betCounter; i++) {
            Bet memory bet = bets[i];
            if (bet.state == STATE.OPEN) {
                tvl += getValueFromToken(bet.betAmount, bet.betToken);
            } else if (bet.state == STATE.MATCHED) {
                tvl += getValueFromToken(
                    bet.betAmount + bet.layAmount,
                    bet.betToken
                );
            }
        }
        return tvl;
    }

    function removeUserBetId(uint256 betId, address user) internal {
        uint256[] storage userBetIds = user_betIds[user];
        for (uint256 i = 0; i < userBetIds.length; i++) {
            if (userBetIds[i] == betId) {
                userBetIds[i] = userBetIds[userBetIds.length - 1];
                userBetIds.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // â†’ `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // â†’ `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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