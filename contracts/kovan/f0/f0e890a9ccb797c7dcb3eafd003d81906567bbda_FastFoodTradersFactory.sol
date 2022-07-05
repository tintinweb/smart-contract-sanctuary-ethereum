/**
 *Submitted for verification at Etherscan.io on 2022-07-05
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/library/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    constructor(address withdrawAddress__) {
        _withdrawAddress = withdrawAddress__;
    }

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }

    function withdrawAddress() external view returns (address) {
        return _withdrawAddress;
    }
}
// File: contracts/library/IMintableNft.sol

interface IMintableNft {
    function mint(address to) external;
}

// File: contracts/library/Factory.sol





contract Factory is Ownable, Withdrawable {
    IMintableNft public nft;
    uint256 public pricePpm;
    bool whiteListEnabled = true;
    mapping(address => bool) whiteList;

    constructor(address nftAddress, uint256 pricePpm_)
        Withdrawable(msg.sender)
    {
        nft = IMintableNft(nftAddress);
        pricePpm = pricePpm_;
    }

    function mint(address to, uint256 count) external payable {
        if (whiteListEnabled) {
            require(
                whiteList[msg.sender],
                "mint enable only for whitelist at moment"
            );
        }
        uint256 needPriice = pricePpm * 1e15 * count;
        require(msg.value >= needPriice, "not enough ether value");
        for (uint256 i = 0; i < count; ++i) nft.mint(to);
    }

    function setPrice(uint256 newPricePpm) external onlyOwner {
        pricePpm = newPricePpm;
    }

    function setWhiteListEnabled(bool enabled) external onlyOwner {
        whiteListEnabled = enabled;
    }

    function addToWhiteList(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            whiteList[accounts[i]] = true;
        }
    }

    function removeFromWhiteList(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            whiteList[accounts[i]] = false;
        }
    }
}

// File: contracts/FastFoodTrader/FastFoodTradersFactory.sol



contract FastFoodTradersFactory is Factory {
    constructor(address nftAddress) Factory(nftAddress, 100) {}
}