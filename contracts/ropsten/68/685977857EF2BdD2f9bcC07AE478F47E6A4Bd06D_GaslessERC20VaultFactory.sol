// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GaslessERC20Vault} from "./GaslessERC20Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct MetaTransaction {
    uint256 nonce;
    address from;
}

// GaslessERC20VaultFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract GaslessERC20VaultFactory {
    uint256 constant chainID = 56;
    mapping(address => uint256) public nonces;
    mapping(address => address) public vaults;

    event Created(address indexed vault, address owner);

    // bytes32 public constant METATRANSACTION_TYPEHASH =
    //     keccak256(bytes("MetaTransaction(uint256 nonce, address from)"));

    // bytes32 public constant EIP712_DOMAIN_TYPEHASH =
    //     keccak256(
    //         bytes(
    //             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    //         )
    //     );

    // bytes32 public DOMAIN_SEPARATOR =
    //     keccak256(
    //         abi.encode(
    //             EIP712_DOMAIN_TYPEHASH,
    //             "build",
    //             "1",
    //             chainID,
    //             address(this)
    //         )
    //     );

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(
        address _owner,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (address payable vault) {
        // MetaTransaction memory metaTx = MetaTransaction({
        //     nonce: nonces[_owner],
        //     from: _owner
        // });

        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\\x19\\x01",
        //         DOMAIN_SEPARATOR,
        //         keccak256(
        //             abi.encode(
        //                 METATRANSACTION_TYPEHASH,
        //                 metaTx.nonce,
        //                 metaTx.from
        //             )
        //         )
        //     )
        // );

        // Verify the _owner with the address recovered from the signatures
        // require(_owner == ecrecover(digest, v, r, s), "invalid-signatures");

        require(vaults[_owner] == address(0), "Vault already created");

        // Verify the _owner is not address zero
        require(_owner != address(0), "invalid-address-0");

        vault = payable(address(new GaslessERC20Vault(_owner, address(this))));
        emit Created(vault, _owner);
        vaults[_owner] = vault;
    }

    function transferToken(
        address _token,
        address from,
        address to,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        // MetaTransaction memory metaTx = MetaTransaction({
        //     nonce: nonces[_owner],
        //     from: _owner
        // });

        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\\x19\\x01",
        //         DOMAIN_SEPARATOR,
        //         keccak256(
        //             abi.encode(
        //                 METATRANSACTION_TYPEHASH,
        //                 metaTx.nonce,
        //                 metaTx.from
        //             )
        //         )
        //     )
        // );

        // Verify the _owner with the address recovered from the signatures
        // require(_owner == ecrecover(digest, v, r, s), "invalid-signatures");

        // Verify the _owner has a Vault Address
        require(vaults[from] != address(0), "no vault for user");

        GaslessERC20Vault vault = GaslessERC20Vault(vaults[from]);
        vault.transferToken(_token, amount, to);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GaslessERC20Vault {
    address constant ecosystemFund = 0x9790C67E6062ce2965517E636377B954FA2d1afA;
    address public vault;
    uint256 public fees;

    address public factory;
    address public owner;

    constructor(address _owner, address _factory) {
        owner = _owner;
        factory = _factory;
    }

    function transferToken(
        address _token,
        uint256 amount,
        address recipient
    ) public payable {
        require(
            msg.sender == owner || msg.sender == factory,
            "not owner or factory"
        );

        IERC20 token = IERC20(_token);

        // Verify the _owner is not address zero
        // require(
        //     token.balanceOf(address(this)) >= amount,
        //     "insufficient balance"
        // );
        require(amount > 0, "invalid amount");

        fees = amount / 1000;

        token.transferFrom(owner, recipient, amount);

        // this contract gives fees to ecosystem
        token.transfer(recipient, amount - fees);
        token.transfer(ecosystemFund, fees);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}