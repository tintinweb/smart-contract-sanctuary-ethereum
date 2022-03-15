/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-11
*/

pragma solidity 0.5.10;

contract BNBInvestCommonFinal{
	using SafeMath for uint256;

	uint256[] public INVEST_MIN_AMOUNT = [0.001 ether]; 
	uint256[] public INVEST_MAX_AMOUNT = [1000 ether]; 
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public CEO_FEE = 9;

	uint256 public totalInvested;
	uint256 public totalUsers;

	address payable public ceoWallet;
	uint256 public startDate;

	struct Deposit {
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
        uint256 userid;
        address useraddress;
		uint256 withdrawn;
		uint256 walletBalanceAmount;
		uint256 checkpoint;
		uint bonus;
	}

	struct BetDeposit{
		address plan;
		uint256 amount;	
		uint256 start;
        uint256 betID;	
	}

	struct BetUser{
		BetDeposit[] betdeposits;
	}

	mapping(address => uint256) public balanceOf;

	uint256 constant public TIME_STEP = 1 days;

	mapping (address => User) internal users;

	mapping (address => BetUser) internal betusers;	
	
	event NewDeposit(address indexed user, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);

	constructor(address payable ceoAddr, uint256 start) public {
			require(!isContract(ceoAddr));
			ceoWallet = ceoAddr;
			
			if(start>0){
				startDate = start;
			}
			else{
				startDate = block.timestamp;
			}

		}

	function invest() public payable {

       balanceOf[msg.sender] += msg.value;

		User storage user = users[msg.sender];

		user.deposits.push(Deposit(msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

        totalUsers=totalUsers.add(1);

        user.userid = totalUsers;

        user.useraddress = msg.sender;

		user.walletBalanceAmount = user.walletBalanceAmount.add(msg.value);
		
		emit NewDeposit(msg.sender, msg.value, block.timestamp);
	}

	function betplaydata(address useraddress, uint256 betID) public payable {
		require(msg.value <= balanceOf[useraddress]);
        balanceOf[useraddress] -= msg.value;
		BetUser storage betuser = betusers[useraddress];    
		betuser.betdeposits.push(BetDeposit(useraddress, msg.value, block.timestamp, betID));

		uint256 ceo = msg.value.mul(CEO_FEE).div(PERCENTS_DIVIDER);
		ceoWallet.transfer(ceo);
	}

	function transferBalanceUserAccount(address useraddress) public payable {
		require(msg.value <= balanceOf[useraddress]);
        balanceOf[useraddress] += msg.value;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserMainWalletBalance(address userAddress) public view returns (uint256) {
		return users[userAddress].walletBalanceAmount;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function walletBalance(address userAddress)public view returns (uint256 amount){
		uint256 totalwallet_balance  = balanceOf[userAddress];
		return totalwallet_balance;
	}

		
	function withdraw() public payable {
        require(msg.value <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= msg.value;
        msg.sender.transfer(msg.value);

		User storage user = users[msg.sender];
		user.withdrawn = user.withdrawn.add(msg.value);
       
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}
	library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function randomno(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: randomno by zero");
        uint256 c = a / b;

        return c;
    }
}