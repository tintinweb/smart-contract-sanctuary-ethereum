/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity 0.8.15;

// Based on yBribe
// now featuring no blacklist or rent-seeking


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

    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint) external view returns (Point memory);
    function checkpoint_gauge(address) external;
    function time_total() external view returns (uint);
    function gauge_types(address) external view returns (int128);
}

interface erc20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}

contract BribeV3 {

    event RewardAdded(address indexed briber, address indexed gauge, address indexed reward_token, uint amount);
    event NewTokenReward(address indexed gauge, address indexed reward_token); // Specifies unique token added for first time to gauge
    event RewardClaimed(address indexed user, address indexed gauge, address indexed reward_token, uint amount);
    event SetRewardRecipient(address indexed user, address recipient);
    event ClearRewardRecipient(address indexed user, address recipient);
    event PeriodUpdated(address indexed gauge, uint indexed period, uint bias);

    uint constant WEEK = 86400 * 7;
    uint constant PRECISION = 10**18;
    GaugeController constant GAUGE = GaugeController(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);

    mapping(address => mapping(address => uint)) public claims_per_gauge;
    mapping(address => mapping(address => uint)) public reward_per_gauge;

    mapping(address => mapping(address => uint)) public reward_per_token;
    mapping(address => mapping(address => uint)) public active_period;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;
    mapping(address => address) public reward_recipient;

    mapping(address => address[]) _rewards_per_gauge;
    mapping(address => address[]) _gauges_per_reward;
    mapping(address => mapping(address => bool)) _rewards_in_gauge;
    mapping(address => bool) _block_third_party_claim;

    function _add(address gauge, address reward) internal {
        if (!_rewards_in_gauge[gauge][reward]) {
            _rewards_per_gauge[gauge].push(reward);
            _gauges_per_reward[reward].push(gauge);
            _rewards_in_gauge[gauge][reward] = true;
            emit NewTokenReward(gauge, reward);
        }
    }

    function rewards_per_gauge(address gauge) external view returns (address[] memory) {
        return _rewards_per_gauge[gauge];
    }

    function gauges_per_reward(address reward) external view returns (address[] memory) {
        return _gauges_per_reward[reward];
    }

    /// @dev Required to sync each gauge/token pair to new week.
    /// @dev Can be triggered either by claiming or adding bribes to gauge/token pair.
    function _update_period(address gauge, address reward_token) internal returns (uint) {
        uint _period = active_period[gauge][reward_token];
        if (block.timestamp >= _period + WEEK) {
            _period = current_period();
            GAUGE.checkpoint_gauge(gauge);
            uint _bias = GAUGE.points_weight(gauge, _period).bias;
            emit PeriodUpdated(gauge, _period, _bias);
            uint _amount = reward_per_gauge[gauge][reward_token] - claims_per_gauge[gauge][reward_token];
            if (_bias > 0){
                reward_per_token[gauge][reward_token] = _amount * PRECISION / _bias;
            }
            active_period[gauge][reward_token] = _period;
        }
        return _period;
    }

    function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool) {
        require(GAUGE.gauge_types(gauge) >= 0); // @dev: reverts on invalid gauge
        _safeTransferFrom(reward_token, msg.sender, address(this), amount);
        _update_period(gauge, reward_token);
        reward_per_gauge[gauge][reward_token] += amount;
        _add(gauge, reward_token);
        emit RewardAdded(msg.sender, gauge, reward_token, amount);
        return true;
    }

    /// @notice Estimate pending bribe amount for any user
    /// @dev This function returns zero if active_period has not yet been updated.
    /// @dev Should not rely on this function for any user case where precision is required.
    function claimable(address user, address gauge, address reward_token) external view returns (uint) {
        uint _period = current_period();
        if (last_user_claim[user][gauge][reward_token] >= _period) {
            return 0;
        }
        uint last_user_vote = GAUGE.last_user_vote(user, gauge);
        if (last_user_vote >= _period) {
            return 0;
        }
        if (_period != active_period[gauge][reward_token]) {
            return 0;
        }
        GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(user, gauge);
        uint _user_bias = _calc_bias(vs.slope, vs.end);
        return _user_bias * reward_per_token[gauge][reward_token] / PRECISION;
    }

    function claim_reward(address gauge, address reward_token) external returns (uint) {
        return _claim_reward(msg.sender, gauge, reward_token);
    }

    function claim_reward_for_many(address[] calldata _users, address[] calldata _gauges, address[] calldata _reward_tokens) external returns (uint[] memory amounts) {
        require(_users.length == _gauges.length && _users.length == _reward_tokens.length, "!lengths");
        uint length = _users.length;
        amounts = new uint[](length);
        for (uint i = 0; i < length; i++) {
            require(!_block_third_party_claim[_users[i]]);
            amounts[i] = _claim_reward(_users[i], _gauges[i], _reward_tokens[i]);
        }
        return amounts;
    }

    function claim_reward_for(address user, address gauge, address reward_token) external returns (uint) {
        require(!_block_third_party_claim[user]);
        return _claim_reward(user, gauge, reward_token);
    }

    function _claim_reward(address user, address gauge, address reward_token) internal returns (uint) {
        uint _period = _update_period(gauge, reward_token);
        uint _amount = 0;
        if (last_user_claim[user][gauge][reward_token] < _period) {
            last_user_claim[user][gauge][reward_token] = _period;
            if (GAUGE.last_user_vote(user, gauge) < _period) {
                GaugeController.VotedSlope memory vs = GAUGE.vote_user_slopes(user, gauge);
                uint _user_bias = _calc_bias(vs.slope, vs.end);
                _amount = _user_bias * reward_per_token[gauge][reward_token] / PRECISION;
                if (_amount > 0) {
                    claims_per_gauge[gauge][reward_token] += _amount;
                    address recipient = reward_recipient[user];
                    recipient = recipient == address(0) ? user : recipient;
                    _safeTransfer(reward_token, recipient, _amount);
                    emit RewardClaimed(user, gauge, user, _amount);
                }
            }
        }
        return _amount;
    }

    /// @dev Compute bias from slope and lock end
    /// @param _slope User's slope
    /// @param _end Timestamp of user's lock end
    function _calc_bias(uint _slope, uint _end) internal view returns (uint) {
        uint current = current_period();
        if (current + WEEK >= _end) return 0;
        return _slope * (_end - current);
    }

    /// @dev Helper function to determine current period globally. Not specific to any gauges or internal state.
    function current_period() public view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    /// @notice Allow any user to route claimed rewards to a specified recipient address
    function set_recipient(address _recipient) external {
        require (_recipient != msg.sender, "self");
        require (_recipient != address(0), "0x0");
        address current_recipient = reward_recipient[msg.sender];
        require (_recipient != current_recipient, "Already set");

        // Update delegation mapping
        reward_recipient[msg.sender] = _recipient;

        if (current_recipient != address(0)) {
            emit ClearRewardRecipient(msg.sender, current_recipient);
        }

        emit SetRewardRecipient(msg.sender, _recipient);
    }

    /// @notice Allow any user to clear any previously specified reward recipient
    function clear_recipient() external {
        address current_recipient = reward_recipient[msg.sender];
        require (current_recipient != address(0), "No recipient set");
        // update delegation mapping
        reward_recipient[msg.sender]= address(0);
        emit ClearRewardRecipient(msg.sender, current_recipient);
    }

    function set_block_third_party_claim(bool _is_blocked) external {
        _block_third_party_claim[msg.sender] = _is_blocked;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}