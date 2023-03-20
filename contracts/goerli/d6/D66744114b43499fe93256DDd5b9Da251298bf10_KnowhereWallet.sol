// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Strings.sol";

library ECDSA {
	enum RecoverError {
		NoError,
		InvalidSignature,
		InvalidSignatureLength,
		InvalidSignatureS,
		InvalidSignatureV // Deprecated in v4.8
	}

	function _throwError(RecoverError error) private pure {
		if (error == RecoverError.NoError) {
			return;
		} else if (error == RecoverError.InvalidSignature) {
			revert("ECDSA: invalid signature");
		} else if (error == RecoverError.InvalidSignatureLength) {
			revert("ECDSA: invalid signature length");
		} else if (error == RecoverError.InvalidSignatureS) {
			revert("ECDSA: invalid signature 's' value");
		}
	}

	function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
		if (signature.length == 65) {
			bytes32 r;
			bytes32 s;
			uint8 v;

			assembly {
				r := mload(add(signature, 0x20))
				s := mload(add(signature, 0x40))
				v := byte(0, mload(add(signature, 0x60)))
			}
			return tryRecover(hash, v, r, s);
		} else {
			return (address(0), RecoverError.InvalidSignatureLength);
		}
	}

	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
		(address recovered, RecoverError error) = tryRecover(hash, signature);
		_throwError(error);
		return recovered;
	}

	function tryRecover(
		bytes32 hash,
		bytes32 r,
		bytes32 vs
	) internal pure returns (address, RecoverError) {
		bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
		uint8 v = uint8((uint256(vs) >> 255) + 27);
		return tryRecover(hash, v, r, s);
	}

	function recover(
		bytes32 hash,
		bytes32 r,
		bytes32 vs
	) internal pure returns (address) {
		(address recovered, RecoverError error) = tryRecover(hash, r, vs);
		_throwError(error);
		return recovered;
	}

	function tryRecover(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (address, RecoverError) {
		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
			return (address(0), RecoverError.InvalidSignatureS);
		}

		address signer = ecrecover(hash, v, r, s);
		if (signer == address(0)) {
			return (address(0), RecoverError.InvalidSignature);
		}

		return (signer, RecoverError.NoError);
	}

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

	function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
	}

	function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
	}

	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Math {
	enum Rounding {
		Down, // Toward negative infinity
		Up, // Toward infinity
		Zero // Toward zero
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return (a & b) + (a ^ b) / 2;
	}

	function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		return a == 0 ? 0 : (a - 1) / b + 1;
	}

	function mulDiv(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			uint256 prod0;
			uint256 prod1;
			assembly {
				let mm := mulmod(x, y, not(0))
				prod0 := mul(x, y)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			if (prod1 == 0) {
				return prod0 / denominator;
			}

			require(denominator > prod1);

			uint256 remainder;
			assembly {
				remainder := mulmod(x, y, denominator)

				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			uint256 twos = denominator & (~denominator + 1);
			assembly {
				denominator := div(denominator, twos)

				prod0 := div(prod0, twos)

				twos := add(div(sub(0, twos), twos), 1)
			}

			prod0 |= prod1 * twos;

			uint256 inverse = (3 * denominator) ^ 2;

			inverse *= 2 - denominator * inverse; // inverse mod 2^8
			inverse *= 2 - denominator * inverse; // inverse mod 2^16
			inverse *= 2 - denominator * inverse; // inverse mod 2^32
			inverse *= 2 - denominator * inverse; // inverse mod 2^64
			inverse *= 2 - denominator * inverse; // inverse mod 2^128
			inverse *= 2 - denominator * inverse; // inverse mod 2^256

			result = prod0 * inverse;
			return result;
		}
	}

	function mulDiv(
		uint256 x,
		uint256 y,
		uint256 denominator,
		Rounding rounding
	) internal pure returns (uint256) {
		uint256 result = mulDiv(x, y, denominator);
		if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
			result += 1;
		}
		return result;
	}

	function sqrt(uint256 a) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 result = 1 << (log2(a) >> 1);
		unchecked {
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			return min(result, a / result);
		}
	}

	function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = sqrt(a);
			return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
		}
	}

	function log2(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 128;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 64;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 32;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 16;
			}
			if (value >> 8 > 0) {
				value >>= 8;
				result += 8;
			}
			if (value >> 4 > 0) {
				value >>= 4;
				result += 4;
			}
			if (value >> 2 > 0) {
				value >>= 2;
				result += 2;
			}
			if (value >> 1 > 0) {
				result += 1;
			}
		}
		return result;
	}

	function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log2(value);
			return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
		}
	}

	function log10(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >= 10**64) {
				value /= 10**64;
				result += 64;
			}
			if (value >= 10**32) {
				value /= 10**32;
				result += 32;
			}
			if (value >= 10**16) {
				value /= 10**16;
				result += 16;
			}
			if (value >= 10**8) {
				value /= 10**8;
				result += 8;
			}
			if (value >= 10**4) {
				value /= 10**4;
				result += 4;
			}
			if (value >= 10**2) {
				value /= 10**2;
				result += 2;
			}
			if (value >= 10**1) {
				result += 1;
			}
		}
		return result;
	}

	function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log10(value);
			return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
		}
	}

	function log256(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 16;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 8;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 4;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 2;
			}
			if (value >> 8 > 0) {
				result += 1;
			}
		}
		return result;
	}

	function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log256(value);
			return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ECDSA.sol";

