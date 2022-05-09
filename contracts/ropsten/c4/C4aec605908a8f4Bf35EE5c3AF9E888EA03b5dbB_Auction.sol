/**
 *Submitted for verification at Etherscan.io on 2022-05-08
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

interface IERC721customs{
    function setOnAuctionTrue(uint256)external;
    function setOnAuctionFalse(uint256)external;
    function removeFromExistingToNew(address,address, uint256)external;
    function updateTokenPrice(uint256, uint256)external; 
}

contract Auction {
    address private nftAddress;
    address private tokenAddress;
    mapping(uint256 => uint256) private endTimes;
    mapping(uint256 => uint256) private startTimes;
    mapping(uint256 => address) private highestBidder;
    mapping(uint256 => uint256) private highestBid;
    uint256[] private activeAuctions;
    uint256[] private temp;
    address private owner;

    event AuctionEnded(address winner, uint256 highestBid);

    constructor(address _tokenAddr, address _nftTokenAddr) {
        owner = msg.sender;
        nftAddress = _nftTokenAddr;
        tokenAddress = _tokenAddr;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access forbidden");
        _;
    }

    function setNFTAddress(address _nftTokenAddr) external onlyOwner {
        nftAddress = _nftTokenAddr;
    }

    function setTokenAddress(address _tokenAddr) external onlyOwner {
        tokenAddress = _tokenAddr;
    }

    function transferAuctionOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function startAuction(
        uint256 _endTime,
        uint256 _startPrice,
        uint256 _tokenId
    ) external {
        require(
            _endTime > block.timestamp,
            "End time should be greater than current time"
        );
        require(_startPrice != 0, "Starting price can not be zero");
        require(
            IERC721(nftAddress).ownerOf(_tokenId) == msg.sender,
            "You are not owner of this token"
        );
        require(
            endTimes[_tokenId] < block.timestamp,
            "Token already in auction"
        );

        IERC721customs(nftAddress).setOnAuctionTrue(_tokenId);
        activeAuctions.push(_tokenId);
        endTimes[_tokenId] = _endTime;
        highestBid[_tokenId] = _startPrice;
        highestBidder[_tokenId] = msg.sender;
        startTimes[_tokenId] = block.timestamp;
    }

    function updateBid(uint256 _tokenId, uint256 _newPrice) external {
        require(
            _newPrice > highestBid[_tokenId],
            "New Bid should be greater than Highest Bid"
        );
        require(
            msg.sender != IERC721(nftAddress).ownerOf(_tokenId),
            "Owner of token cannot bid"
        );
        require(block.timestamp < endTimes[_tokenId], "Auction has ended");
        require(highestBidder[_tokenId] != msg.sender, "You already bid");

        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= highestBid[_tokenId],
            "Your balance should be greater than current bid"
        );

        if (_newPrice > highestBid[_tokenId]) {
            if (
                highestBidder[_tokenId] == IERC721(nftAddress).ownerOf(_tokenId)
            ) {
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _newPrice
                );
                highestBid[_tokenId] = _newPrice;
                highestBidder[_tokenId] = msg.sender;
            } else {
                IERC20(tokenAddress).transfer(
                    highestBidder[_tokenId],
                    highestBid[_tokenId]
                );
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _newPrice
                );
                 highestBid[_tokenId] = _newPrice;
                 highestBidder[_tokenId] = msg.sender;
            }
        }
    }

    function stopAuction(uint256 _tokenId) public {
        require(
            IERC721(nftAddress).ownerOf(_tokenId) == msg.sender,
            "You are not owner of this token"
        );
        require(endTimes[_tokenId] != 0, "Auction does not exist");

        if (highestBidder[_tokenId] != msg.sender) {
            IERC20(tokenAddress).transfer(msg.sender, highestBid[_tokenId]);
         IERC721customs(nftAddress).removeFromExistingToNew(IERC721(nftAddress).ownerOf(_tokenId), highestBidder[_tokenId], _tokenId);  
            IERC721(nftAddress).transferFrom(
                msg.sender,
                highestBidder[_tokenId],
                _tokenId
            );
            
             IERC721customs(nftAddress).updateTokenPrice(_tokenId,highestBid[_tokenId]);
             endTimes[_tokenId] = 0;
             highestBidder[_tokenId] = address(0);
             highestBid[_tokenId] = 0;
            IERC721customs(nftAddress).setOnAuctionFalse(_tokenId);
            emit AuctionEnded(highestBidder[_tokenId], highestBid[_tokenId]);
        } else {

             endTimes[_tokenId] = 0;
             highestBidder[_tokenId] = address(0);
             highestBid[_tokenId] = 0;
             IERC721customs(nftAddress).setOnAuctionFalse(_tokenId);
        }
    }

    function getAllAuctions() public view returns (uint256[] memory) {
        return activeAuctions;
    }

    function auctionInfo(uint256 _tokenId)
        external
        view
        returns (
            uint256 tknStartTime,
            uint256 tknEndTime,
            address addr,
            uint256 tknBid
        )
    {
        require(endTimes[_tokenId] != 0, "auction does not exist");
        tknStartTime = startTimes[_tokenId];
        tknEndTime = endTimes[_tokenId];
        addr = highestBidder[_tokenId];
        tknBid = highestBid[_tokenId];
    }

    function getEndtime(uint256 _tokenId) public view returns (uint256) {
        return endTimes[_tokenId];
    }
}