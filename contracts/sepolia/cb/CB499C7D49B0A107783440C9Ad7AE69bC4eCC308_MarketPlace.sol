// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC1155Receiver.sol";
import "./IERC1155Interface.sol";

contract ERC1155CHECK is IERC1155, IERC1155Receiver {
    // token id => (address => balance)
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // owner => (operator => yes/no)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    // token id => supply
    mapping(uint256 => uint256) public totalSupply;

    uint256 public tokenId;
    string public name;
    string public symbol;
    address public owner;

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenId = 1;
    }

    function balanceOf(
        address _owner,
        uint256 _tokenId
    ) public view returns (uint256) {
        require(_owner != address(0), "ERC1155: invalid address");
        return _balances[_tokenId][_owner];
    }

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) public view returns (uint256[] memory) {
        require(
            _owners.length == _ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        uint256[] memory balances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; i++) {
            balances[i] = balanceOf(_owners[i], _ids[i]);
        }

        return balances;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        _operatorApprovals[msg.sender][_operator] = _approved;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155Token: not authorized"
        );

        // transfer
        _transfer(_from, _to, _id, _amount);
        // safe transfer checks

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            _from,
            _to,
            _id,
            _amount,
            _data
        );
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155Token: not authorized"
        );
        require(
            _ids.length == _amounts.length,
            "ERC1155Token: length mismatch"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids[i],
                _amounts[i],
                _data
            );
            _transfer(_from, _to, _ids[i], _amounts[i]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function mintTo(address _to, uint256 _tokenId, uint256 _amount) public {
        require(owner == msg.sender, "ERC1155: not authorized");
        require(_to != address(0), "ERC1155: invalid mint address");
        require(_amount > 0, "ERC1155: amount invalid");
        require(_tokenId > 0, "ERC1155: invalid tokenId");

        uint256 tokenIdToMint;

        if (_tokenId > tokenId) {
            tokenIdToMint = tokenId;
            tokenId += 1;
        } else {
            tokenIdToMint = _tokenId;
        }

        _balances[tokenIdToMint][_to] += _amount;
        totalSupply[tokenIdToMint] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _ids,
        uint256 _amounts
    ) internal {
        require(_to != address(0), "ERC1155Token: transfer to address 0");

        uint256 id = _ids;
        uint256 amount = _amounts;

        uint256 fromBalance = _balances[id][_from];
        require(
            fromBalance >= amount,
            "ERC1155Token: insufficient balance for transfer"
        );
        _balances[id][_from] -= amount;
        _balances[id][_to] += amount;
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            if (
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    to,
                    id,
                    amount,
                    data
                ) != IERC1155Receiver.onERC1155Received.selector
            ) {
                revert("ERC1155: unsafe recevier address");
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address, address, address, uint256, uint256, bytes)"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721TokenReceiver.sol";

interface IERC721 {
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
}

contract ERC721 is IERC721, IERC721TokenReceiver {
    string public name;
    string public symbol;
    uint256 public tokenId;
    address public contractOwner;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: Invalid Address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return _owners[_tokenId];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: Not owner");
        require(_to != address(0), "ERC721: Invalid Receiver address");
        delete _tokenApprovals[_tokenId];
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: You are not allowed"
        );
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: You are not allowed"
        );
        _transfer(_from, _to, _tokenId);
        require(
            _to.code.length == 0 ||
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                ) ==
                IERC721TokenReceiver.onERC721Received.selector,
            "ERC721:unsafe recipient"
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
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

    function approve(address _to, uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "ERC721: not owner");
        require(_to!=address(0),"ERC721:invalid spender address");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator!=address(0),"ERC721:invalid spender address");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address operator)
    {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to) public {
        require(contractOwner == msg.sender, "ERC721: Only owner can mint");
        require(_to != address(0), "ERC721Token: zero address cannot be owner");
        // require(
        //     _to.code.length == 0,
        //     "ERC721Token: do not mint in contract address "
        // );
        tokenId++;
        _owners[tokenId] = _to;
        _balances[_to] += 1;
        emit Transfer(address(0), _to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC1155 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721TokenReceiver
{

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC721.sol";

contract MarketPlace {
    address public erc721;
    address public erc1155;
    address public marketOwner;

    struct tokenOnSale {
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerToken;
        address seller;
        bool isOnSale;
        bool isERC721;
    }

    struct tokenOnAuction {
        uint256 tokenId;
        uint256 quantity;
        uint256 basePricePerToken;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 maxBidAmount;
        address maxBidAddress;
        address seller;
        bool isOnAuction;
        bool isERC721;
    }
    struct bidders {
        address bidderAddress;
        uint256 biddingAmount;
        //uint256 quantity;
    }

    mapping(bool => mapping(uint256 => mapping(address => tokenOnSale)))
        public tokenOnSaleInfo;
    mapping(bool => mapping(uint256 => mapping(address => tokenOnAuction)))
        public auctionInfo;
    mapping(bool => mapping(uint256 => mapping(address => bidders[])))
        private biddingHistory;

    event SetOnSale(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerToken,
        address _seller
    );
    event Purchase(
        uint256 _tokenId,
        uint256 _quantity,
        address _sellerAddress,
        address _buyerAddress
    );
    event StopSale(uint256 _tokenId, address _owner);
    event SetAuction(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _basePricePerToken,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        address _seller
    );

    event Claim(uint256 _tokenId, address _seller, address _winner);

    event CancelAuction(uint256 _tokenId, address _owner);

    constructor(address _erc721, address _erc1155) {
        erc721 = _erc721;
        erc1155 = _erc1155;
        marketOwner = msg.sender;
    }

    function setOnSale(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerToken,
        bool _isERC721
    ) external {
        require(_pricePerToken > 0, "MarketPlace: invalid price");
        require(_quantity > 0, "MarketPlace: invalid quantity");
        require(
            !tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].isOnSale,
            "MarketPlace: Already in sale"
        );
        require(
            !auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction,
            "MarketPlace: token already in auction"
        );

        // require(!auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction,"MarketPlace: token already in auction");

        tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].tokenId = _tokenId;
        tokenOnSaleInfo[_isERC721][_tokenId][msg.sender]
            .pricePerToken = _pricePerToken;
        tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].seller = msg.sender;
        tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].isOnSale = true;
        tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].isERC721 = _isERC721;
        if (_isERC721) {
            require(
                IERC721(erc721).getApproved(_tokenId) == address(this) ||
                    IERC721(erc721).isApprovedForAll(msg.sender, address(this)),
                "MarketPlace: not approved"
            );

            tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].quantity = 1;
        } else {
            require(
                IERC1155(erc1155).isApprovedForAll(msg.sender, address(this)),
                "MarketPlace: not approved"
            );
            require(
                (IERC1155(erc1155).balanceOf(msg.sender, _tokenId)) >=
                    _quantity +
                        auctionInfo[_isERC721][_tokenId][msg.sender].quantity,
                "MarketPlace: token not avilable"
            );
            tokenOnSaleInfo[_isERC721][_tokenId][msg.sender]
                .quantity += _quantity;
        }
        emit SetOnSale(_tokenId, _quantity, _pricePerToken, msg.sender);
    }

    function purchase(
        uint256 _tokenId,
        uint256 _quantity,
        address _sellerAddress,
        bool _isERC721
    ) external payable {
        // bool _isERC721=tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].isERC721;
        require(
            tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].isOnSale,
            "MarketPlace: token not on sale"
        );
        require(
            msg.sender !=
                tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].seller,
            "MarketPlace: you are the seller"
        );
        require(
            msg.value ==
                _quantity *
                    tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress]
                        .pricePerToken,
            "MarketPlace: invalid price"
        );
        require(
            _quantity <=
                tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].quantity,
            "MarketPlace: insufficient token"
        );

        if (tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].isERC721) {
            //require(_quantity == 1, "MarketPlace: only one token in sale");

            IERC721(erc721).transferFrom(
                tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].seller,
                msg.sender,
                _tokenId
            );
            delete tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress];
        } else {
            IERC1155(erc1155).safeTransferFrom(
                tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].seller,
                msg.sender,
                _tokenId,
                _quantity,
                bytes("Purchased")
            );
            tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress]
                .quantity -= _quantity;
            if (
                tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress].quantity ==
                0
            ) {
                delete tokenOnSaleInfo[_isERC721][_tokenId][_sellerAddress];
            }
        }
        emit Purchase(_tokenId, _quantity, _sellerAddress, msg.sender);
    }

    function cancelSale(uint256 _tokenId, bool _isERC721) external {
        require(
            tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].isOnSale,
            "MarketPlace: not on sale"
        );
        delete tokenOnSaleInfo[_isERC721][_tokenId][msg.sender];
        emit StopSale(_tokenId, msg.sender);
    }

    function tokenOnAuctionInfo(
        uint256 _tokenId,
        bool _isERC721
    ) external view returns (tokenOnAuction memory) {
        require(
            auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction,
            "MarketPlace: token not in Auction"
        );
        return (auctionInfo[_isERC721][_tokenId][msg.sender]);
    }

    function Bidders(
        uint256 _tokenId,
        bool _isERC721
    ) external view returns (bidders[] memory) {
        bidders[] memory arrayBideers = biddingHistory[_isERC721][_tokenId][
            msg.sender
        ];
        return arrayBideers;
    }

    function setAuction(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _basePricePerToken,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        bool _isERC721
    ) external {
        require(
            !auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction,
            "MarketPlace: token already in Auction"
        );
        require(
            !tokenOnSaleInfo[_isERC721][_tokenId][msg.sender].isOnSale,
            "MarketPlace: token already in sale"
        );
        require(
            _basePricePerToken > 0,
            "MarketPlace: base price should postive"
        );
        require(_quantity > 0, "MarketPlace: quantity should positive");
        // require(
        //     _auctionEndTime > block.timestamp,
        //     "MarketPlace: invalid end time"
        // );
        require(
            _auctionStartTime > block.timestamp &&
                _auctionEndTime > _auctionStartTime,
            "MarketPlace: invalid time"
        );

        if (_isERC721) {
            require(
                msg.sender == ERC721(erc721).ownerOf(_tokenId),
                "MarketPlace: not token owner"
            );
            require(
                IERC721(erc721).getApproved(_tokenId) == address(this),
                "MarketPlace: not approved"
            );

            auctionInfo[_isERC721][_tokenId][msg.sender].quantity = 1;
        } else {
            require(
                IERC1155(erc1155).balanceOf(msg.sender, _tokenId) >= _quantity,
                "MarketPlace: not enough tokens"
            );
            require(
                IERC1155(erc1155).isApprovedForAll(msg.sender, address(this)),
                "MarketPlace: not approved"
            );
            // require(
            //     (IERC1155(erc1155).balanceOf(msg.sender, _tokenId)) >=
            //         _quantity +
            //             tokenOnSaleInfo[_isERC721][_tokenId][msg.sender]
            //                 .quantity,
            //     "MarketPlace: token not avilable "
            // );
            auctionInfo[_isERC721][_tokenId][msg.sender].quantity += _quantity;
        }
        auctionInfo[_isERC721][_tokenId][msg.sender].tokenId = _tokenId;
        auctionInfo[_isERC721][_tokenId][msg.sender]
            .basePricePerToken = _basePricePerToken;
        auctionInfo[_isERC721][_tokenId][msg.sender]
            .auctionStartTime = _auctionStartTime;
        auctionInfo[_isERC721][_tokenId][msg.sender]
            .auctionEndTime = _auctionEndTime;
        auctionInfo[_isERC721][_tokenId][msg.sender].seller = msg.sender;
        auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction = true;
        auctionInfo[_isERC721][_tokenId][msg.sender].isERC721 = _isERC721;
        emit SetAuction(
            _tokenId,
            _quantity,
            _basePricePerToken,
            _auctionStartTime,
            _auctionEndTime,
            msg.sender
        );
    }

    function bid(
        uint256 _tokenId,
        address _seller,
        bool _isERC721
    ) external payable {
        require(
            auctionInfo[_isERC721][_tokenId][_seller].isOnAuction,
            "MarketPlace: token not in Auction"
        );
        require(
            block.timestamp <=
                auctionInfo[_isERC721][_tokenId][_seller].auctionEndTime,
            "MarketPlace: auction is over"
        );
        require(
            msg.value >=
                auctionInfo[_isERC721][_tokenId][_seller].basePricePerToken,
            "MarketPlace: value should greater then base price"
        );
        require(
            msg.value > auctionInfo[_isERC721][_tokenId][_seller].maxBidAmount,
            "MarketPlace: bidding amount is not the highest"
        );
        biddingHistory[_isERC721][_tokenId][_seller].push(
            bidders(msg.sender, msg.value)
        );
        auctionInfo[_isERC721][_tokenId][_seller].maxBidAmount = msg.value;
        auctionInfo[_isERC721][_tokenId][_seller].maxBidAddress = msg.sender;
    }

    function claimToken(
        uint256 _tokenId,
        address _seller,
        bool _isERC721
    ) external {
        require(
            auctionInfo[_isERC721][_tokenId][_seller].isOnAuction,
            "MarketPlace: token not in auction"
        );
        require(
            block.timestamp >
                auctionInfo[_isERC721][_tokenId][_seller].auctionEndTime,
            "MarketPlace: auction is not over"
        );
        require(
            auctionInfo[_isERC721][_tokenId][_seller].maxBidAddress !=
                address(0),
            "MarketPlace: no one bidded"
        );
        require(
            msg.sender ==
                auctionInfo[_isERC721][_tokenId][_seller].maxBidAddress,
            "MarketPlace: only winner can access"
        );
        for (
            uint256 index;
            index < biddingHistory[_isERC721][_tokenId][_seller].length;
            index++
        ) {
            if (
                biddingHistory[_isERC721][_tokenId][_seller][index]
                    .bidderAddress ==
                msg.sender &&
                IERC1155(erc1155).isApprovedForAll(_seller, address(this)) &&
                IERC1155(erc1155).balanceOf(
                    auctionInfo[_isERC721][_tokenId][_seller].seller,
                    _tokenId
                ) >=
                auctionInfo[_isERC721][_tokenId][_seller].quantity
            ) {
                IERC1155(erc1155).safeTransferFrom(
                    auctionInfo[_isERC721][_tokenId][_seller].seller,
                    msg.sender,
                    _tokenId,
                    auctionInfo[_isERC721][_tokenId][_seller].quantity,
                    "0x00"
                );
            } else {
                payable(
                    biddingHistory[_isERC721][_tokenId][_seller][index]
                        .bidderAddress
                ).transfer(
                        biddingHistory[_isERC721][_tokenId][_seller][index]
                            .biddingAmount
                    );
            }
        }
        payable(_seller).transfer(
            auctionInfo[_isERC721][_tokenId][_seller].maxBidAmount
        );
        delete auctionInfo[_isERC721][_tokenId][_seller];
        delete biddingHistory[_isERC721][_tokenId][_seller];
        emit Claim(_tokenId, _seller, msg.sender);
    }

    function cancelAuction(uint256 _tokenId, bool _isERC721) external {
        require(
            auctionInfo[_isERC721][_tokenId][msg.sender].isOnAuction,
            "MarketPlace: token not in auction"
        );
        require(
            block.timestamp <
                auctionInfo[_isERC721][_tokenId][msg.sender].auctionEndTime,
            "MarketPlace: auction is over"
        );

        for (
            uint256 index;
            index < biddingHistory[_isERC721][_tokenId][msg.sender].length;
            index++
        ) {
            payable(
                biddingHistory[_isERC721][_tokenId][msg.sender][index]
                    .bidderAddress
            ).transfer(
                    biddingHistory[_isERC721][_tokenId][msg.sender][index]
                        .biddingAmount
                );
        }
        delete auctionInfo[_isERC721][_tokenId][msg.sender];
        delete biddingHistory[_isERC721][_tokenId][msg.sender];
        emit CancelAuction(_tokenId, msg.sender);
    }

    function cancelBid(
        uint256 _tokenId,
        bool _isERC721,
        address _seller
    ) external {
        require(
            auctionInfo[_isERC721][_tokenId][_seller].isOnAuction,
            "ERC721Auction: token not in Auction bid"
        );
        uint256 tempBidAmount;
        address tempAddress;
        uint256 tempMaxBidAmount;
        address tempMaxAddress;
        for (
            uint256 index;
            index < biddingHistory[_isERC721][_tokenId][_seller].length;
            index++
        ) {
            if (
                biddingHistory[_isERC721][_tokenId][_seller][index]
                    .bidderAddress == msg.sender
            ) {
                tempBidAmount = biddingHistory[_isERC721][_tokenId][_seller][
                    index
                ].biddingAmount;
                tempAddress = biddingHistory[_isERC721][_tokenId][_seller][
                    index
                ].bidderAddress;
                biddingHistory[_isERC721][_tokenId][_seller][index]
                    .bidderAddress = address(0);
                biddingHistory[_isERC721][_tokenId][_seller][index]
                    .biddingAmount = 0;
            } else {
                if (
                    biddingHistory[_isERC721][_tokenId][_seller][index]
                        .biddingAmount > tempMaxBidAmount
                ) {
                    tempMaxBidAmount = biddingHistory[_isERC721][_tokenId][
                        _seller
                    ][index].biddingAmount;
                    tempMaxAddress = biddingHistory[_isERC721][_tokenId][
                        _seller
                    ][index].bidderAddress;
                }
            }
            payable(tempAddress).transfer(tempBidAmount);
            auctionInfo[_isERC721][_tokenId][_seller]
                .maxBidAmount = tempMaxBidAmount;
            auctionInfo[_isERC721][_tokenId][_seller]
                .maxBidAddress = tempMaxAddress;
        }
    }
}