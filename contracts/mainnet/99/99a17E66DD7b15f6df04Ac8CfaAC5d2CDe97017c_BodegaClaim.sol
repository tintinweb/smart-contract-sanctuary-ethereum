/**
 *Submitted for verification at Etherscan.io on 2022-09-15
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
    function allocationClass0() external view returns (uint256);
    function allocationClass1() external view returns (uint256);
    function allocationClass2() external view returns (uint256);

    function totalClass0() external view returns (uint256);
    function totalClass1() external view returns (uint256);
    function totalClass2() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
    function getIDsByOwner(address owner) external view returns (uint256[] memory);
}


contract BodegaClaim is Ownable {

    // WETH
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Bodega NFT contract
    IBodega public constant bodega = IBodega(0x6C208c2785050b5A79aC1e7Bd317d81A2E477837);

    // Mapping from tokenId to reward token to excluded rewards
    mapping( uint256 => mapping ( address => uint256 )) private totalExcluded;

    struct RewardToken {
        uint totalRewards;
        uint dividendsPerNFTClass0;
        uint dividendsPerNFTClass1;
        uint dividendsPerNFTClass2;
    }

    // reward tracking
    mapping ( address => RewardToken ) public rewardToken;

    // constant break points
    uint256 public constant breakPoint0 = 111;
    uint256 public constant breakPoint1 = 1_222;

    function giveRewards(address token, uint256 amount) external {
        uint256 received = _transferIn(token, amount);
        _register(token, received);
    }

    function giveETH() external payable {
        _register(WETH, msg.value);
    }

    function claimRewardsForUser(address token) external {
        _batchClaimRewardsMemory(token, msg.sender, getIDsByOwner(msg.sender));
    }

    function claimRewards(address token, uint256[] calldata tokenIds) external {
        _batchClaimRewards(token, msg.sender, tokenIds);
    }

    function claimReward(address token, uint256 tokenId) external {
        _claimReward(token, tokenId);
    }

    function _register(address token, uint256 amount) internal {
        
        (uint256 c0, uint256 c1, uint256 c2) = divvyRewards(amount);
        uint tot0 = totalClass0();
        uint tot1 = totalClass1();
        uint tot2 = totalClass2();
        unchecked {
            rewardToken[token].totalRewards += amount;
            if (tot0 > 0) {
                rewardToken[token].dividendsPerNFTClass0 += c0 / tot0;
            }
            if (tot1 > 0) {
                rewardToken[token].dividendsPerNFTClass1 += c1 / tot1;
            }
            if (tot2 > 0) {
                rewardToken[token].dividendsPerNFTClass2 += c2 / tot2;
            }
        }
    }

    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        uint256 before = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 After = IERC20(token).balanceOf(address(this));
        require(After > before, "Zero Received");
        return After - before;
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
            totalExcluded[ID][token] = getCumulativeDividends(token, ID);
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
            totalExcluded[ID][token] = getCumulativeDividends(token, ID);
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

        // reset total rewards
        totalExcluded[tokenId][token] = getCumulativeDividends(token, tokenId);

        // transfer reward to user
        _send(token, owner, pending);
    }

    function _send(address token, address to, uint256 amount) internal {
        // reward token balance
        uint256 rBal = token == WETH ? address(this).balance : IERC20(token).balanceOf(address(this));
        if (amount > rBal) {
            amount = rBal;
        }

        // return if no rewards
        if (amount == 0) {
            return;
        }

        // require success
        if (token == WETH) {
            (bool s,) = payable(to).call{value: amount}("");
            require(s);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function divvyRewards(uint256 amount)
        public
        view
        returns (
            uint256 class0,
            uint256 class1,
            uint256 class2
        )
    {
        uint all0 = allocationClass0();
        uint all1 = allocationClass1();
        uint all2 = allocationClass2();
        uint total = all0 + all1 + all2;
        class0 = ( amount * all0 ) / total;
        class1 = ( amount * all1 ) / total;
        class2 = amount - (class0 + class1);
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
        uint256 accountTotalDividends = getCumulativeDividends(token, tokenId);
        uint256 accountTotalExcluded = totalExcluded[tokenId][token];

        if (accountTotalDividends <= accountTotalExcluded) {
            return 0;
        }

        return accountTotalDividends - accountTotalExcluded;
    }

    /**
        Cumulative Dividends For A Number Of Tokens
     */
    function getCumulativeDividends(address token, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (tokenId < breakPoint0) {
            return rewardToken[token].dividendsPerNFTClass0;
        } else if (tokenId < breakPoint1) {
            return rewardToken[token].dividendsPerNFTClass1;
        } else {
            return rewardToken[token].dividendsPerNFTClass2;
        }
    }

    function getIDsByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return bodega.getIDsByOwner(owner);
    }

    function allocationClass0() public view returns (uint256) {
        return bodega.allocationClass0();
    }
    function allocationClass1() public view returns (uint256) {
        return bodega.allocationClass1();
    }
    function allocationClass2() public view returns (uint256) {
        return bodega.allocationClass2();
    }
    function totalClass0() public view returns (uint256) {
        return bodega.totalClass0();
    }
    function totalClass1() public view returns (uint256) {
        return bodega.totalClass1();
    }
    function totalClass2() public view returns (uint256) {
        return bodega.totalClass2();
    }
}