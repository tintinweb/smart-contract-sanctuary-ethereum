// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


interface IERC721Receiver {
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
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


contract StakeNFT is Ownable {

    //State variabble
    uint private _stakingId = 0;
    address private NFTToken = 0x5b8a7C40b2c36E970794d6d7F8CFB8329e9199e1;
    address private REWARDToken = 0x8F1B7bfeFC8787C505419Fae0F2D9eB2D4203229;

    address private admin;
    uint private rate;

    //constructor
    constructor(){
        admin = msg.sender;
    }

    //enumerator
    enum StakingStatus {Active, Cancelled}

    //structs
    struct Staking {
        address staker;    
        address token;
        uint tokenId;
        uint releaseTime;
        StakingStatus status;
        uint StakingId;
    }

    //mapping
    mapping(uint => Staking) private _StakedItem; 


    //event
    event tokenStaked(address indexed staker, address indexed token, uint token_id, StakingStatus status, uint StakingId);
    event tokenCancelComplete(address indexed token, uint indexed token_id, StakingStatus indexed status, uint StakingId);

    //function to call another function
    function callStakeToken(address token, uint _tokenID) public {
        require(token == NFTToken, "incorrect NFT to stake"); // hardcode the NFT smart contract to allow only specific NFT into staking, assume 0xd2...d005 as NFT contract address
        stakeToken(token, _tokenID);
    }

    //function to transfer NFT from user to contract
    function stakeToken(address token, uint tokenId)private returns(Staking memory) {
        IERC721(token).transferFrom(msg.sender,address(this),tokenId); // User must approve() this contract address via the NFT ERC721 contract before NFT can be transfered
        uint releaseTime = block.timestamp;
        
        uint currentStakingId = _stakingId;

        Staking memory staking = Staking(msg.sender,token, tokenId, releaseTime, StakingStatus.Active, currentStakingId);
        

        _StakedItem[_stakingId] = staking;
        _stakingId++;

        emit tokenStaked(msg.sender, staking.token, staking.tokenId, staking.status, currentStakingId);
        
        return _StakedItem[currentStakingId];
    }

    //function to stake all NFTs owned by a user in a specific smart contract
    function stakeAll(address token, uint256[] memory tokenIds) external {
        require(token == NFTToken, "incorrect NFT to stake"); // hardcode the NFT smart contract to allow only specific NFT into staking, assume 0xd2...d005 as NFT contract address
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            stakeToken(token, tokenIds[currentId]);
        }
    }

    //function to view staked NFT
    function viewStake(uint stakingId)public view returns (Staking memory) {
        return _StakedItem[stakingId];
    }

    //function to claim reward
    function claimStake(uint stakingId) public returns(Staking memory){
        Staking storage staking = _StakedItem[stakingId];
        
        require(staking.staker == msg.sender,"You cannot cancel this staking as it is not listed under this address");
        require(staking.status == StakingStatus.Active,"Your reward is not claimable");

        uint amount = rate * (block.timestamp - staking.releaseTime) / 5 minutes;
        staking.releaseTime = block.timestamp;
        staking.status = StakingStatus.Active;

        IERC20(REWARDToken).transfer(msg.sender, amount);

        // IERC721(staking.token).transferFrom(address(this), msg.sender, staking.tokenId);
        
        return _StakedItem[stakingId];
    }
    
    //function to claim reward of all tokens at once
    function claimStakeAll(uint256[] memory stakedTokenIds) external {
        for(uint currentId = 0; currentId < stakedTokenIds.length; currentId++) {
            claimStake(stakedTokenIds[currentId]);
        }
    }

    //function to cancel NFT stake
    function cancelStake(uint stakingId) public returns (Staking memory) {
        Staking storage staking = _StakedItem[stakingId];
        require(staking.staker == msg.sender,"You cannot cancel this staking as it is not listed under this address");
        require(staking.status == StakingStatus.Active,"Staking is either not active (Cancalled or in claiming process)");
        
        claimStake(stakingId);
        staking.status = StakingStatus.Cancelled;
        IERC721(staking.token).transferFrom(address(this), msg.sender, staking.tokenId);


        emit tokenCancelComplete(staking.token, staking.tokenId, staking.status, staking.StakingId);
        return _StakedItem[stakingId];
    }

    //function to cancel NFT stake of all staked NFTs by a user
    function cancelStakeAll(uint256[] memory stakedTokenIds) external {
        for(uint currentId = 0; currentId < stakedTokenIds.length; currentId++) {
            cancelStake(stakedTokenIds[currentId]);
        }
    }

    //function to set reward rate per day
    function setRewardRate(uint newRate) external onlyAdmin {
        rate = newRate;
    }

    function getRewardRate() external view returns (uint) {
        return rate;
    }

    function getTotalStaked() external view returns (uint) {
        return _stakingId;
    }
    modifier onlyAdmin{
        require(admin == msg.sender, "OA");
        _;
    }

    function setNewAdmin(address newAdd) external onlyAdmin{
        admin = newAdd;
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