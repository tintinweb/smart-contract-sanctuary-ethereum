pragma solidity >=0.8.4 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_AMOUNT();
error NOT_OWNER();
error TOKENS_ALREADY_RELAEASED();

/**
@title GTCStaking Contract
@notice Vote on gitcoin grants powered by conviction voting off-chain by staking your gtc.
*/
contract GTCStaking {
    event VoteCasted(
        uint56 voteId,
        address indexed voter,
        uint152 amount,
        uint48 grantId
    );

    event TokensReleased(
        uint56 voteId,
        address indexed voter,
        uint152 amount,
        uint48 grantId
    );

    /// @notice gtc token contract instance.
    IERC20 immutable public gtcToken;

    /// @notice vote struct array.
    Vote[] public votes;

    /// @notice mapping which tracks the votes for a particular user.
    mapping(address => uint56[]) public voterToVoteIds;

    /// @notice Vote struct.
    struct Vote {
        bool released;
        address voter;
        uint152 amount;
        uint48 grantId;
        uint56 voteId;
    }

    /// @notice BatchVote struct.
    struct BatchVoteParam {
        uint48 grantId;
        uint152 amount;
    }

    /**
    @dev Constructor.
    @param tokenAddress gtc token address.
    */
    constructor(address tokenAddress) {
        gtcToken = IERC20(tokenAddress);
    }

    /**
    @dev Get Current Timestamp.
    @return current timestamp.
    */
    function currentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /**
    @dev Checks if tokens are locked or not.
    @return status of the tokens.
    */
    function areTokensLocked(uint56 _voteId) external view returns (bool) {
        return !votes[_voteId].released;
    }

    /**
    @dev Vote Info for a user.
    @param _voter address of voter
    @return Vote struct for the particular user id.
    */
    function getVotesForAddress(address _voter)
        external
        view
        returns (Vote[] memory)
    {
        uint56[] memory voteIds = voterToVoteIds[_voter];
        Vote[] memory votesForAddress = new Vote[](voteIds.length);
        for (uint256 i = 0; i < voteIds.length; i++) {
            votesForAddress[i] = votes[voteIds[i]];
        }
        return votesForAddress;
    }

    /**
    @dev Stake and get Voting rights.
    @param _grantId gitcoin grant id.
    @param _amount amount of tokens to lock.
    */
    function _vote(uint48 _grantId, uint152 _amount) internal {
        if (_amount == 0) {
            revert INVALID_AMOUNT();
        }

        gtcToken.transferFrom(msg.sender, address(this), _amount);

        uint56 voteId = uint56(votes.length);

        votes.push(
            Vote({
                voteId: voteId,
                voter: msg.sender,
                amount: _amount,
                grantId: _grantId,
                released: false
            })
        );

        voterToVoteIds[msg.sender].push(voteId);

        emit VoteCasted(voteId, msg.sender, _amount, _grantId);
    }

    /**
    @dev Stake and get Voting rights in barch.
    @param _batch array of struct to stake into multiple grants.
    */
    function vote(BatchVoteParam[] calldata _batch) external {
        for (uint256 i = 0; i < _batch.length; i++) {
            _vote(_batch[i].grantId, _batch[i].amount);
        }
    }

    /**
    @dev Release tokens and give up votes.
    @param _voteIds array of vote ids in order to release tokens.
    */
    function releaseTokens(uint256[] calldata _voteIds) external {
        for (uint256 i = 0; i < _voteIds.length; i++) {
            if (votes[_voteIds[i]].voter != msg.sender) {
                revert NOT_OWNER();
            }
            if (votes[_voteIds[i]].released) {
                // UI can send the same vote multiple times, ignore it
                continue;
            }
            votes[_voteIds[i]].released = true;
            gtcToken.transfer(msg.sender, votes[_voteIds[i]].amount);

            emit TokensReleased(uint56(_voteIds[i]), msg.sender, votes[_voteIds[i]].amount, votes[_voteIds[i]]
                .grantId);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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