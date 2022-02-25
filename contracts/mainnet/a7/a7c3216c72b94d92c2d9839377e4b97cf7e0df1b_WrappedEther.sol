/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.5.0;

contract WrappedEther {

    uint256 _totalSupply;
    string _tokenName;
    string _tokenSymbol;
    uint _decimals;

    mapping(address => uint256) _balanceOf;

    constructor(uint256 totalSupply_, string memory tokenName_, string memory tokenSymbol_, uint decimals_) public {
        _totalSupply = totalSupply_;
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;
        _decimals = decimals_;
        _balanceOf[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function tokenName() public view returns(string memory){
        return _tokenSymbol;
    }

    function tokenSymbol() public view returns (string memory){
        return _tokenName;
    }

    function decimals() public view returns (uint){
        return _decimals;
    }

    function balanceOf(address _address) public view returns(uint256){
        return _balanceOf[_address];
    }

}