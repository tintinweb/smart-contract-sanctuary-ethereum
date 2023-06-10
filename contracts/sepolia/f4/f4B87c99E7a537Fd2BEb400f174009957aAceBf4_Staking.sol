/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: 1155Staking/staking.sol


pragma solidity =0.8.17;






contract Staking is ERC1155Holder, Ownable, Pausable, ReentrancyGuard {

    IERC1155 nft;
    uint256 public lockingTimesAvailable;
    uint256 public totalSharesCreated;

    struct NFTLock {
        address owner;
        uint256 nftId;
        uint256 baseShares;
        uint256 bonusShares;
        uint256 timeLockShare;
        uint256 lockTime;
        uint256 unlockTime;
        bool staked;
    }

    
    // Mapping of staker addresses to their total shares
    mapping(address => uint256) public totalShares;

    //mapping of nfts per tier staked
    mapping(uint256 => uint256) public countPerTier;

    // Mapping of staker addresses to their index in array
    mapping(address => uint256)  addressIndex;

    address[] public stakers;

    // Mapping of staked NFT lock IDs to their lock details
    mapping(uint256 => NFTLock) public NFTId;

    // Mapping of staker addresses to their nft Ids
    mapping(address => uint256[]) stakersNfts;

                                                    //[1,2,3,4]
    mapping(uint256 => uint256) public lockTimes;  // [60 ,7889229, 15778458, 34186659]
    mapping(uint256 => uint256) public baseShare;  // [50 ,300, 1500, 4000]
    mapping(uint256 => uint256) public bonusSharePercentage; // [0 ,100, 200, 250]  100 for 10%
    mapping(uint256 => uint256) public timeLockBonusPercentage; // [0 ,100, 150, 250]  100 for 10%

    event staked(address owner, uint256 nftId, uint256 shares, uint256 unlocktime);
    event lockExtended(uint256 nftId, uint256 newUnlockTime);
    event withdrawn(uint256[]  unstaked);  

 
    constructor(){ 
        
    }

    function stake(uint256[] calldata tokenIds, uint256[] calldata lockTime) external whenNotPaused nonReentrant{
        require(tokenIds.length == lockTime.length, "length mis matched");
        for(uint256 i = 0; i < tokenIds.length; i++){
            require(lockTime[i] <= lockingTimesAvailable && lockTime[i] != 0, "lock time error");
            nft.safeTransferFrom(msg.sender, address(this), tokenIds[i], 1, "");
            uint256 tier = getTier(tokenIds[i]);
            uint256 _baseShare = baseShare[tier];
            uint256 _bonusShare = (_baseShare * bonusSharePercentage[tier])/1000;
            uint256 _timeLockShare = (_baseShare * timeLockBonusPercentage[lockTime[i]])/1000;
            uint256 _totalShare = _baseShare + _bonusShare + _timeLockShare;
            uint256 _lockTime = lockTimes[lockTime[i]];
            uint256 unlockTime = block.timestamp + _lockTime;
            NFTId[tokenIds[i]] = NFTLock(
                msg.sender,
              tokenIds[i],
              _baseShare,
               _bonusShare,
                _timeLockShare,
                 _lockTime,
                  unlockTime,
                   true);

            totalSharesCreated += _totalShare;
            if(totalShares[msg.sender] == 0){
             stakers.push(msg.sender);
             addressIndex[msg.sender] = stakers.length - 1;
            }
            totalShares[msg.sender] += _totalShare;
            stakersNfts[msg.sender].push(tokenIds[i]);

            countPerTier[tier] += 1;
            emit staked(msg.sender, tokenIds[i], _totalShare, unlockTime);
        }

    }


    function unstake(uint256[] calldata tokenIds) external whenNotPaused nonReentrant{
             for(uint256 i = 0; i < tokenIds.length; i++){
                 require( NFTId[tokenIds[i]].owner == msg.sender, "caller not owner");
                 require(NFTId[tokenIds[i]].unlockTime < block.timestamp, "not unlocked");
                 nft.safeTransferFrom(address(this), msg.sender, tokenIds[i], 1, "");
                 uint256 shares = NFTId[tokenIds[i]].baseShares + NFTId[tokenIds[i]].bonusShares + NFTId[tokenIds[i]].timeLockShare;
                 totalShares[msg.sender] -= shares;
                 totalSharesCreated -= shares;
                 if(totalShares[msg.sender] == 0){
                     uint256 currentIndex = addressIndex[msg.sender];
                     stakers[currentIndex] = stakers[stakers.length - 1];
                     addressIndex[stakers[currentIndex]] = currentIndex;
                     stakers.pop(); 
                 }

                 for(uint256 j = 0; j < stakersNfts[msg.sender].length; j++){
                        if (stakersNfts[msg.sender][j] == tokenIds[i]) {
                        // Swap the last element with the element to remove, then pop it off
                        stakersNfts[msg.sender][j] = stakersNfts[msg.sender][stakersNfts[msg.sender].length - 1];
                         stakersNfts[msg.sender].pop();
                        break;
                         }
                 }
                 
                 delete NFTId[tokenIds[i]];
                 uint256 tier = getTier(tokenIds[i]);
                 countPerTier[tier] -= 1;
             }
             emit withdrawn(tokenIds);
    }

    function extendLock(uint256 nftId, uint256 _newTime) external whenNotPaused nonReentrant{
            require( NFTId[nftId].owner == msg.sender && NFTId[nftId].staked == true, "caller not owner");
            require( NFTId[nftId].lockTime < lockTimes[_newTime] && _newTime <= lockingTimesAvailable, "time error"); 
                uint256 tier = getTier(nftId);
            uint256 _baseShare = baseShare[tier];
            uint256 _bonusShare = (_baseShare * bonusSharePercentage[tier])/1000;
            uint256 _timeLockShare = (_baseShare * timeLockBonusPercentage[_newTime])/1000;
            uint256 totalShare = _baseShare + _bonusShare + _timeLockShare;
            uint256 _lockTime = lockTimes[_newTime];
            uint256 oldShare = NFTId[nftId].baseShares + NFTId[nftId].bonusShares +NFTId[nftId].timeLockShare;
            uint256 addedShare = totalShare - oldShare;
            NFTId[nftId] = NFTLock(
            msg.sender,
              nftId,
              _baseShare,
               _bonusShare,
                _timeLockShare,
                 _lockTime,
                  block.timestamp + _lockTime,
                   true);

            totalSharesCreated += addedShare;
            totalShares[msg.sender] += addedShare;
            emit lockExtended(nftId, _newTime);
    }


    function setLockTimes(uint256[] calldata _locktimes, uint256[] calldata _timestamps) external onlyOwner{
        require(_locktimes.length == _timestamps.length, "length mismatched");
        require(lockingTimesAvailable != 0 , "lock time error");
        for(uint256 i = 0; i < _locktimes.length; i++){
            lockTimes[_locktimes[i]] = _timestamps[i];
        } 
    }

    function setBonusSharePercentage(uint256[] calldata _index, uint256[] calldata _bonusSharePercentage) external onlyOwner{
        require(_index.length == _bonusSharePercentage.length, "length mismatched");
        for(uint256 i = 0; i < _index.length; i++){
            bonusSharePercentage[_index[i]] = _bonusSharePercentage[i];
        }
    }

    function setBaseShares(uint256[] calldata _index, uint256[] calldata _baseShares) external onlyOwner{
        require(_index.length == _baseShares.length, "length mismatched");
        for(uint256 i = 0; i < _index.length; i++){
            baseShare[_index[i]] = _baseShares[i];
        }
    }

    function setTimeLockBonusPercentage(uint256[] calldata _index, uint256[] calldata _timeLockBonus) external onlyOwner{
        require(_index.length == _timeLockBonus.length, "length mismatched");
        for(uint256 i = 0; i < _index.length; i++){
            timeLockBonusPercentage[_index[i]] = _timeLockBonus[i];
        }
    }

    function setTotalLockingTimes(uint256 _value) external onlyOwner{
        require(_value != 0, "cannot be 0");
        lockingTimesAvailable = _value;
    }


    function unlockNfts(uint256[] calldata ids) external onlyOwner{
            for(uint256 i = 0; i < ids.length; i++){
                NFTId[ids[i]].unlockTime = 0;
            }
    }

    function totalStakers() external view returns(uint256){
            return stakers.length;
    }

    function setNFTAddress(address _nftContract)external onlyOwner{
            nft = IERC1155(_nftContract);
    }

    function getTier(uint256 tokenId) public pure returns (uint8) {
    uint8 tier;
    while (tokenId != 0) {
        tier = uint8(tokenId % 10);
        tokenId /= 10;
    }
        return tier;
}

    function getStakersNfts(address _address) external view returns(uint256[] memory){
            uint256[] memory nfts = stakersNfts[_address];
            return nfts;
    }

    function getStakersAddresses() external view returns(address[] memory){   
             return stakers;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


}