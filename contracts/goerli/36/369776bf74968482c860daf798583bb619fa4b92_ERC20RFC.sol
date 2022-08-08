/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
interface IERC20 {
    //Optional
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimal() external view returns (uint8);

    //MustExist
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function transfer(address _to, uint256 value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    // //Events
    event Transfer(address indexed _from, address indexed _to, uint256);
    event Approval(address indexed _owner, address indexed _spender, uint256);
}


pragma solidity 0.8.15;
contract ERC20RFC is IERC20 {

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private owner;
    uint256 private _totalSupply;

    constructor(uint256 initialMint) {
        owner = msg.sender;
        _balance[msg.sender] = initialMint * 10 ** 18;
        _totalSupply = initialMint;
    }
    
    function name() external pure returns (string memory) {
        return "Russa Fucking Coine";
    }

    function symbol() external pure returns (string memory) {
        return "RFC";
    }

    function decimal() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;        
    }
    
    function balanceOf(address addr) external view returns (uint256) {
        return _balance[addr];
    }

    function transfer(address _to, uint256 value) external returns (bool) {
        //require(_balance[msg.sender] >= value, "ERC20: transfer amount exceeds balance");
        _balance[msg.sender] -= value;
        _balance[_to] += value;
        emit Transfer(msg.sender, _to, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 value) external returns (bool) {
        //require(_allowances[_from][msg.sender] >= value, "ERC20: transfer amount exceeds balance");
        //require(_balance[_from] >= value, "ERC20: transfer amount exceeds balance");
        _balance[_from] -= value;
        _allowances[_from][msg.sender] -= value;
        _balance[_to] += value;
        emit Transfer(_from, _to, value);
        return true;
    }

    function approve(address _spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][_spender] = value;
        emit Approval(msg.sender, _spender, value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowances[_owner][_spender];
    }
}