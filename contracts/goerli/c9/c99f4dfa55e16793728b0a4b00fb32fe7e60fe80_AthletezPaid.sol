/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: UNLICENSED
// We will be using Solidity version 0.8.14
pragma solidity 0.8.14;

/* ---------- START OF IMPORT SafeMath.sol ---------- */

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */

contract AthletezPaid {
    using SafeMath for uint256;

    // List of existing projects
    Project[] private projects;

    // mapping of existing athletes to their wallet addresses
    mapping (address => string) public athletez;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectAthlete,
        string projectDesc,
        string school1,
        string school2,
        string school3
    );

    /** @dev Function to start a new project.
      * @param athlete Title of the project to be created
      * @param description Brief description about the project
      */
    function startProject(
        string calldata athlete,
        string calldata description,
        string calldata school1,
        string calldata school2,
        string calldata school3
    ) external {
        Project newProject = new Project(payable(msg.sender), athlete, description, school1, school2, school3);
        projects.push(newProject);
        athletez[msg.sender] = athlete;
        emit ProjectStarted(
            address(newProject),
            msg.sender,
            athlete,
            description,
            school1,
            school2,
            school3
        );
    }

    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }

    /** @dev Function to get athlete friendly name via wallet address
      */
    function returnAthleteName(address queriedAddr) external view returns(string memory friendlyAthlete){
        friendlyAthlete = athletez[queriedAddr];
    }
}


