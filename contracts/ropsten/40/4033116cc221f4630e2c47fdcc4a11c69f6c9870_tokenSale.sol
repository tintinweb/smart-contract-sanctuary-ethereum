/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;

contract tokenSale {

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = "Orbitain";
    string public symbol = "OBTN";
    uint8 public decimal = 27;
    address payable Owner;

    mapping(address => uint256) private balances;

    uint256 maximumSupply_ = 1000000000 * 10 ** decimal;
    uint256 totalSupply_;
    
    constructor() {
        Owner = payable(msg.sender);
        _mint(Owner, 100000000 * 10 ** decimal);
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "not owner");
        _;
    }

    function withdraw(uint256 amount) public onlyOwner{
        Owner.transfer(amount);
    }

    function ownerAddress () public view returns(address){
        return Owner;
    }

    function balanceOf (address account) public view returns(uint256){
        return balances[account];
    }

    function _mint(address account, uint256 _value) internal virtual {
        require (account != address(0), "ERC20: mint to zero account");
        require (_value <= maximumSupply_, "ERC20: exceeded maximumsupply");

        _beforeTokenTransfer(address(0), account, _value);
        totalSupply_ += _value;
        balances[account] += _value;
        emit Transfer(address(0), account, _value);

        _afterTokenTransfer(address(0), account, _value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _value
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 _value
    ) internal virtual {}

    function maximumSupply() public view returns (uint256) {
        return maximumSupply_;
    }
    
    function totalSupply() public view returns (uint256) {
        require(totalSupply_ <= maximumSupply_);
        return totalSupply_;
    }

    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    balances[_from] = balances[_from] - (_value);
    balances[_to] = balances[_to] + (_value);
    emit Transfer(_from, _to, _value);
    return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender] - (_value);
    balances[_to] = balances[_to] + (_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
    }
}