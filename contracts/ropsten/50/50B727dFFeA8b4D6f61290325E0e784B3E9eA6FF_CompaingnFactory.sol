/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity^0.8.7;


//合同部署工厂
contract CompaingnFactory{
    address[] public deployedCampains;
    
    //参数
    function createCampaign(uint256 minimum)public{
        address  compaign= new Campaign(minimum,msg.sender).thisaddress();
        deployedCampains.push(compaign);


    }
      //构造函数
    constructor(){
        

    }
}
//请求结构
struct Request{
    string description;
    uint256 value;
    //收件地址
    address redcpient;
    //是否完成
    bool complete;
    //同意的数量
    uint256 approvalCount;
    


}

//众筹合同
contract Campaign{
    //有谁投票了
    mapping(address=>bool) reqApprovals;


    //管理员
    address public manager;
    //最小众筹金额
    uint256 public minimumContribution;
    //众筹人的地址列表
    mapping(address=>bool) public approvers;
    //合同列表
    Request[] public requests;
    //限制修改器
    modifier restricted(){
        require(msg.sender==manager,"msg.sender==manager");
        _;

    }



    //构造函数
    constructor(uint256 minimum,address sender){
        manager=sender;
        minimumContribution=minimum;
        
        

    }
    //返回当前地址
    function thisaddress()public view returns(address){
        return address(this);

    }
    //众筹函数
    function contribute() public payable{
        //大于最小捐款额
        require(msg.value>minimumContribution,"msg.value>minimumContribution");
        approvers[msg.sender]=true;

    }

    //创建请求
    function createRequest(string memory _description,uint256 _value,address _redcpient)
             public restricted{
        Request memory  request= Request({
            description:_description,
            value:_value,
            redcpient:_redcpient,
            complete:false,
            approvalCount:0
            
            

        });
        requests.push(request);

    }
    //投票批准请求
    function aproveRequest(uint index) public{
        require(approvers[msg.sender]==true,"approvers[msg.sender]==true");
        require(reqApprovals[msg.sender]==false,"reqApprovals[msg.sender]==false");
        reqApprovals[msg.sender]=true;
        requests[index].approvalCount++;



    }

}