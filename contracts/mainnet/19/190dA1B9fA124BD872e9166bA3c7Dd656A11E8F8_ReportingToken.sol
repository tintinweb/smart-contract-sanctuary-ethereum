/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract ReportingToken{
    event Transfer(address indexed from, address indexed to, uint256 value);

    event CommitOwnership(address admin);
    event AcceptOwnership(address admin);


    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string constant private _name = "ReportingToken";
    string constant private _symbol = "RPT";

    address public admin;
    address public future_admin;

    constructor() {
        admin = msg.sender;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure  returns (uint8) {
        return 0;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function assign(address account)external {
        require(msg.sender == admin, "onlyOwner");

        require(account != address(0), "assign to the zero address");
        require(_balances[account] == 0, "already assigned");

        unchecked {
            _totalSupply += 1;
            _balances[account] += 1;
        }

        emit Transfer(address(0), account, 1);
    }

    function resign(address account)external {
        require(msg.sender == admin || msg.sender == account, "onlyOwner or holder");

        require(account != address(0), "zero address");
        require(_balances[account] == 1, "not assigned");

        unchecked {
            _balances[account] -= 1;
            _totalSupply -= 1;
        }

        emit Transfer(account, address(0), 1);
    }

    function commit_transfer_ownership(address addr)external {
        /***
        *@notice Transfer ownership of GaugeController to `addr`
        *@param addr Address to have ownership transferred to
        */
        require (msg.sender == admin, "onlyOwner");
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function accept_transfer_ownership()external {
        /***
        *@notice Accept a transfer of ownership
        */
        address _future_admin = future_admin;
        require(msg.sender == _future_admin, "onlyFutureOwner");

        admin = _future_admin;

        emit AcceptOwnership(_future_admin);
    }

}