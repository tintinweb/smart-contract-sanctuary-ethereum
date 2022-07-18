/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-25
 */

//library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

contract staticStakingContract {
    //////////// CHANGES IN CONTRACT ////////////////

    //////// Change DURATION according to your needs //////////
    uint256[4] public durations = [
        15 seconds,
        30 seconds,
        45 seconds,
        60 seconds
    ];


    //////// Change Percent_Reward with 2 zeros, according to your needs /////////
    // Just give percentage+00. E.g : 2 + 00 => 200 => 2% || 45 + 00 =>  4500 => 45 %          <----------------------- KEY POINT
    uint256[4] public percentReward = [400, 600, 800, 900];


    //////////////////////// CHANGES Ended. DO NOT CHANGE ANYTHING BELOW ///////////////////////////////////////////



    using SafeMath for uint256;
    using Address for address;


    IBEP20 public stakingToken; // Interface
    IBEP20 public rewardToken; // Interface

    //  Structs to record user data
    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
    }

    struct User {
        uint256 userTotalStaked;
        uint256 stakeCount;
        uint256 totalRewardTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    /////////// EVENTS //////////
    event tokenStaked(address indexed owner, uint256 indexed id);
    event tokenUnstaked(address indexed owner, uint256 indexed id);
    event minimumStakeSetted(uint256 indexed minimumStake);
    event contractLocked(bool indexed Locked);
    event contractUnlocked(bool indexed Unlocked);
    event planUpgraded(uint256 indexed userStakeCount,uint256 indexed countPlan);



    ////// Global Variables ////////
    address public owner; // owner address

    bool public isLocked = false; // regarding Contract Lock

    uint256 public minimumStake = 2000000000000000000; // 2 TOKEN WITH 18 ZEROS ( 2 - 18 ZEROS)

    uint256 public userBalanceInStakingToken;


    ////// Constructor ///////
    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender; // owner of this contract
        stakingToken = IBEP20(_stakingToken); // address of StakingToken
        rewardToken = IBEP20(_rewardToken); // address of RewardToken
    }




    ////// MAPPINGS ///////
    mapping(address => User) public users;


    //////// Main Functions ////////

    function stake(uint256 amount, uint256 plan) public {
        require(isLocked == false, "Contract is lock.");

        require(plan < durations.length, "put valid plan details");
        require(
            amount >= minimumStake,
            "cant deposit need to stake more than minimum amount"
        );
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        User storage user = users[msg.sender];

        userBalanceInStakingToken = stakingToken.balanceOf(msg.sender);

        stakingToken.transferFrom(msg.sender, owner, amount); // storing all Staking Funds in Owners account

        user.userTotalStaked += amount; // storing all amount user staked.
        user.stakerecord[user.stakeCount].plan = plan; // store chosed plan with stakeCount
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp; // stakeTime
        user.stakerecord[user.stakeCount].amount = amount; // amount
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(
            durations[plan]
        ); // withdraw time, getting from duration Array
        user.stakerecord[user.stakeCount].bonus = rewardCalculate(
            plan,
            user.stakeCount
        ); // getting Bonus based on plan from rewardCalculate function

        emit tokenStaked(msg.sender, user.stakeCount);

        user.stakeCount++; // increase user_Stake_Count
    }

    function withdraw(uint256 count) public {
        require(isLocked == false, "Contract is lock.");

        User storage user = users[msg.sender];

        require(count < user.stakeCount, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan, " withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        require(
            block.timestamp >= user.stakerecord[count].withdrawTime,
            "You cannot withdraw amount before time"
        );
        require(
            rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,
            "owner doesnt have enough balance"
        );


        uint256 totalTransferAmount = user.stakerecord[count].amount.add(user.stakerecord[count].bonus);        // plus bonus and total amount
        rewardToken.transferFrom(
            owner,
            msg.sender,
            totalTransferAmount
        ); // transfer amount from owners account to user's account

        user.stakerecord[count].withdrawan = true;
        user.totalRewardTokens += user.stakerecord[count].bonus;

        emit tokenUnstaked(msg.sender, count);
    }

    // upgradePlan
    function upgradePlan(uint256 count, uint256 plan) public returns (uint256) {
        require(isLocked == false, "Contract is lock.");

        User storage user = users[msg.sender];

        require(!user.stakerecord[count].withdrawan, " withdraw completed ");

        require(count < user.stakeCount, "Invalid Stake index");
        require(plan <= durations.length, "Enter Valid Plan");
        require(
            user.stakerecord[count].plan < plan,
            "Can not extend to lower plan"
        );

        user.stakerecord[count].plan = plan;
        user.stakerecord[count].withdrawTime = block.timestamp.add(
            durations[plan]
        );

        user.stakerecord[count].bonus = rewardCalculate(plan, count);

        emit planUpgraded(count, plan);

        return user.stakerecord[count].plan;
    }

    /////// Complementory Functions /////////

    // lock contract
    function lock() public {
        require(msg.sender == owner, "only owner can lock");
        isLocked = true;

        emit contractLocked(isLocked);
    }

    // unlock contract
    function unlock() public {
        require(msg.sender == owner, "only owner can unlock");

        isLocked = false;

        emit contractUnlocked(isLocked);
    }

    // set new minimum stake
    function setMinimumStake(uint256 amount) public {
        require(isLocked == false, "Contract is lock.");

        require(msg.sender == owner, "only owner can set");
        minimumStake = amount;

        emit minimumStakeSetted(amount);
    }

    // can Change the addresses of stakingToken & rewardToken. can also change one address, give the previous address you don't want to change 
    function setNewTokens(address newStakingToken, address newRewardToken) external {
        require(isLocked == false, "Contract is lock.");

        require(msg.sender == owner, "only owner can set");

        stakingToken = IBEP20(newStakingToken);
        rewardToken = IBEP20(newRewardToken);
    }

    // get stake details
    function stakeDetails(address add, uint256 count)
        public
        view
        returns (Stake memory)
    {
        return (users[add].stakerecord[count]);
    }

    
    ////// Reward Calculation. DO NOT CHANGE ANYTHING //////
    function rewardCalculate(uint256 plan, uint256 count)
        public
        view
        returns (uint256)
    {
        require(plan < percentReward.length, "put valid plan details");

        User storage user = users[msg.sender];

        return
            user.stakerecord[count].amount.mul(percentReward[plan]).div(10000);
    }
}