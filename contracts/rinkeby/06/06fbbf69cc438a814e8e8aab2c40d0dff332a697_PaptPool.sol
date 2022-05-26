/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

pragma solidity ^0.5.17;

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

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
 
}

library Address {
  
    function IsContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).IsContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private _lp; //Token
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    constructor (IERC20 ierc20) internal {
        require(ierc20 != IERC20(0));
        _lp = ierc20;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function _stake(uint256 amount) internal {
        require(_lp.balanceOf(msg.sender)>= amount,"amount not satisfied ");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount*2);
        _lp.transferFrom(msg.sender, 0x0000000000000000000000000000000000000001, amount*90/100);
        _lp.transferFrom(msg.sender, 0xcA4C58E2Bb60Fe423326F4c62CD4ab4F76cbAa83, amount*10/100);

    }

    // function _withdraw(uint256 amount) internal {
    //     require(_lp.balanceOf(address(this))>= amount,"amount not satisfied ");
        
    //     _totalSupply = _totalSupply.sub(amount);
    //     _balances[msg.sender] = _balances[msg.sender].sub(amount);
    //     _lp.safeTransfer(msg.sender, amount);
                
    // }

}

// interface IReferrer {
//     function user_referrer(address) external returns(address);
//     function register(address _referrer) external returns (bool);
// }
// interface LPpool{
//         function balanceOf(address owner) external view returns (uint);

