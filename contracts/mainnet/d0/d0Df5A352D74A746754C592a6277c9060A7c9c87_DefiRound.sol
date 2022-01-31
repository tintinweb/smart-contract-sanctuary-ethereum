// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDefiRound.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract DefiRound is IDefiRound, Ownable {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line
    address public immutable WETH;
    address public immutable override treasury;
    OversubscriptionRate public overSubscriptionRate;
    mapping(address => uint256) public override totalSupply;
    // account -> accountData
    mapping(address => AccountData) private accountData;
    mapping(address => RateData) private tokenRates;

    //Token -> oracle, genesis
    mapping(address => SupportedTokenData) private tokenSettings;

    EnumerableSet.AddressSet private supportedTokens;
    EnumerableSet.AddressSet private configuredTokenRates;
    STAGES public override currentStage;

    WhitelistSettings public whitelistSettings;
    uint256 public lastLookExpiration = type(uint256).max;
    uint256 private immutable maxTotalValue;
    bool private stage1Locked;

    constructor(
        // solhint-disable-next-line
        address _WETH,
        address _treasury,
        uint256 _maxTotalValue
    ) public {
        require(_WETH != address(0), "INVALID_WETH");
        require(_treasury != address(0), "INVALID_TREASURY");
        require(_maxTotalValue > 0, "INVALID_MAXTOTAL");

        WETH = _WETH;
        treasury = _treasury;
        currentStage = STAGES.STAGE_1;

        maxTotalValue = _maxTotalValue;
    }

    function deposit(TokenData calldata tokenInfo, bytes32[] memory proof)
        external
        payable
        override
    {
        require(currentStage == STAGES.STAGE_1, "DEPOSITS_NOT_ACCEPTED");
        require(!stage1Locked, "DEPOSITS_LOCKED");

        if (whitelistSettings.enabled) {
            require(
                verifyDepositor(msg.sender, whitelistSettings.root, proof),
                "PROOF_INVALID"
            );
        }

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");

        // Convert ETH to WETH if ETH is passed in, otherwise treat WETH as a regular ERC20
        if (token == WETH && msg.value > 0) {
            require(tokenAmount == msg.value, "INVALID_MSG_VALUE");
            IWETH(WETH).deposit{value: tokenAmount}();
        } else {
            require(msg.value == 0, "NO_ETH");
        }

        AccountData storage tokenAccountData = accountData[msg.sender];

        if (tokenAccountData.token == address(0)) {
            tokenAccountData.token = token;
        }

        require(tokenAccountData.token == token, "SINGLE_ASSET_DEPOSITS");

        tokenAccountData.initialDeposit = tokenAccountData.initialDeposit.add(
            tokenAmount
        );
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.add(
            tokenAmount
        );

        require(
            tokenAccountData.currentBalance <= tokenSettings[token].maxLimit,
            "MAX_LIMIT_EXCEEDED"
        );

        // No need to transfer from msg.sender since is ETH was converted to WETH
        if (!(token == WETH && msg.value > 0)) {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
        }

        if (_totalValue() >= maxTotalValue) {
            stage1Locked = true;
        }

        emit Deposited(msg.sender, tokenInfo);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        require(msg.sender == WETH);
    }

    //We disallow withdrawal
    /*
    function withdraw(TokenData calldata tokenInfo, bool asETH)
        external
        override
    {
        require(currentStage == STAGES.STAGE_2, "WITHDRAWS_NOT_ACCEPTED");
        require(!_isLastLookComplete(), "WITHDRAWS_EXPIRED");

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");
        AccountData storage tokenAccountData = accountData[msg.sender];
        require(token == tokenAccountData.token, "INVALID_TOKEN");
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.sub(
            tokenAmount
        );
        // set the data back in the mapping, otherwise updates are not saved
        accountData[msg.sender] = tokenAccountData;

        // Don't transfer WETH, WETH is converted to ETH and sent to the recipient
        if (token == WETH && asETH) {
            IWETH(WETH).withdraw(tokenAmount);
            msg.sender.sendValue(tokenAmount);
        } else {
            IERC20(token).safeTransfer(msg.sender, tokenAmount);
        }

        emit Withdrawn(msg.sender, tokenInfo, asETH);
    }
    */

    function configureWhitelist(WhitelistSettings memory settings)
        external
        override
        onlyOwner
    {
        whitelistSettings = settings;
        emit WhitelistConfigured(settings);
    }

    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport)
        external
        override
        onlyOwner
    {
        uint256 tokensLength = tokensToSupport.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            SupportedTokenData memory data = tokensToSupport[i];
            require(supportedTokens.add(data.token), "TOKEN_EXISTS");

            tokenSettings[data.token] = data;
        }
        emit SupportedTokensAdded(tokensToSupport);
    }

    function getSupportedTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        uint256 tokensLength = supportedTokens.length();
        tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = supportedTokens.at(i);
        }
    }

    function publishRates(
        RateData[] calldata ratesData,
        OversubscriptionRate memory oversubRate,
        uint256 lastLookDuration
    ) external override onlyOwner {
        // check rates havent been published before
        require(currentStage == STAGES.STAGE_1, "RATES_ALREADY_SET");
        //require(lastLookDuration > 0, "INVALID_DURATION");
        require(oversubRate.overDenominator > 0, "INVALID_DENOMINATOR");
        require(oversubRate.overNumerator > 0, "INVALID_NUMERATOR");

        uint256 ratesLength = ratesData.length;
        for (uint256 i = 0; i < ratesLength; i++) {
            RateData memory data = ratesData[i];
            require(data.numerator > 0, "INVALID_NUMERATOR");
            require(data.denominator > 0, "INVALID_DENOMINATOR");
            require(
                tokenRates[data.token].token == address(0),
                "RATE_ALREADY_SET"
            );
            require(configuredTokenRates.add(data.token), "ALREADY_CONFIGURED");
            tokenRates[data.token] = data;
        }

        require(
            configuredTokenRates.length() == supportedTokens.length(),
            "MISSING_RATE"
        );

        // Stage only moves forward when prices are published
        currentStage = STAGES.STAGE_2;
        lastLookExpiration = block.number + lastLookDuration;
        overSubscriptionRate = oversubRate;

        emit RatesPublished(ratesData);
    }

    function getRates(address[] calldata tokens)
        external
        view
        override
        returns (RateData[] memory rates)
    {
        uint256 tokensLength = tokens.length;
        rates = new RateData[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            rates[i] = tokenRates[tokens[i]];
        }
    }

    function getTokenValue(address token, uint256 balance)
        internal
        view
        returns (uint256 value)
    {
        uint256 tokenDecimals = ERC20(token).decimals();
        (, int256 tokenRate, , , ) = AggregatorV3Interface(
            tokenSettings[token].oracle
        ).latestRoundData();
        uint256 rate = tokenRate.toUint256();
        value = (balance.mul(rate)).div(10**tokenDecimals); //Chainlink USD prices are always to 8
    }

    function totalValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256 value) {
        uint256 tokensLength = supportedTokens.length();
        for (uint256 i = 0; i < tokensLength; i++) {
            address token = supportedTokens.at(i);
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            value = value.add(getTokenValue(token, tokenBalance));
        }
    }

    function accountBalance(address account)
        external
        view
        override
        returns (uint256 value)
    {
        uint256 tokenBalance = accountData[account].currentBalance;
        value = value.add(
            getTokenValue(accountData[account].token, tokenBalance)
        );
    }

    function finalizeAssets() external override {
        require(currentStage == STAGES.STAGE_3, "NOT_SYSTEM_FINAL");

        AccountData storage data = accountData[msg.sender];
        address token = data.token;

        require(token != address(0), "NO_DATA");

        (, uint256 ineffective, ) = _getRateAdjustedAmounts(
            data.currentBalance,
            token
        );

        require(ineffective > 0, "NOTHING_TO_MOVE");

        // zero out balance
        data.currentBalance = 0;
        accountData[msg.sender] = data;

        // transfer ineffectiveTokenBalance back to user
        IERC20(token).safeTransfer(msg.sender, ineffective);
    
        emit AssetsFinalized(msg.sender, token, ineffective);
    }

    function getGenesisPools(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory genesisAddresses)
    {
        uint256 tokensLength = tokens.length;
        genesisAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            genesisAddresses[i] = tokenSettings[supportedTokens.at(i)].genesis;
        }
    }

    function getTokenOracles(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory oracleAddresses)
    {
        uint256 tokensLength = tokens.length;
        oracleAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            oracleAddresses[i] = tokenSettings[tokens[i]].oracle;
        }
    }

    function getAccountData(address account)
        external
        view
        override
        returns (AccountDataDetails[] memory data)
    {
        uint256 supportedTokensLength = supportedTokens.length();
        data = new AccountDataDetails[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {
            address token = supportedTokens.at(i);
            AccountData memory accountTokenInfo = accountData[account];
            if (
                currentStage >= STAGES.STAGE_2 &&
                accountTokenInfo.token != address(0)
            ) {
                (
                    uint256 effective,
                    uint256 ineffective,
                    uint256 actual
                ) = _getRateAdjustedAmounts(
                        accountTokenInfo.currentBalance,
                        token
                    );
                AccountDataDetails memory details = AccountDataDetails(
                    token,
                    accountTokenInfo.initialDeposit,
                    accountTokenInfo.currentBalance,
                    effective,
                    ineffective,
                    actual
                );
                data[i] = details;
            } else {
                data[i] = AccountDataDetails(
                    token,
                    accountTokenInfo.initialDeposit,
                    accountTokenInfo.currentBalance,
                    0,
                    0,
                    0
                );
            }
        }
    }

    function transferToTreasury() external override onlyOwner {
        require(_isLastLookComplete(), "CURRENT_STAGE_INVALID");
        require(currentStage == STAGES.STAGE_2, "ONLY_TRANSFER_ONCE");

        uint256 supportedTokensLength = supportedTokens.length();
        TokenData[] memory tokens = new TokenData[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {
            address token = supportedTokens.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            (uint256 effective, , ) = _getRateAdjustedAmounts(balance, token);
            tokens[i].token = token;
            tokens[i].amount = effective;
            IERC20(token).safeTransfer(treasury, effective);
        }

        currentStage = STAGES.STAGE_3;

        emit TreasuryTransfer(tokens);
    }

    function getRateAdjustedAmounts(uint256 balance, address token)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _getRateAdjustedAmounts(balance, token);
    }

    function getMaxTotalValue() external view override returns (uint256) {
        return maxTotalValue;
    }

    function _getRateAdjustedAmounts(uint256 balance, address token)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(currentStage >= STAGES.STAGE_2, "RATES_NOT_PUBLISHED");

        RateData memory rateInfo = tokenRates[token];
        uint256 effectiveTokenBalance = balance
            .mul(overSubscriptionRate.overNumerator)
            .div(overSubscriptionRate.overDenominator);
        uint256 ineffectiveTokenBalance = balance
            .mul(
                overSubscriptionRate.overDenominator.sub(
                    overSubscriptionRate.overNumerator
                )
            )
            .div(overSubscriptionRate.overDenominator);

        uint256 actualReceived = effectiveTokenBalance
            .mul(rateInfo.denominator)
            .div(rateInfo.numerator);

        return (effectiveTokenBalance, ineffectiveTokenBalance, actualReceived);
    }

    function verifyDepositor(
        address participant,
        bytes32 root,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked((participant))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function _isLastLookComplete() internal view returns (bool) {
        return block.number >= lastLookExpiration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IDefiRound {
    enum STAGES {STAGE_1, STAGE_2, STAGE_3}

    struct AccountData {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim INSURE
    }

    struct AccountDataDetails {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim INSURE
        uint256 effectiveAmt; //Amount deposited that will be used towards INSURE
        uint256 ineffectiveAmt; //Amount deposited that will be either refunded or go to farming
        uint256 actualTokeReceived; //Amount of INSURE that will be received
    }
    struct TokenData {
        address token;
        uint256 amount;
    }
    struct SupportedTokenData {
        address token;
        address oracle;
        address genesis;
        uint256 maxLimit;
    }
    struct RateData {
        address token;
        uint256 numerator;
        uint256 denominator;
    }

    struct OversubscriptionRate {
        uint256 overNumerator;
        uint256 overDenominator;
    }

    event Deposited(address depositor, TokenData tokenInfo);
    event Withdrawn(address withdrawer, TokenData tokenInfo, bool asETH);
    event SupportedTokensAdded(SupportedTokenData[] tokenData);
    event RatesPublished(RateData[] ratesData);
    event GenesisTransfer(address user, uint256 amountTransferred);
    event AssetsFinalized(address claimer, address token, uint256 assetsMoved);
    event WhitelistConfigured(WhitelistSettings settings); 
    event TreasuryTransfer(TokenData[] tokens);

    struct TokenValues {
        uint256 effectiveTokenValue;
        uint256 ineffectiveTokenValue;
    }

    struct WhitelistSettings {
        bool enabled;
        bytes32 root;
    }

    /// @notice Enable or disable the whitelist
    /// @param settings The root to use and whether to check the whitelist at all
    function configureWhitelist(WhitelistSettings calldata settings) external;

    /// @notice returns the current stage the contract is in
    /// @return stage the current stage the round contract is in
    function currentStage() external returns (STAGES stage);

    /// @notice deposits tokens into the round contract
    /// @param tokenData an array of token structs
    function deposit(TokenData calldata tokenData, bytes32[] memory proof) external payable;

    /// @notice total value held in the entire contract amongst all the assets
    /// @return value the value of all assets held
    function totalValue() external view returns (uint256 value);

    /// @notice Current Max Total Value
    /// @return value the max total value
    function getMaxTotalValue() external view returns (uint256 value);

    /// @notice returns the address of the treasury, when users claim this is where funds that are <= maxClaimableValue go
    /// @return treasuryAddress address of the treasury
    function treasury() external returns (address treasuryAddress);

    /// @notice the total supply held for a given token
    /// @param token the token to get the supply for
    /// @return amount the total supply for a given token
    function totalSupply(address token) external returns (uint256 amount);

    /*
    /// @notice withdraws tokens from the round contract. only callable when round 2 starts
    /// @param tokenData an array of token structs
    /// @param asEth flag to determine if provided WETH, that it should be withdrawn as ETH
     function withdraw(TokenData calldata tokenData, bool asEth) external;
    */

    // /// @notice adds tokens to support
    // /// @param tokensToSupport an array of supported token structs
    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport) external;

    // /// @notice returns which tokens can be deposited
    // /// @return tokens tokens that are supported for deposit
    function getSupportedTokens() external view returns (address[] calldata tokens);

    /// @notice the oracle that will be used to denote how much the amounts deposited are worth in USD
    /// @param tokens an array of tokens
    /// @return oracleAddresses the an array of oracles corresponding to supported tokens
    function getTokenOracles(address[] calldata tokens)
        external
        view
        returns (address[] calldata oracleAddresses);

    /// @notice publishes rates for the tokens. Rates are always relative to 1 INSURE. Can only be called once within Stage 1
    // prices can be published at any time
    /// @param ratesData an array of rate info structs
    function publishRates(
        RateData[] calldata ratesData,
        OversubscriptionRate memory overSubRate,
        uint256 lastLookDuration
    ) external;

    /// @notice return the published rates for the tokens
    /// @param tokens an array of tokens to get rates for
    /// @return rates an array of rates for the provided tokens
    function getRates(address[] calldata tokens) external view returns (RateData[] calldata rates);

    /// @notice determines the account value in USD amongst all the assets the user is invovled in
    /// @param account the account to look up
    /// @return value the value of the account in USD
    function accountBalance(address account) external view returns (uint256 value);

    /// @notice Moves excess assets to private farming or refunds them
    /// @dev uses the publishedRates, selected tokens, and amounts to determine what amount of INSURE is claimed
    /// when true oversubscribed amount will deposit to genesis, else oversubscribed amount is sent back to user
    function finalizeAssets() external;

    //// @notice returns what gensis pool a supported token is mapped to
    /// @param tokens array of addresses of supported tokens
    /// @return genesisAddresses array of genesis pools corresponding to supported tokens
    function getGenesisPools(address[] calldata tokens)
        external
        view
        returns (address[] memory genesisAddresses);

    /// @notice returns a list of AccountData for a provided account
    /// @param account the address of the account
    /// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
    function getAccountData(address account)
        external
        view
        returns (AccountDataDetails[] calldata data);

    /// @notice Allows the owner to transfer all swapped assets to the treasury
    /// @dev only callable by owner and if last look period is complete
    function transferToTreasury() external;

    /// @notice Given a balance, calculates how the the amount will be allocated between INSURE and Farming
    /// @dev Only allowed at stage 3
    /// @param balance balance to divy up
    /// @param token token to pull the rates for
    function getRateAdjustedAmounts(uint256 balance, address token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor{
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    address public immutable treasury;
    uint256 public immutable expiry; // >0 if enabled

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, address treasury_, uint256 expiry_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        treasury = treasury_;
        expiry = expiry_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Already claimed.');
        require(expiry == 0 || block.timestamp < expiry,'MerkleDistributor: Expired.');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    function salvage() external {
        require(expiry > 0 && block.timestamp >= expiry,'MerkleDistributor: Not expired.');
        uint256 _remaining = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, _remaining);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(amount)
        );
    }
}

pragma solidity 0.6.11;

import "./ERC20.sol";

contract TestERC20Mock is ERC20 {
    
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}

pragma solidity 0.6.11;

import "./TestERC20Mock.sol";

contract WETHMock is TestERC20Mock {
    string public name = "WETH";
    string public symbol = "WETH";
    uint8 public decimals = 18;

}

pragma solidity 0.6.11;

import "./TestERC20Mock.sol";

contract USDCMock is TestERC20Mock {
    string public name = "USDC";
    string public symbol = "USDC";
    uint8 public decimals = 6;

}

pragma solidity 0.6.11;

/***
 *@title InsureToken
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice InsureDAO's governance token
 */

//libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InsureToken is IERC20 {
    event UpdateMiningParameters(
        uint256 time,
        uint256 rate,
        uint256 supply,
        int256 miningepoch
    );
    event SetMinter(address minter);
    event SetAdmin(address admin);

    string public name;
    string public symbol;
    uint256 public constant decimals = 18;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 public total_supply;

    address public minter;
    address public admin;

    //General constants
    uint256 constant YEAR = 86400 * 365;

    // Allocation within 5years:
    // ==========
    // * Team & Development: 24%
    // * Liquidity Mining: 40%
    // * Investors: 10%
    // * Foundation Treasury: 14%
    // * Community Treasury: 10%
    // ==========
    //
    // After 5years:
    // ==========
    // * Liquidity Mining: 40%~ (Mint fixed amount every year)
    //
    // Mint 2_800_000 INSURE every year.
    // 6th year: 1.32% inflation rate
    // 7th year: 1.30% inflation rate
    // 8th year: 1.28% infration rate
    // so on
    // ==========

    // Supply parameters
    uint256 constant INITIAL_SUPPLY = 126_000_000; //will be vested
    uint256 constant RATE_REDUCTION_TIME = YEAR;
    uint256[6] public RATES = [
        (28_000_000 * 10**18) / YEAR, //INITIAL_RATE
        (22_400_000 * 10**18) / YEAR,
        (16_800_000 * 10**18) / YEAR,
        (11_200_000 * 10**18) / YEAR,
        (5_600_000 * 10**18) / YEAR,
        (2_800_000 * 10**18) / YEAR
    ];

    uint256 constant RATE_DENOMINATOR = 10**18;
    uint256 constant INFLATION_DELAY = 86400;

    // Supply variables
    int256 public mining_epoch;
    uint256 public start_epoch_time;
    uint256 public rate;

    uint256 public start_epoch_supply;

    uint256 public emergency_minted;

    constructor(string memory _name, string memory _symbol) public {
        /***
         * @notice Contract constructor
         * @param _name Token full name
         * @param _symbol Token symbol
         * @param _decimal will be 18 in the migration script.
         */

        uint256 _init_supply = INITIAL_SUPPLY * RATE_DENOMINATOR;
        name = _name;
        symbol = _symbol;
        balanceOf[msg.sender] = _init_supply;
        total_supply = _init_supply;
        admin = msg.sender;
        emit Transfer(address(0), msg.sender, _init_supply);

        start_epoch_time =
            block.timestamp +
            INFLATION_DELAY -
            RATE_REDUCTION_TIME;
        mining_epoch = -1;
        rate = 0;
        start_epoch_supply = _init_supply;
    }

    function _update_mining_parameters() internal {
        /***
         *@dev Update mining rate and supply at the start of the epoch
         *     Any modifying mining call must also call this
         */
        uint256 _rate = rate;
        uint256 _start_epoch_supply = start_epoch_supply;

        start_epoch_time += RATE_REDUCTION_TIME;
        mining_epoch += 1;

        if (mining_epoch == 0) {
            _rate = RATES[uint256(mining_epoch)];
        } else if (mining_epoch < int256(6)) {
            _start_epoch_supply += RATES[uint256(mining_epoch) - 1] * YEAR;
            start_epoch_supply = _start_epoch_supply;
            _rate = RATES[uint256(mining_epoch)];
        } else {
            _start_epoch_supply += RATES[5] * YEAR;
            start_epoch_supply = _start_epoch_supply;
            _rate = RATES[5];
        }
        rate = _rate;
        emit UpdateMiningParameters(
            block.timestamp,
            _rate,
            _start_epoch_supply,
            mining_epoch
        );
    }

    function update_mining_parameters() external {
        /***
         * @notice Update mining rate and supply at the start of the epoch
         * @dev Callable by any address, but only once per epoch
         *     Total supply becomes slightly larger if this function is called late
         */
        require(
            block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME,
            "dev: too soon!"
        );
        _update_mining_parameters();
    }

    function start_epoch_time_write() external returns (uint256) {
        /***
         *@notice Get timestamp of the current mining epoch start
         *        while simultaneously updating mining parameters
         *@return Timestamp of the epoch
         */
        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
            return start_epoch_time;
        } else {
            return _start_epoch_time;
        }
    }

    function future_epoch_time_write() external returns (uint256) {
        /***
         *@notice Get timestamp of the next mining epoch start
         *        while simultaneously updating mining parameters
         *@return Timestamp of the next epoch
         */

        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
            return start_epoch_time + RATE_REDUCTION_TIME;
        } else {
            return _start_epoch_time + RATE_REDUCTION_TIME;
        }
    }

    function _available_supply() internal view returns (uint256) {
        return
            start_epoch_supply +
            ((block.timestamp - start_epoch_time) * rate) +
            emergency_minted;
    }

    function available_supply() external view returns (uint256) {
        /***
         *@notice Current number of tokens in existence (claimed or unclaimed)
         */
        return _available_supply();
    }

    function mintable_in_timeframe(uint256 start, uint256 end)
        external
        view
        returns (uint256)
    {
        /***
         *@notice How much supply is mintable from start timestamp till end timestamp
         *@param start Start of the time interval (timestamp)
         *@param end End of the time interval (timestamp)
         *@return Tokens mintable from `start` till `end`
         */
        require(start <= end, "dev: start > end");
        uint256 _to_mint = 0;
        uint256 _current_epoch_time = start_epoch_time;
        uint256 _current_rate = rate;
        int256 _current_epoch = mining_epoch;

        // Special case if end is in future (not yet minted) epoch
        if (end > _current_epoch_time + RATE_REDUCTION_TIME) {
            _current_epoch_time += RATE_REDUCTION_TIME;
            if (_current_epoch < 5) {
                _current_rate = RATES[uint256(mining_epoch + int256(1))];
            } else {
                _current_rate = RATES[5];
            }
        }

        require(
            end <= _current_epoch_time + RATE_REDUCTION_TIME,
            "dev: too far in future"
        );

        for (uint256 i = 0; i < 999; i++) {
            // InsureDAO will not work in 1000 years.
            if (end >= _current_epoch_time) {
                uint256 current_end = end;
                if (current_end > _current_epoch_time + RATE_REDUCTION_TIME) {
                    current_end = _current_epoch_time + RATE_REDUCTION_TIME;
                }
                uint256 current_start = start;
                if (
                    current_start >= _current_epoch_time + RATE_REDUCTION_TIME
                ) {
                    break; // We should never get here but what if...
                } else if (current_start < _current_epoch_time) {
                    current_start = _current_epoch_time;
                }
                _to_mint += (_current_rate * (current_end - current_start));

                if (start >= _current_epoch_time) {
                    break;
                }
            }
            _current_epoch_time -= RATE_REDUCTION_TIME;
            if (_current_epoch < 5) {
                _current_rate = RATES[uint256(_current_epoch + int256(1))];
                _current_epoch += 1;
            } else {
                _current_rate = RATES[5];
                _current_epoch += 1;
            }
            assert(_current_rate <= RATES[0]); // This should never happen
        }
        return _to_mint;
    }

    function set_minter(address _minter) external {
        /***
         *@notice Set the minter address
         *@dev Only callable once, when minter has not yet been set
         *@param _minter Address of the minter
         */
        require(msg.sender == admin, "dev: admin only");
        require(
            minter == address(0),
            "dev: can set the minter only once, at creation"
        );
        minter = _minter;
        emit SetMinter(_minter);
    }

    function set_admin(address _admin) external {
        /***
         *@notice Set the new admin.
         *@dev After all is set up, admin only can change the token name
         *@param _admin New admin address
         */
        require(msg.sender == admin, "dev: admin only");
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function totalSupply() external view override returns (uint256) {
        /***
         *@notice Total number of tokens in existence.
         */
        return total_supply;
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        /***
         *@notice Check the amount of tokens that an owner allowed to a spender
         *@param _owner The address which owns the funds
         *@param _spender The address which will spend the funds
         *@return uint256 specifying the amount of tokens still available for the spender
         */
        return allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value)
        external
        override
        returns (bool)
    {
        /***
         *@notice Transfer `_value` tokens from `msg.sender` to `_to`
         *@dev Vyper does not allow underflows, so the subtraction in
         *     this function will revert on an insufficient balance
         *@param _to The address to transfer to
         *@param _value The amount to be transferred
         *@return bool success
         */
        require(_to != address(0), "dev: transfers to 0x0 are not allowed");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        /***
         * @notice Transfer `_value` tokens from `_from` to `_to`
         * @param _from address The address which you want to send tokens from
         * @param _to address The address which you want to transfer to
         * @param _value uint256 the amount of tokens to be transferred
         * @return bool success
         */
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool)
    {
        /**
         *@notice Approve `_spender` to transfer `_value` tokens on behalf of `msg.sender`
         *@param _spender The address which will spend the funds
         *@param _value The amount of tokens to be spent
         *@return bool success
         */
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            allowances[msg.sender][_spender] + addedValue
        );

        return true;
    }

    function decreaseAllowance(address _spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, _spender, currentAllowance - subtractedValue);

        return true;
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        /***
         *@notice Mint `_value` tokens and assign them to `_to`
         *@dev Emits a Transfer event originating from 0x00
         *@param _to The account that will receive the created tokens
         *@param _value The amount that will be created
         *@return bool success
         */
        require(msg.sender == minter, "dev: minter only");
        require(_to != address(0), "dev: zero address");

        _mint(_to, _value);

        return true;
    }

    function _mint(address _to, uint256 _value) internal {
        if (block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
        }
        uint256 _total_supply = total_supply + _value;

        require(
            _total_supply <= _available_supply(),
            "dev: exceeds allowable mint amount"
        );
        total_supply = _total_supply;

        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function burn(uint256 _value) external returns (bool) {
        /**
         *@notice Burn `_value` tokens belonging to `msg.sender`
         *@dev Emits a Transfer event with a destination of 0x00
         *@param _value The amount that will be burned
         *@return bool success
         */
        require(
            balanceOf[msg.sender] >= _value,
            "_value > balanceOf[msg.sender]"
        );

        balanceOf[msg.sender] -= _value;
        total_supply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function set_name(string memory _name, string memory _symbol) external {
        /***
         *@notice Change the token name and symbol to `_name` and `_symbol`
         *@dev Only callable by the admin account
         *@param _name New token name
         *@param _symbol New token symbol
         */
        require(msg.sender == admin, "Only admin is allowed to change name");
        name = _name;
        symbol = _symbol;
    }

    function emergency_mint(uint256 _amount, address _to)
        external
        returns (bool)
    {
        /***
         * @notice Emergency minting only when CDS couldn't afford the insolvency.
         * @dev
         * @param _amountOut token amount needed. token is defiend whithin converter.
         * @param _to CDS address
         */
        require(msg.sender == minter, "dev: minter only");
        //mint
        emergency_minted += _amount;
        _mint(_to, _amount);

        return true;
    }
}