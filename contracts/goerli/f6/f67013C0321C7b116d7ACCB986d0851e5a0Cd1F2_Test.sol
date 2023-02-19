/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

pragma solidity ^0.8.17;
interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract Test{
    function forward(
        address payable from,
        address token,
        address payable recipient,
        uint256 value
    ) external {
        bool success = IERC20(token).transferFrom(
            from,
            recipient,
            value
        );
        require(success, "Tranfer Wrong");
        }
}