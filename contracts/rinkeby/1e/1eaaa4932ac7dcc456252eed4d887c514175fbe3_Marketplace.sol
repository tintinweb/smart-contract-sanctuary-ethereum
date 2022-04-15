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
pragma solidity ^0.8;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

struct Listing {
    string name;
    string linkUrl;
    string imgUrl;
    uint256 stock;
    uint256 initialAllocation;
    string description;
    uint256 limitPerAddress;
    string other;
}

interface xBandit {
    function balanceOf(address account) external view returns (uint256);
}

interface BanditStaking {
    function earned(uint256 tokenId) external view returns (uint256);

    function stakedTokensBy(address maybeOwner)
        external
        view
        returns (int256[3333] memory);
}

contract Marketplace is Ownable {
    mapping(address => uint256) addressToSpent;
    Listing[] public Listings;
    mapping(string => uint256) public NameToPrice;
    mapping(string => address[]) public NameToList;

    xBandit public xb;
    BanditStaking public staking;

    constructor() {}

    function setXBandit(address newAddy) public onlyOwner {
        xb = xBandit(newAddy);
    }

    function getListFor(string memory name) public view returns (address[] memory) {
        return NameToList[name];
    }

    function setBanditStaking(address newAddy) public onlyOwner {
        staking = BanditStaking(newAddy);
    }

    function addListing(
        string memory name,
        string memory linkUrl,
        string memory imgUrl,
        uint256 stock,
        uint256 initialAllocation,
        string memory description,
        uint256 limitPerAddress,
        string memory other,
        uint256 price
    ) public onlyOwner {
        Listings.push(
            Listing(
                name,
                linkUrl,
                imgUrl,
                stock,
                initialAllocation,
                description,
                limitPerAddress,
                other
            )
        );
        NameToPrice[name] = price;
    }

    function removeListing(string memory name) public onlyOwner {
        uint256 i = 0;
        uint256 len = Listings.length;

        for (i; i < len; i++) {
            if (equal(Listings[i].name, name)) {
                Listings[i] = Listings[len - 1];
                Listings.pop();
            }
        }

        delete NameToList[name];
    }

    function getListings() public view returns (Listing[] memory) {
        return Listings;
    }

    function setListingPrice(string memory name, uint256 price)
        public
        onlyOwner
    {
        NameToPrice[name] = price;
    }

    function buyListing(string memory name, address alice) public {
        uint256 currentBalance = balanceOf(msg.sender);

        require(
            currentBalance - addressToSpent[msg.sender] >= NameToPrice[name],
            "Insufficient funds"
        );

        require(alice != address(0), "Don't be a dick");

        uint256 i = 0;
        uint256 numSpots = 0;
        for (i; i < NameToList[name].length; i++) {
            if (NameToList[name][i] == alice) {
                numSpots++;
            }
        }

        i = 0;
        Listing memory listing;
        uint256 len = Listings.length;
        uint256 limit = 0;

        for (i; i < len; i++) {
            if (equal(Listings[i].name, name)) {
                listing = Listings[i];
            }
        }
        require(
            numSpots <= listing.stock,
            "This list is already full"
        );
        require(
            numSpots <= listing.limitPerAddress,
            "You have bought the maximum number of spots on this list"
        );

        addressToSpent[msg.sender] += NameToPrice[name];
        NameToList[name].push(alice);
    }

    function balanceOf(address alice) public view returns (uint256) {
        int256[3333] memory ownedTokens = staking.stakedTokensBy(alice);
        uint256 sum = 0;
        for (uint256 i = 0; i < 3333; i++) {
            int256 id = ownedTokens[i];

            if (id != -1) {
                sum += staking.earned(uint256(id));
            }
        }

        return xb.balanceOf(alice) + sum;
    }

    function addAddressToList(address alice, string memory name)
        public
        onlyOwner
    {
        NameToList[name].push(alice);
    }

    function earned(uint256 tokenId) public view returns (uint256) {
        return staking.earned(tokenId);
    }

    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string storage _a, string memory _b)
        internal
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string storage _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }
}