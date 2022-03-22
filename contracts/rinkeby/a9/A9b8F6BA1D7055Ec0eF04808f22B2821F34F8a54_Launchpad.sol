//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILaunchpadNFT.sol";

contract Launchpad is Ownable, ReentrancyGuard {
    event AddCampaign(address contractAddress, CampaignMode mode, address payeeAddress, uint256 price, uint256 maxSupply, uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress, address validator);
    event UpdateCampaign(address contractAddress, CampaignMode mode, address payeeAddress, uint256 price, uint256 maxSupply, uint256 listingTime, uint256 expirationTime, uint256 maxBatch, uint256 maxPerAddress, address validator);
    event Mint(address indexed contractAddress, CampaignMode mode, address userAddress, address payeeAddress, uint256 size, uint256 price);

    enum CampaignMode {
        normal,
        whitelisted
    }
    struct Campaign {
        address contractAddress;
        address payeeAddress;
        uint256 price; // wei
        uint256 maxSupply;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 maxBatch;
        uint256 maxPerAddress;
        address validator; // only for whitelisted
        uint256 minted;
    }

    mapping(address => Campaign) private _campaignsNormal;
    mapping(address => Campaign) private _campaignsWhitelisted;

    mapping(address => mapping(address => uint256)) private _mintPerAddressNormal;
    mapping(address => mapping(address => uint256)) private _mintPerAddressWhitelisted;

    function mintWhitelisted(
        address contractAddress,
        uint256 batchSize,
        bytes memory signature
    ) public payable nonReentrant {
        // basic check
        require(contractAddress != address(0), "contract address can't be empty");
        require(batchSize > 0, "batchSize must greater than 0");
        Campaign memory campaign = _campaignsWhitelisted[contractAddress];
        require(campaign.contractAddress != address(0), "contract not register");

        //  Check whitelist validator signature
        bytes32 messageHash = keccak256(abi.encodePacked(block.chainid, address(this), contractAddress, msg.sender));
        require(recoverSigner(messageHash, signature) == campaign.validator, "whitelist verification failed");

        // activity check
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(_mintPerAddressWhitelisted[contractAddress][msg.sender] + batchSize <= campaign.maxPerAddress, "reach max per address limit");
        require(campaign.minted + batchSize <= campaign.maxSupply, "reach campaign max supply");
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddressWhitelisted[contractAddress][msg.sender] = _mintPerAddressWhitelisted[contractAddress][msg.sender] + batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadNFT(contractAddress).mintTo(msg.sender, batchSize);
        _campaignsWhitelisted[contractAddress].minted += batchSize;

        emit Mint(campaign.contractAddress, CampaignMode.whitelisted, msg.sender, campaign.payeeAddress, batchSize, campaign.price);
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function mint(address contractAddress, uint256 batchSize) external payable nonReentrant {
        // basic check
        require(contractAddress != address(0), "contract address can't be empty");
        require(batchSize > 0, "batchSize must greater than 0");
        Campaign memory campaign = _campaignsNormal[contractAddress];
        require(campaign.contractAddress != address(0), "contract not register");

        // activity check
        require(batchSize <= campaign.maxBatch, "reach max batch size");
        require(block.timestamp >= campaign.listingTime, "activity not start");
        require(block.timestamp < campaign.expirationTime, "activity ended");
        require(_mintPerAddressNormal[contractAddress][msg.sender] + batchSize <= campaign.maxPerAddress, "reach max per address limit");
        require(campaign.minted + batchSize <= campaign.maxSupply, "reach campaign max supply");
        uint256 totalPrice = campaign.price * batchSize;
        require(msg.value >= totalPrice, "value not enough");

        // update record
        _mintPerAddressNormal[contractAddress][msg.sender] = _mintPerAddressNormal[contractAddress][msg.sender] + batchSize;

        // transfer token and mint
        payable(campaign.payeeAddress).transfer(totalPrice);
        ILaunchpadNFT(contractAddress).mintTo(msg.sender, batchSize);
        _campaignsNormal[contractAddress].minted += batchSize;

        emit Mint(campaign.contractAddress, CampaignMode.normal, msg.sender, campaign.payeeAddress, batchSize, campaign.price);
        // return
        uint256 valueLeft = msg.value - totalPrice;
        if (valueLeft > 0) {
            payable(_msgSender()).transfer(valueLeft);
        }
    }

    function recoverSigner(bytes32 messageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedProof = keccak256(abi.encodePacked(prefix, messageHash));
        return ecrecover(prefixedProof, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) {
            v += 27;
            // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }
    }

    function getMintPerAddress(
        address contractAddress,
        CampaignMode mode,
        address userAddress
    ) external view returns (uint256 mintPerAddress) {
        Campaign memory campaign;
        if (mode == CampaignMode.normal) {
            campaign = _campaignsNormal[contractAddress];
            mintPerAddress = _mintPerAddressNormal[contractAddress][msg.sender];
        } else {
            campaign = _campaignsWhitelisted[contractAddress];
            mintPerAddress = _mintPerAddressWhitelisted[contractAddress][msg.sender];
        }

        require(campaign.contractAddress != address(0), "contract address invalid");
        require(userAddress != address(0), "user address invalid");
    }

    function getLaunchpadMaxSupply(address contractAddress, CampaignMode mode) external view returns (uint256) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress].maxSupply;
        } else {
            return _campaignsWhitelisted[contractAddress].maxSupply;
        }
    }

    function getLaunchpadSupply(address contractAddress, CampaignMode mode) external view returns (uint256) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress].minted;
        } else {
            return _campaignsWhitelisted[contractAddress].minted;
        }
    }

    function addCampaign(
        address contractAddress_,
        CampaignMode mode,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxSupply_,
        uint256 maxBatch_,
        uint256 maxPerAddress_,
        address validator_
    ) external onlyOwner {
        require(contractAddress_ != address(0), "contract address can't be empty");

        Campaign memory campaign;
        uint256 maxSupplyRest;
        if (mode == CampaignMode.normal) {
            campaign = _campaignsNormal[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsWhitelisted[contractAddress_].maxSupply;
        } else {
            campaign = _campaignsWhitelisted[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsNormal[contractAddress_].maxSupply;
            require(validator_ != address(0), "validator can't be empty");
        }

        require(campaign.contractAddress == address(0), "contract address already exist");

        require(payeeAddress_ != address(0), "payee address can't be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can't be 0");
        require(maxSupply_ <= maxSupplyRest, "max supply is exceeded");
        require(maxSupply_ > 0, "max supply can't be 0");

        emit AddCampaign(contractAddress_, mode, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_);
        campaign = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_, 0);
        if (mode == CampaignMode.normal) {
            _campaignsNormal[contractAddress_] = campaign;
        } else {
            _campaignsWhitelisted[contractAddress_] = campaign;
        }
    }

    function updateCampaign(
        address contractAddress_,
        CampaignMode mode,
        address payeeAddress_,
        uint256 price_,
        uint256 listingTime_,
        uint256 expirationTime_,
        uint256 maxSupply_,
        uint256 maxBatch_,
        uint256 maxPerAddress_,
        address validator_
    ) external onlyOwner {
        Campaign memory campaign;
        uint256 maxSupplyRest;
        require(contractAddress_ != address(0), "contract address can't be empty");
        if (mode == CampaignMode.normal) {
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsWhitelisted[contractAddress_].maxSupply;
            campaign = _campaignsNormal[contractAddress_];
        } else {
            campaign = _campaignsWhitelisted[contractAddress_];
            maxSupplyRest = ILaunchpadNFT(contractAddress_).getMaxLaunchpadSupply() - _campaignsNormal[contractAddress_].maxSupply;
            require(validator_ != address(0), "validator can't be empty");
        }

        require(campaign.contractAddress != address(0), "contract address not exist");

        require(payeeAddress_ != address(0), "payee address can't be empty");
        require(maxBatch_ > 0, "max batch invalid");
        require(maxPerAddress_ > 0, "max per address can't be 0");
        require(maxSupply_ <= maxSupplyRest, "max supply is exceeded");
        require(maxSupply_ > 0, "max supply can't be 0");
        emit UpdateCampaign(contractAddress_, mode, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_);
        campaign = Campaign(contractAddress_, payeeAddress_, price_, maxSupply_, listingTime_, expirationTime_, maxBatch_, maxPerAddress_, validator_, campaign.minted);

        if (mode == CampaignMode.normal) {
            _campaignsNormal[contractAddress_] = campaign;
        } else {
            _campaignsWhitelisted[contractAddress_] = campaign;
        }
    }

    function getCampaign(address contractAddress, CampaignMode mode) external view returns (Campaign memory) {
        if (mode == CampaignMode.normal) {
            return _campaignsNormal[contractAddress];
        } else {
            return _campaignsWhitelisted[contractAddress];
        }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILaunchpadNFT {
    // return max supply config for launchpad, if no reserved will be collection's max supply
    function getMaxLaunchpadSupply() external view returns (uint256);
    // return current launchpad supply
    function getLaunchpadSupply() external view returns (uint256);
    // this function need to restrict mint permission to launchpad contract
    function mintTo(address to, uint256 size) external;
}