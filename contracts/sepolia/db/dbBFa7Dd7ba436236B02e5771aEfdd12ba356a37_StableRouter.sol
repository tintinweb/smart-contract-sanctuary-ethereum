// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPair {
    function initialize(address[] memory _tokens, bytes memory _data) external;

    function PAIR_TYPE() external view returns (uint8);

    function AUTH() external view returns (bool);

    function tokens() external view returns (address[] memory);

    function getAmountOut(address _from, address _to, uint256 _amount) external view returns (uint256);
}

interface IVolatilePair is IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function mint(address _to) external returns (uint256 _liquidity);

    function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;

    function getRealBalanceOf() external view returns (uint256, uint256);

    function skim(address _to) external;

    function sync() external;

    function claimFees() external returns (uint256[] memory _adminFees);
}

interface IStablePair is IPair {
    function lpToken() external view returns (address);

    function calculateTokenAmount(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bool _deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidityOneToken(address _token, uint256 _liquidity) external view returns (uint256);

    function calculateRemoveLiquidity(
        address[] calldata _tokens,
        uint256 _amount
    ) external view returns (uint256[] memory);

    function addLiquidity(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _minToMint,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 _amount,
        address[] calldata _tokens,
        uint256[] calldata _minAmounts,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        address _token,
        uint256 _minAmount,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _maxBurnAmount,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _dx,
        uint256 _minDy,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPairERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPairFactory {
    function allPairsLength() external view returns (uint256);

    function isPair(address _pair) external view returns (bool);

    function manager() external view returns (address);

    function getPairAddress(address[] memory _tokens, uint8 _type) external view returns (address);

    function pairTypeValues() external view returns (address[] memory);

    function atPairType(uint256 _index) external view returns (address);

    function createPair(address[] memory _tokens, uint8 _pairType, bytes memory _data) external returns (address _pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IPairRouter {
    /**
     * @dev Struct representing a route between two tokens through a pair contract
     */
    struct Route {
        address from; // Address of the token to swap from
        address to; // Address of the token to swap to
        address pair; // Address of the pair contract to use for the swap
    }

    function PAIR_TYPE() external view returns (uint8);

    function quoteAddLiquidity(
        address[] calldata _tokens,
        uint256[] calldata _amountDesireds
    ) external view returns (uint256[] memory _amountIn, uint256 _liquidity);

    function quoteRemoveLiquidity(
        address[] calldata _tokens,
        uint256 _liquidity
    ) external view returns (uint256[] memory _amounts);

    function addLiquidity(
        address[] memory _tokens,
        uint256[] memory _amountDesireds,
        uint256[] memory _amountsMin,
        uint256 _minLiquidity,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts, uint256 _liquidity);

    function addLiquidityETH(
        address[] memory _tokens,
        uint256[] memory _amountDesireds,
        uint256[] memory _amountMins,
        uint256 _minLiquidity,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory _amounts, uint256 _liquidity);

    function removeLiquidity(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts);

    function removeLiquidityETH(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _returns);

    function removeLiquidityWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256[] memory _amounts);

    function removeLiquidityETHWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256[] memory);

    function swap(
        Route memory _route,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256 _amountOut);
}

interface IVolatileRouter is IPairRouter {
    function getReserves(
        address _pair,
        address[] calldata _tokens
    ) external view returns (uint256 _reserveA, uint256 _reserveB);
}

interface IStablPairRouter is IPairRouter {
    function quoteRemoveLiquidityOneToken(
        address[] calldata _tokens,
        address _token,
        uint256 _liquidity
    ) external view returns (uint256 _amount);

    function quoteRemoveLiquidityImbalance(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external view returns (uint256 _liquidity);

    function removeLiquidityOneToken(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _tokenAmount);

    function removeLiquidityOneTokenETH(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _tokenAmount);

    function removeLiquidityImbalance(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _amount);

    function removeLiquidityImbalanceETH(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _amount);

    function removeLiquidityOneTokenWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _tokenAmount);

    function removeLiquidityOneTokenETHWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _tokenAmount);

    function removeLiquidityImbalanceWithPermit(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _actualBurnAmount);

    function removeLiquidityImbalanceETHWithPermit(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _actualBurnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @title Interface for WETH9
interface IWETH {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/TransferHelper.sol";

import "../interface/IPairRouter.sol";
import "../interface/IPairFactory.sol";
import "../interface/IPair.sol";
import "../interface/IWETH.sol";
import "../interface/IPairERC20.sol";

/**
 * @title StableRouter
 * @notice Router for stablecoin pairs
 * @dev This contract implements the IStablPairRouter interface
 */
contract StableRouter is IStablPairRouter {
    using TransferHelper for address;

    // The type of pair
    uint8 internal constant PAIR_TYPE_ = 3;

    // The address of the factory contract
    address internal immutable factory_;
    // The WETH contract
    IWETH internal immutable weth_;

    constructor(address _factory, address _weth) public {
        factory_ = _factory;
        weth_ = IWETH(_weth);
    }

    // Get the type of pair
    function PAIR_TYPE() external view override returns (uint8) {
        return PAIR_TYPE_;
    }

    // Get the address of the factory contract
    function factory() external view returns (address) {
        return factory_;
    }

    // Get the address of the WETH contract
    function weth() external view returns (address) {
        return address(weth_);
    }

    /**
     * @dev Calculates the amount of tokens needed to add liquidity to a pair
     * @param _tokens The tokens to add liquidity for
     * @param _amountDesireds The desired amounts of each token
     * @return _amountIn The amounts of each token needed to add liquidity
     * @return _liquidity The amount of liquidity that will be added
     */
    function quoteAddLiquidity(
        address[] calldata _tokens,
        uint256[] calldata _amountDesireds
    ) external view override returns (uint256[] memory _amountIn, uint256 _liquidity) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        bool _isPair = IPairFactory(factory_).isPair(_pair);
        if (_isPair) {
            _amountIn = _amountDesireds;
            (bool _success, bytes memory _res) = _pair.staticcall(
                abi.encodeWithSignature(
                    "calculateTokenAmount(address[],uint256[],bool)",
                    _tokens,
                    _amountDesireds,
                    true
                )
            );
            if (_success) _liquidity = abi.decode(_res, (uint256));
        }
    }

    /**
     * @dev Calculates the amount of tokens that will be received upon removing liquidity from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @return _amounts The amounts of each token that will be received
     */
    function quoteRemoveLiquidity(
        address[] calldata _tokens,
        uint256 _liquidity
    ) external view override returns (uint256[] memory _amounts) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        if (IPairFactory(factory_).isPair(_pair))
            _amounts = IStablePair(_pair).calculateRemoveLiquidity(_tokens, _liquidity);
    }

    /**
     * @dev Calculates the amount of a specific token that will be received upon removing liquidity from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _token The token to calculate the amount for
     * @param _liquidity The amount of liquidity to remove
     * @return _amount The amount of the specified token that will be received
     */
    function quoteRemoveLiquidityOneToken(
        address[] calldata _tokens,
        address _token,
        uint256 _liquidity
    ) external view override returns (uint256 _amount) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        if (IPairFactory(factory_).isPair(_pair))
            _amount = IStablePair(_pair).calculateRemoveLiquidityOneToken(_token, _liquidity);
    }

    /**
     * @dev Calculates the amount of liquidity that will be removed when removing an imbalanced amount of tokens from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of each token to remove
     * @return _liquidity The amount of liquidity that will be removed
     */
    function quoteRemoveLiquidityImbalance(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external view override returns (uint256 _liquidity) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        if (IPairFactory(factory_).isPair(_pair))
            _liquidity = IStablePair(_pair).calculateTokenAmount(_tokens, _amounts, false) + 1;
    }

    /**
     * @dev Adds liquidity to a pair
     * @param _tokens The tokens to add liquidity for
     * @param _amountDesireds The desired amounts of each token to add
     * @param _amountMin Unused
     * @param _minLiquidity The minimum amount of liquidity to add
     * @param _to The address to send the liquidity to
     * @param _deadline The deadline to add liquidity by
     * @return _amounts The actual amounts of each token added
     * @return _liquidity The amount of liquidity added
     */
    function addLiquidity(
        address[] memory _tokens,
        uint256[] memory _amountDesireds,
        uint256[] memory _amountMin, // Unused
        uint256 _minLiquidity,
        address _to,
        uint256 _deadline
    ) external override returns (uint256[] memory _amounts, uint256 _liquidity) {
        _amountMin;
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        require(IPairFactory(factory_).isPair(_pair), "StableRouter: is not pair");

        // Transfer tokens from sender to contract and approve for pair
        _amounts = _amountDesireds;
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeTransferFrom(msg.sender, address(this), _amounts[i]);
            _tokens[i].safeApprove(_pair, _amounts[i]);
        }

        // Add liquidity to pair
        _liquidity = IStablePair(_pair).addLiquidity(_tokens, _amounts, _minLiquidity, _to, _deadline);
    }

    /**
     * @dev Adds liquidity to a pair with ETH
     * @param _tokens The tokens to add liquidity for
     * @param _amountDesireds The desired amounts of each token to add
     * @param _amountMin Unused
     * @param _minLiquidity The minimum amount of liquidity to add
     * @param _to The address to send the liquidity to
     * @param _deadline The deadline to add liquidity by
     * @return _amounts The actual amounts of each token added
     * @return _liquidity The amount of liquidity added
     */
    function addLiquidityETH(
        address[] memory _tokens,
        uint256[] memory _amountDesireds,
        uint256[] memory _amountMin, // Unused
        uint256 _minLiquidity,
        address _to,
        uint256 _deadline
    ) external payable override returns (uint256[] memory _amounts, uint256 _liquidity) {
        _amountMin;
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        require(IPairFactory(factory_).isPair(_pair), "StableRouter: is not pair");

        // Transfer tokens from sender to contract and approve for pair
        _amounts = _amountDesireds;
        uint256 _amountETH;
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeApprove(_pair, _amounts[i]);
            if (_tokens[i] == address(weth_)) {
                _amountETH = _amounts[i];
                weth_.deposit{ value: _amounts[i] }();
                continue;
            }
            _tokens[i].safeTransferFrom(msg.sender, address(this), _amounts[i]);
        }

        // Add liquidity to pair
        _liquidity = IStablePair(_pair).addLiquidity(_tokens, _amounts, _minLiquidity, _to, _deadline);

        if (msg.value > _amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - _amountETH);
    }

