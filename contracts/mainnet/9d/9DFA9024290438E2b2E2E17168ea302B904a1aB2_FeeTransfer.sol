/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: UNLICENSED

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: contracts/interfaces/IRouter.sol

pragma solidity 0.8.10;

interface IRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
        external 
        returns (uint[] memory amounts);
}

// File: contracts/FeeTransfer.sol

pragma solidity 0.8.10;


contract FeeTransfer is Ownable {

    uint constant public DIV_PERCENTAGE = 100000;
    uint constant public MAX_VALUE = type(uint256).max;

    struct FeeRange{
        uint minRange;  // 10^6 range, USDC
        uint maxRange;  
        uint fee;       // 1fee = 0,01%; 10fee = 0,1%
    }
    
    uint public maxFee = 1000000000;
    uint public minimumAmountToSwapInToken = 10000000;
    uint public fixedFeeInToken = 1000000;
    uint public totalRanges;
    address public feeReceiver;
    address public nativeToken;
    address public swapToken;
    address public feeRouter;
    address[] public ETHToTokenPath;
    address[] public TokenToETHPath;
    mapping(uint => FeeRange) public feeRanges;
    IRouter public router;

    constructor(IRouter _router, address[] memory _ethToTokenPath, address[] memory _tokenToEthPath, address _swapToken, address _nativeToken, address _feeReceiver) {
        router = _router;
        ETHToTokenPath = _ethToTokenPath;
        TokenToETHPath = _tokenToEthPath;
        swapToken = _swapToken;
        nativeToken = _nativeToken;
        feeReceiver = _feeReceiver;
    }

    function addFeeRange(uint[] memory ranges, uint[] memory fee) public onlyOwner {
        require(ranges.length > 0, "FeeTransfer: Invalid ranges length");
        require(ranges.length == (fee.length - 1), "FeeTransfer: Invalid ranges and fee length");
        for(uint i = 0; i < (ranges.length - 1); i++) {
            require(ranges[i] < ranges[i+1], "FeeTransfer: Invalid ranges");
        }
        uint prevMax = 0;
        for(uint i = 0; i < ranges.length; i++) {
            require(fee[i] > 0, "FeeTransfer: Invalid fee");
            feeRanges[i] = FeeRange(prevMax, ranges[i], fee[i]);
            prevMax = ranges[i];
        }
        totalRanges = ranges.length + 1;
        feeRanges[ranges.length] = FeeRange(prevMax, MAX_VALUE, fee[fee.length - 1]);
    }

    function setRouter(IRouter _router) public onlyOwner {
        router = _router;
    }

    function setETHToTokenPath(address[] memory _path) public onlyOwner {
        ETHToTokenPath = _path;
    }

    function setTokenToETHPath(address[] memory _path) public onlyOwner {
        TokenToETHPath = _path;
    }

    function setFeeRouter(address _feeRouter) public onlyOwner {
        feeRouter = _feeRouter;
    }

    function setMinimumAmountToSwapInToken(uint _minimumAmountToSwapInToken) public onlyOwner {
        minimumAmountToSwapInToken = _minimumAmountToSwapInToken;
    }

    function setFixedFeeInToken(uint _fixedFeeInToken) public onlyOwner {
        require(minimumAmountToSwapInToken >= _fixedFeeInToken, "FeeTransfer: fixedFee needs to be less or equal to minimumAmountToSwap");
        fixedFeeInToken = _fixedFeeInToken;
    }

    function setMaxFee(uint _maxFee) public onlyOwner {
        maxFee = _maxFee;
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }
    
    function getAmountsOut(uint _amountIn, address[] memory _path) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(_amountIn, _path);
        return amounts[amounts.length - 1];
    }
    
    function convertETHToToken(uint _ethAmount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(_ethAmount, ETHToTokenPath);
        return amounts[amounts.length - 1];
    }

    function convertUSDTToETH(uint amount) public view returns (uint) {
        uint[] memory amounts = router.getAmountsOut(amount, TokenToETHPath);
        return amounts[amounts.length - 1];
    }

    function convertTokenToToken(address _tokenIn, address _tokenOut, uint _amount) public view returns (uint) {
        address[] memory pathToToken = new address[](3);
        pathToToken[0] = _tokenIn;
        pathToToken[1] = nativeToken;
        pathToToken[2] = _tokenOut;
        return getAmountsOut(_amount, pathToToken);
    }
    
    function getAmountInTokensWithFee(uint amountInNoFee, address[] calldata _path) external view returns (uint) {
        uint amount = 0;
        uint maxTokenFee = maxFee;
        uint tokenSwapWithFee = amountInNoFee;
        if(_path[0] != swapToken) {
            tokenSwapWithFee = convertTokenToToken(_path[0], swapToken, amountInNoFee);
            maxTokenFee = convertTokenToToken(swapToken, _path[0], maxFee);
            
        }
        for(uint i = 0; i < totalRanges; i++) {
            if(tokenSwapWithFee > feeRanges[i].minRange && tokenSwapWithFee <= feeRanges[i].maxRange) {
                uint mulFactor = DIV_PERCENTAGE - feeRanges[i].fee;
                uint amountWithFee = amountInNoFee * DIV_PERCENTAGE / mulFactor;
                if(amountWithFee > amountInNoFee + maxTokenFee) {
                    amountWithFee = amountInNoFee + maxTokenFee;
                }
                amount = amountWithFee;
            }
        }
        if (_msgSender() == feeRouter && minimumAmountToSwapInToken > 0 && fixedFeeInToken > 0) {
            require(tokenSwapWithFee >= minimumAmountToSwapInToken, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInTokenAux = fixedFeeInToken;
            if(_path[0] != swapToken) {
                fixedFeeInTokenAux= convertTokenToToken(swapToken, _path[0], fixedFeeInToken);
            }
            amount = amount + fixedFeeInTokenAux;
        }
        return amount;
    }
    
    function getAmountInTokensNoFee(uint amountInWithFee, address[] calldata _path) external view returns (uint) {
        uint amount = 0;
        uint maxTokenFee = maxFee;
        uint tokenSwapNoFee = amountInWithFee;
        if(_path[0] != swapToken) {
            tokenSwapNoFee = convertTokenToToken(_path[0], swapToken, amountInWithFee);
            maxTokenFee = convertTokenToToken(swapToken, _path[0], maxFee);
        }
        for(uint i = 0; i < totalRanges; i++) {
            uint mulFactor = DIV_PERCENTAGE - feeRanges[i].fee;
            uint maxRange = i < (totalRanges - 1) ? feeRanges[i].maxRange * DIV_PERCENTAGE / mulFactor : MAX_VALUE;
            uint minRange = feeRanges[i].minRange * DIV_PERCENTAGE / mulFactor;
            if(tokenSwapNoFee > minRange && tokenSwapNoFee <= maxRange) {
                amount = amountInWithFee * mulFactor / DIV_PERCENTAGE;
                if(amountInWithFee - amount > maxTokenFee) {
                    amount = amountInWithFee - maxTokenFee;
                }
                break;
            }
        }
        if (_msgSender() == feeRouter && minimumAmountToSwapInToken > 0 && fixedFeeInToken > 0) {
            require(tokenSwapNoFee >= minimumAmountToSwapInToken, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInTokenAux = fixedFeeInToken;
            if(_path[0] != swapToken) {
                fixedFeeInTokenAux= convertTokenToToken(swapToken, _path[0], fixedFeeInToken);
            }
            amount = amount - fixedFeeInTokenAux;
        }
        return amount;  
    }

    function getAmountInETHWithFee(uint amountInNoFee) external view returns (uint) {
        uint amount = 0;
        uint tokensWithNoFee = convertETHToToken(amountInNoFee);
        uint maxFeeEth = convertUSDTToETH(maxFee);
        for(uint i = 0; i < totalRanges; i++) {
            if(tokensWithNoFee > feeRanges[i].minRange && tokensWithNoFee <= feeRanges[i].maxRange) {
                uint mulFactor = DIV_PERCENTAGE - feeRanges[i].fee;
                uint amountWithFee = amountInNoFee * DIV_PERCENTAGE / mulFactor;
                if(amountWithFee > amountInNoFee + maxFeeEth) {
                    amountWithFee = amountInNoFee + maxFeeEth;
                }
                amount = amountWithFee;
            }
        } 
        if (_msgSender() == feeRouter && minimumAmountToSwapInToken > 0 && fixedFeeInToken > 0) {
            uint minimumToSwapInETH = convertUSDTToETH(minimumAmountToSwapInToken);
            require(amountInNoFee >= minimumToSwapInETH, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInETH = convertUSDTToETH(fixedFeeInToken);
            amount = amount + fixedFeeInETH;
        }
        return amount;
    }

    function getAmountInETHNoFee(uint amountInWithFee) external view returns (uint) {
        uint amount = 0;
        uint tokensWithFee = convertETHToToken(amountInWithFee);
        uint maxFeeEth = convertUSDTToETH(maxFee);
        for(uint i = 0; i < totalRanges; i++) {
            uint mulFactor = DIV_PERCENTAGE - feeRanges[i].fee;
            uint maxRange = i < (totalRanges - 1) ? feeRanges[i].maxRange * DIV_PERCENTAGE / mulFactor : MAX_VALUE;
            uint minRange = feeRanges[i].minRange * DIV_PERCENTAGE / mulFactor;
            if(tokensWithFee > minRange && tokensWithFee <= maxRange) {
                amount = amountInWithFee * mulFactor / DIV_PERCENTAGE;
                if(amountInWithFee - amount > maxFeeEth) {
                    amount = amountInWithFee - maxFeeEth;
                }
                break;
            }
        }
        if (_msgSender() == feeRouter && minimumAmountToSwapInToken > 0 && fixedFeeInToken > 0  ) {
            uint minimumToSwapInETH = convertUSDTToETH(minimumAmountToSwapInToken);
            require(amountInWithFee >= minimumToSwapInETH, "FeeRouter: INSUFFICIENT_AMOUNT_TO_SWAP");
            uint fixedFeeInETH = convertUSDTToETH(fixedFeeInToken);
            amount = amount - fixedFeeInETH;
        }
        return amount; 
    }
}