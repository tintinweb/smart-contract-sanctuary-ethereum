// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./utils/MulSingers.sol";
import "./utils/MulTx.sol";
import "./interfaces/IERCMulSinger.sol";
import "./utils/CountersUpgradeable.sol";
import "./interfaces/IERCSingerManage.sol";

/// @title MulSinger
///@author li
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract MulSinger is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IERCMulSinger,
    IERCSingerManage
{
    using MulSingers for MulSingers.Singer;
    using MulTx for MulTx.Mtx;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private counter;

    address public admin;

    // xthash==>singer
    mapping(uint => MulSingers.Singer) public mulSingers;

    //xthash=>tx
    mapping(uint => MulTx.Mtx) public mulTx;

    //address =>singer
    mapping(address => IERCSingerManage.Singer) public singers;

    //address=>xthash  address own txhash
    mapping(address => uint[]) public singerTxHash;
    // txid =>txhash
    mapping(uint => uint) public txhashs;
    // address =>txhash  address push txhash
    mapping(address => uint[]) public singerSendTxHash;

    function initialize(address txAdmin) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        admin = txAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier txUnOver(uint txHash) {
        MulSingers.Singer storage singer = mulSingers[txHash];
        require(
            singer.status == MulSingers.SingerStatus.Created ||
                singer.status == MulSingers.SingerStatus.Pending,
            "Singer is finished"
        );
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //writer a createMulSinger function  param with singers address arrary and txParams withb MulTx.Mtx struct的filed to create MulTx.Mtx and  MulSinger
    function createMulSingerTx(
        uint amount,
        uint when,
        address to,
        string memory blank,
        MulTx.TxType txType,
        uint txId
    ) external override {
        if(txType != MulTx.TxType.ChangeSinger  && txhashs[txId] != 0){
            revert("txId is exist");
        }
          IERCSingerManage.Singer storage singer = singers[msg.sender];
        if (singer.singers.length == 0) {
            revert("Singer is empty");
        }
        counter.increment();
        MulTx.Mtx memory mtx = MulTx.initialize(
            msg.sender,
            to,
            txType,
            counter.current(),
            txId,
            amount,
            when,
            blank
        );
        mulTx[mtx.txHash] = mtx;
        //judge singerSendTxHash[msg.sender] do not contain mtx.txhash
        for (uint i = 0; i < singerSendTxHash[msg.sender].length; i++) {
            if (singerSendTxHash[msg.sender][i] == mtx.txHash) {
                revert("txhash is exist");
            }
        }
      
        MulSingers.Singer storage singerTx = mulSingers[mtx.txHash];
        singerTx.initialize(
            singer.singers,
            mtx.txHash,
            singer.threshold,
            mtx.when
        );
        txhashs[txId] = mtx.txHash;
        singerSendTxHash[msg.sender].push(mtx.txHash);

        emit CreateMulSinger(msg.sender, singerTx.txHash, mtx.txId);
    }

    //add address  and txhash  to singerTxHash map's txhash array,but txhash array has a unique value
    function addSingerTxHash(address singer, uint txHash) internal {
        uint[] storage txHashs = singerTxHash[singer];
        for (uint i = 0; i < txHashs.length; i++) {
            if (txHashs[i] == txHash) {
                return;
            }
        }
        txHashs.push(txHash);
    }

    //force to over mul singer by TxHash
    //wirte  the forceOverMulSinger  method comment
    ///@param TxHash @type uint @description tx hash
    function forceOverMulSinger(
        uint TxHash
    ) external override onlyAdmin txUnOver(TxHash) {
        MulSingers.Singer storage singer = mulSingers[TxHash];
        singer.overSinger();
        emit ForceOverMulSinger(msg.sender, TxHash, singer.txHash);
    }

    //query current singer unsing mtx list  return  MulTx.Mtxa
    function getSingerMtxs() external view returns (MulTx.Mtx[] memory) {
        uint[] storage txHashs = singerTxHash[msg.sender];
        MulTx.Mtx[] memory mtxs = new MulTx.Mtx[](txHashs.length);
        for (uint i = 0; i < txHashs.length; i++) {
            mtxs[i] = mulTx[txHashs[i]];
        }
        return mtxs;
    }

    // singer to approve mul singer by TxHash
    function approveMulSinger(uint txHash) external override {
        MulSingers.Singer storage singer = mulSingers[txHash];
        require(!singer.isSingerFinished(), "Singer is finished");
        require(
            singer.getSingerStatusBySinger(msg.sender) ==
                MulSingers.SingerStatus.Created,
            "Singer is not Created"
        );
        require(singer.hasSinger(msg.sender), "Singer is not in singer list");
        singer.setSingerResult(msg.sender, MulSingers.SingerStatus.Approved);

        MulTx.Mtx memory mtx = mulTx[txHash];
        if (singer.isSingerFinished()) {
            singer.setSingerStatus();
            if (singer.getSingerStatus() == MulSingers.SingerStatus.Approved) {
                if (mtx.txType == MulTx.TxType.ChangeSinger) {
                    IERCSingerManage.Singer storage singerManage = singers[
                        mtx.from
                    ];
                    if (singer.hasSinger(mtx.to)) {
                        //singers remove mtx.tos
                        for (uint i = 0; i < singerManage.singers.length; i++) {
                            if (singerManage.singers[i] == mtx.to) {
                                singerManage.singers[i] = singerManage.singers[
                                    singerManage.singers.length - 1
                                ];
                                singerManage.singers.pop();
                                break;
                            }
                        }
                        singerManage.threshold = singerManage.threshold - 1;
                        emit RemoveSinger(mtx.to, mtx.from);
                    } else {
                        //add mtx.to to singers
                        singerManage.singers.push(mtx.to);
                        singerManage.threshold = singerManage.threshold + 1;
                        emit AddSinger(mtx.to, mtx.from);
                    }
                } else {
                    emit ExecuteMulSinger(txHash, mtx.txId);
                }
            } else if (
                singer.getSingerStatus() == MulSingers.SingerStatus.Rejected
            ) {
                emit RejectMulSinger(txHash, mtx.txId);
            }
        }
        emit ApproveMulSinger(msg.sender, txHash, mtx.txId);
    }

    function startMulSinger(uint txHash) external override onlyAdmin {
        require(txHash != 0, "txHash is zero");
        MulSingers.Singer storage singer = mulSingers[txHash];

        require(
            singer.status == MulSingers.SingerStatus.Created,
            "Singer is had start"
        );
        require(
            singer.getSingerExpire() > block.timestamp,
            "Singer is expired"
        );
        MulTx.Mtx storage mtx = mulTx[txHash];
        require(mtx.txHash == txHash, "txHash is not exist");
        singer.StartSinger();
        for (uint i = 0; i < singer.singers.length; i++) {
            addSingerTxHash(singer.singers[i], txHash);
        }
        emit StartMulSinger(msg.sender, txHash, mtx.txId);
    }

    function setSingers(
        address[] memory singer,
        uint threshold,
        uint256 userId
    ) external override {
        require(singer.length > 0, "Singer is empty");
        require(threshold > 0, "Threshold is zero");
        require(singer.length >= threshold, "Threshold is bigger than singer");
        require(singer.length <= 10, "Singer is bigger than 10");
        require(singers[msg.sender].singers.length == 0, "Singer is not empty");
        require(userId > 0, "user id is no");
        //require singer items is unique
        for (uint i = 0; i < singer.length; i++) {
            for (uint j = i + 1; j < singer.length; j++) {
                if (singer[i] == singer[j]) {
                    revert("singer is not unique");
                }
            }
        }
        IERCSingerManage.Singer storage singerManage = singers[msg.sender];
        singerManage.singers = singer;
        singerManage.threshold = threshold;
        emit CreateSinger(singer, threshold, msg.sender, userId);
    }

    function getSinger(
        address singer
    ) external view returns (address[] memory) {
        return singers[singer].singers;
    }

    ///todo: only test
    function getBlockTime() external view returns (uint) {
        return block.timestamp;
    }

    ///todo: only test
    function getExpireTime(uint txHash) external view returns (uint) {
        MulSingers.Singer storage singer = mulSingers[txHash];
        return singer.getSingerExpire();
    }

    function getMulTxSinger(
        uint txhash
    ) external view returns (address[] memory) {
        address[] memory s = mulSingers[txhash].singers;
        return s;
    }

    function getSenderTxHash() external view returns (uint[] memory) {
        return singerSendTxHash[msg.sender];
    }

    function getSingerStatus(
        uint txHash
    ) external view returns (MulSingers.SingerStatus) {
        MulSingers.Singer storage singer = mulSingers[txHash];
        return singer.getSingerStatus();
    }

    function getSingerNum(uint txHash) external view returns (uint) {
        MulSingers.Singer storage singer = mulSingers[txHash];
        return singer.getSingedNum();
    }

    function getSingerThreshold(address owner) external view returns (uint) {
        IERCSingerManage.Singer storage singer = singers[owner];
        return singer.threshold;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../upgrade/utils/Initializable.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.9;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

import "../utils/MulSingers.sol";
import "../utils/MulTx.sol";

interface  IERCMulSinger {

    event CreateMulSinger(address sender, uint indexed txHash, uint  indexed txId);

    event ForceOverMulSinger(address sender,uint indexed txHash, uint  indexed txId);

    event ApproveMulSinger(address sender,uint indexed txHash,uint  indexed txId);

    event StartMulSinger(address sender,uint indexed txHash,uint indexed txId);

    event RejectMulSinger(uint indexed txHash,uint indexed txId);

    event ExecuteMulSinger(uint indexed txHash,uint indexed txId);


   //writer a createMulSinger function  param with singers address arrary and txParams withb MulTx.Mtx struct的filed to create MulTx.Mtx and  MulSinger
    function createMulSingerTx(uint amount,uint when, address to, string memory blank, MulTx.TxType txType,uint txId) external;

     //force to over mul singer by TxHash
   function forceOverMulSinger(uint TxHash) external;

   // singer to approve mul singer by TxHash
   function approveMulSinger(uint TxHash) external;

   function startMulSinger(uint TxHash) external;


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.9;

interface IERCSingerManage {
    struct Singer {
        address[] singers;
        uint threshold;
    }

    event CreateSinger(address[] singer, uint threshold,address sender, uint256 indexed userId);

    event AddSinger(address singer,address sender);

    event RemoveSinger(address singer,address sender);


     function setSingers(address[] memory singer, uint threshold,uint256 userId) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.9;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.9;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/IERC1822ProxiableUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.9;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.9;

import "../../interfaces/IERC1822ProxiableUpgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.9;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;
import "../upgrade/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.9;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (MulSingers.sol)

pragma solidity ^0.8.9;


library MulSingers {
    enum SingerStatus {Created,Pending,Approved,Rejected,Executed}

    struct Singer {
        address[] singers;
        uint txHash;
        uint threshold;
        uint   expire;
        SingerStatus status;
       mapping(address=>SingerStatus) singerResult;
    }

    function addSinger(Singer storage self,address singer) internal {
        self.singers.push(singer);
    }
    function getSinger(Singer storage self,uint256 index) internal view returns(address){
        return self.singers[index];
    }
    function getSingerLength(Singer storage self) internal view returns(uint256){
        return self.singers.length;
    }
    function setTxHash(Singer storage self,uint256 TxHash) internal {
        self.txHash=TxHash;
    }
    function getTxHash(Singer storage self) internal view returns(uint256){
        return self.txHash;
    }
    function setThreshold(Singer storage self,uint256 Threshold) internal {
        self.threshold=Threshold;
    }
    function getThreshold(Singer storage self) internal view returns(uint256){
        return self.threshold;
    }

    function initialize(Singer storage self,address[] memory singers,uint TxHash,uint Threshold,uint expire) internal {
        for(uint256 i=0;i<singers.length;i++){
            self.singers.push(singers[i]);
        }
        self.txHash=TxHash;
        self.threshold=Threshold;
        self.expire=expire;
        self.status=SingerStatus.Created;
    }

    function setSingerResult(Singer storage self,address singer,SingerStatus status) internal {
         if(self.status != SingerStatus.Pending){
            revert("Singer is not pending");
         }
        self.singerResult[singer]=status;
    }
    function getSingerApprovedNum(Singer storage self) internal view returns(uint256){
        uint256 num=0;
        for(uint256 i=0;i<self.singers.length;i++){
            if(self.singerResult[self.singers[i]]==SingerStatus.Approved){
                num++;
            }
        }
        return num;
    }

//Get the number of people who have signed
    function getSingedNum(Singer storage self) internal view returns(uint256){
        uint256 num=0;
        for(uint256 i=0;i<self.singers.length;i++){
            if(self.singerResult[self.singers[i]]!=SingerStatus.Created){
                num++;
            }
        }
        return num;
    }
    //Judging whether the signature has ended according to whether it has expired or whether the number of signers is greater than the threshold
    function isSingerFinished(Singer storage self) internal view returns(bool){
         if(self.status != SingerStatus.Pending){
            return true;
         }
        if(block.timestamp>self.expire){
            return true;
        }
        if(getSingedNum(self)>=self.threshold){
            return true;
        }
        return false;
    }
    // Judging whether the signature is agreed or rejected according to whether the number of signed Approved is greater than the threshold
    function isSingerApproved(Singer storage self) internal view returns(bool){
        if(getSingerApprovedNum(self)>=self.threshold){
            return true;
        }
        return false;
    }
    function StartSinger(Singer storage self) internal {
        self.status=SingerStatus.Pending;
    }

    function getUnSinger(Singer storage self) internal view returns(address[] memory){
        address[] memory unsingers=new address[](self.singers.length);
        uint256 index=0;
        for(uint256 i=0;i<self.singers.length;i++){
            if(self.singerResult[self.singers[i]]==SingerStatus.Created){
                unsingers[index]=self.singers[i];
                index++;
            }
        }
        return unsingers;
    }

    function getAllSinger(Singer storage self) internal view returns(address[] memory){
        address[] memory allsingers=new address[](self.singers.length);
        for(uint256 i=0;i<self.singers.length;i++){
            allsingers[i]=self.singers[i];
        }
        return allsingers;
    }

    // force to over singer with rejiect
    function overSinger(Singer storage self) internal {
          if(self.status==SingerStatus.Executed){
           revert("singer is executed");
        }
        self.status=SingerStatus.Rejected;
    }
  //judge current singer lastest status and set status
    function setSingerStatus(Singer storage self) internal {
        if(self.status==SingerStatus.Executed){
           revert("singer is executed");
        }
        if(self.status==SingerStatus.Pending){
            if(isSingerFinished(self)){
                if(isSingerApproved(self)){
                    self.status=SingerStatus.Approved;
                }else{
                    self.status=SingerStatus.Rejected;
                }
            }
        }
    }
    function getSingerStatus(Singer storage self) internal view returns(SingerStatus){
        return self.status;
    }
    function getSingerStatusBySinger(Singer storage self,address singer) internal view returns(SingerStatus){
        return self.singerResult[singer];
    }
    function getSingerExpire(Singer storage self) internal view returns(uint256){
        return self.expire;
    }
    function setSingerExpire(Singer storage self,uint256 expire) internal {
        self.expire=expire;
    }

    function hasSinger(Singer storage self,address singer) internal view returns(bool){
        for(uint256 i=0;i<self.singers.length;i++){
            if(self.singers[i]==singer){
                return true;
            }
        }
        return false;
    }




}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (MulTx.sol)

pragma solidity ^0.8.9;

library MulTx {

    enum TxType{
        WithDraw,
        Exchange,
        ChangeSinger
    }
    struct Mtx{
      string  blank;
      uint txId;
      uint amount;
      uint when;
      address to;
      address from;
      uint index;
      TxType txType;
      uint txHash;
   }

   function initialize(address from,address to,TxType txType,uint index,uint txId,uint amount,uint when,string memory blank) internal  pure returns ( Mtx memory){
       Mtx memory self;
       self.amount=amount;
       self.when=when;
       self.to=to;
       self.txType=txType;
       self.index=index;
       self.txId=txId;
       self.from=from;
       self.blank=blank;
       self.txHash=uint(getTxkeccak256Hash(self));
       return self;
   }
   function getTxkeccak256Hash(Mtx memory self) internal pure returns(bytes32){
       return keccak256(abi.encode(self.amount,self.when,self.to,self.txType, self.index, self.txId,keccak256(abi.encode(self.blank))));
   }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.9;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}