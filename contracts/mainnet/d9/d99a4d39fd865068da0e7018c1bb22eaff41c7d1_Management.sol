/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0 ;

interface IProxy {
    function changeAdmin(address newAdmin) external returns(bool);
    function upgrad(address newLogic) external returns(bool);
}

interface IManagement {
    function addNodePropose(address _addr) external;
    function deleteNodePropose(address _addr) external;
    function updateProxyAdminPropose(address _targetAddr, address _addr) external;
    function updateProxyUpgradPropose(address _targetAddr, address _addr) external;
    function excContractPropose(address _targetAddr, bytes memory _data) external;
    function vote(uint256 _proposalId) external;

}

contract Management is IManagement{
    using SafeMath for uint256;
    uint256 public  proposalCount;                           
    mapping(uint256 => ProposalMsg) public proposalMsg;
    uint256 public nodeNum;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    bool private reentrancyLock = false;

    event Propose(address indexed proposer, uint256 proposalId, string label);
    event Vote(address indexed voter, uint256 proposalId);
    
    struct ProposalMsg {
        address[] proposers;
        bool proposalSta; 
        address targetAddr;   
        address addr;  
        bytes data;
		uint256 expire; 
        uint256 typeIndex;  
        string  label;  
        mapping(address => bool) voterSta;  
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address[] memory _nodeAddrs) {
        uint256 len = _nodeAddrs.length;
        require( len> 4,"The number of node addresses cannot be less than 5");
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            addNodeAddr(_nodeAddrs[i]);
        }
    }
 
    fallback() external{

    }
   
    function addNodePropose(address _addr) override external{
        require(!nodeAddrSta[_addr], "This node is already a node address");
        bytes memory data = new bytes(0x00);
        _propose(address(0), _addr, data, 2, "addNode");
    }
  
    function deleteNodePropose(address _addr) override external{
        require(nodeAddrSta[_addr], "This node is not a node address");
        require(nodeNum > 5, "The number of node addresses cannot be less than 5");
        _propose(address(0), _addr, new bytes(0x00), 3, "deleteNode");
    }
     
    function updateProxyAdminPropose(address _targetAddr, address _addr) override external{
        _propose(_targetAddr, _addr, new bytes(0x00), 4, "updateProxyAdmin");
    }
      
    function updateProxyUpgradPropose(address _targetAddr, address _addr) override external{
        _propose(_targetAddr, _addr, new bytes(0x00), 5, "updateProxyUpgrad");
    }
   
    function excContractPropose(address _targetAddr, bytes memory _data) override external{
        require(bytesToUint(_data) != 2401778032 && bytesToUint(_data) != 822583150, "Calls to methods of proxy contracts are not allowed");
        _propose(_targetAddr, address(0), _data, 6, "excContract");
    }

    function _propose(
        address _targetAddr, 
        address _addr, 
        bytes memory _data, 
        uint256 _typeIndex, 
        string memory _label
    ) internal{
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        uint256 _time = block.timestamp;
        uint256 _proposalId = ++proposalCount;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        _proposalMsg.proposers.push(_sender);
        _proposalMsg.targetAddr = _targetAddr;
        _proposalMsg.addr = _addr;
        _proposalMsg.data = _data;
        _proposalMsg.expire = _time.add(86400);
        _proposalMsg.typeIndex = _typeIndex;
        _proposalMsg.label = _label;
        _proposalMsg.voterSta[_sender] = true;
        emit Propose(_sender, _proposalId, _label);
    }
    
    function vote(uint256 _proposalId) override external nonReentrant(){
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        uint256 _time = block.timestamp;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        require(_proposalMsg.expire > _time, "The vote on the proposal has expired");
        require(!_proposalMsg.voterSta[_sender], "The proposer has already voted");
        _proposalMsg.proposers.push(_sender);
        _proposalMsg.voterSta[_sender] = true;
        uint256 length = _proposalMsg.proposers.length;
        if(length> nodeNum/2 && !_proposalMsg.proposalSta){
            require(_actuator(_proposalId), "The method call failed");
            _proposalMsg.proposalSta = true;
        }
        emit Vote(_sender, _proposalId);
    }
    
    function _actuator(uint256 _proposalId) internal returns(bool){
        bool result = false;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        uint256 _typeIndex = _proposalMsg.typeIndex;
        if(_typeIndex == 2){
            addNodeAddr(_proposalMsg.addr);
            result = true;
        }else if(_typeIndex == 3){
            deleteNodeAddr(_proposalMsg.addr);
            result = true;
        }else if(_typeIndex == 4){
            IProxy proxy = IProxy(_proposalMsg.targetAddr);
            result = proxy.changeAdmin(_proposalMsg.addr);
        }else if(_typeIndex == 5){
            IProxy proxy = IProxy(_proposalMsg.targetAddr);
            result = proxy.upgrad(_proposalMsg.addr);
        }else if(_typeIndex == 6){
            bytes memory _data = _proposalMsg.data;
            (result, ) = _proposalMsg.targetAddr.call(_data);
        }
        return result;
    }

    function addNodeAddr(address _nodeAddr) internal{
        require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
        nodeAddrSta[_nodeAddr] = true;
        uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
        if (_nodeAddrIndex == 0){
            _nodeAddrIndex = ++nodeNum;
            nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
            nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
        }
    }

    function deleteNodeAddr(address _nodeAddr) internal{
        require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
        nodeAddrSta[_nodeAddr] = false;
        uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
        if (_nodeAddrIndex > 0){
            uint256 _nodeNum = nodeNum;
            address _lastNodeAddr = nodeIndexAddr[_nodeNum];
            nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
            nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
            nodeAddrIndex[_nodeAddr] = 0;
            nodeIndexAddr[_nodeNum] = address(0x0);
            nodeNum--;
        }
        require(nodeNum > 4, "The number of node addresses cannot be less than 5");
    }

    function bytesToUint(bytes memory _data) internal pure returns (uint256){
        require(_data.length >= 4, "Insufficient byte length");
        uint256 number;
        for(uint i= 0; i<4; i++){
            number = number + uint8(_data[i])*(2**(8*(4-(i+1))));
        }
        return  number;
    }

    function queryVotes(
        uint256 _proposalId
    ) 
        external 
        view 
        returns(
            address[] memory, 
            bool, 
            address, 
            address,
            bytes memory, 
            uint256, 
            string memory)
    {
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        uint256 len = _proposalMsg.proposers.length;
        address[] memory proposers = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            proposers[i] = _proposalMsg.proposers[i];
        }
        return (proposers, _proposalMsg.proposalSta, _proposalMsg.targetAddr, _proposalMsg.addr, _proposalMsg.data, 
               _proposalMsg.expire, _proposalMsg.label);
    }

    function queryNodes()  external view returns(address[] memory){
        address[] memory nodes = new address[](nodeNum);
        for (uint256 i = 1; i <= nodeNum; i++) {
            nodes[i-1] = nodeIndexAddr[i];
        }
        return nodes;
    }

}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}