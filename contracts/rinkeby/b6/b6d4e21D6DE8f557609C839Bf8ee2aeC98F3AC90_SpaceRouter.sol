// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./ICO/ISpaceCoin.sol";
import "./IPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LP Project
/// @author Agustin Bravo
/// @notice This Router contract faclitates the interaction with the SpacePool contract with checks and calculations.
contract SpaceRouter is Ownable {
    /// Address of the liquidity pool contract.
    address public immutable spaceCoinLP;
    /// Address of SpaceCoin ERC20 Token
    address public immutable spaceCoinToken;

    /// @notice Event emmited once a user adds liquidity to the SpaceCoinLP.
    /// @param to Address where the lp tokens were minted.
    /// @param amountOfSpc Amount of SPC transfered to the pool.
    /// @param amountOfEth Amount of ETH transfered to the pool.
    /// @param lpTokensMinted Amount of LP tokens minted.
    event LiquidityAdd(
        address indexed to,
        uint256 amountOfSpc,
        uint256 amountOfEth,
        uint256 lpTokensMinted
    );

    /// @notice Event emmited once a user removes liquidity from the SpaceCoinLP.
    /// @param to Address where the liquidity assets were sent.
    /// @param amountOfSpc Amount of SPC transfered from the pool.
    /// @param amountOfEth Amount of ETH transfered from the pool.
    /// @param lpTokensBurned Amount of LP tokens burned.
    event LiquidityRemove(
        address indexed to,
        uint256 amountOfSpc,
        uint256 amountOfEth,
        uint256 lpTokensBurned
    );

    /// @notice Event emmited when a swap is executed.
    /// @dev If someone sends both ETH and SPC you will get both outputs.
    /// @param to Address where the funds were sent.
    /// @param spcAmount Amount of SPC transfered to the user.
    /// @param ethAmount Amount of ETH transfered to the user.
    event Swap(address indexed to, uint256 spcAmount, uint256 ethAmount);

    /// Constructor that sets the immutable addresses of the SpaceCoin token and pool.
    constructor(address _spaceCoinToken, address _spaceCoinLp, address _multiSig) {
        spaceCoinToken = _spaceCoinToken;
        spaceCoinLP = _spaceCoinLp;       
        transferOwnership(_multiSig);
    }

    /**
     * @notice Function to add liquidity to the pool.
     * spcMin doesn't take into account the SPC tax. 
     * @dev This function checks all inputs and calculates the best ratio possible before calling mintLpTokens
     * @param to Address where the lp tokens will be minted.
     * @param spcDesired Amount of SPC ideal to send to the pool.
     * @param spcMin Minimum amount of SPC user wants to send to the pool.
     * @param ethMin Minimum amount of ETH user wants to send to the pool.
     * note: "ethDesired" is going to be the ETH sent to this function.
     */
    function addLiquidity(
        address to,
        uint256 spcDesired,
        uint256 spcMin,
        uint256 ethMin
    ) external payable returns (uint256 amountSpc, uint256 amountEth) {
        uint256 ethDesired = msg.value;
        require(spcDesired > 0, "SPC_CANT_BE_ZERO");
        require(ethDesired > 0, "ETH_CANT_BE_ZERO");

        (uint256 spcReserve, uint256 ethReserve) = IPool(spaceCoinLP)
            .getReserves();

        if (spcReserve == 0 && ethReserve == 0) {
            amountSpc = spcDesired;
            amountEth = ethDesired;
        } else {
            // Try to calculate spc with msg.value first to avoid refunding eth
            uint256 spcOptimal = quoteAmount(
                ethDesired,
                ethReserve,
                spcReserve
            );
            if (spcOptimal <= spcDesired) {
                require(spcOptimal >= spcMin, "NOT_ENOUGH_ETH");
                amountSpc = spcOptimal;
                amountEth = ethDesired;
            } else {
                // If the eth sent is greater that the spc desired calculate eth cost of spc desired
                uint256 ethOptimal = quoteAmount(
                    spcDesired,
                    spcReserve,
                    ethReserve
                );
                require(ethOptimal >= ethMin, "NOT_ENOUGH_SPC");
                amountSpc = spcDesired;
                amountEth = ethOptimal;
            }
        }
        // Transfer correct ratio amount to Lp contract
        _safeTransferFromSpc(msg.sender, spaceCoinLP, amountSpc);
        // Send eth to payable function
        uint256 lpTokens = IPool(spaceCoinLP).mintLpTokens{value: amountEth}(to);
        // Emiting event before if caller reenter the order of events is correct
        emit LiquidityAdd(to, amountSpc, amountEth, lpTokens);
        // Refund remainding ETH
        if (msg.value > amountEth) {
            _safeTransferEth(msg.sender, msg.value - amountEth);
        }
    }

    /**
     * @notice Function to remove the liquidity by burning lp tokens owned by the caller.
     * This function will need approval to manage the lp tokens
     * spcAmountMin doesn't take into account the SPC tax.
     * @param to Address where the funds will be sent.
     * @param liquidityTokens Amount of Lp tokens the owner wants to burn.
     * @param spcAmountMin Minimum amount of SPC user wants to receive from the pool.
     * @param ethAmountMin Minimum amount of ETH user wants to receive from the pool.
     */
    function removeLiquidity(
        address to,
        uint256 liquidityTokens,
        uint256 spcAmountMin,
        uint256 ethAmountMin
    ) external {
        // Approve pool to spend LP tokens of caller in front end
        bool success = IPool(spaceCoinLP).transferFrom(
            msg.sender,
            spaceCoinLP,
            liquidityTokens
        );
        require(success, "LP_TOKENS_TRANSFER_FAILED");

        (uint256 spcAmount, uint256 ethAmount) = IPool(spaceCoinLP)
            .burnLpTokens(to);
        require(spcAmount >= spcAmountMin, "SPC_MIN_NOT_FULFILLED");
        require(ethAmount >= ethAmountMin, "ETH_MIN_NOT_FULFILLED");
        emit LiquidityRemove(to, spcAmount, ethAmount, liquidityTokens);
    }

    /**
     * @notice Function to trade between ETH/SPC or SPC/ETH with the pool contract.
     * The exchange rate will depend on the reserves.
     * @param to Address where the output asset will be sent.
     * @param amountSpcIn Amount of SPC that the user will send.
     * @param amountEthOutMin Minimum amount of ETH user wants to receive from the pool.
     * @param amountSpcOutMin Minimum amount of SPC user wants to receive from the pool.
     * note: amountEthIn will be the ETH sent to this function.
     */
    function swap(
        address to,
        uint256 amountSpcIn,
        uint256 amountEthOutMin,
        uint256 amountSpcOutMin
    ) external payable {
        uint256 amountEthIn = msg.value;
        // Since the router should guide the user, it's ilogical to think someone would sends two assets
        require(amountEthIn == 0 || amountSpcIn == 0, "ONLY_ONE_WAY_SWAP");
        if (amountSpcIn > 0) {
            _safeTransferFromSpc(msg.sender, spaceCoinLP, amountSpcIn);
        }
        // If token has tax on the actualSpcIn will differ from the amountSpcIn
        uint256 actualSpcIn = _getSpcIn();
        (uint256 amountSpcOut, uint256 amountEthOut) = getAmountOut(
            actualSpcIn,
            amountEthIn
        );
        require(amountEthOut >= amountEthOutMin, "MIN_ETH_NOT_REACHED");
        uint256 spcBefore = ISpaceCoin(spaceCoinToken).balanceOf(to);
        IPool(spaceCoinLP).swap{value: amountEthIn}(
            to,
            amountSpcOut,
            amountEthOut
        );
        // Check if the SPC sent is more or equal than the amountSpcOutMin
        require(
            ISpaceCoin(spaceCoinToken).balanceOf(to) - spcBefore >=
                amountSpcOutMin,
            "MIN_SPC_NOT_REACHED"
        );
        emit Swap(to, amountSpcOut, amountEthOut);
    }

    /**
     * note: This price will only represent the current rate of exchange of the assets and will not be real in a trade.
     * @notice This function quote the amountI to the current price of the liquidity pool. 
     * @param amountI Input amount.
     * @param reserveI Reserve of the input amount.
     * @param reserveO Reserve of the output amount.
     * @return amountO Current amount of assets that amountI represents.
     */
    function quoteAmount(
        uint256 amountI,
        uint256 reserveI,
        uint256 reserveO
    ) public pure returns (uint256 amountO) {
        require(amountI > 0, "INSUFFICIENT_AMOUNT");
        require(reserveI > 0 && reserveO > 0, "NO_LIQUIDITY");
        amountO = (amountI * reserveO) / reserveI;
    }

    /**
     * @notice This function will calculate the maximun possible output values for ETH or SPC depending on the current reserves.
     * @param spcIn SPC to send to the pool.
     * @param ethIn ETH to send to the pool.
     * @return spcOut SPC amount resulted from the ethIn.
     * @return ethOut ETH amount resulted from the spcIn.
     */
    function getAmountOut(uint256 spcIn, uint256 ethIn)
        public
        view
        returns (uint256 spcOut, uint256 ethOut)
    {
        (uint256 spcReserve, uint256 ethReserve) = IPool(spaceCoinLP)
            .getReserves();
        if (spcReserve == 0 || ethReserve == 0) {
            ethOut = 0;
            spcOut = 0;
        } else {
            if (spcIn > 0) {
                uint256 numerator = spcIn * 99 * ethReserve;
                uint256 denominator = (spcReserve * 100) + (spcIn * 99);
                ethOut = numerator / denominator;
            }
            if (ethIn > 0) {
                uint256 numerator = ethIn * 99 * spcReserve;
                uint256 denominator = (ethReserve * 100) + (ethIn * 99);
                spcOut = numerator / denominator;
            }
        }
    }

    /// @dev Checks the amount of SPC that got into the pool (this will be useful if SPC tax is on)
    function _getSpcIn() internal view returns (uint256 realSpcIn) {
        (uint256 spcReserve, ) = IPool(spaceCoinLP).getReserves();
        (uint256 spcBalance, ) = IPool(spaceCoinLP).getBalances();
        realSpcIn = spcBalance - spcReserve;
    }

    /// @dev Safe transfering SPC from an address to other address with return checks.
    function _safeTransferFromSpc(
        address from,
        address to,
        uint256 spcAmountOut
    ) internal {
        bool success = ISpaceCoin(spaceCoinToken).transferFrom(
            from,
            to,
            spcAmountOut
        );
        require(success, "SPC_TRANSFER_FAILED");
    }

    /// @dev Safe transfering ETH with return checks.
    function _safeTransferEth(address to, uint256 ethAmount) internal {
        (bool success, bytes memory data) = to.call{value: ethAmount}("");
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ETH_TRANSFER_FAILED"
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface ISpaceCoin {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event TaxActive();

    event TaxInactive();

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function activateTax() external;

    function deactivateTax() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface IPool {
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

    function getReserves() external view returns (uint256 _spc, uint256 _eth);

    function getBalances() external view returns (uint256 _spc, uint256 _eth);

    function mintLpTokens(address to)
        external
        payable
        returns (uint256 liquidity);

    function burnLpTokens(address to)
        external
        returns (uint256 spcAmount, uint256 ethAmount);

    function swap(
        address to,
        uint256 spcAmountOut,
        uint256 ethAmountOut
    ) external payable;

    event Minted(address indexed to, uint256 lpAmount);
    event Burned(address indexed from, uint256 lpAmount);
    event Swap(
        address indexed sender,
        uint256 amountSpcIn,
        uint256 amountEthIn,
        uint256 amountSpcOut,
        uint256 amountEthOut,
        address indexed to
    );
    event Synced(uint256 spcReserve, uint256 ethReserve);
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