// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC1155.sol";

contract DragonBallZ1155 is ERC1155{
    string public name;
    string public symbol;
    uint256 public tokenCount;

    mapping(uint256 =>string) private _tokenURIs;

    event URI(string _value, uint256 indexed _id);
    
    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }


    function uri(uint256 tokenId) public view returns(string memory){
        return _tokenURIs[tokenId];

    }


    function mint(uint256 amount,string memory _uri)public{
        require(msg.sender != address(0),"Mint to zero address");
        tokenCount += 1;
        _balances[tokenCount][msg.sender] += amount;
        _tokenURIs[tokenCount] = _uri;
        emit TransferSingle(msg.sender, address(0), msg.sender, tokenCount, amount);
    }


    // function batchMint(uint[] amount,string[] memry _uri )

    

     function supportsInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }






}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract ERC1155 {


     event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;





    function balanceOf(address _account, uint256 _id) public view returns (uint256){
        require(_account != address(0),"Address is  zero");
        return _balances[_id][_account];
    }




    function balanceOfBatch(address[] memory _accounts, uint256[] memory _ids) 
        public view returns (uint256[] memory){
            require(_accounts.length == _ids.length,"Accounts and ids are not the  same length");
            uint256[] memory batchBalances = new uint256[](_accounts.length);
            for (uint256 i = 0; i < _accounts.length; i++) {
                batchBalances[i] = balanceOf(_accounts[i],_ids[i]);
             
            }
            return batchBalances;
    }


     // Enables or disables an operator to manage all of the msg.senders assets

    function setApprovalForAll(address _operator, bool _approved) external {
       _operatorApprovals[msg.sender][_operator] = _approved;
       emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    //  checks if an address is an operator for another address
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }


    function _transfer(address _from,address _to,uint256 _id,uint256 amount) private {
        uint256 fromBalance = _balances[_id][_from];
        require(fromBalance >= amount, "insufficient balance");
        _balances[_id][_from]=fromBalance-amount;
        _balances[_id][_to] += amount;
        
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 amount, bytes calldata _data) 
        external{
            require(msg.sender == _from || isApprovedForAll(_from,msg.sender),"Msg.sender is not a operator or owner");
            require(_to != address(0),"Address is zero");
            _transfer(_from, _to, _id, amount);
            emit TransferSingle(msg.sender,_from,_to,_id,amount);

            require(_checkOnERC1155Received(),"Receiver is not implemented");
    }



    function _checkOnERC1155Received() private pure returns (bool){
        // simplified version
        return true;
    }


    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory amounts, bytes calldata _data) 
        external{
           require(msg.sender == _from || isApprovedForAll(_from,msg.sender),"Msg.sender is not a operator or owner");
            require(_to != address(0),"Address is zero");
            require(_ids.length == amounts.length,"Ids and amount should be a same length");

            for(uint i = 0; i < _ids.length; i++){
                uint256 id = _ids[i];
                uint256 amount = amounts[i];

                _transfer(_from, _to, id, amount);
            }

        emit TransferBatch(msg.sender,_from,_to,_ids,amounts);

        require(_checkOnBatchERC1155Received(),"Receiver is not implemented");

    } 


    function _checkOnBatchERC1155Received() private pure returns (bool){
        // simplified version
        return true;
    }


    function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool){
        return interfaceId == 0xd9b67a26;
    }





}