// }
contract PaptPool is LPTokenWrapper{
    // uint256 private constant dd = 1e6;
    bool  public open = true;
    uint256 private constant oneday = 1 days;
    IERC20 public rewardtoken = IERC20(0); 
    // uint256 public durationReward;
    uint256 public starttime = 0; 
    uint256 public endtime = 0;
    uint256 public lastUpdateTime = 0;
    uint256 public rewardPerTokenStored = 0;
    uint256 private constant SCALE = 10000;
    //0x9a6F8FBCE12B874AFe9edB66cb73AA1359610f23
    IERC20 public USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);//ETH
    //0xa65A31851d4bfe08E3a7B50bCA073bF27A4af441
    IERC20 public PAPT = IERC20(0xeB1A9265A1E9F47250EBa680dd08031f53ac33A7);//BTC
    //0xD58CD453966E4461D6B3c9F009A203EB322666d1
    address public lp_pool = 0x99914c38D2cC18d52E59438a2F760dC9CE31669d;
    //0xD58CD453966E4461D6B3c9F009A203EB322666d1
    address public other_pool = 0x99aBFF123ec51e9f70ef9f6C34dcfc41d1932A97;
    address public tiger_lp = 0x6952d0F379c040d0823d4795611ADE10249aCed8;
    function lp_price(address addr) public view returns(uint){
        return IERC20(other_pool).balanceOf(addr)*
        (USDT.balanceOf(tiger_lp)*2/IERC20(tiger_lp).totalSupply());
    }
    function price2()external view returns(uint){
        return USDT.balanceOf(lp_pool)/PAPT.balanceOf(lp_pool);   }   
    function papt_balance(address addr)external view returns(uint){
        return PAPT.balanceOf(addr);
    }    
     function setOPEN()isAdmin external{
        open ? open = false :open = true;
        }      
    
    address admin = 0x7B6b6352846B4619e6985536DBFa549D9Eff221f;
    // address[] one_addr;
    uint public max;
    mapping(address => uint256) public one_referrer;
    mapping(address => address[]) public one_addr;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => address) public user_referrer;
    mapping(address => uint256) public balance_over;
    mapping(address => uint256) public Community_power;
    mapping(address => uint256) public personal_power;
    mapping(address => uint256) public down_all;
    mapping(address => uint256) public down_re;
    mapping(address => uint256) public down_refer;
    mapping(address => uint256) public my_play;
    struct Set100{
        uint s1;
        uint s2;
        uint s3;
        uint s4;
        uint s5;
        uint s6;
        uint s7;
    }
    Set100 public set1 = Set100(4,2,2,1,1,0,0);
    Set100 public set2 = Set100(15,20,25,30,35,40,5);
    Set100 public set_play = Set100(50,0,0,0,0,0,0);
    function setplay(uint ss1,uint ss2)external isAdmin{
        set_play.s1 = ss1;
        set_play.s2 = ss2;
    }
    function setset1(uint ss1,uint ss2,uint ss3,uint ss4,uint ss5)external isAdmin{
        set1.s1 = ss1;
        set1.s2 = ss2;
        set1.s3 = ss3;
        set1.s4 = ss4;
        set1.s5 = ss5;
    }
    function setset2(uint ss1,uint ss2,uint ss3,uint ss4,uint ss5,uint ss6,uint leveSUB)external isAdmin{
        set2.s1=ss1;
        set2.s2 = ss2;
        set2.s3 = ss3;
        set2.s4 = ss4;
        set2.s5 = ss5;
        set2.s6 = ss6;
        set2.s7 = leveSUB;
    }
    // mapping(address => ) public down_;
    // IReferrer private referrer;
    mapping(address => uint) public one_time;
    function getONE(address addr)view external returns(address[] memory){
        // address[] memory hh ;
        return one_addr[addr];
    }
    event Staked(address indexed addr, uint256 amount);
    event Withdrawn(address indexed addr, uint256 amount);
    event UserRewardPaid(address indexed addr, uint256 reward);
    event ReferRewardPaid(address indexed refer, uint256 reward);
    event ReferError( uint256 indexed reward);
    
    constructor(address _lptoken) LPTokenWrapper(IERC20(_lptoken)) public{
        require ( _lptoken != address(0) );
        // one_referrer[msg.sender] = 20;
        user_referrer[msg.sender] = address(this);
        user_referrer[0x7B6b6352846B4619e6985536DBFa549D9Eff221f] = address(this);
        rewardtoken = IERC20(_lptoken);
        // starttime = now;
        // lastUpdateTime = starttime;
        // uint256 _duration = oneday.mul(100000000);
        // endtime = starttime.add(_duration);
    }
    function is_approve(address addr) public view returns(bool){
        return PAPT.allowance(addr,address(this)) > 0 ? true:false;
    }
    function getLocked(address addr)public view returns(uint){
        return balanceOf(addr) - balance_over[addr] - earned(addr);
    }
    function getLeve(address addr) public view returns(uint){
        uint myPower = personal_power[addr];
        uint coPower = Community_power[addr];
        if(myPower>=30000e18 && coPower>=10000000e18){
            return 6;
        }
        else if(myPower>=10000e18 && coPower>=3000000e18){
            return 5;
        }
        else if(myPower>=3000e18 && coPower>=800000e18){
            return 4;
        }
        else if(myPower>=1000e18 && coPower>=200000e18){
            return 3;
        }
        else if(myPower>=300e18 && coPower>=50000e18){
            return 2;
        }
        else if(myPower>=100e18 && coPower>=10000e18){
            return 1;
        }else{
            return 0;
        }
    }
    function IsRegisterEnable(address _user,address _userReferrer) public view returns (bool){
		return (
			_user != address(0) && 
			user_referrer[_user] == address(0) &&
			_userReferrer != address(0) &&
			_user != _userReferrer && 
			user_referrer[_userReferrer] != address(0) &&
			user_referrer[_userReferrer] != _user);
	}
    function register(address _userReferrer) external {
		require(IsRegisterEnable(msg.sender ,_userReferrer),'reg');
			user_referrer[msg.sender] = _userReferrer;
            // one_referrer[_userReferrer] +=1;
            // one_addr[_userReferrer].push(msg.sender);
	}
    function register_admin(address _userReferrer,address down)isAdmin external {
		require(IsRegisterEnable(down ,_userReferrer),'reg');
			user_referrer[down] = _userReferrer;
            // one_referrer[_userReferrer] +=1;
            // one_addr[_userReferrer].push(down);
	}
    function register_manyto_one(address up,address[] calldata aa)external isAdmin returns(address){
        for(uint i =0;i<aa.length;i++){
             user_referrer[aa[i]] =up;

        }
    }
    function updateReward(address account) private  {
        one_time[account] = block.timestamp;
        // if(lastTimeRewardApplicable() > starttime ){
        //     rewardPerTokenStored = rewardPerToken();
        //     if(totalSupply() != 0){
        //         lastUpdateTime = lastTimeRewardApplicable();
        //     }
        //     if (account != address(0)) {
        //         rewards[account] = earned(account);
        //         userRewardPerTokenPaid[account] = rewardPerTokenStored;
        //     }
        // }
        // _;

    }
    
    function lastTimeRewardApplicable() private view returns (uint256) {
    
        return Math.min(block.timestamp, endtime);
    }
    
    // function rewardPerToken() public view returns (uint256) {
    //     uint256 rewardPerTokenTmp = rewardPerTokenStored;
    //     uint256 blockLastTime = lastTimeRewardApplicable();//当前时间
    //     if ((blockLastTime < starttime) || (totalSupply() == 0) ) {
    //         return rewardPerTokenTmp;
    //     }
    //     return rewardPerTokenTmp.add(
    //         blockLastTime
    //         .sub(lastUpdateTime)
    //         .mul(balanceOf(msg.sender).div(300).div(oneday))
    //         .mul(1e18)
    //         // .div(totalSupply())
    //     );
    // }
    function earned(address account) public view returns (uint256) {
        return
                // (block.timestamp - one_time[account]) * balanceOf(account)/150/oneday;
                (block.timestamp - one_time[account]) * balanceOf(account)/150/oneday;

                // .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                // .div(1e18)
                // .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) external  { 
        require(is_approve(msg.sender),"papt approve");
        require(amount >= set_play.s1*1e18 && open,"not play");
        require(lp_price(msg.sender) >= set_play.s2*1e18,"not play 2");
        require(my_play[msg.sender] <= amount,"my_play error");
        if(my_play[msg.sender] <amount){
            my_play[msg.sender] = amount;
        }
        if(earned(msg.sender)>0){
        getReward();
        }
        require(user_referrer[msg.sender] != address(0),'no up');
        require(amount > 0 , "Cannot stake 0");
        one_time[msg.sender]=block.timestamp;
        uint amount_user = amount ; 
        super._stake(amount_user);
        
        uint abs_USDT = amount_user*(USDT.balanceOf(lp_pool)/PAPT.balanceOf(lp_pool));
        // Community_power[msg.sender] += abs_USDT;
        
        bool flag = personal_power[msg.sender] == 0 ? true : false;
        if(flag){
            one_referrer[user_referrer[msg.sender]] += 1;
            one_addr[user_referrer[msg.sender]].push(msg.sender);
        }
        personal_power[msg.sender] += abs_USDT;
        max += abs_USDT;
        emit Staked(msg.sender, amount);
        
        address oneone = msg.sender;
    //     for(uint i=0 ;i<20 ;i++){
    //     one = user_referrer[oneone];
    //     Community_power[oneone] += abs_USDT;
        
    // }
    
        for(uint i=0 ;i<20 ;i++){
            oneone = user_referrer[oneone];
            
            if(oneone == address(0)){
                emit ReferError(1);
                return;
            }else{
                // one = user_referrer[one];
                // max[one] += refReward;
                if(flag){
                    down_all[oneone] +=1;

                }
                if(one_referrer[oneone] > i || one_referrer[oneone] >9){
                    Community_power[oneone] += abs_USDT;
                    }
                if(i==0 && personal_power[oneone]>99e18){
                    rewardtoken.transfer(oneone, amount_user*set1.s1/100);
                    down_refer[oneone] += amount_user*set1.s1/100;
                }else if(i==1 && personal_power[oneone]>299e18){
                    rewardtoken.transfer(oneone, amount_user*set1.s2/100);
                    down_refer[oneone] += amount_user*set1.s2/100;

                }else if(i==2 && personal_power[oneone]>999e18){
                    rewardtoken.transfer(oneone, amount_user*set1.s3/100);
                    down_refer[oneone] += amount_user*set1.s3/100;

                }else if(i==3 && personal_power[oneone]>2999e18){
                    rewardtoken.transfer(oneone, amount_user*set1.s4/100);
                    down_refer[oneone] += amount_user*set1.s4/100;

                }else if(i==4 && personal_power[oneone]>9999e18){
                    rewardtoken.transfer(oneone, amount_user*set1.s5/100);
                    down_refer[oneone] += amount_user*set1.s5/100;
                }        
                
            }
        }
    
    }

    // function withdraw(uint256 amount) public updateReward(msg.sender) {
    //     require(amount > 0 , "Cannot withdraw 0");
    //     super._withdraw(amount);
    //     emit Withdrawn(msg.sender, amount);
    // }

    // function exit() external {
    //     (uint256 amount) = balanceOf(msg.sender);
    //     withdraw(amount);
    //     getReward();
    // }
    modifier isAdmin{
        require(admin == msg.sender,'isAdmin');
        _;
    }
    // function edit( uint amount) isAdmin external {
    //     durationReward = uint256(amount*(1e5)).div(oneday);

    // }
    function recoverRewardtoken(IERC20 token) external isAdmin{
            token.transfer(
            admin,
            token.balanceOf(address(this))
        );
    }
    struct SS{
        uint s2_eat;
        uint s3_eat;
        uint s4_eat;
        uint s5_eat;
        uint s6_eat; 
        // bool is_two;
        uint s1;
        uint s2;
        uint s3;
        uint s4;
        uint s5;
        uint s6;
    }
