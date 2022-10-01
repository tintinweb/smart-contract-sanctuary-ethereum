// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./NewOwnable.sol";


contract SubscribeRelationship is Ownable{

    struct SubscriptionRelationshipTable {uint artistId; uint closingDate;}
    struct PaymentTypeTable {uint payFee; uint minimumTime;}

    mapping (address => SubscriptionRelationshipTable[]) public ownerToSubcritption;
    mapping (uint => PaymentTypeTable) public payTypeMap;

    event NewSubscriptionRelationship(uint artistId, uint subscribeTime);

    function getDate() public view returns(uint){
        return(block.timestamp);
    }

    function setSubscirbeFee(uint _payType, uint _fee, uint _minimumTime) external onlyOwner returns(bool){
        payTypeMap[_payType].payFee = _fee;
        payTypeMap[_payType].minimumTime = _minimumTime;
        return true;
    }

    function getSubcribeFeeType(uint payType) public view returns(PaymentTypeTable memory) {
        return payTypeMap[payType];
    }

    // 查询订阅者单个艺术家订阅天数view 
    function querySingleArtist(address owner,uint queryArtistId) public view returns(uint) {
        if (ownerToSubcritption[owner].length < 1) {
            return 0;
        }
        for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
            if (ownerToSubcritption[owner][i].artistId == queryArtistId) {
                if (ownerToSubcritption[owner][i].closingDate > block.timestamp) 
                {return ownerToSubcritption[owner][i].closingDate - block.timestamp;}
                else {
                    return 0;
                }                
            }
        }
        return 0;
    }

    // 查询订阅者下面多个艺术家订阅天数关系
    function queryMultipleArtist(address owner) public view returns(uint[] memory,uint[] memory) {
        uint[] memory artistIdList = new uint[](ownerToSubcritption[owner].length);
        uint[] memory remainList  = new uint[](ownerToSubcritption[owner].length);
        if (ownerToSubcritption[owner].length < 1) {
            return(artistIdList, remainList);
        } else {
            for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
                if (ownerToSubcritption[owner][i].closingDate > block.timestamp){
                    artistIdList[i] = ownerToSubcritption[owner][i].artistId;
                    remainList[i] = ownerToSubcritption[owner][i].closingDate - block.timestamp;
                } else {
                    artistIdList[i] = ownerToSubcritption[owner][i].artistId;
                    remainList[i] = 0;
                } 
            }
            return(artistIdList, remainList);
        }
    }


    address erc20 = 0x7b49d3A15E248BcDB717614F2b8f5FA0510EAe29;
    // address erc20 = 0x17B32b1d06dFFD94BfC86214dA7Fb5DeEF988308;
    // constructor(address _erc20) public{
    //     erc20 = _erc20;
    // }
    function transferUSDT(address _form, uint256 _amount) public returns(bool){
      bytes32 a =  keccak256("transferFrom(address,address,uint256)");
      bytes4 methodId = bytes4(a);
      bytes memory b =  abi.encodeWithSelector(methodId, _form, 0x4491B99C9349eEAD7073a4795c66396404b7F6B0, _amount);
      (bool result,) = erc20.call(b);
      return result;
    }

    // 订阅一个artist  payable
    function subscribeArtist(address owner, uint payType, uint subArtistId, uint subscribeTime) public returns(address, uint) {
        // 订阅者首次订阅
        uint payAmount = payTypeMap[payType].payFee;
        require(subscribeTime == payTypeMap[payType].minimumTime);
        bool transferResult = transferUSDT(msg.sender, payAmount);
        // bool transferResult = true;

        if (transferResult) {
            // 转账成功了，开始执行订阅逻辑
            // 用户的映射关系第一次建立
            if (ownerToSubcritption[owner].length < 1) {
            ownerToSubcritption[owner].push(SubscriptionRelationshipTable(subArtistId, block.timestamp + subscribeTime)); 
            emit NewSubscriptionRelationship(subArtistId, subscribeTime);
            return (owner, subscribeTime);
            }

            // 订阅者续约的情况
            for (uint i = 0; i < ownerToSubcritption[owner].length; i++) {
                if (ownerToSubcritption[owner][i].artistId == subArtistId) {
                    // 防止用户第二次订阅超时很久的情况
                    if (ownerToSubcritption[owner][i].closingDate >= block.timestamp) {
                        ownerToSubcritption[owner][i].closingDate += subscribeTime;     
                    } else {
                        ownerToSubcritption[owner][i].closingDate = block.timestamp + subscribeTime;
                    }   
                    emit NewSubscriptionRelationship(subArtistId, subscribeTime);
                    return (owner, ownerToSubcritption[owner][i].closingDate - block.timestamp);         
                }
            }

            // 订阅者之前有订阅其他艺人，第一次订阅这个艺人
            ownerToSubcritption[owner].push(SubscriptionRelationshipTable(subArtistId, block.timestamp + subscribeTime));
            emit NewSubscriptionRelationship(subArtistId, subscribeTime);
            return (owner, subscribeTime);
        }
        return (owner, 0);
    }
}