/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

pragma solidity ^0.5.0;
//referring https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md

contract ERC1155 /* is ERC165 */ {
    

    mapping (uint256 => mapping(address => uint256)) internal balances;//balance 包含index(滑雪板選擇)，address對應到該address有多少該index滑雪板


    mapping (address => mapping(address => bool)) internal operatorApproval;//address:owner，address:受委託人，對應到第二個address是不是受委託人
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);//transfer a kind of skiboard

    
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);//transfer multiple kins of skiboard
    event URI(string value, uint256 indexed id);
    
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);//approve other to trade skiboard

    /////////////////////////////////////////////////////////////
    //中間的code是我自己加的
    
    uint256 private currentSkiboardNum;
    address public init_owner;
    constructor()public 
    {
        currentSkiboardNum=0;
        init_owner=msg.sender;
    }
    mapping (uint256 => string) internal skiboardName;

    function checkAmount(uint256 id)private
    {
        if(balances[id][init_owner]<1000)
        {
            balances[id][init_owner]+=10000;
            emit TransferSingle(msg.sender,address(0), init_owner, id,10000);
        }
    }

    /*function mint(string memory name)public
    {
        currentSkiboardNum++;
        skiboardName[currentSkiboardNum]=name;
        checkAmount(currentSkiboardNum);
    }*/

    function getName(uint256 id)external view returns(string memory)
    {
        require(id<=currentSkiboardNum,"out of skiboard number");
        return skiboardName[id];
    }

    function ownerTransfer(address _to, uint256 _id, uint256 _value) external
    {
        require(_to != address(0x0), "_to must be non-zero.");
        //require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        balances[_id][init_owner] = balances[_id][init_owner]-_value;
        balances[_id][_to]   += _value;

       
        emit TransferSingle(msg.sender,init_owner, _to, _id, _value);
        
        checkAmount(_id);
    }
    ///////////////////////////////////////////////////////////// 
    //event URI(string _value, uint256 indexed _id);

    //transfer a kind of skiboard
    function TransferFrom(address _from, address _to, uint256 _id, uint256 _value) external
    {
        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        balances[_id][_from] = balances[_id][_from]-_value;
        balances[_id][_to]   += _value;

       
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        
        if(_from==init_owner)
        {
            checkAmount(_id);
        }
    }

    //transfer multiple kins of skiboard
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external
    {
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            balances[id][_from] = balances[id][_from]-value;
            balances[id][_to]   = value+balances[id][_to];
            if(_from==init_owner)
            {
                checkAmount(id);
            }
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        
    }

    //get the number of a kind of skiboard
    function balanceOf(address _owner, uint256 _id) external view returns (uint256)
    {
        return balances[_id][_owner];
    }

    //get the multiple balance
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);
        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }
        return balances_;
    }
    



    // give the approve to operator
    function setApprovalForAll(address _operator, bool _approved) external
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    //check if the operator get the owner approve
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return operatorApproval[_owner][_operator];
    }
    
    //mint ////////////////////////////////////////////////






     bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    

    // Creates a new token type and assings _initialSupply to minter
    function create(uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {

        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    // Batch mint tokens. Assign directly to _to[].
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external {

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = balances[_id][to]+quantity;

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

           
        }
    }

    function setURI(string calldata _uri, uint256 _id) external  {
        emit URI(_uri, _id);
    }
}