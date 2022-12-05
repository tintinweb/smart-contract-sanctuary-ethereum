// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./tokens/interfaces/IFurionToken.sol";

/**
 * @title  Claim necessary tokens for testing Furion
 * @notice We will mint sender specific amount of FurionToken, MockUSD, and NFTs
 */

contract TestClaim {
    address constant BAYC = 0xfE0C4f142EbFf93BEf8B0edE768c6d2D7048FB01;
    address constant MAYC = 0xaFFfC6B2A6F10Ff5fDD29496099CB8E0113C451e;
    address constant OTHERDEED = 0x15839d0485bAE4d98a28F5b9a8221D0bb67717c5;
    address constant BAKC = 0x22BA730714BbE51fbFb8Cb329a52E73951e95B9e;
    address constant PUNKS = 0xa3430ccf668e6BF470eb11892B338ee9f3776AA3;
    address constant AZUKI = 0xa0b5875b828A9196cBeD9C48a125205dfA36bA0c;
    address constant DOODLES = 0x610A10D54d4A0050c320bCec8BdDe7E6b8e23876;
    address constant MEEBITS = 0x1FceecefA11d69CAaA33e4a0e6bb3D311F36D254;
    address constant GHOST = 0xaAD851C97D3c71E48dc9F1da7D769A937B5fE8e3;
    address constant CATDDLE = 0xbD431B1b276003D59b2e3359b99bf9468BeA025E;
    address constant SHHANS = 0x629A51AfE063bEE68500546F722c8EC14e8fE847;
    address[] nfts = [
        MAYC,
        OTHERDEED,
        BAKC,
        PUNKS,
        AZUKI,
        DOODLES,
        MEEBITS,
        GHOST,
        CATDDLE,
        SHHANS
    ];
    address constant FUR = 0x167873d27d6f16C503A694814a3895215344B601;

    mapping(address => bool) public claimed;

    uint256 public counter = 0;

    /**
     * @notice Claim testing tokens
     */
    function claimTest() external returns (uint256) {
        // every account can only claim once
        require(!claimed[msg.sender], "Already claimed");

        claimed[msg.sender] = true;

        IFurionToken(FUR).mintFurion(msg.sender, 1000e18);

        bytes memory data;
        bool success;
        bytes memory returnData;

        data = abi.encodeWithSignature("mint(address,uint256)", msg.sender, 1);

        (success, returnData) = BAYC.call(data);
        require(success, string(returnData));

        uint256 randNft = counter % 10;
        (success, returnData) = nfts[randNft].call(data);
        require(success, string(returnData));

        counter++;

        // Return nft index for getting the corresponding image at front-end
        return randNft;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFurionToken is IERC20, IERC20Permit {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //
    function CAP() external view returns (uint256);

    /**
     * @notice Mint Furion native tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mintFurion(address _account, uint256 _amount) external;

    /**
     * @notice Burn Furion native tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burnFurion(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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