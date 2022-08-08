/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier:NOLICENSE
pragma solidity 0.8.14;

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
     * zero by functionault.
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

interface VotingEscrow {
    function user_point_epoch(address addr) external view returns (uint256);
    function user_point_history__ts(address addr, uint256 epoch) external view returns (uint256);
}

interface VotingEscrowBoost {
    function adjusted_balance_of(address _account) external view returns (uint256);
}

interface ERC20Extended {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Math {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library Address {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

contract Farm is ReentrancyGuard {
    using Math for uint;
    using SafeERC20 for IERC20;

    event Deposit(
        address indexed provider,
        uint256 value
    );

    event Withdraw(
        address indexed provider,
        uint256 value
    );

    event UpdateLiquidityLimit(
        address user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 working_balance,
        uint256 working_supply
    );

    event CommitOwnership(
        address admin
    );

    event ApplyOwnership(
        address admin
    );

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event RewardDataUpdate(
        address indexed _token,
        uint256 _amount
    );

    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    uint256 constant MAX_REWARDS = 8;
    uint256 constant MAX_HARVEST = 14 days;
    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant MAX_DEPOSIT_FEE = 5;
    uint256 constant WEEK = 604800;

    address[MAX_REWARDS] public reward_tokens;
    address public LUCAX;
    address public voting_escrow;
    address public veBoost_proxy;
    address public staking_token;
    
    address public admin;
    address public future_admin;
    address public feeCollector;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimal_staking_token;

    uint256 public working_supply;
    uint256 public reward_count;   
    
    uint256 public depositFee;
    uint256 public harvestTime;

    bool public initialized;

    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => Reward) public reward_data;
    mapping(address => address) public rewards_receiver;
    mapping(address => uint256) public working_balances;
    mapping(address => uint256) public lastHarvest;
    mapping(address => uint256) public integrate_checkpoint_of;
    mapping(address => mapping(address => uint256)) claim_data;
    mapping(address => mapping(address => uint256)) public reward_integral_for;    

    function initialize(
        address _staking_token, 
        address _admin, 
        address _LUCAX, 
        address _voting_escrow, 
        address _veBoost_proxy, 
        address _distributor, 
        address _feeCollector, 
        uint _depositFee,
        uint _harvestTime
    ) 
        external 
    {
        require(!initialized, "initialize:: initialized");
        initialized = true;

        require(_admin != address(0), "initialize::unauthorized");
        require(_LUCAX != address(0), "initialize::_LUCAX is zero address");
        require(_voting_escrow != address(0), "initialize::_voting_escrow is zero address");
        require(_veBoost_proxy != address(0), "initialize::_veBoost_proxy is zero address");
        require(_distributor != address(0), "initialize::_distributor is zero address");
        require(_depositFee <= MAX_DEPOSIT_FEE, "initialize:: fee is higher than max depsoit fee");
        require(_harvestTime <= MAX_HARVEST, "initialize:: harvest time is higher than max harvest");

        admin = _admin;
        staking_token = _staking_token;
        decimal_staking_token = ERC20Extended(_staking_token).decimals();

        feeCollector = _feeCollector;
        depositFee = _depositFee;
        harvestTime = _harvestTime;

        string memory _symbol = ERC20Extended(_staking_token).symbol();
        name = string(abi.encodePacked("LUCAX ", _symbol, " Gauge"));
        symbol = string(abi.encodePacked(_symbol, "-gauge"));
        LUCAX = _LUCAX;
        voting_escrow = _voting_escrow;
        veBoost_proxy = _veBoost_proxy;

        reward_data[_LUCAX].distributor = _distributor;
        reward_tokens[0] = _LUCAX;
        reward_count = 1;
    }

    function userCheckpoint(address addr) external returns(bool) {
        require(msg.sender == addr, "userCheckpoint::unauthorized");

        _checkpointRewards(
            addr, 
            totalSupply, 
            false, 
            address(0), 
            true
        );

        _updateLiquidityLimit(
            addr, 
            balanceOf[addr], 
            totalSupply
        );

        return true;
    }    
    
    function setRewardsReceiver(address _receiver) external {
        rewards_receiver[msg.sender] = _receiver;
    }

    function setDepositFee(uint _fee) external {
        require(admin == msg.sender, "setDepositFee::unauthorized");
        require(_fee <= MAX_DEPOSIT_FEE, "setDepositFee::less than MAX_DEPOSIT_FEE");
        depositFee = _fee;
    }

