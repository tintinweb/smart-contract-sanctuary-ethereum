/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// File: contracts/HasRandom.sol

pragma solidity ^0.8.7;

abstract contract HasRandom {
    uint256 _randomNonce = 1;

    function _random() internal returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _randomNonce++,
                        block.timestamp
                    )
                )
            );
    }
}

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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
// File: contracts/IRouter.sol



interface IRouter {
    function roundNumber() external view returns (uint256);

    function token() external view returns (IERC20);

    function isWithdrawInterval() external view returns (bool);

    function interwalLapsedTime() external view returns (uint256);

    function poolAddress() external view returns (address);
}

// File: contracts/Lottery.sol

//import "hardhat/console.sol";




struct Ticket {
    uint256 amount;
    bool isClosed;
}

contract Lottery is Ownable, HasRandom {
    IERC20 public token;
    uint256 public bidSize = 100;
    uint256 public nextBidSize = 100;
    uint256 public roundNumber = 1;
    uint256 public bidsCount;
    Ticket[] tickets;
    mapping(address => uint256[]) public ticketsByAccounts;
    mapping(address => uint256) roundNumberByAccount;
    bool public gettingRewards;
    uint256 cycleEndTime;
    uint256 cycleTimer;
    bool _isWithdrawInterval;
    uint256 public nextIntervalTime;
    uint256 public intervalTimer = 180;
    address public poolAddress;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function setToken(address tokenAddress) external onlyOwner {
        token = IERC20(tokenAddress);
        poolAddress = address(this);
        nextIntervalTime = block.timestamp + intervalTimer * 1 minutes;
    }

    function setNextBidSize(uint256 nextBidSize_) external onlyOwner {
        nextBidSize = nextBidSize_;
    }

    function setIntervalTimer(uint256 intervalTimer_) external onlyOwner {
        intervalTimer = intervalTimer_;
    }

    function setPoolAddress(address poolAddress_) external onlyOwner {
        poolAddress = poolAddress_;
    }

    function buyTicket() external {
        tryNextInterval();
        require(!_isWithdrawInterval, "only in game interval");
        if (roundNumberByAccount[msg.sender] != roundNumber)
            clearData(msg.sender);

        token.transferFrom(msg.sender, address(this), bidSize);
        tickets.push(Ticket(bidSize, false));

        ticketsByAccounts[msg.sender].push(bidsCount);
        roundNumberByAccount[msg.sender] = roundNumber;
        ++bidsCount;

        arrangeRewards(bidsCount - 1);
    }

    function arrangeRewards(uint256 ticketA) private {
        tickets[ticketA].amount -= tickets[ticketA].amount / 20; // 5% fee
        uint256 ticketB = _random() % bidsCount;
        if (ticketB == ticketA) ticketB = (ticketB + 1) % bidsCount;
        if (ticketB == ticketA) return;
        uint256 percent = 1 + (_random() % 100);
        if (_random() % 2 == 0) {
            uint256 delta = (tickets[ticketB].amount * percent) / 100;
            tickets[ticketA].amount += delta;
            tickets[ticketB].amount -= delta;
        } else {
            uint256 delta = (tickets[ticketA].amount * percent) / 100;
            tickets[ticketA].amount -= delta;
            tickets[ticketB].amount += delta;
        }
    }

    function clearData(address account) private {
        delete ticketsByAccounts[account];
    }

    function getTicketsCount(address account) public view returns (uint256) {
        if (roundNumberByAccount[account] != roundNumber) return 0;
        return ticketsByAccounts[account].length;
    }

    function getTicket(address account, uint256 index)
        public
        view
        returns (Ticket memory)
    {
        require(index < getTicketsCount(account), "bad ticketIndex");
        return tickets[ticketsByAccounts[account][index]];
    }

    function closeTicket(address account, uint256 index) external {
        tryNextInterval();
        require(_isWithdrawInterval, "only in withdraw interval");
        Ticket storage ticket = tickets[ticketsByAccounts[account][index]];
        require(!ticket.isClosed, "ticket alredy closed");
        ticket.isClosed = true;
        token.transfer(account, ticket.amount);
    }

    function _newRound() private {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0 && poolAddress != address(this)) {
            token.transfer(poolAddress, token.balanceOf(address(this)));
        }
        roundNumber = roundNumber;
        _isWithdrawInterval = false;
        nextIntervalTime = block.timestamp + intervalTimer * 1 minutes;
        if (bidsCount > 1) {
            ++roundNumber;
            bidSize = nextBidSize;
            bidsCount = 0;
            delete tickets;
        }
    }

    function tryNextInterval() public {
        // next interval
        if (block.timestamp < nextIntervalTime) return;
        nextIntervalTime = block.timestamp + intervalTimer * 1 minutes;
        _isWithdrawInterval = !_isWithdrawInterval;
        // next round
        if (!_isWithdrawInterval) _newRound();
    }

    /// @dev current intervallapsed time in seconds
    function intervalLapsedTime() external view returns (uint256) {
        if (block.timestamp >= nextIntervalTime) return 0;
        return nextIntervalTime - block.timestamp;
    }

    function isWithdrawInterval() external view returns (bool) {
        if (this.intervalLapsedTime() > 0) return _isWithdrawInterval;
        return !_isWithdrawInterval;
    }
}