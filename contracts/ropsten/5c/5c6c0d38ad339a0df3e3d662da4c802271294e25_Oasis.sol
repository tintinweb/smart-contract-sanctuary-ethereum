pragma solidity ^ 0.4.25;

// ----------------------------------------------------------------------------
// 安全的加减乘除
// ----------------------------------------------------------------------------
library SafeMath {
	function add(uint a, uint b) internal pure returns(uint c) {
		c = a + b;
		require(c >= a);
	}

	function sub(uint a, uint b) internal pure returns(uint c) {
		require(b <= a);
		c = a - b;
	}

	function mul(uint a, uint b) internal pure returns(uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}

	function div(uint a, uint b) internal pure returns(uint c) {
		require(b > 0);
		c = a / b;
	}
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
	function totalSupply() public constant returns(uint);

	function balanceOf(address tokenOwner) public constant returns(uint balance);

	function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

	function transfer(address to, uint tokens) public returns(bool success);

	function approve(address spender, uint tokens) public returns(bool success);

	function transferFrom(address from, address to, uint tokens) public returns(bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// 管理员
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

// ----------------------------------------------------------------------------
// 核心类
// ----------------------------------------------------------------------------
contract Oasis is ERC20Interface, Owned {
	using SafeMath
	for uint;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint _totalSupply;
	uint basekeynum;//4500
	uint basekeysub;//500
	uint basekeylast;//2000
    uint startprice;
    uint startbasekeynum;//4500
    uint startbasekeylast;//2000
	
	bool public actived;

	
	uint public keyprice;//钥匙的价格
	uint public keysid;//当前钥匙的最大id
	uint public onceOuttime;
	
	
	uint8 public per;//用户每日静态的释放比例
	uint public allprize;
	uint public allprizeused;
	
	uint[] public mans;//用户上线人数的数组
	uint[] public pers;//用户上线分额的比例数组
	uint[] public prizeper;//用户每日静态的释放比例
	uint[] public prizelevelsuns;//用户上线人数的数组
	uint[] public prizelevelmans;//用户上线人数的比例数组
	address[] public level1;
	address[] public level2;
	address[] public level3;
	uint[] public prizelevelsunsday;//用户上线人数的数组
	uint[] public prizelevelmansday;//用户上线人数的比例数组
	uint[] public prizeactivetime;
	
	address[] public mansdata;
	uint[] public moneydata;
	uint[] public timedata;
	uint public pubper;
	uint public subper;
	uint public luckyper;
	uint public lastmoney;
	uint public lastper;
	uint public lasttime;
	uint public sellkeyper;
	
	bool public isend;
	uint public tags;
	uint public opentime;
	
	uint public runper;
	uint public sellper;
	uint public sysday;
	uint public cksysday;

	mapping(address => uint) balances;//用户的钥匙数量
	
	mapping(address => uint) systemtag;//用户的系统标志 
	mapping(address => uint) eths;//用户的资产数量
	mapping(address => uint) usereths;//用户的总投资
	mapping(address => uint) userethsused;//用户的总投资
	mapping(address => uint) runs;//用户的动态奖励
	mapping(address => uint) used;//用户已使用的资产
	mapping(address => uint) runused;//用户已使用的动态
	mapping(address => mapping(address => uint)) allowed;//授权金额

	/* 冻结账户 */
	mapping(address => bool) public frozenAccount;

	//释放 
	mapping(address => uint[]) public mycantime; //时间
	mapping(address => uint[]) public mycanmoney; //金额
	//上线释放
	mapping(address => uint[]) public myruntime; //时间
	mapping(address => uint[]) public myrunmoney; //金额
	//上家地址
	mapping(address => address) public fromaddr;
	//一代数组
	mapping(address => address[]) public mysuns;
	//2代数组
	mapping(address => address[]) public mysecond;
	//3代数组
	mapping(address => address[]) public mythird;
	//all 3代数组days moeny
	//mapping(address => mapping(uint => uint)) public mysunsdayget;
	//all 3代数组days moeny
	mapping(address => mapping(uint => uint)) public mysunsdaynum;
	//current day prize
	mapping(address => mapping(uint => uint)) public myprizedayget;
	mapping(address => mapping(uint => uint)) public myprizedaygetdata;
	//管理员帐号
	mapping(address => bool) public admins;
	//用户钥匙id
	mapping(address => uint) public mykeysid;
	//与用户钥匙id对应
	mapping(uint => address) public myidkeys;
	mapping(address => uint) public mykeyeths;
	mapping(address => uint) public mykeyethsused;
	
	//all once day get all
	mapping(uint => uint) public daysgeteths;
	mapping(uint => uint) public dayseths;
	//user once day pay
	mapping(address => mapping(uint => uint)) public daysusereths;
	
	mapping(uint => uint)  public ethnum;//用户总资产
	mapping(uint => uint)  public sysethnum;//系统总eth
	mapping(uint => uint)  public userethnum;//用户总eth
	mapping(uint => uint)  public userethnumused;//用户总eth
	mapping(uint => uint)  public syskeynum;//系统总key

	/* 通知 */
	event FrozenFunds(address target, bool frozen);
	modifier onlySystemStart() {
        require(actived == true);
	    require(isend == false);
	    require(tags == systemtag[msg.sender]);
	    require(!frozenAccount[msg.sender]);
        _;
    }
	// ------------------------------------------------------------------------
	// Constructor
	// ------------------------------------------------------------------------
	constructor() public {

		symbol = "OASIS";
		name = "Oasis Key";
		decimals = 18;
		
		_totalSupply = 50000000 ether;
	
		actived = true;
		tags = 0;
		ethnum[0] = 0;
		sysethnum[0] = 0;
		userethnum[0] = 0;
		userethnumused[0] = 0;
		//onceOuttime = 16 hours; //增量的时间 正式 
		onceOuttime = 20 seconds;//test
        keysid = 55555;
        
        //basekeynum = 2000 ether;
        //basekeysub = 500 ether;
        //basekeylast = 2500 ether;
        //startbasekeynum = 2000 ether;
        //startbasekeylast = 2500 ether;
        basekeynum = 20 ether;//test
        basekeysub = 5 ether;//test
        basekeylast = 25 ether;//test
        startbasekeynum = 20 ether;//test
        startbasekeylast = 25 ether;//test
        allprize = 0;
		balances[this] = _totalSupply;
		per = 15;
		runper = 20;
		mans = [2,4,6];
		pers = [20,15,10];
		prizeper = [2,2,2];
		//prizelevelsuns = [20,30,50];
		//prizelevelmans = [100,300,800];
		//prizelevelsunsday = [2,4,6];
		//prizelevelmansday = [10 ether,30 ether,50 ether];
		
		prizelevelsuns = [2,3,5];//test
		prizelevelmans = [3,5,8];//test
		prizelevelsunsday = [1,2,3];//test
		prizelevelmansday = [1 ether,3 ether,5 ether];//test
		
		prizeactivetime = [0,0,0];
		pubper = 2;
		subper = 120;
		luckyper = 5;
		lastmoney = 0;
		lastper = 2;
		//lasttime = 8 hours;
		lasttime = 300 seconds;//test
		//sysday = 1 days;
		//cksysday = 8 hours;
		sysday = 1 hours; //test
		cksysday = 0 seconds;//test
		
		keyprice = 0.01 ether;
		startprice = 0.01 ether;
		//keyprice = 0.0001 ether;//test
		sellkeyper = 30;
		sellper = 10;
		isend = false;
		opentime = now;
		//userethnum = 0;
		//sysethnum = 0;
		//balances[owner] = _totalSupply;
		emit Transfer(address(0), this, _totalSupply);

	}

	/* 获取用户金额 */
	function balanceOf(address tokenOwner) public view returns(uint balance) {
		return balances[tokenOwner];
	}
	function getper() public view returns(uint onceOuttimes, uint perss,uint runpers, 
	uint pubpers, uint subpers, uint luckypers, uint lastpers, uint sellkeypers, uint sellpers,
	uint lasttimes, uint sysdays, uint cksysdays) {
	    onceOuttimes = onceOuttime;//0
	    perss = per;//1
	    runpers = runper;//2
	    pubpers = pubper;//3
	    subpers = subper;//4
	    luckypers = luckyper;//5
	    lastpers = lastper;//6
	    sellkeypers = sellkeyper;//7
	    sellpers = sellper;//8
	    lasttimes = lasttime;//9
	    sysdays = sysday;//10
	    cksysdays = cksysday;//11
	    
	}
	function setper(uint onceOuttimes, uint8 perss,uint runpers, 
	uint pubpers, uint subpers, uint luckypers, uint lastpers, uint sellkeypers, uint sellpers,
	uint lasttimes, uint sysdays, uint cksysdays) onlyOwner public {
	    onceOuttime = onceOuttimes;
	    per = perss;
	    runper = runpers;
	    pubper = pubpers;
	    subper = subpers;
	    luckyper = luckypers;
	    lastper = lastpers;
	    sellkeyper = sellkeypers;
	    sellper = sellpers;
	    lasttime = lasttimes;//9
	    sysday = sysdays;
	    cksysday = cksysdays;
	}
	function indexview(address addr) public view returns(uint keynum,
	uint kprice, uint ethss, uint ethscan, uint level, 
	uint keyid, uint runsnum, uint runscan,
	uint userethnums,uint daysethss,
	uint lttime,uint lastimes
	 ){
	     uint d = gettoday();
	    keynum = balances[addr];//0
	    kprice = keyprice;//1
	    ethss = eths[addr];//2
	    ethscan = getcanuse(addr);//3
	    level = getlevel(addr);//4
	    keyid = mykeysid[addr];//5
	    runsnum = runs[addr];//6
	    runscan = getcanuserun(addr);//7
	    userethnums = userethnum[tags]; //8 all
	    daysethss = dayseths[d]; //9
	    
	    if(timedata.length == 0) {
	        lttime = opentime;//10
	    }else{
	        lttime = timedata[timedata.length - 1];
	    }
	    lastimes = lasttime;//11
	    
	}
	function indexextend(address addr) public view returns(address lkuser,
	uint top1num, uint top2num, uint top3num, uint yestodaycom, uint todaycom, uint lastmoneys,
	uint tagss, uint mytags){
	    
	    uint t = getyestoday();
	    uint d = gettoday();
	    lkuser = getluckyuser();//0
	    top1num = mysuns[addr].length;//1
	    top2num = mysecond[addr].length;//2
	    top3num = mythird[addr].length;//3
	    yestodaycom = myprizedaygetdata[addr][t];//4
	    todaycom = myprizedaygetdata[addr][d];//5
	    lastmoneys = lastmoney;//6
	    tagss = tags;//7
	    mytags = systemtag[addr];//8
	}
	function gettags(address addr) public view returns(uint t) {
	    t = systemtag[addr];
	}
	/*
	 * 添加金额，为了统计用户的进出
	 */
	function addmoney(address _addr, uint256 _money, uint _day) private {
	    uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		mycanmoney[_addr].push(_money);
		mycantime[_addr].push(_now);

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducemoney(address _addr, uint256 _money) private {
		used[_addr] += _money;
	}
	/*
	 * 添加run金额，为了统计用户的进出
	 */
	function addrunmoney(address _addr, uint256 _money, uint _day) private {
		uint256 _days = _day * (1 days);
		uint256 _now = now - _days;
		myrunmoney[_addr].push(_money);
		myruntime[_addr].push(_now);

	}
	/*
	 * 用户金额减少时的触发
	 * @param {Object} address
	 */
	function reducerunmoney(address _addr, uint256 _money) private {
		runused[_addr] += _money;
	}
	function geteths(address addr) public view returns(uint) {
	    return(eths[addr]);
	}
	function getruns(address addr) public view returns(uint) {
	    return(runs[addr]);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getcanuse(address tokenOwner) public view returns(uint) {
		uint256 _now = now;
		uint256 _left = 0;
		/*
		if(tokenOwner == owner) {
			return(eths[owner]);
		}*/
		for(uint256 i = 0; i < mycantime[tokenOwner].length; i++) {
			uint256 stime = mycantime[tokenOwner][i];
			uint256 smoney = mycanmoney[tokenOwner][i];
			uint256 lefttimes = _now - stime;
			if(lefttimes >= onceOuttime) {
				uint256 leftpers = lefttimes / onceOuttime;
				if(leftpers > 100) {
					leftpers = 100;
				}
				_left = smoney * leftpers / 100 + _left;
			}
		}
		_left = _left - used[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > eths[tokenOwner]) {
			return(eths[tokenOwner]);
		}
		return(_left);
	}
	/*
	 * 获取用户的可用金额
	 * @param {Object} address
	 */
	function getcanuserun(address tokenOwner) public view returns(uint) {
		uint256 _now = now;
		uint256 _left = 0;
		/*
		if(tokenOwner == owner) {
			return(runs[owner]);
		}*/
		for(uint256 i = 0; i < myruntime[tokenOwner].length; i++) {
			uint256 stime = myruntime[tokenOwner][i];
			uint256 smoney = myrunmoney[tokenOwner][i];
			uint256 lefttimes = _now - stime;
			if(lefttimes >= onceOuttime) {
				uint256 leftpers = lefttimes / onceOuttime;
				if(leftpers > 100) {
					leftpers = 100;
				}
				_left = smoney * leftpers / 100 + _left;
			}
		}
		_left = _left - runused[tokenOwner];
		if(_left < 0) {
			return(0);
		}
		if(_left > runs[tokenOwner]) {
			return(runs[tokenOwner]);
		}
		return(_left);
	}

	/*
	 * 用户转账
	 * @param {Object} address
	 */
	function _transfer(address from, address to, uint tokens) private{
	    
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		require(actived == true);
		//
		require(from != to);
		//如果用户没有上家
		// 防止转移到0x0， 用burn代替这个功能
        require(to != 0x0);
        // 检测发送者是否有足够的资金
        require(balances[from] >= tokens);
        // 检查是否溢出（数据类型的溢出）
        require(balances[to] + tokens > balances[to]);
        // 将此保存为将来的断言， 函数最后会有一个检验
        uint previousBalances = balances[from] + balances[to];
        // 减少发送者资产
        balances[from] -= tokens;
        // 增加接收者的资产
        balances[to] += tokens;
        // 断言检测， 不应该为错
        assert(balances[from] + balances[to] == previousBalances);
        
		emit Transfer(from, to, tokens);
	}
	/* 传递tokens */
    function transfer(address _to, uint256 _value) onlySystemStart() public returns(bool){
        _transfer(msg.sender, _to, _value);
        mykeyethsused[msg.sender].add(_value);
        return(true);
    }
    //激活钥匙
    function activekey() onlySystemStart() public returns(bool) {
	    address addr = msg.sender;
        uint keyval = 1 ether;
        require(balances[addr] >= keyval);
        require(mykeysid[addr] < 1);
        //require(fromaddr[addr] == address(0));
        keysid = keysid + 1;
	    mykeysid[addr] = keysid;
	    myidkeys[keysid] = addr;
	    balances[addr] -= keyval;
	    balances[owner] += keyval;
	    emit Transfer(addr, owner, keyval);
	    //transfer(owner, keyval);
	    return(true);
	    
    }
	
	/*
	 * 获取上家地址
	 * @param {Object} address
	 */
	function getfrom(address _addr) public view returns(address) {
		return(fromaddr[_addr]);
	}
    function gettopid(address addr) public view returns(uint) {
        address topaddr = fromaddr[addr];
        if(topaddr == address(0)) {
            return(0);
        }
        uint keyid = mykeysid[topaddr];
        if(keyid > 0 && myidkeys[keyid] == topaddr) {
            return(keyid);
        }else{
            return(0);
        }
    }
	function approve(address spender, uint tokens) public returns(bool success) {
	    require(actived == true);
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	/*
	 * 授权转账
	 * @param {Object} address
	 */
	function transferFrom(address from, address to, uint tokens) public returns(bool success) {
		require(actived == true);
		require(!frozenAccount[from]);
		require(!frozenAccount[to]);
		balances[from] = balances[from].sub(tokens);
		//reducemoney(from, tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		//addmoney(to, tokens, 0);
		emit Transfer(from, to, tokens);
		return true;
	}

	/*
	 * 获取授权信息
	 * @param {Object} address
	 */
	function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
		return allowed[tokenOwner][spender];
	}

	/*
	 * 授权
	 * @param {Object} address
	 */
	function approveAndCall(address spender, uint tokens, bytes data) public returns(bool success) {
		//require(admins[msg.sender] == true);
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
		return true;
	}

	/// 冻结 or 解冻账户
	function freezeAccount(address target, bool freeze) public {
		require(admins[msg.sender] == true);
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	/*
	 * 设置管理员
	 * @param {Object} address
	 */
	function admAccount(address target, bool freeze) onlyOwner public {
		admins[target] = freeze;
	}
	
	/*
	 * 设置是否开启
	 * @param {Object} bool
	 */
	function setactive(bool t) public onlyOwner {
		actived = t;
	}

	
	/*
	 * 向账户拨发资金
	 * @param {Object} address
	 */
	function mintToken(address target, uint256 mintedAmount) public onlyOwner{
		require(!frozenAccount[target]);
		require(actived == true);
		balances[target] = balances[target].add(mintedAmount);
		balances[this] = balances[this].sub(mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}
	
	/*
	 * 获取总账目
	 */
	function getall() public view returns(uint256 money) {
		money = address(this).balance;
	}
	function getmykeyid(address addr) public view returns(uint ky) {
	    ky = mykeysid[addr];
	}
	function getyestoday() public view returns(uint d) {
	    uint today = gettoday();
	    d = today - sysday;
	}
	function gettormow() public view returns(uint d) {
	    uint today = gettoday();
	    d = today + sysday;
	}
	function gettoday() public view returns(uint d) {
	    uint n = now;
	    d = n - n%sysday - cksysday;
	}
	function gettodayget() public view returns(uint m) {
	    uint d = gettoday();
	    m = daysgeteths[d];
	}
	function getyestodayget() public view returns(uint m) {
	    uint d = getyestoday();
	    m = daysgeteths[d];
	}
	
	function getlevel(address addr) public view returns(uint) {
	    uint num1 = mysuns[addr].length;
	    uint num2 = mysecond[addr].length;
	    uint num3 = mythird[addr].length;
	    uint nums = num1 + num2 + num3;
	    if(num1 >= prizelevelsuns[2] && nums >= prizelevelmans[2]) {
	        return(3);
	    }
	    if(num1 >= prizelevelsuns[1] && nums >= prizelevelmans[1]) {
	        return(2);
	    }
	    if(num1 >= prizelevelsuns[0] && nums >= prizelevelmans[0]) {
	        return(1);
	    }
	    return(0);
	}
	/*
	function setprize(address addr, uint money) private returns(bool){
	    uint level = getlevel(addr);
	    uint d = gettoday();
	    allprize.add(money);
	    if(level > 0) {
	        uint p = level - 1;
	        uint ps = money*prizeper[p]/100;
	        
	        myprizedayget[addr][d].add(ps);
	    }
	    return(true);
	}*/
	function gettruelevel(uint n, uint m) public view returns(uint) {
	    if(n >= prizelevelsunsday[2] && m >= prizelevelmansday[2]) {
	        return(2);
	    }
	    if(n >= prizelevelsunsday[1] && m >= prizelevelmansday[1]) {
	        return(1);
	    }
	    if(n >= prizelevelsunsday[0] && m >= prizelevelmansday[0]) {
	        return(0);
	    }
	    
	}
	function getprize() onlySystemStart() public returns(bool) {
	    uint d = getyestoday();
	    address user = msg.sender;
	    uint level = getlevel(user);
	   
	    uint money = myprizedayget[user][d];
	    uint mymans = mysunsdaynum[user][d];
	    if(level > 0 && money > 0) {
	        uint p = level - 1;
	        uint activedtime = prizeactivetime[p];
	        require(activedtime > 0);
	        require(activedtime < now);
	        uint allmoney = allprize - allprizeused;
	        if(now - activedtime > sysday) {
	            p = gettruelevel(mymans, money);
	        }
	        uint ps = allmoney*prizeper[p]/100;
	        eths[user] = eths[user].add(ps);
	        addmoney(user, ps, 100);
	        myprizedayget[user][d] = myprizedayget[user][d].sub(money);
	        allprizeused = allprizeused.add(money);
	    }
	}
	function setactivelevel(uint level) private returns(bool) {
	    uint t = prizeactivetime[level];
	    if(t == 0) {
	        prizeactivetime[level] = now + sysday;
	    }
	    return(true);
	}
	function getactiveleveltime(uint level) public view returns(uint t) {
	    t = prizeactivetime[level];
	}
	function setuserlevel(address user) onlySystemStart() public returns(bool) {
	    uint level = getlevel(user);
	    bool has = false;
	    if(level == 1) {
	        
	        for(uint i = 0; i < level1.length; i++) {
	            if(level1[i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            level1.push(user);
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        if(has == true) {
	            for(uint ii = 0; ii < level1.length; ii++) {
    	            if(level1[ii] == user) {
    	                delete level1[ii];
    	            }
    	        }
    	        level2.push(user);
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(uint i2 = 0; i2 < level2.length; i2++) {
    	            if(level1[i2] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            level2.push(user);
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        if(has == true) {
	            for(uint iii = 0; iii < level2.length; iii++) {
    	            if(level2[iii] == user) {
    	                delete level2[iii];
    	            }
    	        }
    	        level3.push(user);
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(uint i3 = 0; i3 < level3.length; i3++) {
    	            if(level3[i3] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            level3.push(user);
    	            setactivelevel(2);
    	            return(true);
    	        }
	        }
	    }
	}
	
	function getfromsun(address addr, uint money, uint amount) private returns(bool){
	    address f1 = fromaddr[addr];
	    address f2 = fromaddr[f1];
	    address f3 = fromaddr[f2];
	    uint d = gettoday();
	    if(f1 != address(0)) {
	        if(mysuns[f1].length >= mans[0]) {
	            uint sendmoney1 = (money*per/1000)*pers[0]/100;
    	        runs[f1] = runs[f1].add(sendmoney1);
    	        addrunmoney(f1, sendmoney1, 0);
    	        myprizedayget[f1][d] = myprizedayget[f1][d].add(amount);
    	        myprizedaygetdata[f1][d] = myprizedaygetdata[f1][d].add(amount);
    	        //setuserlevel(f1);
    	        
	        }
	    }
	    if(f1 != address(0) && f2 != address(0)) {
	        if(mysuns[f2].length >= mans[1]) {
	            uint sendmoney2 = (money*per/1000)*pers[1]/100;
    	        runs[f2] = runs[f2].add(sendmoney2);
    	        addrunmoney(f2, sendmoney2, 0);
    	        myprizedayget[f2][d] = myprizedayget[f2][d].add(amount);
    	        myprizedaygetdata[f2][d] = myprizedaygetdata[f2][d].add(amount);
    	        //setuserlevel(f2);
	        }
	        
	        
	    }
	    if(f1 != address(0) && f2 != address(0) && f3 != address(0)) {
	        if(mysuns[f3].length >= mans[2]) {
	            uint sendmoney3 = (money*per/1000)*pers[2]/100;
    	        runs[f3] = runs[f3].add(sendmoney3);
    	        addrunmoney(f3, sendmoney3, 0);
    	        myprizedayget[f3][d] = myprizedayget[f3][d].add(amount);
    	        myprizedaygetdata[f3][d] = myprizedaygetdata[f3][d].add(amount);
    	        //setuserlevel(f3);
	        }
	    }
	    
	}
	function setpubprize(uint amount) private returns(bool) {
	    uint len = moneydata.length;
	    if(len > 1) {
	        uint all = 0;
	        uint start = 0;
	        
	        if(len > 10) {
	            start = len - 10;
	        }
	        for(uint i = start; i < len; i++) {
	            all += moneydata[i];
	        }
	        uint sendmoney = amount*pubper/100;
	        for(uint ii = start; ii < len; ii++) {
	            //all += moneydata[i];
	            address user = mansdata[ii];
	            uint m = sendmoney*moneydata[ii]/all;
	            eths[user] = eths[user].add(m);
	            addmoney(user, m, 100);
	        }
	    }
	    return(true);
	}
	function getluckyuser() public view returns(address addr) {
	    uint d = gettoday();
	    uint t = getyestoday();
	    uint maxmoney = 1 ether;
	    for(uint i = 0; i < moneydata.length; i++) {
	        if(timedata[i] > t && timedata[i] < d && moneydata[i] >= maxmoney) {
	            maxmoney = moneydata[i];
	            addr = mansdata[i];
	        }
	    }
	}
	function getluckyprize() onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(user == getluckyuser());
	    uint d = getyestoday();
	    require(daysusereths[user][d] > 0);
	    uint money = dayseths[d]*luckyper/1000;
	    eths[user] = eths[user].add(money);
	    addmoney(user, money, 100);
	}
	
	function runtoeth(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint can = getcanuserun(user);
	    uint kn = balances[user];
	    uint usekey = amount*runper/100;
	    require(usekey <= kn);
	    require(runs[user] >= can);
	    require(can >= amount);
	    
	    runs[user] = runs[user].sub(amount);
	    reducerunmoney(user, amount);
	    eths[user] = eths[user].add(amount);
	    addmoney(user, amount, 100);
	    transfer(owner, usekey);
	}
	/*
	function testtop() public view returns(address) {
	    return(fromaddr[msg.sender]);
	}
	function testtop2() public view returns(uint s) {
	    uint money = 3 ether;
	    s = (money*per/1000)*pers[0]/100;
	}*/
	/*
	 * 购买
	 */
	function buy(uint keyid) onlySystemStart() public payable returns(bool) {
		address user = msg.sender;
		require(msg.value > 0);

		uint amount = msg.value;
		require(amount >= 1 ether);
		require(usereths[user] <= 100 ether);
		uint money = amount*3;
		uint d = gettoday();
		uint t = getyestoday();
		bool ifadd = false;
		//如果用户没有上家
		if(fromaddr[user] == address(0)) {
		    if(keyid > 0 && myidkeys[keyid] != user) {
		        address topaddr = myidkeys[keyid];
		        if(topaddr != address(0)) {
		            
    		        //set sun addr
    		        fromaddr[user] = topaddr;
    		        //record suns log
    		        mysuns[topaddr].push(user);
    		        //mysunsdayget[topaddr][d].add(money);
    		        mysunsdaynum[topaddr][d]++;
    		        address top2 = fromaddr[topaddr];
    		        
    		        if(top2 != address(0)){
    		            mysecond[top2].push(user);
    		            //mysunsdayget[top2][d].add(money);
    		            mysunsdaynum[top2][d]++;
    		        }
    		        address top3 = fromaddr[top2];
    		        if(top3 != address(0)){
    		            mythird[top3].push(user);
    		            //mysunsdayget[top3][d].add(money);
    		            mysunsdaynum[top3][d]++;
    		        }
    		        ifadd = true;
		        }
		        
		        //money = money + amount;
		    }
		}else{
		    ifadd = true;
		    //money = money + amount;
		}
		if(ifadd == true) {
		    money = amount*4;
		}
		uint yestodaymoney = daysgeteths[t]*subper/100;
		if(daysgeteths[d] > yestodaymoney && yestodaymoney > 0) {
		    if(ifadd == true) {
    		    money = amount*3;
    		}else{
    		    money = amount*2;
    		}
		}
		
		sysethnum[tags] = sysethnum[tags].add(amount);
		userethnum[tags] = userethnum[tags].add(amount);
		
		
		
        if(fromaddr[user] != address(0)) {
            getfromsun(user, money, amount);
        }
		
        //setlastprize();
	    daysgeteths[d] = daysgeteths[d].add(money);
	    dayseths[d] = dayseths[d].add(amount);
	    
		daysusereths[user][d] = daysusereths[user][d].add(money);
		//public prize
		setpubprize(amount);
		mansdata.push(user);
		moneydata.push(amount);
		timedata.push(now);
		//setlastprize();
		
	    uint ltime = timedata[timedata.length - 1];
	    if(now - ltime > lasttime && lastmoney > 0) {
	        money = money.add(lastmoney*lastper/100);
	        lastmoney = 0;
	    }
		lastmoney = lastmoney.add(amount);
		ethnum[tags] = ethnum[tags].add(money);
		usereths[user] = usereths[user].add(amount);
		eths[user] = eths[user].add(money);
		addmoney(user, money, 0);
		return(true);
	}
	function keybuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    require(amount > balances[user]);
	    require(amount >= 1 ether);
	    _transfer(user, owner, amount);
	    uint money = amount*(keyprice/1 ether);
	    moneybuy(user, money);
	    return(true);
	}
	function ethbuy(uint amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
	    uint canmoney = getcanuse(user);
	    require(canmoney >= amount);
	    require(amount >= 1 ether);
	    eths[user] = eths[user].sub(amount);
	    reducemoney(user, amount);
	    moneybuy(user, amount);
	    return(true);
	}
	function moneybuy(address user,uint amount) private returns(bool) {
		uint money = amount*4;
		uint d = gettoday();
		uint t = getyestoday();
		if(fromaddr[user] == address(0)) {
		    money = amount*3;
		}
		uint yestodaymoney = daysgeteths[t]*subper/100;
		if(daysgeteths[d] > yestodaymoney && yestodaymoney > 0) {
		    if(fromaddr[user] == address(0)) {
    		    money = amount*2;
    		}else{
    		    money = amount*3;
    		}
		}
		ethnum[tags] = ethnum[tags].add(money);
		eths[user] = eths[user].add(money);
		addmoney(user, money, 0);
		
	}
	/*
	 * 系统充值
	 */
	function charge() public payable returns(bool) {
		return(true);
	}
	
	function() payable public {
		buy(0);
	}
	/*
	 * 系统提现
	 * @param {Object} address
	 */
	function withdraw(address _to, uint money) public onlyOwner {
		require(money <= address(this).balance);
		sysethnum[tags] = sysethnum[tags].sub(money);
		_to.transfer(money);
	}
	function chkend(uint money) public view returns(bool) {
	    uint syshas = address(this).balance;
	    uint chkhas = userethnum[tags]/2;
	    if(money > syshas) {
	        return(true);
	    }
	    if((userethnumused[tags] + money) > (chkhas - 1 ether)) {
	        return(true);
	    }
	    if(syshas - money < chkhas) {
	        return(true);
	    }
	    uint d = gettoday();
	    uint t = getyestoday();
	    uint todayget = dayseths[d];
	    uint yesget = dayseths[t];
	    if(yesget > 0 && todayget > yesget*subper/100){
	        return(true);
	    }
	    return false;
	    //require(syshas >= chkhas);
	    /*
	    if(sysethnum[tags] - money < chkhas || syshas < chkhas){
	        isend = true;
	        opentime = now + sysday;
	        return(true);
	    }else{
	        return(false);
	    }*/
	    
	}
	function setend() private returns(bool) {
	    if(userethnumused[tags] > userethnum[tags]/2) {
	        isend = true;
	        opentime = now + sysday;
	        return(true);
	    }
	}
	/*
	 * 出售
	 * @param {Object} uint256
	 */
	function sell(uint256 amount) onlySystemStart() public returns(bool success) {
		address user = msg.sender;
		require(amount > 0);
		
		uint256 canuse = getcanuse(user);
		require(canuse >= amount);
		require(eths[user] >= amount);
		require(address(this).balance/2 > amount);
		
		require(chkend(amount) == false);
		
		uint useper = (amount*sellper*keyprice/100)/1 ether;
		require(balances[user] >= useper);
		
		_transfer(user, owner, useper);
		
		user.transfer(amount);
		userethsused[user] = userethsused[user].add(amount);
		userethnumused[tags] = userethnumused[tags].add(amount);
		
		eths[user] = eths[user].sub(amount);
		reducemoney(user, amount);
		setend();
        //userethsused[user].add(amount);
		//emit Transfer(owner, msg.sender, moneys);
		return(true);
	}
	
	function sellkey(uint256 amount) onlySystemStart() public returns(bool) {
	    address user = msg.sender;
		require(balances[user] >= amount);
		uint money = (keyprice*amount*(100 - sellkeyper)/100)/1 ether;
		require(chkend(money) == false);
		require(address(this).balance/2 > money);
		userethsused[user] = userethsused[user].add(money);
		userethnumused[tags] = userethnumused[tags].add(money);
		_transfer(user, owner, amount);
		user.transfer(money);
		setend();
	}
	/*
	 * 获取总发行
	 */
	function totalSupply() public view returns(uint) {
		return _totalSupply.sub(balances[this]);
	}
	
	function buyprices() public view returns(uint price) {
	    price = keyprice;
	}
	/*
	function test() public view returns(uint) {
	    uint basekeylasts = basekeylast + basekeysub;
	    return(((basekeylasts/basekeysub) -4)*1 ether)/100 ;
	}*/
	function getbuyprice(uint buynum) public view returns(uint kp) {
	    //uint total = totalSupply().add(buynum);
	    //basekeynum = 20 ether;
        //basekeysub = 5 ether;
        //basekeylast = 25 ether;
        uint total = syskeynum[tags].add(buynum);
	    if(total > basekeynum + basekeylast){
	       //basekeynum = basekeynum + basekeylast;
	       uint basekeylasts = basekeylast + basekeysub;
	       kp = (((basekeylasts/basekeysub) - 4)*1 ether)/100;
	    }else{
	       kp = keyprice;
	    }
	    
	}
	function buykey(uint buynum) onlySystemStart() public payable returns(bool success){
	    uint money = msg.value;
	    address user = msg.sender;
	    require(buynum >= 1 ether);
	    //setstart();
	    uint buyprice = getbuyprice(buynum);
	    require(user.balance > buyprice);
	    require(money >= buyprice);
	    //require(money <= keyprice.mul(2000));
	    require(user.balance >= money);
	    require(eths[user] > 0);
	    
	    uint buymoney = buyprice.mul(buynum.div(1 ether));
	    require(buymoney == money);
	    //uint canbuynums = canbuynum();
	    //require(buynum <= canbuynums);
	    
	    mykeyeths[user] = mykeyeths[user].add(money);
	    sysethnum[tags] = sysethnum[tags].add(money);
	    syskeynum[tags] = syskeynum[tags].add(buynum);
		if(buyprice > keyprice) {
		    basekeynum = basekeynum + basekeylast;
	        basekeylast = basekeylast + basekeysub;
	        keyprice = buyprice;
	    }
	    _transfer(this, user, buynum);
	    
	    return(true);
	    
	}
	/*
	function activeuser() public returns(bool) {
	    address user = msg.sender;
	    eths[user] = 0;
	    systemtag[user] = tags;
	    if(now - opentime > sysday) {
	        isend = false;
	        tags++;
	        //this todo restart
	        //restartsys();
	    }
	    return(true);
	}*/
	function ended() public returns(bool) {
	    require(isend == true);
	    require(now < opentime);
	    
	    address user = msg.sender;
	    require(tags == systemtag[user]);
	    require(!frozenAccount[user]);
	    require(eths[user] > 0);
	    require(usereths[user]/2 > userethsused[user]);
	    uint money = usereths[user]/2 - userethsused[user];
	    require(address(this).balance > money);
		userethsused[user] = userethsused[user].add(money);
		eths[user] = 0;
		
		user.transfer(money);
		systemtag[user] = tags + 1;
		restartsys();
		
	    
	}
	function setopen() onlyOwner public returns(bool) {
	    isend = false;
	    tags++;
	    keyprice = startprice;
	    basekeynum = startbasekeynum;
	    basekeylast = startbasekeylast;
	}
	function setstart() public returns(bool) {
	    if(now > opentime && isend == true) {
	        isend = false;
	        tags++;
	        keyprice = startprice;
	        basekeynum = startbasekeynum;
	        basekeylast = startbasekeylast;
	        systemtag[msg.sender] = tags;
	    }
	}
	function reenduser() public returns(bool) {
	    address user = msg.sender;
	    require(isend == false);
	    require(now > opentime);
	    require(!frozenAccount[user]);
	    require(actived == true);
	    require(systemtag[user] < tags);
	    require(eths[user] > 0);
	    require(usereths[user]/2 > userethsused[user]);
	    uint money = usereths[user]/2 - userethsused[user];
	    
	    restartsys();
	    eths[user] = money*3;
	    usereths[user] = money;
	    ethnum[tags] = ethnum[tags].add(money*3);
	    systemtag[user] = tags;
	    /*
	    if(eths[user] > 0) {
	        addmoney(user, eths[user], 0);
	    }
	    systemtag[user] = tags;*/
	}
	function restartsys() private returns(bool) {
	    address user = msg.sender;
	    usereths[user] = 0;
	    userethsused[user] = 0;
	    //eths[user] = 0;
	    runs[user] = 0;
	    runused[user] = 0;
	    used[user] = 0;
	    delete mycantime[user];
	    delete mycanmoney[user];
	    delete myruntime[user];
	    delete myrunmoney[user];
	    //delete mysunsdaynum[user];
	}
}