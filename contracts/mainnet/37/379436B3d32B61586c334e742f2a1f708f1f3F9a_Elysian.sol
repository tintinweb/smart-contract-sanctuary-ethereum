// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./interfaces/ISystemStatus.sol";
import "./ExternStateToken.sol";
import "./MixinResolver.sol";
import "./libraries/SafeMath.sol";

interface IRewardEscrow {
    // Views
    function balanceOf(address account) external view returns (uint);
    function numVestingEntries(address account) external view returns (uint);
    function totalEscrowedAccountBalance(address account) external view returns (uint);
    function totalVestedAccountBalance(address account) external view returns (uint);
    // Mutative functions
    function appendVestingEntry(address account, uint quantity) external;
    function vest() external;
}

interface IHasBalance {
    // Views
    function balanceOf(address account) external view returns (uint);
}

interface IVault {

}

contract Elysian is  ExternStateToken, MixinResolver {
    using SafeMath for uint256;
    
    // ========== STATE VARIABLES ==========
    string public constant TOKEN_NAME = "Elysian Network Token";
    string public constant TOKEN_SYMBOL = "LYS";
    uint8  public constant DECIMALS = 9;

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_TREASURY = "Treasury";
    bytes32 private constant CONTRACT_ELYSIANESCROW = "ElysianEscrow";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_VAULT = "ElysianVault";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";

     // ========== CONSTRUCTOR ==========
    constructor(
        address payable _proxy,
        TokenState _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(
            _proxy, 
            _tokenState, 
            TOKEN_NAME, 
            TOKEN_SYMBOL, 
            _totalSupply, 
            DECIMALS, 
            _owner
        )
        MixinResolver(_resolver) {}


    function totalBalance(address account) external view returns (uint) {
        uint balance = tokenState.balanceOf(account);
        if (address(elysianEscrow()) != address(0)) {
            balance = balance.add(elysianEscrow().balanceOf(account));
        }
        if (address(rewardEscrow()) != address(0)) {
            balance = balance.add(rewardEscrow().balanceOf(account));
        }
        return balance;
    }

    function mint(uint _amount, address _recipient, bool _isEscrowed) external onlyInternalContracts issuanceActive returns (bool) {
        require(_amount > 0, "Cannot mint 0 tokens");
        bool result = _internalIssue(_recipient, _amount, _isEscrowed);
        return result;
    }

    function _internalIssue(address account, uint amount, bool _isEscrowed) internal returns (bool) {
        if (_isEscrowed) {
            tokenState.setBalanceOf(address(this), tokenState.balanceOf(address(this)).add(amount));
            _transfer(address(rewardEscrow()), amount);
            rewardEscrow().appendVestingEntry(account, amount);
            emitTransfer(address(0), address(rewardEscrow()), amount);
        } else {
            tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
            emitTransfer(address(0), account, amount);
        }
        totalSupply = totalSupply.add(amount);
        emitIssued(account, amount);
        return true;
    }

    function burn(uint _amount, address _account) external onlyInternalContracts returns (bool) {
        bool result = _internalBurn(_account, _amount);
        return result;
    }

    function _internalBurn(address account, uint amount) internal returns (bool) {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount, "internal error during burn");

        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
        return true;
    }

    function _transfer(address to, uint value) internal returns (bool) {
        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(address(this), to, value);
        return true;
    }

    function transfer(address to, uint value) external optionalProxy systemActive returns (bool) {
        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(messageSender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy systemActive returns (bool) {
        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        return _transferFromByProxy(messageSender, from, to, value);
    }

    modifier onlyInternalContracts() {
        bool isVault = messageSender == address(vault());
        require(
            isVault,
            "Only authorized contracts allowed"
        );
        _;
    }

    modifier issuanceActive() {
        systemStatus().requireIssuanceActive();
        _;
    }

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(resolver.requireAndGetAddress("SystemStatus", "Missing SystemStatus address"));
    }

    function vault() public view returns (IVault) {
        return IVault(resolver.requireAndGetAddress(CONTRACT_VAULT, "Missing Vault address"));
    }

    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(resolver.requireAndGetAddress(CONTRACT_REWARDESCROW, "Missing reward escrow address"));
    }

    function elysianEscrow() internal view returns (IHasBalance) {
        return IHasBalance(resolver.requireAndGetAddress(CONTRACT_ELYSIANESCROW, "Missing Elysian escrow address"));
    }

    /* ========== EVENTS ========== */
    event Issued(address indexed account, uint value);
    bytes32 private constant ISSUED_SIG = keccak256("Issued(address,uint256)");

    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, addressToBytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);
    bytes32 private constant BURNED_SIG = keccak256("Burned(address,uint256)");

    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, addressToBytes32(account), 0, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
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
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";
import "./State.sol";


