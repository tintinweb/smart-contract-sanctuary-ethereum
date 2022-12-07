/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IERC20 {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

interface ISWTF {
    function hibernatingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool hibernating,
            uint256 current,
            uint256 total
        );

    function ownerOf(uint256 tokenId) external view returns (address);

    function toggleHibernating(uint256[] calldata tokenIds) external;
}

contract RewardPool is Ownable {
    ISWTF private SWTF = ISWTF(0x610515341EC8dDd0C1499dc3A96e9C2eEd873409);
    IERC20 public GOLD = IERC20(0xA2aD46Da4F05c54c1C8F10AC33232049DB63cf51);
    uint8 decimals = 9;
    uint256 public REWARD_NORMAL = 12500 * 10**decimals;
    uint256 public REWARD_CROWN = 25000 * 10**decimals;
    uint256 public REWARD_ETH = 50000 * 10**decimals;
    mapping(uint256 => bool) public isCrown;
    mapping(uint256 => bool) public isETH;
    mapping(uint256 => bool) public blacklisted;

    event RewardClaimed(
        uint256 indexed tokenId,
        address indexed to,
        uint256 indexed ammount
    );

    constructor() {}

    function calculateReward(uint256 tokenId) public view returns (uint256) {
        bool hibernating;
        uint256 current;
        (hibernating, current, ) = SWTF.hibernatingPeriod(tokenId);
        if (!hibernating) return 0;
        uint256 rewardRate = getRewardRate(tokenId);
        if (current < 30 days) return 0;
        if (current < 90 days) return (rewardRate * 30) / 365;
        if (current < 180 days) return (rewardRate * 90) / 365;
        if (current < 365 days) return (rewardRate * 180) / 365;
        return (rewardRate * current) / 365 days;
    }

    function calculateReward(uint256[] calldata tokenIds)
        public
        view
        returns (uint256 totalReward)
    {
        totalReward = 0;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (SWTF.ownerOf(tokenIds[i]) == msg.sender)
                totalReward += calculateReward(tokenIds[i]);
        }
    }

    function _claimReward(uint256 tokenId) internal notBlacklist(tokenId) {
        uint256 reward = calculateReward(tokenId);
        bool isOwner = SWTF.ownerOf(tokenId) == msg.sender;
        require(isOwner, "Reward: not owner of the tokenId");
        require(reward > 0, "Reward: not have claimable reward");
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        SWTF.toggleHibernating(ids);
        SWTF.toggleHibernating(ids);
        GOLD.transfer(msg.sender, reward);
        emit RewardClaimed(tokenId, msg.sender, reward);
    }

    function claimReward(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _claimReward(tokenIds[i]);
        }
    }

    function getRewardRate(uint256 tokenId) internal view returns (uint256) {
        if (isETH[tokenId]) return REWARD_ETH;
        if (isCrown[tokenId]) return REWARD_CROWN;
        return REWARD_NORMAL;
    }

    function withdraw(uint256 amount, address to) private onlyOwner {
        uint256 balance = GOLD.balanceOf(address(this));
        require(amount <= balance, "Reward: Insufficient balance");
        GOLD.transfer(to, amount);
    }

    function addBlacklist(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++)
            blacklisted[tokenIds[i]] = true;
    }

    function removeBlacklist(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++)
            blacklisted[tokenIds[i]] = false;
    }

    function addTrait(uint256[] calldata ids, bool crown) external onlyOwner {
        if (crown) {
            for (uint256 i = 0; i < ids.length; i++) {
                isCrown[ids[i]] = true;
            }
        } else {
            for (uint256 i = 0; i < ids.length; i++) {
                isETH[ids[i]] = true;
            }
        }
    }

    modifier notBlacklist(uint256 tokenId) {
        require(
            blacklisted[tokenId] == false,
            "Reward: TokenId is on the blacklist"
        );
        _;
    }
}