// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721TokenReceiver.sol";

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

    function approve(address _approved, uint256 _tokenId) external;

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

contract ERC721Token is IERC721TokenReceiver, IERC721 {
    uint256 public nextTokenIDMint;
    address public contractOwner;

    //tokenid => owner
    mapping(uint256 => address) owner;

    //owner =>tokenBalance
    mapping(address => uint256) balance;

    //tokenid => approvedAdress
    mapping(uint256 => address) tokenApprovals;

    //owner =>(operator=> true/false)
    mapping(address => mapping(address => bool)) operatorApproval;

    constructor() {
        nextTokenIDMint = 0;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721Token: invalid address");
        return balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return owner[_tokenId];
    }

    function mint(address _to) public {
        require(_to != address(0), "ERC721Token: invalid address");
        owner[nextTokenIDMint] = _to;
        balance[_to] += 1;
        nextTokenIDMint += 1;
        emit Transfer(address(0), _to, nextTokenIDMint);
    }

    function burn(uint256 _tokenId) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ERC721Token: You're not the token owner"
        );

        balance[msg.sender] -= 1;
        nextTokenIDMint -= 1;
        emit Transfer(msg.sender, address(0), _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address, address, uint256, bytes)")
            );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                tokenApprovals[_tokenId] == msg.sender ||
                operatorApproval[ownerOf(_tokenId)][msg.sender],
            "ERC721Token: token owner doesn't match"
        );
        transfer(_from, _to, _tokenId);

        require(
            _to.code.length == 0 ||
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                ) ==
                IERC721TokenReceiver.onERC721Received.selector,
            "ERC721Token: unsafe recepient"
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(
            ownerOf(_tokenId) == msg.sender ||
                tokenApprovals[_tokenId] == msg.sender ||
                operatorApproval[ownerOf(_tokenId)][msg.sender],
            "ERC721Token: token owner doesn't match"
        );
        transfer(_from, _to, _tokenId);
    }

    function transfer(address _from, address _to, uint256 _tokenId) internal {
        require(
            ownerOf(_tokenId) == _from,
            "ERC721Token: token owner doesn't match"
        );
        require(_to != address(0), "ERC721Token: unsafe recepient");

        delete tokenApprovals[_tokenId];

        balance[_from] -= 1;
        balance[_to] += 1;
        owner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ERC721Token: token owner doesn't match"
        );
        tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
pragma solidity ^0.8.18;

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
pragma solidity ^0.8.18;

import "./ERC1155Receiver.sol";

interface IERC1155Token {
    function balanceOf(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256);
    
     function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _tokenIds
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _account, address _operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

contract ERC1155Tokens is IERC1155Token, IERC1155Receiver {
    // token id => (address => balance)
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // owner => (operator => yes/no)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // token id => supply
    mapping(uint256 => uint256) public totalSupply;

    uint256 public nextTokenIdToMint;
    string public name;
    string public symbol;
    address public owner;

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        nextTokenIdToMint = 0;
    }

    function balanceOf(address _owner, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_owner != address(0), "ERC1155Token: invalid address");
        return _balances[_tokenId][_owner];
    }

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _tokenIds
    ) public view returns (uint256[] memory) {
        require(
            _accounts.length == _tokenIds.length,
            "ERC1155Token: accounts id length mismatch"
        );
        // create an array dynamically
        uint256[] memory balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = balanceOf(_accounts[i], _tokenIds[i]);
        }

        return balances;
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
    }

    function isApprovedForAll(address _account, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_account][_operator];
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
        transfer(_from, _to, _id, _amount);
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
            transfer(_from, _to, _ids[i], _amounts[i]);
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids[i],
                _amounts[i],
                _data
            );
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        

        uint256 tokenIdToMint;

        if (_tokenId > nextTokenIdToMint) {
            require(
                _tokenId == nextTokenIdToMint+1,
                "ERC1155Token: invalid tokenId"
            );
            tokenIdToMint = nextTokenIdToMint;
            nextTokenIdToMint += 1;
        } else {
            tokenIdToMint = _tokenId;
        }

        _balances[tokenIdToMint][_to] += _amount;
        totalSupply[tokenIdToMint] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }

    // INTERNAL FUNCTIONS

    function transfer(
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
        require(
            to.code.length == 0 ||
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    to,
                    id,
                    amount,
                    data
                ) ==
                IERC1155Receiver.onERC1155Received.selector,
            "ERC1155Token: unsafe recepient"
        );
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
pragma solidity ^0.8.18;

