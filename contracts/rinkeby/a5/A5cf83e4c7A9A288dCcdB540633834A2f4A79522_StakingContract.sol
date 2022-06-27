// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract StakingContract {

    struct Staker {
        address owner;
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
        uint256 period;
    }

    address public contractOwner;

    constructor(){
        contractOwner = msg.sender;
    }

    receive() external payable{}

    mapping(address => Staker) private staker;
    address[] private stakerList;
    uint256 public interestRate = 1;
    uint public minimumAmount = 10000000000;

    event StakingInformation(address, uint, uint, uint, uint);

    function stake(uint _period) public payable {
        require(!isStaker(msg.sender), "You have already staked.");
        require(msg.value >= minimumAmount, "You need to spend more ETH");
        staker[msg.sender] = Staker(msg.sender, msg.value, interestRate, block.timestamp, _period);
        stakerList.push(msg.sender);
        emit StakingInformation(
            staker[msg.sender].owner, 
            staker[msg.sender].amount, 
            staker[msg.sender].interestRate,
            staker[msg.sender].startTime, 
            staker[msg.sender].period
        );
    }

    function isStaker(address addr) private view returns (bool){
        for (uint i=0; i<stakerList.length; i++){
            if (stakerList[i] == addr) return true;
        }
        return false;
    }

    function currentAmount() public view returns (uint) {
        require(isStaker(msg.sender), "You have not staked yet.");
        Staker memory s = staker[msg.sender];
        if (block.timestamp-s.startTime < s.period) return s.amount + s.amount*s.interestRate*(block.timestamp-s.startTime)/100;
        else return s.amount + s.amount*s.interestRate*s.period/100;
    }

    function period() public view returns (uint) {
        require(isStaker(msg.sender), "You have not staked yet.");
        return staker[msg.sender].period;
    }

    function unStake() public {
        require(isStaker(msg.sender), "You have not staked yet.");
        Staker memory s = staker[msg.sender];
        require(block.timestamp-s.startTime>=s.period, "Not end the period yet.");
        payable(msg.sender).transfer(s.amount + s.amount*interestRate*s.period/100);

        delete(staker[msg.sender]);

        for (uint i=0; i<stakerList.length; i++){
            if (stakerList[i] == msg.sender) {
                delete(stakerList[i]);
                return;
            }
        }  
    } 

    function changeInterestRate(uint _interestRate) public {
        require(msg.sender == contractOwner, "You are not the contract owner.");
        require(_interestRate > 0, "Interest Rate must be greater than 0.");
        interestRate = _interestRate;
    }

    function changeMinimumAmount(uint _minimumAmount) public {
        require(msg.sender == contractOwner, "You are not the contract owner.");
        require(_minimumAmount > 0, "Interest Rate must be greater than 0.");
        minimumAmount = _minimumAmount;
    }

    function balance() external view returns (uint){
        require(msg.sender == contractOwner, "You are not the contract owner.");
        return address(this).balance;
    }
}