    function setFeeCollector( address newFeeCollector) external {
        require(admin == msg.sender, "set_deposit_fee::unauthorized");
        require(newFeeCollector != address(0), "set_deposit_fee::newFeeCollector not zero");
        feeCollector = newFeeCollector;
    }

    function setHarvestTime( uint newHarvestTime) external {
        require(admin == msg.sender, "setTreasury::unauthorized");
        require(newHarvestTime <= MAX_HARVEST, "setTreasury::new harvest is higher than Max harvest");
        harvestTime = newHarvestTime;
    }
    
    function claimRewards(address addr, address receiver) external nonReentrant {
        if(receiver != address(0)) {
            require(
                addr == msg.sender, 
                "claimRewards::cannot redirect when claiming for another user"
            );
        }
        
        require((lastHarvest[addr] == 0) || (lastHarvest[addr] + harvestTime < block.timestamp), "does not reach the harvest time");
        lastHarvest[addr] = block.timestamp;
        _checkpointRewards(addr, totalSupply, true, receiver,false);
    }
    
    function kick(address addr) external {
        uint256 t_last = integrate_checkpoint_of[addr];
        uint256 t_ve = VotingEscrow(voting_escrow).user_point_history__ts(
            addr, 
            VotingEscrow(voting_escrow).user_point_epoch(
                addr
            )
        );
        uint256 _balance = balanceOf[addr];

        require(IERC20(voting_escrow).balanceOf(addr) == 0 || t_ve > t_last, "kick::kick not allowed");
        require(working_balances[addr] > _balance * TOKENLESS_PRODUCTION / 100, "kick::kick not needed");

        uint256 total_supply = totalSupply;
        _checkpointRewards(addr, total_supply, false, address(0), true);
        _updateLiquidityLimit(addr, balanceOf[addr], total_supply);
    }
    
    function deposit(uint256 _value, bool _claim_rewards) external nonReentrant {
        if(_value != 0) {
            bool is_rewards = reward_count != 0;            
            if(is_rewards) {
                _claim_rewards = (lastHarvest[msg.sender] == 0) || (lastHarvest[msg.sender] + harvestTime < block.timestamp);
                if(_claim_rewards) 
                    lastHarvest[msg.sender] = block.timestamp;

                _checkpointRewards(
                    msg.sender, 
                    totalSupply, 
                    _claim_rewards, 
                    address(0),
                    false
                );
            }
            
            uint feeDis = _value * depositFee / 100;
            _value = _value - feeDis;

            totalSupply += _value;
            balanceOf[msg.sender] += _value;
            _updateLiquidityLimit(msg.sender, balanceOf[msg.sender], totalSupply);

            _safeTransferFrom( staking_token, msg.sender, address(this), _value);
            _safeTransferFrom( staking_token, msg.sender, feeCollector, feeDis);

        } else {
            _checkpointRewards(
                msg.sender, 
                totalSupply, 
                false, 
                address(0), 
                true
            );
        }

        emit Deposit(msg.sender, _value);
        emit Transfer(address(0), msg.sender, _value);
    }
    
    function withdraw(uint256 _value, bool _claim_rewards) external nonReentrant {
        if(_value != 0) {
            bool is_rewards = reward_count != 0;
            if(is_rewards) {
                _claim_rewards = (lastHarvest[msg.sender] == 0) || (lastHarvest[msg.sender] + harvestTime < block.timestamp);
                if(_claim_rewards) 
                    lastHarvest[msg.sender] = block.timestamp;

                _checkpointRewards(
                    msg.sender, 
                    totalSupply, 
                    _claim_rewards, 
                    address(0),
                    false
                );
            }

            totalSupply -= _value;
            balanceOf[msg.sender] -= _value;

            _updateLiquidityLimit(msg.sender, balanceOf[msg.sender], totalSupply);

            IERC20(staking_token).transfer(msg.sender, _value);
        } else {
            _checkpointRewards(
                msg.sender, 
                totalSupply, 
                false, 
                address(0), 
                true
            );
        }

        emit Withdraw(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }    

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        uint256 _allowance = allowance[_from][msg.sender];
        if(_allowance != type(uint256).max)
            allowance[_from][msg.sender] = _allowance - _value;

        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
    function increaseAllowance(address _spender, uint256 _added_value) external returns (bool) {
        allowance[msg.sender][_spender] += _added_value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }
    
    function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool) {
        allowance[msg.sender][_spender] -= _subtracted_value;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }
    
