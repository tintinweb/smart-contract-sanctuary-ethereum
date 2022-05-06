/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: 押金合约/deposit.sol


pragma solidity ^0.8.0;




contract deposit is Ownable{

    struct turnover{
        address tokenAddr;// If the currency of the deposit is zero, the address is eth
        address from;// The source account of the deposit
        uint256 amount;// The amount of the deposit
        bool isEffective;// Identifies whether the deposit has been created 
        bool isused;// Identifies whether the deposit is used 
    }

    mapping(string => turnover) public deploys;// A deposit uniquely identified by businessId

    mapping(address => mapping(address => uint256)) public balances;// Record the total deposit amount of an account in a certain currency

    event Payment(address tokenAddr, uint256 amount, string businessId);// payment event, record the receipt of deposit transfer from an account

    event Withdraw(address tokenAddr, uint256 amount, address toAddr, string businessId);// withdraw event, record an account to withdraw a certain deposit

    event Expend(address tokenAddr, uint256 amount, address toAddr, string businessId);// Expend event, record the transfer of a certain deposit from the contract from the ownen account
    
    event Received(address tokenaddr,address payee,uint256 amount);// Received event, record the contract received ETH transfer but no function call

    event CheckSig(uint256 num, string message);// CheckSig event, records that the signature of a withdrawal transaction is illegal


    /**
     * exit Check if the deposit ID has already been created
     */
    function exit(string memory businessId) public view returns (bool){
        return deploys[businessId].isEffective;
    }

    /**
     * used Check if the deposit ID has been withdrawn
     */
     function used(string memory businessId) public view returns (bool){
        return deploys[businessId].isused;
    }

    /**
     * payment User calls to send deposit operation
     */
    function payment(
        address tokenAddr, 
        uint256 amount, 
        string calldata businessId
    ) external payable {
        if (tokenAddr == address(0)){//eth
            require(msg.value >= amount,"Not enough eth tokens");
            require(!exit(businessId),"BusinessId already exists");
            deploys[businessId] = turnover(tokenAddr, msg.sender, msg.value, true, false);
            balances[msg.sender][tokenAddr] += msg.value;
            emit Payment(tokenAddr, msg.value, businessId);
        }else{//erc20
            IERC20 token = IERC20(tokenAddr);
            uint256 _amount = token.allowance(msg.sender,address(this));
            if(amount > _amount || _amount == 0){
                revert("Not enough tokens approve");
            }else{
                bool success = token.transferFrom(msg.sender, address(this), _amount);
                require(success,"ERC20 transferFrom fail");
                require(!exit(businessId),"BusinessId already exists");
                deploys[businessId] = turnover(tokenAddr, msg.sender, _amount, true, false);
                balances[msg.sender][tokenAddr] += _amount;
                emit Payment(tokenAddr, _amount, businessId);
            }
        }
    }

    /**
     * helper The user calls to get the hash of the background account that needs to be signed
     */
    function helper(
        address msgSender,
        address tokenAddr,
        address toAddr, 
        string calldata businessId
    ) public pure returns (bytes32) {
        bytes memory message = abi.encode(msgSender,tokenAddr,toAddr,businessId);
        bytes32 hash = keccak256(message);
        return hash;
  }

    /**
     * verify Verify that the user's order withdrawal is legal
     */
    function verify(
        address  tokenAddr,
        address  toAddr, 
        string memory businessId,
        bytes  memory _sig
    ) internal view returns (bool) {
        bytes memory message = abi.encode(msg.sender, tokenAddr, toAddr, businessId);
        bytes32 hash = keccak256(message);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        (address _address, ) = ECDSA.tryRecover(prefixedHash,_sig);
        if(owner()  == _address){
            return true;
        }else{
            return false;
        }
  }

    
    /**
     * _transferEth Transfer eth
     */
    function _transferEth(
        address _to, 
        uint256 _amount
    ) internal {
        (bool success, ) = _to.call{value: _amount}('');
        require(success, "_transferEth: Eth transfer failed");
    }

    /**
     * _transferERC20 Make an erc20 transfer
     */
    function _transferERC20(
        address tokenAddr, 
        address _to, 
        uint256 _amount
    ) internal {
        IERC20 token = IERC20(tokenAddr);
        bool success = token.transfer(_to,_amount);
        require(success, "_transferERC20: ERC20 token transfer failed");
    }

    /**
     * _withdraw The user withdraws the deposit for placing an order identified by the businessId
     */
    function _withdraw(
        address  tokenAddr, 
        address  toAddr, 
        string  memory businessId
    ) internal {
        require(exit(businessId),"BusinessId does not exist");
        require(!used(businessId),"BusinessId has been used");
        require(deploys[businessId].from == msg.sender,"Not your deposit");
        require(deploys[businessId].tokenAddr == tokenAddr,"Wrong token type");
        require(balances[msg.sender][tokenAddr] >= deploys[businessId].amount,"Insufficient Balance");


        deploys[businessId].isused = true;
        balances[msg.sender][tokenAddr] -= deploys[businessId].amount;

        if(deploys[businessId].tokenAddr == address(0)){//eth
            _transferEth(toAddr,deploys[businessId].amount);
            emit Withdraw(tokenAddr, deploys[businessId].amount, toAddr, businessId);
        }else{//erc20
            _transferERC20(tokenAddr, toAddr,deploys[businessId].amount);
            emit Withdraw(tokenAddr, deploys[businessId].amount, toAddr, businessId);
        }
    }

    /**
     * withdraw The user withdraws the deposit for placing an order identified by the businessId
     */
    function withdraw(
        address[]  calldata tokenAddr, 
        address[]  calldata toAddr, 
        string[]  calldata businessId, 
        bytes[]  calldata sign
    ) external {
        uint256 len = tokenAddr.length;
        require(len == toAddr.length && len == businessId.length && len == sign.length,"LENGTH_MISMATCH");

        for(uint256 i = 0; i < len; ++i){
            bool success = verify(tokenAddr[i], toAddr[i], businessId[i], sign[i]);

            if (!success){
                emit CheckSig(i+1,"illegal signature");
                revert();
            }else{
                _withdraw(tokenAddr[i],toAddr[i],businessId[i]);
            }
        }
    }

    /**
     * queryUserBalance Query the amount of a certain token that the user has stored in the contract
     */
    function queryUserBalance(address tokenAddr, address userAddr) external view returns(uint256){
        return balances[userAddr][tokenAddr];
    }


    /**
     * _expend The owner account withdraws the order deposit identified by the businessId
     */
  function _expend(
        address  tokenAddr, 
        address  toAddr, 
        string  memory businessId
    ) internal {
        require(exit(businessId),"BusinessId does not exist");
        require(!used(businessId),"BusinessId has been used");
        require(deploys[businessId].tokenAddr == tokenAddr,"Wrong token type");

        deploys[businessId].isused = true;
        balances[deploys[businessId].from][tokenAddr] -= deploys[businessId].amount;

        if(deploys[businessId].tokenAddr == address(0)){//eth
            _transferEth(toAddr,deploys[businessId].amount);
            emit Expend(tokenAddr, deploys[businessId].amount, toAddr, businessId);
        }else{//erc20
            _transferERC20(tokenAddr, toAddr,deploys[businessId].amount);
            emit Expend(tokenAddr, deploys[businessId].amount, toAddr, businessId);
        }
    }

    /**
     * expend The owner account withdraws the order deposit identified by the businessId
     */
    function expend(
        address[] calldata tokenAddr, 
        address[] calldata toAddr, 
        string[] calldata businessId
    ) external onlyOwner {
            uint256 len = tokenAddr.length;
            require(len == toAddr.length && len == businessId.length,"LENGTH_MISMATCH");

            for(uint256 i = 0; i < len; ++i){
                _expend(tokenAddr[i],toAddr[i],businessId[i]);
            }
    }

    /**
     * Balance Query the balance of a certain token corresponding to the contract
     */
    function Balanceoftoken(address tokenAddr) public view returns (uint256) {
        if(tokenAddr == address(0)){
            return address(this).balance;
        }else{
            return  IERC20(tokenAddr).balanceOf(address(this));
        }
        
    }

    // receive ETH
    receive() external payable {
        emit Received(address(0), msg.sender, msg.value);
    }
}