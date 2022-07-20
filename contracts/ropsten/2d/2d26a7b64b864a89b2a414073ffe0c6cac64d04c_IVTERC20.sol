/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c =  a + b;
        require( c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b < a);
        uint256 c = a-b;
        return c;
    }

}
interface IVTERC20Interface {
    function name() external view returns( string memory);
    function tokenSymbol() external view returns(string memory);
    function decimal() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address who) external view returns(uint256);
    function transfer(address to, uint256 value) external payable returns(bool); 
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 */
contract IVTERC20 is IVTERC20Interface {

    using SafeMath for uint256;

    string private _name = "IVT";
    string private _tokenSymbol = "IVT Token";
    uint32 private _decimal =18;
    uint256 private _totalSupply = 1000000000000;
    mapping (address=>uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowed;
    constructor() {
        // _name = p_name;
        // _tokenSymbol = p_tokenSymbol;
        // _decimal = p_decimal;
        _balances[msg.sender] = _totalSupply;
    }
    function name() public override view returns(string memory) {
        return _name;
    }
    function tokenSymbol() public override view returns (string memory) {
        return _tokenSymbol;
    }
    function decimal() public override view returns (uint256) {
        return _decimal;
    }
    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address owner) public override view returns(uint256) {
        return _balances[owner];
    }
    function transfer(address to, uint256 _value) public override payable returns(bool) {
        require(_value <= _balances[msg.sender],"Insuffient Balance");
        require(to != address(0),"To Address not Valid");
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[to] = _balances[to].add(_value);
        emit Transfer(msg.sender,to,_value);
        return true;
    }
    function transferFrom(address from, address to, uint256 _value) public override returns(bool) {
        require(_value <= _balances[from]);
        require(to != address(0));
        _balances[from].sub(_value);
        _balances[to].add(_value);
        emit Transfer(msg.sender,to,_value);
        return true;
    }
    function approve(address spender, uint256 _value) public override returns(bool) {
        require(spender != address(0));
        
        _allowed[msg.sender][spender] = _value;
        emit Approve(msg.sender, spender, _value);
        return true;

    }
    function allowance(address owner, address spender) public override view returns(uint256){
        return _allowed[owner][spender];
    }



}