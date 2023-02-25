/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

struct moneyRaising{
    uint256 id;
    address payable owner;
    address payable[] members;
    string description;
    uint256 currentAmmount;
    uint256 closingTime;
    uint256 moneyGoal;
    bool filledUp;
    bool isOpened;
}

contract CrowdFunding{
    address contractOwner;
    moneyRaising[] public moneyRaisings;
    mapping (uint256 => mapping(address => uint256)) public donations;
    event openRaising(uint256 id, address owner, string description, uint256 moneyGoal, uint256 closingTime);
    event getDonations(uint256 id, uint256 value);
    event closeRaising(uint256 id, bool filledUp);
    event ethTransfer(address to, uint256 amount);
    event refund(address to, uint256 amount);
    modifier isExpired(uint256 id){
        if(block.timestamp >= moneyRaisings[id].closingTime || !moneyRaisings[id].isOpened){
            revert("Sorry, raising is expired");
        }
        _;
    }
    constructor() payable{
        contractOwner = msg.sender;
    }
    receive() external payable{
        emit ethTransfer(address(this), msg.value);
    }
    fallback() external payable{
        emit ethTransfer(address(this), msg.value);
    }
    function openNewRaising(uint256 _moneyGoal, string calldata _description, uint256 _closingTime) public{
        require(bytes(_description).length != 0);
        require(_moneyGoal != 0);
        address payable[] memory adr;
        moneyRaising memory raising = moneyRaising({
            id: moneyRaisings.length,
            description: _description,
            moneyGoal: _moneyGoal,
            currentAmmount: 0,
            owner: payable(msg.sender),
            closingTime: block.timestamp + _closingTime,
            filledUp: false,
            isOpened: true,
            members: adr
        });
        moneyRaisings.push(raising);
        emit openRaising(raising.id,raising.owner,raising.description,raising.moneyGoal,raising.closingTime);
    }
    function closeNewRaising(uint256 _id) public{
        require(moneyRaisings[_id].isOpened, "Sorry, raising is expired");
        moneyRaising storage raising = moneyRaisings[_id];
        raising.isOpened = false;
        if (raising.currentAmmount == raising.moneyGoal){
            raising.owner.transfer(raising.currentAmmount);
            emit ethTransfer(raising.owner,raising.currentAmmount);
            raising.currentAmmount = 0;
            raising.filledUp = true;   
        }else{
            for (uint256 i = 0; i < raising.members.length; i++){
                raising.members[i].transfer(donations[_id][raising.members[i]]);
                emit refund(raising.members[i], donations[_id][raising.members[i]]);
            }
            raising.currentAmmount = 0;
        }
    }
    function donate(uint256 _id) public payable isExpired(_id){
        require(msg.value != 0, "WEI amount is null. User is not allowed to donate");
        if ((moneyRaisings[_id].currentAmmount + msg.value) > moneyRaisings[_id].moneyGoal){
            if (msg.value > moneyRaisings[_id].moneyGoal){
                moneyRaisings[_id].currentAmmount += msg.value - moneyRaisings[_id].moneyGoal;
                if (donations[_id][msg.sender] == 0){
                    moneyRaisings[_id].members.push(payable(msg.sender));
                }
                donations[_id][msg.sender] += msg.value - moneyRaisings[_id].moneyGoal;
                moneyRaisings[_id].isOpened = false;
            }
            else{
                moneyRaisings[_id].currentAmmount += moneyRaisings[_id].moneyGoal - msg.value;
                if (donations[_id][msg.sender] == 0){
                    moneyRaisings[_id].members.push(payable(msg.sender));
                }
                donations[_id][msg.sender] += moneyRaisings[_id].moneyGoal - msg.value;
                moneyRaisings[_id].isOpened = false;

            }
        }
        else if (moneyRaisings[_id].currentAmmount + msg.value == moneyRaisings[_id].moneyGoal){
            moneyRaisings[_id].currentAmmount += msg.value;
            if (donations[_id][msg.sender] == 0){
                moneyRaisings[_id].members.push(payable(msg.sender));
            }
            donations[_id][msg.sender] += msg.value;
            moneyRaisings[_id].isOpened = false;
        }
        else{
            moneyRaisings[_id].currentAmmount += msg.value;
            if (donations[_id][msg.sender] == 0){
                moneyRaisings[_id].members.push(payable(msg.sender));
            }
            donations[_id][msg.sender] += msg.value;
        }
        emit getDonations(_id,msg.value);
    }
}