// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import './erc1155.sol';

contract DragonBallz1155 is Erc1155{
    string public name;
    string public symbol;
    uint256 public tokenCount;

    mapping (uint256 => string) private tokenURI;

    constructor (string memory _name, string memory _symblol){
        name = _name;
        symbol = _symblol;
    }

    function uri(uint256 tokenId) public view returns(string memory){
        return tokenURI[tokenId];
    }

    function mint(uint256 amount, string memory _uri)public  {
        require(msg.sender != address(0),"Address is Zero");
        tokenCount += 1;
        _balanceof[tokenCount][msg.sender] += amount;
         tokenURI[tokenCount] = _uri; 
    }

    function supportInterface(bytes4 interfaceId)public pure override returns(bool){
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Erc1155{

    mapping (uint256 => mapping (address => uint)) internal _balanceof;
    mapping(address => mapping(address => bool))private _operatorApproval;

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    function balanceOf(address owner, uint256 id)public view returns(uint256){
        require(owner == address(0),"Address is empty");
        return _balanceof[id][owner];
    }

    function balanceOfBatch(address[] calldata owners, uint256[] memory ids)public view returns(uint256[] memory){
        require(owners.length == ids.length ,"account and lenght are not equal");
        uint256[] memory batchBalances = new uint256[] (owners.length);

        for(uint i=0;i<owners.length;i++){
            batchBalances[i] = balanceOf(owners[i],ids[i]);
        }
        return batchBalances;

    }

    function setApprovalForAll(address _operator, bool _approved)public {
        _operatorApproval[msg.sender][_operator] = _approved;
        emit    ApprovalForAll(msg.sender,_operator,_approved);    
    }

    function isApprovedForAll(address owner,address operator)public view returns(bool){
        return _operatorApproval[owner][operator];
    }

    function _transfer(address from, address to,uint256 id,uint256 amount )private{
        uint256 fromBalance = _balanceof[id][from];
        require(fromBalance >= amount,"No Sufficeient balance");
        _balanceof[id][from] == fromBalance -amount;
        _balanceof[id][to] += amount;
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(msg.sender == _from || isApprovedForAll(msg.sender,_from), "msg.sender is not a owner or an approver");
        require(_to != address(0),"To address is Zero ");
        _transfer(_from,_to,_id,_value);
        emit TransferSingle(msg.sender, _from,_to,_id,_value);

        require(_checkERC1155Receiver(),"REceiver is not implemented");
    }

    function _checkERC1155Receiver()public pure returns(bool){
        return true;
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external{
        require(msg.sender == _from || isApprovedForAll(msg.sender,_from), "msg.sender is not a owner or an approver");
        require(_to != address(0),"To address is Zero ");
        require(_ids.length == _values.length,"arrays lenght donot match");
        
        for(uint i=0; i<= _ids.length ;i++){
            _transfer(_from,_to,_ids[i],_values[i]);
        }
        emit TransferBatch(msg.sender, _from,_to,_ids,_values);
        require(_checkOnBatchERC1155Receiver(),"Reciver is not implemented");
    }

    function _checkOnBatchERC1155Receiver() private pure returns(bool){
        return true;
    }

    function supportInterface(bytes4 interfaceId)public pure virtual returns(bool){
        return interfaceId == 0xd9b67a26;
    }
}