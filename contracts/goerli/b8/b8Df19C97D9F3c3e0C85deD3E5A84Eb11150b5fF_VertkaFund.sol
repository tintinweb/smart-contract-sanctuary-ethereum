// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Imports
//import "hardhat/console.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//import "./VertkaToken.sol";

// Errors
error VertkaToken__NotOwner();
error VertkaToken__NotEnoughAmount();
error VertkaFund__NotOwner();
error VertkaFund__StartTimeNeed2BeFuture();
error VertkaFund__EndTimeNeed2BeFuture();
error VertkaFund__EndTimeOverExpireTime();
error VertkaFund__CampaignStarted();
error VertkaFund__CampaignClaimed();
error VertkaFund__NotStarted();
error VertkaFund__Ended();
error VertkaFund__PenaltyFivePerc();
error VertkaFund__GoalNotReached();
error VertkaFund__NotEnoughAmount();
error VertkaFund__AmountAboveBalance();

// Interfaces
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function fundContract() external payable;

    function registerFunder(address funder, uint256 amountFunded) external;

    function getAmountFunded(address funder) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event IncreasedAllowance(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Contracts
contract VertkaToken is IERC20 {
    // Type Declarations
    using SafeMath for uint256;

    // Events
    event Received(
        address indexed funder,
        uint256 prevFunded,
        uint256 addFunded,
        uint256 totalFunded
    );
    //    event IncreasedAllowance(address indexed owner, address indexed spender, uint256 value);
    //    event Approved(address indexed owner, address indexed spender, uint256 value);
    //    event TransferedFrom(address indexed from, address indexed to, uint256 value);

    // State Variables
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) private s_addressToAmountFunded;
    uint256 public initialSupply;
    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert VertkaToken__NotOwner();
        _;
    }

    // Constructor
    constructor(
        address owner,
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) {
        i_owner = payable(owner);
        balances[owner] = _initialSupply;
        //        mint(msg.sender, initialSupply);
        initialSupply = _initialSupply;
        _totalSupply = initialSupply;
        name = _name;
        symbol = _symbol;
    }

    // Functions
    function fundContract() public payable {
        uint256 prevFunded = s_addressToAmountFunded[msg.sender];
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[
            msg.sender
        ].add(msg.value);
        s_funders.push(msg.sender);
        emit Received(
            msg.sender,
            prevFunded,
            msg.value,
            s_addressToAmountFunded[msg.sender]
        );
    }

    function registerFunder(address funder, uint256 amountFunded) external {
        uint256 prevFunded = s_addressToAmountFunded[funder];
        s_addressToAmountFunded[funder] = s_addressToAmountFunded[funder].add(
            amountFunded
        );
        s_funders.push(funder);
        emit Received(
            funder,
            prevFunded,
            amountFunded,
            s_addressToAmountFunded[funder]
        );
    }

    function getAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[i_owner]);
        require(numTokens <= s_addressToAmountFunded[receiver]);
        balances[i_owner] = balances[i_owner].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(i_owner, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint)
    {
        return allowed[owner][delegate];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        approve(spender, allowance(msg.sender, spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "VertkaToken: decreased allowance below zero"
        );
        unchecked {
            approve(spender, currentAllowance.sub(subtractedValue));
        }
        return true;
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][buyer]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][buyer] = allowed[owner][buyer].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal onlyOwner {
        require(to != address(0), "VertkaToken: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function _burn(address from, uint256 amount) internal onlyOwner {
        require(from != address(0), "VertkaToken: burn from the zero address");
        uint256 accountBalance = balances[from];
        require(
            accountBalance >= amount,
            "VertkaToken: burn amount exceeds balance"
        );

        unchecked {
            balances[from] = balances[from].sub(amount);
        }
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }

    function transferETH(address payable _to, uint256 _amountToTransfer)
        internal
        onlyOwner
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: _amountToTransfer}("");
        require(sent, "Failed to send Ether");
    }

    function dividendsDist(uint256 amountToDist) external onlyOwner {
        if (
            address(this).balance == 0 ||
            (((address(this).balance).mul(95)).div(100)) < amountToDist
        ) revert VertkaToken__NotEnoughAmount();

        for (uint256 i = 1; i < s_funders.length; i++) {
            address contractFunder = s_funders[i];
            uint256 amountToReceiveByFunder = s_addressToAmountFunded[
                contractFunder
            ];
            transferETH(payable(contractFunder), amountToReceiveByFunder);
            emit Transfer(i_owner, contractFunder, amountToReceiveByFunder);
        }
    }

    receive() external payable {
        fundContract();
    }

    fallback() external payable {
        fundContract();
    }
}

