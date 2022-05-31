/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: UNLICENSED

pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract Bebop {
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
            require(IERC20(token).transferFrom(from, to, quantity));
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
        require(
            IERC20(order.base_token).transferFrom(
                order.taker_address,
                msg.sender,
                order.base_quantity
            )
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
            require(
                IERC20(address(base_tokens[i])).transferFrom(
                    order.taker_address,
                    msg.sender,
                    base_quantities[i]
                )
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

        require(
            IERC20(address(order.base_token)).transferFrom(
                order.taker_address,
                msg.sender,
                order.base_quantity
            )
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