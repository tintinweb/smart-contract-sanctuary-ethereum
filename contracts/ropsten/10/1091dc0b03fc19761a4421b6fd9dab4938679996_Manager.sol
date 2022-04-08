/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Manager{

    Project[] public projects;

    event NewProject(
        //address contractAddr,
        address indexed owner,
        address indexed receiver,
        string title,
        string description,
        string img_url,
        uint goalAmount,
        uint duration);

    /**
        @dev Function to get all projects
     */
    function getAllProjects () external view returns (Project[] memory) {
        return projects;
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
        emit NewProject(
           // address(project),
            msg.sender,
            receiver,
            title,
            desc,
            imgUrl,
            goalAmount,
            duration);
    }
}

abstract contract Project{

    // state stores all the infomation about for a project
    struct State{
        address owner;
        address receiver;
        string title;
        string description;
        string img_url;
        uint256 amount;
        uint256 goal_amount;
        uint timestamp;
        //TODO: maybe change deadline to a string with a physical clock? 
        // From a user's perspective, using physical clock makes more sense.
        uint duration; 
        mapping(address => uint256) contribution;
        address[] funders;
        bool active;
    }
    State public state;

    modifier ensure() {
        require(state.timestamp + state.duration * 1 days >= block.timestamp, "This project is expired!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == state.owner, "Permission denied.");
        _;
    }

    modifier active() {
        require(state.active, "This project is not active!");
        _;
    }

    function contribute() public virtual payable returns(bool);
    function changeDuration(uint) public virtual returns(bool);
    function completeProject() public virtual returns(bool);
    function cancelProject() public virtual returns(bool);
    function getCurrentState() public virtual;


}

contract ProjectStandard is Project{

    event stateInfo(address indexed, address indexed, string, string, string, uint256, uint256, uint256, uint, uint, address[]);
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
        state.owner = _owner;
        state.receiver = _receiver;
        state.title = _title;
        state.description = _description;
        state.img_url = _img_url;
        state.goal_amount = _goal_amount;
        state.duration = _duration;
        state.amount = 0;
        state.timestamp = block.timestamp;
        state.active = true;
    }

    function contribute() public active ensure override virtual payable returns(bool){
        state.amount += msg.value;
        
        // record the funder if it's the first time contribute this project
        if(state.contribution[msg.sender] == 0){
            state.funders.push(msg.sender);
        }

        state.contribution[msg.sender] += msg.value;
        emit fundingRecevied(msg.sender, msg.value, address(this).balance);
        return true;
    }

    function completeProject() public active onlyOwner override virtual returns(bool){
        payable(state.receiver).transfer(address(this).balance);
        state.active = false;
        emit projectCompleted(state.owner, state.receiver, state.amount);
        return true;
    }

    function cancelProject() public active onlyOwner override returns(bool){
        for(uint i = 0; i < state.funders.length; i++){
            address funder = state.funders[i];
            uint256 contribution = state.contribution[funder];
            // refund the contribution
            payable(funder).transfer(contribution);
        }
        state.active = false;
        emit projectCanceled(state.owner, state.receiver, state.amount);
        return true;
    }

    function changeDuration(uint _duration) public ensure active onlyOwner override returns(bool){
        require(_duration > state.duration, "Project duration can only be extended.");
        require(address(this).balance < state.goal_amount, "project duration cannot be extended once the funding goal is reached.");
        state.duration = _duration;
        emit durationChanged(state.timestamp, state.duration);
        return true;
    }

    // TODO change it events
    function getCurrentState() public override {
        emit stateInfo(state.owner,
                state.receiver,
                state.title,
                state.description,
                state.img_url,
                state.amount,
                state.goal_amount,
                address(this).balance,
                state.timestamp,
                state.duration,
                state.funders);
    }

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
               }

    function contribute() public active ensure override payable returns(bool){
        state.amount += msg.value;
        
        // record the funder if it's the first time contribute this project
        if(state.contribution[msg.sender] == 0){
            state.funders.push(msg.sender);
        }

        state.contribution[msg.sender] += msg.value;
        lottery.prize = address(this).balance / 100 * lottery.percentage;
        emit fundingRecevied(msg.sender, msg.value, address(this).balance);
        return true;
    }

    function completeProject() public active onlyOwner override returns(bool){
        // draw winner
        if(lottery.prize > 0){
            uint256 _draw = rand(state.amount);
            uint256 _cur = 0;
            for(uint i = 0; i < state.funders.length; i++){
                address funder = state.funders[i];
                _cur += state.contribution[funder];
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

        payable(state.receiver).transfer(address(this).balance);
        state.active = false;
        emit projectCompleted(state.owner, state.receiver, state.amount);
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