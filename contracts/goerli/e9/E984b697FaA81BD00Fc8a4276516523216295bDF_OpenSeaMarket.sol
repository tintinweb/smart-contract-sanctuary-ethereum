// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "../../interfaces/tokens/IERC20.sol";
import "../../interfaces/tokens/IERC721.sol";
import "../../interfaces/tokens/IERC1155.sol";


enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

struct Order {
    OrderParameters parameters;
    bytes signature;
}

interface ISeaport {
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external
        payable
        returns (bool fulfilled);
}

library OpenSeaMarket {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    struct TradeData {
        uint256 value;
        Order order;
        bytes32 fulfillerConduitKey;
    }

    function execute(bytes memory tradeData) external {
        TradeData memory decoded = abi.decode(tradeData, (TradeData));
        bool fulfilled = ISeaport(SEAPORT).fulfillOrder{value: decoded.value}(decoded.order, decoded.fulfillerConduitKey);

        OrderParameters memory params = decoded.order.parameters;
        if (fulfilled) {
            for (uint256 i = 0; i < params.offer.length; i++) {
                OfferItem memory item = params.offer[i];
                if (item.itemType == ItemType.NATIVE) {
                    // ETH
                } else if (item.itemType == ItemType.ERC20) {
                    // ERC-20
                } else if (item.itemType == ItemType.ERC721) {
                    // ERC-721
                    IERC721(item.token).transferFrom(address(this), msg.sender, item.identifierOrCriteria);
                } else if (item.itemType == ItemType.ERC1155) {
                    // ERC-1155
                    IERC1155(item.token).safeTransferFrom(address(this), msg.sender, item.identifierOrCriteria, item.endAmount, "");
                }
            }
        }
    }
}