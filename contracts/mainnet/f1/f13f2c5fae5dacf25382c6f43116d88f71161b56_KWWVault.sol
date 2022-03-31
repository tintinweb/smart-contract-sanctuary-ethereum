/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT

// File: contracts/IKWWGameManager.sol

pragma solidity ^0.8.4;


interface IKWWGameManager{
    enum ContractTypes {KANGAROOS, BOATS, LANDS, VAULT, DATA, BOATS_DATA, MOVING_BOATS, VOTING}

    function getContract(uint8 _type) external view returns(address);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// File: contracts/KWWVault.sol


pragma solidity ^0.8.4;




contract KWWVault is Ownable {
    struct VaultAsset{
        uint64 timeStaked;
        address holder;
        uint8 assetType;
        bool frozen;
    }
    mapping(uint256 => VaultAsset) public assetsData;
    mapping(address => uint256[]) public holderTokens;

    //ETH Vault
    mapping(uint16 => uint256) public boatsWithdrawAmount;
    //landId => ownerType (0-prince,1-princess, 2-landlord)
    mapping(uint16 => mapping(uint8 => uint256)) public landsWithdrawAmount;

    mapping(uint16 => uint256) public boatsMaxWithdraw;
    mapping(uint16 => uint256) public landsMaxWithdraw;

    uint256 teamWithdraw;
    uint256 teamMaxWithdraw;

    uint8 teamPercent = 10;

    bool public vaultOpen = true;

    IKWWGameManager gameManager;

    //ETH Vault
    function depositBoatFees(uint16 totalSupply) public payable onlyGameManager{
        teamMaxWithdraw += msg.value / teamPercent;
        boatsMaxWithdraw[totalSupply] = (msg.value - msg.value / teamPercent ) / totalSupply;
    }

    function boatAvailableToWithdraw(uint16 totalSupply, uint16 boatId) public view returns(uint256) {
        uint16 maxState = (boatId / 100) * 100 + 100;
        uint256 withdrawMaxAmount= 0;
        for(uint16 i = boatId; i < totalSupply && i < maxState ; i++){
            withdrawMaxAmount += boatsMaxWithdraw[i];
        }
        return withdrawMaxAmount - boatsWithdrawAmount[boatId];
    }

    function withdrawBoatFees(uint16 totalSupply, uint16 boatId, address addr) public onlyGameManager{
        uint256 availableToWithdraw = boatAvailableToWithdraw(totalSupply, boatId);
        (bool os, ) = payable(addr).call{value: availableToWithdraw}("");
        require(os);
        boatsWithdrawAmount[boatId] += availableToWithdraw;
    }

    function depositLandFees(uint16 landId) public payable onlyGameManager{
        teamMaxWithdraw += msg.value / teamPercent;
        landsMaxWithdraw[landId] = (msg.value - msg.value / teamPercent ) / 3;
    }

    function landAvailableToWithdraw(uint16 landId, uint8 ownerTypeId) public view returns(uint256) {
        require(ownerTypeId < 3, "Owner type not valid");
        return landsMaxWithdraw[landId] - landsWithdrawAmount[landId][ownerTypeId];
    }

    function withdrawLandFees(uint16 landId, uint8 ownerTypeId, address addr) public onlyGameManager{
        uint256 availableToWithdraw = landAvailableToWithdraw(landId, ownerTypeId);
        (bool os, ) = payable(addr).call{value: availableToWithdraw}("");
        require(os);
        landsWithdrawAmount[landId][ownerTypeId] += availableToWithdraw;
    }

    function teamAvailableToWithdraw() public view returns(uint256) {
        return teamMaxWithdraw - teamWithdraw;
    }

    function withdrawFeesTeam(address teamWallet) public onlyOwner {
        uint256 availableToWithdraw = teamAvailableToWithdraw();
        (bool os, ) = payable(teamWallet).call{value: availableToWithdraw}("");
        require(os);
        teamWithdraw += availableToWithdraw;
    } 

    //NFT Vault
    function depositToVault(address owner, uint256[] memory tokens, uint8 assetsType, bool frozen) public onlyGameManager {
        require(vaultOpen, "Vault is closed");

        IERC721 NFTContract = IERC721(gameManager.getContract(assetsType));
        require(NFTContract.isApprovedForAll(owner, address(this)), "The vault is not approved for all");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 id = tokens[i];
            NFTContract.transferFrom(owner, address(this), id);

            holderTokens[owner].push(id);
            assetsData[id].timeStaked = uint64(block.timestamp);
            assetsData[id].holder = owner;
            assetsData[id].assetType = assetsType;
            assetsData[id].frozen = frozen;
        }
    }

