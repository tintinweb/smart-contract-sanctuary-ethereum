// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DirectInvestment {
    struct Company {
        address holder;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountInvested;
        string image;
        address[] investors;
        uint256[] investments;
    }

    mapping(uint256 => Company) public companies;

    uint256 public numberOfCompanies = 0;

    function createCompany(address _holder, string memory _title, string memory _description, 
    uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Company storage company = companies[numberOfCompanies];
        
        require(company.deadline < block.timestamp, "Deadline is the date in the future.");
        company.holder = _holder;
        company.title = _title;
        company.description = _description;
        company.target = _target;
        company.deadline = _deadline;
        company.amountInvested = 0;
        company.image = _image;

        numberOfCompanies++;

        return numberOfCompanies - 1;
    }

    function investToCompany(uint256 _id) public payable{
        uint256 amount = msg.value;

        Company storage company = companies[_id];

        company.investors.push(msg.sender);
        company.investments.push(amount);

        (bool sent,) = payable(company.holder).call{value: amount}("");

        if(sent) {
            company.amountInvested = company.amountInvested + amount;
        }
    }

    function getinvestors(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (companies[_id].investors, companies[_id].investments);
    }

    function getCompanies() public view returns (Company[] memory){
        Company[] memory allCompanies = new Company[](numberOfCompanies);

        for(uint i = 0; i< numberOfCompanies; i++){
            Company storage item = companies[i];

            allCompanies[i] = item;
        }

        return allCompanies;
    }
}