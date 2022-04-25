// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTitsStaking is Ownable {

    address public rtoken;
    address public nftAddress;
    address public sAddress;

    uint256 public RewardTokenPerBlock;
    uint256 public totalClaimed;
    uint256 public limitClaimValue;
    uint256 public initialLimitClaimValue;

    uint256 constant public TIME_STEP = 1 days;

    uint256 public dailyReward = 10 * (10 ** 18);
    uint256 public dailyMilkReward = 30 * (10 ** 18);

    address public _feeAddress = 0x653d9688f081F36DA3Fc6B653734E4214Da6AB67;
    uint256 public _feePercent = 333;
    uint256 private _feeDividen = 10000;

    bool public isFinished;

    struct StakedInfo {
        uint256 tokenId;
        uint256 checkPoint;
    }

    struct UserInfo {
        StakedInfo[] stakedInfo;
        uint256 withdrawn;
        uint256 stolenReward;
    }

    address[] public userList;

    mapping(address => UserInfo) public users;
    mapping(address => uint256) public stakingAmount;
    mapping(uint256 => bool) public milkIndex;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    constructor(address _nftAddress, address _rewardTokenAddress) {
        require (_nftAddress != address(0), "NFT token can't be adress (0)");
        require (_rewardTokenAddress != address(0), "Reward token can't be adress (0)");

        nftAddress = _nftAddress;
        rtoken = _rewardTokenAddress;
        limitClaimValue = 7777000 * (10 ** 18);
        initialLimitClaimValue = 7777000 * (10 ** 18);
        isFinished = false;
    }

    function getUserStakedInfo(address _address) public view returns(StakedInfo[] memory){
        StakedInfo[] memory stakedInfo = users[_address].stakedInfo;
        return stakedInfo;
    }

    function changeRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = _rewardTokenAddress;
    }

    function changeNFTTokenAddress(address _nftTokenAddress) public onlyOwner {
        nftAddress = _nftTokenAddress;
    }

    function changeRewardTokenPerBlock(uint256 _RewardTokenPerBlock) public onlyOwner {
        RewardTokenPerBlock = _RewardTokenPerBlock;
    }

    function changeDailyReward(uint256 _dailyReward) public onlyOwner {
        dailyReward = _dailyReward;
    }

    function setLimitClaimValue(uint256 _limitValue) public onlyOwner {
        require (_limitValue >= totalClaimed, "limitValue Should be greater than totalClaimed.");
        limitClaimValue = _limitValue;
        isFinished = false;
    }

    function setInitialLimitClaimValue(uint256 _initialLimitValue) public onlyOwner {
        initialLimitClaimValue = _initialLimitValue;
    }

    function setFeeAddress(address feeAddress) public onlyOwner {
        require (feeAddress != address(0));
        _feeAddress = feeAddress;
    }

    function setFeePercent(uint256 _fee) public onlyOwner {
        require (_fee <= 10000, "Fee must be greater than 10000");
        _feePercent = _fee;
    }

    function setStakingAddress(address _address) public {
        require (sAddress == address(0));
        sAddress = _address;
    }

    function getTotalUsers() public view returns(uint256){
        return userList.length;
    }

    function contractBalance() public view returns(uint256){
        return IERC721(nftAddress).balanceOf(address(this));
    }

    function pendingReward(address _user, uint256 _tokenId) public view returns (uint256 rewardAmount) {
        (bool _isStaked, uint256 _checkPoint) = getStakingItemInfo(_user, _tokenId);
        if(!_isStaked) return 0;

        bool isMilk = milkIndex[_tokenId];
        uint256 currentBlock = block.timestamp;

        if (isMilk) {
            rewardAmount = (currentBlock - _checkPoint) * dailyMilkReward / TIME_STEP;
        } else {
            rewardAmount = (currentBlock - _checkPoint) * dailyReward / TIME_STEP;
        }
        return rewardAmount;
    }

    function pendingTotalReward(address _user) public view returns(uint256 pending) {
        pending = 0;
        for (uint256 i = 0; i < users[_user].stakedInfo.length; i++) {
            uint256 _reward = pendingReward(_user, users[_user].stakedInfo[i].tokenId);
            pending = pending+ (_reward);
        }
        return pending;
    }

    function approve(address _token, address _spender, uint256 _amount) public returns (bool) {
        require (sAddress == msg.sender);
        IERC20(_token).approve(_spender, _amount);
        return true;
    }

    function setMilkIndex(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i =0; i < tokenIds.length; i++) {
            milkIndex[tokenIds[i]] = true;
        }
    }

    function stake(uint256[] memory tokenIds) public {
        require (!isFinished,"Staking is finished");
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(_isStaked) continue;
            if(IERC721(nftAddress).ownerOf(tokenIds[i]) != msg.sender) continue;

            IERC721(nftAddress).transferFrom(address(msg.sender), address(this), tokenIds[i]);

            StakedInfo memory info;
            info.tokenId = tokenIds[i];
            info.checkPoint = block.timestamp;

            users[msg.sender].stakedInfo.push(info);
            stakingAmount[msg.sender] = stakingAmount[msg.sender] + 1;

            addUserList (msg.sender);
            emit Stake(msg.sender, 1);
        }
    }

    function addUserList(address _user) internal{
        if (stakingAmount[_user] == 0)
            return;
        for (uint256 i = 0; i < userList.length; i++) {
            if (userList[i] == _user)
                return;
        }
        userList.push(_user);
    }

    function removeUserList(address _user) internal{
        if (stakingAmount[_user] != 0)
            return;
        for (uint256 i = 0; i < userList.length; i++) {
            if (userList[i] == _user) {
                userList[i] = userList[userList.length - 1];
                userList.pop();
                return;
            }
        }
    }

    function unstake(uint256[] memory tokenIds) public {
        uint256 pending = 0;
        uint256 fee = 0;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(!_isStaked) continue;
            if(IERC721(nftAddress).ownerOf(tokenIds[i]) != address(this)) continue;

            uint256 _reward = pendingReward(msg.sender, tokenIds[i]);
            pending = pending+ (_reward);
            
            removeFromUserInfo(tokenIds[i]);
            if(stakingAmount[msg.sender] > 0)
                stakingAmount[msg.sender] = stakingAmount[msg.sender] - 1;

            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenIds[i]);

            removeUserList(msg.sender);
            emit UnStake(msg.sender, 1);
        }

        if(pending > 0) {
            if (pending < users[msg.sender].stolenReward) {
                users[msg.sender].stolenReward = users[msg.sender].stolenReward - pending;
                pending = 0;
            } else {
                pending = pending - users[msg.sender].stolenReward;
                users[msg.sender].stolenReward = 0;
            }

            if (totalClaimed+ (pending) >= limitClaimValue) {
                pending = limitClaimValue - totalClaimed;
                // isFinished = true;
            }

            totalClaimed = totalClaimed+ (pending);

            fee = pending * _feePercent / _feeDividen;
            pending = pending - fee;

            IERC20(rtoken).transfer(msg.sender, pending);
            IERC20(rtoken).transfer(_feeAddress, fee);
            users[msg.sender].withdrawn = users[msg.sender].withdrawn+ (pending);

            if (totalClaimed >= limitClaimValue) {
                limitClaimValue = limitClaimValue+ (initialLimitClaimValue);
                dailyReward = dailyReward / 2;
                dailyMilkReward = dailyMilkReward / 2;
            }
        }
    }

    function getStakingItemInfo(address _user, uint256 _tokenId) public view returns(bool _isStaked, uint256 _checkPoint) {
        for(uint256 i = 0; i < users[_user].stakedInfo.length; i++) {
            if(users[_user].stakedInfo[i].tokenId == _tokenId) {
                _isStaked = true;
                _checkPoint = users[_user].stakedInfo[i].checkPoint;
                break;
            }
        }
    }

    function getUserTotalWithdrawn (address _user) public view returns(uint256){
        return users[_user].withdrawn;
    }
    function removeFromUserInfo(uint256 tokenId) private {        
        for (uint256 i = 0; i < users[msg.sender].stakedInfo.length; i++) {
            if (users[msg.sender].stakedInfo[i].tokenId == tokenId) {
                users[msg.sender].stakedInfo[i] = users[msg.sender].stakedInfo[users[msg.sender].stakedInfo.length - 1];
                users[msg.sender].stakedInfo.pop();
                break;
            }
        }        
    }

    function claim() public {
        uint256 reward = pendingTotalReward(msg.sender);
        users[msg.sender].stolenReward = 0;

        for (uint256 i = 0; i < users[msg.sender].stakedInfo.length; i++) {
            users[msg.sender].stakedInfo[i].checkPoint = block.timestamp;
        }
        if (totalClaimed+ (reward) >= limitClaimValue) {
                reward = limitClaimValue - totalClaimed;
                // isFinished = true;
        }

        totalClaimed = totalClaimed+ (reward);
        uint256 fee = reward * _feePercent / _feeDividen;
        reward = reward - fee;

        IERC20(rtoken).transfer(msg.sender, reward);
        IERC20(rtoken).transfer(_feeAddress, fee);

        users[msg.sender].withdrawn = users[msg.sender].withdrawn+ (reward);

        if (totalClaimed >= limitClaimValue) {
            limitClaimValue = limitClaimValue+ (initialLimitClaimValue);
            dailyReward = dailyReward / 2;
            dailyMilkReward = dailyMilkReward / 2;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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