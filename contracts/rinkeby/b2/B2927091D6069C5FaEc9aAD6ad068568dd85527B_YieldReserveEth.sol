/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The contract for ownership
////import "./../access/Ownable.sol";

/**
 * @title Represents a controllable resource.
 */
contract Controllable is Ownable {
    // The address of the controller
    address internal _controllerAddress;

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param controllerAddr The address of the controller
     */
    constructor (address ownerAddr, address controllerAddr) Ownable (ownerAddr) {
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != ownerAddr, "Owner cannot be the Controller");
        _controllerAddress = controllerAddr;
    }

    /**
     * @notice Throws if the sender is not the controller
     */
    modifier onlyController() {
        require(msg.sender == _controllerAddress, "Unauthorized controller");
        _;
    }

    /**
     * @notice Makes sure the sender is either the owner of the contract or the controller
     */
    modifier onlyOwnerOrController() {
        require(msg.sender == _controllerAddress || msg.sender == _owner, "Only owner or controller");
        _;
    }

    /**
     * @notice Sets the controller
     * @dev This function can be called by the owner only
     * @param controllerAddr The address of the controller
     */
    function setController (address controllerAddr) public onlyOwner {
        // Checks
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != _owner, "Owner cannot be the Controller");
        require(controllerAddr != _controllerAddress, "Controller already set");

        // State changes
        _controllerAddress = controllerAddr;
    }

    /**
     * @notice Gets the address of the controller
     * @return Returns an address
     */
    function getControllerAddress () public view returns (address) {
        return _controllerAddress;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

/**
 * @notice Defines the interface for whitelisting addresses.
 */
interface IAddressWhitelist {
    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external;

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external;

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns 1 if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view returns (bool);
}




/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

////import "./../access/Controllable.sol";

/**
 * @title This contract allows you to manage configuration settings of all crosschain providers supported by the platform.
 */
contract CrosschainProviderConfigManager is Controllable {
    // Defines the settings of each route
    struct ConfigSetting {
        address routerAddress;
        bytes routingInfo;
    }

    // The settings of each crosschain, cross-provider route
    mapping (bytes32 => ConfigSetting) private _routingData;

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     */
    constructor (address ownerAddr, address controllerAddr) Controllable (ownerAddr, controllerAddr) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Sets the configuration of the provider specified.
     * @dev This function can be called by the contract owner only.
     * @param key The routing key
     * @param routerAddress The router address for the source token specified.
     * @param routingInfo The provider configuration
     */
    function setRoute (bytes32 key, address routerAddress, bytes memory routingInfo) public onlyOwnerOrController {
        require(key != bytes32(0), "Key required");
        require(routerAddress != address(0), "Router address required");
        require(routingInfo.length > 0, "Routing info required");

        _routingData[key] = ConfigSetting(routerAddress, routingInfo);
    }

    /**
     * @notice Builds the routing key based on the parameters specified.
     * @param tokenAddr The hash of the token address
     * @param provider The hash of the crosschain provider. It could be Anyswap, LayerZero, etc.
     * @param foreignNetwork The hash of the foreign network or chain. It could be Avalanche, Fantom, etc.
     * @return Returns a key
     */
    function buildKey (address tokenAddr, bytes32 provider, bytes32 foreignNetwork) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, foreignNetwork, tokenAddr));
    }

    /**
     * @notice Gets the routing configuration of the provider specified.
     * @param key The routing key of the provider
     * @return routerAddress The router address for the key specified
     * @return routingInfo The routing settings for the key specified
     */
    function getRoute (bytes32 key) public view returns (address routerAddress, bytes memory routingInfo) {
        routerAddress = _routingData[key].routerAddress;
        routingInfo = _routingData[key].routingInfo;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

////import "./IAddressWhitelist.sol";

// The contract for ownership
////import "./../access/Ownable.sol";

/**
 * @title Contract for whitelisting addresses
 */
contract AddressWhitelist is IAddressWhitelist, Ownable {
    mapping (address => bool) internal whitelistedAddresses;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) Ownable (ownerAddr) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice This modifier throws if the sender is not whitelisted
     */
    modifier onlyIfWhitelisted() {
        require(whitelistedAddresses[msg.sender], "Sender not whitelisted");
        _;
    }

    /**
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) public override onlyOwner {
        require(!whitelistedAddresses[addr], "Already enabled");
        whitelistedAddresses[addr] = true;
    }

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) public override onlyOwner {
        require(whitelistedAddresses[addr], "Already disabled");
        whitelistedAddresses[addr] = false;
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns true if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) public view override returns (bool) {
        return whitelistedAddresses[addr];
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPLv3
pragma solidity 0.8.3;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    /**
    * Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering.
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * This event is triggered when a given amount of tokens is sent to an address.
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param value The amount transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * This event is triggered when a given address is approved to spend a specific amount of tokens
     * on behalf of the sender.
     * @param owner The owner of the token
     * @param spender The spender
     * @param value The amount to transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPLv3
pragma solidity 0.8.3;

/**
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The number of seconds in a day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the number of days elapsed between the two timestamps specified.
     * @param fromTimestamp The source date
     * @param toTimestamp The target date
     * @return Returns the difference, in days
     */
    function diffDays (uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256) {
        require(fromTimestamp <= toTimestamp, "Invalid order for timestamps");
        return (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The standard interface of an ERC20
////import "./../standards/IERC20.sol";

////import "./../access/Controllable.sol";

////import "./../whitelists/AddressWhitelist.sol";

// The crosschain configuration manager
////import "./CrosschainProviderConfigManager.sol";

/**
 * @title Represents a crosschain provider.
 */
abstract contract BaseProvider is Controllable {
    CrosschainProviderConfigManager public configManager;
    AddressWhitelist internal _whitelist;
    
    event OnCrosschainTransfer (address routerAddress, uint256 destinationChainId, address fromAddress, address toAddress, uint256 amount);

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     * @param newConfigManager The config manager
     * @param newWhitelist The whitelist
     */
    constructor (address ownerAddr, address controllerAddr, CrosschainProviderConfigManager newConfigManager, AddressWhitelist newWhitelist) Controllable (ownerAddr, controllerAddr) {
        configManager = newConfigManager;
        _whitelist = newWhitelist;
    }

    /**
     * @notice This modifier throws if the sender is not whitelisted, or if the whitelist is not set.
     */
    modifier onlyIfWhitelistedSender () {
        require(address(_whitelist) != address(0), "Whitelist not set");
        require(_whitelist.isWhitelistedAddress(msg.sender), "Sender not whitelisted");
        _;
    }

    /**
     * @notice Approves the router to spend the amount of tokens specified
     * @param tokenInterface The interface of the ERC20
     * @param routerAddr The address of the router
     * @param spenderAmount The spender amount granted to the router
     */
    function approveRouter (IERC20 tokenInterface, address routerAddr, uint256 spenderAmount) public onlyController {
        require(tokenInterface.approve(routerAddr, spenderAmount), "Approval failed");
    }

    /**
     * @notice Revokes allowance on the router address specified specified
     * @param tokenInterface The interface of the ERC20
     * @param routerAddr The address of the router
     */
    function revokeRouter (IERC20 tokenInterface, address routerAddr) public onlyController {
        require(tokenInterface.approve(routerAddr, 0), "Revoke failed");
    }

    /**
     * @notice Executes a crosschain transfer.
     * @param underlyingTokenInterface The interface of the ERC20
     * @param destinationAddr The destination address
     * @param transferAmount The transfer amount
     * @param foreignNetwork The hash of the remote network/chain
     */
    function executeTransfer (IERC20 underlyingTokenInterface, address destinationAddr, uint256 transferAmount, bytes32 foreignNetwork) public virtual;

    /**
     * @notice Gets the hash of the provider
     * @return The hash of the provider
     */
    function getProviderHash() public pure virtual returns (bytes32);
}



/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

/**
 * @title Defines the interface of the Oracle.
 */
interface IOracle {
    /**
     * @notice Sets the address authorized to update the token price.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setTokenPriceAuthority (address newAddr) external;

    /**
     * @notice Sets the address authorized to update the APR.
     * @dev This function can be called by the contract owner only.
     * @param newAddr The address of the authoritative party
     */
    function setAprAuthority (address newAddr) external;

    /**
     * @notice Updates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital that was deployed
     * @param amountReceived The amount of capital received, or the current balance
     * @param decimalsMultiplier The decimal positions of the underlying token
     */
    function updateTokenPrice (uint256 amountDeployed, uint256 amountReceived, uint256 decimalsMultiplier) external;

    /**
     * @notice Updates the APR
     * @param newApr The new APR
     */
    function changeApr (uint256 newApr) external;

    /**
     * @notice Calculates the token price based on the parameters specified.
     * @param amountDeployed The amount of capital deployed
     * @param currentBalance The current balance of the contract
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the token price
     */
    function calculateTokenPrice (uint256 amountDeployed, uint256 currentBalance, uint256 decimalsMultiplier) external pure returns (uint256);

    /**
     * @notice Converts the amount of receipt tokens specified to the respective amount of the ERC-20 handled by this contract (eg: USDC)
     * @param receiptTokenAmount The number of USDF tokens to convert
     * @param atPrice The token price
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the number of ERC-20 tokens that can be burnt
     */
    function toErc20Amount (uint256 receiptTokenAmount, uint256 atPrice, uint256 decimalsMultiplier) external pure returns (uint256);

    /**
     * @notice Gets the number of tokens to mint based on the amount of USDC/ERC20 specified.
     * @param erc20Amount The amount of USDC/ERC20
     * @param atPrice The token price
     * @return Returns the number of tokens
     */
    function toNumberOfTokens (uint256 erc20Amount, uint256 atPrice) external pure returns (uint256);

    /**
     * @notice Gets the daily interest rate based on the current APR
     * @param decimalsMultiplier The decimal positions of the underlying token
     * @return Returns the daily interest rate
     */
    function getDailyInterestRate (uint256 decimalsMultiplier) external view returns (uint256);

    /**
     * @notice Gets the current price of the USDF token
     * @return Returns the token price
     */
    function getTokenPrice () external view returns (uint256);
}

/** 
 *  SourceUnit: d:\Projects\delos-cx\solidity-contracts\contracts\treasury\YieldReserveEth.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.3;

// The interface of the oracle
////import "./../oracles/IOracle.sol";

// The interface of the whitelist for withdrawals
////import "./../whitelists/IAddressWhitelist.sol";

////import "./../crosschain/BaseProvider.sol";

////import "./../access/Controllable.sol";

// Stateless utilities library
////import "./../libraries/Utils.sol";

/**
 * @title Represents a Yield Reserve.
 */
contract YieldReserveEth is Controllable {
    // ---------------------------------------
    // Tightly packed declarations
    // ---------------------------------------
    // The decimals multiplier of the underlying ERC20
    uint256 immutable private _decimalsMultiplier;

    /**
     * The current period
     */
    uint256 public currentPeriod;

    /**
     * The amount of capital deployed in the current period
     */
    uint256 public totalCapitalDeployed;

    /**
     * The last time this contract reported a gain or a loss
     */
    uint256 public feedbackReceivedOn;

    /**
     * The date/time when capital was deployed
     */
    uint256 public capitalDeployedOn;

    /**
     * The minimum date/time for receiving feedback
     */
    uint256 public minFeedbackDate;

    // The reentrancy guard for capital deployments
    uint8 private _reentrancyGuardForCapital;

    // The reentrancy guard for sending the daily yield
    uint8 private _reentrancyGuardForYield;

    // The reentrancy guard for transfers
    uint8 private _reentrancyGuardForTransfers;

    // This is the security buffer for withdrawals, no matter what the ERC20 is. It ranges from 0%..100%
    uint8 public securityBuffer;

    /**
     * The address of the vault
     */
    address public vaultAddress;

    /**
     * The contract address that receives the deployments of capital
     */
    address public foreignAddress;

    /**
     * @notice The interface of the underlying ERC20 (for example: USDC, USDT, etc)
     */
    IERC20 public immutable underlyingTokenInterface;

    // The interface of the oracle
    IOracle private immutable _oracle;

    /**
     * The whitelist used for validating withdrawals
     */
    IAddressWhitelist public immutable whitelist;


    // ---------------------------------------
    // Mappings
    // ---------------------------------------
    // The amount of capital deployed at each period
    mapping (uint256 => uint256) private _capitalDeployedAtPeriod;

    // The balance at each period
    mapping (uint256 => uint256) private _capitalAtPeriod;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    /**
     * @notice This event is fired when capital gets deployed
     * @param fromAddress Specifies the address of the yield reserve
     * @param toAddress Specifies the foreign address that receives funds in the remote network/chain
     * @param amount Specifies the transfer amount
     */
    event OnCapitalDeployed (address fromAddress, address toAddress, uint256 amount);

    /**
     * @notice This event is fired when the contract sends funds back to the vault
     * @param amount The amount sent to the vault
     * @param vaultAddr The address of the vault
     */
    event OnDailyYieldSent (uint256 amount, address vaultAddr);

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param controllerAddr The controller
     * @param tokenInterface The interface of the underlying token
     * @param newSecurityBuffer The initial security buffer
     * @param oracleInterface The oracle
     * @param whitelistInterface The whitelist
     */
    constructor (address ownerAddr, address controllerAddr, IERC20 tokenInterface, uint8 newSecurityBuffer, IOracle oracleInterface, IAddressWhitelist whitelistInterface) Controllable(ownerAddr, controllerAddr) {
        require(newSecurityBuffer > 0 && newSecurityBuffer < 100, "Invalid security buffer");
        require(address(tokenInterface) != address(0), "Invalid address for ERC20");
        require(address(oracleInterface) != address(0), "Invalid address for oracle");
        require(address(whitelistInterface) != address(0), "Invalid address for whitelist");

        _oracle = oracleInterface;
        whitelist = whitelistInterface;
        securityBuffer = newSecurityBuffer;
        underlyingTokenInterface = tokenInterface;
        _decimalsMultiplier = uint256(10) ** uint256(tokenInterface.decimals());
    }

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    /**
     * @notice Throws if there is a deployment of capital in progress
     */
    modifier ifNotDeployingCapital() {
        require(_reentrancyGuardForCapital == 0, "Capital deployment in progress");
        _;
    }

    /**
     * @notice Throws if there is a transfer in progress
     */
    modifier ifNotSendingDailyYield() {
        require(_reentrancyGuardForYield == 0, "Daily yield transfer in progress");
        _;
    }

    /**
     * @notice Throws if there is a token transfer in progress
     */
    modifier ifNotTransferringFunds() {
        require(_reentrancyGuardForTransfers == 0, "Transfer in progress");
        _;
    }

    /**
     * @notice Throws if the address of the vault was not set
     */
    modifier ifVaultAddressSet() {
        require(vaultAddress != address(0), "Vault address not set");
        _;
    }

    /**
     * @notice Throws if the sender is not whitelisted
     */
    modifier onlyIfWhitelisted() {
        require(whitelist.isWhitelistedAddress(msg.sender), "Sender not whitelisted");
        _;
    }

    // ---------------------------------------
    // Functions
    // ---------------------------------------
    /**
     * @notice Updates the security buffer for withdrawals.
     * @dev This function can be called by the owner or the controller.
     * @param newSecurityBuffer The new security buffer for withdrawals
     */
    function changeSecurityBuffer (uint8 newSecurityBuffer) public onlyOwnerOrController {
        require(newSecurityBuffer > 0 && newSecurityBuffer < 100, "Invalid security buffer");
        securityBuffer = newSecurityBuffer;
    }

    /**
     * @notice Sets the address of the vault.
     * @dev This function can be called by the owner or the controller. It throws if called during a token transfer.
     * @param addr Specifies the address of the vault
     */
    function setVaultAddress (address addr) public onlyOwnerOrController ifNotSendingDailyYield {
        // Make sure the address specified is a smart contract
        require(Utils.isContract(addr), "Address must be a smart contract");
        require(addr != address(vaultAddress), "Address already set");
        require(addr != foreignAddress && addr != address(this), "Invalid address");

        // State changes
        vaultAddress = addr;
    }

    /**
     * @notice Sets the contract address that receives deployments of capital.
     * @dev This function can be called by the owner or the controller. It throws if called during a deployment of capital.
     * @param addr Specifies the foreign address
     */
    function setForeignAddress (address addr) public onlyOwnerOrController ifNotDeployingCapital {
        // Make sure the address specified is a smart contract
        require(Utils.isContract(addr), "Address must be a smart contract");
        require(addr != address(foreignAddress), "Address already set");
        require(addr != vaultAddress && addr != address(this), "Invalid address");

        // State changes
        foreignAddress = addr;
    }

    /**
     * @notice Deploys capital to a remote network/chain
     * @dev This function can be called by the controller only.
     * @param xChainProvider Specifies the crosschain provider to use
     * @param foreignNetwork The hash of the foreign network/chain
     */
    function deployCapital (BaseProvider xChainProvider, bytes32 foreignNetwork) public onlyController ifNotDeployingCapital {
        // Checks
        require(foreignNetwork != bytes32(0), "Invalid network ID");

        // Wake up the reentrancy guard
        _reentrancyGuardForCapital = 1;

        require(foreignAddress != address(0), "Destination address not set");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance > 0, "The yield reserve is empty");

        // Make sure this function cannot be called until we receive feedback from the investments
        if (currentPeriod > 0) require(_capitalAtPeriod[currentPeriod] > 0, "Cannot deploy. Feedback required");

        // Get amount of capital that can be deployed
        uint256 deploymentAmount = currentBalance;

        // Initiate a new period
        currentPeriod++;
        _capitalDeployedAtPeriod[currentPeriod] = deploymentAmount;
        totalCapitalDeployed = deploymentAmount;
        capitalDeployedOn = block.timestamp; // solhint-disable-line not-rely-on-time
        minFeedbackDate = block.timestamp + 24 hours; // solhint-disable-line not-rely-on-time

        // Transfer the respective amount of funds to the crosschain provider
        require(underlyingTokenInterface.transfer(address(xChainProvider), deploymentAmount), "Provider transfer failed");

        // Check the post-transfer balance
        uint256 newBalance = underlyingTokenInterface.balanceOf(address(this));
        require(newBalance == currentBalance - deploymentAmount, "Balance mismatch after transfer");

        // Run the crosschain transfer through the provider specified
        xChainProvider.executeTransfer(underlyingTokenInterface, foreignAddress, deploymentAmount, foreignNetwork);

        // Emit the event
        emit OnCapitalDeployed(address(this), foreignAddress, deploymentAmount);

        // Reset the reentrancy guard
        _reentrancyGuardForCapital = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Deploys capital to a smart contract located at L1.
     * @dev This function can be called by the controller only.
     */
    function deployCapitalToL1 () public onlyController ifNotDeployingCapital {
        // Wake up the reentrancy guard
        _reentrancyGuardForCapital = 1;

        require(foreignAddress != address(0), "Destination address not set");

        uint256 deploymentAmount = underlyingTokenInterface.balanceOf(address(this));
        require(deploymentAmount > 0, "The yield reserve is empty");

        // Make sure this function cannot be called until we receive feedback from the investments
        if (currentPeriod > 0) require(_capitalAtPeriod[currentPeriod] > 0, "Cannot deploy. Feedback required");

        // Initiate a new period
        currentPeriod++;
        _capitalDeployedAtPeriod[currentPeriod] = deploymentAmount;
        totalCapitalDeployed = deploymentAmount;
        capitalDeployedOn = block.timestamp; // solhint-disable-line not-rely-on-time
        minFeedbackDate = block.timestamp + 24 hours; // solhint-disable-line not-rely-on-time

        // Run the transfer at L1
        require(underlyingTokenInterface.transfer(foreignAddress, deploymentAmount), "L1 Provider transfer failed");

        // Emit the event
        emit OnCapitalDeployed(address(this), foreignAddress, deploymentAmount);

        // Reset the reentrancy guard
        _reentrancyGuardForCapital = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Reports a gain.
     * @dev This function can be called by the controller only. Throws if the vault is not set.
     * @param harvestedAmount The amount haversted in the remote network/chain
     */
    function reportGain (uint256 harvestedAmount) public onlyController ifVaultAddressSet ifNotSendingDailyYield {
        require(harvestedAmount > 0, "Invalid amount");

        // Wake up the reentrancy guard
        _reentrancyGuardForYield = 1;

        // This is the amount of capital deployed in the current period. You did this by calling the 'deployCapital()' function
        uint256 amountDeployed = _capitalDeployedAtPeriod[currentPeriod];
        require(amountDeployed > 0, "Capital deployment required");

        // Make sure there is a verifiable delay between the deployment of capital and feedback received from L2
        require(block.timestamp > minFeedbackDate, "Cannot receive feedback so soon"); // solhint-disable-line not-rely-on-time

        // Determine how many days elapsed since the last pull
        // solhint-disable-next-line not-rely-on-time
        uint256 numberOfDaysElapsed = (feedbackReceivedOn > 0) ? Utils.diffDays(feedbackReceivedOn, block.timestamp) : 1;

        // Make sure this function is called every 24 hours, at least.
        require(numberOfDaysElapsed >= 1, "Timelocked feedback in place");

        // Compute the amount we need to transfer (daily yield for X number of days)
        uint256 dailyYieldAmount = getDailyYieldFor(numberOfDaysElapsed);
        require(dailyYieldAmount > 0, "The daily yield cannot be zero");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance >= harvestedAmount, "Harvested amount mismatch");

        uint256 deploymentAmount = _capitalDeployedAtPeriod[currentPeriod];        
        if (_capitalAtPeriod[currentPeriod] == 0) {
            _capitalAtPeriod[currentPeriod] = deploymentAmount + harvestedAmount;
        } else {
            _capitalAtPeriod[currentPeriod] += harvestedAmount;
        }

        // Update the timestamp
        feedbackReceivedOn = block.timestamp; // solhint-disable-line not-rely-on-time

        // Update the price of the token
        _updateTokenPrice();

        // Send the daily yield to the vault
        require(currentBalance >= dailyYieldAmount, "Insufficient balance for yield");
        require(underlyingTokenInterface.transfer(vaultAddress, dailyYieldAmount), "Daily Yield Transfer failed");

        // Report that the daily yield was sent back to the vault
        emit OnDailyYieldSent(dailyYieldAmount, vaultAddress);

        // Reset the reentrancy guard
        _reentrancyGuardForYield = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Reports a loss.
     * @dev This function can be called by the controller only. Throws if the vault is not set.
     * @param lossAmount The loss to report
     */
    function reportLoss (uint256 lossAmount) public onlyController ifVaultAddressSet ifNotSendingDailyYield {
        require(lossAmount > 0, "Invalid amount");

        // Wake up the reentrancy guard
        _reentrancyGuardForYield = 1;

        // This is the amount of capital deployed in the current period. You did this by calling the 'deployCapital()' function
        uint256 amountDeployed = _capitalDeployedAtPeriod[currentPeriod];
        require(amountDeployed > 0, "Capital deployment required");

        // Make sure there is a verifiable delay between the deployment of capital and feedback received from L2
        require(block.timestamp > minFeedbackDate, "Cannot receive feedback so soon"); // solhint-disable-line not-rely-on-time

        // Determine how many days elapsed since the last pull
        uint256 numberOfDaysElapsed = (feedbackReceivedOn > 0) ? Utils.diffDays(feedbackReceivedOn, block.timestamp) : 1; // solhint-disable-line not-rely-on-time

        // Make sure this function is called every 24 hours, at least.
        require(numberOfDaysElapsed >= 1, "Timelocked feedback in place");

        uint256 deploymentAmount = _capitalDeployedAtPeriod[currentPeriod];
        require(deploymentAmount >= lossAmount, "Invalid amount for loss");

        if (_capitalAtPeriod[currentPeriod] == 0) {
            _capitalAtPeriod[currentPeriod] = deploymentAmount - lossAmount;
        } else {
            require(lossAmount <= _capitalAtPeriod[currentPeriod], "Invalid cumulative loss");
            _capitalAtPeriod[currentPeriod] -= lossAmount;
        }

        // Update the timestamp
        feedbackReceivedOn = block.timestamp; // solhint-disable-line not-rely-on-time

        // Update the price of the token
        _updateTokenPrice();

        // Reset the reentrancy guard
        _reentrancyGuardForYield = 0;
    }

    /**
     * @notice Transfers a specific amount of tokens to the destination address specified.
     * @dev Throws if the destination address is not whitelisted. This function can be called by the owner or controller only.
     * @param destinationAddr The destination address
     * @param amount  The amount
     */
    function transfer (address destinationAddr, uint256 amount) public onlyOwnerOrController ifNotTransferringFunds {
        // Basic parameter checks
        require(destinationAddr != address(0) && destinationAddr != address(this), "Invalid destination address");
        require(amount > 0, "Transfer amount required");

        // Wake up the reentrancy guard
        _reentrancyGuardForTransfers = 1;

        // Make sure the destination address is whitelisted
        require(whitelist.isWhitelistedAddress(destinationAddr), "Address not whitelisted");

        // The maximum amount of ERC20 tokens that can be withdrawn from this contract
        uint256 maxTransferAmount = getMaxWithdrawalAmount();
        require(maxTransferAmount > 0, "Insufficient balance");

        // Validate the transfer amount
        require(maxTransferAmount >= amount, "Transfer amount too high");

        // Run the token transfer
        require(underlyingTokenInterface.transfer(destinationAddr, amount), "Transfer failed");

        // Reset the reentrancy guard
        _reentrancyGuardForTransfers = 0;  // solhint-disable-line reentrancy
    }

    /**
     * @notice Transfers funds to the list of addresses specified.
     * @dev Throws if the destination address is not whitelisted. This function can be called by the owner or controller only.
     * @param addresses The list of addresses
     * @param amounts The corresponding amount of each address
     */
    function transferToMultipleAddresses (address[] memory addresses, uint256[] memory amounts) public onlyOwnerOrController ifNotTransferringFunds {
        // Checks
        require(addresses.length > 0, "Addresses list required");
        require(amounts.length > 0, "Amounts required");
        require(addresses.length == amounts.length, "Invalid length for pairs");
        require(addresses.length < 11, "Max addresses limit reached");

        // Wake up the reentrancy guard
        _reentrancyGuardForTransfers = 1;

        // The maximum amount of ERC20 tokens that can be withdrawn from this contract
        uint256 maxTransferAmount = getMaxWithdrawalAmount();
        require(maxTransferAmount > 0, "Insufficient balance");

        uint256 total = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && addresses[i] != address(this), "Invalid address for transfer");
            require(amounts[i] > 0 && amounts[i] <= maxTransferAmount, "Invalid transfer amount");
            require(whitelist.isWhitelistedAddress(addresses[i]), "Address not whitelisted");
            total += amounts[i];
        }

        require(total <= maxTransferAmount, "Maximum transfer amount exceeded");

        // State changes
        for (uint256 i = 0; i < addresses.length; i++) {
            require(underlyingTokenInterface.transfer(addresses[i], amounts[i]), "Transfer failed");
        }

        // Reset the reentrancy guard
        _reentrancyGuardForTransfers = 0; // solhint-disable-line reentrancy
    }

    /**
     * @notice Updates the price of the USDF token
     */
    function _updateTokenPrice () private {
        // This is the amount of capital deployed in the current period
        uint256 amountDeployed = _capitalDeployedAtPeriod[currentPeriod];

        // This is the amount of capital we received from other networks/chains
        uint256 amountReceived = _capitalAtPeriod[currentPeriod];

        // Update the token price
        _oracle.updateTokenPrice(amountDeployed, amountReceived, _decimalsMultiplier);
    }

    // ---------------------------------------
    // Views
    // ---------------------------------------
    /**
     * @notice Gets the current balance of the contract in USDC/ERC20
     * @return Returns the balance
     */
    function getCurrentBalance () public view returns (uint256) {
        return underlyingTokenInterface.balanceOf(address(this));
    }

    /**
     * @notice Gets the amount of ERC20 tokens that can be withdrawn from this contract, per security buffer.
     * @return Returns the maximum amount of tokens that can be withdrawn
     */
    function getMaxWithdrawalAmount () public view returns (uint256) {
        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        return (currentBalance < 1) ? 0 : currentBalance - (securityBuffer * currentBalance / uint256(100));
    }

    /**
     * @notice Gets the number of days that elapsed since the last transfer to the vault.
     * @return Returns the number of days
     */
    function getDaysElapsedSinceLastPull () public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return (feedbackReceivedOn > 0) ? Utils.diffDays(feedbackReceivedOn, block.timestamp) : 0;
    }

    /**
     * @notice Gets the amount that needs to be sent to the vault based on the number of days specified.
     * @param numberOfDaysElapsed The number of days elapsed since the last transfer to the vault
     * @return Returns the amount to send to the vault
     */
    function getDailyYieldFor (uint256 numberOfDaysElapsed) public view returns (uint256) {
        uint256 daysMultiplier = (feedbackReceivedOn == 0 || numberOfDaysElapsed < 1) ? uint256(1) : numberOfDaysElapsed;
        return (totalCapitalDeployed * _oracle.getDailyInterestRate(_decimalsMultiplier) * daysMultiplier) / _decimalsMultiplier / uint256(100) / uint256(100);
    }
    
    /**
     * @notice Gets the daily yield amount that needs to be sent to the vault.
     * @dev The amount varies depending on the timestamp of the last transfer
     * @return Returns the amount to send to the vault
     */
    function getDailyYield () public view returns (uint256) {
        // Get the number of days that elapsed since the last transfer, per block timestamp
        uint256 numberOfDaysElapsed = getDaysElapsedSinceLastPull();

        // Return the respective amount based on the number of days elapsed
        return getDailyYieldFor(numberOfDaysElapsed);
    }
}