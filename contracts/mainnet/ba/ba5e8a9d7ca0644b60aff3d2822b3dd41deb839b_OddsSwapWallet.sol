/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferERC20Token(address tokenAddress, uint _value) public virtual onlyOwner  {
        return IERC20Interface(tokenAddress).transfer(_owner, _value);
    }

    function transferBEP20Token(address tokenAddress, uint256 _value) public virtual onlyOwner  {
        return IBEP20Interface(tokenAddress).transfer(_owner, _value);
    }
}

interface IERC20Interface {
    function transfer(address _to, uint _value)external;
    function transferFrom(address _from, address _to, uint _value)external;
    function allowance(address _owner, address _spender) external returns (uint remaining);
}

interface IBEP20Interface {
    function transfer(address _to, uint256 _value)external;
    function transferFrom(address _from, address _to, uint256 _value)external;
}



interface IOddsSwapWallet {
    function getTokenAddress()external view returns (address);
    function getTokenPoolAddress()external view returns (address);
    function setTokenAddress(address _address) external ;
    function setTokenPoolAddress(address _address) external ;
    function getIfEth()external view returns (bool);
    function setIfEth(bool _ifEth)external;


    function withdraw(uint256 _orderId, address [] memory _users, uint256 [] memory _amounts ,string memory _remark) external returns(bool);
    function getWithDrawOrder(uint256 _orderId) external view returns (uint256 time,address [] memory users, uint256 [] memory amounts,string memory remark);
 
    event Withdraw(uint256 indexed orderId, address []  users, uint256 []  amounts ,string  remark) ;
    event SetTokenAddress(address ctoTokenAddress);
    event SetTokenPoolAddress(address sxcTokenAddress);
}


contract OddsSwapWallet is IOddsSwapWallet, Ownable{

    struct WithdrawItem{
        address user;
        uint256 amount;
    }

    struct WithdrawOrder{
        WithdrawItem []  items;
        uint256 time;
        string remark;
        bool succeed;
    }

    address private _tokenAddress;
    address private _tokenPoolAddress;
    bool private ifEth;

    function getIfEth()external view override returns (bool){
        return ifEth;
    }

    function setIfEth(bool _ifEth)external override onlyOwner {
       ifEth = _ifEth;
    }


    mapping (uint256 => WithdrawOrder) private withdrawOrders;

    function getTokenAddress()external override view returns (address){
        return _tokenAddress;
    }

    function getTokenPoolAddress()external override view returns (address){
        return _tokenPoolAddress;
    }

    function setTokenAddress(address _address) external override onlyOwner {
        _tokenAddress=_address;
        emit SetTokenAddress(_address);
    }

    function setTokenPoolAddress(address _address) external override onlyOwner {
        _tokenPoolAddress=_address;
        emit SetTokenPoolAddress(_address);
    }


    function withdraw(uint256 _orderId, address [] memory _users, uint256 [] memory _amounts ,string memory _remark) external override onlyOwner returns(bool){
        WithdrawOrder storage _order = withdrawOrders[_orderId];
         require(!_order.succeed,"OddsSwapWallet : Order already exists");
        require(_users.length == _amounts.length,"OddsSwapWallet : users.length must equal amounts.length");
        _order.time = block.timestamp;
        _order.remark = _remark;
        _order.succeed = true;
        WithdrawItem  []  storage  _items = _order.items;
        for(uint256 i = 0; i < _users.length; i++){
            address _user = _users[i];
            uint256 _amount = _amounts[i];
            _payToken(_user,_amount);
            WithdrawItem memory item = WithdrawItem({
                user:_user,
                amount:_amount
                });
            _items.push(item);
        }
        emit Withdraw(_orderId,_users,_amounts,_remark);
        return true;
    }

    function _payToken(address to,uint256 amount) internal{
        if(ifEth){
            require(IERC20Interface(_tokenAddress).allowance(msg.sender,address(this))>=amount,"WalletPayment: transfer amount exceeds allowance");
            IERC20Interface(_tokenAddress).transferFrom(_tokenPoolAddress,to,amount);
        }else{
            IBEP20Interface(_tokenAddress).transferFrom(_tokenPoolAddress,to,amount);
        }
    }


    function getWithDrawOrder(uint256 _orderId) external override view returns (uint256 time,address [] memory users, uint256 [] memory amounts,string memory remark){
        WithdrawOrder memory _order = withdrawOrders[_orderId];
      if(_order.succeed){
            WithdrawItem [] memory items = _order.items;
            users = new address[](items.length);
            amounts = new uint256 [](items.length);
            for(uint256 i =0;i<items.length;i++){
                WithdrawItem memory item = items[i];
                users[i]=item.user;
                amounts[i]=item.amount;
            }
            remark = _order.remark;
            time = _order.time;
        }
    }


fallback ()  external payable{}
receive () payable external {}

constructor(address tokenAddress_,address tokenPoolAddress_)  {
_tokenAddress= tokenAddress_;
_tokenPoolAddress = tokenPoolAddress_;
}
}