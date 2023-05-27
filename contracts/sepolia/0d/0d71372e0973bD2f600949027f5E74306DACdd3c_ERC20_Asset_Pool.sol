//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./IMultisigControl.sol";
import "./IERC20.sol";

/// @title ERC20 Asset Pool
/// @author Vega Protocol
/// @notice This contract is the target for all deposits to the ERC20 Bridge via ERC20_Bridge_Logic
contract ERC20_Asset_Pool {
    event Multisig_Control_Set(address indexed new_address);
    event Bridge_Address_Set(address indexed new_address);

    /// @return Current MultisigControl contract address
    address public multisig_control_address;

    /// @return Current ERC20_Bridge_Logic contract address
    address public erc20_bridge_address;

    /// @param multisig_control The initial MultisigControl contract address
    /// @notice Emits Multisig_Control_Set event
    constructor(address multisig_control) {
        require(multisig_control != address(0), "invalid MultisigControl address");
        multisig_control_address = multisig_control;
        emit Multisig_Control_Set(multisig_control);
    }

    /// @notice this contract is not intended to accept ether directly
    receive() external payable {
        revert("this contract does not accept ETH");
    }

    /// @param new_address The new MultisigControl contract address.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed set_multisig_control order
    /// @notice See MultisigControl for more about signatures
    /// @notice Emits Multisig_Control_Set event
    function set_multisig_control(
        address new_address,
        uint256 nonce,
        bytes memory signatures
    ) external {
        require(new_address != address(0), "invalid MultisigControl address");
        require(is_contract(new_address), "new address must be contract");

        bytes memory message = abi.encode(new_address, nonce, "set_multisig_control");
        require(
            IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        multisig_control_address = new_address;
        emit Multisig_Control_Set(new_address);
    }

    /// @param new_address The new ERC20_Bridge_Logic contract address.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed set_bridge_address order
    /// @notice See MultisigControl for more about signatures
    /// @notice Emits Bridge_Address_Set event
    function set_bridge_address(
        address new_address,
        uint256 nonce,
        bytes memory signatures
    ) external {
        bytes memory message = abi.encode(new_address, nonce, "set_bridge_address");
        require(
            IMultisigControl(multisig_control_address).verify_signatures(signatures, message, nonce),
            "bad signatures"
        );
        erc20_bridge_address = new_address;
        emit Bridge_Address_Set(new_address);
    }

    /// @notice This function can only be run by the current "multisig_control_address" and, if available, will send the target tokens to the target
    /// @param token_address Contract address of the ERC20 token to be withdrawn
    /// @param target Target Ethereum address that the ERC20 tokens will be sent to
    /// @param amount Amount of ERC20 tokens to withdraw
    /// @dev amount is in whatever the lowest decimal value the ERC20 token has. For instance, an 18 decimal ERC20 token, 1 "amount" == 0.000000000000000001
    function withdraw(
        address token_address,
        address target,
        uint256 amount
    ) external {
        require(msg.sender == erc20_bridge_address, "msg.sender not authorized bridge");
        require(is_contract(token_address), "token_address must be contract");

        (bool success, bytes memory returndata) = token_address.call(
            abi.encodeWithSignature("transfer(address,uint256)", target, amount)
        );
        require(success, "token transfer failed");

        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "token transfer failed");
        }
    }

    function is_contract(address addr) internal view returns (bool) {
        uint256 code_size;
        assembly {
            code_size := extcodesize(addr)
        }
        return code_size > 0;
    }
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/