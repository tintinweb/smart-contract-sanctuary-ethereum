/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract StableOneV2 is Ownable {
    using SafeMath for uint256;

    uint256 private constant PRIMARY_BENIFICIARY_INVESTMENT_PERC = 100;
    uint256 private constant PRIMARY_BENIFICIARY_REINVESTMENT_PERC = 60;

    uint256 private constant MIN_WITHDRAW = 0.02 ether;
    uint256 private constant MIN_INVESTMENT = 0.05 ether;
    uint256 private constant TIME_STEP = 1 days;
    // uint256 private constant TIME_STEP = 10; //fast test mode
    uint256 private constant DAILY_INTEREST_RATE = 70;
    uint256 private constant DAILY_AUTO_REINTEREST_RATE = 210;
    uint256 private constant ON_WITHDRAW_AUTO_REINTEREST_RATE = 250;
	uint256 private constant PERCENTS_DIVIDER = 1000;
	uint256 private constant TOTAL_RETURN = 2100;
	uint256 private constant TOTAL_REF = 105;
	uint256[] private REFERRAL_PERCENTS = [50, 30, 15, 5, 5];

    address payable public primaryBenificiary;

    uint256 public totalInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReinvested;
    uint256 public totalReferralReward;

    struct Investor {
        address addr;
        address ref;
        uint256[5] refs;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest;
        uint256 dividends;
        uint256 totalRef;
        uint256 investmentCount;
		uint256 depositTime;
		uint256 lastWithdrawDate;
    }

    mapping(address => Investor) public investors;

    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
	event OnWithdraw(address investor, uint256 amount); 

    constructor( address payable _primaryAddress ) {
        require( _primaryAddress != address(0), "Primary address cannot be null" );
        primaryBenificiary = _primaryAddress;
    }

    function changePrimaryBenificiary(address payable newAddress)
        public
        onlyOwner
    {
        require(newAddress != address(0), "Address cannot be null");
        primaryBenificiary = newAddress;
    }

    function invest(address _ref) public payable{
        if (_invest(msg.sender, _ref, msg.value)) {
            emit OnInvest(msg.sender, msg.value);
        }
    }

    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _invest(address _addr, address _ref, uint256 _amount ) private returns (bool){
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.05 Matic");
        require(_ref != _addr, "Ref address cannot be same with caller");

        Investor storage _investor = investors[_addr];
        if (_investor.addr == address(0)) {
            _investor.addr = _addr;
            _investor.depositTime = block.timestamp;
            _investor.lastWithdrawDate = block.timestamp;
        }

        if (_investor.ref == address(0)) {
			if (investors[_ref].totalDeposit > 0) {
				_investor.ref = _ref;
			}

			address upline = _investor.ref;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
                   investors[upline].refs[i] =investors[upline].refs[i].add(1);
					upline = investors[upline].ref;
				} else break;
			}
		}

		if (_investor.ref != address(0)) {
			address upline = _investor.ref;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					investors[upline].totalRef = investors[upline].totalRef.add(amount);
					totalReferralReward = totalReferralReward.add(amount);
					payable(upline).transfer(amount);
					upline = investors[upline].ref;
				} else break;
			}
		}else{
			uint256 amount = _amount.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
			primaryBenificiary.transfer(amount);
			totalReferralReward = totalReferralReward.add(amount);
		}

        if(block.timestamp > _investor.depositTime){
            _investor.dividends = getDividends(_addr);
        }
        _investor.depositTime = block.timestamp;
        _investor.investmentCount = _investor.investmentCount.add(1);
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        totalInvested = totalInvested.add(_amount);

        _sendRewardOnInvestment(_amount);
        return true;
    }

    function _reinvest(address _addr,uint256 _amount) private returns(bool){
        Investor storage _investor = investors[_addr];
        require(_investor.totalDeposit > 0, "not active user");

        if(block.timestamp > _investor.depositTime){
            _investor.dividends = getDividends(_addr);
        }
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        _investor.totalReinvest = _investor.totalReinvest.add(_amount);
        totalReinvested = totalReinvested.add(_amount);

        _sendRewardOnReinvestment(_amount);
        return true;
    }

    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount.mul(PRIMARY_BENIFICIARY_INVESTMENT_PERC).div(1000);
        primaryBenificiary.transfer(rewardForPrimaryBenificiary);
    }
    
    function _sendRewardOnReinvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount.mul(PRIMARY_BENIFICIARY_REINVESTMENT_PERC).div(1000);
        primaryBenificiary.transfer(rewardForPrimaryBenificiary);
    }


    function payoutOf(address _addr) view public returns(uint256 payout, uint256 max_payout) {
        max_payout = investors[_addr].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);

        if(investors[_addr].totalWithdraw < max_payout && block.timestamp > investors[_addr].depositTime) {
            payout = investors[_addr].totalDeposit.mul(DAILY_INTEREST_RATE).mul(block.timestamp.sub(investors[_addr].depositTime)).div(
                TIME_STEP.mul(PERCENTS_DIVIDER)
            );
            payout = payout.add(investors[_addr].dividends);

            if(investors[_addr].totalWithdraw.add(payout) > max_payout) {
                payout = max_payout.subz(investors[_addr].totalWithdraw);
            }
        }
    }

    function getDividends(address addr) public view returns (uint256) {
        uint256 dividendAmount = 0;
        (dividendAmount,) = payoutOf(addr);
        return dividendAmount;
    }

    function getContractInformation()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        ){
        uint256 contractBalance = getBalance();
        return (
            contractBalance,
            totalInvested,
            totalWithdrawal,
            totalReinvested,
            totalReferralReward
        );
    }
    
    function reinvest() public {
		require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 24 hours");
        uint256 dividendAmount = getDividends(msg.sender);

        //21% daily reinvestment
        uint256 _amountToReinvest = dividendAmount
                .mul(DAILY_AUTO_REINTEREST_RATE)
                .div(1000);
        _reinvest(msg.sender, _amountToReinvest);
        investors[msg.sender].lastWithdrawDate = block.timestamp;
		investors[msg.sender].depositTime = block.timestamp;
        
    }

    function withdraw() public {
		require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 24 hours");
        uint256 _amountToReinvest=0;
		uint256 _reinvestAmount=0;
		uint256 totalToReinvest=0;
        uint256 max_payout = investors[msg.sender].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
        uint256 dividendAmount = getDividends(msg.sender);

        if(investors[msg.sender].totalWithdraw.add(dividendAmount) > max_payout) {
                dividendAmount = max_payout.subz(investors[msg.sender].totalWithdraw);
        }

        require(dividendAmount >= MIN_WITHDRAW, "min withdraw amount is 0.02 matic");

        //21% daily reinvestment
        _amountToReinvest = dividendAmount
                .mul(DAILY_AUTO_REINTEREST_RATE)
                .div(1000);

        //25% reinvest on withdraw
        _reinvestAmount = dividendAmount
            .mul(ON_WITHDRAW_AUTO_REINTEREST_RATE)
            .div(1000);

        totalToReinvest = _amountToReinvest.add(_reinvestAmount);

        _reinvest(msg.sender, totalToReinvest);

        uint256 remainingAmount = dividendAmount.subz(_reinvestAmount);
        
        totalWithdrawal = totalWithdrawal.add(remainingAmount);

        if(remainingAmount > getBalance()){
            remainingAmount = getBalance();
        }

        investors[msg.sender].totalWithdraw = investors[msg.sender].totalWithdraw.add(dividendAmount);
		investors[msg.sender].lastWithdrawDate = block.timestamp;
		investors[msg.sender].depositTime = block.timestamp;
		investors[msg.sender].dividends = 0;

        payable(msg.sender).transfer(remainingAmount);
		emit OnWithdraw(msg.sender, remainingAmount);
    }
    
    function getInvestorRefs(address addr)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Investor storage investor = investors[addr];
        return (
            investor.refs[0],
            investor.refs[1],
            investor.refs[2],
            investor.refs[3],
            investor.refs[4]
        );
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

    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}