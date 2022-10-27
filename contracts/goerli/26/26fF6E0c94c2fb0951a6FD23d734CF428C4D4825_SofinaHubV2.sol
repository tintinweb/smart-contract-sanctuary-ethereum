// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/ISofinaHub.sol";
import "../Project/Project.sol";
import "../Project/interfaces/IProject.sol";

contract SofinaHubV2 is ISofinaHub {
    /// @dev owner
    address private _owner;

    uint256 public numOfProjects;

    mapping(uint256 => address) public projects;

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "[SOFINAHUB]: Only SofinaHub can call this method."
        );
        _;
    }

    constructor() {
        _owner = msg.sender;
        numOfProjects = 0;
    }

    /// @dev returns the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev
    /// Create a new Project contract
    /// [0] -> new Project contract address
    function create(SofinaHubOptions memory sofinaHub)
        public
        returns (IProject projectAddress)
    {
        // check project funding goal is greater than 0
        require(
            sofinaHub.fundingGoal > 0,
            "[SOFINAHUB]: Project funding goal must be greater than 0"
        );

        // check project deadline is greater than the current block
        require(
            block.number < sofinaHub.deadline,
            "[SOFINAHUB]: Project deadline must be greater than the current block"
        );

        IProject p = new Project(
            IProject.ProjectOptions(
                sofinaHub.fundingGoal,
                sofinaHub.deadline,
                sofinaHub.title,
                sofinaHub.description,
                payable(msg.sender),
                sofinaHub.images,
                sofinaHub.videos,
                sofinaHub.documents,
                sofinaHub.roi,
                sofinaHub.roiDuration,
                sofinaHub.tokenName,
                sofinaHub.tokenSymbol,
                sofinaHub.tokenDecimal,
                sofinaHub.tokenTotalSupply
            )
        );

        projects[numOfProjects] = address(p);

        emit LogProjectCreated(
            numOfProjects,
            sofinaHub.title,
            address(p),
            msg.sender
        );
        numOfProjects++;

        return p;
    }

    /// @dev
    /// Allow senders to contribute to a Project by it's address. Calls the fund() function in
    /// the Project contract and passes on all value attached to this function call
    /// [0] -> contribution was sent.
    function contribute(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        // check amount sent is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB]: Contributions must be greater than 0 wei"
        );

        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that fund call was successful
        if (deployedProject.fund{value: msg.value}(payable(msg.sender))) {
            emit LogContributionSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Contribution did not send successfully"
            );

            return false;
        }
    }

    /// @dev
    /// Allow contributor to withdraw their funds if funding cap not reached. Calls the refund()
    /// function in the Project contract and passes on all value attached to this function call.
    /// [0] -> contribution was sent.
    function refund(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that refund call was successful
        if (deployedProject.refund(payable(msg.sender))) {
            emit LogRefundSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure("[SOFINAHUB]: Refund did not send successfully");

            return false;
        }
    }

    /// @dev
    function deposit(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        // check amount sent is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB]: Project capital and ROI must be greater than 0 wei"
        );

        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that deposit call was successful
        if (deployedProject.deposit{value: msg.value}(payable(msg.sender))) {
            emit LogDepositSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Project capital and ROI funds are not completed"
            );

            return false;
        }
    }

    function claim(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that claim call was successful
        if (deployedProject.claim(payable(msg.sender))) {
            emit LogClaimSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure("[SOFINAHUB]: Claim did not send successfully");

            return false;
        }
    }

    /// @dev
    /// Verify property against scamming project
    function toggleVerify(address payable _projectAddress)
        public
        onlyOwner
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // toggle verification
        if (deployedProject.toggleVerify()) {
            emit LogToggleVerificationSent(
                "[SOFINAHUB]: Verification sent successfully"
            );

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Verification did not send successfully"
            );

            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    /// @dev Tranfer and Approval events

    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// @dev another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by
    /// @dev a call to {approve}. `value` is the new allowance.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev get the name of the token
    function name() external view returns (string memory);

    /// @dev get the symbol of the token
    function symbol() external view returns (string memory);

    /// @dev get the decimals of the token
    function decimals() external view returns (uint8);

    /// @dev get the total tokens in supply
    function totalSupply() external view returns (uint256);

    /// @dev get balance of an account
    function balanceOf(address account) external view returns (uint256);

    /// @dev approve address/contract to spend a specific amount of token
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev get the remaining amount approved for address/contract
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @dev send token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev automate sending of token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev
    ///
    function sendReward(address contributor, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IERC20.sol";

contract Token is IERC20 {
    /// @dev name of the token
    string public name;

    /// @dev symbol of the token
    string public symbol;

    /// @dev decimal place the amount of the token will be calculated
    uint8 public decimals;

    /// @dev total supply
    uint256 public totalSupply;

    /// @dev owner of the token
    address public owner;

    /// @dev create a table so that we can map addresses to the balances associated with them
    mapping(address => uint256) balances;

    /// @dev create a table so that we can map the addresses of contract owners to those
    /// @dev who are allowed to utilize the owner's contract
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev run during the deployment of smart contract
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _owner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10**_decimals);
        owner = _owner;

        balances[owner] = totalSupply;
    }

    /// @dev get balance of an account
    function balanceOf(address account) public view override returns (uint256) {
        // return the balance for the specific address
        return balances[account];
    }

    /// @dev approve address/contract to spend a specific amount of token
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;

        // fire the event "Approval" to execute any logic
        // that was listening to it
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @dev get the remaining amount approved for address/contract
    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][spender];
    }

    /// @dev send token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        // if the sender has sufficient funds to send
        // and the amount is not zero, then send to
        // the given address
        if (
            balances[msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(msg.sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /// @dev automate sending of token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (
            balances[sender] >= amount &&
            allowed[sender][msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /// @dev
    ///
    function sendReward(address contributor, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        transfer(contributor, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../../Project/interfaces/IProject.sol";

interface ISofinaHub {
    struct SofinaHubOptions {
        uint256 fundingGoal;
        uint256 deadline;
        string title;
        string description;
        string[] images;
        string[] videos;
        string[] documents;
        uint256 roi;
        uint256 roiDuration;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimal;
        uint256 tokenTotalSupply;
    }

    event LogProjectCreated(
        uint256 id,
        string title,
        address addr,
        address creator
    );

    event LogContributionSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogDepositSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogRefundSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogClaimSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogToggleVerificationSent(string message);

    event LogFailure(string message);

    /// @dev
    function create(SofinaHubOptions memory sofinaHub)
        external
        returns (IProject projectAddress);

    /// @dev
    function contribute(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function refund(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function deposit(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function claim(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function toggleVerify(address payable _projectAddress)
        external
        returns (bool successful);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.15;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IProject {
    struct ProjectOptions {
        uint256 _fundingGoal;
        uint256 _deadline;
        string _title;
        string _description;
        address payable _creator;
        string[] _images;
        string[] _videos;
        string[] _documents;
        uint256 _roi;
        uint256 _roiDuration;
        string _tokenName;
        string _tokenSymbol;
        uint8 _tokenDecimal;
        uint256 _tokenTotalSupply;
    }

    struct Properties {
        uint256 goal;
        uint256 deadline;
        string title;
        string description;
        address payable creator;
        string[] images;
        string[] videos;
        string[] documents;
        uint256 roi;
        uint256 roiDuration;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimal;
        uint256 tokenTotalSupply;
        address tokenAddress;
        bool verified;
    }

    struct Contribution {
        uint256 amount;
        address contributor;
    }

    event LogContributionReceived(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogPayoutInitiated(
        address projectAddress,
        address owner,
        uint256 totalPayout
    );

    event LogRefundIssued(
        address projectAddress,
        address contributor,
        uint256 refundAmount
    );

    event LogFundingGoalReached(
        address projectAddress,
        uint256 totalFunding,
        uint256 totalContributions
    );

    event LogFundingFailed(
        address projectAddress,
        uint256 totalFunding,
        uint256 totalContributions
    );

    event LogDeposited(string message, uint256 amount);

    event LogClaimSent(
        address projectAddress,
        address contributor,
        uint256 refundAmount
    );

    event LogFailure(string message);

    /// @dev
    function getProject()
        external
        view
        returns (
            Properties memory,
            uint256,
            uint256,
            uint256,
            address,
            address
        );

    /// @dev
    function getContribution(uint256 _id)
        external
        view
        returns (uint256, address);

    /// @dev
    function fund(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function payout() external payable returns (bool successful);

    /// @dev
    function refund(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function deposit(address payable _creator)
        external
        payable
        returns (bool successful);

    /// @dev
    function claim(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function toggleVerify() external returns (bool successful);

    /// @dev
    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IProject.sol";
import "../Token/Token.sol";
import "../Token/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract Project is IProject {
    using SafeMath for uint256;

    address public sofinaHub;
    address public projectToken;

    mapping(address => uint256) public contributors;
    mapping(uint256 => Contribution) public contributions;

    uint256 public totalFunding;
    uint256 public contributionsCount;
    uint256 public contributorsCount;

    Properties public properties;

    ///
    modifier onlySofinaHub() {
        require(
            sofinaHub == msg.sender,
            "[SOFINAHUB]: Only SofinaHub can call this method."
        );
        _;
    }

    ///
    modifier onlyFundCapReached() {
        require(
            totalFunding >= properties.goal,
            "[SOFINAHUB_PROJECT]: Fund withdrawal is currently not available."
        );
        _;
    }

    ///
    constructor(ProjectOptions memory project) {
        // check to see the funding goal is greater than 0
        require(
            project._fundingGoal > 0,
            "[SOFINAHUB_PROJECT]: Project funding goal must be greater than 0 wei"
        );

        // check to see the deadline is in the future
        require(
            block.number < project._deadline,
            "[SOFINAHUB_PROJECT]: Project deadline must be greater than the current block"
        );

        // Check to see that a creator (payout) address is valid
        require(
            project._creator != address(0),
            "[SOFINAHUB_PROJECT]: Project must include a valid creator address e.g burner address not allowed"
        );

        sofinaHub = msg.sender;

        // create project token
        IERC20 projectTokenAddress = new Token(
            project._tokenName,
            project._tokenSymbol,
            project._tokenDecimal,
            project._tokenTotalSupply,
            address(this)
        );

        // initialize properties struct
        properties = Properties(
            project._fundingGoal,
            project._deadline,
            project._title,
            project._description,
            project._creator,
            project._images,
            project._videos,
            project._documents,
            project._roi,
            project._roiDuration,
            project._tokenName,
            project._tokenSymbol,
            project._tokenDecimal,
            project._tokenTotalSupply,
            address(projectTokenAddress),
            false
        );

        totalFunding = 0;
        contributionsCount = 0;
        contributorsCount = 0;
    }

    /// @dev
    /// Project values are indexed in return value:
    /// [0] -> Project.properties
    /// [1] -> Project.totalFunding
    /// [2] -> Project.contributionsCount
    /// [3] -> Project.contributorsCount
    /// [4] -> Project.sofinaHub
    /// [5] -> Project (address)
    function getProject()
        public
        view
        returns (
            Properties memory,
            uint256,
            uint256,
            uint256,
            address,
            address
        )
    {
        return (
            properties,
            totalFunding,
            contributionsCount,
            contributorsCount,
            sofinaHub,
            address(this)
        );
    }

    /// @dev
    /// Retrieve indiviual contribution information
    /// Contribution.amount
    /// Contribution.contributor
    function getContribution(uint256 _id)
        public
        view
        returns (uint256, address)
    {
        Contribution memory c = contributions[_id];
        return (c.amount, c.contributor);
    }

    /// @dev
    /// This is the function called when the sofinaHub receives a contribution.
    /// If the contribution was sent after the deadline of the project passed,
    /// or the full amount has been reached, the function must return the value
    /// to the originator of the transaction.
    /// If the full funding amount has been reached, the function must call payout.
    /// [0] -> contribution was made
    function fund(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // check amount is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB_PROJECT]: Funding contributions must be greater than 0 wei"
        );

        // check that the project dealine has not passed
        if (block.number > properties.deadline) {
            emit LogFundingFailed(
                address(this),
                totalFunding,
                contributionsCount
            );

            require(
                _contributor.send(msg.value),
                "[SOFINAHUB_PROJECT]: Project deadline has passed, problem returning contribution"
            );

            return false;
        }

        // check that funding goal has not already been met
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );

            require(
                _contributor.send(msg.value),
                "[SOFINAHUB_PROJECT]: Project deadline has passed, problem returning contribution"
            );

            return false;
        }

        // determine if this is a new contributor
        uint256 prevContributionBalance = contributors[_contributor];

        // Add contribution to contributions map
        Contribution storage c = contributions[contributionsCount];
        c.contributor = _contributor;
        c.amount = msg.value;

        // Update contributor's balance
        contributors[_contributor] += msg.value;

        totalFunding += msg.value;
        contributionsCount++;

        // Check if contributor is new and if so increase count
        if (prevContributionBalance == 0) {
            contributorsCount++;
        }

        emit LogContributionReceived(address(this), _contributor, msg.value);

        // send token to contributor
        IERC20 token = Token(properties.tokenAddress);

        // send reward to contributor
        token.sendReward(
            _contributor,
            (msg.value /
                (
                    properties.goal.div(
                        properties.tokenTotalSupply *
                            10**properties.tokenDecimal
                    )
                ))
        );

        // Check again to see whether the last contribution met the fundingGoal
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );

            payout();
        }

        return true;
    }

    /// @dev
    /// If funding goal has been met, transfer fund to project creator
    /// [0] -> payout was successful
    function payout()
        public
        payable
        onlyFundCapReached
        returns (bool successful)
    {
        uint256 amount = totalFunding;

        if (properties.creator.send(amount)) {
            return true;
        } else {
            totalFunding = amount;

            return false;
        }
    }

    /// @dev
    /// If the deadline is passed and the goal was not reached, allow contributors to withdraw
    /// their contributions.
    /// [0] -> refund was successful
    function refund(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // check that the project dealine has passed
        require(
            block.number > properties.deadline,
            "[SOFINAHUB_PROJECT]: Refund is only possible if project is past deadline"
        );

        // check that funding goal has not already been met
        require(
            totalFunding < properties.goal,
            "[SOFINAHUB_PROJECT]: Refund is not possible if project has met goal"
        );

        // token
        IERC20 token = Token(properties.tokenAddress);

        // contributor token balance
        uint256 balance = token.balanceOf(_contributor);

        // check if the contributor token balance is greater than zero
        require(
            balance > 0,
            "[SOFINAHUB_PROJECT]: Contributor token balance must be greater than zero"
        );

        uint256 amount = contributors[_contributor];

        // prevent re-entrancy attack
        contributors[_contributor] = 0;

        // transfer the rewarded token to this project
        token.transferFrom(_contributor, address(this), balance);

        if (payable(_contributor).send(amount)) {
            emit LogRefundIssued(address(this), _contributor, amount);

            return true;
        } else {
            contributors[_contributor] = amount;

            emit LogFailure(
                "[SOFINAHUB_PROJECT]: Refund did not send successfully"
            );
            return false;
        }
    }

    /// @dev
    function deposit(address payable _creator)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        require(
            properties.creator == _creator,
            "[SOFINAHUB_PROJECT]: You're not the creator of this project"
        );

        require(
            block.number >= properties.roiDuration,
            "[SOFINAHUB_PROJECT]: Project ROI duration hasn't been reached to start disbursement"
        );

        uint256 expectedFunds = properties
            .roi
            .div(100)
            .mul(properties.goal)
            .add(properties.goal);

        if (msg.value < expectedFunds) {
            // return funds to creator
            require(
                _creator.send(msg.value),
                "[SOFINAHUB_PROJECT]: Problem returning creator fund"
            );

            return false;
        }

        emit LogDeposited(
            "[SOFINAHUB_PROJECT]: Project capital and ROI funds deposited successfully",
            expectedFunds
        );

        return true;
    }

    /// @dev
    function claim(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // token
        IERC20 token = Token(properties.tokenAddress);

        // contributor token balance
        uint256 balance = token.balanceOf(_contributor);

        // check if the contributor token balance is greater than zero
        require(
            balance > 0,
            "[SOFINAHUB_PROJECT]: Contributor token balance must be greater than zero"
        );

        // capital and roi
        uint256 capital = properties
            .goal
            .div(properties.tokenTotalSupply * 10**properties.tokenDecimal)
            .mul(balance);

        // [properties.roi.div(100).mul(capital)] = 0
        uint256 roi = capital.mul(properties.roi).div(100);

        // transfer the rewarded token to this project
        token.transferFrom(_contributor, address(this), balance);

        if (payable(_contributor).send(capital.add(roi))) {
            emit LogClaimSent(address(this), _contributor, capital.add(roi));

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB_PROJECT]: Claim did not send successfully"
            );
            return false;
        }
    }

    /// @dev
    function toggleVerify() public onlySofinaHub returns (bool successful) {
        properties.verified = !properties.verified;

        return true;
    }

    /// @dev Don't allow Ether to be sent blindly to this contract
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}