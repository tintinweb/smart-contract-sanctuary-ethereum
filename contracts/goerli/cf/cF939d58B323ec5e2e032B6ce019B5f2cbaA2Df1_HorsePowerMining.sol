/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/**
 * ERC721A Contracts v4.1.0 sourced from Chiru Labs
 *
 * This contract is developed in conjunction with:
 * OmniHorse
 *
 * Homepage: https://omnihorse.io
 * Twitter:  https://twitter.com/omnihorse_nft
 *
 * ============================================================================
 *
 * This contract is a modified ERC721A contract that receives it's pricing
 * information from our price controller contract, the address can be found
 * by querying this contract.
 *
 * If defaultPrice is enabled than this contract's default sale price will
 * be used instead.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

contract Ownable {
    /**
     * @dev Error constants.
     */
    string public constant NOT_CURRENT_OWNER = '018001';
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = '018002';

    /**
     * @dev Current owner address.
     */
    address public owner;

    /**
     * @dev An event which is triggered when the owner is changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The constructor sets the original `owner` of the contract to the sender account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, NOT_CURRENT_OWNER);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// https://eips.ethereum.org/EIPS/eip-20
interface Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract HorsePowerMining is Ownable {
    event tokenInitialized(address tokenAddress, uint256 miningBoost);
    event miningStarted(address tokenAddress, uint256 tokenId, address user);
    event miningEnded(address tokenAddress, uint256 tokenId, address user);

    struct Miners {
        address tokenAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 lastClaimed;
        address miner;
        bool isActive;      
    }
    mapping(address => Miners[]) public minerMapping;
    mapping(address => mapping(address => mapping(uint256 => uint256))) private miner_tokenContract_tokenId_index;
    uint256 public minerCount;

    Token public OMH;

    constructor(address _OMH) {
        OMH = Token(_OMH);
    }

    mapping(address => bool) public isOMHNFT;
    mapping(address => uint256) public miningBoost;
    mapping(address => IERC721A) public OmnihorseNFTs;

    function initializeToken(address _tokenAddress, uint256 _miningBoost) external onlyOwner {
        require(!isOMHNFT[_tokenAddress], "Token already initialized");

        isOMHNFT[_tokenAddress] = true;
        miningBoost[_tokenAddress] = _miningBoost;
        OmnihorseNFTs[_tokenAddress] = IERC721A(_tokenAddress);

        emit tokenInitialized(_tokenAddress, _miningBoost);
    }

    /**
     * @dev sets the percentage boost for mining rewards of a specific horse NFT
     * Should be used to reward holders of a horse that recently won a race.
     * @param _tokenAddress is the address of the horse NFT contract
     * @param _miningBoost is the percentage boost to be given to the miner
     * @notice _miningBoost should be at least 3 digits. For example, if a 1.25% boost is desired, @param _miningBoost should be 125.
     * The calculation will be handled in the getReward function.
     */
    function setMiningBoost(address _tokenAddress, uint256 _miningBoost) external onlyOwner {
        require(isOMHNFT[_tokenAddress], "Token uninitialized");
        miningBoost[_tokenAddress] = _miningBoost;
    }

    function startMining(address _tokenAddress, uint256 _tokenId) external {
        require(isOMHNFT[_tokenAddress], "Omnihorse NFTs only");

        OmnihorseNFTs[_tokenAddress].transferFrom(msg.sender, address(this), _tokenId);
        miner_tokenContract_tokenId_index[msg.sender][_tokenAddress][_tokenId] = minerMapping[msg.sender].length;
        minerMapping[msg.sender].push(Miners(_tokenAddress, _tokenId, block.timestamp, block.timestamp, msg.sender, true));

        emit miningStarted(_tokenAddress, _tokenId, msg.sender);
    }

    function endMining(address _tokenAddress, uint256 _tokenId) external {
        uint256 index = miner_tokenContract_tokenId_index[msg.sender][_tokenAddress][_tokenId];
        require(minerMapping[msg.sender][index].isActive, "Token is not mining");

        minerMapping[msg.sender][index].startTime = 0;
        minerMapping[msg.sender][index].lastClaimed = 0;
        minerMapping[msg.sender][index].isActive = false;

        OmnihorseNFTs[_tokenAddress].transferFrom(address(this), msg.sender, _tokenId);

        emit miningEnded(_tokenAddress, _tokenId, msg.sender);
    }

    function getReward(address _miner, address _tokenAddress, uint256 _tokenId) public view returns(uint256){
        uint256 index = miner_tokenContract_tokenId_index[_miner][_tokenAddress][_tokenId];
        uint256 boost = miningBoost[_tokenAddress] > 0 ? miningBoost[_tokenAddress] : 100;
        if(minerMapping[_miner][index].isActive) {
            return ((block.timestamp - minerMapping[_miner][index].lastClaimed) * boost) / 100;
        }
        return 0;
    }

    function withdrawReward(address _miner, address _tokenAddress, uint256 _tokenId) external {
        uint256 index = miner_tokenContract_tokenId_index[_miner][_tokenAddress][_tokenId];
        uint256 reward = getReward(_miner, _tokenAddress, _tokenId);
        
        require(reward > 0, "Reward is 0");

        minerMapping[_miner][index].lastClaimed = block.timestamp;
        bool success = OMH.transfer(msg.sender, reward);
        require(success, "Token transfer failed");
    }

    /**
     * @dev emergency update in case of incorrect OMH address on initialization or 
     * new OMH token address.
     */
    function setOMH(address _OMH) external onlyOwner {
        OMH = Token(_OMH);
    }

    function addLiquidity(uint256 amount) external onlyOwner {
        OMH.transferFrom(msg.sender, address(this), amount);
    }

}