    function withdrawFromVault(uint256[] calldata tokenIds) public  {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(assetsData[id].holder == msg.sender, "Missing permissions - you're not the owner");
            require(isWithdrawAvailable(id), "Asset is still frozen");

            getIERC721Contract(id).transferFrom(address(this), msg.sender, id);

            removeTokenIdFromArray(holderTokens[msg.sender], id);
            assetsData[id].holder = address(0);
        }
    }

    function withdrawFromVault(address owner, uint256[] calldata tokenIds) public onlyGameManager {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(assetsData[id].holder == owner, "Missing permissions - you're not the owner");

            getIERC721Contract(id).transferFrom(address(this), owner, id);

            removeTokenIdFromArray(holderTokens[owner], id);
            assetsData[id].holder = address(0);
        }
    }

    function witdrawAll() public {
        require(getDepositedAmount(msg.sender) > 0, "NONE_STAKED");

        for (uint256 i = holderTokens[msg.sender].length; i > 0; i--) {
            uint256 id = holderTokens[msg.sender][i - 1];
            require(isWithdrawAvailable(id), "Asset is still frozen");

            getIERC721Contract(id).transferFrom(address(this), msg.sender, id);

            holderTokens[msg.sender].pop();
            assetsData[id].holder = address(0);
        }
    }

    function witdrawAll(address owner) public onlyGameManager {
        require(getDepositedAmount(owner) > 0, "Owner vault is empty");

        for (uint256 i = holderTokens[owner].length; i > 0; i--) {
            uint256 id = holderTokens[owner][i - 1];
            require(assetsData[id].holder == owner, "Missing permissions - you're not the owner");

            getIERC721Contract(id).transferFrom(address(this), owner, id);

            holderTokens[owner].pop();
            assetsData[id].holder = address(0);
        }
    }

    function setAssetFrozen(uint256 token, bool isFrozen) public onlyGameManager {
        assetsData[token].frozen = isFrozen;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    /*
        GETTERS
    */

    function getIERC721Contract(uint256 tokenId) public view returns(IERC721){
        return IERC721(gameManager.getContract(assetsData[tokenId].assetType));
    }

    function getDepositedAmount(address holder) public view returns (uint256) {
        return holderTokens[holder].length;
    }

    function getHolder(uint256 tokenId) public view returns (address) {
        return assetsData[tokenId].holder;
    }

    function isWithdrawAvailable(uint256 tokenId) public view returns(bool){
        return !assetsData[tokenId].frozen;
    }

    /*
        MODIFIERS
    */

    modifier onlyGameManager {
        require(address(gameManager) != address(0), "Game manager not set");
        require(msg.sender == owner() || msg.sender == address(gameManager), "caller is not the Boats Contract");
        _;
    }

    /*
        ONLY OWNER
     */

    function toggleVaultOpen() public onlyOwner{
        vaultOpen = !vaultOpen;
    }

    function setGameManager(address _addr) public onlyOwner{
        gameManager = IKWWGameManager(_addr);
    }

    function setTeamPercent(uint8 _teamPercent) public onlyOwner{
        teamPercent = _teamPercent;
    }
}