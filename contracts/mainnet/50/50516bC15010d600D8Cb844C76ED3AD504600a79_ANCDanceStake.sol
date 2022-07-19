// SPDX-License-Identifier: MIT
/***
 *                                                                 .';:c:,.
 *                   ;0NNNNNNX.  lNNNNNNK;       .XNNNNN.     .:d0XWWWWWWWWXOo'
 *                 lXWWWWWWWWO   XWWWWWWWWO.     :WWWWWK    ;0WWWWWWWWWWWWWWWWWK,
 *              .dNWWWWWWWWWWc  ,WWWWWWWWWWNo    kWWWWWo  .0WWWWWNkc,...;oXWWXxc.
 *            ,kWWWWWWXWWWWWW.  dWWWWWXNWWWWWX; .NWWWWW.  KWWWWW0.         ;.
 *          :KWWWWWNd.lWWWWWO   XWWWWW:.xWWWWWWOdWWWWW0  cWWWWWW.
 *        lXWWWWWXl.  0WWWWW:  ,WWWWWN   '0WWWWWWWWWWWl  oWWWWWW;         :,
 *     .dNWWWWW0;    'WWWWWN.  xWWWWWx     :XWWWWWWWWW.  .NWWWWWWkc,'';ckNWWNOc.
 *   'kWWWWWWx'      oWWWWWk   NWWWWW,       oWWWWWWW0    '0WWWWWWWWWWWWWWWWWO;
 * .d000000o.        k00000;  ,00000k         .x00000:      .lkKNWWWWWWNKko;.
 *                                                               .,;;'.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ANCStake.sol";
import "./IERC20F.sol";

contract ANCDanceStake is ANCStake{
    struct StakedDance {
        uint128 stakingStartWeek;
        uint32 coins;
        uint32 stakingDuration;
        uint32 paidDuration;
    }

    uint96 public immutable TOKENS_PER_COIN = 1e18; // 1 full coin = 10^18

    IERC20F private _dance;

    mapping(address => StakedDance[]) private _stakes;

    constructor(uint256 percentPerWeek) ANCStake(percentPerWeek){ }

    /* External Functions */

    function stake(uint32 coins, uint16 stakingDuration) external stakingGate(stakingDuration){
        require(coins > 0, "Need to stake at least 1 DANCE");
        uint256 amount = uint256(coins) * TOKENS_PER_COIN;
        uint256 allowance = _dance.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint256 currentWeek = getCurrentWeek();
        _dance.transferFromNoFee(msg.sender, address(this), amount);
        _stakes[msg.sender].push(StakedDance(uint128(currentWeek), coins, stakingDuration, 0));
        addSharesToWeeks(currentWeek, stakingDuration, getShares(coins, stakingDuration));
    }

    function unstake(uint256 id) external {
        require(_stakes[msg.sender].length > id, "Invalid ID");
        uint256 refund = _stakes[msg.sender][id].coins * TOKENS_PER_COIN;
        uint256 payout = _unstakeDance(id);
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
        _dance.transferNoFee(msg.sender, refund);
    }

    function unstakeAll() external {
        require(_stakes[msg.sender].length > 0, "No Dance Tokens staked");
        uint256 currentWeek = getCurrentWeek();
        uint256 payout = 0;
        uint256 refund = 0;

        // While required since array length changes in _unstakeDance
        uint256 i = 0;
        while (i < _stakes[msg.sender].length) {
            uint256 stakingStartWeek = _stakes[msg.sender][i].stakingStartWeek;
            if(currentWeek - stakingStartWeek >= _stakes[msg.sender][i].stakingDuration){
                refund += _stakes[msg.sender][i].coins * TOKENS_PER_COIN;
                payout += _unstakeDance(i);
            } else {
                i += 1;
            }
        }
        // require here so pre-computation will save you.
        require(payout > 0, "No staking period over");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
        _dance.transferNoFee(msg.sender, refund);
    }

    function payoutReward(uint256 id) external override {
        require(_stakes[msg.sender].length > id, "Invalid ID");
        StakedDance memory mstake = _stakes[msg.sender][id];
        uint256 currentWeek = getCurrentWeek();
        require(currentWeek - mstake.stakingStartWeek < mstake.stakingDuration, "Staking period is over, use unstake function instead");
        require(mstake.stakingStartWeek + mstake.paidDuration < currentWeek, "Nothing to pay out");
        reserveForPastWeeks(currentWeek);
        uint256 payout = _getReward(currentWeek, mstake);
        _stakes[msg.sender][id].paidDuration = uint16(min(currentWeek - mstake.stakingStartWeek, mstake.stakingDuration));
        require(payout > 0, "No reward to pay out");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function payoutAllRewards() external {
        StakedDance[] memory mstakes= _stakes[msg.sender];
        require(mstakes.length > 0, "No Dance Tokens staked");
        uint256 currentWeek = getCurrentWeek();
        reserveForPastWeeks(currentWeek);
        uint256 payout = 0;
        uint256 stakingStartWeek;
        uint256 duration;
        uint256 paidDuration;
        for (uint256 id = 0; id < mstakes.length; id++) {
            stakingStartWeek = mstakes[id].stakingStartWeek;
            duration = mstakes[id].stakingDuration;
            paidDuration = mstakes[id].paidDuration;
            if (currentWeek - stakingStartWeek < duration
                && stakingStartWeek + paidDuration < currentWeek){
                payout += _getReward(currentWeek, mstakes[id]);
                _stakes[msg.sender][id].paidDuration = uint16(min(currentWeek - stakingStartWeek, duration));
            }
        }
        // require here so pre-computation will save you.
        require(payout > 0, "No reward to pay out");
        _reservedTokens -= payout;
        _danceSplitter.proxySend(msg.sender, payout);
    }

    function setRewardToken(address tokenAddress) external onlyOwner {
        require(_dance == IERC20F(address(0)), "dance token is already set");
        require(tokenAddress != address(0), "dance token cannot be 0 address");
        _dance = IERC20F(tokenAddress);
    }

    /* Public Functions */

    function getNumStaked(address address_) public view override returns(uint256){
        return _stakes[address_].length;
    }

    function getStakeInfo(address address_, uint256 id_) public view returns(StakedDance memory){
        return _stakes[address_][id_];
    }

    function getAvailablePayout(address address_, uint256 id_) public view returns(uint256){
        uint256 currentWeek = getCurrentWeek();
        StakedDance memory mstake = _stakes[address_][id_];
        uint256 endWeek = mstake.stakingStartWeek + mstake.stakingDuration;
        uint256 startWeek = mstake.stakingStartWeek + mstake.paidDuration;
        uint256 shares = getShares(mstake.coins, mstake.stakingDuration);
        return _getAvailablePayout(startWeek, endWeek, currentWeek, shares);
    }

    function getStakedIDs(address address_) public view override returns(uint256[] memory){
        uint256 numStaked = getNumStaked(address_);
        uint256[] memory stakedIDs = new uint256[](numStaked);
        for (uint256 id = 0; id < numStaked; id++) {
            stakedIDs[id] = id;
        }
        return stakedIDs;
    }

    function getShares(uint32 coins, uint32 stakingDuration) public pure returns(uint256){
        // max shares per coin < (2^32 -1)/21000000 = 204
        uint256 sD = stakingDuration;
        uint256 base = 50;
        uint256 linear = 30 * sD / MAX_STAKING_DURATION;
        uint256 quadratic = 20 * sD * sD / (MAX_STAKING_DURATION*MAX_STAKING_DURATION);
        return coins * (base + linear + quadratic);
    }

    /* Internal Functions */

    function _unstakeDance(uint256 id) internal returns(uint256) {
        StakedDance memory mstake = _stakes[msg.sender][id];
        uint256 currentWeek = getCurrentWeek();
        require(currentWeek - mstake.stakingStartWeek >= mstake.stakingDuration, "Staking period not over");
        reserveForPastWeeks(currentWeek); // reserve reward tokens
        uint256 payout = _getReward(currentWeek, mstake);
        _stakes[msg.sender][id] = _stakes[msg.sender][_stakes[msg.sender].length - 1];
        _stakes[msg.sender].pop();
        return payout;
    }

    function _getReward(uint256 currentWeek, StakedDance memory mstake) internal view returns(uint256){
        require(mstake.stakingStartWeek > 0, "ID is not staked");
        uint256 payout = getStakingReward(
            mstake.stakingStartWeek,
            currentWeek,
            mstake.stakingDuration,
            mstake.paidDuration,
            getShares(mstake.coins, uint16(mstake.stakingDuration))
        );
        // need to update state (paidDuration) in next step
        return payout;
    }

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
/***
 *                                                                 .';:c:,.
 *                   ;0NNNNNNX.  lNNNNNNK;       .XNNNNN.     .:d0XWWWWWWWWXOo'
 *                 lXWWWWWWWWO   XWWWWWWWWO.     :WWWWWK    ;0WWWWWWWWWWWWWWWWWK,
 *              .dNWWWWWWWWWWc  ,WWWWWWWWWWNo    kWWWWWo  .0WWWWWNkc,...;oXWWXxc.
 *            ,kWWWWWWXWWWWWW.  dWWWWWXNWWWWWX; .NWWWWW.  KWWWWW0.         ;.
 *          :KWWWWWNd.lWWWWWO   XWWWWW:.xWWWWWWOdWWWWW0  cWWWWWW.
 *        lXWWWWWXl.  0WWWWW:  ,WWWWWN   '0WWWWWWWWWWWl  oWWWWWW;         :,
 *     .dNWWWWW0;    'WWWWWN.  xWWWWWx     :XWWWWWWWWW.  .NWWWWWWkc,'';ckNWWNOc.
 *   'kWWWWWWx'      oWWWWWk   NWWWWW,       oWWWWWWW0    '0WWWWWWWWWWWWWWWWWO;
 * .d000000o.        k00000;  ,00000k         .x00000:      .lkKNWWWWWWNKko;.
 *                                                               .,;;'.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FeeSplitter.sol";

abstract contract ANCStake is Ownable{

    struct TwoWeekInfo{
        uint96 tokensEvenWeek;
        uint32 totalSharesEvenWeek;
        uint96 tokensOddWeek;
        uint32 totalSharesOddWeek;
    }

    uint256 public constant MAX_STAKING_DURATION = 52;
    uint256 public constant ONE_WEEK = 604800; // 1 week = 604800
    uint256 public tenthPercentPerWeek;
    uint256 public stakingStart;

    FeeSplitter internal _danceSplitter;

    uint256 internal _reservedTokens;

    mapping(uint256 => TwoWeekInfo) private _weeklyInfo;

    constructor(uint256 tenthPercentPerWeek_){
        tenthPercentPerWeek = tenthPercentPerWeek_;
    }

    modifier stakingGate(uint32 duration){
        require(stakingStart > 0, "Staking has not started");
        require(duration >= 1, "Minimum staking period 1 week");
        require(duration <= MAX_STAKING_DURATION, "Maximum staking period 1 year");
        _;
    }

    /* External Functions */

    function payoutReward(uint256) virtual external;

    function setRewardSplitter(address splitterAddress) external onlyOwner {
        require(_danceSplitter == FeeSplitter(address(0)), "Splitter already set");
        require(splitterAddress != address(0), "splitter cannot be 0 address");
        _danceSplitter = FeeSplitter(splitterAddress);
    }

    function setStakingStart() external onlyOwner {
        require(stakingStart == 0, "Staking has already started.");
        stakingStart = block.timestamp;
    }

    function setTenthPercentPerWeek(uint256 tenthPercentPerWeek_) external onlyOwner {
        require(tenthPercentPerWeek_ > 0, "Value must be bigger than 0");
        tenthPercentPerWeek = tenthPercentPerWeek_;
    }

    function getFundsForWeeksLowerBound(uint256 startWeek, uint256 endWeek) external view returns(uint256){
        uint256 currentWeek = getCurrentWeek();
        uint256 currentFunds = getAvailableFunds();
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        uint256 fundsForWeeks = 0;
        for (uint256 week = startWeek; week < lastUnreservedWeek; week++) {
            fundsForWeeks += getBasePayoutForWeek(week);
        }
        uint256 basePayoutForWeek;
        for (uint256 week = lastUnreservedWeek; week < currentWeek; week++) {
            if (getSharesForWeek(week) > 0) {
                basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
                currentFunds -= basePayoutForWeek;
                fundsForWeeks += basePayoutForWeek;
            }
        }
        for (uint256 week = currentWeek; week < endWeek; week++) {
            basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
            currentFunds -= basePayoutForWeek;
            fundsForWeeks += basePayoutForWeek;
        }
        return fundsForWeeks;
    }

    /* Public Functions */

    function getStakedIDs(address) public view virtual returns(uint256[] memory);

    function getNumStaked(address) public view virtual returns(uint256);

    function getAvailableFunds() public view returns(uint256){
        return _danceSplitter.balanceOf(address(this)) - _reservedTokens;
    }

    function getBasePayoutForWeek(uint256 week) public view returns(uint256){
        if(week & 1 == 0){
            return _weeklyInfo[week].tokensEvenWeek;
        }else{
            return _weeklyInfo[week-1].tokensOddWeek;
        }
    }

    function getSharesForWeek(uint256 week) public view returns(uint256){
        if(week & 1 == 0){
            return _weeklyInfo[week].totalSharesEvenWeek;
        }else{
            return _weeklyInfo[week-1].totalSharesOddWeek;
        }
    }

    function getCurrentWeek() public view returns(uint256){
        return timestamp2week(block.timestamp);
    }

    /* Internal Functions */

    function addSharesToWeeks(uint256 startWeek, uint256 duration, uint256 amount) internal{
        for (uint256 i = startWeek; i < startWeek+duration; i++) {
            if(i & 1 == 0){
                _weeklyInfo[i].totalSharesEvenWeek += uint32(amount);
            }else{
                _weeklyInfo[i-1].totalSharesOddWeek += uint32(amount);
            }
        }
    }

    function reserveAndGetTokens(uint256 balance) internal returns(uint256){
        //console.log("balance:", _dance.balanceOf(address(this)));
        uint256 newReserved = (balance - _reservedTokens) * tenthPercentPerWeek / 1000;
        _reservedTokens += newReserved;
        //console.log("reserved tokens:", _reservedTokens);
        return newReserved;
    }

    function reserveForPastWeeks(uint256 currentWeek) internal{
        // find last reserved Week
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        //console.log("current week", currentWeek);
        //console.log("last unreserved week ", lastUnreservedWeek);
        if (lastUnreservedWeek >= currentWeek) return;
        // reserved unclaimed weeks
        uint256 balance = _danceSplitter.balanceOf(address(this));
        for (uint256 week = lastUnreservedWeek; week < currentWeek; week++) {
            if(week & 1 == 0){
                if (_weeklyInfo[week].totalSharesEvenWeek > 0) {
                    _weeklyInfo[week].tokensEvenWeek = uint96(reserveAndGetTokens(balance));
                    //console.log("tokens for week", week, _weeklyInfo[week].tokensEvenWeek);
                }
            } else {
                if (_weeklyInfo[week-1].totalSharesOddWeek > 0) {
                    _weeklyInfo[week-1].tokensOddWeek = uint96(reserveAndGetTokens(balance));
                    //console.log("tokens for week", week, _weeklyInfo[week-1].tokensOddWeek);
                }
            }
        }
    }

    function findLastUnreservedWeek(uint256 currentWeek) internal view returns(uint256){
        uint256 week = currentWeek;
        uint256 tokensForWeek;
        while(week > 1) {
            week -= 1;
            if(week & 1 == 0){
                tokensForWeek = _weeklyInfo[week].tokensEvenWeek;
            } else {
                tokensForWeek = _weeklyInfo[week-1].tokensOddWeek;
            }
            if (tokensForWeek > 0) return week+1;
        }
        return 0;
    }

    function getStakingReward(
        uint256 stakingStartWeek,
        uint256 currentWeek,
        uint256 duration,
        uint256 paidDuration,
        uint256 shares
    ) internal view returns(uint256){
        if (stakingStartWeek + paidDuration >= currentWeek) return 0; // no weeks to pay out
        return _getStakingReward(stakingStartWeek+paidDuration, min(currentWeek, stakingStartWeek+duration), shares);
    }

    function _getStakingReward(uint256 startWeek, uint256 endWeek, uint256 shares) internal view returns(uint256){
        uint256 payout = 0;
        uint256 weeklyShares;
        for(uint256 i = startWeek; i < endWeek; i++){
            if(i & 1 == 0){
                weeklyShares = _weeklyInfo[i].totalSharesEvenWeek;
            } else {
                weeklyShares = _weeklyInfo[i-1].totalSharesOddWeek;
            }
            payout += (getBasePayoutForWeek(i) * shares) / weeklyShares;
        }
        return payout;
    }

    function _getAvailablePayout(uint256 startWeek, uint256 endWeek, uint256 currentWeek, uint256 shares)
        internal
        view
        returns (uint256)
    {
        uint256 currentFunds = getAvailableFunds();
        endWeek = min(endWeek, currentWeek);
        uint256 lastUnreservedWeek = findLastUnreservedWeek(currentWeek);
        uint256 payout = 0;
        uint256 basePayoutForWeek;
        uint256 sharesForWeek;
        for (uint256 week = startWeek; week < endWeek; week++) {
            sharesForWeek = getSharesForWeek(week);
            if (sharesForWeek > 0) {
                if (week < lastUnreservedWeek) { // week has funds reserved
                    basePayoutForWeek = getBasePayoutForWeek(week);
                } else { // week does not have funds reserved
                    basePayoutForWeek = currentFunds * tenthPercentPerWeek / 1000;
                    currentFunds -= basePayoutForWeek;
                }
                payout += (basePayoutForWeek * shares) / sharesForWeek;
            }
        }
        return payout;
    }

    function timestamp2week (uint256 timestamp) internal view returns(uint256) {
        return ((timestamp - stakingStart) / ONE_WEEK)+1;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a <= b) ? a : b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20F is IERC20 {

    function transferNoFee(address to, uint256 amount) external returns (bool);

    function transferFromNoFee(address from, address to, uint256 amount) external returns (bool);

    function fee() external view returns(uint256[2] memory);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

pragma solidity ^0.8.15;

interface FeeSplitter {

    function proxySend(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

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