library SignatureCheck {
	function verify(
		address signer,
		bytes32 hash,
		bytes memory signature
	) internal pure returns (bool) {
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
		if (error == ECDSA.RecoverError.NoError && recovered == signer) {
			return true;
		}
		return false;
	}

	function getMessageHash(
		address _account,
		uint256 _amount,
		uint256 _expired,
		string calldata _serial
	) internal pure returns (bytes32) {
		bytes32 _msgHash = keccak256(abi.encodePacked(_account, _amount, _expired, _serial));
		return ECDSA.toEthSignedMessageHash(_msgHash);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Math.sol";

library Strings {
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

	function toString(uint256 value) internal pure returns (string memory) {
		unchecked {
			uint256 length = Math.log10(value) + 1;
			string memory buffer = new string(length);
			uint256 ptr;
			assembly {
				ptr := add(buffer, add(32, length))
			}
			while (true) {
				ptr--;
				assembly {
					mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
				}
				value /= 10;
				if (value == 0) break;
			}
			return buffer;
		}
	}

	function toHexString(uint256 value) internal pure returns (string memory) {
		unchecked {
			return toHexString(value, Math.log256(value) + 1);
		}
	}

	function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}

	function toHexString(address addr) internal pure returns (string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./check/SignatureCheck.sol";
import "./ReentrancyGuard.sol";

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract KnowhereWallet is ReentrancyGuard {
	address public immutable admin;
	address public receiver;
	IERC20 public usdtToken;
	address constant signer = 0x9add88207AC0Db396d6050716BADB7eC6C96bA33;

	event RechargeWallet(address indexed account, uint256 amount, uint256 balance);

	event RechargeId(uint256 indexed id, uint256 amount, uint256 balance);

	event WithdrawNotice(address indexed account, uint256 amount, uint256 balance);

	error TransferFailed(string err);
	error WithdrawFailed(string err);

	mapping(bytes32 => bool) private transferHistory;

	uint public _lastTime;
	uint public _dailyMaxBalance = 100000000;
	uint public _dailyBalance;

	constructor(address _wallet, IERC20 _usdt) {
		admin = msg.sender;
		receiver = _wallet;
		usdtToken = IERC20(_usdt);
	}

	modifier onlyOwner() {
		require(msg.sender == admin, "Not admin");
		_;
	}

	function transderToWallet(address account, uint256 amount) external {
		_deposit(amount);
		emit RechargeWallet(account, amount, balance());
	}

	function transderToId(uint256 id, uint256 amount) external {
		require(id > 0, "id invalid");
		_deposit(amount);
		emit RechargeId(id, amount, balance());
	}

	function _deposit(uint256 amount) internal {
		require(amount > 0, "Amount must be greater than 0");
		require(_tokenBalance(msg.sender) > amount, "Balance must be greater than amount");
		if (!usdtToken.transferFrom(msg.sender, address(this), amount)) {
			revert TransferFailed("USDT deposit failed");
		}
	}

	function withdraw(address dest, uint256 amount, uint256 expired, string calldata serial, bytes memory _signature) external onlyOwner nonReentrant {
		require(dest != address(0), "Withdraw to the zero address");
		require(amount > 0 && amount <= getDailyBalance(), "Amount must be greater than 0 and less than 100 usdt");
		require(expired > block.timestamp && expired < block.timestamp + 300, "Transaction Expired");
		bytes32 _msgHash = SignatureCheck.getMessageHash(dest, amount, expired, serial);
		require(!transferHistory[_msgHash], "Transaction completed");
		transferHistory[_msgHash] = true;
		if (!SignatureCheck.verify(signer, _msgHash, _signature)) {
			revert WithdrawFailed("Invalid signature");
		}
		require(balance() >= amount, "Insufficient balance");
		if (!usdtToken.transfer(dest, amount)) {
			revert WithdrawFailed("USDT transfer failed");
		}
		_dailyBalance = _dailyBalance - amount;
		emit WithdrawNotice(dest, amount, balance());
	}

	function withdrawAll(uint256 amount) public onlyOwner {
		require(amount < balance(), "Excess balance");
		usdtToken.transfer(receiver, amount);
	}

	function updateReceiver(address _receiver) external onlyOwner {
		receiver = _receiver;
	}

	function _tokenBalance(address account) internal view returns (uint256) {
		return usdtToken.balanceOf(account);
	}

	function balance() public view returns (uint256) {
		return usdtToken.balanceOf(address(this));
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return usdtToken.allowance(owner, spender);
	}

	function updateDailyMaxBalance(uint256 dailyMaxBalance_) external onlyOwner {
		_dailyMaxBalance = dailyMaxBalance_;
	}

	function getDailyBalance() public returns (uint256 dailyBalance_) {
		if (block.timestamp - _lastTime > 1 days) {
			_lastTime = block.timestamp;
			_dailyBalance = _dailyMaxBalance;
		}
		return _dailyBalance;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

abstract contract ReentrancyGuard {
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {
		_nonReentrantBefore();
		_;
		_nonReentrantAfter();
	}

	function _nonReentrantBefore() private {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		_status = _ENTERED;
	}

	function _nonReentrantAfter() private {
		_status = _NOT_ENTERED;
	}
}