/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
 contract Pausable is Ownable {
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
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/// @title Interface for ERC-721: Non-Fungible Tokens
interface InterfaceERC721 {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

   
}

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

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;

        address tokenAddress;
    }

    // Reference to contract tracking NFT ownership
    InterfaceERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute.
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        require(_isOnAuction(auction));

        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        address seller = auction.seller;

        // Remove the auction before sending the fees
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
          
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            payable(seller).transfer(sellerProceeds);
        }

        // Calculate any excess funds        
        uint256 bidExcess = _bidAmount - price;
        // Return the funds.
        payable(msg.sender).transfer(bidExcess);

        // Tell the world!
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns current price of an NFT on auction. 
    function _currentPrice(Auction memory _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        if (block.timestamp > _auction.startedAt) {
            secondsPassed = block.timestamp - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    /// @dev Computes the current price of an auction.    
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
  
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);          
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}


contract ClockAuction is Pausable, ClockAuctionBase {

     bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     constructor(address _nftAddress, uint256 _cut)  {
        require(_cut <= 10000);
        ownerCut = _cut;

        InterfaceERC721 candidateContract = InterfaceERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    /// @dev Remove all Ether from the contract, which is the owner's cuts
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(
            msg.sender == owner() ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        bool res = payable(nftAddress).send(address(this).balance);
        require(res == true, "transfer failed");
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller,
        address _tokenAddress
    )
        external virtual
        whenNotPaused
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp),
            _tokenAddress
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        external
        virtual 
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
        whenPaused
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction),"not in auction");
        address seller = auction.seller;
        require(msg.sender == seller,"not a seller");
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction),"not in auction");
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;
    
    // Tracks last 5 sale price of gen0 rocket sales
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) 
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller,
        address _tokenAddress
    )
        external override virtual

    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract),"Not a tokenContract");
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp),
            _tokenAddress
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId)
        external 
        virtual 
        override
        payable
    {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(nonFungibleContract)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Base is Context, ERC165, IERC721, IERC721Metadata , Pausable{
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

     // Base URI
    string private baseURI_;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual  returns (string memory) {
        return baseURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if(tokenId != 0){
            require(to != address(0), "ERC721: mint to the zero address");
        }
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

       /**
     * @dev function to set the contract URI
     * @param _baseTokenURI string URI prefix to assign
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        _setBaseURI(_baseTokenURI);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory _baseUri) internal virtual {
        baseURI_ = _baseUri;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseUri() public view returns (string memory) {
        return baseURI_;
    }    


}


contract RocketBase is ERC721Base("Rocket", "RocketDash") {

    /// @dev The Build event is fired whenever a new rocket comes into existence.
    event Build(address owner, uint256 rocketId, uint256 inventorModelId, uint256 architectModelId);

  
    struct Rocket {

        // The timestamp from the block when this rocketcame into existence.
        uint64 buildTime;

        // The minimum timestamp after which this rocket can able build
        // new rockets again.
        uint64 recoveryEndTime;

        // The ID of the originator of this rocket, set to 0 for gen0 rockets.
        uint32 inventorModelId;
        uint32 architectModelId;

        // Set to the ID of the architectModel rocketfor inventorModels that are preProduction,
        // zero otherwise. 
        uint32 ProcessingWithId;

        // Set to the index in the recovery array (see below) that represents
        // the current recovery duration for this Rocket. This starts at zero
        // for gen0 rockets, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful building action, regardless
        // of whether this rocketis acting as inventorModel or architectModel.
        uint16 recoveryIndex;

        // The "generation number" of this rocket.
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other rockets is the larger of the two generation
        // numbers of their originator, plus one.
        // (i.e. max(inventorModel.generation, architectModel.generation) + 1)
        uint16 generation;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table rocketing the recovery duration after any successful
    ///  building action, called "processing time" for inventorModels and "Processing recovery"
    ///  for architectModels. Designed such that the recovery roughly doubles each time a rocket
    ///  is build, encouraging owners not to just keep building the same rocketover
    ///  and over again. Caps out at one week (a rocketcan build an unbounded number
    ///  of times, and the maximum recovery is always seven days).
    uint32[14] public recovery = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    /*** STORAGE ***/

    /// @dev An array containing the Rocket struct for all rockets in existence. The ID
    ///  of each rocketis actually an index into this array. 
    Rocket[] rockets;

    /// @dev A mapping from RocketIDs to an address that has been approved to use
    ///  this Rocket for Processing via buildWith(). Each Rocket can only have one approved
    ///  address for Processing at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public architectModelAllowedToAddress;

    /// @dev The address of the ClockAuction contract that handles sales of rockets. This
    ///  same contract handles both peer-to-peer sales as well as the gen0 sales. 
    SaleClockAuction public saleAuction;

    constructor(){

    }

     function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);
        // once the rocket is transferred also clear architectModel allowances
        delete architectModelAllowedToAddress[tokenId];
    }

    /// @dev An internal method that creates a new rocket and stores it. This
    /// @param _inventorModelId The rocket ID of the inventorModel of this rocket(zero for gen0)
    /// @param _architectModelId The rocket ID of the architectModel of this rocket(zero for gen0)
    /// @param _generation The generation number of this rocket, must be computed by caller.
    /// @param _owner The inital owner of this rocket, must be non-zero (except for the unRocket, ID 0)
    function _createRocket(
        uint256 _inventorModelId,
        uint256 _architectModelId,
        uint256 _generation,
        address _owner
    )
        internal
        returns (uint)
    {

        require(_inventorModelId == uint256(uint32(_inventorModelId)));
        require(_architectModelId == uint256(uint32(_architectModelId)));
        require(_generation == uint256(uint16(_generation)));

        // New rocket starts with the same recovery as parent gen/2
        uint16 recoveryIndex = uint16(_generation / 2);
        if (recoveryIndex > 13) {
            recoveryIndex = 13;
        }

        Rocket memory _rocket = Rocket({
            buildTime: uint64(block.timestamp),
            recoveryEndTime: 0,
            inventorModelId: uint32(_inventorModelId),
            architectModelId: uint32(_architectModelId),
            ProcessingWithId: 0,
            recoveryIndex: recoveryIndex,
            generation: uint16(_generation)
        });
        rockets.push(_rocket);
        uint256 newrocketId =  rockets.length;

      
        require(newrocketId == uint256(uint32(newrocketId)));

        // emit the build event
        emit Build(
            _owner,
            newrocketId,
            uint256(_rocket.inventorModelId),
            uint256(_rocket.architectModelId)
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _mint(_owner, newrocketId);

        return newrocketId;
    }

    /// @notice Returns the total number of rockets currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return rockets.length - 1;
    }

    /// @notice Returns a list of all Rocket IDs assigned to an address.
    /// @param _owner The owner whose rockets we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Rocket array looking for rockets belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalRockets = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all rockets have IDs starting at 1 and increasing
            // sequentially up to the totalRocketcount.
            uint256 rocketId;

            for (rocketId = 1; rocketId <= totalRockets; rocketId++) {
                if (_owners[rocketId] == _owner) {
                    result[resultIndex] = rocketId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

  function setRecovery(uint32[14] calldata  _recovery) external onlyOwner {
        recovery = _recovery;
    }
}

contract RocketBuildBase is RocketBase{

    event Inventing(address owner, uint256 inventorModelId, uint256 architectModelId, uint256 recoveryEndTime);

    /// @notice The minimum payment required to use build new rocket 
    uint256 public autoBuildFee = 2e15;
    // platform charge percentage
    uint256 public charge = 10; // 10 equals 1% 
    // Keeps track of number of preProduction rocket.
    uint256 public preProductionRockets;
 
    /// @dev Checks that a given rocket is able to build. Requires that the
    ///  current recovery is finished (for architectModels) and also checks that there is
    ///  no pending processing.
    function _isReadyToBuild(Rocket memory _rocket) internal view returns (bool) {
        // In addition to checking the recoveryEndTime, we also need to check to see if
        // the rockethas a pending launch; there can be some period of time between the end
        // of the processing timer and the build event.
        return (_rocket.ProcessingWithId == 0) && (_rocket.recoveryEndTime <= uint64(block.timestamp));
    }

    /// @dev Check if a architectModel has authorized building with this inventorModel. True if both architectModel
    ///  and inventorModel have the same owner, or if the architectModel has given build permission to
    ///  the inventorModel's owner (via approveArchitectModel()).
    function _isArchitectModelPermitted(uint256 _architectModelId, uint256 _inventorModelId) internal view returns (bool) {
        address inventorModelOwner = _owners[_inventorModelId];
        address architectModelOwner = _owners[_architectModelId];

        // ArchitectModel is okay if they have same owner, or if the inventorModel's owner was given
        // permission to build with this architectModel.
        return (inventorModelOwner == architectModelOwner || architectModelAllowedToAddress[_architectModelId] == inventorModelOwner);
    }

    /// @dev Set the recoveryEndTime for the given Rocket, based on its current recoveryIndex.
    ///  Also increments the recoveryIndex (unless it has hit the cap).
    /// @param _rocket A reference to the Rocket in storage which needs its timer started.
    function _triggerRecovery(Rocket storage _rocket) internal {
        // Compute an estimation of the recovery time in blocks (based on current recoveryIndex).
        _rocket.recoveryEndTime = uint64((recovery[_rocket.recoveryIndex]) + block.timestamp);

        // Increment the building count, clamping it at 13
        if (_rocket.recoveryIndex < 13) {
            _rocket.recoveryIndex += 1;
        }
    }

    /// @notice Grants approval to another user to architectModel with one of your Rocket.
    /// @param _addr The address that will be able to  create new rocket using architectModel with your Rocket. Set to
    ///  address(0) to clear all Processing approvals for this Rocket.
    /// @param _architectModelId A Rocket that you own that _addr will now be able to architectModel with.
    function approveArchitectModel(address _addr, uint256 _architectModelId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _architectModelId));
        architectModelAllowedToAddress[_architectModelId] = _addr;
    }

    /// @dev Updates the minimum payment required for building new rocket. 
    function setAutoBuildFee(uint256 val) external onlyOwner {
        autoBuildFee = val;
    }

    /// @dev Checks to see if a given Rocket is preProduction and (if so) if the processing
    ///  period has passed.
    function _isReadyToLaunch(Rocket memory _inventorModel) private view returns (bool) {
        return (_inventorModel.ProcessingWithId != 0) && (_inventorModel.recoveryEndTime <= uint64(block.timestamp));
    }

    /// @notice Checks that a given rocket is able to build (i.e. it is not preProduction or
    ///  in the middle of a Processing recovery).
    /// @param _rocketId reference the id of the rocket, any user can inquire about it
    function isReadyToBuild(uint256 _rocketId)
        public
        view
        returns (bool)
    {
        require(_rocketId > 0);
        Rocket storage _rocket = rockets[_rocketId];
        return _isReadyToBuild(_rocket);
    }

    /// @dev Checks whether a rocket is currently preProduction.
    /// @param _rocketId reference the id of the rocket, any user can inquire about it
    function isInventing(uint256 _rocketId)
        public
        view
        returns (bool)
    {
        require(_rocketId > 0);
        // A rocket is preProduction if and only if this field is set
        return rockets[_rocketId].ProcessingWithId != 0;
    }

    /// @dev Internal check to see if a given architectModel and inventorModel are a valid inventor model.
    /// @param _inventorModel A reference to the Rocket struct of the potential inventorModel.
    /// @param _inventorModelId The inventorModel's ID.
    /// @param _architectModel A reference to the Rocket struct of the potential architectModel.
    /// @param _architectModelId The architectModel's ID
    function _isValidInventorModel(
        Rocket storage _inventorModel,
        uint256 _inventorModelId,
        Rocket storage _architectModel,
        uint256 _architectModelId
    )
        private
        view
        returns(bool)
    {
        // A Rocket can't build with itself!
        if (_inventorModelId == _architectModelId) {
            return false;
        }

        // Rocket can't build with inventor .
        if (_inventorModel.inventorModelId == _architectModelId || _inventorModel.architectModelId == _architectModelId) {
            return false;
        }
        if (_architectModel.inventorModelId == _inventorModelId || _architectModel.architectModelId == _inventorModelId) {
            return false;
        }

        // We can short circuit the  co model check (below) if either rocketis
        // gen zero (has a inventorModel ID of zero).
        if (_architectModel.inventorModelId == 0 || _inventorModel.inventorModelId == 0) {
            return true;
        }

        // Rocket can't build with full or half co models.
        if (_architectModel.inventorModelId == _inventorModel.inventorModelId || _architectModel.inventorModelId == _inventorModel.architectModelId) {
            return false;
        }
        if (_architectModel.architectModelId == _inventorModel.inventorModelId || _architectModel.architectModelId == _inventorModel.architectModelId) {
            return false;
        }

        return true;
    }

    /// @dev Internal check to see if a given architectModel and inventorModel are a valid inventor model for
    ///  building via auction (i.e. skips ownership and Processing approval checks).
    function _canBuildWithViaAuction(uint256 _inventorModelId, uint256 _architectModelId)
        internal
        view
        returns (bool)
    {
        Rocket storage inventorModel = rockets[_inventorModelId];
        Rocket storage architectModel = rockets[_architectModelId];
        return _isValidInventorModel(inventorModel, _inventorModelId, architectModel, _architectModelId);
    }

    /// @notice Checks to see if two rocket can build together, including checks for
    ///  ownership and Processing approvals. 
    /// @param _inventorModelId The ID of the proposed inventorModel.
    /// @param _architectModelId The ID of the proposed architectModel.
    function canBuildWith(uint256 _inventorModelId, uint256 _architectModelId)
        external
        view
        returns(bool)
    {
        require(_inventorModelId > 0);
        require(_architectModelId > 0);
        Rocket storage inventorModel = rockets[_inventorModelId];
        Rocket storage architectModel = rockets[_architectModelId];
        return _isValidInventorModel(inventorModel, _inventorModelId, architectModel, _architectModelId) &&
            _isArchitectModelPermitted(_architectModelId, _inventorModelId);
    }

    /// @dev Internal utility function to initiate building, assumes that all building
    ///  requirements have been checked.
    function _buildWith(uint256 _inventorModelId, uint256 _architectModelId) internal {
        // Grab a reference to the Rocket from storage.
        Rocket storage architectModel = rockets[_architectModelId];
        Rocket storage inventorModel = rockets[_inventorModelId];

        inventorModel.ProcessingWithId = uint32(_architectModelId);

        // Trigger the recovery for both inventor .
        _triggerRecovery(architectModel);
        _triggerRecovery(inventorModel);

        // Clear Processing permission for both inventor . This may not be strictly necessary
        delete architectModelAllowedToAddress[_inventorModelId];
        delete architectModelAllowedToAddress[_architectModelId];

        // Every time a new rocket gets in preProduction, counter is incremented.
        preProductionRockets++;

        // Emit the processing event.
        emit Inventing(_owners[_inventorModelId], _inventorModelId, _architectModelId, inventorModel.recoveryEndTime);
    }

    /// @notice Build a Rocket you own (as inventorModel) with a architectModel that you own, or for which you
    ///  have previously been given ArchitectModel approval. Will either make your rocket preProduction, or will
    ///  fail entirely. Requires a pre-payment of the fee given out to the first caller of giveBuild()
    /// @param _inventorModelId The ID of the Rocket acting as inventorModel (will end up preProduction if successful)
    /// @param _architectModelId The ID of the Rocket acting as architectModel (will begin its Processing recovery if successful)
    function buildNewRocket(uint256 _inventorModelId, uint256 _architectModelId)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBuildFee);

        // Caller must own the inventorModel.
        require(_owns(msg.sender, _inventorModelId));
      
        // Check that inventorModel and architectModel are both owned by caller, or that the architectModel
        // has given Processing permission to caller (i.e. inventorModel's owner).
        // Will fail for _architectModelId = 0
        require(_isArchitectModelPermitted(_architectModelId, _inventorModelId));

        // Grab a reference to the potential inventorModel
        Rocket storage inventorModel = rockets[_inventorModelId];

        // Make sure inventorModel isn't preProduction, or in the middle of a Processing recovery
        require(_isReadyToBuild(inventorModel));

        // Grab a reference to the potential architectModel
        Rocket storage architectModel = rockets[_architectModelId];

        // Make sure architectModel isn't preProduction, or in the middle of a Processing recovery
        require(_isReadyToBuild(architectModel));

        // Test that these rocket are a valid inventor model.
        require(_isValidInventorModel(
            inventorModel,
            _inventorModelId,
            architectModel,
            _architectModelId
        ));

        // All checks passed, rocket gets preProduction!
        _buildWith(_inventorModelId, _architectModelId);
    }

    /// @notice Have a preProduction Rocket give build!
    /// @param _inventorModelId A Rocket ready to give build.
    /// @return The Rocket ID of the new rocket.
    /// @dev Looks at a given Rocket and, if preProduction and if the processing period has passed,
    ///  combines the  of the two inventor  to create a new rocket. The new Rocket is assigned
    ///  to the current owner of the inventorModel. Upon successful completion, both the inventorModel and the
    ///  new rocket will be ready to build again. Note that anyone can call this function (if they
    ///  are willing to pay the gas!), but the new rocket always goes to the inventorModel's owner.
    function LaunchRocket(uint256 _inventorModelId)
        external
        whenNotPaused
        returns(uint256)
    {
        // Grab a reference to the inventorModel in storage.
        Rocket storage inventorModel = rockets[_inventorModelId];

        // Check that the inventorModel is a valid rocket.
        require(inventorModel.buildTime != 0);

        // Check that its time has come!
        require(_isReadyToLaunch(inventorModel));

        // Grab a reference to the architectModel in storage.
        uint256 architectModelId = inventorModel.ProcessingWithId;
        Rocket storage architectModel = rockets[architectModelId];

        // Determine the higher generation number of the two inventor 
        uint16 parentGen = inventorModel.generation;
        if (architectModel.generation > inventorModel.generation) {
            parentGen = architectModel.generation;
        }


        // Make the new rocket!
        address owner = _owners[_inventorModelId];
        uint256 rocketId = _createRocket(_inventorModelId, inventorModel.ProcessingWithId, parentGen + 1,  owner);

        delete inventorModel.ProcessingWithId;

        // Every time a rocket gives build counter is decremented.
        preProductionRockets--;

        // Send the balance fee to the person who made build happen.
        payable(msg.sender).transfer(autoBuildFee-(autoBuildFee*charge/1000));

        // return the new rocket's ID
        return rocketId;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (ownerOf(_tokenId) == _claimant);
    }

}

