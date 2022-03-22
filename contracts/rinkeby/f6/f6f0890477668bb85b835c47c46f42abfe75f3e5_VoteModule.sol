/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/IFractionsCore.sol


pragma solidity 0.8.9;

interface IFractionsCore
{
	function __transfer(address _from, address _to, uint256 _amount) external;
	function __mint(address _to, uint256 _amount) external;
	function __burn(address _from, uint256 _amount) external;
	function __approve(address _owner, address _spender, uint256 _amount) external;
	function __pause() external;
	function __unpause() external;
	function __snapshot() external returns (uint256 _snapshotId);
	function __delegate(address _delegator, address _delegatee) external;
	function __addContext(address _context) external;
	function __removeContext(address _context) external;
	function __scheduleAction(bytes32 _actionId, uint256 _available) external;
	function __unscheduleAction(bytes32 _actionId) external;
	function __executeAction(address _module, uint256 _value, bytes calldata _calldata, uint256 _deadline) external returns (bytes memory _returndata);
	function __invalidateAction(bytes32 _actionId) external;
	function __externalCall(address _target, uint256 _value, bytes calldata _calldata) external returns (bytes memory _returndata);
}


// File contracts/IFractions.sol


pragma solidity 0.8.9;


interface IFractions is IERC20Metadata, IERC165, IFractionsCore
{
	function calcActionId(address _module, uint256 _value, bytes calldata _calldata, uint256 _deadline) external view returns (bytes32 _actionId);

	function paused() external view returns (bool _paused);

	function balanceOfAt(address _account, uint256 _snapshotId) external view returns (uint256 _balance);
	function totalSupplyAt(uint256 _snapshotId) external view returns (uint256 _totalSupply);

	function delegates(address _account) external view returns (address _delegates);
	function getVotes(address _account) external view returns (uint256 _votes);
	function delegate(address _newDelegate) external;
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/Module.sol


pragma solidity 0.8.9;

abstract contract Module is ReentrancyGuard
{
	mapping(address => bool) public installed;

	modifier notInstalled
	{
		require(!installed[msg.sender], "already installed");
		_;
	}

	modifier onlyInstalled
	{
		require(installed[msg.sender], "not installed");
		_;
	}

	modifier installedOn(address payable _fractions)
	{
		require(installed[_fractions], "not installed");
		_;
	}

	function action_install() external notInstalled
	{
		IFractions(msg.sender).__addContext(address(this));
		installed[msg.sender] = true;
		_init();
		emit ModuleInstalled(msg.sender);
	}

	function action_uninstall() external onlyInstalled
	{
		IFractions(msg.sender).__removeContext(address(this));
		installed[msg.sender] = false;
		_done();
		emit ModuleUninstalled(msg.sender);
	}

	function _init() internal virtual {}
	function _done() internal virtual {}

	event ModuleInstalled(address indexed _fractions);
	event ModuleUninstalled(address indexed _fractions);
}


// File contracts/modules/VoteModule.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;


contract VoteModule is Module
{
	using ECDSA for bytes32;

	struct Data {
		uint256 delay;
		uint256 quorum;
		uint256 abstention;
		mapping (bytes32 => uint256) votes;
		mapping (address => uint256) timestamp;
	}

	address public constant ABSTINENT = address(type(uint160).max);

	uint256 constant DEFAULT_DELAY = 48 hours;
	uint256 constant DEFAULT_QUORUM = 90e16; // 90%
	uint256 constant DEFAULT_ABSTENTION = 30 days;

	mapping (address => Data) public data;

	function _init() internal override
	{
		Data storage _data = data[msg.sender];
		_data.delay = DEFAULT_DELAY;
		_data.quorum = DEFAULT_QUORUM;
		_data.abstention = DEFAULT_ABSTENTION;
		_data.timestamp[address(0)] = block.timestamp;
	}

	function _done() internal override
	{
		Data storage _data = data[msg.sender];
		_data.delay = 0;
		_data.quorum = 0;
		_data.abstention = 0;
		_data.timestamp[address(0)] = 0;
	}

	// ----- BEGIN: actions

	function action_setDelay(uint256 _newDelay) external onlyInstalled
	{
		Data storage _data = data[msg.sender];
		require(_newDelay <= 1 weeks, "invalid delay");
		uint256 _oldDelay = _data.delay;
		_data.delay = _newDelay;
		emit DelayChanged(msg.sender, _oldDelay, _newDelay);
	}

	function action_setQuorum(uint256 _newQuorum) external onlyInstalled
	{
		Data storage _data = data[msg.sender];
		require(_newQuorum <= 100e16, "invalid quorum");
		uint256 _oldQuorum = _data.quorum;
		_data.quorum = _newQuorum;
		emit QuorumChanged(msg.sender, _oldQuorum, _newQuorum);
	}

	function action_setAbstention(uint256 _newAbstention) external onlyInstalled
	{
		Data storage _data = data[msg.sender];
		require(_newAbstention >= 7 days, "invalid abstention");
		uint256 _oldAbstention = _data.abstention;
		_data.abstention = _newAbstention;
		emit AbstentionChanged(msg.sender, _oldAbstention, _newAbstention);
	}

	// ----- END: actions

	function calcBallotId(bytes32 _actionId, uint256 _ballot) public pure returns (bytes32 _ballotId)
	{
		return keccak256(abi.encodePacked(_actionId, _ballot));
	}

	function recoverSigner_(bytes32 _ballorId, bytes memory _signature) private pure returns (address _signer)
	{
		return _ballorId.toEthSignedMessageHash().recover(_signature);
	}

	function alive(address payable _fractions) external installedOn(_fractions)
	{
		Data storage _data = data[_fractions];
		_data.timestamp[msg.sender] = block.timestamp;
		emit DelegateAlive(_fractions, msg.sender);
	}

	function abstain(address payable _fractions) external installedOn(_fractions)
	{
		IFractions(_fractions).__delegate(msg.sender, ABSTINENT);
	}

	function abstain(address payable _fractions, address[] calldata _accounts) external installedOn(_fractions)
	{
		Data storage _data = data[_fractions];
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			uint256 _timestamp = _data.timestamp[IFractions(_fractions).delegates(_account)];
			require(_timestamp + _data.abstention < block.timestamp, "active account");
			IFractions(_fractions).__delegate(_account, ABSTINENT);
		}
	}