interface InftContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract VertkaFund {
    // Tokens
    IERC20 public token;

    // Libraries
    using SafeMath for uint256;

    // Structs
    struct Campaign {
        address creator; // Creator of campaign
        uint256 goal; // Amount of tokens to raise
        uint256 funded; // Total amount funded
        uint32 startAt; // Timestamp of start of campaign
        uint32 endAt; // Timestamp of end of campaign
        bool claimed; // True if goal was reached and creator has claimed the tokens.
    }

    // State Variables
    address payable private immutable i_owner;
    address[] public tokens;
    string private newTokenName;
    string private newTokenSymbol;
    uint256[] public campaignToken; // To control relation of tokens and campaigns
    uint256 public count; // Total count of campaigns created. It is also used to generate id for new campaigns.
    mapping(uint256 => Campaign) public campaigns; // Mapping from id to Campaign
    mapping(uint256 => mapping(address => uint256)) public fundedAmount; // Mapping from campaign id => funder => amount funded
    address[] private funders; // Array of funders
    uint256[] private assets; // Array of assets (campaigns) invested by each funder
    uint256[] public validTokens;
    InftContract nftContract;

    // Events
    event Launch(
        uint256 id,
        address indexed creator,
        uint256 goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint256 id);
    event Funded(uint256 indexed id, address indexed caller, uint256 amount);
    event UnFunded(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 id, address indexed caller, uint256 amount);
    event Received(address indexed id, uint256 amount_funded);
    event IncreasedAllowance(address indexed spender, uint256 amount);
    event Approved(address indexed spender, uint256 amount);
    event Transfered(address indexed spender, uint256 amount);
    event TransferedFrom(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event NewTokenCreated(address newToken);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert VertkaFund__NotOwner();
        _;
    }

