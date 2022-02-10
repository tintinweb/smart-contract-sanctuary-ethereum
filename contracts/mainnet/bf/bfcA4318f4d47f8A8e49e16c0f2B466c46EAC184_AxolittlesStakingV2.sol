/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/AxolittlesStakingV2.sol


pragma solidity ^0.8.10;
/// @title Interface to interact with Bubbles contract.
interface IBubbles {
    function mint(address recipient, uint256 amount) external;
}

/// @author The Axolittles Team
/// @title Contract V2 for staking axos to receive $BUBBLE
contract AxolittlesStakingV2 is Ownable {
    address public AXOLITTLES = 0xf36446105fF682999a442b003f2224BcB3D82067;
    address public TOKEN = 0x58f46F627C88a3b217abc80563B9a726abB873ba;
    address public STAKING_V1 = 0x1cA6e4643062e67CCd555fB4F64Bee603340e0ea;
    bool public stakingPaused;
    bool public isVariableReward = true;
    uint256 public stakeTarget = 6000;
    // Amount of $BUBBLE generated each block, contains 18 decimals.
    uint256 public emissionPerBlock = 15000000000000000;
    uint256 internal totalStaked;

    /// @notice struct per owner address to store:
    /// a. previously calced rewards, b. number staked, and block since last reward calculation.
    struct staker {
        // number of axolittles currently staked
        uint256 numStaked;
        // block since calcedReward was last updated
        uint256 blockSinceLastCalc;
        // previously calculated rewards
        uint256 calcedReward;
    }

    mapping(address => staker) public stakers;
    mapping(uint256 => address) public stakedAxos;

    constructor() {}

    event Stake(address indexed owner, uint256[] tokenIds);
    event Unstake(address indexed owner, uint256[] tokenIds);
    event Claim(address indexed owner, uint256 totalReward);
    event SetStakingPaused(bool _stakingPaused);
    event SetVariableReward(bool _isVariableReward);
    event SetStakeTarget(uint256 stakeTarget);
    event AdminTransfer(uint256[] tokenIds);

    /// @notice Function to stake axos. Transfers axos from sender to this contract.
    function stake(uint256[] memory tokenIds) external {
        require(!stakingPaused, "Staking is paused");
        require(tokenIds.length > 0, "Nothing to stake");
        stakers[msg.sender].calcedReward = _checkRewardInternal(msg.sender);
        stakers[msg.sender].numStaked += tokenIds.length;
        stakers[msg.sender].blockSinceLastCalc = block.number;
        totalStaked += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(AXOLITTLES).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            stakedAxos[tokenIds[i]] = msg.sender;
        }
        emit Stake(msg.sender, tokenIds);
    }

    /// @notice Function to unstake axos. Transfers axos from this contract back to sender address.
    function unstake(uint256[] memory tokenIds) external {
        require(tokenIds.length > 0, "Nothing to unstake");
        require(
            tokenIds.length <= stakers[msg.sender].numStaked,
            "Not your axo!"
        );
        stakers[msg.sender].calcedReward = _checkRewardInternal(msg.sender);
        stakers[msg.sender].numStaked -= tokenIds.length;
        stakers[msg.sender].blockSinceLastCalc = block.number;
        totalStaked -= tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == stakedAxos[tokenIds[i]], "Not your axo!");
            delete stakedAxos[tokenIds[i]];
            IERC721(AXOLITTLES).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
        emit Unstake(msg.sender, tokenIds);
    }

    /// @notice Function to claim $BUBBLE.
    function claim() external {
        uint256 totalReward = _checkRewardInternal(msg.sender);
        require(totalReward > 0, "Nothing to claim");
        stakers[msg.sender].blockSinceLastCalc = block.number;
        stakers[msg.sender].calcedReward = 0;
        IBubbles(TOKEN).mint(msg.sender, totalReward);
        emit Claim(msg.sender, totalReward);
    }

    /// @notice Function to check rewards per staker address
    function checkReward(address _staker_address)
        external
        view
        returns (uint256)
    {
        return _checkRewardInternal(_staker_address);
    }

    /// @notice Internal function to check rewards per staker address
    function _checkRewardInternal(address _staker_address)
        internal
        view
        returns (uint256)
    {
        uint256 newReward = stakers[_staker_address].numStaked *
            emissionPerBlock *
            (block.number - stakers[_staker_address].blockSinceLastCalc);
        if (isVariableReward) {
            uint256 bothStaked = totalStaked +
                IERC721(AXOLITTLES).balanceOf(STAKING_V1);
            if (bothStaked >= stakeTarget) {
                newReward *= 2;
            } else {
                newReward = (newReward * bothStaked) / stakeTarget;
            }
        }
        return stakers[_staker_address].calcedReward + newReward;
    }

    //ADMIN FUNCTIONS
    /// @notice Function to change address of NFT
    function setAxolittlesAddress(address _axolittlesAddress)
        external
        onlyOwner
    {
        AXOLITTLES = _axolittlesAddress;
    }

    /// @notice Function to change address of reward token
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        TOKEN = _tokenAddress;
    }

    /// @notice Function to change amount of $BUBBLE generated each block per axo
    function setEmissionPerBlock(uint256 _emissionPerBlock) external onlyOwner {
        emissionPerBlock = _emissionPerBlock;
    }

    /// @notice Function to prevent further staking
    function setStakingPaused(bool _isPaused) external onlyOwner {
        stakingPaused = _isPaused;
        emit SetStakingPaused(stakingPaused);
    }

    ///@notice Function to turn on variable rewards
    function setVariableReward(bool _isVariableReward) external onlyOwner {
        require(isVariableReward != _isVariableReward, "Nothing changed");
        isVariableReward = _isVariableReward;
        emit SetVariableReward(isVariableReward);
    }

    ///@notice Function to change stake target for variable rewards
    function setStakeTarget(uint256 _stakeTarget) external onlyOwner {
        require(_stakeTarget > 0, "Please don't break the math!");
        stakeTarget = _stakeTarget;
        emit SetStakeTarget(stakeTarget);
    }

    /// @notice Function for admin to transfer axos out of contract back to original owner
    function adminTransfer(uint256[] memory tokenIds) external onlyOwner {
        require(tokenIds.length > 0, "Nothing to unstake");
        totalStaked -= tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = stakedAxos[tokenIds[i]];
            require(owner != address(0), "Axo not found");
            stakers[owner].numStaked--;
            delete stakedAxos[tokenIds[i]];
            IERC721(AXOLITTLES).transferFrom(address(this), owner, tokenIds[i]);
        }
        emit AdminTransfer(tokenIds);
    }
}