// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {INativePool} from "./interfaces/INativePool.sol";
import {INativeRouter} from "./interfaces/INativeRouter.sol";
import {INativeTreasury} from "./interfaces/INativeTreasury.sol";
import {IWETH9} from "./libraries/IWETH9.sol";
import {Orders} from "./libraries/Order.sol";
import {Blacklistable} from "./Blacklistable.sol";
import {Registry} from "./Registry.sol";
import {NativeRouter} from "./NativeRouter.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/FullMath.sol";
import "./libraries/NoDelegateCallUpgradable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./storage/NativePoolStorage.sol";

contract NativePool is
    INativePool,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    NoDelegateCallUpgradable,
    Blacklistable,
    UUPSUpgradeable,
    NativePoolStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWETH9;
    uint256 public constant FIXED_PRICE_MODEL_ID = 99;
    uint256 public constant PMM_PRICE_MODEL_ID = 100;
    uint256 public constant CONSTANT_SUM_PRICE_MODEL_ID = 0;
    uint256 public constant UNISWAP_V2_PRICE_MODEL_ID = 1;
    uint256 internal constant TEN_THOUSAND_DENOMINATOR = 10000;
    uint256 internal constant TOKEN_ARRAY_MAX_LENGTH = 10;
    bytes32 private constant ORDER_SIGNATURE_HASH =
        keccak256(
            "Order(uint256 id,address signer,address buyer,address seller,address buyerToken,address sellerToken,uint256 buyerTokenAmount,uint256 sellerTokenAmount,uint256 deadlineTimestamp,address caller,bytes16 quoteId)"
        );

    modifier onlyRouter() {
        require(msg.sender == router, "Message sender should only be the router");
        _;
    }

    modifier onlyNotPmm() {
        require(!isPmm, "Not allowed to call this function when PMM is used");
        _;
    }

    modifier onlyPrivateTreasury() {
        require(!isPublicTreasury, "only private treasury is allowed for this operation");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _treasury,
        address _treasuryOwner,
        address _signer,
        address _pricingModelRegistry,
        address _router,
        uint256[] memory _fees,
        address[] memory _tokenAs,
        address[] memory _tokenBs,
        uint256[] memory _pricingModelIds,
        bool _isTreasuryContract,
        bool _isPublicTreasury
    ) external override initializer {
        __EIP712_init("native pool", "1");
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        __NoDelegateCall_init();
        require(_treasury != address(0), "treasury address specified should not be zero address");
        require(
            _treasuryOwner != address(0),
            "treasuryOwner address specified should not be zero address"
        );
        require(_signer != address(0), "signer address specified should not be zero address");
        require(
            _pricingModelRegistry != address(0),
            "pricingModelRegistry address specified should not be zero address"
        );
        treasury = _treasury;
        treasuryOwner = _treasuryOwner;
        isSigner[_signer] = true;
        pricingModelRegistry = _pricingModelRegistry;
        setRouter(_router);
        executeUpdatePairs(_fees, _tokenAs, _tokenBs, _pricingModelIds);
        poolFactory = msg.sender;
        isTreasuryContract = _isTreasuryContract;
        isPublicTreasury = _isPublicTreasury;

        emit SetTreasury(treasury);
        emit SetTreasuryOwner(treasuryOwner);
        emit AddSigner(_signer);
    }

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == poolFactory, "only PoolFactory can call this");
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function setRouter(address _router) internal {
        require(_router != address(0), "router address specified should not be zero address");
        require(router == address(0), "router address is already set");
        router = _router;
        emit SetRouter(router);
    }

    function isOnChainPricing() public view returns (bool) {
        if (isPmm || pairCount == 0) {
            return false;
        } else {
            // should only have 1 pair
            address tokenA = tokenAs[0];
            address tokenB = tokenBs[0];
            Pair storage pair = pairs[tokenA][tokenB];
            return
                pair.pricingModelId == CONSTANT_SUM_PRICE_MODEL_ID ||
                pair.pricingModelId == UNISWAP_V2_PRICE_MODEL_ID;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addSigner(address _signer) external override onlyOwner whenNotPaused {
        require(!isSigner[_signer], "Signer is already added");
        isSigner[_signer] = true;
        emit AddSigner(_signer);
    }

    function removeSigner(address _signer) external override onlyOwner whenNotPaused {
        require(isSigner[_signer], "Signer has not added");
        isSigner[_signer] = false;
        emit RemoveSigner(_signer);
    }

    function swap(
        bytes memory order,
        bytes calldata signature,
        uint256 flexibleAmount,
        address recipient,
        bytes calldata callback
    ) external override nonReentrant whenNotPaused onlyRouter returns (int256, int256) {
        Orders.Order memory _order = abi.decode(order, (Orders.Order));
        if (!isOnChainPricing()) {
            require(verifySignature(_order, signature), "Signature is invalid");
        }
        require(_order.deadlineTimestamp > block.timestamp, "Order is expired");
        require(!nonceMapping[_order.caller][_order.id], "Nonce already used");
        nonceMapping[_order.caller][_order.id] = true;

        require(pairExist(_order.sellerToken, _order.buyerToken), "Pair not exist");
        require(flexibleAmount != 0, "Flexible amount cannot be 0");
        require(!blacklisted[_order.caller], "Account is blacklisted");

        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        uint256 pricingModelId;

        pricingModelId = getPairPricingModel(_order.sellerToken, _order.buyerToken);
        {
            (buyerTokenAmount, sellerTokenAmount) = calculateTokenAmount(
                flexibleAmount,
                _order,
                pricingModelId
            );
        }
        {
            (int256 amount0Delta, int256 amount1Delta) = executeSwap(
                SwapParam({
                    buyerTokenAmount: buyerTokenAmount,
                    sellerTokenAmount: sellerTokenAmount,
                    _order: _order,
                    recipient: recipient,
                    callback: callback,
                    pricingModelId: pricingModelId
                })
            );
            uint256 fee = getPairFee(_order.sellerToken, _order.buyerToken);
            if (amount0Delta < 0) {
                emit Swap(
                    _order.caller,
                    recipient,
                    _order.sellerToken,
                    _order.buyerToken,
                    amount1Delta,
                    amount0Delta,
                    FullMath.mulDivRoundingUp(uint256(amount1Delta), fee, TEN_THOUSAND_DENOMINATOR),
                    _order.quoteId
                );
            } else {
                emit Swap(
                    _order.caller,
                    recipient,
                    _order.sellerToken,
                    _order.buyerToken,
                    amount0Delta,
                    amount1Delta,
                    FullMath.mulDivRoundingUp(uint256(amount0Delta), fee, TEN_THOUSAND_DENOMINATOR),
                    _order.quoteId
                );
            }
            if (isTreasuryContract) {
                INativeTreasury(treasury).syncReserve();
            }
            return (amount0Delta, amount1Delta);
        }
    }

    function pairExist(address tokenIn, address tokenOut) public view returns (bool exist) {
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].isExist;
    }

    function getTokenAs() public view returns (address[] memory) {
        return tokenAs;
    }

    function getTokenBs() public view returns (address[] memory) {
        return tokenBs;
    }

    function getPairPricingModel(
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 pricingModelId) {
        require(pairExist(tokenIn, tokenOut), "Pair not exist");
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].pricingModelId;
    }

    function getPairFee(address tokenIn, address tokenOut) public view returns (uint256 fee) {
        require(pairExist(tokenIn, tokenOut), "Pair not exist");
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        return pairs[token0][token1].fee;
    }

    function executeUpdatePairs(
        uint256[] memory _fees,
        address[] memory _tokenAs,
        address[] memory _tokenBs,
        uint256[] memory _pricingModelIds
    ) private {
        require(
            _fees.length == _tokenAs.length &&
                _fees.length == _tokenBs.length &&
                _fees.length == _pricingModelIds.length,
            "Pair array length mismatch"
        );
        for (uint i = 0; i < _fees.length; ) {
            require(_tokenAs[i] != _tokenBs[i], "Identical addresses");
            require(
                (_fees[i] >= 0) && (_fees[i] <= 10000),
                "Fee should be between 0 and 10k basis points"
            );
            (address token0, address token1) = _tokenAs[i] < _tokenBs[i]
                ? (_tokenAs[i], _tokenBs[i])
                : (_tokenBs[i], _tokenAs[i]);

            require(token0 != address(0), "Zero address in pair");

            bool isPairExist = pairExist(token0, token1);

            if (isPmm) {
                require(
                    _pricingModelIds[i] == PMM_PRICE_MODEL_ID,
                    "Can only add PMM pairs to pool using PMM"
                );
            } else {
                require(
                    pairCount == 0 || isPairExist,
                    "Can not have more than 1 pair for non PMM pool"
                );
            }

            uint256 pricingModelIdOld = 0;
            uint256 feeOld = 0;

            if (!isPairExist) {
                tokenAs.push(token0);
                tokenBs.push(token1);
                pairCount++;
            } else {
                pricingModelIdOld = pairs[token0][token1].pricingModelId;
                feeOld = pairs[token0][token1].fee;
            }
            pairs[token0][token1] = Pair({
                fee: _fees[i],
                isExist: true,
                pricingModelId: _pricingModelIds[i]
            });
            if (!isPmm && _pricingModelIds[i] == PMM_PRICE_MODEL_ID) {
                isPmm = true;
            }

            emit UpdatePair(
                token0,
                token1,
                feeOld,
                _fees[i],
                pricingModelIdOld,
                _pricingModelIds[i]
            );
            unchecked {
                i++;
            }
        }
        if (tokenAs.length > TOKEN_ARRAY_MAX_LENGTH) {
            revert TokenArrayLengthExceedLimit(tokenAs.length);
        }
    }

    function updatePairs(
        uint256[] calldata _fees,
        address[] calldata _tokenAs,
        address[] calldata _tokenBs,
        uint256[] calldata _pricingModelIds
    ) public whenNotPaused onlyPrivateTreasury {
        require(msg.sender == treasuryOwner, "Unauthorized to whitelist pairs");
        executeUpdatePairs(_fees, _tokenAs, _tokenBs, _pricingModelIds);
    }

    function removePair(address tokenIn, address tokenOut) public whenNotPaused {
        require(msg.sender == treasuryOwner, "Unauthorized to whitelist pairs");
        require(pairExist(tokenIn, tokenOut), "Pair not exist");
        (address token0, address token1) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        delete pairs[token0][token1];
        uint tokenAsLength = tokenAs.length;
        for (uint i = 0; i < tokenAsLength; ) {
            if (tokenAs[i] == token0 && tokenBs[i] == token1) {
                tokenAs[i] = tokenAs[tokenAs.length - 1];
                tokenAs.pop();
                tokenBs[i] = tokenBs[tokenBs.length - 1];
                tokenBs.pop();
                pairCount--;
                break;
            }
            unchecked {
                i++;
            }
        }
        emit RemovePair(token0, token1);
    }

    function getAmountOut(
        uint256 amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint amountOut) {
        uint256 pricingModelId = getPairPricingModel(_tokenIn, _tokenOut);
        require(
            pricingModelId != FIXED_PRICE_MODEL_ID && pricingModelId != PMM_PRICE_MODEL_ID,
            "Off-chain pricing unsupported"
        );
        Registry registry = Registry(pricingModelRegistry);

        address tokenIn = _tokenIn;
        address tokenOut = _tokenOut;

        uint256 fee = getPairFee(tokenIn, tokenOut);

        return
            registry.getAmountOut(
                amountIn,
                fee,
                pricingModelId,
                treasury,
                tokenIn,
                tokenOut,
                isTreasuryContract
            );
    }

    function getPricingModelRegistry() public view returns (address) {
        return pricingModelRegistry;
    }

    // private methods
    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order,
        uint256 pricingModelId
    ) private view returns (uint256, uint256) {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;

        sellerTokenAmount = flexibleAmount >= _order.sellerTokenAmount
            ? _order.sellerTokenAmount
            : flexibleAmount;

        if (pricingModelId != FIXED_PRICE_MODEL_ID && pricingModelId != PMM_PRICE_MODEL_ID) {
            buyerTokenAmount = getAmountOut(
                sellerTokenAmount,
                _order.sellerToken,
                _order.buyerToken
            );
        } else {
            require(
                _order.sellerTokenAmount > 0 && _order.buyerTokenAmount > 0,
                "Non-zero amount required"
            );

            buyerTokenAmount = FullMath.mulDiv(
                sellerTokenAmount,
                _order.buyerTokenAmount,
                _order.sellerTokenAmount
            );
        }
        require(buyerTokenAmount > 0 && sellerTokenAmount > 0, "Non-zero amount required");

        return (buyerTokenAmount, sellerTokenAmount);
    }

    function executeSwap(SwapParam memory swapParam) private returns (int256, int256) {
        // Transfer token from treasury to user / router
        executeSwapFromTreasury(swapParam.buyerTokenAmount, swapParam._order, swapParam.recipient);
        // Transfer token from user / router, to pool, then to treasury
        return
            executeSwapToTreasury(
                swapParam._order,
                swapParam.sellerTokenAmount,
                swapParam.buyerTokenAmount,
                swapParam.callback
            );
    }

    // internal methods
    function getMessageHash(Orders.Order memory _order) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                ORDER_SIGNATURE_HASH,
                _order.id,
                _order.signer,
                _order.buyer,
                _order.seller,
                _order.buyerToken,
                _order.sellerToken,
                _order.buyerTokenAmount,
                _order.sellerTokenAmount,
                _order.deadlineTimestamp,
                _order.caller,
                _order.quoteId
            )
        );
        return hash;
    }

    function verifySignature(
        Orders.Order memory _order,
        bytes calldata signature
    ) internal view returns (bool) {
        require(isSigner[_order.signer], "Signer is invalid");
        bytes32 digest = _hashTypedDataV4(getMessageHash(_order));

        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        return _order.signer == recoveredSigner;
    }

    function executeSwapFromTreasury(
        uint256 amount,
        Orders.Order memory _order,
        address recipient
    ) internal {
        address buyerToken = _order.buyerToken;
        uint256 treasuryBalanceInitial = IERC20Upgradeable(buyerToken).balanceOf(address(treasury));
        require(treasuryBalanceInitial >= amount, "Insufficient fund in treasury");

        TransferHelper.safeTransferFrom(_order.buyerToken, treasury, recipient, amount);

        uint256 treasuryBalanceFinal = IERC20Upgradeable(buyerToken).balanceOf(address(treasury));
        require((treasuryBalanceInitial - treasuryBalanceFinal) == amount, "Swap amount not match");
    }

    function executeSwapToTreasury(
        Orders.Order memory _order,
        uint256 sellerTokenAmount,
        uint256 buyerTokenAmount,
        bytes memory callback
    ) internal returns (int256, int256) {
        require(
            sellerTokenAmount <= uint256(type(int256).max),
            "sellerTokenAmount is too large and would cause an overflow error"
        );
        require(
            buyerTokenAmount <= uint256(type(int256).max),
            "buyerTokenAmount is too large and would cause an overflow error"
        );
        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(buyerTokenAmount);
        address sellerToken = _order.sellerToken;
        uint256 treasuryBalanceInitial = IERC20Upgradeable(sellerToken).balanceOf(
            address(treasury)
        );
        uint256 treasuryBalanceFinal;

        INativeRouter(msg.sender).swapCallback(
            outputBuyerTokenAmount,
            outputSellerTokenAmount,
            callback
        );
        TransferHelper.safeTransfer(sellerToken, treasury, sellerTokenAmount);
        treasuryBalanceFinal = IERC20Upgradeable(sellerToken).balanceOf(address(treasury));

        require(
            (treasuryBalanceFinal - treasuryBalanceInitial) == sellerTokenAmount,
            "Swap amount not match"
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
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
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
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
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 */
contract Blacklistable is OwnableUpgradeable {
    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        require(
            msg.sender == blacklister,
            "Blacklistable: caller is not the blacklister"
        );
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function blacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function unBlacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) external onlyOwner {
        require(
            _newBlacklister != address(0),
            "Blacklistable: new blacklister is the zero address"
        );
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }

     /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IPeripheryState.sol";
import "./libraries/IWETH9.sol";
import "./libraries/Order.sol";
import "./libraries/FullMath.sol";

abstract contract ExternalSwapRouterUpgradeable is Initializable {
    using SafeERC20 for IERC20;

    address public pancakeswapRouter; // legacy variable, not removing it just to maintain the storage layout of upgradable contract
    // https://docs.pancakeswap.finance/developers/smart-contracts/pancakeswap-exchange/v2-contracts/router-v2
    address public constant PANCAKESWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // https://docs.uniswap.org/contracts/v3/reference/deployments
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2;
    uint24 public constant UNISWAP_V3_FEE_TIER = 500; // 0.05%

    // different for each chain need to update accordingly
    address public constant ONE_INCH_ROUTER_ADDRESS = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    event SwapPancake(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    event SwapUniswapV3(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    event Swap1inch(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        bytes16 quoteId
    );

    error InvalidFunctionSelectorInCalldata(bytes4);
    error OrderExpired();
    error ZeroFlexibleAmount();
    error InvalidZeroAddressInput();
    error SellerAmountTooLargeOverflow(uint);
    error BuyerAmountTooLargeOverflow(uint);
    error ExternalCallFailed();
    error InvalidZeroInputAmout();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function swapPancake(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        // handle the case where user call with ETH
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= sellerTokenAmount) {
            IWETH9(weth9).deposit{value: sellerTokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), sellerTokenAmount);
        }

        IERC20(tokenIn).safeApprove(PANCAKESWAP_ROUTER_ADDRESS, sellerTokenAmount);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        if (sellerTokenAmount > uint256(type(int256).max)) {
            revert SellerAmountTooLargeOverflow(sellerTokenAmount);
        }

        uint[] memory outputAmounts = IPancakeRouter02(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
            sellerTokenAmount,
            buyerTokenAmount,
            path,
            recipient,
            order.deadlineTimestamp
        );

        if (outputAmounts[outputAmounts.length - 1] > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(outputAmounts[outputAmounts.length - 1]);
        }

        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(outputAmounts[outputAmounts.length - 1]);

        emit SwapPancake(
            order.caller,
            recipient,
            tokenIn,
            tokenOut,
            outputSellerTokenAmount,
            outputBuyerTokenAmount,
            order.quoteId
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }

    function swapUniswapV3(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        // handle the case where user call with ETH
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= sellerTokenAmount) {
            IWETH9(weth9).deposit{value: sellerTokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), sellerTokenAmount);
        }

        IERC20(tokenIn).safeApprove(UNISWAP_V3_ROUTER_ADDRESS, sellerTokenAmount);

        if (sellerTokenAmount > uint256(type(int256).max)) {
            revert SellerAmountTooLargeOverflow(sellerTokenAmount);
        }

        uint256 amountOut = IUniswapV3SwapRouter(UNISWAP_V3_ROUTER_ADDRESS).exactInputSingle(
            IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: UNISWAP_V3_FEE_TIER,
                recipient: recipient,
                amountIn: sellerTokenAmount,
                amountOutMinimum: buyerTokenAmount,
                sqrtPriceLimitX96: 0
            })
        );

        if (amountOut > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(amountOut);
        }

        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(amountOut);

        emit SwapUniswapV3(
            order.caller,
            recipient,
            tokenIn,
            tokenOut,
            outputSellerTokenAmount,
            outputBuyerTokenAmount,
            order.quoteId
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }

    struct OneInchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap1inch(
        Orders.Order memory order,
        uint256 flexibleAmount,
        address recipient,
        address payer,
        bytes memory fallbackSwapCalldata
    ) internal returns (int256, int256) {
        if (order.deadlineTimestamp <= block.timestamp) {
            revert OrderExpired();
        }
        if (flexibleAmount == 0) {
            revert ZeroFlexibleAmount();
        }

        (uint256 buyerTokenAmount, uint256 sellerTokenAmount) = calculateTokenAmount(
            flexibleAmount,
            order
        );

        address tokenIn = order.sellerToken;
        address tokenOut = order.buyerToken;

        // handle the case where user call with ETH
        address weth9 = IPeripheryState(address(this)).WETH9();
        if (tokenIn == weth9 && address(this).balance >= sellerTokenAmount) {
            IWETH9(weth9).deposit{value: sellerTokenAmount}();
        } else if (payer != address(this)) {
            IERC20(tokenIn).safeTransferFrom(payer, address(this), sellerTokenAmount);
        }

        IERC20(tokenIn).safeApprove(ONE_INCH_ROUTER_ADDRESS, sellerTokenAmount);

        if (sellerTokenAmount > uint256(type(int256).max)) {
            revert SellerAmountTooLargeOverflow(sellerTokenAmount);
        }

        bytes4 functionSelector = bytes4(fallbackSwapCalldata);
        bytes memory functionParams;
        assembly {
            functionParams := add(fallbackSwapCalldata, 4) // exlucde the function seletor
        }

        // function signatures and input
        /*
        0x12aa3caf: swap
        function swap(
            IAggregationExecutor executor,
            SwapDescription calldata desc,
            bytes calldata permit,
            bytes calldata data
        )
        */
        /**
        0xe449022e: uniswapV3Swap
        function uniswapV3Swap(
            uint256 amount,
            uint256 minReturn,
            uint256[] calldata pools
        )
        */
        /**
        0x0502b1c5: unoswap
        function unoswap(
            IERC20 srcToken,
            uint256 amount,
            uint256 minReturn,
            uint256[] calldata pools
        )
         */
        // 0x62e238bb: fillOrder            require signature, cannot change input amount
        // 0x3eca9c0a: fillOrderRFQ         require signature, cannot change input amount
        // 0x84bd6d29: clipperSwap          require signature, cannot change input amount
        // 0x9570eeee: fillOrderRFQCompact  require signature, cannot change input amount

        if (functionSelector == bytes4(0x12aa3caf)) {
            (
                address executor,
                OneInchSwapDescription memory desc,
                bytes memory permit,
                bytes memory data
            ) = abi.decode(functionParams, (address, OneInchSwapDescription, bytes, bytes));
            desc.amount = sellerTokenAmount;
            desc.minReturnAmount = buyerTokenAmount;
            fallbackSwapCalldata = abi.encodeWithSelector(
                functionSelector,
                executor,
                desc,
                permit,
                data
            );
        } else if (functionSelector == bytes4(0xe449022e)) {
            (uint256 amount, uint256 minReturn, uint256[] memory pools) = abi.decode(
                functionParams,
                (uint256, uint256, uint256[])
            );
            amount = sellerTokenAmount;
            minReturn = buyerTokenAmount;
            fallbackSwapCalldata = abi.encodeWithSelector(
                functionSelector,
                amount,
                minReturn,
                pools
            );
        } else if (functionSelector == bytes4(0x0502b1c5)) {
            (address srcToken, uint256 amount, uint256 minReturn, uint256[] memory pools) = abi
                .decode(functionParams, (address, uint256, uint256, uint256[]));
            amount = sellerTokenAmount;
            minReturn = buyerTokenAmount;
            fallbackSwapCalldata = abi.encodeWithSelector(
                functionSelector,
                srcToken,
                amount,
                minReturn,
                pools
            );
        } else if (
            functionSelector == bytes4(0x62e238bb) ||
            functionSelector == bytes4(0x3eca9c0a) ||
            functionSelector == bytes4(0x84bd6d29) ||
            functionSelector == bytes4(0x9570eeee)
        ) {
            // cannot change input amount as it requires signature in the input
        } else {
            revert InvalidFunctionSelectorInCalldata(functionSelector);
        }

        (bool success, bytes memory result) = ONE_INCH_ROUTER_ADDRESS.call(fallbackSwapCalldata);
        if (!success) {
            revert ExternalCallFailed();
        }

        IERC20(tokenIn).safeApprove(ONE_INCH_ROUTER_ADDRESS, 0);
        uint256 amountOut;

        // * as desired return value
        // function signatures
        // 0x12aa3caf: swap                 - returns (uint256 returnAmount*, uint256 spentAmount)
        // 0xe449022e: uniswapV3Swap        - returns (uint256 returnAmount*)
        // 0x0502b1c5: unoswap              - returns (uint256 returnAmount*)
        // 0x84bd6d29: clipperSwap          - returns (uint256 returnAmount*)
        // 0x62e238bb: fillOrder            - returns (uint256 actualMakingAmount*, uint256 actualTakingAmount, bytes32 orderHash)
        // 0x3eca9c0a: fillOrderRFQ         - returns (uint256 filledMakingAmount*, uint256 filledTakingAmount, bytes32 orderHash)
        // 0x9570eeee: fillOrderRFQCompact  - returns (uint256 filledMakingAmount*, uint256 filledTakingAmount, bytes32 orderHash)

        if (functionSelector == bytes4(0x12aa3caf)) {
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            amountOut = returnAmount;
        } else if (
            functionSelector == bytes4(0xe449022e) ||
            functionSelector == bytes4(0x0502b1c5) ||
            functionSelector == bytes4(0x84bd6d29)
        ) {
            uint256 returnAmount = abi.decode(result, (uint256));
            amountOut = returnAmount;
        } else if (
            functionSelector == bytes4(0x62e238bb) ||
            functionSelector == bytes4(0x3eca9c0a) ||
            functionSelector == bytes4(0x9570eeee)
        ) {
            (uint256 returnAmount, , ) = abi.decode(result, (uint256, uint256, bytes32));
            amountOut = returnAmount;
        } else {
            revert InvalidFunctionSelectorInCalldata(functionSelector);
        }

        if (amountOut > uint256(type(int256).max)) {
            revert BuyerAmountTooLargeOverflow(amountOut);
        }

        if (recipient != address(this)) {
            IERC20(tokenOut).safeTransfer(recipient, amountOut);
        }

        int256 outputSellerTokenAmount = int256(sellerTokenAmount);
        int256 outputBuyerTokenAmount = -1 * int256(amountOut);

        emit Swap1inch(
            order.caller,
            recipient,
            tokenIn,
            tokenOut,
            outputSellerTokenAmount,
            outputBuyerTokenAmount,
            order.quoteId
        );

        return (outputBuyerTokenAmount, outputSellerTokenAmount);
    }

    function calculateTokenAmount(
        uint256 flexibleAmount,
        Orders.Order memory _order
    ) private pure returns (uint256, uint256) {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;

        sellerTokenAmount = flexibleAmount >= _order.sellerTokenAmount
            ? _order.sellerTokenAmount
            : flexibleAmount;

        if (_order.sellerTokenAmount <= 0 || _order.buyerTokenAmount <= 0) {
            revert InvalidZeroInputAmout();
        }

        buyerTokenAmount = FullMath.mulDiv(
            sellerTokenAmount,
            _order.buyerTokenAmount,
            _order.sellerTokenAmount
        );
        if (sellerTokenAmount <= 0) {
            revert InvalidZeroInputAmout();
        }
        return (buyerTokenAmount, sellerTokenAmount);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-3.0

import {Orders} from "../libraries/Order.sol";
pragma solidity ^0.8.0;

interface INativePool {
    struct Pair {
        uint256 fee;
        bool isExist;
        uint256 pricingModelId;
    }

    struct SwapParam {
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        Orders.Order _order;
        address recipient;
        bytes callback;
        uint256 pricingModelId;
    }

    function initialize(
        address _treasury,
        address _treasuryOwner,
        address _signer,
        address _pricingModelRegistry,
        address _router,
        uint256[] memory _fees,
        address[] memory _tokenAs,
        address[] memory _tokenBs,
        uint256[] memory _pricingModelIds,
        bool _isTreasuryContract,
        bool _isPublicTreasury
    ) external;

    function addSigner(address _signer) external;

    function removeSigner(address _signer) external;

    function swap(
        bytes memory _order,
        bytes calldata signature,
        uint256 flexibleAmount,
        address recipient,
        bytes calldata callback
    ) external returns (int256, int256);

    event Swap(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        address tokenOut,
        int256 amountIn,
        int256 amountOut,
        uint256 fee,
        bytes16 quoteId
    );

    event UpdatePair(
        address indexed tokenA,
        address indexed tokenB,
        uint256 feeOld,
        uint256 feeNew,
        uint256 pricingModelIdOld,
        uint256 pricingModelIdNew
    );

    event RemovePair(
        address tokenA,
        address tokenB
    );


    event AddSigner(
        address signer
    );

    event RemoveSigner(
        address signer
    );

    event SetRouter(
        address router
    );

    event SetTreasury(
        address treasury
    );

    event SetTreasuryOwner(
        address treasuryOwner
    );

    error TokenArrayLengthExceedLimit(uint arrayLength);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../NativePool.sol";
import "../interfaces/INativePool.sol";

error AlreadyMultiPoolTreasury();
error NotMultiPoolTreasury();
error NotMultiPoolTreasuryAndBindedToOtherPool(address treasuryAddress);
error ZeroAddressInput();
error RegistryAlreadySet();
error RegistryNotSet();
error InputArrayLengthMismatch();
error PoolUpgradeFailed();

interface INativePoolFactory {
    /// @notice Emitted when a pool is created
    /// @param treasury The address of treasury for the pool
    /// @param owner The address of owner of the pool
    /// @param pool The address of the created pool
    event PoolCreated(address treasury, address owner, address signer, address pool, address impl);

    event PoolUpgraded(address pool, address impl);

    event AddPoolCreator(address poolCreater);
    event RemovePoolCreator(address poolCreater);
    event AddMultiPoolTreasury(address treasury);
    event RemoveMultiPoolTreasury(address treasury);

    function createNewPool(
        address treasuryAddress,
        address poolOwnerAddress,
        address signerAddress,
        address routerAddress,
        uint256[] memory fees,
        address[] memory tokenAs,
        address[] memory tokenBs,
        uint256[] memory pricingModelIds,
        bool isPublicTreasury,
        bool isTreasuryContract
    ) external returns (address pool);

    function upgradePools(address[] calldata _pools, address[] calldata _impls) external;

    function upgradePool(address pool, address impl) external;

    function getPool(address treasuryAddress) external view returns (address);

    function verifyPool(address poolAddress) external view returns (bool);

    function setPoolImplementation(address newPoolImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ISwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Native
interface INativeRouter is ISwapCallback {
    struct WidgetFee {
        address signer;
        address feeRecipient;
        uint256 feeRate;
    }

    event SetWidgetFeeSigner(address widgetFeeSigner);

    event WidgetFeeTransfer(
        address widgetFeeRecipient,
        uint256 widgetFeeRate,
        uint256 widgetFeeAmount,
        address widgetFeeToken
    );

    function setWidgetFeeSigner(address _widgetFeeSigner) external;

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes orders;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        WidgetFee widgetFee;
        bytes widgetFeeSignature;
        bytes[] fallbackCalldataArray;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    error ZeroAddressInput();
    error InvalidDeltaValue(int amount0Delta, int amount1Delta);
    error CallbackNotFromOrderBuyer(address caller);
    error MultipleOrdersForInputSingle();
    error MultipleFallbackDataForInputSingle();
    error InvalidWidgetFeeSinger();
    error InvalidWidgetFeeSignature();
    error InvalidWidgetFeeRate();
    error InvalidAmountInValue();
    error CallerNotMsgSender(address caller, address msgSender);
    error NotEnoughAmountOut(uint256 amountOut, uint256 amountOutMinimum);
    error Missing1inchCalldata();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// generic interface to treasury contract
interface INativeTreasury {
    event ReservesSynced(uint128 reserve0, uint128 reserve1);

    function syncReserve() external;

    function getReserves() external view returns (uint128 _reserve0, uint128 _reserve1);

    function setPoolAddress(address _pool) external;

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryState {
    /// @return Returns the address of the Native factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPricer {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface ISwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param _data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// ref: https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/IV3SwapRouter.sol
interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/INativePoolFactory.sol";
import "../interfaces/INativePool.sol";

/// @notice Provides validation for callbacks from Native Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Native Pool
    /// @param factory The contract address of the Native factory
    /// @param pool The contract address of a Pool
    /// @return verifiedPool The Native pool contract address
    function verifyCallback(address factory, address pool) internal view returns (INativePool) {
        require(INativePoolFactory(factory).verifyPool(pool), "Invalid pool address");
        return INativePool(pool);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "FullMath: mulDiv: denominator must be greater then zero");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "FullMath: mulDiv: result greater than 2**256");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        // uint256 twos = -denominator & denominator;
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
                result = mulDiv(a, b, denominator);
                if (mulmod(a, b, denominator) > 0) {
                    require(result < type(uint256).max, "FullMath: mulDivRoundingUp: result greater than 2**256");
                    result++;
                }
            }
        }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;


import "./PeripheryValidation.sol";
import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall, PeripheryValidation {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IMulticall
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        override
        checkDeadline(deadline)
        returns (bytes[] memory)
    {
        return multicall(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCallUpgradable is Initializable {
    /// @dev The original address of this contract
    address private original;

    function __NoDelegateCall_init() internal onlyInitializing {
        __NoDelegateCall_init_unchained();
    }

    function __NoDelegateCall_init_unchained() internal onlyInitializing {
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original, "delegate call check violation");
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BytesLib.sol";

//import "hardhat/console.sol";

library Orders {
    using BytesLib for bytes;

    struct Order {
        uint256 id;
        address signer;
        address buyer;
        address seller;
        address buyerToken;
        address sellerToken;
        uint256 buyerTokenAmount;
        uint256 sellerTokenAmount;
        uint256 deadlineTimestamp;
        address caller;
        bytes16 quoteId;
    }

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant UINT256_SIZE = 32;
    uint256 private constant UUID_SIZE = 16;
    uint256 private constant ORDER_SIZE = ADDR_SIZE * 6 + UINT256_SIZE * 4 + UUID_SIZE;
    uint256 private constant SIG_SIZE = 65;
    uint256 private constant HOP_SIZE = SIG_SIZE + ORDER_SIZE;

    function hasMultiplePools(bytes memory orders) internal pure returns (bool) {
        return orders.length > HOP_SIZE;
    }

    function numPools(bytes memory orders) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return (orders.length / HOP_SIZE);
    }

    function decodeFirstOrder(
        bytes memory orders
    ) internal pure returns (Order memory order, bytes memory signature) {
        require(
            orders.length != 0 && orders.length % HOP_SIZE == 0,
            "Orders: decodeFirstOrder: invalid bytes length"
        );
        order.id = orders.toUint256(0);
        order.signer = orders.toAddress(UINT256_SIZE);
        order.buyer = orders.toAddress(UINT256_SIZE + ADDR_SIZE);
        order.seller = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 2);
        order.buyerToken = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 3);
        order.sellerToken = orders.toAddress(UINT256_SIZE + ADDR_SIZE * 4);
        order.buyerTokenAmount = orders.toUint256(UINT256_SIZE + ADDR_SIZE * 5);
        order.sellerTokenAmount = orders.toUint256(UINT256_SIZE * 2 + ADDR_SIZE * 5);
        order.deadlineTimestamp = orders.toUint256(UINT256_SIZE * 3 + ADDR_SIZE * 5);
        order.caller = orders.toAddress(UINT256_SIZE * 4 + ADDR_SIZE * 5);
        order.quoteId = bytes16(orders.slice(UINT256_SIZE * 4 + ADDR_SIZE * 6, UUID_SIZE));
        signature = orders.slice(ORDER_SIZE, SIG_SIZE);
    }

    function getFirstOrder(bytes memory orders) internal pure returns (bytes memory) {
        return orders.slice(0, HOP_SIZE);
    }

    function skipOrder(bytes memory orders) internal pure returns (bytes memory) {
        require(
            orders.length != 0 && orders.length % HOP_SIZE == 0,
            "Orders: decodeFirstOrder: invalid bytes length"
        );
        return orders.slice(HOP_SIZE, orders.length - HOP_SIZE);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IPeripheryPayments.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./TransferHelper.sol";
import "./IWETH9.sol";
import "./PeripheryState.sol";
import "./Weth9Unwrapper.sol";

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryState {
    receive() external payable {
        require(msg.sender == WETH9, "Not WETH9");
    }

    // public methods
    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            TransferHelper.safeTransfer(WETH9, weth9Unwrapper, balanceWETH9);
            Weth9Unwrapper(weth9Unwrapper).unwrapWeth9(balanceWETH9, recipient);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100, "Fee out of range");

        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            uint256 feeAmount = (balanceWETH9 * feeBips) / 100_00;
            if (feeAmount > 0) TransferHelper.safeTransferETH(feeRecipient, feeAmount);
            TransferHelper.safeTransferETH(recipient, balanceWETH9 - feeAmount);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100, "Fee out of range");

        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            uint256 feeAmount = (balanceToken * feeBips) / 100_00;
            if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
        }
    }

    // external methods
    /// @inheritdoc IPeripheryPayments
    function refundETH() external payable override {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    function refundETHRecipient(address recipient) public payable {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(recipient, address(this).balance);
    }

    function unwrapWETH9(uint256 amountMinimum) external payable {
        unwrapWETH9(amountMinimum, msg.sender);
    }

    function wrapETH(uint256 value) external payable {
        IWETH9(WETH9).deposit{value: value}();
    }

    function sweepToken(address token, uint256 amountMinimum) external payable {
        sweepToken(token, amountMinimum, msg.sender);
    }

    function pull(address token, uint256 value) external payable {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
    }

    // internal methods
    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH9 && address(this).balance >= value) {
            //require(address(this).balance >= value, "Insufficient native token value");
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IPeripheryState.sol";
import "../storage/NativeRouterStorage.sol";

abstract contract PeripheryState is IPeripheryState {
    address public override factory;
    address public override WETH9;
    address payable public weth9Unwrapper;

    function initializeState(address _factory, address _WETH9) internal {
        require(_factory != address(0), "PeripheryState: factory address cannot be 0");
        require(_WETH9 != address(0), "PeripheryState: WETH9 address cannot be 0");
        factory = _factory;
        WETH9 = _WETH9;
    }

    function setWeth9Unwrapper(address payable _weth9Unwrapper) virtual public;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract PeripheryValidation {
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library TransferHelper {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        IERC20Upgradeable(token).safeTransferFrom(from, to, value);
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        IERC20Upgradeable(token).safeTransfer(to, value);
    }

    function safeIncreaseAllowance(address token, address to, uint256 value) internal {
        IERC20Upgradeable(token).safeIncreaseAllowance(to, value);
    }

    function safeDecreaseAllowance(address token, address to, uint256 value) internal {
        IERC20Upgradeable(token).safeDecreaseAllowance(to, value);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IWETH9.sol";
import "./TransferHelper.sol";

contract Weth9Unwrapper {
    address immutable public weth9;
    address immutable public nativeRouter;
    constructor (address _weth9, address _router) {
        weth9 = _weth9;
        nativeRouter = _router;
    }

    receive() external payable {}

    function unwrapWeth9(uint256 amount, address recipient) public {
        require(msg.sender == nativeRouter, "only NativeRouter can call this function");
        IWETH9(weth9).withdraw(amount);
        TransferHelper.safeTransferETH(recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/INativeRouter.sol";
import "./interfaces/INativePool.sol";
import "./interfaces/INativePoolFactory.sol";
import "./libraries/SafeCast.sol";
import "./libraries/CallbackValidation.sol";
import "./libraries/Order.sol";
import "./libraries/PeripheryPayments.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "./storage/NativeRouterStorage.sol";
import "./ExternalSwapRouterUpgradeable.sol";

contract NativeRouter is
    INativeRouter,
    PeripheryPayments,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    Multicall,
    NativeRouterStorage,
    PausableUpgradeable,
    ExternalSwapRouterUpgradeable
{
    using Orders for bytes;
    using SafeCast for uint256;
    uint256 public constant TEN_THOUSAND_DENOMINATOR = 10000;
    bytes32 private constant EXACT_INPUT_SIGNATURE_HASH =
        keccak256(
            "NativeSwapCalldata(bytes32 orders,address recipient,uint256 amountIn,address signer,address feeRecipient,uint256 feeRate)"
        );

    struct SwapCallbackData {
        bytes orders;
        address payer;
    }

    event SwapCalculations(uint256 amountIn, address recipient);

    function initialize(
        address factory,
        address weth9,
        address _widgetFeeSigner
    ) public initializer {
        initializeState(factory, weth9);
        __EIP712_init("native router", "1");
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setWidgetFeeSigner(_widgetFeeSigner);
        __Pausable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setWeth9Unwrapper(address payable _weth9Unwrapper) public override onlyOwner {
        if (_weth9Unwrapper == address(0)) {
            revert ZeroAddressInput();
        }
        weth9Unwrapper = _weth9Unwrapper;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setWidgetFeeSigner(address _widgetFeeSigner) public onlyOwner {
        if (_widgetFeeSigner == address(0)) {
            revert ZeroAddressInput();
        }
        widgetFeeSigner = _widgetFeeSigner;
        emit SetWidgetFeeSigner(widgetFeeSigner);
    }

    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override whenNotPaused {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert InvalidDeltaValue(amount0Delta, amount1Delta);
        }
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        (Orders.Order memory order, ) = data.orders.decodeFirstOrder();
        if (msg.sender != order.buyer) {
            revert CallbackNotFromOrderBuyer(msg.sender);
        }

        CallbackValidation.verifyCallback(factory, order.buyer);

        uint256 amountToPay = amount0Delta < 0 ? uint256(amount1Delta) : uint256(amount0Delta);
        pay(order.sellerToken, data.payer, msg.sender, amountToPay);
    }

    function exactInputSingle(
        ExactInputParams memory params
    ) external payable override nonReentrant whenNotPaused returns (uint256 amountOut) {
        if (params.orders.hasMultiplePools()) {
            revert MultipleOrdersForInputSingle();
        }
        if (params.fallbackCalldataArray.length > 1) {
            revert MultipleFallbackDataForInputSingle();
        }
        if (!verifyWidgetFeeSignature(params, params.widgetFeeSignature)) {
            revert InvalidWidgetFeeSignature();
        }
        if (params.widgetFee.feeRate > TEN_THOUSAND_DENOMINATOR) {
            revert InvalidWidgetFeeRate();
        }
        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        if (params.amountIn <= 0) {
            revert InvalidAmountInValue();
        }
        if (order.caller != msg.sender) {
            revert CallerNotMsgSender(order.caller, msg.sender);
        }

        uint256 widgetFeeAmount = (params.amountIn * params.widgetFee.feeRate) /
            TEN_THOUSAND_DENOMINATOR;

        if (msg.value > 0 && order.sellerToken == WETH9) {
            TransferHelper.safeTransferETH(params.widgetFee.feeRecipient, widgetFeeAmount);
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                address(0)
            );
        } else {
            TransferHelper.safeTransferFrom(
                order.sellerToken,
                msg.sender,
                params.widgetFee.feeRecipient,
                widgetFeeAmount
            );
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                order.sellerToken
            );
        }

        params.amountIn -= widgetFeeAmount;
        emit SwapCalculations(params.amountIn, params.recipient);

        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            SwapCallbackData({
                orders: params.orders,
                payer: hasAlreadyPaid ? address(this) : msg.sender
            }),
            params.fallbackCalldataArray.length > 0 ? params.fallbackCalldataArray[0] : bytes("")
        );
        if (amountOut < params.amountOutMinimum) {
            revert NotEnoughAmountOut(amountOut, params.amountOutMinimum);
        }

        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @inheritdoc INativeRouter
    function exactInput(
        ExactInputParams memory params
    ) external payable override nonReentrant whenNotPaused returns (uint256 amountOut) {
        if (!verifyWidgetFeeSignature(params, params.widgetFeeSignature)) {
            revert InvalidWidgetFeeSignature();
        }
        if (params.widgetFee.feeRate > TEN_THOUSAND_DENOMINATOR) {
            revert InvalidWidgetFeeRate();
        }
        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        if (params.amountIn <= 0) {
            revert InvalidAmountInValue();
        }
        if (order.caller != msg.sender) {
            revert CallerNotMsgSender(order.caller, msg.sender);
        }

        address payer = hasAlreadyPaid ? address(this) : msg.sender;

        uint256 widgetFeeAmount = (params.amountIn * params.widgetFee.feeRate) /
            TEN_THOUSAND_DENOMINATOR;
        if (msg.value > 0 && order.sellerToken == WETH9) {
            TransferHelper.safeTransferETH(params.widgetFee.feeRecipient, widgetFeeAmount);
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                address(0)
            );
        } else {
            TransferHelper.safeTransferFrom(
                order.sellerToken,
                msg.sender,
                params.widgetFee.feeRecipient,
                widgetFeeAmount
            );
            emit WidgetFeeTransfer(
                params.widgetFee.feeRecipient,
                params.widgetFee.feeRate,
                widgetFeeAmount,
                order.sellerToken
            );
        }

        params.amountIn -= widgetFeeAmount;
        emit SwapCalculations(params.amountIn, params.recipient);

        uint256 fallbackSwapCalldataIdx = 0;
        while (true) {
            bool hasMultiplePools = params.orders.hasMultiplePools();
            bytes memory fallbackSwapCalldata;
            if (order.buyer == ONE_INCH_ROUTER_ADDRESS) {
                if (params.fallbackCalldataArray.length <= fallbackSwapCalldataIdx) {
                    revert Missing1inchCalldata();
                }
                fallbackSwapCalldata = params.fallbackCalldataArray[fallbackSwapCalldataIdx];
                unchecked {
                    fallbackSwapCalldataIdx++;
                }
            }
            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient,
                SwapCallbackData({
                    orders: params.orders.getFirstOrder(), // only the first pool in the path is necessary
                    payer: payer
                }),
                fallbackSwapCalldata
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.orders = params.orders.skipOrder();
                (order, ) = params.orders.decodeFirstOrder();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        if (amountOut < params.amountOutMinimum) {
            revert NotEnoughAmountOut(amountOut, params.amountOutMinimum);
        }

        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    // private methods
    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data,
        bytes memory fallbackSwapCalldata
    ) private returns (uint256 amountOut) {
        (Orders.Order memory order, bytes memory signature) = data.orders.decodeFirstOrder();

        int256 amount0Delta;
        int256 amount1Delta;
        if (INativePoolFactory(factory).verifyPool(order.buyer)) {
            (amount0Delta, amount1Delta) = INativePool(order.buyer).swap(
                abi.encode(order),
                signature,
                amountIn,
                recipient,
                abi.encode(data)
            );
        } else if (order.buyer == PANCAKESWAP_ROUTER_ADDRESS) {
            (amount0Delta, amount1Delta) = swapPancake(order, amountIn, recipient, data.payer);
        } else if (order.buyer == UNISWAP_V3_ROUTER_ADDRESS) {
            (amount0Delta, amount1Delta) = swapUniswapV3(order, amountIn, recipient, data.payer);
        } else if (order.buyer == ONE_INCH_ROUTER_ADDRESS) {
            if (fallbackSwapCalldata.length <= 0) {
                revert Missing1inchCalldata();
            }
            (amount0Delta, amount1Delta) = swap1inch(
                order,
                amountIn,
                recipient,
                data.payer,
                fallbackSwapCalldata
            );
        } else {
            revert("invalid order buyer");
        }
        return uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
    }

    function getExactInputMessageHash(
        ExactInputParams memory inputParams
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                EXACT_INPUT_SIGNATURE_HASH,
                keccak256(inputParams.orders),
                inputParams.recipient,
                inputParams.amountIn,
                inputParams.widgetFee.signer,
                inputParams.widgetFee.feeRecipient,
                inputParams.widgetFee.feeRate
            )
        );
        return hash;
    }

    function verifyWidgetFeeSignature(
        ExactInputParams memory params,
        bytes memory signature
    ) internal view returns (bool) {
        if (params.widgetFee.signer != widgetFeeSigner) {
            revert InvalidWidgetFeeSinger();
        }
        bytes32 digest = _hashTypedDataV4(getExactInputMessageHash(params));

        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        return params.widgetFee.signer == recoveredSigner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPricer.sol";
import "./interfaces/INativeTreasury.sol";

contract Registry is Ownable {
    mapping(uint256 => address) public pricer;

    // constructor
    constructor(address[] memory pricers) Ownable() {
        for (uint256 i = 0; i < pricers.length; ) {
            pricer[i] = pricers[i];
            unchecked {
                i++;
            }
        }
    }

    // public methods
    function registerPricer(uint256 id, address addr) public onlyOwner {
        require(pricer[id] == address(0), "pricer already set for this id");
        pricer[id] = addr;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 fee,
        uint256 id,
        address treasury,
        address tokenIn,
        address tokenOut,
        bool isTreasuryContract
    ) public view returns (uint amountOut) {
        require(amountIn > 0, "Non-zero amount required");

        uint reserveIn;
        uint reserveOut;
        if (isTreasuryContract) {
            (uint reserve0, uint reserve1) = INativeTreasury(treasury).getReserves();
            if (tokenIn == INativeTreasury(treasury).token0()) {
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                reserveIn = reserve1;
                reserveOut = reserve0;
            }
        } else {
            reserveIn = IERC20(tokenIn).balanceOf(address(treasury));
            reserveOut = IERC20(tokenOut).balanceOf(address(treasury));
        }
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut, fee, id);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee,
        uint256 id
    ) internal view returns (uint amountOut) {
        require(reserveIn > 0 && reserveOut > 0, "Registry: INSUFFICIENT_LIQUIDITY");

        amountOut = IPricer(pricer[id]).getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {INativePool} from "../interfaces/INativePool.sol";

abstract contract NativePoolStorage {
    bool public isPmm;
    address public router;
    address public poolFactory;

    address public treasury;
    address public treasuryOwner;
    address public pricingModelRegistry;

    address[] public tokenAs;
    address[] public tokenBs;
    uint256 public pairCount;
    mapping(address => mapping(address => INativePool.Pair)) internal pairs;
    mapping(address => bool) public isSigner;
    mapping(address => uint256) internal nonce; // deprecated, not used anymore
    bool public isPublicTreasury;
    bool public isTreasuryContract;
    mapping(address => mapping(uint256 => bool)) public nonceMapping;

    uint256[99] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// just a placeholder now in case there is any future state variables
abstract contract NativeRouterStorage {
    address public widgetFeeSigner;
    uint256[100] private __gap;
}