/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 <0.9.0;

contract CrowdFunding{

    event listed_idea(uint idea_id);

    uint256 id_counter = 0;

    uint256 all_time_raised = 0;

    struct idea{
        bool is_active; 
        string title;
        string desc;
        string owner_name;
        string links;
        uint256 unique_id;
        uint256 funding_req;
        uint256 time_of_creation;
        uint256 funding_raised;
        uint256 time_of_deadline;
        uint256 number_of_backers;
        address idea_owner;
    }

    struct donor{
        address donator;
        uint256 amount_donated;
        bool is_refunded;
    }

    mapping(uint256 => donor[]) public project_donators;

    idea[] public ideas;

    function list_new_idea(string memory title, string memory desc, string memory owner_name, string memory links, uint256 funding_req, uint days_to_deadline) public returns(uint256){
        require(days_to_deadline > 0);
        require(funding_req > 0);
        
        ideas.push(idea(true, title, desc,owner_name, links,id_counter,funding_req, block.timestamp, 0, uint256(block.timestamp + days_to_deadline *1 days),0, msg.sender));
        id_counter++;
        emit listed_idea(id_counter-1);
        return id_counter-1;
    }

    function view_all_ideas() public view returns(idea[] memory){
        // return all ideas on platform
        return ideas;
    }

    function donate_to_idea(uint256 idea_id, uint amount) public payable returns(donor[] memory){
        require(block.timestamp < ideas[idea_id].time_of_deadline);
        require(ideas[idea_id].is_active==true);
        require(msg.value > 0 && msg.value==amount);
        // enable a person to donate to an already existing idea
        uint256 amt = msg.value;
        all_time_raised+=amt;
        ideas[idea_id].funding_raised+=amt;
        donor[] storage mydonor = project_donators[idea_id];
        uint flag=0;
        for(uint i=0;i<mydonor.length;i++){
            if(mydonor[i].donator == msg.sender){
                mydonor[i].amount_donated += amt;
                flag=1;
                break;
            }
        }
        if(flag==0){
            mydonor.push(donor(msg.sender, amt, false));
            ideas[idea_id].number_of_backers++;
        }
        return project_donators[idea_id];
    }

    function view_contract_balance() public view returns(uint256){
        // returns contract balance
        return address(this).balance;
    }

    function number_of_donations(uint256 idea_id) public view returns(uint256){
        // returns number of donations made to a project
        return project_donators[idea_id].length;
    }

    function donated_amount_to_project(uint256 idea_id) public view returns(uint256){
        // tells how much a user donated to a project
        uint256 donated_amt=0;
        donor[] storage mydonor = project_donators[idea_id];
        for(uint i=0;i<mydonor.length;i++){
            if(mydonor[i].donator == msg.sender){
                if(mydonor[i].is_refunded==false)
                    donated_amt += mydonor[i].amount_donated;
                break;
            }
        }
        return donated_amt;
    }

    function donated_across_all_projects() public view returns(uint256){
        // tells how much a user donated across all projects
        uint total = 0;
        for(uint i=0;i<ideas.length;i++){
            total+=donated_amount_to_project(i);
        }
        return total;
    }

    function withdraw_funding_raised(uint idea_id) public {
        // withdrawing when we raised funding
        require(ideas[idea_id].is_active==true);
        require(ideas[idea_id].idea_owner == msg.sender);
        require(block.timestamp > ideas[idea_id].time_of_deadline);
        require(ideas[idea_id].funding_raised >= ideas[idea_id].funding_req);
        uint amt = ideas[idea_id].funding_raised;
        payable(msg.sender).transfer(amt);
        ideas[idea_id].is_active=false;
    }

    function claim_refund(uint idea_id) public{
        require(block.timestamp > ideas[idea_id].time_of_deadline);
        require(ideas[idea_id].funding_raised < ideas[idea_id].funding_req);
        donor[] storage mydonor = project_donators[idea_id];
        uint amt=0;
        uint idx=0;
        for(uint i=0;i<mydonor.length;i++){
            if(mydonor[i].donator == msg.sender){
                amt=mydonor[i].amount_donated;
                idx=i;
                break;
            }
        }
        require(mydonor[idx].is_refunded==false);
        if(amt!=0){
            payable(msg.sender).transfer(amt);
            mydonor[idx].is_refunded=true;
        }
    }

}