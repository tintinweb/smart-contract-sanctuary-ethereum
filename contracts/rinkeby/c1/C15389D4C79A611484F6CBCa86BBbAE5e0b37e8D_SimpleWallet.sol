// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC20.sol";

contract SimpleWallet {
    
    ERC20 token;

    function newCheckAllowance(address _tokenAddress, address _owner, address _spender) external returns (uint256){
        token = ERC20(_tokenAddress);
        return token.allowance(_owner, _spender);
    }

    function newTransfer(address _tokenAddress, address _from, address _to, uint256 _amount) external returns (bool){
        token = ERC20(_tokenAddress);
        return token.transferFrom(_from, _to, _amount);
    }

    function checkBalance(address _tokenAddress, address _account) public returns(uint256){
        token = ERC20(_tokenAddress);
        return token.balanceOf(_account);
    }
}