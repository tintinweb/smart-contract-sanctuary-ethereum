// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
import { Claimable } from "./access/Claimable.sol";
import { Errors } from "../libraries/Errors.sol";

// Repositories & services
bytes32 constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant ACL = "ACL";
bytes32 constant PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
bytes32 constant GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant WETH_TOKEN = "WETH_TOKEN";
bytes32 constant WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant LEVERAGED_ACTIONS = "LEVERAGED_ACTIONS";

/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Claimable, IAddressProvider {
    // Mapping from contract keys to respective addresses
    mapping(bytes32 => address) public addresses;

    // Contract version
    uint256 public constant version = 2;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // F:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACL, _address); // F:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // F:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // F:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // F:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(PRICE_ORACLE, _address); // F:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // F:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // F:[AP-6]
    }

    /// @return Address of DataCompressor
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // F:[AP-7]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(DATA_COMPRESSOR, _address); // F:[AP-7]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); // F:[AP-8]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(TREASURY_CONTRACT, _address); // F:[AP-8]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // F:[AP-9]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(GEAR_TOKEN, _address); // F:[AP-9]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // F:[AP-10]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_TOKEN, _address); // F:[AP-10]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // F:[AP-11]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_GATEWAY, _address); // F:[AP-11]
    }

    /// @return Address of PathFinder
    function getLeveragedActions() external view returns (address) {
        return _getAddress(LEVERAGED_ACTIONS); // T:[AP-7]
    }

    /// @dev Sets address of  PathFinder
    /// @param _address Address of  PathFinder
    function setLeveragedActions(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(LEVERAGED_ACTIONS, _address); // T:[AP-7]
    }

    /// @return Address of key, reverts if the key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // F:[AP-1]
        return result; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
        emit AddressSet(key, value); // F:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Claimable
