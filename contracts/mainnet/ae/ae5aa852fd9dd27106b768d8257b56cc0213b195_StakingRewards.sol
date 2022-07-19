// SPDX-License-Identifier: MIT

/*
                 .'cdO0000OO00KKNNNXKOkdc'.                 
              'cooolc;;lc',l:'':lloxO000KKOdc'              
           'ldoll;.'c..;; .:'  ':..::;cxKKxccddl'           
         ;ddlc'.:;                 ,..;c,cdxddk0Ox:.        
       ;ddc..:,                       ...,::xOo;;lkk;       
     .dx;.;;                             ''.,lk0xlodkd'     
    ;kl;c.                                 .c'.okc,,cO0:    
   ckc'..        .cxd,       'ldOd'          .c:c00ollokl   
  cO;'c.        .dWMMX:     ,0MMMM0'          .'.cko;;;xKl  
 ;Ol;,          ;KMMMMO.    oWMMMMWl           .c'cKkcccdO: 
.ko.,'          :NMMMMK,   .dMMMMMMd            .,;dx.   lk'
lk;:,           ,KMMMMO.    lWMMMMWo             ;,,OklllxKl
ko.'.           .oWMMNl     .OWMMM0'             .:;dO;...dO
0:;:             .ckk:.      .:okd'               ,.cO:...c0
0;'.     .;.                            ':c.      ;::0kllldK
O;c;     cXNOo'                      .cONNx.      ..;Oc   'O
0;..      lW0d,                      .;o0K,       ;::Ol...;0
0c;;      cNl                          .xK,       '.:0xlllkK
ko.,.     ;Xx.                         '0O.      .c;dk.   lO
lk::.     .xX:                         oNl       '.,0Oc::lOo
.ko.:'     'O0,                       cXx.      .::dkc::cOO'
 :Ol,'      'OKc.                   .oKx.      ':.:KkcccdO: 
  cO;,c.     .oKO;.               .cOKc.       ',cko;;:xKl  
   ckc.',      'd0Oo;..      ...:d0Ol.       .c,:00olldOl.  
    ;kl:;.       .;okOkkxddxkOOOko;.       .;.'oOl;;:k0:    
     .dx,'c'         .',::::;'..         ..':cxkdlok0x'     
       ;xd:.'c.                       ...c;;xXkc:cdx:       
        .;ddl:..c. .              .'..c,.:ddlcdKXk:.        
           'ldooc..:, .c. ';..':, 'c,,cokK0xdddl,           
              'cooolc;:l,.:c,,:cccldO0Okxkkdc'.             
                 .,lxO000OOO00KKNNNNX0Oxl,.                 
*/

// BETTER Staking Contract v1.1 (advisor vault with token lock period)
// based on Synthetix StakingRewards

pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pauseable.sol";

contract StakingRewards is Ownable,Pausable{
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public withdrawLockPeriod;
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    uint private _totalSupply;
    mapping(address => uint) private _balances;
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event WithdrawDurationUpdated(uint256 newDuration);
    constructor(address _stakingToken, address _rewardsToken, uint256 _endTime, uint256 _rewardRate, address serviceAdmin) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        withdrawLockPeriod = _endTime;
        periodFinish = _endTime;
        rewardRate = _rewardRate;
        Ownable.init(serviceAdmin);
    }
    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }
    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    function stake(uint _amount) external whenNotPaused updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }
    function withdraw(uint _amount) public whenNotPaused updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        require(withdrawLockPeriod < block.timestamp, "Can not withdraw during lock period");
        require(_balances[msg.sender] >= _amount,"Can not withdraw more than the current balance");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }
    function getReward() public whenNotPaused updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0){
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function exit() whenNotPaused external {
        withdraw(_balances[msg.sender]);
        getReward();
    }
    
    function updatewithdrawLockPeriod(uint256 _newperiod)public anyAdmin {
        
        withdrawLockPeriod = _newperiod;
        emit WithdrawDurationUpdated(_newperiod);
    }
    function updatePeriod(uint256 _newperiod)public anyAdmin {
        require(_newperiod > periodFinish, "New time should be greater than old one");
        
        periodFinish = _newperiod;
        emit RewardsDurationUpdated(_newperiod);
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // ================== Functions to pause and unpause contract ==================
    
    function PauseContract()public anyAdmin{
        _pause();
    }
    function UnPauseContract()public anyAdmin{
        _unpause();
    }
}