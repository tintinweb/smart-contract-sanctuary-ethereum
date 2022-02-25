/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)





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

interface IZangNFT {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function exists(uint256 _tokenId) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function zangCommissionAccount() external view returns (address);
    function platformFeePercentage() external view returns (uint16);
}

contract Marketplace is Pausable, Ownable {
    event TokenListed(
        uint256 indexed _tokenId,
        address indexed _seller,
        uint256 _listingId,
        uint256 amount,
        uint256 _price
    );

    event TokenDelisted(
        uint256 indexed _tokenId,
        address indexed _seller,
        uint256 _listingId
    );

    event TokenPurchased(
        uint256 indexed _tokenId,
        address indexed _buyer,
        address indexed _seller,
        uint256 _listingId,
        uint256 _amount,
        uint256 _price
    );

    IZangNFT public immutable zangNFTAddress;

    struct Listing {
        uint256 price;
        address seller;
        uint256 amount;
    }

    // (tokenId => (listingId => Listing)) mapping
    mapping(uint256 => mapping(uint256 => Listing)) public listings;
    mapping(uint256 => uint256) public listingCount;

    constructor(IZangNFT _zangNFTAddress) {
        zangNFTAddress = _zangNFTAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function listToken(uint256 _tokenId, uint256 _price, uint256 _amount) external whenNotPaused {
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist");
        require(zangNFTAddress.isApprovedForAll(msg.sender, address(this)), "Marketplace: Marketplace contract is not approved");
        require(_amount <= zangNFTAddress.balanceOf(msg.sender, _tokenId), "Marketplace: not enough tokens to list");
        require(_amount > 0, "Marketplace: amount must be greater than 0");
        require(_price > 0, "Marketplace: price must be greater than 0");

        uint256 listingId = listingCount[_tokenId];
        listings[_tokenId][listingId] = Listing(_price, msg.sender, _amount);
        listingCount[_tokenId]++;
        emit TokenListed(_tokenId, msg.sender, listingId, _amount, _price);
    }

    function editListingAmount(uint256 _tokenId, uint256 _listingId, uint256 _amount, uint256 _expectedAmount) external whenNotPaused {
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist");
        require(zangNFTAddress.isApprovedForAll(msg.sender, address(this)), "Marketplace: Marketplace contract is not approved");
        // require(_listingId < listingCount[_tokenId], "Marketplace: listing ID out of bounds"); // Opt.
        require(listings[_tokenId][_listingId].seller == msg.sender, "Marketplace: can only edit own listings");
        require(_amount <= zangNFTAddress.balanceOf(msg.sender, _tokenId), "Marketplace: not enough tokens to list");
        require(_amount > 0, "Marketplace: amount must be greater than 0");
        // require(listings[_tokenId][_listingId].seller != address(0), "Marketplace: listing does not exist"); // Opt.
        require(listings[_tokenId][_listingId].amount == _expectedAmount, "Marketplace: expected amount does not match");

        listings[_tokenId][_listingId].amount = _amount;
        emit TokenListed(_tokenId, msg.sender, _listingId, _amount, listings[_tokenId][_listingId].price);
    }
    
    function editListing(uint256 _tokenId, uint256 _listingId, uint256 _price, uint256 _amount, uint256 _expectedAmount) external whenNotPaused {
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist");
        require(zangNFTAddress.isApprovedForAll(msg.sender, address(this)), "Marketplace: Marketplace contract is not approved");
        // require(_listingId < listingCount[_tokenId], "Marketplace: listing ID out of bounds"); // Opt.
        require(listings[_tokenId][_listingId].seller == msg.sender, "Marketplace: can only edit own listings");
        require(_amount <= zangNFTAddress.balanceOf(msg.sender, _tokenId), "Marketplace: not enough tokens to list");
        require(_amount > 0, "Marketplace: amount must be greater than 0");
        require(_price > 0, "Marketplace: price must be greater than 0");
        //require(listings[_tokenId][_listingId].seller != address(0), "Marketplace: listing does not exist"); // Opt.
        require(listings[_tokenId][_listingId].amount == _expectedAmount, "Marketplace: expected amount does not match");

        listings[_tokenId][_listingId] = Listing(_price, msg.sender, _amount);
        emit TokenListed(_tokenId, msg.sender, _listingId, _amount, _price);
    }

    function editListingPrice(uint256 _tokenId, uint256 _listingId, uint256 _price) external whenNotPaused {
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist");
        // require(_listingId < listingCount[_tokenId], "Marketplace: listing ID out of bounds"); // Opt.
        require(zangNFTAddress.isApprovedForAll(msg.sender, address(this)), "Marketplace: Marketplace contract is not approved");
        require(listings[_tokenId][_listingId].seller == msg.sender, "Marketplace: can only edit own listings");
        require(_price > 0, "Marketplace: price must be greater than 0");
        //require(listings[_tokenId][_listingId].seller != address(0), "Marketplace: listing does not exist"); // Opt.

        listings[_tokenId][_listingId].price = _price;
        emit TokenListed(_tokenId, msg.sender, _listingId, listings[_tokenId][_listingId].amount, _price);
    }

    function delistToken(uint256 _tokenId, uint256 _listingId) external whenNotPaused {
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist");
        require(zangNFTAddress.isApprovedForAll(msg.sender, address(this)), "Marketplace: Marketplace contract is not approved");
        // require(_listingId < listingCount[_tokenId], "Marketplace: listing ID out of bounds"); // Opt.
        //require(listings[_tokenId][_listingId].seller != address(0), "Marketplace: cannot interact with a delisted listing"); // Opt.
        require(listings[_tokenId][_listingId].seller == msg.sender, "Marketplace: can only remove own listings");

        _delistToken(_tokenId, _listingId);
    }

    function _removeListing(uint256 _tokenId, uint256 _listingId) private {
        delete listings[_tokenId][_listingId];
    }

    function _delistToken(uint256 _tokenId, uint256 _listingId) private {
        _removeListing(_tokenId, _listingId);
        emit TokenDelisted(_tokenId, msg.sender, _listingId);
    }

    function _handleFunds(uint256 _tokenId, address seller) private {
        uint256 value = msg.value;
        uint256 platformFee = (value * zangNFTAddress.platformFeePercentage()) / 10000;

        uint256 remainder = value - platformFee;

        (address creator, uint256 creatorFee) = zangNFTAddress.royaltyInfo(_tokenId, remainder);

        uint256 sellerEarnings = remainder;
        bool sent;

        if(creatorFee > 0) {
            sellerEarnings -= creatorFee;
            (sent, ) = payable(creator).call{value: creatorFee}("");
            require(sent, "Marketplace: could not send creator fee");
        }

        (sent, ) = payable(zangNFTAddress.zangCommissionAccount()).call{value: platformFee}("");
        require(sent, "Marketplace: could not send platform fee");

        (sent, ) = payable(seller).call{value: sellerEarnings}("");
        require(sent, "Marketplace: could not send seller earnings");
    }

    function buyToken(uint256 _tokenId, uint256 _listingId, uint256 _amount) external payable whenNotPaused {
        // If all copies have been burned, the token is deleted
        require(zangNFTAddress.exists(_tokenId), "Marketplace: token does not exist"); // Opt.
        require(_amount > 0, "Marketplace: _amount must be greater than 0");
        require(_listingId < listingCount[_tokenId], "Marketplace: listing index out of bounds"); // Opt.
        require(listings[_tokenId][_listingId].seller != address(0), "Marketplace: cannot interact with a delisted listing");
        require(listings[_tokenId][_listingId].seller != msg.sender, "Marketplace: cannot buy from yourself");
        require(_amount <= listings[_tokenId][_listingId].amount, "Marketplace: not enough tokens to buy");
        address seller = listings[_tokenId][_listingId].seller;
        // If seller transfers tokens "for free", their listing is still active! If they get them back they can still be bought
        require(_amount <= zangNFTAddress.balanceOf(seller, _tokenId), "Marketplace: seller does not have enough tokens");

        uint256 price = listings[_tokenId][_listingId].price;
        // check if listing is satisfied
        require(msg.value == price * _amount, "Marketplace: price does not match");

        // Update listing
        listings[_tokenId][_listingId].amount -= _amount;

        // Delist a listing if all tokens have been sold
        if (listings[_tokenId][_listingId].amount == 0) {
            _delistToken(_tokenId, _listingId);
        }

        emit TokenPurchased(_tokenId, msg.sender, seller, _listingId, _amount, price);

        _handleFunds(_tokenId, seller);
        zangNFTAddress.safeTransferFrom(seller, msg.sender, _tokenId, _amount, "");
    }
}