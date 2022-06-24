// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./RDL.sol";
import "./RDX.sol";

contract MasterChef {
    struct User {
        uint256 balance;
        uint256 rewardDebt;
    }

    RDL private immutable rdl;
    RDX private immutable rdx;
    uint256 public immutable rewardPerBlock;
    uint256 public constant ACC_PER_SHARE_PRECISION = 1e12;
    uint256 private accRDXPerShare;
    uint256 private lastRewardBlock;
    mapping(address => User) public users;

    constructor(
        address _rdlAddress,
        address _rdxAddress,
        uint256 _rewardPerBlock
    ) {
        rdl = RDL(_rdlAddress);
        rdx = RDX(_rdxAddress);
        rewardPerBlock = _rewardPerBlock;
    }

    /**
    return rdl balance of user
     */
    function depositedBalance(address owner)
        public
        view
        returns (uint256 balance)
    {
        return users[owner].balance;
    }

    /**
    return rdx amount will reward for user
     */
    function rewardAmount(address owner) public view returns (uint256 amount) {
        // update current state
        uint256 chefBalance = rdl.balanceOf(address(this));
        uint256 currentPerShare = 0;
        if (chefBalance != 0) {
            currentPerShare += _calculatePerShare(chefBalance);
        }
        // calculate user reward
        User storage user = users[owner];
        uint256 reward = ((user.balance * currentPerShare) /
            ACC_PER_SHARE_PRECISION) - user.rewardDebt;
        return reward;
    }

    /**
    transfer amount of token RDL from owner to current MasterChef address
     */
    function deposit(address owner, uint256 amount) public {
        // reject deposit amount with 0
        require(amount > 0, "Deposit amount not valid");
        // validate balance of owner enough
        require(
            rdl.balanceOf(owner) >= amount,
            "User RDL balance isn't enough"
        );

        // update state of lastRewardBlock and accRDXShare
        _updateAccShare();
        User storage user = users[owner];
        if (user.balance > 0) {
            claim(owner);
        }
        // trigger transferFrom to transfer token
        rdl.transferFrom(owner, address(this), amount);
        // update state of user)
        // log current deposit amount of owner
        user.balance += amount;
        user.rewardDebt =
            (user.balance * accRDXPerShare) /
            ACC_PER_SHARE_PRECISION;
    }

    /**
    transfer amount of token RDL to special address has own it
     */
    function withdraw(address owner, uint256 amount) public {
        // check balance of user
        User storage user = users[owner];
        uint256 balance = user.balance;
        require(balance >= amount, "Withdraw amount not valid");
        // check balance of chef
        uint256 balanceOfChef = rdl.balanceOf(address(this));
        require(balanceOfChef > amount, "Chef balance not enough");
        // update current state
        _updateAccShare();
        if (user.balance > 0) {
            claim(owner);
        }
        // update user state
        user.balance -= amount;
        user.rewardDebt =
            (user.balance * accRDXPerShare) /
            ACC_PER_SHARE_PRECISION;
        // besure we always support user withdraw even when our balance not enough to fully support user withdraw order
        rdl.transfer(owner, amount);
    }

    /**
    claim all reward user has
     */
    function claim(address owner) public {
        // calculate user reward
        uint256 reward = rewardAmount(owner);
        if (reward > 0) {
            _transferReward(owner, reward);
        }
    }

    /**
     */
    function _updateAccShare() private {
        uint256 chefBalance = rdl.balanceOf(address(this));
        if (chefBalance == 0) {
            accRDXPerShare = 0;
        } else {
            accRDXPerShare += _calculatePerShare(chefBalance);
        }
        lastRewardBlock = block.number;
    }

    /**
     */
    function _calculatePerShare(uint256 balance)
        private
        view
        returns (uint256 perShare)
    {
        return
            (ACC_PER_SHARE_PRECISION *
                rewardPerBlock *
                (block.number - lastRewardBlock)) / balance;
    }

    /**
    calculate and transfer token RDX to address has request claim
     */
    function _transferReward(address owner, uint256 amount) private {
        // check reward amount
        require(amount > 0, "Amount to claim not valid");
        // check rdx balance of chef
        uint256 rdxBalanceOfChef = rdx.balanceOf(address(this));
        require(rdxBalanceOfChef > amount, "RDX balance of chef not valid");
        // trigger erc20 to transfer rdx to address
        rdx.transfer(owner, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./ERC20.sol";

contract RDL is ERC20 {
    constructor(uint8 tokenDecimals) ERC20("RDL token", "RDL", tokenDecimals) {}

    /**
    deposit _value of balance to _to
     */
    function mint(address to, uint256 value) public returns (bool success) {
        require(
            value + _totalSupply <= type(uint256).max,
            "Value to mint not valid"
        );

        _totalSupply += value;
        _balances[to] += value;
        emit Transfer(address(0), to, value);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./ERC20.sol";

contract RDX is ERC20 {
    constructor(uint8 tokenDecimals, uint256 totalSupply)
        ERC20("RDX token", "RDX", tokenDecimals)
    {
        _totalSupply = totalSupply;
        _balances[msg.sender] = totalSupply;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "./IERC20.sol";

/**
Basic ERC20 implementation
 */
contract ERC20 is IERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _approvedList;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    /**
    name of the token, ex: Dai
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
    symbol of the token, ex: DAI
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
    will used to round the balance of address
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
    total supply of token, will reduce when transfer or burn
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
    balance of special address
     */
    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    /**
    transfer _value of token from current sender to _to
     */
    function transfer(address to, uint256 value)
        public
        override
        returns (bool success)
    {
        return _transfer(msg.sender, to, value);
    }

    /**
    transfer _value of token from _from to _to and the sender will have approved by _from to using _from balance before
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool success) {
        require(_approvedList[from][msg.sender] >= value, "Allowance limit");

        bool result = _transfer(from, to, value);
        _approvedList[from][msg.sender] -= value;
        return result;
    }

    /**
    sender will give acception to spender to using _value of balance of sender
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool success)
    {
        _approvedList[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    return remanning of approved balance which owner approved for spender used before
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _approvedList[owner][spender];
    }

    /**
    Transfer _value of balance from _from to _to and emit the Transfer event
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool success) {
        require(_balances[from] >= value, "Insufficient balance");

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}