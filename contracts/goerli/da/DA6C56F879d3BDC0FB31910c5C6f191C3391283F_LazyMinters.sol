//SPDX-License-Identifier:MIT

pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
// import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '../interface/INFT.sol';
import './Gallery.sol';
import './MarketPlace.sol';

import './NFTMarketInfo.sol';
import '../libraries/TokenStructLib.sol';

contract LazyMinters is ReentrancyGuard, Ownable {
	using ECDSA for bytes32;
	using Strings for uint256;
	using SafeMath for uint256;
	using TokenStructLib for TokenStructLib.TokenInfo;

	///@notice stores the metadata for lazy minting
	struct metaData {
		///@notice token uri of the nft to be minted
		string tokenUri;
		///@notice minimum price to be paid for minting
		uint256 minPrice;
		///@notice signature signed by the minters
		bytes signature;
		///@notice address of the gallery contract
		address gallery;
		///@notice address of artist of given nft
		address artist;
		///@notice commission for artist of the nft
		uint256 artistRoyalty;
		///@notice split for gallery owner in first sell of  nft
		uint256 gallerySplit;
		///@notice split for artist in first sell of  nft
		uint256 artistSplit;
		///@notice third party fee
		uint256 thirdPartyFee;
		///@notice time stamp for expiry of third party fee period
		uint256 feeExpiryTime;
		///@notice address of the thirdparty fee reciever
		address thirdParty;
		///@notice Boolean value for USD
		bool USD;
	}
	///@notice stores the minted status for given signature
	mapping(bytes32 => bool) isMinted;

	// /@notice stores the admin status for given address
	// mapping(address => bool) admins;

	INFT public nft;
	MarketPlace public marketPlace;
	IMarketPlace public Imarketplace;
	// AggregatorV3Interface public priceFeed;
	NFTMarketInfo public tokenInfo;

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	event Lazyminted(uint256 indexed _tokenid, address indexed _owner, address indexed _galleryContract, uint256 _price);

	constructor(
		address _nft,
		address payable _marketPlace,
		// address _aggregatorContract,
		address _nftMarketInfo
	) checkAddress(_nft) checkAddress(_marketPlace) // checkAddress(_aggregatorContract)
	{
		nft = INFT(_nft);
		marketPlace = MarketPlace(_marketPlace);
		tokenInfo = NFTMarketInfo(_nftMarketInfo);
		// admins[_marketPlace] = true;
		// priceFeed = AggregatorV3Interface(_aggregatorContract);
	}

	///@notice  Receive Ether
	receive() external payable {}

	///@notice mint lazy minted nfts
	///@param _metadata struct of meta data about nft
	///@param _sign signature signed by the minter/gallery owner
	///@dev payable function to  mint the lazy minted nft
	function mintNft(metaData calldata _metadata, bytes calldata _sign) external payable nonReentrant {
		bytes32 messageHash = getMessageHash(
			string(abi.encodePacked(_metadata.minPrice.toString(), ':', _metadata.tokenUri))
		);
		address minter = _verify(messageHash, _sign);
		require(!isMinted[messageHash], 'LazyMinter:Nft already minted');
		require(Gallery(payable(_metadata.gallery)).owner() == minter, 'LazyMinter:Nft params invalid');
		uint256 price = _metadata.minPrice;
		if (_metadata.USD) {
			price = tokenInfo.view_nft_price_native(price);
		}
		checkAmount(price, msg.sender);
		address platformAddress = tokenInfo.platformaddress();
		uint256 _galleryOwnerfee;
		uint256 _platformfee;
		uint256 _artistfee;
		uint256 _remaningfee;
		(_galleryOwnerfee, _artistfee, _platformfee, _remaningfee) = calculateCommissions(_metadata);
		transferfees(platformAddress, _platformfee);
		transferfees(minter, _galleryOwnerfee); //send to gallery owner address (minter is gallery owner address)
		transferfees(_metadata.artist, _artistfee);
		// transferfees(address(this), _remaningfee);
		uint256 tokenId = nft.mint(_metadata.tokenUri, msg.sender);
		nft.setArtistRoyalty(tokenId, _metadata.artist, uint96(_metadata.artistRoyalty));
		updateTokenInfo(tokenId, _metadata, msg.sender);
		emit Lazyminted(tokenId, msg.sender, _metadata.gallery, _metadata.minPrice);
	}

	// ///@notice calculate the equivalent matic from given dollar price
	// ///@dev uses chainlink data feed's function to get the lateset matic/usd rate and calculate matic( in wei)
	// ///@param priceindollar price in terms of dollar
	// ///@return priceinwei returns the value in terms of wei
	// function view_nft_price_native(uint256 priceindollar) public view returns (uint256) {
	// 	uint8 priceFeedDecimals = priceFeed.decimals();
	// 	uint256 precision = 1 * 10**18;
	// 	uint256 price = uint256(getLatestPrice());
	// 	uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
	// 	return requiredWei;
	// }

	///@notice verify the message signed and recover the signer address
	///@param _hashData signing message
	///@param _sign signature
	function _verify(bytes32 _hashData, bytes calldata _sign) public pure returns (address) {
		address minter = _hashData.toEthSignedMessageHash().recover(_sign);
		return minter;
	}

	///@notice get hash of message
	///@param _message message to be signed
	function getMessageHash(string memory _message) public pure returns (bytes32) {
		bytes32 messageHash = keccak256(abi.encodePacked(_message));
		return messageHash;
	}

	///@notice change the nft contract address
	///@param _newNft new address of the nft contract
	///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner
	function changeNftAddress(address _newNft) public checkAddress(_newNft) onlyOwner {
		nft = INFT(_newNft);
	}

	// ///@notice change the aggregator contract address
	// ///@param _newaggregator new address of the aggregator contract
	// ///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner
	// function changeAggregatorAddress(address _newaggregator) public checkAddress(_newaggregator) onlyOwner {
	// 	priceFeed = AggregatorV3Interface(_newaggregator);
	// }

	///@notice change the marketplace contract address
	///@param _newMarketPlace new address of the market place contract
	///@dev change the address of the market place contract used for matic/usd conversion  and can only be called  by owner
	function changeMarketPlaceAddress(address payable _newMarketPlace) public checkAddress(_newMarketPlace) onlyOwner {
		marketPlace = MarketPlace(_newMarketPlace);
	}

	///@notice calculate the fees/commission rates to different parties
	///@param _metadata struct of meta data about nft
	///@dev internal utility function to calculate commission rate for different parties
	function calculateCommissions(metaData calldata _metadata)
		internal
		view
		returns (
			uint256 _galleryOwnerCommission,
			uint256 _artistCommission,
			uint256 _platformCommission,
			uint256 _remainingAmount
		)
	{
		uint256 price = _metadata.minPrice;
		if (_metadata.USD) {
			price = tokenInfo.view_nft_price_native(_metadata.minPrice);
		}
		uint256 platformfee = tokenInfo.platformfee();
		_platformCommission = cutPer10000(platformfee, price);
		uint256 newSellingPrice = price.sub(_platformCommission);
		_artistCommission = cutPer10000(_metadata.artistSplit, newSellingPrice);
		_galleryOwnerCommission = cutPer10000(_metadata.gallerySplit, newSellingPrice);
		_remainingAmount = newSellingPrice.sub(_artistCommission).sub(_galleryOwnerCommission);
		return (_galleryOwnerCommission, _artistCommission, _platformCommission, _remainingAmount);
	}

	///@notice calculate percent amount for given percent and total
	///@dev calculates the cut per 10000 fo the given total
	///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
	///@param _total total amount from which cut is to be calculated
	///@return cutAmount percentage amount calculated
	///@dev internal utility function to calculate percentage
	function cutPer10000(uint256 _cut, uint256 _total) internal pure returns (uint256 cutAmount) {
		if (_cut == 0) return 0;
		cutAmount = _total.mul(_cut).div(10000);
		return cutAmount;
	}

	///@notice transfer the fees/commission rates to different parties
	///@dev internal utility function to transfer fees
	// function transferfees(uint256 _tokenId) internal {
	function transferfees(address receiver, uint256 _amount) internal {
		(bool txSuccess, ) = receiver.call{ value: _amount }('');
		require(txSuccess, 'Failed to pay commission rates');
	}

	// ///@notice provides the latest matic/usd rate
	// ///@return price latest matictodollar rate
	// ///@dev uses the chain link data feed's function to get latest rate
	// function getLatestPrice() public view returns (int256) {
	// 	(, int256 price, , , ) = priceFeed.latestRoundData();
	// 	return price;
	// }

	///@notice check amount value send
	///@param sellingPrice selling price of the token
	///@param buyer address of the buyer
	///@dev checks the value sent with selling price and return excessive amount to the buyer address
	function checkAmount(uint256 sellingPrice, address buyer) internal {
		require(msg.value >= sellingPrice, 'LazyMinting:Insufficient amount');
		uint256 amountToRefund = msg.value - sellingPrice;
		transferfees(payable(buyer), amountToRefund);
	}

	function updateTokenInfo(
		uint256 _tokenId,
		metaData calldata _metadata,
		address _nftOwner
	) internal {
		address _galleryOwner = Gallery(payable(_metadata.gallery)).owner();
		TokenStructLib.TokenInfo memory Token = TokenStructLib.TokenInfo(
			_tokenId,
			1,
			0,
			_metadata.thirdPartyFee,
			_metadata.gallerySplit,
			_metadata.artistSplit,
			_metadata.feeExpiryTime,
			payable(_metadata.gallery),
			payable(_metadata.thirdParty),
			// payable(_metadata.artist),
			_nftOwner,
			false,
			false,
			false,
			payable(_galleryOwner)
		);

		tokenInfo.addTokenInfo(Token);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

library TokenStructLib {
	using TokenStructLib for TokenInfo;

	struct TokenInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 thirdPartyFee;
		uint256 galleryownerfee;
		uint256 artistfee;
		uint256 thirdPartyFeeExpiryTime;
		address gallery;
		address payable thirdParty;
		// address payable artist;
		address nftOwner;
		bool onSell;
		bool USD;
		bool onAuction;
		address payable galleryOwner;
	}
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface INFT {
	function mint(string calldata _tokenURI, address _to) external returns (uint256);

	function burn(uint256 _tokenId) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function ownerOf(uint256 tokenId) external view returns (address);

	function tokenURI(uint256 tokenId) external view returns (string memory);

	function approve(address to, uint256 tokenId) external;

	function setApprovalForAll(address operator, bool approved) external;

	// function getApproved(uint256 tokenId) external view returns (address);
	// function isApprovedForAll(address owner, address operator) external view returns (bool);
	// function manageMinters(address user, bool status) external;

	function addManagers(address _manager) external;

	function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address reciever, uint256 _rate);

	function setArtistRoyalty(
		uint256 _tokenId,
		address _receiver,
		uint96 _feeNumerator
	) external;

	function checkNft(uint256 _tokenId) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMarketPlace {
	// struct tokenMarketInfo {
	// 	uint256 tokenId;
	// 	uint256 totalSell;
	// 	uint256 minPrice;
	// 	uint256 artistRoyalty;
	// 	uint256 artistfee;
	// 	uint256 galleryownerfee;
	// 	uint256 thirdpartyfee;
	// 	uint256 feeExpiryTime;
	// 	bool onSell;
	// 	address payable galleryOwner;
	// 	address payable artist;
	// 	address payable thirdParty;
	// 	bool USD;
	// 	address owner;
	// }

	// struct feeInfo {
	// 	uint256 totalartistfee;
	// 	// uint256 totalgalleryownerfee;
	// 	uint256 totalplatformfee;
	// 	uint256 totalthirdpartyfee;
	// }

	event Nftonsell(uint256 indexed _tokenid, uint256 indexed _price);
	event Nftbought(uint256 indexed _tokenid, address indexed _seller, address indexed _buyer, uint256 _price);
	event Cancelnftsell(uint256 indexed _tokenid);

	/*@notice buy the token listed for sell 
     @param _tokenId id of token  */
	function buy(uint256 _tokenId, address _buyer) external payable;

	function addAdmin(address _admin) external;

	function addGallery(address _gallery, bool _status) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param _minprice minimum price to sell token*/
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		// uint256 _artistRoyalty,
		uint256 _expirytime,
		address thirdParty,
		address _gallery,
		// address _artist,
		bool USD
	) external;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelSell(uint256 _tokenId) external;

	///@notice resale the token
	///@param _tokenId id of the token to resale
	///@param _minPrice amount to be updated
	function resale(uint256 _tokenId, uint256 _minPrice) external;

	///@notice change the artist fee commission rate
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) external;

	///@notice change the gallery owner commssion rate
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) external;

	/* @notice  list tokena added on sale list */
	function listtokensforsale() external view returns (uint256[] memory);

	// //@notice get token info
	// //@params tokenId to get information about
	// function gettokeninfo(uint256 _tokenId) external view returns (tokenMarketInfo memory);

	// function changePlatformAddress(address _platform) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGallery {
	struct TokenInfo {
		string uri;
		uint256 tokenId;
		uint256 minprice;
		uint256 feeExpiryTime;
		address thirdParty;
		bool onSell;
		address artist;
		bool hasPhysicalTwin;
		uint256 totalSell;
		bool USD;
	}
	///feeInfo for nft
	struct FeeInfo {
		uint256 artistFee;
		uint256 gallerySplit;
		uint256 artistSplit;
		uint256 thirdPartyFee;
	}

	event Nftadded(uint256 indexed nftid, address indexed _artist);
	event Nftminted(uint256 indexed _tokenId, address indexed _minter);
	event Nftburned(uint256 indexed _tokenId, address indexed _from);
	event Transfered(uint256 indexed _tokenId, address indexed _from, address indexed _to);
	event Nftmintedandsold(uint256 indexed _tokenId, address indexed _minter, uint256 indexed _price);
	event Nftmintedandairdrop(uint256 indexed _tokenId, address indexed _receiver, address indexed _owner);
	event Nftmintedandairdropwithverification(uint256 indexed _tokenId, address indexed _owner);
	event NftAirdropped(uint256 indexed _tokenId, address indexed _reciever);

	/*@notice add nft to gallery*/
	// function addNft(string calldata _uri, string calldata _name) external;

	/*@notice mint Nft
    @param nftid id of nft to mint
    @param _to address to mint the token */
	function mintNFT(string calldata uri, address artist) external returns (uint256 tokenId);

	function mintAndSellNft(
		string memory _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) external returns (uint256 tokenId);

	// /*@notice get nft details
	// @param nftid  id of  nft to get details*/
	// function getNftdetails(bytes32 _nftid)
	// 	external
	// 	view
	// 	returns (
	// 		string memory tokenuri,
	// 		address[] memory owner,
	// 		address minter
	// 	);

	/* @notice transfer nft
    @param from address of current owner
    @param to address of new owner */
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) external;

	/*@notice burn token
    @param _tokenid id of token to be burned */
	function burn(uint256 _tokenId) external;

	/*@notice buynft
    @param tokenid id of token to be bought*/
	function buyNft(uint256 tokenid) external payable;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelNftSell(uint256 _tokenid) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param amount minimum price to sell token*/
	function sellNft(
		uint256 tokenid,
		uint256 amount,
		FeeInfo memory feedata,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) external;

	/*@notice get token details
    @param tokenid  id of  token to get details*/
	function getTokendetails(uint256 tokenid)
		external
		view
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 galleryOwnerFee
		);

	//@notice get the list of token minted in gallery//
	function getListOfTokenIds() external view returns (uint256[] memory);

	//@notice get the list of nfts added in gallery//

	function retreiveBalance() external;
}

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

