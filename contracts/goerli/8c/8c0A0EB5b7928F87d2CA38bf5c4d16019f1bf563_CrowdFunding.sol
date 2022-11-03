/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity ^0.4.0;

contract CrowdFunding{

    //向众筹项目投资的投资人
    struct Funder{
        address FunderAddress;  //投资人付款地址
        uint Fund;              //投资人的投资金额
        uint FunderSequence;    //投资人排位
    }

    //众筹项目的资金发起人
    struct Needer{
        address NeederAddress;  //发起人收款地址
        uint NeederSequence;    //发起人排位
        uint TotalAmount;       //发起人众筹目标总金额
        uint NowAmount;         //发起人目前已经众筹的金额
        uint FunderAccount;     //投资人总数
        address[] FunderList;   //投资人列表
        mapping(uint => Funder) Map;    //将不同的众筹项目投资人按数字顺序排列，方便回溯
    }

    uint public NeederAmount;   //众筹项目发起人总数
    mapping(uint => Needer) NeederMap;  //将不同的众筹项目发起人按数字顺序排列，方便回溯

    //众筹项目发起人函数
    function NewNeeder(address _NeederAddress, uint _TotalAmount) public returns(uint){
        NeederAmount++; //众筹项目发起人计数
        Needer storage _Needer = NeederMap[NeederAmount];
        NeederMap[NeederAmount] = Needer(_NeederAddress, NeederAmount, _TotalAmount, 0, 0, _Needer.FunderList);
        return NeederAmount;
    }

    //众筹项目投资人函数
    function NewFunder(address _Funderaddress, uint _NeederNumber) public payable{
        Needer storage _Needer = NeederMap[_NeederNumber];
        uint FunderExistflag;
        if((_Funderaddress != NeederMap[_NeederNumber].NeederAddress) && (msg.value <= (NeederMap[_NeederNumber].TotalAmount - NeederMap[_NeederNumber].NowAmount))){
            for(uint i = 0; i < _Needer.FunderList.length; i++){
                if(_Funderaddress == _Needer.FunderList[i]){    //检查投资人是否为重复投资
                    FunderExistflag = 1; //设定投资人重复标识符
                    break;
                }
            }
            if(FunderExistflag != 1){
                _Needer.FunderList.push(_Funderaddress);
                _Needer.FunderAccount++;
            }
            _Needer.NowAmount += msg.value;
            _Needer.Map[_Needer.FunderAccount] = Funder(_Funderaddress, msg.value, _Needer.FunderAccount);
            FunderExistflag = 0;    //删除投资人重复投资标识符
        }
    }

    //合约账户资金向发起人账户转账函数
    function CrowdFundingCompleted(uint _NeederNumber) public payable{
        Needer storage _Needer = NeederMap[_NeederNumber];
        if(_Needer.NowAmount >= _Needer.TotalAmount){
            _Needer.NeederAddress.transfer(_Needer.NowAmount);
        }
    }

    //显示众筹项目的实际募集情况
    function DisplayCrowdFundingStatus(uint _NeederNumber) public view returns(address, uint, uint, uint, uint, string){
        Needer storage _Needer = NeederMap[_NeederNumber];
        string memory CrowdFundingStatus;
        if(_Needer.NowAmount >= _Needer.TotalAmount){
            CrowdFundingStatus = 'Complete';
        }
        else{
            CrowdFundingStatus = 'Not Complete';
        }
        return (NeederMap[_NeederNumber].NeederAddress, NeederMap[_NeederNumber].NeederSequence, NeederMap[_NeederNumber].TotalAmount, NeederMap[_NeederNumber].NowAmount, NeederMap[_NeederNumber].FunderAccount, CrowdFundingStatus);
    }
    
    //显示单个投资人关于某众筹项目的投资信息
    function DisplayFunderInformation(uint _FunderNumber, uint _NeederNumber) public view returns(address, uint, uint){
        Needer storage _Needer = NeederMap[_NeederNumber]; 
        return (_Needer.Map[_FunderNumber].FunderAddress,_Needer.Map[_FunderNumber].Fund, _Needer.Map[_FunderNumber].FunderSequence);
    }
    
    //显示众筹项目的投资人总列表
    function DisplayCrowdFundingFunderList(uint _NeederNumber) public view returns(address[]){
        return NeederMap[_NeederNumber].FunderList;
    }
    
}