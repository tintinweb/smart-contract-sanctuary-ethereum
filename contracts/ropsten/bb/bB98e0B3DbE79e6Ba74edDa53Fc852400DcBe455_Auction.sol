/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC721 is IERC165 {
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

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721MultiCurrency {
    function getSupportedCurrency(string memory) external view returns(address);

    function getTokenPrice(uint256) external view returns(uint256, string memory);
}

contract Auction {
    address private _nftAddress = address(0);
    mapping(uint256 => uint256) private _endTimes;
    mapping(uint256 => uint256) private _startTimes;
    mapping(uint256 => address) private _highestBidder;
    mapping(uint256 => uint256) private _highestBid;
    uint256[] private _activeAuctions;
    uint256[] private _temp;
    address private _owner;

    event AuctionEnded(address winner, uint256 highestBid);

    constructor(address nftToken) {
        _owner = msg.sender;
        _nftAddress = nftToken;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Access forbidden");
        _;
    }

    function setNFTAddress(address nftToken) external onlyOwner {
        _nftAddress = nftToken;
    }

    function transferAuctionOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function startAuction(
        uint256 endTime,
        uint256 startPrice,
        uint256 tokenId
    ) external {
        require(
            endTime > block.timestamp,
            "End time should be greater than current time"
        );
        require(startPrice != 0, "Starting price can not be zero");
        require(
            IERC721(_nftAddress).ownerOf(tokenId) == msg.sender,
            "You are not owner of this token"
        );
        require(
            _endTimes[tokenId] < block.timestamp,
            "Token already in auction"
        );

        _activeAuctions.push(tokenId);
        _endTimes[tokenId] = endTime;
        _highestBid[tokenId] = startPrice;
        _highestBidder[tokenId] = msg.sender;
        _startTimes[tokenId] = block.timestamp;
    }

    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        require(
            newPrice > _highestBid[tokenId],
            "New Bid should be greater than Highest Bid"
        );
        require(
            msg.sender != IERC721(_nftAddress).ownerOf(tokenId),
            "Owner of token cannot bid"
        );
        require(block.timestamp < _endTimes[tokenId], "Auction has ended");
        require(_highestBidder[tokenId] != msg.sender, "You already bid");

        (, string memory symbol) = IERC721MultiCurrency(_nftAddress).getTokenPrice(tokenId);
        address currencyToken = IERC721MultiCurrency(_nftAddress).getSupportedCurrency(symbol);

        require(
            IERC20(currencyToken).balanceOf(msg.sender) >= _highestBid[tokenId],
            "Your balance should be greater than current bid"
        );

        if (newPrice > _highestBid[tokenId]) {
            if (
                _highestBidder[tokenId] == IERC721(_nftAddress).ownerOf(tokenId)
            ) {
                IERC20(currencyToken).transferFrom(
                    msg.sender,
                    address(this),
                    newPrice
                );
                _highestBid[tokenId] = newPrice;
                _highestBidder[tokenId] = msg.sender;
            } else {
                IERC20(currencyToken).transfer(
                    _highestBidder[tokenId],
                    _highestBid[tokenId]
                );
                IERC20(currencyToken).transferFrom(
                    msg.sender,
                    address(this),
                    newPrice
                );
                _highestBid[tokenId] = newPrice;
                _highestBidder[tokenId] = msg.sender;
            }
        }
    }

    function stopAuction(uint256 tokenId) public {
        require(
            IERC721(_nftAddress).ownerOf(tokenId) == msg.sender,
            "You are not owner of this token"
        );
        require(_endTimes[tokenId] != 0, "Auction does not exist");

        (, string memory symbol) = IERC721MultiCurrency(_nftAddress).getTokenPrice(tokenId);
        address currencyToken = IERC721MultiCurrency(_nftAddress).getSupportedCurrency(symbol);

        if (_highestBidder[tokenId] != msg.sender) {
            IERC20(currencyToken).transfer(msg.sender, _highestBid[tokenId]);
            IERC721(_nftAddress).transferFrom(
                msg.sender,
                _highestBidder[tokenId],
                tokenId
            );

            _endTimes[tokenId] = 0;
            _highestBidder[tokenId] = address(0);
            _highestBid[tokenId] = 0;
            emit AuctionEnded(_highestBidder[tokenId], _highestBid[tokenId]);
        } else {
            _endTimes[tokenId] = 0;
            _highestBidder[tokenId] = address(0);
            _highestBid[tokenId] = 0;
        }
    }

    function getAllAuctions() public view returns (uint256[] memory) {
        return _activeAuctions;
    }

    function auctionInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 tknStartTime,
            uint256 tknEndTime,
            address addr,
            uint256 tknBid
        )
    {
        require(_endTimes[tokenId] != 0, "auction does not exist");
        tknStartTime = _startTimes[tokenId];
        tknEndTime = _endTimes[tokenId];
        addr = _highestBidder[tokenId];
        tknBid = _highestBid[tokenId];
    }

    function getEndtime(uint256 tokenId) public view returns (uint256) {
        return _endTimes[tokenId];
    }
}