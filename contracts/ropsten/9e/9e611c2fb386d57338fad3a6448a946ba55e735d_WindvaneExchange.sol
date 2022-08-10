// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ICurrencyHelper.sol";
import "./bases/TokenTransferBase.sol";
import "./bases/OrderBaseLib.sol";
import "./interfaces/IWindvaneExchange.sol";

contract WindvaneExchange is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    TokenTransferBase,
    IWindvaneExchange
{
    IWETH public weth;
    bytes32 public DOMAIN_SEPARATOR;
    ICurrencyHelper public currencyHelper;

    mapping(address => uint256) public userMinValidNonce; // 每个用户最小的有效nonce
    mapping(address => mapping(uint256 => bool)) public cancelledOrFinalized; //user address- order nonce - bool
    mapping(address => bool) public signers;
    uint256 public maxNum; //每次批量取消挂单时的数量上限
    uint256 public minPercentageToSeller; // 卖方最少收到的百分比

    function initialize(
        string calldata name_,
        string calldata version_,
        address weth_,
        address currencyHelper_
    ) public initializer {
        weth = IWETH(weth_); // 无强制类型转换功能，即IWETH(...)不校验weth_是否实现了对应接口的
        currencyHelper = ICurrencyHelper(currencyHelper_);
        minPercentageToSeller = 7500;
        maxNum = 100;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name_)),
                keccak256(bytes(version_)),
                block.chainid,
                address(this)
            )
        );

        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
    }

    //连续批量取消
    function increaseNonce(uint256 newNonce) public override nonReentrant {
        if (
            newNonce < userMinValidNonce[msg.sender] ||
            newNonce > userMinValidNonce[msg.sender] + maxNum
        ) {
            revert InvalidNewNonce();
        }
        userMinValidNonce[msg.sender] = newNonce;

        emit MinNonceIncreased(msg.sender, newNonce);
    }

    function cancelOrders(uint256[] calldata orderNonces)
        public
        override
        nonReentrant
    {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            uint256 orderNonce = orderNonces[i];
            if (
                orderNonce < userMinValidNonce[msg.sender] ||
                cancelledOrFinalized[msg.sender][orderNonce]
            ) {
                revert OrderAlreadyCancelledOrFinished();
            }
            cancelledOrFinalized[msg.sender][orderNonce] = true;
        }

        emit OrderCancelled(msg.sender, orderNonces);
    }

    function matchOrder(
        OrderBaseLib.TxInput calldata txInput,
        bytes calldata orderSig,
        bytes calldata inputSig
    ) external payable override nonReentrant whenNotPaused {
        if (txInput.taker != msg.sender) {
            revert InvalidTaker();
        }
        // 1. verify input signature
        bytes32 txInputHash = keccak256(
            abi.encode(
                keccak256(orderSig),
                keccak256(abi.encode(txInput.fees)),
                txInput.taker,
                keccak256(txInput.params),
                txInput.salt
            )
        );
        bytes32 hashToSign = OrderBaseLib.toEthSignedMessageHash(txInputHash);
        verifyInputSig(hashToSign, inputSig);

        //2. 验证order相关信息---是否已取消挂单、签名是否有效
        OrderBaseLib.MakerOrder calldata makerOrder = txInput.makerOrder;
        if (
            cancelledOrFinalized[makerOrder.maker][makerOrder.nonce] ||
            makerOrder.nonce < userMinValidNonce[makerOrder.maker]
        ) {
            revert OrderAlreadyCancelledOrFinished();
        }
        // 验证order签名
        bytes32 makerOrderHash = OrderBaseLib.hashMakerOrder(makerOrder);
        if (
            !OrderBaseLib.verifyOrderSignature(
                makerOrderHash,
                orderSig,
                makerOrder.maker,
                DOMAIN_SEPARATOR
            )
        ) {
            revert InvalidOrderSigner();
        }
        //3. 验证order中各个字段
        verifyOrderParameters(txInput);

        // 4. 处理eth特殊情况--接单者支付eth
        uint256 amountRefund = 0;
        if (makerOrder.currency == address(0)) {
            //verifyOrderParameters()中已验证：只有SELL时,currency可以是零地址
            // 买方支付的是 ETH+WETH 的话，直接将费用转到本合约中。由本合约代替买方支付手续费、支付给卖方（如果买方支付的是其他erc20，则参考下一方法的流程）
            if (makerOrder.currencyAmount > msg.value) {
                uint256 wethAmount = makerOrder.currencyAmount - msg.value;
                weth.transferFrom(txInput.taker, address(this), wethAmount);
                weth.withdraw(wethAmount); // 将用户输入的weth转换为eth
            } else {
                amountRefund = msg.value - makerOrder.currencyAmount;
            }
        }

        _matchOrder(txInput, makerOrderHash);

        //最后，将调用者msg.sender支付的多余的eth退回
        if (amountRefund > 0) {
            payable(msg.sender).transfer(amountRefund);
        }
    }

    // function BatchBuy() external payable nonReentrant whenNotPaused {}

    function _matchOrder(
        OrderBaseLib.TxInput calldata txInput,
        bytes32 makerOrderHash
    ) internal {
        //verifyOrderParameters()中已限制 仅支持三种模式：sell\offer\collection offer
        OrderBaseLib.MakerOrder calldata makerOrder = txInput.makerOrder;

        // 将默认值设为SELL模式
        address buyer = txInput.taker;
        address seller = makerOrder.maker;
        OrderBaseLib.OrderItem[] memory transferItems = makerOrder.items;
        // 4. 校验orderType--sell\offer\collection offer
        if (
            makerOrder.orderType == OrderBaseLib.OrderType.OFFER ||
            makerOrder.orderType == OrderBaseLib.OrderType.COLLECTION_OFFER
        ) {
            buyer = makerOrder.maker;
            seller = txInput.taker;
            if (
                makerOrder.orderType == OrderBaseLib.OrderType.COLLECTION_OFFER
            ) {
                uint256[] memory tokenIds = abi.decode(
                    txInput.params,
                    (uint256[])
                );
                if (tokenIds.length != transferItems.length) {
                    revert InvalidOrderItems();
                }

                for (uint256 i = 0; i < tokenIds.length; i++) {
                    transferItems[i].tokenId = tokenIds[i];
                }
            }
        } else {
            if (makerOrder.orderType != OrderBaseLib.OrderType.SELL) {
                revert InvalidOrderType();
            }
        }

        cancelledOrFinalized[makerOrder.maker][makerOrder.nonce] = true;

        _transferFeesAndFunds(
            txInput.fees,
            buyer, //付款方，即买方
            seller, //卖NFT方
            makerOrder.currencyAmount, //订单总金额
            makerOrder.currency
        );

        // 2. 本合约将 卖方账户里的NFT 转到 买方的账户
        _transferBatchOrderItems(transferItems, seller, buyer);

        emit OrderMatched(
            makerOrderHash,
            makerOrder.maker,
            txInput.taker,
            makerOrder.nonce,
            makerOrder.currency,
            makerOrder.currencyAmount
        );
    }

    // // function matchAuctionOrder(){}

    function _transferCurrencyTo(
        address currency,
        address from, //仅erc20时该参数起作用
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (address(currency) == address(0)) {
                payable(to).transfer(amount);
            } else {
                IERC20(currency).transferFrom(from, to, amount);
            }
        }
    }

    // // 支付协议费、版税， 向卖方to支付交易费用
    function _transferFeesAndFunds(
        OrderBaseLib.Fee[] calldata fees,
        address from, //buyer, transfer currency
        address to, //seller,receive currency
        uint256 currencyAmount, //订单总金额
        address currency
    ) internal {
        uint256 finalSellerAmount = currencyAmount;
        {
            address recipient;
            uint256 feeAmount;
            uint256 totalItems = fees.length;
            for (uint256 i = 0; i < totalItems; i++) {
                recipient = fees[i].recipient;
                feeAmount = fees[i].feeAmount;
                // Check parameters
                if ((recipient != address(0)) && (feeAmount != 0)) {
                    _transferCurrencyTo(currency, from, recipient, feeAmount);

                    finalSellerAmount -= feeAmount;
                }
            }
        }
        if (
            (finalSellerAmount * 10000) <
            (minPercentageToSeller * currencyAmount)
        ) {
            revert ExceededSlippage();
        }
        // 3. Transfer final amount to seller
        {
            _transferCurrencyTo(currency, from, to, finalSellerAmount);
        }
    }

    // 验证订单各个参数
    function verifyOrderParameters(OrderBaseLib.TxInput calldata txInput)
        public
        view
    {
        OrderBaseLib.MakerOrder calldata makerOrder = txInput.makerOrder;
        if (makerOrder.maker == address(0)) {
            revert InvalidMaker();
        }
        if (
            makerOrder.taker != address(0) && makerOrder.taker != txInput.taker
        ) {
            revert InvalidTaker();
        }
        if (!currencyHelper.isCurrencyInWhitelist(makerOrder.currency)) {
            revert InvalidCurrency();
        }
        if (makerOrder.items.length == 0) {
            revert InvalidOrderItems();
        }
        if (
            makerOrder.orderType == OrderBaseLib.OrderType.SELL ||
            makerOrder.orderType == OrderBaseLib.OrderType.OFFER ||
            makerOrder.orderType == OrderBaseLib.OrderType.COLLECTION_OFFER
        ) {
            // 2-1. 固定价格挂单（包含私人买卖、捆绑销售两种特殊情况）
            if (makerOrder.currencyAmount == 0) {
                revert InvalidPrice();
            }
            if (
                makerOrder.currency == address(0) &&
                makerOrder.orderType != OrderBaseLib.OrderType.SELL
            ) {
                //offer、collection offer不支持主网币eth
                revert InvalidCurrency();
            }
            if (
                makerOrder.startTime > block.timestamp ||
                block.timestamp > makerOrder.endTime
            ) {
                revert ExpiredOrder();
            }
        } else if (makerOrder.orderType == OrderBaseLib.OrderType.AUCTION) {
            //TODO 拍卖逻辑暂时跳过
            revert UnsupportAuction();
            // if (block.timestamp < makerOrder.endTime) {
            //     revert UnstoppedAuction();
            // }
        } else {
            revert InvalidOrderType();
        }
    }

    function verifyInputSig(bytes32 inputHashToSign, bytes calldata inputSig)
        public
        view
    {
        // 验证input签名
        address signer = OrderBaseLib.recover(inputHashToSign, inputSig);
        if (!signers[signer]) {
            revert InvalidSigner();
        }
    }

    function verifyOrder(
        OrderBaseLib.MakerOrder calldata makerOrder,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        bytes32 makerOrderHash = OrderBaseLib.hashMakerOrder(makerOrder);

        return
            OrderBaseLib.verifyOrderSignature(
                makerOrderHash,
                signature,
                signer,
                DOMAIN_SEPARATOR
            );
    }

    function getMakerOrderHash(OrderBaseLib.MakerOrder calldata makerOrder)
        public
        pure
        returns (bytes32)
    {
        return OrderBaseLib.hashMakerOrder(makerOrder);
    }

    ////// 一些update 状态变量的方法
    function updateMaxNum(uint256 newMaxNum) external onlyOwner {
        if (newMaxNum == 0) {
            revert InvalidMaxCancelNum();
        }
        maxNum = newMaxNum;
        emit MaxNumUpdated(newMaxNum);
    }

    function updateCurrencyHelper(address newCurrencyHelper)
        external
        onlyOwner
    {
        if (newCurrencyHelper == address(0)) {
            revert InvalidCurrencyHelper();
        }
        currencyHelper = ICurrencyHelper(newCurrencyHelper);
        emit CurrencyHelperUpdated(newCurrencyHelper);
    }

    function updateMinPercentageToSeller(uint256 newMinPercentage)
        external
        onlyOwner
    {
        if (newMinPercentage == 0 || newMinPercentage > 10000) {
            revert InvalidParameters();
        }
        minPercentageToSeller = newMinPercentage;
        emit MinPercentageToSellerUpdated(newMinPercentage);
    }

    function updateSigners(address[] memory signers_, bool[] memory status)
        public
        onlyOwner
    {
        if (signers_.length == 0 || signers_.length != status.length) {
            revert InvalidParameters();
        }
        for (uint256 i = 0; i < signers_.length; i++) {
            address signerAddress = signers_[i];

            signers[signerAddress] = status[i];
            emit SignerUpdated(signerAddress, status[i]);
        }
    }

    /////////////////////////////////////
    ////////////////////////////////////////
    // 接收ETH
    receive() external payable {}

    // 管理员：将当前合约中的各种token转给recipient
    function withdrawETH(address recipient) external onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawERC20(address token, address recipient)
        external
        onlyOwner
    {
        IERC20(token).transfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    function withdrawERC721(
        address collection,
        uint256 tokenId,
        address recipient
    ) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
    }

    function withdrawERC1155(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        IERC1155(collection).safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//IERC20Upgradeable.sol和IERC20.sol是相同的
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICurrencyHelper {
    function updateCurrencies(
        address[] memory currencyList,
        bool[] memory status
    ) external ;

    function isCurrencyInWhitelist(address currency)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./OrderBaseLib.sol";
import "../interfaces/EventsAndErrors.sol";

//// 接收、转移ERC721\ERC1155。被继承使用
contract TokenTransferBase is
    IERC721Receiver,
    IERC1155Receiver,
    EventsAndErrors
{
    // interface ERC721的 interfaceID
    // bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // interface ERC1155的 interfaceID
    // bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    function _transferOrderItem(
        OrderBaseLib.OrderItem memory item,
        address from,
        address to
    ) internal {
        if (item.amount == 0) {
            revert InvalidOrderItemAmount();
        }

        // if (item.itemType == OrderBaseLib.ItemType.NATIVE) {
        //     if ((uint160(item.token) | item.tokenId) != 0) {
        //         revert UnnecessaryItemParameters();
        //     }
        //     payable(to).transfer(item.amount);
        //     return;
        // }
        if (item.itemType == OrderBaseLib.ItemType.ERC20) {
            if (item.tokenId != 0) {
                revert UnnecessaryItemParameters();
            }

            if (item.token == address(0) || !isContract(item.token)) {
                revert InvalidAddress();
            }
            // Transfer ERC20
            IERC20(item.token).transferFrom(from, to, item.amount);
            return;
        } else if (item.itemType == OrderBaseLib.ItemType.ERC721) {
            if (item.amount != 1) {
                revert InvalidERC721TransferAmount();
            }
            if (item.token == address(0) || !isContract(item.token)) {
                revert InvalidAddress();
            }
            // Transfer ERC721
            IERC721(item.token).safeTransferFrom(from, to, item.tokenId);
        } else if (item.itemType == OrderBaseLib.ItemType.ERC1155) {
            if (item.token == address(0) || !isContract(item.token)) {
                revert InvalidAddress();
            }
            // Transfer ERC1155
            IERC1155(item.token).safeTransferFrom(
                from,
                to,
                item.tokenId,
                item.amount,
                ""
            );
        } else {
            revert InvalidItemType();
        }
    }

    function _transferBatchOrderItems(
        // transfer NFT
        OrderBaseLib.OrderItem[] memory items,
        address from, //seller,transfer NFT
        address to // buyer,receive NFT
    ) internal {
        for (uint256 i = 0; i < items.length; i++) {
            _transferOrderItem(items[i], from, to);
        }
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceId == 0x4e2312e0 || // IERC1155TokenReceiver (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
            interfaceId == 0x150b7a02; // IERC721Receiver的接口ID `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

library OrderBaseLib {
    bytes constant orderItemTypeString =
        "OrderItem(uint8 itemType,address token,uint256 tokenId,uint256 amount)";

    bytes constant makerOrderPartialTypeString =
        "MakerOrder(uint8 orderType,address maker,address taker,OrderItem[] items,address currency,uint256 currencyAmount,uint256 nonce,uint256 startTime,uint256 endTime,bytes params,uint256 salt)";
    // bytes constant feeTypeString = "Fee(uint256 feeAmount,address recipient)";
    // bytes constant txInputPartialTypeString =
    //     "TxInput(MakerOrder makerOrder,Fee[] fees,address taker,bytes params,uint256 salt)";

    // bytes32 internal constant FEE_TYPEHASH = keccak256(feeTypeString);
    bytes32 internal constant ORDER_ITEM_TYPEHASH =
        keccak256(orderItemTypeString);
    bytes32 internal constant MAKER_ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(makerOrderPartialTypeString, orderItemTypeString)
        );

    bytes4 internal constant EIP_1271_MAGICVALUE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")

    struct TxInput {
        MakerOrder makerOrder;
        Fee[] fees; //平台手续费、版税等
        address taker; //接单者，不一定是msg.sender。msg.sender负责gas费，taker负责currency、NFT的转移
        // uint256 slippage; // 该订单的滑点 eg. 1500 --> 15% ,表示卖方最少收到总价的85%、本次交易才成立
        bytes params; // 备用字段  ---当挂单者是 make collection offer的时候，该字段为接单者要卖出的tokenId:uint256[] tokenIds
        uint256 salt;
        // //订单签名
        // bytes inputSig;
    }
    struct Fee {
        uint256 feeAmount;
        address recipient;
    }

    struct MakerOrder {
        // address exchange; // 兑换合约地址--DOMAIN_SEPARATOR中已包含该信息
        OrderType orderType; // sell or buy,fixed price or auction, one or more。计算hash时用uint8代替
        address maker; // signer of the maker order
        address taker; // 如果是卖单，指定taker即为 私人买卖；如果是买单，指定taker
        OrderItem[] items; // 适用于单个、捆绑
        address currency; // currency (e.g., WETH)
        uint256 currencyAmount; // 价格
        //
        // 订单的全局信息
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp TODO
        // uint256 slippage; // TODO 卖方可以设置该参数，防止手续费过高、导致最终到手的ETH过少/slippage protection (1000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint256 salt; // prevent duplicate hashes
        // //订单签名--放在函数入参中
        // bytes orderSig;
    }

    //enum--->uint8依次表示：固定价格挂单（包含私人买卖、捆绑销售两种特殊情况）、买单（分为对某个、某些个NFT出价)或者对某一个、某些collection出价
    enum OrderType {
        INVALID,
        SELL,
        OFFER,
        COLLECTION_OFFER,
        AUCTION
    }

    struct OrderItem {
        ItemType itemType;
        address token;
        uint256 tokenId;
        uint256 amount;
    }

    enum ItemType {
        INVALID,
        NATIVE,
        ERC20,
        ERC721,
        ERC1155
    }

    function verifyOrderSignature(
        bytes32 hashedMessage, //
        bytes calldata signature,
        address signer,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        //ethers.js signer._signTypedData(...) eip-712:"\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
        bytes32 hashToSign = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hashedMessage)
        );

        if (signer.code.length > 0) {
            //contract's signature
            if (
                IERC1271(signer).isValidSignature(hashToSign, signature) ==
                EIP_1271_MAGICVALUE
            ) {
                return true;
            }
        } else {
            if (signer == recover(hashToSign, signature)) {
                return true;
            }
        }
        return false;
    }

    function recover(bytes32 hashToSign, bytes memory signature)
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return address(0);
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 ||
            (v != 27 && v != 28)
        ) {
            return address(0);
        }
        return ecrecover(hashToSign, v, r, s);
    }

    // function hashFeeess(Fee memory fee) internal pure returns (bytes32) {
    //     return
    //         keccak256(abi.encode(FEE_TYPEHASH, fee.feeAmount, fee.recipient));
    // }

    function hashOrderItem(OrderItem memory orderItem)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_ITEM_TYPEHASH,
                    orderItem.itemType,
                    orderItem.token,
                    orderItem.tokenId,
                    orderItem.amount
                )
            );
    }

    function hashMakerOrder(MakerOrder calldata makerOrder)
        internal
        pure
        returns (bytes32)
    {
        // 参考Seaport的 _deriveOrderHash()\_deriveTypehashes()
        bytes32[] memory orderItemHashes = new bytes32[](
            makerOrder.items.length
        );
        for (uint256 i = 0; i < makerOrder.items.length; ++i) {
            // Hash the offer and place the result into memory.
            orderItemHashes[i] = hashOrderItem(makerOrder.items[i]);
        }

        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_TYPEHASH,
                    makerOrder.orderType,
                    makerOrder.maker,
                    makerOrder.taker,
                    keccak256(abi.encodePacked(orderItemHashes)), //https://docs.ethers.io/v5/api/utils/abi/coder/
                    makerOrder.currency,
                    makerOrder.currencyAmount,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    keccak256(makerOrder.params),
                    makerOrder.salt
                )
            );
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "../bases/OrderBaseLib.sol";

