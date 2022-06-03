/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// File contracts/utils/IOtoCoMaster.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOtoCoMaster {

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev See {OtoCoMaster-baseFee}.
     */
    function baseFee() external view returns (uint256 fee);

    receive() external payable;
}


// File contracts/utils/IOtoCoPlugin.sol

pragma solidity ^0.8.0;

interface IOtoCoPlugin {

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to create a new instance of plugin.
     */
    function addPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Allow attach a previously deployed plugin if possible
     * @dev This function should run enumerous amounts of verifications before allow the attachment.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function removePlugin(uint256 seriesId, bytes calldata pluginData) external payable;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/OtoCoPlugin.sol

pragma solidity ^0.8.0;



abstract contract OtoCoPlugin is IOtoCoPlugin, Ownable {

    // Reference to the OtoCo Master to transfer plugin cost
    IOtoCoMaster public otocoMaster;

    /**
     * Modifier to allow only series owners to change content.
     * @param tokenId The plugin index to update.
     */
    modifier onlySeriesOwner(uint256 tokenId) {
        require(otocoMaster.ownerOf(tokenId) == msg.sender, "OtoCoPlugin: Not the entity owner.");
        _;
    }

    /**
     * Modifier to check if the function set the correct amount of ETH value and transfer it to master.
     * If baseFee are 0 or sender is OtoCoMaster this step is jumped.
     * @dev in the future add/attact/remove could be called from OtoCo Master. In those cases no transfer should be called.
     */
    modifier transferFees() {
        if (otocoMaster.baseFee() > 0 && msg.sender != address(otocoMaster)) payable(otocoMaster).transfer(msg.value);
        _;
    }

    constructor(address payable _otocoMaster) Ownable() {
        otocoMaster = IOtoCoMaster(_otocoMaster);
    }

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to create a new instance of plugin.
     */
    function addPlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override;

    /**
     * Allow attach a previously deployed plugin if possible
     * @dev This function should run enumerous amounts of verifications before allow the attachment.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override {
        revert("OtoCoPlugin: Attach elements are not possible on this plugin.");
    }

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function removePlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override {
        revert("OtoCoPlugin: Remove elements are not possible on this plugin.");
    }
}


// File @openzeppelin/contracts/proxy/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File contracts/plugins/Launchpool.sol

pragma solidity ^0.8.0;


interface PoolInterface {
    function initialize(
        address[] memory allowedTokens,
        uint256[] memory uintArgs,
        string memory _metadata,
        address _sponsor,
        address _shares,
        address _curve
    ) external;

    function sponsor() external view returns(address);
    function metadata() external view returns(string memory);
}

/**
 * Launchpool Factory
 */
contract Launchpool is OtoCoPlugin {
    
    // Launchpool creation and removal events
    event LaunchpoolCreated(uint256 indexed seriesId, address sponsor, address pool, string metadata);
    event LaunchpoolRemoved(uint256 indexed seriesId, address pool);
    
    // The source of launchpool to be deployed
    address private _poolSource;
    // The curve sources that could be used on launchpool
    address[] private _curveSources;

    // The assignment of launchpools to entities
    mapping(uint256 => address) public launchpoolDeployed;

    constructor(
        address payable otocoMaster,
        address poolSource,
        address curveSource,
        uint256[] memory prevIds,
        address[] memory prevLaunchpools
    ) OtoCoPlugin(otocoMaster) {
        _poolSource = poolSource;
        _curveSources.push(curveSource);
        for (uint i = 0; i < prevIds.length; i++ ) {
            launchpoolDeployed[prevIds[i]] = prevLaunchpools[i];
            PoolInterface pool = PoolInterface(launchpoolDeployed[prevIds[i]]);
            emit LaunchpoolCreated(prevIds[i], pool.sponsor(), prevLaunchpools[i], pool.metadata());
        }
    }

    /**
    * Update launchpool Source
    *
    * @param newAddress The new launchpool source to be used on clones
     */
    function updatePoolSource(address newAddress) public onlyOwner {
        _poolSource = newAddress;
    }

    /**
    * Add a new curve source to the curve options
    *
    * @param newAddress The new curve source to be added to curve options
     */
    function addCurveSource(address newAddress) public onlyOwner {
        _curveSources.push(newAddress);
    }

    function addPlugin(uint256 seriesId, bytes calldata pluginData) onlySeriesOwner(seriesId) transferFees() public payable override {
        (
            address[] memory _allowedTokens,
            uint256[] memory _uintArgs,
            string memory _metadata,
            address _shares,
            uint16 _curve,
            address sponsor
        ) = abi.decode(pluginData, (address[], uint256[], string, address, uint16, address));
        address pool = Clones.clone(_poolSource);
        PoolInterface(pool).initialize(_allowedTokens, _uintArgs, _metadata, sponsor, _shares, _curveSources[_curve]);
        launchpoolDeployed[seriesId] = pool;
        emit LaunchpoolCreated(seriesId, sponsor, pool, _metadata);
    }

    function removePlugin(uint256 seriesId, bytes calldata pluginData) onlySeriesOwner(seriesId) transferFees() public payable override {
        // Remove the last token from array
        address pool = launchpoolDeployed[seriesId];
        launchpoolDeployed[seriesId] = address(0);
        emit LaunchpoolRemoved(seriesId, pool);
    }
}