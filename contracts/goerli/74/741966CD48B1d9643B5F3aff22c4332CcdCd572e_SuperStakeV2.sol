/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// File: superstakeV2.sol


pragma solidity ^0.8.4;

interface ERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Staking_Standard {

    function deposit(address tokenAddress,address userAddress, uint256 amount) external;
    function withdraw(address tokenAddress,address userAddress, uint256 amount) external ;
    function pendingReward(address account) external view returns (uint256);
    function autoCompound(address tokenAddress, uint256 amount) external returns (uint256) ;
}

// adding modifiers is pending
contract SuperStakeV2 {
    // staking information
    struct stakeDetails{
        uint amount;
        uint stakedAt;
    }

    mapping(address => mapping(address => stakeDetails[])) public balances;
    mapping(address => bool) is_immediate_withdraw_possible;
   // mapping(address => mapping(address => uint)) public balances;
    mapping(address => address) public protocols;
    mapping(address => bool) public isStakingAllowed;
    mapping(address => bool) public isUnstakingAllowed;
    

    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event AutoCompund(address indexed tokenAddress, uint256 amount);
    event ProtocolAdded(address tokenAddress, address protocolAddress);


    function Stake(address[] calldata tokenAddress, uint256[] calldata amount) public {
        require(tokenAddress.length == amount.length,"input array length mismatch");
        for(uint index =0; index < tokenAddress.length; index++ ){
        require(isStakingAllowed[tokenAddress[index]],"staking not enabled");
        
        // making staking struct
        stakeDetails memory stkDetails = stakeDetails(amount[index], block.timestamp);

        // balances(user => token => struct[])
        balances[msg.sender][tokenAddress[index]].push(stkDetails); // TBD in specific code block
        ERC20 token = ERC20(tokenAddress[index]);
        token.transferFrom(msg.sender, protocols[tokenAddress[index]], amount[index]); // TBD in specific code block

        Staking_Standard( protocols[tokenAddress[index]]).deposit(tokenAddress[index],msg.sender, amount[index]);
        emit Deposit(msg.sender, tokenAddress[index], amount[index]);

        
    }        

    }

    function unStake(address tokenAddress, uint256 index) public {

        require(isUnstakingAllowed[tokenAddress],"unstaking not enabled");

        uint amount = balances[msg.sender][tokenAddress][index].amount;

        balances[msg.sender][tokenAddress][index] = balances[msg.sender][tokenAddress][balances[msg.sender][tokenAddress].length - 1];
        balances[msg.sender][tokenAddress].pop();

        Staking_Standard( protocols[tokenAddress]).withdraw(tokenAddress,msg.sender, amount);
        emit Withdraw(msg.sender, tokenAddress, amount);

    }

    function autoCompond(address tokenAddress, uint _amount) public {

            uint autoAmount = Staking_Standard( protocols[tokenAddress]).autoCompound(tokenAddress, _amount);
            emit AutoCompund(tokenAddress, autoAmount);

    }

    function addProtocols(address token, address protocol, bool _is_immediate_withdraw_possible) public{
        protocols[token] = protocol;
        isStakingAllowed[token] = true;
        isUnstakingAllowed[token] = true;
        is_immediate_withdraw_possible[token] = _is_immediate_withdraw_possible;
        emit ProtocolAdded(token ,  protocol);
    }

    function changeStakeStatus(address _token, bool _stake, bool _unstake) public{
        isStakingAllowed[_token] = _stake;
        isUnstakingAllowed[_token] = _unstake;
    }


}