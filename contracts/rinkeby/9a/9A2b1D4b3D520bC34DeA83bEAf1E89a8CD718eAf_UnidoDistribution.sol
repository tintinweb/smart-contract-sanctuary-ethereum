/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/** 
 *  SourceUnit: UnidoDistribution.sol
*/
            

pragma solidity 0.7.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



/** 
 *  SourceUnit: UnidoDistribution.sol
*/
            

pragma solidity 0.7.0;

contract Ownable {
    address public owner;
    address private _nextOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of the contract can do that");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address nextOwner) public onlyOwner {
        _nextOwner = nextOwner;
    }

    function takeOwnership() public {
        require(msg.sender == _nextOwner, "Must be given ownership to do that");
        emit OwnershipTransferred(owner, _nextOwner);
        owner = _nextOwner;
    }
}

/** 
 *  SourceUnit: UnidoDistribution.sol
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract UnidoDistribution is Ownable {
    using SafeMath for uint256;

    struct PoolInfo {
        uint256 totalSupply;
        uint256 lockoutPeriod;
        uint256 lockoutReleaseRate;
    }

    // 0 - SEED
    // 1 - PRIVATE
    // 2 - TEAM
    // 3 - ADVISOR
    // 4 - ECOSYSTEM
    // 5 - LIQUIDITY
    // 6 - RESERVE
    enum POOL {
        SEED,
        PRIVATE,
        TEAM,
        ADVISOR,
        ECOSYSTEM,
        LIQUIDITY,
        RESERVE
    }

    string public constant name = "Unido";
    uint256 public constant decimals = 18;
    string public constant symbol = "UDO";

    uint256 private _scanLength = 150;
    uint256 private _continuePoint;
    uint256[] private _deletions;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public lockoutPeriods;
    mapping(address => uint256) public lockoutBalances;
    mapping(address => uint256) public lockoutReleaseRates;

    PoolInfo[7] public pools;

    address[] public participants;

    bool public isTradeable;
    uint256 public totalSupply;

    event Active(bool isActive);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Burn(address indexed tokenOwner, uint256 tokens);

    modifier notZeroAddress(address participant) {
        require(participant != address(0), "Error: Zero address");
        _;
    }

    modifier notZero(uint256 amount) {
        require(amount > 0, "Error: Zero amount");
        _;
    }

    modifier onlySpendable(address spender, uint256 amount) {
        require(_spendable(spender) >= amount, "Must have enough spendable tokens");
        _;
    }

    constructor() {
        // SEED Setup
        pools[0].totalSupply = 15e24;
        pools[0].lockoutPeriod = 1;
        pools[0].lockoutReleaseRate = 5;

        // PRIVATE Setup
        pools[1].totalSupply = 14e24;
        pools[1].lockoutReleaseRate = 4;

        // TEAM Setup
        pools[2].totalSupply = 184e23;
        pools[2].lockoutPeriod = 12;
        pools[2].lockoutReleaseRate = 12;

        // ADVISOR Setup
        pools[3].totalSupply = 1035e22;
        pools[3].lockoutPeriod = 6;
        pools[3].lockoutReleaseRate = 6;

        // ECOSYSTEM Setup
        pools[4].totalSupply = 14375e21;
        pools[4].lockoutPeriod = 3;
        pools[4].lockoutReleaseRate = 9;

        // LIQUIDITY Setup
        pools[5].totalSupply = 43125e20;
        pools[5].lockoutPeriod = 1;
        pools[5].lockoutReleaseRate = 1;

        // RESERVE Setup
        pools[6].totalSupply = 3225e22;
        pools[6].lockoutReleaseRate = 18;

        totalSupply = 115e24;

        // Give POLS private sale directly
        balanceOf[0xeFF02cB28A05EebF76cB6aF993984731df8479b1] = 2e24;

        // Give LIQUIDITY pool their half directly
        balanceOf[0xd6221a4f8880e9Aa355079F039a6012555556974] = 43125e20;
    }

    function setTradeable() external onlyOwner {
        require(!isTradeable, "Can only set tradeable when its not already tradeable");
        isTradeable = true;
        emit Active(true);
    }

    function setScanLength(uint256 len) external onlyOwner {
        _scanLength = len;
    }

    function approve(address spender, uint256 tokens) external returns (bool) {
        _approve(msg.sender, spender, tokens);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function burn(uint256 tokens) external notZero(tokens) onlySpendable(msg.sender, tokens) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
    }

    function transfer(address to, uint256 tokens) external returns (bool) {
        return _transferFrom(msg.sender, to, tokens);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool) {
        return _transferFrom(from, to, tokens);
    }

    function addParticipants(
        POOL _pool,
        address[] calldata _participants,
        uint256[] calldata _stakes
    ) external onlyOwner {
        require(_participants.length == _stakes.length, "Must have equal array sizes");

        PoolInfo storage info = pools[uint256(_pool)];

        uint256 sum;
        uint256 len = _participants.length;
        for (uint256 i = 0; i < len; i++) {
            address p = _participants[i];
            require(lockoutBalances[p] == 0, "Participants can't be involved in multiple lock ups");

            participants.push(p);
            lockoutBalances[p] = _stakes[i];
            balanceOf[p] = balanceOf[p].add(_stakes[i]);
            lockoutPeriods[p] = info.lockoutPeriod;
            lockoutReleaseRates[p] = info.lockoutReleaseRate;

            sum = sum.add(_stakes[i]);
        }

        require(sum <= info.totalSupply, "Insufficient amount left in pool for this");
        info.totalSupply = info.totalSupply.sub(sum);
    }

    function finalizeParticipants(POOL pool) external onlyOwner {
        uint256 leftover = pools[uint256(pool)].totalSupply;
        delete pools[uint256(pool)].totalSupply;
        totalSupply = totalSupply.sub(leftover);
    }

    /**
     * For each account with an active lockout, if their lockout has expired
     * then release their lockout at the lockout release rate
     * If the lockout release rate is 0, assume its all released at the date
     * Only do max 100 at a time, call repeatedly which it returns true
     */
    function updateRelease() external onlyOwner returns (bool) {
        uint256 len = participants.length;
        uint256 continueAddScan = _continuePoint.add(_scanLength);
        for (uint256 i = _continuePoint; i < len && i < continueAddScan; i++) {
            address p = participants[i];
            if (lockoutPeriods[p] > 0) lockoutPeriods[p].sub(1);
            else if (lockoutReleaseRates[p] > 0) {
                // First release of reserve is 12.5%
                lockoutBalances[p] = lockoutBalances[p].sub(
                    lockoutReleaseRates[p] == 18
                        ? lockoutBalances[p].div(8)
                        : lockoutBalances[p].div(lockoutReleaseRates[p])
                );
                lockoutReleaseRates[p].sub(1);
            } else _deletions.push(i);
        }
        _continuePoint = _continuePoint.add(_scanLength);
        if (_continuePoint >= len) {
            delete _continuePoint;
            while (_deletions.length > 0) {
                uint256 index = _deletions[_deletions.length.sub(1)];
                _deletions.pop();

                participants[index] = participants[participants.length.sub(1)];
                participants.pop();
            }
            return false;
        }

        return true;
    }

    function spendable(address tokenOwner) external view returns (uint256) {
        return _spendable(tokenOwner);
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 tokens_
    ) internal notZeroAddress(owner_) notZeroAddress(spender_) {
        allowance[owner_][spender_] = tokens_;
        emit Approval(owner_, spender_, tokens_);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokens
    ) internal notZeroAddress(from) notZeroAddress(to) notZero(tokens) onlySpendable(from, tokens) returns (bool) {
        require(isTradeable, "Contract is not trading yet");
        require(allowance[from][msg.sender] >= tokens, "Must be approved to spend that much");

        balanceOf[from] = balanceOf[from].sub(tokens);
        balanceOf[to] = balanceOf[to].add(tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }

    function _spendable(address tokenOwner) internal view returns (uint256) {
        return balanceOf[tokenOwner].sub(lockoutBalances[tokenOwner]);
    }
}