    function addReward(address _reward_token, address _distributor) external {
        require(msg.sender == admin, "addReward::unauthorized");
        require(reward_count < MAX_REWARDS, "addReward::less than MAX_REWARDS");
        require(reward_data[_reward_token].distributor == address(0), "addReward::distributor is not zero address");

        reward_data[_reward_token].distributor = _distributor;
        reward_tokens[reward_count] = _reward_token;
        reward_count = reward_count + 1;
    }
    
    function setRewardDistributor(address _reward_token, address _distributor) external {
        address current_distributor = reward_data[_reward_token].distributor;

        require(msg.sender == current_distributor || msg.sender == admin, "set_reward_distributor::must be distributor or admin");
        require(current_distributor != address(0), "set_reward_distributor::distributor is zero");
        require(_distributor != address(0), "set_reward_distributor::new distributor is zero");

        reward_data[_reward_token].distributor = _distributor;
    }
    
    function depositRewardToken(address _reward_token, uint256 _amount) external nonReentrant {
        require(msg.sender == reward_data[_reward_token].distributor, "deposit_reward_token::not distributor");

        _checkpointRewards(
            address(0), 
            totalSupply, 
            false, 
            address(0),
            false
        );

        _safeTransferFrom( _reward_token, msg.sender, address(this), _amount);
        uint256 period_finish = reward_data[_reward_token].period_finish;

        if(block.timestamp >= period_finish) {
            reward_data[_reward_token].rate = _amount / WEEK;
        } else {
            uint256 remaining = period_finish - block.timestamp;
            uint256 leftover = remaining * reward_data[_reward_token].rate;
            reward_data[_reward_token].rate = (_amount + leftover) / WEEK;
        }

        reward_data[_reward_token].last_update = block.timestamp;
        reward_data[_reward_token].period_finish = block.timestamp + WEEK;

        emit RewardDataUpdate(_reward_token,_amount);
    }

    function commitTransferOwnership(address addr) external {
        require(msg.sender == admin, "commit_transfer_ownership::unauthorized");
        require(addr != address(0), "commit_transfer_ownership::future admin cannot be the 0 address");

        future_admin = addr;
        emit CommitOwnership(addr);
    }
    
