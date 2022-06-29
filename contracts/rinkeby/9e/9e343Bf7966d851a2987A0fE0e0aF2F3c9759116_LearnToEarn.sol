// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT - reduce size of uints/ immutable

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient) external;
}

interface ILearnToken {
    function mintToken(address recipient, uint256 amount) external;

    function transferOwnershipToken(address newOwner) external;
}

contract LearnToEarn is KeeperCompatibleInterface {
    IERC20 private immutable aWNative;
    IAaveInteraction private immutable aave;
    ILearnToken private immutable LearnToken;

    // Change the below visibility to private 4444444444444444
    address[] public students;
    mapping(address => uint) private index;
    mapping(address => uint) private initialDeposit;
    mapping(address => uint) private interestEarned;
    mapping(address => uint) private recordedStartDay; // for payout
    mapping(address => uint) private pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106
    mapping(address => uint) private pingCount; // to track student progress for frontend

    address private owner;
    address private AaveInteraction;
    uint private depositTotal;
    uint public interval;
    uint private todayUTC0;
    uint private prevATokenBal;
    uint private curATokenBal;

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    constructor(
        address _AaveInteractionAddress,
        address _tokenAddress,
        address _LEARNAddress,
        uint _interval
    ) {
        AaveInteraction = _AaveInteractionAddress;
        aave = IAaveInteraction(_AaveInteractionAddress);
        aWNative = IERC20(_tokenAddress);
        LearnToken = ILearnToken(_LEARNAddress);

        owner = msg.sender;
        // Pass in number of seconds (day = 86400)
        interval = _interval;
        // Get most recent start period (midnight)
        todayUTC0 = (block.timestamp / interval) * interval;
    }

    // DelegateCall 4444444444
    function transferOwnership(address newOwner) external onlyOwner {
        LearnToken.transferOwnershipToken(newOwner);
    }

    // For AaveInteraction to get data from this contract's mapping, a getter function MUST be used
    function getWithdrawAmount(address stu) external view returns (uint) {
        return (interestEarned[stu] + initialDeposit[stu]);
    }

    function getPingCount(address stu) external view returns (uint) {
        return pingCount[stu];
    }

    function getStudentStatus(address stu) public view returns (bool) {
        return recordedStartDay[stu] == 0 ? false : true;
    }

    function register() external payable {
        require(
            getStudentStatus(msg.sender) == false,
            "You are already registered"
        );
        // This stops divide by 0 error
        require(msg.value > 0, "Not enough funds deposited");

        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add student data to mappings
        addStudent(msg.sender);

        // Ping is active for rest of interval + 1 interval
        ping();

        //Deposit user funds through AaveInteraction
        aave.deposit{value: msg.value}();

        // Give users LEARN for registering
        LearnToken.mintToken(msg.sender, msg.value * 2);

        // Update prevATokenBal for next calcInterestPrevPeriod()
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    function payout() external {
        calcInterestPrevPeriod();

        depositTotal -= initialDeposit[msg.sender];
        aave.withdraw(msg.sender);
        removeStudent(msg.sender);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    // tUTC0 updates each `interval`
    // Ping emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //      tUTC0      +1     +2
    function ping() public {
        require(
            getStudentStatus(msg.sender) == true,
            "You must be registered to ping"
        );
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);
        pingCount[msg.sender] += 1; // update pingCount for frontend
        LearnToken.mintToken(msg.sender, 1);
    }

    // CHAINLINK KEEPER
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp - todayUTC0) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        // Re-validation check
        if ((block.timestamp - todayUTC0) > interval) {
            todayUTC0 += interval;
            calcInterestPrevPeriod();
            // prevATokenBal updated to curATokenBal as no funds are added
            prevATokenBal = curATokenBal;
        }
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    function calcInterestPrevPeriod() internal {
        curATokenBal = aWNative.balanceOf(AaveInteraction);
        uint interestPrevPeriod = curATokenBal - prevATokenBal; // always 0 or greater

        uint unclaimedInterest;
        uint unclaimedDepositTotal;

        // If inactive, accumulate funds to re-distribute
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            if (pingExpiresAt[student] < block.timestamp) {
                unclaimedInterest +=
                    (interestPrevPeriod * deposit) /
                    depositTotal;
                unclaimedDepositTotal += deposit;
            }
        }

        // If active, student gets default and unclaimed share
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            if (depositTotal > unclaimedDepositTotal) {
                if (pingExpiresAt[student] >= block.timestamp) {
                    // default share
                    interestEarned[student] +=
                        (interestPrevPeriod * deposit) /
                        depositTotal;
                    // share of unclaimed
                    interestEarned[student] +=
                        (unclaimedInterest * deposit) /
                        (depositTotal - unclaimedDepositTotal);
                }
            }
        }
    }

    function addStudent(address stu) private {
        // for itterable mapping
        index[stu] = students.length;
        students.push(stu);

        // for interest calculations
        initialDeposit[stu] = msg.value;
        depositTotal += msg.value;

        // For payout
        recordedStartDay[stu] = todayUTC0 + interval;
    }

    function removeStudent(address stu) private {
        uint delStudentIndex = index[stu];
        delete index[stu];
        delete initialDeposit[stu];
        delete interestEarned[stu];
        delete recordedStartDay[stu];
        delete pingExpiresAt[stu];
        delete pingCount[stu];

        // Replace deleted Stu with last Stu
        students[delStudentIndex] = students[students.length - 1];
        // Update the moved student's index
        address endStuAddress = students[students.length - 1];
        index[endStuAddress] = delStudentIndex;
        // Remove dead space
        students.pop();

        // // Visual demo:
        // [address0, address1, address2, address3, address4]
        // // Remove a2 and move a4 into it's slot
        // [address0, address1, address4, address3]
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