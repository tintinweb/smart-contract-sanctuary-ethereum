// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC1155Airdrop is Context, ReentrancyGuard {

    /// @notice ERC1155 NFT
    IERC1155 public token;
    IERC1155 public tokenV2;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256 tokenId,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC1155 _token,
        IERC1155 _tokenV2
    ) public {
        require(address(_token) != address(0), "Invalid NFT");
        require(address(_tokenV2) != address(0), "Invalid NFT");

        token = _token;
        tokenV2 = _tokenV2;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenId id of the token
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC1155 _token, uint256 _tokenId, address[] memory _recipients) external nonReentrant {
        require(
            _token == token || _token == tokenV2,
            "ERC1155Airdrop: Token is not allowed"
        );
        require(
            _token.balanceOf(_msgSender(), _tokenId) >= _recipients.length,
            "ERC1155Airdrop: Caller does not have amount of tokens"
        );
        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC1155Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenId, 1, "");
        }

        emit AirdropFinished(_tokenId, _recipients);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "./ERC721SaleNonceHolder.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../tokens/HasSecondarySale.sol";
import "../tge/interfaces/IBEP20.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../libs/RoyaltyLibrary.sol";
import "../service_fee/RoyaltiesStrategy.sol";
import "./VipPrivatePublicSaleInfo.sol";

