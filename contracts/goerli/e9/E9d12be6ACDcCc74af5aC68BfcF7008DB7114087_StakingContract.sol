/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity ^ 0.8.9;

contract StakingContract {


    address public owner;

    struct StakingPool {
        address owner;
        uint currenTime;
        uint amount;
    }

    constructor() {
        owner = msg.sender;
    }

    event Staked(address indexed from, uint amount);

    event Unstaked(address indexed to, uint amount);
    
    mapping(address => StakingPool) private stakingPoolData;

    function stakeToken(uint amount) external payable {
        // require(payable(address(this)).send(amount), 'Some error occured while staking!');
        // StakingPool storage stakingPool = stakingPoolData[msg.sender];
        // if(stakingPool.amount == 0) {
        //     stakingPool.owner = msg.sender;
        //     stakingPool.currenTime = block.timestamp;
        //     stakingPool.amount = amount;
        //     stakingPoolData[msg.sender] = stakingPool;
        // } else {
        //     stakingPool.amount = stakingPool.amount + amount;
        //     stakingPoolData[msg.sender] = stakingPool;
        // }
        
        emit Staked(msg.sender,amount);

    }   

    function unstakeToken(uint amount) external payable {
        emit Unstaked(msg.sender, amount);
    }   

    receive() external payable {

    }

    function destroy() external payable{
        require(msg.sender == owner, "Only owner can perform this");

        selfdestruct(payable(owner));
    }
}