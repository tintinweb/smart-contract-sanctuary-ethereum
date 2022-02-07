/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;




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



/** 
 * @title TheGutter
 * @dev Marketplace contract for GutterPunk NFTs
 */
contract TheGutter is Ownable {
    
    event Withdrew(uint256 balance);
   
    struct Listing {
        address listedBy; // address of user that listed the token
        uint256 listedPrice; // price in ether
        bool listingActive;
    }

    mapping(uint256 => Listing) public listings;
    bool public _marketplaceOpen = false; 
    bool public _marketplacePermanentlyClosed = false; 
    address _contAddress = address(0x0); 
    uint256 public _royaltyFee = 5;

    constructor() { }
    
    /** 
     * @dev 
     * @param contAddress address of token to be traded on marketplace
     */
    function setTokenContract(address contAddress) external onlyOwner {
        require(contAddress != address(0x0), "Address cannot be the zero address.");
        _contAddress = contAddress; 
    }

    /** 
     * @dev Toggles if market is open or closed.
     */
    function toggleMarketOpen() external onlyOwner {
        require(!_marketplacePermanentlyClosed, "The Gutter is permanently closed.");
        require(_contAddress != address(0x0), "GutterPunk contract address must be set to open.");
        _marketplaceOpen = !_marketplaceOpen;
    }
    
    /** 
     * @dev Toggles if market is open or closed.
     */
    function permanentlyClose() external onlyOwner {
        require(!_marketplaceOpen, "The Gutter must be closed to shutdown permanently.");
        _marketplacePermanentlyClosed = true;
    }

    function list(uint256 tokenId, uint256 listedPrice) external { 
        require(listedPrice > 0, "Listing price must be greater than zero.");
        GutterPunks gp = GutterPunks(_contAddress);
        require(msg.sender == gp.ownerOf(tokenId), "You must own the GutterPunk to list.");
        require(gp.getApproved(tokenId) == address(this) || gp.isApprovedForAll(gp.ownerOf(tokenId), address(this)), "The Gutter is not approved to access this GutterPunk");

        listings[tokenId].listingActive = true;
        listings[tokenId].listedBy = msg.sender;
        listings[tokenId].listedPrice = listedPrice;
    }

    function delist(uint256 tokenId) external { 
        GutterPunks gp = GutterPunks(_contAddress);
        require(msg.sender == gp.ownerOf(tokenId) || listings[tokenId].listedBy == msg.sender, "You must own the GutterPunk to delist.");

        listings[tokenId].listingActive = false;
        listings[tokenId].listedBy = address(0x0);
        listings[tokenId].listedPrice = 0;
    }

    /** 
     * @dev function used to purchase token from a seller
     * @param tokenId id of token to be purchased
     */
    function purchase(uint256 tokenId) external payable {
        require(!listings[tokenId].listingActive, "GutterPunk is not listed.");
        require(listings[tokenId].listedPrice > 0, "Listing price must be greater than zero.");
        require(listings[tokenId].listedPrice != msg.value * 1000000000000000000, "Payment amount is incorrect.");
        GutterPunks gp = GutterPunks(_contAddress);
        require(listings[tokenId].listedBy == gp.ownerOf(tokenId), "GutterPunk is no longer owned by the lister.");
        require(gp.getApproved(tokenId) == address(this) || gp.isApprovedForAll(gp.ownerOf(tokenId), address(this)), "The Gutter is not approved to access this GutterPunk");

        (bool success, ) = payable(listings[tokenId].listedBy).call{
            value: (msg.value * (1 - _royaltyFee)) / 100
        }("");
        require(success);
        gp.safeTransferFrom(gp.ownerOf(tokenId), msg.sender, tokenId);      
        listings[tokenId].listingActive = false;
        listings[tokenId].listedBy = address(0x0);
        listings[tokenId].listedPrice = 0;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdrew(balance);
    }
}


abstract contract GutterPunks {
    function getApproved(uint256 tokenId) virtual public returns (address operator);
    function safeTransferFrom(address from, address to, uint256 tokenId) virtual public;
    function ownerOf(uint256 tokenId) virtual public returns (address);
    function isApprovedForAll(address owner, address operator) virtual public returns (bool);
}