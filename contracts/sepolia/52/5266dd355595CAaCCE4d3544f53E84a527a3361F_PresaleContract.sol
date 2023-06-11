// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PresaleContract {


    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    struct Presale {
        address owner;
        uint256 presalePrice;
        uint256 listingPrice;
        uint256 softcap;
        uint256 hardcap;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 startTime;
        uint256 endTime;
        uint256 tokensToSell;
        uint8 liquidityPercentage;
        uint256 liquidityUnlockTime;
        bool haveWhitelistedUsers;
        uint256 totalInvestment;
    }

    mapping(address => mapping(address => bool)) whitelistedUsers;
    mapping(address => mapping(address => uint)) contributions;
    mapping(address => Presale) public presales;
    mapping(address => address[]) private tokenOwner;

    event PresaleCreated(
        uint256 indexed _tokenAddress,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softcap,
        uint256 _hardcap
    );

    function createPresale(
        address _tokenAddress,
        uint256 _presalePrice,
        uint256 _listingPrice,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokensToSell,
        uint8 _liquidityPercentage,
        bool _haveWhitelistedUsers,
        address[] memory _whitelistedUsers,
        uint256 _liquidityUnlockTime
    ) external {
        require(
            _startTime >= block.timestamp,
            "Presale: Start time must be in future"
        );
        require(
            _endTime > _startTime,
            "Presale: End time must be after start time"
        );
        require(
            _hardcap > _softcap,
            "Presale: Hardcap must be greater than softcap"
        );
        require(
            _maxContribution > 0,
            "Presale: Max contribution must be greater than 0"
        );
        require(
            _minContribution > 0,
            "Presale: Min contribution must be greater than 0"
        );

        presales[_tokenAddress] = Presale(
            msg.sender,
            _presalePrice,
            _listingPrice,
            _softcap,
            _hardcap,
            _minContribution,
            _maxContribution,
            _startTime,
            _endTime,
            _tokensToSell,
            _liquidityPercentage,
            _liquidityUnlockTime,
            _haveWhitelistedUsers,
            0
        );

        if (_haveWhitelistedUsers) {
            addWhitelistUser(_tokenAddress, _whitelistedUsers);
        }
        tokenOwner[msg.sender].push(_tokenAddress);
    }
    

    function getInvestment(
        address _tokenAddress
    ) external view returns (uint256) {
        Presale storage presale = presales[_tokenAddress];
        return presale.totalInvestment;
    }

    function getPresalesByOwner() external view returns (address[] memory) {
        return tokenOwner[msg.sender];
    }

    function addWhitelistUser(
        address _tokenAddress,
        address[] memory _whitelistedUsers
    ) internal {
        for (uint256 i = 0; i < _whitelistedUsers.length; i++) {
            whitelistedUsers[_tokenAddress][_whitelistedUsers[i]] = true;
        }
    }

    function contribute( address _tokenAddress, uint amount) external {
        address _investor = msg.sender;
        Presale storage presale = presales[_tokenAddress];
        require(block.timestamp >= presale.startTime, "Presale has not started");
        require(block.timestamp <= presale.endTime, "Presale has ended");
        require(presale.totalInvestment < presale.hardcap, "Presale hardcap reached");
        require(amount <= presale.minContribution, "Amount is less than min contribution");
        require(amount >= presale.maxContribution, "Amount is greater than max contribution");
        require(presale.totalInvestment + amount <= presale.hardcap, "Amount exceeds hardcap");
        require(presale.haveWhitelistedUsers == false || whitelistedUsers[_tokenAddress][_investor] == true, "Investor is not whitelisted");
        require(contributions[_tokenAddress][_investor] + amount <= presale.maxContribution, "Amount exceeds max contribution");

        contributions[_tokenAddress][_investor] += amount;
        presale.totalInvestment += amount;
    }


    function withdrawAndDistributeToken(address _tokenAddress) external {
        Presale storage presale = presales[_tokenAddress];
        require(presale.owner == msg.sender, "Only the presale owner can withdraw");
        require(block.timestamp > presale.endTime, "Presale has not ended yet");

        uint256 totalTokensToWithdraw = presale.tokensToSell * (100 - presale.liquidityPercentage) / 100;
        IERC20 token = IERC20(_tokenAddress);

        // Transfer remaining tokens to the owner
        token.transfer(presale.owner, totalTokensToWithdraw);

        // Transfer unsold tokens back to the owner
        uint256 unsoldTokens = presale.tokensToSell - totalTokensToWithdraw;
        if (unsoldTokens > 0) {
            token.transfer(presale.owner, unsoldTokens);
        }

        // Transfer remaining ETH balance to the owner
        payable(presale.owner).transfer(address(this).balance);

        // Add liquidity to the pool and distribute tokens
        if (presale.totalInvestment >= presale.softcap) {
            uint256 ethAmount = address(this).balance;
            uint256 tokenAmount = totalTokensToWithdraw;

            IUniswapV2Router02 router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
            token.approve(address(router), tokenAmount);

            router.addLiquidityETH{value: ethAmount}(
                _tokenAddress,
                tokenAmount,
                tokenAmount,
                ethAmount,
                presale.owner,
                block.timestamp + presale.liquidityUnlockTime
            );

            uint256 totalTokensToDistribute = presale.tokensToSell * presale.liquidityPercentage / 100;

            for (uint256 i = 0; i < tokenOwner[presale.owner].length; i++) {
                address investor = tokenOwner[presale.owner][i];
                uint256 investmentAmount = contributions[_tokenAddress][investor];
                uint256 tokensToDistribute = totalTokensToDistribute * investmentAmount / presale.totalInvestment;

                // Transfer tokens to investor
                token.transfer(investor, tokensToDistribute);
            }
        } else {
            for (uint256 i = 0; i < tokenOwner[presale.owner].length; i++) {
                address investor = tokenOwner[presale.owner][i];
                uint256 investmentAmount = contributions[_tokenAddress][investor];

                // Return original investment amount to investor
                payable(investor).transfer(investmentAmount);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './IUniswapV2Router01.sol';

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