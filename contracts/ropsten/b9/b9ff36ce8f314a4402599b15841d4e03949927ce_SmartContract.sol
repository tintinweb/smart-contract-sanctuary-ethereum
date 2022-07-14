/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.6.0 < 0.9.0;

contract SmartContract { 
    uint256 public price;
    uint8 public limitDays;
    uint256 deadline;

    bool private ContractorPaysDeposit = false;
    bool private FreelancerPaysDeposit = false;

    mapping (address=>uint) balance;
    address public contractor;
    address public freelancer;
    address private Contract;

    address payable payableContractor;
    address payable payableFreelancer;
    address payable payableContract;

    enum State { Created, Hired, Performed, Finished, Canceled } 
    State private state; 

    constructor(
        uint256 _price,
        uint8 _limitDays,
        address _freelancer
    ) public { 
        price = _price * 1000000000; 
        limitDays = limitDays;
        contractor = msg.sender;
        freelancer = _freelancer; 
        state = State.Created;
        Contract = address(this);
        payableContractor = address(uint160(contractor));
        payableFreelancer = address(uint160(freelancer));
        payableContract = address(uint160(Contract));
    }

    modifier onlyContractor{ 
        require(msg.sender == contractor, "You are not the owner of this contract");
        _;
    }

    modifier onlyFreelancer{
        require(msg.sender == freelancer, "You are not the provider of this contract");
        _;
    }

    function deposit() private {
        require(state == State.Finished);
        payableFreelancer.transfer(price + price/5);
    }

    function abort() private {
        require(state == State.Canceled);
        payableContractor.transfer(price);
    }

    function contractorDeposit() public onlyContractor payable { 
        require(msg.value == price, "Wrong price"); 
        balance[msg.sender] += msg.value;

        ContractorPaysDeposit = true;
        if(FreelancerPaysDeposit == true){
            contractCreated();
        }
    }
    
    function freelancerDeposit() public onlyFreelancer payable {
         require(msg.value == price/5, "Wrong price"); 
         balance [msg.sender] += msg.value;

         FreelancerPaysDeposit = true;
         if(ContractorPaysDeposit == true){
            contractCreated(); 
         }
    }

    function contractCreated() private {
    require(FreelancerPaysDeposit == true && ContractorPaysDeposit == true, "Unpaid deposit");
    state = State.Hired;
    deadline = now + (limitDays * 1 days);
    }

    function reverseDeposit() public payable {
        require(state == State.Created, "Invalid reversion");
        if(FreelancerPaysDeposit == true) {
            payableFreelancer.transfer(price/5);
            FreelancerPaysDeposit == false;
        }
        if(ContractorPaysDeposit == true){
            payableContractor.transfer(price);
            ContractorPaysDeposit == false;
        } 
        state = State.Canceled;
    }

    function servicePerformed() public onlyFreelancer {
        require(state == State.Hired, "Contract not valid");
        if(now <= deadline) {
            state = State.Performed;
        }
        else{
            state = State.Canceled;
        }
    }

    function serviceReceived() public onlyContractor {
        require(state == State.Performed, "Service not performed yet");
        if(now <= deadline) {
            state = State.Finished;
            deposit();
        }
        else{
            state = State.Canceled;
        }
    }

    function numContract() public view returns(address contractAddr){
        return address(this);
    }

    function contractBalance() public view returns(uint){
        return address(this).balance;
    }

    function leftTime() public view returns (uint){ 
        if(state != State.Created) {
            return (deadline - now)/ 60/ 60/ 24;
    }
    else {
        return 0;
        }
    }
    function contractRules() public pure returns(string memory services){ 
        return ("The service to be performed for the given contract to be considered finished are the following: 1. A one-hour meeting between the contractor and the freelancer to discuss the project requirements. 2. Produce and post 1 video of 90 seconds duration to post on Instagram as a reel. 3. Produce 3 images explaining the brand's purpose and post it on Instagram. 4. Write all the captions that will be used for the 4 posts (one video reel + 4 images post). 5. Prepare a one-page report about the main performance analytics metrics. 6. Finish the work 30 days.");
    }
    
    function contractStatus() public view returns (string memory status){
        
        if(state == State.Created){ return ("Created");
        }

        if(state == State.Hired){ return ("Hired");
        }

        if(state == State.Performed){ return ("Performed");
        }

        if(state == State.Finished){ return ("Finished");
        }

        if(state == State.Canceled){ return ("Canceled");
        }

    }

    }