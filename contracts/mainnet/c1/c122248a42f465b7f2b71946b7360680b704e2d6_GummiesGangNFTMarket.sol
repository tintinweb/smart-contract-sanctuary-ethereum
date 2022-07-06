/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/Gummies/Market.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Gummies Gang Market
 * @author Decentralized Devs - Angelo
 */






contract GummiesGangNFTMarket is  Ownable {

        struct MarketItem {
            bool sold;
            uint256 price;
            address contractAddress;
            uint256 nftId;
        }
    
    address gumFundingaddress;
    uint256 public _currentIndex;  
    mapping(uint256 => MarketItem) public marketItems; //Nfts
    IERC20 gumToken;

    constructor(address gumTokenAddress, address gumTransfer) {
        gumToken = IERC20(gumTokenAddress);
        gumFundingaddress = gumTransfer;

 
 
    }
    function getAllMarketItems() public view returns (MarketItem[] memory){
      MarketItem[]    memory id = new MarketItem[](_currentIndex);
      for (uint i = 0; i < _currentIndex; i++) {
          MarketItem storage member = marketItems[i];
          id[i] = member;
        }
      return id;
    }  

    function getAllAvailableMarketItems() public view returns (MarketItem[] memory){
      MarketItem[]    memory id = new MarketItem[](_currentIndex);
      for (uint i = 0; i < _currentIndex; i++) {
          MarketItem storage member = marketItems[i];
          if(!member.sold){
            id[i] = member;
          }
         
        }
      return id;
    }    
    
    function listMarketItem(uint256 nftId, address contractAddress, uint256 price) public onlyOwner{
            MarketItem storage marketItem = marketItems[_currentIndex];
            marketItem.contractAddress = contractAddress;
            marketItem.price = price;
            marketItem.nftId = nftId;
            unchecked {
                _currentIndex++;
            }
    }

    function getSaleDetails(uint256 saleIndex) public view returns(MarketItem memory) {
         MarketItem storage marketItem = marketItems[saleIndex];
        return marketItem;
    }

    function getPrice(uint256 saleIndex) public view returns(uint256) {
         MarketItem storage marketItem = marketItems[saleIndex];
         return marketItem.price;
    }

    function getSaleNftId(uint256 saleIndex) public view returns(uint256) {
         MarketItem storage marketItem = marketItems[saleIndex];
         return marketItem.nftId;
    }

    function getSaleNftContract(uint256 saleIndex) public view returns(address) {
         MarketItem storage marketItem = marketItems[saleIndex];
         return marketItem.contractAddress;
    }

    function getSaleNftsoldStatus(uint256 saleIndex) public view returns(bool) {
         MarketItem storage marketItem = marketItems[saleIndex];
         return marketItem.sold;
    }

    function setFundingAddress(address val) public onlyOwner{
        gumFundingaddress = val;
    }

    function setGumContract(address val) public onlyOwner{
         gumToken = IERC20(val);
    }

    function changePrice(uint256 saleId, uint256 val) public onlyOwner{
         MarketItem storage marketItem = marketItems[saleId];
         marketItem.price = val;
    }

    function buyMarketItem(uint256 _saleIndex) external {
        MarketItem storage marketItem = marketItems[_saleIndex];
        require(!marketItem.sold, "Nft Already Sold");
        uint256 bal = gumToken.balanceOf(msg.sender);
        require(bal >= marketItem.price);
        gumToken.transferFrom(msg.sender,gumFundingaddress, marketItem.price);
        IERC721(marketItem.contractAddress).transferFrom(
            address(this),
            msg.sender,
            marketItem.nftId
        );
        marketItem.sold = true;
    }

    function overideTransfer(address _contract, address _to, uint64 _nftId) public onlyOwner {
         IERC721(_contract).transferFrom(
            address(this),
            _to,
            _nftId
        );
    }

    //Selling Whitelist Code

    struct WLItem {
            uint total_sold;
            uint quantity;
            uint256 price;
            string img;
            string title;
            address[] buyers;
        }

        uint256 public _wlcurrentIndex = 0; 
        mapping(uint256 => WLItem) public whitelistItems; //Whitelist

    function listWL_Item(  uint quantity,   uint256 price_in_wei,  string memory img,  string memory title ) public onlyOwner{

            WLItem storage item = whitelistItems[_wlcurrentIndex];

            item.total_sold = 0;
            item.quantity = quantity;
            item.price = price_in_wei;
            item.img = img;
            item.title = title;

            unchecked {
                _wlcurrentIndex++;
            }
    }

    function buyWl_item(uint _id) public {
        WLItem storage item = whitelistItems[_id];
        require(item.total_sold < item.quantity, "Sold");
        uint256 bal = gumToken.balanceOf(msg.sender);
        require(bal >= item.price, "You donot have enough tokens to buy this.");
        gumToken.transferFrom(msg.sender,gumFundingaddress, item.price); 

        item.buyers.push(msg.sender);   
        item.total_sold++;   
    }

    function get_WL_Item_Addresses(uint id) public view returns (address[] memory){
        return whitelistItems[id].buyers;
    }
    function getAllWhiteListItems() public view returns (WLItem[] memory){
      WLItem[]    memory id = new WLItem[](_wlcurrentIndex);
      for (uint i = 0; i < _wlcurrentIndex; i++) {
          WLItem storage member = whitelistItems[i];
          id[i] = member;
        }
      return id;
    }
    function getAllAvailableWhiteListItems() public view returns (WLItem[] memory){
      WLItem[]    memory id = new WLItem[](_wlcurrentIndex);
      for (uint i = 0; i < _wlcurrentIndex; i++) {
          WLItem storage member = whitelistItems[i];
          if(member.total_sold < member.quantity){
            id[i] = member;
          }
        }
      return id;
    }
    


    //Selling Physical Item Code
    struct BuyerInfo {
        string fullname;
        string p_address;
        string country;
        string email;
    }

    struct PhysicalItem {
            uint total_sold;
            uint quantity;
            uint price;
            string img;
            string title;
            uint[] buyersId;     
            
    }
    uint256 buyersCount = 0;
    mapping(uint256 => BuyerInfo) private buyerslist;

    uint256 public _Physical_Item_index = 0; 
    mapping(uint256 => PhysicalItem) public physicalItems; //Whitelist  
    
    function listPhysical_Item(  uint quantity,   uint256 price_in_wei,  string memory img,  string memory title ) public onlyOwner{

            PhysicalItem storage item = physicalItems[_Physical_Item_index];

            item.total_sold = 0;
            item.quantity = quantity;
            item.price = price_in_wei;
            item.img = img;
            item.title = title;

            unchecked {
                _Physical_Item_index++;
            }
    }
     

    function getAllPhysicalItems() public view returns (PhysicalItem[] memory){
      PhysicalItem[]    memory id = new PhysicalItem[](_Physical_Item_index);
      for (uint i = 0; i < _Physical_Item_index; i++) {
          PhysicalItem storage member = physicalItems[i];
          id[i] = member;
        }
      return id;
    }
    function getAllAvailablePhysicalItems() public view returns (PhysicalItem[] memory){
      PhysicalItem[]    memory id = new PhysicalItem[](_Physical_Item_index);
      for (uint i = 0; i < _Physical_Item_index; i++) {
          PhysicalItem storage member = physicalItems[i];
          if(member.total_sold < member.quantity){
            id[i] = member;
          }
          
        }
      return id;
    }

    function getBuyersFromPhysicalItemId(uint _id) public view onlyOwner returns (BuyerInfo[] memory){
        PhysicalItem storage item = physicalItems[_id];
        BuyerInfo[] memory id = new BuyerInfo[](item.buyersId.length);
      for (uint i = 0; i < item.buyersId.length; i++) {
          BuyerInfo storage member = buyerslist[i];
          id[i] = member;
        }
      return id;
    }

    function buyPhysical_item(uint _id, string memory fullname, string memory p_address, string memory country,string memory email) public {
        PhysicalItem storage item = physicalItems[_id];
        require(item.total_sold < item.quantity, "Sold");
        uint256 bal = gumToken.balanceOf(msg.sender);
        require(bal >= item.price, "You donot have enough tokens to buy this.");
        gumToken.transferFrom(msg.sender,gumFundingaddress, item.price); 

        BuyerInfo storage _buyer = buyerslist[buyersCount];
        _buyer.fullname = fullname;
        _buyer.p_address = p_address;
        _buyer.country = country;
        _buyer.email = email;

        item.buyersId.push(buyersCount);

        unchecked {
            buyersCount++;
            item.total_sold++;
        }      
    }
}