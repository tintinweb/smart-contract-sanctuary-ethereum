/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

library ProxyFactory {
    /* functions */

    function _create(address logic, bytes memory data) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.clone(logic);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }

    function _create2(
        address logic,
        bytes memory data,
        bytes32 salt
    ) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.cloneDeterministic(logic, salt);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma abicoder v2;

interface IRageQuit {
    function rageQuit() external;
}

interface IAludel is IRageQuit {
    /* admin events */

    event AludelCreated(address rewardPool, address powerSwitch);
    event AludelFunded(uint256 amount, uint256 duration);
    event BonusTokenRegistered(address token);
    event VaultFactoryRegistered(address factory);
    event VaultFactoryRemoved(address factory);

    /* user events */

    event Staked(address vault, uint256 amount);
    event Unstaked(address vault, uint256 amount);
    event RewardClaimed(address vault, address token, uint256 amount);

    /* data types */

    struct AludelData {
        address stakingToken;
        address rewardToken;
        address rewardPool;
        RewardScaling rewardScaling;
        uint256 rewardSharesOutstanding;
        uint256 totalStake;
        uint256 totalStakeUnits;
        uint256 lastUpdate;
        RewardSchedule[] rewardSchedules;
    }

    struct RewardSchedule {
        uint256 duration;
        uint256 start;
        uint256 shares;
    }

    struct VaultData {
        uint256 totalStake;
        StakeData[] stakes;
    }

    struct StakeData {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardScaling {
        uint256 floor;
        uint256 ceiling;
        uint256 time;
    }

    struct RewardOutput {
        uint256 lastStakeAmount;
        uint256 newStakesCount;
        uint256 reward;
        uint256 newTotalStakeUnits;
    }

    function initializeLock() external;

    function initialize(
        uint64 startTime,
        address ownerAddress,
        address feeRecipient,
        uint16 feeBps,
        bytes calldata
    ) external;

    /* user functions */

    function stake(address vault, uint256 amount, bytes calldata permission)
        external;

    function unstakeAndClaim(
        address vault,
        uint256 amount,
        bytes calldata permission
    )
        external;

    /* admin functions */

    function fund(uint256 amount, uint256 duration) external;

    function registerVaultFactory(address factory) external;

    function removeVaultFactory(address factory) external;

    function registerBonusToken(address bonusToken) external;

    function rescueTokensFromRewardPool(
        address token,
        address recipient,
        uint256 amount
    )
        external;

    /* getter functions */

    function getAludelData()
        external
        view
        returns (AludelData memory aludel);

    function getBonusTokenSetLength()
        external
        view
        returns (uint256 length);

    function getBonusTokenAtIndex(uint256 index)
        external
        view
        returns (address bonusToken);

    function getVaultFactorySetLength()
        external
        view
        returns (uint256 length);

    function getVaultFactoryAtIndex(uint256 index)
        external
        view
        returns (address factory);

    function getVaultData(address vault)
        external
        view
        returns (VaultData memory vaultData);

    function isValidAddress(address target)
        external
        view
        returns (bool validity);

    function isValidVault(address target)
        external
        view
        returns (bool validity);

    function getCurrentUnlockedRewards()
        external
        view
        returns (uint256 unlockedRewards);

    function getFutureUnlockedRewards(uint256 timestamp)
        external
        view
        returns (uint256 unlockedRewards);

    function getCurrentVaultReward(address vault)
        external
        view
        returns (uint256 reward);

    function getCurrentStakeReward(address vault, uint256 stakeAmount)
        external
        view
        returns (uint256 reward);

    function getFutureVaultReward(address vault, uint256 timestamp)
        external
        view
        returns (uint256 reward);

    function getFutureStakeReward(
        address vault,
        uint256 stakeAmount,
        uint256 timestamp
    )
        external
        view
        returns (uint256 reward);

    function getCurrentVaultStakeUnits(address vault)
        external
        view
        returns (uint256 stakeUnits);

