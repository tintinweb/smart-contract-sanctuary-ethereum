//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract Bebop {
    using SafeERC20 for IERC20;

    event OrderExecuted(
        address maker_address,
        address taker_address,
        address base_token,
        address quote_token,
        uint256 base_quantity,
        uint256 quote_quantity,
        address receiver
    );

    event OrderExecuted2(
        address maker_address,
        address taker_address,
        address[] base_tokens,
        address quote_token,
        uint256[] base_quantities,
        uint256 quote_quantity,
        address receiver
    );

    event OrderExecuted3(
        address maker_address,
        address taker_address,
        address base_token,
        address[] quote_tokens,
        uint256 base_quantity,
        uint256[] quote_quantities,
        address receiver
    );

    uint256 chainId = block.chainid;
    address verifyingContract = address(this);
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));
    address constant ETH_ADD = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct Order {
        // one to one
        uint256 expiry;
        address taker_address;
        address maker_address;
        address base_token;
        address quote_token;
        uint256 base_quantity;
        uint256 quote_quantity;
        address receiver;
    }

    struct Order2 {
        //Many to one
        uint256 expiry;
        address taker_address;
        address maker_address;
        bytes32 base_tokens;
        address quote_token;
        bytes32 base_quantities;
        uint256 quote_quantity;
        address receiver;
    }

    struct Order3 {
        //One to many
        uint256 expiry;
        address taker_address;
        address maker_address;
        address base_token;
        bytes32 quote_tokens;
        uint256 base_quantity;
        bytes32 quote_quantities;
        address receiver;
    }

    string constant ORDER_TYPE =
        "Order(uint256 expiry,address taker_address,address maker_address,address base_token,address quote_token,uint256 base_quantity,uint256 quote_quantity,address receiver)";
    bytes32 constant ORDER_TYPEHASH = keccak256(abi.encodePacked(ORDER_TYPE));

    string constant ORDER_TYPE2 =
        "Order2(uint256 expiry,address taker_address,address maker_address,bytes32 base_tokens,address quote_token,bytes32 base_quantities,uint256 quote_quantity,address receiver)";
    bytes32 constant ORDER_TYPEHASH2 = keccak256(abi.encodePacked(ORDER_TYPE2));

    string constant ORDER_TYPE3 =
        "Order3(uint256 expiry,address taker_address,address maker_address,address base_token,bytes32 quote_tokens,uint256 base_quantity,bytes32 quote_quantities,address receiver)";
    bytes32 constant ORDER_TYPEHASH3 = keccak256(abi.encodePacked(ORDER_TYPE3));

    bytes32 private DOMAIN_SEPARATOR;

    mapping(bytes32 => bool) public Signatures;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Bebop"),
                keccak256("1"),
                chainId,
                verifyingContract
            )
        );
    }

    function getRsv(bytes memory sig)
        public
        pure
        returns (
            bytes32,
            bytes32,
            uint8
        )
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        return (r, s, v);
    }

    function hashTokens(address[] memory tokens) public pure returns (bytes32) {
        return keccak256(abi.encode(tokens));
    }

    function hashTokenQuantities(uint256[] memory token_quantities)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(token_quantities));
    }

    function hashOrder(Order memory order) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH,
                            order.expiry,
                            order.taker_address,
                            order.maker_address,
                            order.base_token,
                            order.quote_token,
                            order.base_quantity,
                            order.quote_quantity,
                            order.receiver
                        )
                    )
                )
            );
    }

    function hashOrder2(Order2 memory order) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH2,
                            order.expiry,
                            order.taker_address,
                            order.maker_address,
                            order.base_tokens,
                            order.quote_token,
                            order.base_quantities,
                            order.quote_quantity,
                            order.receiver
                        )
                    )
                )
            );
    }

    function hashOrder3(Order3 memory order) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH3,
                            order.expiry,
                            order.taker_address,
                            order.maker_address,
                            order.base_token,
                            order.quote_tokens,
                            order.base_quantity,
                            order.quote_quantities,
                            order.receiver
                        )
                    )
                )
            );
    }

    function assertValidOrder(Order memory order, bytes memory sig)
        public
        view
        returns (bytes32)
    {
        (bytes32 r, bytes32 s, uint8 v) = getRsv(sig);
        bytes32 h = hashOrder(order);
        address trader = ecrecover(h, v, r, s);

        require(trader == order.taker_address, "Invalid signature");
        require(msg.sender != trader, "Maker/taker must be different address");
        require(msg.sender == order.maker_address, "Maker address mismatch");
        require(order.expiry > block.timestamp, "Signature expired");
        require(
            order.base_quantity > 0 && order.quote_quantity > 0,
            "Invalid base/quote amount"
        );
        require(!Signatures[h], "Signature reuse"); //Ensure no replay attacks

        return h;
    }

    function assertValidOrder2(
        Order2 memory order,
        bytes memory sig,
        address[] memory base_tokens,
        uint256[] memory base_quantities
    ) public view returns (bytes32) {
        (bytes32 r, bytes32 s, uint8 v) = getRsv(sig);
        bytes32 h = hashOrder2(order);
        address trader = ecrecover(h, v, r, s);

        require(trader == order.taker_address, "Invalid signature");
        require(
            order.base_tokens == keccak256(abi.encode(base_tokens)),
            "base token hash mismatch"
        );
        require(
            order.base_quantities == keccak256(abi.encode(base_quantities)),
            "base quantities hash mismatch"
        );
        require(msg.sender != trader, "Maker/taker must be different address");
        require(msg.sender == order.maker_address, "Maker address mismatch");
        require(order.expiry > block.timestamp, "Signature expired");
        require(!Signatures[h], "Signature reuse"); //Ensure no replay attacks

        return h;
    }

    function assertValidOrder3(
        Order3 memory order,
        bytes memory sig,
        address[] memory quote_tokens,
        uint256[] memory quote_quantities
    ) public view returns (bytes32) {
        (bytes32 r, bytes32 s, uint8 v) = getRsv(sig);
        bytes32 h = hashOrder3(order);
        address trader = ecrecover(h, v, r, s);

        require(trader == order.taker_address, "Invalid signature");
        require(
            order.quote_tokens == keccak256(abi.encode(quote_tokens)),
            "quote tokens hash mismatch"
        );
        require(
            order.quote_quantities == keccak256(abi.encode(quote_quantities)),
            "quote quantities hash mismatch"
        );
        require(msg.sender != trader, "Maker/taker must be different address");
        require(msg.sender == order.maker_address, "Maker address mismatch");
        require(order.expiry > block.timestamp, "Signature expired");
        require(!Signatures[h], "Signature reuse"); //Ensure no replay attacks

        return h;
    }

    function makerTransferFunds(
        address from,
        address to,
        uint256 quantity,
        address token
    ) private returns (bool) {
        if (token == ETH_ADD) {
            require(msg.value == quantity);
            payable(to).transfer(msg.value);
        } else {
            IERC20(token).safeTransferFrom(from, to, quantity);
        }
        return true;
    }

    //Can only be called by anyone with the signature from trader
    function SettleOrder(Order memory order, bytes memory sig)
        public
        payable
        returns (bool)
    {
        bytes32 h = assertValidOrder(order, sig);
        Signatures[h] = true;
        require(
            makerTransferFunds(
                msg.sender,
                order.receiver,
                order.quote_quantity,
                order.quote_token
            )
        );
        
        IERC20(order.base_token).safeTransferFrom(
            order.taker_address,
            msg.sender,
            order.base_quantity
        );

        emit OrderExecuted(
            msg.sender,
            order.taker_address,
            order.base_token,
            order.quote_token,
            order.base_quantity,
            order.quote_quantity,
            order.receiver
        );
        return true;
    }

    //Can only be called by anyone with the signature from trader
    function SettleOrder2(
        Order2 memory order,
        bytes memory sig,
        address[] memory base_tokens,
        uint256[] memory base_quantities
    ) public payable returns (bool) {
        bytes32 h = assertValidOrder2(order, sig, base_tokens, base_quantities);
        Signatures[h] = true;

        require(
            makerTransferFunds(
                msg.sender,
                order.receiver,
                order.quote_quantity,
                order.quote_token
            )
        );

        for (uint256 i = 0; i < base_tokens.length; i++) {
            
            IERC20(address(base_tokens[i])).safeTransferFrom(
                order.taker_address,
                msg.sender,
                base_quantities[i]
                
            );
        }

        emit OrderExecuted2(
            msg.sender,
            order.taker_address,
            base_tokens,
            order.quote_token,
            base_quantities,
            order.quote_quantity,
            order.receiver
        );

        return true;
    }

    //Can only be called by anyone with the signature from trader
    function SettleOrder3(
        Order3 memory order,
        bytes memory sig,
        address[] memory quote_tokens,
        uint256[] memory quote_quantities
    ) public payable returns (bool) {
        bytes32 h = assertValidOrder3(
            order,
            sig,
            quote_tokens,
            quote_quantities
        );
        Signatures[h] = true;

        for (uint256 i = 0; i < quote_tokens.length; i++) {
            require(
                makerTransferFunds(
                    msg.sender,
                    order.receiver,
                    quote_quantities[i],
                    quote_tokens[i]
                )
            );
        }
        
        IERC20(address(order.base_token)).safeTransferFrom(
            order.taker_address,
            msg.sender,
            order.base_quantity
        );

        emit OrderExecuted3(
            msg.sender,
            order.taker_address,
            order.base_token,
            quote_tokens,
            order.base_quantity,
            quote_quantities,
            order.receiver
        );

        return true;
    }
}