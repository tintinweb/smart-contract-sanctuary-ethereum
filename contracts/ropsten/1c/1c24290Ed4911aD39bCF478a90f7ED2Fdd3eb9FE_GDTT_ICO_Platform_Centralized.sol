/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    function mint(address toAddr,uint256 amount) external returns (bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

contract Context{
    constructor () {}
   function _msgsender() internal view returns (address) {
    return msg.sender;
  }
}

contract Ownable is Context{
    address private _Owner;

    event transferOwnerShip(address indexed _previousOwner , address indexed _newOwner);

    constructor(){
        address msgsender = _msgsender();
        _Owner = msgsender;
        emit transferOwnerShip(address(0),msgsender);
    }

    function checkOwner() public view returns(address){
        return _Owner;
    }

    modifier OnlyOwner(){
       require(_Owner == _msgsender(),"Only owner can change the Ownership");
       _; 
    }
   
    function transferOwnership(address _newOwner) public OnlyOwner {
      _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
      require(_newOwner != address(0),"Owner should not be 0 address");
      emit transferOwnerShip(_Owner,_newOwner);
      _Owner = _newOwner;
    }
}

contract GDTT is Context, IERC20, Ownable {
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    mapping(address => bool) public hasRole;

    address public Owner;

    string private _name;
    string private _symbol;
    uint private _decimal;
    uint private _totalSupply;

    constructor(){
        Owner = msg.sender;
       _name = "GDTT_Token";
       _symbol = "GDTT";
       _decimal = 18;
    //    _totalSupply = 700000000 * 10 ** 18;
    //    _balances[msg.sender] = _totalSupply;
       emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier _OnlyOwnerAndRole{
        require(Owner == msg.sender || hasRole[msg.sender],"only owner can update or caller doesn't have role!!!");
        _;
    }

    function name() external override view returns(string memory){
        return _name;
    }
    function symbol() external view override returns(string memory){
        return _symbol;
    }
    function decimals() external view override  returns(uint){
        return _decimal;
    }
    function balanceOf(address owner) external view override  returns(uint){
        return _balances[owner];
    }
    function totalSupply() external view override  returns(uint){
        return _totalSupply;
    }
    function approve(address spender , uint value) external override returns(bool){
        _approve(_msgsender(), spender , value);
        return true;
    }
    function allowance(address sender , address spender) external view override returns(uint){
          return _allowances[sender][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(_msgsender(), spender, _allowances[_msgsender()][spender]+(addedValue));
      return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
     _approve(_msgsender(), spender, _allowances[_msgsender()][spender] - subtractedValue);
     return true;
    }

    function transfer(address recepient , uint value) external override returns(bool){
        _transfer(msg.sender, recepient,value);
         return true;
    }

     function transferFrom(address sender ,address recepient, uint amount) external override returns(bool){
        _approve(sender, _msgsender(), _allowances[sender][_msgsender()] - amount);
        _transfer(sender,recepient,amount);
        return true;
    }

    function mint(address addressToMint,uint256 amount) public _OnlyOwnerAndRole  returns (bool) {
        _mint(addressToMint, amount);
        return true;
    }

    function burn(address addressToBurn,uint256 amount) public _OnlyOwnerAndRole returns (bool) {
        _burn(addressToBurn, amount);
        return true;
    }

    function _transfer(address sender,address recepient, uint value) internal  returns(bool success){
        require(_balances[sender] >= value,"Balance not enough");
        _balances[sender] = _balances[sender] - value;
        _balances[recepient] = _balances[recepient] + value;
        emit Transfer(_msgsender(), recepient , value);
        return true;
    }

    function _approve(address sender,address spender, uint amount) internal returns(bool success){
        require(sender != address(0),"Should not be 0 address");
        require(spender != address(0),"Should not be zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "GDTT: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
       require(account != address(0), "GDTT: burn from the zero address");
       _balances[account] = _balances[account] - amount;
       _totalSupply = _totalSupply - amount;
       emit Transfer(account, address(0), amount);
    }

    function addRole(address userAddr) public _OnlyOwnerAndRole{
        require(userAddr != address(0) , "Role cant't be 0 address!!!");
        hasRole[userAddr] = true;
    }
}

contract GDTT_ICO_Platform_Centralized{
    address public Owner;
    address public signerAddress;

    IERC20 public GDTT_Token;

    event ClaimedGDTT(address userAddr, uint amount);
    
    modifier OnlyOwner(){
        require(msg.sender != address(0) ,"Only Admin!!!");
        _;
    }

    modifier _OnlySigner(){
        require(msg.sender == signerAddress,"Only Signer!!!");
        _;
    }
    
    constructor(address _signerAddress, address _GDTTaddress) {
        assembly{
            sstore(signerAddress.slot,_signerAddress)
            sstore(Owner.slot, caller())
            sstore(GDTT_Token.slot, _GDTTaddress)
        }
    }

    function BuyGDTT(address account, uint amount)public _OnlySigner{
        require(account != address(0) ,"Zero address");
        GDTT_Token.mint(account, amount);
        emit ClaimedGDTT(account , amount);
    }

    function updateSignerAddress(address NewSignerAddress) public {
        require(NewSignerAddress != address(0) ,"Zero address");
        assembly{sstore(signerAddress.slot, NewSignerAddress)}
    }

    function withdraw(address tokenAddress,uint8 _type,address _toUser,uint amount)public OnlyOwner returns(bool status){
        require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
            require(address(this).balance >= amount, "Insufficient balance");
            require(payable(_toUser).send(amount), "Transaction failed");
            return true;
        }
        else if (_type == 2) {
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);
            IERC20(tokenAddress).transfer(_toUser,amount);
            return true;
        }
        else{
            revert("Invalid AssetType!!!");
        }
    }
}