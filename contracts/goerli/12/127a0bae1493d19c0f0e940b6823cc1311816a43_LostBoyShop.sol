/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

interface IERC721Receiver {
   function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC1155Receiver{
   function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data ) external returns (bytes4);
}

abstract contract ERC721 {
   function ownerOf(uint256 id) public virtual returns (address owner);
   function transferFrom(address from, address to, uint256 id) public virtual;
   function balanceOf(address owner) public virtual returns (uint256 amount);
   function tokenOfOwnerByIndex(address owner, uint256 tokenId) public virtual returns (uint256 index);
}

abstract contract ERC1155 {
   function balanceOf(address account, uint256 id) public virtual returns (uint256);
   function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) public virtual;
}

abstract contract ERC20 {
   function allowance(address owner, address spender) public virtual;
   function transfer(address to, uint256 value) public virtual;
   function transferFrom(address from, address to, uint256 amount) public virtual;
   function balanceOf(address account) external virtual returns (uint256);
}

contract LostBoyShop is IERC721Receiver, IERC1155Receiver {
    struct Product {
	  bool exists;
	  bool multiple;
	  uint256 price;
	  uint256 tokenId;
	  uint256 quantity;
	  uint256 soldQuantity;
	  address contractAddress;
    }
    mapping(string => Product) public Products;
    address shopManager;
    bool paused;
	
    event ProductCreated(string slug);
    event ProductSold(string slug);
    event ProductDeleted(string slug);
    event ProductPurchased(string slug, address owner);

    ERC20 lostboyToken = ERC20(0xc20557e24FCB23F6b62E1D39C7bbDECE691218Eb);

    modifier onlyShopManager() {
        require(
            msg.sender == shopManager,
            "you must be the shop manager to use this function"
        );
        _;
    }

    modifier pauseable() {
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
	
    function setToken(address contractAddress) public pauseable onlyShopManager {
       lostboyToken = ERC20(contractAddress);
    }

    function setShopManager(address newShopManager) public pauseable onlyShopManager {
       shopManager = newShopManager;
    }

    function withdraw(uint256 withdrawAmount) public pauseable onlyShopManager {
       lostboyToken.transfer(msg.sender, withdrawAmount);
    }
	
    function createProduct(string memory slug, uint256 price, uint256 tokenId, address contractAddress, bool multiple, uint256 quantity) public pauseable onlyShopManager {
        Product memory product = Products[slug];
        require(product.exists == false, "a product with this slug already exists");
		
		if(contractAddress == address(0)) 
		{
		    Products[slug] = Product(true, false, price, 0, quantity, 0, contractAddress);
		    emit ProductCreated(slug);
		}
		else 
		{
		    if(multiple)
			{
			    ERC1155 tokenContract = ERC1155(contractAddress);
				uint256 balance = tokenContract.balanceOf(address(this), tokenId);
                require(balance > 0, "contract does not own any of these tokens");
				
				Products[slug] = Product(true, true, price, tokenId, balance, 0, contractAddress);
				emit ProductCreated(slug);
			}
			else
			{
			    ERC721 tokenContract = ERC721(contractAddress);
				address tokenOwner = tokenContract.ownerOf(tokenId);
				require(tokenOwner == address(this), "contract is not the owner of this token");
				
				Products[slug] = Product(true, false, price, tokenId, 1, 0, contractAddress);
			    emit ProductCreated(slug);
			}
		}
    }

    function deleteProduct(string memory slug) public pauseable onlyShopManager{
        delete Products[slug];
        emit ProductDeleted(slug);
    }
	
    function purchaseProduct(string memory slug) public payable pauseable {
        Product memory product = Products[slug];
        require(product.exists == true, "a product with this slug does not exist");
		require(product.quantity > product.soldQuantity, "product already sold");
		require(lostboyToken.balanceOf(address(msg.sender)) >= product.price, "balance not available for purchase");
		
        if(product.contractAddress != address(0) && !product.multiple) 
		{
		    ERC721 tokenContract = ERC721(product.contractAddress);
            address tokenOwner = tokenContract.ownerOf(product.tokenId);
            require(address(tokenOwner) == address(this), "contract is sold out of these tokens");
			tokenContract.transferFrom(address(this), address(msg.sender), product.tokenId);
        } 
		else if(product.contractAddress != address(0) && product.multiple) 
		{
		    ERC1155 tokenContract = ERC1155(product.contractAddress);
		    uint256 balance = tokenContract.balanceOf(address(this), product.tokenId);
            require(balance > 0, "contract does not own any of these tokens");
			tokenContract.safeTransferFrom(address(this), address(msg.sender), product.tokenId, 1, '');
        }
        
        lostboyToken.transferFrom(address(msg.sender), address(this), product.price);
        Products[slug].soldQuantity += 1;
        emit ProductPurchased(slug, msg.sender);
    }
	
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
	
	function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}