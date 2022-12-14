// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20Permit.sol";
import "./BurnPermit.sol";

/// @title Hashkey token contract
contract HashkeyTokenV0 is BurnPermit, ERC20Permit {
    receive() external payable {
        require(false, "Contract is not payable");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interface/IERC20Permit.sol";
import "./ERC20.sol";
import "./library/CheckSig.sol";

/// @title ERC20 with permit, as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]
/// @notice ERC20 tokens which supports approvement via signature
abstract contract ERC20Permit is IERC20Permit, ERC20 {
    using CheckSig for address;

    bytes32 private constant NAME_HASH = keccak256("HashKey Token");

    bytes32 private constant VERSION_HASH = keccak256("version 0");

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) private _nonces;

    /// @dev return user's current nonce and increase it.
    function increaseNonce(address account) internal returns (uint256) {
        uint256 n = _nonces[account];
        _nonces[account]++;
        return n;
    }

    /// @dev See in IERC20Permit
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }

    /// @dev See in IERC20Permit.
    function nonces(address account) public view override returns (uint256) {
        return _nonces[account];
    }

    /// @dev See in IERC20Permit.
    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, value, increaseNonce(_owner), deadline));
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR(), structHash);

        _owner.checkSignature(digest, v, r, s);

        _approve(_owner, spender, value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";
import "./library/CheckSig.sol";

abstract contract BurnPermit is ERC20 {
    using CheckSig for address;

    mapping(address => uint256) private _burnNonces;

    bytes32 private constant BURN_TYPEHASH = keccak256("HashKey Token v0 Burn");

    bytes32 private constant BURN_FROM_TYPEHASH = keccak256("HashKey Token v0 Burn From");

    bytes32 public constant BURN_ROLE = keccak256("Burn Role");

    /// @dev Return account's available nonce.
    function burnNonce(address account) public view returns (uint256) {
        return _burnNonces[account];
    }

    /// @dev Hash of the burn request message.
    function burnMessageHash(
        address applicant,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                BURN_TYPEHASH,
                block.chainid,
                address(this),
                applicant,
                amount,
                nonce,
                deadline
            )
        );
    }

    /// @dev Hash of the burn from request message.
    function burnFromMessageHash(
        address applicant,
        address from,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                BURN_FROM_TYPEHASH,
                block.chainid,
                address(this),
                applicant,
                from,
                amount,
                nonce,
                deadline
            )
        );
    }

    /// @dev Burn {amount} tokens of {applicant} by the owner, ensure {sig} is signed from {applicant}.
    function burn(
        address applicant,
        uint256 amount,
        uint256 deadline,
        bytes memory sig
    ) external accessible(BURN_ROLE) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "BurnPermit: expired deadline");

        bytes32 message = burnMessageHash(applicant, amount, burnNonce(applicant), deadline);
        bytes32 digest = ECDSA.toEthSignedMessageHash(message);
        _burnNonces[applicant]++;

        applicant.checkSignature(digest, sig);

        _burn(applicant, amount);
    }

    /// @dev Burn {amount} tokens of {applicant} from {from} by the owner, ensure {sig} is signed from {applicant}.
    function burnFrom(
        address applicant,
        address from,
        uint256 amount,
        uint256 deadline,
        bytes memory sig
    ) external accessible(BURN_ROLE) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "BurnPermit: expired deadline");

        bytes32 message = burnFromMessageHash(applicant, from, amount, burnNonce(applicant), deadline);
        bytes32 digest = ECDSA.toEthSignedMessageHash(message);
        _burnNonces[applicant]++;

        applicant.checkSignature(digest, sig);

        _burnFrom(applicant, from, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: Unlicense
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interface/IERC20.sol";
import "./library/Fund.sol";
import "./Access.sol";

/// @title Implement ERC20 token of Hashkey.
abstract contract ERC20 is Access, IERC20 {
    using SafeMath for uint256;
    using SafeCast for uint256;

    /// @dev describe the account state for user, user's fund is consist of 3 parts
    struct AccountState {
        Fund.VestFund[]         vestFunds;
        Fund.EvenVestFund[]     evenVestFunds;
        uint256                 available;
    }

    // mock for test
    uint256 private constant PER_DAY  = 10 seconds;
    // uint256 private constant PER_DAY = 1 days;
    uint256 private constant PER_YEAR = 365 * PER_DAY;

    string  private constant NAME = "HashKey Token";
    string  private constant SYMBOL = "HSK";
    uint8   private constant DECIMALS = 18;

    bool    private _initialized = true;

    uint256 private _platformShare;
    uint256 private _reserveShare;
    uint256 private _teamShare;
    uint256 private _partnerShare;
    uint256 private _totalSupply;

    bytes32 public constant PLATFORM_ROLE = keccak256("Platform Role");
    bytes32 public constant PARTNER_ROLE = keccak256("Partner Role");
    bytes32 public constant RESERVE_ROLE = keccak256("Reserve Role");
    bytes32 public constant TEAM_ROLE = keccak256("Team Role");

    mapping(address => AccountState) private accounts;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Mint(address indexed recipient, uint256 amount);
    event Shrink(uint256 amount);
    event RecallVesting(address indexed account, uint256 amount);
    event DecreaseVestingDays(address indexed account, uint256 vestingDays, uint256 evenVestingDays);
    event Burn(address indexed applicant, uint256 amount);
    event BurnFrom(address indexed applicant, address indexed from, uint256 amount);

    constructor() {
        // set owner to zero address.
        renounceOwnership();
    }

    /// @dev initialize token parameters.
    function init(address _owner) external {
        // not initialized in proxy
        require(!_initialized, "ERC20: Already initialized");

        _initialized        = true;
        _platformShare      = 90000000 * 10 ** DECIMALS;
        _reserveShare       = 20000000 * 10 ** DECIMALS;
        _teamShare          = 70000000 * 10 ** DECIMALS;
        _partnerShare      = 20000000 * 10 ** DECIMALS;
        _totalSupply        = 200000000 * 10 ** DECIMALS;

        _transferOwnership(_owner);
    }

    ///////////////////////////// ERC20 methods /////////////////////////////

    /// @dev see in IERC20
    function name() public pure override returns (string memory) {
        return NAME;
    }

    /// @dev see in IERC20.
    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    /// @dev see in IERC20.
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @dev see in IERC20.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev see in IERC20.
    /// @notice balance is consist of 3 parts: available, vested and even vested
    function balanceOf(address _owner) public view override returns (uint256) {
        AccountState storage state = accounts[_owner];
        uint256 balance = state.available;

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (, uint256 released) = Fund.getVestFund(fund, block.timestamp);
                balance = balance.add(released);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (, uint256 released) = Fund.getEvenVestFund(fund, block.timestamp);
                balance = balance.add(released);
            }
        }

        return balance;
    }

    /// @dev see in IERC20.
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    /// @dev see in IERC20.
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @dev see in IERC20.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @dev see in IERC20.
    /// @notice if _allowance is max of uint256, it means allowance is not limited.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 _allowance = allowance(from, msg.sender);
        if (_allowance != type(uint256).max) {
            require(amount <= _allowance, "ERC20: Insufficient allowance");
            _allowances[from][msg.sender] = _allowance.sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    ///////////////////////////// HSK methods ///////////////////////////// 

    /// @dev batch execute transfer tokens.
    function batchTransfer(address[] memory tos, uint256[] memory amounts) external {
        require(tos.length == amounts.length, "ERC20: Unmatched array length");

        for (uint256 i = 0; i < tos.length; i++) {
            _transfer(msg.sender, tos[i], amounts[i]);
        }
    }

    /// @dev batch execute transferFrom tokens.
    /// @notice if _allowance is max of uint256, it means allowance is not limited.
    function batchTransferFrom(address from, address[] memory tos, uint256[] memory amounts) external {
        require(tos.length == amounts.length, "ERC20: Unmatched array length");
        uint256 _allowance = allowance(from, msg.sender);

        for (uint256 i = 0; i < tos.length; i++) {
            if (_allowance != type(uint256).max) {
                require(amounts[i] <= _allowance, "ERC20: Insufficient allowance");
                _allowance = _allowance.sub(amounts[i]);
            }
            _transfer(from, tos[i], amounts[i]);
        }

        _allowances[from][msg.sender] = _allowance;
    }

    /// @dev return _platformShare.
    function platformShare() public view returns (uint256) {
        return _platformShare;
    }

    /// @dev return _reserveShare.
    function reserveShare() public view returns (uint256) {
        return _reserveShare;
    }

    /// @dev return _partnerShare.
    function partnerShare() public view returns (uint256) {
        return _partnerShare;
    }

    /// @dev return _teamShare.
    function teamShare() public view returns (uint256) {
        return _teamShare;
    }

    /// @dev vesting amount of vest fund and even vest fund.
    function vestingBalanceOf(address _owner) public view returns (uint256) {
        AccountState storage state = accounts[_owner];
        uint256 balance = 0;

        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (uint256 vesting, ) = Fund.getVestFund(fund, block.timestamp);
                balance = balance.add(vesting);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (uint256 vesting, ) = Fund.getEvenVestFund(fund, block.timestamp);
                balance = balance.add(vesting);
            }
        }

        return balance;
    }

    /// @dev mint for platform share, no time locking.
    function mintToPlatform(address recipient, uint256 amount) public accessible(PLATFORM_ROLE) {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount <= _platformShare, "ERC20: Insufficient share");
        _platformShare = _platformShare.sub(amount);

        AccountState storage state = accounts[recipient];
        _mint(state, amount);

        emit Mint(recipient, amount);
    }

    /// @dev batch mint for platform share
    function batchMintToPlatform(
        address[] memory recipients,
        uint256[] memory amounts
    ) external accessible(PLATFORM_ROLE) {
        require(recipients.length == amounts.length, "ERC20: Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintToPlatform(recipients[i], amounts[i]);
        }
    }

    /// @dev mint for reserve token, no time locking.
    function mintForReserve(address recipient, uint256 amount) public accessible(RESERVE_ROLE) {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount <= _reserveShare, "ERC20: Insufficient share");
        _reserveShare = _reserveShare.sub(amount);

        AccountState storage state = accounts[recipient];
        _mint(state, amount);

        emit Mint(recipient, amount);
    }

    /// @dev batch mint reserve tokens
    function batchMintForReserve(
        address[] memory recipients,
        uint256[] memory amounts
    ) external accessible(RESERVE_ROLE) {
        require(recipients.length == amounts.length, "ERC20: Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintForReserve(recipients[i], amounts[i]);
        }
    }

    /// @dev mint to partner, parameters are customized.
    function mintToPartner(
        address recipient,
        uint256 amount,
        uint256 vestingAmount,
        uint256 vestingDays,
        uint256 evenVestingAmount,
        uint256 evenVestingDays
    ) public accessible(PARTNER_ROLE) {
        AccountState storage state = accounts[recipient];

        uint256 totalAmount = amount.add(vestingAmount).add(evenVestingAmount);
        require(amount > 0, "ERC20: Amount is zero");
        require(totalAmount <= _partnerShare, "ERC20: Insufficient share");
        _partnerShare = _partnerShare.sub(totalAmount);

        if (amount > 0) {
            _mint(state, amount);
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp.add(vestingDays.mul(PER_DAY));
        if (vestingAmount > 0) {
            _mintVestFund(state, Fund.OwnerType.Partner, vestingAmount, deadline);
        }

        if (evenVestingAmount > 0) {
            _mintEvenVestFund(
                state,
                Fund.OwnerType.Partner,
                evenVestingAmount,
                deadline,
                deadline.add(evenVestingDays.mul(PER_DAY))
            );
        }

        emit Mint(recipient, totalAmount);
    }

    /// @dev batch mint to partners
    function batchMintToPartners(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256[] memory vestingAmounts,
        uint256[] memory vestingDaysArr,
        uint256[] memory evenVestingAmounts,
        uint256[] memory evenVestingDaysArr
    ) public accessible(PARTNER_ROLE) {
        require(recipients.length == amounts.length, "ERC20: Unmatched array length");
        require(amounts.length == vestingAmounts.length, "ERC20: Unmatched array length");
        require(vestingAmounts.length == vestingDaysArr.length, "ERC20: Unmatched array length");
        require(vestingDaysArr.length == evenVestingAmounts.length, "ERC20: Unmatched array length");
        require(evenVestingAmounts.length == evenVestingDaysArr.length, "ERC20: Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintToPartner(
                recipients[i],
                amounts[i],
                vestingAmounts[i],
                vestingDaysArr[i],
                evenVestingAmounts[i],
                evenVestingDaysArr[i]
            );
        }
    }

    /// @dev mint to team members, 10% will lock for 1 year, 90% will release in 2 more years evenly.
    function mintToTeamMember(address recipient, uint256 amount) public accessible(TEAM_ROLE) {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount <= _teamShare, "ERC20: Insufficient share");
        _teamShare = _teamShare.sub(amount);

        AccountState storage state = accounts[recipient];
        
        uint256 vestAmount = amount.div(10);
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp.add(PER_YEAR);
        _mintVestFund(state, Fund.OwnerType.Team, vestAmount, deadline);
        
        uint256 evenVestAmount = amount.sub(vestAmount);
        _mintEvenVestFund(state, Fund.OwnerType.Team, evenVestAmount, deadline, deadline.add(2 * PER_YEAR));

        emit Mint(recipient, amount);
    }

    /// @dev batch mint to team members
    function batchMintToTeamMembers(
        address[] memory recipients,
        uint256[] memory amounts
    ) external accessible(TEAM_ROLE) {
        require(recipients.length == amounts.length, "ERC20: Unmatched array length");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintToTeamMember(recipients[i], amounts[i]);
        }
    }

    /// @dev recall vesting amount of a team member.
    function recallVesting(address account) external accessible(TEAM_ROLE) {
        AccountState storage state = accounts[account];
        _updateAccountState(state);

        uint256 recycling = 0;
        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active && fund.ownerType == Fund.OwnerType.Team) {
                fund.active = false;
                recycling = recycling.add(fund.amount);
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active && fund.ownerType == Fund.OwnerType.Team) {
                fund.active = false;
                recycling = recycling.add(fund.amount);
            }
        }
        // recycle to teamShare
        _teamShare = _teamShare.add(recycling);

        emit RecallVesting(account, recycling);
    }

    /// @dev decrease deadline of vesting funds and end timestamp of even vesting funds.
    function decreaseVestingDays(
        address account,
        uint256 vestingDays,
        uint256 evenVestingDays
    ) external onlyOwner {
        AccountState storage state = accounts[account];

        uint256 vestingDuration = vestingDays.mul(PER_DAY);
        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                fund.deadline = uint256(fund.deadline).sub(vestingDuration).toUint64();
            }
        }

        uint256 evenVestingDuration = evenVestingDays.mul(PER_DAY);
        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                fund.end = uint256(fund.end).sub(evenVestingDuration).toUint64();
            }
        }

        emit DecreaseVestingDays(account, vestingDays, evenVestingDays);
    }

    /// @dev reduce amount of platform share, add reduce _totalSupply.
    function shrinkPlatformShare(uint256 amount) external onlyOwner {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount < _platformShare, "ERC20: Insufficient share");
        _platformShare = _platformShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Shrink(amount);
    }

    /// @dev reduce amount of reserve share, add reduce _totalSupply.
    function shrinkReserveShare(uint256 amount) external onlyOwner {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount < _reserveShare, "ERC20: Insufficient share");
        _reserveShare = _reserveShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Shrink(amount);
    }

    /// @dev reduce amount of partner share, add reduce _totalSupply.
    function shrinkPartnerShare(uint256 amount) external onlyOwner {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount < _partnerShare, "ERC20: Insufficient share");
        _partnerShare = _partnerShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Shrink(amount);
    }

    /// @dev reduce amount of team share, add reduce _totalSupply.
    function shrinkTeamShare(uint256 amount) external onlyOwner {
        require(amount > 0, "ERC20: Amount is zero");
        require(amount < _teamShare, "ERC20: Insufficient share");
        _teamShare = _teamShare.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Shrink(amount);
    }

    ///////////////////////////// Internal Methods /////////////////////////////

    /// @dev compute the releasing amount of vest part and even vest part.
    function _updateAccountState(AccountState storage state) internal {
        for (uint256 i = 0; i < state.vestFunds.length; i++) {
            Fund.VestFund storage fund = state.vestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (uint256 vesting, uint256 released) = Fund.getVestFund(fund, block.timestamp);
                if (released > 0) {
                    state.available = state.available.add(released);
                }
                fund.amount = vesting;
                if (vesting == 0) {
                    fund.active = false;
                }
            }
        }

        for (uint256 i = 0; i < state.evenVestFunds.length; i++) {
            Fund.EvenVestFund storage fund = state.evenVestFunds[i];
            if (fund.active) {
                // solhint-disable-next-line not-rely-on-time
                (uint256 vesting, uint256 released) = Fund.getEvenVestFund(fund, block.timestamp);
                if (released > 0) {
                    state.available = state.available.add(released);
                }
                fund.amount = vesting;
                if (vesting > 0) {
                    // solhint-disable-next-line not-rely-on-time
                    fund.start = block.timestamp.toUint64();
                } else {
                    fund.active = false;
                }
            }
        }
    }

    /// @dev add amount directly to user available.
    function _mint(AccountState storage state, uint256 amount) internal {
        state.available = state.available.add(amount);
    }

    /// @dev push the specified vest fund into user account state.
    function _mintVestFund(
        AccountState storage state,
        Fund.OwnerType ownerType,
        uint256 amount,
        uint256 deadline
    ) internal {
        // solhint-disable-next-line not-rely-on-time
        require(deadline > block.timestamp, "ERC20: Deadline is invalid");
        state.vestFunds.push(Fund.VestFund({
            active: true,
            ownerType: ownerType,
            amount: amount,
            deadline: deadline.toUint64()
        }));
    }

    /// @dev push the specified even vest fund into user account state.
    function _mintEvenVestFund(
        AccountState storage state,
        Fund.OwnerType ownerType,
        uint256 amount,
        uint256 start,
        uint256 end
    ) internal {
        // solhint-disable-next-line not-rely-on-time
        require(start > block.timestamp, "ERC20: Start time is invalid");
        require(end > start, "ERC20: End time is invalid");
        state.evenVestFunds.push(Fund.EvenVestFund({
            active: true,
            ownerType: ownerType,
            amount: amount,
            start: start.toUint64(),
            end: end.toUint64()
        }));
    }

    /// @dev transfer {amount} from {_from} to {_to}.
    /// @notice update account state firstly.
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: To address is zero");

        AccountState storage fromState = accounts[from];
        _updateAccountState(fromState);
        require(fromState.available >= amount, "ERC20: Insufficient balance");
        fromState.available = fromState.available.sub(amount);

        AccountState storage toState = accounts[to];
        toState.available = toState.available.add(amount);

        emit Transfer(from, to, amount);
    }

    /// @dev approve {amount} of {spender} from {owner}
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(spender != address(0), "ERC20: Spender address is zero");

        _allowances[_owner][spender] = amount;
        
        emit Approval(_owner, spender, amount);
    }

    /// @dev burn {amount} of {applicant}, and reduce _totalSupply.
    function _burn(address applicant, uint256 amount) internal {
        AccountState storage state = accounts[applicant];
        _updateAccountState(state);

        require(state.available >= amount, "ERC20: Insufficient balance");
        state.available = state.available.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(applicant, amount);
    }

    /// @dev burn {amount} of {from} allowance for {applicant}, and reduce _totalSupply.
    function _burnFrom(address applicant, address from, uint256 amount) internal {
        uint256 _allowance = allowance(from, applicant);
        require(amount <= _allowance, "ERC20: Insufficient allowance");
        _allowances[from][applicant] = _allowance.sub(amount);
        
        AccountState storage state = accounts[from];
        _updateAccountState(state);

        require(state.available >= amount, "ERC20: Insufficient balance");
        state.available = state.available.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit BurnFrom(applicant, from, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library CheckSig {
    /// @dev Check {from} has signed a hashed message {digest} with signature {v, r, s}.
    function checkSignature(address from, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal view {
        if (from.code.length > 0) {
            // from is a contract
            (bool success, bytes memory result) = from.staticcall(
                abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, abi.encodePacked(r, s, v))
            );
            require(
                success && result.length == 32 && abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector),
                "ERC1271: Unauthorized"
            );
        } else {
            require(ECDSA.recover(digest, v, r, s) == from, "CheckSig: Unauthorized");
        }
    }

    /// @dev Check {from} has signed a hashed message {digest} with signature {sig}.
    function checkSignature(address from, bytes32 digest, bytes memory sig) internal view {
        if (from.code.length > 0) {
            // from is a contract
            (bool success, bytes memory result) = from.staticcall(
                abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, sig)
            );
            require(
                success && result.length == 32 && abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector),
                "ERC1271: Unauthorized"
            );
        } else {
            require(ECDSA.recover(digest, sig) == from, "CheckSig: Unauthorized");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: Unlicense
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
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Fund {
    using SafeMath for uint256;

    enum OwnerType {
        Partner,
        Team
    }

    /// @dev Vest fund means token will lock for a fixed period, 
    struct VestFund {
        bool            active;
        OwnerType       ownerType;
        uint64          deadline;
        uint256         amount;
    }

    /// @dev Even Vest Fund means token will unlock evenly from start block to end block. 
    struct EvenVestFund {
        bool            active;
        OwnerType       ownerType;
        uint64          start;
        uint64          end;
        uint256         amount;
    }

    /// @dev compute (vesting, vested) amount of VestFund.
    function getVestFund(VestFund storage fund, uint256 timestamp) internal view returns (uint256, uint256) {
        require(fund.active, "Vest fund is not active");

        if (timestamp >= fund.deadline) {
            return (0, fund.amount);
        } else {
            return (fund.amount, 0);
        }
    }

    /// @dev compute (vesting, vested) amount of EvenVestFund.
    function getEvenVestFund(EvenVestFund storage fund, uint256 timestamp) internal view returns (uint256, uint256) {
        require(fund.active, "Even vest fund is not active");

        if (timestamp <= fund.start) {
            return (fund.amount, 0);
        } else if (timestamp > fund.start && timestamp < fund.end) {
            uint256 vesting = fund.amount.mul(fund.end - timestamp).div(fund.end - fund.start);
            return (vesting, fund.amount.sub(vesting));
        } else {
            return (0, fund.amount);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Implement access control of Hashkey.
abstract contract Access is Ownable {
    mapping(bytes32 => mapping(address => bool)) private _roleMembers;

    event SetupRole(bytes32 role, bool enable, address indexed account);

    modifier accessible(bytes32 role) {
        require(
            owner() == msg.sender || hasRole(role, msg.sender),
            "Access: caller has no access"
        );
        _;
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roleMembers[role][account];
    }

    /// @dev
    function setupRole(bytes32 role, bool enable, address account) external onlyOwner {
        require(account != address(0), "Access: account is zero address");
        _roleMembers[role][account] = enable;
        
        emit SetupRole(role, enable, account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}