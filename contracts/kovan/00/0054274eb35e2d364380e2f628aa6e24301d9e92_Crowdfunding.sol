/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.5.0;

contract Crowdfunding {
    
    struct Project{
        uint id; //项目id
        address user; //众筹发起人
        address payable to; //收款地址
        uint currentAmount; //当前筹集数量
        uint maxAmount; //最大筹集数量
        uint currentPeople; //当前筹集人数
        uint maxPeople; //最大筹集人数
        mapping(address => uint) fromDetail; //用户转入资金
        address payable[] allFroms; //转入资金的用户列表
        uint status; //终止状态 
    }
    
    Project[] public projects; //所有众筹项目

    event NewProject(address from, address to, uint maxAmount, uint maxPeople); //新众筹项目
    event NewContribution(address from, uint pid, uint amount); //新众筹
    event CloseProject(uint pid); //终止众筹项目

    // 添加项目 参数:收款地址, 最大众筹数量, 最大众筹人数
    function add(address payable _to, uint _maxAmount, uint _maxPeople) public returns(bool){
        require(_maxAmount > 0, "Amount must be greater than 0");
        require(_maxPeople > 0, "People must be greater than 0");
        projects.length++;
        Project storage p = projects[projects.length - 1];
        p.id = projects.length - 1;
        p.to = _to;
        p.user = msg.sender;
        p.maxAmount =  _maxAmount;
        p.maxPeople = _maxPeople;
        p.status = 1;
        emit NewProject(msg.sender, _to, _maxAmount, _maxPeople);
        return true;
    }
    
    // 捐款
    function contribution(uint _pid) public payable returns(bool){
        Project storage p = projects[_pid];
        require(msg.value > 0, "Amount must be greater than 0");
        require(p.status!= 0, "Crowdfunding has stopped");
        require(p.currentPeople + 1 <= p.maxPeople, "Exceed the maximum number of people");

        if(p.fromDetail[msg.sender] == 0){
            p.currentPeople += 1; 
            p.allFroms.push(msg.sender);
        }
        p.fromDetail[msg.sender] += msg.value;
        
        uint newAmount =  p.currentAmount + msg.value;
        
        if(newAmount >= p.maxAmount){
            p.status = 2;
            p.to.transfer(newAmount);
        } else if(p.currentPeople == p.maxPeople){
            p.status = 0;
            closeProjectInternal(_pid);
        }
        p.currentAmount += msg.value;
        emit NewContribution(msg.sender, _pid, msg.value);
        return true;
    }
    
    // 关闭项目 
    function closeProject(uint _pid) public returns (bool){
        Project storage p = projects[_pid];
        require(p.user == msg.sender, "You don't have permission");
        require(p.status != 0, "Crowdfunding has stopped");
        closeProjectInternal(_pid);
        p.status = 0;
    }
    

    function closeProjectInternal(uint _pid) internal returns (bool){
        Project storage p = projects[_pid];
        mapping(address => uint) storage _fromDetail = p.fromDetail;
        address payable[] memory _allFroms= p.allFroms;
        for(uint i; i < _allFroms.length; i++){
            address payable account = _allFroms[i];
            uint amount = _fromDetail[account];
            account.transfer(amount);
        }
        emit CloseProject(_pid);
    }
    
    // 项目总长度
    function projectLength() public view returns(uint){
        return projects.length;
    }
}