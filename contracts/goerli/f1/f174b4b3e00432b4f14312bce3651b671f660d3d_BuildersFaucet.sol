// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract BuildersFaucet {
    //total funds in faucet at the moment
    uint256 public totalFunds;
    //total funds sent to an address per given request
    uint256 public payOutAmt;
    //total amount of contributos
    uint256 public totalContributors;

    //total amount Contributed
    uint256 public totalContributed;

    //total amount paid to users
    uint256 public totalRequested;
    //total times paid to users
    uint256 public totalRequests;
    //
    struct Contributor {
        uint256 amtRequested;
        uint256 amtDeposited;
        uint256 lastTimeSentAt;
        bool alreadyContributed;
    }

    //mapping user address to user(contributor) struct
    mapping(address => Contributor) public contributors;

    //deopist event
    event Deposited(
        address indexed userAddress,
        uint256 weiAmount,
        uint256 thisTotal,
        uint256 totalContributors
    );

    //requested event
    event TokensSent(
        address indexed userAddress,
        uint256 weiAmount,
        uint256 thisTotal,
        uint256 totalRequests
    );

    //contract owner
    address public owner;

    constructor() payable {
        totalFunds = 0;
        totalContributors = 0;
        totalRequested = 0;
        totalRequests = 0;
        totalContributed = 0;
        payOutAmt = 50000000000000000; //default on launch ( will be chanegeable via function)
        owner = msg.sender;
    }

    //lets user deposit to the contract
    function deposit() public payable {
        if (contributors[msg.sender].alreadyContributed == false) {
            //update public variables
            totalContributors = totalContributors + 1;
            totalContributed = totalContributed + msg.value;

            //update user variables
            contributors[msg.sender].alreadyContributed = true;
            contributors[msg.sender].amtDeposited =
                contributors[msg.sender].amtDeposited +
                msg.value;
        } else {
            //update public variables
            totalContributed = totalContributed + msg.value;

            //update user variables
            contributors[msg.sender].amtDeposited =
                contributors[msg.sender].amtDeposited +
                msg.value;
        }

        emit Deposited(
            msg.sender,
            msg.value,
            address(this).balance,
            totalContributors
        );
        totalFunds = address(this).balance;
    }

    //functio where owners can set payout amount
    function setPayoutAmt(uint256 weiAmtPayout) public {
        require(msg.sender == owner);
        payOutAmt = weiAmtPayout;
    }

    //for backend purposes only
    function getTimeToWaitUntilNextRequest(address userAddress)
        public
        view
        returns (uint256)
    {
        return contributors[userAddress].lastTimeSentAt;
        // ! OMFG THIS COSTS GAS!!!!
        // ! SAY WHAAAAAAAAAAAAT>>>>?????
        // ! @ https://ethereum.stackexchange.com/questions/70877/how-much-gas-does-looking-up-block-timestamp-consume
        // if (contributors[userAddress].lastTimeSentAt > 0) {
        //     return contributors[userAddress].lastTimeSentAt + 24 hours - block.timestamp;
        // } else {
        //     return 0;
        // }
    }

    //this will pay out users who request -- the reason we have address as input paramter and not msg.sender is becasue we will use web3 on the frontend to get the user's address
    function sendTokensToAddress(address payable userAddress) public {
        require(
            (block.timestamp - contributors[userAddress].lastTimeSentAt) >
                1 days
        );

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = userAddress.call{value: payOutAmt}("");
        require(sent, "Failed to send Ether");

        //update public variables
        totalRequested = totalRequested + payOutAmt;
        totalRequests = totalRequests + 1;

        //update user variables
        contributors[userAddress].amtRequested =
            contributors[userAddress].amtRequested +
            payOutAmt;
        contributors[userAddress].lastTimeSentAt = block.timestamp;

        emit TokensSent(
            userAddress,
            payOutAmt,
            address(this).balance,
            totalRequests
        );
        totalFunds = address(this).balance;
    }

    //returns total amount of ETH contributed
    function gettotalContributed() public view returns (uint256) {
        return totalContributed;
    }

    //returns total funds sin contract
    function getTotalFunds() public view returns (uint256) {
        return totalFunds;
    }

    //returns total contributors
    function getTotalContributors() public view returns (uint256) {
        return totalContributors;
    }

    //returns total requests
    function getTotalRequests() public view returns (uint256) {
        return totalRequests;
    }

    function rescueETH() public {
        require(msg.sender == owner, "Only the owner can resuce the ETH");

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");

        totalFunds = address(this).balance;
    }

    // @dev Allows contract to receive ETH
    receive() external payable {
        // add the amount to totalFunds:
        totalFunds = totalFunds + msg.value;
    }
}