/// @dev Implements logic for a two-step ownership transfer on top of Ownable
contract Claimable is Ownable {
    /// @dev The new owner that has not claimed ownership yet
    address public pendingOwner;

    /// @dev A modifier that restricts the function to the pending owner only
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) {
            revert("Claimable: Sender is not pending owner");
        }
        _;
    }

    /// @dev Sets pending owner to the new owner, but does not
    /// transfer ownership yet
    /// @param newOwner The address to become the future owner
    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Claimable: new owner is the zero address"
        );
        pendingOwner = newOwner;
    }

    /// @dev Used by the pending owner to claim ownership after transferOwnership
    function claimOwnership() external onlyPendingOwner {
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IAccountFactoryEvents {
    /// @dev Emits when the account mining contract is changed
    /// @notice Not applicable to factories deployed after V2
    event AccountMinerChanged(address indexed miner);

    /// @dev Emits when a new Credit Account is created
    event NewCreditAccount(address indexed account);

    /// @dev Emits when a Credit Manager takes an account from the factory
    event InitializeCreditAccount(
        address indexed account,
        address indexed creditManager
    );

    /// @dev Emits when a Credit Manager returns an account to the factory
    event ReturnCreditAccount(address indexed account);

    /// @dev Emits when a Credit Account is taking out of the factory forever
    ///      by root
    event TakeForever(address indexed creditAccount, address indexed to);
}

interface IAccountFactoryGetters {
    /// @dev Gets the next available credit account after the passed one, or address(0) if the passed account is the tail
    /// @param creditAccount Credit Account previous to the one to retrieve
    function getNext(address creditAccount) external view returns (address);

    /// @dev Head of CA linked list
    function head() external view returns (address);

    /// @dev Tail of CA linked list
    function tail() external view returns (address);

    /// @dev Returns the number of unused credit accounts in stock
    function countCreditAccountsInStock() external view returns (uint256);

    /// @dev Returns the credit account address under the passed id
    /// @param id The index of the requested CA
    function creditAccounts(uint256 id) external view returns (address);

    /// @dev Returns the number of deployed credit accounts
    function countCreditAccounts() external view returns (uint256);
}

interface IAccountFactory is
    IAccountFactoryGetters,
    IAccountFactoryEvents,
    IVersion
{
    /// @dev Provides a new credit account to a Credit Manager
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external returns (address);

    /// @dev Retrieves the Credit Account from the Credit Manager and adds it to the stock
    /// @param usedAccount Address of returned credit account
    function returnCreditAccount(address usedAccount) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IAddressProviderEvents {
    /// @dev Emits when an address is set for a contract role
    event AddressSet(bytes32 indexed service, address indexed newAddress);
}

/// @title Optimised for front-end Address Provider interface
interface IAddressProvider is IAddressProviderEvents, IVersion {
    /// @return Address of ACL contract
    function getACL() external view returns (address);

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address);

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address);

    /// @return Address of DataCompressor
    function getDataCompressor() external view returns (address);

    /// @return Address of GEAR token
    function getGearToken() external view returns (address);

    /// @return Address of WETH token
    function getWethToken() external view returns (address);

    /// @return Address of WETH Gateway
    function getWETHGateway() external view returns (address);

    /// @return Address of PriceOracle
    function getPriceOracle() external view returns (address);

    /// @return Address of DAO Treasury Multisig
    function getTreasuryContract() external view returns (address);

    /// @return Address of PathFinder
    function getLeveragedActions() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IContractsRegisterEvents {
    /// @dev Emits when a new pool is registered in the system
    event NewPoolAdded(address indexed pool);

    /// @dev Emits when a new Credit Manager is registered in the system
    event NewCreditManagerAdded(address indexed creditManager);
}

interface IContractsRegister is IContractsRegisterEvents, IVersion {
    //
    // POOLS
    //

    /// @dev Returns the array of registered pools
    function getPools() external view returns (address[] memory);

    /// @dev Returns a pool address from the list under the passed index
    /// @param i Index of the pool to retrieve
    function pools(uint256 i) external returns (address);

    /// @return Returns the number of registered pools
    function getPoolsCount() external view returns (uint256);

    /// @dev Returns true if the passed address is a pool
    function isPool(address) external view returns (bool);

    //
    // CREDIT MANAGERS
    //

    /// @dev Returns the array of registered Credit Managers
    function getCreditManagers() external view returns (address[] memory);

    /// @dev Returns a Credit Manager's address from the list under the passed index
    /// @param i Index of the Credit Manager to retrieve
    function creditManagers(uint256 i) external returns (address);

    /// @return Returns the number of registered Credit Managers
    function getCreditManagersCount() external view returns (uint256);

    /// @dev Returns true if the passed address is a Credit Manager
    function isCreditManager(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

/// @title Credit Account
/// @notice Implements generic credit account logic:
///   - Holds collateral assets
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Transfers assets
///   - Executes financial orders by calling connected protocols on its behalf
///
///  More: https://dev.gearbox.fi/developers/credit/credit_account

interface ICrediAccountExceptions {
    /// @dev throws if the caller is not the connected Credit Manager
    error CallerNotCreditManagerException();

    /// @dev throws if the caller is not the factory
    error CallerNotFactoryException();
}

interface ICreditAccount is ICrediAccountExceptions, IVersion {
    /// @dev Called on new Credit Account creation.
    /// @notice Initialize is used instead of constructor, since the contract is cloned.
    function initialize() external;

    /// @dev Connects this credit account to a Credit Manager. Restricted to the account factory (owner) only.
    /// @param _creditManager Credit manager address
    /// @param _borrowedAmount The amount borrowed at Credit Account opening
    /// @param _cumulativeIndexAtOpen The interest index at Credit Account opening
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    /// @dev Updates borrowed amount and cumulative index. Restricted to the currently connected Credit Manager.
    /// @param _borrowedAmount The amount currently lent to the Credit Account
    /// @param _cumulativeIndexAtOpen New cumulative index to calculate interest from
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    /// @dev Removes allowance for a token to a 3rd-party contract. Restricted to factory only.
    /// @param token ERC20 token to remove allowance for.
    /// @param targetContract Target contract to revoke allowance to.
    function cancelAllowance(address token, address targetContract) external;

    /// @dev Transfers tokens from the credit account to a provided address. Restricted to the current Credit Manager only.
    /// @param token Token to be transferred from the Credit Account.
    /// @param to Address of the recipient.
    /// @param amount Amount to be transferred.
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @dev Returns the principal amount borrowed from the pool
    function borrowedAmount() external view returns (uint256);

    /// @dev Returns the cumulative interest index since the last Credit Account's debt update
    function cumulativeIndexAtOpen() external view returns (uint256);

    /// @dev Returns the block at which the contract was last taken from the factory
    function since() external view returns (uint256);

    /// @dev Returns the address of the currently connected Credit Manager
    function creditManager() external view returns (address);

    /// @dev Address of the Credit Account factory
    function factory() external view returns (address);

    /// @dev Executes a call to a 3rd party contract with provided data. Restricted to the current Credit Manager only.
    /// @param destination Contract address to be called.
    /// @param data Data to call the contract with.
    function execute(address destination, bytes memory data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { Balance } from "../libraries/Balances.sol";
import { MultiCall } from "../libraries/MultiCall.sol";
import { ICreditManagerV2, ICreditManagerV2Exceptions } from "./ICreditManagerV2.sol";
import { IVersion } from "./IVersion.sol";

interface ICreditFacadeExtended {
    /// @dev Stores expected balances (computed as current balance + passed delta)
    ///      and compare with actual balances at the end of a multicall, reverts
    ///      if at least one is less than expected
    /// @param expected Array of expected balance changes
    /// @notice This is an extenstion function that does not exist in the Credit Facade
    ///         itself and can only be used within a multicall
    function revertIfReceivedLessThan(Balance[] memory expected) external;

    /// @dev Enables token in enabledTokenMask for the Credit Account of msg.sender
    /// @param token Address of token to enable
    function enableToken(address token) external;

    /// @dev Disables a token on the caller's Credit Account
    /// @param token Token to disable
    /// @notice This is an extenstion function that does not exist in the Credit Facade
    ///         itself and can only be used within a multicall
    function disableToken(address token) external;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of the borrower whose account is funded
    /// @param token Address of a collateral token
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable;

    /// @dev Increases debt for msg.sender's Credit Account
    /// - Borrows the requested amount from the pool
    /// - Updates the CA's borrowAmount / cumulativeIndexOpen
    ///   to correctly compute interest going forward
    /// - Performs a full collateral check
    ///
    /// @param amount Amount to borrow
    function increaseDebt(uint256 amount) external;

    /// @dev Decrease debt
    /// - Decreases the debt by paying the requested amount + accrued interest + fees back to the pool
    /// - It's also include to this payment interest accrued at the moment and fees
    /// - Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param amount Amount to increase borrowed amount
    function decreaseDebt(uint256 amount) external;
}

interface ICreditFacadeEvents {
    /// @dev Emits when a new Credit Account is opened through the
    ///      Credit Facade
    event OpenCreditAccount(
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 borrowAmount,
        uint16 referralCode
    );

    /// @dev Emits when the account owner closes their CA normally
    event CloseCreditAccount(address indexed borrower, address indexed to);

    /// @dev Emits when a Credit Account is liquidated due to low health factor
    event LiquidateCreditAccount(
        address indexed borrower,
        address indexed liquidator,
        address indexed to,
        uint256 remainingFunds
    );

    /// @dev Emits when a Credit Account is liquidated due to expiry
    event LiquidateExpiredCreditAccount(
        address indexed borrower,
        address indexed liquidator,
        address indexed to,
        uint256 remainingFunds
    );

    /// @dev Emits when the account owner increases CA's debt
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev Emits when the account owner reduces CA's debt
    event DecreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev Emits when the account owner add new collateral to a CA
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    /// @dev Emits when a multicall is started
    event MultiCallStarted(address indexed borrower);

    /// @dev Emits when a multicall is finished
    event MultiCallFinished();

    /// @dev Emits when Credit Account ownership is transferred
    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    /// @dev Emits when the user changes approval for account transfers to itself from another address
    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    /// @dev Emits when the account owner enables a token on their CA
    event TokenEnabled(address indexed borrower, address indexed token);

    /// @dev Emits when the account owner disables a token on their CA
    event TokenDisabled(address indexed borrower, address indexed token);
}

interface ICreditFacadeExceptions is ICreditManagerV2Exceptions {
    /// @dev Thrown if the CreditFacade is not expirable, and an aciton is attempted that
    ///      requires expirability
    error NotAllowedWhenNotExpirableException();

    /// @dev Thrown if whitelisted mode is enabled, and an action is attempted that is
    ///      not allowed in whitelisted mode
    error NotAllowedInWhitelistedMode();

    /// @dev Thrown if a user attempts to transfer a CA to an address that didn't allow it
    error AccountTransferNotAllowedException();

    /// @dev Thrown if a liquidator tries to liquidate an account with a health factor above 1
    error CantLiquidateWithSuchHealthFactorException();

    /// @dev Thrown if a liquidator tries to liquidate an account by expiry while a Credit Facade is not expired
    error CantLiquidateNonExpiredException();

    /// @dev Thrown if call data passed to a multicall is too short
    error IncorrectCallDataException();

    /// @dev Thrown inside account closure multicall if the borrower attempts an action that is forbidden on closing
    ///      an account
    error ForbiddenDuringClosureException();

    /// @dev Thrown if debt increase and decrease are subsequently attempted in one multicall
    error IncreaseAndDecreaseForbiddenInOneCallException();

    /// @dev Thrown if a selector that doesn't match any allowed function is passed to the Credit Facade
    ///      during a multicall
    error UnknownMethodException();

    /// @dev Thrown if a user tries to open an account or increase debt with increaseDebtForbidden mode on
    error IncreaseDebtForbiddenException();

    /// @dev Thrown if the account owner tries to transfer an unhealthy account
    error CantTransferLiquidatableAccountException();

    /// @dev Thrown if too much new debt was taken within a single block
    error BorrowedBlockLimitException();

    /// @dev Thrown if the new debt principal for a CA falls outside of borrowing limits
    error BorrowAmountOutOfLimitsException();

    /// @dev Thrown if one of the balances on a Credit Account is less than expected
    ///      at the end of a multicall, if revertIfReceivedLessThan was called
    error BalanceLessThanMinimumDesiredException(address);

    /// @dev Thrown if a user attempts to open an account on a Credit Facade that has expired
    error OpenAccountNotAllowedAfterExpirationException();

    /// @dev Thrown if expected balances are attempted to be set through revertIfReceivedLessThan twice
    error ExpectedBalancesAlreadySetException();

    /// @dev Thrown if a Credit Account has enabled forbidden tokens and the owner attempts to perform an action
    ///      that is not allowed with any forbidden tokens enabled
    error ActionProhibitedWithForbiddenTokensException();
}

interface ICreditFacade is
    ICreditFacadeEvents,
    ICreditFacadeExceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /// @dev Opens credit account, borrows funds from the pool and pulls collateral
    /// without any additional action.
    /// @param amount The amount of collateral provided by the borrower
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != obBehalfOf
    /// @param leverageFactor Percentage of the user's own funds to borrow. 100 is equal to 100% - borrows the same amount
    /// as the user's own collateral, equivalent to 2x leverage.
    /// @param referralCode Referral code that is used for potential rewards. 0 if no referral code provided.
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external payable;

    /// @dev Opens a Credit Account and runs a batch of operations in a multicall
    /// @param borrowedAmount Debt size
    /// @param onBehalfOf The address to open an account for. Transfers to it have to be allowed if
    /// msg.sender != obBehalfOf
    /// @param calls The array of MultiCall structs encoding the required operations. Generally must have
    /// at least a call to addCollateral, as otherwise the health check at the end will fail.
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided
    function openCreditAccountMulticall(
        uint256 borrowedAmount,
        address onBehalfOf,
        MultiCall[] calldata calls,
        uint16 referralCode
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and closes the account
    /// - Wraps ETH to WETH and sends it msg.sender if value > 0
    /// - Executes the multicall - the main purpose of a multicall when closing is to convert all assets to underlying
    /// in order to pay the debt.
    /// - Closes credit account:
    ///    + Checks the underlying balance: if it is greater than the amount paid to the pool, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from msg.sender.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask
    ///    + If convertWETH is true, converts WETH into ETH before sending to the recipient
    /// - Emits a CloseCreditAccount event
    ///
    /// @param to Address to send funds to during account closing
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before closing the account.
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and liquidates the account
    /// - Computes the total value and checks that hf < 1. An account can't be liquidated when hf >= 1.
    ///   Total value has to be computed before the multicall, otherwise the liquidator would be able
    ///   to manipulate it.
    /// - Wraps ETH to WETH and sends it to msg.sender (liquidator) if value > 0
    /// - Executes the multicall - the main purpose of a multicall when liquidating is to convert all assets to underlying
    ///   in order to pay the debt.
    /// - Liquidate credit account:
    ///    + Computes the amount that needs to be paid to the pool. If totalValue * liquidationDiscount < borrow + interest + fees,
    ///      only totalValue * liquidationDiscount has to be paid. Since liquidationDiscount < 1, the liquidator can take
    ///      totalValue * (1 - liquidationDiscount) as premium. Also computes the remaining funds to be sent to borrower
    ///      as totalValue * liquidationDiscount - amountToPool.
    ///    + Checks the underlying balance: if it is greater than amountToPool + remainingFunds, transfers the underlying
    ///      from the Credit Account and proceeds. If not, tries to transfer the shortfall from the liquidator.
    ///    + Transfers all enabled assets with non-zero balances to the "to" address, unless they are marked
    ///      to be skipped in skipTokenMask. If the liquidator is confident that all assets were converted
    ///      during the multicall, they can set the mask to uint256.max - 1, to only transfer the underlying
    ///    + If convertWETH is true, converts WETH into ETH before sending
    /// - Emits LiquidateCreditAccount event
    ///
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Runs a batch of transactions within a multicall and liquidates the account when
    /// this Credit Facade is expired
    /// The general flow of liquidation is nearly the same as normal liquidations, with two main differences:
    ///     - An account can be liquidated on an expired Credit Facade even with hf > 1. However,
    ///       no accounts can be liquidated through this function if the Credit Facade is not expired.
    ///     - Liquidation premiums and fees for liquidating expired accounts are reduced.
    /// It is still possible to normally liquidate an underwater Credit Account, even when the Credit Facade
    /// is expired.
    /// @param to Address to send funds to after liquidation
    /// @param skipTokenMask Uint-encoded bit mask where 1's mark tokens that shouldn't be transferred
    /// @param convertWETH If true, converts WETH into ETH before sending to "to"
    /// @param calls The array of MultiCall structs encoding the operations to execute before liquidating the account.
    /// @notice See more at https://dev.gearbox.fi/docs/documentation/credit/liquidation#liquidating-accounts-by-expiration
    function liquidateExpiredCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Increases debt for msg.sender's Credit Account
    /// - Borrows the requested amount from the pool
    /// - Updates the CA's borrowAmount / cumulativeIndexOpen
    ///   to correctly compute interest going forward
    /// - Performs a full collateral check
    ///
    /// @param amount Amount to borrow
    function increaseDebt(uint256 amount) external;

    /// @dev Decrease debt
    /// - Decreases the debt by paying the requested amount + accrued interest + fees back to the pool
    /// - It's also include to this payment interest accrued at the moment and fees
    /// - Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param amount Amount to increase borrowed amount
    function decreaseDebt(uint256 amount) external;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of the borrower whose account is funded
    /// @param token Address of a collateral token
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable;

    /// @dev Executes a batch of transactions within a Multicall, to manage an existing account
    ///  - Wraps ETH and sends it back to msg.sender, if value > 0
    ///  - Executes the Multicall
    ///  - Performs a fullCollateralCheck to verify that hf > 1 after all actions
    /// @param calls The array of MultiCall structs encoding the operations to execute.
    function multicall(MultiCall[] calldata calls) external payable;

    /// @dev Returns true if the borrower has an open Credit Account
    /// @param borrower Borrower address
    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    /// @dev Sets token allowance from msg.sender's Credit Account to a connected target contract
    /// @param targetContract Contract to set allowance to. Cannot be in the list of upgradeable contracts
    /// @param token Token address
    /// @param amount Allowance amount
    function approve(
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Approves account transfer from another user to msg.sender
    /// @param from Address for which account transfers are allowed/forbidden
    /// @param state True is transfer is allowed, false if forbidden
    function approveAccountTransfer(address from, bool state) external;

    /// @dev Enables token in enabledTokenMask for the Credit Account of msg.sender
    /// @param token Address of token to enable
    function enableToken(address token) external;

    /// @dev Transfers credit account to another user
    /// By default, this action is forbidden, and the user has to approve transfers from sender to itself
    /// by calling approveAccountTransfer.
    /// This is done to prevent malicious actors from transferring compromised accounts to other users.
    /// @param to Address to transfer the account to
    function transferAccountOwnership(address to) external;

    //
    // GETTERS
    //

    /// @dev Calculates total value for provided Credit Account in underlying
    ///
    /// @param creditAccount Credit Account address
    /// @return total Total value in underlying
    /// @return twv Total weighted (discounted by liquidation thresholds) value in underlying
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total, uint256 twv);

    /**
     * @dev Calculates health factor for the credit account
     *
     *          sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *         borrowed amount + interest accrued + fees
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return hf = Health factor in bp (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256 hf);

    /// @dev Returns true if token is a collateral token and is not forbidden,
    /// otherwise returns false
    /// @param token Token to check
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns the CreditManager connected to this Credit Facade
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev Returns true if 'from' is allowed to transfer Credit Accounts to 'to'
    /// @param from Sender address to check allowance for
    /// @param to Receiver address to check allowance for
    function transfersAllowed(address from, address to)
        external
        view
        returns (bool);

    /// @return maxBorrowedAmountPerBlock Maximal amount of new debt that can be taken per block
    /// @return isIncreaseDebtForbidden True if increasing debt is forbidden
    /// @return expirationDate Timestamp of the next expiration (for expirable Credit Facades only)
    function params()
        external
        view
        returns (
            uint128 maxBorrowedAmountPerBlock,
            bool isIncreaseDebtForbidden,
            uint40 expirationDate
        );

    /// @return minBorrowedAmount Minimal borrowed amount per credit account
    /// @return maxBorrowedAmount Maximal borrowed amount per credit account
    function limits()
        external
        view
        returns (uint128 minBorrowedAmount, uint128 maxBorrowedAmount);

    /// @dev Address of the DegenNFT that gatekeeps account openings in whitelisted mode
    function degenNFT() external view returns (address);

    /// @dev Address of the underlying asset
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IPriceOracleV2 } from "./IPriceOracle.sol";
import { IVersion } from "./IVersion.sol";

enum ClosureAction {
    CLOSE_ACCOUNT,
    LIQUIDATE_ACCOUNT,
    LIQUIDATE_EXPIRED_ACCOUNT,
    LIQUIDATE_PAUSED
}

interface ICreditManagerV2Events {
    /// @dev Emits when a call to an external contract is made through the Credit Manager
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev Emits when a configurator is upgraded
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade, or an allowed adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Facade
    error CreditFacadeOnlyException();

    /// @dev Thrown if an access-restricted function is called by an address that is not
    ///      the connected Credit Configurator
    error CreditConfiguratorOnlyException();

    /// @dev Thrown on attempting to open a Credit Account for or transfer a Credit Account
    ///      to the zero address or an address that already owns a Credit Account
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev Thrown on attempting to execute an order to an address that is not an allowed
    ///      target contract
    error TargetContractNotAllowedException();

    /// @dev Thrown on failing a full collateral check after an operation
    error NotEnoughCollateralException();

    /// @dev Thrown on attempting to receive a token that is not a collateral token
    ///      or was forbidden
    error TokenNotAllowedException();

    /// @dev Thrown if an attempt to approve a collateral token to a target contract failed
    error AllowanceFailedException();

    /// @dev Thrown on attempting to perform an action for an address that owns no Credit Account
    error HasNoOpenedAccountException();

    /// @dev Thrown on attempting to add a token that is already in a collateral list
    error TokenAlreadyAddedException();

    /// @dev Thrown on configurator attempting to add more than 256 collateral tokens
    error TooManyTokensException();

    /// @dev Thrown if more than the maximal number of tokens were enabled on a Credit Account,
    ///      and there are not enough unused token to disable
    error TooManyEnabledTokensException();

    /// @dev Thrown when a reentrancy into the contract is attempted
    error ReentrancyLockException();
}

/// @notice All Credit Manager functions are access-restricted and can only be called
///         by the Credit Facade or allowed adapters. Users are not allowed to
///         interact with the Credit Manager directly
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and borrows funds from the pool.
    /// - Takes Credit Account from the factory;
    /// - Requests the pool to lend underlying to the Credit Account
    ///
    /// @param borrowedAmount Amount to be borrowed by the Credit Account
    /// @param onBehalfOf The owner of the newly opened Credit Account
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///  @dev Closes a Credit Account - covers both normal closure and liquidation
    /// - Checks whether the contract is paused, and, if so, if the payer is an emergency liquidator.
    ///   Only emergency liquidators are able to liquidate account while the CM is paused.
    ///   Emergency liquidations do not pay a liquidator premium or liquidation fees.
    /// - Calculates payments to various recipients on closure:
    ///    + Computes amountToPool, which is the amount to be sent back to the pool.
    ///      This includes the principal, interest and fees, but can't be more than
    ///      total position value
    ///    + Computes remainingFunds during liquidations - these are leftover funds
    ///      after paying the pool and the liquidator, and are sent to the borrower
    ///    + Computes protocol profit, which includes interest and liquidation fees
    ///    + Computes loss if the totalValue is less than borrow amount + interest
    /// - Checks the underlying token balance:
    ///    + if it is larger than amountToPool, then the pool is paid fully from funds on the Credit Account
    ///    + else tries to transfer the shortfall from the payer - either the borrower during closure, or liquidator during liquidation
    /// - Send assets to the "to" address, as long as they are not included into skipTokenMask
    /// - If convertWETH is true, the function converts WETH into ETH before sending
    /// - Returns the Credit Account back to factory
    ///
    /// @param borrower Borrower address
    /// @param closureActionType Whether the account is closed, liquidated or liquidated due to expiry
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH
    function closeCreditAccount(
        address borrower,
        ClosureAction closureActionType,
        uint256 totalValue,
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase debt:
    ///   + Increases debt by transferring funds from the pool to the credit account
    ///   + Updates the cumulative index to keep interest the same. Since interest
    ///     is always computed dynamically as borrowedAmount * (cumulativeIndexNew / cumulativeIndexOpen - 1),
    ///     cumulativeIndexOpen needs to be updated, as the borrow amount has changed
    ///
    /// - Decrease debt:
    ///   + Repays debt partially + all interest and fees accrued thus far
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of the Credit Account to change debt for
    /// @param amount Amount to increase / decrease the principal by
    /// @param increase True to increase principal, false to decrease
    /// @return newBorrowedAmount The new debt principal
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of the account which will be charged to provide additional collateral
    /// @param creditAccount Address of the Credit Account
    /// @param token Collateral token to add
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    ) external;

    /// @dev Transfers Credit Account ownership to another address
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to) external;

    /// @dev Requests the Credit Account to approve a collateral token to another contract.
    /// @param borrower Borrower's address
    /// @param targetContract Spender to change allowance for
    /// @param token Collateral token to approve
    /// @param amount New allowance amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    /// @dev Requests a Credit Account to make a low-level call with provided data
    /// This is the intended pathway for state-changing interactions with 3rd-party protocols
    /// @param borrower Borrower's address
    /// @param targetContract Contract to be called
    /// @param data Data to pass with the call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    ) external returns (bytes memory);

    //
    // COLLATERAL VALIDITY AND ACCOUNT HEALTH CHECKS
    //

    /// @dev Enables a token on a Credit Account, including it
    /// into account health and total value calculations
    /// @param creditAccount Address of a Credit Account to enable the token for
    /// @param token Address of the token to be enabled
    function checkAndEnableToken(address creditAccount, address token) external;

    /// @dev Optimized health check for individual swap-like operations.
    /// @notice Fast health check assumes that only two tokens (input and output)
    ///         participate in the operation and computes a % change in weighted value between
    ///         inbound and outbound collateral. The cumulative negative change across several
    ///         swaps in sequence cannot be larger than feeLiquidation (a fee that the
    ///         protocol is ready to waive if needed). Since this records a % change
    ///         between just two tokens, the corresponding % change in TWV will always be smaller,
    ///         which makes this check safe.
    ///         More details at https://dev.gearbox.fi/docs/documentation/risk/fast-collateral-check#fast-check-protection
    /// @param creditAccount Address of the Credit Account
    /// @param tokenIn Address of the token spent by the swap
    /// @param tokenOut Address of the token received from the swap
    /// @param balanceInBefore Balance of tokenIn before the operation
    /// @param balanceOutBefore Balance of tokenOut before the operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    /// @dev Performs a full health check on an account, summing up
    /// value of all enabled collateral tokens
    /// @param creditAccount Address of the Credit Account to check
    function fullCollateralCheck(address creditAccount) external;

    /// @dev Checks that the number of enabled tokens on a Credit Account
    ///      does not violate the maximal enabled token limit and tries
    ///      to disable unused tokens if it does
    /// @param creditAccount Account to check enabled tokens for
    function checkAndOptimizeEnabledTokens(address creditAccount) external;

    /// @dev Disables a token on a credit account
    /// @notice Usually called by adapters to disable spent tokens during a multicall,
    ///         but can also be called separately from the Credit Facade to remove
    ///         unwanted tokens
    /// @return True if token mask was change otherwise False
    function disableToken(address creditAccount, address token)
        external
        returns (bool);

    //
    // GETTERS
    //

    /// @dev Returns the address of a borrower's Credit Account, or reverts if there is none.
    /// @param borrower Borrower's address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Computes amounts that must be sent to various addresses before closing an account
    /// @param totalValue Credit Accounts total value in underlying
    /// @param closureActionType Type of account closure
    ///        * CLOSE_ACCOUNT: The account is healthy and is closed normally
    ///        * LIQUIDATE_ACCOUNT: The account is unhealthy and is being liquidated to avoid bad debt
    ///        * LIQUIDATE_EXPIRED_ACCOUNT: The account has expired and is being liquidated (lowered liquidation premium)
    ///        * LIQUIDATE_PAUSED: The account is liquidated while the system is paused due to emergency (no liquidation premium)
    /// @param borrowedAmount Credit Account's debt principal
    /// @param borrowedAmountWithInterest Credit Account's debt principal + interest
    /// @return amountToPool Amount of underlying to be sent to the pool
    /// @return remainingFunds Amount of underlying to be sent to the borrower (only applicable to liquidations)
    /// @return profit Protocol's profit from fees (if any)
    /// @return loss Protocol's loss from bad debt (if any)
    function calcClosePayments(
        uint256 totalValue,
        ClosureAction closureActionType,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );

    /// @dev Calculates the debt accrued by a Credit Account
    /// @param creditAccount Address of the Credit Account
    /// @return borrowedAmount The debt principal
    /// @return borrowedAmountWithInterest The debt principal + accrued interest
    /// @return borrowedAmountWithInterestAndFees The debt principal + accrued interest and protocol fees
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,
            uint256 borrowedAmountWithInterestAndFees
        );

    /// @dev Maps Credit Accounts to bit masks encoding their enabled token sets
    /// Only enabled tokens are counted as collateral for the Credit Account
    /// @notice An enabled token mask encodes an enabled token by setting
    ///         the bit at the position equal to token's index to 1
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Maps the Credit Account to its current percentage drop across all swaps since
    ///      the last full check, in RAY format
    function cumulativeDropAtFastCheckRAY(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Returns the collateral token at requested index and its liquidation threshold
    /// @param id The index of token to return
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Returns the collateral token with requested mask and its liquidationThreshold
    /// @param tokenMask Token mask corresponding to the token
    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Total number of known collateral tokens.
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns the mask for the provided token
    /// @param token Token to returns the mask for
    function tokenMasksMap(address token) external view returns (uint256);

    /// @dev Bit mask encoding a set of forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @dev Maps allowed adapters to their respective target contracts.
    function adapterToContract(address adapter) external view returns (address);

    /// @dev Maps 3rd party contracts to their respective adapters
    function contractToAdapter(address targetContract)
        external
        view
        returns (address);

    /// @dev Address of the underlying asset
    function underlying() external view returns (address);

    /// @dev Address of the connected pool
    function pool() external view returns (address);

    /// @dev Address of the connected pool
    /// @notice [DEPRECATED]: use pool() instead.
    function poolService() external view returns (address);

    /// @dev A map from borrower addresses to Credit Account addresses
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Address of the connected Credit Configurator
    function creditConfigurator() external view returns (address);

    /// @dev Address of WETH
    function wethAddress() external view returns (address);

    /// @dev Returns the liquidation threshold for the provided token
    /// @param token Token to retrieve the LT for
    function liquidationThresholds(address token)
        external
        view
        returns (uint16);

    /// @dev The maximal number of enabled tokens on a single Credit Account
    function maxAllowedEnabledTokenLength() external view returns (uint8);

    /// @dev Maps addresses to their status as emergency liquidator.
    /// @notice Emergency liquidators are trusted addresses
    /// that are able to liquidate positions while the contracts are paused,
    /// e.g. when there is a risk of bad debt while an exploit is being patched.
    /// In the interest of fairness, emergency liquidators do not receive a premium
    /// And are compensated by the Gearbox DAO separately.
    function canLiquidateWhilePaused(address) external view returns (bool);

    /// @dev Returns the fee parameters of the Credit Manager
    /// @return feeInterest Percentage of interest taken by the protocol as profit
    /// @return feeLiquidation Percentage of account value taken by the protocol as profit
    ///         during unhealthy account liquidations
    /// @return liquidationDiscount Multiplier that reduces the effective totalValue during unhealthy account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremium)
    /// @return feeLiquidationExpired Percentage of account value taken by the protocol as profit
    ///         during expired account liquidations
    /// @return liquidationDiscountExpired Multiplier that reduces the effective totalValue during expired account liquidations,
    ///         allowing the liquidator to take the unaccounted for remainder as premium. Equal to (1 - liquidationPremiumExpired)
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    /// @dev Address of the connected Credit Facade
    function creditFacade() external view returns (address);

    /// @dev Address of the connected Price Oracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Address of the universal adapter
    function universalAdapter() external view returns (address);

    /// @dev Contract's version
    function version() external view returns (uint256);

    /// @dev Paused() state
    function checkEmergencyPausable(address caller, bool state)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { CreditAccountData, CreditManagerData, PoolData, TokenInfo } from "../libraries/Types.sol";
import { IVersion } from "./IVersion.sol";

interface IDataCompressorExceptions {
    /// @dev Thrown if attempting to get data on a contract that is not a registered
    ///      Credit Manager
    error NotCreditManagerException();

    /// @dev Thrown if attempting the get data on a contract that is not a registered
    ///      pool
    error NotPoolException();
}

interface IDataCompressor is IDataCompressorExceptions, IVersion {
    /// @dev Returns CreditAccountData for all opened accounts for particular borrower
    /// @param borrower Borrower address
    function getCreditAccountList(address borrower)
        external
        view
        returns (CreditAccountData[] memory);

    /// @dev Returns whether the borrower has an open credit account with the credit manager
    /// @param creditManager Credit manager to check
    /// @param borrower Borrower to check
    function hasOpenedCreditAccount(address creditManager, address borrower)
        external
        view
        returns (bool);

    /// @dev Returns CreditAccountData for a particular Credit Account account, based on creditManager and borrower
    /// @param _creditManager Credit manager address
    /// @param borrower Borrower address
    function getCreditAccountData(address _creditManager, address borrower)
        external
        view
        returns (CreditAccountData memory);

    /// @dev Returns CreditManagerData for all Credit Managers
    function getCreditManagersList()
        external
        view
        returns (CreditManagerData[] memory);

    /// @dev Returns CreditManagerData for a particular _creditManager
    /// @param _creditManager CreditManager address
    function getCreditManagerData(address _creditManager)
        external
        view
        returns (CreditManagerData memory);

    /// @dev Returns PoolData for a particular pool
    /// @param _pool Pool address
    function getPoolData(address _pool) external view returns (PoolData memory);

    /// @dev Returns PoolData for all registered pools
    function getPoolsList() external view returns (PoolData[] memory);

    /// @dev Returns the adapter address for a particular creditManager and targetContract
    function getAdapter(address _creditManager, address _allowedContract)
        external
        view
        returns (address adapter);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import "../core/AddressProvider.sol";
import { IVersion } from "./IVersion.sol";

interface IPoolServiceEvents {
    /// @dev Emits on new liquidity being added to the pool
    event AddLiquidity(
        address indexed sender,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 referralCode
    );

    /// @dev Emits on liquidity being removed to the pool
    event RemoveLiquidity(
        address indexed sender,
        address indexed to,
        uint256 amount
    );

    /// @dev Emits on a Credit Manager borrowing funds for a Credit Account
    event Borrow(
        address indexed creditManager,
        address indexed creditAccount,
        uint256 amount
    );

    /// @dev Emits on repayment of a Credit Account's debt
    event Repay(
        address indexed creditManager,
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    );

    /// @dev Emits on updating the interest rate model
    event NewInterestRateModel(address indexed newInterestRateModel);

    /// @dev Emits on connecting a new Credit Manager
    event NewCreditManagerConnected(address indexed creditManager);

    /// @dev Emits when a Credit Manager is forbidden to borrow
    event BorrowForbidden(address indexed creditManager);

    /// @dev Emitted when loss is incurred that can't be covered by treasury funds
    event UncoveredLoss(address indexed creditManager, uint256 loss);

    /// @dev Emits when the liquidity limit is changed
    event NewExpectedLiquidityLimit(uint256 newLimit);

    /// @dev Emits when the withdrawal fee is changed
    event NewWithdrawFee(uint256 fee);
}

/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Taking/repaying Credit Manager debt
/// More: https://dev.gearbox.fi/developers/pool/abstractpoolservice
interface IPoolService is IPoolServiceEvents, IVersion {
    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to pool
     * - transfers the underlying to the pool
     * - mints Diesel (LP) tokens to onBehalfOf
     * @param amount Amount of tokens to be deposited
     * @param onBehalfOf The address that will receive the dToken
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without a facilitator.
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external;

    /**
     * @dev Removes liquidity from pool
     * - burns LP's Diesel (LP) tokens
     * - returns the equivalent amount of underlying to 'to'
     * @param amount Amount of Diesel tokens to burn
     * @param to Address to transfer the underlying to
     */

    function removeLiquidity(uint256 amount, address to)
        external
        returns (uint256);

    /**
     * @dev Lends pool funds to a Credit Account
     * @param borrowedAmount Credit Account's debt principal
     * @param creditAccount Credit Account's address
     */
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external;

    /**
     * @dev Repays the Credit Account's debt
     * @param borrowedAmount Amount of principal ro repay
     * @param profit The treasury profit from repayment
     * @param loss Amount of underlying that the CA wan't able to repay
     * @notice Assumes that the underlying (including principal + interest + fees)
     *         was already transferred
     */
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    ) external;

    //
    // GETTERS
    //

    /**
     * @dev Returns the total amount of liquidity in the pool, including borrowed and available funds
     */
    function expectedLiquidity() external view returns (uint256);

    /**
     * @dev Returns the limit on total liquidity
     */
    function expectedLiquidityLimit() external view returns (uint256);

    /**
     * @dev Returns the available liquidity, which is expectedLiquidity - totalBorrowed
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @dev Calculates the current interest index, RAY format
     */
    function calcLinearCumulative_RAY() external view returns (uint256);

    /**
     * @dev Calculates the current borrow rate, RAY format
     */
    function borrowAPY_RAY() external view returns (uint256);

    /**
     * @dev Returns the total borrowed amount (includes principal only)
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * ç
     **/

    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev Returns the address of the underlying
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Returns the address of the diesel token
     */
    function dieselToken() external view returns (address);

    /**
     * @dev Returns the address of a Credit Manager by its id
     */
    function creditManagers(uint256 id) external view returns (address);

    /**
     * @dev Returns the number of known Credit Managers
     */
    function creditManagersCount() external view returns (uint256);

    /**
     * @dev Maps Credit Manager addresses to their status as a borrower.
     *      Returns false if borrowing is not allowed.
     */
    function creditManagersCanBorrow(address id) external view returns (bool);

    /// @dev Converts a quantity of the underlying to Diesel tokens
    function toDiesel(uint256 amount) external view returns (uint256);

    /// @dev Converts a quantity of Diesel tokens to the underlying
    function fromDiesel(uint256 amount) external view returns (uint256);

    /// @dev Returns the withdrawal fee
    function withdrawFee() external view returns (uint256);

    /// @dev Returns the timestamp of the pool's last update
    function _timestampLU() external view returns (uint256);

    /// @dev Returns the interest index at the last pool update
    function _cumulativeIndex_RAY() external view returns (uint256);

    /// @dev Returns the address provider
    function addressProvider() external view returns (AddressProvider);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IPriceOracleV2Events {
    /// @dev Emits when a new price feed is added
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev Thrown if a price feed returns 0
    error ZeroPriceException();

    /// @dev Thrown if the last recorded result was not updated in the last round
    error ChainPriceStaleException();

    /// @dev Thrown on attempting to get a result for a token that does not have a price feed
    error PriceOracleNotExistsException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// @dev Converts a quantity of an asset to USD (decimals = 8).
    /// @param amount Amount to convert
    /// @param token Address of the token to be converted
    function convertToUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
    /// @param amount Amount to convert
    /// @param token Address of the token converted to
    function convertFromUSD(uint256 amount, address token)
        external
        view
        returns (uint256);

    /// @dev Converts one asset into another
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Address of the token to convert from
    /// @param tokenTo Address of the token to convert to
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Returns collateral values for two tokens, required for a fast check
    /// @param amountFrom Amount of the outbound token
    /// @param tokenFrom Address of the outbound token
    /// @param amountTo Amount of the inbound token
    /// @param tokenTo Address of the inbound token
    /// @return collateralFrom Value of the outbound token amount in USD
    /// @return collateralTo Value of the inbound token amount in USD
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns token's price in USD (8 decimals)
    /// @param token The token to compute the price for
    function getPrice(address token) external view returns (uint256);

    /// @dev Returns the price feed address for the passed token
    /// @param token Token to get the price feed for
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns the price feed for the passed token,
    ///      with additional parameters
    /// @param token Token to get the price feed for
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool skipCheck,
            uint256 decimals
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets a price feed if it doesn't exist, or updates an existing one
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function addPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

interface IWETHGateway {
    /// @dev Converts ETH to WETH and add liqudity to the pool
    /// @param pool Address of PoolService contract to add liquidity to. This pool must have WETH as an underlying.
    /// @param onBehalfOf The address that will receive the diesel token.
    /// @param referralCode Code used to log the transaction facilitator, for potential rewards. 0 if non-applicable.
    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /// @dev Removes liquidity from the pool and converts WETH to ETH
    ///       - burns lp's diesel (LP) tokens
    ///       - unwraps WETH to ETH and sends to the LP
    /// @param pool Address of PoolService contract to withdraw liquidity from. This pool must have WETH as an underlying.
    /// @param amount Amount of Diesel tokens to send.
    /// @param to Address to transfer ETH to.
    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    ) external;

    /// @dev Converts WETH to ETH, and sends to the passed address
    /// @param to Address to send ETH to
    /// @param amount Amount of WETH to unwrap
    function unwrapWETH(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IWETH {
    /// @dev Deposits native ETH into the contract and mints WETH
    function deposit() external payable;

    /// @dev Transfers WETH to another account
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Burns WETH from msg.sender and send back native ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

struct Balance {
    address token;
    uint256 balance;
}

library BalanceOps {
    error UnknownToken(address);

    function copyBalance(Balance memory b)
        internal
        pure
        returns (Balance memory)
    {
        return Balance({ token: b.token, balance: b.balance });
    }

    function addBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance += amount;
    }

    function subBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance -= amount;
    }

    function getBalance(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 amount)
    {
        return b[getIndex(b, token)].balance;
    }

    function setBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance = amount;
    }

    function getIndex(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < b.length; ) {
            if (b[i].token == token) {
                return i;
            }

            unchecked {
                ++i;
            }
        }
        revert UnknownToken(token);
    }

    function copy(Balance[] memory b, uint256 len)
        internal
        pure
        returns (Balance[] memory res)
    {
        res = new Balance[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyBalance(b[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(Balance[] memory b)
        internal
        pure
        returns (Balance[] memory)
    {
        return copy(b, b.length);
    }

    function getModifiedAfterSwap(
        Balance[] memory b,
        address tokenFrom,
        uint256 amountFrom,
        address tokenTo,
        uint256 amountTo
    ) internal pure returns (Balance[] memory res) {
        res = copy(b, b.length);
        setBalance(res, tokenFrom, getBalance(b, tokenFrom) - amountFrom);
        setBalance(res, tokenTo, getBalance(b, tokenTo) + amountTo);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Errors library
library Errors {
    //
    // COMMON
    //
    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //
    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //
    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // ACCOUNT FACTORY
    //
    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //
    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //
    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT ACCOUNT
    //
    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // ACL
    //
    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //
    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct MultiCall {
    address target;
    bytes callData;
}

library MultiCallOps {
    function copyMulticall(MultiCall memory call)
        internal
        pure
        returns (MultiCall memory)
    {
        return MultiCall({ target: call.target, callData: call.callData });
    }

    function trim(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory trimmed)
    {
        uint256 len = calls.length;

        if (len == 0) return calls;

        uint256 foundLen;
        while (calls[foundLen].target != address(0)) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return calls;
            }
        }

        if (foundLen > 0) return copy(calls, foundLen);
    }

    function copy(MultiCall[] memory calls, uint256 len)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        res = new MultiCall[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        return copy(calls, calls.length);
    }

    function append(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
        res[len] = copyMulticall(newCall);
    }

    function prepend(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        res[0] = copyMulticall(newCall);

        for (uint256 i = 1; i < len + 1; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function concat(MultiCall[] memory calls1, MultiCall[] memory calls2)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len1 = calls1.length;
        uint256 lenTotal = len1 + calls2.length;

        if (lenTotal == calls1.length) return clone(calls1);
        if (lenTotal == calls2.length) return clone(calls2);

        res = new MultiCall[](lenTotal);

        for (uint256 i; i < lenTotal; ) {
            res[i] = (i < len1)
                ? copyMulticall(calls1[i])
                : copyMulticall(calls2[i - len1]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title DataType library

struct Exchange {
    address[] path;
    uint256 amountOutMin;
}

struct TokenBalance {
    address token;
    uint256 balance;
    bool isAllowed;
    bool isEnabled;
}

struct ContractAdapter {
    address allowedContract;
    address adapter;
}

struct CreditAccountData {
    address addr;
    address borrower;
    bool inUse;
    address creditManager;
    address underlying;
    uint256 borrowedAmountPlusInterest;
    uint256 borrowedAmountPlusInterestAndFees;
    uint256 totalValue;
    uint256 healthFactor;
    uint256 borrowRate;
    TokenBalance[] balances;
    uint256 repayAmount; // for v1 accounts only
    uint256 liquidationAmount; // for v1 accounts only
    bool canBeClosed; // for v1 accounts only
    uint256 borrowedAmount;
    uint256 cumulativeIndexAtOpen;
    uint256 since;
    uint8 version;
    uint256 enabledTokenMask;
}

struct CreditManagerData {
    address addr;
    address underlying;
    address pool;
    bool isWETH;
    bool canBorrow;
    uint256 borrowRate;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 maxLeverageFactor; // for V1 only
    uint256 availableLiquidity;
    address[] collateralTokens;
    ContractAdapter[] adapters;
    uint256[] liquidationThresholds;
    uint8 version;
    address creditFacade; // V2 only: address of creditFacade
    address creditConfigurator; // V2 only: address of creditConfigurator
    bool isDegenMode; // V2 only: true if contract is in Degen mode
    address degenNFT; // V2 only: degenNFT, address(0) if not in degen mode
    bool isIncreaseDebtForbidden; // V2 only: true if increasing debt is forbidden
    uint256 forbiddenTokenMask; // V2 only: mask which forbids some particular tokens
    uint8 maxEnabledTokensLength; // V2 only: in V1 as many tokens as the CM can support (256)
    uint16 feeInterest; // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint16 feeLiquidation; // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint16 liquidationDiscount; // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint16 feeLiquidationExpired; // Liquidation fee protocol charges on expired accounts
    uint16 liquidationDiscountExpired; // Multiplier for the amount the liquidator has to pay when closing an expired account
}

struct PoolData {
    address addr;
    bool isWETH;
    address underlying;
    address dieselToken;
    uint256 linearCumulativeIndex;
    uint256 availableLiquidity;
    uint256 expectedLiquidity;
    uint256 expectedLiquidityLimit;
    uint256 totalBorrowed;
    uint256 depositAPY_RAY;
    uint256 borrowAPY_RAY;
    uint256 dieselRate_RAY;
    uint256 withdrawFee;
    uint256 cumulativeIndex_RAY;
    uint256 timestampLU;
    uint8 version;
}

struct TokenInfo {
    address addr;
    string symbol;
    uint8 decimals;
}

struct AddressProviderData {
    address contractRegister;
    address acl;
    address priceOracle;
    address traderAccountFactory;
    address dataCompressor;
    address farmingFactory;
    address accountMiner;
    address treasuryContract;
    address gearToken;
    address wethToken;
    address wethGateway;
}

struct MiningApproval {
    address token;
    address swapContract;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function underlying_coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function coins(int128) external view returns (address);

    function underlying_coins(int128) external view returns (address);

    function balances(int128) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function token() external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    // Some pools implement ERC20

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITradeExecutor.sol";
import "./interfaces/IVault.sol";

abstract contract BaseTradeExecutor is ITradeExecutor {
    uint256 internal constant MAX_INT = type(uint256).max;

    address public override vault;

    constructor(address _vault) {
        vault = _vault;
        IERC20(vaultWantToken()).approve(vault, MAX_INT);
    }

    function vaultWantToken() public view returns (address) {
        return IVault(vault).wantToken();
    }

    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    /// @notice restrict access to only governance
    modifier onlyGovernance() {
        require(msg.sender == governance(), "ONLY_GOV");
        _;
    }

    /// @notice restrict access to only keeper
    modifier onlyKeeper() {
        require(msg.sender == keeper(), "ONLY_KEEPER");
        _;
    }

    /// @notice restrict access to only vault
    modifier onlyVault() {
        require(msg.sender == vault, "ONLY_VAULT");
        _;
    }

    modifier keeperOrGovernance() {
        require(
            msg.sender == keeper() || msg.sender == governance(),
            "ONLY_KEEPER_OR_GOVERNANCE"
        );
        _;
    }

    function sweep(address _token) public onlyGovernance {
        IERC20(_token).transfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }


}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ClosureAction} from "gearbox_core/interfaces/ICreditManagerV2.sol";
// import {IUniswapV3Adapter} from "gearbox/interfaces/adapters/uniswap/IUniswapV3Adapter.sol";
import {ISwapRouter} from "gearbox_integrations/integrations/uniswap/IUniswapV3.sol";
import {ICurvePool} from "gearbox_integrations/integrations/curve/ICurvePool.sol";
import {MultiCall} from "gearbox_core/libraries/MultiCall.sol";

import {IwstETH} from "./interfaces/IwstETH.sol";
import {IstETH} from "./interfaces/IstETH.sol";
// import {IstETH} from "gearbox_integrations/integrations/lido/IstETH.sol";
// import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {IPoolService} from "gearbox_core/interfaces/IPoolService.sol";
import "./GearboxRegistry.sol";

contract CreditAccountController is GearboxRegistry {
    uint256 public immutable MAX_BPS = 1e4;
    uint256 public CURVE_ETH_STETH_SLIPPAGE = 200;
    uint256 public UNISWAP_ETH_USDC_POOL_SLIPPAGE = 100;
    uint256 public UNISWAP_ETH_FRAX_POOL_SLIPPAGE = 100;
    uint24 public UNISWAP_ETH_USDC_POOL_FEE = 500;
    uint24 public UNISWAP_USDC_FRAX_POOL_FEE = 100;
    uint256 public CURVE_SLIPPAGE_BOUND = 200;
    ICurvePool curvePool =
        ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    constructor(address addressProvider, address creditManager)
        GearboxRegistry(addressProvider, creditManager)
    {}

    function _openCreditAccount(
        uint256 fraxCollateral,
        uint256 ethToBorrow,
        MultiCall memory additionalCall
    ) internal {
        MultiCall[] memory calls = new MultiCall[](2);

        address _creditAccount = address(creditAccount());
        require(_creditAccount == address(0), "CA_ALREADY_EXISTS");
        FRAX.approve(address(creditManager()), fraxCollateral);

        calls[0] = _addCollateralCall(fraxCollateral);
        calls[1] = additionalCall;

        creditFacade().openCreditAccountMulticall(
            ethToBorrow,
            address(this),
            calls,
            0
        );
    }

    function _closeCreditAccount() internal {
        address _creditAccount = address(creditAccount());
        MultiCall[] memory calls = new MultiCall[](1);

        uint256 stETHBal = STETH.balanceOf(_creditAccount);
        if (stETHBal > 1e6) {
            MultiCall[] memory swapCall = new MultiCall[](1);
            uint256 amountOut = priceOracle().convert(
                stETHBal,
                address(STETH),
                address(WETH)
            );
            amountOut = accountOutputSlippage(
                amountOut,
                CURVE_ETH_STETH_SLIPPAGE
            );
            swapCall[0] = (_swapStETHToETHCall(stETHBal, amountOut));

            creditFacade().multicall(swapCall);
        }

        uint256 wethBal = WETH.balanceOf(_creditAccount);
        uint256 wethOwed = _getClosingUnderlyingOwed() + 1;
        /// Line 348 CM
        if (wethOwed > wethBal) {
            uint256 wethRequired = wethOwed - wethBal;

            uint256 fraxNeeded = priceOracle().convert(
                wethRequired,
                address(WETH),
                address(FRAX)
            );
            fraxNeeded = accountInputSlippage(
                fraxNeeded,
                UNISWAP_ETH_FRAX_POOL_SLIPPAGE
            );
            calls[0] = (_swapFRAXToETHCall(wethRequired, fraxNeeded));
        } else if (wethBal > wethOwed) {
            uint256 wethAvailable = wethBal - wethOwed;
            uint256 fraxOut = priceOracle().convert(
                wethAvailable,
                address(WETH),
                address(FRAX)
            );
            fraxOut = accountOutputSlippage(
                fraxOut,
                UNISWAP_ETH_FRAX_POOL_SLIPPAGE
            );
            calls[0] = (_swapETHToFRAXCall(wethAvailable, fraxOut));
        }

        creditFacade().closeCreditAccount(address(this), 0, false, calls);
    }

    function _convertStETHToFrax(uint256 stETHIn)
        internal
        returns (uint256 fraxOut)
    {
        uint256 oldWETHBal = WETH.balanceOf(address(creditAccount()));
        MultiCall[] memory swapCall = new MultiCall[](1);
        uint256 amountOut = priceOracle().convert(
            stETHIn,
            address(STETH),
            address(WETH)
        );
        amountOut = accountOutputSlippage(amountOut, CURVE_ETH_STETH_SLIPPAGE);
        swapCall[0] = (_swapStETHToETHCall(stETHIn, amountOut));

        creditFacade().multicall(swapCall);

        uint256 wethOut = WETH.balanceOf(address(creditAccount())) - oldWETHBal;

        uint256 minFraxOut = priceOracle().convert(
            wethOut,
            address(WETH),
            address(FRAX)
        );
        minFraxOut = accountOutputSlippage(
            fraxOut,
            UNISWAP_ETH_FRAX_POOL_SLIPPAGE
        );

        uint256 oldFraxBal = FRAX.balanceOf(address(creditAccount()));
        swapCall[0] = _swapETHToFRAXCall(wethOut, minFraxOut);
        creditFacade().multicall(swapCall);

        fraxOut = FRAX.balanceOf(address(creditAccount())) - oldFraxBal;
    }

    function _addCollateralCall(uint256 fraxIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.addCollateral.selector,
            address(this),
            address(FRAX),
            fraxIn
        );
    }

    function _increaseDebtCall(uint256 amountIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.increaseDebt.selector,
            amountIn
        );
    }

    function _decreaseDebtCall(uint256 amountIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.decreaseDebt.selector,
            amountIn
        );
    }

    function _getClosingUnderlyingOwed()
        internal
        view
        returns (uint256 amountToPool)
    {
        (uint256 total, ) = creditFacade().calcTotalValue(
            address(creditAccount())
        );

        (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,

        ) = creditManager().calcCreditAccountAccruedInterest(
                address(creditAccount())
            );

        (amountToPool, , , ) = creditManager().calcClosePayments(
            total,
            ClosureAction.CLOSE_ACCOUNT,
            borrowedAmount,
            borrowedAmountWithInterest
        );
    }

    /// UNISWAP V3 SWAPS

    function _swapETHToFRAXCall(uint256 ethIn, uint256 minFraxOut)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInput.selector,
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        WETH,
                        UNISWAP_ETH_USDC_POOL_FEE,
                        USDC,
                        UNISWAP_USDC_FRAX_POOL_FEE,
                        FRAX
                    ),
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: ethIn,
                    amountOutMinimum: minFraxOut
                })
            )
        });
    }

    function _swapFRAXToETHCall(uint256 ethRequired, uint256 maxFRAXIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInput.selector,
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        FRAX,
                        UNISWAP_USDC_FRAX_POOL_FEE,
                        USDC,
                        UNISWAP_ETH_USDC_POOL_FEE,
                        WETH
                    ),
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: maxFRAXIn,
                    amountOutMinimum: ethRequired
                })
            )
        });
    }

    function _swapETHToUSDCCall(uint256 ethIn, uint256 minUSDCOut)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInputSingle.selector,
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(WETH),
                    tokenOut: address(USDC),
                    fee: UNISWAP_ETH_USDC_POOL_FEE,
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: ethIn,
                    amountOutMinimum: minUSDCOut,
                    sqrtPriceLimitX96: 0
                })
            )
        });
    }

    function _swapUSDCToETHCall(uint256 ethRequired, uint256 maxUSDCIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactOutputSingle.selector,
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(WETH),
                    fee: UNISWAP_ETH_USDC_POOL_FEE,
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountOut: ethRequired,
                    amountInMaximum: maxUSDCIn,
                    sqrtPriceLimitX96: 0
                })
            )
        });
    }

    /// CURVE SWAPS

    enum CurvePoolIndex {
        ETH,
        STETH
    }

    function _swapETHToStETHCall(uint256 ethAmount, uint256 minStETHAmount)
        internal
        view
        returns (MultiCall memory call)
    {
        uint256 stETHPriceCurve = curvePool.get_dy(0, 1, ethAmount);

        uint256 stETHPriceLido = ethAmount - 1;

        if (stETHPriceCurve > stETHPriceLido) {
            //curve swap
            call = MultiCall({
                target: adapter(CURVE_STETH_GATEWAY),
                callData: abi.encodeWithSelector(
                    ICurvePool.exchange.selector,
                    CurvePoolIndex.ETH, // i
                    CurvePoolIndex.STETH, // j
                    ethAmount, // dx
                    minStETHAmount // min_dy
                )
            });
        } else {
            //lido deposit
            call = MultiCall({
                target: adapter(LIDO_STETH_GATEWAY),
                callData: abi.encodeWithSelector(
                    IstETH.submit.selector,
                    ethAmount
                )
            });
        }
    }

    function _swapStETHToETHCall(uint256 stETHAmount, uint256 minETHAmount)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(CURVE_STETH_GATEWAY),
            callData: abi.encodeWithSelector(
                ICurvePool.exchange.selector,
                CurvePoolIndex.STETH, // i
                CurvePoolIndex.ETH, // j
                stETHAmount, // dx
                minETHAmount // min_dy
            )
        });
    }

    /// Helper Methods

    function accountOutputSlippage(uint256 amount, uint256 bps)
        internal
        pure
        returns (uint256)
    {
        return (amount * (MAX_BPS - bps)) / MAX_BPS;
    }

    function accountInputSlippage(uint256 amount, uint256 bps)
        internal
        pure
        returns (uint256)
    {
        return (amount * (MAX_BPS + bps)) / MAX_BPS;
    }

    function positionInWantToken() public view returns (uint256 totalEquity) {
        if (isCreditAccountOpen()) {
            (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
                .calcCreditAccountAccruedInterest(address(creditAccount()));

            uint256 totalBorrowedETHInWantToken = priceOracle().convert(
                borrowedAmountAndFeesAndInterest,
                address(WETH),
                address(FRAX)
            );

            uint256 totalstETHInWantToken = priceOracle().convert(
                getStETHPriceInETH(STETH.balanceOf(address(creditAccount()))),
                address(WETH),
                address(FRAX)
            );

            totalEquity =
                FRAX.balanceOf(address(creditAccount())) +
                totalstETHInWantToken -
                totalBorrowedETHInWantToken;
        }
    }

    function healthFactor()
        public
        view
        creditAccountRequired
        returns (uint256)
    {
        return
            creditFacade().calcCreditAccountHealthFactor(
                address(creditAccount())
            );
    }

    function getLeverage() public view returns (uint256 leverage) {
        uint256 totalEquity = positionInWantToken();

        (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
            .calcCreditAccountAccruedInterest(address(creditAccount()));

        uint256 totalBorrowedETHInWantToken = priceOracle().convert(
            borrowedAmountAndFeesAndInterest,
            address(WETH),
            address(FRAX)
        );
        leverage = (totalBorrowedETHInWantToken * MAX_BPS) / totalEquity;
    }

    function getBorrowingRate() public view returns (uint256 borrowRate) {
        IPoolService ethPool = IPoolService(creditManager().pool());
        borrowRate = ethPool.borrowAPY_RAY();
    }

    function getBalances()
        public
        view
        returns (
            uint256 fraxBalance,
            uint256 ethDebtBalance,
            uint256 stETHbalance
        )
    {
        if (isCreditAccountOpen() == true) {
            fraxBalance = FRAX.balanceOf(address(creditAccount()));

            (, , ethDebtBalance) = creditManager()
                .calcCreditAccountAccruedInterest(address(creditAccount()));

            stETHbalance = STETH.balanceOf(address(creditAccount()));
        }
    }

    function getPrices()
        public
        view
        returns (
            uint256 ethPrice,
            uint256 stETHPrice,
            uint256 stETHPriceOnCurve
        )
    {
        uint256 stETHBalance = STETH.balanceOf(address(creditAccount()));
        ethPrice = priceOracle().convertToUSD(1e18, address(WETH));
        stETHPrice = priceOracle().convertToUSD(1e18, address(STETH));
        stETHPriceOnCurve =
            (curvePool.get_dy(1, 0, stETHBalance) * MAX_BPS) /
            stETHBalance;
    }

    /// @notice Calculates ETH amount for stETH based on curvePool
    /// @param amountOfStETH The amount of stETH tokens to deposit
    function getStETHPriceInETH(uint256 amountOfStETH)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 oracleAmount = priceOracle().convert(
            amountOfStETH,
            address(STETH),
            address(WETH)
        );
        uint256 curveAmount = curvePool.get_dy(1, 0, amountOfStETH);
        uint256 boundAmount = (oracleAmount *
            (MAX_BPS - CURVE_SLIPPAGE_BOUND)) / MAX_BPS;
        amountOut = curveAmount < boundAmount ? boundAmount : curveAmount;
    }

    /// @notice Gives the min and max leverage the cm account can operate on.
    function getCMLeverageLimits()
        public
        view
        returns (uint256 minLeverage, uint256 maxLeverage)
    {
        (uint256 minAmountBorrow, uint256 maxAmountBorrow) = creditFacade()
            .limits();
        uint256 minAmount = priceOracle().convert(
            minAmountBorrow,
            address(WETH),
            address(FRAX)
        );
        uint256 maxAmount = priceOracle().convert(
            maxAmountBorrow,
            address(WETH),
            address(FRAX)
        );
        uint256 totalEquity = positionInWantToken();
        minLeverage = (minAmount * MAX_BPS) / totalEquity;

        minLeverage = (minLeverage * (MAX_BPS + 1000)) / MAX_BPS; // added 10% buffer
        maxLeverage = (maxAmount * MAX_BPS) / totalEquity;
        maxLeverage = (maxLeverage * (MAX_BPS - 1000)) / MAX_BPS; // removed 10% buffer
    }

    function _setSlippageBound(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        CURVE_SLIPPAGE_BOUND = slippage;
    }

    function _setCurveSwapSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        CURVE_ETH_STETH_SLIPPAGE = slippage;
    }

    function _setUniETHSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        UNISWAP_ETH_USDC_POOL_SLIPPAGE = slippage;
    }

    function _setUniFRAXSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        UNISWAP_ETH_FRAX_POOL_SLIPPAGE = slippage;
    }

    modifier checkSlippage(uint256 _slippage) {
        require(_slippage < MAX_BPS / 10, "ILLEGAL_SLIPPAGE");
        _;
    }

    function isCreditAccountOpen() public view returns (bool) {
        return !(address(creditAccount()) == address(0));
    }

    modifier creditAccountRequired() {
        require(isCreditAccountOpen(), "CREDIT_ACCOUNT_NOT_FOUND");
        _;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {MultiCall} from "gearbox_core/libraries/MultiCall.sol";

import {IVault} from "./interfaces/IVault.sol";
import {BaseTradeExecutor} from "./BaseTradeExecutor.sol";
import {CreditAccountController} from "./CreditAccountController.sol";

contract GearboxETHTradeExecutor is BaseTradeExecutor, CreditAccountController {
    constructor(
        address _vault,
        address _creditManager,
        address _addressProvider
    )
        BaseTradeExecutor(_vault)
        CreditAccountController(_addressProvider, _creditManager)
    {}

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event OpenCreditAccount(address indexed account, uint256 fraxIn);

    function openCreditAccount(uint256 fraxIn, uint256 leverage)
        external
        onlyKeeper
    {
        uint256 ethValue = priceOracle().convert(
            (fraxIn * leverage) / MAX_BPS,
            address(FRAX),
            address(WETH)
        );

        MultiCall memory call = CreditAccountController._swapETHToStETHCall(
            ethValue,
            ethValue - 1
        );

        CreditAccountController._openCreditAccount(fraxIn, ethValue, call);
        emit OpenCreditAccount(address(creditAccount()), fraxIn);
    }

    /// @notice Emitted after colllateral is deposited into credit account.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event IncreaseCollateral(uint256 fraxIn);

    function increaseCollateral(uint256 fraxIn)
        external
        onlyKeeper
        creditAccountRequired
    {
        FRAX.approve(address(creditManager()), fraxIn);
        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = CreditAccountController._addCollateralCall(fraxIn);
        creditFacade().multicall(calls);
        emit IncreaseCollateral(fraxIn);
    }

    /// @notice Emitted when leverage is updated.
    /// @param oldLeverage The value of old leverage.
    /// @param newLeverage The value of new leverage.
    event UpdatedLeverage(uint256 oldLeverage, uint256 newLeverage);

    function setLeverage(uint256 newLeverage) external onlyKeeper {
        uint256 currentLeverage = CreditAccountController.getLeverage();
        uint256 totalEquity = CreditAccountController.positionInWantToken();
        bool toBorrow = newLeverage > currentLeverage;

        if (toBorrow) {
            uint256 borrowedInWant = (totalEquity *
                (newLeverage - currentLeverage)) / MAX_BPS;
            uint256 ethIn = priceOracle().convert(
                borrowedInWant,
                address(FRAX),
                address(WETH)
            );
            increaseLeverage(ethIn);
        } else {
            uint256 borrowOutWant = (totalEquity *
                (currentLeverage - newLeverage)) / MAX_BPS;
            uint256 ethOut = priceOracle().convert(
                borrowOutWant,
                address(FRAX),
                address(WETH)
            );

            decreaseLeverage(ethOut);
        }

        emit UpdatedLeverage(currentLeverage, newLeverage);
    }

    /// @notice Emitted when more funds are borrowed.
    /// @param borrowedFunds The value of funds borrowed in eth .
    event DebtIncrease(uint256 borrowedFunds);

    function increaseLeverage(uint256 ethIn)
        public
        onlyKeeper
        creditAccountRequired
    {
        MultiCall[] memory calls = new MultiCall[](2);
        calls[0] = CreditAccountController._increaseDebtCall(ethIn);
        uint256 amountOut = priceOracle().convert(
            ethIn,
            address(WETH),
            address(STETH)
        );
        amountOut = accountOutputSlippage(amountOut, CURVE_ETH_STETH_SLIPPAGE);
        calls[1] = CreditAccountController._swapETHToStETHCall(
            ethIn,
            amountOut - 1
        );
        creditFacade().multicall(calls);
        emit DebtIncrease(ethIn);
    }

    /// @notice Emitted when more funds are payed back.
    /// @param payedFunds The value of funds payed back in eth .
    event DebtDecrease(uint256 payedFunds);

    function decreaseLeverage(uint256 ethOut)
        public
        onlyKeeper
        creditAccountRequired
    {
        uint256 wethBal = WETH.balanceOf(address(creditAccount()));
        MultiCall[] memory calls = new MultiCall[](1);
        uint256 amountIn = priceOracle().convert(
            ethOut,
            address(WETH),
            address(STETH)
        );
        amountIn = accountInputSlippage(amountIn, CURVE_ETH_STETH_SLIPPAGE);
        calls[0] = CreditAccountController._swapStETHToETHCall(
            amountIn,
            ethOut
        );
        creditFacade().multicall(calls);

        uint256 swapResult = WETH.balanceOf(address(creditAccount())) - wethBal;

        calls[0] = CreditAccountController._decreaseDebtCall(swapResult);

        creditFacade().multicall(calls);

        emit DebtDecrease(swapResult);
    }

    function multicall(MultiCall[] memory calls) external onlyKeeper {
        creditFacade().multicall(calls);
    }

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    event CloseCreditAccount(address indexed account);

    function closeCreditAccount() external onlyKeeper creditAccountRequired {
        emit CloseCreditAccount(address(creditAccount()));
        CreditAccountController._closeCreditAccount();
    }

    function closeCreditAccountManual(
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] memory additionalCalls
    ) external onlyKeeper creditAccountRequired {
        creditFacade().closeCreditAccount(
            address(this),
            skipTokenMask,
            convertWETH,
            additionalCalls
        );
    }

    /// @notice Emitted when yield is claimed.
    /// @param yield The amount of yield that is claimed.
    event Claim(uint256 yield);

    function claimYield() external onlyKeeper {
        // yieldAccumulated = stETH value - eth debt
        uint256 totalstETHInWantToken = priceOracle().convert(
            STETH.balanceOf(address(creditAccount())),
            address(STETH),
            address(FRAX)
        );
        (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
            .calcCreditAccountAccruedInterest(address(creditAccount()));

        uint256 totalBorrowedETHInWantToken = priceOracle().convert(
            borrowedAmountAndFeesAndInterest,
            address(WETH),
            address(FRAX)
        );

        uint256 yieldAccumulated = totalstETHInWantToken >
            totalBorrowedETHInWantToken
            ? (totalstETHInWantToken - totalBorrowedETHInWantToken)
            : 0;
        if (yieldAccumulated > 0) {
            uint256 yieldAccumulatedInStETH = priceOracle().convert(
                yieldAccumulated,
                address(FRAX),
                address(STETH)
            );

            // convert stETH to wantToken via swap.
            uint256 claimedYield = CreditAccountController._convertStETHToFrax(
                yieldAccumulatedInStETH
            );
            emit Claim(claimedYield);
        }
    }

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock)
    {
        posValue =
            FRAX.balanceOf(address(this)) +
            CreditAccountController.positionInWantToken();
        return (posValue, block.number);
    }

    /// @notice event emitted when slippage is updated
    event UpdatedSlippage(
        uint256 indexed oldSlippage,
        uint256 indexed newSlippage,
        uint256 indexed index
    );

    /// @notice Keeper function to set max slippage acceptable for accounting funds.
    /// @param _slippage Max accepted slippage during pricing of funds
    function setSlippageBound(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_SLIPPAGE_BOUND;

        CreditAccountController._setSlippageBound(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 0);
    }

    /// @notice Keeper function to set max accepted slippage of curve swaps
    /// @param _slippage Max accepted slippage during taking leveraged position
    function setCurveSwapSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_ETH_STETH_SLIPPAGE;

        CreditAccountController._setCurveSwapSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 1);
    }

    /// @notice Keeper function to set max accepted slippage of eth usdc swap.
    /// @param _slippage Max accepted slippage during harvesting
    function setUniETHSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController
            .UNISWAP_ETH_USDC_POOL_SLIPPAGE;

        CreditAccountController._setUniETHSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 2);
    }

    /// @notice Keeper function to set max accepted slippage of eth frax swap.
    /// @param _slippage Max accepted slippage during closing account
    function setUniFRAXSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController
            .UNISWAP_ETH_FRAX_POOL_SLIPPAGE;

        CreditAccountController._setUniETHSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 3);
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IACL} from "gearbox_core/interfaces/IACL.sol";
import {IAddressProvider} from "gearbox_core/interfaces/IAddressProvider.sol";
import {IContractsRegister} from "gearbox_core/interfaces/IContractsRegister.sol";
import {IAccountFactory} from "gearbox_core/interfaces/IAccountFactory.sol";
import {IDataCompressor} from "gearbox_core/interfaces/IDataCompressor.sol";
import {IPoolService} from "gearbox_core/interfaces/IPoolService.sol";
import {IWETH} from "gearbox_core/interfaces/external/IWETH.sol";
import {IWETHGateway} from "gearbox_core/interfaces/IWETHGateway.sol";
import {IPriceOracleV2} from "gearbox_core/interfaces/IPriceOracle.sol";
import {ICreditFacade} from "gearbox_core/interfaces/ICreditFacade.sol";
import {ICreditManagerV2} from "gearbox_core/interfaces/ICreditManagerV2.sol";
import {ICreditAccount} from "gearbox_core/interfaces/ICreditAccount.sol";