contract ERC721Sale is ReentrancyGuard, RoyaltiesStrategy, VipPrivatePublicSaleInfo {
    using ECDSA for bytes32;
    using RoyaltyLibrary for RoyaltyLibrary.Strategy;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce
    );
    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        uint256 price,
        address buyer
    );

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    address public transferProxy;
    address public serviceFeeProxy;
    address public nonceHolder;
    address public tradeTokenManager;

    constructor(
        address _transferProxy,
        address _nonceHolder,
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
    }

    function buy(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        bytes memory _signature
    ) public payable nonReentrant {
        
        bytes32 saleId = getID(_owner, _token, _tokenId);

        // clean up saleInfo
        if(!whitelistNeeded(saleId) && saleInfo[saleId].vipSaleDate >= 0) {
            delete saleInfo[saleId];
        }

        require(
            IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721),
            "ERC721Sale: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC721(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "ERC721Sale: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "ERC721Sale: Royalty Token address does not match buy token"
            );
        }

        require(whitelisted(saleId, msg.sender), "You should be whitelisted and sale should have started");

        require(
            IERC721(_token).ownerOf(_tokenId) == _owner,
            "ERC721Sale: Seller is not the owner of the token"
        );

        uint256 receiveAmount;
        if (_payToken == address(0)) {
            receiveAmount = msg.value;
        } else {
            require(TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true, "ERC721Sale: Pay Token is not allowed");
            receiveAmount = IBEP20(_payToken).allowance(_msgSender(), address(this));
        }

        uint256 price = receiveAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(_msgSender()).add(10000));

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _payToken,
            _owner,
            price,
            _signature
        );
        verifyOpenAndModifyState(_token, _tokenId, _owner, nonce);
        if (_royaltyToken != address(0)) {
            _distributeProfit(_royaltyToken, _tokenId, _payToken, _owner, price, receiveAmount);
        } else {
            _distributeProfit(_token, _tokenId, _payToken, _owner, price, receiveAmount);
        }

        TransferProxy(transferProxy).erc721safeTransferFrom(_token, _owner, _msgSender(), _tokenId);

        emit Buy(_token, _tokenId, _owner, _payToken, price, _msgSender());
    }

    function _distributeProfit(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _totalPrice,
        uint256 _receiveAmount
    ) internal {
        bool supportSecondarySale = IERC165(_token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        uint256 sellerServiceFee;
        uint256 sellerReceiveAmount;
        uint256 royalties;
        if (supportSecondarySale) {
            bool isSecondarySale = HasSecondarySale(_token).checkSecondarySale(_tokenId);
            uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, isSecondarySale);
            sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
            sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
            /*
               * The sellerReceiveAmount is on sale price minus seller service fee minus buyer service fee
               * This make sures we have enough balance even the royalties is 100%
            */
            if (
                IERC165(_token).supportsInterface(_INTERFACE_ID_FEES)
                || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
                || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
            )
                royalties = _payOutRoyaltiesByStrategy(_token, _tokenId, _payToken, _msgSender(), sellerReceiveAmount, isSecondarySale);
            sellerReceiveAmount = sellerReceiveAmount.sub(royalties);
            HasSecondarySale(_token).setSecondarySale(_tokenId);
        } else {
            // default to second sale if it's random 721 token
            uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, true);
            sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
            sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
        }
        if (_payToken == address(0)) {
            _owner.transfer(sellerReceiveAmount);
            serviceFeeRecipient.transfer(sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        } else {
            IBEP20(_payToken).transferFrom(_msgSender(), _owner, sellerReceiveAmount);
            IBEP20(_payToken).transferFrom(_msgSender(), serviceFeeRecipient, sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        }
    }

    function cancel(address token, uint256 tokenId) public {
        uint256 nonce = ERC721SaleNonceHolder(nonceHolder).getNonce(token, tokenId, _msgSender());
        ERC721SaleNonceHolder(nonceHolder).setNonce(token, tokenId, _msgSender(), nonce.add(1));

        emit CloseOrder(token, tokenId, _msgSender(), nonce.add(1));
    }

    function verifySignature(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _price,
        bytes memory _signature
    ) internal view returns (uint256 nonce) {
        nonce = ERC721SaleNonceHolder(nonceHolder).getNonce(_token, _tokenId, _owner);
        address owner;
        if (_payToken == address(0)) {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _price, nonce)).toEthSignedMessageHash().recover(_signature);
        } else {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _payToken, _price, nonce)).toEthSignedMessageHash().recover(_signature);
        }
        require(
            owner == _owner,
            "ERC721Sale: Incorrect signature"
        );
    }

    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        address _owner,
        uint256 _nonce
    ) internal {
        ERC721SaleNonceHolder(nonceHolder).setNonce(_token, _tokenId, _owner, _nonce.add(1));
        emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../roles/OperatorRole.sol";

contract TransferProxy is OperatorRole {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        address token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator {
        IERC1155(token).safeTransferFrom(_from, _to, _id, _value, _data);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/IServiceFee.sol";
import "../roles/AdminRole.sol";

/**
 * @notice Service Fee Proxy to communicate service fee contract
 */
contract ServiceFeeProxy is AdminRole {
    /// @notice service fee contract
    IServiceFee public serviceFeeContract;

    event ServiceFeeContractUpdated(address serviceFeeContract);

    /**
     * @notice Lets admin set the service fee contract
     * @param _serviceFeeContract address of serviceFeeContract
     */
    function setServiceFeeContract(address _serviceFeeContract) onlyAdmin external {
        require(
            _serviceFeeContract != address(0),
            "ServiceFeeProxy.setServiceFeeContract: Zero address"
        );
        serviceFeeContract = IServiceFee(_serviceFeeContract);
        emit ServiceFeeContractUpdated(_serviceFeeContract);
    }

    /**
     * @notice Fetch sell service fee bps from service fee contract
     * @param _seller address of seller
     */
    function getSellServiceFeeBps(address _seller, bool isSecondarySale) external view returns (uint256) {
        require(
            _seller != address(0),
            "ServiceFeeProxy.getSellServiceFeeBps: Zero address"
        );
        return serviceFeeContract.getSellServiceFeeBps(_seller, isSecondarySale);
    }

    /**
     * @notice Fetch buy service fee bps from service fee contract
     * @param _buyer address of seller
     */
    function getBuyServiceFeeBps(address _buyer) external view returns (uint256) {
        require(
            _buyer != address(0),
            "ServiceFeeProxy.getBuyServiceFeeBps: Zero address"
        );
        return serviceFeeContract.getBuyServiceFeeBps(_buyer);
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address payable) {
        return serviceFeeContract.getServiceFeeRecipient();
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) external onlyAdmin {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFeeProxy.setServiceFeeRecipient: Zero address"
        );

        serviceFeeContract.setServiceFeeRecipient(_serviceFeeRecipient);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../roles/OperatorRole.sol";

contract ERC721SaleNonceHolder is OperatorRole {
    // keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    // keccak256(token, owner, tokenId, nonce) => completed amount
    mapping(bytes32 => uint256) public completed;

    function getNonce(
        address token,
        uint256 tokenId,
        address owner
    ) public view returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    function setNonce(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public onlyOperator {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    function getNonceKey(
        address token,
        uint256 tokenId,
        address owner
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }

    function getCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public view returns (uint256) {
        return completed[getCompletedKey(token, tokenId, owner, nonce)];
    }

    function setCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce,
        uint256 _completed
    ) public onlyOperator {
        completed[getCompletedKey(token, tokenId, owner, nonce)] = _completed;
    }

    function getCompletedKey(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner, nonce));
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/introspection/ERC165.sol";

abstract contract HasSecondarySaleFees is ERC165 {

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    constructor() public {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function getFeeRecipients(uint256 id) public virtual view returns (address payable[] memory);
    function getFeeBps(uint256 id) public virtual view returns (uint[] memory);
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../interfaces/IHasSecondarySale.sol";

abstract contract HasSecondarySale is ERC165, IHasSecondarySale {

    // From IHasSecondarySale
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;

    constructor() public {
        _registerInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/ITokenManager.sol";
import "../roles/AdminRole.sol";
import "../tge/interfaces/IBEP20.sol";

contract TradeTokenManager is ITokenManager, AdminRole {

    struct TradeToken {
        string symbol;
        bool created;
        bool active;
    }

    /// @notice ERC20 Token address -> active boolean
    mapping(address => TradeToken) public tokens;

    modifier exist(address _token) {
        require(tokens[_token].created != false, "TradeTokenManager: Token is not added");
        _;
    }

    function addToken(address _erc20Token,string calldata _symbol, bool _active) onlyAdmin external {
        require(_erc20Token != address(0), "TradeTokenManager: Cannot be zero address");
        require(tokens[_erc20Token].created == false, "TradeTokenManager: Token already exist");
        require(IBEP20(_erc20Token).totalSupply() != 0, "TradeTokenManager: Token is not ERC20 standard");
        tokens[_erc20Token] = TradeToken({
            symbol: _symbol,
            created: true,
            active: _active
        });
    }

    function setToken(address _erc20Token, bool _active) onlyAdmin exist(_erc20Token) external override {
        tokens[_erc20Token].active = _active;
    }

    function removeToken(address _erc20Token) onlyAdmin exist(_erc20Token) external override {
        delete tokens[_erc20Token];
    }

    function supportToken(address _erc20Token) exist(_erc20Token) external view override returns (bool) {
        return tokens[_erc20Token].active;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../roles/AdminRole.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IRoyalty.sol";
import "../libs/NftTokenLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NftTokenManager is ITokenManager, AdminRole {
    struct NftToken {
        string name;
        bool created;
        bool active;
        NftTokenLibrary.TokenType tokenType;
    }

    /// @notice ERC1155 or ERC721 Token address -> active boolean
    mapping(address => NftToken) public tokens;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    modifier exist(address _token) {
        require(tokens[_token].created != false, "NftTokenManager: Token is not added");
        _;
    }
    // TODO: Add Token By Batch
    function addToken(address _token, string calldata _name, bool _active, NftTokenLibrary.TokenType _tokenType) onlyAdmin external {
        require(_token != address(0), "NftTokenManager: Cannot be zero address");
        require(tokens[_token].created == false, "NftTokenManager: Token already exist");
        // TODO: Add Royalty type and link royalty to erc token
        if (_tokenType != NftTokenLibrary.TokenType.REFINABLE_ROYALTY_ERC721_CONTRACT && _tokenType != NftTokenLibrary.TokenType.REFINABLE_ROYALTY_ERC1155_CONTRACT) {
            require(
                IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721) || IERC1155(_token).supportsInterface(_INTERFACE_ID_ERC1155),
                "NftTokenManager: Token is not ERC1155 or ERC721 standard"
            );
        } else {
            require(
                IERC165(_token).supportsInterface(type(IRoyalty).interfaceId),
                "NftTokenManager: Token is not IRoyalty standard"
            );
        }
        tokens[_token] = NftToken({
        name : _name,
        created : true,
        active : _active,
        tokenType : _tokenType
        });
    }

    function setToken(address _token, bool _active) onlyAdmin exist(_token) external override {
        tokens[_token].active = _active;
    }

    function removeToken(address _token) onlyAdmin exist(_token) external override {
        delete tokens[_token];
    }

    function supportToken(address _token) exist(_token) external view override returns (bool) {
        return tokens[_token].active;
    }

    function getTokenType(address _token) exist(_token) external view returns (NftTokenLibrary.TokenType) {
        return tokens[_token].tokenType;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

library RoyaltyLibrary {
    enum Strategy {
        ROYALTY_STRATEGY, // get royalty from the sales price (default)
        PROFIT_DISTRIBUTION_STRATEGY, // profit sharing from a fixed royalties of the sales price
        PRIMARY_SALE_STRATEGY // 1 party get royalty from primary sale, secondary sale will follow ROYALTY_STRATEGY
    }

    struct RoyaltyInfo {
        uint256 value; //bps
        Strategy strategy;
    }

    struct RoyaltyShareDetails {
        address payable recipient;
        uint256 value; // bps
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";

import "../libs/RoyaltyLibrary.sol";
import "../tokens/v2/ERC721BaseV2.sol";
import "../tge/interfaces/IBEP20.sol";
import "../tokens/Royalty.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../interfaces/IPrimaryRoyalty.sol";

abstract contract RoyaltiesStrategy is Context {
    using SafeMath for uint256;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyShareDetails;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyInfo;

    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    function _payOutRoyaltiesByStrategy(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address _payer,
        uint256 _actualPrice, // the total paid price - seller service fee - buyer service fee
        bool _isSecondarySale
    ) internal returns (uint256){
        /*
           * The _totalPrice is on sale price minus seller service fee minus buyer service fee
           * This make sures we have enough balance even the royalties is 100%
        */
        uint256 royalties;
        if (
            IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        ) {
            royalties = _payOutRoyalties(_token, _tokenId, _payToken, _payer, _actualPrice, _isSecondarySale);
        } else {
            // support the old contract with no strategy
            address payable[] memory recipients = HasSecondarySaleFees(_token).getFeeRecipients(_tokenId);
            uint256[] memory royaltyShares = HasSecondarySaleFees(_token).getFeeBps(_tokenId);
            require(royaltyShares.length == recipients.length, "RoyaltyStrategy: Royalty share array length not match recipients array length");
            uint256 sumRoyaltyShareBps;
            for (uint256 i = 0; i < royaltyShares.length; i++) {
                sumRoyaltyShareBps = sumRoyaltyShareBps.add(royaltyShares[i]);
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should not exceed 10000"
            );
            for (uint256 i = 0; i < royaltyShares.length; i++) {
                uint256 recipientRoyalty = _actualPrice.mul(royaltyShares[i]).div(10 ** 4);
                _transferToken(_payToken, _payer, recipients[i], recipientRoyalty);
                royalties = royalties.add(recipientRoyalty);
            }
        }
        return royalties;
    }

    function _payOutRoyalties(address _token, uint256 _tokenId, address _payToken, address _payer, uint256 _payPrice, bool _isSecondarySale) internal returns (uint256) {
        uint256 royalties;
        RoyaltyLibrary.RoyaltyInfo memory royalty = Royalty(_token).getRoyalty(_tokenId);
        RoyaltyLibrary.RoyaltyShareDetails[] memory royaltyShares;
        if (royalty.strategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY && _isSecondarySale == false) {
            if (IERC165(_token).supportsInterface(type(IPrimaryRoyalty).interfaceId)) {
                royaltyShares = IPrimaryRoyalty(_token).getPrimaryRoyaltyShares(_tokenId);
            } else {
                royaltyShares = Royalty(_token).getRoyaltyShares(_tokenId);
            }
        } else {
            royaltyShares = Royalty(_token).getRoyaltyShares(_tokenId);
        }
        _checkRoyaltiesBps(royalty, royaltyShares);
        for (uint256 i = 0; i < royaltyShares.length; i++) {
            uint256 recipientRoyalty;
            if (royalty.strategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY && _isSecondarySale) {
                recipientRoyalty = _payPrice.mul(royalty.value).mul(royaltyShares[i].value).div(10 ** 8);
            } else {
                recipientRoyalty = _payPrice.mul(royaltyShares[i].value).div(10 ** 4);
            }
            _transferToken(_payToken, _payer, royaltyShares[i].recipient, recipientRoyalty);
            royalties = royalties.add(recipientRoyalty);
        }
        return royalties;
    }

    function _checkRoyaltiesBps(RoyaltyLibrary.RoyaltyInfo memory _royalty, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal pure {
        require(
            _royalty.value <= 10 ** 4,
            "RoyaltyStrategy: Royalty bps should be less than 10000"
        );
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }
        if (_royalty.strategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should be 10000"
            );
        } else {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should not exceed 10000"
            );
        }
    }

    function _transferToken(address _payToken, address _payer, address payable _recipient, uint256 _amount) internal {
        if (_payToken == address(0)) {
            _recipient.transfer(_amount);
        } else {
            if (_payer == address(this)) {
                IBEP20(_payToken).transfer(_recipient, _amount);
            } else {
                IBEP20(_payToken).transferFrom(_payer, _recipient, _amount);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165Checker} from "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract VipPrivatePublicSaleInfo is Ownable {

    using ERC165Checker for address;

    enum WhitelistType{ VIP, PRIVATE }

    struct SaleInfo {
        uint256 vipSaleDate;
        mapping(address => bool) vipWhitelist;
        uint256 privateSaleDate;
        mapping(address => bool) privateWhitelist;
        uint256 publicSaleDate;
        address creator;
    }

    /// @dev address -> token id -> sale info
    mapping(bytes32 => SaleInfo) public saleInfo;

    event Whitelisted(WhitelistType whitelistType, address indexed account, bool isWhitelisted);

    modifier onlyCreator(bytes32 _saleId) {
        require(saleInfo[_saleId].creator == msg.sender, "Whitelist: Not Sale creator");
        _;
    }

    function setSaleInfo(        
        address _token,
        uint256 _tokenId,
        uint256 _vipSaleDate,
        uint256 _privateSaleDate,
        uint256 _publicSaleDate
    ) external {

        if(_token.supportsInterface(type(IERC1155).interfaceId)) {
            require(
                IERC1155(_token).balanceOf(msg.sender, _tokenId) > 0,
                "ERC1155Sale: Caller doesn't have any tokens"
            );
        } else if(_token.supportsInterface(type(IERC721).interfaceId)) {
            require(
                IERC721(_token).ownerOf(_tokenId) == msg.sender,
                "ERC721Sale: Caller doesn't this tokenId"
            );
        } else {
            require(false, "not ERC1155 or ERC721 token");
        }

        bytes32 saleId = getID(msg.sender, _token, _tokenId);

        saleInfo[saleId] = SaleInfo({
            vipSaleDate: _vipSaleDate,
            privateSaleDate: _privateSaleDate,
            publicSaleDate: _publicSaleDate,
            creator: msg.sender
        });
    }

    function batchSetSaleInfo(
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        uint256 _vipSaleDate,
        uint256 _privateSaleDate,
        uint256 _publicSaleDate
    ) external {         

        require(_tokens.length == _tokenIds.length, "tokens and token ids length doesnt match");

        for(uint i = 0; i < _tokenIds.length; i++) {

            if(_tokens[i].supportsInterface(type(IERC1155).interfaceId)) {
                require(
                    IERC1155(_tokens[i]).balanceOf(msg.sender, _tokenIds[i]) > 0,
                    "ERC1155Sale: Caller doesn't have any tokens"
                );
            } else if(_tokens[i].supportsInterface(type(IERC721).interfaceId)) {
                require(
                    IERC721(_tokens[i]).ownerOf(_tokenIds[i]) == msg.sender,
                    "ERC721Sale: Caller doesn't this tokenId"
                );
            } else {
                require(false, "not ERC1155 or ERC721 token");
            }


            bytes32 saleId = getID(msg.sender, _tokens[i], _tokenIds[i]);
            saleInfo[saleId] = SaleInfo({
                vipSaleDate: _vipSaleDate,
                privateSaleDate: _privateSaleDate,
                publicSaleDate: _publicSaleDate,
                creator: msg.sender
            });
        }
    }

    function whitelisted(bytes32 saleId, address _address)
    public
    view
    returns (bool)
    {

        // if it doesn't exist, we just allow sale to go through
        if(saleInfo[saleId].creator == address(0)) {
            return true;
        }

        // should be whitelisted if we're in the VIP sale
        if(
            saleInfo[saleId].vipSaleDate <= _getNow() &&
            saleInfo[saleId].privateSaleDate > _getNow() 
        ) {
            return saleInfo[saleId].vipWhitelist[_address];
        }
        

        // should be whitelisted if we're in the Private sale
        if(
            saleInfo[saleId].privateSaleDate <= _getNow() && 
            saleInfo[saleId].publicSaleDate > _getNow() 
        ) {
            return 
                saleInfo[saleId].vipWhitelist[_address] || 
                saleInfo[saleId].privateWhitelist[_address];
        }

        return false;
    }

    function whitelistNeeded(bytes32 saleId)
    public
    view
    returns (bool)
    {
        // whitelist has passed when now is > vip and private sale date
        if(
            saleInfo[saleId].vipSaleDate < _getNow() &&
            saleInfo[saleId].privateSaleDate < _getNow() &&
            saleInfo[saleId].publicSaleDate < _getNow()

        ) {
            return false;
        }


        return true;
    }

    function toggleAddressByBatch(bytes32[] memory _saleIds, WhitelistType[][] memory _whitelistTypes, address[][][] memory _addresses, bool enable)
    public
    {
        // for many sale ids
        for(uint i = 0; i < _saleIds.length; i++) {       

            require(saleInfo[_saleIds[i]].creator == msg.sender, "Whitelist: Not Sale creator");

            // 1 sale can have many whitelist types
            for (uint256 j = 0; j < _whitelistTypes[i].length; j++) {

                // 1 whitelist type can have many addresses
                for(uint k = 0; k < _addresses[i][j].length; k++) {
                    if(_whitelistTypes[i][j] == WhitelistType.VIP) {
                        require(saleInfo[_saleIds[i]].vipWhitelist[_addresses[i][j][k]] == !enable);
                        saleInfo[_saleIds[i]].vipWhitelist[_addresses[i][j][k]] = enable;
                        emit Whitelisted(WhitelistType.VIP, _addresses[i][j][k], enable);
                    }
                    if(_whitelistTypes[i][j] == WhitelistType.PRIVATE) {
                        require(saleInfo[_saleIds[i]].privateWhitelist[_addresses[i][j][k]] == !enable);
                        saleInfo[_saleIds[i]].privateWhitelist[_addresses[i][j][k]] = enable;
                        emit Whitelisted(WhitelistType.PRIVATE, _addresses[i][j][k], enable);
                    }
                }
            }
        }
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /*
     * @notice Get Sale info with owner address and token id
     * @param _owner address of token Owner
     * @param _tokenId Id of token
     */
    function getSaleInfo(
        address _owner,
        address _token,
        uint256 _tokenId
    ) public view returns (bytes32 saleId, uint256 vipSaleDate, uint256 privateSaleDate, uint256 publicSaleDate, address creator) {

        bytes32 _saleId = getID(_owner, _token, _tokenId);

        require(saleInfo[_saleId].vipSaleDate >= 0, "VipPrivatePublicSale: Sale has no dates set");

        return (_saleId, saleInfo[_saleId].vipSaleDate, saleInfo[_saleId].privateSaleDate, saleInfo[_saleId].publicSaleDate, saleInfo[_saleId].creator);
    }



    
    function getID(address _owner, address _token, uint256 _tokenId) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_owner, ":", _token, ":",Strings.toString(_tokenId)));
    }

    function getIDBatch(address[] memory _owners, address[] memory _tokens, uint256[] memory _tokenIds) public pure returns (bytes32[] memory) {
        
        require(_tokenIds.length <= 100, "You are requesting too many ids, max 100");
        require(_tokenIds.length == _owners.length, "tokenIds length != owners length");
        require(_tokenIds.length == _tokens.length, "tokenIds length != tokens length");
        
        bytes32[] memory ids = new bytes32[](_tokenIds.length);
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            ids[i] = getID(_owners[i], _tokens[i], _tokenIds[i]);
        }

        return ids;
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract OperatorRole is AccessControl {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "Ownable: caller is not the operator");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addOperator(address _account) public onlyAdmin {
        _setupRole(OPERATOR_ROLE , _account);
    }

    function removeOperator(address _account) public onlyAdmin {
        revokeRole(OPERATOR_ROLE , _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function isOperator(address _account) internal virtual view returns(bool) {
        return hasRole(OPERATOR_ROLE , _account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @notice Service Fee interface for Refinable NFT Marketplace
 */
interface IServiceFee {

    /**
     * @notice Lets admin set the refinable token contract
     * @param _refinableTokenContract address of refinable token contract
     */
    function setRefinableTokenContract(address _refinableTokenContract) external;

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) external;

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) external;

    /**
     * @notice Calculate the seller service fee in according to the business logic and returns it
     * @param _seller address of seller
     * @param _isPrimarySale sale is primary or secondary
     */
    function getSellServiceFeeBps(address _seller, bool _isPrimarySale) external view returns (uint256);

    /**
     * @notice Calculate the buyer service fee in according to the business logic and returns it
     * @param _buyer address of buyer
     */
    function getBuyServiceFeeBps(address _buyer) external view returns (uint256);

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address payable);

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) external;
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AdminRole is AccessControl {

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface IHasSecondarySale {

    /*
     * bytes4(keccak256('checkSecondarySale(uint256)')) == 0x0e883747
     * bytes4(keccak256('setSecondarySale(uint256)')) == 0x5b1d0f4d
     *
     * => 0x0e883747 ^ 0x5b1d0f4d == 0x5595380a
     */
//    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
//
//    constructor() public {
//        _registerInterface(_INTERFACE_ID_HAS_SECONDARY_SALE);
//    }

    function checkSecondarySale(uint256 tokenId) external view returns (bool);
    function setSecondarySale(uint256 tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ITokenManager {
    function setToken(address _token, bool _active) external;

    function removeToken(address _token) external;

    function supportToken(address _token) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/RoyaltyLibrary.sol";

interface IRoyalty {
    using RoyaltyLibrary for RoyaltyLibrary.Strategy;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyInfo;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyShareDetails;

    /*
     * bytes4(keccak256('getRoyalty(uint256)')) == 0x1af9cf49
     * bytes4(keccak256('getRoyaltyShares(uint256)')) == 0xac04f243
     * bytes4(keccak256('getTokenContract()') == 0x28b7bede
     *
     * => 0x1af9cf49 ^ 0xac04f243 ^ 0x28b7bede  == 0x9e4a83d4
     */

    //    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x9e4a83d4;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_ROYALTY);
    //    }

    function getRoyalty(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyInfo memory);

    function getRoyaltyShares(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyShareDetails[] memory);

    function getTokenContract() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

library NftTokenLibrary {
    // DO NOT change the ordering
    enum TokenType {
        ERC721_CONTRACT, // 0
        ERC1155_CONTRACT, // 1
        REFINABLE_ERC721_CONTRACT, // 2
        REFINABLE_ERC1155_CONTRACT, // 3
        REFINABLE_ERC721_V2_CONTRACT, // 4
        REFINABLE_ERC1155_V2_CONTRACT, // 5
        REFINABLE_WHITELISTED_ERC721_CONTRACT, // 6
        REFINABLE_WHITELISTED_ERC1155_CONTRACT, // 7
        REFINABLE_WHITELISTED_ERC721_V2_CONTRACT, // 8
        REFINABLE_WHITELISTED_ERC1155_V2_CONTRACT, // 9
        REFINABLE_WHITELISTED_ERC721_V3_CONTRACT, // 10
        REFINABLE_WHITELISTED_ERC1155_V3_CONTRACT, // 11
        REFINABLE_ROYALTY_ERC721_CONTRACT, // 12
        REFINABLE_ROYALTY_ERC1155_CONTRACT // 13
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "../HasContractURI.sol";
import "../HasSecondarySale.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721BaseV2 is
HasSecondarySale,
HasContractURI,
ERC721Burnable,
MinterRole,
Royalty
{
    /// @dev sale is primary or secondary
    mapping(uint256 => bool) public isSecondarySale;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;


    /**
     * @dev Constructor function
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        string memory _baseURI
    ) public HasContractURI(contractURI) ERC721(_name, _symbol) {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
        _setBaseURI(_baseURI);
    }

    function checkSecondarySale(uint256 _tokenId) public view override returns (bool) {
        return isSecondarySale[_tokenId];
    }

    function setSecondarySale(uint256 _tokenId) public override {
        isSecondarySale[_tokenId] = true;
    }

    function _mint(
        address _to,
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) internal {
        require(_exists(_tokenId) == false, "ERC721: Token is already minted");
        require(bytes(_uri).length > 0, "ERC721: Uri should be set");

        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if(_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10**4,
                "ERC721: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10**4,
                "ERC721: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps,  RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        }else{
            revert("ERC721: Royalty option does not exist");
        }
        _addRoyaltyShares(_tokenId, _royaltyShares);
    }

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../libs/RoyaltyLibrary.sol";
import "../interfaces/IRoyalty.sol";
import "../interfaces/IPrimaryRoyalty.sol";
import "../interfaces/ICreator.sol";

abstract contract Royalty is Context, ERC165, IRoyalty, IPrimaryRoyalty, ICreator {
    event SetRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    event SetRoyalty (
        address owner,
        uint256 indexed tokenId,
        uint256 value,
        RoyaltyLibrary.Strategy strategy
    );

    event SetPrimaryRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    // tokenId => royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyInfo) public royalty;

    // tokenId => royaltyShares
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) public royaltyShares;

    // tokenId => creator address
    mapping(uint256 => address) creators;

    // tokenId => primary royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) primaryRoyaltyShares;

    // Max count of royalty shares
    uint256 maxRoyaltyShareCount = 100;

    /*
     * bytes4(keccak256('getRoyalty(uint256 _tokenId)')) == 0x71f1e123
     * bytes4(keccak256('getRoyaltyShares(uint256 _tokenId)')) == 0x8e9727ba
     * bytes4(keccak256('_setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy')) == 0x8bb6c361
     * bytes4(keccak256('_addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares)')) == 0xa0034d9f
     * bytes4(keccak256('royalty()')) == 0x29ee566c
     * bytes4(keccak256('royaltyShares()')) == 0x861475d2
     *
     * => 0x71f1e123 ^ 0x8e9727ba ^ 0x8bb6c361 ^ 0xa0034d9f ^ 0x29ee566c ^ 0x861475d2 == 0x7b296bd9
     */

    // IMPORTANT: This is version 1 of the royalty. Please do not delete for record.
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;

    // From IRoyalty
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    constructor() public {
        _registerInterface(_INTERFACE_ID_ROYALTY_V2);
        _registerInterface(type(IPrimaryRoyalty).interfaceId);
        _registerInterface(type(ICreator).interfaceId);
    }

    function getTokenContract() public view override returns (address) {
        return address(this);
    }

    function getRoyalty(uint256 _tokenId) public view override returns (RoyaltyLibrary.RoyaltyInfo memory) {
        return royalty[_tokenId];
    }

    function getRoyaltyShares(uint256 _tokenId) public view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return royaltyShares[_tokenId];
    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return primaryRoyaltyShares[_tokenId];
    }

    function getCreator(uint256 _tokenId) external view override returns (address) {
        return creators[_tokenId];
    }

    function _setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy) internal {
        require(
            _bps <= 10 ** 4,
            "Royalty: Total royalty bps should not exceed 10000"
        );
        royalty[_tokenId] = RoyaltyLibrary.RoyaltyInfo({
        value : _bps,
        strategy : _strategy
        });
        emit SetRoyalty(_msgSender(), _tokenId, _bps, _strategy);
    }

    function _addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Royalty share bps value should be positive");
            royaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetRoyaltyShares(_tokenId, recipients, bps);
        }
    }

    function _addPrimaryRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Primary royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Primary royalty share bps value should be positive");
            primaryRoyaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetPrimaryRoyaltyShares(_tokenId, recipients, bps);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/RoyaltyLibrary.sol";

interface IPrimaryRoyalty {

    /*
     * bytes4(keccak256('getPrimaryRoyaltyShares(uint256)')) == 0x20b029a5
     */

    //    bytes4 private constant _INTERFACE_ID_PRIMARY_ROYALTY = 0x20b029a5;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_PRIMARY_ROYALTY);
    //    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view returns (RoyaltyLibrary.RoyaltyShareDetails[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC721.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/introspection/ERC165.sol";

contract HasContractURI is ERC165 {

    string public contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory _contractURI) public {
        contractURI = _contractURI;
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    /**
     * @dev Internal function to set the contract URI
     * @param _contractURI string URI prefix to assign
     */
    function _setContractURI(string memory _contractURI) internal {
        contractURI = _contractURI;
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MinterRole is AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "Ownable: caller is not the signer");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "Ownable: caller is not the minter");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addSigner(address _account) public onlyAdmin {
        grantRole(SIGNER_ROLE, _account);
    }

    function removeSigner(address _account) public onlyAdmin {
        revokeRole(SIGNER_ROLE, _account);
    }

    function addMinterBatch(address[] memory _accounts) public onlyAdmin {
        for(uint256 i = 0; i< _accounts.length; i++) {
            _setupRole(MINTER_ROLE, _accounts[i]);
        }
    }

    function addMinter(address _account) public onlyAdmin {
        _setupRole(MINTER_ROLE, _account);
    }

    function removeMinter(address _account) public onlyAdmin {
        revokeRole(MINTER_ROLE, _account);
    }

    function addAdmin(address _account) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function removeAdmin(address _account) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE , _account);
    }

    function isSigner(address _account) internal virtual view returns(bool) {
        return hasRole(SIGNER_ROLE, _account);
    }

    function isMinter(address _account) internal virtual view returns(bool) {
        return hasRole(MINTER_ROLE, _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ICreator {
    /*
     * bytes4(keccak256('getCreator(uint256)')) == 0xd48e638a
     */

    //    bytes4 private constant _INTERFACE_ID_CREATOR = 0xd48e638a;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_CREATOR);
    //    }

    function getCreator(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../HasContractURI.sol";
import "./HasSecondarySaleFees.sol";
import "../HasSecondarySale.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721Base is
    HasSecondarySaleFees,
    HasSecondarySale,
    ERC721,
    HasContractURI
{
    // Token name
    // Now in openzeppelin ERC721
    // string public override name;

    // Token symbol
    // Now in openzeppelin ERC721
    // string public override symbol;

    using SafeMath for uint256;

    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // id => fees
    mapping(uint256 => Fee[]) public fees;

    /// @dev sale is primary or secondary
    mapping(uint256 => bool) public isSecondarySale;

    // Max count of fees
    uint256 maxFeesCount = 100;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        string memory _baseURI
    ) public HasContractURI(contractURI) ERC721(_name, _symbol) {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _setBaseURI(_baseURI);
    }

    function getFeeRecipients(uint256 id)
        public
        view
        override
        returns (address payable[] memory)
    {
        Fee[] memory _fees = fees[id];
        address payable[] memory result = new address payable[](_fees.length);
        for (uint256 i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].recipient;
        }
        return result;
    }

    function getFeeBps(uint256 id) public view override returns (uint256[] memory) {
        Fee[] memory _fees = fees[id];
        uint256[] memory result = new uint256[](_fees.length);
        for (uint256 i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].value;
        }
        return result;
    }

    function checkSecondarySale(uint256 id) public view override returns(bool) {
        return isSecondarySale[id];
    }

    function setSecondarySale(uint256 id) public override {
        isSecondarySale[id] = true;
    }

    function _mint(
        address to,
        uint256 tokenId,
        Fee[] memory _fees
    ) internal {
        require(
            _fees.length <= maxFeesCount,
            "Amount of fee recipients can't exceed 100"
        );

        uint256 sumFeeBps = 0;
        for (uint256 i = 0; i < _fees.length; i++) {
            sumFeeBps = sumFeeBps.add(_fees[i].value);
        }

        require(
            sumFeeBps <= 10000,
            "Total fee bps should not exceed 10000"
        );

        _mint(to, tokenId);
        address[] memory recipients = new address[](_fees.length);
        uint256[] memory bps = new uint256[](_fees.length);
        for (uint256 i = 0; i < _fees.length; i++) {
            require(
                _fees[i].recipient != address(0x0),
                "Recipient should be present"
            );
            require(_fees[i].value != 0, "Fee value should be positive");
            fees[tokenId].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        if (_fees.length > 0) {
            emit SecondarySaleFees(tokenId, recipients, bps);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721Base.sol";
import "../../roles/MinterRole.sol";
import "../../libs/Ownable.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.
 */
contract RefinableERC721WhiteListedToken is
IERC721,
IERC721Metadata,
ERC721Burnable,
ERC721Base,
MinterRole,
Ownable
{
    using ECDSA for bytes32;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721Base(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
        _registerInterface(bytes4(keccak256("MINT_WITH_ADDRESS")));
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        Fee[] memory _fees,
        string memory _tokenURI
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );
        _mint(msg.sender, _tokenId, _fees);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721Base.sol";
import "../../roles/SignerRole.sol";
import "../../libs/Ownable.sol";

/**
 * @title RefinableERC721Token
 * @dev anyone can mint token.
 */
contract RefinableERC721Token is
    IERC721,
    IERC721Metadata,
    ERC721Burnable,
    ERC721Base,
    SignerRole,
    Ownable
{
    using ECDSA for bytes32;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721Base(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
        _registerInterface(bytes4(keccak256("MINT_WITH_ADDRESS")));
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        Fee[] memory _fees,
        string memory _tokenURI
    ) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );
        _mint(msg.sender, _tokenId, _fees);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SignerRole is AccessControl {
    
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "Ownable: caller is not the signer");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addAdmin(address _accont) internal onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE , _accont);
    }

    function removeAdmin(address _accont) internal onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE , _accont);
    }

    function addSigner(address _account) public onlyAdmin {
        grantRole(SIGNER_ROLE, _account);
    }

    function removeSigner(address _account) public onlyAdmin {
        revokeRole(SIGNER_ROLE, _account);
    }

    function isSigner(address _account) public virtual view returns(bool) {
        return hasRole(SIGNER_ROLE, _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC1155Base.sol";
import "../../roles/SignerRole.sol";

contract RefinableERC1155Token is ERC1155Base, SignerRole {
    
    using ECDSA for bytes32;

    string public name;
    string public symbol;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(string memory _name, string memory _symbol, address _signer, string memory _contractURI, string memory _tokenURIPrefix, string memory _uri) ERC1155Base(_contractURI, _tokenURIPrefix, _uri) public {
        name = _name;
        symbol = _symbol;

        addAdmin(_msgSender());
        addSigner(_msgSender());
        addSigner(_signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    function mint(uint256 _tokenId, bytes memory _signature, Fee[] memory _fees, uint256 _supply, string memory _uri) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
                    .toEthSignedMessageHash()
                    .recover(_signature)
            )
            ,"invalid signature"
        );
        _mint(_tokenId, _fees, _supply, _uri);
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "./HasSecondarySaleFees.sol";
import "./ERC1155Metadata_URI.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../../libs/Ownable.sol";
import "../HasContractURI.sol";

abstract contract ERC1155Base is HasSecondarySaleFees, Ownable, ERC1155Metadata_URI, HasContractURI, ERC1155 {

    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // id => creator
    mapping (uint256 => address) public creators;
    // id => fees
    mapping (uint256 => Fee[]) public fees;

    // Max count of fees
    uint256 maxFeesCount = 100;

    constructor(string memory contractURI, string memory tokenURIPrefix, string memory uri) HasContractURI(contractURI) ERC1155Metadata_URI(tokenURIPrefix) ERC1155(uri) public {

    }

    function getFeeRecipients(uint256 id) public override view returns (address payable[] memory) {
        Fee[] memory _fees = fees[id];
        address payable[] memory result = new address payable[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].recipient;
        }
        return result;
    }

    function getFeeBps(uint256 id) public override view returns (uint[] memory) {
        Fee[] memory _fees = fees[id];
        uint[] memory result = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].value;
        }
        return result;
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(uint256 _id, Fee[] memory _fees, uint256 _supply, string memory _uri) internal {
        require(
            _fees.length <= maxFeesCount,
            "Amount of fee recipients can't exceed 100"
        );

        uint256 sumFeeBps = 0;
        for (uint256 i = 0; i < _fees.length; i++) {
            sumFeeBps = sumFeeBps.add(_fees[i].value);
        }

        require(
            sumFeeBps <= 10000,
            "Total fee bps should not exceed 10000"
        );

        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        creators[_id] = msg.sender;
        address[] memory recipients = new address[](_fees.length);
        uint[] memory bps = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "Recipient should be present");
            require(_fees[i].value != 0, "Fee value should be positive");
            fees[_id].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        if (_fees.length > 0) {
            emit SecondarySaleFees(_id, recipients, bps);
        }
        _mint(msg.sender, _id, _supply, "");
        //balanceOf(msg.sender, _id) = _supply;
        _setTokenURI(_id, _uri);

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _supply);
        emit URI(_uri, _id);
    }

    function burn(address _owner, uint256 _id, uint256 _value) external {

        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender) == true, "Need operator approval for 3rd party burns.");

        _burn(_owner, _id, _value);
        // SafeMath will throw with insuficient funds _owner
        // or if _id is not valid (balance will be 0)
        // balanceOf(_owner, _id) = balanceOf( _owner, _id).sub(_value);

        // MUST emit event
        // emit TransferSingle(msg.sender, _owner, address(0x0), _id, _value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) override virtual internal {
        require(creators[tokenId] != address(0x0), "_setTokenURI: Token should exist");
        super._setTokenURI(tokenId, uri);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    function uri(uint256 _id) override(ERC1155Metadata_URI, ERC1155) external view returns (string memory) {
        return _tokenURI(_id);
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "../HasContractURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "../HasTokenURI.sol";

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
abstract contract ERC1155Metadata_URI is IERC1155MetadataURI, HasTokenURI {

    constructor(string memory _tokenURIPrefix) HasTokenURI(_tokenURIPrefix) public {

    }

    function uri(uint256 _id) override virtual external view returns (string memory) {
        return _tokenURI(_id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
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
    function uri(uint256) external view virtual override returns (string memory) {
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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

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

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "../libs/StringLibrary.sol";

contract HasTokenURI {
    using StringLibrary for string;

    //Token URI prefix
    string public tokenURIPrefix;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _tokenURIPrefix) public {
        tokenURIPrefix = _tokenURIPrefix;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return tokenURIPrefix.append(_tokenURIs[tokenId]);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) virtual internal {
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param _tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function _clearTokenURI(uint256 tokenId) internal {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC1155Base.sol";
import "../../roles/MinterRole.sol";

contract RefinableERC1155WhiteListedToken is ERC1155Base, MinterRole {

    using ECDSA for bytes32;

    string public name;
    string public symbol;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(string memory _name, string memory _symbol, address _signer, string memory _contractURI, string memory _tokenURIPrefix, string memory _uri) ERC1155Base(_contractURI, _tokenURIPrefix, _uri) public {
        name = _name;
        symbol = _symbol;

        addSigner(_msgSender());
        addSigner(_signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    function mint(uint256 _tokenId, bytes memory _signature, Fee[] memory _fees, uint256 _supply, string memory _uri) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        ,"invalid signature"
        );
        _mint(_tokenId, _fees, _supply, _uri);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "../HasContractURI.sol";
import "../HasSecondarySale.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721BaseV3 is
HasSecondarySale,
HasContractURI,
ERC721Burnable,
MinterRole,
Royalty
{
    /// @dev sale is primary or secondary
    mapping(uint256 => bool) public isSecondarySale;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;


    /**
     * @dev Constructor function
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        string memory _baseURI
    ) public HasContractURI(contractURI) ERC721(_name, _symbol) {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
        _setBaseURI(_baseURI);
    }

    function checkSecondarySale(uint256 _tokenId) public view override returns (bool) {
        return isSecondarySale[_tokenId];
    }

    function setSecondarySale(uint256 _tokenId) public override {
        isSecondarySale[_tokenId] = true;
    }

    function _mint(
        address _to,
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) internal {
        require(_exists(_tokenId) == false, "ERC721: Token is already minted");
        require(bytes(_uri).length > 0, "ERC721: Uri should be set");

        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
        creators[_tokenId] = _to;
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if (_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "ERC721: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "ERC721: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps, RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY) {
            uint256 sumPrimaryRoyaltyShareBps;
            for (uint256 i = 0; i < _primaryRoyaltyShares.length; i++) {
                sumPrimaryRoyaltyShareBps = sumPrimaryRoyaltyShareBps + _primaryRoyaltyShares[i].value;
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            require(
                sumPrimaryRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total primary royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY);
            _addPrimaryRoyaltyShares(_tokenId, _primaryRoyaltyShares);
        } else {
            revert("ERC721: Royalty option does not exist");
        }
        _addRoyaltyShares(_tokenId, _royaltyShares);
    }

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC721BaseV3.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract WhiteListedTokenERC721V3 is ERC721BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV3(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function mintSimilarBatch(
        uint256[] memory _tokenIds,
        bytes[] memory _signatures,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string[] memory _uris,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {

        require(_tokenIds.length < 101, "You can only batch mint 100 tokens");

        for(uint i = 0; i < _tokenIds.length; i++) {
            mint(_tokenIds[i], _signatures[i], _royaltyShares, _uris[i], _royaltyBps, _royaltyStrategy, _primaryRoyaltyShares);
        }
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC1155BaseV3.sol";
import "../../../libs/RoyaltyLibrary.sol";

contract WhiteListedTokenERC1155V3 is ERC1155BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV3(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    //add the default royalties if the contract has set
    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });

        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC1155: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../HasContractURI.sol";
import "../HasTokenURI.sol";
import "./ERC1155Supply.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";
import "../../interfaces/ICreator.sol";
import "../../interfaces/IPrimaryRoyalty.sol";

abstract contract ERC1155BaseV3 is
HasTokenURI,
HasContractURI,
ERC1155Supply,
MinterRole,
Royalty
{
    string public name;
    string public symbol;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) HasContractURI(_contractURI) HasTokenURI(_tokenURIPrefix) ERC1155(_uri) public {
        name = _name;
        symbol = _symbol;
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) internal {
        require(exists(_tokenId) == false, "ERC1155: Token is already minted");
        require(_supply != 0, "ERC1155: Supply should be positive");
        require(bytes(_uri).length > 0, "ERC1155: Uri should be set");

        _mint(_msgSender(), _tokenId, _supply, "");
        _setTokenURI(_tokenId, _uri);
        creators[_tokenId] = _msgSender();
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if (_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "ERC1155: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "ERC1155: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps, RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY) {
            uint256 sumPrimaryRoyaltyShareBps;
            for (uint256 i = 0; i < _primaryRoyaltyShares.length; i++) {
                sumPrimaryRoyaltyShareBps = sumPrimaryRoyaltyShareBps + _primaryRoyaltyShares[i].value;
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            require(
                sumPrimaryRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total primary royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY);
            _addPrimaryRoyaltyShares(_tokenId, _primaryRoyaltyShares);
        } else {
            revert("ERC1155: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);

        // Transfer event with mint semantic
        emit URI(_uri, _tokenId);
    }


    function burn(address _owner, uint256 _tokenId, uint256 _value) external {
        _burn(_owner, _tokenId, _value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(exists(_tokenId), "ERC1155: Token should exist");
        super._setTokenURI(_tokenId, _uri);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyAdmin {
        _setTokenURIPrefix(_tokenURIPrefix);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }

    function uri(uint256 _tokenId) override external view returns (string memory) {
        return _tokenURI(_tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Supply: caller is not owner nor approved"
        );
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Supply: caller is not owner nor approved"
        );
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC1155BaseV3.sol";
import "../../../libs/RoyaltyLibrary.sol";

contract IMXHKERC1155WhiteListedTokenV3 is ERC1155BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV3(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    //add the default royalties if the contract has set
    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });

        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC1155: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC1155BaseV3.sol";

contract RefinableERC1155WhiteListedTokenV3 is ERC1155BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV3(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory customPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0) {
            customPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        } else {
            customPrimaryRoyaltyShares = _primaryRoyaltyShares;
        } 

        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, _royaltyStrategy, customPrimaryRoyaltyShares);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC1155: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC1155BaseV3.sol";
import "../../../libs/RoyaltyLibrary.sol";

contract DAFERC1155WhiteListedTokenV3 is ERC1155BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV3(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    //add the default royalties if the contract has set
    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });

        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC1155: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC1155BaseV3.sol";
import "../../../libs/RoyaltyLibrary.sol";

contract CoralERC1155WhiteListedTokenV3 is ERC1155BaseV3 {
    using ECDSA for bytes32;

    RoyaltyLibrary.RoyaltyShareDetails[] public defaultPrimaryRoyaltyReceivers;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV3(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    //add the default royalties if the contract has set
    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );

        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyReceivers);
    }

    function setPrimaryDefaultRoyaltyReceivers(RoyaltyLibrary.RoyaltyShareDetails[] memory _receivers) public onlyAdmin {
        delete defaultPrimaryRoyaltyReceivers;
        for (uint256 i = 0; i < _receivers.length; i++) {
            defaultPrimaryRoyaltyReceivers.push(_receivers[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../../interfaces/IRoyalty.sol";
import "../../interfaces/IHasSecondarySale.sol";
import "../../libs/RoyaltyLibrary.sol";
import "./RanERC721Mock.sol";
import "../../interfaces/ICreator.sol";
import "../../interfaces/IPrimaryRoyalty.sol";


contract RoyaltyERC721Mock is Context, IRoyalty, IHasSecondarySale, ERC165, ICreator, IPrimaryRoyalty {
    event SetRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    event SetRoyalty (
        address owner,
        uint256 indexed tokenId,
        uint256 value,
        RoyaltyLibrary.Strategy strategy
    );

    event SetPrimaryRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    // tokenId => royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyInfo) royalty;

    // tokenId => royaltyShares
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) royaltyShares;

    // tokenId => bool: true is first sale, false is secondary sale
    mapping(uint256 => bool) isSecondarySale;

    // ERC721/1155 Address
    address tokenContract;

    // Max count of royalty shares
    uint256 maxRoyaltyShareCount;

    // tokenId => creator address
    mapping(uint256 => address) creators;

    // tokenId => primary royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) primaryRoyaltyShares;

    constructor (address _tokenContract, uint256 _maxRoyaltyShareCount) public {
        tokenContract = _tokenContract;
        maxRoyaltyShareCount = _maxRoyaltyShareCount;

        _registerInterface(type(IRoyalty).interfaceId);
        _registerInterface(type(IHasSecondarySale).interfaceId);
        _registerInterface(type(IPrimaryRoyalty).interfaceId);
        _registerInterface(type(ICreator).interfaceId);
    }

    function getTokenContract() external view override returns (address) {
        return tokenContract;
    }

    //    // Optional
    //    function setTokenContract(address token);

    function getRoyalty(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyInfo memory) {
        return royalty[_tokenId];
    }

    function getRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return royaltyShares[_tokenId];
    }

    function checkSecondarySale(uint256 _tokenId) public view override returns (bool) {
        return isSecondarySale[_tokenId];
    }

    function setSecondarySale(uint256 _tokenId) public override {
        isSecondarySale[_tokenId] = true;
    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return primaryRoyaltyShares[_tokenId];
    }

    function getCreator(uint256 _tokenId) external view override returns (address) {
        return creators[_tokenId];
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        string memory _uri,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public {
        RanERC721Mock(tokenContract).mint(_msgSender(), _tokenId);
        _addRoyalties(_tokenId, _royaltyShares, _royaltyBps, _royaltyStrategy, _primaryRoyaltyShares);
        creators[_tokenId] = _msgSender();
    }

    // Optional to make it public or not
    function _addRoyalties(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) internal {
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps + _royaltyShares[i].value;
        }

        if (_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "Royalty: Total royalty share bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps, RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY) {
            uint256 sumPrimaryRoyaltyShareBps;
            for (uint256 i = 0; i < _primaryRoyaltyShares.length; i++) {
                sumPrimaryRoyaltyShareBps = sumPrimaryRoyaltyShareBps + _primaryRoyaltyShares[i].value;
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            require(
                sumPrimaryRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total primary royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY);
            _addPrimaryRoyaltyShares(_tokenId, _primaryRoyaltyShares);
        } else {
            revert("Royalty: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);
    }

    function _setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy) internal {
        require(
            _bps <= 10 ** 4,
            "Royalty: Total royalty bps should not exceed 10000"
        );
        royalty[_tokenId] = RoyaltyLibrary.RoyaltyInfo({
        value : _bps,
        strategy : _strategy
        });
        emit SetRoyalty(_msgSender(), _tokenId, _bps, _strategy);
    }

    function _addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Royalty share bps value should be positive");
            royaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetRoyaltyShares(_tokenId, recipients, bps);
        }
    }

    function _addPrimaryRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Primary royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Primary royalty share bps value should be positive");
            primaryRoyaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetPrimaryRoyaltyShares(_tokenId, recipients, bps);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RanERC721Mock is ERC721 {
    constructor (string memory name, string memory symbol) ERC721 (name, symbol) public {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../../interfaces/IRoyalty.sol";
import "../../libs/RoyaltyLibrary.sol";
import "./RanERC1155Mock.sol";
import "../../interfaces/ICreator.sol";
import "../../interfaces/IPrimaryRoyalty.sol";


contract RoyaltyERC1155Mock is Context, IRoyalty, ERC165, ICreator, IPrimaryRoyalty {
    event SetRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    event SetRoyalty (
        address owner,
        uint256 indexed tokenId,
        uint256 value,
        RoyaltyLibrary.Strategy strategy
    );

    event SetPrimaryRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    // tokenId => royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyInfo) royalty;

    // tokenId => royaltyShares
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) royaltyShares;

    // tokenId => bool: true is first sale, false is secondary sale
    mapping(uint256 => bool) isSecondarySale;

    // ERC721/1155 Address
    address tokenContract;

    // Max count of royalty shares
    uint256 maxRoyaltyShareCount;

    // tokenId => creator address
    mapping(uint256 => address) creators;

    // tokenId => primary royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) primaryRoyaltyShares;

    constructor (address _tokenContract, uint256 _maxRoyaltyShareCount) public {
        tokenContract = _tokenContract;
        maxRoyaltyShareCount = _maxRoyaltyShareCount;

        _registerInterface(type(IRoyalty).interfaceId);
        _registerInterface(type(IPrimaryRoyalty).interfaceId);
        _registerInterface(type(ICreator).interfaceId);
    }

    function getTokenContract() external view override returns (address) {
        return tokenContract;
    }

    //    // Optional
    //    function setTokenContract(address token);

    function getRoyalty(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyInfo memory) {
        return royalty[_tokenId];
    }

    function getRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return royaltyShares[_tokenId];
    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return primaryRoyaltyShares[_tokenId];
    }

    function getCreator(uint256 _tokenId) external view override returns (address) {
        return creators[_tokenId];
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        uint256 _supply,
        string memory _uri,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public {
        RanERC1155Mock(tokenContract).mint(_msgSender(), _tokenId, _supply);
        _addRoyalties(_tokenId, _royaltyShares, _royaltyBps, _royaltyStrategy, _primaryRoyaltyShares);
        creators[_tokenId] = _msgSender();
    }

    // Optional to make it public or not
    function _addRoyalties(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) internal {
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps + _royaltyShares[i].value;
        }

        if (_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "Royalty: Total royalty share bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps, RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY) {
            uint256 sumPrimaryRoyaltyShareBps;
            for (uint256 i = 0; i < _primaryRoyaltyShares.length; i++) {
                sumPrimaryRoyaltyShareBps = sumPrimaryRoyaltyShareBps + _primaryRoyaltyShares[i].value;
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            require(
                sumPrimaryRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total primary royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY);
            _addPrimaryRoyaltyShares(_tokenId, _primaryRoyaltyShares);
        } else {
            revert("Royalty: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);
    }

    function _setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy) internal {
        require(
            _bps <= 10 ** 4,
            "Royalty: Total royalty bps should not exceed 10000"
        );
        royalty[_tokenId] = RoyaltyLibrary.RoyaltyInfo({
        value : _bps,
        strategy : _strategy
        });
        emit SetRoyalty(_msgSender(), _tokenId, _bps, _strategy);
    }

    function _addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Royalty share bps value should be positive");
            royaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetRoyaltyShares(_tokenId, recipients, bps);
        }
    }

    function _addPrimaryRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Primary royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Primary royalty share bps value should be positive");
            primaryRoyaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetPrimaryRoyaltyShares(_tokenId, recipients, bps);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RanERC1155Mock is ERC1155 {
    constructor (string memory uri) ERC1155 (uri) public {}

    function mint(address account, uint256 id, uint256 amount) public {
        _mint(account, id, amount, '');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Supply: caller is not owner nor approved"
        );
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Supply: caller is not owner nor approved"
        );
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../HasContractURI.sol";
import "../HasTokenURI.sol";
import "./ERC1155Supply.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";

abstract contract ERC1155BaseV2 is
HasTokenURI,
HasContractURI,
ERC1155Supply,
MinterRole,
Royalty
{
    string public name;
    string public symbol;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) HasContractURI(_contractURI) HasTokenURI(_tokenURIPrefix) ERC1155(_uri) public {
        name = _name;
        symbol = _symbol;
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) internal {
        require(exists(_tokenId) == false, "ERC1155: Token is already minted");
        require(_supply != 0, "ERC1155: Supply should be positive");
        require(bytes(_uri).length > 0, "ERC1155: Uri should be set");

        _mint(msg.sender, _tokenId, _supply, "");
        _setTokenURI(_tokenId, _uri);
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if(_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10**4,
                "ERC1155: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10**4,
                "ERC1155: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps,  RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        }else{
            revert("ERC1155: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);

        // Transfer event with mint semantic
        emit URI(_uri, _tokenId);
    }

    function burn(address _owner, uint256 _tokenId, uint256 _value) external {
        _burn(_owner, _tokenId, _value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(exists(_tokenId), "ERC1155: Token should exist");
        super._setTokenURI(_tokenId, _uri);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyAdmin {
        _setTokenURIPrefix(_tokenURIPrefix);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }

    function uri(uint256 _tokenId) override external view returns (string memory) {
        return _tokenURI(_tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC1155BaseV2.sol";

contract RefinableERC1155WhiteListedTokenV2 is ERC1155BaseV2 {

    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV2(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    //add the default royalties if the contract has set
    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) public onlyMinter {
        require(
            hasRole(SIGNER_ROLE,
            keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
            .toEthSignedMessageHash()
            .recover(_signature)
            )
        , "invalid signature"
        );
        RoyaltyLibrary.RoyaltyShareDetails[] memory newRoyaltyShares;
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0) {
            newRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](_royaltyShares.length + 1);
            for (uint256 i = 0; i < _royaltyShares.length; i++) {
                newRoyaltyShares[i] = _royaltyShares[i];
            }
            newRoyaltyShares[_royaltyShares.length] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        } else {
            newRoyaltyShares = _royaltyShares;
        }

        _mint(_tokenId, newRoyaltyShares, _supply, _uri, _royaltyBps, _royaltyStrategy);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10**4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC1155BaseV2.sol";

contract RefinableERC1155TokenV2 is ERC1155BaseV2 {
    using ECDSA for bytes32;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _tokenURIPrefix token URI Prefix
     * @param _uri ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) ERC1155BaseV2(_name, _symbol, _contractURI, _tokenURIPrefix, _uri) public {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, _msgSender()))
                .toEthSignedMessageHash()
                .recover(_signature)
            )
        , "invalid signature"
        );
        _mint(_tokenId, _royaltyShares, _supply, _uri, _royaltyBps, _royaltyStrategy);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC1155SaleNonceHolder.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../tge/interfaces/IBEP20.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../libs/RoyaltyLibrary.sol";
import "../service_fee/RoyaltiesStrategy.sol";
import "../interfaces/ICreator.sol";

import "./VipPrivatePublicSaleInfo.sol";

contract ERC1155Sale is ReentrancyGuard, RoyaltiesStrategy, VipPrivatePublicSaleInfo {
  using ECDSA for bytes32;
    using RoyaltyLibrary for RoyaltyLibrary.Strategy;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce
    );
    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        uint256 price,
        address buyer,
        uint256 value
    );    

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    address public transferProxy;
    address public serviceFeeProxy;
    address public nonceHolder;
    address public tradeTokenManager;

    constructor(
        address _transferProxy,
        address _nonceHolder,
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
    }

    function buy(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _selling,
        uint256 _buying,
        bytes memory _signature
    ) public payable nonReentrant {

        bytes32 saleId = getID(_owner, _token, _tokenId);

        // clean up saleInfo
        if(!whitelistNeeded(saleId) && saleInfo[saleId].vipSaleDate >= 0) {
            delete saleInfo[saleId];
        }

        require(
            IERC1155(_token).supportsInterface(_INTERFACE_ID_ERC1155),
            "ERC1155Sale: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC1155(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "ERC1155Sale: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "ERC1155Sale: Royalty Token address does not match buy token"
            );
        }

        require(whitelisted(saleId, msg.sender), "You should be whitelisted and sale should have started");

        require(
            IERC1155(_token).balanceOf(_owner, _tokenId) >= _buying,
            "ERC1155Sale: Owner doesn't enough tokens"
        );

        uint256 receiveAmount;
        if (_payToken == address(0)) {
            receiveAmount = msg.value;
        } else {
            require(TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true, "ERC721Sale: Pay Token is not allowed");
            receiveAmount = IBEP20(_payToken).allowance(msg.sender, address(this));
        }

        uint256 price = receiveAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(msg.sender).add(10 ** 4)).div(_buying);

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _payToken,
            _owner,
            _selling,
            price,
            _signature
        );
        verifyOpenAndModifyState(
            _token,
            _tokenId,
            _owner,
            nonce,
            _selling,
            _buying
        );

        TransferProxy(transferProxy).erc1155safeTransferFrom(
            _token,
            _owner,
            msg.sender,
            _tokenId,
            _buying,
            EMPTY
        );

        if (_royaltyToken != address(0)) {
            _distributeProfit(_royaltyToken, _tokenId, _payToken, _owner, price.mul(_buying), receiveAmount);
        } else {
            _distributeProfit(_token, _tokenId, _payToken, _owner, price.mul(_buying), receiveAmount);
        }
        emit Buy(_token, _tokenId, _owner, _payToken, price, msg.sender, _buying);
    }

    function _distributeProfit(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _totalPrice,
        uint256 _receiveAmount
    ) internal {
        bool isSecondarySale = _checkSecondarySale(_token, _tokenId, _owner);
        uint256 sellerServiceFeeBps = ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(_owner, isSecondarySale);
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        uint256 sellerServiceFee = _totalPrice.mul(sellerServiceFeeBps).div(10 ** 4);
        /*
           * The sellerReceiveAmount is on sale price minus seller service fee minus buyer service fee
           * This make sures we have enough balance even the royalties is 100%
        */
        uint256 sellerReceiveAmount = _totalPrice.sub(sellerServiceFee);
        uint256 royalties;
        if (
            IERC165(_token).supportsInterface(_INTERFACE_ID_FEES)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        )
            royalties = _payOutRoyaltiesByStrategy(_token, _tokenId, _payToken, _msgSender(), sellerReceiveAmount, isSecondarySale);

        sellerReceiveAmount = sellerReceiveAmount.sub(royalties);
        if (_payToken == address(0)) {
            _owner.transfer(sellerReceiveAmount);
            serviceFeeRecipient.transfer(sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        } else {
            IBEP20(_payToken).transferFrom(_msgSender(), _owner, sellerReceiveAmount);
            IBEP20(_payToken).transferFrom(_msgSender(), serviceFeeRecipient, sellerServiceFee.add(_receiveAmount.sub(_totalPrice)));
        }
    }

    function _checkSecondarySale(address _token, uint256 _tokenId, address _seller) internal returns (bool){
        if (IERC165(_token).supportsInterface(type(ICreator).interfaceId)) {
            address creator = ICreator(_token).getCreator(_tokenId);
            return (creator != _seller);
        } else {
            return true;
        }
    }

    function cancel(address token, uint256 tokenId) public {
        uint256 nonce = ERC1155SaleNonceHolder(nonceHolder).getNonce(token, tokenId, msg.sender);
        ERC1155SaleNonceHolder(nonceHolder).setNonce(token, tokenId, msg.sender, nonce.add(1));

        emit CloseOrder(token, tokenId, msg.sender, nonce.add(1));
    }

    function verifySignature(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address payable _owner,
        uint256 _selling,
        uint256 _price,
        bytes memory _signature
    ) internal view returns (uint256 nonce) {
        nonce = ERC1155SaleNonceHolder(nonceHolder).getNonce(_token, _tokenId, _owner);
        address owner;

        if (_payToken == address(0)) {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _price, _selling, nonce))
            .toEthSignedMessageHash()
            .recover(_signature);
        } else {
            owner = keccak256(abi.encodePacked(_token, _tokenId, _payToken, _price, _selling, nonce))
            .toEthSignedMessageHash()
            .recover(_signature);
        }

        require(
            owner == _owner,
            "ERC1155Sale: Incorrect signature"
        );
    }

    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        address payable _owner,
        uint256 _nonce,
        uint256 _selling,
        uint256 _buying
    ) internal {
        uint256 comp = ERC1155SaleNonceHolder(nonceHolder)
        .getCompleted(_token, _tokenId, _owner, _nonce)
        .add(_buying);
        require(comp <= _selling);
        ERC1155SaleNonceHolder(nonceHolder).setCompleted(_token, _tokenId, _owner, _nonce, comp);

        if (comp == _selling) {
            ERC1155SaleNonceHolder(nonceHolder).setNonce(_token, _tokenId, _owner, _nonce.add(1));
            emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../roles/OperatorRole.sol";

contract ERC1155SaleNonceHolder is OperatorRole {
    // keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    // keccak256(token, owner, tokenId, nonce) => completed amount
    mapping(bytes32 => uint256) public completed;

    function getNonce(
        address token,
        uint256 tokenId,
        address owner
    ) public view returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    function setNonce(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public onlyOperator {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    function getNonceKey(
        address token,
        uint256 tokenId,
        address owner
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }

    function getCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public view returns (uint256) {
        return completed[getCompletedKey(token, tokenId, owner, nonce)];
    }

    function setCompleted(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce,
        uint256 _completed
    ) public onlyOperator {
        completed[getCompletedKey(token, tokenId, owner, nonce)] = _completed;
    }

    function getCompletedKey(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner, nonce));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../tge/interfaces/IBEP20.sol";
import "../tokens/HasSecondarySale.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../roles/AdminRole.sol";
import "../libs/BidLibrary.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../service_fee/RoyaltiesStrategy.sol";

/**
 * @notice Primary sale auction contract for Refinable NFTs
 */
contract ERC721Auction is Context, ReentrancyGuard, AdminRole, RoyaltiesStrategy {
    using SafeMath for uint256;
    using Address for address payable;
    using BidLibrary for BidLibrary.Bid[];

    /// @notice Event emitted only on construction. To be used by indexers
    event AuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event Destroy();

    event AuctionCreated(bytes32 auctionId, address token, uint256 indexed tokenId, address payToken);

    event AuctionCreateTimeLimitUpdated(uint256 auctionCreateTimeLimit);

    event AuctionStartTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, uint256 startTime);

    event AuctionEndTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, uint256 endTime);

    event MinBidIncrementBpsUpdated(uint256 minBidIncrementBps);

    event MaxBidStackCountUpdated(uint256 maxBidStackCount);

    event BidWithdrawalLockTimeUpdated(uint256 bidWithdrawalLockTime);

    event BidPlaced(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed bidder,
        uint256 bidAmount,
        uint256 actualBidAmount
    );

    event BidWithdrawn(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed bidder,
        uint256 bidAmount
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bidAmount,
        address payToken
    );

    event AuctionResulted(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address payToken,
        address indexed winner,
        uint256 winningBidAmount
    );

    event AuctionCancelled(bytes32 auctionId, address token, uint256 indexed tokenId);

    /// @notice Parameters of an auction
    struct Auction {
        address token;
        address royaltyToken;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        bool created;
    }

    address public serviceFeeProxy;

    address public tradeTokenManager;

    /// @notice ERC721 Auction ID -> Auction Parameters
    mapping(bytes32 => Auction) public auctions;

    /// @notice ERC721 Auction ID -> Bid Parameters
    mapping(bytes32 => BidLibrary.Bid[]) public bids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrementBps = 250;

    //@notice global auction create time limit
    uint256 public auctionCreateTimeLimit = 30 days;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 3 days;

    /// @notice global limit time betwen bid time and auction end time
    uint256 public bidLimitBeforeEndTime = 5 minutes;

    /// @notice max bidders stack count
    uint256 public maxBidStackCount = 1;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    modifier whenNotPaused() {
        require(!isPaused, "Auction: Function is currently paused");
        _;
    }

    modifier onlyCreatedAuction(bytes32 _auctionId) {
        require(
            auctions[_auctionId].created == true,
            "Auction: Auction does not exist"
        );
        _;
    }

    /**
     * @notice Auction Constructor
    * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AuctionContractDeployed();
    }

    /**
     * @notice Creates a new auction for a given token
     * @dev Only the owner of a token can create an auction and must have approved the contract
     * @dev End time for the auction must be in the future.
     * @param _token Token Address that follows ERC721 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _startPrice Starting bid price of the token being auctioned
     * @param _startTimestamp Unix epoch in seconds for the auction start time
     * @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        uint256 _startPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external whenNotPaused {
        require(
            _startTimestamp <= _getNow().add(auctionCreateTimeLimit),
            "Auction: Exceed auction start time limit"
        );
        require(
            IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721),
            "Auction: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC721(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "Auction: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "Auction: Royalty Token address does not match buy token"
            );
        }

        // Check owner of the token is the creator and approved
        require(
            IERC721(_token).ownerOf(_tokenId) == msg.sender,
            "Auction: Caller is not the owner"
        );
        require(
            IERC721(_token).isApprovedForAll(msg.sender, address(this)),
            "Auction: Owner has not approved"
        );

        if (_payToken != address(0)) {
            require(
                TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true,
                "Auction: Pay Token is not allowed"
            );
        }

        bytes32 auctionId = getAuctionId(_token, _tokenId, msg.sender);

        // Check the auction already created, can only list 1 token at a time
        require(
            auctions[auctionId].created == false,
            "Auction: Auction has been already created"
        );
        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp > _startTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        // Setup the auction
        auctions[auctionId] = Auction({
        token : _token,
        royaltyToken : _royaltyToken,
        tokenId : _tokenId,
        owner : msg.sender,
        payToken : _payToken,
        startPrice : _startPrice,
        startTime : _startTimestamp,
        endTime : _endTimestamp,
        created : true
        });

        emit AuctionCreated(auctionId, _token, _tokenId, _payToken);
    }

    /**
     * @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     * @dev Only callable when the auction is open
     * @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function placeBid(bytes32 _auctionId)
    external
    payable
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        require(
            msg.sender.isContract() == false,
            "Auction: No contracts permitted"
        );

        // Ensure auction is in flight
        require(
            _getNow() >= auctions[_auctionId].startTime && _getNow() <= auctions[_auctionId].endTime,
            "Auction: Bidding outside of the auction window"
        );

        uint256 bidAmount;

        if (auctions[_auctionId].payToken == address(0)) {
            bidAmount = msg.value;
        } else {
            bidAmount = IBEP20(auctions[_auctionId].payToken).allowance(msg.sender, address(this));
            require(
                IBEP20(auctions[_auctionId].payToken).transferFrom(msg.sender, address(this), bidAmount) == true,
                "Auction: Token transfer failed"
            );
        }

        // Ensure bid adheres to outbid increment and threshold
        uint256 actualBidAmount = bidAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(msg.sender).add(10 ** 4));
        uint256 minBidRequired;
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length != 0) {
            minBidRequired =
            bidList[bidList.length - 1].actualBidAmount.mul(minBidIncrementBps.add(10 ** 4)).div(10 ** 4);
        } else {
            minBidRequired = auctions[_auctionId].startPrice;
        }

        require(
            actualBidAmount >= minBidRequired,
            "Auction: Failed to outbid min price"
        );

        // assign top bidder and bid time
        BidLibrary.Bid memory newHighestBid = BidLibrary.Bid({
        bidder : _msgSender(),
        bidAmount : bidAmount,
        actualBidAmount : actualBidAmount,
        bidTime : _getNow()
        });

        bidList.push(newHighestBid);

        //Refund old bid if bidlist overflows thans max bid stack count
        if (bidList.length > maxBidStackCount) {
            BidLibrary.Bid memory oldBid = bidList[0];
            if (oldBid.bidder != address(0)) {
                _refundBid(oldBid.bidder, oldBid.bidAmount, auctions[_auctionId].payToken);
            }

            bidList.removeByIndex(0);
        }

        //Increase auction end time if bid time is more than 5 mins before end time
        if (auctions[_auctionId].endTime <= newHighestBid.bidTime.add(bidLimitBeforeEndTime)) {
            _updateAuctionEndTime(_auctionId, auctions[_auctionId].endTime.add(bidLimitBeforeEndTime));
        }

        emit BidPlaced(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].payToken,
            _msgSender(),
            bidAmount,
            actualBidAmount
        );
    }

    /**
     * @notice Given a sender who is in the bid list of auction, allows them to withdraw their bid
     * @dev Only callable by the existing top bidder
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function withdrawBid(bytes32 _auctionId)
    external
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        BidLibrary.Bid[] storage bidList = bids[_auctionId];
        require(bidList.length > 0, "Auction: There is no bid");

        uint256 withdrawIndex = bidList.length;
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == _msgSender()) {
                withdrawIndex = i;
            }
        }

        require(withdrawIndex != bidList.length, "Auction: Caller is not bidder");

        BidLibrary.Bid storage withdrawableBid = bidList[withdrawIndex];

        // Check withdrawal after delay time
        require(
            _getNow() >= auctions[_auctionId].endTime.add(bidWithdrawalLockTime),
            "Auction: Cannot withdraw until auction ends"
        );

        if (withdrawableBid.bidder != address(0)) {
            _refundBid(withdrawableBid.bidder, withdrawableBid.bidAmount, auctions[_auctionId].payToken);
        }

        bidList.removeByIndex(withdrawIndex);

        emit BidWithdrawn(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].payToken,
            _msgSender(),
            withdrawableBid.bidAmount
        );
    }

    /**
     * @notice Results a finished auction
     * @dev Only admin or smart contract
     * @dev Auction can only be resulted if there has been a bidder and reserve met.
     * @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function endAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // Check the auction has ended
        require(
            _getNow() > auction.endTime,
            "Auction: Auction has not ended"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC721(auction.token).isApprovedForAll(auction.owner, address(this)),
            "Auction: Auction not approved"
        );

        // Get info on who the highest bidder is
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        require(bidList.length > 0, "Auction: There is no bid");

        BidLibrary.Bid memory highestBid = bidList[bidList.length - 1];

        bool isSecondarySale;
        if (IERC165(auction.token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            isSecondarySale = HasSecondarySale(auction.token).checkSecondarySale(auction.tokenId);
        } else if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2)) {
            isSecondarySale = HasSecondarySale(auction.royaltyToken).checkSecondarySale(auction.tokenId);
        }
        // Work out platform fee from above reserve amount
        uint256 totalServiceFee = highestBid.bidAmount.sub(highestBid.actualBidAmount).add(
            highestBid.actualBidAmount.mul(
                ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(auction.owner, isSecondarySale)
            ).div(10 ** 4)
        );

        // Send platform fee
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        bool platformTransferSuccess;
        bool ownerTransferSuccess;
        uint256 royalties;
        if (
            IERC165(auction.token).supportsInterface(_INTERFACE_ID_FEES)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        ) {
            royalties = _payOutRoyaltiesByStrategy(
                auction.token,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        } else if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2)) {
            require(
                IRoyalty(auction.royaltyToken).getTokenContract() == auction.token,
                "Auction: Royalty Token address does not match buy token"
            );
            royalties = _payOutRoyaltiesByStrategy(
                auction.royaltyToken,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        }
        uint256 remain = highestBid.bidAmount.sub(totalServiceFee).sub(royalties);
        if (auction.payToken == address(0)) {
            (platformTransferSuccess,) =
            serviceFeeRecipient.call{value : totalServiceFee}("");
            // Send remaining to designer
            if (remain > 0) {
                (ownerTransferSuccess,) =
                auction.owner.call{
                value : remain
                }("");
            }
        } else {
            platformTransferSuccess = IBEP20(auction.payToken).transfer(serviceFeeRecipient, totalServiceFee);
            if (remain > 0) {
                ownerTransferSuccess = IBEP20(auction.payToken).transfer(auction.owner, remain);
            }
        }

        require(
            platformTransferSuccess,
            "Auction: Failed to send fee"
        );
        if (remain > 0) {
            require(
                ownerTransferSuccess,
                "Auction: Failed to send winning bid"
            );
        }
        // Transfer the token to the winner
        IERC721(auction.token).safeTransferFrom(auction.owner, highestBid.bidder, auction.tokenId);

        if (IERC165(auction.token).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE))
            HasSecondarySale(auction.token).setSecondarySale(auction.tokenId);

        if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE))
            HasSecondarySale(auction.royaltyToken).setSecondarySale(auction.tokenId);

        // Refund bid amount to bidders who isn't the top unfortunately
        for (uint256 i = 0; i < bidList.length - 1; i++) {
            _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
        }

        // Clean up the highest bid
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionResulted(
            _auctionId,
            auction.token,
            auction.tokenId,
            auction.payToken,
            highestBid.bidder,
            highestBid.bidAmount
        );
    }

    /**
     * @notice Cancels and inflight and un-resulted auctions, returning the funds to bidders if found
     * @dev Only admin
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function cancelAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // refund bid amount to existing bidders
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length > 0) {
            for (uint256 i = 0; i < bidList.length; i++) {
                _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
            }
        }

        // Remove auction and bids
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionCancelled(_auctionId, auction.token, auction.tokenId);
    }

    /**
     * @notice Update the auction create time limit by which how far ahead can auctions be created
     * @dev Only admin
     * @param _auctionCreateTimeLimit New auction create time limit
     */
    function updateAuctionCreateTimeLimit(uint256 _auctionCreateTimeLimit)
    external
    onlyAdmin
    {
        auctionCreateTimeLimit = _auctionCreateTimeLimit;
        emit AuctionCreateTimeLimitUpdated(_auctionCreateTimeLimit);
    }

    /**
     * @notice Update the amount by which bids have to increase, across all auctions
     * @dev Only admin
     * @param _minBidIncrementBps New bid step in WEI
     */
    function updateMinBidIncrementBps(uint256 _minBidIncrementBps)
    external
    onlyAdmin
    {
        minBidIncrementBps = _minBidIncrementBps;
        emit MinBidIncrementBpsUpdated(_minBidIncrementBps);
    }

    /**
     * @notice Update the global max bid stack count
     * @dev Only admin
     * @param _maxBidStackCount max bid stack count
     */
    function updateMaxBidStackCount(uint256 _maxBidStackCount)
    external
    onlyAdmin
    {
        maxBidStackCount = _maxBidStackCount;
        emit MaxBidStackCountUpdated(_maxBidStackCount);
    }

    /**
     * @notice Update the global bid withdrawal lockout time
     * @dev Only admin
     * @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
    external
    onlyAdmin
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit BidWithdrawalLockTimeUpdated(_bidWithdrawalLockTime);
    }

    /**
     * @notice Update the current start time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(bytes32 _auctionId, uint256 _startTime)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        auctions[_auctionId].startTime = _startTime;
        emit AuctionStartTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, _startTime);
    }

    /**
     * @notice Update the current end time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp New end time (unix epoch in seconds)
     */
    function updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        require(
            auctions[_auctionId].startTime < _endTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        _updateAuctionEndTime(_auctionId, _endTimestamp);
    }

    /**
     * @notice Method for getting all info about the auction
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getAuction(bytes32 _auctionId)
    external
    view
    returns (Auction memory)
    {
        return auctions[_auctionId];
    }

    /**
     * @notice Method for getting all info about the bids
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getBidList(bytes32 _auctionId) public view returns (BidLibrary.Bid[] memory) {
        return bids[_auctionId];
    }

    /**
     * @notice Method for getting auction id to query the auctions mapping
     * @param _token Token Address that follows ERC1155 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _owner Owner address of the token Id
    */
    function getAuctionId(address _token, uint256 _tokenId, address _owner) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_token, _tokenId, _owner));
    }

    /**
     * @notice Method for the block timestamp
    */
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Used for sending back escrowed funds from a previous bid
     * @param _bidder Address of the last highest bidder
     * @param _bidAmount Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundBid(address payable _bidder, uint256 _bidAmount, address _payToken) private {
        // refund previous best (if bid exists)
        bool successRefund;
        if (_payToken == address(0)) {
            (successRefund,) = _bidder.call{value : _bidAmount}("");
        } else {
            successRefund = IBEP20(_payToken).transfer(_bidder, _bidAmount);
        }
        require(
            successRefund,
            "Auction: Failed to refund"
        );
        emit BidRefunded(_bidder, _bidAmount, _payToken);
    }

    /**
     * @notice Private method used for update auction end time
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp timestamp of end time
     */
    function _updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp) private {
        auctions[_auctionId].endTime = _endTimestamp;
        emit AuctionEndTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, _endTimestamp);
    }

    /**
     * @notice Toggling the pause of the contract
     * @dev Only admin
    */
    function toggleIsPaused() external onlyAdmin {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Destroy the smart contract
     * @dev Only admin
     */
    function destroy() external onlyAdmin {
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        selfdestruct(serviceFeeRecipient);
        emit Destroy();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../tge/interfaces/IBEP20.sol";

library BidLibrary {
    /// @notice Information about the sender that placed a bid on an auction
    struct Bid {
        address payable bidder;
        uint256 bidAmount;
        uint256 actualBidAmount;
        uint256 bidTime;
    }

    function removeByIndex(Bid[] storage _list, uint256 _index) internal {
        for (uint256 i = _index; i < _list.length - 1; i++) {
            _list[i] = _list[i + 1];
        }
        _list.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../ERC721Auction.sol";
import "../../managers/TradeTokenManager.sol";

/**
 * @notice Mock Contract of ERC721Auction
 */
contract ERC721AuctionMock is ERC721Auction {
    uint256 public fakeBlockTimeStamp = 100;

    /**
     * @notice Auction Constructor
     * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) ERC721Auction(_serviceFeeProxy, _tradeTokenManager)
    public {}

    function setBlockTimeStamp(uint256 _now) external {
        fakeBlockTimeStamp = _now;
    }

    function _getNow() internal override view returns (uint256) {
        return fakeBlockTimeStamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import './interfaces/IBEP20.sol';
import './libs/SafeMath.sol';
import './libs/Context.sol';
import './libs/Ownable.sol';

contract RefinableToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  constructor() public {
    _name = 'Refinable Token';
    _symbol = 'FINE';
    _decimals = 18;
    _totalSupply = 5 * 10**8 * 10**18; // 500m
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view virtual override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the token name.
   */
  function name() external view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'BEP20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'BEP20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {BEP20-_burn}.
   */
  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {BEP20-_burn} and {BEP20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    uint256 decreasedAllowance =
      _allowances[account][_msgSender()].sub(
        amount,
        'BEP20: burn amount exceeds allowance'
      );

    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), 'BEP20: transfer from the zero address');
    require(recipient != address(0), 'BEP20: transfer to the zero address');

    _balances[sender] = _balances[sender].sub(
      amount,
      'BEP20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), 'BEP20: burn from the zero address');

    _balances[account] = _balances[account].sub(
      amount,
      'BEP20: burn amount exceeds balance'
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'BEP20: approve from the zero address');
    require(spender != address(0), 'BEP20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
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
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
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
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import './Context.sol';

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() public {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import './tge/interfaces/IBEP20.sol';

contract Disperse {
  function disperseBNB(
    address payable[] calldata recipients,
    uint256[] calldata values
  ) external payable {
    for (uint256 i = 0; i < recipients.length; i++)
      recipients[i].transfer(values[i]);
    uint256 balance = address(this).balance;
    address payable change = payable(msg.sender);
    if (balance > 0) change.transfer(balance);
  }

  function disperseToken(
    IBEP20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    uint256 total = 0;
    for (uint256 i = 0; i < recipients.length; i++) total += values[i];
    require(token.transferFrom(msg.sender, address(this), total));
    for (uint256 i = 0; i < recipients.length; i++)
      require(token.transfer(recipients[i], values[i]));
  }

  function disperseTokenSimple(
    IBEP20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    for (uint256 i = 0; i < recipients.length; i++)
      require(token.transferFrom(msg.sender, recipients[i], values[i]));
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../tge/interfaces/IBEP20.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../roles/AdminRole.sol";
import "../libs/BidLibrary.sol";
import "../managers/TradeTokenManager.sol";
import "../managers/NftTokenManager.sol";
import "../service_fee/RoyaltiesStrategy.sol";
import "../interfaces/ICreator.sol";

/**
 * @notice Primary sale auction contract for Refinable NFTs
 */
contract ERC1155Auction is Context, ReentrancyGuard, AdminRole, RoyaltiesStrategy {
    using SafeMath for uint256;
    using Address for address payable;
    using BidLibrary for BidLibrary.Bid[];
    /// @notice Event emitted only on construction. To be used by indexers
    event AuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event Destroy();

    event AuctionCreated(bytes32 auctionId, address token, uint256 indexed tokenId, address owner, address payToken);

    event AuctionCreateTimeLimitUpdated(uint256 auctionCreateTimeLimit);

    event AuctionEndTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, address owner, uint256 endTime);

    event AuctionStartTimeUpdated(bytes32 auctionId, address token, uint256 indexed tokenId, address owner, uint256 startTime);

    event MinBidIncrementBpsUpdated(uint256 minBidIncrementBps);

    event MaxBidStackCountUpdated(uint256 maxBidStackCount);

    event BidWithdrawalLockTimeUpdated(uint256 bidWithdrawalLockTime);

    event BidPlaced(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        address indexed bidder,
        uint256 bidAmount,
        uint256 actualBidAmount
    );

    event BidWithdrawn(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        address indexed bidder,
        uint256 bidAmount
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bidAmount,
        address payToken
    );

    event AuctionResulted(
        bytes32 auctionId,
        address token,
        uint256 indexed tokenId,
        address owner,
        address payToken,
        address indexed winner,
        uint256 winningBidAmount
    );

    event AuctionCancelled(bytes32 auctionId, address token, uint256 indexed tokenId, address owner);

    /// @notice Parameters of an auction
    struct Auction {
        address token;
        address royaltyToken;
        uint256 tokenId;
        address owner;
        address payToken;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        bool created;
    }

    address public serviceFeeProxy;

    address public tradeTokenManager;

    /// @notice ERC1155 Auction ID -> Auction Parameters
    mapping(bytes32 => Auction) public auctions;

    /// @notice ERC1155 Auction ID -> Bid Parameters
    mapping(bytes32 => BidLibrary.Bid[]) public bids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrementBps = 250;

    //@notice global auction create time limit
    uint256 public auctionCreateTimeLimit = 30 days;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 3 days;

    /// @notice global limit time between bid time and auction end time
    uint256 public bidLimitBeforeEndTime = 5 minutes;

    /// @notice max bidders stack count
    uint256 public maxBidStackCount = 1;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    modifier whenNotPaused() {
        require(!isPaused, "Auction: Function is currently paused");
        _;
    }

    modifier onlyCreatedAuction(bytes32 _auctionId) {
        require(
            auctions[_auctionId].created == true,
            "Auction: Auction does not exist"
        );
        _;
    }

    /**
     * @notice Auction Constructor
    * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) public {
        serviceFeeProxy = _serviceFeeProxy;
        tradeTokenManager = _tradeTokenManager;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AuctionContractDeployed();
    }

    /**
     * @notice Creates a new auction for a given token
     * @dev Only the owner of a token can create an auction and must have approved the contract
     * @dev End time for the auction must be in the future.
     * @param _token Token Address that follows ERC1155 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _startPrice Starting bid price of the token being auctioned
     * @param _startTimestamp Unix epoch in seconds for the auction start time
     * @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        address _token,
        address _royaltyToken,
        uint256 _tokenId,
        address _payToken,
        uint256 _startPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external whenNotPaused {
        require(
            _startTimestamp <= _getNow().add(auctionCreateTimeLimit),
            "Auction: Exceed auction start time limit"
        );
        require(
            IERC1155(_token).supportsInterface(_INTERFACE_ID_ERC1155),
            "Auction: Invalid NFT"
        );

        if (_royaltyToken != address(0)) {
            require(
                IERC1155(_royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2),
                "Auction: Invalid royalty contract"
            );
            require(
                IRoyalty(_royaltyToken).getTokenContract() == _token,
                "Auction: Royalty Token address does not match buy token"
            );
        }

        // Check owner has token and approved
        require(
            IERC1155(_token).balanceOf(msg.sender, _tokenId) > 0,
            "Auction: Caller does not have the token"
        );
        require(
            IERC1155(_token).isApprovedForAll(_msgSender(), address(this)),
            "Auction: Owner has not approved"
        );

        if (_payToken != address(0)) {
            require(
                TradeTokenManager(tradeTokenManager).supportToken(_payToken) == true,
                "Auction: Pay Token is not allowed"
            );
        }

        bytes32 auctionId = getAuctionId(_token, _tokenId, msg.sender);

        // Check the auction already created, can only list 1 token at a time
        require(
            auctions[auctionId].created == false,
            "Auction: Auction has been already created"
        );
        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp > _startTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        // Setup the auction
        auctions[auctionId] = Auction({
        token : _token,
        royaltyToken : _royaltyToken,
        tokenId : _tokenId,
        owner : msg.sender,
        payToken : _payToken,
        startPrice : _startPrice,
        startTime : _startTimestamp,
        endTime : _endTimestamp,
        created : true
        });

        emit AuctionCreated(auctionId, _token, _tokenId, msg.sender, _payToken);
    }

    /**
     * @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     * @dev Only callable when the auction is open
     * @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function placeBid(bytes32 _auctionId)
    external
    payable
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        require(
            _msgSender().isContract() == false,
            "Auction: No contracts permitted"
        );

        // Ensure auction is in flight
        require(
            _getNow() >= auctions[_auctionId].startTime && _getNow() <= auctions[_auctionId].endTime,
            "Auction: Bidding outside of the auction window"
        );

        uint256 bidAmount;

        if (auctions[_auctionId].payToken == address(0)) {
            bidAmount = msg.value;
        } else {
            bidAmount = IBEP20(auctions[_auctionId].payToken).allowance(msg.sender, address(this));
            require(
                IBEP20(auctions[_auctionId].payToken).transferFrom(msg.sender, address(this), bidAmount) == true,
                "Auction: Token transfer failed"
            );
        }

        // Ensure bid adheres to outbid increment and threshold
        uint256 actualBidAmount = bidAmount.mul(10 ** 4).div(ServiceFeeProxy(serviceFeeProxy).getBuyServiceFeeBps(msg.sender).add(10 ** 4));
        uint256 minBidRequired;
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length != 0) {
            minBidRequired =
            bidList[bidList.length - 1].actualBidAmount.mul(minBidIncrementBps.add(10 ** 4)).div(10 ** 4);
        } else {
            minBidRequired = auctions[_auctionId].startPrice;
        }

        require(
            actualBidAmount >= minBidRequired,
            "Auction: Failed to outbid min price"
        );

        // assign top bidder and bid time
        BidLibrary.Bid memory newHighestBid = BidLibrary.Bid({
        bidder : _msgSender(),
        bidAmount : bidAmount,
        actualBidAmount : actualBidAmount,
        bidTime : _getNow()
        });

        bidList.push(newHighestBid);

        //Refund old bid if bidlist overflows thans max bid stack count
        if (bidList.length > maxBidStackCount) {
            BidLibrary.Bid memory oldBid = bidList[0];
            if (oldBid.bidder != address(0)) {
                _refundBid(oldBid.bidder, oldBid.bidAmount, auctions[_auctionId].payToken);
            }

            bidList.removeByIndex(0);
        }

        //Increase auction end time if bid time is within 5 mins after auction end time
        if (auctions[_auctionId].endTime <= newHighestBid.bidTime.add(bidLimitBeforeEndTime)) {
            _updateAuctionEndTime(_auctionId, auctions[_auctionId].endTime.add(bidLimitBeforeEndTime));
        }

        emit BidPlaced(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].owner,
            auctions[_auctionId].payToken,
            _msgSender(),
            bidAmount,
            actualBidAmount
        );
    }

    /**
     * @notice Given a sender who is in the bid list of auction, allows them to withdraw their bid
     * @dev Only callable by the existing top bidder
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function withdrawBid(bytes32 _auctionId)
    external
    nonReentrant
    whenNotPaused
    onlyCreatedAuction(_auctionId)
    {
        BidLibrary.Bid[] storage bidList = bids[_auctionId];
        require(bidList.length > 0, "Auction: There is no bid");

        uint256 withdrawIndex = bidList.length;
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == _msgSender()) {
                withdrawIndex = i;
            }
        }

        require(withdrawIndex != bidList.length, "Auction: Caller is not bidder");

        BidLibrary.Bid storage withdrawableBid = bidList[withdrawIndex];

        // Check withdrawal after delay time
        require(
            _getNow() >= auctions[_auctionId].endTime.add(bidWithdrawalLockTime),
            "Auction: Cannot withdraw until auction ends"
        );

        if (withdrawableBid.bidder != address(0)) {
            _refundBid(withdrawableBid.bidder, withdrawableBid.bidAmount, auctions[_auctionId].payToken);
        }

        bidList.removeByIndex(withdrawIndex);

        emit BidWithdrawn(
            _auctionId,
            auctions[_auctionId].token,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].owner,
            auctions[_auctionId].payToken,
            _msgSender(),
            withdrawableBid.bidAmount
        );
    }

    /**
     * @notice Results a finished auction
     * @dev Only admin or smart contract
     * @dev Auction can only be resulted if there has been a bidder and reserve met.
     * @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function endAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // Check the auction has ended
        require(
            _getNow() > auction.endTime,
            "Auction: Auction has not ended"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC1155(auction.token).isApprovedForAll(auction.owner, address(this)),
            "Auction: Auction not approved"
        );

        // Get info on who the highest bidder is
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        require(bidList.length > 0, "Auction: There is no bid");

        BidLibrary.Bid memory highestBid = bidList[bidList.length - 1];

        // Send platform fee
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        bool platformTransferSuccess;
        bool ownerTransferSuccess;

        uint256 totalServiceFee;
        uint256 royalties;
        if (
            IERC165(auction.token).supportsInterface(_INTERFACE_ID_FEES)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(auction.token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        ) {
            bool isSecondarySale = _isSecondarySale(auction.token, auction.tokenId, auction.owner);
            // Work out platform fee from above reserve amount
            totalServiceFee = highestBid.bidAmount.sub(highestBid.actualBidAmount).add(
                highestBid.actualBidAmount.mul(
                    ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(auction.owner, isSecondarySale)
                ).div(10 ** 4)
            );
            royalties = _payOutRoyaltiesByStrategy(
                auction.token,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        } else if (auction.royaltyToken != address(0) && IERC165(auction.royaltyToken).supportsInterface(_INTERFACE_ID_ROYALTY_V2)) {
            require(
                IRoyalty(auction.royaltyToken).getTokenContract() == auction.token,
                "Auction: Royalty Token address does not match buy token"
            );
            bool isSecondarySale = _isSecondarySale(auction.royaltyToken, auction.tokenId, auction.owner);
            // Work out platform fee from above reserve amount
            totalServiceFee = highestBid.bidAmount.sub(highestBid.actualBidAmount).add(
                highestBid.actualBidAmount.mul(
                    ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(auction.owner, isSecondarySale)
                ).div(10 ** 4)
            );
            royalties = _payOutRoyaltiesByStrategy(
                auction.royaltyToken,
                auction.tokenId,
                auction.payToken,
                address(this),
                highestBid.bidAmount.sub(totalServiceFee),
                isSecondarySale
            );
        } else {
            totalServiceFee = highestBid.bidAmount.sub(highestBid.actualBidAmount).add(
                highestBid.actualBidAmount.mul(
                    ServiceFeeProxy(serviceFeeProxy).getSellServiceFeeBps(auction.owner, true)
                ).div(10 ** 4)
            );
        }

        uint256 remain = highestBid.bidAmount.sub(totalServiceFee).sub(royalties);
        if (auction.payToken == address(0)) {
            (platformTransferSuccess,) =
            serviceFeeRecipient.call{value : totalServiceFee}("");
            // Send remaining to designer
            if (remain > 0) {
                (ownerTransferSuccess,) =
                auction.owner.call{
                value : remain
                }("");
            }
        } else {
            platformTransferSuccess = IBEP20(auction.payToken).transfer(serviceFeeRecipient, totalServiceFee);
            if (remain > 0) {
                ownerTransferSuccess = IBEP20(auction.payToken).transfer(auction.owner, remain);
            }
        }
        require(
            platformTransferSuccess,
            "Auction: Failed to send fee"
        );
        if (remain > 0) {
            require(
                ownerTransferSuccess,
                "Auction: Failed to send winning bid"
            );
        }

        // Transfer the token to the winner
        IERC1155(auction.token).safeTransferFrom(auction.owner, highestBid.bidder, auction.tokenId, 1, "");

        // Refund bid amount to bidders who isn't the top unfortunately
        for (uint256 i = 0; i < bidList.length - 1; i++) {
            _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
        }

        // Remove auction and bids
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionResulted(
            _auctionId,
            auction.token,
            auction.tokenId,
            auction.owner,
            auction.payToken,
            highestBid.bidder,
            highestBid.bidAmount
        );
    }

    /**
     * @notice Cancels and inflight and un-resulted auctions, returning the funds to bidders if found
     * @dev Only admin
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function cancelAuction(bytes32 _auctionId)
    external
    nonReentrant
    onlyCreatedAuction(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        require(
            isAdmin(msg.sender) || (auction.owner == msg.sender),
            "Auction: Only admin or auction owner can result the auction"
        );

        // refund bid amount to existing bidders
        BidLibrary.Bid[] storage bidList = bids[_auctionId];

        if (bidList.length > 0) {
            for (uint256 i = 0; i < bidList.length; i++) {
                _refundBid(bidList[i].bidder, bidList[i].bidAmount, auction.payToken);
            }
        }

        // Remove auction and bids
        delete bids[_auctionId];
        delete auctions[_auctionId];

        emit AuctionCancelled(_auctionId, auction.token, auction.tokenId, auction.owner);
    }

    /**
     * @notice Update the amount by which bids have to increase, across all auctions
     * @dev Only admin
     * @param _minBidIncrementBps New bid step in WEI
     */
    function updateMinBidIncrementBps(uint256 _minBidIncrementBps)
    external
    onlyAdmin
    {
        minBidIncrementBps = _minBidIncrementBps;
        emit MinBidIncrementBpsUpdated(_minBidIncrementBps);
    }

    /**
     * @notice Update the auction create time limit by which how far ahead can auctions be created
     * @dev Only admin
     * @param _auctionCreateTimeLimit New auction create time limit
     */
    function updateAuctionCreateTimeLimit(uint256 _auctionCreateTimeLimit)
    external
    onlyAdmin
    {
        auctionCreateTimeLimit = _auctionCreateTimeLimit;
        emit AuctionCreateTimeLimitUpdated(_auctionCreateTimeLimit);
    }

    /**
     * @notice Update the global max bid stack count
     * @dev Only admin
     * @param _maxBidStackCount max bid stack count
     */
    function updateMaxBidStackCount(uint256 _maxBidStackCount)
    external
    onlyAdmin
    {
        maxBidStackCount = _maxBidStackCount;
        emit MaxBidStackCountUpdated(_maxBidStackCount);
    }

    /**
     * @notice Update the global bid withdrawal lockout time
     * @dev Only admin
     * @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
    external
    onlyAdmin
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit BidWithdrawalLockTimeUpdated(_bidWithdrawalLockTime);
    }

    /**
     * @notice Update the current start time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(bytes32 _auctionId, uint256 _startTime)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        auctions[_auctionId].startTime = _startTime;
        emit AuctionStartTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, auctions[_auctionId].owner, _startTime);
    }

    /**
     * @notice Update the current end time for an auction
     * @dev Only admin
     * @dev Auction must exist
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp New end time (unix epoch in seconds)
     */
    function updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp)
    external
    onlyAdmin
    onlyCreatedAuction(_auctionId)
    {
        require(
            auctions[_auctionId].startTime < _endTimestamp && _endTimestamp > _getNow(),
            "Auction: Auction time is incorrect"
        );

        _updateAuctionEndTime(_auctionId, _endTimestamp);
    }

    /**
     * @notice Method for getting all info about the auction
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getAuction(bytes32 _auctionId)
    external
    view
    returns (Auction memory)
    {
        return auctions[_auctionId];
    }

    /**
     * @notice Method for getting all info about the bids
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     */
    function getBidList(bytes32 _auctionId) public view returns (BidLibrary.Bid[] memory) {
        return bids[_auctionId];
    }

    /**
     * @notice Method for getting auction id to query the auctions mapping
     * @param _token Token Address that follows ERC1155 standard
     * @param _tokenId Token ID of the token being auctioned
     * @param _owner Owner address of the token Id
    */
    function getAuctionId(address _token, uint256 _tokenId, address _owner) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_token, _tokenId, _owner));
    }

    /**
     * @notice Method for the block timestamp
    */
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _isSecondarySale(address _token, uint256 _tokenId, address _seller) internal returns (bool){
        if (IERC165(_token).supportsInterface(type(ICreator).interfaceId)) {
            address creator = ICreator(_token).getCreator(_tokenId);
            return (creator != _seller);
        } else {
            return true;
        }
    }

    /**
     * @notice Private method used for sending back escrowed funds from a previous bid
     * @param _bidder Address of the last highest bidder
     * @param _bidAmount Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundBid(address payable _bidder, uint256 _bidAmount, address _payToken) private {
        // refund previous best (if bid exists)
        bool successRefund;
        if (_payToken == address(0)) {
            (successRefund,) = _bidder.call{value : _bidAmount}("");
        } else {
            successRefund = IBEP20(_payToken).transfer(_bidder, _bidAmount);
        }
        require(
            successRefund,
            "Auction: Failed to refund"
        );
        emit BidRefunded(_bidder, _bidAmount, _payToken);
    }

    /**
     * @notice Private method used for update auction end time
     * @param _auctionId Auction ID the id can be obtained from the getAuctionId function
     * @param _endTimestamp timestamp of end time
     */
    function _updateAuctionEndTime(bytes32 _auctionId, uint256 _endTimestamp) private {
        auctions[_auctionId].endTime = _endTimestamp;
        emit AuctionEndTimeUpdated(_auctionId, auctions[_auctionId].token, auctions[_auctionId].tokenId, auctions[_auctionId].owner, _endTimestamp);
    }

    /**
     * @notice Toggling the pause of the contract
     * @dev Only admin
    */
    function toggleIsPaused() external onlyAdmin {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     * @notice Destroy the smart contract
     * @dev Only admin
     */
    function destroy() external onlyAdmin {
        address payable serviceFeeRecipient = ServiceFeeProxy(serviceFeeProxy).getServiceFeeRecipient();
        selfdestruct(serviceFeeRecipient);
        emit Destroy();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../ERC1155Auction.sol";

/**
 * @notice Mock Contract of ERC1155Auction
 */
contract ERC1155AuctionMock is ERC1155Auction {
    uint256 public fakeBlockTimeStamp = 100;

    /**
     * @notice Auction Constructor
     * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) ERC1155Auction(_serviceFeeProxy, _tradeTokenManager)
    public {}

    function setBlockTimeStamp(uint256 _now) external {
        fakeBlockTimeStamp = _now;
    }

    function _getNow() internal override view returns (uint256) {
        return fakeBlockTimeStamp;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IRefinableToken.sol";
import "../interfaces/IServiceFee.sol";

/**
 * @notice Service Fee contract for Refinable NFT Marketplace
 */
contract ServiceFeeMatic is AccessControl, IServiceFee {
    using Address for address;

    /// @notice service fee contract
    IRefinableToken public refinableTokenContract;

    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    /// @notice Service fee recipient address
    address payable public serviceFeeRecipient;

    event ServiceFeeRecipientChanged(address payable serviceFeeRecipient);

    event RefinableTokenContractUpdated(address refinableTokenContract);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Ownable: caller is not the admin"
        );
        _;
    }

    modifier onlyProxy() {
        require(
            hasRole(PROXY_ROLE, _msgSender()),
            "Ownable: caller is not the proxy"
        );
        _;
    }

    /**
     * @dev Constructor Function
    */
    constructor() public {
        require(
            _msgSender() != address(0),
            "Auction: Invalid Platform Fee Recipient"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Lets admin set the refinable token contract
     * @param _refinableTokenContract address of refinable token contract
     */
    function setRefinableTokenContract(address _refinableTokenContract) onlyAdmin external override {
        require(
            _refinableTokenContract != address(0),
            "ServiceFee.setRefinableTokenContract: Zero address"
        );
        refinableTokenContract = IRefinableToken(_refinableTokenContract);
        emit RefinableTokenContractUpdated(_refinableTokenContract);
    }

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) onlyAdmin external override {
        require(
            _proxyAddr.isContract(),
            "ServiceFee.addProxy: address is not a contract address"
        );
        grantRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) onlyAdmin external override{
        require(
            _proxyAddr.isContract(),
            "ServiceFee.removeProxy: address is not a contract address"
        );
        revokeRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Calculate the seller service fee in according to the business logic and returns it
     * @param _seller address of seller
     * @param _isSecondarySale sale is primary or secondary
     */
    function getSellServiceFeeBps(address _seller, bool _isSecondarySale) external view onlyProxy override returns (uint256) {
        require(
            _seller != address(0),
            "ServiceFee.getSellServiceFeeBps: Zero address"
        );

        // We cannot check the FINE balance since it's not deployed to Matic yet. Everything is set to 1.5% for now.
        // TODO: Add the bridge token so the service fee can check FINE balance on Matic

        //        uint256 balance = refinableTokenContract.balanceOf(_seller);
        
//        if(_isSecondarySale) {
//            if(balance >= 10000 * 10 ** 18)
//                return 150;
//            else if(balance >= 2500 * 10 ** 18)
//                return 175;
//            else if(balance >= 250 * 10 ** 18)
//                return 200;
//            else if(balance >= 20 * 10 ** 18)
//                return 225;
//        } else {
//            if(balance >= 250 * 10 ** 18)
//                return 200;
//            else if(balance >= 20 * 10 ** 18)
//                return 225;
//        }
        return 150;
    }

    /**
     * @notice Calculate the buyer service fee in according to the business logic and returns it
     * @param _buyer address of buyer
     */
    function getBuyServiceFeeBps(address _buyer) onlyProxy external view override returns (uint256) {
        require(
            _buyer != address(0),
            "ServiceFee.getBuyServiceFeeBps: Zero address"
        );
//        uint256 balance = refinableTokenContract.balanceOf(_buyer);
//
//        if(balance >= 10000 * 10 ** 18)
//            return 150;
//        else if(balance >= 2500 * 10 ** 18)
//            return 175;
//        else if(balance >= 250 * 10 ** 18)
//            return 200;
//        else if(balance >= 20 * 10 ** 18)
//            return 225;
        return 0;
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() onlyProxy external view override returns (address payable) {
        return serviceFeeRecipient;
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) onlyProxy external override {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFee.setServiceFeeRecipient: Zero address"
        );

        serviceFeeRecipient = _serviceFeeRecipient;
        emit ServiceFeeRecipientChanged(_serviceFeeRecipient);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IRefinableToken {

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account)
    external
    view
    returns (uint256);

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    external
    returns (bool);

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    external
    returns (bool);

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IRefinableToken.sol";
import "../interfaces/IServiceFee.sol";

/**
 * @notice Service Fee contract for Refinable NFT Marketplace
 */
contract ServiceFee is AccessControl, IServiceFee {
    using Address for address;

    /// @notice service fee contract
    IRefinableToken public refinableTokenContract;

    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    /// @notice Service fee recipient address
    address payable public serviceFeeRecipient;

    event ServiceFeeRecipientChanged(address payable serviceFeeRecipient);

    event RefinableTokenContractUpdated(address refinableTokenContract);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Ownable: caller is not the admin"
        );
        _;
    }

    modifier onlyProxy() {
        require(
            hasRole(PROXY_ROLE, _msgSender()),
            "Ownable: caller is not the proxy"
        );
        _;
    }

    /**
     * @dev Constructor Function
    */
    constructor() public {
        require(
            _msgSender() != address(0),
            "Auction: Invalid Platform Fee Recipient"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Lets admin set the refinable token contract
     * @param _refinableTokenContract address of refinable token contract
     */
    function setRefinableTokenContract(address _refinableTokenContract) onlyAdmin external override {
        require(
            _refinableTokenContract != address(0),
            "ServiceFee.setRefinableTokenContract: Zero address"
        );
        refinableTokenContract = IRefinableToken(_refinableTokenContract);
        emit RefinableTokenContractUpdated(_refinableTokenContract);
    }

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) onlyAdmin external override {
        require(
            _proxyAddr.isContract(),
            "ServiceFee.addProxy: address is not a contract address"
        );
        grantRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) onlyAdmin external override{
        require(
            _proxyAddr.isContract(),
            "ServiceFee.removeProxy: address is not a contract address"
        );
        revokeRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Calculate the seller service fee in according to the business logic and returns it
     * @param _seller address of seller
     * @param _isSecondarySale sale is primary or secondary
     */
    function getSellServiceFeeBps(address _seller, bool _isSecondarySale) external view onlyProxy override returns (uint256) {
        require(
            _seller != address(0),
            "ServiceFee.getSellServiceFeeBps: Zero address"
        );

        uint256 balance = refinableTokenContract.balanceOf(_seller);

        if(_isSecondarySale) {
            if(balance >= 10000 * 10 ** 18)
                return 150;
            else if(balance >= 2500 * 10 ** 18)
                return 175;
            else if(balance >= 250 * 10 ** 18)
                return 200;
            else if(balance >= 20 * 10 ** 18)
                return 225;
        } else {
            if(balance >= 250 * 10 ** 18)
                return 200;
            else if(balance >= 20 * 10 ** 18)
                return 225;
        }
        return 250;
    }

    /**
     * @notice Calculate the buyer service fee in according to the business logic and returns it
     * @param _buyer address of buyer
     */
    function getBuyServiceFeeBps(address _buyer) onlyProxy external view override returns (uint256) {
        require(
            _buyer != address(0),
            "ServiceFee.getBuyServiceFeeBps: Zero address"
        );
        uint256 balance = refinableTokenContract.balanceOf(_buyer);

        if(balance >= 10000 * 10 ** 18)
            return 150;
        else if(balance >= 2500 * 10 ** 18)
            return 175;
        else if(balance >= 250 * 10 ** 18)
            return 200;
        else if(balance >= 20 * 10 ** 18)
            return 225;
        return 250;
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() onlyProxy external view override returns (address payable) {
        return serviceFeeRecipient;
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) onlyProxy external override {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFee.setServiceFeeRecipient: Zero address"
        );

        serviceFeeRecipient = _serviceFeeRecipient;
        emit ServiceFeeRecipientChanged(_serviceFeeRecipient);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721BaseV2.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract RefinableERC721WhiteListedTokenV2 is ERC721BaseV2 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV2(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );
        RoyaltyLibrary.RoyaltyShareDetails[] memory newRoyaltyShares;

        //add the default royalties if the contract has set
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0) {
            newRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](_royaltyShares.length + 1);
            for (uint256 i = 0; i < _royaltyShares.length; i++) {
                newRoyaltyShares[i] = _royaltyShares[i];
            }
            newRoyaltyShares[_royaltyShares.length] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        } else {
            newRoyaltyShares = _royaltyShares;
        }

        _mint(msg.sender, _tokenId, newRoyaltyShares, _uri, _royaltyBps, _royaltyStrategy);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10**4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./ERC721BaseV2.sol";

/**
 * @title RefinableERC721Token
 * @dev anyone can mint token.
 */
contract RefinableERC721TokenV2 is ERC721BaseV2 {
    using ECDSA for bytes32;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV2(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) public {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender))
                .toEthSignedMessageHash()
                .recover(_signature)
            ),
            "invalid signer"
        );
        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, _royaltyStrategy);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC721AirdropMatic is Context, ReentrancyGuard {

    /// @notice ERC721 NFT
    IERC721 public token;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256[] tokenIds,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC721 _token
    ) public {
        require(address(_token) != address(0), "Invalid NFT");

        token = _token;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenIds array of token id
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC721 _token, uint256[] memory _tokenIds, address[] memory _recipients) external nonReentrant {
        require(
            _token == token,
            "ERC721Airdrop: Token is not allowed"
        );
        require(
            _recipients.length == _tokenIds.length,
            "ERC721Airdrop: Count of recipients should be same as count of token ids"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _token.ownerOf(_tokenIds[i]) == _msgSender(),
                "ERC721Airdrop: Caller is not the owner"
            );
        }

        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC721Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenIds[i]);
        }

        emit AirdropFinished(_tokenIds, _recipients);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title RefinableERC721Token Interface
 */
interface IRefinableERC721Token is IERC721 {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        Fee[] memory _fees,
        string memory _tokenURI
    ) external;

    function setBaseURI(string memory _baseURI) external;

    function setContractURI(string memory _contractURI) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRefinableERC721Token.sol";
import "../interfaces/IRefinableERC1155Token.sol";
import "../libs/Ownable.sol";

/**
 * @title RefinableNFTFactory Contract
 */
contract RefinableNFTFactory is Ownable
{
    /// @notice Event emitted only on construction. To be used by indexers
    event RefinableNFTFactoryContractDeployed();

    event ERC721TokenBulkMinted(
        address indexed minter,
        uint256[] tokenIds,
        IRefinableERC721Token.Fee[][] fees,
        string[] tokenURIs
    );

    /// @notice Max bulk mint count
    uint256 public maxBulkCount = 100;

    /// @notice RefinableERC721 Token
    IRefinableERC721Token public refinableERC721Token;

    /// @notice RefinableERC1155 Token
    IRefinableERC1155Token public refinableERC1155Token;

    /**
     * @notice Auction Constructor
     * @param _refinableERC721Token RefinableERC721Token Interface
     * @param _refinableERC1155Token RefinableERC1155Token Interface
     */
    constructor(
        IRefinableERC721Token _refinableERC721Token,
        IRefinableERC1155Token _refinableERC1155Token
    ) public {
        require(
            address(_refinableERC721Token) != address(0),
            "Invalid NFT"
        );

        require(
            address(_refinableERC1155Token) != address(0),
            "Invalid NFT"
        );

        refinableERC721Token = _refinableERC721Token;
        refinableERC1155Token = _refinableERC1155Token;

        emit RefinableNFTFactoryContractDeployed();
    }

    function bulk_mint_erc721_token(
        uint256[] memory _tokenIds,
        bytes[] memory _signatures,
        IRefinableERC721Token.Fee[][] memory _fees,
        string[] memory _tokenURIs
    ) public onlyOwner {
        require(
            _tokenIds.length > 0,
            "Empty array is provided"
        );

        require(
            _tokenIds.length < maxBulkCount,
            "Too big array is provided"
        );

        require(
            _tokenIds.length == _signatures.length && _signatures.length == _fees.length && _fees.length == _tokenURIs.length,
            "Size of params are not same"
        );

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            refinableERC721Token.mint(_tokenIds[i], _signatures[i], _fees[i],  _tokenURIs[i]);
            refinableERC721Token.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        emit ERC721TokenBulkMinted(msg.sender, _tokenIds, _fees, _tokenURIs);
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

/**
 * @title RefinableERC1155Token Interface
 */
interface IRefinableERC1155Token {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    function mint(uint256 _tokenId, bytes memory _signature, Fee[] memory _fees, uint256 _supply, string memory _uri) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC721Airdrop is Context, ReentrancyGuard {

    /// @notice ERC721 NFT
    IERC721 public token;
    IERC721 public tokenV2;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256[] tokenIds,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC721 _token,
        IERC721 _tokenV2
    ) public {
        require(address(_token) != address(0), "Invalid NFT");
        require(address(_tokenV2) != address(0), "Invalid NFT");

        token = _token;
        tokenV2 = _tokenV2;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenIds array of token id
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC721 _token, uint256[] memory _tokenIds, address[] memory _recipients) external nonReentrant {
        require(
            _token == token || _token == tokenV2,
            "ERC721Airdrop: Token is not allowed"
        );
        require(
            _recipients.length == _tokenIds.length,
            "ERC721Airdrop: Count of recipients should be same as count of token ids"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _token.ownerOf(_tokenIds[i]) == _msgSender(),
                "ERC721Airdrop: Caller is not the owner"
            );
        }

        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC721Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenIds[i]);
        }

        emit AirdropFinished(_tokenIds, _recipients);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC1155AirdropMatic is Context, ReentrancyGuard {

    /// @notice ERC1155 NFT
    IERC1155 public token;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256 tokenId,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC1155 _token
    ) public {
        require(address(_token) != address(0), "Invalid NFT");

        token = _token;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenId id of the token
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC1155 _token, uint256 _tokenId, address[] memory _recipients) external nonReentrant {
        require(
            _token == token,
            "ERC1155Airdrop: Token is not allowed"
        );
        require(
            _token.balanceOf(_msgSender(), _tokenId) >= _recipients.length,
            "ERC1155Airdrop: Caller does not have amount of tokens"
        );
        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC1155Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenId, 1, "");
        }

        emit AirdropFinished(_tokenId, _recipients);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC721BaseV3.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract DAFERC721WhiteListedTokenV3 is ERC721BaseV3 {
    using ECDSA for bytes32;

    address payable public defaultRoyaltyReceiver = address(0);
    uint256 public defaultRoyaltyReceiverBps = 0;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV3(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );

        RoyaltyLibrary.RoyaltyShareDetails[] memory defaultPrimaryRoyaltyShares = new RoyaltyLibrary.RoyaltyShareDetails[](1);
        if (defaultRoyaltyReceiver != address(0) && defaultRoyaltyReceiverBps != 0)
            defaultPrimaryRoyaltyShares[0] = RoyaltyLibrary.RoyaltyShareDetails({
            recipient : defaultRoyaltyReceiver,
            value : defaultRoyaltyReceiverBps
            });
        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyShares);
    }

    function setDefaultRoyaltyReceiver(address payable _receiver) public onlyAdmin {
        defaultRoyaltyReceiver = _receiver;
    }

    function setDefaultRoyaltyReceiverBps(uint256 _bps) public onlyAdmin {
        require(_bps <= 10 ** 4, "ERC721: Fee bps should not exceed 10000");
        defaultRoyaltyReceiverBps = _bps;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../ERC721BaseV3.sol";
/**
 * @title RefinableERC721TokenWhiteListed
 * @dev only minters can mint token.

 */
contract CoralERC721WhiteListedTokenV3 is ERC721BaseV3 {
    using ECDSA for bytes32;

    RoyaltyLibrary.RoyaltyShareDetails[] public defaultPrimaryRoyaltyReceivers;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _root address of admin account
     * @param _signer address of signer account
     * @param _contractURI URI of contract ex: https://api-mainnet.rarible.com/contractMetadata/{address}
     * @param _baseURI ex: https://ipfs.daonomic.com
    */
    constructor(
        string memory _name,
        string memory _symbol,
        address _root,
        address _signer,
        string memory _contractURI,
        string memory _baseURI
    ) public ERC721BaseV3(_name, _symbol, _contractURI, _baseURI) {
        addAdmin(_root);
        addSigner(_signer);
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public onlyMinter {
        require(
            isSigner(
                keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(_signature)
            ),
            "invalid signer"
        );

        _mint(msg.sender, _tokenId, _royaltyShares, _uri, _royaltyBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY, defaultPrimaryRoyaltyReceivers);
    }

    function setPrimaryDefaultRoyaltyReceivers(RoyaltyLibrary.RoyaltyShareDetails[] memory _receivers) public onlyAdmin {
        delete defaultPrimaryRoyaltyReceivers;
        for (uint256 i = 0; i < _receivers.length; i++) {
            defaultPrimaryRoyaltyReceivers.push(_receivers[i]);
        }
    }
}