    function acceptTransferOwnership() external {
        address _admin = future_admin;
        require(msg.sender == _admin, "accept_transfer_ownership::unauthorized");

        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    function claimedReward(address _addr, address _token) external view returns (uint256) {
        return claim_data[_addr][_token] % 2**128;
    }
 
    function claimableReward(address _user, address _reward_token) external view returns (uint256) {
        uint256 integral = reward_data[_reward_token].integral;
        uint256 total_supply = totalSupply;
        uint256 user_balance = balanceOf[_user];

        if(_reward_token == LUCAX) {
            total_supply = working_supply;
            user_balance = working_balances[_user];
        }

        if(total_supply != 0) {
            uint256 last_update = block.timestamp.min(reward_data[_reward_token].period_finish);
            uint256 duration = last_update - reward_data[_reward_token].last_update;
            integral += (duration * reward_data[_reward_token].rate * 10**18 / total_supply);
        }

        uint256 integral_for = reward_integral_for[_reward_token][_user];
        uint256 new_claimable = user_balance * (integral - integral_for) / 10**18;

        return (claim_data[_user][_reward_token] >> 128) + new_claimable;
    }

    function decimals() external view returns (uint256) {
        return decimal_staking_token;
    }

    function _updateLiquidityLimit(address _addr, uint256 _balance, uint256 _total_supply) internal {
        //  To be called after totalSupply is updated
        uint256 voting_balance = VotingEscrowBoost(veBoost_proxy).adjusted_balance_of(_addr);
        uint256 voting_total = IERC20(voting_escrow).totalSupply();

        uint256 lim = _balance * TOKENLESS_PRODUCTION / 100;
        if(voting_total > 0) {
            lim += (_total_supply * voting_balance) / ((voting_total * (100 - TOKENLESS_PRODUCTION)) / 100);
        }

        lim = _balance.min(lim);
        uint256 old_bal = working_balances[_addr];
        working_balances[_addr] = lim;
        uint256 _working_supply = (working_supply + lim) - old_bal;
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(_addr, _balance, _total_supply, lim, _working_supply);
    }
    
    function _checkpointReward(
        address _user, 
        address token, 
        uint256 _total_supply, 
        uint256 _user_balance, 
        bool _claim, 
        address receiver
    ) 
        internal 
    {
        if(token == LUCAX) {
            _total_supply = working_supply;
            _user_balance = working_balances[_user];
        }

        uint256[3] memory integral_last_update_duration;
        integral_last_update_duration[0] = reward_data[token].integral;
        integral_last_update_duration[1] = block.timestamp.min(reward_data[token].period_finish);
        integral_last_update_duration[2] = integral_last_update_duration[1] - reward_data[token].last_update;

        if(integral_last_update_duration[2] != 0) {
            reward_data[token].last_update = integral_last_update_duration[1];
            if(_total_supply != 0) {
                integral_last_update_duration[0] += integral_last_update_duration[2] * reward_data[token].rate * 10**18 / _total_supply;
                reward_data[token].integral = integral_last_update_duration[0];
            }
        }

        if(_user != address(0)) {
            uint256 integral_for = reward_integral_for[token][_user];
            uint256 new_claimable = 0;

            if(integral_for < integral_last_update_duration[0]) {
                reward_integral_for[token][_user] = integral_last_update_duration[0];
                new_claimable = _user_balance * (integral_last_update_duration[0] - integral_for) / 10**18;
            }

            uint256 _claim_data = claim_data[_user][token];
            uint256 total_claimable = (_claim_data >> 128) + new_claimable;
            
            if(total_claimable > 0) {
                uint256 total_claimed = _claim_data % 2**128;
                if(_claim) {
                    IERC20(token).transfer(receiver,total_claimable);
                    claim_data[_user][token] = total_claimed + total_claimable;
                } else if(new_claimable > 0) {
                    claim_data[_user][token] = total_claimed + (total_claimable << 128);
                }
            }
        }

        if(token == LUCAX) {
            integrate_checkpoint_of[_user] = block.timestamp;
        }
    }
           
    function _checkpointRewards(
        address _user, 
        uint256 _total_supply, 
        bool _claim, 
        address _receiver, 
        bool _only_checkpoint
    ) 
        internal 
    {
        address receiver = _receiver;
        uint256 user_balance = 0;

        if(_user != address(0)) {
            user_balance = balanceOf[_user];
            if(_claim && _receiver == address(0)){
                receiver = rewards_receiver[_user];
                if(receiver == address(0)) 
                    receiver = _user;
            }
        }

        if(_only_checkpoint) {
            _checkpointReward(
                _user, 
                LUCAX, 
                _total_supply, 
                user_balance, 
                false, 
                receiver
            );
        } else {
            uint256 _reward_count = reward_count;
            for(uint i; i<MAX_REWARDS;i++) {
                if(i == _reward_count)
                    break;
                
                address token = reward_tokens[i];
                _checkpointReward(
                    _user, 
                    token, 
                    _total_supply, 
                    user_balance, 
                    _claim, 
                    receiver
                );
            }
        }
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        uint256 total_supply = totalSupply;

        if(_value != 0) {
            bool is_rewards = reward_count != 0;
            if(is_rewards) {
                _checkpointRewards(
                    _from, 
                    total_supply,
                    false, 
                    address(0), 
                    false
                );
            }

            balanceOf[_from] -= _value;
            _updateLiquidityLimit(
                _from, 
                balanceOf[_from], 
                total_supply
            );

            if(is_rewards) {
                _checkpointRewards(
                    _to, 
                    total_supply, 
                    false, 
                    address(0), 
                    false
                );
            }

            balanceOf[_to] += _value;
            _updateLiquidityLimit(
                _to, 
                balanceOf[_to], 
                total_supply
            );
        }
        else {
            _checkpointRewards(
                _from, 
                total_supply, 
                false, 
                address(0), 
                true
            );

            _checkpointRewards(
                _to, 
                total_supply, 
                false, 
                address(0), 
                true
            );
        }

        emit Transfer(_from, _to, _value);
    }

    function _safeTransferFrom(address token, address _from, address _to, uint _amount) internal {
        IERC20(token).safeTransferFrom(_from, _to, _amount);
    }
}