//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IELFeeRecipient.1.sol";

import "./libraries/LibUint256.sol";

import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";

/// @title Execution Layer Fee Recipient (v1)
/// @author Kiln
/// @notice This contract receives all the execution layer fees from the proposed blocks + bribes
contract ELFeeRecipientV1 is Initializable, IELFeeRecipientV1 {
    /// @inheritdoc IELFeeRecipientV1
    function initELFeeRecipientV1(address _riverAddress) external init(0) {
        RiverAddress.set(_riverAddress);
        emit SetRiver(_riverAddress);
    }

    /// @inheritdoc IELFeeRecipientV1
    function pullELFees(uint256 _maxAmount) external {
        address river = RiverAddress.get();
        if (msg.sender != river) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        uint256 amount = LibUint256.min(_maxAmount, address(this).balance);

        IRiverV1(payable(river)).sendELFees{value: amount}();
    }

    /// @inheritdoc IELFeeRecipientV1
    receive() external payable {
        this;
    }

    /// @inheritdoc IELFeeRecipientV1
    fallback() external payable {
        revert InvalidCall();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./state/shared/Version.sol";

/// @title Initializable
/// @author Kiln
/// @notice This contract ensures that initializers are called only once per version
contract Initializable {
    /// @notice An error occured during the initialization
    /// @param version The version that was attempting to be initialized
    /// @param expectedVersion The version that was expected
    error InvalidInitialization(uint256 version, uint256 expectedVersion);

    /// @notice Emitted when the contract is properly initialized
    /// @param version New version of the contracts
    /// @param cdata Complete calldata that was used during the initialization
    event Initialize(uint256 version, bytes cdata);

    /// @notice Use this modifier on initializers along with a hard-coded version number
    /// @param _version Version to initialize
    modifier init(uint256 _version) {
        if (_version != Version.get()) {
            revert InvalidInitialization(_version, Version.get());
        }
        Version.set(_version + 1); // prevents reentrency on the called method
        _;
        emit Initialize(_version, msg.data);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Execution Layer Fee Recipient Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to receive all the execution layer fees from the proposed blocks + bribes
interface IELFeeRecipientV1 {
    /// @notice The storage river address has changed
    /// @param river The new river address
    event SetRiver(address indexed river);

    /// @notice The fallback has been triggered
    error InvalidCall();

    /// @notice Initialize the fee recipient with the required arguments
    /// @param _riverAddress Address of River
    function initELFeeRecipientV1(address _riverAddress) external;

    /// @notice Pulls all the ETH to the River contract
    /// @dev Only callable by the River contract
    /// @param _maxAmount The maximum amount to pull into the system
    function pullELFees(uint256 _maxAmount) external;

    /// @notice Ether receiver
    receive() external payable;

    /// @notice Invalid fallback detector
    fallback() external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./components/IConsensusLayerDepositManager.1.sol";
import "./components/IOracleManager.1.sol";
import "./components/ISharesManager.1.sol";
import "./components/IUserDepositManager.1.sol";

/// @title River Interface (v1)
/// @author Kiln
/// @notice The main system interface
interface IRiverV1 is IConsensusLayerDepositManagerV1, IUserDepositManagerV1, ISharesManagerV1, IOracleManagerV1 {
    /// @notice Funds have been pulled from the Execution Layer Fee Recipient
    /// @param amount The amount pulled
    event PulledELFees(uint256 amount);

    /// @notice The stored Execution Layer Fee Recipient has been changed
    /// @param elFeeRecipient The new Execution Layer Fee Recipient
    event SetELFeeRecipient(address indexed elFeeRecipient);

    /// @notice The stored Collector has been changed
    /// @param collector The new Collector
    event SetCollector(address indexed collector);

    /// @notice The stored Allowlist has been changed
    /// @param allowlist The new Allowlist
    event SetAllowlist(address indexed allowlist);

    /// @notice The stored Global Fee has been changed
    /// @param fee The new Global Fee
    event SetGlobalFee(uint256 fee);

    /// @notice The stored Operators Registry has been changed
    /// @param operatorRegistry The new Operators Registry
    event SetOperatorsRegistry(address indexed operatorRegistry);

    /// @notice The system underlying supply increased. This is a snapshot of the balances for accounting purposes
    /// @param _collector The address of the collector during this event
    /// @param _oldTotalUnderlyingBalance Old total ETH balance under management by River
    /// @param _oldTotalSupply Old total supply in shares
    /// @param _newTotalUnderlyingBalance New total ETH balance under management by River
    /// @param _newTotalSupply New total supply in shares
    event RewardsEarned(
        address indexed _collector,
        uint256 _oldTotalUnderlyingBalance,
        uint256 _oldTotalSupply,
        uint256 _newTotalUnderlyingBalance,
        uint256 _newTotalSupply
    );

    /// @notice The computed amount of shares to mint is 0
    error ZeroMintedShares();

    /// @notice The access was denied
    /// @param account The account that was denied
    error Denied(address account);

    /// @notice Initializes the River system
    /// @param _depositContractAddress Address to make Consensus Layer deposits
    /// @param _elFeeRecipientAddress Address that receives the execution layer fees
    /// @param _withdrawalCredentials Credentials to use for every validator deposit
    /// @param _oracleAddress The address of the Oracle contract
    /// @param _systemAdministratorAddress Administrator address
    /// @param _allowlistAddress Address of the allowlist contract
    /// @param _operatorRegistryAddress Address of the operator registry
    /// @param _collectorAddress Address receiving the the global fee on revenue
    /// @param _globalFee Amount retained when the ETH balance increases and sent to the collector
    function initRiverV1(
        address _depositContractAddress,
        address _elFeeRecipientAddress,
        bytes32 _withdrawalCredentials,
        address _oracleAddress,
        address _systemAdministratorAddress,
        address _allowlistAddress,
        address _operatorRegistryAddress,
        address _collectorAddress,
        uint256 _globalFee
    ) external;

    /// @notice Get the current global fee
    /// @return The global fee
    function getGlobalFee() external view returns (uint256);

    /// @notice Retrieve the allowlist address
    /// @return The allowlist address
    function getAllowlist() external view returns (address);

    /// @notice Retrieve the collector address
    /// @return The collector address
    function getCollector() external view returns (address);

    /// @notice Retrieve the execution layer fee recipient
    /// @return The execution layer fee recipient address
    function getELFeeRecipient() external view returns (address);

    /// @notice Retrieve the operators registry
    /// @return The operators registry address
    function getOperatorsRegistry() external view returns (address);

    /// @notice Changes the global fee parameter
    /// @param newFee New fee value
    function setGlobalFee(uint256 newFee) external;

    /// @notice Changes the allowlist address
    /// @param _newAllowlist New address for the allowlist
    function setAllowlist(address _newAllowlist) external;

    /// @notice Changes the collector address
    /// @param _newCollector New address for the collector
    function setCollector(address _newCollector) external;

    /// @notice Changes the execution layer fee recipient
    /// @param _newELFeeRecipient New address for the recipient
    function setELFeeRecipient(address _newELFeeRecipient) external;

    /// @notice Input for execution layer fee earnings
    function sendELFees() external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensys Layer Deposit Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the interactions with the official deposit contract
interface IConsensusLayerDepositManagerV1 {
    /// @notice A validator key got funded on the deposit contract
    /// @param publicKey BLS Public key that got funded
    event FundedValidatorKey(bytes publicKey);

    /// @notice The stored deposit contract address changed
    /// @param depositContract Address of the deposit contract
    event SetDepositContractAddress(address indexed depositContract);

    /// @notice The stored withdrawal credentials changed
    /// @param withdrawalCredentials The withdrawal credentials to use for deposits
    event SetWithdrawalCredentials(bytes32 withdrawalCredentials);

    /// @notice Not enough funds to deposit one validator
    error NotEnoughFunds();

    /// @notice The length of the BLS Public key is invalid during deposit
    error InconsistentPublicKeys();

    /// @notice The length of the BLS Signature is invalid during deposit
    error InconsistentSignatures();

    /// @notice The internal key retrieval returned no keys
    error NoAvailableValidatorKeys();

    /// @notice The received count of public keys to deposit is invalid
    error InvalidPublicKeyCount();

    /// @notice The received count of signatures to deposit is invalid
    error InvalidSignatureCount();

    /// @notice The withdrawal credentials value is null
    error InvalidWithdrawalCredentials();

    /// @notice An error occured during the deposit
    error ErrorOnDeposit();

    /// @notice Returns the amount of pending ETH
    /// @return The amount of pending ETH
    function getBalanceToDeposit() external view returns (uint256);

    /// @notice Retrieve the withdrawal credentials
    /// @return The withdrawal credentials
    function getWithdrawalCredentials() external view returns (bytes32);

    /// @notice Get the deposited validator count (the count of deposits made by the contract)
    /// @return The deposited validator count
    function getDepositedValidatorCount() external view returns (uint256);

    /// @notice Deposits current balance to the Consensus Layer by batches of 32 ETH
    /// @param _maxCount The maximum amount of validator keys to fund
    function depositToConsensusLayer(uint256 _maxCount) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inputs provided by the oracle
interface IOracleManagerV1 {
    /// @notice The stored oracle address changed
    /// @param oracleAddress The new oracle address
    event SetOracle(address indexed oracleAddress);

    /// @notice The consensus layer data provided by the oracle has been updated
    /// @param validatorCount The new count of validators running on the consensus layer
    /// @param validatorTotalBalance The new total balance sum of all validators
    /// @param roundId Round identifier
    event ConsensusLayerDataUpdate(uint256 validatorCount, uint256 validatorTotalBalance, bytes32 roundId);

    /// @notice The reported validator count is invalid
    /// @param providedValidatorCount The received validator count value
    /// @param depositedValidatorCount The number of deposits performed by the system
    error InvalidValidatorCountReport(uint256 providedValidatorCount, uint256 depositedValidatorCount);

    /// @notice Get oracle address
    /// @return The oracle address
    function getOracle() external view returns (address);

    /// @notice Get CL validator total balance
    /// @return The CL Validator total balance
    function getCLValidatorTotalBalance() external view returns (uint256);

    /// @notice Get CL validator count (the amount of validator reported by the oracles)
    /// @return The CL validator count
    function getCLValidatorCount() external view returns (uint256);

    /// @notice Set the oracle address
    /// @param _oracleAddress Address of the oracle
    function setOracle(address _oracleAddress) external;

    /// @notice Sets the validator count and validator total balance sum reported by the oracle
    /// @dev Can only be called by the oracle address
    /// @dev The round id is a blackbox value that should only be used to identify unique reports
    /// @dev When a report is performed, River computes the amount of fees that can be pulled
    /// @dev from the execution layer fee recipient. This amount is capped by the max allowed
    /// @dev increase provided during the report.
    /// @dev If the total asset balance increases (from the reported total balance and the pulled funds)
    /// @dev we then compute the share that must be taken for the collector on the positive delta.
    /// @dev The execution layer fees are taken into account here because they are the product of
    /// @dev node operator's work, just like consensus layer fees, and both should be handled in the
    /// @dev same manner, as a single revenue stream for the users and the collector.
    /// @param _validatorCount The number of active validators on the consensus layer
    /// @param _validatorTotalBalance The balance sum of the active validators on the consensus layer
    /// @param _roundId An identifier for this update
    /// @param _maxIncrease The maximum allowed increase in the total balance
    function setConsensusLayerData(
        uint256 _validatorCount,
        uint256 _validatorTotalBalance,
        bytes32 _roundId,
        uint256 _maxIncrease
    ) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Shares Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the shares of the depositor and the ERC20 interface
interface ISharesManagerV1 is IERC20 {
    /// @notice Balance too low to perform operation
    error BalanceTooLow();

    /// @notice Allowance too low to perform operation
    /// @param _from Account where funds are sent from
    /// @param _operator Account attempting the transfer
    /// @param _allowance Current allowance
    /// @param _value Requested transfer value in shares
    error AllowanceTooLow(address _from, address _operator, uint256 _allowance, uint256 _value);

    /// @notice Invalid empty transfer
    error NullTransfer();

    /// @notice Invalid transfer recipients
    /// @param _from Account sending the funds in the invalid transfer
    /// @param _to Account receiving the funds in the invalid transfer
    error UnauthorizedTransfer(address _from, address _to);

    /// @notice Retrieve the token name
    /// @return The token name
    function name() external pure returns (string memory);

    /// @notice Retrieve the token symbol
    /// @return The token symbol
    function symbol() external pure returns (string memory);

    /// @notice Retrieve the decimal count
    /// @return The decimal count
    function decimals() external pure returns (uint8);

    /// @notice Retrieve the total token supply
    /// @return The total supply in shares
    function totalSupply() external view returns (uint256);

    /// @notice Retrieve the total underlying asset supply
    /// @return The total underlying asset supply
    function totalUnderlyingSupply() external view returns (uint256);

    /// @notice Retrieve the balance of an account
    /// @param _owner Address to be checked
    /// @return The balance of the account in shares
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance of an account
    /// @param _owner Address to be checked
    /// @return The underlying balance of the account
    function balanceOfUnderlying(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance from an amount of shares
    /// @param _shares Amount of shares to convert
    /// @return The underlying asset balance represented by the shares
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256);

    /// @notice Retrieve the shares count from an underlying asset amount
    /// @param _underlyingAssetAmount Amount of underlying asset to convert
    /// @return The amount of shares worth the underlying asset amopunt
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256);

    /// @notice Retrieve the allowance value for a spender
    /// @param _owner Address that issued the allowance
    /// @param _spender Address that received the allowance
    /// @return The allowance in shares for a given spender
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// @notice Performs a transfer from the message sender to the provided account
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Performs a transfer between two recipients
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Approves an account for future spendings
    /// @dev An approved account can use transferFrom to transfer funds on behalf of the token owner
    /// @param _spender Address that is allowed to spend the tokens
    /// @param _value The allowed amount in shares, will override previous value
    /// @return True if success
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @notice Increase allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _additionalValue Amount of shares to add
    /// @return True if success
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool);

    /// @notice Decrease allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _subtractableValue Amount of shares to subtract
    /// @return True if success
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title User Deposit Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inbound transfers cases or the explicit submissions
interface IUserDepositManagerV1 {
    /// @notice User deposited ETH in the system
    /// @param depositor Address performing the deposit
    /// @param recipient Address receiving the minted shares
    /// @param amount Amount in ETH deposited
    event UserDeposit(address indexed depositor, address indexed recipient, uint256 amount);

    /// @notice And empty deposit attempt was made
    error EmptyDeposit();

    /// @notice Explicit deposit method to mint on msg.sender
    function deposit() external payable;

    /// @notice Explicit deposit method to mint on msg.sender and transfer to _recipient
    /// @param _recipient Address receiving the minted LsETH
    function depositAndTransfer(address _recipient) external payable;

    /// @notice Implicit deposit method, when the user performs a regular transfer to the contract
    receive() external payable;

    /// @notice Invalid call, when the user sends a transaction with a data payload but no method matched
    fallback() external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Lib Basis Points
/// @notice Holds the basis points max value
library LibBasisPoints {
    /// @notice The max value for basis points (represents 100%)
    uint256 internal constant BASIS_POINTS_MAX = 10_000;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Errors
/// @notice Library of common errors
library LibErrors {
    /// @notice The operator is unauthorized for the caller
    /// @param caller Address performing the call
    error Unauthorized(address caller);

    /// @notice The call was invalid
    error InvalidCall();

    /// @notice The argument was invalid
    error InvalidArgument();

    /// @notice The address is zero
    error InvalidZeroAddress();

    /// @notice The string is empty
    error InvalidEmptyString();

    /// @notice The fee is invalid
    error InvalidFee();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibErrors.sol";
import "./LibBasisPoints.sol";

/// @title Lib Sanitize
/// @notice Utilities to sanitize input values
library LibSanitize {
    /// @notice Reverts if address is 0
    /// @param _address Address to check
    function _notZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert LibErrors.InvalidZeroAddress();
        }
    }

    /// @notice Reverts if string is empty
    /// @param _string String to check
    function _notEmptyString(string memory _string) internal pure {
        if (bytes(_string).length == 0) {
            revert LibErrors.InvalidEmptyString();
        }
    }

    /// @notice Reverts if fee is invalid
    /// @param _fee Fee to check
    function _validFee(uint256 _fee) internal pure {
        if (_fee > LibBasisPoints.BASIS_POINTS_MAX) {
            revert LibErrors.InvalidFee();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Uint256
/// @notice Utilities to perform uint operations
library LibUint256 {
    /// @notice Converts a value to little endian (64 bits)
    /// @param _value The value to convert
    /// @return result The converted value
    function toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 tempValue = _value;
        result = tempValue & 0xFF;
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        result = (result << 8) | (tempValue & 0xFF);
        tempValue >>= 8;

        assert(0 == tempValue); // fully converted
        result <<= (24 * 8);
    }

    /// @notice Returns the minimum value
    /// @param _a First value
    /// @param _b Second value
    /// @return Smallest value between _a and _b
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a > _b ? _b : _a);
    }
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

/// @title Lib Unstructured Storage
/// @notice Utilities to work with unstructured storage
library LibUnstructuredStorage {
    /// @notice Retrieve a bool value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bool value
    function getStorageBool(bytes32 _position) internal view returns (bool data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an address value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The address value
    function getStorageAddress(bytes32 _position) internal view returns (address data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve a bytes32 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bytes32 value
    function getStorageBytes32(bytes32 _position) internal view returns (bytes32 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an uint256 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The uint256 value
    function getStorageUint256(bytes32 _position) internal view returns (uint256 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Sets a bool value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bool value to set
    function setStorageBool(bytes32 _position, bool _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an address value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The address value to set
    function setStorageAddress(bytes32 _position, address _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets a bytes32 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bytes32 value to set
    function setStorageBytes32(bytes32 _position, bytes32 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an uint256 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The uint256 value to set
    function setStorageUint256(bytes32 _position, uint256 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title River Address Storage
/// @notice Utility to manage the River Address in storage
library RiverAddress {
    /// @notice Storage slot of the River Address
    bytes32 internal constant RIVER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.riverAddress")) - 1);

    /// @notice Retrieve the River Address
    /// @return The River Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(RIVER_ADDRESS_SLOT);
    }

    /// @notice Sets the River Address
    /// @param _newValue New River Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(RIVER_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Version Storage
/// @notice Utility to manage the Version in storage
library Version {
    /// @notice Storage slot of the Version
    bytes32 public constant VERSION_SLOT = bytes32(uint256(keccak256("river.state.version")) - 1);

    /// @notice Retrieve the Version
    /// @return The Version
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(VERSION_SLOT);
    }

    /// @notice Sets the Version
    /// @param _newValue New Version
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(VERSION_SLOT, _newValue);
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