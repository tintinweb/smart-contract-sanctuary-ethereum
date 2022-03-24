// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFeeHandler.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external pure returns(uint256[] memory);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

contract FeeHandler is IFeeHandler, Ownable {
    /*
        Marketplace tax,
        Hunting tax,
        Damage for legions,
        Summon fee,
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address constant BLST = 0xd8344cc7fEbce19C2182988Ad219cF3553664356;
    uint[6] fees = [1500,250,100,18,13,24];
    IDEXRouter public router;
    
    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }
    function getFee(uint8 _index) external view override returns (uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyOwner {
        require(_index>=0 && _index<6, "Unknown fee type");
        fees[_index] = _fee;
    }

    function getSummoningPrice(uint256 _amount) external view override returns(uint256) {
        uint256 UsdValue = fees[3];
        uint256 amountIn;
        if(_amount==1) {
            amountIn = UsdValue*10**6;
        } else if(_amount==10) {
            amountIn = UsdValue*10*99*10**4;
        } else if(_amount==50) {
            amountIn = UsdValue*50*98*10**4;
        } else if(_amount==100) {
            amountIn = UsdValue*100*97*10**4;
        } else if(_amount==150) {
            amountIn = UsdValue*150*95*10**4;
        } else {
            amountIn = UsdValue*_amount*10**6;
        }
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(amountIn, path)[1];
    }
    function getTrainingCost(uint256 _count) external view override returns(uint256) {
        if(_count==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_count*(10**6)/2, path)[1];
    }
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==0) return 0;
        if(_supply==7) {
            return getBLSTAmount(7*_warriorCount);
        } else if(_supply==14) {
            return getBLSTAmount(fees[4]*_warriorCount);
        } else if (_supply==28) {
            return getBLSTAmount(fees[5]*_warriorCount);
        } else {
            return getBLSTAmount(_supply*_warriorCount);
        }
    }

    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==7) {
            return 7*_warriorCount*10000;
        } else if(_supply==14) {
            return fees[4]*_warriorCount*10000;
        } else if (_supply==28) {
            return fees[5]*_warriorCount*10000;
        } else {
            return _supply*_warriorCount*10000;
        }
    }

    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view override returns(uint256) {
        if(_warriorCount==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut((_remainingHunts*_warriorCount)*10**6+_warriorCount*10**6/2, path)[1];
    }
    function getBLSTAmountFromUSD(uint256 _usd) external view override returns(uint256) {
        return getBLSTAmount(_usd);
    }
    function getUSDAmountInBLST(uint256 _blst) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTAmount(uint256 _usd) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_usd*10**6, path)[1];
    }
    function getUSDAmountFromBLST(uint256 _blst) external view override returns(uint256) {
        if(_blst==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTReward(uint256 _reward) external view override returns(uint256) {
        if(_reward==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_reward*10**2, path)[1];
    }
    function getExecuteAmount() external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(fees[3]*10**6*2/10, path)[1]; // 20% will return back to player
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
    function getSummoningPrice(uint256 _amount) external view returns(uint256);
    function getTrainingCost(uint256 _count) external view returns(uint256);
    function getBLSTAmountFromUSD(uint256 _usd) external view returns(uint256);
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view returns(uint256);
    function getBLSTReward(uint256 _reward) external view returns(uint256);
    function getExecuteAmount() external view returns(uint256);
    function getUSDAmountInBLST(uint256 _blst) external view returns(uint256);
    function getUSDAmountFromBLST(uint256 _blst) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
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