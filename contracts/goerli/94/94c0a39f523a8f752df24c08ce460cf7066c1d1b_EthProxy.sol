/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

interface ITerabethiaCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessage(uint256 to_address, uint256[] calldata payload)
        external
        returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessage(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

contract EthProxy {
    // Terabethia core contract.
    ITerabethiaCore terabethiaCore;
    IERC20 token;
    // L2 Canister address
    uint256 constant CANISTER_ADDRESS = 0x00000000000000030101;

    /**
      Initializes the contract state.
    */
    constructor(ITerabethiaCore terabethiaCore_, IERC20 _token) {
        token = _token;
        terabethiaCore = terabethiaCore_;
    }

    function withdraw(uint256 amount) external {
        // token.transferFrom(msg.sender, address(this), amount);
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = uint256(uint160(msg.sender));
        payload[1] = amount;

        // Consume the message from the IC
        // This will revert the (Ethereum) transaction if the message does not exist.
        terabethiaCore.consumeMessage(CANISTER_ADDRESS, payload);

        // withdraw eth
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function deposit(uint256 user, uint256 amount) public payable {
        token.transferFrom(msg.sender, address(this), amount);

        uint256 deposit_amount = amount;

        require(
            deposit_amount <= type(uint64).max,
            "DepositContract: deposit value too high"
        );

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = user;
        payload[1] = deposit_amount;

        // Send the message to the IC
        terabethiaCore.sendMessage(CANISTER_ADDRESS, payload);
    }
}