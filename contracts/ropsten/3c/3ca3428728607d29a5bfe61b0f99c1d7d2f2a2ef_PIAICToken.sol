/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity >=0.7.0 <0.9.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
contract PIAICToken is IERC20{
    mapping(address => uint256) private _balances;
//           owner             spender    allowance
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public owner;

    string  public name;
    string public symbol;
    uint8 public decimals;
    uint256 private Price;
    uint256 private Send_token;
    address private ETH_Sender;

    
    constructor() public {
        name = "PIAIC-BCC";
        symbol = "BCC";
        decimals=18;
        ETH_Sender=msg.sender;
        owner= msg.sender;
        _totalSupply=10 ether;
        _balances[owner]=_totalSupply;
        emit Transfer(address(this),owner,_totalSupply);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender=msg.sender;
        require (sender != address(0),"transfer from zero address");
        require (recipient !=address(0),"transfer from zero address");
        require (_balances[sender] > amount,"transfer account exceed balances");
        _balances[sender]=_balances[sender]-amount;
        _balances[recipient]=_balances[recipient]+amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function allowance(address  tokenOwner, address spender) public view virtual override returns (uint256){
        return _allowances[tokenOwner][spender];
        
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner=msg.sender;
        require (tokenOwner!=address(0), "approve from zero address");
        require (spender!=address(0), "approve from zero address");
        _allowances[tokenOwner][spender]=amount;
        emit Approval(tokenOwner, spender, amount);
        return true;
     }
     
    function transferFrom(address tokenOwner,address recipient,uint256 amount) public virtual override returns (bool) {
        
         address spender=msg.sender;
         uint256 _allowance = _allowances[tokenOwner][spender];
         require(_allowance >= amount, " transfer amount exceeds allowance");
         _allowance=_allowance-amount;
         _balances[tokenOwner]=_balances[tokenOwner]-amount;
         _balances[recipient]=_balances[recipient]+amount;
         emit Transfer(tokenOwner,recipient,amount);
         _allowances[tokenOwner][spender]=_allowance;
         emit Approval(tokenOwner,spender,amount);
         return true;
    }
 
    function mint(uint256 qty) public  returns(uint256){
        require(msg.sender== owner,"only admin can run this function");
        _totalSupply += qty;
        _balances[owner] +=qty;
        return _totalSupply;
    }
    fallback() external payable{
    }
    receive() external payable{
        
    }
    // if you adjust price=10000000000000000 wei then you are able to send 100 token against 1 ether.
    function adjustPrice(uint256 _Price) public returns(uint256){
        Price=_Price;
        require(msg.sender== owner,"only admin can run this function");
        return _Price;
    }
    
    function ether_Send () public payable {
        uint256 Recive_ETH = msg.value;
        payable(owner).transfer( Recive_ETH);
        _totalSupply += ( Recive_ETH);
        require( Recive_ETH > 0,"you need to send some ether");
        Send_token =  Recive_ETH/ Price;
        _balances[msg.sender] += Send_token;
        _totalSupply -=(Send_token);
    }
    
}