    // Constructor
    constructor() {
        //        token = IERC20(_token);
        i_owner = payable(msg.sender);
        nftContract = InftContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            77469689882666531793798202221056432409823282589566023883918938027846273073153
        ];
    }

    // Functions
    function checkEligibility(address _interactor) private view returns (bool) {
        for (uint i = 0; i < validTokens.length; i++) {
            if (nftContract.balanceOf(_interactor, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function addTokenId(uint256 _tokenId) public onlyOwner {
        validTokens.push(_tokenId);
    }

    function launch(
        uint256 _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external onlyOwner {
        //require(checkEligibility(msg.sender), "Only NFT holders can launch.");
        if (_startAt < block.timestamp)
            revert VertkaFund__StartTimeNeed2BeFuture(); // _startAt >= block.timestamp
        if (_endAt < _startAt) revert VertkaFund__EndTimeNeed2BeFuture(); // _endAt >= _startAt
        if (_endAt > block.timestamp + 180 days)
            revert VertkaFund__EndTimeOverExpireTime(); // _endAt <= block.timestamp + 180 days

        count = count.add(1);
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            funded: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint256 _id) external onlyOwner {
        Campaign memory campaign = campaigns[_id];
        if (block.timestamp > campaign.startAt)
            revert VertkaFund__CampaignStarted(); // block.timestamp < campaign.startAt

        delete campaigns[_id];

        emit Cancel(_id);
    }

    function fund(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        //require(checkEligibility(msg.sender), "Only NFT holders can fund.");
        if (block.timestamp < campaign.startAt) revert VertkaFund__NotStarted(); // block.timestamp >= campaign.startAt
        if (block.timestamp > campaign.endAt) revert VertkaFund__Ended(); // block.timestamp <= campaign.endAt
        if (campaign.claimed == true) revert VertkaFund__CampaignClaimed();
        if (msg.value == 0) revert VertkaFund__NotEnoughAmount();

        campaign.funded = campaign.funded.add(msg.value);
        fundedAmount[_id][msg.sender] = fundedAmount[_id][msg.sender].add(
            msg.value
        );
        funders.push(msg.sender);
        assets.push(_id);
        if (campaign.funded >= campaign.goal && campaign.claimed == false) {
            emit Funded(_id, msg.sender, msg.value);
            claim(_id);
        } else {
            emit Funded(_id, msg.sender, msg.value);
        }
    }

    function transferViaCall(address payable _to, uint256 _amountToTransfer)
        internal
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = _to.call{value: _amountToTransfer}("");
        require(sent, "Failed to send Ether");
    }

    function unfund(uint256 _id, uint256 _amount) public payable {
        Campaign storage campaign = campaigns[_id];
        if (block.timestamp < campaign.startAt) revert VertkaFund__NotStarted(); // block.timestamp >= campaign.startAt
        if (block.timestamp > campaign.endAt) revert VertkaFund__Ended(); // block.timestamp <= campaign.endAt
        if (campaign.claimed == true) revert VertkaFund__CampaignClaimed();
        if ((fundedAmount[_id][msg.sender].mul(95)).div(100) == 0)
            revert VertkaFund__NotEnoughAmount();
        if (fundedAmount[_id][msg.sender] < _amount)
            revert VertkaFund__AmountAboveBalance();
        if (fundedAmount[_id][msg.sender] < (_amount.mul(95)).div(100))
            revert VertkaFund__PenaltyFivePerc();

        campaign.funded = campaign.funded.sub((_amount.mul(95)).div(100)); // Penalty of 5% to unfund
        fundedAmount[_id][msg.sender] = (
            fundedAmount[_id][msg.sender].sub((_amount.mul(95)).div(100))
        ).sub((_amount.mul(5)).div(100));
        transferViaCall(payable(msg.sender), (_amount.mul(95)).div(100));

        emit UnFunded(_id, msg.sender, (_amount.mul(95)).div(100));
    }

    // function create(uint256 initialSupply, uint256 _id, string memory name, string memory symbol) internal {
    //     token = new VertkaToken(initialSupply, name, symbol);
    //     tokens.push(token);
    //     campaignToken.push(_id);
    // }

    function claim(uint256 _id) internal {
        Campaign storage campaign = campaigns[_id];
        //        require(campaign.creator == msg.sender, "not creator");
        //        require(block.timestamp > campaign.endAt, "not ended");
        if (campaign.funded < campaign.goal)
            revert VertkaFund__GoalNotReached();
        if (campaign.claimed == true) revert VertkaFund__CampaignClaimed();

        campaign.claimed = true;

        emit Claim(_id);

        newTokenName = string.concat("VertkaToken", Strings.toString(_id));
        newTokenSymbol = string.concat("VRTK", Strings.toString(_id));
        //console.log(i_owner);
        token = new VertkaToken(
            i_owner,
            campaign.funded,
            newTokenName,
            newTokenSymbol
        );
        tokens.push(address(token));
        campaignToken.push(_id);

        emit NewTokenCreated(address(token));

        transferViaCall(payable(address(token)), campaign.funded);

        emit Transfered(address(token), campaign.funded);

        for (uint256 i = 0; i < funders.length; i++) {
            //console.log(assets[i]);
            if (assets[i] == _id) {
                //console.log(fundedAmount[_id][funders[i]]);
                uint256 tokensToTransfer = fundedAmount[_id][funders[i]];
                if (fundedAmount[_id][funders[i]] > 0) {
                    token.registerFunder(funders[i], tokensToTransfer);
                    token.transfer(funders[i], tokensToTransfer);
                    emit Transfered(funders[i], tokensToTransfer);
                }
            }
        }
    }

    function refund(uint256 _id) external onlyOwner {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.funded < campaign.goal, "total funded >= goal");

        uint256 bal = fundedAmount[_id][msg.sender];
        fundedAmount[_id][msg.sender] = 0;
        //        VRTK_Token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}