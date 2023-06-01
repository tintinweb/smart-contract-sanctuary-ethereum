// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
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

    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC721 {
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

    function approve(address _to, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC1155.sol";

interface IMarket is IERC721 {
    function mint(address to) external;
}

interface IMarket1155 is IERC1155 {
    function mint(address to, uint tokenId, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC165.sol";
import "./IMarket.sol";

contract Market {
    struct SaleDetails {
        uint256 tokenId;
        address contractAddress;
        uint256 price;
        address ownerAddress;
        uint256 quantity;
    }

    struct AuctionDetails {
        uint256 tokenId;
        address contractAddress;
        uint256 price;
        address ownerAddress;
        uint256 quantity;
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint256) bidderDetails;
        uint256 highPrice;
        address[] higestAddress;
    }

    address _owner;
    // address _erc721;
    // address _erc1155;
    string public name;
    string public symbol;

    // id -> ownerAddress -> contractAddress -> StructDetails
    mapping(uint256 => mapping(address => mapping(address => SaleDetails)))
        public _saleDetails;

    //     // id -> ownerAddress -> contractAddress -> AuctionDetails
    mapping(uint256 => mapping(address => mapping(address => AuctionDetails)))
        public _auctionDetails;

    event Sale(
        uint256 indexed id,
        address indexed sellerAddress,
        address contractAddress,
        uint256 indexed quantity
    );

    event Buy(
        uint256 indexed id,
        address indexed sellerAddress,
        address indexed buyerAddress,
        address contractAddress,
        uint256 quantity
    );

    event Auction(
        uint256 indexed id,
        address indexed seller,
        address contractAddress,
        uint256 indexed quantity
    );

    event Bid(
        uint256 indexed tokenId,
        address indexed bidderAddress,
        address contractAddress,
        uint256 indexed quantity
    );

    event CancleBid(
        uint256 indexed tokenId,
        address indexed bidderAddress,
        address contractAddress,
        uint256 quantity,
        uint256 indexed bidderAmount
    );

    event CancleAuction(
        uint256 indexed tokenId,
        address indexed ownerAddress,
        address contractAddress,
        uint256 indexed quantity
    );

    event Claim(
        uint256 indexed tokenId,
        address indexed ownerAddress,
        address indexed bidderAddress,
        address contractAddress,
        uint256 quantity
    );

    constructor(string memory mName, string memory mSymbol) {
        _owner = msg.sender;
        name = mName;
        symbol = mSymbol;
    }

    function transferOwner(address newOwner) external {
        require(msg.sender == _owner, "Market: only owner can change");
        _owner = newOwner;
    }

    function itemSaleDetail(
        uint256 id,
        address contractAddresss,
        address salerAddress
    ) external view returns (SaleDetails memory) {
        return _saleDetails[id][salerAddress][contractAddresss];
    }

    function mint(
        uint256 tokenId,
        uint256 quantity,
        address contractAddress
    ) external {
        if (_isERC721(contractAddress)) {
            IMarket(contractAddress).mint(msg.sender);
            // _erc721.mint(msg.sender);
        } else if (_isERC1155(contractAddress)) {
            require(
                tokenId > 0 && quantity > 0,
                "Market: id or quantity must be greater then zero"
            );
            IMarket1155(contractAddress).mint(msg.sender, tokenId, quantity);
        } else {
            revert("Market: mint not allowed");
        }
    }

    function sale(
        uint256 tokenId,
        address contractAddress,
        uint256 quantity,
        uint256 price
    ) external {
        require(tokenId > 0 && price > 0, "Market: invalid value");
        _saleOrAuction(tokenId, contractAddress, msg.sender, quantity);
        SaleDetails memory saleDetail = _saleDetails[tokenId][msg.sender][
            contractAddress
        ];
        if (_isERC721(contractAddress)) {
            require(
                msg.sender == IERC721(contractAddress).ownerOf(tokenId),
                "Market: not owner"
            );
            _isApproved721(tokenId, contractAddress);
            quantity = 0;
        } else if (_isERC1155(contractAddress)) {
            _ERC1155BalanceApprov(
                msg.sender,
                tokenId,
                quantity + saleDetail.quantity,
                contractAddress
            );
            quantity += saleDetail.quantity;
        } else {
            revert("Market: support interface not allowed");
        }
        _saleDetails[tokenId][msg.sender][contractAddress] = SaleDetails(
            tokenId,
            contractAddress,
            price,
            msg.sender,
            quantity
        );
        emit Sale(tokenId, msg.sender, contractAddress, quantity);
    }

    function buy(
        uint256 tokenId,
        address contractAddress,
        uint256 quantity,
        address ownerAddress
    ) external payable {
        SaleDetails memory saleDetail = _saleDetails[tokenId][ownerAddress][
            contractAddress
        ];
        require(saleDetail.ownerAddress != address(0), "Market: not for sale");

        if (_isERC721(contractAddress)) {
            require(
                msg.sender != IERC721(contractAddress).ownerOf(tokenId),
                "Market: owner not allowed"
            );
            require(msg.value == saleDetail.price, "Market: enter exact price");
            _isApproved721(tokenId, contractAddress);
            delete _saleDetails[tokenId][ownerAddress][contractAddress];
            IERC721(contractAddress).transferFrom(
                saleDetail.ownerAddress,
                msg.sender,
                tokenId
            );
        } else if (_isERC1155(contractAddress)) {
            require(
                saleDetail.quantity >= quantity,
                "Market: not enough quantity"
            );
            require(
                msg.value == saleDetail.price * quantity,
                "Market: invalid amount"
            );
            _ERC1155BalanceApprov(
                saleDetail.ownerAddress,
                tokenId,
                quantity,
                contractAddress
            );
            IERC1155(contractAddress).safeTransferFrom(
                saleDetail.ownerAddress,
                msg.sender,
                tokenId,
                quantity,
                ""
            );
            _saleDetails[tokenId][ownerAddress][contractAddress]
                .quantity -= quantity;

            if (
                _saleDetails[tokenId][ownerAddress][contractAddress].quantity ==
                0
            ) {
                delete _saleDetails[tokenId][ownerAddress][contractAddress];
            }
        } else {
            revert("Market: support interface not allowed");
        }
        payable(saleDetail.ownerAddress).transfer(msg.value);
        emit Buy(
            tokenId,
            saleDetail.ownerAddress,
            msg.sender,
            contractAddress,
            quantity
        );
    }

    function auction(
        uint256 tokenId,
        address contractAddress,
        uint256 quantity,
        uint256 basePrice,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(basePrice > 0, "Market: invalid price");
        require(
            endTime > startTime && startTime > block.timestamp,
            "Market: invalid time"
        );
        _saleOrAuction(tokenId, contractAddress, msg.sender, quantity);
        if (_isERC721(contractAddress)) {
            // require(
            //     _auctionDetails[tokenId][msg.sender][contractAddress]
            //         .ownerAddress == address(0),
            //     "Market: already on auction"
            // );
            _isApproved721(tokenId, contractAddress);
            require(
                msg.sender == IERC721(contractAddress).ownerOf(tokenId),
                "Market: owner is different"
            );
            quantity = 0;
        } else if (_isERC1155(contractAddress)) {
            require(quantity > 0, "Market: invalid quantity");
            _ERC1155BalanceApprov(
                msg.sender,
                tokenId,
                quantity,
                contractAddress
            );
        } else {
            revert("Market: support interface not allowed");
        }
        _auctionDetails[tokenId][msg.sender][contractAddress].tokenId = tokenId;
        _auctionDetails[tokenId][msg.sender][contractAddress].ownerAddress = msg
            .sender;
        _auctionDetails[tokenId][msg.sender][contractAddress]
            .contractAddress = contractAddress;
        _auctionDetails[tokenId][msg.sender][contractAddress].price = basePrice;
        _auctionDetails[tokenId][msg.sender][contractAddress]
            .quantity = quantity;
        _auctionDetails[tokenId][msg.sender][contractAddress]
            .startTime = startTime;
        _auctionDetails[tokenId][msg.sender][contractAddress].endTime = endTime;
        emit Auction(tokenId, msg.sender, contractAddress, quantity);
    }

    function placeBid(
        uint256 tokenId,
        address contractAddress,
        address ownerAddress
    ) external payable {
        AuctionDetails storage auctionDetail = _auctionDetails[tokenId][
            ownerAddress
        ][contractAddress];
        require(
            tokenId == auctionDetail.tokenId,
            "Market: not avaible for auction"
        );
        _checkTime(auctionDetail.endTime, "Market: auction is end");
        require(
            msg.sender != auctionDetail.ownerAddress,
            "Market: owner can't place bid"
        );
        require(
            msg.value >= auctionDetail.price &&
                msg.value > auctionDetail.highPrice,
            "Market: low bid not allowed"
        );
        _auctionDetails[tokenId][ownerAddress][contractAddress]
            .higestAddress
            .push(msg.sender);
        if (auctionDetail.bidderDetails[msg.sender] > 0) {
            payable(msg.sender).transfer(
                auctionDetail.bidderDetails[msg.sender]
            );
        }
        auctionDetail.bidderDetails[msg.sender] = msg.value;
        auctionDetail.highPrice = msg.value;
        emit Bid(tokenId, msg.sender, contractAddress, auctionDetail.quantity);
    }

    function cancleBid(
        uint256 tokenId,
        address contractAddress,
        address ownerAddress
    ) external {
        AuctionDetails storage auctionDetail = _auctionDetails[tokenId][
            ownerAddress
        ][contractAddress];
        require(
            auctionDetail.ownerAddress != address(0),
            "Market: not for auction"
        );
        _checkTime(auctionDetail.endTime, "Market: not for auction");
        require(
            auctionDetail.bidderDetails[msg.sender] > 0,
            "Market: not bidder"
        );
        uint256 len = auctionDetail.higestAddress.length - 1;
        uint256 index;
        uint256 returnAmount;
        if (msg.sender == auctionDetail.higestAddress[len]) {
            address prvAdr;
            if (len > 0) {
                prvAdr = auctionDetail.higestAddress[len - 1];
            }
            _auctionDetails[tokenId][ownerAddress][contractAddress]
                .higestAddress
                .pop();
            auctionDetail.highPrice = auctionDetail.bidderDetails[prvAdr];
        } else {
            for (
                index = 0;
                index < auctionDetail.higestAddress.length;
                index++
            ) {
                if (msg.sender == auctionDetail.higestAddress[index]) {
                    _auctionDetails[tokenId][ownerAddress][contractAddress]
                        .higestAddress[index] = address(0);
                    break;
                }
            }
        }
        returnAmount = auctionDetail.bidderDetails[msg.sender];
        delete auctionDetail.bidderDetails[msg.sender];
        payable(msg.sender).transfer(returnAmount);
        emit CancleBid(
            tokenId,
            msg.sender,
            contractAddress,
            auctionDetail.quantity,
            returnAmount
        );
    }

    function cancleAuction(uint256 tokenId, address contractAddress) external {
        AuctionDetails storage auctionDetail = _auctionDetails[tokenId][
            msg.sender
        ][contractAddress];
        require(
            auctionDetail.ownerAddress != address(0),
            "Market: not for auction"
        );
        // require(
        //     msg.sender == auctionDetail.ownerAddress,
        //     "Market: owner is differnet"
        // );
        _checkTime(auctionDetail.endTime, "Market: cancle auction not allowed");
        for (
            uint256 index = 0;
            index < auctionDetail.higestAddress.length;
            index++
        ) {
            address biderAddress = auctionDetail.higestAddress[index];
            uint256 returnAmount = auctionDetail.bidderDetails[biderAddress];
            auctionDetail.bidderDetails[biderAddress] = 0;
            // _transferERC20(biderAddress, returnAmount);
            payable(biderAddress).transfer(returnAmount);
        }
        delete _auctionDetails[tokenId][msg.sender][contractAddress];
        emit CancleAuction(
            tokenId,
            msg.sender,
            contractAddress,
            auctionDetail.quantity
        );
    }

    function claim(
        uint256 tokenId,
        address contractAddress,
        address ownerAddress
    ) external {
        AuctionDetails storage auctionDetail = _auctionDetails[tokenId][
            ownerAddress
        ][contractAddress];
        require(
            tokenId == auctionDetail.tokenId,
            "Market: claim id not allowed"
        );
        require(
            auctionDetail.bidderDetails[msg.sender] > 0,
            "Market: not a bidder"
        );
        uint256 len = auctionDetail.higestAddress.length - 1;
        require(
            msg.sender == auctionDetail.higestAddress[len],
            "Auction: not higest bidder"
        );
        require(
            block.timestamp > auctionDetail.endTime,
            "Auction: auction is running"
        );
        if (_isERC721(contractAddress)) {
            _isApproved721(tokenId, contractAddress);
            IERC721(contractAddress).transferFrom(
                auctionDetail.ownerAddress,
                msg.sender,
                tokenId
            );
        } else if (_isERC1155(contractAddress)) {
            _ERC1155BalanceApprov(
                auctionDetail.ownerAddress,
                tokenId,
                auctionDetail.quantity,
                contractAddress
            );
            IERC1155(contractAddress).safeTransferFrom(
                auctionDetail.ownerAddress,
                msg.sender,
                tokenId,
                auctionDetail.quantity,
                ""
            );
        } else {
            revert("Market: support interface not allowed");
        }

        if (len > 0) {
            for (uint256 index = 0; index < len - 1; index++) {
                uint256 returnAmount = auctionDetail.bidderDetails[
                    auctionDetail.higestAddress[index]
                ];
                auctionDetail.bidderDetails[
                    auctionDetail.higestAddress[index]
                ] = 0;

                payable(auctionDetail.higestAddress[index]).transfer(
                    returnAmount
                );
            }
        }

        payable(auctionDetail.ownerAddress).transfer(
            auctionDetail.bidderDetails[auctionDetail.higestAddress[len]]
        );
        delete _auctionDetails[tokenId][ownerAddress][contractAddress];
        emit Claim(
            tokenId,
            msg.sender,
            ownerAddress,
            contractAddress,
            auctionDetail.quantity
        );
    }

    function cancleSale(uint256 tokenId, address contractAddress) external {
        SaleDetails memory saleDetail = _saleDetails[tokenId][msg.sender][
            contractAddress
        ];
        require(saleDetail.ownerAddress != address(0), "Market: not on a Sale");
        require(msg.sender == saleDetail.ownerAddress, "Market: not owner");
        delete _saleDetails[tokenId][msg.sender][contractAddress];
    }

    function _checkTime(uint256 endTime, string memory ans) private view {
        require(endTime > block.timestamp, ans);
    }

    function _saleOrAuction(
        uint256 id,
        address contractAddress,
        address msgSender,
        uint256 quantity
    ) private view {
        if (_isERC721(contractAddress)) {
            require(
                _auctionDetails[id][msgSender][contractAddress].ownerAddress ==
                    address(0) &&
                    _saleDetails[id][msgSender][contractAddress].ownerAddress ==
                    address(0),
                "Market: sale or auction is not allowed"
            );
        } else {
            require(
                IERC1155(contractAddress).balanceOf(msgSender, id) >=
                    (_auctionDetails[id][msgSender][contractAddress].quantity +
                        _saleDetails[id][msgSender][contractAddress].quantity) +
                        quantity,
                "Market: balance is low for sale or auction"
            );
        }
    }

    function _isERC721(address nftAddress) public view returns (bool) {
        bytes4 IID_ERC721 = type(IERC721).interfaceId;
        return IERC165(nftAddress).supportInterface(IID_ERC721);
    }

    function _isERC1155(address nftAddress) public view returns (bool) {
        bytes4 IID_ERC1155 = type(IERC1155).interfaceId;
        return IERC165(nftAddress).supportInterface(IID_ERC1155);
    }

    function _isApproved721(uint256 id, address contractAddress) private view {
        require(
            address(this) == IERC721(contractAddress).getApproved(id),
            "Market: not approved by token owner"
        );
    }

    function _ERC1155BalanceApprov(
        address msgSender,
        uint256 id,
        uint256 checkAmount,
        address contractAddress
    ) private view {
        require(
            IERC1155(contractAddress).balanceOf(msgSender, id) >= checkAmount,
            "Market: not have enough balance "
        );
        require(
            IERC1155(contractAddress).isApprovedForAll(
                msgSender,
                address(this)
            ),
            "Market: approval revoke"
        );
    }
}