interface IWindvaneExchange {
    function increaseNonce(uint256 newNonce) external;

    function cancelOrders(uint256[] calldata orderNonces) external;

    function matchOrder(
        OrderBaseLib.TxInput calldata txInput,
        bytes calldata orderSig,
        bytes calldata inputSig
    ) external payable;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.7;
import "../bases/OrderBaseLib.sol";

interface EventsAndErrors {
    event MinNonceIncreased(address indexed maker, uint256 newMinNonce);

    event OrderCancelled(address indexed maker, uint256[] orderNonces);
    event OrderValidated(
        bytes32 orderHash,
        address indexed maker,
        address indexed taker,
        uint256 indexed orderNonce
    );
    event OrderMatched(
        bytes32 orderHash,
        address indexed maker,
        address indexed taker,
        uint256 indexed orderNonce,
        address currency,
        uint256 currencyAmount
    );

    event FeePaid(address indexed recipient, address currency, uint256 amount);
    event MaxNumUpdated(uint256 newMaxNum);
    event CurrencyHelperUpdated(address newCurrencyHelper);
    event SignerUpdated(address indexed signer, bool status);
    event MinPercentageToSellerUpdated(uint256 newMinPercentage);
    ///////////////////////////
    error InvalidERC721TransferAmount();

    error InvalidOrderItemAmount();

    error InvalidAddress(); // address is zero , or address is not a contract

    error UnnecessaryItemParameters();
    error InvalidItemType();

    error InvalidMakerOrderType();
    error InvalidCurrency();
    error InvalidOrderType();
    error InvalidNewNonce();

    error InvalidCanceller();
    error ExceededSlippage();
    error OrderAlreadyCancelledOrFinished();
    error InvalidCurrencyHelper();
    error InvalidWethAddress();
    error InvalidMaxCancelNum();
    error InvalidParameters();
    error InvalidMaker();
    error InvalidTaker();
    error InvalidSigner();
    error InvalidOrderSigner();
    error InvalidOrderItems();
    error InvalidPrice();
    error ExpiredOrder();
    error UnstoppedAuction();
    error UnsupportAuction();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}