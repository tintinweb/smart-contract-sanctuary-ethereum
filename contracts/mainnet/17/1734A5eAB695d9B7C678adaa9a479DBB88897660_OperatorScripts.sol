// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../../interfaces/INestedFactory.sol";
import "../../interfaces/IOperatorResolver.sol";
import "../../abstracts/MixinOperatorResolver.sol";
import "../../interfaces/external/ITransparentUpgradeableProxy.sol";

contract OperatorScripts {
    struct tupleOperator {
        bytes32 name;
        bytes4 selector;
    }

    address public immutable nestedFactory;
    address public immutable resolver;

    constructor(address _nestedFactory, address _resolver) {
        require(_nestedFactory != address(0), "AO-SCRIPT: INVALID_FACTORY_ADDR");
        require(_resolver != address(0), "AO-SCRIPT: INVALID_RESOLVER_ADDR");
        nestedFactory = _nestedFactory;
        resolver = _resolver;
    }

    /// @notice Call NestedFactory and OperatorResolver to add an operator.
    /// @param operator The operator to add
    /// @param name The operator bytes32 name
    function addOperator(IOperatorResolver.Operator memory operator, bytes32 name) external {
        require(operator.implementation != address(0), "AO-SCRIPT: INVALID_IMPL_ADDRESS");

        // Init arrays with length 1 (only one operator to import)
        bytes32[] memory names = new bytes32[](1);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](1);
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);

        names[0] = name;
        operatorsToImport[0] = operator;
        destinations[0] = MixinOperatorResolver(nestedFactory);

        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);

        ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
            ITransparentUpgradeableProxy(nestedFactory).implementation(),
            abi.encodeWithSelector(INestedFactory.addOperator.selector, name)
        );
    }

    /// @notice Deploy and add operators
    /// @dev One address and multiple selectors/names
    /// @param bytecode Operator implementation bytecode
    /// @param operators Array of tuples => bytes32/bytes4 (name and selector)
    function deployAddOperators(bytes memory bytecode, tupleOperator[] memory operators) external {
        uint256 operatorLength = operators.length;
        require(operatorLength != 0, "DAO-SCRIPT: INVALID_OPERATOR_LEN");
        require(bytecode.length != 0, "DAO-SCRIPT: BYTECODE_ZERO");

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployedAddress != address(0), "DAO-SCRIPT: FAILED_DEPLOY");

        // Init arrays
        bytes32[] memory names = new bytes32[](operatorLength);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](operatorLength);

        for (uint256 i; i < operatorLength; i++) {
            names[i] = operators[i].name;
            operatorsToImport[i] = IOperatorResolver.Operator(deployedAddress, operators[i].selector);
        }

        // Only the NestedFactory as destination
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);
        destinations[0] = MixinOperatorResolver(nestedFactory);

        // Start importing operators
        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);

        // Add all the operators to the factory
        for (uint256 i; i < operatorLength; i++) {
            ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
                ITransparentUpgradeableProxy(nestedFactory).implementation(),
                abi.encodeWithSelector(INestedFactory.addOperator.selector, operators[i].name)
            );
        }
    }

    /// @notice Call NestedFactory and OperatorResolver to remove an operator.
    /// @param name The operator bytes32 name
    function removeOperator(bytes32 name) external {
        ITransparentUpgradeableProxy(nestedFactory).upgradeToAndCall(
            ITransparentUpgradeableProxy(nestedFactory).implementation(),
            abi.encodeWithSelector(INestedFactory.removeOperator.selector, name)
        );

        // Init arrays with length 1 (only one operator to remove)
        bytes32[] memory names = new bytes32[](1);
        IOperatorResolver.Operator[] memory operatorsToImport = new IOperatorResolver.Operator[](1);
        MixinOperatorResolver[] memory destinations = new MixinOperatorResolver[](1);

        names[0] = name;
        operatorsToImport[0] = IOperatorResolver.Operator({ implementation: address(0), selector: bytes4(0) });
        destinations[0] = MixinOperatorResolver(nestedFactory);

        IOperatorResolver(resolver).importOperators(names, operatorsToImport, destinations);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NestedReserve.sol";
import "../FeeSplitter.sol";

/// @title NestedFactory interface
interface INestedFactory {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when the feeSplitter is updated
    /// @param feeSplitter The new feeSplitter address
    event FeeSplitterUpdated(address feeSplitter);

    /// @dev Emitted when the entryFees is updated
    /// @param entryFees The new entryFees amount
    event EntryFeesUpdated(uint256 entryFees);

    /// @dev Emitted when the exitFees is updated
    /// @param exitFees The new exitFees amount
    event ExitFeesUpdated(uint256 exitFees);

    /// @dev Emitted when the reserve is updated
    /// @param reserve The new reserve address
    event ReserveUpdated(address reserve);

    /// @dev Emitted when a NFT (portfolio) is created
    /// @param nftId The NFT token Id
    /// @param originalNftId If replicated, the original NFT token Id
    event NftCreated(uint256 indexed nftId, uint256 originalNftId);

    /// @dev Emitted when a NFT (portfolio) is updated
    /// @param nftId The NFT token Id
    event NftUpdated(uint256 indexed nftId);

    /// @dev Emitted when a new operator is added
    /// @param newOperator The new operator bytes name
    event OperatorAdded(bytes32 newOperator);

    /// @dev Emitted when an operator is removed
    /// @param oldOperator The old operator bytes name
    event OperatorRemoved(bytes32 oldOperator);

    /// @dev Emitted when tokens are unlocked (sent to the owner)
    /// @param token The unlocked token address
    /// @param amount The unlocked amount
    event TokensUnlocked(address token, uint256 amount);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Represent an order made to the factory when creating/editing an NFT
    /// @param operator The bytes32 name of the Operator
    /// @param token The expected token address in output/input
    /// @param callData The operator parameters (delegatecall)
    struct Order {
        bytes32 operator;
        address token;
        bytes callData;
    }

    /// @dev Represent multiple input orders for a given token to perform multiple trades.
    /// @param inputToken The input token
    /// @param amount The amount to transfer (input amount)
    /// @param orders The orders to perform using the input token.
    /// @param _fromReserve Specify the input token source (true if reserve, false if wallet)
    ///        Note: fromReserve can be read as "from portfolio"
    struct BatchedInputOrders {
        IERC20 inputToken;
        uint256 amount;
        Order[] orders;
        bool fromReserve;
    }

    /// @dev Represent multiple output orders to receive a given token
    /// @param outputToken The output token
    /// @param amounts The amount of sell tokens to use
    /// @param orders Orders calldata
    /// @param toReserve Specify the output token destination (true if reserve, false if wallet)
    ///        Note: toReserve can be read as "to portfolio"
    struct BatchedOutputOrders {
        IERC20 outputToken;
        uint256[] amounts;
        Order[] orders;
        bool toReserve;
    }

    /* ------------------------------ OWNER FUNCTIONS ------------------------------ */

    /// @notice Add an operator (name) for building cache
    /// @param operator The operator name to add
    function addOperator(bytes32 operator) external;

    /// @notice Remove an operator (name) for building cache
    /// @param operator The operator name to remove
    function removeOperator(bytes32 operator) external;

    /// @notice Sets the address receiving the fees
    /// @param _feeSplitter The address of the receiver
    function setFeeSplitter(FeeSplitter _feeSplitter) external;

    /// @notice Sets the entry fees amount
    ///         Where 1 = 0.01% and 10000 = 100%
    /// @param _entryFees Entry fees amount
    function setEntryFees(uint256 _entryFees) external;

    /// @notice Sets the exit fees amount
    ///         Where 1 = 0.01% and 10000 = 100%
    /// @param _exitFees Exit fees amount
    function setExitFees(uint256 _exitFees) external;

    /// @notice The Factory is not storing funds, but some users can make
    /// bad manipulations and send tokens to the contract.
    /// In response to that, the owner can retrieve the factory balance of a given token
    /// to later return users funds.
    /// @param _token The token to retrieve.
    function unlockTokens(IERC20 _token) external;

    /* ------------------------------ USERS FUNCTIONS ------------------------------ */

    /// @notice Create a portfolio and store the underlying assets from the positions
    /// @param _originalTokenId The id of the NFT replicated, 0 if not replicating
    /// @param _batchedOrders The order to execute
    function create(uint256 _originalTokenId, BatchedInputOrders[] calldata _batchedOrders) external payable;

    /// @notice Process multiple input orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedOrders The order to execute
    function processInputOrders(uint256 _nftId, BatchedInputOrders[] calldata _batchedOrders) external payable;

    /// @notice Process multiple output orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedOrders The order to execute
    function processOutputOrders(uint256 _nftId, BatchedOutputOrders[] calldata _batchedOrders) external;

    /// @notice Process multiple input orders and then multiple output orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedInputOrders The input orders to execute (first)
    /// @param _batchedOutputOrders The output orders to execute (after)
    function processInputAndOutputOrders(
        uint256 _nftId,
        BatchedInputOrders[] calldata _batchedInputOrders,
        BatchedOutputOrders[] calldata _batchedOutputOrders
    ) external payable;

    /// @notice Burn NFT and exchange all tokens for a specific ERC20 then send it back to the user
    /// @dev Will unwrap WETH output to ETH
    /// @param _nftId The id of the NFT to destroy
    /// @param _buyToken The output token
    /// @param _orders Orders calldata
    function destroy(
        uint256 _nftId,
        IERC20 _buyToken,
        Order[] calldata _orders
    ) external;

    /// @notice Withdraw a token from the reserve and transfer it to the owner without exchanging it
    /// @param _nftId NFT token ID
    /// @param _tokenIndex Index in array of tokens for this NFT and holding.
    function withdraw(uint256 _nftId, uint256 _tokenIndex) external;

    /// @notice Update the lock timestamp of an NFT record.
    /// Note: Can only increase the lock timestamp.
    /// @param _nftId The NFT id to get the record
    /// @param _timestamp The new timestamp.
    function updateLockTimestamp(uint256 _nftId, uint256 _timestamp) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../abstracts/MixinOperatorResolver.sol";

/// @title Operator address resolver interface
interface IOperatorResolver {
    /// @dev Represents an operator definition
    /// @param implementation Contract address
    /// @param selector Function selector
    struct Operator {
        address implementation;
        bytes4 selector;
    }

    /// @notice Emitted when an operator is imported
    /// @param name The operator name
    /// @param destination The operator definition
    event OperatorImported(bytes32 name, Operator destination);

    /// @notice Get an operator (address/selector) for a given name
    /// @param name The operator name
    /// @return The operator struct (address/selector)
    function getOperator(bytes32 name) external view returns (Operator memory);

    /// @notice Get an operator (address/selector) for a given name but require the operator to exist.
    /// @param name The operator name
    /// @param reason Require message
    /// @return The operator struct (address/selector)
    function requireAndGetOperator(bytes32 name, string calldata reason) external view returns (Operator memory);

    /// @notice Check if some operators are imported with the right name (and vice versa)
    /// @dev The check is performed on the index, make sure that the two arrays match
    /// @param names The operator names
    /// @param destinations The operator addresses
    /// @return True if all the addresses/names are correctly imported, false otherwise
    function areOperatorsImported(bytes32[] calldata names, Operator[] calldata destinations)
        external
        view
        returns (bool);

    /// @notice Import/replace operators
    /// @dev names and destinations arrays must coincide
    /// @param names Hashes of the operators names to register
    /// @param operatorsToImport Operators to import
    /// @param destinations Destinations to rebuild cache atomically
    function importOperators(
        bytes32[] calldata names,
        Operator[] calldata operatorsToImport,
        MixinOperatorResolver[] calldata destinations
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "../OperatorResolver.sol";
import "../interfaces/IOperatorResolver.sol";
import "../interfaces/INestedFactory.sol";

/// @title Mixin operator resolver
/// @notice Store in cache operators name and address/selector
abstract contract MixinOperatorResolver {
    /// @notice Emitted when cache is updated
    /// @param name The operator name
    /// @param destination The operator address
    event CacheUpdated(bytes32 name, IOperatorResolver.Operator destination);

    /// @dev The OperatorResolver used to build the cache
    OperatorResolver public immutable resolver;

    /// @dev Cache operators map of the name and Operator struct (address/selector)
    mapping(bytes32 => IOperatorResolver.Operator) internal operatorCache;

    constructor(address _resolver) {
        require(_resolver != address(0), "MOR: INVALID_ADDRESS");
        resolver = OperatorResolver(_resolver);
    }

    /// @dev This function is public not external in order for it to be overridden and
    ///      invoked via super in subclasses
    function resolverOperatorsRequired() public view virtual returns (bytes32[] memory) {}

    /// @notice Rebuild the operatorCache
    function rebuildCache() public {
        bytes32[] memory requiredOperators = resolverOperatorsRequired();
        bytes32 name;
        IOperatorResolver.Operator memory destination;
        // The resolver must call this function whenever it updates its state
        for (uint256 i = 0; i < requiredOperators.length; i++) {
            name = requiredOperators[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            destination = resolver.getOperator(name);
            if (destination.implementation != address(0)) {
                operatorCache[name] = destination;
            } else {
                delete operatorCache[name];
            }
            emit CacheUpdated(name, destination);
        }
    }

    /// @notice Check the state of operatorCache
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredOperators = resolverOperatorsRequired();
        bytes32 name;
        IOperatorResolver.Operator memory cacheTmp;
        IOperatorResolver.Operator memory actualValue;
        for (uint256 i = 0; i < requiredOperators.length; i++) {
            name = requiredOperators[i];
            cacheTmp = operatorCache[name];
            actualValue = resolver.getOperator(name);
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (
                actualValue.implementation != cacheTmp.implementation ||
                actualValue.selector != cacheTmp.selector ||
                cacheTmp.implementation == address(0)
            ) {
                return false;
            }
        }
        return true;
    }

    /// @dev Get operator address in cache and require (if exists)
    /// @param name The operator name
    /// @return The operator address
    function requireAndGetAddress(bytes32 name) internal view returns (IOperatorResolver.Operator memory) {
        IOperatorResolver.Operator memory _foundAddress = operatorCache[name];
        require(_foundAddress.implementation != address(0), string(abi.encodePacked("MOR: MISSING_OPERATOR: ", name)));
        return _foundAddress;
    }

    /// @dev Build the calldata (with safe datas) and call the Operator
    /// @param _order The order to execute
    /// @param _inputToken The input token address
    /// @param _outputToken The output token address
    /// @return success If the operator call is successful
    /// @return amounts The amounts from the execution (used and received)
    ///         - amounts[0] : The amount of output token
    ///         - amounts[1] : The amount of input token USED by the operator (can be different than expected)
    function callOperator(
        INestedFactory.Order calldata _order,
        address _inputToken,
        address _outputToken
    ) internal returns (bool success, uint256[] memory amounts) {
        IOperatorResolver.Operator memory _operator = requireAndGetAddress(_order.operator);
        // Parameters are concatenated and padded to 32 bytes.
        // We are concatenating the selector + given params
        bytes memory data;
        (success, data) = _operator.implementation.delegatecall(bytes.concat(_operator.selector, _order.callData));

        if (success) {
            address[] memory tokens;
            (amounts, tokens) = abi.decode(data, (uint256[], address[]));
            require(tokens[0] == _outputToken, "MOR: INVALID_OUTPUT_TOKEN");
            require(tokens[1] == _inputToken, "MOR: INVALID_INPUT_TOKEN");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

interface ITransparentUpgradeableProxy {
    function admin() external returns (address);

    function implementation() external returns (address);

    function changeAdmin(address newAdmin) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./abstracts/OwnableFactoryHandler.sol";

/// @title Stores underlying assets of NestedNFTs.
/// @notice The factory itself can only trigger a transfer after verification that the user
///         holds funds present in this contract. Only the factory can withdraw/transfer assets.
contract NestedReserve is OwnableFactoryHandler {
    /// @notice Release funds to a recipient
    /// @param _recipient The receiver
    /// @param _token The token to transfer
    /// @param _amount The amount to transfer
    function transfer(
        address _recipient,
        IERC20 _token,
        uint256 _amount
    ) external onlyFactory {
        require(_recipient != address(0), "NRS: INVALID_ADDRESS");
        SafeERC20.safeTransfer(_token, _recipient, _amount);
    }

    /// @notice Release funds to the factory
    /// @param _token The ERC20 to transfer
    /// @param _amount The amount to transfer
    function withdraw(IERC20 _token, uint256 _amount) external onlyFactory {
        SafeERC20.safeTransfer(_token, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/external/IWETH.sol";

/// @title Manage the fees between shareholders
/// @notice Receives fees collected by the NestedFactory, and splits the income among
/// shareholders (the NFT owners, Nested treasury and a NST buybacker contract).
contract FeeSplitter is Ownable, ReentrancyGuard {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when a payment is released
    /// @param to The address receiving the payment
    /// @param token The token transfered
    /// @param amount The amount paid
    event PaymentReleased(address to, address token, uint256 amount);

    /// @dev Emitted when a payment is received
    /// @param from The address sending the tokens
    /// @param token The token received
    /// @param amount The amount received
    event PaymentReceived(address from, address token, uint256 amount);

    /// @dev Emitted when the royalties weight is updated
    /// @param weight The new weight
    event RoyaltiesWeightUpdated(uint256 weight);

    /// @dev Emitted when a new shareholder is added
    /// @param account The new shareholder account
    /// @param weight The shareholder weight
    event ShareholdersAdded(address account, uint256 weight);

    /// @dev Emitted when a shareholder weight is updated
    /// @param account The shareholder address
    /// @param weight The new weight
    event ShareholderUpdated(address account, uint256 weight);

    /// @dev Emitted when royalties are claim released
    /// @param to The address claiming the royalties
    /// @param token The token received
    /// @param value The amount received
    event RoyaltiesReceived(address to, address token, uint256 value);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Represent a shareholder
    /// @param account Shareholders address that can receive income
    /// @param weight Determines share allocation
    struct Shareholder {
        address account;
        uint96 weight;
    }

    /// @dev Registers shares and amount release for a specific token or ETH
    struct TokenRecords {
        uint256 totalShares;
        uint256 totalReleased;
        mapping(address => uint256) shares;
        mapping(address => uint256) released;
    }

    /* ----------------------------- VARIABLES ----------------------------- */

    /// @dev Map of tokens with the tokenRecords
    mapping(address => TokenRecords) private tokenRecords;

    /// @dev All the shareholders (array)
    Shareholder[] private shareholders;

    /// @dev Royalties part weights when applicable
    uint256 public royaltiesWeight;

    uint256 public totalWeights;

    address public immutable weth;

    /* ---------------------------- CONSTRUCTOR ---------------------------- */

    constructor(
        address[] memory _accounts,
        uint96[] memory _weights,
        uint256 _royaltiesWeight,
        address _weth
    ) {
        require(_weth != address(0), "FS: INVALID_ADDRESS");
        // Initial shareholders addresses and weights
        setShareholders(_accounts, _weights);
        setRoyaltiesWeight(_royaltiesWeight);
        weth = _weth;
    }

    /// @dev Receive ether after a WETH withdraw call
    receive() external payable {
        require(msg.sender == weth, "FS: ETH_SENDER_NOT_WETH");
    }

    /* -------------------------- OWNER FUNCTIONS -------------------------- */

    /// @notice Sets the weight assigned to the royalties part for the fee
    /// @param _weight The new royalties weight
    function setRoyaltiesWeight(uint256 _weight) public onlyOwner {
        require(_weight != 0, "FS: WEIGHT_ZERO");
        totalWeights = totalWeights + _weight - royaltiesWeight;
        royaltiesWeight = _weight;
        emit RoyaltiesWeightUpdated(_weight);
    }

    /// @notice Sets a new list of shareholders
    /// @param _accounts Shareholders accounts list
    /// @param _weights Weight for each shareholder. Determines part of the payment allocated to them
    function setShareholders(address[] memory _accounts, uint96[] memory _weights) public onlyOwner {
        delete shareholders;
        uint256 accountsLength = _accounts.length;
        require(accountsLength != 0, "FS: EMPTY_ARRAY");
        require(accountsLength == _weights.length, "FS: INPUTS_LENGTH_MUST_MATCH");
        totalWeights = royaltiesWeight;

        for (uint256 i = 0; i < accountsLength; i++) {
            _addShareholder(_accounts[i], _weights[i]);
        }
    }

    /// @notice Updates weight for a shareholder
    /// @param _accountIndex Account to change the weight of
    /// @param _weight The new weight
    function updateShareholder(uint256 _accountIndex, uint96 _weight) external onlyOwner {
        require(_weight != 0, "FS: INVALID_WEIGHT");
        require(_accountIndex < shareholders.length, "FS: INVALID_ACCOUNT_INDEX");
        Shareholder storage _shareholder = shareholders[_accountIndex];
        totalWeights = totalWeights + _weight - _shareholder.weight;
        require(totalWeights != 0, "FS: TOTAL_WEIGHTS_ZERO");
        _shareholder.weight = _weight;
        emit ShareholderUpdated(_shareholder.account, _weight);
    }

    /* -------------------------- USERS FUNCTIONS -------------------------- */

    /// @notice Release multiple tokens and handle ETH unwrapping
    /// @param _tokens ERC20 tokens to release
    function releaseTokens(IERC20[] calldata _tokens) external nonReentrant {
        uint256 amount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            amount = _releaseToken(_msgSender(), _tokens[i]);
            if (address(_tokens[i]) == weth) {
                IWETH(weth).withdraw(amount);
                (bool success, ) = _msgSender().call{ value: amount }("");
                require(success, "FS: ETH_TRANFER_ERROR");
            } else {
                SafeERC20.safeTransfer(_tokens[i], _msgSender(), amount);
            }
            emit PaymentReleased(_msgSender(), address(_tokens[i]), amount);
        }
    }

    /// @notice Release multiple tokens without ETH unwrapping
    /// @param _tokens ERC20 tokens to release
    function releaseTokensNoETH(IERC20[] calldata _tokens) external nonReentrant {
        uint256 amount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            amount = _releaseToken(_msgSender(), _tokens[i]);
            SafeERC20.safeTransfer(_tokens[i], _msgSender(), amount);
            emit PaymentReleased(_msgSender(), address(_tokens[i]), amount);
        }
    }

    /// @notice Sends a fee to this contract for splitting, as an ERC20 token. No royalties are expected.
    /// @param _token Currency for the fee as an ERC20 token
    /// @param _amount Amount of token as fee to be claimed by this contract
    function sendFees(IERC20 _token, uint256 _amount) external nonReentrant {
        uint256 weights;
        unchecked {
            weights = totalWeights - royaltiesWeight;
        }

        uint256 balanceBeforeTransfer = _token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_token, _msgSender(), address(this), _amount);

        _sendFees(_token, _token.balanceOf(address(this)) - balanceBeforeTransfer, weights);
    }

    /// @notice Sends a fee to this contract for splitting, as an ERC20 token
    /// @param _royaltiesTarget The account that can claim royalties
    /// @param _token Currency for the fee as an ERC20 token
    /// @param _amount Amount of token as fee to be claimed by this contract
    function sendFeesWithRoyalties(
        address _royaltiesTarget,
        IERC20 _token,
        uint256 _amount
    ) external nonReentrant {
        require(_royaltiesTarget != address(0), "FS: INVALID_ROYALTIES_TARGET");

        uint256 balanceBeforeTransfer = _token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        uint256 amountReceived = _token.balanceOf(address(this)) - balanceBeforeTransfer;

        uint256 _totalWeights = totalWeights;
        uint256 royaltiesAmount = (amountReceived * royaltiesWeight) / _totalWeights;

        _sendFees(_token, amountReceived, _totalWeights);
        _addShares(_royaltiesTarget, royaltiesAmount, address(_token));

        emit RoyaltiesReceived(_royaltiesTarget, address(_token), royaltiesAmount);
    }

    /* ------------------------------- VIEWS ------------------------------- */

    /// @notice Returns the amount due to an account. Call releaseToken to withdraw the amount.
    /// @param _account Account address to check the amount due for
    /// @param _token ERC20 payment token address
    /// @return The total amount due for the requested currency
    function getAmountDue(address _account, IERC20 _token) public view returns (uint256) {
        TokenRecords storage _tokenRecords = tokenRecords[address(_token)];
        uint256 _totalShares = _tokenRecords.totalShares;
        if (_totalShares == 0) return 0;

        uint256 totalReceived = _tokenRecords.totalReleased + _token.balanceOf(address(this));
        return (totalReceived * _tokenRecords.shares[_account]) / _totalShares - _tokenRecords.released[_account];
    }

    /// @notice Getter for the total shares held by shareholders.
    /// @param _token Payment token address
    /// @return The total shares count
    function totalShares(address _token) external view returns (uint256) {
        return tokenRecords[_token].totalShares;
    }

    /// @notice Getter for the total amount of token already released.
    /// @param _token Payment token address
    /// @return The total amount release to shareholders
    function totalReleased(address _token) external view returns (uint256) {
        return tokenRecords[_token].totalReleased;
    }

    /// @notice Getter for the amount of shares held by an account.
    /// @param _account Account the shares belong to
    /// @param _token Payment token address
    /// @return The shares owned by the account
    function shares(address _account, address _token) external view returns (uint256) {
        return tokenRecords[_token].shares[_account];
    }

    /// @notice Getter for the amount of Ether already released to a shareholders.
    /// @param _account The target account for this request
    /// @param _token Payment token address
    /// @return The amount already released to this account
    function released(address _account, address _token) external view returns (uint256) {
        return tokenRecords[_token].released[_account];
    }

    /// @notice Finds a shareholder and return its index
    /// @param _account Account to find
    /// @return The shareholder index in the storage array
    function findShareholder(address _account) external view returns (uint256) {
        for (uint256 i = 0; i < shareholders.length; i++) {
            if (shareholders[i].account == _account) return i;
        }
        revert("FS: SHAREHOLDER_NOT_FOUND");
    }

    /* ------------------------- PRIVATE FUNCTIONS ------------------------- */

    /// @notice Transfers a fee to this contract
    /// @dev This method calculates the amount received, to support deflationary tokens
    /// @param _token Currency for the fee
    /// @param _amount Amount of token sent
    /// @param _totalWeights Total weights to determine the share count to allocate
    function _sendFees(
        IERC20 _token,
        uint256 _amount,
        uint256 _totalWeights
    ) private {
        Shareholder[] memory shareholdersCache = shareholders;
        for (uint256 i = 0; i < shareholdersCache.length; i++) {
            _addShares(
                shareholdersCache[i].account,
                (_amount * shareholdersCache[i].weight) / _totalWeights,
                address(_token)
            );
        }
        emit PaymentReceived(_msgSender(), address(_token), _amount);
    }

    /// @dev Increase the shares of a shareholder
    /// @param _account The shareholder address
    /// @param _shares The shares of the holder
    /// @param _token The updated token
    function _addShares(
        address _account,
        uint256 _shares,
        address _token
    ) private {
        TokenRecords storage _tokenRecords = tokenRecords[_token];
        _tokenRecords.shares[_account] += _shares;
        _tokenRecords.totalShares += _shares;
    }

    function _releaseToken(address _account, IERC20 _token) private returns (uint256) {
        uint256 amountToRelease = getAmountDue(_account, _token);
        require(amountToRelease != 0, "FS: NO_PAYMENT_DUE");

        TokenRecords storage _tokenRecords = tokenRecords[address(_token)];
        _tokenRecords.released[_account] += amountToRelease;
        _tokenRecords.totalReleased += amountToRelease;

        return amountToRelease;
    }

    function _addShareholder(address _account, uint96 _weight) private {
        require(_weight != 0, "FS: ZERO_WEIGHT");
        require(_account != address(0), "FS: INVALID_ADDRESS");
        for (uint256 i = 0; i < shareholders.length; i++) {
            require(shareholders[i].account != _account, "FS: ALREADY_SHAREHOLDER");
        }

        shareholders.push(Shareholder(_account, _weight));
        totalWeights += _weight;
        emit ShareholdersAdded(_account, _weight);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Asbtract "Ownable" contract managing a whitelist of factories
abstract contract OwnableFactoryHandler is Ownable {
    /// @dev Emitted when a new factory is added
    /// @param newFactory Address of the new factory
    event FactoryAdded(address newFactory);

    /// @dev Emitted when a factory is removed
    /// @param oldFactory Address of the removed factory
    event FactoryRemoved(address oldFactory);

    /// @dev Supported factories to interact with
    mapping(address => bool) public supportedFactories;

    /// @dev Reverts the transaction if the caller is a supported factory
    modifier onlyFactory() {
        require(supportedFactories[msg.sender], "OFH: FORBIDDEN");
        _;
    }

    /// @notice Add a supported factory
    /// @param _factory The address of the new factory
    function addFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "OFH: INVALID_ADDRESS");
        supportedFactories[_factory] = true;
        emit FactoryAdded(_factory);
    }

    /// @notice Remove a supported factory
    /// @param _factory The address of the factory to remove
    function removeFactory(address _factory) external onlyOwner {
        require(supportedFactories[_factory], "OFH: NOT_SUPPORTED");
        supportedFactories[_factory] = false;
        emit FactoryRemoved(_factory);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address recipien) external returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "./interfaces/IOperatorResolver.sol";
import "./abstracts/MixinOperatorResolver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Operator Resolver implementation
/// @notice Resolve the operators address
contract OperatorResolver is IOperatorResolver, Ownable {
    /// @dev Operators map of the name and address
    mapping(bytes32 => Operator) public operators;

    /// @inheritdoc IOperatorResolver
    function getOperator(bytes32 name) external view override returns (Operator memory) {
        return operators[name];
    }

    /// @inheritdoc IOperatorResolver
    function requireAndGetOperator(bytes32 name, string calldata reason)
        external
        view
        override
        returns (Operator memory)
    {
        Operator memory _foundOperator = operators[name];
        require(_foundOperator.implementation != address(0), reason);
        return _foundOperator;
    }

    /// @inheritdoc IOperatorResolver
    function areOperatorsImported(bytes32[] calldata names, Operator[] calldata destinations)
        external
        view
        override
        returns (bool)
    {
        uint256 namesLength = names.length;
        require(namesLength == destinations.length, "OR: INPUTS_LENGTH_MUST_MATCH");
        for (uint256 i = 0; i < namesLength; i++) {
            if (
                operators[names[i]].implementation != destinations[i].implementation ||
                operators[names[i]].selector != destinations[i].selector
            ) {
                return false;
            }
        }
        return true;
    }

    /// @inheritdoc IOperatorResolver
    function importOperators(
        bytes32[] calldata names,
        Operator[] calldata operatorsToImport,
        MixinOperatorResolver[] calldata destinations
    ) external override onlyOwner {
        require(names.length == operatorsToImport.length, "OR: INPUTS_LENGTH_MUST_MATCH");
        bytes32 name;
        Operator calldata destination;
        for (uint256 i = 0; i < names.length; i++) {
            name = names[i];
            destination = operatorsToImport[i];
            operators[name] = destination;
            emit OperatorImported(name, destination);
        }

        // rebuild caches atomically
        // see. https://github.com/code-423n4/2021-11-nested-findings/issues/217
        rebuildCaches(destinations);
    }

    /// @notice rebuild the caches of mixin smart contracts
    /// @param destinations The list of mixinOperatorResolver to rebuild
    function rebuildCaches(MixinOperatorResolver[] calldata destinations) public onlyOwner {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }
}