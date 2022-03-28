//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// TransferHelper Library
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// Safemath Library
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// DEXLibrary Library
interface IDEXPair {
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
library DEXLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DEXLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DEXLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(bytes32 initHash, address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initHash // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(bytes32 initHash, address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(initHash, factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDEXPair(pairFor(initHash, factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'DEXLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DEXLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'DEXLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DEXLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'DEXLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'DEXLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(bytes32 initHash, address factory, uint amountIn, address[] memory path, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'DEXLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(initHash, factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(bytes32 initHash, address factory, uint amountOut, address[] memory path, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'DEXLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(initHash, factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee);
        }
    }
}

// Ownable Contract
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// interface IDEXRouter
interface IDEXRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    // function swapExactTokensForTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external returns (uint[] memory amounts);
    // function swapTokensForExactTokens(
    //     uint amountOut,
    //     uint amountInMax,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path, uint256 dexId) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path, uint256 dexId) external view returns (uint[] memory amounts);
}
interface IDEXRouter02 is IDEXRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 dexId
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 usd,
        uint256 dexId
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 usd,
        uint256 dexId
    ) external;
}

// interface IERC20
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

// interface IWETH
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}

interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface AnjiReferral {
    function referralBuy(address referrer, uint256 bnbBuy, address tokenAddr) external;
}

interface AnjiFees {
    function distributeDividend() external;
}

