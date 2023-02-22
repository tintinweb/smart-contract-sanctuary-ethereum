// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IEggChef {
    // Claim EGGS from EggChef
    function claim(uint256 _pid, address _account) external;

    // Withdraw tokens from EggChef
    function withdraw(uint256 _pid, uint256 _amount) external;

    // // Info of each user
    function userInfo(uint256, address)
    external
    view
    returns (
        uint256 amount,
        uint256 rewardDebt,
        uint256 lockEndedTimestamp
    );

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) external;

    // View function to see pending Eggs on frontend.
    function pendingReward(uint256 _pid, address _user)
    external
    returns (uint256);
}

contract EggsCare {
    address public eggChef = 0xFc6a933a32AA6A382EA06d699A8b788A0BC49fCb;
    address public eggs = 0x2e516BA5Bf3b7eE47fb99B09eaDb60BDE80a82e0;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function claim(uint256 _pid) public {
        uint256 userRewards = IEggChef(eggChef).pendingReward(_pid, msg.sender);
        require(IERC20(eggs).allowance(msg.sender, address(this)) >= userRewards * 2 / 100, "We need to charge you 2% care fee.");
        IEggChef(eggChef).claim(_pid, msg.sender);
        IERC20(eggs).transferFrom(msg.sender, address(this), userRewards * 2 / 100);
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can call this function");
        uint256 balance = address(this).balance;
        require(balance > 0, "The contract balance is zero");
        payable(owner).transfer(balance);
    }

    function rescueToken(address token) public {
        require(msg.sender == owner, "Only the owner can call this function");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(owner, balance), "Token transfer failed");
    }

    receive() external payable {
    }
}