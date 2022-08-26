/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.15;

interface IToken {
    function addPair(address pair, address token) external;
    function depositLPFee(uint amount, address token) external;
}

interface IRYZRSwapCallee {
    function newSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

/**	
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.	
 *	
 * These functions can be used to verify that a message was signed by the holder	
 * of the private keys of a given address.	
 */	
library ECDSA {	
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
        // Check the signature length	
        if (signature.length != 65) {	
            revert("ECDSA: invalid signature length");	
        }	
        // Divide the signature in r, s and v variables	
        bytes32 r;	
        bytes32 s;	
        uint8 v;	
        // ecrecover takes the signature parameters, and the only way to get them	
        // currently is to use assembly.	
        // solhint-disable-next-line no-inline-assembly	
        assembly {	
            r := mload(add(signature, 0x20))	
            s := mload(add(signature, 0x40))	
            v := byte(0, mload(add(signature, 0x60)))	
        }	
        return recover(hash, v, r, s);	
    }	
    /**	
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,	
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
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This	
     * replicates the behavior of the	
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]	
     * JSON-RPC method.	
     *	
     * See {recover}.	
     */	
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {	
        // 32 is the length in bytes of hash,	
        // enforced by the type signature above	
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));	
    }	
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath { // provides additional gas efficiency
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-underflow");
        z = x / y;
    }
}

interface IRYZRSwapERC20 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract RYZRSwapERC20 is IRYZRSwapERC20 {
    using SafeMath for uint;

    string public constant override name = 'RYZRSwap-LP';
    string public constant override symbol = 'NEW-LP';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public immutable override DOMAIN_SEPARATOR;
    bytes32 public constant override PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max - 1) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'RYZRSwap: TIMESTAMP_DEADLINE_EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'RYZRSwap: SIGNATURE_IS_INVVALID');
        _approve(owner, spender, value);
    }
}

interface IRYZRSwapRouter {
    function pairFeeAddress(address pair) external view returns (address);
    function adminFee() external view returns (uint256);
    function feeAddressGet() external view returns (address);
}

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
 *	
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas	
 * metering changes introduced in the Istanbul hardfork.	
 */	
contract ReentrancyGuard {	
    bool private _notEntered;	
    constructor () {	
        // Storing an initial non-zero value makes deployment a bit more	
        // expensive, but in exchange the refund on every call to nonReentrant	
        // will be lower in amount. Since refunds are capped to a percetange of	
        // the total transaction's gas, it is best to keep them low in cases	
        // like this one, to increase the likelihood of the full refund coming	
        // into effect.	
        _notEntered = true;	
    }	
    /**	
     * @dev Prevents a contract from calling itself, directly or indirectly.	
     * Calling a `nonReentrant` function from another `nonReentrant`	
     * function is not supported. It is possible to prevent this from happening	
     * by making the `nonReentrant` function external, and make it call a	
     * `private` function that does the actual work.	
     */	
    modifier nonReentrant() {	
        // On the first call to nonReentrant, _notEntered will be true	
        require(_notEntered, "ReentrancyGuard: reentrant call");	
        // Any calls to nonReentrant after this point will fail	
        _notEntered = false;	
        _;	
        // By storing the original value once again, a refund is triggered (see	
        // https://eips.ethereum.org/EIPS/eip-2200)	
        _notEntered = true;	
    }	
}

interface IRYZRSwapPair {
    function baseToken() external view returns (address);
    function getTotalFee() external view returns (uint);
    function updateTotalFee(uint totalFee) external returns (bool);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address _baseToken);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, uint amount0Fee, uint amount1Fee, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setBaseToken(address _baseToken) external;
}

interface IRYZRSwapFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function pairExist(address pair) external view returns (bool);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function routerInitialize(address) external;
    function routerAddress() external view returns (address);
}

