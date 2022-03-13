/**
 *Submitted for verification at Etherscan.io on 2022-03-13
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
    uint256 public bidSize = 100000000;
    uint256 public nextBidSize = 100000000;
    uint256 public roundNumber = 1;
    uint256 public bidsCount;
    mapping(uint256=>Ticket[]) public tickets;
    uint256 public ticketsRewards; // current round tickets summary reward
    mapping(uint256 => mapping(address => uint256[])) ticketsByAccounts;
    mapping(address => uint256) roundNumberByAccount;
    mapping(address => bool) hasTicket;
    uint256 public playersCount;
    bool _isWithdrawInterval;
    uint256 _nextIntervalTime;
    uint256 public intervalTimerMin = 1;
    address public cAASBankAddress;
    uint256 cAASBankAddressPercent = 50;
    uint256 public jackpot;
    uint256 public lotteryFeePercent = 5;
    uint256 jackpotN = 1000;
    uint256 nextJackpotN;
    bool public isOpened;

    event OnJackpot(uint256 count, uint256 indexed roundNumber);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        cAASBankAddress = address(this);
        nextJackpotN = jackpotN;
    }

    function setLotteryFeePercent(uint256 lotteryFeePercent_)
        external
        onlyOwner
    {
        require(lotteryFeePercent_ <= 90);
        lotteryFeePercent = lotteryFeePercent_;
    }

    function setOpenLottery(bool opened) external onlyOwner {
        isOpened = opened;
        _nextIntervalTime = block.timestamp + intervalTimerMin * 1 minutes;
    }

    function setToken(address tokenAddress) external onlyOwner {
        token = IERC20(tokenAddress);
    }

    function setNextJackpotN(uint256 n) external onlyOwner {
        nextJackpotN = n;
    }

    function withdrawOwner() external onlyOwner {
        token.transfer(_owner, token.balanceOf(address(this)));
    }

    function setNextBidSize(uint256 nextBidSize_) external onlyOwner {
        nextBidSize = nextBidSize_;
        if (bidsCount == 0) bidSize = nextBidSize_;
    }

    function setIntervalTimer(uint256 intervalTimerMin_) external onlyOwner {
        intervalTimerMin = intervalTimerMin_;
    }

    function setCAASBankAddress(address cAASBankAddress_) external onlyOwner {
        cAASBankAddress = cAASBankAddress_;
    }

    function setCAASBankAddressPercent(uint256 cAASBankAddressPercent_)
        external
        onlyOwner
    {
        require(cAASBankAddressPercent_ <= 100);
        cAASBankAddressPercent = cAASBankAddressPercent_;
    }

    function buyTicket() external {
        _buyTickets(msg.sender, 1);
    }

    function buyTickets(address account, uint256 count) external {
        _buyTickets(account, count);
    }

    function _buyTickets(address account, uint256 count) private {
        require(count > 0, "count is zero");
        require(isOpened, "lottery is not open");
        tryNextInterval();
        require(!_isWithdrawInterval, "only in game interval");
        if (roundNumberByAccount[account] != roundNumber) clearData(account);

        token.transferFrom(account, address(this), bidSize * count);

        roundNumberByAccount[account] = roundNumber;
        if (!hasTicket[account]) ++playersCount;
        hasTicket[account] = true;
        uint256 lastbTicketsCount = bidsCount;
        bidsCount += count;
        for (uint256 i = 0; i < count; ++i) {
            tickets[roundNumber].push(Ticket(bidSize, false));
            ticketsByAccounts[roundNumber][account].push(lastbTicketsCount + i);
            arrangeRewards(lastbTicketsCount + i);
        }
    }

    function arrangeRewards(uint256 ticketA) private {
        ticketsRewards += tickets[roundNumber][ticketA].amount;
        tickets[roundNumber][ticketA].amount -=
            (tickets[roundNumber][ticketA].amount * (lotteryFeePercent + 10)) /
            100; // lottery fee + 10% token tax
        uint256 random = _random();
        uint256 currentTicketsCount = ticketA + 1;
        uint256 ticketB = random % currentTicketsCount;
        if (ticketB == ticketA) ticketB = (ticketB + 1) % currentTicketsCount;

        // jackpot
        if (random % jackpotN == 0) {
            emit OnJackpot(jackpot, roundNumber);
            tickets[roundNumber][ticketB].amount += jackpot;
            ticketsRewards += jackpot;
            jackpot = 0;
        }

        if (ticketB == ticketA) return;
        uint256 percent = 1 + (random % 1000);
        if (random % 2 == 0) {
            uint256 delta = (tickets[roundNumber][ticketB].amount * percent) / 1000;
            tickets[roundNumber][ticketA].amount += delta;
            tickets[roundNumber][ticketB].amount -= delta;
        } else {
            uint256 delta = (tickets[roundNumber][ticketA].amount * percent) / 1000;
            tickets[roundNumber][ticketA].amount -= delta;
            tickets[roundNumber][ticketB].amount += delta;
        }
    }

    function clearData(address account) private {
        hasTicket[account] = false;
    }

    function getTicketsCount(address account) public view returns (uint256) {
        if (
            roundNumberByAccount[account] != roundNumber ||
            (_isWithdrawInterval &&
                intervalLapsedTime() == 0 &&
                playersCount > 1) ||
            (
                (!_isWithdrawInterval &&
                    block.timestamp >=
                    _nextIntervalTime + intervalTimerMin * 1 minutes &&
                    playersCount > 1)
            )
        ) return 0;

        return ticketsByAccounts[roundNumber][account].length;
    }

    function getTicket(address account, uint256 index)
        public
        view
        returns (Ticket memory)
    {
        require(index < getTicketsCount(account), "bad ticketIndex");
        return tickets[roundNumber][ticketsByAccounts[roundNumber][account][index]];
    }

    function getTickets(
        address account,
        uint256 startIndex,
        uint256 count
    ) external view returns (Ticket[] memory) {
        Ticket[] memory ticketsList = new Ticket[](count);
        require(
            startIndex + count <= getTicketsCount(account),
            "bad ticketIndex"
        );
        for (uint256 i = 0; i < count; ++i) {
            ticketsList[i] = tickets[roundNumber][
                ticketsByAccounts[roundNumber][account][startIndex + i]
            ];
        }

        return ticketsList;
    }

    function getAllTicketsListPage(uint256 startIndex, uint256 count)
        external
        view
        returns (Ticket[] memory)
    {
        Ticket[] memory ticketsList = new Ticket[](count);
        for (uint256 i = 0; i < count; ++i) {
            ticketsList[i] = tickets[roundNumber][startIndex + i];
        }

        return ticketsList;
    }

    function closeTicket(address account, uint256 index) external {
        _closeTickets(account, index, 1);
    }

    function closeTickets(
        address account,
        uint256 startIndex,
        uint256 count
    ) external {
        _closeTickets(account, startIndex, count);
    }

    function _closeTickets(
        address account,
        uint256 startIndex,
        uint256 count
    ) private {
        require(count > 0, "count is zero");
        require(isOpened, "lottery is not open");
        tryNextInterval();
        require(_isWithdrawInterval, "only in withdraw interval");
        uint256 toTransfer;
        uint256 lastIndex = startIndex + count;
        for (uint256 i = startIndex; i < lastIndex; ++i) {
            Ticket storage ticket = tickets[roundNumber][ticketsByAccounts[roundNumber][account][i]];
            if (ticket.isClosed) continue;
            ticket.isClosed = true;
            toTransfer += ticket.amount;
        }
        require(toTransfer > 0, "has no rewards");
        token.transfer(account, toTransfer);
    }

    function _newRound() private {
        if (!isOpened) return;
        _isWithdrawInterval = false;

        if (playersCount > 1 || (playersCount == 1 && tickets[roundNumber][0].isClosed)) {
            ++roundNumber;
            bidSize = nextBidSize;
            bidsCount = 0;
            playersCount = 0;
            ticketsRewards = 0;
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0 && cAASBankAddress != address(this)) {
                uint256 toTransfer = ((token.balanceOf(address(this)) -
                    jackpot) * cAASBankAddressPercent) / 100;
                token.transfer(cAASBankAddress, toTransfer);
            }

            jackpot = token.balanceOf(address(this));
            jackpotN = nextJackpotN;
        }
    }

    function tryNextInterval() public {
        if (!isOpened) return;
        // next interval
        if (block.timestamp < _nextIntervalTime) return;

        // if skip reward interval
        if (!_isWithdrawInterval) {
            if (
                !_isWithdrawInterval &&
                block.timestamp >=
                _nextIntervalTime + intervalTimerMin * 1 minutes
            ) {
                _nextIntervalTime =
                    block.timestamp +
                    intervalTimerMin *
                    1 minutes;
                _newRound();
                return;
            }
            _nextIntervalTime = block.timestamp + intervalLapsedTime();
        } else {
            _nextIntervalTime = block.timestamp + intervalTimerMin * 1 minutes;
        }

        // next interval
        _isWithdrawInterval = !_isWithdrawInterval;
        // next round
        if (!_isWithdrawInterval) _newRound();
    }

    /// @dev current intervallapsed time in seconds
    function intervalLapsedTime() public view returns (uint256) {
        // if timer
        if (block.timestamp < _nextIntervalTime)
            return _nextIntervalTime - block.timestamp;
        // now withdraw interval (skipping withdraq interval)
        if (
            !_isWithdrawInterval &&
            block.timestamp < _nextIntervalTime + intervalTimerMin * 1 minutes
        )
            return
                _nextIntervalTime +
                intervalTimerMin *
                1 minutes -
                block.timestamp;
        // new interval
        return 0;
    }

    function isWithdrawInterval() external view returns (bool) {
        // if timer
        if (block.timestamp < _nextIntervalTime) return _isWithdrawInterval;
        // now withdraw interval (skipping withdraq interval)
        if (
            !_isWithdrawInterval &&
            block.timestamp >= _nextIntervalTime + intervalTimerMin * 1 minutes
        ) return false;
        // new interval
        return !_isWithdrawInterval;
    }
}