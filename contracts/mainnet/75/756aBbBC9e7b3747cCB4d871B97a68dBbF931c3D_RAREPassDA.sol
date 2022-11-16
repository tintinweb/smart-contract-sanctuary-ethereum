// SPDX-License-Identifer: MIT

/// @title RARE Pass DA
/// @notice contract to implement dutch auction mint functionality for the RARE Pass
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "Ownable.sol";
import "ReentrancyGuard.sol";

interface RAREPass {
    function mintExternal(address recipient) external returns(uint256);
    function totalSupply() external view returns(uint256);
}

contract RAREPassDA is Ownable, ReentrancyGuard {

    // state variables
    bool public saleOpen;
    bool private _auctionSet;
    address public payoutAddress;
    uint256 public mintAllowance;

    uint256 public maxSupply;
    uint256 public auctionSupply;

    uint256 public startingPrice;
    uint256 public endingPrice;
    uint256 public stepDuration;
    uint256 public stepSize;
    uint256 public numSteps;
    uint256 public startsAt;

    RAREPass public rareContract;

    mapping(address => uint256) private _numMinted;
    mapping(address => bool) private _ofacList;

    // events
    event Sale(address indexed contractAddress, uint256 indexed tokenId, uint256 indexed saleValueWei, address buyer);

    constructor(
        address payout,
        uint256 allowance,
        uint256 maxSupply_,
        uint256 auctionSupply_,
        address passContractAddress
    )
    Ownable()
    ReentrancyGuard()
    {   
        payoutAddress = payout;
        mintAllowance = allowance;
        maxSupply = maxSupply_;
        auctionSupply = auctionSupply_;
        rareContract = RAREPass(passContractAddress);
    }

    /// @notice function to add addresses to the OFAC disallow list
    /// @dev requires contract owner
    function addToOfacList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _ofacList[addresses[i]] = true;
        }
    }

    /// @notice function to set rare pass contract address
    /// @dev requires contract owner
    function setRarePassContract(address rarePass) external onlyOwner {
        rareContract = RAREPass(rarePass);
    }

    /// @notice funciton to set auction details
    /// @dev requires contract owner
    function setAuctionDetails(uint256 startPrice, uint256 endPrice, uint256 auctionDuration, uint256 numAuctionSteps) external onlyOwner {
        startingPrice = startPrice;
        endingPrice = endPrice;
        stepDuration = auctionDuration / numAuctionSteps;
        stepSize = (startPrice - endPrice) / (numAuctionSteps);
        numSteps = numAuctionSteps;
        _auctionSet = true;
    }

    /// @notice function to open the sale
    /// @dev requires contract owner
    function openSale() external onlyOwner {
        require(_auctionSet, "auction not set");
        startsAt = block.timestamp;
        saleOpen = true;
    }

    /// @notice function to close the sale
    /// @dev requires contract owner
    function closeSale() external onlyOwner {
        saleOpen = false;
    }

    /// @notice function to set mint allowance
    /// @dev requires contract owner
    /// @dev useful if the mint allowance needs to change
    function setMintAllowance(uint256 newMintAllowance) external onlyOwner {
        mintAllowance = newMintAllowance;
    }

    /// @notice function to set payout address
    /// @dev requires contract owner
    /// @dev useful if payout address need to change
    function setPayoutAddress(address newPayoutAddress) external onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    /// @notice function to mint to a wallet
    /// @dev requires contract owner
    /// @dev mints number to a specified address
    function ownerMint(address[] calldata recipients) external onlyOwner {
        require(rareContract.totalSupply() + recipients.length <= maxSupply, "no supply left");
        for (uint256 i = 0; i < recipients.length; i++) {
            rareContract.mintExternal(recipients[i]);
        }
    }

    /// @notice function to mint a pass
    /// @dev implements reentrancy guard so only one nft can be purchased in a single tx
    function buy() external payable nonReentrant {
        require(!_ofacList[msg.sender] && !_ofacList[tx.origin], "user is on the OFAC disallow list");
        require(saleOpen, "sale not open");
        require(_numMinted[msg.sender] < mintAllowance, "sender cannot mint more");
        require(rareContract.totalSupply() < auctionSupply, "no supply left");

        uint256 price = getPrice();
        require(msg.value >= price, "not enough ether attached");

        _numMinted[msg.sender]++;
        uint256 tokenId = rareContract.mintExternal(msg.sender);

        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: refund}("");
            require(refundSuccess, "refund failed");
        }
        (bool payoutSuccess, ) = payoutAddress.call{value: price}("");
        require(payoutSuccess, "payment transfer failed");

        emit Sale(address(rareContract), tokenId, price, msg.sender);
    }

    /// @notice function to get number minted by address
    function getNumMinted(address user) external view returns(uint256) {
        return _numMinted[user];
    }

    /// @notice function to get mint price
    /// @dev requires sale to be open
    function getPrice() public view returns(uint256) {
        require(saleOpen, "sale not yet open");
        uint256 numStepsSinceStart = (block.timestamp - startsAt) / stepDuration;
        if (numStepsSinceStart >= numSteps) {
            return(endingPrice);
        }
        uint256 price = startingPrice - numStepsSinceStart * stepSize;
        if (price < endingPrice) {
            return(endingPrice);
        } else {
            return(price);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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