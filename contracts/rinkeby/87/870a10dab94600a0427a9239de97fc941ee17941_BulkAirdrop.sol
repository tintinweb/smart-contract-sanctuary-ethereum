/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: contracts/dropair.sol

/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// File: contracts/bulkairdrop.sol



pragma solidity ^0.8.10;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

contract BulkAirdrop {
    constructor() {}

    function BulkAirdropERC20(
        IERC20 _token,
        address[] calldata _to,
        uint256[] calldata _value
    ) public {
        require(
            _to.length == _value.length,
            "Receivers and amount are different length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }
}