// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    uint256 public NFT_BASE_RATE = 1000000000000000000; // 1 per day

    address public NFT_ADDRESS; //NFT Collection Address
    address public TOKEN_ADDRESS;

    bool public stakingLive = false;
    bool public locked = false;

    mapping(uint256 => uint256) internal NftTimeStaked;
    mapping(uint256 => address) internal NftToStaker;
    mapping(address => uint256[]) internal StakerToNft;

    mapping(uint256 => uint256) private NftToType;
    mapping(address => uint256) public claimable;

    uint256 type1Multiplier = 3;
    uint256 type2Multiplier = 5;
    uint256 type3Multiplier = 5;

    event ClaimVirtual(address indexed staker, uint256 amount);

    IERC721Enumerable private nft;

    constructor(address nft_address, address token_address) {
        if (token_address != address(0)) {
            TOKEN_ADDRESS = token_address;
        }
        NFT_ADDRESS = nft_address;
        nft = IERC721Enumerable(NFT_ADDRESS);
    }

    function getTokenIDsStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return StakerToNft[staker];
    }

    function stakeCount() public view returns (uint256) {
        return nft.balanceOf(address(this));
    }

    function removeIdFromArray(uint256[] storage arr, uint256 tokenId)
        internal
    {
        uint256 length = arr.length;
        for (uint256 i = 0; i < length; i++) {
            if (arr[i] == tokenId) {
                length--;
                if (i < length) {
                    arr[i] = arr[length];
                }
                arr.pop();
                break;
            }
        }
    }

    // covers single staking and multiple
    function stake(uint256[] calldata tokenIds) public {
        require(stakingLive, "Staking not Live!");
        uint256 id;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            id = tokenIds[i];
            require(
                nft.ownerOf(id) == msg.sender && NftToStaker[id] == address(0),
                "Token not owned by staker"
            );
            // set trait type to default if not set
            if (NftToType[id] == 0) {
                NftToType[id] = 1;
            }
            //NFT transfer
            nft.transferFrom(msg.sender, address(this), id);
            //Track data
            StakerToNft[msg.sender].push(id);
            NftTimeStaked[id] = block.timestamp;
            NftToStaker[id] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            StakerToNft[msg.sender].length > 0,
            "Need at least 1 staked to unstake"
        );
        uint256 total = 0;

        for (uint256 i = StakerToNft[msg.sender].length; i > 0; i--) {
            uint256 tokenId = StakerToNft[msg.sender][i - 1];

            nft.transferFrom(address(this), msg.sender, tokenId);
            //append calcuated field
            total += calculateRewardsByTokenId(tokenId);
            // count from end
            StakerToNft[msg.sender].pop();
            NftToStaker[tokenId] = address(0);
            // set total rewards to 0 , timestamp to 0
            NftTimeStaked[tokenId] = 0;
        }

        claimable[msg.sender] += total;
    }

    function unstake(uint256[] calldata tokenIds) public {
        uint256 total = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(NftToStaker[id] == msg.sender, "NOT the staker");

            nft.transferFrom(address(this), msg.sender, id);
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            // remove specific id from array
            removeIdFromArray(StakerToNft[msg.sender], id);
            NftToStaker[id] = address(0);
            // set total rewards to 0 , timestamp to 0
            NftTimeStaked[id] = 0;
        }

        claimable[msg.sender] += total;
    }

    function claim(uint256 tokenId) external {
        require(NftToStaker[tokenId] == msg.sender, "NOT the staker");
        require(TOKEN_ADDRESS != address(0), "Token Withdraw disabled");
        //append calcuated field
        uint256 total = calculateRewardsByTokenId(tokenId);
        NftTimeStaked[tokenId] = block.timestamp;
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, total);
    }

    function claimAll() external {
        require(TOKEN_ADDRESS != address(0), "Token Withdraw disabled");
        uint256 total = 0;
        uint256[] memory TokenIds = StakerToNft[msg.sender];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            uint256 id = TokenIds[i];
            require(NftToStaker[id] == msg.sender, "Sender not staker");
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            NftTimeStaked[id] = block.timestamp;
        }
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, total);
    }

    // claims and burns all virtual tokens for shop use
    function claimVirtual() external {
        uint256 total = 0;
        uint256[] memory TokenIds = StakerToNft[msg.sender];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            uint256 id = TokenIds[i];
            require(NftToStaker[id] == msg.sender, "Sender not staker");
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            //set timestamp , set current rewards to 0
            NftTimeStaked[id] = block.timestamp;
        }
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        emit ClaimVirtual(msg.sender, total);
    }

    //maps token id to staker address
    function getNftStaker(uint256 tokenId) public view returns (address) {
        return NftToStaker[tokenId];
    }

    //return public is token id staked in contract
    function isStaked(uint256 tokenId) public view returns (bool) {
        return (NftToStaker[tokenId] != address(0));
    }

    function getType(uint256 tokenId) public view returns (uint256) {
        return NftToType[tokenId];
    }

    /* Calculate Reward functions */

    // calculate the rewards for a specific token id
    function calculateRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256 _rewards)
    {
        uint256 total = 0;
        // get the time staked for the token id
        uint256 tempRewards = (block.timestamp - NftTimeStaked[tokenId]);
        // calculate the rewards per time staked
        if (NftToType[tokenId] == 1) {
            tempRewards = (tempRewards * type1Multiplier);
        }
        if (NftToType[tokenId] == 2) {
            tempRewards = (tempRewards * type2Multiplier);
        }
        if (NftToType[tokenId] == 3) {
            tempRewards = (tempRewards * type3Multiplier);
        }
        // add the rewards to the total
        total += (((tempRewards * NFT_BASE_RATE) / 86400));
        return (total);
    }

    //total rewards for staker
    function getAllRewards(address staker) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory tokenIds = StakerToNft[staker];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //append calcuated field
            total += (calculateRewardsByTokenId(tokenIds[i]));
        }
        // add claimable
        total += claimable[staker];
        return total;
    }

    function getRewardsPerDay(uint256[] calldata tokenId)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < tokenId.length; i++) {
            if (NftToType[tokenId[i]] == 1) {
                total += type1Multiplier;
            }
            if (NftToType[tokenId[i]] == 2) {
                total += type2Multiplier;
            }
            if (NftToType[tokenId[i]] == 3) {
                total += type3Multiplier;
            }
        }
        return (total * (NFT_BASE_RATE / 1 ether));
    }

    /* Owner Functions */

    //set type list for specific token id
    function setTypeList(uint256 tokenId, uint256 typeNumber)
        external
        onlyOwner
    {
        NftToType[tokenId] = typeNumber;
    }

    // set full type list for specific token ids and override any previous type list
    function setFullTypeList(uint256[] calldata idList, uint256 typeNumber)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < idList.length; i++) {
            NftToType[idList[i]] = typeNumber;
        }
    }

    // set multiplier for specific token id
    function setTypeMultiplier(uint256 typeNumber, uint256 multiplier)
        external
        onlyOwner
    {
        if (typeNumber == 1) {
            type1Multiplier = multiplier;
        }
        if (typeNumber == 2) {
            type2Multiplier = multiplier;
        }
        if (typeNumber == 3) {
            type3Multiplier = multiplier;
        }
    }

    // set base rate
    function setBaseRate(uint256 baseRate) external onlyOwner {
        NFT_BASE_RATE = baseRate;
    }

    // set token address
    function setTokenAddress(address tokenAddress) external onlyOwner {
        TOKEN_ADDRESS = tokenAddress;
    }

    //unstake all tokens , used for emergency unstaking , requires deploying a new contract
    //  NftTimeStaked , NftToStaker ,  StakerToNft , nftStaked still defined
    function emergencyUnstake() external payable onlyOwner {
        require(locked == true, "lock is on");
        uint256 currSupply = nft.totalSupply();
        for (uint256 i = 0; i < currSupply; i++) {
            if (NftToStaker[i] != address(0)) {
                address sendAddress = NftToStaker[i];
                nft.transferFrom(address(this), sendAddress, i);
            }
        }
    }

    //return lock change
    function returnLockToggle() public onlyOwner {
        locked = !locked;
    }

    // activate staking
    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }

    //withdraw amount of tokens or all tokens
    function withdraw(uint256 bal) external onlyOwner {
        uint256 balance = bal;
        if (balance == 0) {
            balance = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, balance);
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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