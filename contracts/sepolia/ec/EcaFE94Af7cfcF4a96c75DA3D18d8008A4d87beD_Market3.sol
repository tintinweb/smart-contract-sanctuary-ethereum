// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC165/IERC165.sol";

interface IERC1155 is IERC165 {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;



    event TransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address operator,
        address from,
        address to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address account, address operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC1155.sol";

interface IERC1155mint is IERC1155 {
    function mint(
        address tokenOwner,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../ERC165/IERC165.sol";

interface IERC721 is IERC165{
    event Transfer(address from, address to, uint256 tokenId);

    event Approval(address owner, address approved, uint256 tokenId);

    event ApprovalForAll(address owner, address operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // function mint(address caller) external;
    // function name() external view returns(string memory);
    // function symbol() external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721mint is IERC721 {
    function mint(address caller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {
    struct onSaleTokens {
        address contractAddress;
        address owner;
        uint256 price;
        uint256 amount;
        bool isOnSale;
    }

    struct onAuctionTokens {
        address contractAddress;
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 baseValue;
        uint256 currentBidding;
        address currentBidder;
        bool isOnAuction;
    }

    event SaleStarted(
        address owner,
        uint256 id,
        address contractAddress,
        uint256 amount,
        uint256 price
    );

    event SaleEnded(address owner, uint256 id, address contractAddress);

    event AuctionStarted(
        address owner,
        uint256 id,
        address contractAddress,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 baseValue
    );

    event AuctionEnd(
        uint256 id,
        address contractAddress,
        address highestBidder,
        uint256 highestBidding
    );

    event AuctionCancelled(uint256 id, address contractAddress, address owner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721/IERC721.sol";
import "./ERC721/IERC721mint.sol";
import "./ERC1155/IERC1155.sol";
import "./ERC1155/IERC1155mint.sol";
import "./IMarket.sol";

contract Market3 is IMarket {
    mapping(uint256 => mapping(address => mapping(address => onSaleTokens)))
        public saleTokensInfo;
    mapping(uint256 => mapping(address => mapping(address => onAuctionTokens)))
        public auctionTokensInfo;
    mapping(uint256 => mapping(address => mapping(address => address[])))
        private bidders;
    mapping(uint256 => mapping(address => mapping(address => mapping(address => uint256))))
        private biddingAmount;
    mapping(uint256 => mapping(address => mapping(address => bool)))
        private isLocked;
    uint256 public mintPrice721;
    uint256 public mintPrice1155;

    constructor(uint256 _mintPrice721, uint256 _mintPrice1155) {
        mintPrice721 = _mintPrice721;
        mintPrice1155 = _mintPrice1155;
    }

    function isSupportERC721(address owner) private view returns (bool) {
        bytes4 IID_IERC721 = type(IERC721).interfaceId;
        return IERC165(owner).supportsInterface(IID_IERC721);
    }

    function isSupportERC1155(address owner) private view returns (bool) {
        bytes4 IID_IERC1155 = type(IERC1155).interfaceId;
        return IERC165(owner).supportsInterface(IID_IERC1155);
    }

    function _isContract(address contractAddress) private view {
        require(
            contractAddress.code.length > 0,
            "Market: invalid contract address"
        );
    }

    function _isLocked(
        uint256 id,
        address contractAddress,
        address seller
    ) private view {
        require(!isLocked[id][contractAddress][seller], "Market: token locked");
    }

    function mint(
        uint256 id,
        uint256 numberOfTokens,
        address contractAddress
    ) external payable {
        _isContract(contractAddress);
        if (isSupportERC721(contractAddress)) {
            require(msg.value == mintPrice721, "Market: send enough ether");
            IERC721mint(contractAddress).mint(msg.sender);
        } else if (isSupportERC1155(contractAddress)) {
            require(
                msg.value == mintPrice1155 * numberOfTokens,
                "Market: send enough ether"
            );
            IERC1155mint(contractAddress).mint(msg.sender, id, numberOfTokens);
        } else revert("Market: interface does not support mint");
    }

    function setSale(
        uint256 id,
        uint256 amount,
        uint256 price,
        address contractAddress
    ) external {
        _isContract(contractAddress);
        _isLocked(id, contractAddress, msg.sender);
        if (isSupportERC721(contractAddress)) {
            require(amount == 0, "Market: amount needs to be zero for erc721");
            require(
                IERC721(contractAddress).ownerOf(id) == msg.sender,
                "Market: not owner"
            );
            require(
                IERC721(contractAddress).getApproved(id) == address(this) ||
                    IERC721(contractAddress).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "Market: approve market first"
            );

            saleTokensInfo[id][contractAddress][msg.sender].amount = 0;
        } else if (isSupportERC1155(contractAddress)) {
            require(amount > 0, "Market: zero amount");
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, id) >= amount,
                "Market: not enough token"
            );
            require(
                IERC1155(contractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Market: approve market first"
            );
            saleTokensInfo[id][contractAddress][msg.sender].amount = amount;
        } else revert("Market: invalid contract address");
        saleTokensInfo[id][contractAddress][msg.sender]
            .contractAddress = contractAddress;
        saleTokensInfo[id][contractAddress][msg.sender].owner = msg.sender;
        saleTokensInfo[id][contractAddress][msg.sender].price = price;
        saleTokensInfo[id][contractAddress][msg.sender].isOnSale = true;
        isLocked[id][contractAddress][msg.sender] = true;
        emit SaleStarted(msg.sender, id, contractAddress, amount, price);
    }

    function purchase(
        uint256 id,
        address seller,
        uint256 amount,
        address contractAddress
    ) external payable {
        require(
            saleTokensInfo[id][contractAddress][seller].isOnSale,
            "Market: token not on sale"
        );
        require(msg.sender != seller, "Market: buying your token");
        if (isSupportERC721(contractAddress)) {
            require(
                msg.value == saleTokensInfo[id][contractAddress][seller].price,
                "Market: send enough ether"
            );
            IERC721(contractAddress).transferFrom(seller, msg.sender, id);
            delete saleTokensInfo[id][contractAddress][seller];
        } else if (isSupportERC1155(contractAddress)) {
            require(
                amount <= saleTokensInfo[id][contractAddress][seller].amount &&
                    amount > 0,
                "Market: not enough tokens"
            );
            require(
                msg.value ==
                    saleTokensInfo[id][contractAddress][seller].price * amount,
                "Market: send enough ether"
            );
            IERC1155(contractAddress).safeTransferFrom(
                seller,
                msg.sender,
                id,
                amount,
                "0x00"
            );
            saleTokensInfo[id][contractAddress][seller].amount -= amount;
            if (saleTokensInfo[id][contractAddress][seller].amount == 0)
                delete saleTokensInfo[id][contractAddress][seller];
        } else revert("Market: invalid contract address");
        delete isLocked[id][contractAddress][msg.sender];
        payable(seller).transfer(msg.value);
    }

    function cancelSale(uint256 id, address contractAddress) external {
        _isContract(contractAddress);
        require(
            saleTokensInfo[id][contractAddress][msg.sender].isOnSale,
            "Market: token not on sale"
        );
        delete saleTokensInfo[id][contractAddress][msg.sender];
        delete isLocked[id][contractAddress][msg.sender];
        emit SaleEnded(msg.sender, id, contractAddress);
    }

    function setAuction(
        uint256 startTime,
        uint256 endTime,
        uint256 baseValue,
        uint256 id,
        uint256 amount,
        address contractAddress
    ) external {
        _isLocked(id, contractAddress, msg.sender);
        require(
            startTime <= endTime &&
                (startTime >= block.timestamp || startTime == 0) &&
                endTime >= block.timestamp,
            "Market: invalid start or end time"
        );
        require(baseValue > 0, "Market: invalid baseValue");
        require(
            !auctionTokensInfo[id][contractAddress][msg.sender].isOnAuction,
            "Market: token on auction"
        );
        if (isSupportERC721(contractAddress)) {
            require(amount == 0, "Market: amount needs to be zero for erc721");
            require(
                msg.sender == IERC721(contractAddress).ownerOf(id),
                "Market: not token owner"
            );
            require(
                IERC721(contractAddress).getApproved(id) == address(this) ||
                    IERC721(contractAddress).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "Market: please approve contract first"
            );
            auctionTokensInfo[id][contractAddress][msg.sender].amount = 0;
        } else if (isSupportERC1155(contractAddress)) {
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, id) >= amount,
                "Market: not enough tokens"
            );
            require(
                IERC1155(contractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Market: please approve contract first"
            );
            auctionTokensInfo[id][contractAddress][msg.sender].amount = amount;
        } else revert("Market: invalid contract address");
        if (startTime == 0) startTime = block.timestamp;
        auctionTokensInfo[id][contractAddress][msg.sender].owner = msg.sender;
        auctionTokensInfo[id][contractAddress][msg.sender]
            .startTime = startTime;
        auctionTokensInfo[id][contractAddress][msg.sender].endTime = endTime;
        auctionTokensInfo[id][contractAddress][msg.sender]
            .baseValue = baseValue;
        auctionTokensInfo[id][contractAddress][msg.sender].isOnAuction = true;
        auctionTokensInfo[id][contractAddress][msg.sender].currentBidder = msg
            .sender;
        bidders[id][contractAddress][msg.sender].push(msg.sender);
        isLocked[id][contractAddress][msg.sender] = true;
        emit AuctionStarted(
            msg.sender,
            id,
            contractAddress,
            amount,
            startTime,
            endTime,
            baseValue
        );
    }

    function bid(
        uint256 id,
        address auctioner,
        uint256 bidding,
        address contractAddress
    ) external payable {
        require(
            auctionTokensInfo[id][contractAddress][auctioner].isOnAuction,
            "Market: not on auction"
        );
        require(
            block.timestamp <=
                auctionTokensInfo[id][contractAddress][auctioner].endTime &&
                block.timestamp >=
                auctionTokensInfo[id][contractAddress][auctioner].startTime,
            "Market: auction is not live"
        );
        require(msg.sender != auctioner, "Market: you can't bid");
        require(
            bidding >
                auctionTokensInfo[id][contractAddress][auctioner]
                    .currentBidding &&
                bidding >
                auctionTokensInfo[id][contractAddress][auctioner].baseValue,
            "Market: bidding value has to be more than current"
        );
        require(
            msg.value ==
                bidding -
                    biddingAmount[id][contractAddress][auctioner][msg.sender],
            "Market: invalid bidding value"
        );
        if (biddingAmount[id][contractAddress][auctioner][msg.sender] == 0) {
            bidders[id][contractAddress][auctioner].push(msg.sender);
        }
        biddingAmount[id][contractAddress][auctioner][msg.sender] = bidding;
        auctionTokensInfo[id][contractAddress][auctioner].currentBidder = msg
            .sender;
        auctionTokensInfo[id][contractAddress][auctioner]
            .currentBidding = bidding;
    }

    function cancelBid(
        uint256 id,
        address auctioner,
        address contractAddress
    ) external {
        require(
            biddingAmount[id][contractAddress][auctioner][msg.sender] != 0,
            "Market: not bidder"
        );
        uint256 amount = biddingAmount[id][contractAddress][auctioner][
            msg.sender
        ];
        biddingAmount[id][contractAddress][auctioner][msg.sender] = 0;
        if (
            msg.sender ==
            auctionTokensInfo[id][contractAddress][auctioner].currentBidder
        ) {
            uint256 testVar;
            address secondHighest;
            for (
                uint256 index = 0;
                index < bidders[id][contractAddress][auctioner].length;
                index++
            ) {
                if (
                    testVar <
                    biddingAmount[id][contractAddress][auctioner][
                        bidders[id][contractAddress][auctioner][index]
                    ]
                ) {
                    secondHighest = bidders[id][contractAddress][auctioner][
                        index
                    ];
                }
            }
            auctionTokensInfo[id][contractAddress][auctioner]
                .currentBidder = secondHighest;
            auctionTokensInfo[id][contractAddress][auctioner]
                .currentBidding = biddingAmount[id][contractAddress][auctioner][
                secondHighest
            ];
        }
        payable(msg.sender).transfer(amount);
    }

    function endAuction(uint256 id, address contractAddress) external {
        address highestBidder = auctionTokensInfo[id][contractAddress][
            msg.sender
        ].currentBidder;
        uint256 highestBidding = auctionTokensInfo[id][contractAddress][
            msg.sender
        ].currentBidding;
        if (
            block.timestamp >
            auctionTokensInfo[id][contractAddress][msg.sender].endTime
        ) {
            require(
                msg.sender ==
                    auctionTokensInfo[id][contractAddress][msg.sender].owner ||
                    msg.sender == highestBidder,
                "Market: not allowed"
            );
        } else {
            require(
                msg.sender ==
                    auctionTokensInfo[id][contractAddress][msg.sender].owner,
                "Market: not allowed"
            );
        }
        if (isSupportERC721(contractAddress)) {
            IERC721(contractAddress).transferFrom(
                msg.sender,
                highestBidder,
                id
            );
        } else if (isSupportERC1155(contractAddress)) {
            IERC1155(contractAddress).safeTransferFrom(
                msg.sender,
                highestBidder,
                id,
                auctionTokensInfo[id][contractAddress][msg.sender].amount,
                "0x00"
            );
        }
        biddingAmount[id][contractAddress][msg.sender][highestBidder] = 0;
        biddingAmount[id][contractAddress][msg.sender][
            msg.sender
        ] = highestBidding;
        delete (auctionTokensInfo[id][contractAddress][msg.sender]);
        for (
            uint256 index = 0;
            index < bidders[id][contractAddress][msg.sender].length;
            index++
        ) {
            address receiver = bidders[id][contractAddress][msg.sender][index];
            uint256 amount = biddingAmount[id][contractAddress][msg.sender][
                receiver
            ];
            delete biddingAmount[id][contractAddress][msg.sender][receiver];
            payable(receiver).transfer(amount);
        }
        delete isLocked[id][contractAddress][msg.sender];

        emit AuctionEnd(id, contractAddress, highestBidder, highestBidding);
    }
}