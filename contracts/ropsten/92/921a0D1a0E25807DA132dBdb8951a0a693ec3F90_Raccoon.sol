/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Raccoon
{
    struct ProfileData
    {
        uint balance;
        uint locked;
        uint iteration;
        uint feeableTimestamp;
        bool participated;
        bool verified;
        mapping(address => uint) allowance;
    }

    struct PoolData
    {
        uint opened;
        uint deadlineGate;
        uint deadline;
        uint locked;
        uint volume;
    }

    string private name_;
    string private symbol_;
    uint private decimals_;
    uint private totalSupply_;
    uint private maxSupply_;

    uint private mintPrice;
    uint private mintCounter;

    uint private verificationFee;
    uint private transactionFeeCap;
    uint private transactionFeePaid;
    uint private iteration;

    address payable private owner;
    address private utility;

    mapping(address => ProfileData) private profiles;
    mapping(uint => PoolData) private pools;
    
    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Verification(address indexed user);
    event Mint(address indexed user, uint valueETH, uint valueRAC);
    event Fee(address indexed user, uint iteration, uint value);
    event Gate(address indexed user, uint iteration, string status);
    event Traffic(address indexed user, uint iteration, string status);
    event Reward(address indexed user, uint iteration, uint locked, uint reward);
    
    constructor()
    {
        name_ = "Raccoon";
        symbol_ = "RAC";
        decimals_ = 18;
        maxSupply_ = 8000000000 * 10 ** decimals_;
        totalSupply_ = maxSupply_ * 75 / 100;
        verificationFee = 3000 * 10 ** decimals_;
        transactionFeeCap = 20000000 * 10 ** decimals_;
        mintPrice = 0.000003333333333 ether;
        owner = payable(address(0xC908d58587Bfee67B07b6B41229529E79cE605Ca));
        utility = address(0xC5C24a2383Bf5199D1e6E6225C21cC379e362BE5);
        profiles[owner].balance = maxSupply_ * 15 / 100;
        profiles[utility].balance = maxSupply_ * 60 / 100;
        emit Transfer(address(0), owner, profiles[owner].balance);
        emit Transfer(address(0), utility, profiles[utility].balance);
        openPool();
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVerified
    {
        require(profiles[msg.sender].verified);
        _;
    }
    
    function name() external view returns (string memory)
    {
        return name_;
    }
    
    function symbol() external view returns (string memory)
    {
        return symbol_;
    }
    
    function decimals() external view returns (uint)
    {
        return decimals_;
    }
    
    function totalSupply() external view returns (uint)
    {
        return totalSupply_;
    }

    function maxSupply() external view returns (uint)
    {
        return maxSupply_;
    }
    
    function balanceOf(address _owner) external view returns (uint)
    {
        return profiles[_owner].balance;
    }

    function allowance(address _owner, address _spender) external view returns (uint)
    {
        return profiles[_owner].allowance[_spender];
    }

    function cycle() external view returns (uint)
    {
        return iteration;
    }

    function mintsCounter() external view returns (uint)
    {
        return mintCounter;
    }

    function isVerified(address _owner) external view returns (bool)
    {
        return profiles[_owner].verified;
    }

    function pool(uint _iteration) external view returns (PoolData memory)
    {
        require(validIteration(_iteration));
        return pools[_iteration];
    }

    function isPoolInitialized(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].opened > 0;
    }

    function isPoolGatesOpen(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadlineGate >= block.timestamp ? true : false;
    }

    function isPoolRunning(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadline >= block.timestamp ? true : false;
    }

    function poolJoined(address _owner) external view returns (uint itr, uint lkd)
    {
        require(_owner != address(0));
        return (profiles[_owner].iteration, profiles[_owner].locked);
    }

    function approve(address _spender, uint _value) external returns (bool)
    {
        require(_spender != address(0));
        profiles[msg.sender].allowance[_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfering(address _from, address _to, uint _value) private
    {
        profiles[_from].balance -= _value;
        profiles[_to].balance += _value;
        emit Transfer(_from, _to, _value);
        transferingFee(_from, _value);
    }

    function transfer(address _to, uint _value) external returns (bool success)
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= profiles[msg.sender].balance);
        transfering(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool success)
    {
        require(_to != address(0));
        require(_to != _from);
        require(_value <= profiles[_from].balance);
        require(_value <= profiles[_from].allowance[msg.sender]);
        profiles[_from].allowance[msg.sender] -= _value;
        transfering(_from, _to, _value);
        return true;
    }

    function transferingFee(address _from, uint _value) private
    {
        if (profiles[_from].feeableTimestamp + 1 hours <= block.timestamp)
        {
            if (transactionFeePaid < transactionFeeCap)
            {
                profiles[_from].feeableTimestamp = block.timestamp;
                uint fee = _value >= 100 ? (_value / 100) : 0;
                uint pay = transactionFeePaid + fee <= transactionFeeCap ? fee : transactionFeeCap - transactionFeePaid;
                profiles[utility].balance -= pay;
                pools[iteration].volume += pay;
                emit Fee(utility, iteration, pay);
            }
        }
    }

    function mint() payable external returns (bool success)
    {
        uint amount = 10 ** decimals_ * msg.value / mintPrice;
        amount = mintCounter <= 1618 ? amount * 115 / 100 : amount;
        require(amount + totalSupply_ <= maxSupply_);
        profiles[msg.sender].balance += amount;
        totalSupply_ += amount;
        mintCounter++;
        emit Mint(msg.sender, msg.value, amount);
        return true;
    }

    function verify() external returns (bool)
    {
        require(!profiles[msg.sender].verified);
        require(profiles[msg.sender].balance >= verificationFee);
        profiles[msg.sender].balance -= verificationFee;
        profiles[msg.sender].verified = true;
        pools[iteration].volume += verificationFee;
        emit Verification(msg.sender);
        return true;
    }

    function managePool() external returns (bool)
    {
        require(isPoolInitialized(iteration));
        require(!isPoolRunning(iteration));
        closePool();
        openPool();
        return true;
    }

    function openPool() private
    {
        pools[iteration].opened = block.timestamp;
        pools[iteration].deadlineGate = block.timestamp + 45 minutes;
        pools[iteration].deadline = block.timestamp + 60 minutes;
        transactionFeePaid = 0;
        emit Gate(msg.sender, iteration, "open");
    }

    function closePool() private
    {
        emit Gate(msg.sender, iteration, "close");
        iteration++;
    }

    function joinPool(uint _stake) onlyVerified external returns (bool)
    {
        require(isPoolGatesOpen(iteration));
        require(_stake > 0);
        require(profiles[msg.sender].participated == false);
        require(profiles[msg.sender].balance >= _stake);
        profiles[msg.sender].balance -= _stake;
        profiles[msg.sender].participated = true;
        profiles[msg.sender].iteration = iteration;
        profiles[msg.sender].locked = _stake;
        pools[iteration].locked += _stake;
        emit Traffic(msg.sender, iteration, "joined");
        return true;
    }

    function leavePool() onlyVerified external returns (bool)
    {
        require(isPoolGatesOpen(iteration));
        uint index = profiles[msg.sender].iteration;
        uint locked = profiles[msg.sender].locked;
        require(index == iteration);
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].participated = false;
        profiles[msg.sender].balance += locked;
        pools[index].locked -= locked;
        emit Traffic(msg.sender, index, "left");
        return true;
    }

    function claimReward() onlyVerified external returns (uint itr, uint lkd, uint rwd)
    {
        itr = profiles[msg.sender].iteration;
        require(profiles[msg.sender].participated);
        require(isPoolInitialized(itr));//??????????????????????????????
        require(!isPoolRunning(itr));
        lkd = profiles[msg.sender].locked;
        rwd = pools[itr].volume * lkd / pools[itr].locked;
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].participated = false;
        profiles[msg.sender].balance += lkd + rwd;
        emit Reward(msg.sender, itr, lkd, rwd);
        emit Traffic(msg.sender, itr, "left");
        return (itr, lkd, rwd);
    }

    function validIteration(uint _iteration) private view returns (bool)
    {
        require(_iteration <= iteration);
        return true;
    }

    function withdraw() external onlyOwner
    {
        owner.transfer(address(this).balance);
    }
}