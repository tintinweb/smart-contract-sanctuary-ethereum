// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdfund {

    address contractToken;
    uint internal projectslength = 0;

    constructor(address tokenAddress){
        contractToken = tokenAddress;
    }


    struct Project {
        address payable creator;
        string name;
        string description;
        uint supporters;
        uint goal;
        uint invested;
    }
    
    // the key is the project / projectslength
    // use Project.suggestions as length for mapping
    mapping(uint => mapping(address => bool)) internal isSupporting;
    mapping(uint => mapping(address => uint)) internal investAmount;
    mapping(uint => address[]) internal supporters; // key is project index
    
    

    mapping (uint => Project) internal projects;

    function addProject(
        string memory _name,
        string memory _description,
        uint _goal
    ) public {

        projects[projectslength] = Project (
            payable(msg.sender),
            _name,
            _description,
            0,
            _goal,
            0
        );
        projectslength ++;
    }

    function readProject(uint _index) public view returns (
        address _creator,
        string memory _name,
        string memory _description,
        uint _supporters,
        uint _goal,
        uint _invested
    ) {
        return (
            projects[_index].creator,
            projects[_index].name, 
            projects[_index].description, 
            projects[_index].supporters, 
            projects[_index].goal,
            projects[_index].invested
        );
    }
    
    function supportProject(uint _index, uint _amount) public {
        require(
          IERC20Token(contractToken).transferFrom(
            msg.sender,
            projects[_index].creator,
            _amount
          ),
          "support did not go through."
        );
        
        if (isSupporting[_index][msg.sender] != true) {
            projects[_index].supporters ++;
        }
        
        projects[_index].invested += _amount;
        isSupporting[_index][msg.sender] = true;
        
    }
    
    function getSupporters(uint _index) public view returns(address[] memory _supporters) {
        return supporters[_index];
    }
    
    function amountSupported(uint _index, address _addr) public view returns(uint _amount) {
        return investAmount[_index][_addr];
    }
    
    function totalProjects() public view returns (uint) {
        return (projectslength);
    }
    
    
}