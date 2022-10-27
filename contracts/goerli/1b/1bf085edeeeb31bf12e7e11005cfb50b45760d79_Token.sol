/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT

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
contract Token is IERC20{
    uint256 private TOTAL_SUPPLY;
    string  public name;
    string public symbol;
    uint8 public decimals;
    address public founder;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    constructor(){
        name = "TESTUSD";
        symbol = "USDT";
        decimals = 6;
        founder = msg.sender;
        TOTAL_SUPPLY = 1000000 * 10 ** decimals;
        balances[founder] = TOTAL_SUPPLY;
    }
    function totalSupply() public view override returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }
    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        require (msg.sender != address(0),"transfer from zero address");
        require (_recipient != address(0),"transfer from zero address");
        require (balances[msg.sender] > _amount,"transfer account exceed balances");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function allowance(address _tokenOwner, address _spender) public view virtual override returns (uint256){
        return allowances[_tokenOwner][_spender];
    }
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        require (msg.sender!=address(0), "approve from zero address");
        require (_spender!=address(0), "approve from zero address");
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
     }

    function transferFrom(address _tokenOwner,address _recipient,uint256 _amount) public virtual override returns (bool) {
         require(allowances[_tokenOwner][msg.sender] >= _amount, " transfer ERC20 exceeds allowance");
         allowances[_tokenOwner][msg.sender] = allowances[_tokenOwner][msg.sender] - _amount;
         balances[_tokenOwner] -= _amount;
         balances[_recipient] += _amount;
         emit Transfer(_tokenOwner, _recipient, _amount);
         return true;
    }
}