// import {IWETHGateway} from "gearbox/interfaces/IWETHGateway.sol";
// import {IWETHGateway} from "gearbox/interfaces/IWETHGateway.sol";

contract GearboxRegistry {
    IERC20 public FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public STETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IERC20 public WSTETH = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public CURVE_STETH_GATEWAY =
        0xEf0D72C594b28252BF7Ea2bfbF098792430815b1;
    address public UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public LIDO_STETH_GATEWAY =
        0x6f4b4aB5142787c05b7aB9A9692A0f46b997C29D;

    address internal _addressProvider =
        0xcF64698AFF7E5f27A11dff868AF228653ba53be0;
    address internal _wethCreditManager =
        0x5887ad4Cb2352E7F01527035fAa3AE0Ef2cE2b9B;

    constructor(address ap, address cm) {
        _setAddressProvider(ap);
        _setCreditManager(cm);
    }

    function adapter(address _allowedContract) public view returns (address) {
        return
            dataCompressor().getAdapter(
                address(creditManager()),
                _allowedContract
            );
    }

    function addressProvider() public view returns (IAddressProvider) {
        return IAddressProvider(_addressProvider);
    }

    function creditManager() public view returns (ICreditManagerV2) {
        return ICreditManagerV2(_wethCreditManager);
    }

    function creditAccount() public view returns (ICreditAccount) {
        return ICreditAccount(creditManager().creditAccounts(address(this)));
    }

    function acl() public view returns (IACL) {
        return IACL(addressProvider().getACL());
    }

    function contractsRegister() public view returns (IContractsRegister) {
        return IContractsRegister(addressProvider().getContractsRegister());
    }

    function accountFactory() public view returns (IAccountFactory) {
        return IAccountFactory(addressProvider().getAccountFactory());
    }

    function dataCompressor() public view returns (IDataCompressor) {
        return IDataCompressor(addressProvider().getDataCompressor());
    }

    function poolService() public view returns (IPoolService) {
        return IPoolService(creditManager().pool());
    }

    function gearToken() public view returns (IERC20) {
        return IERC20(addressProvider().getGearToken());
    }

    function weth() public view returns (IERC20) {
        return IERC20(addressProvider().getWethToken());
    }

    function wethGateway() public view returns (IWETHGateway) {
        return IWETHGateway(addressProvider().getWETHGateway());
    }

    function priceOracle() public view returns (IPriceOracleV2) {
        return IPriceOracleV2(addressProvider().getPriceOracle());
    }

    function creditFacade() public view returns (ICreditFacade) {
        return ICreditFacade(creditManager().creditFacade());
    }

    /// @dev Do not expose this method externally, discard the TE if this needs to be changed
    function _setAddressProvider(address ap) internal {
        _addressProvider = ap;
    }

    /// @dev Do not expose this method externally, discard the TE if this needs to be changed
    function _setCreditManager(address cm) internal {
        _wethCreditManager = cm;
    }

    function _setCurveStETHGateway(address gateway) internal {
        CURVE_STETH_GATEWAY = gateway;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ITradeExecutor {
    function vault() external view returns (address);

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver) external returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver) external returns (uint256 amountOut);
    function batcher() external view returns (address);
    function zapper() external view returns (address);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IstETH {
    function submit(uint256 amount) external returns (uint256 value);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IwstETHGetters is IERC20Metadata {
    function stETH() external view returns (address);

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     * @param _stETHAmount amount of stETH
     * @return Amount of wstETH for a given stETH amount
     */
    function getWstETHByStETH(uint256 _stETHAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     * @param _wstETHAmount amount of wstETH
     * @return Amount of stETH for a given wstETH amount
     */
    function getStETHByWstETH(uint256 _wstETHAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256);

    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of wstETH for a 1 stETH
     */
    function tokensPerStEth() external view returns (uint256);
}

interface IwstETH is IwstETHGetters {
    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @dev Requirements:
     *  - `_stETHAmount` must be non-zero
     *  - msg.sender must approve at least `_stETHAmount` stETH to this
     *    contract.
     *  - msg.sender must have at least `_stETHAmount` of stETH.
     * User should first approve _stETHAmount to the WstETH contract
     * @return Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external returns (uint256);

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}