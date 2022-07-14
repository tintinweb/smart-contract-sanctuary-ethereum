/**
 *Submitted for verification at BscScan.com on 2022-05-13
 */

/*   ETH2x - Yield Farming Smart Contract built on ETH Smart Chain.
 *   The only official platform of original ETH2x team! All other platforms with the same contract code are FAKE!
 *
 *   [OFFICIAL LINKS]
 *
 *   ┌────────────────────────────────────────────────────────────┐
 *   │   Website: https://ETH2x.org                               │
 *   │                                                            │
 *   │   Twitter: https://twitter.com/ETH2x_org                   │
 *   │   Telegram: https://t.me/ETH2x                             │
 *   │                                                            │
 *   │   E-mail: [email protected]                                  │
 *   └────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Transfer method directly from wallet without website UI
 *
 *      - Deposit - Transfer ETH you want to double to contract address, use msg.data to provide referrer address
 *      - Withdraw earnings - Transfer 0 ETH to contract address
 *      - Reinvest earnings - Withdraw and Deposit manually
 *
 *   2) Using website UI
 *
 *      - Connect web3 wallet
 *      - Deposit - Enter ETH amount you want to double, click "Double Your ETH" button and confirm transaction
 *      - Reinvest earnings - Click "Double Earnings" button and confirm transaction
 *      - Withdraw earnings - Click "Withdraw Earnings" button and confirm transaction
 *
 *   [DEPOSIT CONDITIONS]
 *
 *   - Minimal deposit: 0.02 ETH, no max limit
 *   - Total income: 200% per deposit
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - Referral reward: 10%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, using for participants payouts, affiliate program bonuses
 *   - 10% Advertising and promotion expenses, Support work, Development, Administration fee
 *
 *   Verified contract source code has been audited by an independent company
 *   there is no backdoors or unfair rules.
 *
 *   Note: This project has high risks as well as high profits.
 *   Once contract balance drops to zero payments will stops,
 *   deposit at your own risk.
 */

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract ETH2x_org is Ownable {
    uint256 constant INVEST_MIN_AMOUNT = 2e16; // 0.02 ETH
    uint256 constant REFERRAL_PERCENT = 10;
    uint256 constant PROJECT_FEE = 10;
    uint256 constant ROI = 200;
    uint256 constant PERCENTS_DIVIDER = 100;
    uint256 constant PERIOD = 30 days;

    uint256 totalInvested;
    uint256 totalRefBonus;

    struct Deposit {
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 referals;
        uint256 totalBonus;
    }

    mapping(address => User) internal users;

    bool started;
    address payable commissionWallet =
        payable(0xdA61dAb21521B59CD74bf7be2d5Ff07DA1f0C902);

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Reinvest(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() {}

    fallback() external payable {
        if (msg.value >= INVEST_MIN_AMOUNT) {
            invest(bytesToAddress(msg.data));
        } else {
            withdraw();
        }
    }

    receive() external payable {
        if (msg.value >= INVEST_MIN_AMOUNT) {
            invest(address(0));
        } else {
            withdraw();
        }
    }

    function invest(address referrer) public payable {
        if (!started) {
            if (msg.sender == commissionWallet) {
                started = true;
            } else revert("Not started yet");
        }

        checkIn(msg.value, referrer);
    }

    function reinvest() public {
        uint256 totalAmount = checkOut();

        emit Reinvest(msg.sender, totalAmount);

        checkIn(totalAmount, address(0));
    }

    function withdraw() public {
        uint256 totalAmount = checkOut();

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalInvested, uint256 _totalBonus)
    {
        return (totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 readyToWithdraw,
            uint256 totalDeposits,
            uint256 totalActiveDeposits,
            uint256 totalWithdrawn,
            uint256 totalBonus,
            address referrer,
            uint256 referals
        )
    {
        User storage user = users[userAddress];

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start + PERIOD;
            uint256 roi = (user.deposits[i].amount * ROI) / PERCENTS_DIVIDER;
            if (user.deposits[i].withdrawn < roi) {
                uint256 profit;
                if (block.timestamp >= finish) {
                    profit = roi - user.deposits[i].withdrawn;
                } else {
                    uint256 from = user.deposits[i].start > user.checkpoint
                        ? user.deposits[i].start
                        : user.checkpoint;
                    uint256 to = block.timestamp;
                    profit = (roi * (to - from)) / PERIOD;

                    totalActiveDeposits += user.deposits[i].amount;
                }

                readyToWithdraw += profit;
            }

            totalDeposits += user.deposits[i].amount;
            totalWithdrawn += user.deposits[i].withdrawn;
        }

        totalBonus = user.totalBonus;
        referrer = user.referrer;
        referals = user.referals;
    }

    function checkIn(uint256 value, address referrer) internal {
        require(value >= INVEST_MIN_AMOUNT, "Less than minimum for deposit");

        uint256 fee = (value * PROJECT_FEE) / PERCENTS_DIVIDER;
        commissionWallet.transfer(fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;

            address upline = user.referrer;
            users[upline].referals++;
        }

        if (user.referrer != address(0)) {
            uint256 amount = (value * REFERRAL_PERCENT) / PERCENTS_DIVIDER;
            users[user.referrer].totalBonus += amount;
            totalRefBonus += amount;
            payable(user.referrer).transfer(amount);
            emit RefBonus(user.referrer, msg.sender, amount);
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(value, block.timestamp, 0));

        totalInvested += value;

        emit NewDeposit(msg.sender, value);
    }

    function checkOut() internal returns (uint256) {
        User storage user = users[msg.sender];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start + PERIOD;
            uint256 roi = (user.deposits[i].amount * ROI) / PERCENTS_DIVIDER;
            if (user.deposits[i].withdrawn < roi) {
                uint256 profit;
                if (block.timestamp >= finish) {
                    profit = roi - user.deposits[i].withdrawn;
                } else {
                    uint256 from = user.deposits[i].start > user.checkpoint
                        ? user.deposits[i].start
                        : user.checkpoint;
                    uint256 to = block.timestamp;
                    profit = (roi * (to - from)) / PERIOD;
                }

                totalAmount += profit;
                user.deposits[i].withdrawn += profit;
            }
        }

        require(totalAmount > 0, "User has no dividends");

        user.checkpoint = block.timestamp;

        return totalAmount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function bytesToAddress(bytes memory _source)
        internal
        pure
        returns (address parsedreferrer)
    {
        assembly {
            parsedreferrer := mload(add(_source, 0x14))
        }
        return parsedreferrer;
    }

    function setCommisionWallet(address payable _newAddress) external onlyOwner {
        require(!isContract(_newAddress));
        commissionWallet = _newAddress;
    }
}