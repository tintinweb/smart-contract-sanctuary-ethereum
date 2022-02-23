/**
 *Submitted for verification at Etherscan.io on 2022-02-23
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

contract Many2One {
    event OrderExecuted(
        address maker_address,
        address taker_address,
        address base_token,
        address quote_token,
        uint256 base_quantity,
        uint256 quote_quantity
    );

    uint256 constant chainId = 3;
    address verifyingContract = address(this);
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));
    address constant ETH_ADD = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct Order {
        uint256 expiry;
        address taker_address;
        bytes32 base_tokens;
        address quote_token;
        bytes32 base_quantities;
        uint256 quote_quantity;
    }

    string constant ORDER_TYPE =
        "Order(uint256 expiry,address taker_address,bytes32 base_tokens,address quote_token,bytes32 base_quantities,uint256 quote_quantity)";
    bytes32 constant ORDER_TYPEHASH = keccak256(abi.encodePacked(ORDER_TYPE));

    bytes32 private DOMAIN_SEPARATOR;

    mapping(bytes32 => bool) public Signatures;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Many2One"),
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


    function hashBaseTokens(address[] memory base_tokens)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(base_tokens));
    }


    function hashBaseQuantities(uint256[] memory base_quantities)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(base_quantities));
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
                            order.base_tokens,
                            order.quote_token,
                            order.base_quantities,
                            order.quote_quantity
                        )
                    )
                )
            );
    }


    function assertValidOrder(Order memory order, bytes memory sig, address[] memory base_tokens, uint256[] memory base_quantities)
        public
        view
        returns (bytes32)
    {
        (bytes32 r, bytes32 s, uint8 v) = getRsv(sig);
        bytes32 h = hashOrder(order);
        address trader = ecrecover(h, v, r, s);

        require(trader == order.taker_address, "Invalid signature");
        require(order.base_tokens == keccak256(abi.encode(base_tokens)));
        require(order.base_quantities == keccak256(abi.encode(base_quantities)));
        require(msg.sender != trader, "Maker/taker must be different address");
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
    function SettleOrder(Order memory order, bytes memory sig, address[] memory base_tokens, uint256[] memory base_quantities)
        public
        payable
        returns (bool)
    {
        bytes32 h = assertValidOrder(order, sig, base_tokens, base_quantities);
        Signatures[h] = true;
        
        require(
            makerTransferFunds(
                msg.sender,
                order.taker_address,
                order.quote_quantity,
                order.quote_token
            )
        );

        for (uint256 i = 0; i < base_tokens.length; i++){
            require(
                IERC20(address(base_tokens[i])).transferFrom(
                    order.taker_address,
                    msg.sender,
                    base_quantities[i]
                )
            );
        }

        return true;
    }
}