pragma solidity 0.8.17;
import "IERC20.sol";

interface iVlyCrv {
    function takeSnapshot() external;

    function getSnapshotUnpacked(
        uint
    )
        external
        view
        returns (address[] memory gaugesList, uint256[] memory votesList);

    function decodedVotePointers(address) external view returns (uint256);

    function totalVotes() external view returns (uint256);

    function nextPeriod() external view returns (uint256);
}

interface GaugeController {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }

    struct Point {
        uint bias;
        uint slope;
    }

    function vote_user_slopes(
        address,
        address
    ) external view returns (VotedSlope memory);

    function last_user_vote(address, address) external view returns (uint);

    function points_weight(address, uint) external view returns (Point memory);

    function checkpoint_gauge(address) external;

    function time_total() external view returns (uint);

    function gauge_types(address) external view returns (int128);
}

interface iAutoVoter {
    struct Snapshot {
        uint128 timestamp;
        uint128 stVotes;
    }

    function lastSnapshot() external view returns (Snapshot memory);
}

interface iBribeV3 {
    function claim_reward(
        address gauge,
        address reward_token
    ) external returns (uint);

    function claim_reward_for(
        address voter,
        address gauge,
        address reward_token
    ) external returns (uint);
}

contract BribeSplitter {

    event GovernanceChanged(
        address indexed oldGovernance,
        address indexed newGovernance
    );
    event VlYcrvChanged(address indexed vlYcrvAddress);
    event AutovoterChanged(address indexed autovoterAddress);
    event YBribeChanged(address indexed ybribeAddress);
    event StYcrvChanged(address indexed stYcrvAddress);
    event RefundHolderChanged(address indexed refundHolderAddress);
    event OperatorChanged(address indexed operator, bool indexed allowed);
    event StShareChanged(uint indexed stShare);
    event DiscountedGaugeChanged(
        address indexed gauge,
        bool indexed discounted
    );
    event RefundRecipientChanged(
        address indexed gauge,
        address indexed rewardToken,
        address indexed recipient
    );

    address public stYcrvStrategy; //the strategy that will receive ST-YCRV's share of the rewards
    address public autovoter;
    address public ybribe;
    address public vlycrv;
    address[] public discountedGauges;

    // Gauge -> Token -> Amount (refund-eligible amount of veCRV)
    // Should be set to 0 if the votes are done through vl-yCRV. Refund is sent to refundHolder or address found in refundRecipient mapping
    mapping(address => mapping(address => uint)) public otcRefunds;

    // If refundRecipient is not set, the refund goes to refundHolder
    address public refundHolder;

    // The GaugeController where veCRV gauge votes are submitted and stored
    GaugeController constant GAUGE =
        GaugeController(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    uint constant WEEK = 86400 * 7;

    address constant YEARN = 0xF147b8125d2ef93FB6965Db97D6746952a133934; // yearns crv locker and voter

    // Trusted operators are allowed to initiate the refunds
    mapping(address => bool) public operators;

    // By default 10% of st-yCRV votes go to the yCRV gauge
    uint256 public stShare = 9_000;
    uint constant DENOMINATOR = 10_000;

    // Gauge -> Token -> Recipient
    // All refunds owed for votes on a gauge/token combo go to this refundRecipient
    mapping(address => mapping(address => address)) public refundRecipient;
    address public governance = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52; //ychad.eth
    address public yearnTreasury = 0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde; //treasury.ychad.eth
    address pendingGovernance;

    constructor(
        address _stYcrvStrategy,
        address _autovoter,
        address _ybribe,
        address _vlycrv,
        address _refundHolder,
        address[] memory _discountedGauges
    ) {
        stYcrvStrategy = _stYcrvStrategy;
        autovoter = _autovoter;
        ybribe = _ybribe;
        vlycrv = _vlycrv;
        refundHolder = _refundHolder;
        discountedGauges = _discountedGauges;

        operators[msg.sender] = true;
    }

    /// @notice Split
    /// @dev If the rewards are already in the contract and there are no vl-yCRV votes then gauge can be any gauge we voted on
    /// @param token Reward token that we are splitting
    /// @param gauge Address of the gauge that was voted on
    /// @param claim Claim from the yBribe contract? False means we just split the tokens currently sitting in this contract
    function bribesSplit(
        address token,
        address gauge,
        bool claim
    ) external onlyOperator {
        _split(token, gauge, claim, 0);
    }

    /// @notice Split using a manual st-yCRV balance. Use only if vl-yCRV isn't in use
    /// @dev same as bribesSplit but can be used without vl-yCRV and AutoVoter. Manually input the yCRV in st-yCRV
    /// @param token Reward token that we are splitting
    /// @param gauge Address of the gauge that was voted on
    /// @param stBalance Balance of yCRV in st-yCRV
    /// @param claim Claim from the yBribe contract?
    function bribesSplitWithManualStBalance(
        address token,
        address gauge,
        uint stBalance,
        bool claim
    ) external onlyOperator {
        require(autovoter == address(0));
        _split(token, gauge, claim, stBalance );
    }

    function _split(address token, address gauge, bool claim,  uint stBalance) internal {
        //as others can claim for us we don't always want to claim.
        if (claim) {
            iBribeV3(ybribe).claim_reward_for(YEARN, gauge, token);
        }

        // By the end, all of this will be distributed
        uint tokenBalance = IERC20(token).balanceOf(address(this));

        require(tokenBalance > 0, "nothing to split");

        GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(
            YEARN,
            gauge
        );
        uint lastVote = GAUGE.last_user_vote(YEARN, gauge);

        // gaugeVotes gives us how many veCRV we voted with on that gauge
        uint gaugeVotes = _calcBias(vs.slope, vs.end, lastVote);

        // We can then reverse calculate that number to get us yearn's total veCRV votes
        uint yearnTotalVotes = (gaugeVotes * 10_000) / vs.power;

        uint stVotes;

        // If there is no AutoVoter attached, we can manually enter the yCRV balance of st-yCRV via bribesSplitWithManualStBalance
        if(autovoter != address(0)){
            iAutoVoter.Snapshot memory snap = iAutoVoter(autovoter).lastSnapshot();
            require(lastVote == snap.timestamp, "autovoter"); // Can only use when autovoter did last vote
            stVotes = snap.stVotes;
        }else{
            require(stBalance > 0, "no st-ycrv balance found");
            stVotes = stBalance;
        }
        
        uint usedVotes;
        address[] memory vlGauges; // The list of all gauges voted on by vl-yCRV
        uint[] memory vlVotes; // The list of all votes by vl-yCRV

        // _refund returns any monies that was voted on by vl-yCRV voters
        // usedVotes keeps track of the number of votes we will be disregarding from the final split. At this point it is the total votes by vl-yCRV
        (tokenBalance, usedVotes, vlGauges, vlVotes) = _refund(
            token,
            gauge,
            gaugeVotes,
            tokenBalance,
            lastVote
        );

        // Pass in any gauges that were voted for by vl-yCRV, so that we don't double count them
        // Increase usedVotes by any votes that were made to disregarded gauges. For instance, we don't count votes on the yCRV gauge
        usedVotes = usedVotes + _disregardedVotes(vlGauges, vlVotes);

        stVotes = stVotes * stShare / DENOMINATOR; // What share of bribes does st-yCRV get. By default 90%, as 10% of their vote goes to the yCRV gauge

        // Do the final split between yearn treasury and st-yCRV
        _basicSplit(
            token,
            tokenBalance,
            yearnTotalVotes - usedVotes,
            stVotes
        );
    }

    function disregardedVotes() external view returns (uint disregardedAmounts) {
        address[] memory ignoredGauges;
        uint[] memory ignoredVotes;
        return _disregardedVotes(ignoredGauges, ignoredVotes);
    }

    function disregardedVotes(address[] memory ignoredGauges,  uint[] memory ignoredVotes) external view returns (uint disregardedAmounts) {
        return _disregardedVotes(ignoredGauges, ignoredVotes);
    }


    // Finds total amount of votes on gauges that are present in discountedGauges and not in the vlVotedOnGauges list
    function _disregardedVotes(
        address[] memory vlGauges,
         uint[] memory vlVotes
    ) internal view returns (uint disregardedAmounts) {
        uint length = discountedGauges.length;

        for (uint i; i < length; i++) {
            address gauge = discountedGauges[i];
            uint discounted;
            for (uint j; j < vlGauges.length; j++) {
                if (vlGauges[j] == gauge) {
                    discounted = vlVotes[j];
                    break;
                }
            }
            
            GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(
                YEARN,
                gauge
            );
            uint lastVote = GAUGE.last_user_vote(YEARN, gauge);
            uint gaugeVotes = _calcBias(vs.slope, vs.end, lastVote);
            discounted = discounted > gaugeVotes ? gaugeVotes : discounted; // If, for whatever reason, we have more predicted votes than real
            disregardedAmounts += gaugeVotes - discounted;
        }
    }

    /// @dev Cycle through the gauges voted on by vl-yCRV to see if they voted on the gauge we are splitting
    /// @return remainingBalance Keep track of the balance of tokens in this contract to save sloads
    /// @return usedVotes Keep track of the total votes by all vl-yCRV voters so we can disregard them from the yearn treasury total
    /// @return gaugesList Return the list of gauges vl-yCRV voted on so that we don't double count them later
    function _refund(
        address token,
        address gauge,
        uint gaugeVotes,
        uint tokenBalance,
        uint timestamp
    )
        internal
        returns (
            uint remainingBalance,
            uint usedVotes,
            address[] memory gaugesList,
            uint256[] memory votesList
            
        )
    {
        // Refund any OTC amount
        uint otcRefund = otcRefunds[gauge][token];
        if(otcRefund > 0){
            usedVotes += otcRefund;
            
            uint refundAmount = (tokenBalance *
                ((otcRefund * 1e18) / gaugeVotes)) / 1e18;
            tokenBalance = tokenBalance - refundAmount;

            address recipient = refundRecipient[gauge][token];
            recipient = recipient == address(0) ? refundHolder : recipient;
            IERC20(token).transfer(recipient, refundAmount);
        }

        // Will still work if there is no vl-yCRV or AutoVoter
        if(vlycrv != address(0) && autovoter != address(0)){
            (gaugesList, votesList) = iVlyCrv(vlycrv).getSnapshotUnpacked(
            timestamp
        );
            for (uint i; i < gaugesList.length; i++) {
                usedVotes += votesList[i];
                if (gaugesList[i] == gauge) {
                    uint refundAmount = (tokenBalance *
                        ((votesList[i] * 1e18) / gaugeVotes)) / 1e18;
                    tokenBalance = tokenBalance - refundAmount;

                    address recipient = refundRecipient[gauge][token];
                    recipient = recipient == address(0) ? refundHolder : recipient;
                    IERC20(token).transfer(recipient, refundAmount);
                }
            }
        }
        remainingBalance = tokenBalance;
    }

    function _basicSplit(
        address token,
        uint balance,
        uint totalVotes,
        uint stVotes
    ) internal {
        // split vl and treasury
        uint stSplit = (balance * stVotes) / totalVotes;

        uint yearnSplit = balance - stSplit;

        IERC20(token).transfer(stYcrvStrategy, stSplit);
        IERC20(token).transfer(yearnTreasury, yearnSplit);
    }

    function _calcBias(
        uint _slope,
        uint _end,
        uint256 current
    ) internal pure returns (uint) {
        if (current + WEEK >= _end) return 0;
        return _slope * (_end - current);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "!operator");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    function setOperator(
        address _operator,
        bool _allowed
    ) external onlyGovernance {
        operators[_operator] = _allowed;
        emit OperatorChanged(_operator, _allowed);
    }

    function setOtcRefund(
        address gauge,
        address token,
        uint96 numVotes
    ) external onlyGovernance {

        otcRefunds[gauge][token] = numVotes;

    }

    // Don't add more than once, you'd just be wasting gas
    function addDiscountedGauge(address _gauge) external onlyGovernance {
        uint length = discountedGauges.length;
        for (uint i; i < length; i++) {
            require(discountedGauges[i] != _gauge, "already added");
        }

        discountedGauges.push(_gauge);
        emit DiscountedGaugeChanged(_gauge, true);
    }

    function removeDiscountedGauge(address _gauge) external onlyGovernance {
        uint length = discountedGauges.length;
        for (uint i; i < length; i++) {
            if (discountedGauges[i] == _gauge) {
                if (i != length - 1) {
                    discountedGauges[i] = discountedGauges[length - 1];
                }
                discountedGauges.pop();
                break;
            }
        }
        emit DiscountedGaugeChanged(_gauge, false);
    }

    function setRefundRecipient(
        address _gauge,
        address _token,
        address _recipient
    ) external onlyGovernance {
        refundRecipient[_gauge][_token] = _recipient;
        emit RefundRecipientChanged(_gauge, _token, _recipient);
    }
    
    function setStShare(
        uint _share
    ) external onlyGovernance {
        require(_share <= 10_000, "over 100%");
        stShare = _share;
        emit StShareChanged(_share);
    }
    
    function setVlYcrv(
        address _vlycrv
    ) external onlyGovernance {
        vlycrv = _vlycrv;
        emit VlYcrvChanged(_vlycrv);
    }
    
    function setStYcrv(
        address _stycrv
    ) external onlyGovernance {
        stYcrvStrategy = _stycrv;
        emit StYcrvChanged(_stycrv);
    }
    
    function setAutoVoter(
        address _autoVoter
    ) external onlyGovernance {
        autovoter = _autoVoter;
        emit AutovoterChanged(_autoVoter);
    }
    
    function setRefundHolder(
        address _refundHolder
    ) external onlyGovernance {
        refundHolder = _refundHolder;
        require(_refundHolder != address(0), "0 address");
        emit RefundHolderChanged(_refundHolder);
    }
    
    function setYBribe(
        address _ybribe
    ) external onlyGovernance {
        ybribe = _ybribe;
        emit YBribeChanged(_ybribe);
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!governance");
        address old = governance;
        governance = pendingGovernance;
        emit GovernanceChanged(old, governance);
    }

    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
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