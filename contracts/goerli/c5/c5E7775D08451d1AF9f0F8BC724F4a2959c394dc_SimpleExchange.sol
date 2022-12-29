// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleExchange  {
    address payable owner;

    // SOME TOKENS FOR TEST
    address private immutable uniAddress =
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI TOKEN
    address private immutable usdcAddress =
        0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43; // USDC TOKEN
    address dexContractAddress =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; // Contrato Objetivo


    // FUNCTION FOR EXCHANGE
    function exchangeCall(address target, bytes memory callData, uint values, uint estimatedGas) public payable returns (uint256 blockNumber) {
        blockNumber = block.number;
        (bool success, bytes memory ret) = target.call{value:values,gas:estimatedGas}(callData);
        require(success);
    }

    // FUNCTION FOR EXCHANGE
    function exchangeCallUNI(address target, bytes memory callData) external returns (uint256 blockNumber) {
        blockNumber = block.number;
        (bool success, bytes memory ret) = target.call(callData);
        require(success);
    }

    //OPTIONAL FUNCTIONS FOR DEVELOPMENT TESTS
    function approveUSDC(uint256 _amount) external returns (bool) {
        return IERC20(usdcAddress).approve(dexContractAddress, _amount);
    }

    function allowanceUSDC() external view returns (uint256) {
        return IERC20(usdcAddress).allowance(address(this), dexContractAddress);
    }

    function approveUNI(uint256 _amount) external returns (bool) {
        return IERC20(uniAddress).approve(dexContractAddress, _amount);
    }

    function allowanceUNI() external view returns (uint256) {
        return IERC20(uniAddress).allowance(address(this), dexContractAddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function transfer(address _tokenAddress, address receiverAddr, uint receiverAmnt) public payable{
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(receiverAddr, receiverAmnt);
    }

    function transferFrom(address sender, address recipient, uint256 amount,address token) external returns (bool){
        IERC20(token).transferFrom(sender,recipient,amount);
        return true;
    }

    function withdraw(address _tokenAddress) external {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }


    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}