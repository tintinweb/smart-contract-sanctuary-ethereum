//SPDX-License-Identifier: MIT

//This contract is a solution of Exactly.finance challange https://github.com/exactly-finance/challenge

//# Solution
//This task becomes simple if we imagine that each user buys shares and so, rewards are dividends. It means, when a 
//user interacts with ETHPool and calls makeDeposit(), ETHPool saves count of shares (=ethers/share_price) 
//instead of ethers. When the team makes a reward, the price of the share changes 
//proportionally as reward/total_users_deposit. Count of share doesn't 
//change, only price. From this moment the user's part of 
//reward (we can say) is reinvested.
//User can call withdrawDepositAndRewards() and get his deposit + reward.
//When a new user (or old) makes makeDeposit() - [s]he buys shares by actual price.
//This approach allows don't think about time and don't use arrays of deposit and time when deposit happens (+arrays of
//rewards). (Arrays are very bad for solidity when using loop operators - if our dApp will be successful, the count 
//of users can reach huge amounts and smart-contract functions will need more gas than one block can propose. 
//But this task can be solved by doing things by parts. However, why do we need to complicate it if there 
//exists a better and simpler solution.)

//## Nuances
//Requirement "Only the team can deposit rewards" can be done if smart-contract saves the sum of ethers sent by users
//and the team. But in this case, ethers which were sent directly to smart-contract or smart-contract address 
//which was selfdestruct parameter or in miner coinbase address - these ethers will be saved on 
//smart-contract addresses and do nothing until the team decides to destroy the contract. 
//Current solution allows to send ethers directly on the contract address only 
//by team (reverted to others, except selfdestroy and miner's coinbase). As a result we have an interesting side 
//effect - this amount of ethers can count as minimal guarantee 
//reward - it will be distributed when the team call 
//teamMakesReward() next time, but until next 
//time doesn't happen, users can see 
//reward and maybe more actively 
//makeDeposit().
//Requirement "Users should be able to withdraw their deposits along with their share of rewards considering the time 
//when they deposited" was done by one method withdrawDepositAndRewards(). It is possible to make a method for 
//partial withdrawal (as the contract saves the user's shares count), but, in general, users can call 
//makeDeposit again with desired amount.
//In process "New rewards are deposited manually into the pool by the ETHPool team each week using a contract function"
//mention "each week" was ignored because our solution is time-independent and there no sense to restrict 
//teamMakesReward() at once per week.

//---------------------------------------------------------------------------------------------------------------------
//all tests and some gas optimization were done for this version of solidity. When version changes
//something can happen (maybe tests will still work but gas optimization can get other numbers).
//So, for real contract which operate with users' depo it will be better to write exact
//version of compiler
pragma solidity 0.8.13;

