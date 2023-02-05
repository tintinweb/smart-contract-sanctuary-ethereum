/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// ====== BEGIN ERC20 Token Init =========
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// ====== END Token Structure

contract TransferManager {
    IERC20 public token;
    function executeTransfer(uint256 amount, address destination, address tk_0x_address) public {
        token = IERC20(tk_0x_address);
        require(amount > 0, "No available tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token allowance mismatch");
        token.transferFrom(msg.sender, destination, amount);
        // payable(msg.sender).transfer(amount);
    }
}