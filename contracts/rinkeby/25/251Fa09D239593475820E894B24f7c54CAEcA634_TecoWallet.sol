/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

address constant constant_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

interface TDEX {

    function getPrice(address _tokenContract) external view returns (uint256);
}

struct Token {
    address tokenContract;
    string name;
    string symbol;
    uint decimals;
    uint256 balance;
}

contract TecoWallet {

    constructor () {
    }

    function tokenInfos(address _sender, address[] memory _tokenContractList) external view returns (Token[] memory)
    {
        Token[] memory list = new Token[](_tokenContractList.length);
        for (uint i=0; i<_tokenContractList.length; i++)
        {
            address token = _tokenContractList[i];
            
            string memory name;
            string memory symbol;
            uint decimals;
            uint256 balance;
            if (token != constant_ETH)
            {
                name = ERC20(token).name();
                symbol = ERC20(token).symbol();
                decimals = ERC20(token).decimals();
                balance = IERC20(token).balanceOf(_sender);
            }
            else
            {
                balance = _sender.balance;
                decimals = 18;
            }

            list[i] = Token(token, name, symbol, decimals, balance);
        }
        return list;
    }

    function balanceOfs(address _sender, address[] memory _tokenContractList) external view returns (uint256[] memory)
    {
        uint256[] memory list = new uint256[](_tokenContractList.length);
        for (uint i=0; i<_tokenContractList.length; i++)
        {
            address token = _tokenContractList[i];
            if (token != constant_ETH)
            {
                list[i] = IERC20(token).balanceOf(_sender);
            }
            else
            {
                list[i] = _sender.balance;
            }
        }
        return list;
    }
}