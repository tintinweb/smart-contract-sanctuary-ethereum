/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;
 
interface IERC165 {
 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
interface IERC721Metadata {
 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
 
interface IERC721 {
 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
 
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);  
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
 
 
contract Marketplace{
 
    // структура с информацией о токене, выставленном на продажу
    struct Item{
        uint256 tokenId;
        uint256 cost;
        address tokenAddress;
        address tokenOwner;
    }
 
    // структура с информацией о токене, выставленном на аукцион
    struct AuctionItem{
        uint256 tokenId;
        uint256 currentCost;
        uint256 time;
        uint24 bidCount;
        address tokenAddress;
        address tokenOwner;
        address lastCustomer;
    }
 
    // общее количество всех токенов когда-либо выставляемых на продажу
    uint256 public listId;
    // общее количество всех токенов когда-либо выставляемых на аукцион
    uint256 public listAuctionId;
 
    // словарь токенов, выставленных на продажу
    // (id лота => структура с информацией)
    mapping(uint256 => Item) public list;
    // словарь токенов, выставленных на аукцион
    // (id лота => структура с информацией)
    mapping(uint256 => AuctionItem) public listAuction;
 
    event ListingItem(uint256 tokenId, uint256 cost, address tokenAddress);
    event CancelingItem(uint256 id);
    event BuyingItem(uint256 id);
    event ListingItemOnAuction(uint256 tokenId, uint256 minCost, address tokenAddress);
    event MakingBid(uint256 id);
    event FinishingAuction(uint256 id, address to, uint256 value);

    // функция для выставления токена на продажу
    function listItem(uint256 tokenId, uint256 cost, address tokenAddress) external returns(uint256) {
        require(tokenAddress.code.length > 0, "Token is not contract");
        require(IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId) || IERC165(tokenAddress).supportsInterface(type(IERC721Metadata).interfaceId), "IERC721 is not supported");
        require(msg.sender == (IERC721(tokenAddress).ownerOf(tokenId)), "Msg.Sender is not an owner");
        require(address(this) == IERC721(tokenAddress).getApproved(tokenId) || IERC721(tokenAddress).isApprovedForAll(msg.sender, address(this)), "Token is not approved for Marketplace");
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId); // отправка токена в маркетплейс
        listId += 1;
        list[listId] = Item(tokenId, cost, tokenAddress, msg.sender);
        emit ListingItem(tokenId, cost, tokenAddress);
        return listId;
    }
    
    // address(this) - адрес маркетплейса (должен иметь разрешение на торговлю токеном по id)
    // address(0) - ? - адрес токена не равен ему, если продается
    // IERC721(tokenAddress).ownerOf(tokenId) - владелец токена
    // 

    // покупка токена
    function buyItem(uint256 id) external payable {
        require(list[id].tokenAddress != address(0), "Token can not be seled");
        require(msg.value >= list[id].cost, "Not enough money to buy this token");
        payable(list[id].tokenOwner).transfer(list[id].cost);
        IERC721(list[id].tokenAddress).safeTransferFrom(address(this), msg.sender, id); // отправка токена покупателю
        delete list[id];
        if (list[id].cost < msg.value) payable(msg.sender).transfer(msg.value - list[id].cost);
        emit BuyingItem(id);
    }

    // функция cнятия токена с продажи
    function cancel(uint256 id) external {
        require(list[id].tokenAddress != address(0), "Token can not be seled");
        require(msg.sender == list[id].tokenOwner, "Msg.Sender is not an owner");
        IERC721(list[id].tokenAddress).safeTransferFrom(address(this), msg.sender, id);
        delete list[id];
        emit CancelingItem(id);
    }

    // функция для выставления токена на аукцион
    function listItemOnAuction(uint256 tokenId, uint256 minCost, address tokenAddress) external returns(uint256) {
        require(tokenAddress.code.length > 0, "Token is not contract");
        require(IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId) || IERC165(tokenAddress).supportsInterface(type(IERC721Metadata).interfaceId), "IERC721 is not supported");
        require(msg.sender == (IERC721(tokenAddress).ownerOf(tokenId)), "Msg.Sender is not an owner");
        require(address(this) == IERC721(tokenAddress).getApproved(tokenId) || IERC721(tokenAddress).isApprovedForAll(msg.sender, address(this)), "Token is not approved for Marketplace");
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId); // отправка токена в маркетплейс
        listAuctionId += 1;
        listAuction[listAuctionId] = AuctionItem(tokenId, minCost, block.timestamp, 0, tokenAddress, msg.sender, address(0));
        emit ListingItemOnAuction(tokenId, minCost, tokenAddress);
        return listAuctionId;
    }
 
    // функция, чтобы делать ставку в аукционе
    function makeBid(uint256 id) external payable returns(bool) {
        require(listAuction[id].tokenAddress != address(0), "Token can not be seled");
        require(msg.value >= listAuction[id].currentCost, "Your bid is smaller then actual token cost");
        require(listAuction[id].time + 10 minutes <= block.timestamp, "Auction time is out");
        payable(listAuction[id].lastCustomer).transfer(listAuction[id].currentCost);
        listAuction[id].currentCost = msg.value;
        listAuction[id].lastCustomer = msg.sender;
        listAuction[id].bidCount += 1;
        emit MakingBid(id);
        return true;
    }
 
    // функция завершения аукциона
    function finishAuction(uint256 id) external {
        require(listAuction[id].tokenAddress != address(0), "Token can not be seled");
        require(listAuction[id].time + 10 minutes > block.timestamp, "Auction time is not out");
        if (listAuction[id].bidCount < 3) {
            payable(listAuction[id].lastCustomer).transfer(listAuction[id].currentCost);
            IERC721(listAuction[id].tokenAddress).safeTransferFrom(address(this), listAuction[id].tokenOwner, id);
            emit FinishingAuction(id, listAuction[id].lastCustomer, listAuction[id].currentCost);
        } else {
            payable(listAuction[id].tokenOwner).transfer(listAuction[id].currentCost);
            IERC721(listAuction[id].tokenAddress).safeTransferFrom(address(this), listAuction[id].lastCustomer, id);
            emit FinishingAuction(id, listAuction[id].tokenOwner, listAuction[id].currentCost);
        }
    }
 
    // функция необходима, чтобы этот контракт мог принимать токены ERC721 - просто так положено
    function onERC721Received(address , address , uint256 , bytes memory) external pure returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}