// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";

contract BatchNFT is ERC1155  {
    string public _name;
    string public _symbol;
    uint256 public tokenCount;
    
    mapping(uint256 => string) private _tokenUris;

    constructor(string memory name, string memory symbol)  {
        _name = name;
        _symbol = symbol;
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return _tokenUris[tokenId];
    }
    function mint(uint256 amount, string memory _uri) public {
        require(msg.sender != address(0), "Not valid addresss");
        tokenCount += 1;
        _balances[tokenCount][msg.sender] += amount;
        _tokenUris[tokenCount] = _uri;

        emit TransferSingle(msg.sender, address(0), msg.sender, tokenCount, amount);
    }

    function _supportInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ERC1155 {
    mapping (uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _id, uint256[] _amounts);



    function balanceOf(address account, uint256 id) public view returns(uint256) {
        require(account != address(0), "Not valid address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns(uint256[] memory) {
        require(accounts.length == ids.length, "Not same lengths of address and ids");
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for(uint i = 0 ; i < accounts.length; i++){
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        
        return batchBalances;
    }

    function _transfer(address from,address to, uint256 id, uint256 amount) private {
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Insufficiant amount to transfer");
        _balances[id][from] -= amount;
        _balances[id][to] += amount;
    }

    function safeTransferFrom(address from,address to, uint256 id, uint256 amount) external { 
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "Msg.sender is not the operator or owner");
        require(to != address(0), "Address is 0");
        _transfer(from, to, id, amount);
        emit TransferSingle(msg.sender, from, to, id, amount);

        require(_checkOnERC721Recieved(), "Reciever is not implemented");
    }

    function _checkOnERC721Recieved() private pure returns(bool) {
        return true;
    }

    function safeBatchTransferFrom(address from,address to, uint256[] memory ids, uint256[] memory amounts) external { 
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "Msg.sender is not the operator or owner");
        require(to != address(0), "Address is 0");
        require(ids.length == amounts.length, "Id and amount length has to be same");

        for(uint i = 0 ; i < ids.length; i++){
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _transfer(from, to, id, amount);
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        require(_checkOnBatchERC721Recieved(), "Reciever is not implemented");
    }

    function _checkOnBatchERC721Recieved() private pure returns(bool) {
        return true;
    }

    function _supportInterface(bytes4 interfaceId) public pure virtual returns(bool) {
        return interfaceId == 0xd9b67a26;
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }
}