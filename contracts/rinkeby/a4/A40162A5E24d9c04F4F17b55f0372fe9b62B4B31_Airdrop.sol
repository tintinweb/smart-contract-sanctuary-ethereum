// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Airdrop{
    address ownerAddress = 0x07292fBFaEfC1A47252C1F0f856F36cCFE45a868;
    address tokenAddress = 0x7DEe9eB0eEF15293c52d9BFC4c70fb486c9CD87F;
    IERC20 token = IERC20(tokenAddress);

    function airdrop(address _userAddress, uint256 _amount) public {
        token.transferFrom(ownerAddress,_userAddress,_amount);
    }
}