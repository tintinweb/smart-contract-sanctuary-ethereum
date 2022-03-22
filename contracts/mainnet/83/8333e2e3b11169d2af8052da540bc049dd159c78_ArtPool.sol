// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './libraries/TimeConverter.sol';
import './logic/StakingPoolLogic.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ArtPool {

    using StakingPoolLogic for PoolData;

    constructor(address rewardAsset_) public {
        rewardAsset = IERC20(rewardAsset_);
        _admin = msg.sender;
    }

    address public _admin;

    struct PoolData {
        string poolName;
        uint256 rewardPerSecond;
        uint256 rewardIndex;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalPrincipal;
        uint256 lastUpdateTimestamp;
        uint256 totalNFT;
        uint256 voteMax;
        bool isFullLockup;
        uint256 lockupTimestamp;
        uint256 totalVoted;
        uint256 voteStartTimestamp;
        uint256 voteEndTimestamp;
        bool hasTaxCollected;
        mapping(address => WhitelistNFT) whitelistNFT;
        mapping(address => uint256) userIndex;
        mapping(address => uint256) userReward;
        mapping(address => uint256) userPrincipal;
        mapping(address => uint256) userVoted;
        mapping(address => UserNFT) userNFT;
        NFT[] votedNFT;
    }

    struct UserNFT {
        mapping(address => uint256[]) stakedTokens;
        // mapping(address => mapping(uint256 => uint256)) indexOfToken;
        mapping(address => mapping(uint256 => uint256)) startStakeTimestamp;
        uint256 amountStaked;
    }

    struct WhitelistNFT {
        bool isWhitelisted;
        bool isAllWhitelisted;
        uint256 multiplier;
        mapping(uint256 => bool) tokenIsWhitelisted;
        mapping(uint256 => VoteInfo) voteInfo;
    }

    struct VoteInfo {
        address[] voters;
        mapping(address => uint256) votingCount;
        uint256 voted;
    }

    struct NFT {
        address nftAddress;
        uint256 tokenId;
    }

    mapping(uint8 => PoolData) internal _rounds;

    mapping(address => mapping(uint256 => address)) public tokenOwners;

    uint8 public lastRound;

    IERC20 public rewardAsset;

    event InitRound(
        uint256 rewardPerSecond,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint8 roundNumber
    );

    event Stake(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint8 round
    );

    event Unstake(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint8 round
    );

    event Claim(
        address indexed user,
        uint256 reward,
        uint8 round
    );

    event Vote(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint8 round
    );

    function setVoteTime(uint8 round, uint256 startTimestamp, uint256 endTimestamp) external onlyAdmin {
        PoolData storage poolData = _rounds[round];

        poolData.voteStartTimestamp = startTimestamp;
        poolData.voteEndTimestamp = endTimestamp;
    }

    function initNewRound(
        string calldata poolName,
        bool isFullLockup,
        uint256 lockupTimestamp,
        uint256 rewardPerSecond,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 duration,
        uint256 voteMax
    ) external onlyAdmin {
        uint256 roundstartTimestamp = TimeConverter.toTimestamp(year, month, day, hour);

        uint8 newRound = lastRound + 1;
        (uint256 startTimestamp, uint256 endTimestamp) = _rounds[newRound].initRound(
            poolName,
            isFullLockup,
            lockupTimestamp,
            rewardPerSecond,
            roundstartTimestamp,
            duration,
            voteMax
        );

        lastRound = newRound;

        emit InitRound(
            rewardPerSecond,
            startTimestamp,
            endTimestamp,
            newRound
        );
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert("OnlyAdmin");
        _;
    }

    function getVoteData(uint8 round, address nftAddress, uint256 tokenId)
    external
    view
    returns(
        uint256 totalVoters,
        uint256 totalVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        return(
        voteInfo.voters.length,
        voteInfo.voted
        );
    }

    function getUserVoteData(uint8 round, address nftAddress, uint256 tokenId, address user)
    external
    view
    returns(
        uint256 totalVoted,
        uint256 totalVoter,
        uint256 userVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        return (
        voteInfo.voters.length,
        voteInfo.voted,
        voteInfo.votingCount[user]
        );
    }

    function getPoolData(uint8 round)
    external
    view
    returns (
        string memory poolName,
        bool isFullLockup,
        uint256 lockupTimestamp,
        uint256 rewardPerSecond,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 totalNFT,
        uint256 voteMax,
        uint256 voteStartTimestamp,
        uint256 voteEndTimestamp
    )
    {
        PoolData storage poolData = _rounds[round];

        return (
        poolData.poolName,
        poolData.isFullLockup,
        poolData.lockupTimestamp,
        poolData.rewardPerSecond,
        poolData.startTimestamp,
        poolData.endTimestamp,
        poolData.totalNFT,
        poolData.voteMax,
        poolData.voteStartTimestamp,
        poolData.voteEndTimestamp
        );
    }

    function getPoolDataETC(uint8 round)
    external
    view
    returns(
        uint256 totalVoted,
        uint256 totalPrincipal,
        bool hasTaxCollected,
        uint256 votedNFTs
    )
    {
        PoolData storage poolData = _rounds[round];

        return (
        poolData.totalVoted,
        poolData.totalPrincipal,
        poolData.hasTaxCollected,
        poolData.votedNFT.length
        );
    }

    function getUserData(uint8 round, address user)
    external
    view
    returns (
        uint256 userIndex,
        uint256 userReward,
        uint256 userPrincipal,
        uint256 amountStaked,
        uint256 amountVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        UserNFT storage userNFT = poolData.userNFT[user];

        return (
        poolData.userIndex[user],
        poolData.userReward[user],
        poolData.userPrincipal[user],
        userNFT.amountStaked,
        poolData.userVoted[user]
        );
    }

    function getUserReward(address user, uint8 round) external view returns (uint256) {
        PoolData storage poolData = _rounds[round];
        return poolData.getUserReward(user);
    }

    function getUserDataNFT(uint8 round, address user, address nftAddress)
    external
    view
    returns (
        uint256[] memory tokenId
    )
    {
        PoolData storage poolData = _rounds[round];
        UserNFT storage userNFT = poolData.userNFT[user];

        return (userNFT.stakedTokens[nftAddress]);
    }

    function getWhitelistNFTData(uint8 round, address nftAddress)
    external
    view
    returns (
        bool isWhitelisted,
        bool isAllWhitelisted,
        uint256 multiplier
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        return (
        whitelistNFT.isWhitelisted,
        whitelistNFT.isAllWhitelisted,
        whitelistNFT.multiplier
        );
    }

    function checkWhiteListed(uint8 round, address nftAddress, uint256 tokenId)
    external
    view
    returns(
        bool isWhitelisted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(whitelistNFT.isWhitelisted){
            if(whitelistNFT.isAllWhitelisted) {
                return true;
            }else {
                return whitelistNFT.tokenIsWhitelisted[tokenId];
            }
        }else {
            return false;
        }
    }

    function addWhitelist(uint8 round, address nftAddress, bool isAllWhitelisted, uint256[] calldata whitelistedToken, uint256 multiplier) external onlyAdmin {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(poolData.whitelistNFT[nftAddress].isWhitelisted) revert("Already whitelisted");

        whitelistNFT.isWhitelisted = true;
        whitelistNFT.isAllWhitelisted = isAllWhitelisted;
        whitelistNFT.multiplier = multiplier;
        for(uint256 i = 0; i < whitelistedToken.length; i ++ ){
            whitelistNFT.tokenIsWhitelisted[whitelistedToken[i]] = true;
        }
    }

    function claim(uint8 round) external {
        _claim(msg.sender, round);
    }

    function stake(uint8 round, address nftAddress, uint256 tokenId) external {
        _stake(msg.sender, round, nftAddress, tokenId);
    }

    function batchStake(uint8 round, address nftAddress, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _stake(msg.sender, round, nftAddress, tokenIds[i]);
        }
    }

    function unstake(uint8 round, address nftAddress, uint256 tokenId) external {
        _unstake(msg.sender, round, nftAddress, tokenId);
    }

    function batchUnstake(uint8 round, address nftAddress, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _unstake(msg.sender, round, nftAddress, tokenIds[i]);
        }
    }

    function _stake(address userAddress, uint8 round, address nftAddress, uint256 tokenId) internal {
        PoolData storage poolData = _rounds[round];
        UserNFT storage user = poolData.userNFT[userAddress];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if (round == 0) revert("StakingNotInitiated");

        if (poolData.endTimestamp < block.timestamp || poolData.startTimestamp > block.timestamp)
            revert("NotInRound");

        if(!whitelistNFT.isWhitelisted)
            revert("NotWhitelistedNFT");

        if(!whitelistNFT.isAllWhitelisted){
            if(!whitelistNFT.tokenIsWhitelisted[tokenId])
                revert("NotWhiteListedToken");
        }

        uint256 amount = whitelistNFT.multiplier > 0 ? whitelistNFT.multiplier : 1;

        poolData.updateStakingPool(round, userAddress);

        // nft 전송
        IERC721(nftAddress).transferFrom(userAddress, address(this), tokenId);

        poolData.userPrincipal[userAddress] = add(poolData.userPrincipal[userAddress], amount);
        poolData.totalPrincipal = add(poolData.totalPrincipal, amount);
        poolData.totalNFT = add(poolData.totalNFT, 1);


        user.stakedTokens[nftAddress].push(tokenId);
        // user.indexOfToken[nftAddress][tokenId] = user.stakedTokens[nftAddress].length;
        user.amountStaked += 1;


        user.startStakeTimestamp[nftAddress][tokenId] = block.timestamp;
        tokenOwners[nftAddress][tokenId] = msg.sender;

        emit Stake(
            msg.sender,
            nftAddress,
            tokenId,
            round
        );
    }

    function _unstake(address userAddress, uint8 round, address nftAddress, uint256 tokenId) internal {
        require(tokenOwners[nftAddress][tokenId] == userAddress, "NotOwnerOfThisToken");

        PoolData storage poolData = _rounds[round];
        UserNFT storage user = poolData.userNFT[userAddress];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(poolData.isFullLockup){
            if(poolData.endTimestamp > block.timestamp) {
                revert ("LockupNotFinished");
            }
        }

        if(poolData.lockupTimestamp > 0 && block.timestamp < poolData.endTimestamp) {
            if(block.timestamp - user.startStakeTimestamp[nftAddress][tokenId] < poolData.lockupTimestamp){
                revert ("LockupNotFinished");
            }
        }

        poolData.updateStakingPool(round, msg.sender);

        for (uint256 i; i<user.stakedTokens[nftAddress].length; i++) {
            if (user.stakedTokens[nftAddress][i] == tokenId) {
                user.stakedTokens[nftAddress][i] = user.stakedTokens[nftAddress][user.stakedTokens[nftAddress].length - 1];
                user.stakedTokens[nftAddress].pop();
                break;
            }
        }

        delete tokenOwners[nftAddress][tokenId];

        user.amountStaked -= 1;
        poolData.totalNFT = sub(poolData.totalNFT, 1);

        uint256 amount = whitelistNFT.multiplier > 0 ? whitelistNFT.multiplier : 1;

        poolData.userPrincipal[userAddress] = sub(poolData.userPrincipal[userAddress], amount);
        poolData.totalPrincipal = sub(poolData.totalPrincipal, amount);

        IERC721(nftAddress).transferFrom(
            address(this),
            userAddress,
            tokenId
        );

        emit Stake(
            msg.sender,
            nftAddress,
            tokenId,
            round
        );
    }

    function _claim(address user, uint8 round) internal {
        PoolData storage poolData = _rounds[round];

        uint256 reward = poolData.getUserReward(user);

        if (reward == 0) revert("ZeroReward");

        poolData.userReward[user] = 0;
        poolData.userIndex[user] = poolData.getRewardIndex();

        rewardAsset.transfer(user, reward);

        emit Claim(user, reward, round);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function vote(uint8 round, address nftAddress, uint256 tokenId, uint256 amount) external {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        if(tokenOwners[nftAddress][tokenId] == address(0)) revert("NotStakedNFT");

        if (poolData.voteEndTimestamp < block.timestamp || poolData.voteStartTimestamp > block.timestamp)
            revert("NotInVoteTime");

        if(amount > poolData.voteMax) revert("GreaterThanMaximum");

        uint userTotalVotingCount = poolData.userVoted[msg.sender];

        uint256 userVotingCount = voteInfo.votingCount[msg.sender];

        if(add(amount, userTotalVotingCount) > poolData.voteMax) revert("ExceedsMaximum");

        if(userVotingCount > 0) {
            // if(add(amount, userVotingCount) > poolData.voteMax) revert("ExceedsMaximum");
        }else {
            voteInfo.voters.push(msg.sender);
        }

        if(voteInfo.voted <= 0) {
            poolData.votedNFT.push(NFT({
            nftAddress: nftAddress,
            tokenId: tokenId
            }));
        }

        voteInfo.votingCount[msg.sender] = add(userVotingCount, amount);
        voteInfo.voted = add(voteInfo.voted, amount);
        poolData.totalVoted = add(poolData.totalVoted, amount);
        poolData.userVoted[msg.sender] = add(userTotalVotingCount, amount);

        rewardAsset.transferFrom(msg.sender, address(this), amount);

        emit Vote(
            msg.sender,
            nftAddress,
            tokenId,
            amount,
            round
        );
    }

    function forcedTransferFrom(address to, address nftAddress, uint256 tokenId) external onlyAdmin {
        IERC721(nftAddress).transferFrom(address(this), to, tokenId);
    }

    function withdraw() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken() external onlyAdmin {
        uint256 balance = rewardAsset.balanceOf(address(this));
        rewardAsset.transfer(msg.sender, balance);
    }

    function finishVote(uint8 round, address taxCollector, uint256 taxRate) external onlyAdmin {
        PoolData storage poolData = _rounds[round];

        if(poolData.hasTaxCollected) revert("AlreadyCollectedTax");
        if(taxRate > 100 ) revert("RateCannotOver100");
        if(poolData.endTimestamp > block.timestamp) revert("NotFinishedRound");

        uint256 totalVoted = poolData.totalVoted;
        uint256 tax = totalVoted * taxRate / 100;
        uint256 totalPrize = totalVoted - tax;

        uint256 winningVoteCount = 0;
        uint256 winningIndex = 0;

        for (uint256 i = 0; i < poolData.votedNFT.length; i++) {
            address nftAddress = poolData.votedNFT[i].nftAddress;
            uint256 tokenId = poolData.votedNFT[i].tokenId;

            WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
            VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

            if (voteInfo.voted > winningVoteCount) {
                winningVoteCount = voteInfo.voted;
                winningIndex = i;

                if(voteInfo.voted * 2 >= totalVoted){
                    break;
                }
            }
        }

        address winnerNFT = poolData.votedNFT[winningIndex].nftAddress;
        uint256 winnerTokenId = poolData.votedNFT[winningIndex].tokenId;

        WhitelistNFT storage winnerNFTInfo = poolData.whitelistNFT[winnerNFT];
        VoteInfo storage winnerVoteInfo = winnerNFTInfo.voteInfo[winnerTokenId];

        for (uint256 v = 0 ; v < winnerVoteInfo.voters.length; v ++){
            address voter = winnerVoteInfo.voters[v];
            uint256 userVotingCount = winnerVoteInfo.votingCount[voter];

            uint256 prize = ((userVotingCount * 10000) / winnerVoteInfo.voted) * totalPrize / 10000;
            rewardAsset.transfer(voter, prize);
        }

        rewardAsset.transfer(taxCollector, tax);

        poolData.hasTaxCollected = true;
    }

    function getWinners(uint8 round)
    external
    view
    returns(
        uint256 votedNFTs,
        uint256 voted,
        uint256 winningVoteCount,
        address winnerNFT,
        uint256 winnerTokenId,
        address[] memory winners
    )
    {
        PoolData storage poolData = _rounds[round];

        uint256 totalVoted = poolData.totalVoted;

        winningVoteCount = 0;
        uint256 winningIndex = 0;


        votedNFTs = poolData.votedNFT.length;

        for (uint256 i = 0; i < poolData.votedNFT.length; i++) {
            address nftAddress = poolData.votedNFT[i].nftAddress;
            uint256 tokenId = poolData.votedNFT[i].tokenId;

            VoteInfo storage voteInfo = poolData.whitelistNFT[nftAddress].voteInfo[tokenId];

            voted = voteInfo.voted;

            if (voteInfo.voted > winningVoteCount) {
                winningVoteCount = voteInfo.voted;
                winningIndex = i;

                if(voteInfo.voted * 2 >= totalVoted){
                    break;
                }
            }
        }


        winnerNFT = poolData.votedNFT[winningIndex].nftAddress;
        winnerTokenId = poolData.votedNFT[winningIndex].tokenId;

        WhitelistNFT storage winnerNFTInfo = poolData.whitelistNFT[winnerNFT];
        VoteInfo storage winnerVoteInfo = winnerNFTInfo.voteInfo[winnerTokenId];

        return (
            votedNFTs,
            voted,
            winningVoteCount,
            winnerNFT,
            winnerTokenId,
            winnerVoteInfo.voters
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8;
import '../ArtPool.sol';
import '../libraries/TimeConverter.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library StakingPoolLogic {
  using StakingPoolLogic for ArtPool.PoolData;

  event UpdateStakingPool(
    address indexed user,
    uint256 newRewardIndex,
    uint256 totalPrincipal,
    uint8 currentRound
  );

  function getRewardIndex(ArtPool.PoolData storage poolData) internal view returns (uint256) {
    uint256 currentTimestamp = block.timestamp < poolData.endTimestamp
      ? block.timestamp
      : poolData.endTimestamp;
    uint256 timeDiff = currentTimestamp - poolData.lastUpdateTimestamp;
    uint256 totalPrincipal = poolData.totalPrincipal;

    if (timeDiff == 0) {
      return poolData.rewardIndex;
    }

    if (totalPrincipal == 0) {
      return poolData.rewardIndex;
    }

    uint256 rewardIndexDiff = (timeDiff * poolData.rewardPerSecond * 1e9) / totalPrincipal;

    return poolData.rewardIndex + rewardIndexDiff;
  }

  function getUserReward(ArtPool.PoolData storage poolData, address user)
    internal
    view
    returns (uint256)
  {
    if (poolData.userIndex[user] == 0) {
      return 0;
    }
    uint256 indexDiff = getRewardIndex(poolData) - poolData.userIndex[user];

    uint256 balance = poolData.userPrincipal[user];

    uint256 result = poolData.userReward[user] + (balance * indexDiff) / 1e9;

    return result;
  }

  function updateStakingPool(
    ArtPool.PoolData storage poolData,
    uint8 currentRound,
    address user
  ) internal {
    poolData.userReward[user] = getUserReward(poolData, user);
    poolData.rewardIndex = poolData.userIndex[user] = getRewardIndex(poolData);
    poolData.lastUpdateTimestamp = block.timestamp < poolData.endTimestamp
      ? block.timestamp
      : poolData.endTimestamp;
    emit UpdateStakingPool(msg.sender, poolData.rewardIndex, poolData.totalPrincipal, currentRound);
  }

  function initRound(
    ArtPool.PoolData storage poolData,
    string memory poolName,
    bool isFullLockup,
    uint256 lockupTimestamp,
    uint256 rewardPerSecond,
    uint256 roundStartTimestamp,
    uint8 duration,
    uint256 voteMax
  ) internal returns (uint256, uint256) {
    poolData.poolName = poolName;
    poolData.isFullLockup = isFullLockup;
    poolData.lockupTimestamp = lockupTimestamp;
    poolData.rewardPerSecond = rewardPerSecond;
    poolData.startTimestamp = roundStartTimestamp;
    poolData.endTimestamp = roundStartTimestamp + (duration * 1 days);
    poolData.lastUpdateTimestamp = roundStartTimestamp;
    poolData.rewardIndex = 1e18;
    poolData.whitelistNFT;
    poolData.voteMax = voteMax;

    return (poolData.startTimestamp, poolData.endTimestamp);
  }

  function resetUserData(ArtPool.PoolData storage poolData, address user) internal {
    poolData.userReward[user] = 0;
    poolData.userIndex[user] = 0;
    poolData.userPrincipal[user] = 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/**
 * @title Ethereum timestamp conversion library
 * @author ethereum-datatime
 */
library TimeConverter {
  struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  uint256 constant DAY_IN_SECONDS = 86400;
  uint256 constant YEAR_IN_SECONDS = 31536000;
  uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint256 constant HOUR_IN_SECONDS = 3600;
  uint256 constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint256 year) internal pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (isLeapYear(year)) {
      return 29;
    } else {
      return 28;
    }
  }

  function parseTimestamp(uint256 timestamp) internal pure returns (DateTime memory dateTime) {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;

    // Year
    dateTime.year = getYear(timestamp);
    buf = leapYearsBefore(dateTime.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dateTime.year - ORIGIN_YEAR - buf);

    // Month
    uint256 secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dateTime.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dateTime.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dateTime.month, dateTime.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dateTime.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dateTime.hour = getHour(timestamp);
    // Minute
    dateTime.minute = getMinute(timestamp);
    // Second
    dateTime.second = getSecond(timestamp);
    // Day of week.
    dateTime.weekday = getWeekday(timestamp);
  }

  function getYear(uint256 timestamp) internal pure returns (uint16) {
    uint256 secondsAccountedFor = 0;
    uint16 year;
    uint256 numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) internal pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, minute, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) internal pure returns (uint256 timestamp) {
    uint16 i;

    // Year
    for (i = ORIGIN_YEAR; i < year; i++) {
      if (isLeapYear(i)) {
        timestamp += LEAP_YEAR_IN_SECONDS;
      } else {
        timestamp += YEAR_IN_SECONDS;
      }
    }

    // Month
    uint8[12] memory monthDayCounts;
    monthDayCounts[0] = 31;
    if (isLeapYear(year)) {
      monthDayCounts[1] = 29;
    } else {
      monthDayCounts[1] = 28;
    }
    monthDayCounts[2] = 31;
    monthDayCounts[3] = 30;
    monthDayCounts[4] = 31;
    monthDayCounts[5] = 30;
    monthDayCounts[6] = 31;
    monthDayCounts[7] = 31;
    monthDayCounts[8] = 30;
    monthDayCounts[9] = 31;
    monthDayCounts[10] = 30;
    monthDayCounts[11] = 31;

    for (i = 1; i < month; i++) {
      timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
    }

    // Day
    timestamp += DAY_IN_SECONDS * (day - 1);
    // Hour
    timestamp += HOUR_IN_SECONDS * (hour);
    // Minute
    timestamp += MINUTE_IN_SECONDS * (minute);
    // Second
    timestamp += second;

    return timestamp;
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