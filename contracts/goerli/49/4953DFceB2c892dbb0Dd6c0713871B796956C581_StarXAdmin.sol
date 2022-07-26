// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IRequest.sol";
import "./StarXManaged.sol";
import "./financial-security-asset/StarXCelebrity.sol";


/// @title StarXAdmin
/// @notice A gatekeeper and permissioned caller for:
/// @notice (1) deploying StarXCelebrity contracts
/// @notice (2) deploying StarXFinancialSecurityAsset contracts through calling a given StarXCelebrity contract
/// @notice (3) minting new tokens of a StarXFinancialSecurityAsset through calling a given StarXCelebrity contract
/// @dev Inherits from `StarXManaged`
contract StarXAdmin is StarXManaged {


    //---- v1 - events - start ----

    /// @notice Event emitted on deployment of contract = StarXCelebrity
    /// @param celebWallet the address of the celebrity wallet for which the StarXCelebrity is created
    /// @param newCelebContract the address of the newly-created StarXCelebrity contract
    /// @dev emitted at the conclusion of call to function: `StarXAdmin::deployNewCelebContract`
    event NewCelebContractDeployed(
        address indexed celebWallet,
        address indexed newCelebContract
    );

    /// @notice Event emitted on deployment of a new StarXFinancialSecurityAsset contract through a call to a given StarXCelebrity contract
    /// @dev emitted at the conclusion of call to function: `StarXAdmin::deployNewAssetContractForCelebContract`
    event NewCelebAssetContractDeployed(
        address indexed celebContract,
        address indexed celebAssetContract,
        string requestedAssetName,
        string requestedAssetSymbol,
        string requestedAssetDescription,
        address starXCustodyWallet,
        IRequest.DeployAssetResult deploymentResult
    );

    /// @notice Event emitted when a new token is minted from a StarXFinancialSecurityAsset contract via a call through a StarXCelebrity contract
    /// @dev emitted at the conclusion of call to function: `StarXAdmin::mintNewSecurityForCelebAndAssetContract`
    event NewTokenForCelebAssetContract(
        address indexed celebContract,
        address indexed celebAssetContract,
        uint256 indexed newTokenId,
        uint256 tokenInitialPrice,
        uint256 tokenSupply,
        IRequest.AssetType tokenAssetType,
        address tokenCreator,
        uint16 tokenHolderRoyaltyBps,
        string tokenInvestmentContractUri
    );

    // TODO: dev doc
    event CelebAssetContractDisabled(
        address indexed celebContract,
        address indexed celebAssetContract
    );

    //---- v1 - events - finish ----

    //---- v1 - methods - start ----

    /// @notice Contract initializer
    function initialize() public initializer {
        __Ownable_init();
    }

    /// @notice Deploys StarXCelebrity for specified wallet
    /// @dev Only callable by permissioned accounts in `StarXManaged::managers`
    /// @dev Permissioned call of StarXCelebrity constructor
    /// @param _celebWallet address of wallet belonging to the celebrity for whom this contract is deployed
    /// @param _starXAddressRegistry address of StarXAddress registry contract at deployment.  An argument to the constructor of StarXCelebrity
    function deployNewCelebContract(
        address _celebWallet,
        address _starXAddressRegistry
    ) external starXOnly returns (address) {
        // check: valid celeb wallet
        require(_celebWallet != address(0), "bad arg: _celebWallet");
        // check: valid address for StarXAddressRegistry
        require(
            _starXAddressRegistry != address(0),
            "bad arg: _starXAddressRegistry"
        );
        // effect: init new contract
        StarXCelebrity celeb = new StarXCelebrity(
            _celebWallet,
            _starXAddressRegistry
        );

        // emit event
        emit NewCelebContractDeployed(_celebWallet, address(celeb));

        // return
        return address(celeb);
    }

    /// @notice Deploys StarXFinancialSecurityAsset contract for specified StarXCelebrity contract
    /// @dev Only callable by permissioned accounts in `StarXManaged::managers`
    /// @dev Permissioned call of `StarXCelebrity::deployFinancialSecurityAssetContract`
    /// @param _celebrityContractAddress address of StarXCelebrity for which we will deploy a StarXFinancialSecurityAsset contract
    /// @param _req IRequest.DeployAssetContractRequest arguments which define the state of StarXFinancialSecurityAsset contract
    function deployNewAssetContractForCelebContract(
        address _celebrityContractAddress,
        IRequest.DeployAssetContractRequest calldata _req
    )
        public
        starXOnly
        returns (
            IRequest.DeployAssetResult deployAssetResult,
            address assetContractAddress
        )
    {
        // check: valid custody wallet
        require(_req.custodyWallet != address(0), "bad arg: custody wallet");
        // effect: deploy new asset contract for specified celebrity contract
        (deployAssetResult, assetContractAddress) = IStarXCelebrity(
            _celebrityContractAddress
        ).deployFinancialSecurityAssetContract(_req);

        // emit event to indicate outcome
        emit NewCelebAssetContractDeployed(
            _celebrityContractAddress,
            assetContractAddress,
            _req.assetName,
            _req.assetSymbol,
            _req.assetDescription,
            _req.custodyWallet,
            deployAssetResult
        );
    }

    /// @notice Mints ERC-1155 token for specified StarXCelebrity and StarXFinancialSecurityAsset contract
    /// @dev Only callable by permissioned accounts in `StarXManaged::managers`
    /// @dev Permissioned call of `StarXCelebrity::mintNewSecurity`
    /// @param _celebContract address of StarXCelebrity
    /// @param _celebAssetContract address of StarXFinancialSecurityAsset that exists within _celebContract
    /// @param _req IRequest.ListAssetRequest arguments which define the attributes of the token to be minted
    function mintNewSecurityForCelebAndAssetContract(
        address _celebContract,
        address _celebAssetContract,
        IRequest.ListAssetRequest calldata _req
    ) public starXOnly returns (uint256 newTokenId) {
        // effect: do mint
        newTokenId = IStarXCelebrity(_celebContract).mintNewSecurity(
            _celebAssetContract,
            _req
        );
        // emit event
        emit NewTokenForCelebAssetContract(
            _celebContract,
            _celebAssetContract,
            newTokenId,
            _req.initialOfferingPrice,
            _req.supply,
            _req.assetType,
            _req.creator,
            _req.holderRoyaltyBps,
            _req.investmentContractUri
        );
    }

    /// @notice Deploys StarXFinancialSecurityAsset contract for specified StarXCelebrity contract and mints its first token within a single call
    /// @dev Only callable by permissioned accounts in `StarXManaged::managers`
    /// @dev Sequenced call of `StarXAdmin::deployNewAssetContractForCelebContract` and `StarXAdmin::mintNewSecurityForCelebAndAssetContract`
    /// @param _celebContract address of StarXCelebrity
    /// @param _deployReq IRequest.DeployAssetContractRequest arguments which define the state of StarXFinancialSecurityAsset contract
    /// @param _mintReq IRequest.ListAssetRequest arguments which define the attributes of the token to be minted
    function deployAssetAndMintFirstToken(
        address _celebContract,
        IRequest.DeployAssetContractRequest calldata _deployReq,
        IRequest.ListAssetRequest calldata _mintReq
    ) external starXOnly {
        // effect: DEPLOY and obtain new asset contract address
        (
            IRequest.DeployAssetResult deployAssetResult,
            address newAssetContractAddress
        ) = deployNewAssetContractForCelebContract(_celebContract, _deployReq);

        // check: can only proceed to minting if deployment succeeded
        require(
            deployAssetResult == IRequest.DeployAssetResult.Success,
            "asset deployment failed"
        );

        // effect: MINT
        mintNewSecurityForCelebAndAssetContract(
            _celebContract,
            newAssetContractAddress,
            _mintReq
        );
    }

    // TODO: fn doc
    function updateStarXAddressRegistryForCelebrityContract(
        address _celebContract,
        address _newStarXAddressRegistry
    ) external starXOnly {
        // effect: update address for contract = StarXAddressRegistry
        IStarXCelebrity(_celebContract).updateStarXAddressRegistry(
            _newStarXAddressRegistry
        );
    }

    // TODO: fn doc
    function updateCustodyWalletForCelebrityContractAndAsset(
        address _celebContract,
        address _assetContract,
        address _newWallet
    ) external starXOnly {
        // effect: update custody wallet of specified StarXCelebrity
        IStarXCelebrity(_celebContract).updateCustodyWalletForAsset(
            _assetContract,
            _newWallet
        );
    }

    // TODO: fn doc
    function updateListingStatusForCelebrityAsset(
        address _celebContract,
        address _assetContract,
        uint256 _tokenId,
        bool _newStatus
    ) external starXOnly {
        // effect: update custody wallet of specified StarXCelebrity
        IStarXCelebrity(_celebContract).updateListingStatusForAsset(
            _assetContract,
            _tokenId,
            _newStatus
        );
    }

    // TODO: dev doc
    function disableCelebrityAsset(
        address _celebContract,
        address _assetContract
    ) external starXOnly {
        // effect: disable specified asset contract of specified celeb contract
        IStarXCelebrity(_celebContract).disableAssetContract(_assetContract);

        // emit event
        emit CelebAssetContractDisabled(_celebContract, _assetContract);
    }

    //---- v1 - methods - finish ----
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

pragma solidity ^0.8.4;

interface IRequest {

    /// @notice The basic attributes which define a StarXFinancialSecurityAsset deployment request
    /// @dev Argument for function `StarXAdmin::deployNewAssetContractForCelebContract`
    /// @dev Argument for function `StarXAdmin::deployAssetAndMintFirstToken`
    struct DeployAssetContractRequest {
        string assetName;
        string assetSymbol;
        string assetDescription;
        address custodyWallet;
    }
    /// @notice The result of the aforementioned StarXFinancialSecurityAsset deployment request
    /// @dev If result is Success, then a new asset contract is deployed
    /// @dev If result is DuplicatedAssetName, then there already exists an asset contract deployed by this StarXCelebrity contract with that name
    /// @dev If result is DuplicatedAssetSymbol, then there already exists an asset contract deployed by this StarXCelebrity contract with that symbol
    /// @dev If result is Fail, then something else went wrong and additional investigation is required
    enum DeployAssetResult {
        Success,
        DuplicatedAssetName,
        DuplicatedAssetSymbol,
        Fail
    }

    /// @notice When an asset is listed by a StarXFinancialSecurityAsset (i.e. a new token minted), this enum defines the possible types of that asset
    enum AssetType {
        None,
        Equity,
        Debt,
        Nft
    }
    /// @notice The basic attributes which define a token/asset listing request from a StarXFinancialSecurityAsset contract
    /// @dev Argument to function `StarXAdmin::mintNewSecurityForCelebAndAssetContract`
    /// @dev Argument to function `StarXAdmin::deployAssetAndMintFirstToken`
    struct ListAssetRequest {
        uint256 initialOfferingPrice;
        uint256 supply;
        AssetType assetType;
        address creator;
        uint16 holderRoyaltyBps;
        string investmentContractUri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/// @title StarXManaged
/// @notice Owner of this contract can define a range of addresses known as "managers".
/// @dev Any contract which inherits `StarXManaged` can apply the modifier `starXOnly` to its member functions so that they are only callable by permissioned "managers"
/// @dev Inherited by `StarXAdmin`
abstract contract StarXManaged is OwnableUpgradeable {

    mapping (address => bool) public managers;

    /// @dev Allows execution by managers only
    modifier starXOnly {
        require(managers[msg.sender], "StarX only");
        _;
    }

    /// @notice Either add a new manager or de-permission a pre-existing manager
    /// @dev only callable by the owner of this contract
    /// @param manager address The address to either be added or removed
    /// @param state bool If `true`/`false` indicates StarX permissions enabled/disabled for specified address
    function setManager(address manager, bool state) public onlyOwner {
        managers[manager] = state;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../interfaces/IRequest.sol";

import "./StarXFinancialSecurityAsset.sol";
import "./IStarXAddressRegistry.sol";
import "./IStarXCelebrity.sol";

/// @title StarXCelebrity
/// @notice An on-chain artifact representing the unique identity of a celebrity or a celebrity’s business (the “entity”) in order to properly issue yield bearing securities on the StarX platform
/// @dev Contract is uniquely owned by the celebrity's wallet and ownership cannot be transferred from that wallet
/// @dev State-changing functions are only callable by StarXAdmin
/// @dev Inherits from IStarXCelebrity
contract StarXCelebrity is IStarXCelebrity {
    /// @notice On change indicates previous and new value of internal record of contract StarXAddressRegistry
    event UpdateStarXAddressRegistry(
        address oldStarXAddressRegistry,
        address newStarXAddressRegistry
    );

    //---------------------------------- v1 - member vars - start ------------------------------------

    /// @notice Indicates the wallet of the celebrity which owns this contract
    address private m_owningCelebWallet;

    /// @notice The canoncial address of StarXAddressRegistry.  Uses this contract to determine if a caller is a StarXAdmin
    address private m_starXAddressRegistry;

    /// @notice The number of instances of StarXFinancialSecurityAsset deployed from this contract
    uint256 private m_deployedAssetCount;

    /// @notice Instance or 1-based index => address of StarXFinancialSecurityAsset contract deployed from this contract
    mapping(uint256 => address) private m_assetLookup;

    /// @notice Address of StarXFinancialSecurityAsset contract deployed from this contract => instance or 1-based index
    mapping(address => uint256) private m_assetLookupRev;

    /// @notice Mapping of NAME of an asset contract deployed by this celebrity contract TO the address of that asset contract
    /// @dev NAME is hashed to bytes32 for storage/gas efficiency
    mapping(bytes32 => address) private m_nameHashedToAssetAddress;

    /// @notice Mapping of SYMBOL of an asset contract deployed by this celebrity contract TO the address of that asset contract
    /// @dev SYMBOL is hashed to bytes32 for storage/gas efficiency
    mapping(bytes32 => address) private m_symbolHashedToAssetAddress;

    bytes4 constant INTERFACE_ID_IStarXCelebrity =
        type(IStarXCelebrity).interfaceId;

    //---------------------------------- v1 - member vars - finish ------------------------------------

    //---------------------------------- v1 - modifiers - start ------------------------------------

    // TODO: get revert message lengths under 32 (gas efficiency)

    /// @notice Restrict function caller to a permissioned StarX admin only
    /// @dev Permissioned admins are looked up via StarXAddressRegistry
    modifier modOnlyAdmin() {
        require(
            IStarXAddressRegistry(m_starXAddressRegistry).adminNftContracts(
                _msgSender()
            ),
            "[Celeb] Caller not StarXAdmin"
        );
        _;
    }

    /// @notice Checks that specified asset contract was deployed by this celebrity contract
    modifier modAssetContractExists(address _assetContract) {
        require(
            m_assetLookupRev[_assetContract] > 0,
            "[Celeb] DNE asset contract"
        );
        _;
    }

    //---------------------------------- v1 - modifiers - finish ------------------------------------

    //---------------------------------- v1 - functions - start ------------------------------------

    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @param _entityAddress The EOA or wallet belonging to the entity which deploys this contract
    /// @param _contractStarXAddressRegistry The canonical StarXAddressRegistry at the time this contract is deployed
    constructor(address _entityAddress, address _contractStarXAddressRegistry) {
        // check: valid addresses
        require(
            _entityAddress != address(0),
            "[StarXCelebrity] invalid ctor arg: _entityAddress"
        );
        require(
            _contractStarXAddressRegistry != address(0),
            "[StarXCelebrity] invalid ctor arg: _contractStarXAddressRegistry"
        );
        // check: ctor of this contract can only be called by StarXAdmin
        {
            require(
                IStarXAddressRegistry(_contractStarXAddressRegistry)
                    .adminNftContracts(_msgSender()),
                "[StarXCelebrity] ctor only callable by registered StarXAdmin"
            );
        }

        // transfer ownership of this contract to specified "entity"
        m_owningCelebWallet = _entityAddress;

        // set starting address of contract = StarXAddressRegistry
        m_starXAddressRegistry = _contractStarXAddressRegistry;

        // emit event(s)
        emit UpdateStarXAddressRegistry(address(0), m_starXAddressRegistry);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function getInterfaceId() external pure returns (bytes4) {
        return INTERFACE_ID_IStarXCelebrity;
    }

    /// @notice Gets the celeb wallet which owns this contract
    /// @dev Defined at construction of celebrity contract instance (and not changed thereafter)
    function getOwningCelebWallet() external view returns (address) {
        return m_owningCelebWallet;
    }

    /// @notice Get the canonical instance of contract StarXAddressRegistry
    function getStarXAddressRegistry()
        external
        view
        virtual
        override
        returns (address)
    {
        return m_starXAddressRegistry;
    }

    /// @notice Updates this contract's record of StarXAddressRegistry to a new address
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @param _newAddress The new address of StarXAddressRegistry contract
    function updateStarXAddressRegistry(address _newAddress)
        external
        virtual
        override
        modOnlyAdmin
    {
        require(_newAddress != address(0), "AddressRegistry arg invalid");
        // emit event
        emit UpdateStarXAddressRegistry(m_starXAddressRegistry, _newAddress);
        // update
        m_starXAddressRegistry = _newAddress;
    }

    /// @notice Get the number of StarXFinancialSecurityAsset contracts deployed by this contract
    function getAssetCount() external view returns (uint256) {
        return m_deployedAssetCount;
    }

    /// @notice Get the StarXFinancialSecurityAsset contract (deployed by this contract) by its 1-based index (i.e. it's order of deployment relative to other asset contracts)
    /// @dev It is assumed that _index > 0.  Calling with _index = 0 yields a return value of address(0)
    /// @dev Returns address(0) should the specified index not exist within the mapping
    /// @param _index 1-based index of target asset contract
    function getAssetAddressAtIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return m_assetLookup[_index];
    }

    function _hashAssetStringAttribute(string memory _attribute)
        private
        pure
        returns (bytes32)
    {
        require(bytes(_attribute).length > 0, "_attribute is empty");
        return keccak256(abi.encodePacked(_attribute));
    }

    //-------- v1 - overrides - start --------

    /// @notice Check that specified interface meets the definition of IStarXCelebrity
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_IStarXCelebrity;
    }

    /// @notice Deploys a new instance of StarXFinancialSecurityAsset with the specified parameters
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @dev Permissioned call to constructor of StarXFinancialSecurityAsset
    /// @param _req IRequest.DeployAssetContractRequest contains the parameters which define the state of the new StarXFinancialSecurityAsset instance
    /// @return address of newly-deployed StarXFinancialSecurityAsset contract
    function deployFinancialSecurityAssetContract(
        IRequest.DeployAssetContractRequest calldata _req
    )
        external
        virtual
        override
        modOnlyAdmin
        returns (IRequest.DeployAssetResult, address)
    {
        // check: valid custody wallet
        require(
            _req.custodyWallet != address(0),
            "Deploy with bad custody wallet"
        );

        // hash asset name/symbol for more efficient check of duplication and storage
        bytes32 hashedAssetName = _hashAssetStringAttribute(_req.assetName);
        bytes32 hashedAssetSymbol = _hashAssetStringAttribute(_req.assetSymbol);

        // check: ASSET NAME is not duplicated by pre-existing asset contract
        {
            address assetAddress = m_nameHashedToAssetAddress[hashedAssetName];
            if (assetAddress != address(0)) {
                // return the pre-existing address
                return (
                    IRequest.DeployAssetResult.DuplicatedAssetName,
                    assetAddress
                );
            }
        }
        // check: ASSET SYMBOL is not duplicated by pre-existing asset contract
        {
            address assetAddress = m_symbolHashedToAssetAddress[
                hashedAssetSymbol
            ];
            if (assetAddress != address(0)) {
                // return the pre-existing address
                return (
                    IRequest.DeployAssetResult.DuplicatedAssetSymbol,
                    assetAddress
                );
            }
        }

        // init new contract
        StarXFinancialSecurityAsset security = new StarXFinancialSecurityAsset(
            _req
        );
        address newAssetAddress = address(security);

        // increment count of deployed contracts
        m_deployedAssetCount++;

        // add newly-deployed contract to local lookup(s)
        m_assetLookup[m_deployedAssetCount] = newAssetAddress;
        m_assetLookupRev[newAssetAddress] = m_deployedAssetCount;
        // store with respect to hashed asset name/symbol so that we can check for duplicates on subsequent deploy attempts
        m_nameHashedToAssetAddress[hashedAssetName] = newAssetAddress;
        m_symbolHashedToAssetAddress[hashedAssetSymbol] = newAssetAddress;

        // return result
        return (IRequest.DeployAssetResult.Success, newAssetAddress);
    }

    /// @notice Mint a new token for the specified instance of StarXFinancialSecurityAsset
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @dev Permissioned call to StarXFinancialSecurityAsset::listAsset
    /// @param _securityContract address of StarXFinancialSecurityAsset.  Must have been deployed by this contract
    /// @param _req IRequest.ListAssetRequest arguments which define the attributes of the token to be minted
    /// @return newTokenId of newly-minted token
    function mintNewSecurity(
        address _securityContract,
        IRequest.ListAssetRequest calldata _req
    )
        external
        virtual
        override
        modOnlyAdmin
        modAssetContractExists(_securityContract)
        returns (uint256 newTokenId)
    {
        // check: specified 1155 contract address belongs to this entity
        require(
            m_assetLookupRev[_securityContract] > 0,
            "Mint with bad asset contract"
        );

        // do mint
        newTokenId = StarXFinancialSecurityAsset(_securityContract).listAsset(
            _req
        );
    }

    /// @notice Update the current custody wallet for specified StarXFinancialSecurityAsset.  Next token minted from that contract will go to this wallet.
    /// @dev Call will revert if specified StarXFinancialSecurityAsset was not deployed by this contract
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @dev Permissioned call to StarXFinancialSecurityAsset::updateCurrentCustodyWallet
    /// @param _assetContract address of StarXFinancialSecurityAsset contract to be updated
    /// @param _newWallet address of the new StarX custody wallet for next-minted tokens
    function updateCustodyWalletForAsset(
        address _assetContract,
        address _newWallet
    )
        external
        virtual
        override
        modOnlyAdmin
        modAssetContractExists(_assetContract)
    {
        // TODO: should this be an interface instead?
        // effect: update custody wallet of asset
        StarXFinancialSecurityAsset(_assetContract).updateCurrentCustodyWallet(
            _newWallet
        );
    }

    /// @notice Update the listing status of specified token of specified StarXFinancialSecurityAsset contract to the specified new status
    /// @dev Call will revert if specified StarXFinancialSecurityAsset was not deployed by this contract
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @dev Permissioned call to StarXFinancialSecurityAsset::updateListingStatus
    /// @param _assetContract address of StarXFinancialSecurityAsset contract to be updated
    /// @param _tokenId of the specified StarXFinancialSecurityAsset contract to be updated
    /// @param _newStatus bool new value of `AssetInfo::isListed` for specified contract/token
    function updateListingStatusForAsset(
        address _assetContract,
        uint256 _tokenId,
        bool _newStatus
    )
        external
        virtual
        override
        modOnlyAdmin
        modAssetContractExists(_assetContract)
    {
        // check: valid asset address
        require(
            m_assetLookupRev[_assetContract] > 0,
            "Update cust. wallet - bad asset"
        );
        // effect: update listing status for that asset
        StarXFinancialSecurityAsset(_assetContract).updateListingStatus(
            _tokenId,
            _newStatus
        );
    }

    /// @notice Disable the asset contract.  In effect, marking it as deprecated and halting it from changing its state
    /// @notice This also frees the disabled asset contract's name and symbol for reuse
    /// @notice e.g. a celebrity wanting to recreate a deal with the same symbol AND/OR a different spelling of a name
    /// @dev Call will revert if specified StarXFinancialSecurityAsset was not deployed by this contract
    /// @dev Only callable via a StarXAdmin (as looked up by StarXAddressRegistry)
    /// @dev Permissioned call to StarXFinancialSecurityAsset::disableContract
    /// @param _assetContract `address` the target asset contract to be disabled
    function disableAssetContract(address _assetContract)
        external
        virtual
        override
        modOnlyAdmin
        modAssetContractExists(_assetContract)
    {
        // effect: remove the disabled asset name/symbol from tracked collection
        // get hashed value(s)
        bytes32 hashedAssetName = _hashAssetStringAttribute(
            StarXFinancialSecurityAsset(_assetContract).name()
        );
        bytes32 hashedAssetSymbol = _hashAssetStringAttribute(
            StarXFinancialSecurityAsset(_assetContract).symbol()
        );
        // and reset the mapping entries
        m_nameHashedToAssetAddress[hashedAssetName] = address(0);
        m_symbolHashedToAssetAddress[hashedAssetSymbol] = address(0);

        // effect: disable the specified asset contract
        StarXFinancialSecurityAsset(_assetContract).disableContract();
    }
    //-------- v1 - overrides - finish --------

    //---------------------------------- v1 - member functions - finish ------------------------------------
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "./../interfaces/IRequest.sol";
import "./IStarXAddressRegistry.sol";
import "./IStarXCelebrity.sol";

/// @title StarXFinancialSecurityAsset
/// @notice Represents a LLC, deal or asset issued by the owning celebrity (with on-chain representation in the form of StarXCelebrity contract)
/// @notice Mints a supply of a token which represents purchasable shares in this opportunity
/// @notice Shares are purchasable via StarX front-end marketplace and record individual ownership is maintained in StarX internal database for regulatory/compliance purposes
/// @dev Only the owning instance of StarXCelebrity can call this contract's functions
/// @dev On-chain ownership of minted token is maintained by a StarX custody wallet
/// @dev inherits from ERC1155Burnable
contract StarXFinancialSecurityAsset is ERC1155Burnable {
    /// @notice basic attributes which define a FinancialSecurityAsset (defined per unique token id)
    struct AssetInfo {
        /// @notice Flag which is true when asset has been listed and is available for purchase.  Flag is false when asset is no longer purchasable
        bool isListed;
        /// @notice The address of the celebrity wallet from which is this asset originated
        address creator;
        IRequest.AssetType assetType;
        /// @notice The purchasable number of shares for this asset
        uint256 supply;
        /// @notice The initial, per-share price of this asset
        uint256 initialOfferingPrice;
        /// @notice The royalty rate of underlying asset to which the security holder is entitled.  Denominated in bps such that min/max value is 0/100% or 0/10,000 bps
        uint16 holderRoyaltyBps;
        /// @notice The URI to the contract defining the payout attributes of this asset
        string investmentContractUri;
    }

    //---------------------------------- v1 - events - start ------------------------------------

    /// @notice Event emitted when the current custody wallet of this asset changes.  Next token minted from this contract will go to the new wallet.
    event AssetCustodyWalletUpdated(
        address indexed newAddress,
        address indexed oldAddress,
        string indexed assetContractName
    );

    /// @notice Event emitted when the listing status of a particular token within this contract is updated
    event UpdateListingStatus(
        uint256 indexed tokenId,
        bool newStatus,
        bool oldStatus,
        string indexed assetContractName
    );

    /// @notice Event emitted when a new ERC-1155 token is minted from this contract
    event MintAndListAsset(
        string indexed assetContractName,
        address indexed creator,
        uint256 indexed tokenId,
        uint256 supply,
        IRequest.AssetType assetType,
        uint256 initialOfferingPrice,
        uint16 holderRoyaltyBps,
        address custodyWallet
    );
    //---------------------------------- v1 - events - finish ------------------------------------

    //---------------------------------- v1 - member vars - start ------------------------------------

    /// @notice asset name
    string private m_name;

    /// @notice asset symbol
    string private m_symbol;

    /// @notice long form description of this asset
    string private m_description;

    /// @notice The instance of StarXCelebrity which deployed this contract.  As such it is the only, permissioned caller of this contract
    address private m_deployingStarXCelebrity;

    /// @notice The id of the last-minted ERC-1155 token from this contract (0 when no tokens have yet been minted)
    uint256 private m_tokenId;

    /// @notice token id => asset info
    mapping(uint256 => AssetInfo) private m_tokenToFinancialSecurityAsset;

    /// @notice The StarX custody wallet for the next-minted ERC-1155 token of this contract
    address m_currentCustodyWallet;

    /// @notice token id => StarX custody wallet which holds that token
    mapping(uint256 => address) private m_tokenToCustodyWallet;
    // TODO: pre-existing standard for custody wallet?

    // TODO: dev doc
    bool private m_isDisabled;

    //---------------------------------- v1 - member vars - finish ------------------------------------

    //---------------------------------- v1 - modifiers - start ------------------------------------

    /// @notice For a function that takes a Token ID argument, that Token ID must have been minted by this contract
    modifier modTokenIdExists(uint256 _tokenId) {
        require(
            _tokenId > 0 &&
                m_tokenToFinancialSecurityAsset[_tokenId].supply > 0,
            "[Asset] DNE token id"
        );
        _;
    }

    /// @notice Specied rate must be valid.
    /// @notice A valid rate is in the range 0 to 100% (100 x 100 = 10,000 basis points)
    modifier modValidRateInBps(uint16 _rateBps) {
        // valid range is from 0 to 100% (100 x 100 = 10,000 basis points)
        require(_rateBps < 10001, "invalid rate bps");
        _;
    }

    /// @notice For functions that may only be called by the instance of StarXCelebrity which deployed this asset contract
    modifier modOnlyDeployingStarXCelebrity() {
        // caller can only be deploying instance of StarXCelebrity
        require(
            _msgSender() == m_deployingStarXCelebrity,
            "Caller not source celeb contract"
        );
        _;
    }

    /// @notice For function that may only be called while this asset contract is enabled
    modifier modIsEnabled() {
        require(!m_isDisabled, "asset contract disabled");
        _;
    }

    //---------------------------------- v1 - modifiers - finish ------------------------------------

    //---------------------------------- v1 - functions - start ------------------------------------

    /// @dev must satisfy call to parent (ERC1155) constructor
    /// @dev use empty string as we have no need (at present) for a base uri
    constructor(IRequest.DeployAssetContractRequest memory _req) ERC1155("") {
        require(
            IERC165(_msgSender()).supportsInterface(
                type(IStarXCelebrity).interfaceId
            ),
            "ONLY StarXCelebrity calls ctor"
        );

        m_name = _req.assetName;
        m_symbol = _req.assetSymbol;
        m_description = _req.assetDescription;

        m_deployingStarXCelebrity = _msgSender();

        m_currentCustodyWallet = _req.custodyWallet;

        m_isDisabled = false;
    }

    /// @notice Asset contract name
    /// @dev Defined at construction of asset contract instance
    function name() external view returns (string memory) {
        return m_name;
    }

    /// @notice Asset contract symbol
    /// @dev Defined at construction of asset contract instance
    function symbol() external view returns (string memory) {
        return m_symbol;
    }

    /// @notice Asset contract description
    /// @dev Defined at construction of asset contract instance
    function description() external view returns (string memory) {
        return m_description;
    }

    /// @notice Get the address of the StarXCelebrity contract which deployed this asset contract
    function getStarXCelebrity() external view returns (address) {
        return m_deployingStarXCelebrity;
    }

    /// @notice Get the last-minted Token ID of this asset contract (0 if no tokens have yet been minted)
    function getCurrentTokenID() public view returns (uint256) {
        return m_tokenId;
    }

    /// @notice Get the address of the custody wallet to which this asset contract's next token will be minted to
    function getCurrentCustodyWallet() external view returns (address) {
        return m_currentCustodyWallet;
    }

    /// @notice Has this asset contract been disabled (i.e. frozen from any further state changes)
    function isDisabled() external view returns (bool) {
        return m_isDisabled;
    }

    /// @notice Mark this asset contract as disabled (i.e. deprecated)
    /// @notice No longer tracked or called by deploying instance of StarXCelebrity
    /// @notice Once asset contract is frozen, all listed tokens are de-listed
    /// @notice Once asset contract is frozen, subsequent state changes (via function calls) is forbidden
    /// @notice Once asset contract is frozen it cannot be unfrozen
    /// @dev Only callable via owning instance of StarXCelebrity
    /// @dev Only callable while this asset contract is NOT disabled
    /// @dev Iterates through all deployed tokens and sets listing status to false
    function disableContract()
        external
        modOnlyDeployingStarXCelebrity
        modIsEnabled
    {
        // close listing status of all tokens for this contract
        for (uint256 id = 1; id <= m_tokenId; id++) {
            _updateListingStatus(id, false);
        }
        // set disabled field
        m_isDisabled = true;
    }

    /// @notice Get the asset info
    /// @dev Checks that specified token id exists within this asset contract
    /// @param _tokenId uint256, the target asset info to be retrieved
    /// @return AssetInfo
    function getFinancialSecurityAsset(uint256 _tokenId)
        external
        view
        modTokenIdExists(_tokenId)
        returns (AssetInfo memory)
    {
        return m_tokenToFinancialSecurityAsset[_tokenId];
    }

    /// @notice Update the current custody wallet for this contract.  Next ERC-1155 token minted from this contract will go to this wallet.
    /// @dev Only callable via owning instance of StarXCelebrity
    /// @dev Only callable while this asset contract is NOT disabled
    /// @param _newWallet address of the new StarX custody wallet for next-minted tokens
    function updateCurrentCustodyWallet(address _newWallet)
        external
        modOnlyDeployingStarXCelebrity
        modIsEnabled
    {
        require(_newWallet != address(0), "Invalid new custody wallet");

        // emit event
        emit AssetCustodyWalletUpdated(
            _newWallet,
            m_currentCustodyWallet,
            m_name
        );
        m_currentCustodyWallet = _newWallet;
    }

    /// @notice Update the asset listing status of specified token
    /// @dev Only callable via owning instance of StarXCelebrity
    /// @dev Only callable while this asset contract is NOT disabled
    /// @dev Checks that specified token id exists within this asset contract
    /// @param _tokenId the token for which the listing status will be updated
    /// @param _status the new listing status; true/false means assets is/is not purchasable
    function updateListingStatus(uint256 _tokenId, bool _status)
        external
        modTokenIdExists(_tokenId)
        modOnlyDeployingStarXCelebrity
        modIsEnabled
    {
        _updateListingStatus(_tokenId, _status);
    }

    function _updateListingStatus(uint256 _tokenId, bool _status) private {
        AssetInfo storage asset = m_tokenToFinancialSecurityAsset[_tokenId];
        // emit event
        emit UpdateListingStatus(_tokenId, asset.isListed, _status, m_name);

        // effect: update listing status
        asset.isListed = _status;
    }

    /// @notice Mint a new ERC-1155 token from this contract using the specified parameters
    /// @dev Only callable via owning instance of StarXCelebrity
    /// @dev Only callable while this asset contract is NOT disabled
    /// @dev Reverts if invalid rate (in bps) is specified
    /// @param _req IRequest.ListAssetRequest arguments which define the attributes of the token to be minted
    /// @return the id of the newly-minted token
    function listAsset(IRequest.ListAssetRequest calldata _req)
        external
        modOnlyDeployingStarXCelebrity
        modValidRateInBps(_req.holderRoyaltyBps)
        modIsEnabled
        returns (uint256)
    {
        // check(s)
        require(_req.creator != address(0), "invalid creator address");
        require(_req.supply > 0, "listing requires non-zero supply");
        require(_req.initialOfferingPrice > 0, "cannot list at zero-price");
        // increment token
        m_tokenId++;
        // initialize financial security asset of this token
        m_tokenToFinancialSecurityAsset[m_tokenId] = AssetInfo({
            isListed: true,
            creator: _req.creator,
            assetType: _req.assetType,
            supply: _req.supply,
            initialOfferingPrice: _req.initialOfferingPrice,
            holderRoyaltyBps: _req.holderRoyaltyBps,
            investmentContractUri: _req.investmentContractUri
        });

        // map new token to its custody wallet
        m_tokenToCustodyWallet[m_tokenId] = m_currentCustodyWallet;

        // use 1155 to mint supply
        // -> beneficiary/holder = StarX custody wallet
        // --> holds the full balance of all tokens minted from this contract
        _mint(m_currentCustodyWallet, m_tokenId, _req.supply, bytes(""));

        // emit event
        emit MintAndListAsset(
            m_name,
            _req.creator,
            m_tokenId,
            _req.supply,
            _req.assetType,
            _req.initialOfferingPrice,
            _req.holderRoyaltyBps,
            m_currentCustodyWallet
        );

        // return new token id to caller
        return m_tokenId;
    }

    //-------- v1 - overrides - start --------

    /// @dev See {ERC1155-uri}
    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return m_tokenToFinancialSecurityAsset[_tokenId].investmentContractUri;
    }

    //-------- v1 - overrides - finish --------

    //---------------------------------- v1 - functions - finish ------------------------------------
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStarXAddressRegistry {
    function adminNftContracts(address nftAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./../interfaces/IRequest.sol";

interface IStarXCelebrity is IERC165 {
    function deployFinancialSecurityAssetContract(
        IRequest.DeployAssetContractRequest calldata _req
    ) external returns (IRequest.DeployAssetResult, address);

    function mintNewSecurity(
        address _securityContract,
        IRequest.ListAssetRequest memory _req
    ) external returns (uint256);

    function getStarXAddressRegistry() external view returns (address);

    function updateStarXAddressRegistry(address _newAddress) external;

    function updateCustodyWalletForAsset(
        address _assetContract,
        address _newWallet
    ) external;

    function updateListingStatusForAsset(
        address _assetContract,
        uint256 _tokenId,
        bool _newStatus
    ) external;

    function disableAssetContract(address _assetContract) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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