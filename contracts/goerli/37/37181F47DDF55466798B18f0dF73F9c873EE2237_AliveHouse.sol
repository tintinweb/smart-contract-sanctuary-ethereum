// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./RegistryContracts/AliveRegistry.sol";
import "./BandContracts/AliveBand.sol";

contract AliveHouse is Initializable {
    address public aliveRegistry;
    struct Band {
        uint256 bandId;
        string bandName;
        address bandAddress;
        address bandAdmin;
    }

    Band[] public allBands;
    mapping(uint256 => Band) bandById;

    // Modifier
    modifier onlyAdmin() {
        require(
            AliveRegistry(aliveRegistry).adminAddress() == msg.sender,
            "Only Admin!"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true,
            "Only Governor!"
        );
        _;
    }

    // Events
    event BandCreated(
        uint256 bandId,
        string bandName,
        address bandAddress,
        address bandAdmin
    );

    function initialize(address _aliveRegistry) public initializer {
        aliveRegistry = _aliveRegistry;
    }

    function createAliveBand(address _bandAdmin, string memory _bandName)
        public
        onlyGovernor
        returns (address)
    {
        uint256 id = allBands.length + 1;
        bytes memory data = abi.encodeWithSelector(
            AliveBand(address(0)).initialize.selector,
            id,
            _bandName,
            _bandAdmin,
            aliveRegistry
        );
        BeaconProxy bandImp = new BeaconProxy(
            address(AliveRegistry(aliveRegistry).aliveBandBeacon()),
            data
        );
        Band memory newBand;

        newBand.bandId = id;
        newBand.bandName = _bandName;
        newBand.bandAddress = address(bandImp);
        newBand.bandAdmin = _bandAdmin;

        allBands.push(newBand);
        bandById[id] = newBand;

        emit BandCreated(id, _bandName, address(bandImp), _bandAdmin);
        return address(bandImp);
    }

    function getAllBands() public view returns (Band[] memory) {
        return allBands;
    }

    function getBandById(uint256 _id) public view returns (Band memory) {
        return bandById[_id];
    }
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Beacons/AliveBandBeacon.sol";
import "../Beacons/AliveSongBeacon.sol";
import "../ProxyAdmin.sol";

contract AliveRegistry is Initializable, ProxyAdmin {
    struct AliveSongImp {
        address impAddress;
        uint256 maxMintAmountPerTx;
        AliveSongBeacon aliveSongBeacon;
        uint8 songVersion;
    }

    uint256 initialMaxMintAmountPerTx;

    address public aliveHouseRoyaltyReceiver;
    address public splitsAddress;
    address public adminAddress;

    AliveBandBeacon public aliveBandBeacon;

    mapping(address => bool) public isManagerWallet;
    mapping(address => bool) public isSignerWallet;
    mapping(uint8 => AliveSongImp) public aliveSongByType;

    uint8 public feePercent;
    uint8 public totalSongTypes;

    uint8 public bandVersion;
    uint8 public registryVersion;
    uint8 public houseVersion;

    // Modifier
    modifier onlyAdmin() {
        require(adminAddress == msg.sender, "Only Admin!");
        _;
    }

    // Events
    event AddNewSongImp(address newSongImp, uint256 maxMintAmount);
    event UpgradeAliveBandImp(address to, uint8 version);
    event UpgradeAliveSongImp(uint8 songType, address to, uint8 version);
    event AddManagers(address[] managers);
    event RemoveManagers(address[] managers);
    event ChangeAdmin(address oldAdmin, address newAdmin);
    event UpgradeRegistry(address to, uint8 version);
    event UpgradeHouse(address to, uint8 version);

    function initialize(
        address _aliveHouseRoyaltyReceiver, // Treasury Wallet address
        uint8 _feePercent, // Precentage of Fee
        address _managerWallet, // Alive Manager Wallet address
        address _bandImp, // Initial Band implementation address
        address[] memory _songImps, // Initial Song implementations address(Fixed,Bonded, Dutch)
        uint256[] memory _maxMintAmountsPerTx, // Limits of songs per mint
        address _splitsAddress, // Splits Imp address
        address _admin
    ) public initializer {
        require(_feePercent < 100, "Percentage must be less than 100!");
        initialMaxMintAmountPerTx = 10;
        isManagerWallet[_managerWallet] = true;
        aliveHouseRoyaltyReceiver = _aliveHouseRoyaltyReceiver;
        aliveBandBeacon = new AliveBandBeacon(_bandImp);
        totalSongTypes = uint8(_songImps.length);
        adminAddress = _admin;
        unchecked {
            for (uint8 i = 0; i < totalSongTypes; i++) {
                uint256 tempMaxMint;
                if (_maxMintAmountsPerTx[i] != 0) {
                    tempMaxMint = _maxMintAmountsPerTx[i];
                } else {
                    tempMaxMint = initialMaxMintAmountPerTx;
                }
                aliveSongByType[i + 1] = AliveSongImp(
                    _songImps[i],
                   tempMaxMint,
                    new AliveSongBeacon(_songImps[i]),
                    1
                );
            }
        }

        splitsAddress = _splitsAddress;
        bandVersion = 1;
        registryVersion = 1;
        houseVersion = 1;
    }

    function reset(
        address _aliveHouseRoyaltyReceiver, // Treasury Wallet address
        uint8 _feePercent, // Precentage of Fee
        address _managerWallet, // Alive Manager Wallet address
        address _bandImp, // Initial Band implementation address
        address[] memory _songImps, // Initial Song implementations address
        uint256[] memory _maxMintAmountsPerTx, // Limits of songs per mint
        address _splitsAddress // Splits Imp address
    ) external onlyAdmin {
        require(_feePercent < 100, "Percentage must be less than 100!");
        initialMaxMintAmountPerTx = 10;
        isManagerWallet[_managerWallet] = true;
        aliveHouseRoyaltyReceiver = _aliveHouseRoyaltyReceiver;
        aliveBandBeacon = new AliveBandBeacon(_bandImp);

        unchecked {
            for (uint8 i = 0; i < _songImps.length; i++) {
                uint256 tempMaxMint;
                if (_maxMintAmountsPerTx[i] != 0) {
                    tempMaxMint = _maxMintAmountsPerTx[i];
                } else {
                    tempMaxMint = initialMaxMintAmountPerTx;
                }
                aliveSongByType[i + 1] = AliveSongImp(
                    _songImps[i],
                    _maxMintAmountsPerTx[i],
                    new AliveSongBeacon(_songImps[i]),
                    1
                );
            }
        }

        splitsAddress = _splitsAddress;
        bandVersion = 1;
    }

    function getAliveSongMaxMintPerTxByType(uint8 _songType)
        external
        view
        returns (uint256)
    {
        return aliveSongByType[_songType].maxMintAmountPerTx;
    }

    function getAliveSongImp(uint8 _songType)
        external
        view
        returns (AliveSongImp memory)
    {
        require(
            _songType > 0 && _songType <= totalSongTypes,
            "There is no Song that you selected!"
        );
        return aliveSongByType[_songType];
    }

    function updateMaxMintAmountsPerTx(uint256[] calldata _maxMintAmountsPerTx)
        external
        onlyAdmin
    {
        unchecked {
            for (uint8 i = 0; i < totalSongTypes; i++) {
                uint256 tempMaxAmountMint;
                if (_maxMintAmountsPerTx[i] != 0) {
                    tempMaxAmountMint = _maxMintAmountsPerTx[i];
                } else {
                    tempMaxAmountMint = initialMaxMintAmountPerTx;
                }
                aliveSongByType[i + 1].maxMintAmountPerTx = tempMaxAmountMint;
            }
        }
    }

    function updateMaxMintAmountPerTxBySongType(
        uint8 _songType,
        uint256 _maxMintAmount
    ) external onlyAdmin {
        require(
            _songType > 0 && _songType <= totalSongTypes,
            "There is no Song that you selected!"
        );
        require(
            _maxMintAmount > 0,
            "The max mint amount of song must be over 0!"
        );
        aliveSongByType[_songType].maxMintAmountPerTx = _maxMintAmount;
    }

    function updateSplitsAddress(address _newSplit) external onlyAdmin {
        splitsAddress = _newSplit;
    }

    function updateAliveHouseRoyaltyReceiver(address _newTreasuryWallet)
        external
        onlyAdmin
    {
        aliveHouseRoyaltyReceiver = _newTreasuryWallet;
    }

    function updateRoyaltyFee(uint8 _newFeePercent) external onlyAdmin {
        require(_newFeePercent < 100, "Percentage must be less than 100!");
        feePercent = _newFeePercent;
    }

    function addMangerWallets(address[] calldata _newManagerWallets)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _newManagerWallets.length; i++) {
            isManagerWallet[_newManagerWallets[i]] = true;
        }
        emit AddManagers(_newManagerWallets);
    }

    function removeManagerWallets(address[] calldata _removeManagerWallets)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _removeManagerWallets.length; i++) {
            isManagerWallet[_removeManagerWallets[i]] = false;
        }
        emit RemoveManagers(_removeManagerWallets);
    }
    function addSignerWallets(address[] calldata _newSignerWallets)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _newSignerWallets.length; i++) {
            isSignerWallet[_newSignerWallets[i]] = true;
        }
       
    }

    function removeSignerWallets(address[] calldata _removeSignerWallets)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _removeSignerWallets.length; i++) {
            isSignerWallet[_removeSignerWallets[i]] = false;
        }
     
    }

    function upgradeAliveBandImp(address _to) public onlyAdmin returns (bool) {
        aliveBandBeacon.update(_to);
        bandVersion++;
        emit UpgradeAliveBandImp(_to, bandVersion);
        return true;
    }

    function upgradeAliveSongImp(uint8 _songType, address _to)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            _songType > 0 && _songType <= totalSongTypes,
            "There is no Song that you selected!"
        );
        aliveSongByType[_songType].aliveSongBeacon.update(_to);
        aliveSongByType[_songType].songVersion++;
        emit UpgradeAliveSongImp(
            _songType,
            _to,
            aliveSongByType[_songType].songVersion
        );
        return true;
    }

    function addNewSongImp(address _newSongImp, uint256 _maxMintAmount)
        public
        onlyAdmin
    {
        require(
            _maxMintAmount > 0,
            "The max mint amount of song must be over 0!"
        );
        totalSongTypes = totalSongTypes + 1;
        aliveSongByType[totalSongTypes] = AliveSongImp(
            _newSongImp,
            _maxMintAmount,
            new AliveSongBeacon(_newSongImp),
            1
        );
        emit AddNewSongImp(_newSongImp, _maxMintAmount);
    }

    function changeAdmin(address _to) public onlyAdmin {
        emit ChangeAdmin(adminAddress, _to);
        adminAddress = _to;
    }

    function setInitialMaxMintAmountPerTx(uint256 _maxMintAmount)
        public
        onlyAdmin
    {
        initialMaxMintAmountPerTx = _maxMintAmount;
    }

    function upgradeVersion(
        TransparentUpgradeableProxy proxy,
        address implementation, // New Implementation Address
        uint8 contractNum // AliveRegistry: 0, AliveHouse: 1
    ) public onlyAdmin {
        upgrade(proxy, implementation);
        if (contractNum == 0) {
            registryVersion++;
            emit UpgradeRegistry(implementation, registryVersion);
        } else if (contractNum == 1) {
            houseVersion++;
            emit UpgradeHouse(implementation, houseVersion);
        }
    }

    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        override
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        override
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public override onlyAdmin {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override onlyAdmin {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation)
        internal
        override
        onlyAdmin
    {
        proxy.upgradeTo(implementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../RegistryContracts/AliveRegistry.sol";
import "../../Interfaces/splitMain.sol";
import "../Songs/v2/FixedV2.sol";
import "../Songs/v2/BondedV2.sol";
import "../Songs/v2/DutchV2.sol";

contract AliveBand is Initializable, AccessControlUpgradeable {
    struct Song {
        uint256 songId;
        uint256 songType; // 1, 2, 3 etc are the types
        address songContract;
        address splitSecondaryReceiverAddress;
        address splitMintReceiverAddress;
    }

    bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    address public aliveRegistry;
    address public bandAdmin;
    address[] public membersOfBand;
    address[] allSplits;

    uint256 public bandId;
    string public bandName;

    Song[] public allSongs;

    mapping(address => uint256) memberIdByAddress;
    mapping(uint256 => Song) songById;
    mapping(address => uint256) splitAddToId;

    IERC20 public usdc;

    // Modifiers
    modifier onlyGovernor() {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true ||
                hasRole(GOVERNANCE_ROLE, msg.sender),
            "only governor"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true
        );
        _;
    }

    // Events
    event SongCreated(address songAddress, uint256 songId, uint256 songType);
    event AdminChanged(address oldAdmin, address newAdmin);
    event SplitWalletCreated(address splitWallet, uint256 id);

    function initialize(
        uint256 _id,
        string memory _bandName,
        address _bandAdmin,
        address _aliveRegistry
        // IERC20 _usdc
    ) external initializer {
        bandId = _id;
        _grantRole(GOVERNANCE_ROLE, _bandAdmin);
        aliveRegistry = _aliveRegistry;
        bandAdmin = _bandAdmin;
        bandName = _bandName;
        // usdc = _usdc;
    }

    function createFixedSong(
        address _royaltyReceiverSecondary,
        uint96 _royaltyFeesInBips,
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips,
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256[3] memory _songInfos
    ) public onlyGovernor returns (address) {
        uint256 songId = allSongs.length + 1;

        bytes memory data = abi.encodeWithSelector(
            AliveFixedSongV2(address(0)).initialize.selector,
            aliveRegistry,
            _royaltyReceiverSecondary,
            _royaltyFeesInBips,
            _royaltyReceiverSplit,
            _offchainRoyaltyPercentageInBips,
            _songURI,
            _contractURI,
            _artist,
            songId,
            _songInfos );

        BeaconProxy song = new BeaconProxy(
            address(
                AliveRegistry(aliveRegistry).getAliveSongImp(1).aliveSongBeacon
            ),
            data
        );
        Song memory newSong;
        newSong.songContract = address(song);
        newSong.songId = songId;
        newSong.songType = 1;
        newSong.splitSecondaryReceiverAddress = _royaltyReceiverSecondary;
        newSong.splitMintReceiverAddress = _royaltyReceiverSplit;
        allSongs.push(newSong);
        emit SongCreated(address(song), songId, 1);
        return address(song);
    }

    function createBondedSong(
        address _royaltyReceiverSecondary,
        uint96 _royaltyFeesInBips,
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips,
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256[4] memory _songInfos
    ) public virtual onlyGovernor returns (address) {
        uint256 songId = allSongs.length + 1;
        bytes memory data = abi.encodeWithSelector(
            AliveBondedSongV2(address(0)).initialize.selector,
            aliveRegistry,
            _royaltyReceiverSecondary,
            _royaltyFeesInBips,
            _royaltyReceiverSplit,
            _offchainRoyaltyPercentageInBips,
            _songURI,
            _contractURI,
            _artist,
            songId,
            _songInfos
        );

        BeaconProxy song = new BeaconProxy(
            address(
                AliveRegistry(aliveRegistry).getAliveSongImp(2).aliveSongBeacon
            ),
            data
        );
        Song memory newSong;
        newSong.songContract = address(song);
        newSong.songId = songId;
        newSong.songType = 2;
        newSong.splitSecondaryReceiverAddress = _royaltyReceiverSecondary;
        newSong.splitMintReceiverAddress = _royaltyReceiverSplit;
        allSongs.push(newSong);
        emit SongCreated(address(song), songId, 2);
        return address(song);
    }

    function createDutchSong(
        address _royaltyReceiverSecondary,
        uint96 _royaltyFeesInBips,
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips,
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256[5] memory _songInfos
    ) public onlyGovernor returns (address) {
        uint256 songId = allSongs.length + 1;
        bytes memory data = abi.encodeWithSelector(
            AliveDutchSongV2(address(0)).initialize.selector,
            aliveRegistry,
            _royaltyReceiverSecondary,
            _royaltyFeesInBips,
            _royaltyReceiverSplit,
            _offchainRoyaltyPercentageInBips,
            _songURI,
            _contractURI,
            _artist,
            songId,
            _songInfos
        );

        BeaconProxy song = new BeaconProxy(
            address(
                AliveRegistry(aliveRegistry).getAliveSongImp(3).aliveSongBeacon
            ),
            data
        );
        Song memory newSong;
        newSong.songContract = address(song);
        newSong.songId = songId;
        newSong.songType = 3;
        newSong.splitSecondaryReceiverAddress = _royaltyReceiverSecondary;
        newSong.splitMintReceiverAddress = _royaltyReceiverSplit;
        allSongs.push(newSong);
        emit SongCreated(address(song), songId, 3);
        return address(song);
    }

    function getSplitWallet(uint256 id) public view returns (address) {
        return allSplits[id];
    }

    function transferAdminOwnership(address _to) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        bandAdmin = _to;
        _grantRole(DEFAULT_ADMIN_ROLE, _to);
        emit AdminChanged(msg.sender, _to);
    }

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function createSplitWallet(
        address[] memory accounts,
        uint32[] calldata percentAllocations
    ) public onlyGovernor returns (address) {
        address splits = AliveRegistry(aliveRegistry).splitsAddress();
        address predictedSplit = ISplitMain(splits)
            .predictImmutableSplitAddress(accounts, percentAllocations, 0);

        if (!isContract(predictedSplit)) {
            address split1 = ISplitMain(splits).createSplit(
                accounts,
                percentAllocations,
                0,
                address(0)
            );
            uint256 id = allSplits.length;
            allSplits.push(split1);
            splitAddToId[split1] = id;
            emit SplitWalletCreated(split1, id);
            return split1;
        } else {
            emit SplitWalletCreated(
                predictedSplit,
                splitAddToId[predictedSplit]
            );
            return predictedSplit;
        }
    }

    function addMember(address _addr) public onlyAdmin returns (bool) {
        require(memberIdByAddress[_addr] == 0);
        uint256 id = membersOfBand.length + 1;
        memberIdByAddress[_addr] = id;
        membersOfBand.push(_addr);
        return true;
    }

    function addMemberBulk(address[] memory _addrs)
        public
        onlyAdmin
        returns (bool)
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            addMember(_addrs[i]);
        }
        return true;
    }

    function removeMember(address _addr) public onlyAdmin returns (bool) {
        require(memberIdByAddress[_addr] != 0, "not a member");
        uint256 idOfMember = memberIdByAddress[_addr];

        for (
            uint256 index = idOfMember - 1;
            index < membersOfBand.length - 1;
            index++
        ) {
            membersOfBand[index] = membersOfBand[index + 1];
        }
        membersOfBand.pop();
        memberIdByAddress[_addr] = 0;
        return true;
    }

    function getSongById(uint256 _id) public view returns (Song memory) {
        return songById[_id];
    }

    function getAllSongs() public view returns (Song[] memory) {
        return allSongs;
    }

    function getAllMembers() public view returns (address[] memory) {
        return membersOfBand;
    }

    function grantGovernanceRole(address _to) public {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true
        );
        _grantRole(GOVERNANCE_ROLE, _to);
    }

    function getGovernanceRole(address _to) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(hasRole(GOVERNANCE_ROLE, _to));
        _revokeRole(GOVERNANCE_ROLE, _to);
    }

  function setAliveRegistry(address _aliveReg) public onlyAdmin virtual {
  aliveRegistry = _aliveReg;
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AliveBandBeacon is Ownable {
    UpgradeableBeacon public immutable aliveBandBeacon;

    constructor(address _initBlueprint) {
        aliveBandBeacon = new UpgradeableBeacon(_initBlueprint);
    }

    function implementation() public view returns (address) {
        return aliveBandBeacon.implementation();
    }

    function update(address _newBlueprint) public {
        aliveBandBeacon.upgradeTo((_newBlueprint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AliveSongBeacon is Ownable {
    UpgradeableBeacon public immutable aliveSongBeacon;

    constructor(address _initBlueprint) {
        aliveSongBeacon = new UpgradeableBeacon(_initBlueprint);
    }

    function implementation() public view returns (address) {
        return aliveSongBeacon.implementation();
    }

    function update(address _newBlueprint) public {
        aliveSongBeacon.upgradeTo((_newBlueprint));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public virtual {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation)
        internal
        virtual
    {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

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
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
     
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../AliveFixedSong.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AliveFixedSongV2 is AliveFixedSong {
    // uint8 public aliveRoyaltyFee;

    // bool public isUSDCMint;
    // IERC20 public usdc;

    // function initialize(
    //     address _aliveRegistry,
    //     address _royaltyReceiverSecondary, // royalityReceiver
    //     uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
    //     address _royaltyReceiverSplit,
    //     uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
    //     string memory _songURI,
    //     string memory _contractURI,
    //     address _artist,
    //     uint256 _songId,
    //     uint256[4] memory _songInfos,
    //     uint8 _aliveRoyaltyFee,
    //     IERC20 _usdc
    // ) external  initializer  initializerERC721A {
    //     __ERC721A_init("AliveE1", "AE1");
    //     _grantRole(DEFAULT_ADMIN_ROLE, _artist);
    //     _grantRole(GOVERNANCE_ROLE, _artist);
    //     _grantRole(PAUSER_ROLE, _artist);
    //     band = msg.sender;

    //     aliveRegistry = _aliveRegistry;
    //     mintRoyaltyReceiver = _royaltyReceiverSplit;
    //     offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
    //     _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);

    //     songId = _songId;
    //     baseURI = _songURI;
    //     contractURI = _contractURI;
    //     songType = 1;
    //     usdc = _usdc;
    //     startedAt = _songInfos[3];
    //     aliveRoyaltyFee = _aliveRoyaltyFee;
    //     maxMintAmount = _songInfos[1];

    //     if (_songInfos[0] == 0) {
    //         // matic payment

    //         initialPrice = _songInfos[2];
    //     } else {
    //         // usdc payment
    //         isUSDCMint = true;
    //         initialPrice = _songInfos[2];
    //     }
    // }

    // function setUSDCAddress(address _usdc) public onlyGovernor {
    //     usdc = IERC20(_usdc);
    // }

    // function mint(
    //     address _to,
    //     uint256 _quantity
    // ) public payable override whenNotPaused nonReentrant {
    //     require(block.timestamp > startedAt);
    //     require(
    //         _quantity <
    //             AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
    //                 songType
    //             ),
    //         "You can mint Songs more than Limit per mint!"
    //     );
    //     require(
    //         totalSupply() + _quantity <= getMaxMintAmount(),
    //         "Can't mint more than Limit!"
    //     );
    //     require(_quantity > 0, "You must mint more than 0!");
    //     uint256 price = getPrice(_quantity, _to);
    //     if (isUSDCMint) {
    //          require(usdc.allowance(msg.sender, address(this)) >= price, "Insufficient allowance of usdc!");
    //         uint256 feePercent = aliveRoyaltyFee;
    //         // uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
    //         uint256 feePrice = (price * feePercent) / 100;
    //         address aliveRoyaltyRec = AliveRegistry(aliveRegistry)
    //             .aliveHouseRoyaltyReceiver();
    //         usdc.transferFrom(msg.sender, aliveRoyaltyRec, feePrice);
    //         usdc.transferFrom(
    //             msg.sender,
    //             mintRoyaltyReceiver,
    //             price - feePrice
    //         );
    //         uint256 currentTotalSupply = totalSupply();
    //         for (uint256 i = 0; i < _quantity; i++) {
    //             addressTokenIds[_to].push(currentTotalSupply + i + 1);
    //         }
    //         emit SongMinted(_to, _quantity, totalSupply(), address(this));
    //     } else {
    //         require(msg.value >= price, "Insufficient funds!");
    //         if (msg.value > price) {
    //             payable(msg.sender).transfer(msg.value - price);
    //         }

    //         uint256 feePercent = aliveRoyaltyFee;
    //         // uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
    //         uint256 feePrice = (price * feePercent) / 100;
    //         payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
    //             .transfer(feePrice);
    //         payable(mintRoyaltyReceiver).transfer(price - feePrice);
    //         uint256 currentTotalSupply = totalSupply();
    //         super._mint(_to, _quantity);
    //         for (uint256 i = 0; i < _quantity; i++) {
    //             addressTokenIds[_to].push(currentTotalSupply + i + 1);
    //         }
    //         emit SongMinted(_to, _quantity, totalSupply(), address(this));
    //     }
    // }

    // function changeAliveRoyaltyFee(uint8 newAliveRoyaltyFee)
    //     external
    //     onlyAdmin
    // {
    //     aliveRoyaltyFee = newAliveRoyaltyFee;
    // }

    function getNFTData(uint amount, address _address)
        public
        view
        returns (
            uint _price,
            uint _totalSupply,
            uint maxSupply,
            uint _balanceOfUser,
            uint _startedAt
        )
    {
        return (
            getPrice(amount, _address),
            totalSupply(),
            getMaxMintAmount(),
            balanceOf(_address),
            startedAt
        );
    }

    function getPrice(uint256 _quantity, address _to)
        public
        view
        override
        returns (uint256 price)
    {
        if (isWhiteListed[_to]) {
            return whitelistPrice * _quantity;
        } else {
            return initialPrice * _quantity;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../AliveBondedSong.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
contract AliveBondedSongV2 is AliveBondedSong {
// uint8 public aliveRoyaltyFee;
//     bool public isUSDCMint;
//     IERC20 public usdc;

//  function initialize(
//         address _aliveRegistry,
//         address _royaltyReceiverSecondary, // royalityReceiver
//         uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
//         address _royaltyReceiverSplit,
//         uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
//         string memory _songURI,
//         string memory _contractURI,
//         address _artist,
//         uint256 _songId,
//         uint256[5] memory _songInfos, 
//         uint8 _aliveRoyaltyFee,
//           IERC20 _usdc
//     ) external initializer  initializerERC721A {
//         __ERC721A_init("AliveE2", "AE2");
//         _grantRole(DEFAULT_ADMIN_ROLE, _artist);
//         _grantRole(GOVERNANCE_ROLE, _artist);
//         _grantRole(PAUSER_ROLE, _artist);

//         band = msg.sender;
//         usdc = _usdc;

//         aliveRegistry = _aliveRegistry;
//         mintRoyaltyReceiver = _royaltyReceiverSplit;
//         offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
//         _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);

//         songId = _songId;
//         baseURI = _songURI;
//         contractURI = _contractURI;
//         songType = 2;

//         maxMintAmount = _songInfos[1];
//         initialPrice = _songInfos[2];
//         currentPrice = _songInfos[2];
//         upcountRate = _songInfos[3];
//         startedAt = _songInfos[4];
//         aliveRoyaltyFee = _aliveRoyaltyFee;


//         if (_songInfos[0] == 0) {
//             // matic payment

//         } else {
//             // usdc payment
//             isUSDCMint = true;
//         }
//     }


//  function mint(address _to, uint256 _quantity)
//         public
//         payable
//         override
//         whenNotPaused
//         nonReentrant
//     {   require(block.timestamp > startedAt);
//         require(
//             _quantity <
//                 AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
//                     songType
//                 ),
//             "You can mint Songs more than Limit per mint!"
//         );
//         require(
//             totalSupply() + _quantity <= maxMintAmount,
//             "Can't mint more than Limit!"
//         );
//         require(_quantity > 0, "You must mint more than 0!");
//         uint256 price = getPrice(_quantity);

//         if(isUSDCMint) {
//         require(usdc.allowance(msg.sender, address(this)) >= price, "Insufficient allowance of usdc!");

//           uint256 feePercent = aliveRoyaltyFee;
//            address aliveRoyaltyRec = AliveRegistry(aliveRegistry)
//         .aliveHouseRoyaltyReceiver();
//         uint256 feePrice = (price * feePercent) / 100;
//             usdc.transferFrom(msg.sender, aliveRoyaltyRec, feePrice);
//             usdc.transferFrom(
//                 msg.sender,
//                 mintRoyaltyReceiver,
//                 price - feePrice
//             );
//         currentPrice = currentPrice + upcountRate * _quantity;

//         emit SongMinted(_to, _quantity, totalSupply(), address(this));


//         }
//       else {
//             require(msg.value >= price, "Insufficient funds!");
//         if (msg.value > price) {
//             payable(msg.sender).transfer(msg.value - price);
//         }

//         uint256 feePercent = aliveRoyaltyFee;
//         // uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
//         uint256 feePrice = (price * feePercent) / 100;
//         payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
//             .transfer(feePrice);
//         payable(mintRoyaltyReceiver).transfer(price - feePrice);
//         super._mint(_to, _quantity);

//         currentPrice = currentPrice + upcountRate * _quantity;

//         emit SongMinted(_to, _quantity, totalSupply(), address(this));
//       }
//     }


// function changeAliveRoyaltyFee(uint8 newAliveRoyaltyFee) external onlyAdmin {
//    aliveRoyaltyFee = newAliveRoyaltyFee;
// }

function getNFTData(uint amount, address _of) public view returns(uint _price, uint _totalSupply, uint _maxMintAmount, uint _upcountRate,uint _balanceOf, uint _startedAt) {
  return (getPrice(amount),totalSupply(), maxMintAmount, upcountRate, balanceOf(_of), startedAt);
}


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../AliveDutchSong.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AliveDutchSongV2 is AliveDutchSong {
// uint8 public aliveRoyaltyFee;
    // bool public isUSDCMint;
    // IERC20 public usdc;

//  function initialize(
//         address _aliveRegistry,
//         address _royaltyReceiverSecondary, // royalityReceiver
//         uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
//         address _royaltyReceiverSplit,
//         uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
//         string memory _songURI,
//         string memory _contractURI,
//         address _artist,
//         uint256 _songId,
//         uint256[6] memory _songInfos, 
//         uint8 _aliveRoyaltyFee,
//           IERC20 _usdc
//     ) external initializer initializerERC721A {
//         __ERC721A_init("AliveE3", "AE3");
//         _grantRole(DEFAULT_ADMIN_ROLE, _artist);
//         _grantRole(GOVERNANCE_ROLE, _artist);
//         _grantRole(PAUSER_ROLE, _artist);
//         band = msg.sender;
        
//         aliveRegistry = _aliveRegistry;
//         mintRoyaltyReceiver = _royaltyReceiverSplit;
//         offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
//         _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);  

//         songId = _songId;
//         baseURI = _songURI;
//         contractURI = _contractURI;
//         songType = 3;
//                 usdc = _usdc;

//         maxMintAmount = _songInfos[1];
//         ceilPrice = _songInfos[2];
//         floorPrice = _songInfos[3];
//         startedAt = _songInfos[4];
//         discountRate = _songInfos[5];
//         aliveRoyaltyFee = _aliveRoyaltyFee;



//         if (_songInfos[0] == 0) {
//             // matic payment

//         } else {
//             // usdc payment
//             isUSDCMint = true;
//         }
//     }

//      function mint(address _to, uint256 _quantity)
//         public
//         payable
//         override
//         whenNotPaused
//         nonReentrant
//     {  require(block.timestamp > startedAt);
//         require(
//             _quantity <
//                 AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
//                     songType),
//             "You can mint Songs more than Limit per mint!"
//         );
//         require(
//             totalSupply() + _quantity <= maxMintAmount,
//             "Can't mint more than Limit!"
//         );
//         require(_quantity > 0, "You must mint more than 0!");
//         uint256 price = getPrice(_quantity);

//         if(isUSDCMint) {
//  require(usdc.allowance(msg.sender, address(this)) >= price, "Insufficient allowance of usdc!");
       

//         uint256 feePercent = aliveRoyaltyFee;
//         // uint256 feePercent = AliveRegistry(aliveRegistry).feePercent(); //previous
//         address aliveRoyaltyRec = AliveRegistry(aliveRegistry)
//         .aliveHouseRoyaltyReceiver();
//         uint256 feePrice = (price * feePercent) / 100;
//             usdc.transferFrom(msg.sender, aliveRoyaltyRec, feePrice);
//             usdc.transferFrom(
//                 msg.sender,
//                 mintRoyaltyReceiver,
//                 price - feePrice
//             );
//         super._mint(_to, _quantity);
//         emit SongMinted(_to, _quantity, totalSupply(), address(this));
//         }

//         else {
//   require(msg.value >= price, "Insufficient funds!");
//         if (msg.value > price) {
//             payable(msg.sender).transfer(msg.value - price);
//         }

//         uint256 feePercent = aliveRoyaltyFee;
//         // uint256 feePercent = AliveRegistry(aliveRegistry).feePercent(); //previous
//         uint256 feePrice = (price * feePercent) / 100;
//         payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
//             .transfer(feePrice);
//         payable(mintRoyaltyReceiver).transfer(price - feePrice);
//         super._mint(_to, _quantity);
//         emit SongMinted(_to, _quantity, totalSupply(), address(this));
//         }
      
//     }


//     function changeAliveRoyaltyFee(uint8 newAliveRoyaltyFee) external onlyAdmin {
//    aliveRoyaltyFee = newAliveRoyaltyFee;
// }


function getNFTData(uint amount, address _address) public view returns(uint _price, uint _totalSupply, uint _maxMintAmount, uint _floorPrice, uint _ceilPrice, uint _discountRate,uint _balanceOf ,uint _startedAt ) {
    
  return (getPrice(amount),totalSupply(), maxMintAmount, floorPrice, ceilPrice, discountRate, balanceOf(_address), startedAt);
}


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./AliveCommonSong.sol";
import "../RegistryContracts/AliveRegistry.sol";

contract AliveFixedSong is AliveCommonSong {
    uint256 public songId;
    uint8 public songType;
    uint256 public initialPrice;
    uint256 public startedAt;////
    uint256 public whitelistPrice;
    mapping (address => bool) public isWhiteListed; // is wl?
    uint mintStopTime;
    
function whitelistBatch(address[] memory _wlAdd) public onlyAdmin {
  unchecked {
    for (uint i = 0; i < _wlAdd.length; i++) {
        isWhiteListed[_wlAdd[i]] = true;
    }
  }
}

function setWhiteListPrice(uint _wlPrice) public virtual onlyAdmin{
  whitelistPrice = _wlPrice;
}
function removeWhitelistBatch(address[] memory _wlRem) public onlyAdmin {
  unchecked {
    for (uint i = 0; i < _wlRem.length; i++) {
        isWhiteListed[_wlRem[i]] = false;
    }
  }
}


function getMaxMintAmount() public view virtual returns(uint){
  if(mintStopTime != 0 && block.timestamp > mintStopTime) {
      return totalSupply();
  }
else {
 return maxMintAmount;
     }
}


function setMintStopTime(uint _stopTime) public virtual onlyAdmin {
mintStopTime = _stopTime;
}

 

    function initialize(
        address _aliveRegistry,
        address _royaltyReceiverSecondary, // royalityReceiver
        uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256 _songId,
        uint256[3] memory _songInfos
    ) external initializer virtual initializerERC721A {
        __ERC721A_init("AliveE1", "AE1");
        _grantRole(DEFAULT_ADMIN_ROLE, _artist);
        _grantRole(GOVERNANCE_ROLE, _artist);
        _grantRole(PAUSER_ROLE, _artist);
        band = msg.sender;

        aliveRegistry = _aliveRegistry;
        mintRoyaltyReceiver = _royaltyReceiverSplit;
        offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
        _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);

        songId = _songId;
        baseURI = _songURI;
        contractURI = _contractURI;
        songType = 1;

        maxMintAmount = _songInfos[0];
        initialPrice = _songInfos[1];
        startedAt = _songInfos[2];
    
    }

 function getPrice(uint256 _quantity, address _to) virtual public view returns (uint256 price) {
     if(isWhiteListed[_to]) {
         return whitelistPrice*_quantity;
     }
     else {
        return initialPrice * _quantity;
     }
  }

  
    function mint(address _to, uint256 _quantity)
        public
        payable
        virtual
        whenNotPaused
        nonReentrant
    {   require(block.timestamp > startedAt);
        require(
            _quantity <
                AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
                    songType
                ),
            "You can mint Songs more than Limit per mint!"
        );
        require(
            totalSupply() + _quantity <= getMaxMintAmount(),
            "Can't mint more than Limit!"
        );
        require(_quantity > 0, "You must mint more than 0!");
        uint256 price = getPrice(_quantity, _to);
        require(msg.value >= price, "Insufficient funds!");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
        uint256 feePrice = (price * feePercent) / 100;
        payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
            .transfer(feePrice);
        payable(mintRoyaltyReceiver).transfer(price - feePrice);
        uint256 currentTotalSupply = totalSupply();
        super._mint(_to, _quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            addressTokenIds[_to].push(currentTotalSupply + i + 1);
        }
        emit SongMinted(_to, _quantity, totalSupply(), address(this));
    }


    
       function updateStartAt(uint256 time)public onlyAdmin {
        startedAt = time;
    }


    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "../../erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../RegistryContracts/AliveRegistry.sol";

contract AliveCommonSong is
    ERC721AUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /** @dev A struct that is a drop, a drop is a Matic Drop, that will be available for all the token holders at particular time to be able to claim and receive their share of matic  **/

    struct Drop {
        uint256 dropID;
        uint256 dropTotalAmount;
        uint256 dropPerNFT;
        uint256 totalClaimed;
        uint256 dropNumber;
    }

    /** @dev mapping for keeping track of drops and claims */

    mapping(uint256 => mapping(uint256 => bool)) public claimedOfTokenId;

    bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /** @dev some state variables */

    address public aliveRegistry; // address of the AliveRegistry contract, that stores all the important and dynamic data
    address public mintRoyaltyReceiver; // tha address where the funds will be sent to in each txn
    address public band; // address of the band, off which this song or nft is part of

    string baseURI; // the baseURI
    string public contractURI; // the song contract URI(for opensea)

    uint256 public offchainRoyaltyPercentageInBips; // the streaming revenue distribution of this particular edition, this is not each nft,
    // but each edition offchain distribution, to calculate how much a particular nft holder will get, we need to divide this by totalSupply

    uint256 public maxMintAmount; // masSupply of the nft collection
    mapping (uint => string) _idToTokenUri;

    Drop[] public allDrops; // collection of all the drops done by the artist for this particular edition

    mapping(address => uint256[]) public addressTokenIds;


    // Modifier
    modifier onlyGovernor() {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true ||
                hasRole(GOVERNANCE_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "only governor"
        );
        _;
    }

    // manager is fetched from registry contract, a manger has permission for functions that deploy some sort of contract or reste some data

    modifier onlyAdmin() {
        require(
            AliveRegistry(aliveRegistry).isManagerWallet(msg.sender) == true
        );
        _;
    }

    // Events
    event SongMinted(
        address owner,
        uint256 quantity,
        uint256 totalSupply,
        address songAddress
    );

    event ClaimDrop(
        address owner,
        uint256 dropID,
        uint256 tokenID,
        uint256 amount
    );

    event ClaimAllDrop(address owner, uint256 tokenID);

    /** @dev function that creates new drop, so artist or manager can send money through this function and it will use it as a drop which can be claimd equally by all token holders */

    function newDrop() public payable onlyGovernor {
        require(
            msg.value > 1 ether,
            "Min drop amount must be bigger than 1 ether!"
        );

        uint256 dropPerUnit = getdropPerUnit(msg.value, totalSupply());
        uint256 id = allDrops.length + 1;
        Drop memory newdrop = Drop(
            id,
            msg.value,
            dropPerUnit,
            0,
            totalSupply()
        );
        allDrops.push(newdrop);
        if (msg.value % totalSupply() != 0) {
            payable(msg.sender).transfer(msg.value % totalSupply());
        }
    }

    /** @dev a function to claim all the drops and send the money to particular token holder at the moment */

    function claimAllDrop(uint256 tokenID)
        external
        nonReentrant
        returns (bool success)
    {
        require(allDrops.length > 0, "No drops yet");

        unchecked {
            for (uint256 i = 1; i <= allDrops.length; i++) {
                if (
                    claimedOfTokenId[i][tokenID] == false &&
                    allDrops[i - 1].totalClaimed < allDrops[i - 1].dropNumber
                ) {
                    _claimDrop(i, tokenID);
                }
            }
        }
        emit ClaimAllDrop(ownerOf(tokenID), tokenID);
        return true;
    }

    function _claimDrop(uint256 dropID, uint256 tokenID) internal {
        require(claimedOfTokenId[dropID][tokenID] == false, "Already claimed");

        payable(ownerOf(tokenID)).transfer(allDrops[dropID - 1].dropPerNFT);
        claimedOfTokenId[dropID][tokenID] = true;
        emit ClaimDrop(
            ownerOf(tokenID),
            dropID,
            tokenID,
            allDrops[dropID - 1].dropPerNFT
        );

        unchecked {
            allDrops[dropID - 1].totalClaimed++;
        }
    }

    /** @dev function to claim a Drop that was done by the artist/owner. notice that this function doesn't require the msg.sender to be the holder of the nft, it distributes the funds on basis of token id ansd theiir holder and the time of distribution */
    function claimDrop(uint256 dropID, uint256 tokenID)
        public
        nonReentrant
        returns (bool)
    {
        require(allDrops.length >= dropID, "Drop doesn't exist");
        require(
            allDrops[dropID - 1].totalClaimed < allDrops[dropID - 1].dropNumber,
            "Drop empty"
        );
        _claimDrop(dropID, tokenID);
        return true;
    }

    // Get Claimed Status by Token ID - for instance : [true, false, ...] or [false, false, ...]

    function getClaimStatusByTokenID(uint256 tokenID)
        public
        view
        returns (bool[] memory)
    {
        uint256 length = allDrops.length;
        bool[] memory returnVal = new bool[](length);
        for (uint256 i = 1; i <= length; i++) {
            returnVal[i - 1] = claimedOfTokenId[i][tokenID];
        }
        return returnVal;
    }

    // get balance available from the drops which is unclaimed

    function myTotalBalance(uint256 _tokenId) public view returns (uint256) {
        require(allDrops.length > 0, "no drops yet");
        uint256 bal;
        uint256 start = 1;
        unchecked {
            for (uint256 i = start; i <= allDrops.length; i++) {
                if (
                    allDrops[i - 1].totalClaimed < allDrops[i - 1].dropNumber &&
                    claimedOfTokenId[i][_tokenId] == false
                ) {
                    bal = bal + allDrops[i - 1].dropPerNFT;
                }
            }
        }

        return bal;
    }

    // Get all token IDs by owner

    function getAllTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = addressTokenIds[_owner].length;
        uint256[] memory tokenIDs = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIDs[i] = addressTokenIds[_owner][i];
        }
        return tokenIDs;
    }

    function batchAirDrop(
        address[] memory _arrayOfReceivers,
        uint256 _amountForEach
    ) public onlyGovernor {
        require(
            totalSupply() + _arrayOfReceivers.length * _amountForEach <=
                maxMintAmount,
            "can't mint more than supply"
        );
        unchecked {
        for (uint256 i = 0; i < _arrayOfReceivers.length; i++) {
            super._mint(_arrayOfReceivers[i], _amountForEach);
           } 
        }
    }

    function getAllDrops() public view returns (Drop[] memory) {
        return allDrops;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory tempBaseURI = _baseURI();
        return
            bytes(tempBaseURI).length != 0
                ? string(abi.encodePacked(tempBaseURI))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) public onlyAdmin {
        _setTokenRoyalty(
            _tokenId,
            _royaltiesReceipientAddress,
            _percentageBasisPoints
        );
    }

    function updateRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setURI(string memory _uri) public onlyAdmin {
        baseURI = _uri;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function setContractURI(string memory _uri, string memory _nftname) external onlyAdmin {
        ERC721AStorage.layout()._name = _nftname;
        contractURI = _uri;
    }

    function pause() public onlyGovernor {
        _pause();
    }

    function unpause() public onlyGovernor {
        _unpause();
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        bytes4  _INTERFACE_ID_ERC2981 = 0x2a55205a;
        bytes4  _INTERFACE_ID_LIBROYALTIES = 0xcad96cca;

        if(interfaceId == _INTERFACE_ID_ERC2981 ) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_LIBROYALTIES ) {
            return true;
        }
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    // calculates drop amount for per nft

    function getdropPerUnit(uint256 totalVal, uint256 totalSupply)
        internal
        pure
        returns (uint256)
    {
        return (totalVal - (totalVal % totalSupply)) / totalSupply;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();
        
        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");
        
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    // function setNameAndSym(string memory name_, string memory _sym) internal {
    //        ERC721AStorage.layout()._name = name_;
    //     ERC721AStorage.layout()._symbol = _sym;
    // }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (ERC721AStorage.layout()._packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (ERC721AStorage.layout()._packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            ERC721AStorage.layout()._currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = ERC721AStorage.layout()._tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            ERC721AStorage.layout()._packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721AUpgradeable} from './ERC721AUpgradeable.sol';

library ERC721AStorage {
    struct Layout {
        // The tokenId of the next token to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See `_packedOwnershipOf` implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructorr()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructorr() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./AliveCommonSong.sol";
import "../RegistryContracts/AliveRegistry.sol";

contract AliveBondedSong is AliveCommonSong {
    uint256 public songId;
    uint8 public songType;
    uint256 public initialPrice;
    uint256 public currentPrice;
    uint256 public upcountRate;
    uint256 public startedAt;

    function initialize(
        address _aliveRegistry,
        address _royaltyReceiverSecondary, // royalityReceiver
        uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256 _songId,
        uint256[4] memory _songInfos
    ) external initializer virtual initializerERC721A {
        __ERC721A_init("AliveE2", "AE2");
        _grantRole(DEFAULT_ADMIN_ROLE, _artist);
        _grantRole(GOVERNANCE_ROLE, _artist);
        _grantRole(PAUSER_ROLE, _artist);

        band = msg.sender;

        aliveRegistry = _aliveRegistry;
        mintRoyaltyReceiver = _royaltyReceiverSplit;
        offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
        _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);

        songId = _songId;
        baseURI = _songURI;
        contractURI = _contractURI;
        songType = 2;

        maxMintAmount = _songInfos[0];
        initialPrice = _songInfos[1];
        currentPrice = _songInfos[1];
        upcountRate = _songInfos[2];
        startedAt = _songInfos[3];
    }

    function getPrice(uint256 _quantity)
        public
        view
        returns (uint256 totalPrice)
    {
        require(_quantity > 0);
        uint256 price = currentPrice;
        uint256 temp = currentPrice;

        unchecked {
            for (uint256 i = 1; i < _quantity; i++) {
                temp = temp + upcountRate;
                price = price + temp;
            }
        }
        return price;
    }

    function mint(address _to, uint256 _quantity)
        public
        payable
        whenNotPaused
        virtual
        nonReentrant
    {   require(block.timestamp > startedAt);
        require(
            _quantity <
                AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
                    songType
                ),
            "You can mint Songs more than Limit per mint!"
        );
        require(
            totalSupply() + _quantity <= maxMintAmount,
            "Can't mint more than Limit!"
        );
        require(_quantity > 0, "You must mint more than 0!");
        uint256 price = getPrice(_quantity);
        require(msg.value >= price, "Insufficient funds!");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
        uint256 feePrice = (price * feePercent) / 100;
        payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
            .transfer(feePrice);
        payable(mintRoyaltyReceiver).transfer(price - feePrice);
        super._mint(_to, _quantity);

        currentPrice = currentPrice + upcountRate * _quantity;

        emit SongMinted(_to, _quantity, totalSupply(), address(this));
    }


    function updateStartAt(uint256 time)public onlyAdmin {
        startedAt = time;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./AliveCommonSong.sol";
import "../RegistryContracts/AliveRegistry.sol";

contract AliveDutchSong is AliveCommonSong {
    uint256 public songId;
    uint8 public songType;
    uint256 public ceilPrice;
    uint256 public floorPrice;
    uint256 public startedAt;
    uint256 public discountRate;
    
    function initialize(
        address _aliveRegistry,
        address _royaltyReceiverSecondary, // royalityReceiver
        uint96 _royaltyFeesInBips, // this royality is for secondary sale and mint, which will be 0xsplit address of  band
        address _royaltyReceiverSplit,
        uint96 _offchainRoyaltyPercentageInBips, // bips = %*100 - this is in % roYALTY THAT THE ARTIST offers from the revenue generated from the band - 5% for e.g, this means artist will do a drop of 5% of his revenue for all his nft holders to claim the royalty.
        string memory _songURI,
        string memory _contractURI,
        address _artist,
        uint256 _songId,
        uint256[5] memory _songInfos
    ) external initializer virtual initializerERC721A {
        __ERC721A_init("AliveE3", "AE3");
        _grantRole(DEFAULT_ADMIN_ROLE, _artist);
        _grantRole(GOVERNANCE_ROLE, _artist);
        _grantRole(PAUSER_ROLE, _artist);
        band = msg.sender;
        
        aliveRegistry = _aliveRegistry;
        mintRoyaltyReceiver = _royaltyReceiverSplit;
        offchainRoyaltyPercentageInBips = _offchainRoyaltyPercentageInBips;
        _setDefaultRoyalty(_royaltyReceiverSecondary, _royaltyFeesInBips);  

        songId = _songId;
        baseURI = _songURI;
        contractURI = _contractURI;
        songType = 3;
        
        maxMintAmount = _songInfos[0];
        ceilPrice = _songInfos[1];
        floorPrice = _songInfos[2];
        startedAt = _songInfos[3];
        discountRate = _songInfos[4];
    }

    function getPrice(uint256 _quantity) public view returns (uint256 price) {
        if(block.timestamp > startedAt) {
        uint256 timeElapsed = block.timestamp - startedAt;

        uint256 discount = discountRate * timeElapsed;

        if (discount > ceilPrice || floorPrice > ceilPrice - discount) {
            return floorPrice * _quantity;
        } else {
            return (ceilPrice - discount) * _quantity;
           }
         }
       else { 
           return ceilPrice;
       }

    }

    function mint(address _to, uint256 _quantity)
        public
        payable
        virtual
        whenNotPaused
        nonReentrant
    {  require(block.timestamp > startedAt);
        require(
            _quantity <
                AliveRegistry(aliveRegistry).getAliveSongMaxMintPerTxByType(
                    songType),
            "You can mint Songs more than Limit per mint!"
        );
        require(
            totalSupply() + _quantity <= maxMintAmount,
            "Can't mint more than Limit!"
        );
        require(_quantity > 0, "You must mint more than 0!");
        uint256 price = getPrice(_quantity);
        require(msg.value >= price, "Insufficient funds!");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        uint256 feePercent = AliveRegistry(aliveRegistry).feePercent();
        uint256 feePrice = (price * feePercent) / 100;
        payable(AliveRegistry(aliveRegistry).aliveHouseRoyaltyReceiver())
            .transfer(feePrice);
        payable(mintRoyaltyReceiver).transfer(price - feePrice);
        super._mint(_to, _quantity);
        emit SongMinted(_to, _quantity, totalSupply(), address(this));
    }

       function updateStartAt(uint256 time)public onlyAdmin {
        startedAt = time;
    }
}