contract AuctionBase is RocketBuildBase {

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyOwner {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Put a rocket up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _rocketId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _tokenAddress
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If rocket is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _rocketId));
        // Ensure the rocket is not inventing to prevent the auction
        // contract accidentally receiving ownership of the child.
        // NOTE: the rocket IS allowed to be in a recovery.
        require(!isInventing(_rocketId));
        _approve(address(saleAuction),_rocketId);
        // Sale auction throws if inputs are invalid and clears
        // transfer and architectModel approval after escrowing the rocket.
        saleAuction.createAuction(
            _rocketId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender,
            _tokenAddress
        );
    }
    
    /// @dev Transfers the balance of the sale auction contract
    /// to the RocketCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyOwner {
        saleAuction.withdrawBalance();
    }
}

contract RocketdashMinting is AuctionBase {

    // Constants for gen0 auctions.
    uint256 public constant GEN0_STARTING_PRICE = 10e15;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

    // Counts the number of rockets the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;
    uint256 public elononeCreatedCount;

    uint256 public initTime;

    address elonone = 0x97b65710D03E12775189F0D113202cc1443b0aa2;
    uint256 elononeRequirement = 40000000000 * 10**9; // 40b

    // for future business collab partner rockets
    // vars needed to split mint fees with partners and set price, time frame
    uint256 mintPrice;
    uint256 mintInit;
    uint256 mintPeriod;
    address payable partnerAddress;
    address payable teamAddress;

    mapping(address => bool) hasMinted;

    constructor (string memory _baseUri) {
        _setBaseURI(_baseUri);
    }

    IERC20 _elonone = IERC20(elonone);

    // to stop bot smart contracts from frontrunning minting
    modifier noContract(address account) {
        require(Address.isContract(account) == false, "Contracts are not allowed to interact with the farm");
        _;
    }

    function initElononeMint() external onlyOwner {
        initTime = block.timestamp;
    }

    function mintElononeRocket() external noContract(msg.sender) {
        uint256 bal = _elonone.balanceOf(msg.sender);
        require(bal >= elononeRequirement, "you need more ELONONE!");
        require(block.timestamp < initTime + 3 days, "ELONONE mint is over!");
        require(!hasMinted[msg.sender], "already minted");
        _createRocket(0, 0, 0, msg.sender);
        hasMinted[msg.sender] = true;
        gen0CreatedCount++;
        elononeCreatedCount++;
    }

    // 1 partner mint event at a time only
    function initPartnershipMintWithParams(uint256 _mintPrice, uint256 _mintPeriod, address payable _partnerAddress, address payable _teamAddress) external onlyOwner {
        mintPrice = _mintPrice;
        mintInit = block.timestamp;
        mintPeriod = _mintPeriod;
        partnerAddress = _partnerAddress;
        teamAddress = _teamAddress;
    }

    function mintPartnershipRocket() external payable noContract(msg.sender) {
        require(block.timestamp < mintInit + mintPeriod, "mint is over");
        require(msg.value >= mintPrice, "not enough ether supplied");
        _createRocket(0, 0, 0, msg.sender);
        gen0CreatedCount++;
        uint256 divi = msg.value / 2;
        partnerAddress.transfer(divi);
        teamAddress.transfer(divi);
    }

    function createMultipleRocket(address[] memory _owner,uint256 _count) external onlyOwner {
        require(_owner.length == _count,"Invalid count of minting");
        uint i;
        for(i = 0; i < _owner.length; i++){

            address rocketOwner = _owner[i];
            if (rocketOwner == address(0)) {
                rocketOwner = owner();
            }

            promoCreatedCount++;
            _createRocket(0, 0, 0,  rocketOwner);
        }
    }

    /// @dev Creates a new gen0 rocket
    ///  creates an auction for it.
    function createGen0Auction(address _tokenAddress) external onlyOwner {

        uint256 rocketId = _createRocket(0, 0, 0, address(this));
        _approve(address(saleAuction), rocketId);

        saleAuction.createAuction(
            rocketId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this),
            _tokenAddress
        );

        gen0CreatedCount++;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don't overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));
        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }
        return nextPrice;
    }


    /// @notice Returns all the relevant information about a specific rocket.
    /// @param _id The ID of the rocket of interest.
    function getRocket(uint256 _id)
        external
        view
        returns (
        bool isProcessing,
        bool isReady,
        uint256 recoveryIndex,
        uint256 nextActionAt,
        uint256 ProcessingWithId,
        uint256 buildTime,
        uint256 inventorModelId,
        uint256 architectModelId,
        uint256 generation
    ) {
        Rocket storage _rocket = rockets[_id];

        // if this variable is 0 then it's not building 
        isProcessing = (_rocket.ProcessingWithId != 0);
        isReady = (_rocket.recoveryEndTime <= block.timestamp);
        recoveryIndex = uint256(_rocket.recoveryIndex);
        nextActionAt = uint256(_rocket.recoveryEndTime);
        ProcessingWithId = uint256(_rocket.ProcessingWithId);
        buildTime = uint256(_rocket.buildTime);
        inventorModelId = uint256(_rocket.inventorModelId);
        architectModelId = uint256(_rocket.architectModelId);
        generation = uint256(_rocket.generation);
    }

     // @dev Allows the owner to capture the balance available to the contract.
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        // Subtract all the currently preProduction rockets we have, plus 1 of margin.
        uint256 subtractFees = (preProductionRockets + 1) * autoBuildFee;

        if (balance > subtractFees) {
            payable(msg.sender).transfer(balance - subtractFees);
        }
    }
    
    // @dev allow contract to receive ether 
    receive () external payable {}

}