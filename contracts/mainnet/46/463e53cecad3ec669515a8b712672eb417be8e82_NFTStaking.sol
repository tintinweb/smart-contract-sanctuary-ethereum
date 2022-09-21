/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 */
contract Cloneable {

    /**
        @dev Deploys and returns the address of a clone of address(this
        Created by DeFi Mark To Allow Clone Contract To Easily Create Clones Of Itself
        Without redundancy
     */
    function clone() external returns(address) {
        return _clone(address(this));
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

interface IERC721Metadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NFTStakingData is ReentrancyGuard {

    uint256 internal constant PRECISION = 10**18;

    address public NFT;
    address public rewardToken;
    uint256 public lockTime;

    address public lockTimeSetter;

    uint256 public dividendsPerNFT;
    uint256 public totalDividends;
    uint256 public totalStaked;

    string public name;
    string public symbol;

    struct UserInfo {
        uint256[] tokenIds;
        uint256 balance;
        uint256 totalExcluded;
        uint256 totalRewardsClaimed;
    }

    struct StakedTokenId {
        uint256 index;      // index in user token id array
        uint256 timeLocked; // time the id was locked
        address owner;
    }

    mapping ( address => UserInfo ) public userInfo;
    mapping ( uint256 => StakedTokenId ) public tokenInfo;
}

contract NFTStaking is NFTStakingData, Cloneable, IERC721, IERC721Metadata {

    function __init__(
        address NFT_,
        address rewardToken_,
        uint256 lockTime_,
        string calldata name_,
        string calldata symbol_,
        address lockTimeSetter_
    ) external {
        require(
            NFT_ != address(0) &&
            NFT == address(0),
            'Invalid Init'
        );

        NFT = NFT_;
        rewardToken = rewardToken_;
        lockTime = lockTime_;
        name = name_;
        symbol = symbol_;
        lockTimeSetter = lockTimeSetter_;
    }

    function setLockTime(uint256 newLockTime) external nonReentrant {
        require(
            msg.sender == lockTimeSetter,
            'Only Setter Can Call'
        );
        require(
            newLockTime <= 10**7,
            'Lock Time Too Long'
        );
        lockTime = newLockTime;
    }

    function setLockTimeSetter(address newSetter) external nonReentrant {
        require(
            msg.sender == lockTimeSetter,
            'Only Setter Can Call'
        );
        lockTimeSetter = newSetter;
    }

    function stake(uint256 tokenId) external nonReentrant {
        _stake(tokenId);
    }

    function batchStake(uint256[] calldata tokenIds) external nonReentrant {
        _batchStake(tokenIds);
    }

    function withdraw(uint256 tokenId) external nonReentrant {
        _withdraw(tokenId);
    }

    function batchWithdraw(uint256[] calldata tokenIds) external nonReentrant {
        _batchWithdraw(tokenIds);
    }

    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender);
    }

    function _stake(uint256 tokenId) internal {

        // ensure message sender is owner of nft
        require(
            isOwner(tokenId, msg.sender),
            'Sender Not NFT Owner'
        );
        require(
            tokenInfo[tokenId].owner == address(0),
            'Already Staked'
        );

        // claim rewards if applicable
        _claimRewards(msg.sender);    

        // send nft to self
        IERC721(NFT).transferFrom(msg.sender, address(this), tokenId);

        // ensure nft is now owned by `this`
        require(
            isOwner(tokenId, address(this)),
            'NFT Ownership Not Transferred'
        );

        // increment total staked and user balance
        totalStaked++;
        userInfo[msg.sender].balance++;

        // reset total rewards
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].balance);
        
        // set current tokenId index to length of user id array
        tokenInfo[tokenId].index = userInfo[msg.sender].tokenIds.length;
        tokenInfo[tokenId].timeLocked = block.number;
        tokenInfo[tokenId].owner = msg.sender;

        // push new token id to user id array
        userInfo[msg.sender].tokenIds.push(tokenId);

        emit Transfer(address(0), msg.sender, tokenId);
    }

    function _batchStake(uint256[] calldata tokenIds) internal {

        // claim rewards if applicable
        _claimRewards(msg.sender);   

        // length of array
        uint256 len = tokenIds.length; 

        for (uint i = 0; i < len;) {
            // ensure message sender is owner of nft
            require(
                isOwner(tokenIds[i], msg.sender),
                'Sender Not NFT Owner'
            );
            require(
                tokenInfo[tokenIds[i]].owner == address(0),
                'Already Staked'
            );

            // send nft to self
            IERC721(NFT).transferFrom(msg.sender, address(this), tokenIds[i]);

            // ensure nft is now owned by `this`
            require(
                isOwner(tokenIds[i], address(this)),
                'NFT Ownership Not Transferred'
            );

            // set current tokenId index to length of user id array
            tokenInfo[tokenIds[i]].index = userInfo[msg.sender].tokenIds.length;
            tokenInfo[tokenIds[i]].timeLocked = block.number;
            tokenInfo[tokenIds[i]].owner = msg.sender;

            // push new token id to user id array
            userInfo[msg.sender].tokenIds.push(tokenIds[i]);

            emit Transfer(address(0), msg.sender, tokenIds[i]);
            unchecked { ++i; }
        }

        // increment total staked and user balance
        totalStaked += len;
        userInfo[msg.sender].balance += len;

        // reset total rewards
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].balance);
    }

    function _withdraw(uint256 tokenId) internal {
        require(
            isOwner(tokenId, address(this)),
            'NFT Is Not Staked'
        );
        require(
            tokenInfo[tokenId].owner == msg.sender,
            'Only Owner Can Withdraw'
        );
        require(
            hasStakedNFT(msg.sender, tokenId),
            'User Has Not Staked tokenId'
        );
        require(
            timeUntilUnlock(tokenId) == 0,
            'Token Still Locked'
        );

        // claim pending rewards if any
        _claimRewards(msg.sender);
        
        // decrement balance
        userInfo[msg.sender].balance -= 1;
        totalStaked -= 1;

        // reset total rewards
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].balance);

        // remove nft from user array
        _removeNFT(msg.sender, tokenId);
        
        // send nft to caller
        IERC721(NFT).transferFrom(address(this), msg.sender, tokenId);

        emit Transfer(msg.sender, address(0), tokenId);
    }

    function _batchWithdraw(uint256[] calldata tokenIds) internal {

        // claim pending rewards if any
        _claimRewards(msg.sender);

        // length of array
        uint256 len = tokenIds.length;

        // decrement balance
        userInfo[msg.sender].balance -= len;
        totalStaked -= len;

        // reset total rewards
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].balance);

        for (uint i = 0; i < len;) {
            
            require(
                isOwner(tokenIds[i], address(this)),
                'NFT Is Not Staked'
            );
            require(
                hasStakedNFT(msg.sender, tokenIds[i]),
                'User Has Not Staked tokenId'
            );
            require(
                timeUntilUnlock(tokenIds[i]) == 0,
                'Token Still Locked'
            );

            // remove nft from user array
            _removeNFT(msg.sender, tokenIds[i]);

            // send nft to caller
            IERC721(NFT).transferFrom(address(this), msg.sender, tokenIds[i]);

            // emit event
            emit Transfer(msg.sender, address(0), tokenIds[i]);

            unchecked { ++i; }
        }
    }

    /**
        Claims Reward For User
     */
    function _claimRewards(address user) internal {

        // return if zero balance
        if (userInfo[user].balance == 0) {
            return;
        }

        // fetch pending rewards
        uint pending = pendingRewards(user);
        uint max = rewardBalanceOf();
        if (pending > max) {
            pending = max;
        }
        
        // reset total rewards
        userInfo[user].totalExcluded = getCumulativeDividends(userInfo[user].balance);

        // return if no rewards
        if (pending == 0) {
            return;
        }

        // incremenet total rewards claimed
        unchecked {
            userInfo[user].totalRewardsClaimed += pending;
        }

        // transfer reward to user
        require(
            IERC20(rewardToken).transfer(
                user,
                pending
            ),
            'Failure Reward Transfer'
        );
    }

    /**
        Pending Token Rewards For `account`
     */
    function pendingRewards(address account) public view returns (uint256) {
        if(userInfo[account].balance == 0){ return 0; }

        uint256 accountTotalDividends = getCumulativeDividends(userInfo[account].balance);
        uint256 accountTotalExcluded = userInfo[account].totalExcluded;

        if(accountTotalDividends <= accountTotalExcluded){ return 0; }

        return accountTotalDividends - accountTotalExcluded;
    }

    /**
        Cumulative Dividends For A Number Of Tokens
     */
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return (share * dividendsPerNFT) / PRECISION;
    }

    function giveRewards(uint256 amount) external {
        
        uint balBefore = rewardBalanceOf();
        IERC20(rewardToken).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint balAfter = rewardBalanceOf();
        require(
            balAfter > balBefore,
            'Zero Rewards'
        );

        uint received = balAfter - balBefore;

        totalDividends += received;
        dividendsPerNFT += ( received * PRECISION ) / totalStaked;
    }

    function _removeNFT(address user, uint256 tokenId) internal {
        
        uint lastElement = userInfo[user].tokenIds[userInfo[user].tokenIds.length - 1];
        uint removeIndex = tokenInfo[tokenId].index;

        userInfo[user].tokenIds[removeIndex] = lastElement;
        tokenInfo[lastElement].index = removeIndex;
        userInfo[user].tokenIds.pop();

        delete tokenInfo[tokenId];
    }

    function timeUntilUnlock(uint256 tokenId) public view returns (uint256) {
        uint unlockTime = tokenInfo[tokenId].timeLocked + lockTime;
        return unlockTime <= block.number ? 0 : unlockTime - block.number;
    }

    function isOwner(uint256 tokenId, address user) public view returns (bool) {
        return IERC721(NFT).ownerOf(tokenId) == user;
    }

    function listUserStakedNFTs(address user) public view returns (uint256[] memory) {
        return userInfo[user].tokenIds;
    }

    function fetchBalancePendingAndTotalRewards(address user) public view returns (uint256, uint256, uint256) {
        return (userInfo[user].balance, pendingRewards(user), userInfo[user].totalRewardsClaimed);
    }
    
    function listUserStakedNFTsAndURIs(address user) public view returns (uint256[] memory, string[] memory) {
        
        uint len = userInfo[user].tokenIds.length;
        string[] memory uris = new string[](len);
        for (uint i = 0; i < len;) {
            uris[i] = IERC721Metadata(NFT).tokenURI(userInfo[user].tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return (userInfo[user].tokenIds, uris);
    }

    function listUserStakedNFTsURIsAndRemainingLockTimes(address user) public view returns (
        uint256[] memory, 
        string[] memory,
        uint256[] memory
    ) {
        
        uint len = userInfo[user].tokenIds.length;
        string[] memory uris = new string[](len);
        uint256[] memory remainingLocks = new uint256[](len);
        for (uint i = 0; i < len;) {
            uris[i] = IERC721Metadata(NFT).tokenURI(userInfo[user].tokenIds[i]);
            remainingLocks[i] = timeUntilUnlock(userInfo[user].tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return (userInfo[user].tokenIds, uris, remainingLocks);
    }

    function listUserTotalNFTs(address user, uint min, uint max) public view returns (uint256[] memory) {
        
        IERC721 NFT_ = IERC721(NFT);
        uint len = NFT_.balanceOf(user);

        uint256[] memory ids = new uint256[](len);
        uint count = 0;

        for (uint i = min; i < max;) {

            if (NFT_.ownerOf(i) == user) {
                ids[count] = i;
                count++;
            }
            
            unchecked {++i;}
        }
        return (ids);
    }

    function listUserTotalNFTsAndUris(address user, uint min, uint max) public view returns (uint256[] memory, string[] memory) {
        
        IERC721 NFT_ = IERC721(NFT);
        uint len = NFT_.balanceOf(user);

        uint256[] memory ids = new uint256[](len);
        string[] memory uris = new string[](len);
        uint count = 0;

        for (uint i = min; i < max;) {

            if (NFT_.ownerOf(i) == user) {
                ids[count] = i;
                uris[count] = IERC721Metadata(NFT).tokenURI(i);
                count++;
            }
            
            unchecked {++i;}
        }
        return (ids, uris);
    }

    function hasStakedNFT(address user, uint256 tokenId) public view returns (bool) {
        if (userInfo[user].tokenIds.length <= tokenInfo[tokenId].index || tokenInfo[tokenId].owner != user) {
            return false;
        }
        return userInfo[user].tokenIds[tokenInfo[tokenId].index] == tokenId;
    }

    function hasStakedNFTs(address user, uint256[] calldata tokenId) public view returns (bool[] memory) {
        uint len = tokenId.length;
        bool[] memory hasStaked = new bool[](len);
        for (uint i = 0; i < len;) {
            hasStaked[i] = userInfo[user].tokenIds[tokenInfo[tokenId[i]].index] == tokenId[i];
            unchecked {
                ++i;
            }
        }
        return hasStaked;
    }

    function rewardBalanceOf() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return IERC721(NFT).balanceOf(address(this));
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return userInfo[owner].balance;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        return tokenInfo[tokenId].owner;
    }

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
        address,
        address,
        uint256
    ) external override {

    }

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
        address,
        address,
        uint256
    ) external override {

    }

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
    function approve(address, uint256) external override {
        emit Approval(address(0), address(0), 0);
        return;
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 a) external view override returns (address operator) {
        return a == uint(uint160(msg.sender)) ? address(0) : msg.sender;
    }

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
    function setApprovalForAll(address, bool) external override {
        emit Approval(address(0), address(0), 0);
        return;
    }

    function isApprovedForAll(address a, address b) external view override returns (bool) {
        return a == b && a == NFT;
    }

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
        address,
        address,
        uint256,
        bytes calldata
    ) external override {

    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return IERC721Metadata(NFT).tokenURI(tokenId);
    }

}