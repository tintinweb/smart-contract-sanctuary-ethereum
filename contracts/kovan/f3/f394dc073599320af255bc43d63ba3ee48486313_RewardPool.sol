/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/Stake.sol

pragma solidity ^0.8.7;

struct Stake {
    uint256 scores; // scores of the stake
    uint256 lastGrantIntervalNumber; // interval number, when last granted reward
    uint256[] nft;
}

// File: contracts/IERC721.sol

pragma solidity ^0.8.7;

interface IERC721 {

    function balanceOf(address owner) external view returns (uint256 balance);
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
}
// File: contracts/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: contracts/RewardPoolBase.sol

pragma solidity ^0.8.7;

//import "hardhat/console.sol";





abstract contract RewardPoolBase is Ownable {
    mapping(address => Stake) internal staks; // token staks by account
    uint256 public staksScoresSum; // total staks scores
    uint256 public claimStaksScoresSum; // total staked scores, in use for claim reward pool
    uint256 public claimRewardPool; // reward pool to claim
    uint256 public claimRewardPoolStartCount; // reward pool to claim on start
    uint256 public nextIntervalTime; // time of new interval
    uint256 public intervalMinutes = 1; // interval length
    uint256 public intervalNumber; // number of current interval (if pool is not started the value is 0)
    uint256 public totalRewardClaimed; // total, that claimed by users
    bool public enabled; // if true, than pool is enabled

    function start() external onlyOwner {
        require(intervalNumber == 0, "reward pool alredy started");
        beforeStart();
        nextIntervalTime = block.timestamp + intervalMinutes * 1 minutes;
        intervalNumber = 1;
        claimRewardPoolStartCount = claimRewardPool;
        enabled = true;
    }

    function setIntervalTimer(uint256 newIntervalMinutes) external onlyOwner {
        intervalMinutes = newIntervalMinutes;
    }

    function setIsEnabled(bool newEnabled) external onlyOwner {
        enabled = newEnabled;
    }

    function nextIntervalLapsedTime() external view returns (uint256) {
        if (block.timestamp >= nextIntervalTime) return 0;
        return nextIntervalTime - block.timestamp;
    }

    function getRewardCount(address account) public view returns (uint256) {
        return _getRewardCount(staks[account]);
    }

    function _getRewardCount(Stake storage stake)
        internal
        view
        returns (uint256)
    {
        if (
            stake.scores == 0 || stake.lastGrantIntervalNumber >= intervalNumber
        ) return 0;
        return (stake.scores * claimRewardPoolStartCount) / claimStaksScoresSum;
    }

    function _grantReward(
        address account,
        Stake storage stake,
        uint256 reward
    ) private {
        if (reward > claimRewardPool) reward = claimRewardPool;
        if (reward == 0) return;
        unchecked {
            claimRewardPool -= reward;
            totalRewardClaimed += reward;
        }
        // grant reward
        transferRewardTo(account, reward);
        // use stake
        stake.lastGrantIntervalNumber = intervalNumber;
    }

    function claimReward() external {
        tryNextInterval();
        Stake storage stake = staks[msg.sender];
        uint256 reward = _getRewardCount(stake);
        require(reward > 0, "has no reward");
        _grantReward(msg.sender, stake, reward);
    }

    function removeStake() external {
        tryNextInterval();
        Stake storage stake = staks[msg.sender];
        _grantReward(msg.sender, stake, _getRewardCount(stake)); // try grant reward if change stack
        require(stake.scores > 0, "stake scores is 0");
        removeStake(msg.sender, stake);
        staksScoresSum -= stake.scores;        
        delete staks[msg.sender];
    }

    function tryNextInterval() public {
        // try to go into next  interval
        if (block.timestamp < nextIntervalTime) return;
        // save total staks
        claimStaksScoresSum = staksScoresSum;
        // update reward pools
        claimRewardPool = getRewardsTotal();
        claimRewardPoolStartCount = claimRewardPool;
        // set the next interval
        ++intervalNumber;
        nextIntervalTime = block.timestamp + intervalMinutes * 1 minutes;
    }

    function _updateScores(Stake storage stake, uint256 newScores) internal {
        require(intervalNumber > 0 && enabled, "reward pool not started");
        tryNextInterval();
        _grantReward(msg.sender, stake, _getRewardCount(stake));
        if (stake.scores == newScores) return;
        if (stake.scores < newScores) {
            uint256 delta = newScores - stake.scores;
            staksScoresSum += delta;
            stake.scores += delta;
        } else {
            uint256 delta = stake.scores - newScores;
            staksScoresSum -= delta;
            stake.scores -= delta;
        }
        stake.lastGrantIntervalNumber = intervalNumber;
    }

    function getStake(address account) external view returns (Stake memory) {
        return _getStake(account);
    }

    function _getStake(address account)
        internal
        view
        virtual
        returns (Stake memory)
    {
        return staks[account];
    }

    function beforeStart() internal virtual;

    function transferRewardTo(address account, uint256 count) internal virtual;

    function removeStake(address account, Stake memory stake) internal virtual;

    // current total rewards count (for claims and accumulative)
    function getRewardsTotal() public view virtual returns (uint256);
}

// File: contracts/RewardPool.sol

pragma solidity ^0.8.7;

//import "hardhat/console.sol";





// the reward pool that provides erc20 and nft staking and grants erc20 tokens
contract RewardPool is RewardPoolBase {
    IERC20 public erc20; // erc20 token
    IERC721 public nft; // erc721 token
    mapping(address => uint256[]) mftByAccounts;

    constructor(address erc20Address, address nftAddress) {
        erc20 = IERC20(erc20Address);
        nft = IERC721(nftAddress);
    }

    function setErc20Address(address newErc20Address) external onlyOwner {
        erc20 = IERC20(newErc20Address);
    }

    function setNftAddress(address newNftAddress) external onlyOwner {
        nft = IERC721(newNftAddress);
    }

    function beforeStart() internal view override {
        require(address(erc20) != address(0), "erc20 is zero");
        require(address(nft) != address(0), "nft is zero");
    }

    function getRewardsTotal() public view override returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function transferRewardTo(address account, uint256 count)
        internal
        override
    {
        erc20.transfer(account, count);
    }

    function removeStake(address account, Stake memory stake)
        internal
        override
    {
        uint256 len = stake.nft.length;
        for (uint256 i = 0; i < len; ++i)
            nft.safeTransferFrom(address(this), account, stake.nft[i]);
    }

    function addNftToStack(uint256 nftId) external {
        _addNftToStack(nftId);
    }

    function _addNftToStack(uint256 nftId) private {
        require(nftId != 0, "nft id can not be zero");
        Stake storage stake = staks[msg.sender];
        nft.transferFrom(msg.sender, address(this), nftId);
        stake.nft.push(nftId);
        _updateScores(stake, stake.scores + 1);
    }

    function addNftListToStack(uint256[] calldata nftIds) external {
        for (uint256 i = 0; i < nftIds.length; ++i) _addNftToStack(nftIds[i]);
    }

    function withdraw() external onlyOwner {
        erc20.transfer(_owner, erc20.balanceOf(address(this)));
    }
}