/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;
interface IVBExpressCallee {
    function vbExpressCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
interface IVBExpressFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB, uint24 kA, uint24 kB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint24 kA, uint24 kB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IVBExpressPair {
    event Mint(address indexed sender, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, address indexed to);
    event Withdraw(address indexed sender, uint256 amount1, address indexed to);
    event Express(
        address indexed sender,
        uint256 amount1In,
        uint256 amount0Out,
        address indexed to,
        address indexed assigned
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    function MINIMUM_LIQUIDITY() external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function prioritizedToken1Of(address account) external view returns (uint256);

    function getReserve0() external view returns (uint256 _reserve0, uint32 _blockTimestampLast);

    function getReserve1() external view returns (uint256 _reserve1, uint32 _blockTimestampLast);

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint24 _k0, uint24 _k1) external;

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external returns (uint256 amount0);

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external returns (uint256 burnedAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function withdraw(address to) external returns (uint256 burnedAmount, uint256 withdrawedAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function express(uint256 amount0Out, uint256 amount1In, address to, bytes calldata data) external;

    function expressWithAssign(uint256 amount0Out, uint256 amount1In, address to, address assigned, bytes calldata data) external;
}

interface IVBERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IVBERC20Metadata is IVBERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract VBERC20 is Context, IVBERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "VBchain Express";
    string private _symbol = "VBC-E";

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "VBERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, "VBchain Express: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "VBchain Express: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "VBERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "VBERC20: transfer from the zero address");
        require(recipient != address(0), "VBERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "VBERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "VBERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "VBERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "VBERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "VBERC20: approve from the zero address");
        require(spender != address(0), "VBERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract VBExpressPair is IVBExpressPair, VBERC20 {

    event VBExpressMint(address indexed sender, uint256 liquidity);
    event VBExpressBurn(address indexed sender, uint256 amount0, address indexed to);
    event VBExpressWithdraw(address indexed sender, uint256 amount1, address indexed to);
    event VBExpressExpress(
        address indexed sender,
        uint256 amount1In,
        uint256 amount1Out,
        address indexed to,
        address indexed assigned
    );
    event VBExpressSync(uint256 reserve0, uint256 reserve1);

    mapping(address => uint256) private _priorities;
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public override factory;
    address public override token0;
    address public override token1;
    
    uint256 private reserve0;           // uses single storage slot, accessible via getReserves
    uint256 private reserve1;
    uint256 private totalPriorities;

    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves
    uint24 private k0;
    uint24 private k1;

    uint8 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "VBchain Express: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function prioritizedToken1Of(address account) external override view returns (uint256) {
        return _priorities[account];
    }

    function getReserve0() public override view returns (uint256 _reserve0, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _blockTimestampLast = blockTimestampLast;
    }

    function getReserve1() public override view returns (uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "VBchain Express: TRANSFER_FAILED");
    }

    constructor() {
        factory = _msgSender();
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint24 _k0, uint24 _k1) external override {
        require(_msgSender() == factory, "VBchain Express: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        k0 = _k0;
        k1 = _k1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1) private {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit VBExpressSync(reserve0, reserve1);
    }

    function _assign(address account, uint256 _reserve1, uint256 amount1In) private {
        uint256 _assiged = _priorities[account];
        uint256 _liquidity = balanceOf(account);
        uint256 _totalSupply = totalSupply();
        uint256 _lock = _assiged*k0/k1 + _liquidity*(_reserve1- totalPriorities)*k0/(k1*_totalSupply);
        uint256 available = _liquidity - _lock;
        require(available >= amount1In, "VBchain Express: INSUFFICIENT_AMOUNT_ASSIGNED");
        _priorities[account] += amount1In;
        totalPriorities += amount1In;
    } 

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 amount0) {
        (uint256 _reserve0,) = getReserve0(); // gas savings
        uint256 balance0 = IVBERC20(token0).balanceOf(address(this));
        uint256 balance1 = IVBERC20(token1).balanceOf(address(this));
        amount0 = balance0 - _reserve0;
        require(amount0 > 0 && amount0 > MINIMUM_LIQUIDITY, "VBchain Express: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, amount0);
        _update(balance0,balance1);
        emit VBExpressMint(_msgSender(), amount0);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 burnedAmount) {
        address _token0 = token0;                                // gas savings
        uint256 liquidity = balanceOf(to);
        burnedAmount = balanceOf(address(this));
        require(liquidity >= burnedAmount, "VBchain Express: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), burnedAmount);
        _safeTransfer(_token0, to, burnedAmount);
        uint256 balance0 = IVBERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IVBERC20(token1).balanceOf(address(this));
        _update(balance0,balance1);
        emit VBExpressBurn(_msgSender(), burnedAmount, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function withdraw(address to) external override lock returns (uint256 burnedAmount, uint256 withdrawedAmount) {
        address _token1 = token1;                                // gas savings
        burnedAmount = balanceOf(address(this));
        withdrawedAmount = burnedAmount*k1/k0;
        require(withdrawedAmount > 0, "VBchain Express: INSUFFICIENT_AMOUNT_WITHDRAWED");
        totalPriorities -= _priorities[to];
        _priorities[to] = 0;
        _burn(address(this), burnedAmount);
        _safeTransfer(_token1, to, withdrawedAmount);
        uint256 balance0 = IVBERC20(token0).balanceOf(address(this));
        uint256 balance1 = IVBERC20(token1).balanceOf(address(this));
        _update(balance0, balance1);
        emit VBExpressBurn(_msgSender(), burnedAmount, to);
        emit VBExpressWithdraw(_msgSender(), withdrawedAmount, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function express(uint256 amount0Out, uint256 amount1In, address to, bytes calldata data) external lock override {
        require(amount0Out > 0 && amount1In > 0, "VBchain Express: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 _reserve1, ) = getReserve1(); // gas savings
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance1 = IVBERC20(token1).balanceOf(address(this));
        require(amount1In == balance1 - _reserve1 && amount1In > MINIMUM_LIQUIDITY, "VBchain Express: INSUFFICIENT_INPUT_AMOUNT");
        require(to != _token0 && to != _token1 && to != address(0), "VBchain Express: INVALID_TO");
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (data.length > 0) IVBExpressCallee(to).vbExpressCall(msg.sender, amount0Out, amount1In, data);
        uint256 balance0 = IVBERC20(token0).balanceOf(address(this));
        _update(balance0, balance1);
        emit VBExpressExpress(_msgSender(), amount1In, amount0Out, to, address(this));
    }

    function expressWithAssign(uint256 amount0Out, uint256 amount1In, address to, address assigned, bytes calldata data) external lock override {
        (uint256 _reserve1, ) = getReserve1(); // gas savings
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance1 = IVBERC20(token1).balanceOf(address(this));
        require(amount1In == balance1 - _reserve1 && amount1In > MINIMUM_LIQUIDITY, "VBchain Express: INSUFFICIENT_INPUT_AMOUNT");
        require(to != _token0 && to != _token1 && to != address(0), "VBchain Express: INVALID_TO");
        _assign(assigned, _reserve1, amount1In);
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (data.length > 0) IVBExpressCallee(to).vbExpressCall(msg.sender, amount0Out, amount1In, data);
        uint256 balance0 = IVBERC20(token0).balanceOf(address(this));
        _update(balance0, balance1);
        emit VBExpressExpress(_msgSender(), amount1In, amount0Out, to, assigned);
    }
}