contract RYZRSwapPair is IRYZRSwapPair, RYZRSwapERC20, ReentrancyGuard {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    IRYZRSwapRouter public routerAddress;

    address public immutable override factory;
    address public override token0;
    address public override token1;
    address public override baseToken;
    uint public totalFee = 1000;

    uint112 private reserve0;           
    uint112 private reserve1;           
    uint32  private blockTimestampLast; 

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; 

    uint private unlocked = 1;
    modifier lock() { // IMPORTANT TO PREVENT RE-ENTRANCY
        require(msg.sender == address(routerAddress), "RYZRSwap: ONLY_ROUTER_CAN_ACCESS");
        require(unlocked == 1, "RYZRSwap: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast, address _baseToken) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
        _baseToken = baseToken;
    }

    function _safeTransfer(address token, address to, uint value, bool isSwapping) private nonReentrant {
        if(value == 0){
            return;
        }
        if (routerAddress.pairFeeAddress(address(this)) == token && isSwapping){
            uint256 adminFee = routerAddress.adminFee();
            if(adminFee != 0){
                uint256 getOutFee = value.mul(adminFee) / (10000);
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, routerAddress.feeAddressGet(), getOutFee));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "RYZRSwap: TRANSFER_FAILED");
                value = value.sub(getOutFee);
            }
            (bool success1, bytes memory data1) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
            require(success1 && (data1.length == 0 || abi.decode(data1, (bool))), "RYZRSwap: TRANSFER_FAILED");
        }else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "RYZRSwap: TRANSFER_FAILED");
        }
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event Initialize(address token0, address token1, IRYZRSwapRouter router, address caller);	
    event BaseTokenSet(address baseToken, address caller);	
    event TotalFeeUpdate(uint totalFee);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, "RYZRSwap: ONLY_FACTORY_CAN_CALL"); 
        require(_token0 != address(0) && _token1 != address(0), "RYZRSwap: INVALID_ADDRESS");
        token0 = _token0;
        token1 = _token1;
        routerAddress = IRYZRSwapRouter(IRYZRSwapFactory(factory).routerAddress());
        emit Initialize(token0, token1, routerAddress, msg.sender);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "RYZRSwap: OVERFLOW_ERROR");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; 
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IRYZRSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; 
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); 
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; 
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); 
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "RYZRSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        require(totalSupply != 0, "RYZRSwap: totalSupply must not be 0");
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); 
        address _token0 = token0;                                
        address _token1 = token1;                               
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; 
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, "RYZRSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0, false);
        _safeTransfer(_token1, to, amount1, false);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, uint amount0Fee, uint amount1Fee, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, "ERROR: TRY_INCREASING_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); 
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "RYZRSwap: INSUFFICIENT_LIQUIDITY");

        if(baseToken != address(0)) {
            require(amount0Fee > 0 || amount1Fee > 0, "RYZRSwap: INSUFFICIENT_FEE_AMOUNT");
        }

        uint balance0;
        uint balance1;
        { 
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "RYZRSwap: INVALID_RECEIVER");
            if (amount0Out > 0) {
                _safeTransfer(_token0, to, amount0Out, true);
            }
            if (amount1Out > 0) {
                _safeTransfer(_token1, to, amount1Out, true);
            }

            if(amount0Fee > 0 && baseToken == token0) {
                bool success0 = IERC20(_token0).approve(_token1, amount0Fee);
                require(success0);
                IToken(_token1).depositLPFee(amount0Fee, _token0);
            }
            if(amount1Fee > 0 && baseToken == token1) {
                bool success1 = IERC20(_token1).approve(_token0, amount1Fee);
                require(success1);
                IToken(_token0).depositLPFee(amount1Fee, _token1);
            }

            if (data.length > 0) IRYZRSwapCallee(to).newSwapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out - amount0Fee ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out - amount1Fee ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "ERROR: AMOUNT_MUST_BE_GREATER_THAN_ZERO");

        _update(balance0, balance1, _reserve0, _reserve1);

        {
            uint _amount0Out = amount0Out;
            uint _amount1Out = amount1Out;
            address _to = to;
            emit Swap(msg.sender, amount0In, amount1In, _amount0Out, _amount1Out, _to);
        }
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; 
        address _token1 = token1; 
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0), false);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1), false);
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // This function can ONLY be called by the token contract
    function setBaseToken(address _baseToken) external override {
        require(msg.sender == token0 || msg.sender == token1, "RYZRSwap: NOT_ALLOWED");
        require(_baseToken == token0 || _baseToken == token1, "RYZRSwap: WRONG_ADDRESS");

        baseToken = _baseToken;
        emit BaseTokenSet(baseToken, msg.sender);
    }

    function getTotalFee() external override view returns (uint) {
        return totalFee;
    }

    // This function can ONLY be called by the token contract
    function updateTotalFee(uint _totalFee) external override returns (bool) {
        if (baseToken == address(0)) return false;
        address feeTaker = baseToken == token0 ? token1 : token0;
        require(feeTaker == msg.sender, "RYZRSwap: NOT_ALLOWED");
        require(_totalFee <= 2500, "RYZRSwap: FEE_TOO_HIGH");

        totalFee = _totalFee;
        emit TotalFeeUpdate(totalFee);
        return true;
    }
}

contract RYZRSwapFactory is IRYZRSwapFactory, ReentrancyGuard {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(RYZRSwapPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;
    address public override routerAddress;
    bool public routerInit;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    mapping (address => bool) public override pairExist;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event FeeToUpdate(address feeTo);		
    event FeeToSetterUpdate(address feeToSetter);		

    constructor() {
        feeToSetter = msg.sender;
        feeTo = msg.sender;
    }

    function routerInitialize(address _router) external override {
        require(!routerInit, "RYZRSwap: ROUTER_INITIALIZED_ALREADY");
        require(!routerInit, "RYZRSwap: INITIALIZED_ALREADY");	
        require(_router != address(0), "RYZRSwap: INVALID_ADDRESS");
        routerAddress = _router;
        routerInit = true;
    }
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override nonReentrant returns (address pair) {
        require(tokenA != tokenB, "RYZRSwap: CANNOT_BE_IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "RYZRSwap: CANNOT_BE_THE_ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "RYZRSwap: PAIR_ALREADY_EXISTS"); 
        bytes memory bytecode = type(RYZRSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IRYZRSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; 
        allPairs.push(pair);
        pairExist[pair] = true;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "RYZRSwap: ACCESS_DENIED");
        require(_feeTo != address(0), "RYZRSwap: INVALID_ADDRESS");	
        feeTo = _feeTo;	
        emit FeeToUpdate(feeTo);
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "RYZRSwap: ACCESS_DENIED");
        require(_feeToSetter != address(0), "RYZRSwap: INVALID_ADDRESS");	
        feeToSetter = _feeToSetter;	
        emit FeeToSetterUpdate(feeToSetter);
    }
}