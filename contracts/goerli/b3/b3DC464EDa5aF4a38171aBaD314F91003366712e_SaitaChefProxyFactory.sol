// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SaitaChefProxy.sol";
import "./interfaces/ISaitaChef.sol";
import "./interfaces/IToken.sol";


contract SaitaChefProxyFactory is OwnableUpgradeable{

    address internal imp;
    address[] public totalChefInstances;

    mapping(address => address) public tokenAddrToChefAddr;

    event Deposit(address indexed chefProxy, uint256 amount, uint256 pid, address indexed user);
    event Withdraw(address indexed chefProxy, uint256 amount, uint256 pid, address indexed user);
    event Harvest(address indexed chefProxy,  uint256 rewardAmount, uint256 pid, address indexed user);

    event Add(address indexed chefProxy, address indexed _lpToken, uint256 pid, uint256 depositFees, uint256 withdrawalFees, address indexed token, address  pairToken);
    event Set(address indexed chefProxy, uint256 pid, uint256 depositFees, uint256 withdrawalFees);

    event EmergencyWithdrawn(address indexed chefProxy,  uint256 amount, uint256 pid, address indexed user);
    event UpdateEmergencyFees(address indexed chefProxy, uint256 newFees);
    event UpdatePlatformFee(address indexed chefProxy, uint256 newFees);
    event UpdateOwnerWallet(address indexed chefProxy, address indexed newOwnerWallet);
    event UpdateTreasuryWallet(address indexed chefProxy, address indexed newTreasuryWallet);
    event UpdateRewardWallet(address indexed chefProxy, address indexed newRewardWallet);
    event UpdateRewardPerBlock(address indexed chefProxy, uint256 newRate);
    event UpdateMultiplier(address indexed chefProxy, uint256 newMultiplier);


    event Deployed(address indexed instance);
    event StakingInitialized(address indexed _proxyInstance, address indexed _saita, uint256 _saitaPerBlock, uint256 _startBlock );

    function initialize(address _imp) external initializer {
        __Ownable_init();
        imp = _imp;
    }

    function deposit(address token, uint256 _pid, uint256 _amount) external payable {
        // IERC20(_lpToken).approve(tokenAddrToChefAddr[_lpToken], _amount);
        uint256 amount = ISaitaChef(tokenAddrToChefAddr[token]).deposit{value:msg.value}(msg.sender, _pid, _amount);
        emit Deposit(tokenAddrToChefAddr[token], amount, _pid, msg.sender);
    }
    

    function withdraw(address token, uint256 _pid, uint256 _amount) external payable {
        // IERC20(_lpToken).approve(tokenAddrToChefAddr[_lpToken], _amount);
        ISaitaChef(tokenAddrToChefAddr[token]).withdraw{value:msg.value}(msg.sender, _pid, _amount);
        emit Withdraw(tokenAddrToChefAddr[token], _amount, _pid, msg.sender);
    }

    function harvest(address token, uint256 _pid) external payable {
        uint256 rewardAmount = ISaitaChef(tokenAddrToChefAddr[token]).harvest{value:msg.value}(msg.sender, _pid);
        emit Harvest(tokenAddrToChefAddr[token], rewardAmount, _pid, msg.sender);
    }

    function emergencyWithdraw(address token, uint256 _pid) external payable {
        (uint256 amount) = ISaitaChef(tokenAddrToChefAddr[token]).emergencyWithdraw{value:msg.value}(msg.sender, _pid);
        emit EmergencyWithdrawn(tokenAddrToChefAddr[token], amount, _pid, msg.sender);
    }

    function add(address token, address _lpToken, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate, address pairToken) external onlyOwner{
        uint256 _pid = ISaitaChef(tokenAddrToChefAddr[token]).add(_allocPoint, _lpToken, _depositFees, _withdrawalFees, _withUpdate);
        emit Add(tokenAddrToChefAddr[token], _lpToken,  _pid, _depositFees, _withdrawalFees, token, pairToken);
    }

    function set(address token,uint256 _pid, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external onlyOwner{
        ISaitaChef(tokenAddrToChefAddr[token]).set(_pid, _allocPoint, _depositFees, _withdrawalFees, _withUpdate);
        emit Set(tokenAddrToChefAddr[token], _pid, _depositFees, _withdrawalFees);
    }


    function updateEmergencyFees(address token, uint256 newFees) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateEmergencyFees(newFees);
        emit UpdateEmergencyFees(tokenAddrToChefAddr[token], newFees);
    }

    function updatePlatformFee(address token, uint256 newFee) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updatePlatformFee(newFee);

        emit UpdatePlatformFee(tokenAddrToChefAddr[token], newFee);
    }

    function updateFeeCollector(address token, address newWallet) external onlyOwner {
       ISaitaChef(tokenAddrToChefAddr[token]).updateFeeCollector(newWallet);

        emit UpdateOwnerWallet(tokenAddrToChefAddr[token], newWallet);
    }

    function updateTreasuryWallet(address token, address newTreasuryWallet) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateTreasuryWallet(newTreasuryWallet);

        emit UpdateTreasuryWallet(tokenAddrToChefAddr[token], newTreasuryWallet);
    }

    function updateRewardWallet(address token, address newWallet) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateRewardWallet(newWallet);

        emit UpdateRewardWallet(tokenAddrToChefAddr[token], newWallet);
    }

    function updateRewardPerBlock(address token, uint256 newRate) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateRewardPerBlock(newRate);

        emit UpdateRewardPerBlock(tokenAddrToChefAddr[token], newRate);
    }

    function updateMultiplier(address token, uint256 newMultiplier) external onlyOwner {
        ISaitaChef(tokenAddrToChefAddr[token]).updateMultiplier(newMultiplier);

        emit UpdateMultiplier(tokenAddrToChefAddr[token], newMultiplier);
    }


    function getPoolLength(address token) external view returns(uint256) {
        return ISaitaChef(tokenAddrToChefAddr[token]).poolLength();
    }

    function deployInstance() external onlyOwner returns(address addr) {
        addr = address(new SaitaChefProxy(address(this)));
        require(addr!=address(0), "NULL_CONTRACT_ADDRESS_CREATED");
        totalChefInstances.push(addr);
        
        emit Deployed(addr);
        return addr;
    }

    function initializeProxyInstance(address _proxyInstance, uint256 _saitaPerBlock, uint256 _startBlock, address token, address _treasury, 
                                    address _feeCollector, uint256 _platformFees, uint256 _emergencyFees,
                                    address _rewardWallet) external onlyOwner {
        
            tokenAddrToChefAddr[token] = _proxyInstance;
            {
            // string memory _name = IToken(_lpToken).name();
            // string memory _symbol = IToken(_lpToken).symbol();

            // initialize pool
            SaitaChefProxy proxyInstance = SaitaChefProxy(payable(_proxyInstance));
            {
                bytes memory init = returnHash(_saitaPerBlock,_startBlock,token,_treasury, _feeCollector, _platformFees, _emergencyFees, _rewardWallet);
                if (init.length > 0)
                    
                    assembly 
                    {
                        if eq(call(gas(), proxyInstance, 0, add(init, 0x20), mload(init), 0, 0), 0) {
                            revert(0, 0)
                        }
                    }
            }
            emit StakingInitialized(_proxyInstance, token, _saitaPerBlock,_startBlock);
            }
        
    }

    function setFactoryProxyInstance(address _proxyInstance) external onlyOwner {
                // set factory in deployed proxy instance
                SaitaChefProxy proxyInstance = SaitaChefProxy(payable(_proxyInstance));
                proxyInstance.setFactory(address(this));
    }

    function returnHash(uint256 _saitaPerBlock, uint256 _startBlock, address _saita, address _treasury, 
                                    address _feeCollector, uint256 _platformFees, uint256 _emergencyFees,
                                    address _rewardWallet) internal pure returns(bytes memory data) {
        data = abi.encodeWithSignature("initialize(uint256,uint256,address,address,address,uint256,uint256,address)", 
                                        _saitaPerBlock,_startBlock,_saita,_treasury, _feeCollector, _platformFees, _emergencyFees, _rewardWallet);
    }

    function updateImp(address _newImp) external onlyOwner {
        imp = _newImp;
    }

    function impl() external view returns(address) {
        return imp;
    }

    function totalChefNo() external view returns(uint256) {
        return totalChefInstances.length;
    }

    function pendingSaita(address token, uint256 pid, address user) external view returns(uint256) {
    return ISaitaChef(tokenAddrToChefAddr[token]).pendingSaita(pid, user);
    }

    function userInfo(address token, uint256 pid, address user) external view returns(uint256) {
        (uint256 amount,) = ISaitaChef(tokenAddrToChefAddr[token]).userInfo(pid, user);
        return amount;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./interfaces/ISaitaFactory.sol";

contract SaitaChefProxy {
    
        bytes32 private constant proxyOwnerPosition = keccak256("com.saitama.chef.proxy.owner");
        bytes32 private constant factory = keccak256("com.saitama.chef.proxy.factory");

    constructor(address owner) {
        setProxyOwner(owner);

    }

    function setProxyOwner(address newProxyOwner) private  {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function setFactory(address _factory) public  {
        require(msg.sender == proxyOwner(), "ONLY_OWNER_CAN_CHANGE");
        bytes32 position = factory;
        assembly {
            sstore(position, _factory)
        }
    }

    function getFactory() public view returns (address _factory) {
        bytes32 position = factory;
        assembly {
            _factory := sload(position)
        }
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }


    function implementation() public view returns (address) {
        return ISaitaFactory(getFactory()).impl();
    }
    


    fallback() external payable {
        address _impl = implementation();

            assembly 
                {
                let ptr := mload(0x40)

                // (1) copy incoming call data
                calldatacopy(ptr, 0, calldatasize())

                // (2) forward call to logic contract
                let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
                let size := returndatasize()

                // (3) retrieve return data
                returndatacopy(ptr, 0, size)

                // (4) forward return data back to caller
                switch result
                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
                }
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISaitaChef {
    function add(uint256 _allocPoint, address _lpToken, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external returns(uint256);
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external;
    function deposit(address user, uint256 pid, uint256 amount) external payable returns(uint256);
    function withdraw(address user, uint256 pid, uint256 amount) external payable;
    function harvest(address user, uint256 pid) external payable returns(uint256);
    
    function pendingSaita(uint256 _pid, address _user) external view returns (uint256);
    function updateRewardPerBlock(uint256 _newRate) external;
    
    function emergencyWithdraw(address user, uint256 pid) external payable returns(uint256);
    function updateEmergencyFees(uint256 newFee) external ;
    function updatePlatformFee(uint256 newFee) external;
    function updateFeeCollector(address newWallet) external;
    function updateTreasuryWallet(address newTreasurywallet) external;
    function updateRewardWallet(address newWallet) external;

    function updateMultiplier(uint256 _multiplier) external;
    function poolLength() external view returns(uint256);
    function userInfo(uint256 pid, address user) external view returns(uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IToken {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISaitaFactory {
    function impl() external view returns(address);
}