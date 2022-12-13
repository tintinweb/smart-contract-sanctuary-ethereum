//SPDX-License-Identifier: UNLICENSED


import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

pragma solidity ^0.8.0;

contract LimitSwap {
    using SafeERC20 for IERC20;

    event SwapExecuted(
        address user,
        address mm,
        address t1,
        address t2,
        uint256 t1qty,
        uint256 t2qty
    );

    uint256 chainId = block.chainid;
    address verifyingContract = address(this);
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(abi.encodePacked(EIP712_DOMAIN));
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct Swap {
        uint256 expiry;
        address user;
        address mm;
        address t1; //user selling t1 (move from user to mm)
        address t2; //user buying t2  (moved to user from mm)
        uint256 t1qty;  //user selling t1qty
        uint256 t2qty;  //user buying t2qty
    }

    string constant SWAP_TYPE =
        "Swap(uint256 expiry,address user,address mm,address t1,address t2,uint256 t1qty,uint256 t2qty)";
    bytes32 constant SWAP_TYPEHASH = keccak256(abi.encodePacked(SWAP_TYPE));

    bytes32 private DOMAIN_SEPARATOR;

    //If true, swap has been executed or has expired
    mapping(bytes => bool) public InvalidSignatures;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("LimitSwap"),
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

    function hashSwap(Swap memory swap) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SWAP_TYPEHASH,
                            swap.expiry,
                            swap.user,
                            swap.mm,
                            swap.t1,
                            swap.t2,
                            swap.t1qty,
                            swap.t2qty
                        )
                    )
                )
            );
    }

    function checkValidSwap(Swap memory swap, bytes memory sig)
        public
        view
        returns (bool)
    {
        (bytes32 r, bytes32 s, uint8 v) = getRsv(sig);
        bytes32 h = hashSwap(swap);
        address user = ecrecover(h, v, r, s);

        require(user == swap.user, "ecrecover fail");
        require(msg.sender != user, "taking own order");
        require(swap.mm == address(0) || msg.sender == swap.mm, "not the otc executor");
        require(swap.expiry > block.timestamp, "Signature expired");
        require(InvalidSignatures[sig], "Signature reuse"); //Ensure no replay attacks

        return true;
    }


    function ExecuteSwap(Swap memory swap, bytes memory sig)
        public
        payable
        returns (bool)
    {
        checkValidSwap(swap, sig);
        InvalidSignatures[sig] = true;

        //mm to user who place limit orders
        if (swap.t2 == ETH_ADDRESS) {
            require(msg.value == swap.t2qty);
            payable(swap.user).transfer(msg.value);
        } else {
            IERC20(swap.t2).safeTransferFrom(swap.mm, swap.user, swap.t2qty);
        }
        
        //limit order from user to mm
        IERC20(swap.t1).safeTransferFrom(
            swap.user,
            msg.sender,
            swap.t1qty
        );

        return true;
    }

}