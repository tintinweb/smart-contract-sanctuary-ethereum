//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;


contract TriklV2{

     // address owner;
    address private immutable i_owner;

    //creator reward pool
    //mapping(uint256 => address) public rewardPools; 

    mapping(address => uint) public rewardPools;

    // custom error to save gas
    error NotOwner();
    error ContractCalling();
    error TransactionFailed();
    error InsufficientBalance();
    error NotEnoughBalance();

     event FundRewardPool(
        address indexed from,
        uint256 amount
    );


   constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
   
    function tip(address _creatorAddress) external payable {
        if (tx.origin != msg.sender) {
                revert ContractCalling();
            }

        (
                bool sent, /*memory data*/

            ) = _creatorAddress.call{value: ((msg.value * 900) / 1000)}("");
            if (!sent) {
                revert TransactionFailed();
            }
    }

    function fundRewardPool() public payable {
        emit FundRewardPool(msg.sender, msg.value);
        rewardPools[msg.sender] = rewardPools[msg.sender] + msg.value;
    }

    function fundCreatorPool(address _creator) public payable{
        emit FundRewardPool(_creator, msg.value);
        rewardPools[_creator] = rewardPools[_creator] + msg.value;
    }

    function distributeRewards(address _winner1, address _winner2, address _winner3) public{         

        uint256 rewardamount = rewardPools[msg.sender]; 

        if (rewardamount <= 0) {
                revert NotEnoughBalance();
            }

        rewardPools[msg.sender] = 0;

        payable(_winner1).transfer((rewardamount * 500) / 1000);
        payable(_winner2).transfer((rewardamount * 300) / 1000);
        payable(_winner3).transfer((rewardamount * 200) / 1000);

    }


    /*********************************************************
     *                                                       *
     *                    Owner functions                    *
     *                                                       *
     *********************************************************/

    function withdraw(uint _amount) external onlyOwner {
        if (_amount > address(this).balance) {
            revert InsufficientBalance();
        }
        (
            bool sent, /*memory data*/

        ) = i_owner.call{value: _amount}("");
        if (!sent) {
            revert TransactionFailed();
        }
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

}