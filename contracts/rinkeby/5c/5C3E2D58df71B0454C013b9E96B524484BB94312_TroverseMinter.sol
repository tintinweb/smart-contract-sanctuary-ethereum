// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


interface INFTContract {
    function Mint(address _to, uint256 _quantity) external payable;
    function numberMinted(address owner) external view returns (uint256);
    function totalSupplyExternal() external view returns (uint256);
}


contract TroverseMinter is Ownable, ReentrancyGuard {

    INFTContract public NFTContract;

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant TOTAL_PLANETS = 10000;
    uint256 public constant MAX_MINT_PER_ADDRESS = 5;
    uint256 public constant RESERVED_PLANETS = 300;
    uint256 public constant RESERVED_OR_AUCTION_PLANETS = 7300;

    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 180 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP = 0.1 ether;

    uint256 public auctionSaleStartTime;
    uint256 public publicSaleStartTime;
    uint256 public whitelistPrice;
    uint256 public publicSalePrice;
    uint256 private publicSaleKey;

    mapping(address => uint256) public whitelist;

    uint256 public lastAuctionSalePrice = AUCTION_START_PRICE;
    mapping(address => uint256) public credits;
    EnumerableSet.AddressSet private _creditOwners;
    uint256 private _totalCredits = 0;
    uint256 private _totalCreditCount = 0;

    event CreditRefunded(address indexed owner, uint256 value);
    
    

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() { }

    /**
    * @dev Set the NFT contract address
    */
    function setNFTContract(address _NFTContract) external onlyOwner {
        NFTContract = INFTContract(_NFTContract);
    }

    /**
    * @dev Try to mint NFTs during the dutch auction sale
    *      Based on the price of last mint, extra credits could be refunded after the auction finshied
    *      Any extra funds will be transferred back to the sender's address
    */
    function auctionMint(uint256 quantity) external payable callerIsUser {
        require(auctionSaleStartTime != 0 && block.timestamp >= auctionSaleStartTime, "Sale has not started yet");
        require(totalSupply() + quantity <= RESERVED_OR_AUCTION_PLANETS, "Not enough remaining reserved for auction to support desired mint amount");
        require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS, "Can not mint this many");

        lastAuctionSalePrice = getAuctionPrice();
        uint256 totalCost = lastAuctionSalePrice * quantity;

        if (lastAuctionSalePrice > AUCTION_END_PRICE) {
            _creditOwners.add(msg.sender);

            credits[msg.sender] += totalCost;
            _totalCredits += totalCost;
            _totalCreditCount += quantity;
        }

        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(totalCost);
    }
    
    /**
    * @dev Try to mint NFTs during the whitelist phase
    *      Any extra funds will be transferred back to the sender's address
    */
    function whitelistMint(uint256 quantity) external payable callerIsUser {
        require(whitelistPrice != 0, "Whitelist sale has not begun yet");
        require(whitelist[msg.sender] > 0, "Not eligible for whitelist mint");
        require(whitelist[msg.sender] >= quantity, "Can not mint this many");
        require(totalSupply() + quantity <= TOTAL_PLANETS, "Reached max supply");

        whitelist[msg.sender] -= quantity;
        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(whitelistPrice * quantity);
    }

    /**
    * @dev Try to mint NFTs during the public sale
    *      Any extra funds will be transferred back to the sender's address
    */
    function publicSaleMint(uint256 quantity, uint256 key) external payable callerIsUser {
        require(publicSaleKey == key, "Called with incorrect public sale key");

        require(isPublicSaleOn(), "Public sale has not begun yet");
        require(totalSupply() + quantity <= TOTAL_PLANETS, "Reached max supply");
        require(numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS, "Can not mint this many");

        NFTContract.Mint(msg.sender, quantity);
        refundIfOver(publicSalePrice * quantity);
    }

    /**
    * @dev Try to transfer back extra funds, if the paying amount is more than the needed cost
    */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Insufficient funds");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
    * @dev Check if the public sale is active
    */
    function isPublicSaleOn() public view returns (bool) {
        return publicSalePrice != 0 && block.timestamp >= publicSaleStartTime && publicSaleStartTime != 0;
    }

    /**
    * @dev Calculate auction price 
    */
    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < auctionSaleStartTime) {
            return AUCTION_START_PRICE;
        }
        
        if (block.timestamp - auctionSaleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionSaleStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    /**
    * @dev Set the dutch auction start time
    */
    function setAuctionSaleStartTime(uint256 timestamp) external onlyOwner {
        auctionSaleStartTime = timestamp;
    }

    /**
    * @dev Set the price for the whitlisted buyers
    *      Whitelist sale will be active if the price is not 0
    */
    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    /**
    * @dev Set the price for the public sale
    */
    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    /**
    * @dev Set the public sale start time
    */
    function setPublicSaleStartTime(uint256 timestamp) external onlyOwner {
        publicSaleStartTime = timestamp;
    }

    /**
    * @dev Set the key for accessing the public sale
    */
    function setPublicSaleKey(uint256 key) external onlyOwner {
        publicSaleKey = key;
    }

    /**
    * @dev Adding or updating new whitelisted wallets
    */
    function addWhitelist(address[] memory addresses, uint256 limit) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = limit;
        }
    }

    /**
    * @dev Mint the reserved planets, which will be used for promotions, marketing, strategic partnerships, giveaways, airdrops and also for Troverse team allocation
    */
    function reserveMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= RESERVED_PLANETS, "Too many already minted before dev mint");
        NFTContract.Mint(msg.sender, quantity);
    }

    /**
    * @dev Check if the auction refund price is finalized
    */
    function isAuctionPriceFinalized() public view returns(bool) {
        return totalSupply() >= RESERVED_OR_AUCTION_PLANETS || lastAuctionSalePrice == AUCTION_END_PRICE;
    }

    /**
    * @dev Get remaining credits to refund after the auction phase
    */
    function getRemainingCredits(address owner) external view returns(uint256) {
        if (credits[owner] > 0) {
            return credits[owner] - lastAuctionSalePrice * numberMinted(owner);
        }
        return 0;
    }
    
    /**
    * @dev Get total remaining credits to refund after the auction phase
    */
    function getTotalRemainingCredits() public view returns(uint256) {
        return _totalCredits - lastAuctionSalePrice * _totalCreditCount;
    }
    
    /**
    * @dev Get the maximum possible credits to refund after the auction phase
    */
    function getMaxPossibleCredits() public view returns(uint256) {
        if (isAuctionPriceFinalized()) {
            return getTotalRemainingCredits();
        }

        return _totalCredits - AUCTION_END_PRICE * _totalCreditCount;
    }

    /**
    * @dev Refund remaining credits after the auction phase
    */
    function refundRemainingCredits() external nonReentrant {
        require(isAuctionPriceFinalized(), "Auction price is not finalized yet!");
        require(_creditOwners.contains(msg.sender), "Not a credit owner!");
        
        uint256 remaininCredits = credits[msg.sender];
        uint256 remaininCreditCount = numberMinted(msg.sender);
        uint256 toSendCredits = remaininCredits - lastAuctionSalePrice * remaininCreditCount;

        require(toSendCredits > 0, "No credits to refund!");

        delete credits[msg.sender];

        _creditOwners.remove(msg.sender);

        _totalCredits -= remaininCredits;
        _totalCreditCount -= remaininCreditCount;

        emit CreditRefunded(msg.sender, toSendCredits);

        require(payable(msg.sender).send(toSendCredits));
    }

    /**
    * @dev Refund the remaining ethereum balance for unclaimed addresses
    */
    function refundAllRemainingCreditsByCount(uint256 count) external onlyOwner {
        require(isAuctionPriceFinalized(), "Auction price is not finalized yet!");
        
        address toSendWallet;
        uint256 toSendCredits;
        uint256 remaininCredits;
        uint256 remaininCreditCount;
        
        uint256 j = 0;
        while (_creditOwners.length() > 0 && j < count) {
            toSendWallet = _creditOwners.at(0);
            
            remaininCredits = credits[toSendWallet];
            remaininCreditCount = numberMinted(toSendWallet);
            toSendCredits = remaininCredits - lastAuctionSalePrice * remaininCreditCount;
            
            delete credits[toSendWallet];
            _creditOwners.remove(toSendWallet);

            if (toSendCredits > 0) {
                require(payable(toSendWallet).send(toSendCredits));
                emit CreditRefunded(toSendWallet, toSendCredits);

                _totalCredits -= toSendCredits;
                _totalCreditCount -= remaininCreditCount;
            }
            j++;
        }
    }
    
    /**
     * @dev Withdraw all collected funds excluding the remaining credits
     */
    function withdrawAll(address to) external onlyOwner {
        uint256 maxPossibleCredits = getMaxPossibleCredits();
        require(address(this).balance > maxPossibleCredits, "No funds to withdraw");

        uint256 toWithdrawFunds = address(this).balance - maxPossibleCredits;
        require(payable(to).send(toWithdrawFunds), "Transfer failed");
    }
    
    /**
     * @dev Get total mints by an address
     */
    function numberMinted(address owner) public view returns (uint256) {
        return NFTContract.numberMinted(owner);
    }

    /**
     * @dev Get total supply from NFT contract
     */
    function totalSupply() public view returns (uint256) {
        return NFTContract.totalSupplyExternal();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
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