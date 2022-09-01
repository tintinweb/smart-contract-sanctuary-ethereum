/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract PoolMatrixGame {

    uint256[] prices = [
        0.04 ether,
        0.06 ether,
        0.10 ether,
        0.13 ether,
        0.15 ether,
        0.20 ether,
        0.30 ether,
        0.40 ether,
        0.50 ether,
        1.00 ether,
        2.00 ether
    ];

    uint256[] times = [
        191 hours,
        167 hours,
        143 hours,
        119 hours,
        95 hours,
        71 hours,
        47 hours,
        23 hours,
        11 hours,
        5 hours,
        0
    ];

     uint256 public startDateUnix;

    uint256[] gameRefPercents = [
        14,
        7,
        4
    ];

    uint256[] stakingRefPercents = [
        30,
        15,
        10
    ];

    address payable[][] data;
    mapping (uint256 => mapping (uint256 => uint256)) count;
    uint256[11] pushUp;
    uint256[11] pushDown;

    uint256 constant INVEST_MIN_AMOUNT = 4e16; // 0.04 bnb
    uint256 constant INVEST_MAX_AMOUNT = 30e18; // 30 bnb

    uint256 constant PERIOD = 150 days;
    uint256 constant PROJECT_FEE = 10;
    uint256 constant STAKING_FEE = 15;
    uint256 constant ROI = 300;
    uint256 constant PERCENTS_DIVIDER = 100;

    uint256 public totalInvested;
    uint256 public totalRefBonus;

    struct Deposit {
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
    }

    struct User {
        Deposit[] deposits;

        uint256 checkpoint;
        address referrer;
        uint256 totalBonus;

        uint256[3] referals;
        uint256[3] referalDeps;
        uint256[3] stakingRefBonuses;

        uint256[11] _slots;
        uint256[11] _slotsClosed;
        uint256[11] _rewards;
        uint256[11] _gameRefBonuses;
    }

    mapping (address => User) internal users;

    address payable refWallet;
    address payable projectWallet;
    address payable stakingWallet;
    address payable pushWallet;

    event Fireslot(address indexed account, uint8 indexed level, uint256 amount);
    event Payment(address indexed recipient, uint8 indexed level, address from, uint256 amount);
    event RefPayment(address indexed recipient, uint8 indexed level, address from, uint256 amount);

    event RefBonus(address indexed recipient, uint8 indexed level, address from, uint256 amount);
    event NewDeposit(address indexed account, uint256 amount);
    event Reinvest(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

   constructor(/*address payable projectAddr, address payable stakingAddr, address payable refAddr, address payable pushAddr, uint256 start, address[] memory accs, uint256[] memory amts, address[] memory refs*/) {
        //refWallet = refAddr;
        //projectWallet = projectAddr;
        //stakingWallet = stakingAddr;
        //pushWallet = pushAddr;
        //startDateUnix = start;

        address payable[] memory s = new address payable[](0);
        for (uint256 i; i < 11; i++) {
            data.push(s);
        }

        /*users[refs[1]].referrer = refs[0];
        users[refs[0]].referals[0]++;
        users[refs[0]].referalDeps[0] = amts[1];
        for (uint256 i; i < 2; i++) {
            users[accs[i]].checkpoint = block.timestamp;
            users[accs[i]].deposits.push(Deposit(amts[i], block.timestamp, 0));
        }*/
    }

    bool initialization;
    mapping (address => bool) a;
    function init(address payable[] memory x, uint8[] memory y, uint256[] memory z, bool check) public {
        require(!initialization);
        for (uint256 i; i < x.length; i++) {
            address payable addr = x[i];
            uint8 lvl = y[i];
            uint256 amount = z[i];
            a[addr] = true;
            users[addr]._slots[lvl] += amount;
            for (uint256 j; j < amount; j++) {
                data[lvl].push(addr);
                if (data[lvl].length > 2) {
                    address payable next = data[lvl][((data[lvl].length-1)/2)-1];
                    data[lvl].push(next);
                }
            }
        }
        initialization = check;
    }

    fallback() external payable {
        if (msg.value > 0) {
            invest(bytesToAddress(msg.data));
        } else {
            withdraw();
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            invest(address(0));
        } else {
            withdraw();
        }
    }

    function buyFireslot(uint8 level, address referrer) public payable {
        require(block.timestamp >= startDateUnix + times[level], "Slot not opened yet");
        uint256 amount = msg.value / prices[level];
        require(amount >= 1, "Incorrect value");

        uint256 mod = msg.value % prices[level];
        if (mod > 0) {
            payable(msg.sender).transfer(mod);
        }

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && referrer != msg.sender) {
			user.referrer = referrer;
			address ref = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (ref != address(0)) {
					users[ref].referals[i]++;
					ref = users[ref].referrer;
				} else break;
			}
		}

        process(payable(msg.sender), level, amount);

        if (level < 10 && pushUp[level] >= prices[level+1] && address(this).balance >= prices[level+1]) {
            pushUp[level] -= prices[level+1];
            process(pushWallet, level+1, 1);
        } else if (level > 0 && pushDown[level] >= prices[level-1] && address(this).balance >= prices[level-1]) {
            pushDown[level] -= prices[level-1];
            process(pushWallet, level-1, 1);
        }

    }

    function process(address payable account, uint8 level, uint256 amount) internal {
        uint256 value = amount * prices[level];
        (projectWallet.send(value * PROJECT_FEE / PERCENTS_DIVIDER));

        User storage user = users[account];

        address payable recipient;
        user._slots[level] += amount;
        emit Fireslot(account, level, amount);
        uint256 adminFee;

        for (uint256 i = 0; i < amount; i++) {
            data[level].push(payable(account));

            if (data[level].length < 3 || data[level].length % 2 == 0) {
                if (data[level].length == 2) {
                    recipient = data[level][0];
                    count[level][0]++;
                } else {
                    recipient = projectWallet;
                }
            } else {
                recipient = data[level][data[level].length / 2];
                count[level][data[level].length / 2]++;
                if (count[level][data[level].length / 2] == 4) {
                    users[recipient]._slotsClosed[level]++;
                }

                uint256 nextId = ((data[level].length-1) / 2)-1;
                address payable next = data[level][nextId];
                    count[level][data[level].length-1] = count[level][nextId];
                if (count[level][nextId] < 4) {
                    data[level].push(next);
                    count[level][data[level].length-1] = count[level][nextId];
                }
            }

            uint256 payment = prices[level] / 2;
            (recipient.send(payment));
            users[recipient]._rewards[level] += payment;
            emit Payment(recipient, level, account, payment);

            uint256 pushValue = prices[level] * 15 / 2 / PERCENTS_DIVIDER;

            if (level < 10) {
                pushUp[level] += pushValue;
            } else {
                adminFee += pushValue;
            }

            if (level > 0) {
                pushDown[level] += pushValue;
            } else {
                adminFee += pushValue;
            }
        }

        if (adminFee > 0) {
            (pushWallet.send(adminFee));
            adminFee = 0;
        }

        address upline = users[account].referrer;
        for (uint8 j = 0; j < 3; j++) {
            if (upline != address(0)) {
                uint256 refBonus = value * gameRefPercents[j] / PERCENTS_DIVIDER;

                if (users[upline]._slots[level] > 0) {
                    users[upline]._gameRefBonuses[level] += refBonus;
                    (payable(upline).send(refBonus));
                    emit RefPayment(upline, j, account, refBonus);
                } else {
                    adminFee += refBonus;
                }

                upline = users[upline].referrer;
            } else {
                for (uint256 k = j; k < 3; k++) {
                    adminFee += value * gameRefPercents[k] / PERCENTS_DIVIDER;
                }
                break;
            }
        }

        (refWallet.send(adminFee));
    }

    function invest(address referrer) public payable {
        require(block.timestamp >= startDateUnix, "Staking not opened yet");
		checkIn(msg.value, referrer);
        emit NewDeposit(msg.sender, msg.value);
	}

	function reinvest() public {
		uint256 totalAmount = checkOut();

		checkIn(totalAmount, address(0));
        emit Reinvest(msg.sender, totalAmount);
	}

	function withdraw() public {
		uint256 totalAmount = checkOut();

		payable(msg.sender).transfer(totalAmount);
        emit Withdraw(msg.sender, totalAmount);
	}

    function checkIn(uint256 value, address referrer) internal {
		require(value >= INVEST_MIN_AMOUNT && value <= INVEST_MAX_AMOUNT, "Incorrect amount");

		uint256 adminFee = value * STAKING_FEE / PERCENTS_DIVIDER;
		(stakingWallet.send(adminFee));

		User storage user = users[msg.sender];

        if (user.referrer == address(0) && referrer != msg.sender) {
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].referals[i]++;
					upline = users[upline].referrer;
				} else break;
			}
		}

        address ref = user.referrer;
        for (uint256 i = 0; i < 3; i++) {
            if (ref != address(0)) {
                users[ref].referalDeps[i] += value;
                ref = users[ref].referrer;
            } else break;
        }

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
		}

		user.deposits.push(Deposit(value, block.timestamp, 0));

		totalInvested += value;
	}

	function checkOut() internal returns(uint256) {
		User storage user = users[msg.sender];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start + PERIOD;
			uint256 roi = user.deposits[i].amount * ROI / PERCENTS_DIVIDER;
			if (user.deposits[i].withdrawn < roi) {
				uint256 profit;
				if (block.timestamp >= finish) {
					profit = roi - user.deposits[i].withdrawn;
				} else {
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = block.timestamp;
					profit = roi * (to - from) / PERIOD;
				}

				totalAmount += profit;
				user.deposits[i].withdrawn += profit;
			}
		}

        address upline = user.referrer;
        for (uint8 i = 0; i < 3; i++) {
            if (upline != address(0) && users[upline].deposits.length > 0) {
                uint256 uplineBonus = totalAmount * stakingRefPercents[i] / 100;
                users[upline].stakingRefBonuses[i] += uplineBonus;
                users[upline].totalBonus += uplineBonus;
                emit RefBonus(upline, i, msg.sender, uplineBonus);
                upline = users[upline].referrer;
            }
        }

        totalAmount += user.totalBonus;
        user.totalBonus = 0;

		require(totalAmount > 0, "User has no dividends");

		user.checkpoint = block.timestamp;

		return totalAmount;
	}

    function getSiteInfo() public view returns(uint256[11] memory amt, uint256[11] memory time) {
        for (uint256 i; i < 11; i++) {
            uint t = (startDateUnix + times[i]);
            time[i] = block.timestamp < t ? t - block.timestamp : 0;
            amt[i] = data[i].length;
        }
    }

    function getUserInfo(address account) public view returns(uint256[11] memory slots, uint256[11] memory slotsClosed, uint256[11] memory rewards, uint256[11] memory invested, address[3] memory referrers, uint256[3] memory referrals, uint256[11] memory gameRefBonuses) {
        User storage user = users[account];

        slots = user._slots;
        slotsClosed = user._slotsClosed;
        rewards = user._rewards;

        for (uint256 i; i < 11; i++) {
            invested[i] = user._slots[i] * prices[i];
        }

        referrers[0] = user.referrer;
        referrers[1] = users[referrers[0]].referrer;
        referrers[2] = users[referrers[1]].referrer;

        referrals = user.referals;
        gameRefBonuses = user._gameRefBonuses;
    }

    function getStakingInfo(address account) public view returns(uint256 amountOfDeposits, uint256 invested, uint256 avialable, uint256 withdrawn, uint256[3] memory refBonus, uint256 totalBonus, uint256[3] memory referalDeps) {
        User storage user = users[account];

        amountOfDeposits = user.deposits.length;
		for (uint256 i = 0; i < amountOfDeposits; i++) {
			uint256 finish = user.deposits[i].start + PERIOD;
			uint256 roi = user.deposits[i].amount * ROI / PERCENTS_DIVIDER;
			if (user.deposits[i].withdrawn < roi) {
				uint256 profit;
				if (block.timestamp >= finish) {
					profit = roi - user.deposits[i].withdrawn;
				} else {
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = block.timestamp;
					profit = roi * (to - from) / PERIOD;

				}

				avialable += profit;
			}

			invested += user.deposits[i].amount;
			withdrawn += user.deposits[i].withdrawn;
		}

        refBonus = user.stakingRefBonuses;
		totalBonus = user.totalBonus;
        referalDeps = user.referalDeps;
    }

    function getDepositInfo(address account, uint256 i) public view returns(bool active, uint256 startUnix, uint256 amount, uint256 timePassed, uint256 dailyAmount, uint256 evenUnix, uint256 avialable, uint256 withdrawn, uint256 finishAmount, uint256 finishUnix) {
        User storage user = users[account];

        amount = user.deposits[i].amount;
        withdrawn = user.deposits[i].withdrawn;
        startUnix = user.deposits[i].start;
        timePassed = block.timestamp - startUnix;
        evenUnix = startUnix + (PERIOD / 3);
        finishUnix = startUnix + PERIOD;
        dailyAmount = amount * 2 / 100;
        finishAmount = amount * ROI / PERCENTS_DIVIDER;

        if (withdrawn < finishAmount) {
            if (block.timestamp >= finishUnix) {
                avialable = finishAmount - withdrawn;
                active = false;
            } else {
                uint256 from = startUnix > user.checkpoint ? startUnix : user.checkpoint;
                uint256 to = block.timestamp;
                avialable = finishAmount * (to - from) / PERIOD;
                active = true;
            }
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function bytesToAddress(bytes memory _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }

}