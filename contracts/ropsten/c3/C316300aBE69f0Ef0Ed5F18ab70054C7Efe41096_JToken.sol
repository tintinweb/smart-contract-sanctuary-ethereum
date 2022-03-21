//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";

contract JToken is Ownable {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    mapping(address => uint256) public rewardTimeTracker;

    string public name = "JToken";
    string public symbol = "JT";
    uint8 public decimals = 18;

    uint256 public tokenPrice = 0.001 ether;
    uint256 public numberPerToken = 1000;
    address payable public the_owner;
    address[] internal stakeholders;

    // Payable constructor can receive Ether
    constructor() payable {
        totalSupply = 10000 * 10**18;
        the_owner = payable(msg.sender);
        _mint(1000 * 10**18);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed the_owner,
        address indexed spender,
        uint256 value
    );
    event Buy(address indexed addr, bool value);
    event ChangePrice(uint256 value);
    event Stake(address addr, uint256 stake);
    event Reward(address addr, uint256 reward, bool value);

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(to, amount);
        return true;
    }

    function _transfer(address recipient, uint256 amount)
        internal
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        _mint(amount);
    }

    function _mint(uint256 amount) internal {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function buyToken(address receiver) external payable {
        require(msg.value > 0, "Insufficient Ether provided");
        (bool success, ) = the_owner.call{value: msg.value}("");
        require(success, "Failed to send money");

        uint256 tokens = numberPerToken * msg.value;
        totalSupply -= tokens;
        balanceOf[receiver] += tokens;
        totalSupply += tokens;
        emit Buy(receiver, success);
    }

    function modifyTokenBuyPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        uint256 gen = 1;
        numberPerToken = gen / price;
        emit ChangePrice(tokenPrice);
    }

    function createStake(uint256 _stake) public {
        _burn(_stake);
        if (stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender] + _stake;
        rewardTimeTracker[msg.sender] = block.timestamp;
        emit Stake(msg.sender, _stake);
    }

    function getTokenStacked(address _address) public view returns (uint256) {
        return stakes[_address];
    }

    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function claimReward() public {
        if (block.timestamp >= rewardTimeTracker[msg.sender] + 7 days) {
            uint256 reward = (stakes[msg.sender] * 1) / 100;
            balanceOf[msg.sender] += reward;
            rewardTimeTracker[msg.sender] = block.timestamp;
            emit Reward(msg.sender, reward, true);
        } else {
            emit Reward(msg.sender, 0, false);
        }
    }
}