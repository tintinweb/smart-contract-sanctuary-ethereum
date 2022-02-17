// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./libraries/TransferHelper.sol";

import "./interfaces/IFlypeRouter01.sol";
import "./libraries/FlypeLibrary.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFlypeDiscounter.sol";

contract FlypeRouter01 is FlypeLibrary {
    
    address public immutable factory;
    address public immutable WETH;
    address public immutable DMM;

    event RemoveLiquidity(address token, address reciever, uint256 liquidity, uint256 amountToken, uint256 amountETH);
    event AddLiquidity(address token, address reciever, uint256 liquidity, uint256 amountToken, uint256 amountETH);
    event Swap(uint256[] amounts, address[] path, address to, uint256[] fees);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "FlypeRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH, Dmm _DMM) FlypeLibrary(_factory, _WETH, _DMM){
        factory = _factory;
        WETH = _WETH;
        DMM = address(_DMM);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn"t exist yet
        if (IFlypeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IFlypeFactory(factory).createPair(tokenA, tokenB);
        }        
        (uint256 priceLP, uint256 priceETH) = getPrices(tokenA, tokenB);
        uint256 amountBOptimal = quote(amountADesired, priceLP, priceETH);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "FlypeRouter: INSUFFICIENT_B_AMOUNT");
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = quote(amountBDesired, priceETH, priceLP);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal >= amountAMin, "FlypeRouter: INSUFFICIENT_A_AMOUNT");
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    /// @notice Adds liquidity to Flype pair
    /// @param token LpToken address
    /// @param amountTokenDesired Desired amount amount of spending lpTokens
    /// @param amountTokenMin Minimum amount of spending lpToken
    /// @param amountETHMin Minimum amount of spending ETH
    /// @param to Address of person who received  Flype lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amountToken Amount of spended lpTokens
    /// @return amountETH Amount of spended WETH
    /// @return liquidity Amount of received Flype lpTokens
    function addLiquidity(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = pairFor(token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IFlypePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        emit AddLiquidity(token, to, liquidity, amountToken, amountETH);
    }
    
    // **** REMOVE LIQUIDITY ****
    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) internal virtual ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB);
        require(pair != address(0), "FlypeRouter: WRONG_PAIR");
        IFlypePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IFlypePair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "FlypeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "FlypeRouter: INSUFFICIENT_B_AMOUNT");
    }

    /// @notice Exchange Flype lpToken for lpToken and WETH
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amountToken Amount of recieved lpToken
    /// @return amountETH Amount of recieved ETH
    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = _removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        emit RemoveLiquidity(token, to, liquidity, amountToken, amountETH);
    }

    /// @notice Exchange Flype lpToken for lpToken and WETH by signature
    /// @param token Address of desired lpToken, it must be in the Flype lpToken that is being exchanged
    /// @param liquidity Amount of Flype lpToken, that is being exchanged
    /// @param amountTokenMin Minimum amount of recieved lpToken
    /// @param amountETHMin Minimum amount of recieved WETH
    /// @param to Address of person who recieved lpTokens and ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @param approveMax If true => approve max uint from user to this contract
    /// @param v Part of the splited signature
    /// @param r Part of the splited signature
    /// @param s Part of the splited signature
    /// @return amountToken Amount of recieved lpToken
    /// @return amountETH Amount of recieved ETH
    function removeLiquidityWithPermit(
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
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        address pair = pairFor(token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IFlypePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidity(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }


    // **** SWAP ****
    /// @notice swap lpTokens or WETH in path 
    /// @dev requires the initial amount to have already been sent to the first pair
    /// @param amounts Calculated by FlypeLibrary amount of lpTokens to swap 
    /// @param path Array of lpToken and WETH address, see details below
    /// @param _to Address of person who recieved lpTokens and ETH
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : _to;
            IFlypePair(FlypeLibrary.pairFor(input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of desired lpToken
    /// @param amountIn Exact amount of swapped lpToken 
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from  swapped lpToken to desired, it must be always in form [lpToken, WETH, lpToken]
    /// @param to Address of person who recieved desired lpToken
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 3 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsOut(amountIn, path, msg.sender);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
        emit Swap(amounts, path, to, fees);
    }

    /// @notice Swap some amount of lpToken for exact amount of desired lpToken
    /// @param amountOut Exact amount of desired lpToken 
    /// @param amountInMax Maximum amount of swapped lpToken
    /// @param path Array of addresses from  swapped lpToken to desired, it must be always in form [lpToken, WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 3 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsIn(amountOut, path, msg.sender);
        require(amounts[0] <= amountInMax, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
        emit Swap(amounts, path, to, fees);

    }

    /// @notice Swap exact amount of ETH for equivalent amount of desired lpToken
    /// @param amountOutMin Minimum amount of desired lpToken
    /// @param path Array of addresses from ETH to desired lpToken, it must always be in form [WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual payable ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 2 && path[0] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsOut(msg.value, path, msg.sender);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        emit Swap(amounts, path, to, fees);    
    }

    /// @notice Swap some amount of lpToken for exact amount of ETH
    /// @param amountOut Exact amount of ETH 
    /// @param amountInMax Maximum amount of swapped lpToken
    /// @param path Array of addresses from lpToken to ETH, it must always be in form [lpToken, WETH]
    /// @param to Address of person who recieved ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 2 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsIn(amountOut, path, msg.sender);
        require(amounts[0] <= amountInMax, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        emit Swap(amounts, path, to, fees);
    }

    /// @notice Swap exact amount of lpToken for equivalent amount of ETH
    /// @param amountIn Exact amount of swapped lpTokens 
    /// @param amountOutMin Minimum amount of recieved ETH
    /// @param path Array of addresses from lpToken to ETH, it must always be in form [lpToken, WETH]
    /// @param to Address of person who recieved ETH
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 2 && path[1] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsOut(amountIn, path, msg.sender);
        require(amounts[amounts.length - 1] >= amountOutMin, "FlypeRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, pairFor(path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        emit Swap(amounts, path, to, fees);
    }

    /// @notice Swap some amount of ETH for exact amount of desired lpToken
    /// @param amountOut Exact amount of desired lpToken
    /// @param path Array of addresses from ETH to desired lpToken, it must always be in form [WETH, lpToken]
    /// @param to Address of person who recieved desired lpTokens
    /// @param deadline block.timestamp before which transaction can be confirmed
    /// @return amounts Array which contain amounts for swaps path and fee on each swap in usd(e18) 
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual payable ensure(deadline) returns (uint256[] memory amounts, uint256[] memory fees) {
        require(path.length == 2 && path[0] == WETH, "FlypeRouter: INVALID_PATH");
        (amounts, fees) =  getAmountsIn(amountOut, path, msg.sender);
        require(amounts[0] <= msg.value, "FlypeRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0])TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        uint256 refund = msg.value - amounts[0];
        amounts[0] -= refund; 
        emit Swap(amounts, path, to, fees);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeUPM {
    function getPrice(address lpPair) external view returns (uint price);
    function getPriceETH() external view returns(uint priceETH);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/access/AccessControl.sol";
contract Dmm is AccessControl{
    uint public constant a_ACC = 1e1;
    uint public constant tenthRootFrom1e18 = 63_095734448; // 1e18 ^ (1/10)
    uint[] public MAX_VALUE = [37, 25, 18, 15, 12, 10, 9, 7];

    uint public a;
    uint public b;
    uint public b_ACC;

    modifier liquidityCheck(uint256 reserve, uint256 amountSwapped){
        require(reserve > amountSwapped, "INSUFFICIENT LIQUIDITY");
        _;
    }

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setAdminsValues(
        uint256 _a,
        uint256 _b,
        uint256 _b_ACC
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_b < _b_ACC, "b must be in this range: 0<=b<1");
        require(_b_ACC > 0, "accuracy of b must be greater than 1");
        require(_a > 0, "a must be greater than 0");
        a = _a;
        b = _b;
        b_ACC = _b_ACC;
    }    

    function getAmountInForEthToLpSwap(uint256 lpPrice, uint256 ethPrice, uint256 lpReserve, uint256 ethReserve, uint256 amountSwapped) external view liquidityCheck(lpReserve, amountSwapped) returns(uint256 quote){
        uint D = getD(lpPrice, ethPrice, lpReserve, ethReserve);
        //ΔX = ΔY = D*Xc*ΔX / (Xc-ΔX)
        quote = lpReserve * amountSwapped * D / (lpReserve - amountSwapped) / 1e18;
    }

    function getAmountOutForEthToLpSwap(uint256 lpPrice, uint256 ethPrice, uint256 lpReserve, uint256 ethReserve, uint256 amountSwapped) external view returns(uint256 quote){
        uint D = getD(lpPrice, ethPrice, lpReserve, ethReserve);
        //ΔX = Xc*ΔY / (Xc*D+ΔY)
        quote = lpReserve * amountSwapped * 1e18 / (lpReserve * D + amountSwapped * 1e18); 
    }     

    function getAmountInForLpToEthSwap(uint256 lpPrice, uint256 ethPrice, uint256 lpReserve, uint256 ethReserve, uint256 amountSwapped) external view liquidityCheck(ethReserve, amountSwapped) returns(uint256 quote){
        uint D = getD(lpPrice, ethPrice, lpReserve, ethReserve);
        //ΔX = Yc*ΔY / (D*(Yc-ΔY)
        quote = ethReserve * amountSwapped * 1e18 / (D * ethReserve - D * amountSwapped);
    }

    function getAmountOutForLpToEthSwap(uint256 lpPrice, uint256 ethPrice, uint256 lpReserve, uint256 ethReserve, uint256 amountSwapped) external view returns(uint256 quote){
        uint D = getD(lpPrice, ethPrice, lpReserve, ethReserve);
        //ΔY= Yc*D*ΔX / (Yc+D*ΔX)
        quote = ethReserve * D * amountSwapped / (ethReserve * 1e18 + D * amountSwapped);
    }

    function getD(uint256 lpPrice, uint256 ethPrice, uint256 lpReserve, uint256 ethReserve) public view returns(uint){
        uint256 k = lpPrice * lpReserve * 1e18 / (ethPrice * ethReserve) + 1;
        uint256 root1 = 1e18;
        if(k != 1e18){
            if(a%10 > 0){     
                uint sqr = 1e18;
                for(uint256 i; i < a%10; i++){
                    sqr = sqr * k / 1e18;
                }
                root1 = nthRootWithoutSlice(sqrt(sqr), 5, 5, 1000) * 1e22 / tenthRootFrom1e18;
            }        
            if(a >= 10){
                for(uint i = 0; i < (a - a%10)/10; i++) root1 = root1 * k / 1e18;
            }
        }
        //D = K * (1+b*(1-k^a)/(1+k^a))
        int256 D = int(k) * int(1e18 + 
        int(int(b) * int(1e18 - int(root1)) * 1e18 / int(1e18 + root1) / int(b_ACC))
        ) /1e18;
        return uint(D);
    }

    // calculates a^(1/n) to dp decimal places
    // maxIts bounds the number of iterations performed
    function nthRoot(uint _a, uint _n, uint _dp, uint _maxIts) public pure returns(uint) {
        if (_n == 1 || _a == 1) return _a * 10 ** _dp;
        if (_n == 0) return 10 ** _dp;
        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint one = 10 ** (1 + _dp);
        uint a0 = one ** _n * _a;

        // Initial guess: 1.0
        uint xNew = one;
        uint x;
        uint iter = 0;
        while (xNew != x && iter < _maxIts) {
            x = xNew;
            uint t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;
            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
        }
        // Round to nearest in the last dp.
        return xNew/10;
    }

    function nthRootWithoutSlice(uint _a, uint _n, uint _dp, uint _maxIts) public view returns(uint result) {
       if(_n == 1) return (_a * 10**_dp);
       if(_n == 0) return (10**_dp);
       uint256 sliced;
       while(_a % (10 ** (MAX_VALUE[_n - 2] - _dp)) < _a){ 
            _a /= 10;
            sliced++;
        }
        result = nthRoot(_a, _n, _dp, _maxIts);
        if(sliced > 0){
            result = result * (10 ** (sliced/_n)) * nthRootWithoutSlice(10**(sliced%_n), _n, _dp,  800) / 10 ** _dp;
        }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../Core/interfaces/IFlypeFactory.sol";
import "../../Core/interfaces/IFlypePair.sol";
import "../interfaces/IFlypeStaking.sol";
import "../upm/interfaces/IFlypeUPM.sol";
import "../upm/DMM.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FlypeLibrary is Ownable {
    uint256 public constant MAX_DISCOUNT = 100;

    address public flypeUPM;
    address public staking;
    Dmm public _DMM;

    uint256[] public discountThresholds;
    uint256[] public discounts;
    
    address internal _factory;
    address internal _WETH;    

    constructor(address factory, address WETH, Dmm DMM_){
        _factory = factory;
        _WETH = WETH;
        _DMM = DMM_;
    }

    /// @notice Set flype token address for discounts
    /// @param _staking Flype staking address
    function setFlypeStaking(address _staking) external onlyOwner{
        staking = _staking;
    }

    /// @notice Set flype token address for discounts
    /// @param DMM_ Flype DMM address
    function setFlypeDMM(Dmm DMM_) external onlyOwner{
        _DMM = DMM_;
    }

    /// @notice Set discounts and discountThresholds for Flype holders
    /// @param _discountThresholds balance limits for discount
    /// @param _discounts discount size
    /// @dev discounts have decimals -> 2
    function setThresholdsAndDiscount(uint[] memory _discountThresholds, uint256[] memory _discounts) external onlyOwner{
        require(_discountThresholds.length == _discounts.length, "Length mismatch"); //TOS+DOncomments
        if(_discounts.length > 1){
            for(uint256 i; i < _discounts.length - 1; i++){
                require(_discounts[i] > _discounts[i+1], "Numbers must be from largest to smallest");
                require(_discountThresholds[i] > _discountThresholds[i+1], "Numbers must be from largest to smallest");
                require( _discounts[i] <= MAX_DISCOUNT && _discounts[i+1] <= MAX_DISCOUNT, "Discount must be with only 2 digits");
            }
        }
        discountThresholds = _discountThresholds;
        discounts = _discounts;
    }

    /// @notice Returns discount for specific user based on his flype token balance
    /// @param user User address
    function discountCalculator(address user) public view returns (uint discountSize){
        uint balance = IFlypeStaking(staking).flypePoolInfo(user);
        if(Address.isContract(user)) return 0;

        for(uint256 i; i < discounts.length; i++){
            if(balance >= discountThresholds[i]) return discounts[i];
        }
    }
    
    /// @notice Set flypeUPM to receive price and reserves of lpTokens
    /// @param _flypeUPM FlypeUPM address
    function setFlypeUPM(address _flypeUPM) external onlyOwner{
        flypeUPM = _flypeUPM;
    }
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'FlypeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'FlypeLibrary: ZERO_ADDRESS');
    }

    /// @notice Returns pair of lpToken from specific factory
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function pairFor(address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IFlypeFactory(_factory).getPair(token0, token1);
    }

    /// @notice Returns and sorts the reserves for a pair
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function getReserves(address tokenA, address tokenB) public view returns (uint reserveLp, uint reserveEth) {
        (uint reserve0, uint reserve1,) = IFlypePair(pairFor(tokenA, tokenB)).getReserves();
        if( IFlypePair(pairFor(tokenA, tokenB)).token0() == _WETH){
            (reserveLp, reserveEth) = (reserve1, reserve0);            
        } else{
            (reserveLp, reserveEth) = (reserve0, reserve1); 
        }
    }
    
    /// @notice Returns prices for pair
    /// @param tokenA Token1 address
    /// @param tokenB Token2 address
    function getPrices(address tokenA, address tokenB) public view returns (uint priceLp, uint priceETH) {
        // (uint reserve0, uint reserve1,) = IFlypePair(pairFor(factory, tokenA, tokenB)).getReserves();
        priceLp = IFlypeUPM(flypeUPM).getPrice(pairFor(tokenA, tokenB));
        priceETH = IFlypeUPM(flypeUPM).getPriceETH();
    }

    /// @notice Given some amount of an asset and pair price, returns an equivalent amount of the other asset
    /// @param amountA Amount of swapped token
    /// @param priceA Price of first token in pair
    /// @param priceB Price of second token in pair
    function quote(uint amountA, uint priceA, uint priceB) public pure returns (uint amountB) {
        require(amountA > 0, 'FlypeLibrary: INSUFFICIENT_AMOUNT');
        // require(reserveA > 0 && reserveB > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * priceA / priceB;
    }

    /// @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    /// @param amount Amount calculated 
    /// @param priceIn Price of swapped lpToken or WETH
    /// @param user Address of user who called swap function
    /// @return amountOut Equivalent amount of desired lpToken or WETH  
    function getAmountOut(uint amount, uint priceIn, address user, bool doubleSwap) internal view returns (uint amountOut, uint256 fee) {
        amountOut = amount * (99800 + 2 * discountCalculator(user)) / 1e5;
        fee = (amount - amountOut) / (doubleSwap? 2 : 1);
        amountOut = amount - fee;
        fee = fee * priceIn / 1e18;
    }
    

    /// @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param amount Amount calculated 
    /// @param priceIn Price of swapped lpToken or WETH 
    /// @param user Address of user who called swap function
    /// @return amountIn Equivalent amount of swapped lpToke or WETH  
    function getAmountIn(uint amount, uint priceIn, address user, bool doubleSwap) internal view returns (uint amountIn, uint256 fee) {
        amountIn = amount * 1e5 / (99800 + 2 * discountCalculator(user));
        fee = (amountIn - amount) / (doubleSwap? 2 : 1);
        amountIn = amount + fee;
        fee = fee * priceIn / 1e18;
    }

    /// @notice Performs chained getAmountOut calculations on any number of pairs
    /// @param amountIn Amount of swapped lpToken or WETH
    /// @param path Array of addresses from  swapped lpToken to desired, there is 2 type of swap:
    ///     1)   from WETH to lpToken or backwards
    ///     2)   from lpToken to another lpToken
    ///     For 1) case path might be: [WETH, lpToken] or backwards
    ///     For 2) case path always be: [lpToken, WETH, lpToken]
    /// @param user Address of user who called swap function
    /// @return amounts Amount of desired lpToken or WETH
    function getAmountsOut(uint amountIn, address[] memory path, address user) public view returns (uint[] memory amounts, uint256[] memory fees) {
        require(path.length == 2 || path.length == 3, 'FlypeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        fees = new uint[](path.length - 1);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveLp, uint reserveEth) = getReserves(path[i + 1], path[i]);
            require(reserveLp > 0 && reserveEth > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
            (uint priceLp, uint priceEth) = getPrices(path[i], path[i + 1]);   
            (path[i] == _WETH)?
            (amounts[i + 1], fees[i]) = getAmountOut(
                _DMM.getAmountOutForEthToLpSwap(priceLp, priceEth, reserveLp, reserveEth, amounts[i]),
                priceEth, user, path.length == 3)
             :
             (amounts[i + 1], fees[i]) = getAmountOut(
                _DMM.getAmountOutForLpToEthSwap(priceLp, priceEth, reserveLp, reserveEth, amounts[i]), 
                priceLp, user, path.length == 3);
        }
    }
    /// @notice Performs chained getAmountIn calculations on any number of pairs
    /// @param amountOut Amount of desired lpToken or WETH
    /// @param path Array of addresses from  swapped lpToken to desired, there is 2 type of swap:
    ///     1)   from WETH to lpToken or backwards
    ///     2)   from lpToken to another lpToken
    ///     For 1) case path might be: [WETH, lpToken] or backwards
    ///     For 2) case path always be: [lpToken, WETH, lpToken]
    /// @param user Address of user who called swap function
    /// @return amounts Amount of swapped lpToken or WETH
    function getAmountsIn(uint amountOut, address[] memory path, address user) public view returns (uint[] memory amounts, uint256[] memory fees) {
        require(path.length >= 2, 'FlypeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        fees = new uint256[](path.length - 1);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveLp, uint reserveEth) = getReserves(path[i - 1], path[i]);
            require(reserveLp > 0 && reserveEth > 0, 'FlypeLibrary: INSUFFICIENT_LIQUIDITY');
            (uint priceLp, uint priceEth) = getPrices(path[i - 1], path[i]);      

            (path[i] == _WETH)?
             (amounts[i - 1], fees[i - 1]) = getAmountIn(
                _DMM.getAmountInForLpToEthSwap(priceLp, priceEth, reserveLp, reserveEth, amounts[i]),
                 priceLp, user, path.length == 3)
             :
             (amounts[i - 1], fees[i - 1]) = getAmountIn(
                 _DMM.getAmountInForEthToLpSwap(priceLp, priceEth, reserveLp, reserveEth, amounts[i]), 
                 priceEth, user, path.length == 3);
        }
    }

    function getD(address flypeLp) external view returns(uint){
        IFlypePair pairInst = IFlypePair(flypeLp);
        (uint lpPrice, uint ethPrice) = getPrices(pairInst.token0(), pairInst.token1());
        (uint lpReserve, uint ethReserve) = getReserves(pairInst.token0(), pairInst.token1());
        return(_DMM.getD(lpPrice, ethPrice, lpReserve, ethReserve));
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeStaking{
    function flypePoolInfo(address user) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './IFlypeRouter.sol';

interface IFlypeRouter01 is IFlypeRouter {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
    ) external returns (uint[] memory amounts, uint256[] memory fees);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts, uint256[] memory fees);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts, uint256[] memory fees);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts, uint256[] memory fees);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts, uint256[] memory fees);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts, uint256[] memory fees);

    function quote(uint amountA, uint reserveA, uint reserveB) external view returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut, uint256 fee);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn, uint256 fee);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts, uint256[] memory fees);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts, uint256[] memory fees);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeDiscounter {
    function discountCalculator(address user) external view returns (uint discountSize);
    function getPrices(address factory, address tokenA, address tokenB) external view returns (uint priceA, uint priceB);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './IFlypeERC20.sol';

interface IFlypePair is IFlypeERC20 {

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeFactory {

    function feeTo() external view returns (address);
    
    function feeToSetter() external view returns (address);
    function isRouter(address router) external view returns(bool);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeERC20 {

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}