contract Project {
    using SafeMath for uint256;

    // Data structures
    // enum State {
    //     Fundraising,
    //     Expired,
    //     Successful
    // }

    // State variables
    address payable public creator;
    address payable private servAddr = payable(0xC3E9D612C1C7Ba33Dd2f76A37Ac66Fe64D011850);
    // uint256 public currentBalance;
    // uint256 public AmtRaised;
    uint8 public authed;
    uint256 private serviceFee;
    string public athlete;
    string public description;
    // string public target;
    string public school1;
    string public school2;
    string public school3;
    // State public state = State.Fundraising; // initialize on create
    // mapping (address => uint) public contributions;
    mapping (string => mapping(address => uint)) public contributions;
    mapping (string => uint) public StateInt;
    mapping (string => uint) public TotalContrib;
    mapping (string => uint) public TotalAmtRaised;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, string school2contrib, uint amount, uint currentTotal);
    // Event that will be emitted whenever the project starter has received the funds
    event CreatorPaid(address recipient);
    // Event that will be emitted whenever refund has occurred
    event RefundPaid(address refundee, uint refundAmt);
    // Event that will be emitted whenever state changes
    event StateChange(string schoolChange, uint newState);
    // Event that will be emitted whenever campaign is authed
    event AuthUpdate(uint8 authState);
    // Event that will be emitted whenever service fee is changes
    event ServFeeUpdate(uint256 newServFee);

    // Modifier to check current state
    // modifier inState(State _state) {
    //     require(state == _state);
    //     _;
    // }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    constructor
    (
        address payable projectStarter,
        string memory projectAthlete,
        string memory projectDesc,
        string memory projectSchool1,
        string memory projectSchool2,
        string memory projectSchool3
    ) {
        creator = projectStarter;
        athlete = projectAthlete;
        description = projectDesc;
        school1 = projectSchool1;
        school2 = projectSchool2;
        school3 = projectSchool3;
        // AmtRaised = 0;
        serviceFee = 100;
        StateInt[school1] = 5;
        StateInt[school2] = 5;
        StateInt[school3] = 5;
    }

    /** @dev Function to fund a certain project.
      */
    function contribute(string memory school2contrib) external payable {
        require(msg.sender != creator);
        require(StateInt[school2contrib] == 5);
        uint256 contribAmt = 0;
        uint256 feeAmt = 0;
        feeAmt = msg.value.div(serviceFee);
        contribAmt = msg.value.sub(feeAmt);
        contributions[school2contrib][msg.sender] = contributions[school2contrib][msg.sender].add(contribAmt);
        TotalContrib[school2contrib] = TotalContrib[school2contrib].add(contribAmt);
        //currentBalance = currentBalance.add(contribAmt);
        emit FundingReceived(msg.sender, school2contrib, msg.value, contribAmt);
        servAddr.transfer(feeAmt);
    }

    /** @dev Function to give the received funds to project starter.
      */
    function payOut(string memory school2service) internal returns (bool) {
        require(StateInt[school2service] == 2);
        uint256 payoutAmt = 0;
        uint256 feeAmt = 0;
        feeAmt = TotalContrib[school2service].div(serviceFee);
        payoutAmt = TotalContrib[school2service].sub(feeAmt);
        uint256 totalRaised = payoutAmt;
        TotalContrib[school2service] = 0;

        if (creator.send(totalRaised)) {
            emit CreatorPaid(creator);
            servAddr.transfer(feeAmt);
            return true;
        } else {
            TotalContrib[school2service] = totalRaised;
            StateInt[school2service] = 2;
        }

        return false;
    }

    /** @dev Function getRefund to retrieve donated amount when a project expires.
      */
    function getRefund(string calldata school2refund) public returns (bool) {
        require(StateInt[school2refund] == 1);
        require(contributions[school2refund][msg.sender] > 0);
        uint256 payoutAmt = 0;
        uint256 feeAmt = 0;
        feeAmt = contributions[school2refund][msg.sender].div(serviceFee);
        uint amountToRefund = contributions[school2refund][msg.sender];
        payoutAmt = amountToRefund - feeAmt;
        contributions[school2refund][msg.sender] = 0;

        if (!payable(msg.sender).send(payoutAmt)) {
            contributions[school2refund][msg.sender] = amountToRefund;
            return false;
        } else {
            emit RefundPaid(msg.sender, payoutAmt);
            servAddr.transfer(feeAmt);
            TotalContrib[school2refund] = TotalContrib[school2refund].sub(amountToRefund);
        }

        return true;
    }

    /** @dev Function expireCampaign force campaign to expire.
      */
    function expireCampaign(string calldata school2service) public returns (bool) {
        // address expAddr = 0x279EaC0638d37C857DdcEa92ad523b97d44576c7;
        require(msg.sender == servAddr);
        require(StateInt[school2service] == 5);
        StateInt[school2service] = 1;
        emit StateChange(school2service, 1);
        TotalAmtRaised[school2service] = TotalContrib[school2service];
        return true;
    }

    /** @dev Function successfulCampaign force campaign to success.
      */
    function successfulCampaign(string calldata school2success) public returns (bool) {
        // address successAddr = 0x711c857aeFFE607Ea8e0374E1136EF0a3469608a;
        require(msg.sender == servAddr);
        require(StateInt[school2success] == 5);
        StateInt[school2success] = 2;
        emit StateChange(school2success, 2);
        TotalAmtRaised[school2success] = TotalContrib[school2success];
        payOut(school2success);
        return true;
    }

    /** @dev Function authorizeCampaign authorizes a valid campaign/project starter.
      */
    function authorizeCampaign() public returns (bool) {
        // address authAddr = 0xef07Cc20B80F0171F6392521bb730Ca754Bc42d0;
        require(msg.sender == servAddr);
        authed = 1;
        emit AuthUpdate(authed);
        return true;
    }

    /** @dev Function adjustServiceFee adjusts the default 1% service fee.
      */
    function adjustServiceFee(uint256 newServFee) public returns (bool) {
        // address authAddr = 0xef07Cc20B80F0171F6392521bb730Ca754Bc42d0;
        require(msg.sender == servAddr);
        //should be submitted as a percent!
        uint256 numerator = 100;
        serviceFee = numerator.div(newServFee);
        emit ServFeeUpdate(serviceFee);
        return true;
    }

    function getDetails() public view returns
    (
        address payable projectStarter,
        string memory projectAthlete,
        string memory projectDesc,
        string memory projectSchool1,
        string memory projectSchool2,
        string memory projectSchool3,
        uint8 Authed,
        uint256 theServiceFee,
        uint amtRaized1,
        uint amtRaized2,
        uint amtRaized3,
        uint totalInContract
    ) {
        projectStarter = creator;
        projectAthlete = athlete;
        projectDesc = description;
        projectSchool1 = school1;
        projectSchool2 = school2;
        projectSchool3 = school3;
        Authed = authed;
        theServiceFee = serviceFee;
        amtRaized1 = TotalContrib[school1];
        amtRaized2 = TotalContrib[school2];
        amtRaized3 = TotalContrib[school3];
        totalInContract = TotalContrib[school1] + TotalContrib[school2] + TotalContrib[school3];
    }
}