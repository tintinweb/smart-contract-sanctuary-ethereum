// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IERC4907.sol";
import "./IERC20WithPermit.sol";

contract Marketplace is ReentrancyGuard {
    struct Listing {
        address owner;
        address renter;
        address nftContract; // NFT contract address
        uint256 tokenId; // NFT id
        uint256 pricePerDay; // Price
        uint256 startDateUNIX; // Rental start date
        uint256 endDateUNIX; // Rental end date
        uint256 expiryDate; // Rental expiry date
    }
    // Translates contract address to token id, which is then mapped to the features of the rental listing
    mapping(address => mapping(uint256 => Listing)) private _listingMap;
    // Takes a list of tokens and converts NFT contracts into those tokens.
    mapping(address => EnumerableSet.UintSet) private _nftContractTokensMap;
    // A list of staking for each user address
    mapping(address => uint256) private stakingBalance;
    // Monitors the nft contracts that have been posted on the website.
    EnumerableSet.AddressSet private _nftContracts;

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// Variables
    Counters.Counter private _nftsListed;
    address private _marketplaceOwner;
    uint8 private _rentFee;
    IERC20WithPermit private _paymentToken;

    /// Modifiers
    modifier ownerOfIERC721(address nftContract, uint256 tokenId) {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "The following address is not the owner."
        );
        _;
    }
    modifier correctPrice(uint256 price) {
        require(price > 0, "The rental price should be greater than zero.");
        _;
    }
    modifier validateStartDate(uint256 date) {
        require(
            date >= block.timestamp,
            "The beginning date cannot be in the past."
        );
        _;
    }
    modifier validateEndDate(uint256 startDate, uint256 endDate) {
        require(
            endDate >= startDate,
            "The end date cannot be later than the beginning date."
        );
        _;
    }

    /// Events
    event NFTListed(
        address owner,
        address renter,
        address nftContract,
        uint256 tokenId,
        string tokenURI,
        uint256 pricePerDay,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint256 expiryDate
    );
    event NFTUnlisted(
        address unlistSender,
        address nftContract,
        uint256 tokenId,
        uint256 refund
    );
    event NFTRented(
        address owner,
        address renter,
        address nftContract,
        uint256 tokenId,
        string tokenURI,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint256 expiryDate,
        uint256 rentalFee
    );

    constructor(address paymentTokenAddress, uint8 rentFee) {
        _marketplaceOwner = msg.sender;
        _paymentToken = IERC20WithPermit(paymentTokenAddress);
        _rentFee = rentFee;
    }

    /**
     * @notice List an NFT
     * @dev Modifiers
     * - Check the NFT is ERC4907 and ERC721 compliant
     * - Check if the owner of the NFT is on the list.
     * - Check if the listing properties (i.e., price, start date, and end date) are valid values.
     * - Check if the owner has enough balance in the ETH wallet to cover the listing fee.
     * - Check if the NFT has not already been listed.
     * - To protect against reentrancy attacks.
     * @param nftContract  Contract address
     * @param tokenId  Generated token id
     * @param pricePerDay  Price/day
     * @param startDateUNIX  UNIX timestamp start date
     * @param endDateUNIX  UNIX timestamp expiry date
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 pricePerDay,
        uint256 startDateUNIX,
        uint256 endDateUNIX
    )
        external
        ownerOfIERC721(nftContract, tokenId)
        correctPrice(pricePerDay)
        validateStartDate(startDateUNIX)
        validateEndDate(startDateUNIX, endDateUNIX)
        nonReentrant
    {
        require(
            isRentableNFT(nftContract),
            "The contract is not ERC4907 protocol."
        );
        require(
            _listingMap[nftContract][tokenId].nftContract == address(0),
            "This NFT was included on the list before."
        );
        _listingMap[nftContract][tokenId] = Listing(
            msg.sender,
            address(0),
            nftContract,
            tokenId,
            pricePerDay,
            startDateUNIX,
            endDateUNIX,
            0
        );
        _nftsListed.increment();
        EnumerableSet.add(_nftContractTokensMap[nftContract], tokenId);
        EnumerableSet.add(_nftContracts, nftContract);
        string memory _tokenURI = IERC721Metadata(nftContract).tokenURI(tokenId);

        emit NFTListed(
            IERC721(nftContract).ownerOf(tokenId),
            address(0),
            nftContract,
            tokenId,
            _tokenURI,
            pricePerDay,
            startDateUNIX,
            endDateUNIX,
            0
        );
    }

    /// @dev A helper function for determining whether the token contract meets the standard.
    function isRentableNFT(address nftContract) private view returns (bool) {
        bool _isRentable = false;
        bool _isNFT = false;
        try
            IERC165(nftContract).supportsInterface(type(IERC4907).interfaceId)
        returns (bool rentable) {
            _isRentable = rentable;
        } catch {
            return false;
        }
        try
            IERC165(nftContract).supportsInterface(type(IERC721).interfaceId)
        returns (bool nft) {
            _isNFT = nft;
        } catch {
            return false;
        }
        return _isRentable && _isNFT;
    }

    /**
     * @notice Unlist your rental from an NFT (Also refunding user, if there is lost time)
     * @dev Modifiers
     * - To protect against reentrancy attacks
     * @param nftContract  Contract address
     * @param tokenId  Generated token id
     */
    function unlistNFT(address nftContract, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        Listing storage listing = _listingMap[nftContract][tokenId];
        require(
            listing.owner != address(0),
            "This NFT is not included in the list."
        );
        require(
            listing.owner == msg.sender || _marketplaceOwner == msg.sender,
            "The request to delist NFT was denied because you are the owner or not the renter of this NFT"
        );
        // The fee will be returned to the user if the listing is taken down before the end of the rental period,
        // but there will be no refund if there is no renter.
        uint256 refundAmount = 0;
        if (listing.renter != address(0)) {
            uint256 diff = listing.expiryDate - block.timestamp;
            uint256 perDiem = diff / 60 / 60 / 24 + 1;
            refundAmount = perDiem * listing.pricePerDay;
            refund(refundAmount, listing.renter);
        }
        // Remove user data
        IERC4907(nftContract).setUser(tokenId, address(0), 0);
        EnumerableSet.remove(_nftContractTokensMap[nftContract], tokenId);
        delete _listingMap[nftContract][tokenId];
        if (EnumerableSet.length(_nftContractTokensMap[nftContract]) == 0) {
            EnumerableSet.remove(_nftContracts, nftContract);
        }
        _nftsListed.decrement();

        emit NFTUnlisted(msg.sender, nftContract, tokenId, refundAmount);
    }

    function refund(uint256 value, address beneficiary) private returns (uint256 amount) {
        require(
            _paymentToken.balanceOf(msg.sender) >= value,
            "Could not proceed because there is not enough balance in your wallet to cover rental period"
        );
        amount = value;
        _paymentToken.transfer(beneficiary, amount);
    }

    /**
     * @notice Rent an NFT
     * @dev Modifiers
     * - To protect against reentrancy attacks
     * @param nftContract  Contract address
     * @param tokenId  Generated token id
     * @param expiryDate  Rental period
     *
     * Permit specs
     * // https://eips.ethereum.org/EIPS/eip-2612
     * @param deadline  blocktime for validity
     * @param v  secp256k1 (signature from owner of the message)
     * @param r  secp256k1 (signature from owner of the message)
     * @param s  secp256k1 (signature from owner of the message)
     */
    function rentNFT(
        address nftContract,
        uint256 tokenId,
        uint64 startDate,
        uint64 expiryDate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        Listing storage listing = _listingMap[nftContract][tokenId];
        require(
            listing.renter == address(0) ||
                block.timestamp > listing.expiryDate,
            "NFT has already been rented."
        );
        require(
            expiryDate <= listing.endDateUNIX,
            "The rental period exceeds the maximum date rentable."
        );
        // Transfer rental fee
        uint256 numDays = (expiryDate - startDate) / 60 / 60 / 24 + 1; // Calculate number of days
        uint256 rentalFee = listing.pricePerDay * numDays; // Total amount of fees
        safeTransfer(listing.owner, rentalFee, deadline, v, r, s);
        // Update listing
        IERC4907(nftContract).setUser(tokenId, msg.sender, expiryDate); // Set owner
        listing.renter = msg.sender; // Set renter
        listing.expiryDate = expiryDate; // Set NFT expiry date
        string memory _tokenURI = IERC721Metadata(nftContract).tokenURI(tokenId);

        emit NFTRented(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            nftContract,
            tokenId,
            _tokenURI,
            listing.startDateUNIX,
            listing.endDateUNIX,
            listing.expiryDate,
            rentalFee
        );
    }

    /**
     * @notice Retreive the list of all listed NFTs
     * @dev This is function will be used only for testing
     * WARNING:
     * This procedure will transfer everything from storage into memory, which may be a very costly endeavor. 
     * This is intended to be utilized by accessors the majority of the time since there are no gas expenses
     * associated with querying them. Developers need to keep in mind that this function has an unbounded cost
     * and that if they use it as part of a function that changes the state, the function might become uncallable 
     * if the set grows to the point where copying it to memory requires too much gas to fit in a block. 
     * This is something that should be kept in mind at all times.
     * 
     */
    function getAllListings() external view returns (Listing[] memory) {
        Listing[] memory listings = new Listing[](_nftsListed.current());
        uint256 listingsIndex = 0;
        address[] memory nftContracts = EnumerableSet.values(_nftContracts);
        for (uint256 i = 0; i < nftContracts.length; i++) {
            address nftAddress = nftContracts[i];
            uint256[] memory tokens = EnumerableSet.values(_nftContractTokensMap[nftAddress]);
            for (uint256 j = 0; j < tokens.length; j++) {
                listings[listingsIndex] = _listingMap[nftAddress][tokens[j]];
                listingsIndex++;
            }
        }
        return listings;
    }

    //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
    // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'
    //                              Transactions Functionalities
    //      .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.     .-.
    // `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'   `._.'
    
    /**
     * @notice Safe transfer from sender to recipient using eip-2612 permit extension
     * @dev Modifiers
     * - To protect against reentrancy attacks
     */
    function safeTransfer(
        address recipient,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (uint256 txValue) {
        require(
            _paymentToken.balanceOf(msg.sender) >= value,
            "Could not proceed because there is not enough balance in your wallet to cover rental period"
        );
        // Permit
        _paymentToken.permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        // Safe transfer from
        _paymentToken.transferFrom(msg.sender, address(this), value);
        // Staking balance
        uint256 fee = value * (_rentFee / 100);
        uint256 recipientTransaction = value - fee;
        stakingBalance[recipient] += recipientTransaction;
        stakingBalance[address(this)] += fee;

        txValue = recipientTransaction;
        return txValue;
    }

    /**
     * @notice Withdrawal contract balance
     * @dev Modifiers
     * - To protect against reentrancy attacks
     */
    function withdrawalContractBalance() external nonReentrant {
        // Check if sender is marketplace owner
        require(
            msg.sender == _marketplaceOwner,
            "User does not have permission to withdraw, you should be marketplace owner"
        );
        // Get user balance
        uint256 balance = stakingBalance[address(this)];
        require(
            balance > 0,
            "Could not proceed because there is not enough balance in contract wallet"
        );
        // Transfer contract balance
        _paymentToken.transfer(msg.sender, balance);
        // Update stacking balance of the user
        stakingBalance[address(this)] = 0;
    }

    function contractBalance() external view returns (uint256) {
        return stakingBalance[address(this)];
    }

    /**
     * @notice Withdrawal user balance
     * @dev Modifiers
     * - To protect against reentrancy attacks
     */
    function withdrawalUserBalance() external nonReentrant {
        uint256 userBalance = stakingBalance[msg.sender];
        require(
            userBalance > 0,
            "Could not proceed because staking balance cannot be 0"
        );
        _paymentToken.transfer(msg.sender, userBalance);
        stakingBalance[msg.sender] = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC4907 {
  // Logged when the user of a NFT is changed or expires is changed
  /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
  /// The zero address for user indicates that there is no user address
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

  /// @notice set the user and expires of a NFT
  /// @dev The zero address indicates there is no user
  /// Throws if `tokenId` is not valid NFT
  /// @param user  The new user of the NFT
  /// @param expires  UNIX timestamp, The new user could use the NFT before expires
  function setUser(uint256 tokenId, address user, uint64 expires) external;

  /// @notice Get the user address of an NFT
  /// @dev The zero address indicates that there is no user or the user is expired
  /// @param tokenId The NFT to get the user address for
  /// @return The user address for this NFT
  function userOf(uint256 tokenId) external view returns(address);

  /// @notice Get the user expires of an NFT
  /// @dev The zero value indicates that there is no user
  /// @param tokenId The NFT to get the user expires for
  /// @return The user expires for this NFT
  function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";

/**
 * @title IERC20WithPermit
 *
 * @notice Interface for the permit function (EIP-2612)
 **/
interface IERC20WithPermit is IERC20 {
    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";