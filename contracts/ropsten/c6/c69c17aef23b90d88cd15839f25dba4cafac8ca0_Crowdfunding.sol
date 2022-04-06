/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 <0.9.0;

contract Crowdfunding{

    //Storage struct
    struct Project{
        uint id;
        address payable wallet;
        string name;
        string description;
        uint totalAmount;
        uint collected;
        ProjectState isFull;
    }

    struct Contribution{
        address contributor;
        uint value;
        uint date;
    }

    //enum
    enum ProjectState {Incomplete, Complete}

    //Events 
    event ProjectCreated(
        uint id,
        address wallet,
        string name,
        string description,
        uint totalAmount
    );

    event MoneyInput(
        address from,
        uint project,
        uint amount,
        uint date
    );

    event ProjectChange(
        uint numberChangeProject,
        ProjectState newState
    );

    //projects array
    Project[] public projects;

    //Modifiers
    modifier noWner(uint _number){
        require(msg.sender!=projects[_number].wallet, "The owners can't aport money for their own projects");
        //the function will be insert here
        _;
    }

    //errors
    error InputInvalid(uint input);
    error StateInvalid(ProjectState state);

    //mappings
    mapping(uint => Contribution[]) public contributions;


    //FUNCTIONS

    //create project
    function createProject(string memory _name, string memory _description, uint _totalAmount) public returns(string memory state){
        require(_totalAmount>0, "The amount should be greater than 0 wei");
        projects.push(Project(projects.length+1, payable(msg.sender), _name, _description, _totalAmount, 0, ProjectState.Incomplete));
        emit ProjectCreated(projects.length, msg.sender, _name, _description, _totalAmount);
        state = "success";
    }

    //contribute
    function fundProject(uint _number) public payable noWner(_number) returns(string memory stateTx, uint valor, uint collected){
        require(msg.value > 0, "The aport amount should be greater than 0 wei");

       if(_number>=0 && _number<projects.length){
           require(projects[_number].collected+msg.value<=projects[_number].totalAmount, "The project can't receive this amount, 'cause it exceeds the limit");
           projects[_number].wallet.transfer(msg.value); //send money
           projects[_number].collected += msg.value; //+ at the counter
           stateTx = "success";
           collected = projects[_number].collected;
           valor = msg.value;
           if(projects[_number].collected==projects[_number].totalAmount){
                changeProjectState(_number);
            }        
       }
       else{
           revert InputInvalid(_number);
       }

       //keep the contribution
       contributions[_number].push(Contribution(msg.sender, msg.value, block.timestamp));

       //back event
       emit MoneyInput(msg.sender, _number, msg.value, block.timestamp);

    }

    function changeProjectState(uint _option) private{
        projects[_option].isFull=ProjectState.Complete;
        emit ProjectChange(_option, projects[_option].isFull);
    }

    function getBalances(uint _number) public view returns(uint balance){
        if(_number>=0 && _number<projects.length){
            balance=projects[_number].collected;
        }
        else{
            revert InputInvalid(_number);
        }
    }
    
}