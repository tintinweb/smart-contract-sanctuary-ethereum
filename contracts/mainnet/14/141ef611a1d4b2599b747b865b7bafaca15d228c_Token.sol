/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed currentOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Ownable : Function called by unauthorized user."
        );
        _;
    }

    function owner() external view returns (address ownerAddress) {
        ownerAddress = _owner;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        require(newOwner != address(0), "Ownable/transferOwnership : cannot transfer ownership to zero address");
        success = _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        success = _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal returns (bool success) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        success = true;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}interface IERC20Metadata is IERC20 {
    /**
     * @dev  Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev  Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev  Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
abstract contract ERC20 is Context, IERC20
{
	uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    constructor () {
		
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
	
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }	
	
    function _mint(address _to, uint256 _amount) internal virtual
    {
        _totalSupply = _totalSupply + _amount;
        _balances[_to] = _balances[_to] + _amount;
        emit Transfer(address(0), _to, _amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
	
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}

	abstract contract ERC20Pausable is ERC20, Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }


    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    
    function pause() onlyOwner whenNotPaused public {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() onlyOwner whenPaused public {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
	abstract contract ERC20Mintable is ERC20
, Ownable
, ERC20Pausable 
{
    event Mint(address indexed _to, uint256 _amount);
    event MintFinished();
	
    bool internal _mintingFinished;

    function mint(address _to, uint256 _amount)
        external
        onlyOwner
		        whenNotPaused
		        returns (bool success)
    {
        require(_to != address(0),"ERC20Mintable/mint : Should not mint to zero address");
		
				
        require(
            !_mintingFinished,
            "ERC20Mintable/mint : Cannot mint after finished"
        );
        _mint(_to, _amount);
        emit Mint(_to, _amount);
        success = true;
    }

    function finishMint()
        external
        onlyOwner
        returns (bool success)
    {
        require(
            !_mintingFinished,
            "ERC20Mintable/finishMinting : Already finished"
        );
        _mintingFinished = true;
        emit MintFinished();
        return true;
    }
	
	
    function isFinished() external view returns(bool finished) {
        finished = _mintingFinished;
    }
}
	library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
library Arrays {
   /**
     * @dev  Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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
interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}library ECDSA {
    /**
     * @dev  Returns the address that signed a hashed message (`hash`) with
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev  Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev  Returns an Ethereum Signed Message, created from a `hash`. This
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
     * @dev  Returns an Ethereum Signed Typed Data, created from a
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
abstract contract EIP712 {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev  Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev  Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev  Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(string memory name) EIP712(name, "1") {
    }
	
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

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
	abstract contract ERC20Lockable is ERC20, Ownable {
    struct LockInfo {
        uint256 amount;
        uint256 due;
    }

    mapping(address => LockInfo[]) internal _locks;
    mapping(address => uint256) internal _totalLocked;

    event Lock(address indexed from, uint256 amount, uint256 due);
    event Unlock(address indexed from, uint256 amount);

    modifier checkLock(address from, uint256 amount) {
        require(_balances[from] >= _totalLocked[from] + amount, "ERC20Lockable/Cannot send more than unlocked amount");
        _;
    }

    function _lock(address from, uint256 amount, uint256 due)
    internal
    returns (bool success)
    {
        require(due > block.timestamp, "ERC20Lockable/lock : Cannot set due to past");
        require(
            _balances[from] >= amount + _totalLocked[from],
            "ERC20Lockable/lock : locked total should be smaller than balance"
        );
        _totalLocked[from] = _totalLocked[from] + amount;
        _locks[from].push(LockInfo(amount, due));
        emit Lock(from, amount, due);
        success = true;
    }

    function _unlock(address from, uint256 index) internal returns (bool success) {
        LockInfo storage lock = _locks[from][index];
        _totalLocked[from] = _totalLocked[from] - lock.amount;
        emit Unlock(from, lock.amount);
        _locks[from][index] = _locks[from][_locks[from].length - 1];
        _locks[from].pop();
        success = true;
    }

    function unlock(address from, uint256 idx) external returns(bool success){
        require(_locks[from][idx].due < block.timestamp,"ERC20Lockable/unlock: cannot unlock before due");
        return _unlock(from, idx);
    }

    function unlockAll(address from) external returns (bool success) {
        for(uint256 i = 0; i < _locks[from].length;){
            i++;
            if(_locks[from][i - 1].due < block.timestamp){
                if(_unlock(from, i - 1)){
                    i--;
                }
            }
        }
        success = true;
    }

    function releaseLock(address from)
    external
    onlyOwner
    returns (bool success)
    {
        for(uint256 i = 0; i < _locks[from].length;){
            i++;
            if(_unlock(from, i - 1)){
                i--;
            }
        }
        success = true;
    }

    function transferWithLockUp(address recipient, uint256 amount, uint256 due)
    external
    onlyOwner
    returns (bool success)
    {
        require(
            recipient != address(0),
            "ERC20Lockable/transferWithLockUp : Cannot send to zero address"
        );
        _transfer(msg.sender, recipient, amount);
        _lock(recipient, amount, due);
        success = true;
    }

    function lockInfo(address locked, uint256 index)
    external
    view
    returns (uint256 amount, uint256 due)
    {
        LockInfo memory lock = _locks[locked][index];
        amount = lock.amount;
        due = lock.due;
    }

    function totalLocked(address locked) external view returns(uint256 amount, uint256 length){
        amount = _totalLocked[locked];
        length = _locks[locked].length;
    }
}
	contract Freezable is Ownable {
    mapping(address => bool) private _frozen;

    event Freeze(address indexed target);
    event Unfreeze(address indexed target);

    modifier whenNotFrozen(address target) {
        require(!_frozen[target], "Freezable : target is frozen");
        _;
    }

    function freeze(address target) external onlyOwner returns (bool success) {
        _frozen[target] = true;
        emit Freeze(target);
        success = true;
    }

    function unFreeze(address target)
        external
        onlyOwner
        returns (bool success)
    {
        _frozen[target] = false;
        emit Unfreeze(target);
        success = true;
    }

    function isFrozen(address target)
        external
        view
        returns (bool frozen)
    {
        return _frozen[target];
    }
}

	abstract contract ERC20Burnable is ERC20 
	, ERC20Pausable 
    ,Freezable
    ,ERC20Lockable
{
    function burn(uint256 amount) public 
		whenNotFrozen(_msgSender())
			whenNotPaused
			checkLock(_msgSender(), amount)
		virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public
		whenNotFrozen(account)
			whenNotPaused
			checkLock(account, amount)
		virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
	
	function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}
contract Token is
	IERC20Metadata
	,ERC20Burnable
    ,ERC20Mintable
	,ERC20Permit
{
    string private _name;
    string private _symbol;
	uint8  private _decimals;
	
	
			constructor (uint256 initial_supply_, uint8 decimals_,string memory name_, string memory symbol_)
				ERC20Permit(name_)
		{
		_name     = name_;
		_symbol   = symbol_;
		_decimals = decimals_; 
		
								
			_mint(_msgSender(), initial_supply_);
			}
		
	

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) public 
		whenNotFrozen(_msgSender())
			whenNotPaused
			checkLock(_msgSender(), amount)
		virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public 
		whenNotFrozen(sender)
			whenNotPaused
			checkLock(sender, amount)
		virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
	
    
}