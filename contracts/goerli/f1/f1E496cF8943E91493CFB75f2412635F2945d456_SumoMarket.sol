/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.0;

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
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract SumoMarket is Ownable {

     IERC721 public ERC721;
     IERC20 public ERC20;

    function setERC721(address _address) external onlyOwner { ERC721 = IERC721(_address); }
    function setERC20(address _address) external onlyOwner { ERC20 = IERC20(_address); }

    struct ListedToken {address owner; bool listed; uint256 tokenId; uint256 price; uint256 priceToken; }
    mapping(uint256 => ListedToken) public idListed;

    mapping(uint256 => bool) public idListedForToken;

    //List token normal
    function listToken(uint256 id_, uint256 price_) external onlySender {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        idListed[id_] = ListedToken(msg.sender, true, id_, price_ * 10 ** 18, 0);
    }

    //List token with custom ERC20 token
    function listTokenWithToken(uint256 id_, uint256 price_) external onlySender {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        idListedForToken[id_] == true;
        idListed[id_] = ListedToken(msg.sender, true, id_, 0, price_ * 10 ** 18);
    }

    function cancelListing(uint256 id_) external onlySender {
        require(ERC721.ownerOf(id_) == msg.sender, "You do not own this token");
        require(idListed[id_].owner == msg.sender, "Not listed by you");

        idListed[id_].listed = false;
    }

    //Purchase token normal
    function purchaseToken(uint256 id_) external payable onlySender {
        require(idListed[id_].listed, "This token is not listed");
        require(!idListedForToken[id_], "This token is listed for token");
        require(msg.value >= idListed[id_].price, "Not enough ether to purchase token");
        //require(msg.value == idListed[id_].price, "Value sent is not correct");

        //Make sure the price goes to the wallet of lister
        address seller = idListed[id_].owner;
        address payable payableSeller = payable(seller);
        payableSeller.transfer(idListed[id_].price);

        //msg.sender.transfer(idListed[id_].price);
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        idListed[id_].listed = false;
    }

    //Purchase token with custom ERC20 token
    function purchaseTokenWithToken(uint256 id_) external payable onlySender {
        require(idListed[id_].listed, "This token is not listed");
        require(idListedForToken[id_], "This token is not listed for token");
        //require(msg.value >= idListed[id_].price, "Not enough ether to purchase token");

        ERC20.transferFrom(msg.sender, idListed[id_].owner, idListed[id_].priceToken);
        ERC721.transferFrom(idListed[id_].owner, msg.sender, id_);
        idListed[id_].listed = false;
        idListedForToken[id_] = false;
    }

    function getlistedItems(uint256 _id) public view returns (ListedToken memory) {
        return idListed[_id];
    }

    modifier onlySender() {require(msg.sender == tx.origin, "No smart contract");_;}

}