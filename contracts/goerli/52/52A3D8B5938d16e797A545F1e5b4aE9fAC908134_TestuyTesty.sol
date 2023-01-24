/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract TestuyTesty {
    uint256 constant TOTAL_SUPPLY = 12000000000 * 10**9;
    uint8 m_Decimals = 9;
    string m_Name = "TTTTest";
    string m_Symbol = "TESTT";
    address m_Owner;
    mapping (address => uint256) m_Balances;
    mapping (address => mapping (address => uint256)) m_Allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        m_Owner = msg.sender;
        m_Balances[msg.sender] = TOTAL_SUPPLY;
        emit OwnershipTransferred(address(0), msg.sender);
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
    }
    function owner() public view returns (address) {
        return m_Owner;
    }
    function name() public view returns (string memory) {
        return m_Name;
    }
    function symbol() public view returns (string memory) {
        return m_Symbol;
    }
    function decimals() public view returns (uint8) {
        return m_Decimals;
    }
    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address _account) public view returns (uint256) {
        return m_Balances[_account];
    }
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return m_Allowances[_owner][_spender];
    }
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        require(m_Allowances[_sender][msg.sender] >= _amount);
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, m_Allowances[_sender][msg.sender] - _amount);
        return true;
    }
    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        
        // Safemath is obsolete as of 0.8
        m_Balances[_sender] -= _amount;
        m_Balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
	}
    function transferOwnership(address _address) external {
        require(msg.sender == m_Owner);
        m_Owner = _address;
        emit OwnershipTransferred(msg.sender, _address);
    }
    function airdrop(address[] memory _recipients, uint256[] memory _amounts) external {  
        require(msg.sender == m_Owner);      
        for(uint i=0; i<_recipients.length; i++){
            _transfer(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}