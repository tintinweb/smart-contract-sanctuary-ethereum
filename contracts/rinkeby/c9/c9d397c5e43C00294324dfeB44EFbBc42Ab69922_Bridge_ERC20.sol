//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Bridge_ERC20 {
    using ECDSA for bytes32;
    address owner;
    address bridge;
    uint256 public chainId;
    address public ERC20Token;
    mapping (bytes32 => status) swaps;
    enum status { EMPTY, SWAPED, REDEEMED }
    

    constructor(address _ERC20Address, uint256 _chainId) {
        owner = msg.sender;
        ERC20Token = _ERC20Address;
        chainId = _chainId;
    }

    event swapInitialized(uint256 _amount, address _owner, uint256 _chainIDfrom, uint256 _chainIDto);
    event tokenRedeemed(uint256 _amount, address _owner, uint256 _chainIDfrom, uint256 _chainIDto);

    function swap(
        uint256 _amount, 
        uint256 _chainIdTo, 
        uint256 _nonce
    ) external {
        require(Standart_ERC20(ERC20Token).balanceOf(msg.sender) >= _amount, "User does not have enough tokens"); 
        bytes32 dataHash = keccak256(
            abi.encodePacked(_amount, msg.sender, _nonce, chainId, _chainIdTo)
        );
        swaps[dataHash] = status.SWAPED;
        Standart_ERC20(ERC20Token).burn(msg.sender, _amount);
        emit swapInitialized(_amount, msg.sender, chainId, _chainIdTo);
    }

    function redeem(
        uint256 _amount,
        address _owner, 
        uint256 _chainIdFrom, 
        uint256 _nonce,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) external {
        require(msg.sender == bridge, "Caller is not owner of bridge");

        bytes32 dataHash = keccak256(
            abi.encodePacked(_amount, _owner, _nonce, _chainIdFrom, chainId)
        );
        address signer = ECDSA.recover(dataHash.toEthSignedMessageHash(), _v, _r, _s);
        require(signer == msg.sender, "Signature is wrong");
        require(swaps[dataHash] != status.REDEEMED, "Already Redeemed");
        swaps[dataHash] = status.REDEEMED;
        Standart_ERC20(ERC20Token).mint(_owner, _amount);
    }

    function setChairePerson(address _newChairPerson) public {
        require(msg.sender == owner, "Caller is not owner of bridge");
        bridge = _newChairPerson;
    }

    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/**  
* @title Standard but handmade contract by standard ERC20.
* @author Pavel E. Hrushchev (DrHPoint).
* @notice You can use this contract for standard token transactions.
* @dev All function calls are currently implemented without side effects. 
*/
contract Standart_ERC20 {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals; // = 18;
    uint256 private _totalSupply = 0;
    address public owner;
    address public bridge;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /** 
    * @notice This event shows from which (_from) and to which address (_to) a certain amount (_value) of tokens were transferred.
    * @dev Nothing unusual. Standard event with two addresses and the amount of tokens for which the transaction is made.
    * @param _from is the address from which the transaction is made.
    * @param _to is the address to which the transaction is made.
    * @param _value is the value by which the transaction is made.
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    /**  
    * @notice This event indicates that a user with one address (_owner) has entrusted a user with a different address (_spender) to use a certain number of tokens (_value).
    * @dev Nothing unusual. Standard event with two addresses and the amount of tokens with which action is allowed.
    * @param _owner is the address from which the approval was given to carry out transactions by proxy.
    * @param _spender is the address to which the approval was given to carry out transactions by proxy.
    * @param _value is the value by which the approval was given to carry out transactions by proxy.
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**  
    * @notice This event notifies about the transfer of ownership of the contract from the old address (_previousOwner) to the new address(_newOwner)
    * @dev Nothing unusual. Standard event with two addresses signifying the transfer of ownership to a contract
    * @param _previousOwner is the address of previous owner of that contract.
    * @param _newOwner is the address of new owner of that contract.
    */
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /** 
    *@dev Currently, the value of '_totalSupply' shown in the constructor, cannot be set. Set '_name', '_symbol' and '_decimals' value
    * @param Name is Name of Token.
    * @param Symbol is Symbol of Token.
    * @param Decimals is Decimals of the token (how many the whole token is being divided).
    */  
    constructor(string memory Name, string memory Symbol, uint8 Decimals) {
        owner = msg.sender;
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        mint(owner, 19632017 * 1e18);
    }

    ///@dev modifier to check for owner address
    modifier onlyForOwnerAndBridge () {
        require(((msg.sender == owner) || (msg.sender == bridge)), "Not owner or bridge");
        _;
   }  

    ///@dev modifier to check for owner address
    modifier onlyForOwner () {
        require(msg.sender == owner, "Not owner");
        _;
   }  

    /**  
    * @notice This function returns the name of the token.
    * @dev Returns the name of the token, which is hardcoded in the parameters of the contract.
    * @return _name - Name of Token.
    */
    function name() external view returns (string memory) {
        return _name;
    }

    /**  
    * @notice This function returns the symbol of the token.
    * @dev Returns the symbol of the token, which is hardcoded in the parameters of the contract.
    * @return _symbol - Symbol of Token.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**  
    * @notice This function shows how many the whole token is being divided.
    * @dev Returns the decimals of the token, which is hardcoded in the parameters of the contract.
    * @return _decimals - Decimals of the token (how many the whole token is being divided).
    */
    function decimals() external view returns (uint8){
        return _decimals;
    }

    /**  
    * @notice This function shows the sum of all balances.
    * @dev Standard function that returns the current amount of balances.
    * @return totalSupply - the sum of all balances.
    */
    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    /**  
    * @notice This function shows the balance of the address (_owner) you need to know.
    * @dev Standart view balance function without any complexity.
    * @param _owner - The address of the client whose balance you want to check.
    * @return balance - The client's token balance
    */
    function balanceOf(address _owner) external view returns (uint256 balance){
        return _balances[_owner];
    }

    /**  
    * @notice This function transfers a certain number of tokens (_value) from the address from which the user applies to another address specified in the parameters (_to).
    * @dev The function checks for a zero address, then for a sufficient number of tokens on the balance of the contacting user, after which it conducts a transfer and calls transaction event.
    * @param _to - The address of the user to whose balance the transfer is made.
    * @param _value - The value of tokens used in the transfer.
    * @return success - value "true" if the transfer was successful.
    */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= _value, "Not enough tokens");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /** 
    *  @notice This function transfers a certain number of tokens (_value) from the address from which the user wants to transfer tokens (_from) to another address specified in the parameters (_to).
    * @dev The function checks for a zero address, then for a sufficient number of tokens on the balance of another user, from which the contact's user wants to transfer tokens and whether it is allowed to him, after which it conducts a transfer, reduces the number of trusted tokens and calls transaction event.
    * @param _from - The address of the user from whose balance the transfer is made.
    * @param _to - The address of the user to whose balance the transfer is made.
    * @param _value - The value of tokens used in the transfer.
    * @return success - value "true" if the transfer was successful.
    */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success){
        require(_from != address(0), "Transfer from the zero address");
        require(_to != address(0), "Transfer to the zero address");
        require(_allowances[_from][msg.sender] >= _value, "Not enough allowed amount");
        require(_balances[_from] >= _value, "Not enough tokens");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**  
    * @notice This function allows the requesting user to entrust the management of a certain amount of tokens (_value) to a user with a different address (_spender).
    * @dev The function checks for the presence of a zero address, after which it assigns a power of attorney for the use of a certain number of tokens and calls approval event.
    * @param _spender - The address of the user who is allowed to use other user tokens.
    * @param _value - The value of tokens that the specified user is allowed to use.
    * @return success - value "true" if the approve was successful.
    */
    function approve(address _spender, uint256 _value) external returns (bool success){
        require(_spender != address(0), "Approve to the zero address");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**  
    * @notice This function allows you to find out how many tokens a user with one specified address (_owner) is trusted to use from the user's balance with another specified address (_spender).
    * @dev Nothing unusual. Returns the current trusted tokens.
    * @param _owner - The address of the user who trusts the use of their tokens.
    * @param _spender - The address of the user who is allowed to use other user tokens.
    * @return remaining - The current number of tokens trusted by one user to another user.
    */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining){
        return _allowances[_owner][_spender];
    }

    /** @notice This function allows you to burn a certain number of tokens from a specified address (_from).
    * @dev The function checks for the owner of the contract, for a zero address, for a sufficient number of tokens at a given user address and burns tokens from this address, together with a decrease totalSupply, after which it calls transaction event.
    * @param _from - User address from whose balance tokens are burned.
    * @param _value - The value of tokens to be burned.
    * @return success - value "true" if the burn of tokens was successful.
    */
    function burn(address _from, uint256 _value) public onlyForOwnerAndBridge returns (bool success){
        require(_from != address(0), "Burn from the zero address");
        require(_balances[_from] >= _value, "Not enough tokens");
        _balances[_from] -= _value;
        _totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /**  
    * @notice This function allows you to mint a certain number of tokens to a specified address (_to).
    * @dev The function checks for the owner of the contract, for a zero address and burns tokens from at a given user address, together with a decrease totalSupply, after which it calls transaction event.
    * @param _to - User address from whose balance tokens are minted.
    * @param _value - The value of tokens to be minted.
    * @return success - value "true" if the mint of tokens was successful.
    */
    function mint(address _to, uint256 _value) public onlyForOwnerAndBridge returns (bool success){
        require(_to != address(0), "Mint to the zero address");
        _balances[_to] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**  
    * @notice This function allows you to transfer ownership of a contract to a new owner(_newOwner).
    * @dev The function checks for the owner of the contract, for a zero address and transfer ownership of a contract to a new owner, after which it calls ownership transferred event.
    * @param _newOwner - User address from whose balance tokens are minted.
    */
    function transferOwnership(address _newOwner) public onlyForOwner {
        require(_newOwner != address(0), "New owner have the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**  
    * @notice This function allows you to set a new bridge address(_newBridge).
    * @dev The function checks for the owner of the contract, for a zero address and transfer ownership of a contract to a new owner, after which it calls ownership transferred event.
    * @param _newBridge - User address from whose balance tokens are minted.
    */
    function setBridgeAddress(address _newBridge) public onlyForOwner {
        require(_newBridge != address(0), "New bridge have the zero address");
        bridge = _newBridge;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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