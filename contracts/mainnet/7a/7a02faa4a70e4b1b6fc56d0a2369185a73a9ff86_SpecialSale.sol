//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SpecialConfigurePoolLibrary.sol";
import "./SpecialEndPoolLibrary.sol";
import "./SpecialDeployPoolLibrary.sol";
import "./SpecialDepositPoolLibrary.sol";
import "./ISpecialPool.sol";
import "./SpecialValidatePoolLibrary.sol";
import "./SpecialSaleExtra.sol";

contract SpecialSale is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    SpecialSaleExtra private constant specialSaleExtra =
        SpecialSaleExtra(0x5FaeD0dB185AD9235E2dEA35d98C07eF3B521b72);
    address public constant treasury =
        address(0xDf47F618a94eEC71c2eD8cFad256942787E0d951);
    IIDO public constant ido=IIDO(0x6126E7Af6989cfabD2be277C46fB507aa5836CFd);
    address[] public poolAddresses;
    uint256[] public poolFixedFee;
    uint256 public poolPercentFee;
    uint256 public poolTokenPercentFee;
    mapping(address => address) public poolOwners;
    mapping(address => ISpecialPool.PoolModel) public poolInformation;
    mapping(address => ISpecialPool.PoolDetails) public poolDetails;
    mapping(address => address[]) public participantsAddress;
    mapping(address => mapping(address => uint256)) public collaborations;
    mapping(address => uint256) public _weiRaised;
    mapping(address => mapping(address => bool)) public _didRefund;
    mapping(address => mapping(address => bool))
        private whitelistedAddressesMap;
    mapping(address => address[]) public whitelistedAddressesArray;
    mapping(address => bool) public isHiddenPool;
    address public holdingToken;
    uint256[] public holdingTokenAmount;
    mapping(address => ISpecialPool.UserVesting) public userVesting;
    mapping(address => mapping(address => uint256))
        public unlockedVestingAmount;
    mapping(address => uint256) public cliff;
    mapping(address => bool) public isAdminSale;
    mapping(address => address) public fundRaiseToken;
    mapping(address => uint256) public fundRaiseTokenDecimals;
    mapping(address => uint256) public allowDateTime;
    uint256 gweiLimit;
    address public holdingStakedToken;
    uint256[] public holdingStakedTokenAmount;
    mapping(address => bool) public isTieredWhitelist;
    mapping(address => mapping(address => bool))
        private whitelistedAddressesMapForTiered;
    mapping(address => address[]) public whitelistedAddressesArrayForTiered;
    uint256 private amountInit;
    uint256 private amountAddedPerSec;
    uint256 private limitPeriod;
    mapping(address=>mapping(uint256=>uint256)) depositAmount;
    address public holdingNFT;
    mapping(address => bool) public noTier; 
    event LogPoolCreated(
        address poolOwner,
        address pool,
        ISpecialPool.PoolModel model,
        ISpecialPool.PoolDetails details,
        ISpecialPool.UserVesting userVesting,
        uint256 cliff,
        bool isAdminSale,
        bool isTieredWhitelist,
        address fundRaiseToken,
        uint256 fundRaiseTokenDecimals,
        uint256 allowDateTime
    );
    event LogPoolKYCUpdate(address pool, bool kyc);
    event LogPoolAuditUpdate(address pool, bool audit, string auditLink);
    event LogPoolTierUpdate(address pool, uint256 tier);
    event LogPoolExtraData(address pool, string extraData);
    event LogDeposit(address pool, address participant, uint256 weiRaised, uint256 decimals);
    event LogPoolStatusChanged(address pool, uint256 status);
    event LogConfigChanged(
        uint256[] poolFixedFee,
        uint256 poolPercentFee,
        uint256 poolTokenPercentFee
    );
    event LogAddressWhitelisted(
        address pool,
        address[] whitelistedAddresses,
        address[] whitelistedAddressesForTiered
    );
    event TierAllowed(address pool, bool isAllowed);
    event LogUpdateWhitelistable(address pool, bool[2] whitelistable);
    event LogPoolHide(address pool, bool isHide);
    event LogAdminPoolFilled(
        address sender,
        address pool,
        address projectTokenAddress,
        uint256 decimals,
        uint256 totalSupply,
        string symbol,
        string name
    );
    event LogUpdateAllowDateTime(address pool, uint256 allowDateTime);
    event LogEmergencyWithdraw(
        address _pool,
        address participant,
        uint256 weiRaised, 
        uint256 decimals
    );
    modifier _onlyPoolOwner(address _pool, address _owner) {
        require(poolOwners[_pool] == _owner, "Not Owner!");
        _;
    }
    modifier _onlyPoolOwnerAndOwner(address _pool, address _owner) {
        require(poolOwners[_pool] == _owner || _owner == owner(), "Not Owner!");
        _;
    }

    function initialize(
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();        
    }

    function createPool(
        ISpecialPool.PoolModel calldata model,
        ISpecialPool.PoolDetails calldata details,
        ISpecialPool.UserVesting calldata _userVesting,
        uint256 _cliff,
        bool _isAdminSale,
        bool _isTieredWhitelist,
        address _fundRaiseToken,
        uint256 _allowDateTime
    ) external payable nonReentrant returns (address poolAddress) {
        require(!_isAdminSale || msg.sender == owner(), "not Admin!");
        require(
            (_isAdminSale || msg.value >= poolFixedFee[uint256(details.tier)]),
            "Not enough fee!"
        );
        poolAddress = SpecialDeployPoolLibrary.deployPool();
        if (_fundRaiseToken == address(0))
            fundRaiseTokenDecimals[poolAddress] = 18;
        else {
            IERC20Metadata _token = IERC20Metadata(_fundRaiseToken);
            uint256 _decimals = _token.decimals();
            if (_decimals > 0) {
                fundRaiseToken[poolAddress] = _fundRaiseToken;
                fundRaiseTokenDecimals[poolAddress] = _decimals;
            } else fundRaiseTokenDecimals[poolAddress] = 18;
        }

        poolInformation[poolAddress] = ISpecialPool.PoolModel({
            hardCap: model.hardCap,
            softCap: model.softCap,
            specialSaleRate: model.specialSaleRate,
            projectTokenAddress: model.projectTokenAddress,
            status: ISpecialPool.PoolStatus.Inprogress,
            startDateTime: model.startDateTime,
            endDateTime: model.endDateTime,
            minAllocationPerUser: model.minAllocationPerUser,
            maxAllocationPerUser: model.maxAllocationPerUser
        });
        allowDateTime[poolAddress] = _allowDateTime;
        isAdminSale[poolAddress] = _isAdminSale;
        SpecialValidatePoolLibrary._preValidatePoolCreation(poolInformation[poolAddress], _isAdminSale, _allowDateTime);

        poolDetails[poolAddress] = ISpecialPool.PoolDetails({
            extraData: details.extraData,
            whitelistable: details.whitelistable,
            audit: false,
            auditLink: "",
            tier: details.tier,
            kyc: false
        });
        if (!poolDetails[poolAddress].whitelistable) {
            require(!_isTieredWhitelist, "not whitelist");
        }
        isTieredWhitelist[poolAddress] = _isTieredWhitelist;
        userVesting[poolAddress] = _userVesting;
        cliff[poolAddress] = _cliff;
        SpecialValidatePoolLibrary._preValidateUserVesting(userVesting[poolAddress], _cliff);

        if (!_isAdminSale)
            SpecialDeployPoolLibrary.initPool(
                poolAddress,
                owner(),
                poolInformation[poolAddress],
                poolTokenPercentFee,
                fundRaiseTokenDecimals[poolAddress]
            );

        poolAddresses.push(poolAddress);
        poolOwners[poolAddress] = msg.sender;
        emit LogPoolCreated(
            msg.sender,
            poolAddress,
            poolInformation[poolAddress],
            poolDetails[poolAddress],
            userVesting[poolAddress],
            _cliff,
            _isAdminSale,
            _isTieredWhitelist,
            fundRaiseToken[poolAddress],
            fundRaiseTokenDecimals[poolAddress],
            _allowDateTime
        );
    }

    function updateAllowDateTime(address _pool, uint256 _allowDateTime)
        external
        nonReentrant
        onlyOwner
    {
        require(
            (poolInformation[_pool].hardCap == _weiRaised[_pool] &&
                _allowDateTime >=
                poolInformation[_pool].startDateTime) ||
                (_allowDateTime >= poolInformation[_pool].endDateTime),
            "allow>=end!"
        );
        allowDateTime[_pool] = _allowDateTime;
        poolInformation[_pool].endDateTime=_allowDateTime;
        emit LogUpdateAllowDateTime(_pool, _allowDateTime);
    }

    function fillAdminPool(address poolAddress, address _projectTokenAddress)
        external
        nonReentrant
        onlyOwner
    {
        require(isAdminSale[poolAddress], "not Admin!");
        uint256 decimals;
        uint256 totalSupply;
        string memory symbol;
        string memory name;
        if (poolInformation[poolAddress].projectTokenAddress == address(0)) {
            poolInformation[poolAddress]
                .projectTokenAddress = _projectTokenAddress;
        }
        IERC20Metadata token = IERC20Metadata(
            poolInformation[poolAddress].projectTokenAddress
        );
        decimals = token.decimals();
        totalSupply = token.totalSupply();
        symbol = token.symbol();
        name = token.name();
        SpecialDeployPoolLibrary.fillAdminPool(
            poolAddress,
            poolInformation[poolAddress],
            decimals,
            _weiRaised[poolAddress],
            fundRaiseTokenDecimals[poolAddress]>0 ? fundRaiseTokenDecimals[poolAddress] : 18
        );
        emit LogAdminPoolFilled(
            msg.sender,
            poolAddress,
            poolInformation[poolAddress].projectTokenAddress,
            decimals,
            totalSupply,
            symbol,
            name
        );
    }

    function updateTierAllowed(
        address _pool,
        bool isAllowed
    ) external onlyOwner{
        noTier[_pool]=isAllowed;
        emit TierAllowed(_pool, isAllowed);       
    }

    function setAdminConfig(
        uint256[] memory _poolFixedFee,
        uint256 _poolPercentFee,
        uint256 _poolTokenPercentFee,
        uint256 _gweiLimit
    ) public onlyOwner {
        poolFixedFee = _poolFixedFee;
        poolPercentFee = _poolPercentFee;
        poolTokenPercentFee = _poolTokenPercentFee;        
        gweiLimit = _gweiLimit;
    }

    // function setAdminLimit(
    //     uint256 _amountInit,
    //     uint256 _amountAddedPerSec,
    //     uint256 _limitPeriod
    // ) public onlyOwner {
    //     amountInit=_amountInit;
    //     amountAddedPerSec=_amountAddedPerSec;
    //     limitPeriod=_limitPeriod;
    // }
    function updateExtraData(address _pool, string memory _extraData)
        external
        _onlyPoolOwner(_pool, msg.sender)
    {
        SpecialConfigurePoolLibrary.updateExtraData(
            _extraData,
            poolInformation[_pool],
            poolDetails[_pool]
        );
        emit LogPoolExtraData(_pool, _extraData);
    }

    function updateKYCStatus(address _pool, bool _kyc) external onlyOwner {
        SpecialConfigurePoolLibrary.updateKYCStatus(_kyc, poolDetails[_pool]);
        emit LogPoolKYCUpdate(_pool, _kyc);
    }

    function updateAuditStatus(
        address _pool,
        bool _audit,
        string memory _auditLink
    ) external {
        require((poolOwners[_pool] == msg.sender && uint256(poolDetails[_pool].tier)>0) || msg.sender == owner(), "Not Special sale Owner or less than gold tier!");
        SpecialConfigurePoolLibrary.updateAuditStatus(
            _audit,
            _auditLink,
            poolDetails[_pool]
        );
        emit LogPoolAuditUpdate(_pool, _audit, _auditLink);
    }

    function updateTierStatus(address _pool, uint256 _tier) external onlyOwner {
        poolDetails[_pool].tier = ISpecialPool.PoolTier(_tier);
        emit LogPoolTierUpdate(_pool, _tier);
    }

    function addAddressesToWhitelist(
        address _pool,
        address[] memory whitelistedAddresses,
        address[] memory whitelistedAddressesForTiered
    ) external _onlyPoolOwner(_pool, msg.sender) {
        if (poolDetails[_pool].whitelistable) {
            SpecialConfigurePoolLibrary.addAddressesToWhitelist(
                whitelistedAddresses,
                poolInformation[_pool],
                whitelistedAddressesMap[_pool],
                whitelistedAddressesArray[_pool]
            );
            if (isTieredWhitelist[_pool]) {
                SpecialConfigurePoolLibrary.addAddressesToWhitelistForTiered(
                    whitelistedAddressesForTiered,
                    poolInformation[_pool],
                    whitelistedAddressesMapForTiered[_pool],
                    whitelistedAddressesArrayForTiered[_pool]
                );
                emit LogAddressWhitelisted(
                    _pool,
                    whitelistedAddresses,
                    whitelistedAddressesForTiered
                );
            }else{
                emit LogAddressWhitelisted(
                    _pool,
                    whitelistedAddresses,
                    new address[](0)
                );
            }                
        }
    }

    function updateWhitelistable(address _pool, bool[2] memory whitelistable)
        external
        _onlyPoolOwner(_pool, msg.sender)
    {
        SpecialConfigurePoolLibrary.updateWhitelistable(
            _pool,
            whitelistable,
            isTieredWhitelist,
            poolInformation[_pool],
            poolDetails[_pool],
            whitelistedAddressesMap[_pool],
            whitelistedAddressesArray,
            whitelistedAddressesMapForTiered[_pool],
            whitelistedAddressesArrayForTiered
        );
        emit LogUpdateWhitelistable(_pool, whitelistable);
    }

    function deposit(address _pool, uint256 _amount) external payable {
        require(tx.gasprice <= gweiLimit, "No sniping!");
        require(poolOwners[_pool] != address(0x0), "Not Existed!");        
        bool isPassed=!poolDetails[_pool].whitelistable ? true : SpecialDepositPoolLibrary.whitelistCheckForNFTAndAccount(
                uint256(poolDetails[_pool].tier),
                isTieredWhitelist[_pool],
                poolInformation[_pool].startDateTime,    
                ido                
            );
        if(!isPassed)   
        {
            isPassed=SpecialDepositPoolLibrary.whitelistCheckForTokenHolders(
                ido.holdingToken(), 
                ido.holdingStakedToken(),
                [
                    ido.holdingTokenAmount(uint256(poolDetails[_pool].tier)),
                    ido.holdingStakedTokenAmount(uint256(poolDetails[_pool].tier)),
                    ido.holdingTokenAmount(3),
                    ido.holdingStakedTokenAmount(3),
                    uint256(poolDetails[_pool].tier),
                    poolInformation[_pool].startDateTime
                ],
                isTieredWhitelist[_pool]
            );
            if(!isPassed)
                SpecialDepositPoolLibrary.whitelistCheck(
                    isTieredWhitelist[_pool],
                    poolInformation[_pool].startDateTime,
                    whitelistedAddressesMap[_pool],
                    whitelistedAddressesMapForTiered[_pool]
                );
        }
        {
            SpecialDepositPoolLibrary.depositPool(
                [_pool, fundRaiseToken[_pool]],
                _weiRaised,
                poolInformation[_pool],
                collaborations[_pool],
                participantsAddress,
                _amount
            );
        }

        if (fundRaiseToken[_pool] == address(0)) {
            emit LogDeposit(_pool, msg.sender, _weiRaised[_pool], fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18);
        } else emit LogDeposit(_pool, msg.sender, _weiRaised[_pool], fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18);
    }

    // old contract usable from here
    function cancelPool(address _pool)
        external
        _onlyPoolOwnerAndOwner(_pool, msg.sender)
        nonReentrant
    {
        SpecialEndPoolLibrary.cancelPool(
            poolInformation[_pool],
            poolOwners[_pool],
            _pool
        );

        emit LogPoolStatusChanged(
            _pool,
            uint256(ISpecialPool.PoolStatus.Cancelled)
        );
    }

    function forceCancelPool(address _pool) external onlyOwner nonReentrant {
        SpecialEndPoolLibrary.forceCancelPool(poolInformation[_pool]);
        emit LogPoolStatusChanged(
            _pool,
            uint256(ISpecialPool.PoolStatus.Cancelled)
        );
    }

    function claimToken(address _pool) external nonReentrant {
        SpecialEndPoolLibrary.claimToken(
            poolInformation[_pool],
            collaborations[_pool],
            unlockedVestingAmount[_pool],
            userVesting[_pool],
            _didRefund[_pool],
            _pool,
            cliff[_pool],
            fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18
        );
    }

    function refund(address _pool) external nonReentrant {
        SpecialEndPoolLibrary.refund(
            _pool,
            _weiRaised[_pool],
            _didRefund[_pool],
            collaborations[_pool],
            poolInformation[_pool],
            fundRaiseToken[_pool]
        );
    }

    function collectFunds(address _pool)
        external
        _onlyPoolOwner(_pool, msg.sender)
    {
        SpecialEndPoolLibrary.collectFunds(
            [_pool, owner(), poolOwners[_pool], fundRaiseToken[_pool]],
            [
                _weiRaised[_pool],
                poolPercentFee,
                poolTokenPercentFee,
                fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18
            ],
            poolInformation[_pool],
            isAdminSale[_pool]
        );
        emit LogPoolStatusChanged(
            _pool,
            uint256(ISpecialPool.PoolStatus.Collected)
        );
    }

    function allowClaim(address _pool)
        external
        _onlyPoolOwnerAndOwner(_pool, msg.sender)
    {
        SpecialEndPoolLibrary.allowClaim(
            [_pool, owner(), fundRaiseToken[_pool]],
            [_weiRaised[_pool], fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18],
            poolInformation[_pool],
            isAdminSale[_pool],
            allowDateTime[_pool]
        );
        emit LogPoolStatusChanged(
            _pool,
            uint256(ISpecialPool.PoolStatus.Allowed)
        );
    }

    function updateHidePool(address pool, bool isHide) external onlyOwner {
        SpecialConfigurePoolLibrary.updateHidePool(pool, isHide, isHiddenPool);
        emit LogPoolHide(pool, isHide);
    }

    function emergencyWithdraw(address _pool) external nonReentrant {
        bool isWithdrawn = SpecialEndPoolLibrary.emergencyWithdraw(
            _pool,
            treasury,
            _weiRaised,
            collaborations[_pool],
            participantsAddress[_pool],
            poolInformation[_pool],
            fundRaiseToken[_pool]
        );
        if (isWithdrawn) emit LogEmergencyWithdraw(_pool, msg.sender, _weiRaised[_pool], fundRaiseTokenDecimals[_pool]>0 ? fundRaiseTokenDecimals[_pool] : 18);
    }
    receive() external payable {}

    function getPoolAddresses() external view returns (address[] memory) {
        return poolAddresses;
    }
    function getParticipantsAddresses(address _pool) external view returns (address[] memory) {
        return participantsAddress[_pool];
    }

    function getWhitelistAddresses(address _pool) external view returns (address[] memory t1, address[] memory t2) {
        t1= whitelistedAddressesArray[_pool];
        t2= whitelistedAddressesArrayForTiered[_pool];
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "./ISpecialPool.sol";
import "./SpecialValidatePoolLibrary.sol";

library SpecialConfigurePoolLibrary {

    function updateExtraData(
        string calldata _extraData,
        ISpecialPool.PoolModel storage poolInformation,
        ISpecialPool.PoolDetails storage poolDetails
    ) external {
        SpecialValidatePoolLibrary._poolIsNotCancelled(poolInformation);
        poolDetails.extraData = _extraData;
    }

    function updateKYCStatus(
        bool _kyc,
        ISpecialPool.PoolDetails storage poolDetails
    ) external {
        poolDetails.kyc = _kyc;
    }

    function updateAuditStatus(
        bool _audit,
        string calldata _auditLink,
        ISpecialPool.PoolDetails storage poolDetails
    ) external {
        poolDetails.audit = _audit;
        poolDetails.auditLink = _auditLink;
    }

    function addAddressesToWhitelist(
        address[] calldata whitelistedAddresses,
        ISpecialPool.PoolModel storage poolInformation,
        mapping(address => bool) storage whitelistedAddressesMap,
        address[] storage whitelistedAddressesArray
    ) external {
        SpecialValidatePoolLibrary._poolIsNotCancelled(poolInformation);        

        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            address userAddress = whitelistedAddresses[i];
            require(
                address(0) != address(userAddress),
                "zero address not accepted!"
            );

            if (!whitelistedAddressesMap[userAddress]) {
                whitelistedAddressesMap[userAddress] = true;
                whitelistedAddressesArray.push(userAddress);
            }
        }
    }

    function addAddressesToWhitelistForTiered(
        address[] calldata whitelistedAddressesForTiered,
        ISpecialPool.PoolModel storage poolInformation,
        mapping(address => bool) storage whitelistedAddressesMapForTiered,
        address[] storage whitelistedAddressesArrayForTiered
    ) external {        
        for (uint256 i = 0; i < whitelistedAddressesForTiered.length; i++) {
            require(
                address(0) != address(whitelistedAddressesForTiered[i]),
                "zero address not accepted!"
            );

            if (
                !whitelistedAddressesMapForTiered[
                    whitelistedAddressesForTiered[i]
                ]
            ) {
                whitelistedAddressesMapForTiered[
                    whitelistedAddressesForTiered[i]
                ] = true;
                whitelistedAddressesArrayForTiered.push(
                    whitelistedAddressesForTiered[i]
                );
            }
        }
        require(
            whitelistedAddressesArrayForTiered.length
             <= poolInformation.softCap/poolInformation.maxAllocationPerUser+1,
            "whitelist exceeds limit"
        );
    }

    function updateWhitelistable(
        address _pool,
        bool[2] memory whitelistable,
        mapping(address => bool) storage isTieredWhitelist,
        ISpecialPool.PoolModel storage poolInformation,
        ISpecialPool.PoolDetails storage poolDetails,
        mapping(address => bool) storage whitelistedAddressesMap,
        mapping(address => address[]) storage whitelistedAddressesArray,
        mapping(address => bool) storage whitelistedAddressesMapForTiered,
        mapping(address => address[]) storage whitelistedAddressesArrayForTiered
    ) external {
        SpecialValidatePoolLibrary._poolIsUpcoming(poolInformation);
        poolDetails.whitelistable = whitelistable[0];
        isTieredWhitelist[_pool] = whitelistable[1];
        if(!whitelistable[0]){
            for (uint256 i = 0; i < whitelistedAddressesArray[_pool].length; i++) {
                whitelistedAddressesMap[
                    whitelistedAddressesArray[_pool][i]
                ] = false;
            }
            delete whitelistedAddressesArray[_pool];    
        }
        if(!whitelistable[1]){
            for (
                uint256 i = 0;
                i < whitelistedAddressesArrayForTiered[_pool].length;
                i++
            ) {
                whitelistedAddressesMapForTiered[
                    whitelistedAddressesArrayForTiered[_pool][i]
                ] = false;
            }
            delete whitelistedAddressesArrayForTiered[_pool];
        }

        if (!whitelistable[0]) {
            require(!whitelistable[1], "not whitelist!");
        }
    }
    function updateHidePool(
        address pool,
        bool isHide,
        mapping(address => bool) storage isHiddenPool
    ) external {
        isHiddenPool[pool] = isHide;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISpecialPool.sol";

import "./SpecialValidatePoolLibrary.sol";

library SpecialEndPoolLibrary {

    function cancelPool(
        ISpecialPool.PoolModel storage poolInformation,
        address poolOwner,
        address _pool
    ) external {
        SpecialValidatePoolLibrary._poolIsNotCancelled(poolInformation);
        IERC20 projectToken = IERC20(poolInformation.projectTokenAddress);
        poolInformation.status = ISpecialPool.PoolStatus.Cancelled;
        ISpecialPool(payable(_pool)).sendToken(
            poolInformation.projectTokenAddress,
            projectToken.balanceOf(_pool),
            poolOwner
        );
    }

    function forceCancelPool(ISpecialPool.PoolModel storage poolInformation)
        external
    {
        SpecialValidatePoolLibrary._poolIsNotCancelled(poolInformation);
        poolInformation.status = ISpecialPool.PoolStatus.Cancelled;
    }

    function claimToken(
        ISpecialPool.PoolModel storage poolInformation,
        mapping(address => uint256) storage collaborations,
        mapping(address => uint256) storage unlockedVestingAmount,
        ISpecialPool.UserVesting storage userVesting,
        mapping(address => bool) storage _didRefund,
        address _pool,
        uint256 _cliff,
        uint256 fundRaiseTokenDecimals
    ) external {
        SpecialValidatePoolLibrary._poolIsAllowed(poolInformation);
        uint256 _amount = collaborations[msg.sender]
            *poolInformation.specialSaleRate
            /(10**fundRaiseTokenDecimals);
        if (!userVesting.isVesting) {
            if (_didRefund[msg.sender] != true && _amount > 0) {
                _didRefund[msg.sender] = true;
                ISpecialPool(payable(_pool)).sendToken(
                    poolInformation.projectTokenAddress,
                    _amount,
                    msg.sender
                );
            }
        } else {
            uint256 tokenToBeUnlockPercent = userVesting.firstPercent;
            uint256 tokenToBeUnlock = 0;
            uint256 now_date = poolInformation.endDateTime+(
                _cliff * 1 days
            );
            while (true) {
                now_date = now_date+(userVesting.eachPeriod * 1 days);
                if (now_date < block.timestamp) {
                    tokenToBeUnlockPercent = tokenToBeUnlockPercent+(
                        userVesting.eachPercent
                    );
                    if (tokenToBeUnlockPercent >= 100) break;
                } else {
                    break;
                }
            }
            tokenToBeUnlockPercent = tokenToBeUnlockPercent > 100
                ? 100
                : tokenToBeUnlockPercent;

            tokenToBeUnlock = _amount*tokenToBeUnlockPercent/100;
            require(
                tokenToBeUnlock > unlockedVestingAmount[msg.sender],
                "nothing to unlock!"
            );
            uint256 tokenUnlocking = tokenToBeUnlock-unlockedVestingAmount[msg.sender];

            unlockedVestingAmount[msg.sender] = tokenToBeUnlock;
            ISpecialPool(payable(_pool)).sendToken(
                poolInformation.projectTokenAddress,
                tokenUnlocking,
                msg.sender
            );
        }
    }

    function collectFunds(
        address[4] calldata addresses,
        uint256[4] calldata amounts,
        ISpecialPool.PoolModel storage poolInformation,
        bool _isAdminSale
    ) external {
        SpecialValidatePoolLibrary._poolIsReadyCollect(
            poolInformation,
            amounts[0],
            addresses[0], addresses[3],
            _isAdminSale
        );
        if (!_isAdminSale) {
            IERC20 projectToken = IERC20(poolInformation.projectTokenAddress);
            uint256 totalToken = projectToken.balanceOf(addresses[0]);
            ISpecialPool(payable(addresses[0])).sendToken(
                poolInformation.projectTokenAddress,
                totalToken,
                addresses[0]
            );
            require(
                projectToken.balanceOf(addresses[0]) == totalToken,
                "remove tax"
            );

            // pay for the admin
            uint256 toAdminAmount = amounts[0]*amounts[1]/100;
            if (addresses[3] == address(0)) {
                if (toAdminAmount > 0)
                    ISpecialPool(payable(addresses[0])).sendETH(
                        toAdminAmount,
                        addresses[1]
                    );
                ISpecialPool(payable(addresses[0])).sendETH(
                    amounts[0]*(100 - amounts[1])/100,
                    addresses[2]
                );
            } else {
                if (toAdminAmount > 0)
                    ISpecialPool(payable(addresses[0])).sendToken(
                        addresses[3],
                        toAdminAmount,
                        addresses[1]
                    );
                ISpecialPool(payable(addresses[0])).sendToken(
                    addresses[3],
                    amounts[0]*(100 - amounts[1])/100,
                    addresses[2]
                );
            }

            toAdminAmount = projectToken
                .balanceOf(addresses[0])
                *(amounts[2])
                /(100 + amounts[2]);
            if (toAdminAmount > 0)
                ISpecialPool(payable(addresses[0])).sendToken(
                    poolInformation.projectTokenAddress,
                    toAdminAmount,
                    addresses[1]
                );

            uint256 rest = amounts[0]*poolInformation.specialSaleRate/(
                10**amounts[3]
            );

            rest = projectToken.balanceOf(addresses[0])-rest;
            if (rest > 0)
                ISpecialPool(payable(addresses[0])).sendToken(
                    poolInformation.projectTokenAddress,
                    rest,
                    addresses[2]
                );
        } else {
            if (addresses[3] == address(0)) {
                ISpecialPool(payable(addresses[0])).sendETH(
                    amounts[0],
                    addresses[2]
                );
            } else
                ISpecialPool(payable(addresses[0])).sendToken(
                    addresses[3],
                    amounts[0],
                    addresses[2]
                );
        }

        poolInformation.status = ISpecialPool.PoolStatus.Collected;
    }

    function refund(
        address _pool,
        uint256 _weiRaised,
        mapping(address => bool) storage _didRefund,
        mapping(address => uint256) storage collaborations,
        ISpecialPool.PoolModel storage poolInformation,
        address fundRaiseToken
    ) external {
        SpecialValidatePoolLibrary._poolIsCancelled(
            poolInformation,
            _weiRaised
        );
        if (_didRefund[msg.sender] != true && collaborations[msg.sender] > 0) {
            _didRefund[msg.sender] = true;
            if (fundRaiseToken == address(0))
                ISpecialPool(payable(_pool)).sendETH(
                    collaborations[msg.sender],
                    msg.sender
                );
            else
                ISpecialPool(payable(_pool)).sendToken(
                    fundRaiseToken,
                    collaborations[msg.sender],
                    msg.sender
                );
        }
    }

    function allowClaim(
        address[3] calldata addresses,
        uint256[2] calldata amount,
        ISpecialPool.PoolModel storage poolInformation,
        bool _isAdminSale,
        uint256 allowDateTime
    ) external {
        if (_isAdminSale) {
            IERC20 projectToken = IERC20(poolInformation.projectTokenAddress);
            uint256 totalToken = projectToken.balanceOf(addresses[0]);
            ISpecialPool(payable(addresses[0])).sendToken(
                poolInformation.projectTokenAddress,
                totalToken,
                addresses[0]
            );
            require(
                projectToken.balanceOf(addresses[0]) == totalToken,
                "remove tax"
            );

            uint256 rest = amount[0]*poolInformation.specialSaleRate/(
                10**amount[1]
            );

            rest = projectToken.balanceOf(addresses[0])-rest;
            if (rest > 0)
                ISpecialPool(payable(addresses[0])).sendToken(
                    poolInformation.projectTokenAddress,
                    rest,
                    addresses[1]
                );
        }
        SpecialValidatePoolLibrary._poolIsReadyAllow(poolInformation, allowDateTime);
        poolInformation.status = ISpecialPool.PoolStatus.Allowed;
    }
    function emergencyWithdraw(
        address _pool,
        address treasury,
        mapping(address => uint256) storage _weiRaised,
        mapping(address => uint256) storage collaborations,
        address[] storage participantsAddress,
        ISpecialPool.PoolModel storage poolInformation,
        address fundRaiseToken
    ) external returns (bool) {
        SpecialValidatePoolLibrary._poolIsOngoing(poolInformation);
        require(
            _weiRaised[_pool] < poolInformation.hardCap &&
                poolInformation.endDateTime >= block.timestamp + 1 hours,
            "sale finished"
        );
        if (collaborations[msg.sender] > 0) {
            _weiRaised[_pool] = _weiRaised[_pool]-collaborations[msg.sender];

            uint256 withdrawAmount = collaborations[msg.sender]*9/10;
            uint256 feeAmount = collaborations[msg.sender] - withdrawAmount;
            if (fundRaiseToken == address(0)) {
                ISpecialPool(payable(_pool)).sendETH(withdrawAmount, msg.sender);
                ISpecialPool(payable(_pool)).sendETH(feeAmount, treasury);
            } else {
                ISpecialPool(payable(_pool)).sendToken(
                    fundRaiseToken,
                    withdrawAmount,
                    msg.sender
                );
                ISpecialPool(payable(_pool)).sendToken(
                    fundRaiseToken,
                    feeAmount,
                    treasury
                );
            }

            for (uint256 i = 0; i < participantsAddress.length - 1; i++) {
                if (participantsAddress[i] == msg.sender) {
                    for (
                        uint256 k = i;
                        k < participantsAddress.length - 1;
                        k++
                    ) {
                        participantsAddress[k] = participantsAddress[k + 1];
                    }
                    break;
                }
            }
            participantsAddress.pop();
            collaborations[msg.sender] = 0;
            return true;
        }
        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISpecialPool.sol";
import "./SpecialPool.sol";
import "./SpecialValidatePoolLibrary.sol";

library SpecialDeployPoolLibrary {

    function deployPool() external returns (address poolAddress) {
        bytes memory bytecode = type(SpecialPool).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, address(this), block.number)
        );
        assembly {
            poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        return poolAddress;
    }

    function initPool(
        address poolAddress,
        address admin,
        ISpecialPool.PoolModel calldata poolInformation,
        uint256 poolTokenPercentFee,
        uint256 fundRaiseTokenDecimals
    ) external {
        IERC20 projectToken = IERC20(poolInformation.projectTokenAddress);
        uint256 totalTokenAmount = poolInformation
            .hardCap*poolInformation.specialSaleRate/(10**fundRaiseTokenDecimals);
        totalTokenAmount = totalTokenAmount+totalTokenAmount*poolTokenPercentFee/100;
        require(
            totalTokenAmount <= projectToken.balanceOf(msg.sender),
            "insufficient funds for transfer"
        );
        projectToken.transferFrom(msg.sender, poolAddress, totalTokenAmount);
        uint256 restToken = totalTokenAmount-(
            projectToken.balanceOf(poolAddress)
        );
        if (restToken > 0) {
            restToken = restToken*(totalTokenAmount)/(
                projectToken.balanceOf(poolAddress)
            );
            require(
                restToken <= projectToken.balanceOf(msg.sender),
                "insufficient funds for transfer"
            );
            projectToken.transferFrom(msg.sender, poolAddress, restToken);
        }
        if (msg.value > 0) {
            (bool sent, ) = payable(admin).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
    }

    function fillAdminPool(
        address poolAddress,
        ISpecialPool.PoolModel storage poolInformation,
        uint256 decimals,
        uint256 _weiRaised,
        uint256 fundRaiseTokenDecimals
    ) external {
        SpecialValidatePoolLibrary._poolIsFillable(poolInformation, _weiRaised);
        IERC20 projectToken = IERC20(poolInformation.projectTokenAddress);
        uint256 _balance = projectToken.balanceOf(poolAddress);
        poolInformation.specialSaleRate = poolInformation
            .specialSaleRate*(10**decimals)/(10**18);
        uint256 totalTokenAmount;
        if (
            poolInformation.status == ISpecialPool.PoolStatus.Collected ||
            (poolInformation.endDateTime <= block.timestamp &&
                poolInformation.status == ISpecialPool.PoolStatus.Inprogress &&
                poolInformation.softCap <= _weiRaised)
        ) {
            totalTokenAmount = _weiRaised*(poolInformation.specialSaleRate)/(10**fundRaiseTokenDecimals);
        } else {
            totalTokenAmount = poolInformation
                .hardCap*(poolInformation.specialSaleRate)/(10**fundRaiseTokenDecimals);
        }
        uint256 amountNeeded = totalTokenAmount-_balance;
        require(amountNeeded > 0, "already filled");
        require(
            amountNeeded <= projectToken.balanceOf(msg.sender),
            "insufficient funds for transfer"
        );
        projectToken.transferFrom(msg.sender, poolAddress, amountNeeded);
        uint256 restToken = totalTokenAmount-projectToken.balanceOf(poolAddress);
        if (restToken > 0) {
            restToken = restToken*(amountNeeded)/(
                projectToken.balanceOf(poolAddress)-(
                    totalTokenAmount-amountNeeded
                )
            );
            require(
                restToken <= projectToken.balanceOf(msg.sender),
                "insufficient funds for transfer"
            );
            projectToken.transferFrom(msg.sender, poolAddress, restToken);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ISpecialPool.sol";
import "./SpecialValidatePoolLibrary.sol";
interface IIDO{
    function holdingNFTs(uint256) external view returns(address);
    function tiersForNFTs(uint256) external view returns(uint256);
    function tiersForAccounts(address) external view returns(uint256);
    function holdingToken() external view returns(address);
    function holdingStakedToken() external view returns(address);
    function holdingTokenAmount(uint256) external view returns(uint256);
    function holdingStakedTokenAmount(uint256) external view returns(uint256);
    function getAccountsAndNftsForTier() external view returns(address[] memory accounts, address[] memory nfts, uint256[] memory tiers);
}
library SpecialDepositPoolLibrary {

    function whitelistCheckForNFTAndAccount(
        uint256 isTier,
        bool isTieredWhitelist,
        uint256 startDateTime,
        IIDO ido
    ) external view returns(bool) {
        if(isTier<ido.tiersForAccounts(msg.sender) || (isTieredWhitelist && isTier==4 && isTier<=ido.tiersForAccounts(msg.sender) &&
        block.timestamp >= startDateTime + 10 minutes)){
            return true;
        }
        (, address[] memory nfts, uint256[] memory tiers)=ido.getAccountsAndNftsForTier();
        for(uint256 i=0;i<nfts.length;i++){
            if(IERC721(nfts[i]).balanceOf(msg.sender)>0 && (tiers[i]>isTier || (isTieredWhitelist &&
                isTier==4 && tiers[i]>=isTier &&
                block.timestamp >= startDateTime + 10 minutes
            ))){
                return true;
            }
        }
        return false;
    }

    function whitelistCheckForTokenHolders(
        address holdingToken,
        address holdingStakedToken,
        uint256[6] calldata amounts,
        bool isTieredWhitelist
    ) external view returns(bool) {
        if((holdingToken != address(0) &&
                        IERC20(holdingToken).balanceOf(msg.sender) >= amounts[0]) ||
                (holdingStakedToken != address(0) &&
                IERC20(holdingStakedToken).balanceOf(msg.sender) >= amounts[1])
        )
            return true;            
        else{
            if(isTieredWhitelist && amounts[4]==4 && block.timestamp >= amounts[5] + 10 minutes &&
                (
                    (holdingToken != address(0) &&
                            IERC20(holdingToken).balanceOf(msg.sender) >= amounts[2]) ||
                    (holdingStakedToken != address(0) &&
                    IERC20(holdingStakedToken).balanceOf(msg.sender) >= amounts[3])
            ))
                return true;
            else
                return false;
        }
        
    }

    function whitelistCheck(
        bool isTieredWhitelist,
        uint256 startDateTime,
        mapping(address => bool) storage whitelistedAddressesMap,
        mapping(address => bool) storage whitelistedAddressesMapForTiered
    ) external view {
        if (isTieredWhitelist) {
            require(
                    (block.timestamp >=
                        startDateTime + 10 minutes &&
                        (whitelistedAddressesMap[msg.sender] ||
                            whitelistedAddressesMapForTiered[msg.sender])) ||
                    whitelistedAddressesMapForTiered[msg.sender],
                "Not!"
            );
        } else
            require(
                    whitelistedAddressesMap[msg.sender],
                "Not!"
            );
    }

    function depositPool(
        address[2] calldata addresses,
        mapping(address => uint256) storage _weiRaised,
        ISpecialPool.PoolModel storage poolInformation,
        mapping(address => uint256) storage collaborations,
        mapping(address => address[]) storage participantsAddress,
        uint256 amounts
    ) external {
        SpecialValidatePoolLibrary._poolIsOngoing(poolInformation);
        require(
            (addresses[1] != address(0) && amounts > 0) || msg.value > 0,
            "No WEI found!"
        );

        SpecialValidatePoolLibrary._minAllocationNotPassed(
            poolInformation.minAllocationPerUser,
            _weiRaised[addresses[0]],
            poolInformation.hardCap,
            collaborations[msg.sender],
            addresses[1],
            amounts
        );
        SpecialValidatePoolLibrary._maxAllocationNotPassed(
            poolInformation.maxAllocationPerUser,
            collaborations[msg.sender],
            addresses[1],
            amounts
        );
        SpecialValidatePoolLibrary._hardCapNotPassed(
            poolInformation.hardCap,
            _weiRaised[addresses[0]],
            addresses[1],
            amounts
        );
        if (collaborations[msg.sender] <= 0)
            participantsAddress[addresses[0]].push(msg.sender);
        if (addresses[1] == address(0)) {
            _weiRaised[addresses[0]] = _weiRaised[addresses[0]] + msg.value;
            collaborations[msg.sender] = collaborations[msg.sender] + msg.value;
            (bool sent, ) = payable(addresses[0]).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        } else {
            _weiRaised[addresses[0]] = _weiRaised[addresses[0]] + amounts;
            collaborations[msg.sender] = collaborations[msg.sender] + amounts;
            IERC20 _token = IERC20(addresses[1]);
            _token.transferFrom(msg.sender, addresses[0], amounts);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISpecialPool { 
  enum PoolStatus {
    Inprogress,    
    Cancelled,
    Collected,
    Allowed 
  }
  enum PoolTier {
    Nothing,
    Gold,
    Platinum,
    Diamond,
    Alpha
  }
  struct PoolModel {
    uint256 hardCap; // how much project wants to raise
    uint256 softCap; // how much of the raise will be accepted as successful IDO
    uint256 specialSaleRate;
    address projectTokenAddress; //the address of the token that project is offering in return   
    PoolStatus status; //: by default “Upcoming”,
    uint256 startDateTime;
    uint256 endDateTime;
    uint256 minAllocationPerUser;
    uint256 maxAllocationPerUser;   
  }

  struct PoolDetails {     
    string extraData;
    bool whitelistable;
    bool audit;
    string auditLink;
    PoolTier tier;
    bool kyc;
  }

  struct UserVesting{
    bool isVesting;
    uint256 firstPercent;
    uint256 eachPercent;
    uint256 eachPeriod;
  }
  function sendToken(address tokenAddress, uint256 amount, address recipient) external returns (bool);
  function sendETH(uint256 amount, address recipient) external returns (bool);
  receive() external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISpecialPool.sol";

library SpecialValidatePoolLibrary {
    function _preValidatePoolCreation(
        ISpecialPool.PoolModel memory _pool,
        bool _isAdminSale,
        uint256 _allowDateTime
    ) public view {
        require(_pool.hardCap > 0, "hardCap > 0");
        require(_pool.softCap > 0, "softCap > 0");
        require(_pool.softCap < _pool.hardCap, "softCap < hardCap");
        require(
            _pool.softCap >= (_pool.hardCap * 3) / 10,
            "softCap > hardCap*30%"
        );

        require(
            _isAdminSale || address(_pool.projectTokenAddress) != address(0),
            "token is a zero address!"
        );
        require(_pool.specialSaleRate > 0, "specialSaleRate > 0!");
        require(
            _pool.startDateTime >= block.timestamp,
            "startDate fail!"
        );

        require(
            _pool.startDateTime + 1 days <= _pool.endDateTime,
            "start<end!"
        );
        require(_allowDateTime >= _pool.endDateTime, "allow>=end!");
        require(_pool.minAllocationPerUser > 0, "min>0");
        require(
            _pool.minAllocationPerUser <= _pool.maxAllocationPerUser,
            "min<max"
        );
    }

    function _preValidateUserVesting(
        ISpecialPool.UserVesting memory _vesting,
        uint256 _cliff
    ) public pure {
        require(
            !_vesting.isVesting || _vesting.firstPercent > 0,
            "user firstPercent > 0"
        );
        require(
            !_vesting.isVesting || _vesting.eachPeriod >= 1,
            "user period >= 1"
        );
        require(
            !_vesting.isVesting ||
                _vesting.firstPercent + _vesting.eachPercent <= 100,
            "user firstPercent + eachPercent <= 100"
        );
        require(_cliff >= 0 && _cliff <= 365, "0<=cliff<=365");
    }

    function _poolIsOngoing(ISpecialPool.PoolModel memory poolInformation)
        public
        view
    {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            poolInformation.startDateTime <= block.timestamp,
            "not started!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(poolInformation.endDateTime >= block.timestamp, "ended!");
    }

    function _poolIsUpcoming(ISpecialPool.PoolModel memory poolInformation)
        public
        view
    {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(poolInformation.endDateTime > block.timestamp, "ended!");
    }

    function _poolIsFillable(
        ISpecialPool.PoolModel memory poolInformation,
        uint256 _weiRaised
    ) public view {
        require(
            poolInformation.status == ISpecialPool.PoolStatus.Inprogress ||
                poolInformation.status == ISpecialPool.PoolStatus.Collected,
            "not available!"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            poolInformation.endDateTime >= block.timestamp ||
                poolInformation.softCap <= _weiRaised,
            "started!"
        );
    }

    function _poolIsNotCancelled(ISpecialPool.PoolModel memory _pool)
        public
        pure
    {
        require(
            _pool.status == ISpecialPool.PoolStatus.Inprogress,
            "already cancelled!"
        );
    }

    function _poolIsCancelled(
        ISpecialPool.PoolModel memory _pool,
        uint256 _weiRaised
    ) public view {
        require(
            _pool.status == ISpecialPool.PoolStatus.Cancelled ||
                (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.endDateTime <= block.timestamp &&
                    _pool.softCap > _weiRaised),
            "not cancelled!"
        );
    }

    function _poolIsReadyCollect(
        ISpecialPool.PoolModel memory _pool,
        uint256 _weiRaised,
        address poolAddress,
        address fundRaiseToken,
        bool _isAdminSale
    ) public view {
        if (!_isAdminSale) {
            require(
                (_pool.endDateTime <= block.timestamp &&
                    _pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.softCap <= _weiRaised) ||
                    (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                        _pool.hardCap == _weiRaised &&
                        _pool.startDateTime + 24 hours <= block.timestamp),
                "not finalized!"
            );
        } else {
            require(
                (_pool.endDateTime <= block.timestamp &&
                    _pool.status == ISpecialPool.PoolStatus.Inprogress &&
                    _pool.softCap <= _weiRaised) ||
                    (_pool.status == ISpecialPool.PoolStatus.Inprogress &&
                        _pool.hardCap == _weiRaised),
                "not finalized!"
            );
        }

        if (fundRaiseToken == address(0))
            require(payable(poolAddress).balance > 0, "collected!");
        else {
            IERC20 _token = IERC20(fundRaiseToken);
            require(_token.balanceOf(poolAddress) > 0, "collected!");
        }
    }

    function _poolIsReadyAllow(
        ISpecialPool.PoolModel memory _pool,
        uint256 allowDateTime
    ) public view {
        require(
            _pool.status == ISpecialPool.PoolStatus.Collected &&
                allowDateTime <= block.timestamp,
            "not finalized!"
        );
    }

    function _poolIsAllowed(ISpecialPool.PoolModel memory _pool) public pure {
        require(
            _pool.status == ISpecialPool.PoolStatus.Allowed,
            "not allowed!"
        );
    }

    function _hardCapNotPassed(
        uint256 _hardCap,
        uint256 _weiRaised,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 _beforeBalance = _weiRaised;
        uint256 sum;
        if (fundRaiseToken == address(0)) {
            sum = _weiRaised + msg.value;
        } else {
            sum = _weiRaised + amount;
        }
        require(sum <= _hardCap, "hardCap!");
        require(sum > _beforeBalance, "hardCap overflow!");
    }

    function _minAllocationNotPassed(
        uint256 _minAllocationPerUser,
        uint256 _weiRaised,
        uint256 hardCap,
        uint256 collaboration,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 aa;
        if (fundRaiseToken == address(0)) {
            aa = collaboration + msg.value;
        } else {
            aa = collaboration + amount;
        }

        require(
            hardCap - _weiRaised < _minAllocationPerUser ||
                _minAllocationPerUser <= aa,
            "Less!"
        );
    }

    function _maxAllocationNotPassed(
        uint256 _maxAllocationPerUser,
        uint256 collaboration,
        address fundRaiseToken,
        uint256 amount
    ) public view {
        uint256 aa;
        if (fundRaiseToken == address(0)) {
            aa = collaboration + msg.value;
        } else {
            aa = collaboration + amount;
        }
        require(aa <= _maxAllocationPerUser, "More!");
    }

    function _onlyFactory(address sender, address factory) public pure {
        require(factory == sender, "Not factory!");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SpecialSaleExtra is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Badges{
        bool vetted;
        string vettedLink;    
        bool kycPlus;
        string kycPlusLink;  
    }
    mapping(address => Badges) public badges;
    event LogPoolVettedUpdate(address indexed pool, bool vetted, string vettedLink);
    event LogPoolKYCPlusUpdate(address indexed pool, bool kycPlus, string kycPlusLink);

    function initialize(
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function updateVettedStatus(address _pool, string memory _vettedLink) external onlyOwner {
        badges[_pool].vetted = !badges[_pool].vetted;
        badges[_pool].vettedLink = _vettedLink;
        emit LogPoolVettedUpdate(_pool, badges[_pool].vetted, _vettedLink);
    }
    function updateKYCPlusStatus(address _pool, string memory _kycPlusLink) external onlyOwner {
        badges[_pool].kycPlus = !badges[_pool].kycPlus;
        badges[_pool].kycPlusLink = _kycPlusLink;
        emit LogPoolKYCPlusUpdate(_pool, badges[_pool].kycPlus, _kycPlusLink);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISpecialPool.sol";
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
contract SpecialPool is ISpecialPool {
  address private factory; 
  constructor() {
    factory = msg.sender;

  }

  function sendToken(address tokenAddress, uint256 amount, address recipient) external override returns (bool){
    require(
      msg.sender == factory,
      "Not factory!"
    );
    IERC20 projectToken = IERC20(tokenAddress);
    if(projectToken.balanceOf(address(this))>=amount){
      projectToken.transfer(recipient, amount);
      return true;
    }else
      return false;
      
  }
  function sendETH(uint256 amount, address recipient) external override returns (bool){
    require(
      msg.sender == factory,
      "Not factory!"
    );
    if(amount>0){
      (bool sent,) = payable(recipient).call{value:amount}("");
      require(sent, "Failed to send Ether");
    }
    return true;
  }


  receive() external payable {
    require(
      msg.sender == factory,
      "Not factory!"
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}