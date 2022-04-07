/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: src/IPayroll.sol

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPayroll {
    event PaymentReceived(address indexed sender, uint256 amount);
    event PaymentTokensReceived(
        address indexed sender,
        address token,
        uint256 amount
    );
    event PaymentReleased(address indexed sender, uint256 amount);
    event PaymentTokensReleased(
        address indexed sender,
        address token,
        uint256 amount
    );

    function receivePayment() external payable;

    function receivePayment(IERC20 token, uint256 amount) external;

    function releasePayment(uint256 amount) external payable;

    function releasePayment(IERC20 token, uint256 amount) external;
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Strings.sol";

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


// Root file: src/payroll.sol

pragma solidity ^0.8.0;

// import "src/IPayroll.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payroll is IPayroll, Context {
    event DepartmentAdded(
        bytes32 name,
        address head,
        uint256 shares,
        bytes32 reason
    );
    event DepartmentRemoved(bytes32 name, bytes32 reason);
    event DepartmentTransferred(bytes32 departmentName, address newHead);
    event DepartmentSharesUpdated(
        bytes32 departmentName,
        int256 changeInShares,
        bytes32 reason
    );
    struct Department {
        bytes32 name;
        address head;
        uint256 shares;
        uint256 position;
    }
    address public constant NATIVE = 0x0000000000000000000000000000000000000001;
    uint8 constant maxDeparments = 10;

    bytes32[] departmentNames;

    mapping(bytes32 => Department) public departments;
    mapping(bytes32 => mapping(address => uint256)) balances;
    mapping(bytes32 => mapping(address => uint256)) released;
    mapping(address => bytes32) departmentHead;
    mapping(bytes => bool) signatureRegister;

    uint256 totalShares = 0;

    modifier onlyDepartmentHead() {
        require(
            departmentHead[_msgSender()] != 0,
            "Not Authorized: Only for department head"
        );
        _;
    }

    constructor(
        bytes32[] memory _departmentNames,
        address[] memory _departmentHeads,
        uint256[] memory _departmentShares
    ) {
        require(_departmentNames.length > 0, "Atleast have one department");
        require(
            _departmentNames.length <= maxDeparments,
            "Too many initial departments"
        );
        require(
            _departmentNames.length == _departmentHeads.length,
            "Deparment names and heads mismatch"
        );
        require(
            _departmentNames.length == _departmentShares.length,
            "Deparment names and shares mismatch"
        );
        uint8 i = 0;
        for (i = 0; i < _departmentNames.length; i++) {
            _addDepartment(
                _departmentNames[i],
                _departmentHeads[i],
                _departmentShares[i]
            );
        }
    }

    function getAllDepartmentNames() public view returns (bytes32[] memory) {
        return departmentNames;
    }

    function addDepartment(
        bytes32 _name,
        address _head,
        uint256 _shares,
        bytes32 _reason,
        bytes memory data,
        bytes[] calldata _signatures
    ) public onlyDepartmentHead {
        require(
            _signatures.length == departmentNames.length,
            "Signatures mismatch"
        );

        _validateSignatures(data, _signatures);

        (
            bytes32 dDeptName,
            address dHead,
            uint256 dShares,
            bytes32 dReason
        ) = abi.decode(data, (bytes32, address, uint256, bytes32));

        require(dDeptName == _name, "Name mismatch");
        require(dHead == _head, "Head mismatch");
        require(dShares == _shares, "Shares mismatch");
        require(dReason == _reason, "Reason mismatch");

        _addDepartment(_name, _head, _shares);
        emit DepartmentAdded(_name, _head, _shares, _reason);
    }

    function removeDepartment(
        bytes32 _departmentName,
        bytes32 _reason,
        address[] memory _tokenAddresses,
        bytes memory data,
        bytes[] calldata _signatures
    ) public onlyDepartmentHead {
        require(departmentNames.length > 1, "Cannot remove last department");
        require(
            _signatures.length == departmentNames.length - 1,
            "Signatures mismatch"
        );

        (bytes32 dDeptName, bytes32 dReason) = abi.decode(
            data,
            (bytes32, bytes32)
        );

        require(dDeptName == _departmentName, "Name mismatch");
        require(dReason == _reason, "Reason mismatch");

        _validateSignatures(data, _signatures);

        Department memory department = departments[_departmentName];
        require(department.head != address(0), "Department not found");

        bytes32 lastDepartmentName = departmentNames[
            departmentNames.length - 1
        ];

        departments[lastDepartmentName].position = department.position;
        departmentNames[department.position] = lastDepartmentName;
        departmentNames.pop();

        uint256 distributedShares = department.shares /
            (departmentNames.length);

        for (uint8 i = 0; i < departmentNames.length; i++) {
            departments[departmentNames[i]].shares += distributedShares;
        }
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            uint256 tokenBalance = this.balanceOf(
                _departmentName,
                IERC20(_tokenAddresses[i])
            );
            _distributeTokens(_tokenAddresses[i], tokenBalance);
            delete balances[_departmentName][_tokenAddresses[i]];
            delete released[_departmentName][_tokenAddresses[i]];
        }
        delete departmentHead[department.head];
        delete departments[department.name];
        emit DepartmentRemoved(_departmentName, _reason);
    }

    function balanceOf(bytes32 _departmentName) public view returns (uint256) {
        return
            balances[_departmentName][NATIVE] -
            released[_departmentName][NATIVE];
    }

    function balanceOf(bytes32 _departmentName, IERC20 token)
        public
        view
        returns (uint256)
    {
        return
            balances[_departmentName][address(token)] -
            released[_departmentName][address(token)];
    }

    function releasedOf(bytes32 _departmentName) public view returns (uint256) {
        return released[_departmentName][NATIVE];
    }

    function releasedOf(bytes32 _departmentName, IERC20 token)
        public
        view
        returns (uint256)
    {
        return released[_departmentName][address(token)];
    }

    function receivePayment() external payable override {
        require(msg.value > 0, "Payment must be greater than 0");
        _distributeTokens(NATIVE, msg.value);
        emit PaymentReceived(msg.sender, msg.value);
    }

    function receivePayment(IERC20 token, uint256 amount) external override {
        require(amount > 0, "Payment must be greater than 0");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        _distributeTokens(address(token), amount);
        emit PaymentTokensReceived(msg.sender, address(token), amount);
    }

    function releasePayment(uint256 amount)
        external
        payable
        override
        onlyDepartmentHead
    {
        require(amount > 0, "Amount must be greater than 0");
        bytes32 departmentName = departmentHead[_msgSender()];
        require(
            amount <= balanceOf(departmentName),
            "Amount must be less than or equal to balance"
        );
        released[departmentName][NATIVE] += amount;
        payable(_msgSender()).transfer(amount);
        emit PaymentReleased(_msgSender(), amount);
    }

    function releasePayment(IERC20 token, uint256 amount)
        external
        override
        onlyDepartmentHead
    {
        require(amount > 0, "Amount must be greater than 0");
        bytes32 departmentName = departmentHead[_msgSender()];
        require(
            amount <= balanceOf(departmentName, token),
            "Amount must be less than or equal to balance"
        );
        released[departmentName][address(token)] += amount;
        bool transferSuccess = token.transfer(_msgSender(), amount);
        require(transferSuccess, "Transfer failed");
        emit PaymentTokensReleased(_msgSender(), address(token), amount);
    }

    function transferOwnership(bytes32 _departmentName, address newHead)
        public
        onlyDepartmentHead
    {
        require(newHead != address(0), "New owner cannot be 0");
        require(newHead != _msgSender(), "New owner cannot be sender");
        require(
            departments[_departmentName].head != address(0),
            "Department does not exists"
        );
        require(
            departments[_departmentName].head == _msgSender(),
            "Sender is not head of the department"
        );
        require(
            departmentHead[newHead] == 0,
            "New head is already a department head"
        );

        departmentHead[newHead] = _departmentName;
        departments[_departmentName].head = newHead;
        delete departmentHead[_msgSender()];

        emit DepartmentTransferred(_departmentName, newHead);
    }

    function updateShares(
        bytes32 _departmentName,
        int256 _changeInShares,
        bytes32 _reason,
        bytes memory _data,
        bytes[] calldata _signatures
    ) public onlyDepartmentHead {
        require(_changeInShares != 0, "Change must not be zero");
        require(
            departments[_departmentName].head != address(0),
            "Department does not exists"
        );
        require(
            departments[_departmentName].head == _msgSender(),
            "Sender is not head of the department"
        );
        require(
            _signatures.length == departmentNames.length - 1,
            "Signatures mismatch"
        );

        _validateSignatures(_data, _signatures);

        (bytes32 dDeptName, int256 dChangeInShares, bytes32 dReason) = abi
            .decode(_data, (bytes32, int256, bytes32));

        require(dDeptName == _departmentName, "Name mismatch");
        require(dChangeInShares == _changeInShares, "Change mismatch");
        require(dReason == _reason, "Reason mismatch");

        departments[_departmentName].shares = uint256(
            int256(departments[_departmentName].shares) + _changeInShares
        );
        emit DepartmentSharesUpdated(_departmentName, _changeInShares, _reason);
    }

    function _distributeTokens(address _token, uint256 _amount) internal {
        for (uint8 i = 0; i < departmentNames.length; i++) {
            Department memory department = departments[departmentNames[i]];
            uint256 addedAmount = (_amount * department.shares) / totalShares;
            balances[departmentNames[i]][_token] += addedAmount;
        }
    }

    function _validateSignatures(bytes memory data, bytes[] memory signatures)
        internal
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(data));
        for (uint8 i = 0; i < signatures.length; i++) {
            require(
                signatureRegister[signatures[i]] == false,
                "Signature already registered"
            );
            address signer = ECDSA.recover(hash, signatures[i]);
            require(departmentHead[signer] != 0, "Invalid Signature");
            signatureRegister[signatures[i]] = true;
        }
    }

    function _addDepartment(
        bytes32 _name,
        address _head,
        uint256 _shares
    ) internal {
        require(
            departmentNames.length < maxDeparments - 1,
            "Too many departments"
        );
        require(
            departments[_name].head == address(0),
            "Department already exists"
        );
        require(departmentHead[_head] == 0, "Head already exists");
        require(_shares > 0, "Department shares must be greater than 0");
        require(
            _name != "" || _name.length > 0,
            "Department name cannot be empty"
        );

        departments[_name] = Department({
            name: _name,
            head: _head,
            shares: _shares,
            position: departmentNames.length
        });
        departmentNames.push(_name);
        departmentHead[_head] = _name;
        totalShares += _shares;
    }
}