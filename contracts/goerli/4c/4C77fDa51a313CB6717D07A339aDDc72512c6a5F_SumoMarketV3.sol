/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
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

contract SumoMarketV3 is Ownable {

    using SafeMath for uint256;

     IERC721 public ERC721 = IERC721(0xE07BeA89ea957a2632D52c10d881De45d948D0bc);
     IERC20 public ERC20;

    function setERC721(address _address) external onlyOwner { ERC721 = IERC721(_address); }
    function setERC20(address _address) external onlyOwner { ERC20 = IERC20(_address); }

    struct ListedToken {address owner; uint256 listedType; uint256 tokenId; uint256 price;}
    /*
     *listedType 
     *1 - ETH
     *2 - CustomERC20Token
     */
    mapping(uint256 => ListedToken) public idListed;

    struct Bid {bool hasBid; uint256 tokenId; address bidder; uint256 price;}
    mapping (uint256 => Bid) public tokenBid;

    modifier onlySender() {require(msg.sender == tx.origin, "No smart contract");_;}
    event TokenListed(address from_, uint256 tokenType_, uint256 tokenId_, uint256 price_);
    event Tokenbits(address from_, uint256 tokenId_, uint256 price_);
    event Dealdone(address from_, address to_, uint256 tokenType_, uint256 tokenId_, uint256 price_);
    event DealdoneBit(address from_, address to_, uint256 tokenId_, uint256 price_);

    function listToken(uint256 id_, uint256 price_, uint256 type_) external onlySender {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        require(idListed[id_].owner == address(0), "Token is already listed");
        require(type_ == 1 || type_ == 2, "Invalid listing type");
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(price_ > 0, "Invalid price");
        idListed[id_] = ListedToken(msg.sender, type_, id_, price_);
        emit TokenListed(msg.sender, type_, id_, price_);
    }

    function cancelListing(uint256 id_) external onlySender {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        require(idListed[id_].owner == msg.sender, "Not listed by you");
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        delete idListed[id_];
    }

    //Purchase token normal
    function purchaseToken(uint256 id_) external payable onlySender {
        require(idListed[id_].listedType == 1, "This token is not listed 4 eth");
        require(msg.value >= idListed[id_].price, "Not enough ether to purchase");

        uint256 value = msg.value;
        address payable payableSeller = payable(idListed[id_].owner);
        payableSeller.transfer(value);
        
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
    }

    //Purchase token with custom ERC20 token
    function purchaseTokenWithToken(uint256 id_) external payable onlySender {
        require(idListed[id_].listedType == 2, "This token is not listed 4 token");
        require(ERC20.balanceOf(msg.sender) >= idListed[id_].price, "Not enought token to purchase");
        ERC20.transferFrom(msg.sender, idListed[id_].owner, idListed[id_].price);
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        emit Dealdone(idListed[id_].owner, msg.sender, idListed[id_].listedType, id_, idListed[id_].price);
        delete idListed[id_];
    }

    //both combined
    function purchaseTokenBothWay(uint256 id_, uint256 type_) external payable onlySender {
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

    function bidForToken(uint256 id_, uint256 price_) external payable onlySender {
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(price_ > 0, "Invalid price");
        require(msg.value == price_, "Value sent is not correct");
        tokenBid[id_] = Bid(true, id_, msg.sender, price_);

        emit Tokenbits(msg.sender, id_, price_);
    }

    function cancelBit(uint256 id_) external onlySender {
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(tokenBid[id_].bidder == msg.sender, "Not bidder");

        uint256 sendAmount = tokenBid[id_].price;
        address i = payable(msg.sender);
        bool success;
        (success, ) = i.call{value: (sendAmount)}("");
        require(success, "Failed to withdraw bit");

        delete tokenBid[id_];
    }
    
    function acceptBit(uint id_) external onlySender {
        require(id_ > 0 && id_ < 334, "Invalid token ID");
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");

        address tokenOwner = ERC721.ownerOf(id_);
        uint256 sendAmount = tokenBid[id_].price;
        address i = payable(tokenOwner);
        bool success;
        (success, ) = i.call{value: (sendAmount)}("");
        require(success, "Failed to withdraw bit");

        ERC721.transferFrom(tokenOwner, tokenBid[id_].bidder, id_);
        emit DealdoneBit(tokenOwner, tokenBid[id_].bidder, id_, tokenBid[id_].price);
        delete tokenBid[id_];
        delete idListed[id_];
    }
}