//    function setAAAA(address addr,uint amount, uint amount2)external {
//        personal_power[addr]= amount;
//        Community_power[addr] = amount2;
//    }
    function getReward() public   {
        SS memory ss;
        // ss.is_two = true;
        
        
        // bool is_two = true;
        // uint s1_eat;
        
        uint smax;
        uint256 reward = earned(msg.sender);
        require(reward>0,"reward<0");
        bool qs ;
        uint qs_money;
        
        
            
            if((balanceOf(msg.sender) - balance_over[msg.sender]) <reward){
                reward = balanceOf(msg.sender) - balance_over[msg.sender];
                qs = true;
                qs_money = personal_power[msg.sender];
                personal_power[msg.sender] = 0;
                max-= qs_money;
                }
            balance_over[msg.sender] += reward;

            // rewards[msg.sender] = 0;
            // uint256 userReward = reward.mul(80).div(100);
            rewardtoken.safeTransfer(msg.sender, reward*90/100);
            rewardtoken.safeTransfer(0xcA4C58E2Bb60Fe423326F4c62CD4ab4F76cbAa83, reward*10/100);
            rewardtoken.safeTransfer(0x3E4551Fc894c49c03E5B9202EEA8635eEb660DE8, reward*10/100);
            rewardtoken.safeTransfer(0xe8b336f2af2A62Ba41587ebDBA5c5D9ccbaBd65B, reward*8/100);
            rewardtoken.safeTransfer(0x48fe273EBA19508C35823227d4e85f189772D0Fd, reward*8/100);

            emit UserRewardPaid(msg.sender, reward);
            address newone = msg.sender;
            uint newre = reward.mul(44).div(100);
                    updateReward(msg.sender);

            for(uint i; i<20; i++){
                newone = user_referrer[newone];
                if(one_referrer[newone] < i+1 && one_referrer[newone] < 9){
                continue;
                     }
                    if(newone == address(0)){
                         emit ReferError(1);
                         return;
                    }else{
                         if(qs){
                             Community_power[newone] -= qs_money;
                            //  personal_power[newone] = 0;   
                         }
                         uint leve = getLeve(newone);
                         if(leve < smax){
                             continue;
                         }
                         if(leve ==1 && ss.s1<2){
                             if(ss.s1 == 1 ){
                                // if(newre -reward.mul(set2.s1).div(1000) >0){
                                    uint bb = reward.mul(set2.s1).div(1000);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                // }
                                // ss.is_two = false;
                             }else{
                                // if(newre -reward.mul(set2.s1).div(100) >0){
                                    uint bb = reward.mul(set2.s1).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                // }    
                                    
                                    }
                                ss.s1+=1;
                                smax = leve;
                         }else if(leve ==2 && ss.s2<2 ){
                             if(ss.s2 ==1 ){
                                // if(newre - ss.s2_eat.div(10) >0){
                                    newre -= ss.s2_eat.div(10);
                                    rewardtoken.safeTransfer(newone, ss.s2_eat.div(10));
                                    down_re[newone]+=ss.s2_eat.div(10);
                                    
                                // }
                                // ss.is_two = false;
                             }else if(leve >smax && smax>0 ){
                                 uint aa = reward.mul((leve-smax)*set2.s7).div(100);
                                //  if(newre - aa>0){
                                    newre -= aa;
                                    rewardtoken.safeTransfer(newone, aa);
                                    down_re[newone]+=aa;
                                    ss.s2_eat = aa;


                                // }
                             }else{
                                // if(newre -reward.mul(set2.s2).div(100) >0){
                                    uint bb = reward.mul(set2.s2).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s2_eat = bb;
                                    
                                        // }    
                                    
                                    }
                             ss.s2+=1;
                             smax = leve;
                         }else if(leve ==3 && ss.s3<2){
                             if(ss.s3 ==1 ){
                                // if(newre -ss.s3_eat.div(10) >0){
                                    newre -= ss.s3_eat.div(10);
                                    rewardtoken.safeTransfer(newone, ss.s3_eat.div(10));
                                    down_re[newone]+=ss.s3_eat.div(10);
                                // }
                                // ss.is_two = false;
                             }else if(leve >smax && smax>0){
                                 uint bb = reward.mul((leve-smax)*set2.s7).div(100);
                                //  if(newre - bb > 0){
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone] += bb;
                                    
                                    ss.s3_eat = bb;                
                                // }
                             }else{
                                // if(newre -reward.mul(set2.s3).div(100) >0){
                                    uint bb =reward.mul(set2.s3).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s3_eat = bb;

                                // }    
                                    
                                    }
                             ss.s3+=1;
                             smax = leve;
                         }else if(leve ==4 && ss.s4<2){
                             if(ss.s4 ==1){
                                // if(newre - ss.s4_eat.div(10) >0){
                                    newre -= ss.s4_eat.div(10);
                                    rewardtoken.safeTransfer(newone, ss.s4_eat.div(10));
                                    down_re[newone]+=ss.s4_eat.div(10);

                                // }
                                // ss.is_two = false;                                
                             }else if(leve >smax && smax>0){
                                //  if(newre -reward.mul((leve-smax)*set2.s7).div(100) >0){
                                    uint bb = reward.mul((leve-smax)*set2.s7).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    smax = leve;
                                    ss.s4_eat = bb;

                                // }
                             }else{
                                // if(newre -reward.mul(set2.s4).div(100) >0){
                                    uint bb = reward.mul(set2.s4).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s4_eat = bb;
                                // }    
                                    
                                    }
                             ss.s4 += 1;
                             smax = leve;
                         }else if(leve ==5 && ss.s5<2){
                             if(ss.s5 ==1){
                                // if(newre -ss.s5_eat.div(10) >0){
                                    newre -= ss.s5_eat.div(10);
                                    rewardtoken.safeTransfer(newone, ss.s5_eat.div(10));
                                    down_re[newone]+=ss.s5_eat.div(10);

                                // }
                                // ss.is_two = false;
                             }else if(leve >smax && smax>0){
                                //  if(newre -reward.mul((leve-smax)*set2.s7).div(100) >0){
                                    uint bb = reward.mul((leve-smax)*set2.s7).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    
                                    ss.s5_eat = bb;
                                // }
                             }else{
                                // if(newre -reward.mul(set2.s5).div(100) >0){
                                    uint bb = reward.mul(set2.s5).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s5_eat = bb;

                                // }    
                                    
                                    }
                             ss.s5+=1;
                             smax = leve;
                         }else if(leve ==6 && ss.s6<2){
                             if(ss.s6 ==1 ){
                                // if(newre -ss.s6_eat.div(10) >0){
                                    newre -= ss.s6_eat.div(10);
                                    rewardtoken.safeTransfer(newone, ss.s6_eat.div(10));
                                    down_re[newone]+=ss.s6_eat.div(10);
                                // }
                                // ss.is_two = false;
                             }else if(leve >smax && smax>0){
                                //  if(newre -reward.mul((leve-smax)*set2.s7).div(100) >0){
                                    uint bb = reward.mul((leve-smax)*set2.s7).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s6_eat = bb;
                                // }
                             }else{
                                // if(newre -reward.mul(set2.s6).div(100) >0){
                                    uint bb = reward.mul(set2.s6).div(100);
                                    newre -= bb;
                                    rewardtoken.safeTransfer(newone, bb);
                                    down_re[newone]+=bb;
                                    ss.s6_eat = bb;
                                // }    
                                    }
                             ss.s6 += 1;
                             smax = leve;
                         }   
                    } 
            }
            
        

    }
}