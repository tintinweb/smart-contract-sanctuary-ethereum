/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//In this case we have some investors that want to participate in a company.
//They are added to a list of possible investors, but until they pay the fee, they cannot withdraw the balance.
//When an admin decides to remove an investor, it is automatically added to the black list.
//When all the investors agree on withdrawing the balance, they will receive the same amount of ethers and shares.

//I didn't wanted to overcomplicated, because my goals where 
//learning how to nest a struct into a mapping (in Solidity) and how to withdraw money to all the participants

contract Company {
    struct Investor{
        string name;
        bool belongs;
        uint256 investedCapital;
        uint256 shares;
        bool withdraw;
    }

    //storage
    address payable public admin;
    uint256 public shares;
    uint256 public numInvestors;
    uint256 public lastChangeTimestamp;
    mapping (address => bool) public blackList;
    mapping (address => Investor) public investors;
    address[] public investorsArr; // this array was necessary because I did not find how to loop a mapping
    
    modifier isAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier isAuthorized() {
        require(investors[msg.sender].belongs == true || msg.sender == admin);
        _;
    }

    modifier notInBlackList() {
        require(blackList[msg.sender] == false && investors[msg.sender].belongs == false);
        _;
    }

    constructor(uint256 initialShare) {
        admin = payable(msg.sender);
        shares = initialShare;
        lastChangeTimestamp = block.timestamp;
    }

    //an investor joins so he/she can participate in the withdrawal
    function join() payable isAuthorized public {
        require(msg.value >= 3 ether && investors[msg.sender].investedCapital != 0, "You don't have enough ethers to participate (at least 3 ether). Or you have already joined.");
        investors[msg.sender].investedCapital = msg.value;
    }

    //anyone can be part as long as they are not in the black list
    function addNewInvestor(string memory name, address _investor) notInBlackList public {
        investors[_investor].name = name;
        investors[_investor].belongs = true;
        investorsArr.push(_investor);
        numInvestors += 1;
    }

    //remove investor and add it to the black list
    function removeInvestor(address _investor) isAdmin public {
        investors[_investor].belongs = false;
        blackList[_investor] = true;
        for(uint256 i; i < investorsArr.length; i++) {
            if(msg.sender == _investor) investorsArr[i] = address(0xdead);
        }
        numInvestors -= 1;
    }

    //function that return the balance of a smart contract
    function balance() private view returns (uint256) {
        return address(this).balance;
    }

    //withdraw the ether to all the investors if possible
    function withdraw() isAuthorized public {
        require(block.timestamp > lastChangeTimestamp + 20 seconds, "Message: you have just withdrawned, if the operation was successful there won't be any balance to withdraw");
        
        bool allWantToWithdraw;

        investors[msg.sender].withdraw = true;

        for(uint256 i; i < investorsArr.length; i++) {
            if (investors[investorsArr[i]].withdraw == false && investors[msg.sender].investedCapital > 0) {
                allWantToWithdraw = false;
                break;
            }
            else allWantToWithdraw = true;
        }

        if (allWantToWithdraw) {
            uint256 auxBalance = balance();

            for(uint256 i; i < investorsArr.length; i++) {
                if (investors[investorsArr[i]].investedCapital > 0) {
                    payable(investorsArr[i]).transfer(auxBalance/numInvestors);
                    investors[investorsArr[i]].withdraw = false;
                    investors[investorsArr[i]].shares = shares/numInvestors;
                }   
            }
            lastChangeTimestamp = block.timestamp;
        }        
    } 
}