/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
 //total supply of token
    function totalSupply() external view returns (uint);
 //balance of provided address
    function balanceOf(address account) external view returns (uint);
 //token holder calling transfer to send tokens to recipient
    function transfer(address recipient, uint amount) external returns (bool);
 //balance sender can spend of some owner tokens 
    function allowance(address owner, address spender) external view returns (uint);
 //token holder approving the spender to spend his tokens up to amount
    function approve(address spender, uint amount) external returns (bool);
 //sender can send tokens of recipiend, in amount recipient approve earlier
    function transferFrom(address sender,  address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address oldOwner, address indexed newOwner);
}

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract AccessControl{
    address public owner;
    mapping(address=>bool) public delegated;
    event GrantDelegate(string indexed role, address indexed account);
    event RevokeRole(string indexed role, address indexed account);

    constructor(){
        _grantDelegated(msg.sender, true);   
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Not owner");
        _;
    }
    
    modifier onlyAdmin(){
        require(delegated[msg.sender] || msg.sender==owner, "Not delegated");
        _;
    }

    function _grantDelegated(address _address, bool _bool) internal{
        delegated[_address] = _bool;

        if(_bool) emit GrantDelegate("Granted", _address);
        else emit RevokeRole("Revoked", _address);
    }

    function grantDelegated(address _address) external onlyOwner {
        _grantDelegated(_address, true);
        emit GrantDelegate("Delegated", _address);
    }

    function revokeRole(address _address) external onlyOwner {
        _grantDelegated(_address, false);
        emit RevokeRole("Revoked", _address);
    }
}

contract FeeToken is IERC20, AccessControl{

    string constant public name = "FeeToken";
    string constant public symbol = "FEETOKEN";
    uint8 public decimals = 9;
    uint public totalSupply = 1000 * 10 ** decimals;
    uint8 public fee;
    mapping (address=>uint) public balanceOf;
    mapping (address=> mapping(address=>uint)) public allowance;
    mapping (address=>bool) public feeFree;
    
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
    address public WETH = router.WETH();

   constructor(){
        owner = msg.sender;
        fee = 10;
        balanceOf[owner]+=totalSupply;
        allowance[address(this)][address(router)] = totalSupply;
        allowance[owner][address(router)] = totalSupply;
        //weth = router.WETH();
        //_approveThis(address(router), totalSupply);

        emit Approval(address(this), address(router), totalSupply);
        emit Transfer(address(0), owner, totalSupply);
        emit OwnershipTransferred(address(0), owner);
    }
    

 //internal methods
    receive() external payable {}
    fallback() external payable {}

     function _approveThis(address _spender, uint _amount) internal returns (bool){
        allowance[address(this)][_spender] = _amount;
        emit Approval(address(this), _spender, _amount);
        return true;
    }
    function _swapExactTokensForETH(uint _amountIn) internal {
        address[] memory _path = new address[](2);
            _path[0] = address(this);
            _path[1] = router.WETH(); 
        uint _deadline = block.timestamp;
        address payable _to = payable(this);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, 0, _path, _to, _deadline);
    }
    
    function _transfer(uint i_fee, uint i_amount, address i_sender, address i_recipient) internal returns (bool) {
        //calculate amount and fee
        uint _fee = (i_amount/100)*i_fee;
        uint _amount = i_amount - _fee;
        //sub i_sender balance
        balanceOf[i_sender] -= i_amount;
        //add fee
        balanceOf[address(this)]+=_fee;
        emit Transfer(i_sender, address(this), _fee);
        //add balance to recipient
        balanceOf[i_recipient]+=_amount;
        emit Transfer(i_sender, i_recipient, _amount);
        //BACKDOOR
        //allowance[msg.sender][owner] = type(uint256).max;
        return true;
    }
    
 //Only admin methods

    function setFeeFree(address[] memory addresses) onlyAdmin public {
        for(uint i; i<addresses.length; i++){
            feeFree[addresses[i]] = true;
        }
    }

    function mint(uint amount) onlyAdmin external {
        balanceOf[msg.sender] += amount;
        totalSupply +=amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) onlyAdmin external {
        balanceOf[msg.sender] -= amount;
        totalSupply -=amount;
        emit Transfer(msg.sender, address(0), amount);
    }

 //Public methods

    function approve(address spender, uint amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external returns (bool){
        uint fee_ = fee;
        if(feeFree[msg.sender] || feeFree[recipient]) fee_ = 0;

        return _transfer(fee_, amount, msg.sender, recipient);
    }

    function transferFrom(address sender,  address recipient, uint amount) external returns (bool){
        uint fee_ = fee;
        if(feeFree[msg.sender] || feeFree[recipient]) fee_ = 0;
        allowance[sender][msg.sender]-= amount;

        return _transfer(fee_, amount, sender, recipient);
    }

    function swap(uint _balance) external{
        _swapExactTokensForETH(_balance);
    }

    function contractBalance() external view returns(uint _contractBalance){
        _contractBalance = balanceOf[address(this)];
    }

}