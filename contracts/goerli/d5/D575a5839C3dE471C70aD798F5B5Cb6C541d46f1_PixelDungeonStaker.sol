/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

contract PixelDungeonStaker is Ownable, IERC721Receiver{
    IERC721 public PixelDungeonNFT;

    struct StakeInfo {
        uint256 since;
        bool locked;
    }

    mapping(address => mapping(uint256 => StakeInfo)) public userTokenStakeInfo; 
    mapping(address => uint256[]) private userTokenOwnershipList;
    mapping(address => uint256) private updateRewards;

    uint256 private stakeTime = 10;
    uint256 private smallReward = 0.02 ether;
    uint256 private midReward = 0.04 ether;
    uint256 private largeReward = 0.08 ether;
    uint256 private grandReward = 0.12 ether;

    bool public stakeOpen = false;

    constructor(address PixelDungeonAddress){
        PixelDungeonNFT = IERC721(PixelDungeonAddress);
    }

    //Update the variables in the contrac
    //Stake time is in seconds
    //Rewards are set in Eth amount
    function changeVariables(
        uint256 _stakeTime,
        uint256 _smallReward,
        uint256 _midReward,
        uint256 _largeReward,
        uint256 _grandReward
    )
    external onlyOwner{
        stakeTime = _stakeTime;
        smallReward = _smallReward;
        midReward = _midReward;
        largeReward = _largeReward;
        grandReward = _grandReward;
    }

    function openStaking() public onlyOwner {
        stakeOpen = !stakeOpen;
    }

    //Checks if NFT is still 'locked' within the currect stake timer
    function isLocked(StakeInfo memory info) internal view returns (bool) {
        return block.timestamp - info.since < stakeTime;//86400;
    }

    //Stake users NFT
    function stake(uint256[] calldata tokenIds_) external{
        require(stakeOpen, "Staking Needs To Be Active");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(PixelDungeonNFT.ownerOf(tokenIds_[i]) == msg.sender, "Not Your PixelDungeon To Stake");
            storePixelDungeon(msg.sender, tokenIds_[i]);
            PixelDungeonNFT.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds_[i]
            );
        }
    }

    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 100;
    }

    //Checks if the stake timer is reached and unstaked the users NFT
    //Then calculates the users reward and NFT + reward is send to that user within one transaction
    function unstake(uint256 tokenId_) external {
        require(stakeOpen, "Staking Needs To Be Active");
        StakeInfo storage info = userTokenStakeInfo[msg.sender][tokenId_];
        userTokenStakeInfo[msg.sender][tokenId_] = StakeInfo({
            since: userTokenStakeInfo[msg.sender][tokenId_].since,
            locked: isLocked(info)
        });

        require(!userTokenStakeInfo[msg.sender][tokenId_].locked, "Your champion is still fighting in the dungeon");
        require(removePixelDungeon(msg.sender, tokenId_) == true, "Not your PixelDungeon Token");

        uint256 rewards = uint256(calculateRewards());
        updateRewards[msg.sender] += uint256(rewards);

        PixelDungeonNFT.isApprovedForAll(address(this), msg.sender);
        PixelDungeonNFT.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId_
        );                  

        withdrawPrizeMoney(updateRewards[msg.sender]);
    }

    function clearRewards(address _user) external onlyOwner {
        updateRewards[_user] = 0;
    }

    //Stores the NFT into the users 'staked' nft pool within the contract
    function storePixelDungeon(address owner_, uint256 tokenId_) internal
    {
        uint256 now_ = block.timestamp;
        userTokenStakeInfo[owner_][tokenId_] = StakeInfo({
            since: now_,
            locked: true
        });
        userTokenOwnershipList[owner_].push(tokenId_);
    }

    //Remove the NFT from the users 'staked' nft pool
    function removePixelDungeon(address owner_, uint256 tokenId_) internal returns(bool)
    {
        delete userTokenStakeInfo[owner_][tokenId_];

        uint256 tokensOwnedCount = userTokenOwnershipList[owner_].length;
        for (uint256 i = 0; i < tokensOwnedCount; i++) {
            if (userTokenOwnershipList[owner_][i] == tokenId_) {
                uint256 length = userTokenOwnershipList[owner_].length;
                userTokenOwnershipList[owner_][i] = userTokenOwnershipList[
                    owner_
                ][length - 1];
                userTokenOwnershipList[owner_].pop();
                return true;
            }
        }
        return false;
    }

    //Randomly formulates the winnings for an unstaked NFT
    function calculateRewards()
        internal view
        returns (uint256)
    {
        uint256 reward = 0;
        uint256 randomNumber = random();

        if(randomNumber <= 1){
            reward += grandReward;
        }
        if(randomNumber > 1 && randomNumber <= 4){
            reward += largeReward;
        }
        if(randomNumber > 4 && randomNumber <= 10){
            reward += midReward;
        }
        if(randomNumber > 10 && randomNumber <= 95){
            reward += smallReward;
        }
        
        return reward;
    }

    //Returns a list of the users staked NFTs
    function returnStakedNFTs() external view returns(uint256 [] memory){
        uint256 tokensOwnedCount = userTokenOwnershipList[msg.sender].length;
        uint256[] memory stakedList = new uint256[](tokensOwnedCount);

        for (uint256 i = 0; i < tokensOwnedCount; i++) {
            stakedList[i] = userTokenOwnershipList[msg.sender][i];    
        }

        return stakedList;
    }

    //Checks if any of users NFTs are unlocked
    function returnStakedNFTsAreUnlocked() external view returns(bool){
        uint256 tokensOwnedCount = userTokenOwnershipList[msg.sender].length;
        uint256[] memory stakedList = new uint256[](tokensOwnedCount);

        for (uint256 i = 0; i < tokensOwnedCount; i++) {
            stakedList[i] = userTokenOwnershipList[msg.sender][i];    
        }


        for (uint256 i = 0; i < stakedList.length; i++) {

            StakeInfo storage info = userTokenStakeInfo[msg.sender][stakedList[i]];

            if(block.timestamp - info.since > stakeTime){
                return true;
            }       
        }

        return false;
    }

    //Checks if a chosen NFT is unlocked
    function returnStakedNFTIsUnlocked(uint256 _NFTNumber) external view returns(bool){
        StakeInfo storage info = userTokenStakeInfo[msg.sender][_NFTNumber];
        if(info.since <= 0){
            return false;
        }

        if(block.timestamp - info.since > stakeTime){
            return true;
        }    

        return false;
    }

    function withdrawPrizeMoney(uint256 _prizeWinnings) internal {
        payable(msg.sender).transfer(_prizeWinnings);
        updateRewards[msg.sender] = 0;
    }

    //Add eth amount to contract prize pool
    function topUpContract() public payable onlyOwner {
        require(msg.value > .01 ether);
    }

    //Withdraw entire contract balance
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //Query for balance
    function getBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}