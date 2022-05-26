// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./EIP20.sol";
import "./SafeMath.sol";

contract SorteoContract {
    using SafeMath for uint256;
    EIP20 public payment_token;

    address public admin;
    uint256 public adminFeePercent;
    uint256 public adminBalance;
    uint256 public rafflesCount;
    uint256 public rafflesExpiration;
    uint256 public totalClaimedReward;
    uint256 public totalClaimedOwner;

    enum Status {
        Active,
        Finished
    }

    struct Ticket {
        address owner;
        bool claimed;
        uint256 createdAt;
    }

    struct Raffle {
        Status status;
        string name;
        address owner;
        uint256 winner;
        uint256 ownerBalance;
        bool ownerBalanceClaimed;
        uint256 prizePercentage;
        uint256 prizeBalance;
        uint256 ticketPrice;
        uint256 ticketGoal;
        uint256 startDate;
        uint256 endDate;
        Ticket[] tickets;
    }

    mapping(uint256 => Raffle) public raffles;

    event RaffleCreated(uint256 id, string name);
    event RaffleFinished(uint256 id, string name);

    constructor(EIP20 _payment_token) {
        payment_token = _payment_token;
        admin = msg.sender;
        adminFeePercent = 5;
        rafflesCount = 0;
        rafflesExpiration = 30 days;
        totalClaimedOwner = 0;
        totalClaimedReward = 0;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "This function is restricted to the admin"
        );
        _;
    }

    modifier onlyOwner(uint256 _raffleId) {
        require(
            msg.sender == raffles[_raffleId].owner,
            "This function is restricted to the owner"
        );
        _;
    }

    modifier onlyActive(uint256 _raffleId) {
        require(
            raffles[_raffleId].status == Status.Active,
            "The raffle already finished"
        );
        _;
    }

    modifier onlyFinished(uint256 _raffleId) {
        require(
            raffles[_raffleId].status == Status.Finished,
            "The raffle is running"
        );
        _;
    }

    function _generateRandomNumber(uint256 _maxValue)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        block.difficulty
                    )
                )
            ).mod(_maxValue);
    }

    function createRaffle(
        string memory _name,
        uint256 _prizePercentage,
        uint256 _ticketPrice,
        uint256 _ticketGoal
    ) public {
        require(
            _prizePercentage <= 100,
            "Prize percentage must be 100 or lower"
        );
        require(_prizePercentage >= 25, "Prize percentage must be 25 or greater");
        require(_ticketGoal >= 10, "Ticket goal must be 10 or greater");

        Raffle storage raffle = raffles[rafflesCount++];
        raffle.status = Status.Active;
        raffle.name = _name;
        raffle.owner = msg.sender;
        raffle.ownerBalance = 0;
        raffle.ownerBalanceClaimed = false;
        raffle.prizePercentage = _prizePercentage;
        raffle.prizeBalance = 0;
        raffle.ticketPrice = _ticketPrice;
        raffle.ticketGoal = _ticketGoal;
        raffle.startDate = block.timestamp;
        raffle.endDate = block.timestamp + rafflesExpiration;
        raffle.tickets;
        emit RaffleCreated(rafflesCount, raffle.name);
    }

    function getRaffle(uint256 _raffleId) public view returns (Raffle memory) {
        return raffles[_raffleId];
    }

    function _finishRaffle(uint256 _raffleId) internal {
        require(
            raffles[_raffleId].tickets.length > 0,
            "The raffle didnt have any tickets"
        );
        Raffle storage raffle = raffles[_raffleId];
        uint256 winnerId = _generateRandomNumber(raffle.tickets.length);
        raffle.status = Status.Finished;
        raffle.winner = winnerId;
        raffle.endDate = block.timestamp;
        emit RaffleFinished(_raffleId, raffle.name);
    }

    function checkWinner(uint256 _raffleId)
        public
        view
        returns (Ticket memory)
    {
        return raffles[_raffleId].tickets[raffles[_raffleId].winner];
    }

    function tryToFinish(uint256 _raffleId) public onlyActive(_raffleId) {
        if (
            raffles[_raffleId].tickets.length == raffles[_raffleId].ticketGoal
        ) {
            _finishRaffle(_raffleId);
        }
        if (raffles[_raffleId].endDate <= block.timestamp) {
            _finishRaffle(_raffleId);
        }
    }

    function getTicket(uint256 _raffleId, uint256 _ticketId)
        public
        view
        returns (Ticket memory)
    {
        return raffles[_raffleId].tickets[_ticketId];
    }

    function getTickets(uint256 _raffleId)
        public
        view
        returns (Ticket[] memory)
    {
        return raffles[_raffleId].tickets;
    }

    function buyTicket(uint256 _raffleId, uint256 _ticketsTotal)
        public
        payable
        onlyActive(_raffleId)
    {
        require(_ticketsTotal >= 1, "You should buy one ticket at least");
        require(
            _ticketsTotal <=
                raffles[_raffleId].ticketGoal.sub(
                    raffles[_raffleId].tickets.length
                ),
            "Insufficient tickets available"
        );
        require(
            msg.value >= raffles[_raffleId].ticketPrice.mul(_ticketsTotal),
            "Value is different than ticket price"
        );

        Raffle storage raffle = raffles[_raffleId];
        uint256 fee = msg.value.mul(adminFeePercent).div(100);
        adminBalance += fee;
        uint256 totalBalance = msg.value.sub(fee);
        uint256 prizeBalance = totalBalance.mul(raffle.prizePercentage).div(
            100
        );
        uint256 ownerBalance = totalBalance.sub(prizeBalance);
        raffle.prizeBalance += prizeBalance;
        raffle.ownerBalance += ownerBalance;

        //payment_token.transferFrom(msg.sender, _wallets[tokenId], amount4owner);
        for (uint256 i = 0; i < _ticketsTotal; i++) {
            raffle.tickets.push(Ticket(msg.sender, false, block.timestamp));
        }

        tryToFinish(_raffleId);
    }

    function getTicketsCount(uint256 _raffleId) public view returns (uint256) {
        return raffles[_raffleId].tickets.length;
    }

    function claimReward(uint256 _raffleId) public onlyFinished(_raffleId) {
        Raffle storage raffle = raffles[_raffleId];
        Ticket storage ticket = raffle.tickets[raffle.winner];

        require(raffle.prizeBalance > 0, "This raffle hasn't prize");
        require(
            ticket.owner == msg.sender,
            "This function is restricted to the winner"
        );
        require(ticket.claimed == false, "The reward already claimed");

        ticket.claimed = true;
        totalClaimedReward += raffle.prizeBalance;

        payable(ticket.owner).transfer(raffle.prizeBalance);
    }

    function claimOwnerBalance(uint256 _raffleId) public onlyOwner(_raffleId) {
        if (raffles[_raffleId].status == Status.Active) {
            tryToFinish(_raffleId);
        }

        require(
            raffles[_raffleId].status == Status.Finished,
            "The raffle is running"
        );
        require(
            raffles[_raffleId].ownerBalance > 0,
            "This raffle hasn't prize"
        );
        require(
            raffles[_raffleId].ownerBalanceClaimed == false,
            "The raffle balance already claimed"
        );

        Raffle storage raffle = raffles[_raffleId];

        raffle.ownerBalanceClaimed = true;
        totalClaimedOwner += raffle.ownerBalance;

        payable(raffle.owner).transfer(raffle.ownerBalance);
    }

    function claimAdminBalance() public onlyAdmin {
        require(adminBalance > 0, "You dont have any balance");
        payable(admin).transfer(adminBalance);

        adminBalance = 0;
    }

    function totalBalanceClaimed() public view returns (uint256) {
        return totalClaimedOwner + totalClaimedReward;
    }

    function updateRafflesExpiration(uint256 _newValue) public onlyAdmin {
        rafflesExpiration = _newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EIP20 {

    uint256 public totalSupply;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
 
    string public name;
    uint8 public decimals;
    string public symbol;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && _allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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