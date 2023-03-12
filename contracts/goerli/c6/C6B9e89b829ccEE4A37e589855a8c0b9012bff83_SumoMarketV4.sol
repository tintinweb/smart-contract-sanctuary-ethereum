/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private locked = 1;
    modifier nonReentrant() virtual { require(locked == 1, "REENTRANCY"); locked = 2;_; locked = 1; }
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract SumoMarketV4 is Ownable, ReentrancyGuard {

     IERC721 public ERC721 = IERC721(0xE07BeA89ea957a2632D52c10d881De45d948D0bc);
     IERC20 public ERC20;

    function setERC721(address _address) external onlyOwner { ERC721 = IERC721(_address); }
    function setERC20(address _address) external onlyOwner { ERC20 = IERC20(_address); }

    /// listedType 
    /// 1 - ETH
    /// 2 - CustomERC20Token
    struct ListedToken {address owner; uint256 listedType; uint256 tokenId; uint256 price;}
    mapping(uint256 => ListedToken) public idListed;
    
    modifier onlySender() {require(msg.sender == tx.origin, "No smart contract");_;}
    event TokenListed(address from_, uint256 tokenType_, uint256 tokenId_, uint256 price_);
    event Dealdone(address from_, address to_, uint256 tokenType_, uint256 tokenId_, uint256 price_);

    function listToken(uint256 id_, uint256 price_, uint256 type_) external onlySender nonReentrant {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        require(idListed[id_].owner == address(0), "Token is already listed");
        require(type_ == 1 || type_ == 2, "Invalid listing type");
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(price_ > 0, "Invalid price");
        idListed[id_] = ListedToken(msg.sender, type_, id_, price_);
        emit TokenListed(msg.sender, type_, id_, price_);
    }

    function cancelListing(uint256 id_) external onlySender nonReentrant {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        require(idListed[id_].owner == msg.sender, "Not listed by you");
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        delete idListed[id_];
    }

    /// Purchase token normal
    function purchaseToken(uint256 id_) external payable onlySender nonReentrant {
        require(idListed[id_].listedType == 1, "This token is not listed 4 eth");
        require(msg.value >= idListed[id_].price, "Not enough ether to purchase");

        uint256 value = msg.value;
        address payable payableSeller = payable(idListed[id_].owner);
        payableSeller.transfer(value);
        
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
    }

    /// Purchase token with custom ERC20 token
    function purchaseTokenWithToken(uint256 id_) external payable onlySender nonReentrant {
        require(idListed[id_].listedType == 2, "This token is not listed 4 token");
        require(ERC20.balanceOf(msg.sender) >= idListed[id_].price, "Not enought token to purchase");
        ERC20.transferFrom(msg.sender, idListed[id_].owner, idListed[id_].price);
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
    }

    /// both combined
    function purchaseTokenBothWay(uint256 id_, uint256 type_) external payable onlySender nonReentrant {
        require(type_ == 1 || type_ == 2, "Invalid listing type");
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        if (type_ == 1) {
        require(idListed[id_].listedType == 1, "This token is not listed 4 eth");
        require(msg.value >= idListed[id_].price, "Not enough ether to purchase");

        uint256 value = msg.value;
        address payable payableSeller = payable(idListed[id_].owner);
        payableSeller.transfer(value);
        
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
        }
        if (type_ == 2) {
        require(idListed[id_].listedType == 2, "This token is not listed 4 token");
        require(ERC20.balanceOf(msg.sender) >= idListed[id_].price, "Not enought token to purchase");

        ERC20.transferFrom(msg.sender, idListed[id_].owner, idListed[id_].price);
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
        }
    }

    event BIDDEALDONE(address from_, address to_, uint256 tokenId_, uint256 price_);
    event BIDDONE(address from_, uint256 tokenId_, uint256 price_);
    struct BIDINFO { address bidder; uint256 tokenID; uint256 priceID; }
    mapping(uint256 => BIDINFO[]) public BID;

    function MAKEBID(uint256 id_, BIDINFO memory BIDINFO_) external payable onlySender nonReentrant {
        require(BIDINFO_.bidder == msg.sender, "Not sender");
        require(BIDINFO_.priceID > 0, "Invalid price");
        require(msg.value == BIDINFO_.priceID / 10**18, "Value sent is not correct");

        BID[id_].push(BIDINFO_);
        emit BIDDONE(msg.sender, id_, BIDINFO_.priceID);
    }

    function CANCELBID(uint256 id_) external onlySender nonReentrant {
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        uint256 len = BID[id_].length;
        for (uint256 i = 0; i < len; i++) {
            if (BID[id_][i].bidder == msg.sender) {
            // Remove the bid from the array
                if (i < len - 1) {
                    BID[id_][i] = BID[id_][len - 1];
                }
            uint256 sendAmount = BID[id_][i].priceID;
            bool success;
            (success, ) = payable(msg.sender).call{value: (sendAmount)}("");
            require(success, "Failed to withdraw bit");
            BID[id_].pop();
            break;
        }
    }}

    function ACCEPTBID(uint256 id_, address bidby_) external onlySender nonReentrant {
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        address tokenOwner = ERC721.ownerOf(id_);
        uint256 len = BID[id_].length;
        for (uint256 i = 0; i < len; i++) {
            if (BID[id_][i].bidder == bidby_) {
            // Remove the bid from the array
                if (i < len - 1) {
                    BID[id_][i] = BID[id_][len - 1];
                }
            uint256 sendAmount = BID[id_][i].priceID;
            bool success;
            (success, ) = payable(tokenOwner).call{value: (sendAmount)}("");
            require(success, "Failed to withdraw bit");
            ERC721.transferFrom(tokenOwner, bidby_, id_);
            emit BIDDEALDONE(tokenOwner, bidby_, id_, BID[id_][i].priceID);
            BID[id_].pop();
            delete idListed[id_];
            break;
        }}
    }
}