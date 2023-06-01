// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Erc721/IERC165.sol";

interface IERC1155 is IERC165 {
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event URI(string _value, uint256 indexed _id);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC165.sol";

interface IERC721 is IERC165 {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);

    event Transfer(address _from, address _to, uint256 _tokenId);
    event Approval(address _owner, address _approved, uint256 _tokenId);
    event ApprovalForAll(address _owner, address _operator, bool _approved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Erc1155/IERC1155.sol";

interface NewIERC1155 is IERC1155 {
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Erc721/IERC721.sol";

interface NewIERC721 is IERC721{
    function mintToken(address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUpdateMarket {
    struct AuctionDetails {
        address seller;
        address contractAddress;
        uint128 price;
        uint256 tokenId;
        uint256 amount;
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
        uint256 endTime;
    }
    struct SaleDetails {
        address seller;
        address contractAddress;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
    }
    struct Bid {
        address bidder;
        uint256 bidAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../ERCNew/NewIERC1155.sol";
import "../ERCNew/NewIERC721.sol";
import "./IUpdateMarket.sol";

contract UpdateMarket is IUpdateMarket {
    event AuctionCreated(
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    );
    event AuctionCancelled(
        address seller,
        address contractAddress,
        uint256 tokenId
    );
    event SaleCreated(
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    );
    event SaleCancelled(
        address seller,
        address contractAddress,
        uint256 tokenId
    );
    event PurchaseToken(
        address seller,
        address contractAddress,
        address to,
        uint256 tokenId,
        uint256 amount
    );
    event AuctionSuccessful(
        address highestBidder,
        uint256 tokenId,
        uint256 price
    );
    // contractAddress=>tokrnId=>sellerAddress=>AuctionDetails
    mapping(address => mapping(uint256 => mapping(address => AuctionDetails)))
        public _auctionList;
    // contractAddress=>tokrnId=>sellerAddress=>SaleDetails
    mapping(address => mapping(uint256 => mapping(address => SaleDetails)))
        public _saleList;
    // contractAddress=>tokrnId=>sellerAddress=>bids
    mapping(address => mapping(uint256 => mapping(address => Bid[])))
        private _bids;

    function isERC721(address contractAddress) private view returns (bool) {
        bytes4 IID_IERC721 = type(IERC721).interfaceId;
        return IERC165(contractAddress).supportsInterface(IID_IERC721);
    }

    function isERC1155(address contractAddress) private view returns (bool) {
        bytes4 IID_IERC1155 = type(IERC1155).interfaceId;
        return IERC165(contractAddress).supportsInterface(IID_IERC1155);
    }

    function mint(
        address to,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (isERC721(contractAddress)) {
            NewIERC721(contractAddress).mintToken(to, tokenId);
        } else if (isERC1155(contractAddress)) {
            NewIERC1155(contractAddress).mint(to, tokenId, amount);
        } else {
            revert("Market: unsupported interface");
        }
    }

    function createAuction(
        address contractAddress,
        uint128 price,
        uint256 tokenId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(price != 0, "Market: Price must be greater than zero");
        require(
            _saleList[contractAddress][tokenId][msg.sender].tokenId != tokenId,
            "Market: already on sale "
        );

        require(
            _auctionList[contractAddress][tokenId][msg.sender].seller ==
                address(0),
            "Market: nft already on auction"
        );
        require(
            startTime > block.timestamp && endTime > block.timestamp,
            "Market: Invalid time input"
        );
        require(endTime > startTime, "Market: Invalid time input");

        if (isERC721(contractAddress)) {
            require(
                msg.sender == IERC721(contractAddress).ownerOf(tokenId),
                "Market: Only owner create an auction"
            );
            require(
                IERC721(contractAddress).getApproved(tokenId) ==
                    address(this) ||
                    IERC721(contractAddress).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "Market: contract not approved"
            );
            _auctionList[contractAddress][tokenId][msg.sender] = AuctionDetails(
                msg.sender,
                contractAddress,
                price,
                tokenId,
                0,
                0,
                address(0),
                startTime,
                endTime
            );
        } else if (isERC1155(contractAddress)) {
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, tokenId) >=
                    amount,
                "Market:Insufficient balance to create auction"
            );
            require(
                IERC1155(contractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Market: contract not approved"
            );

            _auctionList[contractAddress][tokenId][msg.sender] = AuctionDetails(
                msg.sender,
                contractAddress,
                price,
                tokenId,
                amount,
                0,
                address(0),
                startTime,
                endTime
            );
        } else {
            revert("Market: wrong address");
        }
        emit AuctionCreated(
            msg.sender,
            contractAddress,
            tokenId,
            price,
            amount
        );
    }

    function createSale(
        address contractAddress,
        uint256 price,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(price > 0, "Market: Price must be greater than zero");
        require(
            _auctionList[contractAddress][tokenId][msg.sender].tokenId !=
                tokenId,
            "Market: already on auction"
        );

        require(
            _saleList[contractAddress][tokenId][msg.sender].seller ==
                address(0),
            "Market:token already on Sale"
        );
        if (isERC721(contractAddress)) {
            require(
                IERC721(contractAddress).ownerOf(tokenId) == msg.sender,
                "Market: Only owner create sale"
            );
            require(
                IERC721(contractAddress).getApproved(tokenId) ==
                    address(this) ||
                    IERC721(contractAddress).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "Market: contract not approved"
            );

            _saleList[contractAddress][tokenId][msg.sender] = SaleDetails(
                msg.sender,
                contractAddress,
                price,
                tokenId,
                0
            );
        } else if (isERC1155(contractAddress)) {
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, tokenId) >=
                    amount,
                "Market: Insufficient balance to create sale"
            );
            require(
                IERC1155(contractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Market: contract not approved"
            );

            _saleList[contractAddress][tokenId][msg.sender] = SaleDetails(
                msg.sender,
                contractAddress,
                price,
                tokenId,
                amount
            );
        } else {
            revert("Market: wrong address");
        }
        emit SaleCreated(msg.sender, contractAddress, tokenId, price, amount);
    }

    function cancelSale(address contractAddress, uint256 tokenId) external {
        require(
            _saleList[contractAddress][tokenId][msg.sender].seller ==
                msg.sender,
            "Market: only token seller"
        );

        delete _saleList[contractAddress][tokenId][msg.sender];

        emit SaleCancelled(msg.sender, contractAddress, tokenId);
    }

    function purchaseToken(
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) external payable {
        SaleDetails memory saleDetails = _saleList[contractAddress][tokenId][
            seller
        ];

        require(seller != address(0), "Market: seller zero address");
        require(saleDetails.seller != msg.sender, "Market: seller not allowed");
        require(saleDetails.tokenId == tokenId, "Market: nft not on sale");

        if (isERC721(contractAddress)) {
            require(
                msg.value == saleDetails.price,
                "Market: pay a valid ether"
            );
            delete _saleList[contractAddress][tokenId][seller];
            IERC721(contractAddress).transferFrom(
                saleDetails.seller,
                msg.sender,
                saleDetails.tokenId
            );

            payable(saleDetails.seller).transfer(msg.value);
        } else if (isERC1155(contractAddress)) {
            require(
                saleDetails.amount >= amount,
                "Market: invalid amount input"
            );
            require(
                saleDetails.price * amount == msg.value,
                "Market: pay valid ether"
            );

            saleDetails.amount -= amount;
            if (saleDetails.amount == 0) {
                delete _saleList[contractAddress][tokenId][seller];
            }
            IERC1155(contractAddress).safeTransferFrom(
                saleDetails.seller,
                msg.sender,
                saleDetails.tokenId,
                amount,
                ""
            );

            payable(saleDetails.seller).transfer(msg.value);
        } else {
            revert("Market: wrong address");
        }
        emit PurchaseToken(
            seller,
            contractAddress,
            msg.sender,
            tokenId,
            amount
        );
    }

    function placeBid(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) external payable {
        AuctionDetails memory auction = _auctionList[contractAddress][tokenId][
            seller
        ];
        require(auction.seller != msg.sender, "Market: seller not allowed");

        require(
            auction.startTime < block.timestamp &&
                auction.endTime > block.timestamp,
            "Market: Auction not active"
        );
        require(
            _auctionList[contractAddress][tokenId][seller].highestBid <
                msg.value,
            "Market:bid with more ETH"
        );

        _bids[contractAddress][tokenId][seller].push(
            Bid(msg.sender, msg.value)
        );

        _auctionList[contractAddress][tokenId][seller].highestBid = msg.value;
        _auctionList[contractAddress][tokenId][seller].highestBidder = msg
            .sender;

        emit AuctionSuccessful(
            _auctionList[contractAddress][tokenId][seller].highestBidder,
            tokenId,
            _auctionList[contractAddress][tokenId][seller].highestBid
        );
    }

    function cancelBid(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) external {
        require(
            _auctionList[contractAddress][tokenId][seller].endTime >=
                block.timestamp,
            "Market: auction is ended"
        );
        Bid[] memory bidList = _bids[contractAddress][tokenId][seller];
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == msg.sender) {
                uint256 tempBidAmount = bidList[i].bidAmount;
                address tempbidder = bidList[i].bidder;
                if (i == 0) {
                    delete _bids[contractAddress][tokenId][seller][i];
                    payable(tempbidder).transfer(tempBidAmount);
                } else if (i == bidList.length - 1) {
                    _auctionList[contractAddress][tokenId][seller]
                        .highestBid = bidList[i - 1].bidAmount;
                    _auctionList[contractAddress][tokenId][seller]
                        .highestBidder = bidList[i - 1].bidder;
                    delete _bids[contractAddress][tokenId][seller][i];
                    payable(tempbidder).transfer(tempBidAmount);
                } else {
                    delete _bids[contractAddress][tokenId][seller][i];
                    payable(tempbidder).transfer(tempBidAmount);
                }
            }
        }
    }

    function claim(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) external {
        AuctionDetails memory auctionDetails = _auctionList[contractAddress][
            tokenId
        ][seller];

        require(
            auctionDetails.tokenId == tokenId,
            "Market: nft not on auction"
        );
        require(
            auctionDetails.endTime <= block.timestamp,
            "Market: auction not ended"
        );
        require(
            msg.sender == auctionDetails.seller ||
                auctionDetails.highestBidder == msg.sender,
            "Market: you are not allowed"
        );
        _bids[contractAddress][tokenId][seller].pop();
        if (isERC721(contractAddress)) {
            delete _auctionList[contractAddress][tokenId][seller];
            payable(auctionDetails.seller).transfer(auctionDetails.highestBid);
            IERC721(contractAddress).transferFrom(
                auctionDetails.seller,
                auctionDetails.highestBidder,
                auctionDetails.tokenId
            );
            withdraw(contractAddress, tokenId, seller);
        } else if (isERC1155(contractAddress)) {
            delete _auctionList[contractAddress][tokenId][seller];
            payable(auctionDetails.seller).transfer(auctionDetails.highestBid);
            IERC1155(contractAddress).safeTransferFrom(
                auctionDetails.seller,
                auctionDetails.highestBidder,
                tokenId,
                auctionDetails.amount,
                ""
            );
            withdraw(contractAddress, tokenId, seller);
        } else {
            revert("Market: wrong address");
        }
    }

    function withdraw(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) internal {
        Bid[] memory bidList = _bids[contractAddress][tokenId][seller];

        for (uint256 i = 0; i < bidList.length; i++) {
            uint256 tempBid = bidList[i].bidAmount;
            address tempbidder = bidList[i].bidder;
            delete _bids[contractAddress][tokenId][seller][i];
            payable(tempbidder).transfer(tempBid);
        }
    }

    function cancelAuction(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) external {
        AuctionDetails memory auctiondetails = _auctionList[contractAddress][
            tokenId
        ][seller];
        require(
            auctiondetails.tokenId == tokenId,
            "Market: nft not on auction"
        );
        require(auctiondetails.seller == msg.sender, "Market: only saller");
        Bid[] memory bidList = _bids[contractAddress][tokenId][seller];
        if (bidList.length == 0) {
            delete _auctionList[contractAddress][tokenId][seller];
        } else {
            delete _auctionList[contractAddress][tokenId][seller];
            withdraw(contractAddress, tokenId, seller);
        }
    }
}