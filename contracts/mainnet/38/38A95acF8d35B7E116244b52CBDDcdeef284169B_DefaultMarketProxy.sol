// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.13;

contract Constants {
    //seaport
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    uint256 public constant SEAPORT_MARKET_ID = 0;

    //looksrare
    address public constant LOOKSRARE =
        0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    uint256 public constant LOOKSRARE_MARKET_ID = 1;
    //x2y2
    address public constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3; //单个购买时的market合约
    // address public constant X2Y2_BATCH =
    //     0x56Dd5bbEDE9BFDB10a2845c4D70d4a2950163044; // 批量购买时的market合约--参考用
    uint256 public constant X2Y2_MARKET_ID = 2;
    //cryptopunk
    address public constant CRYPTOPUNK =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    uint256 public constant CRYPTOPUNK_MARKET_ID = 3;
    //mooncat
    address public constant MOONCAT =
        0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;
    uint256 public constant MOONCAT_MARTKET_ID = 4;

    struct ERC20Detail {
        address tokenAddr;
        uint256 amount;
    }

    struct ERC721Detail {
        address tokenAddr;
        uint256 id;
    }

    struct ERC1155Detail {
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }
    struct OrderItem {
        ItemType itemType;
        address tokenAddr;
        uint256 id;
        uint256 amount;
    }
    enum ItemType {
        INVALID,
        NATIVE,
        ERC20,
        ERC721,
        ERC1155
    }
    struct TradeInput {
        uint256 value; // 此次调用x2y2\looksrare\..需传递的主网币数量
        bytes inputData; //此次调用的input data
        OrderItem[] tokens; // 本次调用要购买的NFT信息
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ICryptoPunks.sol";
import "../interfaces/IMoonCatsRescue.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Constants.sol";

contract TransferHelper is Constants {
    IMoonCatsRescue moonCat = IMoonCatsRescue(MOONCAT);
    ICryptoPunks cryptoPunk = ICryptoPunks(CRYPTOPUNK); //CryptoPunksMarket

    function _uintToBytes5(uint256 id)
        internal
        pure
        returns (bytes5 slicedDataBytes5)
    {
        bytes memory _bytes = new bytes(32);
        assembly {
            mstore(add(_bytes, 32), id)
        }

        bytes memory tempBytes;

        assembly {
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
            let lengthmod := and(5, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
            let mc := add(
                add(tempBytes, lengthmod),
                mul(0x20, iszero(lengthmod))
            )
            let end := add(mc, 5)

            for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                let cc := add(
                    add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
                    27
                )
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, 5)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        assembly {
            slicedDataBytes5 := mload(add(tempBytes, 32))
        }
    }

    // 从msg.sender那买入MoonCat（需要msg.sender提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptMoonCat(uint256 moonCatId) internal {
        // msg.sender -> address(this)
        bytes5 catId = _uintToBytes5(moonCatId);
        address owner = moonCat.catOwners(catId);
        require(owner == msg.sender, "_acceptMoonCat: invalid mooncat owner");
        moonCat.acceptAdoptionOffer(catId);
    }

    // 将本合约中的MoonCat转出给用户to
    function _transferMoonCat(uint256 moonCatId, address to) internal {
        moonCat.giveCat(_uintToBytes5(moonCatId), to);
    }

    // 从msg.sender那买入CryptoPunk（需要msg.sender提前挂一个价格为0、并指定onlySellTo为本合约的卖单）
    function _acceptCryptoPunk(uint256 cryptoPunkId) internal {
        address owner = cryptoPunk.punkIndexToAddress(cryptoPunkId);
        require(owner == msg.sender, "_acceptCryptoPunk: invalid punk owner");
        cryptoPunk.buyPunk(cryptoPunkId); //msg.value为0
    }

    // 将本合约中的CryptoPunk转出给用户to
    function _transferCryptoPunk(uint256 cryptoPunkId, address to) internal {
        cryptoPunk.transferPunk(to, cryptoPunkId);
    }

    // 从本合约中转出主网币
    function _transferETH(address to, uint256 amount) internal {
        payable(to).transfer(amount); //失败则revert
    }

    function _transferERC20s(
        ERC20Detail[] calldata erc20Details, //tokenAddr-amount
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc20Details.length; i++) {
            // Transfer ERC20
            IERC20(erc20Details[i].tokenAddr).transferFrom(
                from,
                to,
                erc20Details[i].amount
            );
        }
    }

    function _transferERC721s(
        ERC721Detail[] calldata erc721Details, // tokenAddr-id
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            IERC721(erc721Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc721Details[i].id
            );
        }
    }

    function _transferERC1155s(
        ERC1155Detail[] calldata erc1155Details, //tokenAddr-id- amount
        address from,
        address to
    ) internal {
        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeTransferFrom(
                from,
                to,
                erc1155Details[i].id,
                erc1155Details[i].amount,
                ""
            );
        }
    }

    function _transferItemsFromThis(OrderItem[] calldata items, address to)
        internal
    {
        OrderItem calldata item;
        uint256 itemNums = items.length;
        uint256 tokenBalance = 0;
        // for-each
        for (uint256 i = 0; i < itemNums; i++) {
            item = items[i];
            if (item.amount == 0) {
                revert("_transferOrderItems: InvalidOrderItemAmount");
            }

            if (item.tokenAddr == CRYPTOPUNK) {
                _transferCryptoPunk(item.id, to);
            } else if (item.tokenAddr == MOONCAT) {
                _transferMoonCat(item.id, to);
            } else if (item.itemType == ItemType.ERC20) {
                tokenBalance = IERC20(item.tokenAddr).balanceOf(address(this));
                if (tokenBalance >= item.amount) {
                    IERC20(item.tokenAddr).transfer(to, item.amount);
                }
            } else if (item.itemType == ItemType.ERC721) {
                if (IERC721(item.tokenAddr).ownerOf(item.id) == address(this)) {
                    // Transfer ERC721
                    IERC721(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id
                    );
                }
            } else if (item.itemType == ItemType.ERC1155) {
                if (
                    IERC1155(item.tokenAddr).balanceOf(
                        address(this),
                        item.id
                    ) >= item.amount
                ) {
                    // Transfer ERC1155
                    IERC1155(item.tokenAddr).safeTransferFrom(
                        address(this),
                        to,
                        item.id,
                        item.amount,
                        ""
                    );
                }
            } else {
                revert("_transferOrderItem: InvalidItemType");
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index)
        external
        view
        returns (address owner);

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) external payable;

    function makeAdoptionOfferToAddress(
        bytes5 catId,
        uint256 price,
        address to
    ) external;

    function giveCat(bytes5 catId, address to) external;

    function catOwners(bytes5 catId) external view returns (address);

    function rescueOrder(uint256 rescueIndex)
        external
        view
        returns (bytes5 catId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../bases/TransferHelper.sol";

// delegatecall 的方式调用此合约
contract DefaultMarketProxy is TransferHelper {
    event BuyResult(uint256, bool);

    function batchBuyFromMarket(
        address targetMarket,
        TradeInput[] calldata tradeInputs
    ) public payable returns (uint256) {
        uint256 tradeNums = tradeInputs.length;

        bool success;
        uint256 successNum = 0;

        for (uint256 i = 0; i < tradeNums; i++) {
            // 1. buy from CryptoPunk（recipient=address(this))
            (success, ) = targetMarket.call{value: tradeInputs[i].value}(
                tradeInputs[i].inputData
            );
            if (success) {
                successNum++;
                // 2. transfer tokens from address(this) to msg.sender
                _transferItemsFromThis(tradeInputs[i].tokens, msg.sender);
                emit BuyResult(i, success);
            }
        }
        return successNum;
    }
}