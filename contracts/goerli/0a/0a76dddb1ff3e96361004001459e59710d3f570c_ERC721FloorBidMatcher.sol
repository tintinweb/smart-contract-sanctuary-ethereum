// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./interfaces/INftTransferProxy.sol";
import "./interfaces/IERC20TransferProxy.sol";
import "./interfaces/IRoyaltiesProvider.sol";
import "./lib/LibPart.sol";

contract ERC721FloorBidMatcher is
    ReentrancyGuardUpgradeable,
    ContextUpgradeable
{
    using SafeMathUpgradeable for uint256;

    uint256 public ordersCount;
    uint256 public daoFeeBps;
    uint256 public maxTokensInOrder;
    address public daoAddress;

    address public erc20TransferProxy;
    address public nftTransferProxy;
    address public royaltiesRegistry;

    mapping(uint256 => ERC721FloorBidOrder) public orders;
    mapping(address => bool) public supportedERC20Tokens;

    enum OrderStatus {
        OPENED,
        PARTIALLY_EXECUTED,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }

    struct ERC721FloorBidOrder {
        address erc721TokenAddress;
        uint256 numberOfTokens;
        uint256[] erc721TokenIdsSold;
        uint256 tokenPrice;
        address paymentTokenAddress;
        uint256 amount;
        uint256 endTime;
        address creator;
        ERC721FloorBidMatcher.OrderStatus orderStatus;
    }

    struct SecondaryFee {
        uint256 remainingValue;
        uint256 feeValue;
    }

    event LogCreateBuyOrder(
        address erc721TokenAddress,
        address paymentTokenAddress,
        uint256 amount,
        uint256 endTime,
        address creator,
        uint256 orderId
    );

    event LogMatchBuyOrder(
        address erc721TokenAddress,
        uint256[] tokenIds,
        address paymentTokenAddress,
        uint256 amount,
        address taker,
        uint256 orderId
    );

    event LogCancelOrder(
        address erc721TokenAddress,
        address paymentTokenAddress,
        uint256 amount,
        uint256 endTime,
        address creator,
        uint256 orderId
    );

    event LogTokenWithdrawal(
        address erc721TokenAddress,
        address paymentTokenAddress,
        uint256 amount,
        uint256 endTime,
        address creator,
        uint256 orderId
    );

    modifier onlyDAO() {
        require(_msgSender() == daoAddress, "Not called from the dao");
        _;
    }

    function __ERC721FloorBidMatcher_init(
        address _daoAddress,
        uint256 _daoFeeBps,
        address _erc20TransferProxy,
        address _nftTransferProxy,
        address _royaltiesRegistry,
        uint256 _maxTokensInOrder,
        address[] memory _supportedERC20Tokens
    ) external initializer {
        daoAddress = _daoAddress;
        daoFeeBps = _daoFeeBps;
        erc20TransferProxy = _erc20TransferProxy;
        nftTransferProxy = _nftTransferProxy;
        royaltiesRegistry = _royaltiesRegistry;
        maxTokensInOrder = _maxTokensInOrder;
        _initSupportedERC20Tokens(_supportedERC20Tokens);
    }

    function _initSupportedERC20Tokens(address[] memory _supportedERC20Tokens)
        internal
    {
        for (uint256 i = 0; i < _supportedERC20Tokens.length; i += 1) {
            supportedERC20Tokens[_supportedERC20Tokens[i]] = true;
        }
    }

    function createBuyOrder(
        address erc721TokenAddress,
        address paymentTokenAddress,
        uint256 numberOfTokens,
        uint256 amount,
        uint256 endTime
    ) external nonReentrant {
        require(block.timestamp < endTime, "End time should be in the future");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxTokensInOrder,
            "Wrong number of tokens"
        );
        require(amount > 0, "Wrong amount");
        require(supportedERC20Tokens[paymentTokenAddress], "ERC20 token not supported");

        IERC20Upgradeable(paymentTokenAddress).approve(
            erc20TransferProxy,
            amount
        );

        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(paymentTokenAddress),
            _msgSender(),
            address(this),
            amount
        );

        ordersCount = ordersCount.add(1);
        uint256 orderId = ordersCount;

        orders[orderId].erc721TokenAddress = erc721TokenAddress;
        orders[orderId].paymentTokenAddress = paymentTokenAddress;
        orders[orderId].amount = amount;
        orders[orderId].numberOfTokens = numberOfTokens;
        orders[orderId].tokenPrice = amount.div(numberOfTokens);
        orders[orderId].endTime = endTime;
        orders[orderId].creator = _msgSender();
        orders[orderId].orderStatus = OrderStatus.OPENED;

        emit LogCreateBuyOrder(
            erc721TokenAddress,
            paymentTokenAddress,
            amount,
            endTime,
            _msgSender(),
            orderId
        );
    }

    function createBuyOrderETH(
        address erc721TokenAddress,
        uint256 numberOfTokens,
        uint256 endTime
    ) external payable nonReentrant {
        uint256 amount = msg.value;
        address paymentTokenAddress = address(0);

        require(block.timestamp < endTime, "End time should be in the future");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxTokensInOrder,
            "Wrong number of tokens"
        );
        require(amount > 0, "Wrong amount");

        ordersCount = ordersCount.add(1);
        uint256 orderId = ordersCount;

        orders[orderId].erc721TokenAddress = erc721TokenAddress;
        orders[orderId].paymentTokenAddress = paymentTokenAddress;
        orders[orderId].amount = amount;
        orders[orderId].numberOfTokens = numberOfTokens;
        orders[orderId].tokenPrice = amount.div(numberOfTokens);
        orders[orderId].endTime = endTime;
        orders[orderId].creator = _msgSender();
        orders[orderId].orderStatus = OrderStatus.OPENED;

        emit LogCreateBuyOrder(
            erc721TokenAddress,
            paymentTokenAddress,
            amount,
            endTime,
            _msgSender(),
            orderId
        );
    }

    function matchBuyOrder(uint256 orderId, uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        ERC721FloorBidOrder storage order = orders[orderId];

        require(order.endTime > block.timestamp, "Order expired");
        require(order.numberOfTokens > 0, "No tokens remaining to buy");
        require(
            order.orderStatus == OrderStatus.OPENED ||
                order.orderStatus == OrderStatus.PARTIALLY_EXECUTED,
            "Order expired"
        );

        uint256 totalSecondaryFees;

        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            uint256 secondarySaleFees = distributeSecondarySaleFees(
                order.erc721TokenAddress,
                order.paymentTokenAddress,
                tokenIds[i],
                order.tokenPrice
            );

            INftTransferProxy(nftTransferProxy).erc721safeTransferFrom(
                IERC721Upgradeable(order.erc721TokenAddress),
                _msgSender(),
                order.creator,
                tokenIds[i]
            );

            order.erc721TokenIdsSold.push(tokenIds[i]);
            totalSecondaryFees = totalSecondaryFees.add(secondarySaleFees);
        }

        uint256 amountToPay = tokenIds.length.mul(order.tokenPrice);
        uint256 daoFee = daoFeeBps.mul(amountToPay - totalSecondaryFees).div(10000);

        if (order.paymentTokenAddress == address(0)) {
            (bool daoTransferSuccess, ) = payable(daoAddress).call{
                value: daoFee
            }("");
            require(daoTransferSuccess, "Failed");

            (bool buyerTransferSuccess, ) = payable(_msgSender()).call{
                value: amountToPay.sub(daoFee).sub(totalSecondaryFees)
            }("");
            require(buyerTransferSuccess, "Failed");
        } else {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(order.paymentTokenAddress),
                address(this),
                daoAddress,
                daoFee
            );
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(order.paymentTokenAddress),
                address(this),
                _msgSender(),
                amountToPay.sub(daoFee).sub(totalSecondaryFees)
            );
        }

        order.numberOfTokens = order.numberOfTokens.sub(tokenIds.length);
        order.amount = order.amount.sub(amountToPay);
        (order.numberOfTokens == 0)
            ? order.orderStatus = OrderStatus.EXECUTED
            : order.orderStatus = OrderStatus.PARTIALLY_EXECUTED;

        emit LogMatchBuyOrder(
            order.erc721TokenAddress,
            tokenIds,
            order.paymentTokenAddress,
            amountToPay,
            _msgSender(),
            orderId
        );
    }

    function cancelOrder(uint256 orderId) external nonReentrant {
        ERC721FloorBidOrder storage order = orders[orderId];

        require(order.endTime > block.timestamp, "Order expired");
        require(order.creator == _msgSender(), "Only creator can cancel");
        require(order.numberOfTokens > 0, "No tokens remaining to buy");
        require(
            order.orderStatus == OrderStatus.OPENED ||
                order.orderStatus == OrderStatus.PARTIALLY_EXECUTED,
            "Order expired"
        );

        if (order.paymentTokenAddress == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: order.amount}(
                ""
            );
            require(success, "Failed");
        } else {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(order.paymentTokenAddress),
                address(this),
                _msgSender(),
                order.amount
            );
        }

        order.orderStatus = OrderStatus.CANCELLED;

        emit LogCancelOrder(
            order.erc721TokenAddress,
            order.paymentTokenAddress,
            order.amount,
            order.endTime,
            _msgSender(),
            orderId
        );
    }

    function withdrawFundsFromExpiredOrder(uint256 orderId)
        external
        nonReentrant
    {
        ERC721FloorBidOrder storage order = orders[orderId];

        require(order.endTime < block.timestamp, "Order not expired");
        require(order.creator == _msgSender(), "Only creator can cancel");
        require(order.numberOfTokens > 0, "No tokens remaining to buy");
        require(
            order.orderStatus == OrderStatus.OPENED ||
                order.orderStatus == OrderStatus.PARTIALLY_EXECUTED,
            "Order expired"
        );

        if (order.paymentTokenAddress == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: order.amount}(
                ""
            );
            require(success, "Failed");
        } else {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(order.paymentTokenAddress),
                address(this),
                _msgSender(),
                order.amount
            );
        }

        order.orderStatus = OrderStatus.EXPIRED;

        emit LogTokenWithdrawal(
            order.erc721TokenAddress,
            order.paymentTokenAddress,
            order.amount,
            order.endTime,
            _msgSender(),
            orderId
        );
    }

    function setDaoFeeBps(uint256 _daoFeeBps) external onlyDAO {
        daoFeeBps = _daoFeeBps;
    }

    function setMaxTokensInOrder(uint256 _maxTokensInOrder) external onlyDAO {
        maxTokensInOrder = _maxTokensInOrder;
    }

    function setERC20TransferProxy(address _erc20TransferProxy)
        external
        onlyDAO
    {
        erc20TransferProxy = _erc20TransferProxy;
    }

    function setNFTTransferProxy(address _nftTransferProxy) external onlyDAO {
        nftTransferProxy = _nftTransferProxy;
    }

    function setRoylatiesRegistry(address _royaltiesRegistry) external onlyDAO {
        royaltiesRegistry = _royaltiesRegistry;
    }

    function getSoldTokensFromOrder(uint256 orderId)
        public
        view
        returns (uint256[] memory)
    {
        ERC721FloorBidOrder memory order = orders[orderId];
        return order.erc721TokenIdsSold;
    }

    function distributeSecondarySaleFees(
        address erc721TokenAddress,
        address paymentTokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal returns (uint256) {
        (LibPart.Part[] memory nftRoyalties, LibPart.Part[] memory collectionRoyalties) = IRoyaltiesProvider(royaltiesRegistry)
            .getRoyalties(erc721TokenAddress, tokenId);

        uint256 totalFees = 0;
        if (collectionRoyalties.length > 0) {
            uint256 value = amount;

            for (uint256 i = 0; i < collectionRoyalties.length && i < 5; i += 1) {
                SecondaryFee memory interimFee = subFee(
                    value,
                    amount.mul(collectionRoyalties[i].value).div(10000)
                );
                value = interimFee.remainingValue;
                if (interimFee.feeValue > 0) {
                    if (paymentTokenAddress == address(0)) {
                        (bool success, ) = payable(collectionRoyalties[i].account).call{
                            value: interimFee.feeValue
                        }("");
                        require(success, "Failed");
                    } else {
                        IERC20TransferProxy(erc20TransferProxy)
                            .erc20safeTransferFrom(
                                IERC20Upgradeable(paymentTokenAddress),
                                address(this),
                                address(collectionRoyalties[i].account),
                                interimFee.feeValue
                            );
                    }
                    totalFees = totalFees.add(interimFee.feeValue);
                }
            }
        }

        // Calculate the Collection Fees from the remained amount
        if (nftRoyalties.length > 0) {
            uint256 leftAmount = amount - totalFees;
            uint256 value = amount - totalFees;

            for (uint256 i = 0; i < nftRoyalties.length && i < 5; i += 1) {
                SecondaryFee memory interimFee = subFee(
                    value,
                    leftAmount.mul(nftRoyalties[i].value).div(10000)
                );
                value = interimFee.remainingValue;

                if (interimFee.feeValue > 0) {
                    if (paymentTokenAddress == address(0)) {
                        (bool success, ) = payable(nftRoyalties[i].account).call{
                            value: interimFee.feeValue
                        }("");
                        require(success, "Failed");
                    } else {
                        IERC20TransferProxy(erc20TransferProxy)
                            .erc20safeTransferFrom(
                                IERC20Upgradeable(paymentTokenAddress),
                                address(this),
                                address(nftRoyalties[i].account),
                                interimFee.feeValue
                            );
                    }
                    totalFees = totalFees.add(interimFee.feeValue);
                }
            }
        }
        return totalFees;
    }

    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (SecondaryFee memory interimFee)
    {
        if (value > fee) {
            interimFee.remainingValue = value - fee;
            interimFee.feeValue = fee;
        } else {
            interimFee.remainingValue = 0;
            interimFee.feeValue = value;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {

    struct ERC721BundleItem {
        address tokenAddress;
        uint256[] tokenIds;
    }

    struct ERC721Item {
        address tokenAddress;
        uint256 tokenId;
    }

    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(IERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    function erc721BundleSafeTransferFrom(ERC721BundleItem[] calldata erc721BundleItems, address from, address to) external; 

    function erc721BatchTransfer(ERC721Item[] calldata erc721Items, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../lib/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory, LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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