/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Manager{

    Project[] public projects;

    event NewStandardProject(
        //address contractAddr,
        address indexed owner,
        address indexed receiver,
        string title,
        string description,
        string img_url,
        uint goalAmount,
        uint duration);

    event NewLotteryProject(
        //address contractAddr,
        address indexed owner,
        address indexed receiver,
        string title,
        string description,
        string img_url,
        uint goalAmount,
        uint duration,
        uint percentage);

    /**
        @dev Function to get all projects
     */
    function getAllProjects () external view returns (Project[] memory) {
        return projects;
    }

    /**
        @dev Function to get all projects that are created by msg sender
     */
    function getMyOwnProjects () external view returns (Project[] memory) {
        uint num = 0;
        for(uint i = 0; i < projects.length; i++){
            if(projects[i].owner() == msg.sender) {
                num++;
            }
        }
        Project[] memory myProjects = new Project[](num);
        uint count = 0;
        for(uint i = 0; i < projects.length; i++){
            if(projects[i].owner() == msg.sender) {
                myProjects[count] = projects[i];
                count++;
            }
        }
        return myProjects;
    }

    /**
        @dev Function to get all projects that are funded by msg sender
     */
    function getMyFundedProjects () external view returns (Project[] memory) {
        uint num = 0;
        for(uint i = 0; i < projects.length; i++){
            for(uint j = 0; j < projects[i].getNumFunders();j++){
                if(projects[i].funders(j) == msg.sender) {
                    num++;
                    break;
                }
            }
        }
        Project[] memory fundedProjects = new Project[](num);
        uint count = 0;
        for(uint i = 0; i < projects.length; i++){
            for(uint j = 0; j < projects[i].getNumFunders();j++){
                if(projects[i].funders(j) == msg.sender) {
                    fundedProjects[count] = projects[i];
                    count++;
                    break;
                }
            }
        }
        return fundedProjects;
    }

    /**
        @dev Function to create a new Project
        @param receiver Reveiver of the new Project
        @param title Title of the funding project
        @param desc Desc of the funding project
        @param goalAmount Funding target
        @param duration Duration of project
     */
    function createProject(
        address receiver,
        // calldata read-only
        string calldata title, 
        string calldata desc, 
        string calldata imgUrl,
        uint256 goalAmount,
        uint256 duration) external {
        require(receiver != address(0), "Invalid receiver address!");
        require(bytes(title).length != 0, "Title cannot be empty!");
        require(bytes(desc).length != 0, "Description cannot be empty!");
        require(goalAmount > 0, "Funding goal should not be zero!");
        require(duration > 0, "Project duration should be at least 1 day!");

        Project project = new ProjectStandard(msg.sender, receiver, title, desc, imgUrl, goalAmount, duration);
        projects.push(project);
        emit NewStandardProject(
           // address(project),
            msg.sender,
            receiver,
            title,
            desc,
            imgUrl,
            goalAmount,
            duration);
    }

    /**
        @dev Function to create a new Project
        @param _receiver Reveiver of the new Project
        @param _title Title of the funding project
        @param _desc Desc of the funding project
        @param _goalAmount Funding target
        @param _duration Duration of project
        @param _percentage Percentage of funding as lottery prize pool
     */
    function createLotteryProject(
        address _receiver,
        // calldata read-only
        string calldata _title, 
        string calldata _desc, 
        string calldata _imgUrl,
        uint256 _goalAmount,
        uint256 _duration,
        uint8 _percentage) external {
        require(_receiver != address(0), "Invalid receiver address!");
        require(bytes(_title).length != 0, "Title cannot be empty!");
        require(bytes(_desc).length != 0, "Description cannot be empty!");
        require(_goalAmount > 0, "Funding goal should not be zero!");
        require(_duration > 0, "Project duration should be at least 1 day!");
        require(_percentage > 5 && _percentage < 75, "At least 5% of funding and at most 75% of funding can be used as lottery prize pool!");

        Project project = new ProjectLottery(msg.sender, _receiver, _title, _desc, _imgUrl, _goalAmount, _duration, _percentage);
        projects.push(project);
        emit NewLotteryProject(
           // address(project),
            msg.sender,
            _receiver,
            _title,
            _desc,
            _imgUrl,
            _goalAmount,
            _duration,
            _percentage);
    }
}

