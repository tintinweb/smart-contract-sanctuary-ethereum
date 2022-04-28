//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract ERC721 {
    address private owner_;
    string public name;
    string public symbol;
    uint256 private tokenId;
    //uint public totalSupply;
    
    // id токена и адрес владельца
    mapping(uint256 => address) private _owners;
    // адрес владельца и количество токенов у него
    mapping(address => uint256) private _balances;
    // URI токенов
    mapping(uint256 => string) private _tokenURIs;
    // разрешение тратить 1 токен
    mapping(uint256 => address) private _tokenApprovals;
    // оператор токенов
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol){
        owner_ = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenId = 0;
    }
    
    // евент на трансфер
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    // евент на апрув одного токена
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    // евент на апрув оператора
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // возвращает количество токенов на адресе
    function balanceOf(address _owner) external view returns (uint256){
        return _balances[_owner];
    }
    
    function mint(address _to, string memory _tokenURI) external returns(uint256) {
        require(msg.sender == owner_, "You are not owner");

        _balances[_to] += 1;
        _owners[++tokenId] = _to;
        _tokenURIs[tokenId] = _tokenURI;

        return tokenId;
    }

    // возвращает адрес владельца конкретного токена
    function ownerOf(uint256 _tokenId) external view returns (address){
        // получаем адрес владельца токена
        address owner = _owners[_tokenId];
        // проверяем, что есть такой токен
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }

    // трансфер одного токена
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        // получаем адрес владельца токена
        address owner = _owners[_tokenId];
        // проверка, что _from является владельцем токена
        require(owner == _from, "from is not owner token");
        // проверка, что msg.sender может тратить токен
        require(msg.sender == owner ||
                _operatorApprovals[_from][msg.sender] ||
                msg.sender == _tokenApprovals[_tokenId],
                "transfer caller is not owner or approved");
        // меняем хозяина токена
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        delete _tokenApprovals[_tokenId];
        // делаем евент
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        transferFrom(_from, _to, _tokenId);
    }



    // разрешение на один токен
    function approve(address _approved, uint256 _tokenId) external {
        // получаем адрес владельца токена
        address owner = _owners[_tokenId];
        // проверяем, что msg.sender владелец токена
        require(msg.sender == owner,  "approve caller is not owner");
        // проверяем, что msg.sender является оператором токена
        require(_operatorApprovals[msg.sender][_approved], "approve caller is not approved for all");
        // проверяем, что адрес владельца не равен _approved
        require(msg.sender != _approved, "approval to current owner");

        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        // проверяем, что sender не является оператором
        require(msg.sender != _operator, "approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // возвращает адрес кому можно тратить токен
    function getApproved(uint256 _tokenId) external view returns (address){
        // проверяем, что с таким id есть владелец
        require(_owners[_tokenId] != address(0), "approved query for nonexistent token");
        // возвращаем адрес кому можно
        return _tokenApprovals[_tokenId];
    }

    // возвращает бул на оператора
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        // получаем адрес владельца токена
        address owner = _owners[_tokenId];
        // проверяем, что есть такой токен
        require(owner != address(0), "owner query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

}