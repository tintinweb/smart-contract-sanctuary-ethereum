// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC1155.sol";

contract DragonBallXYZ is ERC1155{
    string public name;
    string public symbol;
    uint256 public tokenCount;
    mapping(uint256=>string) private _tokenURIs;

    constructor(string memory _name,string memory _symbol){
        name=_name;
        symbol=_symbol;
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return _tokenURIs[tokenId];
    }
    function mint(uint256 amount,string memory _uri) public{
        require(msg.sender !=address(0),"Mint on Zero Address not valid");
        tokenCount+=1;
        _balances[tokenCount][msg.sender]+=amount;
        _tokenURIs[tokenCount]=_uri;
        emit TransferSingle(msg.sender, address(0), msg.sender, tokenCount, amount);
    }
    function supportsInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId==0xd9b67a26 || interfaceId==0x0e89341c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ERC1155{
    mapping(uint256=>mapping(address=>uint256)) internal _balances;
     mapping(address => mapping(address => bool)) private _operatorApprovals;
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    function balanceOf(address account, uint256 _id) public view returns (uint256){
        require(account!=address(0),"Address is zero");
        return _balances[_id][account];
    }
    function balanceOfBatch(address[] memory accounts, uint256[] memory _ids) 
    external view returns (uint256[] memory){
        require(accounts.length==_ids.length,"Length must be same");
        uint256[] memory batchBalances=new uint256[](accounts.length);

        for(uint256 i=0;i<accounts.length;i++){
            batchBalances[i]=balanceOf(accounts[i], _ids[i]);
        }
        return batchBalances;
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }
    function _transfer(address from,address to,uint256 id,uint256 amount) private{
        uint256 fromBalance=_balances[id][from];
        require(fromBalance>=amount,"Insuffciant Balance");
        _balances[id][from]=fromBalance-amount;
        _balances[id][to]+=amount;
    }
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata _data) external{
        require(msg.sender==from || isApprovedForAll(from,msg.sender),"Msg.sender is not the operator or owner");
        require(to!=address(0),"Address is zero");
        emit TransferSingle(msg.sender, from, to, id, amount);
        require(_checkOnEERC1155Received(), "Reciever not implement");
    }
    function _checkOnEERC1155Received() private pure returns(bool) {
        return true;
    }
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes calldata _data) 
    external{
        require(msg.sender==from || isApprovedForAll(from,msg.sender),"Msg.sender is not the operator or owner");
        require(to!=address(0),"Address is zero");
        require(ids.length==amounts.length,"Length must be same");

        for(uint256 i=0;i<ids.length;i++){
            uint256 id=ids[i];
            uint256 amount =amounts[i];

            _transfer(from, to, id, amount);
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        require(_checkOnEERC1155Received(), "Reciever not implement");
    }
    function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool){
        return interfaceId==0xd9b67a26;
    }
}