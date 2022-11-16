/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

interface IBodega {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getIDsByOwner(address owner) external view returns (uint256[] memory);
}

interface ITetherSucks {
    function transfer(address recipient, uint256 amount) external;
}

interface IChainlinkPriceFeed {
    function latestAnswer() external view returns (int256);
}


contract BodegaClaim is Ownable {

    // WETH
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // USDT
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Chainlink ETH Oracle
    IChainlinkPriceFeed public constant ethPriceFeed = IChainlinkPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    // Bodega NFT contract
    IBodega public immutable bodega;

    // Mapping from tokenId to last time claimed
    mapping( uint256 => uint256 ) public lastClaim;

    // Reward Token Structure
    struct RewardToken {
        bool isApproved;
        uint rewardsPerBlockTier0;
        uint rewardsPerBlockTier1;
        uint rewardsPerBlockTier2;
    }

    // reward tracking
    mapping ( address => RewardToken ) public rewardToken;

    // constant break points
    uint256 public constant breakPoint0 = 111;
    uint256 public constant breakPoint1 = 1_222;

    // Set Bodega Contract
    constructor(address bodega_) {
        bodega = IBodega(bodega_);
    }

    /**
        For ETH Rewards, use WETH Address above, and set the USD Value formatted to 10^8 decimal places
     */
    function setRewardTokenStats(
        address token, 
        uint rewardPerDayFirstTier,
        uint rewardPerDaySecondTier,
        uint rewardPerDayThirdTier
    ) external onlyOwner {
        rewardToken[token] = RewardToken({
            isApproved: true,
            rewardsPerBlockTier0: rewardPerDayFirstTier / 5760,
            rewardsPerBlockTier1: rewardPerDaySecondTier / 5760,
            rewardsPerBlockTier2: rewardPerDayThirdTier / 5760
        });
    }

    function removeRewardToken(address token) external onlyOwner {
        delete rewardToken[token];
    }

    function resetClaim(uint256[] calldata tokenIds, uint256 decrement) external onlyOwner {
        uint len = tokenIds.length;
        for (uint i = 0; i < len;) {
            lastClaim[tokenIds[i]] = block.number - decrement;
            unchecked { ++i; }
        }
    }

    function withdrawETH(uint amount) external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: amount}("");
        require(s);
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        if (token == USDT) {
            ITetherSucks(token).transfer(msg.sender, amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    receive() external payable {}

    function initRewards(uint256 tokenId) external {
        require(
            msg.sender == address(bodega),
            'Only Bodega'
        );
        lastClaim[tokenId] = block.number;
    }


    function claimRewardsForUser(address token) external {
        require(
            rewardToken[token].isApproved,
            'Only Approved Tokens'
        );
        _batchClaimRewardsMemory(token, msg.sender, getIDsByOwner(msg.sender));
    }

    function claimRewards(address token, uint256[] calldata tokenIds) external {
        require(
            rewardToken[token].isApproved,
            'Only Approved Tokens'
        );
        _batchClaimRewards(token, msg.sender, tokenIds);
    }

    function claimReward(address token, uint256 tokenId) external {
        require(
            rewardToken[token].isApproved,
            'Only Approved Tokens'
        );
        _claimReward(token, tokenId);
    }


    function _batchClaimRewards(address token, address user, uint256[] calldata tokenIds)
        internal
    {
        uint256 total;
        uint256 len = tokenIds.length;

        for (uint256 i = 0; i < len; ) {
            uint256 ID = tokenIds[i];
            require(bodega.ownerOf(ID) == user, "Not Owner Of TokenID");
            total += pendingRewardsForID(token, ID);
            lastClaim[ID] = block.number;
            unchecked {
                ++i;
            }
        }

        // send rewards to user
        _send(token, user, total);
    }

    function _batchClaimRewardsMemory(address token, address user, uint256[] memory tokenIds)
        internal
    {
        uint256 total;
        uint256 len = tokenIds.length;

        for (uint256 i = 0; i < len; ) {
            uint256 ID = tokenIds[i];
            require(bodega.ownerOf(ID) == user, "Not Owner Of TokenID");
            total += pendingRewardsForID(token, ID);
            lastClaim[ID] = block.number;
            unchecked {
                ++i;
            }
        }

        // send rewards to user
        _send(token, user, total);
    }

    /**
        Claims Reward For User
     */
    function _claimReward(address token, uint256 tokenId) internal {

        // owner of token id
        address owner = bodega.ownerOf(tokenId);
        require(
            owner != address(0),
            'Zero Owner'
        );

        // fetch pending rewards
        uint256 pending = pendingRewardsForID(token, tokenId);

        // reset last claim
        lastClaim[tokenId] = block.number;

        // transfer reward to user
        _send(token, owner, pending);
    }

    function _send(address token, address to, uint256 amount) internal {

        // is the reward token ETH?
        bool isWETH = token == WETH;

        // reward token balance
        uint256 rBal = isWETH ? address(this).balance : IERC20(token).balanceOf(address(this));

        // ensure overflow
        if (amount > rBal) {
            amount = rBal;
        }

        // return if no rewards
        if (amount == 0) {
            return;
        }

        // require success
        if (isWETH) {
            (bool s,) = payable(to).call{value: amount}("");
            require(s);
        } else {
            if (token == USDT) {
                ITetherSucks(token).transfer(to, amount);
            } else {
                IERC20(token).transfer(to, amount);
            }
        }
    }

    function timeSince(uint256 tokenId) public view returns (uint256) {
        if (lastClaim[tokenId] == 0) {
            return 0;
        }

        return lastClaim[tokenId] < block.number ? block.number - lastClaim[tokenId] : 0;
    }

    function valuePerBlock(address token, uint256 tokenId) public view returns (uint256) {
        if (tokenId < breakPoint0) {
            return rewardToken[token].rewardsPerBlockTier0;
        } else if (tokenId < breakPoint1) {
            return rewardToken[token].rewardsPerBlockTier1;
        } else {
            return rewardToken[token].rewardsPerBlockTier2;
        }
    }

    function priceOfETH() public view returns (uint256) {
        int256 answer = ethPriceFeed.latestAnswer();
        if (answer < 1000) {
            return 0;
        } else {
            return uint256(answer) / 10**8;
        }
    }

    /**
        Pending Rewards For `tokenId`
     */
    function pendingRewardsForUser(address token, address user)
        external
        view
        returns (uint256 total)
    {
        uint256[] memory tokenIds = getIDsByOwner(user);

        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len; ) {
            total += pendingRewardsForID(token, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
        Pending Rewards For `tokenId`
     */
    function pendingRewards(address token, uint256[] calldata tokenIds)
        public
        view
        returns (uint256 total)
    {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len; ) {
            total += pendingRewardsForID(token, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
        Pending Rewards For `tokenId`
     */
    function pendingRewardsForID(address token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint timePassed = timeSince(tokenId);
        uint value = valuePerBlock(token, tokenId);

        return token == WETH ? (timePassed * value) / priceOfETH() : timePassed * value;
    }

    function getIDsByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return bodega.getIDsByOwner(owner);
    }
}