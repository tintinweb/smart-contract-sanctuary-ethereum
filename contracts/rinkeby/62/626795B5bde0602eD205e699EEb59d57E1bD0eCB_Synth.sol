pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./ExternStateToken.sol";
import "./MixinResolver.sol";
import "./interfaces/ISynth.sol";
//import "./interfaces/IERC20.sol";

// Internal references
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract template for Derived Assets
contract Synth is Owned, ExternStateToken, MixinResolver, ISynth {
    /* ========== STATE VARIABLES ========== */

    // Currency key which identifies this Synth to the Derived system
    bytes32 public override currencyKey;

    uint8 public constant DECIMALS = 18;
    using SafeMath for uint256;

    // Where fees are pooled in USDx
    address public constant FEE_ADDRESS =
        0x5639C9278b4a5C40225C995285Ae4067167738d5;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _owner,
        bytes32 _currencyKey,
        uint256 _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(
            _proxy,
            _tokenState,
            _tokenName,
            _tokenSymbol,
            _totalSupply,
            DECIMALS,
            _owner
        )
        MixinResolver(_resolver)
    {
        require(_proxy != address(0), "_proxy cannot be 0");
        require(_owner != address(0), "_owner cannot be 0");

        currencyKey = _currencyKey;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address to, uint256 value)
        public
        optionalProxy
        returns (bool)
    {
        _ensureCanTransfer(messageSender, value);

        // transfers to FEE_ADDRESS will be exchanged into USDx and recorded as fee
        if (to == FEE_ADDRESS) {
            return _transferToFeeAddress(to, value);
        }

        // transfers to 0x address will be burned
        if (to == address(0)) {
            return _internalBurn(messageSender, value);
        }

        return super._internalTransfer(messageSender, to, value);
    }

    function transferAndSettle(address to, uint256 value)
        public
        override
        optionalProxy
        returns (bool)
    {
        // Exchanger.settle ensures synth is active
        (, , uint256 numEntriesSettled) =
            exchanger().settle(messageSender, currencyKey);

        // Save gas instead of calling transferableSynths
        uint256 balanceAfter = value;

        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(messageSender);
        }

        // Reduce the value to transfer if balance is insufficient after reclaimed
        value = value > balanceAfter ? balanceAfter : value;

        return super._internalTransfer(messageSender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public optionalProxy returns (bool) {
        _ensureCanTransfer(from, value);

        return _internalTransferFrom(from, to, value);
    }

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) public override optionalProxy returns (bool) {
        // Exchanger.settle() ensures synth is active
        (, , uint256 numEntriesSettled) = exchanger().settle(from, currencyKey);

        // Save gas instead of calling transferableSynths
        uint256 balanceAfter = value;

        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(from);
        }

        // Reduce the value to transfer if balance is insufficient after reclaimed
        value = value >= balanceAfter ? balanceAfter : value;

        return _internalTransferFrom(from, to, value);
    }

    /**
     * @notice _transferToFeeAddress function
     * non-USDx synths are exchanged into USDx via synthInitiatedExchange
     * notify feePool to record amount as fee paid to feePool */
    function _transferToFeeAddress(address to, uint256 value)
        internal
        returns (bool)
    {
        uint256 amountInUSD;

        // USDx can be transferred to FEE_ADDRESS directly
        if (currencyKey == "USDx") {
            amountInUSD = value;
            super._internalTransfer(messageSender, to, value);
        } else {
            // else exchange synth into USDx and send to FEE_ADDRESS
            amountInUSD = exchanger().exchange(
                messageSender,
                currencyKey,
                value,
                "USDx",
                FEE_ADDRESS
            );
        }

        // Notify feePool to record USDx to distribute as fees
        feePool().recordFeePaid(amountInUSD);

        return true;
    }

    function issue(address account, uint256 amount)
        external
        override
        onlyInternalContracts
    {
        _internalIssue(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyInternalContracts
    {
        _internalBurn(account, amount);
    }

    function _internalIssue(address account, uint256 amount) internal {
        tokenState.setBalanceOf(
            account,
            tokenState.balanceOf(account).add(amount)
        );
        totalSup = totalSup.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

    function _internalBurn(address account, uint256 amount)
        internal
        returns (bool)
    {
        tokenState.setBalanceOf(
            account,
            tokenState.balanceOf(account).sub(amount)
        );
        totalSup = totalSup.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);

        return true;
    }

    // Allow owner to set the total supply on import.
    function setTotalSupply(uint256 amount) external optionalProxy_onlyOwner {
        totalSup = amount;
    }

    /* ========== VIEWS ========== */

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired()
        public
        view
        override
        returns (bytes32[] memory addresses)
    {
        addresses = new bytes32[](4);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_FEEPOOL;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function _ensureCanTransfer(address from, uint256 value) internal view {
        require(
            exchanger().maxSecsLeftInWaitingPeriod(from, currencyKey) == 0,
            "Cannot transfer during waiting period"
        );
        require(
            transferableSynths(from) >= value,
            "Insufficient balance after any settlement owing"
        );
        systemStatus().requireSynthActive(currencyKey);
    }

    function transferableSynths(address account)
        public
        view
        override
        returns (uint256)
    {
        (uint256 reclaimAmount, , ) =
            exchanger().settlementOwing(account, currencyKey);

        // Note: ignoring rebate amount here because a settle() is required in order to
        // allow the transfer to actually work

        uint256 balance = tokenState.balanceOf(account);

        if (reclaimAmount > balance) {
            return 0;
        } else {
            return balance.sub(reclaimAmount);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _internalTransferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // Skip allowance update in case of infinite allowance
        if (tokenState.allowance(from, messageSender) != type(uint256).max) {
            // Reduce the allowance by the amount we're transferring.
            // The safeSub call will handle an insufficient allowance.
            tokenState.setAllowance(
                from,
                messageSender,
                tokenState.allowance(from, messageSender).sub(value)
            );
        }

        return super._internalTransfer(from, to, value);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyInternalContracts() {
        bool isFeePool = msg.sender == address(feePool());
        bool isExchanger = msg.sender == address(exchanger());
        bool isIssuer = msg.sender == address(issuer());

        require(
            isFeePool || isExchanger || isIssuer,
            "Only FeePool, Exchanger or Issuer contracts allowed"
        );
        _;
    }

    /* ========== EVENTS ========== */
    event Issued(address indexed account, uint256 value);
    bytes32 private constant ISSUED_SIG = keccak256("Issued(address,uint256)");

    function emitIssued(address account, uint256 value) internal {
        proxy._emit(
            abi.encode(value),
            2,
            ISSUED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }

    event Burned(address indexed account, uint256 value);
    bytes32 private constant BURNED_SIG = keccak256("Burned(address,uint256)");

    function emitBurned(address account, uint256 value) internal {
        proxy._emit(
            abi.encode(value),
            2,
            BURNED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}

pragma solidity ^0.8.4;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
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
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./Proxyable.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./TokenState.sol";

// Contract to operate as proxy for upgradability
contract ExternStateToken is Owned, Proxyable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /* Stores balances and allowances. */
    TokenState public tokenState;

    /* Other ERC20 fields. */
    string public nme;
    string public sym;
    uint256 public totalSup;
    uint8 public decimal;

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _nme,
        string memory _sym,
        uint256 _totalSup,
        uint8 _decimal,
        address _owner
    ) public Owned(_owner) Proxyable(_proxy) {
        tokenState = _tokenState;

        nme = _nme;
        sym = _sym;
        totalSup = _totalSup;
        decimal = _decimal;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual 
        returns (uint256)
    {
        return tokenState.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     */
    function balanceOf(address account) external view returns (uint256) {
        return tokenState.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(TokenState _tokenState)
        external
        optionalProxy_onlyOwner
    {
        tokenState = _tokenState;
        emitTokenStateUpdated(address(_tokenState));
    }

    function _internalTransfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(
            to != address(0) && to != address(this) && to != address(proxy),
            "Cannot transfer to this address"
        );

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transferByProxy(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        return _internalTransfer(from, to, value);
    }

    /*
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFromByProxy(
        address sender,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(
            from,
            sender,
            tokenState.allowance(from, sender).sub(value)
        );
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Approves spender to transfer on the message sender's behalf.
     */
    function approve(address spender, uint256 value)
        public 
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;

        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    bytes32 internal constant TRANSFER_SIG =
        keccak256("Transfer(address,address,uint256)");

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) internal {
        proxy._emit(
            abi.encode(value),
            3,
            TRANSFER_SIG,
            addressToBytes32(from),
            addressToBytes32(to),
            0
        );
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    bytes32 internal constant APPROVAL_SIG =
        keccak256("Approval(address,address,uint256)");

    function emitApproval(
        address owner,
        address spender,
        uint256 value
    ) internal {
        proxy._emit(
            abi.encode(value),
            3,
            APPROVAL_SIG,
            addressToBytes32(owner),
            addressToBytes32(spender),
            0
        );
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 internal constant TOKENSTATEUPDATED_SIG =
        keccak256("TokenStateUpdated(address)");

    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(
            abi.encode(newTokenState),
            1,
            TOKENSTATEUPDATED_SIG,
            0,
            0,
            0
        );
    }
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";

// Internal references
import "./AddressResolver.sol";
import "./ReadProxy.sol";

// contract that helps in storing the address of all synths
abstract contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
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
    function resolverAddressesRequired()
        public
        view
        virtual
        returns (bytes32[] memory addresses)
    {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(
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
            if (
                resolver.getAddress(name) != addressCache[name] ||
                addressCache[name] == address(0)
            ) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name)
        internal
        view
        returns (address)
    {
        address _foundAddress = addressCache[name];
        require(
            _foundAddress != address(0),
            string(abi.encodePacked("Missing address: ", name))
        );
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

pragma solidity ^0.8.4;

interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account)
        external
        view
        returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value)
        external
        returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Restricted: used internally to Derived
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

pragma solidity ^0.8.4;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account)
        external
        view
        returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenSynthsAllowed(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view;

    function systemSuspension()
        external
        view
        returns (bool suspended, uint248 reason);

    function issuanceSuspension()
        external
        view
        returns (bool suspended, uint248 reason);

    function exchangeSuspension()
        external
        view
        returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey)
        external
        view
        returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey)
        external
        view
        returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

pragma solidity ^0.8.4;

interface IFeePool {
    // Views

    // solhint-disable-next-line func-name-mixedcase
    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account)
        external
        view
        returns (uint256, uint256);

    function feePeriodDuration() external view returns (uint256);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint256);

    function totalFeesAvailable() external view returns (uint256);

    function totalRewardsAvailable() external view returns (uint256);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;

    // Restricted: used internally to Derived
    function appendAccountIssuanceRecord(
        address account,
        uint256 lockedAmount,
        uint256 debtEntryIndex
    ) external;

    function recordFeePaid(uint256 USDxAmount) external;

    function setRewardsToDistribute(uint256 amount) external;
}

pragma solidity >=0.4.24;

import "./IVirtualSynth.sol";

// https://docs.derived.fi/contracts/source/interfaces/iexchanger
interface IExchanger {
    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    // Mutative functions
    function exchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external virtual returns (uint amountReceived);

    function exchangeWithTracking(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        address originator,
        bytes32 trackingCode
    ) external virtual returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external virtual returns (uint amountReceived);

    //function exchangeWithVirtual(
    //    address from,
    //    bytes32 sourceCurrencyKey,
    //    uint sourceAmount,
    //    bytes32 destinationCurrencyKey,
    //    address destinationAddress,
    //    bytes32 trackingCode
    //) external virtual returns (uint amountReceived, IVirtualSynth vSynth);

    function settle(address from, bytes32 currencyKey)
        external virtual 
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function setLastExchangeRateForSynth(bytes32 currencyKey, uint rate) external;

    //function suspendSynthWithInvalidRate(bytes32 currencyKey) external virtual;
}

pragma solidity ^0.8.4;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views
    function anySynthOrDVDXRateIsInvalid()
        external
        view
        returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer)
        external
        view
        returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey)
        external
        view
        returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer)
        external
        view
        returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys)
        external
        view
        returns (ISynth[] memory);

    function synthsByAddress(address synthAddress)
        external
        view
        returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeEtherCollateral)
        external
        view
        returns (uint256);

    function transferableDerivedAndAnyRateIsInvalid(
        address account,
        uint256 balance
    ) external view returns (uint256 transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Derived
    function issueSynths(address from, uint256 amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint256 amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint256 amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint256 amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from)
        external;

    function liquidateDelinquentAccount(
        address account,
        uint256 USDxAmount,
        address liquidator
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate);
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

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxy.sol";

// This contract should be treated like an abstract contract
abstract contract Proxyable is Owned {
    /* The proxy this contract exists behind. */
    Proxy public proxy;
    Proxy public integrationProxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setIntegrationProxy(address payable _integrationProxy)
        external
        onlyOwner
    {
        integrationProxy = Proxy(_integrationProxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(
            Proxy(payable(msg.sender)) == proxy ||
                Proxy(payable(msg.sender)) == integrationProxy,
            "Only the proxy can call"
        );
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (
            Proxy(payable(msg.sender)) != proxy &&
            Proxy(payable(msg.sender)) != integrationProxy &&
            messageSender != msg.sender
        ) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (
            Proxy(payable(msg.sender)) != proxy &&
            Proxy(payable(msg.sender)) != integrationProxy &&
            messageSender != msg.sender
        ) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}

pragma solidity ^0.8.4;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// contract that provides the ability to manipulate fractional numbers, performing safe arithmetic with unsigned fixed-point decimals.
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

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
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
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
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function multiplyDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
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
    function divideDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
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
    function divideDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen =
            i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./State.sol";

// An external state contract to hold ERC20 balances and allowances
contract TokenState is Owned, State {
    /* ERC20 fields. */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address _owner, address _associatedContract)
        public
        Owned(_owner)
        State(_associatedContract)
    {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set ERC20 allowance.
     * @dev Only the associated contract may call this.
     * @param tokenOwner The authorising party.
     * @param spender The authorised party.
     * @param value The total value the authorised party may spend on the
     * authorising party's behalf.
     */
    function setAllowance(
        address tokenOwner,
        address spender,
        uint256 value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint256 value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxyable.sol";

// A proxy contract that, if it does not recognise the function
// being called on it, passes all value and call data to an
// underlying target contract.
contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint256 numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint256 size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
                case 0 {
                    log0(add(_callData, 32), size)
                }
                case 1 {
                    log1(add(_callData, 32), size, topic1)
                }
                case 2 {
                    log2(add(_callData, 32), size, topic1, topic2)
                }
                case 3 {
                    log3(add(_callData, 32), size, topic1, topic2, topic3)
                }
                case 4 {
                    log4(
                        add(_callData, 32),
                        size,
                        topic1,
                        topic2,
                        topic3,
                        topic4
                    )
                }
        }
    }

    // solhint-disable no-complex-fallback
    fallback() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize())

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(
                gas(),
                sload(target.slot),
                callvalue(),
                free_ptr,
                calldatasize(),
                0,
                0
            )
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(result) {
                revert(free_ptr, returndatasize())
            }
            return(free_ptr, returndatasize())
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";

// An external state contract whose functions can only be called by an associated controller if modified with onlyAssociatedContract.
abstract contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(
            msg.sender == associatedContract,
            "Only the associated contract can perform this action"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

pragma solidity ^0.8.4;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

// Address resolver contract
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external onlyOwner {
        require(
            names.length == destinations.length,
            "Input lengths must match"
        );

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

    function areAddressesImported(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view override returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        override
        returns (address)
    {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view override returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

pragma solidity ^0.8.4;

import "./Owned.sol";

// Contract to read the proxy contracts
contract ReadProxy is Owned {
    address public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(address _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(target);
    }

    fallback() external {
        // The basics of a proxy read call
        // Note that msg.sender in the underlying will always be the address of this contract.
        assembly {
            calldatacopy(0, 0, calldatasize())

            // Use of staticcall - this will revert if the underlying function mutates state
            let result := staticcall(
                gas(),
                sload(target.slot),
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            if iszero(result) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    event TargetUpdated(address newTarget);
}

pragma solidity ^0.8.4;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

pragma solidity ^0.8.4;

import "./ISynth.sol";

interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);

    function rate() external view returns (uint256);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint256);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}