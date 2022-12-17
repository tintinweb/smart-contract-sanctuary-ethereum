/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract Marketplace {
    struct Item {
        uint256 tokenId;
        uint256 cost;
        address tokenAddress;
        address tokenOwner;
    }

    struct AuctionItem {
        uint256 tokenId;
        uint256 currentCost;
        uint256 time;
        uint24 bidCount;
        address tokenAddress;
        address tokenOwner;
        address lastCustomer;
    }

    uint256 public listId;
    uint256 public listAuctionId;

    mapping(uint256 => Item) public list;
    mapping(uint256 => AuctionItem) public listAuction;

    function listItem(
        uint256 tokenId,
        uint256 cost,
        address tokenAddress
    ) external returns (uint256) {
        require(
            tokenAddress.code.length > 0,
            "MarketPlace: tokenAddress need to be a contract"
        );
        require(
            IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId),
            "MarketPlace: tokenAddress need to be a ERC721 implementer"
        );
        IERC721 token = IERC721(tokenAddress);
        require(
            token.ownerOf(tokenId) == msg.sender,
            "MarketPlace: you need to be an owner of token"
        );
        require(
            token.getApproved(tokenId) == address(this) ||
                token.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: you need to approve this token to marketplace"
        );
        token.transferFrom(msg.sender, address(this), tokenId);
        listId += 1;
        list[listId] = Item(tokenId, cost, tokenAddress, msg.sender);
        return listId;
    }

    function buyItem(uint256 id) external payable {
        require(
            list[id].tokenAddress != address(0),
            "MarketPlace: token is not selling"
        );
        require(
            msg.value >= list[id].cost,
            "MarketPlace: you need to send more ether than this token cost"
        );
        uint256 cost = list[id].cost;
        payable(list[id].tokenOwner).transfer(list[id].cost);
        IERC721 token = IERC721(list[id].tokenAddress);
        token.transferFrom(address(this), msg.sender, list[id].tokenId);
        delete list[id];
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function cancel(uint256 id) external {
        require(
            list[id].tokenAddress != address(0),
            "MarketPlace: token is not selling"
        );
        require(
            list[id].tokenOwner == msg.sender,
            "MarketPlace: you aren't an owner of this token"
        );
        IERC721 token = IERC721(list[id].tokenAddress);
        token.transferFrom(address(this), msg.sender, list[id].tokenId);
        delete list[id];
    }

    function listItemOnAuction(
        uint256 tokenId,
        uint256 minCost,
        address tokenAddress
    ) external returns (uint256) {
        require(
            tokenAddress.code.length > 0,
            "MarketPlace: tokenAddress need to be a contract"
        );
        require(
            IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId),
            "MarketPlace: tokenAddress need to be a ERC721 implementer"
        );
        IERC721 token = IERC721(tokenAddress);
        require(
            token.ownerOf(tokenId) == msg.sender,
            "MarketPlace: you need to be an owner of token"
        );
        require(
            token.getApproved(tokenId) == address(this) ||
                token.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: you need to approve this token to marketplace"
        );
        token.transferFrom(msg.sender, address(this), tokenId);
        listAuctionId += 1;
        listAuction[listAuctionId] = AuctionItem(
            tokenId,
            minCost,
            block.timestamp,
            0,
            tokenAddress,
            msg.sender,
            address(0)
        );
        return listAuctionId;
    }

    function makeBid(uint256 id) external payable returns (bool) {
        require(
            listAuction[id].tokenAddress != address(0),
            "MarketPlace: token is not in auction"
        );
        require(
            msg.value > listAuction[id].currentCost,
            "MarketPlace: you need to send more ether than this token bid"
        );
        require(
            block.timestamp <= listAuction[id].time + 3600,
            "MarketPlace: auction's time is 1 hour"
        );
        if (listAuction[id].lastCustomer != address(0)) {
            payable(listAuction[id].lastCustomer).transfer(
                listAuction[id].currentCost
            );
        }
        listAuction[id].lastCustomer = msg.sender;
        listAuction[id].currentCost = msg.value;
        listAuction[id].bidCount += 1;
        return true;
    }

    function finishAuction(uint256 id) external {
        require(
            listAuction[id].tokenAddress != address(0),
            "MarketPlace: token is not in auction"
        );
        require(
            block.timestamp > listAuction[id].time + 3600,
            "MarketPlace: auction's time is 1 hour"
        );
        IERC721 token = IERC721(listAuction[id].tokenAddress);
        if (listAuction[id].bidCount < 3) {
            if (listAuction[id].lastCustomer != address(0)) {
                payable(listAuction[id].lastCustomer).transfer(
                    listAuction[id].currentCost
                );
            }
            token.transferFrom(
                address(this),
                listAuction[id].tokenOwner,
                listAuction[id].tokenId
            );
        } else {
            payable(listAuction[id].tokenOwner).transfer(
                listAuction[id].currentCost
            );
            token.transferFrom(
                address(this),
                listAuction[id].lastCustomer,
                listAuction[id].tokenId
            );
        }
        delete listAuction[id];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}