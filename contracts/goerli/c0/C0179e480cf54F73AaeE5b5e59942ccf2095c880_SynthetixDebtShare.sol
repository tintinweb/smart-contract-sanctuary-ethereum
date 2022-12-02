pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

pragma solidity ^0.5.16;

// Internal references
import "./AddressResolver.sol";

// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.5.16;

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./externals/openzeppelin/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10 ** uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10 ** uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(signedAbs(x));
    }
}

pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/ISynthetixDebtShare.sol";
import "./interfaces/IDebtShareAggregator.sol";
import "./interfaces/IIssuedSynthAggregator.sol";
import "./MixinResolver.sol";

// Libraries
import "./SafeDecimalMath.sol";

// https://docs.synthetix.io/contracts/source/contracts/synthetixdebtshare
contract SynthetixDebtShare is Owned, MixinResolver, ISynthetixDebtShare {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    struct PeriodBalance {
        uint128 amount;
        uint128 periodId;
    }

    bytes32 public constant CONTRACT_NAME = "SynthetixDebtShare";

    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_DEBT_AGGREGATOR = "DebtShareAggregator";
    bytes32 private constant CONTRACT_ISSUED_SYNTH_AGGREGATOR = "IssuedSynthAggregator";

    uint256 internal constant MAX_PERIOD_ITERATE = 30;

    /* ========== STATE VARIABLES ========== */

    /**
     * Addresses selected by owner which are allowed to call `transferFrom` to manage debt shares
     */
    mapping(address => bool) public authorizedBrokers;

    /**
     * Addresses selected by owner which are allowed to call `takeSnapshot`
     * `takeSnapshot` is not public because only a small number of snapshots can be retained for a period of time, and so they
     * must be controlled to prevent censorship
     */
    mapping(address => bool) public authorizedToSnapshot;

    /**
     * Records a user's balance as it changes from period to period.
     * The last item in the array always represents the user's most recent balance
     * The intermediate balance is only recorded if
     * `currentPeriodId` differs (which would happen upon a call to `setCurrentPeriodId`)
     */
    mapping(address => PeriodBalance[]) public balances;

    /**
     * Records totalSupply as it changes from period to period
     * Similar to `balances`, the `totalSupplyOnPeriod` at index `currentPeriodId` matches the current total supply
     * Any other period ID would represent its most recent totalSupply before the period ID changed.
     */
    mapping(uint256 => uint256) public totalSupplyOnPeriod;

    /* ERC20 fields. */
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * Period ID used for recording accounting changes
     * Can only increment
     */
    uint128 public currentPeriodId;

    /**
     * Prevents the owner from making further changes to debt shares after initial import
     */
    bool public isInitialized = false;

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {
        name = "Synthetix Debt Shares";
        symbol = "SDS";
        decimals = 18;

        // NOTE: must match initial fee period ID on `FeePool` constructor if issuer wont report
        currentPeriodId = 1;
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_ISSUER;
        addresses[1] = CONTRACT_DEBT_AGGREGATOR;
        addresses[2] = CONTRACT_ISSUED_SYNTH_AGGREGATOR;
    }

    /* ========== VIEWS ========== */

    function debtShareAggregator() internal view returns (IDebtShareAggregator) {
        return IDebtShareAggregator(requireAndGetAddress(CONTRACT_DEBT_AGGREGATOR));
    }

    function issuedSynthAggregator() internal view returns (IIssuedSynthAggregator) {
        return IIssuedSynthAggregator(requireAndGetAddress(CONTRACT_ISSUED_SYNTH_AGGREGATOR));
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 accountPeriodHistoryCount = balances[account].length;

        if (accountPeriodHistoryCount == 0) {
            return 0;
        }

        return uint256(balances[account][accountPeriodHistoryCount - 1].amount);
    }

    function balanceOfOnPeriod(address account, uint256 periodId) public view returns (uint256) {
        uint256 accountPeriodHistoryCount = balances[account].length;

        int256 oldestHistoryIterate = int256(
            MAX_PERIOD_ITERATE < accountPeriodHistoryCount ? accountPeriodHistoryCount - MAX_PERIOD_ITERATE : 0
        );
        int256 i;
        for (i = int256(accountPeriodHistoryCount) - 1; i >= oldestHistoryIterate; i--) {
            if (balances[account][uint256(i)].periodId <= periodId) {
                return uint256(balances[account][uint256(i)].amount);
            }
        }

        require(i < 0, "SynthetixDebtShare: not found in recent history");
        return 0;
    }

    function balanceOfCrossChain(address account) external view returns (uint256) {
        return debtShareAggregator().balanceOf(account);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyOnPeriod[currentPeriodId];
    }

    function totalSupplyCrossChain() external view returns (uint256) {
        return debtShareAggregator().totalSupply();
    }

    function sharePercent(address account) external view returns (uint256) {
        return sharePercentOnPeriod(account, currentPeriodId);
    }

    function sharePercentOnPeriod(address account, uint256 periodId) public view returns (uint256) {
        uint256 balance = balanceOfOnPeriod(account, periodId);

        if (balance == 0) {
            return 0;
        }

        return balance.divideDecimal(totalSupplyOnPeriod[periodId]);
    }

    function allowance(address, address spender) public view returns (uint256) {
        if (authorizedBrokers[spender]) {
            return uint256(-1);
        } else {
            return 0;
        }
    }

    function debtRatio() public view returns (uint256) {
        uint256 totalIssuedSynthr = issuedSynthAggregator().totalIssuedSynths();
        uint256 totalDebtShare = debtShareAggregator().totalSupply();
        return totalDebtShare == 0 ? SafeDecimalMath.preciseUnit() : totalIssuedSynthr.divideDecimalRoundPrecise(totalDebtShare);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addAuthorizedBroker(address target) external onlyOwner {
        authorizedBrokers[target] = true;
        emit ChangeAuthorizedBroker(target, true);
    }

    function removeAuthorizedBroker(address target) external onlyOwner {
        authorizedBrokers[target] = false;
        emit ChangeAuthorizedBroker(target, false);
    }

    function addAuthorizedToSnapshot(address target) external onlyOwner {
        authorizedToSnapshot[target] = true;
        emit ChangeAuthorizedToSnapshot(target, true);
    }

    function removeAuthorizedToSnapshot(address target) external onlyOwner {
        authorizedToSnapshot[target] = false;
        emit ChangeAuthorizedToSnapshot(target, false);
    }

    function takeSnapshot(uint128 id) external onlyAuthorizedToSnapshot {
        require(id > currentPeriodId, "period id must always increase");
        totalSupplyOnPeriod[id] = totalSupplyOnPeriod[currentPeriodId];
        currentPeriodId = id;
    }

    function mintShare(address account, uint256 amount) external onlyIssuer {
        require(account != address(0), "ERC20: mint to the zero address");

        _increaseBalance(account, amount);

        totalSupplyOnPeriod[currentPeriodId] = totalSupplyOnPeriod[currentPeriodId].add(amount);

        emit Transfer(address(0), account, amount);
        emit Mint(account, amount);
    }

    function burnShare(address account, uint256 amount) external onlyIssuer {
        require(account != address(0), "ERC20: burn from zero address");

        _deductBalance(account, amount);

        totalSupplyOnPeriod[currentPeriodId] = totalSupplyOnPeriod[currentPeriodId].sub(amount);

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }

    function approve(address, uint256) external pure returns (bool) {
        revert("debt shares are not transferrable");
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert("debt shares are not transferrable");
    }

    function transferFrom(address from, address to, uint256 amount) external onlyAuthorizedBrokers returns (bool) {
        require(to != address(0), "ERC20: send to the zero address");

        _deductBalance(from, amount);
        _increaseBalance(to, amount);
        emit Transfer(address(from), address(to), amount);

        return true;
    }

    function importAddresses(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner onlySetup {
        uint256 supply = totalSupplyOnPeriod[currentPeriodId];

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 curBalance = balanceOf(accounts[i]);
            if (curBalance < amounts[i]) {
                uint256 amount = amounts[i] - curBalance;
                _increaseBalance(accounts[i], amount);
                supply = supply.add(amount);
                emit Mint(accounts[i], amount);
                emit Transfer(address(0), accounts[i], amount);
            } else if (curBalance > amounts[i]) {
                uint256 amount = curBalance - amounts[i];
                _deductBalance(accounts[i], amount);
                supply = supply.sub(amount);
                emit Burn(accounts[i], amount);
                emit Transfer(accounts[i], address(0), amount);
            }
        }

        totalSupplyOnPeriod[currentPeriodId] = supply;
    }

    function finishSetup() external onlyOwner {
        isInitialized = true;
    }

    /* ========== INTERNAL FUNCTIONS ======== */
    function _increaseBalance(address account, uint256 amount) internal {
        uint256 accountBalanceCount = balances[account].length;

        if (accountBalanceCount == 0) {
            balances[account].push(PeriodBalance(uint128(amount), uint128(currentPeriodId)));
        } else {
            uint128 newAmount = uint128(uint256(balances[account][accountBalanceCount - 1].amount).add(amount));

            if (balances[account][accountBalanceCount - 1].periodId != currentPeriodId) {
                balances[account].push(PeriodBalance(newAmount, currentPeriodId));
            } else {
                balances[account][accountBalanceCount - 1].amount = newAmount;
            }
        }
    }

    function _deductBalance(address account, uint256 amount) internal {
        uint256 accountBalanceCount = balances[account].length;

        require(accountBalanceCount != 0, "SynthetixDebtShare: account has no share to deduct");

        uint128 newAmount = uint128(uint256(balances[account][accountBalanceCount - 1].amount).sub(amount));

        if (balances[account][accountBalanceCount - 1].periodId != currentPeriodId) {
            balances[account].push(PeriodBalance(newAmount, currentPeriodId));
        } else {
            balances[account][accountBalanceCount - 1].amount = newAmount;
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyIssuer() {
        require(
            msg.sender == requireAndGetAddress(CONTRACT_ISSUER) || msg.sender == address(debtShareAggregator()),
            "SynthetixDebtShare: only issuer and debtShare aggregator can mint/burn"
        );
        _;
    }

    modifier onlyAuthorizedToSnapshot() {
        require(
            authorizedToSnapshot[msg.sender] || msg.sender == requireAndGetAddress(CONTRACT_ISSUER),
            "SynthetixDebtShare: not authorized to snapshot"
        );
        _;
    }

    modifier onlyAuthorizedBrokers() {
        require(authorizedBrokers[msg.sender], "SynthetixDebtShare: only brokers can transferFrom");
        _;
    }

    modifier onlySetup() {
        require(!isInitialized, "SynthetixDebt: only callable while still initializing");
        _;
    }

    /* ========== EVENTS ========== */
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event ExchangeShare(address indexed from, address indexed to, uint256 amount, uint16 destChainId);

    event ChangeAuthorizedBroker(address indexed authorizedBroker, bool authorized);
    event ChangeAuthorizedToSnapshot(address indexed authorizedToSnapshot, bool authorized);
}

pragma solidity ^0.5.16;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IDebtShareAggregator {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IIssuedSynthAggregator {
    function totalIssuedSynths() external view returns (uint256 _issuedSynths);

    function totalIssuedSynthsPerIssuer(address account) external view returns (uint256 _issuedSynths);

    function totalIssuedSynthPerAsset(bytes32 currencyKey) external view returns (uint256 _issuedSynth);

    function totalIssuedSynthPerAssetAndIssuer(bytes32 currencyKey, address account) external view returns (uint256 _issuedSynth);
}

pragma solidity >=0.4.24;

import "../interfaces/ISynth.sol";

// https://docs.synthetix.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo() external view returns (uint256 debt, uint256 sharesSupply, bool isStale);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(
        address _issuer
    ) external view returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(
        address issuer
    ) external view returns (uint256 maxIssuable, uint256 alreadyIssued, uint256 totalSystemDebt);

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(address _issuer, bytes32 _collateralKey) external view returns (uint256 withdrawableSynthr);

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynthsOnBehalf(
        address issueFor,
        address from,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(address from, uint256 amount) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint256 amount
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynthsToTarget(address from) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynthsToTargetOnBehalf(
        address burnForAddress,
        address from
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function burnForRedemption(address deprecatedSynthProxy, address account, uint256 balance) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        bool isSelfLiquidation
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate, uint256 sharesToRemove);

    function destIssue(address _account, bytes32 _synthKey, uint256 _synthAmount, uint256 _debtShare) external;

    function destBurn(address _account, bytes32 _synthKey, uint256 _synthAmount, uint256 _debtShare) external;
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external returns (bool);

    function transferFromAndSettle(address from, address to, uint256 value) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/isynthetixdebtshare
interface ISynthetixDebtShare {
    // Views

    function currentPeriodId() external view returns (uint128);

    function allowance(address account, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function balanceOfOnPeriod(address account, uint256 periodId) external view returns (uint256);

    function balanceOfCrossChain(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyCrossChain() external view returns (uint256);

    function sharePercent(address account) external view returns (uint256);

    function sharePercentOnPeriod(address account, uint256 periodId) external view returns (uint256);

    function debtRatio() external view returns (uint256);

    // Mutative functions

    function takeSnapshot(uint128 id) external;

    function mintShare(address account, uint256 amount) external;

    function burnShare(address account, uint256 amount) external;

    function approve(address, uint256) external pure returns (bool);

    function transfer(address to, uint256 amount) external pure returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function addAuthorizedBroker(address target) external;

    function removeAuthorizedBroker(address target) external;

    function addAuthorizedToSnapshot(address target) external;

    function removeAuthorizedToSnapshot(address target) external;
}