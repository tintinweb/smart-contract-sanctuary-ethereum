// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

import './interfaces/IWSCustomProxy.sol';
import './interfaces/IFarmingRewards.sol';
import './interfaces/IImplementationGetter.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWSERC20.sol';

import './Ownable.sol';
import './FarmingRewards.sol';
import './proxy/FarmingProxy.sol';

contract FarmingRewardsFactory is Ownable {

    address public implementationGetter;
    address public wsd;
    uint8 public feePercent;
    uint256 public lockAmount;
    uint256 public minEpochDuration = 1;
    uint256 public countFarmingPools;
    mapping(address => uint) public nonce;
    mapping(address => uint[]) public usersFarmingPool;
    mapping(uint => uint) public farmingPoolLocks;
    mapping(uint => FarmingPoolsInfo) public farmingInfo;

    //implementationGetter is interacting with FarmingRewards.sol
    constructor(
        address _implementationGetter,
        address _wsd,
        uint256 _lockAmount,
        uint8 _feePercent
    )  {
        implementationGetter = _implementationGetter;
        wsd = _wsd;
        lockAmount = _lockAmount;
        feePercent = _feePercent;
    }

    struct FarmingPoolsInfo {
        uint256 id;
        address stakingToken;
        address rewardToken;
        uint256 startDate;
        uint256 finishDate;
        uint256 rewardAmount;
        uint256 epochDuration;
        address farmingPool;
    }

    function deploy(
        address stakingToken,
        address rewardToken,
        uint256 startDate,
        uint256 epochDuration,
        uint256 rewardAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(rewardAmount > 0, 'Can not be zero');
        require(epochDuration >= minEpochDuration, 'Small epoch duration');
        uint finishDate = startDate + epochDuration;

//        bytes32 digest = keccak256(abi.encodePacked(
//           '\x19\x01',
//           keccak256(abi.encode(owner(), msg.sender, requester, id, nonce[msg.sender]))
//        ));
//
//        address recoveredAddress = ecrecover(digest, v, r, s);
//        require(recoveredAddress != address(0));
//        require(recoveredAddress == owner(), 'Not valid owner');


        address farmingProxy = address(new FarmingProxy());
        IWSCustomProxy(farmingProxy).upgradeStorageTo(address(implementationGetter));
        IFarmingRewards(farmingProxy).initialize(
            rewardToken,
            stakingToken,
            rewardAmount,
            startDate,
            finishDate,
            epochDuration
        );

        IERC20(rewardToken).transferFrom(msg.sender, address(farmingProxy), rewardAmount);

        FarmingPoolsInfo memory newRewardsInfo;

        newRewardsInfo.id = countFarmingPools;
        newRewardsInfo.stakingToken = stakingToken;
        newRewardsInfo.rewardToken = rewardToken;
        newRewardsInfo.startDate = startDate;
        newRewardsInfo.finishDate = finishDate;
        newRewardsInfo.rewardAmount = rewardAmount;
        newRewardsInfo.epochDuration = epochDuration;
        newRewardsInfo.farmingPool = farmingProxy;

        usersFarmingPool[msg.sender].push(countFarmingPools);
        farmingPoolLocks[countFarmingPools] = lockAmount;

        farmingInfo[countFarmingPools] = newRewardsInfo;
        countFarmingPools++;
    }

    function deployWithPermit(
        address stakingToken,
        address rewardToken,
        uint256 startDate,
        uint256 epochDuration,
        uint256 rewardAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        IWSERC20(wsd).permit(msg.sender, address(this), lockAmount, deadline, v, r, s);
        deploy(stakingToken,rewardToken,startDate,epochDuration,rewardAmount, deadline, v, r, s);
        deploy(stakingToken, rewardToken, startDate, epochDuration, rewardAmount, deadline, v, r, s);
    }

    function deployWithoutPermit(
        address stakingToken,
        address rewardToken,
        uint256 startDate,
        uint256 epochDuration,
        uint256 rewardAmount
    ) public {
        require(rewardAmount > 0, 'Can not be zero');
        require(epochDuration >= minEpochDuration, 'Small epoch duration');
        uint finishDate = startDate + epochDuration;

        address farmingProxy = address(new FarmingProxy());
        IWSCustomProxy(farmingProxy).upgradeStorageTo(address(implementationGetter));
        IFarmingRewards(farmingProxy).initialize(
            rewardToken,
            stakingToken,
            rewardAmount,
            startDate,
            finishDate,
            epochDuration
        );

        IERC20(rewardToken).transferFrom(msg.sender, address(farmingProxy), rewardAmount);

        FarmingPoolsInfo memory newRewardsInfo;

        newRewardsInfo.id = countFarmingPools;
        newRewardsInfo.stakingToken = stakingToken;
        newRewardsInfo.rewardToken = rewardToken;
        newRewardsInfo.startDate = startDate;
        newRewardsInfo.finishDate = finishDate;
        newRewardsInfo.rewardAmount = rewardAmount;
        newRewardsInfo.epochDuration = epochDuration;
        newRewardsInfo.farmingPool = farmingProxy;

        usersFarmingPool[msg.sender].push(countFarmingPools);
        farmingPoolLocks[countFarmingPools] = lockAmount;

        farmingInfo[countFarmingPools] = newRewardsInfo;
        countFarmingPools++;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

import "./WSCustomProxy.sol";

contract FarmingProxy is TransparentUpgradeableCustomProxy {
    constructor() public payable TransparentUpgradeableCustomProxy() {
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

import './libraries/Math.sol';
import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';
import './interfaces/IERC20.sol';
import './interfaces/IFarmingRewards.sol';
import './ReentrancyGuard.sol';

contract FarmingRewards is ReentrancyGuard, IFarmingRewards {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public initialized;
    IERC20 public rewardToken;
    IERC20 public stakingToken;
    uint256 public rewardAmount;
    uint256 public _totalSupply;
    uint256 public startDate;
    uint256 public finishDate;
    uint256 public epochDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public currentCountAccounts;
    uint private dateOfFirstFarmInvestment;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) private _balances;

    event EpochAdded(uint startEpoch, uint endDate, uint256 reward, uint256 epochDuration);
    event Farmed(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);

    modifier updateReward(address account) {
        require(account != address(0), 'Can not be zero address');

        _updateRewardForEpoch(account);
        _;
    }

    function initialize(
        address _rewardToken,
        address _stakingToken,
        uint256 _rewardAmount,
        uint256 _startDate,
        uint256 _finishDate,
        uint256 _epochDuration
    ) external {
        require(initialized == false, "Contract already initialized.");
        rewardToken = IERC20(_rewardToken);
        stakingToken = IERC20(_stakingToken);

        createEpoch(_startDate, _finishDate, _rewardAmount, _epochDuration);
    }

    function _balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function _lastTimeRewardApplicable() internal view returns (uint) {
        if (block.timestamp < startDate) {
            return 0;
        }
        return Math.min(block.timestamp, finishDate);
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint) {
        return _balanceOf(account);
    }

    function lastTimeRewardApplicable() public override view returns (uint) {
        return _lastTimeRewardApplicable();
    }

    function _rewardPerToken() internal view returns (uint) {
        if (block.timestamp < startDate) {
            return 0;
        }
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            _lastTimeRewardApplicable()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(1e18)
                .div(_totalSupply)
        );
    }

    function rewardPerToken() public override view returns (uint) {
        return _rewardPerToken();
    }

    function _earned(address account) internal view returns (uint256) {
        return _balances[account]
            .mul(_rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    function earned(address account) external override view returns (uint256) {
        return _earned(account);
    }

    function getRewardForDuration() external override view returns (uint256) {
        return rewardRate.mul(finishDate - dateOfFirstFarmInvestment);
    }

    function getBlock() external returns(uint256) {
        return block.timestamp;
    }

    function farm(uint256 amount) nonReentrant updateReward(msg.sender) external {
        require(amount > 0, "Cannot farm 0");
        require(block.timestamp < finishDate, 'Farming pool already finished');
        require(block.timestamp >= startDate, 'Farming pool not ready');

        if (dateOfFirstFarmInvestment == 0) {
            dateOfFirstFarmInvestment = block.timestamp;
        }

        if(_balances[msg.sender] == 0){
            currentCountAccounts++;
        }

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Farmed(msg.sender, amount);
    }

    function withdraw(uint256 amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);

        if (_balances[msg.sender] == 0) {
            --currentCountAccounts;
        }

        if (currentCountAccounts == 0) {
            dateOfFirstFarmInvestment = block.timestamp;
        }

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        require(rewards[msg.sender] > 0, 'Zero balance reward');

        rewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, rewards[msg.sender]);

        emit RewardPaid(msg.sender, rewards[msg.sender]);
    }

    function exit() override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function _updateRewardForEpoch(address account) internal {
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateTime = _lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = _earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function createEpoch(uint _startDate, uint _finishDate, uint _rewardAmount, uint _epochDuration) internal {
        require(_startDate >= block.timestamp, "Provided start date too late.");
        require(_finishDate > _startDate, "Wrong end date epoch.");
        require(_rewardAmount > 0, "Wrong reward amount");

        rewardAmount = _rewardAmount;
        startDate = _startDate;
        finishDate = _finishDate;
        epochDuration = _epochDuration;
        rewardRate = rewardAmount.div(epochDuration);

        emit EpochAdded(startDate, finishDate, rewardAmount, epochDuration);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    // Let contract be functional for proxy contract initialization
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

interface IWSERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address user, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IImplementationGetter {
    function getImplementationAddress() external view returns (address);
    function upgradeImplementation(address _implementation) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

interface IFarmingRewards {

    function initialize(
        address rewardsToken,
        address stakingToken,
        uint256 rewardAmount,
        uint256 startDate,
        uint256 finishDate,
        uint256 epochDuration
    ) external;
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function farm(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IWSCustomProxy {
    function initialize(address _implementation, address _admin, bytes calldata _data) external;
    function upgradeStorageTo(address _proxy) external;
    function upgradeStorageToAndCall(address _proxy, bytes calldata data) external payable;
    function changeAdmin(address newAdmin) external;
    function admin() external returns (address);
    function implementation() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

import '../interfaces/IWSCustomProxy.sol';

interface ImplementationGetter {
    function getImplementationAddress() external returns(address);
}

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _delegate(_implementation());
    }
}

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableCustomProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor() public payable {
        assert(_IMPLEMENTATION_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation_storage")) - 1));
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementationStorage);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_STORAGE_SLOT = 0x32966ed17b28d3117e87cb2c15a847a3829937667aa3286f41cf85a257e10460;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_STORAGE_SLOT;
        address storage_address;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            storage_address := sload(slot)
        }
        impl = ImplementationGetter(storage_address).getImplementationAddress();
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeStorageTo(address newImplementationStorage) virtual internal {
        _setImplementationStorage(newImplementationStorage);
        emit Upgraded(newImplementationStorage);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementationStorage(address newImplementationStorage) private {
        bytes32 slot = _IMPLEMENTATION_STORAGE_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementationStorage)
        }
    }
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative inerface of your proxy.
 */
contract TransparentUpgradeableCustomProxy is UpgradeableCustomProxy, IWSCustomProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor() public payable UpgradeableCustomProxy() {
        require(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1), "Wrong admin slot");
        _setAdmin(msg.sender);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     */
    function admin() external override ifAdmin returns (address) {
        return _admin();
    }

    function initialize(address _newImplementationStorage, address _admin, bytes calldata _data) external override ifAdmin {
        _upgradeStorageTo(_newImplementationStorage);
        _setAdmin(_admin);
        if(_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = _implementation().delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Returns the current implementation.
     */
    function implementation() external override ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external override ifAdmin {
        require(newAdmin != _admin(), "WSProxy: new admin is the same admin.");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeStorageTo(address newImplementation) external override ifAdmin {
        _upgradeStorageTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeStorageToAndCall(address newImplementation, bytes calldata data) external override payable ifAdmin {
        _upgradeStorageTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;
        // remove this protection
        // require(newAdmin != address(0), "WSProxy: Can't set admin to zero address.");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

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
contract ReentrancyGuard {
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

    constructor ()  {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.12;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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