    /**
     * @dev Remove liquidity from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _amountsMin The minimum amounts of each token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _pairTokens The tokens in the pair
     * @return _amounts The actual amounts of each token received
     */
    function _removeLiquidity(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline
    ) internal returns (address[] memory _pairTokens, uint256[] memory _amounts) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        require(IPairFactory(factory_).isPair(_pair), "StableRouter: is not pair"); // send liquidity to pair

        address _lpToken = IStablePair(_pair).lpToken();
        _lpToken.safeTransferFrom(msg.sender, address(this), _liquidity);
        _lpToken.safeApprove(_pair, _liquidity);

        _amounts = IStablePair(_pair).removeLiquidity(_liquidity, _tokens, _amountsMin, _to, _deadline);
        _pairTokens = IPair(_pair).tokens();
    }

    /**
     * @dev Transfer tokens out of the contract with ETH
     * @param _tokens The tokens to transfer out
     * @param _amounts The amounts of each token to transfer out
     * @param _to The address to send the tokens to
     */
    function _transferOutWithETH(address[] memory _tokens, uint256[] memory _amounts, address _to) internal {
        uint256 _amountETH;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(weth_)) {
                _amountETH = _amounts[i];
                weth_.withdraw(_amountETH);
                // _to.safeTransferETH(_amounts[i]);
                continue;
            }
            _tokens[i].safeTransfer(_to, _amounts[i]);
        }
        _to.safeTransferETH(_amountETH);
    }

    /**
     * @dev Remove liquidity from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _amountsMin The minimum amounts of each token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _amounts The actual amounts of each token received
     */
    function removeLiquidity(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline
    ) public override returns (uint256[] memory _amounts) {
        (, _amounts) = _removeLiquidity(_tokens, _liquidity, _amountsMin, _to, _deadline);
    }

    /**
     * @dev Remove liquidity from a pair with ETH
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _amountsMin The minimum amounts of each token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _amounts The actual amounts of each token received
     */
    function removeLiquidityETH(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline
    ) public override returns (uint256[] memory _amounts) {
        address[] memory _pairTokens;
        (_pairTokens, _amounts) = _removeLiquidity(_tokens, _liquidity, _amountsMin, address(this), _deadline);
        _transferOutWithETH(_pairTokens, _amounts, _to);
    }

    /**
     * @dev Remove liquidity from a pair for a single token
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _token The token to receive
     * @param _minAmount The minimum amount of token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _tokenAmount The actual amount of token received
     */
    function _removeLiquidityOneToken(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline
    ) internal returns (uint256 _tokenAmount) {
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        require(IPairFactory(factory_).isPair(_pair), "StableRouter: is not pair");

        address _lpToken = IStablePair(_pair).lpToken();
        _lpToken.safeTransferFrom(msg.sender, address(this), _liquidity);
        _lpToken.safeApprove(_pair, _liquidity);

        _tokenAmount = IStablePair(_pair).removeLiquidityOneToken(_liquidity, _token, _minAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity for a single token from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _token The token to receive
     * @param _minAmount The minimum amount of token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _tokenAmount The actual amount of token received
     */
    function removeLiquidityOneToken(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline
    ) public override returns (uint256 _tokenAmount) {
        _tokenAmount = _removeLiquidityOneToken(_tokens, _liquidity, _token, _minAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity for a single token from a pair with ETH
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _token The token to receive (must be WETH)
     * @param _minAmount The minimum amount of token to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _tokenAmount The actual amount of token received
     */
    function removeLiquidityOneTokenETH(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline
    ) public override returns (uint256 _tokenAmount) {
        require(_token == address(weth_), "StableRouter: token must be WETH");

        _tokenAmount = _removeLiquidityOneToken(_tokens, _liquidity, _token, _minAmount, address(this), _deadline);

        weth_.withdraw(_tokenAmount);
        _to.safeTransferETH(_tokenAmount);
    }

    /**
     * @dev Remove liquidity imbalance for multiple tokens from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of tokens to remove liquidity for
     * @param _maxBurnAmount The maximum amount of liquidity to remove
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _actualBurnAmount The actual amount of liquidity burned
     */
    function _removeLiquidityImbalance(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline
    ) internal returns (uint256 _actualBurnAmount) {
        // Get the pair address from the factory
        address _pair = IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_);
        // Ensure that the pair exists
        require(IPairFactory(factory_).isPair(_pair), "StableRouter: is not pair");

        // Get the LP token address
        address _lpToken = IStablePair(_pair).lpToken();
        // Transfer the LP tokens from the sender to this contract
        _lpToken.safeTransferFrom(msg.sender, address(this), _maxBurnAmount);
        // Approve the LP tokens for the pair
        _lpToken.safeApprove(_pair, _maxBurnAmount);

        // Remove the liquidity imbalance
        _actualBurnAmount = IStablePair(_pair).removeLiquidityImbalance(
            _tokens,
            _amounts,
            _maxBurnAmount,
            _to,
            _deadline
        );

        // If the actual burn amount is less than the maximum burn amount, transfer the remaining LP tokens back to the sender
        if (_maxBurnAmount > _actualBurnAmount) {
            _lpToken.safeApprove(_pair, 0);
            _lpToken.safeTransfer(msg.sender, _maxBurnAmount - _actualBurnAmount);
        }
    }

    /**
     * @dev Remove liquidity imbalance for multiple tokens from a pair
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of tokens to remove liquidity for
     * @param _maxBurnAmount The maximum amount of liquidity to remove
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _actualBurnAmount The actual amount of liquidity burned
     */
    function removeLiquidityImbalance(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline
    ) public override returns (uint256 _actualBurnAmount) {
        _actualBurnAmount = _removeLiquidityImbalance(_tokens, _amounts, _maxBurnAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity imbalance for multiple tokens from a pair with ETH
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of tokens to remove liquidity for
     * @param _maxBurnAmount The maximum amount of liquidity to remove
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @return _actualBurnAmount The actual amount of liquidity burned
     */
    function removeLiquidityImbalanceETH(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline
    ) public override returns (uint256 _actualBurnAmount) {
        // Remove liquidity imbalance for multiple tokens from a pair
        _actualBurnAmount = _removeLiquidityImbalance(_tokens, _amounts, _maxBurnAmount, address(this), _deadline);
        // Transfer tokens out with ETH
        _transferOutWithETH(_tokens, _amounts, _to);
    }

    /**
     * @dev Approve the LP tokens for the pair using permit
     * @param _pair The address of the pair
     * @param _liquidity The amount of liquidity to approve
     * @param _deadline The deadline to approve by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     */
    function _withPermit(
        address _pair,
        uint256 _liquidity,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        // Determine the value to approve
        uint256 _value = _approveMax ? uint256(-1) : _liquidity;
        // Get the LP token address
        address _lpToken = IStablePair(_pair).lpToken();
        // Approve the LP tokens using permit
        IPairERC20(_lpToken).permit(msg.sender, address(this), _value, _deadline, _v, _r, _s);
    }

    /**
     * @dev Remove liquidity with permit
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _amountsMin The minimum amounts of tokens to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _amounts The actual amounts of tokens received
     */
    function removeLiquidityWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256[] memory _amounts) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _liquidity,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity for multiple tokens from a pair
        _amounts = removeLiquidity(_tokens, _liquidity, _amountsMin, _to, _deadline);
    }

    /**
     * @dev Remove liquidity with permit
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _amountsMin The minimum amounts of tokens to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _amounts The actual amounts of tokens received
     */
    function removeLiquidityETHWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        uint256[] memory _amountsMin,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256[] memory _amounts) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _liquidity,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity for ETH from a pair
        _amounts = removeLiquidityETH(_tokens, _liquidity, _amountsMin, _to, _deadline);
    }

    /**
     * @dev Remove liquidity for a single token with permit
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _token The token to receive
     * @param _minAmount The minimum amount of tokens to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _tokenAmount The actual amount of tokens received
     */
    function removeLiquidityOneTokenWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256 _tokenAmount) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _liquidity,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity for a single token from a pair
        _tokenAmount = removeLiquidityOneToken(_tokens, _liquidity, _token, _minAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity for a single token with permit and receive ETH
     * @param _tokens The tokens to remove liquidity for
     * @param _liquidity The amount of liquidity to remove
     * @param _token The token to receive
     * @param _minAmount The minimum amount of tokens to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _tokenAmount The actual amount of tokens received
     */
    function removeLiquidityOneTokenETHWithPermit(
        address[] memory _tokens,
        uint256 _liquidity,
        address _token,
        uint256 _minAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256 _tokenAmount) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _liquidity,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity for a single token from a pair and receive ETH
        _tokenAmount = removeLiquidityOneTokenETH(_tokens, _liquidity, _token, _minAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity with permit when the amount of tokens to remove is imbalanced
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of tokens to remove
     * @param _maxBurnAmount The maximum amount of liquidity to burn
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _actualBurnAmount The actual amount of liquidity burned
     */
    function removeLiquidityImbalanceWithPermit(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256 _actualBurnAmount) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _maxBurnAmount,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity with imbalanced amounts of tokens from a pair
        _actualBurnAmount = removeLiquidityImbalance(_tokens, _amounts, _maxBurnAmount, _to, _deadline);
    }

    /**
     * @dev Remove liquidity with permit when the amount of tokens to remove is imbalanced and receive ETH
     * @param _tokens The tokens to remove liquidity for
     * @param _amounts The amounts of tokens to remove
     * @param _maxBurnAmount The maximum amount of liquidity to burn
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to remove liquidity by
     * @param _approveMax Whether to approve the maximum amount of liquidity
     * @param _v The v value of the permit signature
     * @param _r The r value of the permit signature
     * @param _s The s value of the permit signature
     * @return _actualBurnAmount The actual amount of liquidity burned
     */
    function removeLiquidityImbalanceETHWithPermit(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _maxBurnAmount,
        address _to,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override returns (uint256 _actualBurnAmount) {
        // Approve the LP tokens for the pair using permit
        _withPermit(
            IPairFactory(factory_).getPairAddress(_tokens, PAIR_TYPE_),
            _maxBurnAmount,
            _deadline,
            _approveMax,
            _v,
            _r,
            _s
        );

        // Remove liquidity with imbalanced amounts of tokens from a pair and receive ETH
        _actualBurnAmount = removeLiquidityImbalanceETH(_tokens, _amounts, _maxBurnAmount, _to, _deadline);
    }

    /**
     * @dev Swap tokens through a route
     * @param _route The route to swap through
     * @param _amountIn The amount of tokens to swap in
     * @param _amountOutMin The minimum amount of tokens to receive
     * @param _to The address to send the tokens to
     * @param _deadline The deadline to swap by
     * @return _amountOut The actual amount of tokens received
     */
    function swap(
        Route memory _route,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline
    ) external payable override returns (uint256 _amountOut) {
        // Ensure that the pair exists
        require(IPairFactory(factory_).isPair(_route.pair), "StableRouter: is not pair");

        // Approve the pair to spend the input token
        _route.from.safeApprove(_route.pair, _amountIn);

        // Swap the tokens through the route
        _amountOut = IStablePair(_route.pair).swap(_route.from, _route.to, _amountIn, _amountOutMin, _to, _deadline);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Library for safely executing transfers and approvals of ERC20 tokens and ETH.
 */
library TransferHelper {
    /**
     * @dev Safely approves `value` tokens for `to` by calling the `approve` function on `token`.
     * @param token The address of the ERC20 token.
     * @param to The address to approve tokens for.
     * @param value The number of tokens to approve.
     */
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    /**
     * @dev Safely transfers `value` tokens to `to` by calling the `transfer` function on `token`.
     * @param token The address of the ERC20 token.
     * @param to The address to transfer tokens to.
     * @param value The number of tokens to transfer.
     */
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    /**
     * @dev Safely transfers `value` tokens from `from` to `to` by calling the `transferFrom` function on `token`.
     * @param token The address of the ERC20 token.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The number of tokens to transfer.
     */
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    /**
     * @dev Safely transfers `value` ETH to `to`.
     * @param to The address to transfer ETH to.
     * @param value The amount of ETH to transfer.
     */
    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}