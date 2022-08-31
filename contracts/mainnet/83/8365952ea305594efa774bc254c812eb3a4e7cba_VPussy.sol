/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// File: Farm.sol


pragma solidity ^0.8;

contract VPussy {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    uint public rewardRate = 1 ether;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public lastStaked;

    constructor() {
        owner = msg.sender;
        stakingToken = IERC20(0x2284c0100Fc9146E7FA5eF9DcEb1a822FBD6a403);
        rewardsToken = IERC20(0xd9F3D410A62d6feDf7b0F00197B807012EBFEE06);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    function stake(uint _amount) external {
        require(_amount > 0, "amount = 0");
        if(balanceOf[msg.sender] > 0) {
            claim(msg.sender);
        } else {
            lastStaked[msg.sender] = block.timestamp;
        }
        balanceOf[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "amount = 0");
        require(balanceOf[msg.sender] > 0, "none staked to withdraw lol");
        claim(msg.sender);
        lastStaked[msg.sender] = block.timestamp;
        balanceOf[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getRewards(address account) public view returns (uint256) {
        require(lastStaked[account] != 0, "GetRewards: User Hasn't Staked!");
        uint256 timeStaked = block.timestamp - lastStaked[account];
        uint256 amount = timeStaked * rewardRate;
        return amount;
    }

    function claim(address account) public {
        uint256 amount = getRewards(account);
        lastStaked[account] = block.timestamp;
        rewardsToken.mint(account, amount);
    }


}

interface IERC20 {
    function mint(address recipient, uint256 amount) external;

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}