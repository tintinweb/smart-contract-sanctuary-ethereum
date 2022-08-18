// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract  Subscribed {


    struct User {
        uint id;
        uint types;
        uint subtime;
        bool isAdd;
        address referrer;
    }


  //  function users 
    mapping(address => User) public users;
    //  function users(address _users) external view returns(User memory);
	
	function isUserExists(address _user) public view returns(bool) {
        return users[_user].id>0;
    }
	
   function isDeposited(address _user) public view returns(bool) {
        return users[_user].types>0;
    }

}


contract IdoLock{

    struct User {
        uint id;  
        uint starttime; 
        uint released; 
        address referrer; 
        bool isUnlock;
    }

	mapping(address => User) public users; 

	function isUserExists(address _user) public view returns(bool) {   
        return users[_user].id>0;
    }


}


 
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function getAmountsOut(uint amountIn, address[] memory path) view
        external returns (uint[] memory amounts);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
 
contract Ownable is Context {
    address internal _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Farmerex is Ownable {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 600e18;
	uint256 constant public BASE_PERCENT = 116;
	uint256[] public REFERRAL_PERCENTS = [10, 30, 50,7,6,5,4,3,2,1];

	uint256 constant public PERCENTS_DIVIDER = 10000;

	uint256 constant public TIME_STEP = 1 days;

	uint256 public strartTime;



	

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;


	IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;


	address public usdt;
	address public ETP;
	address public ETC;
	address public ETPAssetsManager;
	address public usdtLpPoolManager;


	address public DAO;
	address public IEO;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 directNumber;
		uint256 referDeposits;
		uint256 referCount;
	}

	mapping (address => User) public users;
	
	mapping (address => uint256) public userWithdrawn;
	mapping (address => uint256) public userUsdtIncome;
	
	mapping (address => uint256) public userReferralBonus;

	mapping(address => address[]) public directAddresses;
	

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 usdtAmount,uint256 etpAmont);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event Reinvest(address sender,uint256 amount);
	event ExchangeEtp(address indexed user,uint256 usdtIncome,uint256 etpIncome);

	
	constructor() {
		usdt = 0x709f4Db920B39Fe50430911EF06706E62331799a;
		ETP = 0x574D7960474817c4C508C491bfD9c8715a07f74f;
		ETC = 0x1e7f7d67F5da2C1b00aE0959cb8fe9ba41cBFd7C;
		ETPAssetsManager = 0x65518F078Ea391fdFFa3ebe916778b70440116D7;
		usdtLpPoolManager = 0x65518F078Ea391fdFFa3ebe916778b70440116D7;
		strartTime = block.timestamp;
		_owner = msg.sender;

		DAO = 0x0d3ec695Ba989225199366c85406913A4BCF1026;
		IEO= 0x02CdB655A24E75B389e235f280D6b7961172e8ad;
	
	}

	function setDAO(address dao_)public onlyOwner{
		DAO = dao_;
	}
	function setIEO(address ieo_) public onlyOwner{
		IEO = ieo_;
	}



	
	function setETCAddress(address ETC_)external onlyOwner{
		ETC = ETC_;
	}


	function setUsdtAddress(address usdt_) external onlyOwner{
		usdt = usdt_;
	}

	function setETPAddress(address ETP_)external onlyOwner{
		ETP = ETP_;
	}


	function setUsdtLpPoolManager(address usdtLpPoolManager_) external onlyOwner{
		usdtLpPoolManager = usdtLpPoolManager_;
	}


	function setETPAssetsManager(address ETPAssetsManager_)external onlyOwner{
		ETPAssetsManager = ETPAssetsManager_;
	}

	function getDaoOrIeoRefer(address userAddress_) public view returns(address){
		bool isUserDao = Subscribed(DAO).isUserExists(userAddress_);
		
		if(isUserDao){

			 ( , , ,,address referrer) =  Subscribed(DAO).users(userAddress_);
			return referrer;
		}
		bool isUserIeo = IdoLock(IEO).isUserExists(userAddress_);
		if(isUserIeo){
 			( ,  ,,address referrer,) =  IdoLock(IEO).users(userAddress_);
			return referrer;
		}

		return address(0);

	}



	function getReferLeval(address useraddress_) public view returns(uint256){
			uint256 leval;
			if(users[useraddress_].directNumber > 10){
				leval =  10;
			}else{
				leval =  users[useraddress_].directNumber;
			}	
			return leval;
	}



	function swapTokensForTokens(uint256 tokenAmount,address to) private {
        
        address[] memory path = new address[](2);
        path[0] = usdt;
		path[1] = ETP;
        
 
        IERC20(usdt).approve(address(uniswapV2Router), tokenAmount);
       
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            to,
            block.timestamp
        );
    }



	function exchangeEtp() public returns(uint256) {

		uint256 income =  userUsdtIncome[msg.sender];
		uint256 etpBonus;
		if(income > 0){

			etpBonus =  getEtpAmoutOunt(income);
			userUsdtIncome[msg.sender] = 0;
			IERC20(ETP).transferFrom(ETPAssetsManager,msg.sender,etpBonus);
			emit ExchangeEtp(msg.sender,income,etpBonus);

		}

		return etpBonus;

	}


	
	function invest(address referrer,uint256 usdt_ ) public  {
		require(usdt_ >= INVEST_MIN_AMOUNT);	

		IERC20(usdt).transferFrom(msg.sender, address(this),usdt_);

		uint etpAmount =  getEtpAmoutOunt(usdt_);

		swapTokensForTokens(usdt_,address(this));

		IERC20(ETP).transferFrom(msg.sender,address(this),  etpAmount);
		uint256 curEtpBalance =  IERC20(ETP).balanceOf(address(this));

		IERC20(ETP).transfer(address(0),curEtpBalance);


		

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && referrer != msg.sender) {
			
			address direfer = 	getDaoOrIeoRefer(msg.sender);
			if(direfer!= address(0)){
				referrer = direfer;
			}



			user.referrer = referrer;

			if(directAddresses[msg.sender].length <= 10){

				directAddresses[msg.sender].push(referrer);
			}
			
			User storage userRefer = users[referrer];
			userRefer.directNumber ++;
		}


		if (user.deposits.length == 0) {

			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		}

		user.deposits.push(Deposit(usdt_.mul(2), 0, block.timestamp));

		totalInvested = totalInvested.add(usdt_.mul(2));

		totalDeposits = totalDeposits.add(1);



		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {				
					users[upline].referCount = users[upline].referCount+1;
					users[upline].referDeposits = users[upline].referDeposits.add(usdt_.mul(2));
					upline = users[upline].referrer;
				} else break;
			}
		}


		emit NewDeposit(msg.sender, usdt_,etpAmount);

	}

	function getuserInfo(address userAddress_) public view returns(uint256 totalDeposits_,uint256 teamSize ,uint256 teamDeposits){

		totalDeposits_ = getUserTotalDeposits(userAddress_);
		User memory user = users[userAddress_];
		teamSize = user.referCount;
		teamDeposits = user.referDeposits;
	}

	function getDays() public view returns(uint256){
		return	(block.timestamp).sub(strartTime).div(1 days);
		

	}
	

    function getEtpAmoutOunt(uint usdTotal) public view returns (uint ){

        address[] memory path = new address[](2);
		path[0] = usdt;
	    path[1] = ETP;
       return uniswapV2Router.getAmountsOut(usdTotal,path)[0];

        
    }

	function withdraw() public {
	
		User storage user = users[msg.sender];
				
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		address upline = user.referrer;
		for(uint256 i = 0;i<=9;i++){
			if (upline != address(0)) {
					if(getReferLeval(upline)> (i)) {
						uint256 amount = dividends.mul(REFERRAL_PERCENTS[i]).div(100);
						users[upline].bonus = users[upline].bonus.add(amount); //动态奖励
						emit RefBonus(upline, msg.sender, i, amount);
						upline = users[upline].referrer;
						
					}
					
				} else break;
		}


		uint256 referralBonus = getUserReferralBonus(msg.sender);
		
		userReferralBonus[msg.sender] = userReferralBonus[msg.sender].add(referralBonus);
		
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

	

		uint256 userTotalDeposit =  getUserTotalDeposits(msg.sender);
		if(totalAmount > userTotalDeposit.mul(3).sub(userWithdrawn[msg.sender]) ){

			totalAmount = userTotalDeposit.mul(3).sub(userWithdrawn[msg.sender]) ;
		}

		user.checkpoint = block.timestamp;
		
		userWithdrawn[msg.sender] = userWithdrawn[msg.sender].add(totalAmount);
	
		userUsdtIncome[msg.sender] = userUsdtIncome[msg.sender].add(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);
		
		user.checkpoint = block.timestamp;

		emit Withdrawn(msg.sender, totalAmount.mul(70).div(100));

	}



	//获取静态收益
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

	

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(3)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(3)) {
					dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	//查询用户动态奖励
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		uint256 availableAmount =   getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
		uint256 amount3 =  getUserTotalDeposits(userAddress).mul(3).sub(userWithdrawn[userAddress]);
		if(amount3 < availableAmount){
			return amount3;
		}
		return availableAmount;
	}

	function isActive(address userAddress) public view returns (bool) {
		User memory user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(3)) {
				return true;
			}
		}

		return false;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User memory user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User memory user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
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
}