abstract contract Project{

    // state stores all the infomation about for a project
    address public owner;
    address public receiver;
    string public category;
    string public title;
    string public description;
    string public img_url;
    uint256 public amount;
    uint256 public goal_amount;
    uint public timestamp;
    uint public duration; 
    mapping(address => uint256) public contribution;
    address[] public funders;
    bool public active;

    modifier ensure() {
        require(timestamp + duration * 1 days >= block.timestamp, "This project is expired!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    modifier isActive() {
        require(active, "This project is not active!");
        _;
    }

    modifier minimum() {
        require(msg.value > 0, "You cannot contribute 0 ether.");
        _;
    }

    function contribute() public virtual payable returns(bool);
    function changeDuration(uint) public virtual returns(bool);
    function completeProject() public virtual returns(bool);
    function cancelProject() public virtual returns(bool);
    function getNumFunders() external view virtual returns(uint);
    // function getCurrentState() public virtual;


}

contract ProjectStandard is Project{

    // event stateInfo(address indexed, address indexed, string, string, string, uint256, uint256, uint256, uint, uint, address[]);
    event fundingRecevied(address indexed, uint256, uint256);
    event projectCompleted(address indexed, address indexed, uint256);
    event projectCanceled(address indexed, address indexed, uint256);
    event durationChanged(uint, uint);

    constructor(address _owner, 
               address _receiver, 
               string memory _title, 
               string memory _description,
               string memory _img_url,
               uint256 _goal_amount,
               uint _duration) {
        owner = _owner;
        receiver = _receiver;
        category = "standard";
        title = _title;
        description = _description;
        img_url = _img_url;
        goal_amount = _goal_amount;
        duration = _duration;
        amount = 0;
        timestamp = block.timestamp;
        active = true;
    }

    function contribute() public isActive ensure minimum override virtual payable returns(bool){
        amount += msg.value;
        
        // record the funder if it's the first time contribute this project
        if(contribution[msg.sender] == 0){
            funders.push(msg.sender);
        }

        contribution[msg.sender] += msg.value;
        emit fundingRecevied(msg.sender, msg.value, address(this).balance);
        return true;
    }

    function completeProject() public isActive onlyOwner override virtual returns(bool){
        payable(receiver).transfer(address(this).balance);
        active = false;
        emit projectCompleted(owner, receiver, amount);
        return true;
    }

    function cancelProject() public isActive onlyOwner override returns(bool){
        for(uint i = 0; i < funders.length; i++){
            address funder = funders[i];
            uint256 contribution = contribution[funder];
            // refund the contribution
            payable(funder).transfer(contribution);
        }
        active = false;
        emit projectCanceled(owner, receiver, amount);
        return true;
    }

    function changeDuration(uint _duration) public ensure isActive onlyOwner override returns(bool){
        require(_duration > duration, "Project duration can only be extended.");
        require(address(this).balance < goal_amount, "project duration cannot be extended once the funding goal is reached.");
        duration = _duration;
        emit durationChanged(timestamp, duration);
        return true;
    }

    function getNumFunders() external view override returns(uint) {
        return funders.length;
    }

    // TODO change it events
    // function getCurrentState() public override {
    //     emit stateInfo(owner,
    //             receiver,
    //             title,
    //             description,
    //             img_url,
    //             amount,
    //             goal_amount,
    //             address(this).balance,
    //             timestamp,
    //             duration,
    //             funders);
    // }

}

contract ProjectLottery is ProjectStandard{

    struct Lottery{
        address winner;
        uint256 prize;
        uint256 drawTimestamp;
        uint8 percentage;
    }
    Lottery public lottery;

    event lotteryDrawn(address indexed, uint256);

    constructor(address _owner, 
               address _receiver, 
               string memory _title, 
               string memory _description,
               string memory _img_url,
               uint256 _goal_amount,
               uint _duration,
               uint8 _percentage) ProjectStandard(_owner, _receiver, _title, _description, _img_url, _goal_amount, _duration){
                   lottery.percentage = _percentage;
                   category = "lottery";
               }

    function contribute() public isActive ensure minimum override payable returns(bool){
        amount += msg.value;
        
        // record the funder if it's the first time contribute this project
        if(contribution[msg.sender] == 0){
            funders.push(msg.sender);
        }

        contribution[msg.sender] += msg.value;
        lottery.prize = address(this).balance / 100 * lottery.percentage;
        emit fundingRecevied(msg.sender, msg.value, address(this).balance);
        return true;
    }

    function completeProject() public isActive onlyOwner override returns(bool){
        // draw winner
        if(lottery.prize > 0){
            uint256 _draw = rand(amount);
            uint256 _cur = 0;
            for(uint i = 0; i < funders.length; i++){
                address funder = funders[i];
                _cur += contribution[funder];
                if(_cur > _draw)
                {
                    lottery.winner = funder;
                    lottery.drawTimestamp = block.timestamp;
                    payable(funder).transfer(lottery.prize);
                    emit lotteryDrawn(funder, lottery.prize);
                    break;
                }
            } 
        }

        payable(receiver).transfer(address(this).balance);
        active = false;
        emit projectCompleted(owner, receiver, amount);
        return true;
    }

    function rand(uint256 _max)
        internal
        view
        returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / _max) * _max));
    }
}