//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title ETHPool provides a service where people can deposit ETH and they will receive weekly rewards.
/// @author Sherif Abdelmoatty
/// @notice Alembics programming test
contract ETHPool{
    address public governance;  
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) lockedDepositBalances;
    uint256 public totalDepositBalance;
    uint256 totalLockedDepositBalances;
    mapping(address => bool) public isTeam;
    address payable[] public users;

    uint256 public minimumBalance; //minimum allowd balance, to minimize the number
                                    //accounts with small balances to save gas 

    event Deposit(address user,uint256 amount);
    event Withdraw(address user,uint256 amount);

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    modifier onlyTeam() {
        require(isTeam[msg.sender]);
        _;
    }

    constructor(){
        governance = msg.sender;
    }

    /// @notice Add team member
    /// @param member The member address to be added
    function addTeamMember(address member) public onlyGovernance{
        isTeam[member] = true;
    }

    /// @notice Remove team member
    /// @param member The member address to be removed
    function removeTeamMember(address member) public onlyGovernance{
        require(isTeam[member], "Not a team member!");
        isTeam[member] = false;
    }

    /// @notice Set minimumBalance
    function setMinBalance(uint256 _minimumBalance) public onlyGovernance{
        minimumBalance = _minimumBalance;
    }

    /// @notice deposit ether
    function deposit() public payable{
        require(msg.value > 0, "No Ether to deposit!");
        
        if(depositBalances[msg.sender] == 0){ //user isn't in the users list
            require(msg.value > minimumBalance, "Deposit amount is less that the minimum allowed.");
            users.push(payable(msg.sender)); // add user to users list
        }
        depositBalances[msg.sender] += msg.value; //update the user balance
        totalDepositBalance += msg.value; //update the total deposit balance
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice withdraw ether
    /// @param amount to be withdrawn
    function withdraw(uint256 amount) public payable{
        require(amount > 0, "Amount must be higher than 0.");
        require(depositBalances[msg.sender] > amount,
             "No suffecient funds in user balance.");

        depositBalances[msg.sender] -= amount; //update the user balance

        //if remaining balance less than minimumBalance, add the remaining
        //balance to the withdraw amount and set the user balance to 0
        if(depositBalances[msg.sender] < minimumBalance){
            amount += depositBalances[msg.sender];
            depositBalances[msg.sender] = 0;
        }
        totalDepositBalance -= amount; //update the total deposit balance

        //update the locked balance values
        if(lockedDepositBalances[msg.sender] > depositBalances[msg.sender]){
            totalLockedDepositBalances -= lockedDepositBalances[msg.sender] 
                                                - depositBalances[msg.sender];
            lockedDepositBalances[msg.sender] = depositBalances[msg.sender];
        }
        
        payable(msg.sender).transfer(amount); //transfer amount to the user account
        emit Withdraw(msg.sender, amount);
    }

    /// @notice any team member can deposit rewards using this function
    /// @notice and it will distribute the rewards based on the locked balances
    /// @dev the looking period(weekly) depends on how often the team members calls
    /// @dev this function
    function depositAndDestriputeRewards() public payable onlyTeam{
        uint256 totalRewardsBalance = msg.value;
        uint256 tlb = totalLockedDepositBalances;
        for (uint n = 0; n < users.length; n++) { //distribute rewards for each user
            address payable user = users[n];
            if(depositBalances[user] == 0){ 
                users[n] = users[users.length-1];
                delete users[users.length-1]; // remove user if balance 0
                if(n != users.length-1){ //check if last element to prevent infinite loop
                    n--;
                }
                break;
            }
            uint256 reward;
            //check if there is any balances looked
            if(totalLockedDepositBalances > 0){ 
                reward = (lockedDepositBalances[user] * totalRewardsBalance)/
                                totalLockedDepositBalances ;
            }else{
                //this can happen in the first rewards deposit
                //or if every user removed all there balances during the locking period
                reward = (depositBalances[user] * totalRewardsBalance)/
                                totalDepositBalance ;
            }
            
            depositBalances[user] += reward;
            lockedDepositBalances[user] = depositBalances[user];
            tlb += lockedDepositBalances[user];
        }
        totalLockedDepositBalances = tlb;

    }

}