contract AnjiRouter is IDEXRouter02, Ownable {
    using SafeMath for uint;

    struct DEX {
        string name;
        address factory;
        address router;
        bytes32 initHash;
        uint256 fee;
        bool enabled;
        uint256 id;
    }

    mapping (uint256 => DEX) public dexList;
    uint256 public dexCount;

    event Result(string);
    address public override factory;
    address public override WETH;
    address public anjiReferral;
    uint256 public busdThreshold = 100;

    address public feeReceiver;
    bool public feeOFF = false;
    bool public feeDistribute;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'AnjiRouter: EXPIRED');
        _;
    }

    constructor(
        address _WETH,
        bool _feeDistribute,
        string[] memory dexNames,
        address[] memory dexFactories,
        address[] memory dexRouters,
        bytes32[] memory dexInitHashes,
        uint256[] memory dexFees
    ) public {
        feeDistribute = _feeDistribute;
        WETH = _WETH;
        feeReceiver = msg.sender;

        for (uint256 index = 0; index < dexNames.length; index++) {
            dexCount++;
            dexList[dexCount] = DEX({
                name: dexNames[index],
                factory: dexFactories[index],
                router: dexRouters[index],
                initHash: dexInitHashes[index],
                fee: dexFees[index],
                enabled: true,
                id: dexCount
            });
        }
    }

    function addDex(string memory name, address _factory, address router, bytes32 _initHash, uint256 fee, bool enabled) external onlyOwner {
        dexCount++;
        dexList[dexCount] = DEX({
            name: name,
            factory: _factory,
            router: router,
            initHash: _initHash,
            fee: fee,
            enabled: enabled,
            id: dexCount
        });
    }

    function setDEXEnabled(uint256 dexID, bool enabled) external onlyOwner {
        dexList[dexID].enabled = enabled;
    }

    function getLargestDEX(address tokenA, address tokenB) public view returns (uint256) {
        uint256 largestReserve = 0;
        uint256 dexId = 0;

        // DEX Id's start at 1
        for(uint256 i = 1; i < dexCount; i++){
            if(!dexList[i].enabled){ continue; }

            if(IDEXFactory(dexList[i].factory).getPair(tokenA, tokenB) != address(0)){
                (uint256 reserve0, uint256 reserve1) = DEXLibrary.getReserves(dexList[i].initHash, dexList[i].factory, tokenA, tokenB);

                if(reserve0 + reserve1 > largestReserve){
                    largestReserve = reserve0 + reserve1;

                    dexId = dexList[i].id;
                }
            }
        }

        return dexId;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setReceiverAddress(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setBUSDThreshold(uint256 _threshold) public onlyOwner {
        busdThreshold = _threshold;
    }

    function setFeeDistribute(bool _feeDistribute) public onlyOwner {
        feeDistribute = _feeDistribute;
    }

    function setAnjiReferral(address _anjiReferral) public onlyOwner {
        anjiReferral = _anjiReferral;
    }

    function _feeAmount(uint amount, bool isReferrer, uint usd) public view returns (uint) {
        if (isReferrer == true){
            return amount.mul(2)/1000;
        }

        if (usd>= busdThreshold) {
            return amount.mul(1)/1000;

        } else {
            return amount.mul(2)/1000;
        }
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, bytes32 initHash, address _factory) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? DEXLibrary.pairFor(initHash, _factory, output, path[i + 2]) : _to;
            IDEXPair(DEXLibrary.pairFor(initHash, _factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'AnjiR: INVALID_PATH');
        //uint amountIn = msg.value;
        uint fee = _feeAmount(msg.value, false, usd);
        uint amount = msg.value - fee;
        amounts = DEXLibrary.getAmountsOut(dexList[dexId].initHash, dexList[dexId].factory, amount, path, dexList[dexId].fee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'AnjiR: INSUF_OUTA');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, dexList[dexId].initHash, dexList[dexId].factory);
        //send the fee to the fee receiver
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

    }

    function referrerSwapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(msg.sender != referrer, "Sender=Referrer");
        require(referrer != address(0), "No Referrer");
        require(path[0] == WETH, 'AnjiR: INVALID_PATH');
        //uint amountIn = msg.value;
        uint fee = _feeAmount(msg.value, true, usd);
        //uint amount = msg.value - fee;

        amounts = DEXLibrary.getAmountsOut(dexList[dexId].initHash, dexList[dexId].factory, msg.value - fee, path, dexList[dexId].fee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'AnjiR: INSUF_OUTA');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, dexList[dexId].initHash, dexList[dexId].factory);
        //send the fee to the fee receiver
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee/2);
            TransferHelper.safeTransferETH(referrer, fee/2);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        AnjiReferral(anjiReferral).referralBuy(referrer, msg.value, path[1]);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {

        require(path[0] == WETH, 'AnjiR: INVALID_PATH');

        amounts = DEXLibrary.getAmountsIn(dexList[dexId].initHash, dexList[dexId].factory, amountOut, path, dexList[dexId].fee);
        require(amounts[0] <= msg.value, 'AnjiR: EXC_INA');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, dexList[dexId].initHash, dexList[dexId].factory);

        //send the fee to the fee receiver
        uint fee = _feeAmount(amounts[0], false, usd);
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        // refund dust eth, if any
        if (msg.value - fee > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0] - fee);
    }

    function referrerSwapETHForExactTokens(uint amountOut, address[] calldata path, address to, address referrer, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(msg.sender != referrer, "Sender=Referrer");
        require(referrer != address(0), "No Referrer");
        require(path[0] == WETH, 'AnjiR: INVALID_PATH');
        amounts = DEXLibrary.getAmountsIn(dexList[dexId].initHash, dexList[dexId].factory, amountOut, path, dexList[dexId].fee);
        require(amounts[0] <= msg.value, 'AnjiR: EXCINA');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, dexList[dexId].initHash, dexList[dexId].factory);

        //send the fee to the fee receiver
        uint fee = _feeAmount(amounts[0], true, usd);
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee/2);
            TransferHelper.safeTransferETH(referrer, fee/2);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        // refund dust eth, if any
        if (msg.value - fee > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0] - fee);

        AnjiReferral(anjiReferral).referralBuy(referrer, msg.value, path[1]);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'AnjiR: INVALID_PATH');
        amounts = DEXLibrary.getAmountsIn(dexList[dexId].initHash, dexList[dexId].factory, amountOut, path, dexList[dexId].fee);
        require(amounts[0] <= amountInMax, 'AnjiR: EXCIA');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), dexList[dexId].initHash, dexList[dexId].factory);

        uint fee = _feeAmount(amounts[amounts.length - 1], false, usd);
        uint sendingAmount = amounts[amounts.length - 1].sub(fee);

        if (fee > 0){
            IWETH(WETH).withdraw(fee);
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        IWETH(WETH).withdraw(sendingAmount);
        TransferHelper.safeTransferETH(to, sendingAmount);

    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'AnjiR: INVALID_PATH');
        amounts = DEXLibrary.getAmountsOut(dexList[dexId].initHash, dexList[dexId].factory, amountIn, path, dexList[dexId].fee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'AnjiR: INSUFOUTA');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), dexList[dexId].initHash, dexList[dexId].factory);

        uint fee = _feeAmount(amounts[amounts.length - 1], false, usd);
        uint sendingAmount = amounts[amounts.length - 1].sub(fee);

        if (fee > 0){
            IWETH(WETH).withdraw(fee);
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        IWETH(WETH).withdraw(sendingAmount);
        TransferHelper.safeTransferETH(to, sendingAmount);
    }


    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, DEX memory dex) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            IDEXPair pair = IDEXPair(DEXLibrary.pairFor(dex.initHash, dex.factory, input, output));
            // uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            // amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = DEXLibrary.getAmountOut(IERC20(input).balanceOf(address(pair)).sub(reserveInput), reserveInput, reserveOutput, dex.fee);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? DEXLibrary.pairFor(dex.initHash, dex.factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 dexId
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, dexList[dexId]);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'AnjiR: INSUFOA'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 usd,
        uint256 dexId
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'AnjiR:INVALID_PATH');
        //uint amountIn = msg.value;
        uint fee = _feeAmount(msg.value, false, usd);
        uint amount = msg.value - fee;
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amount));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, dexList[dexId]);
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'AnjiR:INSUFOA'
        );
    }

    function referralSwapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline, uint256 usd, uint256 dexId)
        external
        virtual
        payable
        ensure(deadline)
    {
        require(msg.sender != referrer, "Sender=Referrer");
        require(referrer != address(0), "NoReferrer");
        require(path[0] == WETH, 'AnjiR:INVALID_PATH');
        //uint amountIn = msg.value;
        uint fee = _feeAmount(msg.value, true, usd);
        //uint amount = msg.value - fee;
        IWETH(WETH).deposit{value: msg.value - fee}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), msg.value - fee));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, dexList[dexId]);
        if (fee > 0) {
            TransferHelper.safeTransferETH(feeReceiver, fee/2);
            TransferHelper.safeTransferETH(referrer, fee/2);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'AnjiR:INSUFOA'
        );
        AnjiReferral(anjiReferral).referralBuy(referrer, msg.value, path[1]);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 usd,
        uint256 dexId
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'AnjiR:INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(dexList[dexId].initHash, dexList[dexId].factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), dexList[dexId]);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'AnjiR:INSUFOA');

        uint fee = _feeAmount(amountOut, false, usd);
        uint sendingAmount = amountOut.sub(fee);

        if (fee > 0){
            IWETH(WETH).withdraw(fee);
            TransferHelper.safeTransferETH(feeReceiver, fee);
        }

        if(feeDistribute && address(feeReceiver).balance > 3){
            try AnjiFees(feeReceiver).distributeDividend{gas: 77589 }() {
                emit Result("success");
            } catch (bytes memory) {
                emit Result("failed");
            }
        }

        IWETH(WETH).withdraw(sendingAmount);
        TransferHelper.safeTransferETH(to, sendingAmount);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return DEXLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return DEXLibrary.getAmountOut(amountIn, reserveIn, reserveOut,9975);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return DEXLibrary.getAmountIn(amountOut, reserveIn, reserveOut, 9975);
    }

    function getAmountsOut(uint amountIn, address[] memory path, uint256 dexId)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return DEXLibrary.getAmountsOut(dexList[dexId].initHash, dexList[dexId].factory, amountIn, path, dexList[dexId].fee);
    }

    function getAmountsIn(uint amountOut, address[] memory path, uint256 dexId)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return DEXLibrary.getAmountsIn(dexList[dexId].initHash, dexList[dexId].factory, amountOut, path, dexList[dexId].fee);
    }
}