contract ETHPool {

    //introduce MIN_AMOUNT - it prevents rounding errors during mul and div, it equals 10 gwei.
    uint256 private constant MIN_AMOUNT = 10_000_000_000;
    
    //represent shares owned by users in the current moment
    mapping (address => uint256) public sharesOwnedByUsers;
    
    //represent count of users with nonzero shares. when become 0 it used for reset sharePrice 
    //to MIN_AMOUNT but also can be useful for dapp User Interface.
    uint256 public usersCount;
    
    //represent count of shares which exist
    uint256 public totalShares;
    
    //represent current share price. Set it to MIN_AMOUNT at start
    uint256 public sharePrice = MIN_AMOUNT; 

    //represent team address
    address public team;
    
    //Changing of team was realized through 2-steps procedure:
    //at the 1st step old team suppose new team;
    //at the 2nd step new team admit that they ready to be the Team
    //Such a way was chosen because if a team makes a mistake in the address of a new team - control over the contract 
    //will be lost forever. This simple 2-steps procedure insures from typo or miscoping
    address public newTeam; 
    
    //represent event when old team start 2-steps procedure of changing team
    event InitializeTeamChange(address from, address to);

    //represent event when new team admits agreement to be a team
    event TeamChanged(address to);

    //represent event when somebody make deposit 
    event Deposit(address from, uint256 amount, uint currentSharesOfUser);
    
    //represent event when the team adds reward;
    event RewardAdded(uint256 amount, uint256 newSharePrice);
    
    //represent event when a user withdraws rewards;
    event WithdrawSuccesful(address to, uint256 amount);

    //represent event when all users withdraw their deposits and rewards;
    event PoolEmpty(uint256 newSharePrice);

    //represent an event when the team sends ether directly on the contract address. In such case, the reward
    //will be distributed among users during the next call of teamMakesReward. So, team can send
    //ether directly on the contract address with purpose to show and guarantee "at least" reward amount.
    event MinRewardForNextTimeWasAdded(uint256 minReward);

    //represent event when a user can't withdraw deposit
    error UnsuccessfulWithdraw();

    modifier onlyTeam {
        require(msg.sender == team, "Only Team can call this method");
        _;
    }

    constructor(address _team) {
        team = _team;
    }

    //1st step of 2-steps procedure of changing team
    function changeTeam(address _newTeam) external onlyTeam {
        newTeam = _newTeam;
        emit InitializeTeamChange(team, newTeam);
    }

    //2nd step of 2-steps procedure of changing team
    function admitNewTeam() external {
        require(msg.sender == newTeam, "Only newTeam allows"); //<--can be modifier but used only once
        team = newTeam;
        emit TeamChanged(team);
    }

    //users should call this function to deposit their ethers;
    function makeDeposit() external payable {
        require(msg.value >= MIN_AMOUNT, "Min deposit is 10 gwei");

        //gas savings
        uint256 userShareCount = sharesOwnedByUsers[msg.sender];
        if (userShareCount == 0) {
            ++usersCount;
        }

        //introducing local variable saves ~6557 gas (in average)
        uint256 sharesToAdd = msg.value / sharePrice; 
        totalShares += sharesToAdd;
        userShareCount += sharesToAdd;
        sharesOwnedByUsers[msg.sender] = userShareCount;
        emit Deposit(msg.sender, msg.value, userShareCount);
    }
    
    //the team should call this method to make rewards. This method calcs new price of 1 share
    function teamMakesReward() external payable onlyTeam {
        require(usersCount > 0, "No users to catch reward!");
        require(msg.value >= MIN_AMOUNT, "Min rewards is 10 gwei");

        //introducing _sharePrice saves 211 gas
        uint256 _sharePrice = sharePrice;
        uint256 _totalDepositedWithMethods = _sharePrice * totalShares;
        _sharePrice += _sharePrice * (address(this).balance - _totalDepositedWithMethods) / _totalDepositedWithMethods;
        sharePrice = _sharePrice;

        //optimizer works well, _sharePrice or sharePrice cost the same gas. Keep things simple
        emit RewardAdded(msg.value, sharePrice);
    }

    //users call this function to withdraw their deposit + rewards
    function withdrawDepositAndRewards() external {
        uint256 sharesToPay = sharesOwnedByUsers[msg.sender];

        //even in case of reentrancy sharesToPay will be zero and nothing happens
        if (sharesToPay > 0) {
            totalShares -= sharesToPay;
            delete sharesOwnedByUsers[msg.sender];
            uint256 amount = sharesToPay * sharePrice;

            //such type of ether sending allows to send to smart-contract but it is can be dangerous 
            //because smart-contract can try "reentrancy-attack", however it is not our 
            //case - withdraDepositAndRewards() protected from this type of attack
            (bool isSent, ) = msg.sender.call{value: amount}("");
            if (!isSent) {
                revert UnsuccessfulWithdraw();               
            }
            --usersCount;
            if (usersCount == 0) {

                //sharePrice can only grow by design, it is ideal place to reset sharePrice 
                //to defaultValue because there no any shareholders
                sharePrice = MIN_AMOUNT;
                emit PoolEmpty(MIN_AMOUNT);
            } 
            emit WithdrawSuccesful(msg.sender, amount);
        }
    }

    //contract allows to recieve ether only from team
    receive() external payable onlyTeam {

        //usually this method call has 2300 gas, so we can only emit event
        emit MinRewardForNextTimeWasAdded(msg.value);    
    }

    //contract allows to recieve ether only from team
    fallback() external payable onlyTeam {

        //usually this method call has 2300 gas, so we can only emit event
        emit MinRewardForNextTimeWasAdded(msg.value);
    }

    //in case of destructing - send ethers to team 
    function destroy() external payable onlyTeam {
        selfdestruct(payable(msg.sender));
    }
}