// import './StructDeclaration.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../interface/INFT.sol';
import '../libraries/TokenStructLib.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract NFTMarketInfo is ReentrancyGuard, Ownable {
	using SafeMath for uint256;

	uint256 public platformfee;
	address public platformaddress;

	uint256 public DECIMALS;

	uint256 public MAX_FEE = 1500;

	using TokenStructLib for TokenStructLib.TokenInfo;

	mapping(address => bool) public isManager;
	mapping(uint256 => TokenStructLib.TokenInfo) public TokenMarketInfo;
	INFT public nft;

	AggregatorV3Interface public priceFeed;

	constructor(
		address _nft,
		address _platformfeeaddress,
		address _priceFeed,
		uint256 decimals
	) {
		nft = INFT(_nft);
		priceFeed = AggregatorV3Interface(_priceFeed);
		platformfee = 450; // 4.5%
		platformaddress = _platformfeeaddress;
		DECIMALS = decimals;
	}

	modifier onlyManager() {
		require(isManager[msg.sender], 'NFTInfo:access-denied');
		_;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	modifier onlyManagerOrOwner() {
		require(isManager[msg.sender] || owner() == msg.sender, 'NFTInfo:access-denied');
		_;
	}

	///@notice function to add token info in a struct
	///@param tokeninfo struct of type TokenStructLib.TokenInfo to store nft/token related info
	///@dev stores all the nft related info and can only be called by managers
	function addTokenInfo(TokenStructLib.TokenInfo calldata tokeninfo) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[tokeninfo.tokenId];
		tokenInfo.tokenId = tokeninfo.tokenId;
		tokenInfo.totalSell = tokeninfo.totalSell;
		tokenInfo.minPrice = tokeninfo.minPrice;
		tokenInfo.thirdPartyFee = tokeninfo.thirdPartyFee;
		tokenInfo.galleryownerfee = tokeninfo.galleryownerfee;
		tokenInfo.artistfee = tokeninfo.artistfee;
		tokenInfo.thirdPartyFeeExpiryTime = tokeninfo.thirdPartyFeeExpiryTime;
		tokenInfo.gallery = tokeninfo.gallery;
		tokenInfo.thirdParty = tokeninfo.thirdParty;
		// tokenInfo.artist = tokeninfo.artist;
		tokenInfo.nftOwner = tokeninfo.nftOwner;
		tokenInfo.onSell = tokeninfo.onSell;
		// tokenInfo.onAuction = tokeninfo.onAuction;
		tokenInfo.USD = tokeninfo.USD;
		tokenInfo.galleryOwner = tokeninfo.galleryOwner;
	}

	///@notice function to update token info for sell
	///@param _tokenId id of the token to update info
	///@param _minPrice minimum selling price
	///@dev is called from marketplace contract (only managers can call)
	function updateForSell(
		uint256 _tokenId,
		uint256 _minPrice,
		bool USD
	) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = _minPrice;
		tokenInfo.USD = USD;
	}

	///@notice function to update token info for buy
	///@param _tokenId id of the token to update info
	///@param _owner new owner of nft
	///@dev is called from marketplace contract (only managers can call)
	function updateForBuy(uint256 _tokenId, address _owner) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = 0;
		tokenInfo.totalSell += 1;
		tokenInfo.onSell = false;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to update token info for cancel sell
	///@param _tokenId id of the token to update info
	///@dev is called from marketplace contract (only managers can call)
	function updateForCancelSell(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.onSell = false;
		tokenInfo.USD = false;
	}

	function updateForAuction(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		// tokenInfo.onAuction = false;
		tokenInfo.USD = false;
	}

	///@notice function to provide token related info
	///@param _tokenId id of the token to get info
	///@dev getter function
	function getTokenData(uint256 _tokenId)
		public
		view
		returns (
			TokenStructLib.TokenInfo memory tokenInfo // uint256 _minPrice,
		)
	{
		return TokenMarketInfo[_tokenId];
	}

	///@notice function to change galleryfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _galleryFee new gallery owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateGalleryFee(uint256 _tokenId, uint256 _galleryFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryownerfee = _galleryFee;
	}

	///@notice function to change artistfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _artistFee new artist owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateArtistFee(uint256 _tokenId, uint256 _artistFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryownerfee = _artistFee;
	}

	function addManagers(address _manager) public onlyOwner {
		isManager[_manager] = true;
	}

	///@notice change the aggregator contract address
	///@param _newaggregator new address of the aggregator contract
	///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner
	function changeAggregatorAddress(address _newaggregator) public checkAddress(_newaggregator) onlyOwner {
		priceFeed = AggregatorV3Interface(_newaggregator);
	}

	///@notice calculate the fees/commission rates to different parties
	///@param tokenId id of the token
	///@dev internal utility function to calculate commission rate for different parties
	function calculateCommissions(uint256 tokenId)
		public
		view
		returns (
			uint256 _galleryOwnercommission,
			uint256 artistcommssion,
			uint256 platformCommission,
			uint256 thirdPartyCommission,
			uint256 _remainingAmount,
			address artist
		)
	{
		TokenStructLib.TokenInfo memory tokenmarketInfo = TokenMarketInfo[tokenId];
		// tokenmarketInfo = tokenInfo.getTokenData(tokenId);

		uint256 sellingPrice = tokenmarketInfo.minPrice;

		if (tokenmarketInfo.USD) {
			sellingPrice = view_nft_price_native(tokenmarketInfo.minPrice);
		}
		platformCommission = cutPer10000(platformfee, sellingPrice);
		uint256 newSellingPrice = sellingPrice.sub(platformCommission);
		thirdPartyCommission;
		artistcommssion;
		uint256 _rate;
		address receiver;
		artist = receiver;
		(receiver, _rate) = nft.getRoyaltyInfo(uint256(tokenId), newSellingPrice);

		if (tokenmarketInfo.totalSell == 0) {
			artistcommssion = cutPer10000(tokenmarketInfo.artistfee, newSellingPrice);
			_galleryOwnercommission = cutPer10000(tokenmarketInfo.galleryownerfee, newSellingPrice);
			_remainingAmount = newSellingPrice.sub(artistcommssion).sub(_galleryOwnercommission);
		} else {
			artistcommssion = _rate;
			if (block.timestamp <= tokenmarketInfo.thirdPartyFeeExpiryTime) {
				thirdPartyCommission = cutPer10000(tokenmarketInfo.thirdPartyFee, newSellingPrice);
			} else thirdPartyCommission = 0;

			_remainingAmount = newSellingPrice.sub(_rate).sub(thirdPartyCommission);
		}

		return (
			_galleryOwnercommission,
			artistcommssion,
			platformCommission,
			thirdPartyCommission,
			_remainingAmount,
			artist
		);
	}

	///@notice change the platform address
	///@param _platform new platform address
	///@dev only owner can change the platform address
	function changePlatformAddress(address _platform) public onlyOwner checkAddress(_platform) {
		platformaddress = _platform;
	}

	///@notice change the platform commission rate
	///@param _amount new amount
	///@dev only owner can change the platform commission rate
	function changePlatformFee(uint256 _amount) public onlyOwner {
		require(_amount < MAX_FEE, 'Exceeded max platformfee');
		platformfee = _amount;
	}

	///@notice provides the latest matic/usd rate
	///@return price latest matictodollar rate
	///@dev uses the chain link data feed's function to get latest rate
	function getLatestPrice() public view returns (int256) {
		(, int256 price, , , ) = priceFeed.latestRoundData();
		return price;
	}

	///@notice calculate the equivalent matic from given dollar price
	///@dev uses chainlink data feed's function to get the lateset matic/usd rate and calculate matic( in wei)
	///@param priceindollar price in terms of dollar
	///@return priceinwei returns the value in terms of wei
	function view_nft_price_native(uint256 priceindollar) public view returns (uint256) {
		uint8 priceFeedDecimals = priceFeed.decimals();
		uint256 precision = 1 * 10**18;
		uint256 price = uint256(getLatestPrice());
		uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
		requiredWei = requiredWei / 10**DECIMALS;
		return requiredWei;
	}

	///@notice calculate percent amount for given percent and total
	///@dev calculates the cut per 10000 fo the given total
	///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
	///@param _total total amount from which cut is to be calculated
	///@return cutAmount percentage amount calculated
	///@dev internal utility function to calculate percentage
	function cutPer10000(uint256 _cut, uint256 _total) internal pure returns (uint256 cutAmount) {
		if (_cut == 0) return 0;
		cutAmount = _total.mul(_cut).div(10000);
		return cutAmount;
	}
}

