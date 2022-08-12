pragma solidity >=0.7.0 <0.9.0;
import "./IERC20.sol";

contract Masterchef {
    mapping(address => uint256) public balances;
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount;
        uint256 reward;
        uint256 rewardDebt;
    }

    IERC20 A;
    IERC20 RDX;

    // thông tin về pool
    uint256 lastRewardBlock;
    uint256 public rewardPerBlock = 10000 * 10 ** 18; // thưởng mỗi block
    uint256 accRewardPerShare = 0; // tỷ lệ nhận rdx trên 1 đơn vị token A staking

    constructor(address _aToken, address _rdxToken) {
        A = IERC20(_aToken);
        RDX = IERC20(_rdxToken);
    }

    function updatePool() private {
        if (A.balanceOf(address(this)) == 0) {
            lastRewardBlock = block.number;
        } else {
            accRewardPerShare +=
                (rewardPerBlock * (block.number - lastRewardBlock)) /
                A.balanceOf(address(this));
            lastRewardBlock = block.number;
        }
    }

    function deposit(uint256 _amount) public {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount * accRewardPerShare - user.rewardDebt;
            if (pending > 0) {
                user.reward += pending;
            }
        }
        if (_amount > 0) {
            A.transferFrom(msg.sender, address(this), _amount);
            user.amount += _amount;
        }
        user.rewardDebt = user.amount * accRewardPerShare;
        emit Deposit(msg.sender, _amount);
    }

    function getReward(address _addr) public view returns (uint256) {
        UserInfo storage user = userInfo[_addr];
        uint256 _accRewardPerShare = accRewardPerShare +
            (rewardPerBlock * (block.number - lastRewardBlock)) /
            A.balanceOf(address(this));
        uint256 _reward = user.amount *
            _accRewardPerShare -
            user.rewardDebt +
            user.reward;
        return _reward;
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0 && _amount <= user.amount, "reject because amount < 0");
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount * accRewardPerShare - user.rewardDebt;
            if (pending > 0) {
                user.reward += pending;
            }
        }
        user.amount -= _amount;
        user.rewardDebt = user.amount * accRewardPerShare;
        A.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function claimRdx(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "reject because amount < 0");

        uint256 _accRewardPerShare = accRewardPerShare +
            ((rewardPerBlock * (block.number - lastRewardBlock)) /
                A.balanceOf(address(this)));
        uint256 pending = user.amount * _accRewardPerShare - user.rewardDebt;

        require((user.reward + pending) >= _amount, "reject amount > reward");

        RDX.transfer(msg.sender, _amount);
        user.reward = user.reward + pending - _amount ;
        user.rewardDebt = user.amount * _accRewardPerShare;
        emit Claim(msg.sender, _amount);
    }
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
}

pragma solidity >= 0.7.0 <0.9.0;

interface IERC20{

    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address indexed owner,address indexed spender,uint value);
    
    function mint(address to,uint value) external ;
    function transfer(address to,uint value) external ;
    function transferFrom(address from,address to,uint value) external ;
    function balanceOf(address owner) external view returns(uint);
    function approve(address spender ,uint value) external ;
}