    function getFutureVaultStakeUnits(address vault, uint256 timestamp)
        external
        view
        returns (uint256 stakeUnits);

    function getCurrentTotalStakeUnits()
        external
        view
        returns (uint256 totalStakeUnits);

    function getFutureTotalStakeUnits(uint256 timestamp)
        external
        view
        returns (uint256 totalStakeUnits);

    /* pure functions */

    function calculateTotalStakeUnits(
        StakeData[] memory stakes,
        uint256 timestamp
    )
        external
        pure
        returns (uint256 totalStakeUnits);

    function calculateStakeUnits(uint256 amount, uint256 start, uint256 end)
        external
        pure
        returns (uint256 stakeUnits);

    function calculateUnlockedRewards(
        RewardSchedule[] memory rewardSchedules,
        uint256 rewardBalance,
        uint256 sharesOutstanding,
        uint256 timestamp
    )
        external
        pure
        returns (uint256 unlockedRewards);

    function calculateRewardFromStakes(
        StakeData[] memory stakes,
        uint256 unstakeAmount,
        uint256 unlockedRewards,
        uint256 totalStakeUnits,
        uint256 timestamp,
        RewardScaling memory rewardScaling
    )
        external
        pure
        returns (RewardOutput memory out);

    function calculateReward(
        uint256 unlockedRewards,
        uint256 stakeAmount,
        uint256 stakeDuration,
        uint256 totalStakeUnits,
        RewardScaling memory rewardScaling
    )
        external
        pure
        returns (uint256 reward);
}

contract AludelFactory is Ownable {
    struct ProgramData {
        address template;
        uint64 startTime;
        string name;
        string stakingTokenUrl;
    }
    struct TemplateData {
        bool listed;
        bool disabled;
        string name;
    }

    /// @notice set of template data
    mapping(address => TemplateData) private _templates;

    /// @notice address => ProgramData mapping
    mapping(address => ProgramData) private _programs;

    /// @notice fee's recipient.
    address public feeRecipient;
    /// @notice fee's basis point
    uint16 public feeBps;

    /// @dev emitted when a new template is added
    event TemplateAdded(address template);

    /// @dev emitted when a template is updated
    event TemplateUpdated(address template, bool disabled);

    /// @dev emitted when a program's (deployed via the factory or preexisting)
    // url or name is changed
    event ProgramChanged(address program, string name, string url);
    /// @dev emitted when a program's (deployed via the factory or preexisting)
    /// is created
    event ProgramAdded(address program, string name, string url);
    /// @dev emitted when a program is delisted
    event ProgramDelisted(address program);

    error InvalidTemplate();
    error TemplateNotRegistered();
    error TemplateDisabled();
    error TemplateAlreadyAdded();
    error ProgramAlreadyRegistered();
    error AludelNotRegistered();
    error AludelAlreadyRegistered();

    constructor(address recipient, uint16 bps) {
        feeRecipient = recipient;
        feeBps = bps;
    }

    /// @notice perform a minimal proxy deploy of a predefined aludel template
    /// @param template the number of the template to launch
    /// @param name the string represeting the program's name
    /// @param stakingTokenUrl the program's url
    /// @param data the calldata to use on the new aludel initialization
    /// @return aludel the new aludel deployed address.
    function launch(
        address template,
        string memory name,
        string memory stakingTokenUrl,
        uint64 startTime,
        address vaultFactory,
        address[] memory bonusTokens,
        address ownerAddress,
        bytes calldata data
    )
        public
        returns (address aludel)
    {
        if (!_templates[template].listed) {
            revert TemplateNotRegistered();
        }

        // reverts when template is disabled
        if (_templates[template].disabled) {
            revert TemplateDisabled();
        }

        // create clone and initialize
        aludel = ProxyFactory._create(
            template,
            abi.encodeWithSelector(
                IAludel.initialize.selector,
                startTime,
                ownerAddress,
                feeRecipient,
                feeBps,
                data
            )
        );

        // add program's data to the storage
        _programs[aludel] = ProgramData({
            startTime: startTime,
            template: template,
            name: name,
            stakingTokenUrl: stakingTokenUrl
        });

        // register vault factory
        IAludel(aludel).registerVaultFactory(vaultFactory);

        uint256 bonusTokenLength = bonusTokens.length;

        // register bonus tokens
        for (uint256 index = 0; index < bonusTokenLength; ++index) {
            IAludel(aludel).registerBonusToken(bonusTokens[index]);
        }

        // transfer ownership
        Ownable(aludel).transferOwnership(ownerAddress);
        
        emit ProgramAdded(address(aludel), name, stakingTokenUrl);

        // explicit return
        return aludel;
    }

    /* admin */

    /// @notice adds a new template to the factory
    function addTemplate(address template, string memory name, bool disabled)
        public
        onlyOwner
    {
        // cannot add address(0) as template
        if (template == address(0)) {
            revert InvalidTemplate();
        }

        // add template to the storage
        if (_templates[template].listed) {
            revert TemplateAlreadyAdded();
        } else {
            _templates[template] = TemplateData({
                listed: true,
                disabled: disabled,
                name: name
            });
        }

        // emit event
        emit TemplateAdded(template);
    }

    // @dev function to check if an arbitrary address is a registered program
    // @notice programs cant have a null template, so this should be enough to
    // know if storage is occupied or not
    function isAludel(address who) public view returns(bool){
      return _programs[who].template != address(0);
    }

    /// @notice sets a template as disable or enabled
    function updateTemplate(address template, bool disabled)
        external
        onlyOwner
    {
        if (!_templates[template].listed) {
            revert InvalidTemplate();
        }

        _templates[template].disabled = disabled;
        emit TemplateUpdated(template, disabled);
    }

    /// @notice updates both name and url of a program at once
    /// @dev to set only one of them, you can pass an empty string as the other
    /// and then you'll save some gas
    function updateProgram(address program, string memory newName,string memory newUrl) external onlyOwner {
        // check if the address is already registered
        if(!isAludel(program)){
          revert AludelNotRegistered();
        }
        // update storage
        if(bytes(newName).length != 0){
            _programs[program].name = newName;
        }
        if(bytes(newUrl).length != 0){
            _programs[program].stakingTokenUrl = newUrl;
        }
        // emit event
        emit ProgramChanged(program, newName, newUrl);
    }

    /// @notice manually adds a program
    /// @dev this allows onchain storage of pre-aludel factory programs
    function addProgram(
        address program,
        address template,
        string memory name,
        string memory stakingTokenUrl,
        uint64 startTime
    )
        external
        onlyOwner
    {
        if(isAludel(program)){
          revert AludelAlreadyRegistered();
        }
        if (!_templates[template].listed) {
            revert TemplateNotRegistered();
        }

        // add program's data to the storage
        _programs[program] = ProgramData({
            startTime: startTime,
            template: template,
            name: name,
            stakingTokenUrl: stakingTokenUrl
        });

        emit ProgramAdded(program, name, stakingTokenUrl);

    }

    /// @notice delist a program
    /// @dev removes `program` as a registered instance of the factory
    function delistProgram(address program) external onlyOwner {
        if(!isAludel(program)){
          revert AludelNotRegistered();
        }
        delete _programs[program];

        emit ProgramDelisted(program);
    }

    /// @notice retrieves a template's data
    function getTemplate(address template)
        external
        view
        returns (TemplateData memory)
    {
        return _templates[template];
    }

    // @dev the automatically generated getter doesn't return a struct, but
    // instead a tuple. I didn't research the gas cost implications of this,
    // but it's more readable to access fields by name, so this is used to
    // force returning a struct
    function programs(address program) external view returns (ProgramData memory) {
      return _programs[program];
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        feeRecipient = newRecipient;
    }

    function setFeeBps(uint16 bps) external onlyOwner {
        feeBps = bps;
    }
}