	function voteAction(address payable _fractions, bytes32 _actionId, bytes[] memory _signatures, uint256[] memory _ballots) external installedOn(_fractions)
	{
		Data storage _data = data[_fractions];
		uint256 _noVotes = 0;
		uint256 _yesVotes = 0;
		uint256 _totalVotes = IFractions(_fractions).getVotes(ABSTINENT);
		address _previous = address(0);
		for (uint256 _i = 0; _i < _signatures.length; _i++) {
			bytes memory _signature = _signatures[_i];
			uint256 _ballot = _ballots[_i];
			require(_ballot <= 2, "invalid ballot");
			address _account = recoverSigner_(calcBallotId(_actionId, _ballot), _signature);
			require(uint160(_account) > uint160(_previous), "invalid ordering");
			uint256 _votes = IFractions(_fractions).getVotes(_account);
			unchecked {
				if (_ballot == 1) _noVotes += _votes;
				else
				if (_ballot == 0) _yesVotes += _votes;
				_totalVotes += _votes;
			}
			_data.timestamp[_account] = block.timestamp;
			emit DelegateAlive(_fractions, _account);
			_previous = _account;
		}
		uint256 _attendance = 0;
		unchecked {
			uint256 _totalSupply = IFractions(_fractions).totalSupply();
			if (_totalSupply > 0) {
				_attendance = _totalVotes * 100e16 / _totalSupply;
			}
		}
		uint256 _quorum = _data.quorum;
		require(_attendance >= _quorum, "no quorum");
		require(_totalVotes > _data.votes[_actionId], "insufficient votes");
		_data.votes[_actionId] = _totalVotes;
		emit VoteAction(_fractions, _actionId, _signatures, _ballots, _attendance, _quorum);
		if (_yesVotes > _noVotes) {
			IFractions(_fractions).__scheduleAction(_actionId, block.timestamp + _data.delay);
		} else {
			IFractions(_fractions).__unscheduleAction(_actionId);
		}
	}

	event DelayChanged(address indexed _fractions, uint256 _oldDelay, uint256 _newDelay);
	event QuorumChanged(address indexed _fractions, uint256 _oldQuorum, uint256 _newQuorum);
	event AbstentionChanged(address indexed _fractions, uint256 _oldAbstention, uint256 _newAbstention);
	event DelegateAlive(address indexed _fractions, address indexed _delegate);
	event VoteAction(address indexed _fractions, bytes32 indexed _actionId, bytes[] _signatures, uint256[] _ballots, uint256 _attendance, uint256 _quorum);
}