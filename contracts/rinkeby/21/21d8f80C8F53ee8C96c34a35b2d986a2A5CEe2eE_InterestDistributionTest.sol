// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient, uint _withdrawAmount) external;
}

contract InterestDistributionTest is KeeperCompatibleInterface {
    // Testing
    // uint public interestPrevPeriod;
    // uint public totalAwarded;

    // Could neaten these up by using a struct, nested mapping ,iterable mapping??? 4444444444444444444444
    address[] public students;
    mapping(address => uint) initialDeposit;
    mapping(address => uint) interestEarned;
    uint public depositTotal;
    mapping(address => uint) recordedStartDay; // for payout
    mapping(address => uint) pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106
    uint public currentTime = block.timestamp;

    uint public todayUTC0;
    IERC20 aPolWNative = IERC20(0x608D11E704baFb68CfEB154bF7Fd641120e33aD4);

    // Interface requires the correct deployed address for AaveInteraction contract (maybe pass through constructor??) 4444444444444444
    // Create js file for complex constructor arguments 4444444444444444
    address AaveInteraction = 0x57F1d07e453bae3B0B155e0dedc08E2D5946Fe35;
    IAaveInteraction aave = IAaveInteraction(AaveInteraction);

    uint public interval = 120 seconds; // maybe uint32
    uint public intervalDoubled = 2 * interval;

    constructor(uint _todayUTC0) payable {
        todayUTC0 = _todayUTC0;
        // for contract to have some gas(maybe not needed)
        // deposit{value: msg.value}();
        // Currently payable. Not necessary if all gas is passed to user
    }

    uint public prevATokenBal;
    uint public curATokenBal;

    function register() external payable {
        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add new student
        students.push(msg.sender);
        initialDeposit[msg.sender] = msg.value;
        depositTotal += msg.value;

        // For payout
        // recordedStartDay[msg.sender] = todayUTC0 + 1 days;
        recordedStartDay[msg.sender] = todayUTC0 + interval;

        // ping active for rest of day + 1 days
        ping();

        //Deposit user funds into Aave
        aave.deposit{value: msg.value}();

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWNative.balanceOf(AaveInteraction);
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    uint public interestPrevPeriod;

    function calcInterestPrevPeriod() internal {
        curATokenBal = aPolWNative.balanceOf(AaveInteraction);
        interestPrevPeriod = curATokenBal - prevATokenBal;

        uint unclaimedInterest;
        uint unclaimedDepositTotal;

        // If inactive, accumulate funds to re-distribute
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            uint studentShare = deposit / depositTotal;

            if (currentTime - pingExpiresAt[student] > 0) {
                unclaimedInterest += interestPrevPeriod * studentShare;
                unclaimedDepositTotal += deposit;
            }
        }

        // If active, student gets default and unclaimed share
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            uint studentShare = deposit / depositTotal;
            uint studentShareUnclaimed = deposit /
                (depositTotal - unclaimedDepositTotal);

            if (pingExpiresAt[student] - currentTime >= 0) {
                // default share
                interestEarned[student] += interestPrevPeriod * studentShare;
                // share of unclaimed
                interestEarned[student] +=
                    unclaimedInterest *
                    studentShareUnclaimed;

                // Testing
                // totalAwarded += interestPrevPeriod * studentShare;
            }
        }
    }

    // tUTC0 updates each 24hr period
    // ping  emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //     tUTC0      +1     +2
    function ping() public {
        // pingExpiresAt[msg.sender] = todayUTC0 + 2 days;
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);
    }

    // KEEPER check for 24hr

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (currentTime - todayUTC0) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        // Re-validation check
        if ((currentTime - todayUTC0) > interval) {
            todayUTC0 += interval;
            calcInterestPrevPeriod();
            prevATokenBal = curATokenBal;
        }
    }

    // function performUpkeep(bytes calldata) external override {
    //     // Re-validation check
    //     // if ((block.timestamp - todayUTC0) > interval) {
    //     // Could automate todayUTC0 with % ?? where upkeep handles all time parameters 4444444444444444
    //     // todayUTC0 += 1 days;
    //     todayUTC0 += interval;
    //     // calcInterestPrevPeriod();
    //     // the previous balance is updated to the Current balance as no additional funds are added (as in recipient)
    //     // prevATokenBal = curATokenBal;
    //     // }
    // }

    function payout() external {
        // add security checks 4444444444444444444
        // recordedStartDay UTC0 + number of study days
        // require(
        //     block.timestamp >= (recordedStartDay[msg.sender] + 20 minutes),
        //     // (recordedStartDay[msg.sender] + (4 * studyPeriodDuration)),
        //     "You can only receive a payout once the study session is over"
        // );
        calcInterestPrevPeriod();

        uint withdrawAmount = interestEarned[msg.sender] +
            initialDeposit[msg.sender];
        depositTotal -= initialDeposit[msg.sender];
        interestEarned[msg.sender] = 0;
        initialDeposit[msg.sender] = 0;
        // REMOVE student from array/struct 444444444444444444444

        // Is there a safer way to do this?? withdraw doesn't seem to return an uint/ or any value...
        // this withdraws funds to AaveInteraction
        aave.withdraw(msg.sender, withdrawAmount);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWNative.balanceOf(AaveInteraction);
    }

    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING

    // Check the AdminContract/User balance
    function getBalance(address tokenHolder) external view returns (uint) {
        return aPolWNative.balanceOf(tokenHolder);
    }

    function getInterestEarnedOfUser(address student)
        external
        view
        returns (uint)
    {
        return interestEarned[student];
    }

    function getInitialDepositOfUser(address student)
        external
        view
        returns (uint)
    {
        return initialDeposit[student];
    }

    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING
}
// on deployment of contract send some funds into aave (surplus funds will be added to this??)
// user registers, their funds go into aave
// store their initial deposit in a mapping
// have an array of Struct which contains student address, this will allow awards to be given to users (maybe just array)
// keeper will update user interest earnings based on their proportional deposited funds
// keeper will check the ping status of each user in the array
// if the ping status is true award funds
// ping at any stage in a 24hr period to earn interest for the next 24hr period (use the Official start plus x days)

// aave protocal aToken balance can only increase, so each keeper update will distribute funds (but is this accurate?? I can test this once set up. if not accurate withdraw then redeposit)
// users can withdraw funds at any time, any forefitted earning go to procol
// the next 24hr period they click ping and they become elidgable for reward

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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}