//SPDX-License-Identifier: Unlicensed
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../interface/IMarketPlace.sol';
import '../interface/INFT.sol';
import './NFTMarketInfo.sol';
import '../libraries/TokenStructLib.sol';

pragma solidity 0.8.10;

contract MarketPlace is ReentrancyGuard, Ownable, IMarketPlace, IERC721Receiver, Multicall {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.UintSet;

	using TokenStructLib for TokenStructLib.TokenInfo;

	// uint256 public platformfee;
	uint256 public blockNumber;
	// address public platformaddress;

	uint256 public MAX_FEE = 1500;

	// uint256 public DECIMALS;

	INFT public nft;

	// AggregatorV3Interface public priceFeed;

	NFTMarketInfo public tokenInfo;

	// ///@notice provides  market information of particular tokenId
	// ///@dev map the tokenid with tokenMarketInfo struct
	// mapping(uint256 => tokenMarketInfo) public TokenMarketInfo;

	// mapping(uint256 => feeInfo) public TokenfeeInfo;

	///@notice checks whether the given address is added as Gallery or not
	mapping(address => bool) public isGallery;

	///@notice checks whether the given address is added as admin or not
	mapping(address => bool) public isAdmin;

	EnumerableSet.UintSet private tokenIdOnSell;

	constructor(
		address _nft,
		// address _platformfeeaddress,
		// address _aggregatorContract,
		address _tokenInfo
	)
		// uint256 decimals
		checkAddress(_nft)
		// checkAddress(_aggregatorContract)
		// checkAddress(_platformfeeaddress)
		checkAddress(_tokenInfo)
	{
		nft = INFT(_nft);
		tokenInfo = NFTMarketInfo(_tokenInfo);
		// platformfee = 450; // 4.5%
		// platformaddress = _platformfeeaddress;
		// priceFeed = AggregatorV3Interface(_aggregatorContract);
		isAdmin[msg.sender] = true;
		blockNumber = block.number;
		// DECIMALS = decimals;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyGalleryOrTokenOwner(uint256 _tokenId) {
		address owner = address(nft.ownerOf(_tokenId));
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);

		// tokenMarketInfo memory Tokeninfo = TokenMarketInfo[_tokenId];
		if (!isGallery[msg.sender] && owner != msg.sender && tokenmarketInfo.nftOwner != msg.sender) {
			revert('access-denied');
		}
		_;
	}

	///@notice to check whether the sender address is admin or not
	///@dev modifier to check whether the sender address is admin or not
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], 'admin-access-denied');
		_;
	}
	///@notice to check whether the sender address is admin or owner or not
	///@dev modifier to check whether the sender address is admin ,owner or  not
	modifier onlyAdminOrOwner() {
		require(isAdmin[msg.sender] || owner() == msg.sender, 'Should be owner/admin');
		_;
	}

	///@notice to check whether the sender address is token owner or not
	///@dev modifier to check whether the sender address token owner or not
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(nft.ownerOf(_tokenId) == msg.sender, 'Not-owner');
		_;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice  Receive Ether
	receive() external payable {}

	///@notice buy the given token id
	///@param _tokenId token id to be bought by the buyer
	///@param _buyer address of the buyer
	///@dev payable function
	function buy(uint256 _tokenId, address _buyer) public payable override nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;

		tokenmarketInfo = gettokeninfo(_tokenId);
		require(nft.checkNft(_tokenId), 'invalid TokenId');
		require(tokenmarketInfo.onSell, 'Not for sale');
		require(_buyer != tokenmarketInfo.nftOwner, 'owner cannot buy');

		uint256 sellingPrice = tokenmarketInfo.minPrice;
		if (tokenmarketInfo.USD) {
			sellingPrice = tokenInfo.view_nft_price_native(tokenmarketInfo.minPrice);
		}
		checkAmount(sellingPrice, _buyer);

		uint256 _galleryownerfee;
		uint256 _artistfee;
		uint256 _platformfee;
		uint256 _thirdpartyfee;
		uint256 ownerfee;
		address artist;

		(_galleryownerfee, _artistfee, _platformfee, _thirdpartyfee, ownerfee, artist) = tokenInfo.calculateCommissions(
			_tokenId
		);

		transferfees(artist, _artistfee);
		transferfees(tokenInfo.platformaddress(), _platformfee);
		transferfees(tokenmarketInfo.galleryOwner, _galleryownerfee);
		if (_thirdpartyfee > 0) transferfees(tokenmarketInfo.thirdParty, _thirdpartyfee);
		transferfees(tokenmarketInfo.nftOwner, ownerfee);

		nft.safeTransferFrom(address(this), _buyer, _tokenId);
		tokenInfo.updateForBuy(_tokenId, _buyer);
		tokenIdOnSell.remove(_tokenId);
		emit Nftbought(_tokenId, tokenmarketInfo.nftOwner, _buyer, sellingPrice);
	}

	///@notice check amount value send
	///@param sellingPrice selling price of the token
	///@param buyer address of the buyer
	///@dev checks the value sent with selling price and return excessive amount to the buyer address
	function checkAmount(uint256 sellingPrice, address buyer) internal {
		require(msg.value >= sellingPrice, 'Insufficient amount');
		uint256 amountToRefund = msg.value - sellingPrice;
		transferfees(payable(buyer), amountToRefund);
	}

	///@notice transfer the fees/commission rates to different parties
	///@dev internal utility function to transfer fees
	// function transferfees(uint256 _tokenId) internal {
	function transferfees(address receiver, uint256 _amount) internal {
		(bool txSuccess, ) = receiver.call{ value: _amount }('');
		require(txSuccess, 'Failed to pay commission rates');
	}

	// ///@notice calculate the fees/commission rates to different parties
	// ///@param tokenId id of the token
	// ///@dev internal utility function to calculate commission rate for different parties
	// function calculateCommissions(uint256 tokenId)
	// 	internal
	// 	view
	// 	returns (
	// 		uint256 _galleryOwnercommission,
	// 		uint256 artistcommssion,
	// 		uint256 platformCommission,
	// 		uint256 thirdPartyCommission,
	// 		uint256 _remainingAmount
	// 	)
	// {
	// 	TokenStructLib.TokenInfo memory tokenmarketInfo;
	// 	tokenmarketInfo = tokenInfo.getTokenData(tokenId);

	// 	uint256 sellingPrice = tokenmarketInfo.minPrice;

	// 	if (tokenmarketInfo.USD) {
	// 		sellingPrice = view_nft_price_matic(tokenmarketInfo.minPrice);
	// 	}
	// 	platformCommission = cutPer10000(platformfee, sellingPrice);
	// 	uint256 newSellingPrice = sellingPrice.sub(platformCommission);
	// 	thirdPartyCommission;
	// 	artistcommssion;

	// 	if (tokenmarketInfo.totalSell == 0) {
	// 		artistcommssion = cutPer10000(tokenmarketInfo.artistfee, newSellingPrice);
	// 		_galleryOwnercommission = cutPer10000(tokenmarketInfo.galleryownerfee, newSellingPrice);
	// 		_remainingAmount = newSellingPrice.sub(artistcommssion).sub(_galleryOwnercommission);
	// 	} else {
	// 		uint256 _rate;
	// 		address receiver;
	// 		(receiver, _rate) = nft.getRoyaltyInfo(uint256(tokenId), newSellingPrice);
	// 		artistcommssion = _rate;
	// 		if (block.timestamp <= tokenmarketInfo.thirdPartyFeeExpiryTime) {
	// 			thirdPartyCommission = cutPer10000(tokenmarketInfo.thirdPartyFee, newSellingPrice);
	// 		} else thirdPartyCommission = 0;

	// 		_remainingAmount = newSellingPrice.sub(_rate).sub(thirdPartyCommission);
	// 	}

	// 	return (_galleryOwnercommission, artistcommssion, platformCommission, thirdPartyCommission, _remainingAmount);
	// }

	///@notice set the nft for sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	///@param _artistfee commission rate to be transferred to artist while selling nft
	///@param _galleryownerfee commission rate to be transferred to gallery owner while selling nft
	///@param _thirdpartyfee commission rate to be transferred to thirdparty while selling nft
	///@param _expirytime time limit to pay third party commission fee
	// /@param _artist address of the artist of nft
	///@param _thirdParty address of the third party asssociated with nft
	///@param _gallery address of the gallery associated  with  nft
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by gallery or tokenOwner
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		uint256 _expirytime,
		address _thirdParty,
		address _gallery,
		// address _artist,
		bool USD
	) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		require(!gettokeninfo(_tokenId).onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');
		tokenIdOnSell.add(_tokenId);
		TokenStructLib.TokenInfo memory Token = TokenStructLib.TokenInfo(
			_tokenId,
			0,
			_minprice,
			_thirdpartyfee,
			_galleryownerfee,
			_artistfee,
			_expirytime,
			msg.sender,
			payable(_thirdParty),
			// payable(_artist),
			msg.sender,
			true,
			USD,
			false,
			payable(_gallery)
		);
		tokenInfo.addTokenInfo(Token);

		transferNft(_tokenId);

		emit Nftonsell(_tokenId, _minprice);
	}

	function transferNft(uint256 _tokenId) internal {
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, address(this), _tokenId);
	}

	///@notice set the nft for secondary sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	/// @param USD boolean value to indicate pricing is in dollar or not
	///@dev nft is set for sell after first sell
	function SecondarySell(
		uint256 _tokenId,
		uint256 _minprice,
		bool USD
	) public onlyTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);

		require(!tokenmarketInfo.onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');

		tokenIdOnSell.add(_tokenId);
		tokenInfo.updateForSell(_tokenId, _minprice, USD);
		transferNft(_tokenId);
		emit Nftonsell(_tokenId, _minprice);
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery  or token owner can cancel the sell of nft
	function cancelSell(uint256 _tokenId) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'Invalid TokenId');
		tokenIdOnSell.remove(_tokenId);
		tokenInfo.updateForCancelSell(_tokenId);
		nft.safeTransferFrom(address(this), msg.sender, _tokenId);
		emit Cancelnftsell(_tokenId);
	}

	///@notice get token info
	///@param _tokenId token id
	///@dev returns the tuple providing information about token
	function gettokeninfo(uint256 _tokenId) public view returns (TokenStructLib.TokenInfo memory tokenMarketInfo) {
		tokenMarketInfo = tokenInfo.getTokenData(_tokenId);
		return tokenMarketInfo;
	}

	///@notice list  all the token listed for sale
	function listtokensforsale() public view override returns (uint256[] memory) {
		return tokenIdOnSell.values();
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery  or token owner can change  the artist commission rate for given  nft
	function resale(uint256 _tokenId, uint256 _minprice) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateForSell(_tokenId, _minprice, tokenmarketInfo.USD);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistFee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateArtistFee(_tokenId, _artistFee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _galleryFee new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateGalleryFee(_tokenId, _galleryFee);
	}

	///@notice add the gallery address
	///@param _gallery address of the gallery to be added
	///@param _status status to set
	///@dev only Admin can the gallery
	function addGallery(address _gallery, bool _status) public override onlyAdmin {
		require(_gallery != address(0x0), '0x00 galleryaddress');
		isGallery[_gallery] = _status;
	}

	///@notice add new admins
	///@param _admin address to add as admin
	///@dev onlyOwner can add new admin
	function addAdmin(address _admin) public override onlyOwner {
		isAdmin[_admin] = true;
	}

	// ///@notice calculate percent amount for given percent and total
	// ///@dev calculates the cut per 10000 fo the given total
	// ///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
	// ///@param _total total amount from which cut is to be calculated
	// ///@return cutAmount percentage amount calculated
	// ///@dev internal utility function to calculate percentage
	// function cutPer10000(uint256 _cut, uint256 _total) internal pure returns (uint256 cutAmount) {
	// 	if (_cut == 0) return 0;
	// 	cutAmount = _total.mul(_cut).div(10000);
	// 	return cutAmount;
	// }

	// ///@notice calculate total amount accumulated
	// ///@param _add add to be added to previous total
	// ///@param _total previous total amount
	// ///@return totalAmount added sum
	// ///@dev internal utility function to add totals
	// function addTotal(uint256 _add, uint256 _total) internal pure returns (uint256 totalAmount) {
	// 	totalAmount = _total.add(_add);
	// }

	// ///@notice change the platform address
	// ///@param _platform new platform address
	// ///@dev only owner can change the platform address
	// function changePlatformAddress(address _platform) public override onlyOwner checkAddress(_platform) {
	// 	platformaddress = _platform;
	// }

	// ///@notice change the platform commission rate
	// ///@param _amount new amount
	// ///@dev only owner can change the platform commission rate
	// function changePlatformFee(uint256 _amount) public onlyOwner {
	// 	require(_amount < MAX_FEE, 'Exceeded max platformfee');
	// 	platformfee = _amount;
	// }

	// ///@notice provides the latest matic/usd rate
	// ///@return price latest matictodollar rate
	// ///@dev uses the chain link data feed's function to get latest rate
	// function getLatestPrice() public view returns (int256) {
	// 	(, int256 price, , , ) = priceFeed.latestRoundData();
	// 	return price;
	// }

	// ///@notice calculate the equivalent matic from given dollar price
	// ///@dev uses chainlink data feed's function to get the lateset matic/usd rate and calculate matic( in wei)
	// ///@param priceindollar price in terms of dollar
	// ///@return priceinwei returns the value in terms of wei
	// function view_nft_price_matic(uint256 priceindollar) public view returns (uint256) {
	// 	uint8 priceFeedDecimals = priceFeed.decimals();
	// 	uint256 precision = 1 * 10**18;
	// 	uint256 price = uint256(getLatestPrice());
	// 	uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
	// 	requiredWei = requiredWei / 10**DECIMALS;
	// 	return requiredWei;
	// }

	// ///@notice change the aggregator contract address
	// ///@param _contract new address of the aggregator contract
	// ///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner or admin
	// function changeAggregatorContract(address _contract) public onlyAdminOrOwner checkAddress(_contract) {
	// 	priceFeed = AggregatorV3Interface(_contract);
	// }

	// ///@notice change the decimal of  marketplace contract
	// ///@param _decimals new decimal  value
	// ///@dev change the decimals  and can only be called  by owner or admin
	// function changeMarketPlaceDecimal(uint256 _decimals) public onlyAdminOrOwner {
	// 	DECIMALS = _decimals;
	// }

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		// emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
	}

	// function changeThirdPartyAddress(uint256 _tokenId, address _account) public {
	// 	tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
	// 	TokenInfo.thirdParty = payable(_account);
	// }
}

