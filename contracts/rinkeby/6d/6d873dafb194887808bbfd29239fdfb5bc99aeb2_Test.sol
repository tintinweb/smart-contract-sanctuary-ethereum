/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVault
{
	enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		address assetIn;
		address assetOut;
		uint256 amount;
		bytes userData;
	}

	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

    function getPoolTokenInfo(bytes32 _poolId, address _token) external view returns (uint256 _cash, uint256 _managed, uint256 _lastChangeBlock, address _assetManager);

    function joinPool(bytes32 _poolId, address _sender, address _recipient, JoinPoolRequest memory _request) external payable;
    function exitPool(bytes32 _poolId, address _sender, address payable _recipient, ExitPoolRequest memory _request) external;
	function swap(SingleSwap memory _singleSwap, FundManagement memory _funds, uint256 _limit, uint256 _deadline) external payable returns (uint256 _amountCalculated);

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	function queryBatchSwap(SwapKind _kind, BatchSwapStep[] memory _swaps, address[] memory _assets, FundManagement memory _funds) external view returns (int256[] memory _assetDeltas);
}

interface IERC20
{
    function balanceOf(address _account) external view returns (uint256 _balance);

    function approve(address _spender, uint256 _amount) external returns (bool _success);
    function transfer(address _to, uint256 _amount) external returns (bool _success);
}

interface IFaucet is IERC20
{
    function faucet() external;
}

contract Test
{
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant MOR = 0x170679BeA5f63c988b21072D5ff34dAFc5A85d98;
    address constant USD = 0xcC6DC55370403a964a2e2ACb4DD6d8Fad347599c;
    address constant MOR_USD = 0x949a12b95eC5B80C375b98963A5D6B33B0D0EffF;
    bytes32 constant MOR_USD_POOL_ID = 0x949a12b95ec5b80c375b98963a5d6b33b0d0efff00020000000000000000012d;

    function getRate() external view returns (uint256 _rate, int256[] memory _assetDeltas)
    {
        IVault.BatchSwapStep[] memory _swaps = new IVault.BatchSwapStep[](1);
		_swaps[0].poolId = MOR_USD_POOL_ID;
		_swaps[0].assetInIndex = 1;
		_swaps[0].assetOutIndex = 0;
		_swaps[0].amount = 1e18;
		_swaps[0].userData = new bytes(0);
        address[] memory _assets = new address[](2);
        _assets[0] = MOR;
        _assets[1] = USD;
        IVault.FundManagement memory _funds;
		_funds.sender = payable(address(this));
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(address(this));
		_funds.toInternalBalance = false;
        _assetDeltas = IVault(VAULT).queryBatchSwap(IVault.SwapKind.GIVEN_IN, _swaps, _assets, _funds);
        return (_rate, _assetDeltas);
    }
}

