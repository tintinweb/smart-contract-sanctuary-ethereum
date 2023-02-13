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

// Ref: https://github.com/reservoirprotocol/core/blob/main/packages/contracts/contracts/interfaces/ISeaport.sol

interface ISeaport {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
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
        address recipient;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);
}


// Ref: https://github.com/reservoirprotocol/core/blob/main/packages/contracts/contracts/router/modules/exchanges/SeaportModule.sol
library ReservoirMarket {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    event ExecutionLogString (string data);
    event ExecutionLogBytes(bytes data);

    struct TradeData {
        uint256 value;
        ISeaport.AdvancedOrder advancedOrder;
        address recipient;
    }

    function execute(bytes memory tradeData) external {
        TradeData memory decoded = abi.decode(tradeData, (TradeData));

        try ISeaport(SEAPORT).fulfillAdvancedOrder{value: decoded.value}(
                decoded.advancedOrder,
                new ISeaport.CriteriaResolver[](0),
                bytes32(0),
                decoded.recipient
            ) returns (bool fulfilled) {

            ISeaport.OrderParameters memory params = decoded.advancedOrder.parameters;
            if (fulfilled) {
                for (uint256 i = 0; i < params.offer.length; i++) {
                    ISeaport.OfferItem memory item = params.offer[i];
                    if (item.itemType == ISeaport.ItemType.NATIVE) {
                        // ETH
                    } else if (item.itemType == ISeaport.ItemType.ERC20) {
                        // ERC-20
                    } else if (item.itemType == ISeaport.ItemType.ERC721) {
                        // ERC-721
                        IERC721(item.token).transferFrom(address(this), msg.sender, item.identifierOrCriteria);
                    } else if (item.itemType == ISeaport.ItemType.ERC1155) {
                        // ERC-1155
                        IERC1155(item.token).safeTransferFrom(address(this), msg.sender, item.identifierOrCriteria, item.endAmount, "");
                    }
                }
            } else {
                emit ExecutionLogString("Order not fulfilled");
            }
        } catch Error(string memory reason) {
            emit ExecutionLogString(reason);
        } catch (bytes memory reason) {
            emit ExecutionLogBytes(reason);
        }
    }
}