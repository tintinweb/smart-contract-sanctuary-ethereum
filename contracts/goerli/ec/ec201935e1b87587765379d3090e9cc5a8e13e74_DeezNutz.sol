/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV1Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getamountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getamountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getamountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getamountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV1Router02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

contract DeezNutz is IERC20 {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromSellLock;

    mapping(address => bool) public _blacklist;
    bool isBlacklist = true;

    string public constant _name = "Deez Nutz";
    string public constant _symbol = "$NUTZ";
    uint8 public constant _decimals = 9;
    uint256 public constant InitialSupply = 1 * 10**12 * 10**_decimals;

    // NOTE Max swapper by the contract
    uint256 swapLimit = InitialSupply / 100; // 1%
    bool isSwapPegged = true;

    // NOTE Limits are calculaating on the base value / the divider
    uint16 public BuyLimitDivider = 100; // 1%
    uint8 public BalanceLimitDivider = 50; // 2%
    uint16 public SellLimitDivider = 75; // 0.75%

    // NOTE Antirug limit
    uint16 public MaxSellLockTime = 10 seconds;
    mapping(address => bool) isMariaDolores;

    // NOTE Block protection
    uint public enableBlock;
    uint public blockProtection = 2;

    address public constant router_address =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _circulatingSupply = InitialSupply;
    uint256 public balanceLimit = _circulatingSupply / BalanceLimitDivider;
    uint256 public sellLimit = _circulatingSupply / SellLimitDivider;
    uint256 public buyLimit = _circulatingSupply / BuyLimitDivider;

    // NOTE Fees
    uint8 public _buyFee = 5;
    uint8 public _sellFee = 99;
    uint8 public _transferFee = 5;

    // NOTE Shares between taxes
    uint8 public liquidityShare = 20;
    uint8 public marketingShare = 40;
    uint8 public chingonShare = 40;

    // NOTE Locally used taxAmount to keep track of what is to swap
    uint taxOnTransferAmount;

    bool private _isTokenSwaping;

    uint256 public totalTokenSwapGenerated;

    uint256 public totalPayouts;

    uint256 public marketingBalance;
    uint256 public chingonBalance;
    uint256 public treasuryBalance;

    bool isTokenSwapManual = false;

    bool public francotirador_proteccion = true;

    address public USDC = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public pair_address;
    IUniswapV2Router02 public router = IUniswapV2Router02(router_address);

    address owner;
    // NOTE Analog of auth
    modifier cuandoSeiMariaDolores() {
        require(is_mariaDolores(msg.sender), "Caller not in Auth");
        _;
    }

    function is_mariaDolores(address addr) private view returns (bool) {
        return addr == owner || isMariaDolores[addr];
    }

    // @notice Initialization and creation of the prerequisites
    constructor() {
        owner = msg.sender;

        _balances[msg.sender] = _circulatingSupply;
        emit Transfer(address(0), msg.sender, _circulatingSupply);

        // NOTE Creating the pair
        pair_address = IUniswapFactory(router.factory())
            .createPair(address(this), USDC);

        sellLockTime = 2 seconds;

        _excluded.add(msg.sender);
        _excludedFromSellLock.add(router_address);
        _excludedFromSellLock.add(pair_address);
        _excludedFromSellLock.add(address(this));
    }

    // @notice Internal transfer method
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if (isBlacklist) {
            require(
                !_blacklist[sender] && !_blacklist[recipient],
                "Blacklisted!"
            );
        }

        bool isExcluded = (_excluded.contains(sender) ||
            _excluded.contains(recipient) ||
            isMariaDolores[sender] ||
            isMariaDolores[recipient]);

        bool isContractTransfer = (sender == address(this) ||
            recipient == address(this));

        bool isLiquidityTransfer = ((sender == pair_address &&
            recipient == router_address) ||
            (recipient == pair_address && sender == router_address));

        if (
            isContractTransfer || isLiquidityTransfer || isExcluded
        ) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            // NOTE francotirador rekt before tradingEnabled
            if (!tradingEnabled) {
                if (!is_mariaDolores(sender) && !is_mariaDolores(recipient)) {
                    if (francotirador_proteccion) {
                        emit Transfer(sender, recipient, 0);
                        return;
                    } else {
                        require(tradingEnabled, "trading not yet enabled");
                    }
                }
            } else {
                // NOTE Block protection on first two blocks
                if (block.number < (enableBlock + blockProtection)) {
                    if(!is_mariaDolores(sender) && !is_mariaDolores(recipient)) {
                        if (francotirador_proteccion) {
                            emit Transfer(sender, recipient, 0);
                            return;
                        } else {
                            require(block.number >= enableBlock + blockProtection, "block protection");
                        }
                    }
                }
            }


            

            bool isBuy = sender == pair_address ||
                sender == router_address;
            bool isSell = recipient == pair_address ||
                recipient == router_address;
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);

        }
    }

    // @notice Manages the taxed transfers
    function _taxedTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) private {
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        swapLimit = sellLimit / 2;

        uint8 tax;
        if (isSell) {
            if (!_excludedFromSellLock.contains(sender)) {
                require(
                    _sellLock[sender] <= block.timestamp || sellLockDisabled,
                    "Seller in sellLock"
                );
                _sellLock[sender] = block.timestamp + sellLockTime;
            }

            require(amount <= sellLimit, "Dump protection");
            tax = _sellFee;
        } else if (isBuy) {
            require(
                recipientBalance + amount <= balanceLimit,
                "whale protection"
            );
            require(amount <= buyLimit, "whale protection");
            tax = _buyFee;
        } else {
            require(
                recipientBalance + amount <= balanceLimit,
                "whale protection"
            );
            if (!_excludedFromSellLock.contains(sender))
                require(
                    _sellLock[sender] <= block.timestamp || sellLockDisabled,
                    "Sender in Lock"
                );
            tax = _transferFee;
        }

        // NOTE Getting the token amount total for taxes
        taxOnTransferAmount += (amount * tax) / 100;

        if (
            (sender != pair_address) &&
            (!manualConversion) &&
            (!_isSwappingContractModifier)
        ) {
            // NOTE Actually swapping 
            _swapContractToken(amount, taxOnTransferAmount);
        }


        uint256 contractToken = _calculateFee(
            amount,
            tax
        );
        uint256 taxedAmount = amount - (contractToken);

        _removeToken(sender, amount);

        _balances[address(this)] += contractToken;

        _addToken(recipient, taxedAmount);

        emit Transfer(sender, recipient, taxedAmount);
    }

    // @notice Mechanism-free transfers
    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender, amount);
        _addToken(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    // @notice Fees are calculated here
    function _calculateFee(
        uint256 amount,
        uint8 tax
    ) private pure returns (uint256) {
        return (amount * tax) / 100;
    }

    // @notice Internal usage only: adds tokens to an address
    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] + amount;
        _balances[addr] = newAmount;
    }

    // @notice Internal usage only: removes tokens from an address
    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] - amount;
        _balances[addr] = newAmount;
    }

    // @notice Distributing fees between the balances
    function _distributeFeesUSDC(uint256 USDCamount) private {
        uint256 marketingSplit = (USDCamount * marketingShare) / 100;
        uint256 chingonSplit = (USDCamount * chingonShare) / 100;

        marketingBalance += marketingSplit;
        chingonBalance += chingonSplit;
    }

    uint256 public totalLPUSDC;

    bool private _isSwappingContractModifier;
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    // @notice Swapping the tokens specified for paired tokens and adding liquidity
    function _swapContractToken(uint256 totalMax, uint256 totalTax) private lockTheSwap {
        uint256 contractBalance = _balances[address(this)];

        // NOTE Ensure the limit is respected
        uint tokenToSwap;
        if(totalTax > swapLimit) {
            tokenToSwap = swapLimit;
        } else {
            tokenToSwap = totalTax;
        }

        // NOTE Ensure swap pegging
        if (tokenToSwap > totalMax) {
            if (isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }

        // NOTE Ensure to stay within the contract limits
        if (contractBalance < tokenToSwap) {
            tokenToSwap = contractBalance;
        }
        
        // NOTE Dividing the tokens
        uint256 tokenForLiquidity = (tokenToSwap * liquidityShare) / totalTax;
        uint256 tokenForMarketing = (tokenToSwap * marketingShare) / totalTax;
        uint256 tokenForchingon = (tokenToSwap * chingonShare) / totalTax;

        // NOTE Liquidity tokens
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqUSDCToken = tokenForLiquidity - liqToken;

        // NOTE Subtracting the swapped tokens
        taxOnTransferAmount -= tokenToSwap;

        // NOTE Adjustment based on liquidity
        uint256 swapToken = liqUSDCToken +
            tokenForMarketing +
            tokenForchingon;

        // NOTE Swapping
        uint256 initialUSDCBalance = address(this).balance;
        _swapTokenForUSDC(swapToken);
        uint256 newUSDC = (address(this).balance - initialUSDCBalance);

        // NOTE Calculating the liquidity to inject and injecting
        uint256 liqUSDC = (newUSDC * liqUSDCToken) / swapToken;
        _addLiquidity(liqToken, liqUSDC);

        // NOTE Noting the generated USDC and distributing
        uint256 generatedUSDC = (address(this).balance - initialUSDCBalance);
        _distributeFeesUSDC(generatedUSDC);
    }

    // @notice Internal method to swaps tokens for USDC
    function _swapTokenForUSDC(uint256 amount) private {
        _approve(address(this), address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // @notice Internal method to add liquidity
    function _addLiquidity(uint256 tokenamount, uint256 USDCAmount) private {
        totalLPUSDC += USDCAmount;
        _approve(address(this), address(router), tokenamount);
        router.addLiquidity(
            USDC,
            address(this),
            USDCAmount,
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // @notice Destroy (burn) tokens
    function destroy(uint256 amount) public cuandoSeiMariaDolores {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        _circulatingSupply -= amount;
        emit Transfer(address(this), Dead, amount);
    }

    // @notice Get the swap limits 
    function getLimits()
        public
        view
        returns (uint256 balance, uint256 sell)
    {
        return (balanceLimit / 10**_decimals, sellLimit / 10**_decimals);
    }

    // @notice Provide info on taxes
    function getTaxes()
        public
        view
        returns (
            uint256 chingonTax,
            uint256 liquidityTax,
            uint256 marketingTax,
            uint256 buyFee,
            uint256 sellFee,
            uint256 transferFee
        )
    {
        return (
            chingonShare,
            liquidityShare,
            marketingShare,
            _buyFee,
            _sellFee,
            _transferFee
        );
    }

    // @notice Get the cooldown period of an address
    function getAddressSellLockTimeInSeconds(address AddressToCheck)
        public
        view
        returns (uint256)
    {
        uint256 lockTime = _sellLock[AddressToCheck];
        if (lockTime <= block.timestamp) {
            return 0;
        }
        return lockTime - block.timestamp;
    }

    // @notice Get the default cooldown period
    function getSellLockTimeInSeconds() public view returns (uint256) {
        return sellLockTime;
    }

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;

    // @notice Set if the token swap is to be limited by tx size
    function SetPeggedSwap(bool isPegged) public cuandoSeiMariaDolores {
        isSwapPegged = isPegged;
    }

    // @notice Set the max limit of swappable tokens for fees
    function SetMaxSwap(uint256 max) public cuandoSeiMariaDolores {
        swapLimit = max;
    }

    // @notice Set the maximul cooldown to apply
    function SetMaxLockTime(uint16 max) public cuandoSeiMariaDolores {
        MaxSellLockTime = max;
    }

    /// ANCHOR ACL Functions

    // @notice Blacklist or unban a specific address
    function BlackListAddress(address addy, bool booly) public cuandoSeiMariaDolores {
        _blacklist[addy] = booly;
    }

    // @notice Freeze an address without blacklisting (cooldown of 1 year)
    function AddressStop() public cuandoSeiMariaDolores {
        _sellLock[msg.sender] = block.timestamp + (365 days);
    }

    // @notice Apply a fine to an address as penalty
    function FineAddress(address addy, uint256 amount) public cuandoSeiMariaDolores {
        require(_balances[addy] >= amount, "Not enough tokens");
        _balances[addy] -= (amount * 10**_decimals);
        _balances[address(this)] += (amount * 10**_decimals);
        emit Transfer(addy, address(this), amount * 10**_decimals);
    }

    // @notice Gives authorizations to an address
    function esMariaDolores(address addy, bool booly) public cuandoSeiMariaDolores {
        isMariaDolores[addy] = booly;
    }

    // @notice Ban and removes tokens from an address as penalty
    function SeizeAddress(address addy) public cuandoSeiMariaDolores {
        uint256 seized = _balances[addy];
        _blacklist[addy] = true;
        _balances[addy] = 0;
        _balances[address(this)] += seized;
        emit Transfer(addy, address(this), seized);
    }

    // @notice Whitelist an address from fees
    function ExcludeAccountFromFees(address account) public cuandoSeiMariaDolores {
        _excluded.add(account);
    }

    // @notice Includes an address in fees
    function IncludeAccountToFees(address account) public cuandoSeiMariaDolores {
        _excluded.remove(account);
    }

    // @notice Exclude an account from cooldown checks
    function ExcludeAccountFromSellLock(address account) public cuandoSeiMariaDolores {
        _excludedFromSellLock.add(account);
    }

    // @notice Include an account in cooldown checks
    function IncludeAccountToSellLock(address account) public cuandoSeiMariaDolores {
        _excludedFromSellLock.remove(account);
    }

    // @notice Withdraw the USDC tokens in the marketing balance
    function WithdrawMarketingUSDC() public cuandoSeiMariaDolores {
        uint256 amount = marketingBalance;
        marketingBalance = 0;
        address sender = msg.sender;
        IERC20(USDC).transfer(sender, amount);
    }

    // @notice Withdraw the USDC tokens in the chingon balance
    function WithdrawChingonUSDC() public cuandoSeiMariaDolores {
        uint256 amount = chingonBalance;
        chingonBalance = 0;
        address sender = msg.sender;
        IERC20(USDC).transfer(sender, amount);
    }

    // @notice Self destruct the contract in case of migrations
    function Bambolero() public cuandoSeiMariaDolores {
        selfdestruct(payable(msg.sender));
    }

    // @notice Stop automatic feed conversion and forces them to be swapped manually
    function SwitchManualUSDCConversion(bool manual) public cuandoSeiMariaDolores {
        manualConversion = manual;
    }

    // @notice Disable cooldown checks
    function DisableSellLock(bool disabled) public cuandoSeiMariaDolores {
        sellLockDisabled = disabled;
    }

    // @notice Set the cooldown period
    function SetSellLockTime(uint256 sellLockSeconds) public cuandoSeiMariaDolores {
        sellLockTime = sellLockSeconds;
    }

    // @notice Edit taxes and shares
    function SetTaxes(
        uint8 treasuryTaxes,
        uint8 chingonTaxes,
        uint8 liquidityTaxes,
        uint8 marketingTaxes,
        uint8 buyFee,
        uint8 sellFee,
        uint8 transferFee
    ) public cuandoSeiMariaDolores {
        uint8 totalTax = treasuryTaxes +
            chingonTaxes +
            liquidityTaxes +
            marketingTaxes;
        require(totalTax == 100, "burn+liq+marketing needs to equal 100%");
        chingonShare = chingonTaxes;
        liquidityShare = liquidityTaxes;
        marketingShare = marketingTaxes;

        _buyFee = buyFee;
        _sellFee = sellFee;
        _transferFee = transferFee;
    }

    // @notice Change the percentage going to the marketing balance
    function ChangeMarketingShare(uint8 newShare) public cuandoSeiMariaDolores {
        marketingShare = newShare;
    }

    // @notice Change the percentage going to the chingon balance
    function ChangeChingonShare(uint8 newShare) public cuandoSeiMariaDolores {
        chingonShare = newShare;
    }

    // @notice Manually swap and redistribute tokens owned by the CA
    function ManualGenerateTokenSwapBalance(uint256 _qty)
        public
        cuandoSeiMariaDolores
    {
        _swapContractToken(_qty * 10**9, _qty * 10**9);
    }

    // @notice Set the limits for transactions
    function UpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit)
        public
        cuandoSeiMariaDolores
    {
        newBalanceLimit = newBalanceLimit * 10**_decimals;
        newSellLimit = newSellLimit * 10**_decimals;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }

    bool public tradingEnabled;
    address private _liquidityTokenAddress;

    // @notice Open or close the swaps for the public
    function EnableTrading(bool booly) public cuandoSeiMariaDolores {
        tradingEnabled = booly;
    }

    // @notice Manually set the pair address
    function LiquidityTokenAddress(address liquidityTokenAddress)
        public
        cuandoSeiMariaDolores
    {
        _liquidityTokenAddress = liquidityTokenAddress;
    }

    // @notice Avoid having tokens stuck in the contract by transferring them if needed
    function RescueTokens(address tknAddress) public cuandoSeiMariaDolores {
        IERC20 token = IERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance > 0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    // @notice Enable or disable the blacklist feature
    function setBlacklistEnabled(bool isBlacklistEnabled)
        public
        cuandoSeiMariaDolores
    {
        isBlacklist = isBlacklistEnabled;
    }

    function setContractTokenSwapManual(bool manual) public cuandoSeiMariaDolores {
        isTokenSwapManual = manual;
    }

    // @notice Plain blacklisting method
    function setBlacklistedAddress(address toBlacklist)
        public
        cuandoSeiMariaDolores
    {
        _blacklist[toBlacklist] = true;
    }

    // @notice Plain unban method
    function removeBlacklistedAddress(address toRemove)
        public
        cuandoSeiMariaDolores
    {
        _blacklist[toRemove] = false;
    }

    // @notice In case something goes wrong, avoid ETH to be stuck in the CA
    function AvoidLocks() public cuandoSeiMariaDolores {
        (bool sent, ) = msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    receive() external payable {}

    fallback() external payable {}

    function getOwner() external view override returns (address) {
        return owner;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}