contract GrowthAMO
{
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant MOR = 0x170679BeA5f63c988b21072D5ff34dAFc5A85d98;
    address constant USD = 0xcC6DC55370403a964a2e2ACb4DD6d8Fad347599c;
    address constant MOR_USD = 0x949a12b95eC5B80C375b98963A5D6B33B0D0EffF;
    bytes32 constant MOR_USD_POOL_ID = 0x949a12b95ec5b80c375b98963a5d6b33b0d0efff00020000000000000000012d;

    function inspectPool() external view returns (uint256 _balanceMOR, uint256 _balanceUSD)
    {
        (uint256 _cashMOR, uint256 _managedMOR,,) = IVault(VAULT).getPoolTokenInfo(MOR_USD_POOL_ID, MOR);
        (uint256 _cashUSD, uint256 _managedUSD,,) = IVault(VAULT).getPoolTokenInfo(MOR_USD_POOL_ID, USD);
        return (_cashMOR + _managedMOR, _cashUSD + _managedUSD);
    }

    function addInitialLiquidity() external
    {
        IFaucet(MOR).faucet();
        IFaucet(USD).faucet();
        uint256 _balanceMOR = IERC20(MOR).balanceOf(address(this));
        uint256 _balanceUSD = IERC20(USD).balanceOf(address(this));
        require(IERC20(MOR).approve(VAULT, _balanceMOR), "approve failure MOR");
        require(IERC20(USD).approve(VAULT, _balanceUSD), "approve failure USD");
        IVault.JoinPoolRequest memory _request;
        _request.assets = new address[](2);
        _request.assets[0] = MOR;
        _request.assets[1] = USD;
        _request.maxAmountsIn = new uint256[](2);
        _request.maxAmountsIn[0] = _balanceMOR;
        _request.maxAmountsIn[1] = _balanceUSD;
        _request.userData = abi.encode(JoinKind.INIT, _request.maxAmountsIn);
        _request.fromInternalBalance = false;
        IVault(VAULT).joinPool(MOR_USD_POOL_ID, address(this), msg.sender, _request);
    }

    function addLiquidity() external
    {
        IFaucet(MOR).faucet();
        IFaucet(USD).faucet();
        uint256 _balanceMOR = IERC20(MOR).balanceOf(address(this));
        uint256 _balanceUSD = IERC20(USD).balanceOf(address(this));
        require(IERC20(MOR).approve(VAULT, _balanceMOR), "approve failure MOR");
        require(IERC20(USD).approve(VAULT, _balanceUSD), "approve failure USD");
        IVault.JoinPoolRequest memory _request;
        _request.assets = new address[](2);
        _request.assets[0] = MOR;
        _request.assets[1] = USD;
        _request.maxAmountsIn = new uint256[](2);
        _request.maxAmountsIn[0] = _balanceMOR;
        _request.maxAmountsIn[1] = _balanceUSD;
        _request.userData = abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _request.maxAmountsIn, 1);
        _request.fromInternalBalance = false;
        IVault(VAULT).joinPool(MOR_USD_POOL_ID, address(this), msg.sender, _request);
    }

    function removeLiquidity() external
    {
        uint256 _balanceMOR_USD = IERC20(MOR_USD).balanceOf(address(this));
        require(IERC20(MOR_USD).approve(VAULT, _balanceMOR_USD), "approve failure MOR_USD");
        IVault.ExitPoolRequest memory _request;
        _request.assets = new address[](2);
        _request.assets[0] = MOR;
        _request.assets[1] = USD;
        _request.minAmountsOut = new uint256[](2);
        _request.minAmountsOut[0] = 1;
        _request.minAmountsOut[1] = 1;
        _request.userData = abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _balanceMOR_USD);
        _request.toInternalBalance = false;
        IVault(VAULT).exitPool(MOR_USD_POOL_ID, address(this), payable(msg.sender), _request);
    }

    function swapMOR_USD() external
    {
        IFaucet(MOR).faucet();
        uint256 _balanceMOR = IERC20(MOR).balanceOf(address(this));
        require(IERC20(MOR).approve(VAULT, _balanceMOR), "approve failure MOR");
		IVault.SingleSwap memory _swap;
		_swap.poolId = MOR_USD_POOL_ID;
		_swap.kind = IVault.SwapKind.GIVEN_IN;
		_swap.assetIn = MOR;
		_swap.assetOut = USD;
        _swap.amount = _balanceMOR;
		_swap.userData = new bytes(0);
		IVault.FundManagement memory _funds;
		_funds.sender = address(this);
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(msg.sender);
		_funds.toInternalBalance = false;
        IVault(VAULT).swap(_swap, _funds, 1, block.timestamp);
    }

    function swapUSD_MOR() external
    {
        IFaucet(USD).faucet();
        uint256 _balanceUSD = IERC20(USD).balanceOf(address(this));
        require(IERC20(USD).approve(VAULT, _balanceUSD), "approve failure USD");
		IVault.SingleSwap memory _swap;
		_swap.poolId = MOR_USD_POOL_ID;
		_swap.kind = IVault.SwapKind.GIVEN_IN;
		_swap.assetIn = USD;
		_swap.assetOut = MOR;
        _swap.amount = _balanceUSD;
		_swap.userData = new bytes(0);
		IVault.FundManagement memory _funds;
		_funds.sender = address(this);
		_funds.fromInternalBalance = false;
		_funds.recipient = payable(msg.sender);
		_funds.toInternalBalance = false;
        IVault(VAULT).swap(_swap, _funds, 1, block.timestamp);
    }
}