// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';


contract ChizShop is IERC721Receiver {

    ERC20 chizToken = ERC20(0x5c761c1a21637362374204000e383204d347064C); // mainnet
    
    struct Product {
        bool exists;
        uint256 price;
        uint256 tokenId;
        address contractAddress;
        bool multiple;
        uint256 startId;
        uint256 qty;
    }

    mapping(string => Product) public Products;

    address shopManager;
    bool paused;

    event ProductCreated(string slug);
    event ProductSold(string slug);
    event ProductDeleted(string slug);
    event ProductPurchased(string slug, address owner);

    

    modifier onlyShopManager() {
        require(msg.sender == shopManager, "you must be the shop manager to use this function");
        _;
    }

    modifier onlyUnpaused() {
        require(paused == false, "contract is paused");
        _;
    }

    constructor() {
        shopManager = msg.sender;
    }

    function pause() public onlyShopManager {
        paused = true;
    }

    function unpause() public onlyShopManager {
        paused = false;
    }

    function setToken(address contractAddress) public onlyUnpaused onlyShopManager{
        chizToken = ERC20(contractAddress);
    }

    function setShopManager(address newShopManager) public onlyUnpaused onlyShopManager{
        shopManager = newShopManager;
    }

    function withdraw(uint256 withdrawAmount) public onlyUnpaused onlyShopManager {
        chizToken.transfer(msg.sender, withdrawAmount);
    }

    function createProduct(
        string memory slug,
        uint256 price,
        uint256 tokenId,
        address contractAddress,
        bool multiple,
        uint256 startId,
        uint256 qty
    ) public onlyUnpaused onlyShopManager {

        Product memory product = Products[slug];
        require(product.exists == false, "a product with this slug already exists");

        ERC721 tokenContract = ERC721(contractAddress);

        if (!multiple) {
            require(tokenContract.ownerOf(tokenId) == address(this), "contract is not the owner of this token");
        } else {
            uint256 balance = tokenContract.balanceOf(address(this));
            require(balance != 0, "the shop contract does not own any of these tokens");
        }

        Products[slug] = Product(
            true,
            price,
            tokenId,
            contractAddress,
            multiple,
            startId,
            qty
        );
        emit ProductCreated(slug);
    }

    function deleteProduct(string memory slug) public onlyUnpaused onlyShopManager{
        delete Products[slug];
        emit ProductDeleted(slug);
    }

    function purchaseProduct(string memory slug) public payable onlyUnpaused {
        Product memory product = Products[slug];
        require(product.exists == true, "a product with this slug does not exist");

        ERC721 tokenContract = ERC721(product.contractAddress);
        uint256 tokenId;

        if (product.multiple) {
            require(product.qty > 0, "there are no more tokens available");
            tokenId = product.startId;
        } else {
            tokenId = product.tokenId;
        }

        require(tokenContract.ownerOf(tokenId) == address(this), "contract is sold out of these tokens");

        // if product has multiple tokens, increment startId and decrement qty
        if (product.multiple) {
            product.startId++;
            product.qty--;
        }

        chizToken.transferFrom(msg.sender, address(this), product.price);
        tokenContract.transferFrom(address(this), msg.sender, tokenId);

        Products[slug] = Product(
            true,
            product.price,
            product.tokenId,
            product.contractAddress,
            product.multiple,
            product.startId,
            product.qty
        );

        emit ProductPurchased(slug, msg.sender);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}



abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address owner);
    function transferFrom(address from, address to, uint256 id) public virtual;
    function balanceOf(address owner) public virtual returns (uint256 amount);
    function totalSupply () public virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 tokenId) public virtual returns (uint256 index);
}

abstract contract ERC20 {
    function allowance(address owner, address spender) public virtual;
    function transfer(address to, uint256 value) public virtual;
    function transferFrom(address from, address to, uint256 amount) public virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}