// https://docs.elysian.cash/contracts/TokenState
contract TokenState is OwnedwManager, State {
    /* ERC20 fields. */
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(address _owner, address _associatedContract) public OwnedwManager(_owner, _owner) State(_associatedContract) {}

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
        uint value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value) external onlyAssociatedContract {
        balanceOf[account] = value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";

abstract contract State is OwnedwManager {
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
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    } 
 
    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";


// https://docs.elysian.cash/contracts/SelfDestructible
abstract contract SelfDestructible is OwnedwManager {
    uint public constant SELFDESTRUCT_DELAY = 4 weeks; 

    uint public initiationTime;
    bool public selfDestructInitiated;

    address public selfDestructBeneficiary;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        selfDestructBeneficiary = owner;
        emit SelfDestructBeneficiaryUpdated(owner);
    }

    /**
     * @notice Set the beneficiary address of this contract.
     * @dev Only the contract owner may call this. The provided beneficiary must be non-null.
     * @param _beneficiary The address to pay any eth contained in this contract to upon self-destruction.
     */
    function setSelfDestructBeneficiary(address payable _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary must not be zero");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this.
     */
    function initiateSelfDestruct() external onlyOwner {
        initiationTime = block.timestamp;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }  

    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this.
     */
    function terminateSelfDestruct() external onlyOwner {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

    /**
     * @notice If the self-destruction delay has elapsed, destroy this contract and
     * remit any ether it owns to the beneficiary address.
     * @dev Only the contract owner may call this.
     */
    function selfDestruct() external onlyOwner {
        require(selfDestructInitiated, "Self Destruct not yet initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < block.timestamp, "Self destruct delay not met");
        emit SelfDestructed(selfDestructBeneficiary);
        selfdestruct(address(uint160(selfDestructBeneficiary)));
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Libraries
// TODO(zx): Replace all instances of SafeMath with OZ implementation
import "./libraries/SafeMath.sol";  
    
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 9;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
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
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
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
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

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
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
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
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
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
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

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
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";

// Internal references
import "./Proxy.sol";

// https://docs.synthetix.io/contracts/source/contracts/proxyable
abstract contract Proxyable is OwnedwManager {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    } 

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy {
        _onlyProxy();
        _;  
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol";

// Internal references
import "./Proxyable.sol";

contract Proxy is OwnedwManager {
    Proxyable public target;

    constructor(address _owner) OwnedwManager(_owner, _owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
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
                    log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
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
            let result := call(gas(), sload(target.slot), callvalue(), free_ptr, calldatasize(), 0, 0)
            let size := returndatasize()

            returndatacopy(free_ptr, 0, size)

            if iszero(result) {
                revert(free_ptr, size)
            }
            return(free_ptr, size)
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract OwnedwManager {
    address public owner;
    address public manager;

    address public nominatedOwner;

    constructor(address _owner, address _manager) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        manager = _manager;
        emit OwnerChanged(address(0), _owner);
        emit ManagerChanged(_manager);
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

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    modifier onlyManager {
        _onlyManager();
        _;
    }
    
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    function _onlyManager() private view {
        require(msg.sender == manager, "Only the contract owner may perform this action");
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit ManagerChanged(_manager);
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
    event ManagerChanged(address newManager);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
     
// Internal references
import "./AddressResolver.sol";             
       
   abstract contract MixinResolver {
    AddressResolver public resolver;   
  
    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver)  {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ====== ==== */
    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)  
    {
        combination = new bytes32[](first.length + second.length); 

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }      
 
    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol"; 
import "./SelfDestructible.sol";
import "./Proxyable.sol";

// Libraries
import "./SafeDecimalMath.sol";

// Internal references
import "./TokenState.sol";

contract ExternStateToken is  OwnedwManager, SelfDestructible, Proxyable {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */
    /* Stores balances and allowances. */
    TokenState public tokenState;

    /* Other ERC20 fields. */
    string public  name;
    string public  symbol;
    uint   public  totalSupply;
    uint8  public  decimals;

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint8 _decimals,
        address _owner
    ) public OwnedwManager(_owner, _owner) SelfDestructible() Proxyable(_proxy) {
        tokenState = _tokenState;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
    }
    /* ========== VIEWS ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender) public view returns (uint) {
        return tokenState.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     */ 
    function balanceOf(address account) external view returns (uint) {
        return tokenState.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(TokenState _tokenState) external optionalProxy_onlyOwner {
        tokenState = _tokenState;
        emitTokenStateUpdated(address(_tokenState));
    }

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0) && to != address(this) && to != address(proxy), "Cannot transfer to this address");
        require(tokenState.balanceOf(from) >= value, "Not enough balance");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value, "Not enough balance"));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

        // Emit a standard ERC20 transfer event*/
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
        uint value
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
        uint value
    ) internal returns (bool) {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Approves spender to transfer on the message sender's behalf.
     */
    function approve(address spender, uint value) public optionalProxy returns (bool) {
        address sender = messageSender;

        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 internal constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");

    function emitTransfer(
        address from,
        address to,
        uint value
    ) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, addressToBytes32(from), addressToBytes32(to), 0);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 internal constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");

    function emitApproval(
        address owner,
        address spender,
        uint value
    ) internal {
        proxy._emit(abi.encode(value), 3, APPROVAL_SIG, addressToBytes32(owner), addressToBytes32(spender), 0);
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 internal constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");

    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol"; 
// Internal references
//import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";
import "./interfaces/IAddressResolver.sol";
 
interface IMixinResolver_ {
    function rebuildCache() external;
}  

contract AddressResolver is   OwnedwManager, IAddressResolver {     
    mapping(bytes32 => address) public repository;

    constructor(address _owner) OwnedwManager(_owner, _owner)  {}
 
    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(address[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            IMixinResolver_(destinations[i]).rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external override view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external override view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external override view returns (address) {
        //IIssuer issuer = IIssuer(repository["Issuer"]);
        //require(address(issuer) != address(0), "Cannot find Issuer address");
        //return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}