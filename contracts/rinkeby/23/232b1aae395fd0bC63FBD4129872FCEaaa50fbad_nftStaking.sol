// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract nftStaking is ReentrancyGuard,Ownable{
    struct DepositRecord {
        address deposit;
        uint depositTime;
        uint projectId;
        bytes32 compress;
        bool extract;
    }
    struct Project {
        address[] nfts;
        uint[] counts;
        address token;
        uint amount;
        uint pledgeDuration;
        uint punish;
        bool status;

        uint startTime;
        uint endTime;
        uint supply;
    }

    uint depositId = 1;

    mapping(uint => uint) public projectSold;
    mapping(uint => bool) public projectExist;
    mapping(uint => Project) public findProject;
    mapping(uint => DepositRecord) public findDeposit;

    event Deposit(uint sid,address depositer,uint projectId,uint sold,uint[] types,address[] nfts,uint[] ids,uint[] amounts,bytes[] _datas);
    event Build(uint pid,address[] nfts,uint[] counts,address token,uint amount,uint pledgeDuration,uint punish,bool status,uint startTime,uint endTime,uint supply);
    event Extract(uint sid,address token,uint amount);

    constructor(address _owner) {
        transferOwnership(_owner);
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // 构建新项目
    function buildProject(
        uint _projectId,
        address[] memory _nfts,
        uint[] memory _counts,
        address _token,
        uint _amount,
        uint _pledgeDuration,
        uint _punish,
        uint _startTime,
        uint _endTime,
        uint _supply
    ) public onlyOwner {
        require(!projectExist[_projectId],"Project already exists");
        findProject[_projectId] = Project(_nfts,_counts,_token,_amount,_pledgeDuration,_punish,true,_startTime,_endTime,_supply);
        projectExist[_projectId] = true;
        emit Build(_projectId,_nfts,_counts,_token,_amount,_pledgeDuration,_punish,true,_startTime,_endTime,_supply);
    }
    
    function setProject(
        uint _id,
        address _token,
        uint _amount,
        uint _pledgeDuration,
        uint _punish,
        bool _status,
        uint _startTime,
        uint _endTime,
        uint _supply
    ) public onlyOwner {
        require(projectExist[_id],"Project not exists");
        findProject[_id] = Project(findProject[_id].nfts,findProject[_id].counts,_token,_amount,_pledgeDuration,_punish,_status,_startTime,_endTime,_supply);
        emit Build(_id,findProject[_id].nfts,findProject[_id].counts,_token,_amount,_pledgeDuration,_punish,_status,_startTime,_endTime,_supply);
    }

    // 统计是否满足条件
    function statisticalQuantity(
        uint _id,
        address[] memory _nfts,
        uint[] memory _amounts
    ) internal view returns (bool result) {
        result = true;
        uint[] memory temp = new uint[](findProject[_id].nfts.length);
        
        for(uint i = 0; i < findProject[_id].nfts.length; i++){
            temp[i] = 0;
            for(uint j = 0; j < _nfts.length; j++){
                if(_nfts[j] == findProject[_id].nfts[i]){
                    temp[i] += _amounts[j];
                }
            }
        }
        for(uint s = 0; s < temp.length; s++){
            if(temp[s] != findProject[_id].counts[s]){
                result = false;
            }
        }
    }

    function compressEncode(
        bytes32 _compress,
        uint _type,
        address _nft,
        uint _id,
        uint _amount,
        bytes memory _data
    ) internal pure returns (bytes32 compress) {
        bytes32 temp;
        temp = keccak256(abi.encodePacked(_type,_nft,_id,_amount,_data));
        compress = keccak256(abi.encodePacked(_compress,temp));
    }

    function depositCompress(
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas
    ) internal pure returns (bytes32 compress) {
        for(uint i = 0; i < _nfts.length; i++){
            // 压缩编码
            compress = compressEncode(compress,_types[i],_nfts[i],_ids[i],_amounts[i],_datas[i]);
        }
    }

    // 批量发送nft
    function _nftSend(
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas,
        address from,
        address to
    ) private {
        for(uint i = 0; i < _nfts.length; i++){
            if(_types[i] == 721){
                IERC721 nft721 = IERC721(_nfts[i]);
                nft721.transferFrom(from,to,_ids[i]);
            }else if(_types[i] == 1155){
                IERC1155 nft1155 = IERC1155(_nfts[i]);
                nft1155.safeTransferFrom(from,to,_ids[i],_amounts[i],_datas[i]);
            }else{
                revert("I won't support it");
            }
        }
    }

    // nft 质押存储
    function nftDeposit(
        uint _id,
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas
    ) public nonReentrant {
        require(_types.length == _nfts.length,"Illegal parameter");
        require(findProject[_id].status,"Current project closed");
        require(block.timestamp >= findProject[_id].startTime,"Project not started");
        require(block.timestamp <= findProject[_id].endTime,"Project closed");
        require(projectSold[_id] < findProject[_id].supply,"Sold out");
        require(statisticalQuantity(_id,_nfts,_amounts),"Conditions not met");

        // nft存入
        bytes32 compress = depositCompress(_types,_nfts,_ids,_amounts,_datas);
        _nftSend(_types,_nfts,_ids,_amounts,_datas,msg.sender,address(this));

        findDeposit[depositId] = DepositRecord(msg.sender,block.timestamp,_id,compress,false);
        projectSold[_id] += 1;
        emit Deposit(depositId,msg.sender,_id,projectSold[_id],_types,_nfts,_ids,_amounts,_datas);
        depositId += 1;
    }

    function _profitSend(
        address _token,
        uint _amount
    ) private returns (bool result) {
        if(_token == address(0)){
            Address.sendValue(payable(msg.sender),_amount);
            result = true;
        }else{
            IERC20 token = IERC20(_token);
            result = token.transfer(msg.sender,_amount);
        }
    }

    function externalToken(
        address _token,
        uint _amount
    ) public onlyOwner {
        _profitSend(_token,_amount);
    }

    function receiveEth() public payable { }

    function extractProfit(
        uint _sid,
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas
    ) public nonReentrant {
        uint pid = findDeposit[_sid].projectId;
        require(!findDeposit[_sid].extract,"Extracted");
        require(findDeposit[_sid].deposit == msg.sender,"Illegal extractor");
        require(findProject[pid].status,"Current project closed");

        bytes32 verify = depositCompress(_types,_nfts,_ids,_amounts,_datas);
        require(findDeposit[_sid].compress == verify,"Error in extracted NFT");

        // 返还nft
        _nftSend(_types,_nfts,_ids,_amounts,_datas,address(this),msg.sender);

        // 收益金额
        uint amount;
        // 质押天数
        uint pledgelen = (block.timestamp - findDeposit[_sid].depositTime) / 86400;
        // 提前提取
        if(findProject[pid].pledgeDuration <= pledgelen){
            amount = findProject[pid].amount;
        }else{
            amount = pledgelen * findProject[pid].punish / findProject[pid].pledgeDuration;
        }
        // 发放收益
        require(_profitSend(findProject[pid].token,amount),"Income distribution failed");
        
        findDeposit[_sid].extract = true;
        emit Extract(_sid,findProject[pid].token,amount);
    }

}