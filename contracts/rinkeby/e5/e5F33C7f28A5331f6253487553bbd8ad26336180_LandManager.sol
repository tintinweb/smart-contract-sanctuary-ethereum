// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LandManager is Ownable {

    event NewLandTierAdded (
        string tierName, 
        uint256 cap, 
        uint256 price,
        uint256 timestamp
    );

    event TierCapUpdated(string tierName, LandTierInfo updatedInfo);

    event LandTierPriceUpdated(string tierName, LandTierInfo updatedInfo);

    string[] private landTiers;

    IERC721 LandsContract;

    struct LandTierInfo {
        uint256 cap;
        uint256 price;
        uint256 sold;
    }

    mapping (string => bool) isLandTierDeleted;
    mapping (string => LandTierInfo) landTierInfo;
    mapping (string => uint256[]) tokenIdsIn;
    mapping (uint256 => string) tierOf;

    mapping (uint256 => string) tierByLandId;
    mapping (string => uint256[]) landIdsByTier;


    constructor (IERC721 _landsContract) { //initial price cap []
        LandsContract = _landsContract;
    }

    modifier onlyOwnerOrLandsContract() {
        require(
            msg.sender == owner() || msg.sender == address(LandsContract),
            "Ownable: Only owner or Lands Contract can perform this action"
        );
        _;
    }

    function getLandsContract() public view returns(IERC721) {
        return LandsContract;
    }

    function setLandsContract(IERC721 _landsContract) public onlyOwner {
        LandsContract = _landsContract;
    }

    function addLandTiers (
        string[] memory _landTiers, 
        uint256[] memory _tierCaps, 
        uint256[] memory _tierPrices
    ) public onlyOwner {
        require (
            (_landTiers.length == _tierCaps.length) && (_tierCaps.length == _tierPrices.length), 
            "LandManager: Invalid arguments"
        );
        
        for (uint256 i = 0; i < _landTiers.length; i++) {
            _addNewLandTier(_landTiers[i], _tierCaps[i], _tierPrices[i]);
        }

    }

    function _addNewLandTier(string memory _landTier, uint256 _tierCap, uint256 _tierPrice) 
    internal 
    {
        landTiers.push(_landTier);
        // isLandTierDeleted[_landTier] = false;
        landTierInfo[_landTier] = LandTierInfo( _tierCap, _tierPrice, 0);

        emit NewLandTierAdded(
            _landTier,
            _tierCap,
            _tierPrice,
            block.timestamp
        );
    }

    function getAllLandTiers() public view returns(string[] memory) {
        string[] memory _landTiers = new string[](landTiers.length);
        uint256 deletedElems = 0;
        uint256 counter = 0;

        for (uint256 i = 0; i < landTiers.length; i++) {
            if(!isLandTierDeleted[landTiers[i]]){
                _landTiers[counter] = landTiers[i];
                counter++;
            } else {deletedElems++;}
        }
        assembly { mstore(_landTiers, sub(mload(_landTiers), deletedElems)) }

        return _landTiers;
    }

    function getLandTierInfo(string memory _landTierName) 
    public 
    view 
    returns (LandTierInfo memory)
    {
        return landTierInfo[_landTierName];
    }

    function updateLandTierCap(string memory _landTierName, uint256 _newCap) 
    public 
    onlyOwner {

        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        require(_tierInfo.cap != 0 && _tierInfo.price != 0, "LandManager: Tier not found");
        require(_newCap >= _tierInfo.sold, "LandManager: Cannot set cap less than number of sold Lands");

        landTierInfo[_landTierName] = LandTierInfo(_newCap, _tierInfo.price, _tierInfo.sold);

        emit TierCapUpdated(_landTierName, landTierInfo[_landTierName]);

    }

    function updateLandTierPrice(string memory _landTierName, uint256 _newPrice) 
    public 
    onlyOwner 
    {
        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        require(_tierInfo.cap != 0 && _tierInfo.price != 0, "LandManager: Tier not found");
        landTierInfo[_landTierName] = LandTierInfo(_tierInfo.cap, _newPrice, _tierInfo.sold);
        emit LandTierPriceUpdated(_landTierName, landTierInfo[_landTierName]);

    }

    function removeTier(string memory _landTierName) public onlyOwner {

        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        require(_tierInfo.cap != 0 && _tierInfo.price != 0, "LandManager: Tier not found");
        require(_tierInfo.sold == 0, "LandManager: Asset sold already, cannot delete Tier!");
        isLandTierDeleted[_landTierName] = true;
        delete landTierInfo[_landTierName];

    }

    function increaseTierSold (
        string memory _landTierName, 
        uint256 tokenId,
        uint256 landId
    ) public onlyOwnerOrLandsContract 
    {

        require(keccak256(bytes(tierByLandId[landId])) == keccak256(bytes('')), 
            "LandManager: Land Id exists already");
        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        require(getRemainingCap(_landTierName) > 0, "LandManager: Cap limit exceded");

        tokenIdsIn[_landTierName].push(tokenId);
        tierOf[tokenId] = _landTierName;

        landTierInfo[_landTierName] = LandTierInfo(_tierInfo.cap, _tierInfo.price, ++_tierInfo.sold);

        tierByLandId[landId] = _landTierName;
        landIdsByTier[_landTierName].push(landId);


    }

    function increaseBatchTierSold (
        string memory _landTierName, 
        uint256[] memory tokenIds,
        uint256[] memory landIds
    ) public onlyOwnerOrLandsContract 
    {
        require(landIds.length == tokenIds.length, "LandManager: Invalid arguments");
        require(getRemainingCap(_landTierName) >= tokenIds.length, "LandManager: Cap limit exceded");
        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];

        uint256 updatedSold = _tierInfo.sold + tokenIds.length;
        _pushTokenIdsInTier(_landTierName, tokenIds, landIds, updatedSold);
        landTierInfo[_landTierName] = LandTierInfo(_tierInfo.cap, _tierInfo.price, updatedSold);

    }

    function _pushTokenIdsInTier (
        string memory _landTierName, 
        uint256[] memory tokenIds,
        uint256[] memory landIds,
        uint256 expectedNumOfSold
        ) internal {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(keccak256(bytes(tierByLandId[landIds[i]])) == keccak256(bytes('')), 
            "LandManager: Land Id exists already");

            tokenIdsIn[_landTierName].push(tokenIds[i]);
            tierOf[tokenIds[i]] = _landTierName;

            tierByLandId[landIds[i]] = _landTierName;
            landIdsByTier[_landTierName].push(landIds[i]);
        }

        require(
            expectedNumOfSold == tokenIdsIn[_landTierName].length, 
            "LandManager: number of solds should match with num of Id's in a particular Teir"
        );

    }

    function getRemainingCap(string memory _landTierName) public view returns(uint256){
        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        require(_tierInfo.cap != 0 && _tierInfo.price != 0, "LandManager: Tier not found");

        if(_tierInfo.cap == 0 && _tierInfo.price == 0){
            return 0;
        }
        return (_tierInfo.cap - _tierInfo.sold);
    }

    function getTierPrice(string memory _landTierName) public view returns(uint256) {
        LandTierInfo memory _tierInfo = landTierInfo[_landTierName];
        return _tierInfo.price;
    }

    function getTokenIdByTier(string memory _landTierName) 
    public 
    view 
    returns(uint256[] memory) {
        return tokenIdsIn[_landTierName];
    }

    function getLandTierByTokenId(uint256 _tokenId) public view returns(string memory) {
        return tierOf[_tokenId];
    }

    function getAllLandIdsByLandTier(string memory _landTierName) public view returns (uint256[] memory){
        return tokenIdsIn[_landTierName];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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