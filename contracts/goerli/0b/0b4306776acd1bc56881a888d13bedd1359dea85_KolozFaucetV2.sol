/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

contract KolozFaucetV2 {
    error ChillOut();
    error YUNoWork();
    error DontBeGreedy();
    
    mapping(address => uint256) private rareCooldowns;
    mapping(address => uint256) private ethCooldowns;

    IERC20 private rare;

    address public owner;

    constructor(address _rare) {
        rare = IERC20(_rare);
        owner = msg.sender;
    }

    function claimRare() external {
        if (rareCooldowns[msg.sender] > block.timestamp) revert ChillOut();
        rareCooldowns[msg.sender] = block.timestamp + 1 days;
        rare.transfer(msg.sender, 4200000000000000000000);
    }

    function claimEth() external {
        if (ethCooldowns[msg.sender] > block.timestamp) revert ChillOut();
        ethCooldowns[msg.sender] = block.timestamp + 1 days;
        (bool s,) = msg.sender.call{value:420000000000000000}("");
        if (!s) revert YUNoWork();
    }

    function withdrawAll() external {
        if (msg.sender != owner) revert DontBeGreedy();
        (bool s,) = msg.sender.call{value:address(this).balance}("");
        if (!s) revert YUNoWork();
        rare.transfer(msg.sender, rare.balanceOf(address(this)));
    }

    receive() external payable {}
}