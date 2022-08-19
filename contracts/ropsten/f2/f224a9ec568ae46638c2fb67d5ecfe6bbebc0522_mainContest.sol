/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//date 2022/08/11 tony
pragma solidity ^0.5.0;                                  

interface IERC20 {//繼承token 的 balanceOf & transfer的功能
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract contest{//目前設定公司抽成100代幣
    address private creater;//比賽創辦者
    uint256 private initial_prize;//初始獎金
    uint256[] private proportion;//分配比例
    uint256 private attendFee; //參賽費
    string private rule;
    address private parentContract;//比賽主合約地址
    address private companyAddress;
    string private prove;
    //uint256 private status=0;// 1:創建完成 2:繳費完成
    IERC20 token = IERC20(address(0xd76c64574484bB9a39BB8fc88D4871729187Ecee));//代幣地址
    

    constructor(address _creater,uint256 _prize,uint256[] memory _proportion,uint256 _attendFee,string memory _rule,address _companyAddress)public
    {
        creater=_creater;
        initial_prize=_prize;
        proportion=_proportion;
        attendFee=_attendFee;
        rule=_rule;
        parentContract=msg.sender;
        companyAddress=_companyAddress;
        //status=1;
    }

    function addProve(string memory _prove)public returns(bool success)
    {
        require(parentContract==msg.sender,"only owner can execute this function");
        prove=_prove;
        return true;
    }

    function checkPayment()public view returns(bool success)
    {
        if(initial_prize<token.balanceOf(address(this)))
        {
            return true;
        }
        return false;
    }

    function endContest(address[] memory ranking)public returns(bool success)
    {
        require(parentContract==msg.sender,"only owner can execute this function");
        require(proportion.length<=ranking.length,"獎金分配人數大於得獎人數");
        token.transfer(companyAddress,100);
        uint256 totalPrize=token.balanceOf(address(this));
        for(uint i=0 ;i<proportion.length;i++)
        {
            token.transfer(ranking[i],totalPrize/100*proportion[i]);
        }
        //status=4;
        return true;
    }

    function getProve()public view returns(string memory _prove)
    {
        return prove;
    }

    /*function getStatus()public view returns(uint256 _status)
    {
        return status;
    }*/

}


contract mainContest{ 

    IERC20 token = IERC20(address(0xd76c64574484bB9a39BB8fc88D4871729187Ecee));//代幣地址
    address public owner;
    
    constructor()public 
    {
        owner=msg.sender;
    }

    mapping (uint256 => contest) private contestById;


    function createContest(uint256 ID,uint256 _prize, uint256[] memory _proportion,uint256 _attendFee,string memory _rule)public returns(bool success)
    {
        contestById[ID]=new contest(msg.sender,_prize,_proportion,_attendFee,_rule,owner);
        return true;
    }

    function checkPayment(uint256 ID)public view returns(bool success)
    {
        return contestById[ID].checkPayment();
    } 

    /*function getStatus(uint256 ID)public view returns(uint256 status)//查詢繳費是否成功
    {
        return contestById[ID].getStatus();
    }
    */

    function getContestAddress(uint256 ID)public view returns(address contestAddress)//回傳每個比賽的address
    {
        require(address(contestById[ID])!=address(0),"無此ID比賽");
        return address(contestById[ID]);
    }

    function getCurrentPrize(uint256 ID)public view returns(uint256 prize)
    {
        require(address(contestById[ID])!=address(0),"無此ID比賽");
        return token.balanceOf(address(contestById[ID]));
    }

    function endContest(uint256 ID,address[] memory ranking)public returns(bool success)
    {
        require(msg.sender==owner,"only owner can execute this function");
        contestById[ID].endContest(ranking);
        return true;
    }
    
    function addProve(uint256 ID ,string memory prove)public returns (bool success)
    {
        require(msg.sender==owner,"only owner can execute this function");
        contestById[ID].addProve(prove);
        return true;
    }

    function getProve(uint256 ID)public view returns(string memory prove)
    {
        require(address(contestById[ID])!=address(0),"無此ID比賽");
        return contestById[ID].getProve();
    }

}