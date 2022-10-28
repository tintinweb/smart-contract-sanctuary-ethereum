// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IFactory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IFeed{
    function latestAnswer() external view returns (int256);
}

contract NFTStaking is Ownable{

    uint8[1001] public rarity;
    uint256[4] public rewardForRarity; // 100000000 = $1

    struct UserInfo {
        uint256 rewardPerMonth;
        mapping(uint256=>bool) staked;
        uint256 calculatedReward;
        uint256 withdrawnReward;
        uint8 depositedCount;
        uint256 lastUpdated;
    }

    mapping(address=>UserInfo) public userInfos;

    address public WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    IFactory public factory = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IERC20 public rewardToken;
    IERC721 public yonkoNFT;
    IFeed public feed;
    uint256 public minTokenUSD;

    constructor (
        IERC721 _yonkoNFT,
        uint8[1001] memory _rarity,
        uint256[4] memory _rewardForRarity,
        IERC20 _rewardToken,
        IFeed _feed,
        uint256 _minTokenUSD)
    {
        yonkoNFT = _yonkoNFT;
        rarity = _rarity;
        rewardForRarity = _rewardForRarity;
        rewardToken = _rewardToken;
        feed = _feed;
        minTokenUSD = _minTokenUSD;
    }

    function updateConfig(
        IERC721 _yonkoNFT,
        uint8[1001] memory _rarity,
        uint256[4] memory _rewardForRarity,
        IERC20 _rewardToken,
        IFeed _feed,
        uint256 _minTokenUSD
    ) external onlyOwner{
        yonkoNFT = _yonkoNFT;
        rarity = _rarity;
        rewardForRarity = _rewardForRarity;
        rewardToken = _rewardToken;
        feed = _feed;
        minTokenUSD = _minTokenUSD;
    }

    function updateUserInfo(address user) internal {
        UserInfo storage info = userInfos[user];
        info.calculatedReward += ((block.timestamp-info.lastUpdated)*info.rewardPerMonth)/(30 days);
        info.lastUpdated = block.timestamp;
    }

    function deposit(uint256 tokenId) external {
        require(msg.sender == yonkoNFT.ownerOf(tokenId), "You are not the owner of the token.");
        uint256 minTokenAmount = getTokenAmount(minTokenUSD);
        require(rewardToken.balanceOf(msg.sender) >= minTokenAmount, "Not enough token balance.");
        yonkoNFT.safeTransferFrom(msg.sender, address(this), tokenId);
        UserInfo storage info = userInfos[msg.sender];
        if(info.depositedCount > 0)
            updateUserInfo(msg.sender);
        info.depositedCount++;
        info.staked[tokenId] = true;
        uint8 tokenRarity = rarity[tokenId-1];
        uint256 reward = rewardForRarity[tokenRarity-1];
        info.rewardPerMonth += reward;
    }

    function withdraw(uint256 tokenId) external {
        UserInfo storage info = userInfos[msg.sender];
        require(info.staked[tokenId], "You are not the staker of the token.");
        yonkoNFT.safeTransferFrom(address(this), msg.sender, tokenId);
        updateUserInfo(msg.sender);
        info.depositedCount--;
        info.staked[tokenId] = false;
        uint8 tokenRarity = rarity[tokenId-1];
        uint256 reward = rewardForRarity[tokenRarity-1];
        info.rewardPerMonth -= reward;
    }

    function pendingReward(address user) external view returns(uint256){
        UserInfo storage info = userInfos[user];
        return (((block.timestamp-info.lastUpdated)*info.rewardPerMonth)/(30 days)) + info.calculatedReward;
    }

    function isStaked(address user, uint256 tokenID) external view returns(bool){
        return userInfos[user].staked[tokenID];
    }

    function claim() external{
        UserInfo storage info = userInfos[msg.sender];
        updateUserInfo(msg.sender);
        uint256 rewardAmount = info.calculatedReward - info.withdrawnReward;
        rewardAmount = getTokenAmount(rewardAmount);
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if(rewardTokenBalance < rewardAmount)
            rewardAmount = rewardTokenBalance;
        info.withdrawnReward = info.calculatedReward;
        rewardToken.transfer(msg.sender, rewardAmount);
    }

    function getTokenAmount(uint256 usdValue) public view returns(uint256) {
        //get ETH price in usd
        uint256 ETHPrice = uint256(feed.latestAnswer());
        //get ETH amount for usdValue
        uint256 ETHAmount = 1e18*usdValue / ETHPrice;
        //get token price in ETHValue
        IPair pair = IPair(factory.getPair(address(rewardToken), WETH));
        (uint256 amount0, uint256 amount1,) = pair.getReserves();
        address token0 = pair.token0();
        uint256 tokenAmount = token0 == WETH ? (ETHAmount*amount1/amount0) : (ETHAmount*amount0/amount1);

        return tokenAmount;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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