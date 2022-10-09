// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {AssetLayer} from "./AssetLayerV0_1.sol";
import {LogicProxy} from "./utils/LogicProxy.sol";
import {RawCallLib} from "./utils/RawCallLib.sol";

/// @author philogy <https://github.com/philogy>
contract LayerFactory is Ownable, Multicallable {
    using RawCallLib for address;

    event AppCreated(address indexed app);

    error CannotReduceExpiry();
    error NotApp();

    mapping(address => uint256) public getAppWatchExpiry;
    mapping(address => bool) public getCreatedHere;

    constructor() Ownable() {}

    /*//////////////////////////////////////////////////////////////
                          MANAGE APPS
    //////////////////////////////////////////////////////////////*/

    function setAppWatchExpiry(address _app, uint256 _newExpiry)
        external
        onlyOwner
    {
        if (_newExpiry <= getAppWatchExpiry[_app]) revert CannotReduceExpiry();
        getAppWatchExpiry[_app] = _newExpiry;
    }

    function callApp(address _app, bytes memory _data) external onlyOwner {
        if (!getCreatedHere[_app]) revert NotApp();
        _app.rawCall(_data);
    }

    /*//////////////////////////////////////////////////////////////
                           CREATE APP
    //////////////////////////////////////////////////////////////*/

    function createApp(address _upgrader, address _implementation) external {
        _registerApp(new AssetLayer(_upgrader, _implementation));
    }

    function createAppAndCall(
        address _upgrader,
        address _implementation,
        bytes memory _logicInitData
    ) external payable {
        AssetLayer assetLayer = new AssetLayer(_upgrader, _implementation);
        address logicModule = address(assetLayer.logicModule());
        logicModule.rawCall(_logicInitData, msg.value);
        _registerApp(assetLayer);
    }

    function _registerApp(AssetLayer _assetLayer) internal {
        address app = address(payable(_assetLayer));
        getCreatedHere[app] = true;
        emit AppCreated(app);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                // prettier-ignore
                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    // prettier-ignore
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {Math} from "@openzeppelin/utils/math/Math.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {LogicProxy} from "./utils/LogicProxy.sol";
import {RawCallLib} from "./utils/RawCallLib.sol";
import {IAssetLayerV0_1} from "./IAssetLayerV0_1.sol";

/// @author philogy <https://github.com/philogy>
contract AssetLayer is IAssetLayerV0_1, Multicallable {
    using SafeTransferLib for ERC20;
    using SafeCastLib for uint256;
    using MerkleProofLib for bytes32[];
    using RawCallLib for address;

    event WithdrawalAdded(
        WithdrawalType indexed wtype,
        address indexed asset,
        address indexed recipient,
        uint256 assetDenominator,
        uint256 settlesAt
    );

    error NotLogicModule();
    error AttemptedReentrancy();
    error TooLargeTotalDelay();
    error AlreadySettled();
    error NotYetSettled();
    error UnknownSettlementStatus();
    error NonexistentWithdrawal();
    error InvalidWithdrawalType();
    error Frozen();
    error NotFrozen();

    enum WithdrawalType {
        None,
        ERC20,
        ERC721,
        NATIVE
    }

    struct Withdrawal {
        uint64 enqueuedAt;
        uint24 delay;
        WithdrawalType wtype;
        address asset;
        address recipient;
        uint256 assetDenominator; // amount token ID
    }

    struct Freeze {
        uint64 lastEnd;
        uint64 start;
        bytes32 validWithdrawalsRoot;
    }

    address public immutable factory;

    mapping(uint256 => Withdrawal) public getWithdrawal;
    mapping(uint256 => Freeze) public getFreeze;

    uint8 internal constant NO_ENTRY = 1;
    uint8 internal constant SINGLE_ENTRY = 2;

    uint8 internal reentryGuard = NO_ENTRY;
    uint64 internal nextWithdrawalId;
    uint24 public withdrawDefaultDelay;
    address payable public logicModule;

    uint64 internal delayExtendTime = 1;
    uint24 internal delayExtension = 1;
    uint64 internal lastFreeze;
    uint64 internal nextFreezeId;
    bool internal isFrozen;

    address public upgrader;

    modifier only(address _authAccount) {
        if (msg.sender != _authAccount) revert NotLogicModule();
        _;
    }

    modifier nonReentrant() {
        if (reentryGuard == SINGLE_ENTRY) revert AttemptedReentrancy();
        reentryGuard = SINGLE_ENTRY;
        _;
        reentryGuard = NO_ENTRY;
    }

    modifier existingWithdrawal(uint256 _withdrawalId) {
        if (
            _withdrawalId >= nextWithdrawalId &&
            getWithdrawal[_withdrawalId].wtype != WithdrawalType.None
        ) revert NonexistentWithdrawal();
        _;
    }

    modifier whileNotFrozen() {
        if (isFrozen) revert Frozen();
        _;
    }

    constructor(address _upgrader, address _initialLogicImpl) {
        factory = msg.sender;
        upgrader = _upgrader;
        logicModule = payable(new LogicProxy(address(this), _initialLogicImpl));
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                          PULL ASSETS
    //////////////////////////////////////////////////////////////*/

    function pullERC20(
        address _token,
        address _sender,
        uint256 _tokenAmount
    )
        external
        only(logicModule)
        nonReentrant
        returns (uint256 depositedAmount)
    {
        uint256 balBefore = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransferFrom(_sender, address(this), _tokenAmount);
        depositedAmount = ERC20(_token).balanceOf(address(this)) - balBefore;
    }

    function naivePullERC20(
        address _token,
        address _sender,
        uint256 _tokenAmount
    ) external only(logicModule) nonReentrant {
        ERC20(_token).safeTransferFrom(_sender, address(this), _tokenAmount);
    }

    function pullERC721(
        address _collection,
        address _owner,
        uint256 _tokenId
    ) external only(logicModule) nonReentrant {
        IERC721(_collection).transferFrom(_owner, address(this), _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                         LOGIC UPGRADES
    //////////////////////////////////////////////////////////////*/

    function setUpgrader(address _newUpgrader) external only(upgrader) {
        upgrader = _newUpgrader;
    }

    function setLogicModule(address _newLogicModule) external only(upgrader) {
        logicModule = payable(_newLogicModule);
    }

    function upgradeAndCallProxyLogic(
        address _newLogicImplementation,
        bool _doPostCall,
        bytes memory _postUpgradeData
    ) external payable only(upgrader) {
        address payable logicModuleCached = logicModule;
        LogicProxy(logicModuleCached).upgradeTo(_newLogicImplementation);
        if (_doPostCall) address(logicModuleCached).rawCall(_postUpgradeData);
    }

    /*//////////////////////////////////////////////////////////////
                     MONITOR ADMIN METHODS
    //////////////////////////////////////////////////////////////*/

    function setDefaultDelay(uint24 _delay) external only(factory) {
        withdrawDefaultDelay = _delay;
    }

    function extendGlobalDelay(uint256 _delayIncrease) external only(factory) {
        uint256 delayExtendTimeCached = delayExtendTime;
        uint256 delayExtensionCached = delayExtension;
        if (delayExtendTimeCached == 0) {
            delayExtendTime = uint64(block.timestamp);
            delayExtension = _delayIncrease.safeCastTo24();
        } else {
            delayExtendTime = Math
                .max(
                    delayExtendTimeCached,
                    block.timestamp - delayExtensionCached
                )
                .safeCastTo64();
            delayExtension = (delayExtensionCached + _delayIncrease)
                .safeCastTo24();
        }
    }

    function resetGlobalDelayIncrease() external only(factory) {
        delayExtendTime = 1;
        delayExtension = 1;
    }

    /*//////////////////////////////////////////////////////////////
                        ASSET WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    function withdrawERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external only(logicModule) {
        _addWithdrawal(WithdrawalType.ERC20, _token, _recipient, _amount);
    }

    function withdrawERC721(
        address _token,
        address _recipient,
        uint256 _tokenId
    ) external only(logicModule) {
        _addWithdrawal(WithdrawalType.ERC721, _token, _recipient, _tokenId);
    }

    function withdrawNative(address _recipient, uint256 _amount)
        external
        only(logicModule)
    {
        _addWithdrawal(WithdrawalType.NATIVE, address(0), _recipient, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                           SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    function executeDirectSettlement(uint256 _withdrawalId)
        external
        existingWithdrawal(_withdrawalId)
    {
        if (!settled(_withdrawalId)) revert NotYetSettled();
        _executeSettlement(_withdrawalId);
    }

    function executePreFreezeSettlement(
        uint256 _withdrawalId,
        uint256 _freezeId
    ) external existingWithdrawal(_withdrawalId) {
        (uint256 origTime, uint256 settlementTime) = _getSettlementTime(
            _withdrawalId
        );
        uint256 lastEnd = getFreeze[_freezeId].lastEnd;
        uint256 start = getFreeze[_freezeId].start;
        if (origTime < lastEnd || start < settlementTime)
            revert UnknownSettlementStatus();
        _executeSettlement(_withdrawalId);
    }

    function executeValidWithdrawalSettlement(
        uint256 _withdrawalId,
        uint256 _freezeId,
        bytes32[] calldata _proof
    ) external existingWithdrawal(_withdrawalId) {
        if (
            !_proof.verify(
                getFreeze[_freezeId].validWithdrawalsRoot,
                bytes32(_withdrawalId)
            )
        ) revert UnknownSettlementStatus();
        _executeSettlement(_withdrawalId);
    }

    function settled(uint256 _withdrawalId) public view returns (bool) {
        (uint256 origTime, uint256 settlementTime) = _getSettlementTime(
            _withdrawalId
        );
        if (origTime < lastFreeze) revert UnknownSettlementStatus();
        return settlementTime <= block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                       EMERGENCY ACTIONS
    //////////////////////////////////////////////////////////////*/

    function extendWithdrawalDelay(uint256 _withdrawalId, uint24 _addedDelay)
        external
        only(factory)
        existingWithdrawal(_withdrawalId)
    {
        if (settled(_withdrawalId)) revert AlreadySettled();
        getWithdrawal[_withdrawalId].delay += _addedDelay;
    }

    function freeze() external only(factory) whileNotFrozen {
        lastFreeze = uint64(block.timestamp);
        uint256 freezeId = nextFreezeId;
        isFrozen = true;
        getFreeze[freezeId].start = uint64(block.timestamp);
    }

    function unfreeze(bytes32 _validWithdrawalsRoot)
        external
        only(factory)
        whileNotFrozen
    {
        if (!isFrozen) revert NotFrozen();
        isFrozen = false;
        getFreeze[nextFreezeId++].validWithdrawalsRoot = _validWithdrawalsRoot;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function _addWithdrawal(
        WithdrawalType _wtype,
        address _asset,
        address _recipient,
        uint256 _assetDenominator
    ) internal whileNotFrozen {
        unchecked {
            uint256 withdrawalId = nextWithdrawalId++;
            uint256 delay = withdrawDefaultDelay;
            getWithdrawal[withdrawalId] = Withdrawal({
                enqueuedAt: uint64(block.timestamp),
                delay: uint24(delay),
                wtype: _wtype,
                asset: _asset,
                recipient: _recipient,
                assetDenominator: _assetDenominator
            });

            emit WithdrawalAdded(
                _wtype,
                _asset,
                _recipient,
                _assetDenominator,
                block.timestamp + delay
            );
        }
    }

    function _executeSettlement(uint256 _withdrawalId) internal nonReentrant {
        WithdrawalType wtype = getWithdrawal[_withdrawalId].wtype;
        address asset = getWithdrawal[_withdrawalId].asset;
        address recipient = getWithdrawal[_withdrawalId].recipient;
        uint256 assetDenominator = getWithdrawal[_withdrawalId]
            .assetDenominator;
        delete getWithdrawal[_withdrawalId];
        if (wtype == WithdrawalType.ERC20) {
            ERC20(asset).safeTransfer(recipient, assetDenominator);
        } else if (wtype == WithdrawalType.ERC721) {
            IERC721(asset).transferFrom(
                address(this),
                recipient,
                assetDenominator
            );
        } else if (wtype == WithdrawalType.NATIVE) {
            SafeTransferLib.safeTransferETH(recipient, assetDenominator);
        } else {
            revert InvalidWithdrawalType();
        }
    }

    function _getSettlementTime(uint256 _withdrawalId)
        internal
        view
        returns (uint256 origTime, uint256 settlementTime)
    {
        origTime = getWithdrawal[_withdrawalId].enqueuedAt;
        uint256 origDelay = getWithdrawal[_withdrawalId].enqueuedAt;
        settlementTime = _addDelay(
            origTime + origDelay,
            delayExtendTime,
            delayExtension
        );
    }

    function _addDelay(
        uint256 _origSettlementTime,
        uint256 _addedTime,
        uint256 _addedDelay
    ) internal pure returns (uint256) {
        if (_addedTime == 1) return _origSettlementTime;
        return
            _origSettlementTime < _addedTime
                ? _origSettlementTime
                : _origSettlementTime + _addedDelay;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/// @author philogy <https://github.com/philogy>
contract LogicProxy {
    // `keccak256("eip1967.proxy.implementation") - 1`
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public immutable getAssetLayer;

    constructor(address _assetLayer, address _startImplementation) {
        getAssetLayer = _assetLayer;
        _setImplementation(_startImplementation);
    }

    fallback() external payable {
        _delegateToImpl();
    }

    /*
     * @dev Sets implementation if caller is `assetLayer`, forwards to
     * implementation otherwise incase it has its own `upgradeTo` method.
     * */
    function upgradeTo(address _newImpl) external payable {
        if (msg.sender == getAssetLayer) _setImplementation(_newImpl);
        else _delegateToImpl();
    }

    /*
     * @dev Forwards calldata to implementation sending any ETH to the
     * `assetLayer`.
     * */
    function _delegateToImpl() internal {
        // store immutable locally since immutables not supported in assembly
        address assetLayer = getAssetLayer;
        assembly {
            // deposit any ETH directly into asset layer
            if callvalue() {
                pop(call(gas(), assetLayer, callvalue(), 0, 0, 0, 0))
            }
            // forward calldata to implementation
            calldatacopy(0x00, 0x00, calldatasize())
            let success := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                0x00,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0x00, 0x00, returndatasize())
            if success {
                return(0x00, returndatasize())
            }
            revert(0x00, returndatasize())
        }
    }

    function _setImplementation(address _impl) internal {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _impl)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/// @author philogy <https://github.com/philogy>
library RawCallLib {
    function rawCall(address _addr, bytes memory _data) internal {
        rawCall(_addr, _data, 0);
    }

    function rawCall(
        address _addr,
        bytes memory _data,
        uint256 _value
    ) internal {
        assembly {
            let success := call(
                gas(),
                _addr,
                _value,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            if iszero(success) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

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

    /*//////////////////////////////////////////////////////////////
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

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leafs` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        assembly {
            // If the number of flags is correct.
            // prettier-ignore
            for {} eq(add(leafs.length, proof.length), add(flags.length, 1)) {} {

                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leafs[0]) == root`.
                    isValid := eq(
                        calldataload(
                            xor(leafs.offset, mul(xor(proof.offset, leafs.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leafs into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                // Left shift by 5 is equivalent to multiplying by 0x20.
                calldatacopy(hashesFront, leafs.offset, shl(5, leafs.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leafs.length))
                // This is the end of the memory for the queue.
                let end := add(hashesBack, shl(5, flags.length))

                let flagsOffset := flags.offset
                let proofOffset := proof.offset

                // prettier-ignore
                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flagsOffset)) {
                        // Loads the next proof.
                        b := calldataload(proofOffset)
                        proofOffset := add(proofOffset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }
                    
                    // Advance to the next flag offset.
                    flagsOffset := add(flagsOffset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    // prettier-ignore
                    if iszero(lt(hashesBack, end)) { break }
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(mload(sub(hashesBack, 0x20)), root)
                break
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/// @author philogy <https://github.com/philogy>
interface IAssetLayerV0_1 {
    function pullERC20(
        address _collection,
        address _sender,
        uint256 _tokenAmount
    ) external returns (uint256);

    function naivePullERC20(
        address _collection,
        address _sender,
        uint256 _tokenAmount
    ) external;

    function pullERC721(
        address _collection,
        address _owner,
        uint256 _tokenId
    ) external;

    function withdrawERC20(
        address _token,
        address _recipient,
        uint256 _tokens
    ) external;

    function withdrawERC721(
        address _token,
        address _recipient,
        uint256 _tokenId
    ) external;

    function withdrawNative(address _recipient, uint256 _amount) external;
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