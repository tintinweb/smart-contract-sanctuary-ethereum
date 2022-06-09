// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

/**
 * @dev This is a smart contract which provides staking and unstaking facilities with time-lock only for AnimeMetaverse NftTokens.
 * Owners of AnimeMetaverse NftTokens can call `stake` function to stake their NftTokens and `unstake` function to unstake their NftTokens.
 * When owner of the NftTokens call `stake` function he provides a list of tokenIds and a time-lock type.
 * Based on the type of time-lock, Time-lock values are defined which can only be 0,30,60,90 days.
 * Once the NftTokens' owner call the staking function, the ownership of these NftTokens are trasferred from the owner address to this smart contract address.
 * The owner's address, current timestamp and time-lock are saved in a vault of this smart contrct.
 * Later, when the owner of these NftTokens call the unstake function with a list of NftTokenIds, Firstly, it is checked that whether this caller was the previous owner
 * of these NftTokens or not.
 * This checking is done with the data saved in `vault`.
 * Then the time-lock validation is checked.
 * If these checking are done, then the NftTokens ownership is given back to the orginal owner from this smart contract address.
 */

contract AmvNftStaker is Ownable {
    // Stores counts of staked NFT tokens.
    uint256 public totalStaked;

    // Flag to enable or disable the staking.
    bool public isOpenForStaking = true;

    // Flag to enable or disable the time-lock checking during unstaking.
    bool public isTimeLockActive = true;

    // Stores maximum length of batch staking/unstaking tokenIds array.
    uint256 public maxInputSize = 10;

    // Maximum token size to be set for batch staking and unstaking.
    uint256 public constant allowedMaxInputSize = 100;

    // Stores AMV smart contract details.
    IERC721 public nft;

    // String constant to determine the event type.
    bytes32 public constant stakingEventType = "staking";

    // String constant to determine the event type.
    bytes32 public constant unStakingEventType = "unstaking";

    // TimeLock for NFT staking
    // Value of ZERO_DAY = 0
    // Value of THIRTY_DAYS = 1
    // Value of SIXTY_DAYS = 2
    // Value of NINETY_DAYS = 3
    enum TimeLock {
        ZERO_DAY,
        THIRTY_DAYS,
        SIXTY_DAYS,
        NINETY_DAYS
    }

    // Struct to store a stake's tokenId, address of the owner and function execution timestamp and the token's owner defined time-lock for unstaking.
    struct Stake {
        uint256 tokenId;
        address owner;
        uint256 stakedAt;
        uint256 timeLock;
    }

    // Stores all possible value of time-locks
    uint256[4] public timeLocks = [0, 30 * 86400, 60 * 86400, 90 * 86400];

    // Maps tokenId to stake details.
    mapping(uint256 => Stake) public vault;

    // List of tokens that have been staked at least once.
    uint256[] public nftTokenIds;

    // Maps tokenId to bool to check if tokenId has been staked at least once.
    mapping(uint256 => bool) public tokenIdExist;

    /**
     * @dev Emits when the NFTs are staked.
     * @param owner The address of the owner of these NFTs.
     * @param tokenIds The tokenIDs of these NFTs.
     * @param timestamp The execution timestamp of the staking function.
     * @param eventType The Type of this event.
     */
    event NFTStaked(
        address owner,
        uint256[] tokenIds,
        uint256 timestamp,
        bytes32 eventType
    );

    /**
     * @dev Emits when the NFTs are unstaked.
     * @param owner The address of the owner of these NFTs.
     * @param tokenIds The tokenIDs of these NFTs.
     * @param timestamp The execution timestamp of the unstaking function.
     * @param eventType The Type of this event.
     */
    event NFTUnstaked(
        address owner,
        uint256[] tokenIds,
        uint256 timestamp,
        bytes32 eventType
    );

    /**
     * @dev Initializes the contract.
     * Creates instance of AnimeMetaverse smart contract through constructor.
     */
    constructor(address amvAddress) {
        nft = IERC721(amvAddress);
    }

    /**
     * @notice Only Owner of this smart contract is allowed to call this function.
     * @dev public function to set the maximum length of batch staking/unstaking tokenIds array.
     */
    function setMaxInputSize(uint256 _maxInputSize) public onlyOwner {
        /**
         * @dev Throws if _maxInputSize is greater than 100.
         */
        require(
            _maxInputSize <= allowedMaxInputSize,
            "Can not set MaxInputSize more than 100"
        );
        /**
         * @dev Throws if _maxInputSize is less than 1.
         */
        require(_maxInputSize >= 1, "Can not set MaxInputSize less than 1");
        maxInputSize = _maxInputSize;
    }

    /**
     * @notice Only Owner of this smart contract is allowed to call this function.
     * @dev public function to change the value of `isOpenForStaking` flag which decides whether staking to this smart contract is allowed or not .
     */
    function setIsOpenForStaking(bool _isOpenForStaking) public onlyOwner {
        isOpenForStaking = _isOpenForStaking;
    }

    /**
     * @notice Only Owner of this smart contract is allowed to call this function.
     * @dev public function to change the value of `isTimeLockActive` flag which decides whether time-lock will be considered during unstaking or not .
     */
    function setIsTimeLockActive(bool _isTimeLockActive) public onlyOwner {
        isTimeLockActive = _isTimeLockActive;
    }

    /**
     * @notice Use this function with caution. Wrong usage can have serious consequences.
     * @dev external function to stake AnimeMetaverse NFTs from owner address of these NFTs to this smart contract address.
     * @param tokenIds uint256[] tokenIDs of the AnimeMetaverse NFTs to be staked to this smart contract address.
     */
    function stake(uint256[] calldata tokenIds, uint8 timeLockType) external {
        /**
         * @dev Throws if the `isOpenForStaking` is false.
         */
        require(isOpenForStaking, "Staking is not allowed");

        /**
         * @dev Throws if the `timeLockType` is not between 0 and 3.
         */
        require(
            timeLockType == uint8(TimeLock.ZERO_DAY) ||
                timeLockType == uint8(TimeLock.THIRTY_DAYS) ||
                timeLockType == uint8(TimeLock.SIXTY_DAYS) ||
                timeLockType == uint8(TimeLock.NINETY_DAYS),
            "Invalid timeLock type"
        );

        /**
         * @dev Throws if the `tokenIds` is empty or count of `tokenIds` is more than 50.
         */
        require(tokenIds.length > 0, "Input parameter array is empty");
        require(
            tokenIds.length <= maxInputSize,
            "Maximum Input size of tokenIds is exceded"
        );

        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            /**
             * Getting owner's address of this tokenId from AnimeMetaverse NFT smart contract.
             * @dev Throws if `nftOwnerAddress` doesn't match with `msg.sender`.
             */
            address nftOwnerAddress = nft.ownerOf(tokenId);
            require(
                nftOwnerAddress == msg.sender,
                "Sender is not the owner of the token"
            );

            /**
             * @dev Throws if the tokenId of this NFT is already staked.
             */
            require(vault[tokenId].tokenId == 0, "Token is already staked");

            /**
             * @dev Transfers the ownership of an NFT from `msg.sender` to `address(this)`.
             * `address(this)` means this smart contract address.
             */
            nft.transferFrom(msg.sender, address(this), tokenId);

            addNewNftToVault(tokenId, timeLocks[timeLockType]);
            addNewTokenIdToList(tokenId); //
        }
        totalStaked += tokenIds.length; // Updating the count of total staked NFT tokens.
        emit NFTStaked(msg.sender, tokenIds, block.timestamp, stakingEventType); // emiting NFTStaked event.
    }

    /**
     * @dev Private function to add NFT information to the `vault`.
     * Stores tokenId, address of the owner and function execution timestamp against tokenId using map.
     * @param tokenId uint256 tokenID of the AnimeMetaverse nfts to be added to the `vault`.
     */
    function addNewNftToVault(uint256 tokenId, uint256 timeLock) private {
        vault[tokenId] = Stake({
            owner: msg.sender,
            tokenId: tokenId,
            stakedAt: uint256(block.timestamp),
            timeLock: timeLock
        });
    }

    /**
     * @dev Private function to add tokenIds to `nftTokenIds` list.
     * Checks if this tokenId is already added to `nftTokenIds` list or not.
     * If if this tokenId is not already added to `nftTokenIds` , sets the flag for this `tokenId` true and adds to the `nftTokenIds` list
     * @param tokenId uint256 tokenID of the AnimeMetaverse nfts to be added to the `nftTokenIds` list.
     */
    function addNewTokenIdToList(uint256 tokenId) private {
        if (!tokenIdExist[tokenId]) {
            tokenIdExist[tokenId] = true;
            nftTokenIds.push(tokenId);
        }
    }

    /**
     * @notice Use this function with caution. Wrong usage can have serious consequences.
     * @dev External function to unstake AnimeMetaverse NFTs from this smart contract address to the owner of these NFTs tokenIds.
     * @param tokenIds uint256[] tokenIDs of the AnimeMetaverse NFTs to be unstaked from this smart contract address.
     */
    function unstake(uint256[] calldata tokenIds) external {
        /**
         * @dev Throws if the `tokenIds` is empty or count of `tokenIds` is more than 50.
         */
        require(tokenIds.length > 0, "Input parameter array is empty");
        require(
            tokenIds.length <= maxInputSize,
            "Maximum input size of tokenIds is exceded"
        );

        uint256 tokenId;
        totalStaked -= tokenIds.length; // updating the count of total staked NFT tokens.

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            /**
             * Getting stake information from the vault for this tokenId.
             * @dev Throws if `staked.owner` doesn't match with `msg.sender`.
             * Here, staked.owner is the owner address of this tokenId which is stored in our vault.
             */
            Stake memory staked = vault[tokenId];
            require(
                staked.owner == msg.sender,
                "Sender is not the owner of these tokens"
            );

            /**
             * @dev Throws if this smart contract is not the owner of the token.
             */
            address nftOwnerAddress = nft.ownerOf(tokenId);
            require(
                nftOwnerAddress == address(this),
                "This smart contract is not the owner of these tokens"
            );

            timeLockCheck(staked.stakedAt, staked.timeLock);

            removeNftFromVault(tokenId);

            /**
             * @dev Transfers the ownership of an NFT from `address(this)` to`msg.sender`.
             * Here, `address(this)` means this smart contract address.
             */
            nft.transferFrom(address(this), msg.sender, tokenId);
        }

        emit NFTUnstaked(
            msg.sender,
            tokenIds,
            block.timestamp,
            unStakingEventType
        ); //emiting NFTUnstaked event.
    }

    /**
     * @dev Public function to check if a token is eligible to unstake.
     * @param stakedAt uint256 staking timestamp of a token stored in `vault`.
     * @param timeLock uint256 time-lock of a token set by token's owner during staking which is stored in `vault`.
     */
    function timeLockCheck(uint256 stakedAt, uint256 timeLock) public view {
        /**
         * @dev Throws if `isTimeLockActive` is true and the differnce between the current timestamp and staking timestamp is not greater than tokens owner's predefined time-lock.
         */
        if (isTimeLockActive) {
            require(
                (block.timestamp - stakedAt) > timeLock,
                "Tokens cannot be unstaked before its chosen minimum time lock period"
            );
        }
    }

    /**
     * @dev Private function to delete NFT information from the `vault`.
     * @param tokenId uint256 tokenID of the AnimeMetaverse nfts to be added to the `vault`.
     */
    function removeNftFromVault(uint256 tokenId) private {
        delete vault[tokenId];
    }

    /**
     * @dev Public function to get a list of NFTs which are staked in our smart contract.
     * Checks every stake stored in this `vault` against this `account`
     * If the owner of any stake matches with this `account`, then collects them in a list and are returned.
     * @param account address The address that owns the NFTs.
     * @return ownrTokens A list of tokens owned by `account` from `vault`
     */
    function tokensOfOwner(address account)
        public
        view
        returns (Stake[] memory ownrTokens)
    {
        uint256 supply = nftTokenIds.length;
        Stake[] memory tmp = new Stake[](supply);

        uint256 nftCount = 0;
        for (uint256 i = 0; i < supply; i++) {
            Stake memory staked = vault[nftTokenIds[i]];
            if (staked.owner == account) {
                tmp[nftCount] = staked;
                nftCount += 1;
            }
        }
        Stake[] memory ownerTokens = new Stake[](nftCount);
        for (uint256 i = 0; i < nftCount; i++) {
            ownerTokens[i] = tmp[i];
        }
        return ownerTokens;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}