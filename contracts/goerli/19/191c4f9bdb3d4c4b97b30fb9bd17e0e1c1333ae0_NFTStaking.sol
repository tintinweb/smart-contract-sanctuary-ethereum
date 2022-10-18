/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: yakuza_staking.sol



pragma solidity ^0.8.7;



contract NFTStaking is Ownable {

    address[] public VaultContracts;

    address public caveAddress = 0x8e87d154CAc8FA8A088B35F8143399AA99fDa5c6;

    struct Stake {
        address owner; // 32bits
        uint128 timestamp;  // 32bits
    }

    bool public stakingEnabled = false;
    uint256 public totalStaked;

    mapping(address => mapping(uint256 => Stake)) public vault; 
    mapping(address => mapping(address => uint256[])) public userStakeTokens;
    mapping(address => uint256[]) public userStakeCaves;

    event NFTStaked(address owner, address tokenAddress, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, address tokenAddress, uint256 tokenId, uint256 value);
    event Claimed(address owner);

    function setCaveAddress(address _contract) public onlyOwner {
        caveAddress = _contract;
    }

    function addVault(address _contract) public onlyOwner {
        VaultContracts.push(_contract);
    }
    
    function stakeNfts(uint256 _pid, uint256[] calldata tokenIds) external {

        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(userStakeCaves[msg.sender].length > 0, "You cannot stake without having a Cave staked.");

        IERC721 nftContract = IERC721(VaultContracts[_pid]);

        for (uint i; i < tokenIds.length; i++) {
            require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "You do not own this token");
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[VaultContracts[_pid]][tokenIds[i]] = Stake({owner: msg.sender, timestamp: uint128(block.timestamp)});
            userStakeTokens[msg.sender][VaultContracts[_pid]].push(tokenIds[i]);
            emit NFTStaked(msg.sender, VaultContracts[_pid], tokenIds[i], block.timestamp);
            totalStaked++;
        }

    }

    function stakeCave(uint256[] memory tokenIds) external {
        require(stakingEnabled == true, "Staking is not enabled yet.");

        IERC721 Cave = IERC721(caveAddress);

        for (uint i; i < tokenIds.length; i++) {
            Cave.transferFrom(msg.sender, address(this), tokenIds[i]);
            userStakeCaves[msg.sender].push(tokenIds[i]);
        }
    }

    function unstakeNfts(uint256 _pid, uint256[] calldata tokenIds) external {
        IERC721 nftContract = IERC721(VaultContracts[_pid]);
        
        for (uint i; i < tokenIds.length; i++) {
            // Replaced this function with: require(isTokenOwner == true, "You do not own this Token"); 
            // require(vault[VaultContracts[_pid]][tokenIds[i]].owner == msg.sender, "You do not own this NFT");

            bool isTokenOwner = false;
            uint tokenIndex = 0;
        
            for (uint j = 0; j < userStakeTokens[msg.sender][VaultContracts[_pid]].length; j++) {
                if (tokenIds[i] == userStakeTokens[msg.sender][VaultContracts[_pid]][j]) {
                    isTokenOwner = true;
                    tokenIndex = j;
                    break;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), msg.sender, tokenIds[i]);

            delete vault[VaultContracts[_pid]][tokenIds[i]];
            totalStaked--;

            //delete userStakeTokens[msg.sender][VaultContracts[_pid]][tokenIndex];
            userStakeTokens[msg.sender][VaultContracts[_pid]][tokenIndex] = userStakeTokens[msg.sender][VaultContracts[_pid]][userStakeTokens[msg.sender][VaultContracts[_pid]].length - 1];
            userStakeTokens[msg.sender][VaultContracts[_pid]].pop();

            emit NFTUnstaked(msg.sender, VaultContracts[_pid], tokenIds[i], block.timestamp);
        }
    } 

    function unstakeCave(uint256[] memory tokenIds) external {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(getUserStaked(msg.sender) == 0, "You cannot unstake your Cave until you unstake all your NFTs");

        IERC721 Cave = IERC721(caveAddress);

        for (uint i; i < tokenIds.length; i++) {
            
            bool isCaveOwner = false;
            uint caveIndex = 0;
        
            for (uint j = 0; j < userStakeCaves[msg.sender].length; j++) {
                if (tokenIds[i] == userStakeCaves[msg.sender][j]) {
                    isCaveOwner = true;
                    caveIndex = j;
                    break;
                }
            }

            require(isCaveOwner == true, "You do not own this Cave");

            Cave.transferFrom(address(this), msg.sender, tokenIds[i]);
            
            //delete userStakeCaves[msg.sender][caveIndex];
            userStakeCaves[msg.sender][caveIndex] = userStakeCaves[msg.sender][userStakeCaves[msg.sender].length - 1];
            userStakeCaves[msg.sender].pop();

        }
    }

    function setStakingEnabled(bool _enabled) external  onlyOwner {
        stakingEnabled = _enabled;
    }

    function getStakedCaves(address _user) external view returns (uint256[] memory) {
        return userStakeCaves[_user];
    } 

    function getStakedTokens(address _user, address _contract) external view returns (uint256[] memory) {
        return userStakeTokens[_user][_contract];
    } 

    function getVaultContracts() external view returns (address[] memory) {
        return VaultContracts;
    }

    function getStake(address _contract, uint256 _tokenId) external view returns (Stake memory) {
        return vault[_contract][_tokenId];
    }
    
    // get the total staked NFTs
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    } 
    
    function getUserStaked(address _user) public view returns (uint256) {
        uint256 total;
        for (uint i; i < VaultContracts.length; i++) {
            total += userStakeTokens[_user][VaultContracts[i]].length;
        }
        return total;
    }

}