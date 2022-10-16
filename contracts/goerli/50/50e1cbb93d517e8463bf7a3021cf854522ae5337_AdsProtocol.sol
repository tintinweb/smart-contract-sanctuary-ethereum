// SPDX-License-Identifier:MIT
pragma solidity ^0.8;

import "./ProjectDashboard.sol";
import "./Space.sol";

contract AdsProtocol is IAdsProtocol{
    address[] private allProjectDashboard;
    address[] private allSpace;
    address[] private marketFactory;
    address public override Stargate;
    bool public feeOn;
    uint public fee;
    mapping(address=>address) public projectDashboardAddress;
    mapping(address=>address) public override spaceAddress;
    mapping(string=>bool) public projectNameUsed;
    mapping(string=>bool) public spaceNameUsed;
    
    event LaunchProject(address indexed project,address indexed projectDashboard,string indexed name);
    event CreateSpace(address indexed user,address indexed space,string indexed name);
    event Log(address sender,uint value);

    modifier OnlyStargate(){
        if(msg.sender!=Stargate){
            revert ForbidError("Only Stargate");
        }
        _;
    }

    error ForbidError(string);
    error AlreadyRegistered(address);
    
    constructor(address _Stargate){
        Stargate = _Stargate;
    }

    fallback()external payable{
        emit Log(msg.sender,msg.value);
    }
    receive() external payable{
        emit Log(msg.sender,msg.value);
    }

    function launchProject(string memory _projectName)external{
        address  creater = msg.sender;
        address projectDashboard = projectDashboardAddress[creater];
        if (projectDashboard!=address(0)){
            revert AlreadyRegistered(projectDashboard);
        }
        ProjectDashboard project = new ProjectDashboard(_projectName,creater,address(this));
        allProjectDashboard.push(address(project));
        projectDashboardAddress[creater] = address(project);
        projectNameUsed[_projectName] = true;
        emit LaunchProject(creater,address(project),_projectName);
    }

    function createSpace(string memory _spaceName)external payable{
        if(feeOn==true){
            if(msg.value!=fee){
                revert ForbidError("Invalid Value");
            }
        }
        address  creater = msg.sender;
        address spaceCheck = spaceAddress[creater];
        if (spaceCheck!=address(0)){
            revert AlreadyRegistered(spaceCheck);
        }
        Space space = new Space(_spaceName,creater);
        allSpace.push(address(space));
        spaceAddress[creater] = address(space);
        spaceNameUsed[_spaceName] = true;
        emit LaunchProject(creater,address(space),_spaceName);

    }

    function updataMarket(address _newMarket)external OnlyStargate{ 
        marketFactory.push(_newMarket);
    }

    function getMarketFactoryAddress(uint _index)external view override returns(address _marketFactory){
        if(_index > marketFactory.length){
            revert ForbidError("Error MarketIndex");
        }
        _marketFactory = marketFactory[_index-1];
    }

    function setFeeOn(bool on_off)external OnlyStargate{ 
        feeOn = on_off;
    }
    function setFeeAmount(uint _fee)external OnlyStargate{
        fee = _fee;
    }
    function getLaunchedProjectAmount()external view returns(uint len){
        len = allProjectDashboard.length;
    }
    function getLaunchedSpaceAmount()external view returns(uint len){
        len = allSpace.length;
    }
    function getMarketAmount()external view returns(uint len){
        len = marketFactory.length;
    }
    function getFee()external OnlyStargate{
        payable(Stargate).transfer(address(this).balance);
    }

}