//SPDX-License-Identifier: Unlicensed

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interface/IGallery.sol';
import '../interface/INFT.sol';
import '../interface/IMarketPlace.sol';

pragma solidity 0.8.10;

contract Gallery is ReentrancyGuard, Ownable, IGallery, Multicall, IERC721Receiver {
	///@notice map the given address with boolean
	///@dev checks whether the given address is added as admins or not
	mapping(address => bool) public admins;

	///@notice id of the gallery
	///@dev provides the unique id of this gallery
	string public id;

	///@notice address of the gallery owner
	///@dev provides the address of the gallery creator
	address public creator;

	///@dev instance of NFT contract
	INFT public nft;

	///@dev creates the instance of Marketplace contract
	IMarketPlace public market;

	///@notice blockNumber when contract is deployed
	///@dev provides blockNumber when contract is deployed
	uint256 public blockNumber;

	///@notice expirytime for airdrop in terms of hours
	uint256 public airDropTime;

	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.UintSet;

	constructor(
		string memory _id,
		address _owner, //gallery owner address
		address _nft,
		address _market
	)
		// address _dollarmarket
		checkAddress(_nft)
		checkAddress(_market)
	{
		id = _id;
		creator = _owner;
		nft = INFT(_nft);
		admins[_owner] = true;
		admins[msg.sender] = true;
		market = IMarketPlace(_market);
		transferOwnership(_owner);
		blockNumber = block.number;
		airDropTime = 72;
		// market_dollar = IMarketPlace(_dollarmarket);
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice to check whether the sender address is admin/owner or not
	///@dev modifier to check whether the sender address is admin/owner or not
	modifier _onlyAdminOrOwner(address _owner) {
		require(admins[_owner] || owner() == _owner, 'only owner/admin');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not
	///@dev modifier check whether the sender address is owner of given token id or not
	modifier onlyTokenOwner(uint256 tokenid) {
		address owner = address(nft.ownerOf(tokenid));
		require(owner == msg.sender, 'Only Token Owner');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyOwnerorTokenOwner(uint256 tokenid) {
		address tokenowner = nft.ownerOf(tokenid);
		if (tokenowner != msg.sender && owner() != msg.sender && !admins[msg.sender])
			revert('Only token-owner/gallery-owner');
		_;
	}

	struct AirDropInfo {
		uint256 tokenId;
		bytes32 verificationCode;
		bool isClaimed;
		address receiver;
		uint256 expiryTime;
	}

	EnumerableSet.UintSet private listOfTokenIds;
	EnumerableSet.UintSet private listOfTokenIdsForSale;
	EnumerableSet.UintSet private listofTokenAirDropped;

	mapping(uint256 => TokenInfo) public tokeninfo;
	mapping(uint256 => FeeInfo) public feeInfo;

	mapping(uint256 => AirDropInfo) public airDropInfo;

	receive() external payable {}

	///@notice Mint the nft through gallery
	///@param _uri token uri of the nft to be minted
	///@param _artist address of the artist of nft
	///@dev onlyAdmin or Owner of gallery can mint the nft
	function mintNFT(string memory _uri, address _artist)
		public
		override
		_onlyAdminOrOwner(msg.sender)
		nonReentrant
		returns (uint256)
	{
		uint256 tokenid = nft.mint(_uri, address(this));
		// if (owner() != creator) transferOwnership(creator);
		listOfTokenIds.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		emit Nftminted(tokenid, address(this));
		return tokenid;
	}

	///@notice burn the given token Id
	///@param _tokenId token id to burn
	///@dev only gallery owner or token owner can burn the given token id
	function burn(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		nft.burn(_tokenId);
		listOfTokenIds.remove(_tokenId);
		listOfTokenIdsForSale.remove(_tokenId);
		emit Nftburned(_tokenId, msg.sender);
	}

	///@notice transfer the given token Id
	///@param from address of current owner of the given tokenId
	///@param to address of new owner for the given tokenId
	///@param tokenId token id to transfer
	///@dev only gallery owner or token owner can transfer the given token id
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		nft.safeTransferFrom(from, to, tokenId);
		emit Transfered(tokenId, from, to);
	}

	///@notice buy the given token id
	///@param tokenid token id to be bought by the buyer
	///@dev payable function
	function buyNft(uint256 tokenid) public payable override nonReentrant {
		require(listOfTokenIds.contains(tokenid), 'Tokenid N/A');
		TokenInfo storage Token = tokeninfo[tokenid];
		require(Token.onSell, 'Not on sell');
		listOfTokenIdsForSale.remove(tokenid);
		Token.onSell = false;
		Token.minprice = 0;
		Token.USD = false;

		market.buy{ value: msg.value }(tokenid, msg.sender);
		Token.totalSell = Token.totalSell + 1;
	}

	///@notice set the nft for sell
	///@param tokenId token id to be listed for sale
	///@param amount selling price of the token id
	///@param feeData tuple value containing fee information about nft(artistFee,gallerySplit,artistSplit,thirdPartyfee)
	///@param _thirdParty address of the thirdparty to recieve royalty on nft sell form second sell onwards
	///@param _feeExpiryTime time period till the thirdparty will recieve the royalty
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by galleryOwner or tokenOwner
	function sellNft(
		uint256 tokenId,
		uint256 amount,
		FeeInfo memory feeData,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		require(listOfTokenIds.contains(tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[tokenId];
		FeeInfo storage fee = feeInfo[tokenId];
		Token.tokenId = tokenId;
		Token.minprice = amount;
		Token.onSell = true;
		fee.artistFee = feeData.artistFee;
		fee.artistSplit = feeData.artistSplit;
		fee.thirdPartyFee = feeData.thirdPartyFee;
		Token.hasPhysicalTwin = physicalTwin;
		Token.USD = USD;
		fee.gallerySplit = feeData.gallerySplit;
		listOfTokenIdsForSale.add(tokenId);
		nft.setApprovalForAll(address(market), true);
		if (Token.totalSell == 0) {
			nft.setArtistRoyalty(tokenId, Token.artist, uint96(feeData.artistFee));
			Token.thirdParty = _thirdParty;
			Token.feeExpiryTime = calculateExpiryTime(_feeExpiryTime);
		}
		market.sell(
			tokenId,
			amount,
			feeData.artistSplit,
			feeData.gallerySplit,
			feeData.thirdPartyFee,
			Token.feeExpiryTime,
			_thirdParty,
			creator,
			// Token.artist,
			USD
		);
	}

	///@notice mint the nft and list for sell
	///@param _uri token uri of the nft to be minted
	///@param artist address of the artist of nft
	///@param thirdParty address of the third party asssociated with nft
	///@param amount selling price of the token id
	///@param artistSplit spilt rate  artist will recieve while selling nft for first time
	///@param gallerySplit split rate to be transferred to gallery owner while selling nft
	///@param artistFee commission rate to be transferred to artist while selling nft
	///@param thirdPartyFee commission rate to be transferred to thirdparty while selling nft
	///@param feeExpiryTime time limit to pay third party commission fee
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@dev function to mint the  nft and list it for  sell in a single transaction
	function mintAndSellNft(
		string calldata _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) public override returns (uint256 _tokenId) {
		uint256 tokenId = mintNFT(_uri, artist);
		FeeInfo memory feedata = FeeInfo(artistFee, gallerySplit, artistSplit, thirdPartyFee);
		sellNft(
			tokenId,
			amount,
			feedata,
			// feeInfo{artistFee,gallerySplit,artistSplit,thirdPartyFee},
			thirdParty,
			feeExpiryTime,
			physicalTwin,
			true
		);
		emit Nftmintedandsold(tokenId, address(this), amount);
		return tokenId;
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery owner or token owner can cancel the sell of nft
	function cancelNftSell(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = 0;
		Token.onSell = false;
		Token.USD = false;
		listOfTokenIdsForSale.remove(_tokenId);
		market.cancelSell(_tokenId);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistfee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistCommission(uint256 _tokenId, uint256 _artistfee)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage Fee = feeInfo[_tokenId];
		Fee.artistFee = _artistfee;
		market.changeArtistFee(_tokenId, _artistfee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _gallerySplit new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryCommission(uint256 _tokenId, uint256 _gallerySplit)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage fee = feeInfo[_tokenId];
		fee.gallerySplit = _gallerySplit;
		market.changeGalleryFee(_tokenId, _gallerySplit);
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function reSaleNft(uint256 _tokenId, uint256 _minprice) public onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = _minprice;
		market.resale(_tokenId, _minprice);
	}

	///@notice list the token ids associated with this gallery
	function getListOfTokenIds() public view override returns (uint256[] memory) {
		return listOfTokenIds.values();
	}

	///@notice get the details of the given tokenid
	///@param tokenid id of the token whose detail is to be known
	function getTokendetails(uint256 tokenid)
		public
		view
		override
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 gallerySplit
		)
	{
		TokenInfo memory Token = tokeninfo[tokenid];
		FeeInfo memory fee = feeInfo[tokenid];
		address tokenowner = nft.ownerOf(tokenid);
		string memory uri = nft.tokenURI(tokenid);
		return (uri, tokenowner, Token.minprice, Token.onSell, fee.artistFee, fee.gallerySplit);
	}

	///@notice list the token ids listed for sale from this gallery
	function getListOfTokenOnSell() public view returns (uint256[] memory) {
		return listOfTokenIdsForSale.values();
	}

	///@notice retreive the balance accumulated with gallery contract
	///@dev only gallery owner can retreive the balance of gallery
	function retreiveBalance() public override onlyOwner nonReentrant {
		uint256 amount = address(this).balance;
		(bool success, ) = payable(msg.sender).call{ value: amount }(' ');
		require(success, 'Fail-to-retrieve');
	}

	///@notice initiate the airdrop feature
	///@dev approve the address to transfer nft on owner's behalf
	///@param _to address to approve
	///@param _tokenId tokenid to approve
	function manageAirDrop(address _to, uint256 _tokenId) public onlyOwner {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		listofTokenAirDropped.add(_tokenId);
		// require(!tokeninfo[tokenId].onSell, 'Token is on sell');
		nft.approve(_to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice initiate the airdrop feature with verification code
	///@dev add verification code associated with  particular artswap token
	///@param _randomstring random string used as code to verify airdrop
	///@param _tokenid token Id of artswap token to be dropped
	function manageAirDropWithVerification(string memory _randomstring, uint256 _tokenid)
		public
		_onlyAdminOrOwner(msg.sender)
	{
		require(listOfTokenIds.contains(_tokenid), 'N/A in this gallery');
		if (tokeninfo[_tokenid].onSell) cancelNftSell(_tokenid);
		listofTokenAirDropped.add(_tokenid);
		AirDropInfo storage airdrop = airDropInfo[_tokenid];
		airdrop.tokenId = _tokenid;
		airdrop.isClaimed = false;
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		airdrop.verificationCode = getHash(_randomstring);
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and approve the address to transfer nft on owner's behalf
	///@param to address to approve
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDrop(
		address to,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		// Token.nftId = _id;
		Token.artist = _artist;
		nft.approve(to, tokenid);
		emit Nftmintedandairdrop(tokenid, to, address(this));
		return tokenid;
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and store  the verification code to claim the airdropped token
	///@param _randomstring random string used as code to verify airdrop
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDropwithVerification(
		string memory _randomstring,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) nonReentrant returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		Token.feeExpiryTime = calculateExpiryTime(0);
		AirDropInfo storage airdrop = airDropInfo[tokenid];
		airdrop.tokenId = tokenid;
		airdrop.isClaimed = false;
		airdrop.verificationCode = getHash(_randomstring);
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		//  block.timestamp + airDropTime * 1 hours;
		emit Nftmintedandairdropwithverification(tokenid, address(this));
		return tokenid;
	}

	///@notice verify the airdrop feature enabled with verification code
	///@dev verify the verification code and transfer the specified tokenid to the specified new owner
	///@param _to new address to transfer the ownership
	///@param _tokenId nft id to transfer
	///@param _randomstring verification code associated with given nft
	function verifyAirDrop(
		address _to,
		uint256 _tokenId,
		string memory _randomstring
	) public {
		AirDropInfo storage airdrop = airDropInfo[_tokenId];
		bytes32 _code = getHash(_randomstring);
		require(airdrop.verificationCode == _code, 'Invalid Code');
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		require(block.timestamp <= airdrop.expiryTime, 'airdrop:expired');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		airdrop.isClaimed = true;
		airdrop.receiver = _to;
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, _to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice changes the airdrop expiration time in terms of hour
	///@param _newtime new time in terms of hours
	///@dev only Admin or gallery owner can change the airdrop expiration time
	function changeAirDropTime(uint256 _newtime) public _onlyAdminOrOwner(msg.sender) nonReentrant {
		airDropTime = _newtime;
	}

	///@notice calculate the expiry time
	///@param time expiry time in terms of hours
	///@dev utils function to calculate expiry time
	function calculateExpiryTime(uint256 time) private view returns (uint256) {
		// uint256 timeToAdd = time * 365;
		return (block.timestamp + time * 1 hours);
	}

	///@notice generate the hash value
	///@dev generate the keccak256 hash of given input value
	///@param _string string value whose hash is to be calculated
	function getHash(string memory _string) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_string));
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		// emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
	}
}