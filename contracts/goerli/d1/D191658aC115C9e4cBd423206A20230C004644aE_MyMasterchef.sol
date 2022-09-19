// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./RDX.sol";

contract MyMasterchef {
    struct UserInfo {
        uint256 amount; // total LP token user provided
        uint256 rewardDebt;
        uint256 reward; // actual reward earn
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. RDX to distribute per block.
        uint256 lastRewardBlock; // Last block number that RDX distribution occurs.
        uint256 accRdxPerShare; // Accumulated RDX per share
    }

    // RDX token - reward token
    RDX public rdx;

    // RDX23 tokens created per block.
    uint256 public rdxPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RDX staking starts.
    uint256 public startBlock;

    address public owner;

    event UpdatePool(uint256 pid, uint256 rdxReward, uint256 accRdxPerShare);
    event Claim(uint256 pid, uint256 rdxReward, uint256 accRdxPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        RDX _rdx,
        uint256 _rdxPerBlock,
        uint256 _startBlock
    ) public {
        owner = msg.sender;
        rdx = _rdx;
        rdxPerBlock = _rdxPerBlock * 10**18; // in decimals
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add new liquidity to the pool. Can be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken) public {
        require(msg.sender == owner, "Caller is not the owner!");
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRdxPerShare: 0
            })
        );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // for case 1st deposit
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 rdxReward = (block.number - pool.lastRewardBlock) *
            rdxPerBlock *
            (pool.allocPoint / totalAllocPoint);
        // Ignored step: minted RDX token for Masterchef: RDX token must be transfered manual to Masterchef before
        // update pool: accRdxPerShare, lastRewardBlock
        pool.accRdxPerShare += ((rdxReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
        emit UpdatePool(_pid, rdxReward, lpSupply);
    }

    // View function to see pending RDX on frontend.
    function pendingRdx(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRdxPerShare = pool.accRdxPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rdxReward = ((block.number - pool.lastRewardBlock) *
                rdxPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRdxPerShare = accRdxPerShare + ((rdxReward * 1e12) / lpSupply);
        }
        return
            user.reward +
            (user.amount * accRdxPerShare) /
            1e12 -
            user.rewardDebt;
    }

    // claim pending reward RDX
    function claimPendingRdx(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // update rewardDebt
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        // update reward
        user.reward = user.reward + pending - _amount;
        // transfer token
        safeRdxTransfer(msg.sender, _amount);
        emit Claim(_pid, user.reward, pool.accRdxPerShare);
    }

    // Deposit LP tokens to MasterChef for RDX allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // transfer lpToken
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // update amount staking
        user.amount = user.amount + _amount;
        // update reward
        user.reward = user.reward + pending;
        // update rewardDebt
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens and all unclaimed RDX from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "exceeds withdrawal limit");
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // withdraw all reward
        safeRdxTransfer(msg.sender, user.reward + pending);
        user.amount = user.amount - _amount;
        user.reward = 0; // reset reward to zero
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe transfer function, check case if not enough balance for transfer
    function safeRdxTransfer(address _to, uint256 _amount) internal {
        uint256 rdxBal = rdx.balanceOf(address(this));
        if (_amount > rdxBal) {
            rdx.transfer(_to, rdxBal);
        } else {
            rdx.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

// token only mint once time for creator
contract RDX is ERC20 {
    uint256 private constant DEFAULT_MINT_AMOUNT = 10**8;

    constructor() ERC20("RDX", "RDX") {
        _mint(msg.sender, 10**12 * 10**decimals());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// base contract for ERC20
contract ERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;

    string private _symbol;

    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );

            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
}