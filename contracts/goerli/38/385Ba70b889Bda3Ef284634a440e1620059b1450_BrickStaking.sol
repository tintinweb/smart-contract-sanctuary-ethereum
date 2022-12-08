// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IBrickToken.sol";
import "./IBrickNft.sol";
import "./IBrickManager.sol";

contract BrickStaking{

    struct stakeInfo{
        uint256 stakingTime;
        uint256 lastClaimTime;
        uint256 amount;
    }

    IBrickToken private brickToken;
    IBrickNft private brickNft;
    IBrickManager private brickManager;

    uint256 public constant REWARD_PERIOD = 1 minutes; //should be 1/2 year
    uint256 public constant UPGRADE_REWARD_PERIOD = 10 minutes; //should be 3 years
    uint256 public constant PIXEL_VALUE = 1e10; //10000

    bytes32 REGISTERED_ROLE = keccak256('REGISTERED');
    bytes32 DEFAULT_ADMIN_ROLE = 0x00;

    uint256[] REWARD_PERCENT;

    mapping(address => stakeInfo[]) stakings;
    mapping(address => uint256) stakedAmount;
    mapping(address => uint256) bricksToFinishPixel;
    
    //TODO change event names
    event staked(address staker, uint256 amount);
    event unstaked(address staker, uint256 amount);
    event rewardClaimed(address staker, uint256 amount);

    constructor(address brickManager_){
        REWARD_PERCENT.push(0);
        REWARD_PERCENT.push(5);
        REWARD_PERCENT.push(10);
        REWARD_PERCENT.push(15);

        brickManager = IBrickManager(brickManager_);
    }

    function getNewPixelsAmount(uint256 stakeValue, address staker) public view returns (uint256 amount){
        uint256 currentPixelsAmount = getPixelsAmount(staker);
        
        return (stakedAmount[staker] + stakeValue + PIXEL_VALUE / 2) / PIXEL_VALUE - currentPixelsAmount;
    }

    function getPixelsAmount(address staker) public view returns (uint256){
        return (stakedAmount[staker] + PIXEL_VALUE / 2) / PIXEL_VALUE;
    }

    function getStakedAmount(address staker) public view returns (uint256){
        return stakedAmount[staker];
    }

    function getBricksToFinishPixel(address staker) public view returns (uint256){
        return bricksToFinishPixel[staker];
    }

    function canUnstake(address staker, uint256 amount) public view returns (bool){
        if(stakedAmount[staker] < amount || amount == 0) 
            return false;
        uint256 bricksLeft = (stakedAmount[staker] - amount) % PIXEL_VALUE;
        if(bricksLeft == 0 || bricksLeft >= PIXEL_VALUE / 2)
            return true;
        
        return false;
    }

    function getRewardLevel(address staker, uint256 stakingTime) public view returns (uint256){
        uint8 nftType = brickManager.getUserType(staker);
        uint256 upgradePeriods = (block.timestamp - stakingTime) / UPGRADE_REWARD_PERIOD;
        uint256 rewardLevel = nftType + upgradePeriods > 3 ? 3 : nftType + upgradePeriods;

        return rewardLevel;
    }   

    function getRewardAmount(address staker) public view returns (uint256){
        uint256 reward = 0;

        for(uint256 i = 0; i < stakings[staker].length; i++){
            uint256 stakingPeriods = (block.timestamp - stakings[staker][i].lastClaimTime) / REWARD_PERIOD;

            uint8 nftType = brickManager.getUserType(staker);
            uint256 upgradePeriods = (block.timestamp - stakings[staker][i].stakingTime) / UPGRADE_REWARD_PERIOD;
            uint256 rewardLevel = nftType + upgradePeriods > 3 ? 3 : nftType + upgradePeriods;
            
            reward += ((stakings[staker][i].amount * REWARD_PERCENT[rewardLevel]) / 100) * stakingPeriods;
        }
        return reward;
    }

    function setBrick(address brickToken_, address brickNft_) external onlyAdmin{
        brickToken = IBrickToken(brickToken_);
        brickNft = IBrickNft(brickNft_);
    }

    function addStake(uint256 amount) public onlyRegistered{
        uint256 extraBricks = (stakedAmount[msg.sender] + amount) % PIXEL_VALUE;
        require(extraBricks >= PIXEL_VALUE / 2 || extraBricks == 0, "Less than 1/2 of pixel left");

        bricksToFinishPixel[msg.sender] = (PIXEL_VALUE + bricksToFinishPixel[msg.sender] - amount % PIXEL_VALUE) % PIXEL_VALUE;

        stakeInfo memory stake;
        stake.stakingTime = block.timestamp;
        stake.lastClaimTime = block.timestamp;
        stake.amount = amount; 

        brickToken.transferFrom(msg.sender, address(this), amount);
        stakings[msg.sender].push(stake);
        stakedAmount[msg.sender] += amount;

        emit staked(msg.sender, amount);
    }

    function removeStake(uint256 amount) public onlyRegistered{
        require(amount <= stakedAmount[msg.sender], "You can`t unstake more than you have");
        require(stakings[msg.sender].length > 0, "You have 0 active stakes");
        uint256 extraBricks = (stakedAmount[msg.sender] - amount) % PIXEL_VALUE;
        require(extraBricks >= PIXEL_VALUE / 2 || extraBricks == 0, "Less than 1/2 of pixel left");

        uint256 currentAmount = 0;
        for(uint256 i = stakings[msg.sender].length - 1; i >= 0; i--){
            if(currentAmount + stakings[msg.sender][i].amount < amount){
                currentAmount += stakings[msg.sender][i].amount;
                stakings[msg.sender].pop;
            }
            else{
                stakings[msg.sender][i].amount -= (amount - currentAmount);
                break;
            }
        }
        
        brickToken.transfer(msg.sender, amount);

        bricksToFinishPixel[msg.sender] = (bricksToFinishPixel[msg.sender] + amount % PIXEL_VALUE) % PIXEL_VALUE;
        stakedAmount[msg.sender] -= amount;

        emit unstaked(msg.sender, amount);
    }

    function claimRewards() public onlyRegistered{
        uint256 reward = 0;
        for(uint256 i = 0; i < stakings[msg.sender].length; i++){
            uint256 stakingPeriods = (block.timestamp - stakings[msg.sender][i].lastClaimTime) / REWARD_PERIOD;
            stakings[msg.sender][i].lastClaimTime = stakings[msg.sender][i].lastClaimTime + (REWARD_PERIOD * stakingPeriods);

            uint256 rewardLevel = getRewardLevel(msg.sender, stakings[msg.sender][i].stakingTime);
            reward += ((stakings[msg.sender][i].amount * REWARD_PERCENT[rewardLevel]) / 100) * stakingPeriods;
        }
        require(reward > 0, "Nothing to claim");
        brickToken.payStakingReward(msg.sender, reward);
        emit rewardClaimed(msg.sender, reward);
    }

    modifier onlyRegistered{
        require(brickManager.hasRole(REGISTERED_ROLE, msg.sender), "This account is not registered");
        _;
    }

    modifier onlyAdmin{
        require(brickManager.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "This account doesn't have admin rights");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBrickToken is IERC20, IERC20Metadata {
    
    function mint(address to, uint256 amount) external;

    function payStakingReward(address to, uint256 amount) external;

    function payLotteryReward(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBrickNft is IERC721 {

    function mint(address owner, string memory uri) external returns (uint256);

    function getUri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBrickManager{

    struct nftInfo{
        uint256 id;
        uint8 _type;
        uint256 stakedAmount;
        uint256 votingPower;
        string uri;
    }

    function getUserType(address user) external view returns (uint8);

    function getNftInfo(address user) external view returns (nftInfo memory);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function REGISTERED_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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