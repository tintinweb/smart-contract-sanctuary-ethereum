/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(owner, addr);
        owner = addr;
    }
}

/**
 * @title Represents a controllable resource.
 */
contract Controllable is Ownable {
    address public controllerAddress;

    event OnControllerChanged (address prevAddress, address newAddress);

    /**
     * @notice Constructor
     * @param ownerAddr The owner of the smart contract
     * @param controllerAddr The address of the controller
     */
    constructor (address ownerAddr, address controllerAddr) Ownable (ownerAddr) {
        require(controllerAddr != address(0), "Controller address required");
        require(controllerAddr != ownerAddr, "Owner cannot be the Controller");
        controllerAddress = controllerAddr;
    }

    /**
     * @notice Throws if the sender is not the controller
     */
    modifier onlyController() {
        require(msg.sender == controllerAddress, "Unauthorized controller");
        _;
    }

    /**
     * @notice Makes sure the sender is either the owner of the contract or the controller
     */
    modifier onlyOwnerOrController() {
        require(msg.sender == controllerAddress || msg.sender == owner, "Only owner or controller");
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
        require(controllerAddr != owner, "Owner cannot be the Controller");
        require(controllerAddr != controllerAddress, "Controller already set");

        emit OnControllerChanged(controllerAddress, controllerAddr);

        // State changes
        controllerAddress = controllerAddr;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public override onlyOwner {
        require(addr != controllerAddress, "Cannot transfer to controller");
        super.transferOwnership(addr);
    }
}

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

    /**
     * This event is triggered when a new address is whitelisted.
     * @param addr The address that was whitelisted
     */
    event OnAddressEnabled(address addr);

    /**
     * This event is triggered when an address is disabled.
     * @param addr The address that was disabled
     */
    event OnAddressDisabled(address addr);
}

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
     * @notice Whitelists the address specified.
     * @param addr The address to enable
     */
    function enableAddress (address addr) external override onlyOwner {
        require(!whitelistedAddresses[addr], "Already enabled");
        whitelistedAddresses[addr] = true;
        emit OnAddressEnabled(addr);
    }

    /**
     * @notice Disables the address specified.
     * @param addr The address to disable
     */
    function disableAddress (address addr) external override onlyOwner {
        require(whitelistedAddresses[addr], "Already disabled");
        whitelistedAddresses[addr] = false;
        emit OnAddressDisabled(addr);
    }

    /**
     * @notice Indicates if the address is whitelisted or not.
     * @param addr The address to disable
     * @return Returns true if the address is whitelisted
     */
    function isWhitelistedAddress (address addr) external view override returns (bool) {
        return whitelistedAddresses[addr];
    }
}

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

interface IAnyswapV5Router {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

/**
 * @title Crosschain provider for Anyswap/Multichain
 */
contract MultichainProvider is BaseProvider {
    /**
     * @notice Constructor
     * @param ownerAddr The owner of the vault
     * @param controllerAddr The controller of the vault
     * @param newConfigManager The config manager
     * @param newWhitelist The whitelist
     */
    constructor (address ownerAddr, address controllerAddr, CrosschainProviderConfigManager newConfigManager, AddressWhitelist newWhitelist)
    BaseProvider (ownerAddr, controllerAddr, newConfigManager, newWhitelist) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Executes a crosschain transfer.
     * @param underlyingTokenInterface The interface of the ERC20
     * @param destinationAddr The destination address
     * @param transferAmount The transfer amount
     * @param foreignNetwork The hash of the remote network/chain
     */
    function executeTransfer (IERC20 underlyingTokenInterface, address destinationAddr, uint256 transferAmount, bytes32 foreignNetwork)
    public override onlyIfWhitelistedSender {
        // Checks
        require(destinationAddr != address(0), "Destination address required");
        require(transferAmount > 0, "Amount must be greater than zero");
        require(foreignNetwork != bytes32(0), "Foreign network required");

        bytes32 key = configManager.buildKey(address(underlyingTokenInterface), getProviderHash(), foreignNetwork);

        // Get the parameters/config for the routing key specified
        (address routerAddress, bytes memory routingInfo) = configManager.getRoute(key);

        // Parameters may vary depending on the provider as well as on the platform and/or token to transfer.
        // Thus the only way to grab the parameters is by reading bytes in the format expected by this provider.
        uint256 destinationChainId;
        address anyTokenAddress;

        // Read the provider-specific payload. These are the parameters we need for Anyswap.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            destinationChainId := mload(add(routingInfo, 0x20))
            anyTokenAddress := mload(add(routingInfo, 0x40))
        }

        // Validate the payload
        require(anyTokenAddress != address(0), "Invalid AnyToken address");
        require(destinationChainId > 0, "Invalid destination chain");

        // Check the balance
        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(currentBalance >= transferAmount, "Insufficient balance");

        // Run the crosschain transfer
        IAnyswapV5Router(routerAddress).anySwapOutUnderlying(anyTokenAddress, destinationAddr, transferAmount, destinationChainId);

        // Check the balance
        uint256 newBalance = underlyingTokenInterface.balanceOf(address(this));
        require(newBalance == currentBalance - transferAmount, "Balance mismatch after transfer");

        // Emit the crosschain transfer event
        emit OnCrosschainTransfer(routerAddress, destinationChainId, address(this), destinationAddr, transferAmount);
    }

    /**
     * @notice Gets the hash of the provider
     * @return The hash of the provider
     */
    function getProviderHash() public pure override returns (bytes32) {
        return keccak256(abi.encodePacked("Anyswap/Multichain"));
    }
}