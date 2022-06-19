/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

//date:2022/6/3
pragma solidity ^0.5.0;

contract ERC20 {
    //uint256 private totalSupply;
    address public owner;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);//Transfer event , active it when the token is being transfer
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);//Approval event , active it when succesfully execute "approve" method 
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private balances;//建立一個address映射到uint256類別balances,顯示該address帳戶餘額
    mapping (address => mapping (address => uint256)) private allowed;//建立一個address映射到address,uint256類別allowed,顯示該帳戶允許哪個帳戶操作他多少金額
    string private _name;                  
    string private _symbol;
    uint8 private _decimal=0;//小數位為0
    uint256 private totalSupplyAmount=10000;//10000 tokens in total          

    constructor(string memory name_, string memory symbol_) public{//constructor
        _name = name_;
        _symbol = symbol_;
        owner=msg.sender;
        balances[owner]=totalSupplyAmount;//將總共的10000沒tokens都給initial owner
        emit Transfer(address(0), owner, 10000);
    }

    function name()public view returns(string memory)//the function which returns token name
    {
        return _name;
    } 

    function symbol()public view returns(string memory)//the function which returns tokens symbol 
    {
        return _symbol;
    }

    function decimals()public view returns(uint8)//the function which returns the decimal (0)
    {
        return _decimal;
    }

    function totalSupply()public view returns(uint256)//the function which returns the total amount of tokens(1000)
    {
        return totalSupplyAmount;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {//the function transfer token from owner account to other account , if success ,return true.
        require(balances[msg.sender] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        balances[msg.sender] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(msg.sender, _to, _value); //trigger Transfer event
        if(msg.sender==owner)
        {
            checkAmount();
        }
        return true;
    }

    function TransferToOwner(address _from ,uint256 _value)public returns (bool success)
    {
        require(balances[_from] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        balances[_from] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[owner] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(_from,owner, _value); //trigger Transfer event
        return true;
    }

    function ownerTransfer(address _to,uint256 _value)public returns(bool success){//new
        require(balances[owner] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        //require(msg.sender==owner);
        balances[owner] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(owner, _to, _value); //trigger Transfer event
        checkAmount();
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {//the function transfer token from the account which allowed user to operate to other account, if success,return true
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少也同時比allowance還要少
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        balances[_from] -= _value;//tokenes original owner原有的tokens數量-他要匯出的數量
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;//將allowance減去匯出的數量
        }
        emit Transfer(_from, _to, _value); //trigger Transfer event
        if(_to==owner)
        {
            checkAmount();
        }
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {//the function returns the balances of user
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {//owner approve the other having right to operate _value tokens
        allowed[msg.sender][_spender] = _value;//allowance set up to _value
        emit Approval(msg.sender, _spender, _value); //trigger approval event
        return true;
    }

    function approveContract(address _approver,uint256 _value)public returns(bool success){
        allowed[_approver][msg.sender] = _value;//allowance set up to _value
        emit Approval(_approver,msg.sender,_value); //trigger approval event
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {//input the owner and spender ,and the function will return the allowance
        return allowed[_owner][_spender];
    }

    function checkAmount() private returns(bool)
    {
        if(balances[owner]<=1000)//確保owner可以有無限的token
        {
            balances[owner]+=10000;
            totalSupplyAmount=totalSupplyAmount+10000;
            emit Transfer(address(0), owner, 10000);
        }
    } 
}


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
   // mapping (uint256 => string) internal skiboardName;

    function checkAmount(uint256 id)private
    {
        if(balances[id][init_owner]<1000)
        {
            balances[id][init_owner]+=10000;
            emit TransferSingle(msg.sender,address(0), init_owner, id,10000);
        }
    }

    function ownerTransfer(address _to, uint256 _id, uint256 _value) external
    {
        require(_to != address(0x0), "_to must be non-zero.");
        //require(msg.sender==init_owner);
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
    function TransferToOwner(address _from, uint256 _id, uint256 _value) external
    {
        address _to=init_owner;
        require(_to != address(0x0), "_to must be non-zero.");
        //require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

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
    
    function setApprovalForAllContract(address _approver, bool _approved) external
    {
        operatorApproval[_approver][msg.sender] = _approved;
        emit ApprovalForAll(_approver,msg.sender, _approved);
    }
    //mint ////////////////////////////////////////////////






     bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    

    // Creates a new token type and assings _initialSupply to minter
    function create(uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {
        require(msg.sender==init_owner);
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    // Batch mint tokens. Assign directly to _to[].
    /*function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external {
        require(msg.sender==init_owner);
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
    */
    function setURI(string calldata _uri, uint256 _id) external  {
        emit URI(_uri, _id);
    }
    
}

contract GameStatus{
      
    uint256 private price;
    uint256 private entryPrice;
    address private init_owner;
    ERC20 erc20;
    ERC1155 erc1155;
    constructor()public{
        erc20=new ERC20("skiGame","Coin");
        erc1155=new ERC1155();
        //ERC20.constructor("skiGameToken","Coin");
        entryPrice=1;
        init_owner=msg.sender;
        
    }
    
    function buyToken(address sender)public payable
    {
        require( msg.value == 0.01 ether, "0.01 ETH");
        erc20.ownerTransfer(sender,10);
    }
   function getToken(address sender,uint256 score)public
    {
        uint256 prize=score/200;//1000分換一代幣
        erc20.ownerTransfer(sender,prize);
    }
    function startGame(address sender,uint256 skiboardId) public payable returns(bool success)//資產滑雪板，nft人物，滑雪板
    {
        erc20.TransferToOwner(sender,1);//燒掉滑雪板，確認他有nft
        if(skiboardId!=0)
        {
            erc1155.TransferToOwner(sender,skiboardId,1);//burn the skiboard
        }
        //TODO
    }
    function buySkiBoard(address sender,uint256 skiboardId)public payable returns(bool success)
    {
        require( msg.value == 0.01 ether, "0.01 ETH");
        erc1155.ownerTransfer(sender,skiboardId,100);
    }
    function erc20name()public view returns(string memory)
    {
        return erc20.name();
    }
    function erc20symbol()public view returns(string memory)//the function which returns tokens symbol 
    {
        return erc20.symbol();
    }
    function erc20decimals()public view returns(uint8)//the function which returns the decimal (0)
    {
        return erc20.decimals();
    }
    function erc20totalSupply()public view returns(uint256)
    {
        return erc20.totalSupply();   
    }
    function erc20transfer(address _to, uint256 _value) public returns (bool success)
    {
        return erc20.transfer(_to,_value);
    }
    /*function erc20ownerTransfer(address _to,uint256 _value)private returns(bool success)
    {
        return erc20.ownerTransfer(_to,_value);   
    }*/
    /*function erc20transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        return erc20.transferFrom(_from,_to,_value);
    }*/
    function erc20balanceOf(address _owner) public view returns (uint256 balance) 
    {
        return erc20.balanceOf(_owner);
    }
    function erc20approve(address _spender, uint256 _value) public returns (bool success) 
    {
        return erc20.approve(_spender,_value);
    }
    //function erc20allowance(address _owner, address _spender) public view returns (uint256 remaining);
    //ERC20 end 
    //ERC1155 start

    
    function erc1155TransferFrom(address _from, address _to, uint256 _id, uint256 _value) external
    {
        erc1155.TransferFrom(_from,_to,_id,_value);
    }
    /*function erc1155safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external
    {
        bytes temp=0x21;
        erc1155.safeBatchTransferFrom(_from,_to,_ids, _values,temp);
    }*/
    function erc1155balanceOf(address _owner, uint256 _id) external view returns (uint256)
    {
        return erc1155.balanceOf(_owner,_id);
    }
    function erc1155balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory)
    {
        return erc1155.balanceOfBatch(_owners,_ids);
    }
    function erc1155create(uint256 _initialSupply, string calldata _uri) external returns(uint256 _id)
    {
        return erc1155.create(_initialSupply,_uri);
    }
    /*function erc1155mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external
    {
        erc1155.mint(_id,_to,_quantities);
    }*/
    function erc1155setURI(string calldata _uri, uint256 _id) external
    {
        erc1155.setURI(_uri,_id);
    }

}