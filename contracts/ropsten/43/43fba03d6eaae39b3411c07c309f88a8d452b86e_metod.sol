/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity ^0.5.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC1155 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function batchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function allowance(address _owner, address _spender, uint256 _id) external view returns(uint256);
    function approve (address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
}


contract metod is IERC1155 {

    using SafeMath for uint256;

    //id => (owner=>balance)
    mapping (uint256 => mapping (address => uint256)) internal balances;
    //from => operator => id => allowances
    mapping (address => mapping (address => mapping (uint256 => uint256))) internal allowances;
    // owner => (operator => approved)
    mapping (address => mapping (address => bool)) internal operatorApproval;
    //id => creator
    mapping (uint256 => address) public creators;
    //id => uri
    mapping (uint256 => string) public mapUri;
    //uri => id
    mapping (string => uint256) public mapStringOfUri;    
    
    uint256 public nonce;

    modifier creatorOnly(uint256 _id) { 
        require (creators[_id] == msg.sender); 
        _; 
    }
    
    function create (uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;
        mapUri[_id] = _uri;
        mapStringOfUri[_uri] = _id;

        emit URI (_uri, _id);
        emit TransferSingle (msg.sender, address(0x0), msg.sender, _id, _initialSupply);
    }

    function mint (uint256 _id, address[] calldata _to, uint256[] calldata _amounts) external creatorOnly ( _id) {
        for (uint256 i=0; i<_to.length; i++){
            address to = _to[i];
            uint256 amounts = _amounts[i];

            balances[_id][to] = amounts.add(balances[_id][to]);
            emit TransferSingle (msg.sender, address(0x0), to, _id, amounts);
        }
    }   

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) public {

        require(_to != address(0x0), "_to must be non-zero address.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true || allowance(_from, _to, _id) >= _value, "Need operator approval for transfers.");


        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        if(allowance(_from, _to, _id) >= _value) {
            allowances[_from][msg.sender][_id] = allowances[_from][msg.sender][_id].sub(_value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);
    }

    function batchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external {

        require(_to != address(0x0), "address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if(allowance(_from, _to, id) >= value) {

                balances[id][_from] = balances[id][_from].sub(value);
                balances[id][_to]   = value.add(balances[id][_to]);

                allowances[_from][msg.sender][id] = allowances[_from][msg.sender][id].sub(value);

                emit TransferSingle(msg.sender, _from, _to, id, value);
            }
        }
    }

    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        require(_owner != address(0x0), "ERC1155: balance query for the zero address");
        return balances[_id][_owner];
     }

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public view returns (uint256[] memory) {

        require(_owners.length == _ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balanceOf(_owners[i], _ids[i]);
        }

            return balances_;

    }

    function approve (address _spender, uint256 _id, uint256 _currentValue, uint256 _value) public{

        require(allowances[msg.sender][_spender][_id] == _currentValue);
        allowances[msg.sender][_spender][_id] = _value;

        emit Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function allowance (address _owner, address _spender, uint256 _id) public view returns(uint256){
        return allowances[_owner][_spender][_id];
    }

    function setApprovalForAll(address _operator, bool _approved) public{
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll (msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool){

        return operatorApproval[_owner][_operator];
    }
}