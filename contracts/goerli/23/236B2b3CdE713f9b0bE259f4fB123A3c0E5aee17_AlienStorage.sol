// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IAlienFrensIncubator {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burnIncubatorForAddress(address burnTokenAddress) external;
}

interface IAFE {
    function ownerOf(uint256 id)
        external
        view
        returns (address);
}

contract AlienStorage is Ownable, ReentrancyGuard {

    address public IncubatorContract = 0xF2113bA61C090180ba00CA5F67AFCC7E4Cea3f3A;
    address public AFEContract = 0x220607D6428223Cf6d24E6B42A61853b098f1f53;
    mapping(uint256 => bool) public IdIsEvolved;
    mapping(uint8 => string) public partnershipName; // partnershipID => partnershipName -- there is no partnership 0
    mapping(uint8 => uint256) public partnershipMaxMints; // partnershipID => maxMints 
    mapping(uint8 => uint256) public partnershipMintCounter; // partnershipID => numMints
    mapping(uint256 => uint8) public partnershipTokens; // tokenID => partnershipID
    mapping(uint256 => uint256) public metadataId; // tokenID => metadataId -- this associates the tokenID with the ID for metadata
    uint8 public numberOfPartnerships;
    bool public isActive = false;

    function setIncubatorContract(address _IncubatorContract) public onlyOwner {
        IncubatorContract = _IncubatorContract;
    }

    function setAFEContract(address _contract) public onlyOwner {
        AFEContract = _contract;
    }

    function setIsActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function createParnership (string calldata _partnershipName, uint256 maxMints) public onlyOwner {
        require(numberOfPartnerships < 255, "Max partnerships reached");
        require(maxMints > 0, "Max mints must be greater than 0");
        require(bytes(_partnershipName).length > 0, "Partnership name must be greater than 0");
        numberOfPartnerships++;
        partnershipName[numberOfPartnerships] = _partnershipName;
        partnershipMaxMints[numberOfPartnerships] = maxMints;
    }

    function updatePartnership(uint8 partnershipId, string calldata _partnershipName, uint256 maxMints) public onlyOwner {
        require(partnershipId <= numberOfPartnerships, "Partnership doesn't exist");
        require(partnershipId != 0, "Partnership doesn't exist");
        require(maxMints > 0, "Max mints must be greater than 0");
        require(bytes(_partnershipName).length > 0, "Partnership name must be greater than 0");
        require(partnershipMintCounter[partnershipId] < maxMints, "Max mints must be greater than current mints");
        partnershipName[partnershipId] = _partnershipName;
        partnershipMaxMints[partnershipId] = maxMints;
    }

    function addTokensToPartnership (uint8 partnershipId, uint256[] calldata tokenIds) public onlyOwner {
        require(partnershipId <= numberOfPartnerships, "Partnership doesn't exist");
        require(partnershipId != 0, "Partnership doesn't exist");
        for(uint8 i = 0; i < tokenIds.length; i++) {
            partnershipTokens[tokenIds[i]] = partnershipId;
        }
    }

    function getTokenInfo(uint256 tokenId) public view returns (string memory, uint8, bool, uint256) {
        // partnershipName, partnershipId, isEvolved, metadataId
        return (partnershipName[partnershipTokens[tokenId]], partnershipTokens[tokenId], IdIsEvolved[tokenId], metadataId[tokenId]);
    }

    function getPartnershipInfo(uint8 partnershipId) public view returns (string memory, uint256, uint256) {
        // partnershipName, maxMints, numMints
        return (partnershipName[partnershipId], partnershipMaxMints[partnershipId], partnershipMintCounter[partnershipId]);        
    }

    event EvolveEvent(uint256 tokenId);

    function evolve(uint256 AFEtokenId, uint8 partnershipId) external {
        require(isActive == true, "Evolving is not active");
        require(IAlienFrensIncubator(IncubatorContract).balanceOf(msg.sender, 0) > 0, "You don't own an Incubator");
        require(IAFE(AFEContract).ownerOf(AFEtokenId) == msg.sender, "You are not the owner of this token");
        require(IdIsEvolved[AFEtokenId] == false, "Already evolved");
        require(partnershipTokens[AFEtokenId] != 0, "Token ID not associated with a partnership");
        require(partnershipTokens[AFEtokenId] == partnershipId, "Token ID not associated with this partnership");
        require(partnershipMintCounter[partnershipId] < partnershipMaxMints[partnershipId], "Max mints reached for this partnership");
        IdIsEvolved[AFEtokenId] = true;
        metadataId[AFEtokenId] = partnershipMintCounter[partnershipId];
        partnershipMintCounter[partnershipId]++;

        // burn Incubator
        IAlienFrensIncubator(IncubatorContract).burnIncubatorForAddress(
            msg.sender
        );

        emit EvolveEvent(AFEtokenId);
    }
}