/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Counters {
    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);   
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

interface IERC20Mintable is IERC20 {
    function mint(address _to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external ;
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
}

library Address {
 
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash= 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success,"Address: unable to send value, recipient may have reverted");
    }

 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

 
    function functionCallWithValue( address target,bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue( target, data, value,"Address: low-level call with value failed");
    }


    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue( address target, bytes memory data, uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Initializable {

    uint8 private _initialized;
    bool private _initializing;

    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address previousOwner, address newOwner);


    function owner() external view returns (address) {
    return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
    require(!paused, "Pausable: paused");
    _;
    }


    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

 
    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }


}

interface IERC20Metadata is IERC20Mintable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;


    function toString(uint256 value) internal pure returns (string memory) {
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



}

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
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
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

interface IERC20Permit is IERC20Metadata{
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;


    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

abstract contract EIP712 {
   
    bytes32 private  _CACHED_DOMAIN_SEPARATOR;
    uint256 private  _CACHED_CHAIN_ID;
    address private  _CACHED_THIS;
    bytes32 private  _HASHED_NAME;
    bytes32 private  _HASHED_VERSION;
    bytes32 private  _TYPE_HASH;


    function eip712(string memory name, string memory version) internal virtual {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }


    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

   
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

contract INRx is  Ownable, Pausable, Initializable, IERC20Permit, EIP712  {
    using Counters for Counters.Counter;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal _totalSupply;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    mapping(address => Counters.Counter) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);

    function initialize( string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, address newOwner) external  initializer {
        require(newOwner != address(0),"ERC20: new owner is the zero address");

        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        setOwner(newOwner);
        eip712(tokenName,"1");
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "ERC20: caller is not a minter");
        _;
    }

    function rescueERC20( IERC20 tokenContract, address to, uint256 amount ) external onlyOwner {
        tokenContract.transfer(to, amount);
    }

    function mint(address to, uint256 amount) external override whenNotPaused onlyMinters returns (bool) {
        require(to != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: mint amount not greater than 0");

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(amount <= mintingAllowedAmount,"ERC20: mint amount exceeds minterAllowance");

        _totalSupply += amount;
        balances[to] += amount;
        minterAllowed[msg.sender] = mintingAllowedAmount-amount;
        emit Mint(msg.sender, to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function minterAllowance(address minter) external view returns (uint256) {
        return minterAllowed[minter];
    }

    function isMinter(address account) external view returns (bool) {
        return minters[account];
    }


    function allowance(address owner, address spender) external override view returns (uint256) {
        return allowed[owner][spender];
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return balances[account];
    }
 
    function approve(address spender, uint256 value) external override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender,uint256 value) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) external override whenNotPaused  returns (bool) {
        require(value <= allowed[from][msg.sender], "ERC20: transfer amount exceeds allowance");
        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;
        return true;
    }

    function transfer(address to, uint256 value) external override whenNotPaused  returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer( address from, address to, uint256 value) internal  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value <= balances[from],"ERC20: transfer amount exceeds balance");

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }

    function configureMinter(address minter, uint256 minterAllowedAmount) external whenNotPaused onlyOwner returns (bool) {
        require(!minters[minter],"ERC20: should not be a minter before");
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

    function removeMinter(address minter) external onlyOwner returns (bool) {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    function burn(uint256 amount) external override {
        uint256 balance = balances[msg.sender];
        require(amount > 0, "ERC20: burn amount not greater than 0");
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        _totalSupply  -= amount;
        balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function increaseAllowance(address spender, uint256 increment) external whenNotPaused  returns (bool) {
        _increaseAllowance(msg.sender, spender, increment);
        return true;
    }

    function decreaseAllowance(address spender, uint256 decrement) external whenNotPaused  returns (bool) {
        _decreaseAllowance(msg.sender, spender, decrement);
        return true;
    }

    function _increaseAllowance( address owner, address spender, uint256 increment) internal  {
        _approve(owner, spender, allowed[owner][spender]+increment);
    }

    function _decreaseAllowance(address owner, address spender, uint256 decrement) internal  {
         _approve(owner,spender, allowed[owner][spender]-decrement);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public whenNotPaused virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

}