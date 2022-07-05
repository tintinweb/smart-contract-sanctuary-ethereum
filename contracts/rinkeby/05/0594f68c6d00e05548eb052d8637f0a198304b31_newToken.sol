/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity ^0.8.15;

contract newToken {
    string _tokenName;
    string _tokenSymbol;
    uint256 _tokenSupply;
    uint _decimals;
    mapping(address => uint256) _balanceOf;
    constructor(uint256 tokenSupply_, string memory tokenName_, string memory tokenSymbol_, uint decimals_) {
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;
        _tokenSupply = tokenSupply_;
        _decimals = decimals_;
        _balanceOf[msg.sender] = tokenSupply_;

    }
    function totalSupply() public view returns(uint256){
        return _tokenSupply;
    }
    function tokenName() public view returns(string memory) {
        return _tokenName;
    }
    function tokenSymbol() public view returns(string memory) {
        return _tokenSymbol;
    }
    function decimals() public view returns(uint){
        return _decimals;
    }
    function balanceOf(address _address) public view returns(uint256){
        return _balanceOf[_address];
    }
}