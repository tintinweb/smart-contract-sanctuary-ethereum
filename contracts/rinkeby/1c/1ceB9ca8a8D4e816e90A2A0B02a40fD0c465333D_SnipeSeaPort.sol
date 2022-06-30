// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum OrderType {
    FULL_OPEN,
    PARTIAL_OPEN,
    FULL_RESTRICTED,
    PARTIAL_RESTRICTED
}
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}
enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
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
enum BasicOrderType {
    ETH_TO_ERC721_FULL_OPEN,
    ETH_TO_ERC721_PARTIAL_OPEN,
    ETH_TO_ERC721_FULL_RESTRICTED,
    ETH_TO_ERC721_PARTIAL_RESTRICTED,
    ETH_TO_ERC1155_FULL_OPEN,
    ETH_TO_ERC1155_PARTIAL_OPEN,
    ETH_TO_ERC1155_FULL_RESTRICTED,
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC20_TO_ERC721_FULL_OPEN,
    ERC20_TO_ERC721_PARTIAL_OPEN,
    ERC20_TO_ERC721_FULL_RESTRICTED,
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,
    ERC20_TO_ERC1155_FULL_OPEN,
    ERC20_TO_ERC1155_PARTIAL_OPEN,
    ERC20_TO_ERC1155_FULL_RESTRICTED,
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC721_TO_ERC20_FULL_OPEN,
    ERC721_TO_ERC20_PARTIAL_OPEN,
    ERC721_TO_ERC20_FULL_RESTRICTED,
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,
    ERC1155_TO_ERC20_FULL_OPEN,
    ERC1155_TO_ERC20_PARTIAL_OPEN,
    ERC1155_TO_ERC20_FULL_RESTRICTED,
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

interface ISeaPort {
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);
}
interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract SnipeSeaPort {
    address private reciver;
    ISeaPort private seaport = ISeaPort(0x00000000006c3852cbEf3e08E8dF289169EdE581);
    constructor(){
        reciver = msg.sender;
    }
    function snipeFulfillBasicOrder(BasicOrderParameters calldata parameters) external payable returns (bool) {
        bool fulfilled = seaport.fulfillBasicOrder{value: msg.value}(parameters);
        IERC721(parameters.offerToken).transferFrom(address(this), reciver, parameters.offerIdentifier);
        return fulfilled;
    }
    function claimETH() external {
        payable(reciver).transfer(address(this).balance);
    }
    function claimToken(address token) external {
        IERC20(token).transfer(reciver, IERC20(token).balanceOf(address(this)));
    }
    function claimNFT(address token, uint256 id) external {
        IERC721(token).transferFrom(address(this), reciver, id);
    }
}