interface ITokenMarketPlace {
    struct TokenOnSale {
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 tokenPrice;
        bool isOnSale;
        uint256 tokenType;
    }

    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool activeAuction;
    }

    struct Bidders {
        address bidderAddr;
        uint256 priceBid;
    }

    event SaleSet(
        address seller,
        uint256 tokenId,
        uint256 tokenPrice,
        uint256 quantity
    );
    event TokenPurchased(
        address buyer,
        uint256 tokenId,
        uint256 quantity,
        address tokenSeller
    );
    event AuctionCreated(
        address seller,
        uint256 tokenId,
        uint256 quantity,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime
    );
    event BidPlaced(
        address bidder,
        uint256 tokenId,
        address tokenSeller,
        uint256 bidAmount
    );
    event SaleEnded(address seller, uint256 tokenId);
    event AuctionEnded(address seller, uint256 tokenId);
    event TokenClaimed(
        address highestBidder,
        uint256 tokenId,
        address tokenSeller,
        uint256 highestBid
    );
    event BidCancelation(
        address BidCanceler,
        uint256 tokenId,
        address tokenSeller
    );

    function setOnSale(
        uint256 _tokenId,
        uint256 _tokenPrice,
        uint256 _quantity,
        uint256 _tokenType
    ) external;

    function buy(
        uint256 _tokenId,
        uint256 _tokenType,
        uint256 _quantity,
        address _sellerAddress
    ) external payable;

    function stopSale(uint256 _tokenId, uint256 _tokenType) external;

    function createAuction(
        uint256 _tokenType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _duration
    ) external;

    function placeBid(
        uint256 _tokenId,
        uint256 _tokenType,
        address _tokenSeller
    ) external payable;

    function cancelAuction(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external;

    function claimToken(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external;

    function cancelBid(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../ERC721/ERC721Token.sol";
import "./ERC1155Tokens.sol";
import "./ITokenMarketPlace.sol";

contract TokenMarketPlace is ITokenMarketPlace {
    address public erc1155;
    address public erc721;

    mapping(uint256 => mapping(uint256 => mapping(address => TokenOnSale)))
        public tokenSale;

    mapping(uint256 => mapping(uint256 => mapping(address => Auction)))
        public auction;
    mapping(uint256 => mapping(uint256 => mapping(address => Bidders[])))
        private bidder;
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private bidderAmounts;

    constructor(address _erc721, address _erc1155) {
        erc721 = _erc721;
        erc1155 = _erc1155;
    }

    function mint(
        uint256 _tokenType,
        uint256 _tokenId,
        uint256 _quantity
    ) public {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(_quantity > 0, "TokenMarketPlace: Tokens cannot be zero");
        if (_tokenType == 0) {
            _quantity = 1;
            ERC721Token(erc721).mint(msg.sender);
            _tokenId = ERC721Token(erc721).nextTokenIDMint() - 1;
        } else {
            IERC1155Token(erc1155).mint(msg.sender, _tokenId, _quantity);
        }
    }

    function setOnSale(
        uint256 _tokenId,
        uint256 _tokenPrice,
        uint256 _quantity,
        uint256 _tokenType
    ) public {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(_tokenPrice > 0, "TokenMarketPlace: invalid price");
        require(
            !auction[_tokenType][_tokenId][msg.sender].activeAuction,
            "TokenMarketPlace: There is a active auction"
        );
        require(
            !tokenSale[_tokenType][_tokenId][msg.sender].isOnSale,
            "TokenMarketPlace: token already on Sale"
        );
        if (_tokenType == 0) {
            _quantity = 1;
            require(
                ERC721Token(erc721).ownerOf(_tokenId) == msg.sender,
                "TokenMarketPlace: not token owner"
            );

            require(
                ERC721Token(erc721).getApproved(_tokenId) == address(this) ||
                    ERC721Token(erc721).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "TokenMarketPlace: not approved"
            );
        } else {
            require(_quantity > 0, "TokenMarketPlace: invalid quantity");

            require(
                IERC1155Token(erc1155).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "TokenMarketPlace: not approved"
            );
        }
        tokenSale[_tokenType][_tokenId][msg.sender].tokenPrice = _tokenPrice;
        tokenSale[_tokenType][_tokenId][msg.sender].quantity += _quantity;
        tokenSale[_tokenType][_tokenId][msg.sender].seller = msg.sender;
        tokenSale[_tokenType][_tokenId][msg.sender].isOnSale = true;
        tokenSale[_tokenType][_tokenId][msg.sender].tokenType = _tokenType;
        emit SaleSet(msg.sender, _tokenId, _tokenPrice, _quantity);
    }

    function buy(
        uint256 _tokenId,
        uint256 _tokenType,
        uint256 _quantity,
        address _sellerAddress
    ) public payable {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            tokenSale[_tokenType][_tokenId][_sellerAddress].isOnSale,
            "TokenMarketPlace: token not on sale"
        );
        require(
            msg.sender !=
                tokenSale[_tokenType][_tokenId][_sellerAddress].seller,
            "TokenMarketPlace: you are the seller"
        );
        if (_tokenType == 0) {
            _quantity = 1;
            require(
                tokenSale[_tokenType][_tokenId][_sellerAddress].tokenPrice ==
                    msg.value,
                "TokenMarketPlace: invalid Price"
            );
            ERC721Token(erc721).transferFrom(
                _sellerAddress,
                msg.sender,
                _tokenId
            );
        } else {
            require(
                _quantity > 0 &&
                    _quantity <=
                    tokenSale[_tokenType][_tokenId][_sellerAddress].quantity,
                "TokenMarketPlace: invalid quantity"
            );
            require(
                msg.value ==
                    _quantity *
                        tokenSale[_tokenType][_tokenId][_sellerAddress]
                            .tokenPrice,
                "TokenMarketPlace: invalid Price"
            );
            IERC1155Token(erc1155).safeTransferFrom(
                tokenSale[_tokenType][_tokenId][_sellerAddress].seller,
                msg.sender,
                _tokenId,
                _quantity,
                bytes("Purchased")
            );
        }
        tokenSale[_tokenType][_tokenId][_sellerAddress].quantity -= _quantity;

        if (tokenSale[_tokenType][_tokenId][_sellerAddress].quantity == 0) {
            delete tokenSale[_tokenType][_tokenId][_sellerAddress];
        }

        emit TokenPurchased(msg.sender, _tokenId, _quantity, _sellerAddress);
    }

    function stopSale(uint256 _tokenId, uint256 _tokenType) external {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            tokenSale[_tokenType][_tokenId][msg.sender].isOnSale,
            "TokenMarketPlace: not on sale"
        );
        require(
            tokenSale[_tokenType][_tokenId][msg.sender].seller == msg.sender,
            "TokenMarketPlace: you're not the seller"
        );
        delete tokenSale[_tokenType][_tokenId][msg.sender];
        emit SaleEnded(msg.sender, _tokenId);
    }

    function createAuction(
        uint256 _tokenType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _endTime
    ) external {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );

        require(
            _startTime > block.timestamp || _startTime == 0,
            "TokenMarketPlace: invalid time"
        );

        require(
            _startPrice > 0,
            "TokenMarketPlace: starting price must be greater than zero."
        );

        require(
            !auction[_tokenType][_tokenId][msg.sender].activeAuction,
            "TokenMarketPlace: There is a active auction"
        );

        if (_startTime == 0) {
            _startTime = block.timestamp;
        }

        if (_tokenType == 0) {
            _quantity = 1;
            require(
                !tokenSale[_tokenType][_tokenId][msg.sender].isOnSale,
                "TokenMarketPlace: token already on Sale"
            );
            require(
                ERC721Token(erc721).ownerOf(_tokenId) == msg.sender,
                "TokenMarketPlace: You must own the token to create an auction"
            );

            require(
                ERC721Token(erc721).getApproved(_tokenId) == address(this) ||
                    ERC721Token(erc721).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "TokenMarketPlace: not approved"
            );

            // ERC721Token(erc721).transferFrom(
            //     msg.sender,
            //     address(this),
            //     _tokenId
            // );
        } else {
            if (tokenSale[_tokenType][_tokenId][msg.sender].quantity > 0) {
                require(
                    _quantity <=
                        IERC1155Token(erc1155).balanceOf(msg.sender, _tokenId) -
                            tokenSale[_tokenType][_tokenId][msg.sender]
                                .quantity,
                    "TokenMarketPlace: unsufficient tokens"
                );
            }
            require(
                _quantity <=
                    IERC1155Token(erc1155).balanceOf(msg.sender, _tokenId),
                "TokenMarketPlace: Not enough tokens"
            );

            require(
                IERC1155Token(erc1155).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "TokenMarketPlace: not approved"
            );

            // IERC1155Token(erc1155).safeTransferFrom(
            //     msg.sender,
            //     address(this),
            //     _tokenId,
            //     _quantity,
            //     "0x00"
            // );
        }

        auction[_tokenType][_tokenId][msg.sender] = Auction({
            seller: msg.sender,
            tokenId: _tokenId,
            quantity: _quantity,
            startPrice: _startPrice,
            startTime: _startTime,
            endTime: _endTime,
            activeAuction: true,
            highestBidder: address(0),
            highestBid: 0
        });

        emit AuctionCreated(
            msg.sender,
            _tokenId,
            _quantity,
            _startPrice,
            _startTime,
            _endTime
        );
    }

    function placeBid(
        uint256 _tokenId,
        uint256 _tokenType,
        address _tokenSeller
    ) external payable {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            auction[_tokenType][_tokenId][_tokenSeller].activeAuction,
            "TokenMarketPlace: Auction is not active"
        );
        require(
            block.timestamp <
                auction[_tokenType][_tokenId][_tokenSeller].endTime,
            "TokenMarketPlace: Auction has ended"
        );
        require(
            msg.sender != auction[_tokenType][_tokenId][_tokenSeller].seller,
            "TokenMarketPlace: You cannot bid"
        );
        require(
            msg.value > auction[_tokenType][_tokenId][_tokenSeller].highestBid,
            "TokenMarketPlace: Bid amount must be higher than the current highest bid"
        );

        bidder[_tokenType][_tokenId][_tokenSeller].push(
            Bidders(msg.sender, msg.value)
        );
        bidderAmounts[_tokenType][_tokenSeller][msg.sender] += msg.value;
        auction[_tokenType][_tokenId][_tokenSeller].highestBidder = msg.sender;
        auction[_tokenType][_tokenId][_tokenSeller].highestBid = msg.value;

        emit BidPlaced(msg.sender, _tokenId, _tokenSeller, msg.value);
    }

    function cancelAuction(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            msg.sender == auction[_tokenType][_tokenId][_tokenSeller].seller,
            "TokenMarketPlace: Only the seller can perform this action"
        );
        require(
            auction[_tokenType][_tokenId][_tokenSeller].activeAuction,
            "TokenMarketPlace: Auction is not active"
        );

        auction[_tokenType][_tokenId][_tokenSeller].activeAuction = false;

        // if (_tokenType == 0) {
        //     ERC721Token(erc721).transferFrom(
        //         address(this),
        //         _tokenSeller,
        //         _tokenId
        //     );
        // } else {
        //     IERC1155Token(erc1155).safeTransferFrom(
        //         address(this),
        //         _tokenSeller,
        //         _tokenId,
        //         auction[_tokenType][_tokenId][_tokenSeller].quantity,
        //         "tokens transfered"
        //     );
        // }

        for (
            uint256 index = 0;
            index < bidder[_tokenType][_tokenId][_tokenSeller].length;
            index++
        ) {
            payable(
                bidder[_tokenType][_tokenId][_tokenSeller][index].bidderAddr
            ).transfer(
                    bidder[_tokenType][_tokenId][_tokenSeller][index].priceBid
                );
        }

        delete auction[_tokenType][_tokenId][_tokenSeller];

        emit AuctionEnded(_tokenSeller, _tokenId);
    }

    function claimToken(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            msg.sender ==
                auction[_tokenType][_tokenId][_tokenSeller].highestBidder,
            "TokenMarketPlace: You're not the highest bidder"
        );

        require(
            block.timestamp >=
                auction[_tokenType][_tokenId][_tokenSeller].endTime,
            "TokenMarketPlace: Auction has not ended yet"
        );

        if (_tokenType == 0) {
            ERC721Token(erc721).transferFrom(
                _tokenSeller,
                msg.sender,
                _tokenId
            );
        } else {
            IERC1155Token(erc1155).safeTransferFrom(
                _tokenSeller,
                msg.sender,
                _tokenId,
                auction[_tokenType][_tokenId][_tokenSeller].quantity,
                "tokens transferd"
            );
        }

        payable(_tokenSeller).transfer(
            auction[_tokenType][_tokenId][_tokenSeller].highestBid
        );

        for (
            uint256 index = 0;
            index < bidder[_tokenType][_tokenId][_tokenSeller].length;
            index++
        ) {
            if (
                bidder[_tokenType][_tokenId][_tokenSeller][index].bidderAddr !=
                msg.sender
            ) {
                payable(
                    bidder[_tokenType][_tokenId][_tokenSeller][index].bidderAddr
                ).transfer(
                        bidder[_tokenType][_tokenId][_tokenSeller][index]
                            .priceBid
                    );
            }
        }
        delete auction[_tokenType][_tokenId][_tokenSeller];

        emit TokenClaimed(
            msg.sender,
            _tokenId,
            _tokenSeller,
            auction[_tokenType][_tokenId][_tokenSeller].highestBid
        );
    }

    function cancelBid(
        uint256 _tokenId,
        address _tokenSeller,
        uint256 _tokenType
    ) external {
        require(
            _tokenType == 0 || _tokenType == 1,
            "TokenMarketPlace: Invalid token type"
        );
        require(
            bidderAmounts[_tokenType][_tokenSeller][msg.sender] > 0,
            "TokenMarketPlace: You haven't bid yet"
        );
        payable(msg.sender).transfer(
            bidderAmounts[_tokenType][_tokenSeller][msg.sender]
        );

        for (
            uint256 index = 0;
            index < bidder[_tokenType][_tokenId][_tokenSeller].length;
            index++
        ) {
            if (
                msg.sender ==
                bidder[_tokenType][_tokenId][_tokenSeller][index].bidderAddr
            ) {
                for (
                    uint256 indexs = 0;
                    indexs <
                    bidder[_tokenType][_tokenId][_tokenSeller].length - 1;
                    indexs++
                ) {
                    bidder[_tokenType][_tokenId][_tokenSeller][indexs] = bidder[
                        _tokenType
                    ][_tokenId][_tokenSeller][indexs + 1];
                }
                bidder[_tokenType][_tokenId][_tokenSeller].pop();
            }
        }

        emit BidCancelation(msg.sender, _tokenId, _tokenSeller);
    }
}