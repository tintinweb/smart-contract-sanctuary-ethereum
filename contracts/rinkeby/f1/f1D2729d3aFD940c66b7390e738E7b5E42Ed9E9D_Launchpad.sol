/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.8.0;

interface ILaunchpadNFT {
    // return max supply config for launchpad, if no reserved will be collection's max supply
    function getMaxLaunchpadSupply() external view returns (uint256);
    // return current launchpad supply
    function getLaunchpadSupply() external view returns (uint256);
    // this function need to restrict mint permission to launchpad contract
    function mintTo(address to, uint256 size) external;
}
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/GameZone/Launchpad.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;




contract Launchpad is Ownable, ReentrancyGuard {

    event AddCampaign(address contractAddress, address payeeAddress, uint256 price, uint256 maxSupply,
                        uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress);
    event UpdateCampaign(address contractAddress, address payeeAddress, uint256 price, uint256 maxSupply,
                        uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress);
    event Mint(address indexed contractAddress, address payeeAddress, uint256 size, uint256 price);

    struct Campaign {
        address contractAddress;
        address payeeAddress;
        uint256 price; // wei
        uint256 maxSupply;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 maxBatch;
        uint256 maxPerAddress;
    }

    mapping(address => Campaign) private _campaigns;
    mapping(address => mapping(address => uint256)) private _mintPerAddress;

    function mint(address contractAddress, uint256 batchSize) external payable nonReentrant {
        // basic check
        require(contractAddress != address(0), "contract address can not be empty");
        require(batchSize > 0, "batchSize must greater than 0");
        require(_campaigns[contractAddress].contractAddress != address(0), "contract not register");

        // activity check
        Campaign memory campaign = _campaigns[contractAddress];
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(_mintPerAddress[contractAddress][msg.sender] + batchSize <= campaign.maxPerAddress, "reach max per address limit");
        // NFT contract must impl ERC721Enumerable to have this totalSupply method
        uint256 currentSupply = ILaunchpadNFT(contractAddress).getLaunchpadSupply();
        require(currentSupply + batchSize <= campaign.maxSupply, "reach campaign max supply");
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddress[contractAddress][msg.sender] = _mintPerAddress[contractAddress][msg.sender] + batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadNFT(contractAddress).mintTo(msg.sender, batchSize);

        emit Mint(campaign.contractAddress, campaign.payeeAddress, batchSize, campaign.price);
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function getMintPerAddress(address contractAddress, address userAddress) view external returns (uint256) {
        require(_campaigns[contractAddress].contractAddress != address(0), "contract address invalid");
        require(userAddress != address(0), "user address invalid");
        return _mintPerAddress[contractAddress][userAddress];
    }

    function getLaunchpadMaxSupply(address contractAddress) view external returns (uint256) {
        return ILaunchpadNFT(contractAddress).getMaxLaunchpadSupply();
    }

    function getLaunchpadSupply(address contractAddress) view external returns (uint256) {
        return ILaunchpadNFT(contractAddress).getLaunchpadSupply();
    }

    function addCampaign(address contractAddress_, address payeeAddress_, uint256 price_,
        uint256 listingTime_, uint256 expirationTime_, uint256 maxBatch_, uint256 maxPerAddress_) external onlyOwner {
        require(contractAddress_ != address(0), "contract address can not be empty");
        require(_campaigns[contractAddress_].contractAddress == address(0), "contract address already exist");
        require(payeeAddress_ != address(0), "payee address can not be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can not be 0");
        uint256 maxSupply_ = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply();
        require(maxSupply_ > 0, "max supply can not be 0");
        emit AddCampaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_,
            expirationTime_, maxBatch_, maxPerAddress_);
        _campaigns[contractAddress_] = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_,
                                                expirationTime_, maxBatch_, maxPerAddress_);
    }

    function updateCampaign(address contractAddress_, address payeeAddress_, uint256 price_,
        uint256 listingTime_, uint256 expirationTime_, uint256 maxBatch_, uint256 maxPerAddress_) external onlyOwner {
        require(contractAddress_ != address(0), "contract address can not be empty");
        require(_campaigns[contractAddress_].contractAddress != address(0), "contract address not exist");
        require(payeeAddress_ != address(0), "payee address can not be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can not be 0");
        uint256 maxSupply_ = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply();
        require(maxSupply_ > 0, "max supply can not be 0");
        emit UpdateCampaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_,
                            expirationTime_, maxBatch_, maxPerAddress_);
        _campaigns[contractAddress_] = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_,
                                                expirationTime_, maxBatch_, maxPerAddress_);
    }

    function getCampaign(address contractAddress) view external returns (address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
        Campaign memory a = _campaigns[contractAddress];
        return (a.contractAddress, a.payeeAddress, a.price, a.maxSupply, a.listingTime, a.expirationTime, a.maxBatch, a.maxPerAddress);
    }
}