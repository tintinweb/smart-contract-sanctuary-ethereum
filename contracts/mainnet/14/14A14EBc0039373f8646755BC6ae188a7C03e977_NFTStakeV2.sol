/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// File: openzeppelin-contracts/contracts/utils/introspection/IERC165.sol


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

// File: openzeppelin-contracts/contracts/token/ERC721/IERC721.sol


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

// File: openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: openzeppelin-contracts/contracts/utils/Context.sol


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

// File: openzeppelin-contracts/contracts/access/Ownable.sol


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

// File: NFTStakeV2.sol


pragma solidity ^0.8.0;



interface IMint{
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface IV1{
    struct StakeInfo{
        uint32 stakeTime;
        uint32 unstakeTime;
        uint192 claimedReward;
    }
    function stakeNFT() external view returns(IERC721Enumerable);
    function rewardNFT() external view returns(IMint);
    function rewards(address) external view returns(uint192);
    function stakeInfos(uint256) external view returns(StakeInfo memory);
    function blackTokens(uint256) external view returns(bool);
    function getPower(uint16) external view returns(uint8);
    function getReward(uint256, uint256, uint256) external view returns(uint192);
    function tokenIdsWithStakeInfo(address, uint256, uint256) external view returns(uint256, uint256[] memory, StakeInfo[] memory, uint192[] memory);
}

contract NFTStakeV2 is Ownable{
    struct StakeInfo{
        address owner;
        uint32 stakeTime;
        uint192 claimedReward;
    }
    IV1 immutable public v1;
    mapping(uint256 => StakeInfo) public _stakeInfos;
    bool public stakeOpen = true;
    mapping(address => uint192) public rewards;
    
    constructor(IV1 _v1){
        v1 = _v1;
    }
    
    modifier onlyOpen(){
        require(stakeOpen, "Stake:notOpen");
        _;
    }
    
    function setStakeOpen(bool enable) external onlyOwner{
        stakeOpen = enable;
    }
    
    function nestingTransfer(uint256 tokenId) external pure returns(bool){
        return true;
    }
    
    function stakeInfos(uint256 tokenId) public view returns(StakeInfo memory infov2){
        infov2 = _stakeInfos[tokenId];
        if(infov2.owner == address(0)){
            IV1.StakeInfo memory infov1 = v1.stakeInfos(tokenId);
            infov2 = StakeInfo(v1.stakeNFT().ownerOf(tokenId), infov1.stakeTime, infov1.claimedReward);
        }
    }
    
    function _checkOwner(uint16 tokenId) internal view returns(address _owner){
        _owner = v1.stakeNFT().ownerOf(tokenId);
        require(_owner == msg.sender || owner() == msg.sender, "Stake:notOwner");
    }
    
    function _stake(uint16 tokenId) internal{
        address _owner = _checkOwner(tokenId);
        StakeInfo memory infov2 = _stakeInfos[tokenId];
        if(infov2.owner == address(0)){
            IV1.StakeInfo memory infov1 = v1.stakeInfos(tokenId);
            if(infov1.stakeTime > 0){
                _stakeInfos[tokenId] = StakeInfo(_owner, infov1.stakeTime, infov1.claimedReward);
                return;
            }
        }else if(infov2.owner == _owner){
            require(infov2.stakeTime == 0, "Stake:staked");
        }
        _stakeInfos[tokenId] = StakeInfo(_owner, uint32(block.timestamp), 0);
    }
    
    function stake(uint16 tokenId) external onlyOpen{
        _stake(tokenId);
    }
    
    function batchStake(uint16[] calldata tokenIds) external onlyOpen{
        for(uint256 i = 0; i < tokenIds.length; i++){
            _stake(tokenIds[i]);
        }
    }
    
    function stakeInfoAndReward(uint16 tokenId, address _owner) public view returns(uint192 totalReward, StakeInfo memory infov2){
        infov2 = stakeInfos(tokenId);
        if(v1.blackTokens(tokenId)){
            totalReward = infov2.claimedReward;
        }else if(infov2.owner == _owner && infov2.stakeTime > 0){
            totalReward = v1.getReward(infov2.stakeTime, block.timestamp, v1.getPower(tokenId));
        }
    }
    
    function unstake(uint16 tokenId) public{
        address _owner = _checkOwner(tokenId);
        (uint192 totalReward, StakeInfo memory infov2) = stakeInfoAndReward(tokenId, _owner);
        _stakeInfos[tokenId] = StakeInfo(_owner, 0, 0);
        rewards[_owner] += (totalReward - infov2.claimedReward);
    }
    
    function batchUnstake(uint16[] calldata tokenIds) external{
        for(uint256 i = 0; i < tokenIds.length; i++){
            unstake(tokenIds[i]);
        }
    }
    
    function _claimReward(uint16 tokenId) internal returns(uint192 reward){
        address _owner = v1.stakeNFT().ownerOf(tokenId);
        require(_owner == msg.sender, "Stake:notOwner");
        (uint192 totalReward, StakeInfo memory infov2) = stakeInfoAndReward(tokenId, _owner);
        reward = totalReward - infov2.claimedReward;
        _stakeInfos[tokenId] = StakeInfo(_owner, infov2.stakeTime, totalReward);
    }
    
    function _claim(uint192 reward) internal {
        uint192 amount = reward / 1e18;
        require(amount > 0, "Stake:notEnoughReward");
        rewards[msg.sender] = reward % 1e18;
        v1.rewardNFT().mint(msg.sender, 0, amount, "");
    }
    
    function claim(uint16 tokenId) external{
        uint192 reward = rewards[msg.sender] + _claimReward(tokenId);
        _claim(reward);
    }
    
    function batchClaim(uint16[] calldata tokenIds) external{
        uint192 reward = rewards[msg.sender];
        for(uint256 i = 0; i < tokenIds.length; i++){
            reward += _claimReward(tokenIds[i]);
        }
        _claim(reward);
    }
    
    function tokenIdsWithStakeInfo(address account, uint256 pageStart, uint256 pageSize) external view returns(
        uint256 len, uint256[] memory tokenIds, StakeInfo[] memory stakeInfos_, uint192[] memory totalRewards){
        IERC721Enumerable nft = v1.stakeNFT();
        len = nft.balanceOf(account);
        uint256 size;
        if(pageStart < len){
            size = len - pageStart;
            if(size > pageSize) size = pageSize;
        }
        tokenIds = new uint256[](size);
        stakeInfos_ = new StakeInfo[](size);
        totalRewards = new uint192[](size);
        for(uint256 i = 0; i < size; i++){
            uint256 tokenId = nft.tokenOfOwnerByIndex(account, pageStart+i);
            tokenIds[i] = tokenId;
            (uint192 totalReward, StakeInfo memory infov2) = stakeInfoAndReward(uint16(tokenId), account);
            stakeInfos_[i] = infov2;
            totalRewards[i] = totalReward;
        }
    }
    
    function migrageReward(address[] calldata accounts, uint192[] calldata _rewards) external onlyOwner{
        require(accounts.length == _rewards.length, "arrayNotMatch");
        for(uint256 i = 0; i < accounts.length; i++){
            rewards[accounts[i]] += _rewards[i];
        }
    }
}