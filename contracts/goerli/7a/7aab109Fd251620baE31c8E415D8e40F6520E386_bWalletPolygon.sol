// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface MeshGateway {
    function depositETH() external payable;

    function withdrawETH(uint256 withdrawAmount) external;
}

interface MeshRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
}

contract bWalletPolygon {
    address public owner;
    uint256 public nonce;
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    event Replayed(address, uint256, uint256 fee);
    event FeeIncoming(address, uint256 finalAmt, uint256 fee);
    event StakedMesh(address, uint256);
    event StakedAave(address, uint256);
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;

    // map  ERC20 tokens to user
    mapping(address => mapping(address => uint256)) public ERC20Balances;




    address public bitsManager = 0x07f899CA879Ba85376D710fE448B88aF53049067;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public aaveLendingPool = 0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;
    address public quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public meshSwapRouter = 0x10f4A785F458Bc144e3706575924889954946639;
    address public aEthWETH = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;
    address public iWMatic = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf;
    address iMESH = 0x6dBADf2a3e53885076f1D30B6198e560830cb4Bb; // pool
    address MESH = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a; // token
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // token
    address iUSDC = 0x590Cd248e16466F747e74D4cfa6C48f597059704; // pool
    address iUSDT = 0x782D7eC740d997445D62e4463ce64C67c7484497; // pool
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // token

    address public WrappedTokenGatewayV3 =
        0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
    uint256 public bitsValue;
    uint256 public totalFee;
    uint256 public feez = 85;
    IWETHGateway public aaveContract;
    MeshGateway public meshContract;
    MeshRouter public meshRouter;

    IERC20 public aEthWETHcontract;

    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userStakedAmountMesh;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(bitsManager == msg.sender, "Manager only");
        _;
    }

    constructor() payable {
        owner = msg.sender;
        _aaveContract = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
        aaveContract = IWETHGateway(_aaveContract);

        aEthWETHcontract = IERC20(aEthWETH);
  
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function updateFee(uint256 _feez) public onlyManager {
        feez = _feez;
    }

    function send(address payable _to, uint256 _amount) external onlyManager {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        nonce += 1;
        emit Sent(_to, _amount);
    }

    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnership(address _newOwner) external onlyManager {
        owner = _newOwner;
    }

    function withdraw() external onlyManager {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }

    function SplitIt() public {
        uint256 _staked = userStakedAmount[msg.sender];
        uint256 feeValue = address(this).balance - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        userStakedAmount[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: finalAmount}("");
        require(sent, "Failed to send Ether");
        (bool sent2, ) = address(bitsManager).call{value: fee}("");
        require(sent2, "Failed to send Ether");
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
    }

    /////// meshswap

    function stakeMeshswap() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approv wmatic
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        IERC20 wmaticToken = IERC20(wMatic);
        wmaticToken.approve(iWMatic, maxUint);
        MeshGateway iwMatic = MeshGateway(iWMatic);
        iwMatic.depositETH();

        values[msg.sender] = msg.value;
        userStakedAmountMesh[msg.sender] += msg.value;
        emit StakedMesh(msg.sender, msg.value);
    }

    function withdrawETHMesh() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        meshContract.withdrawETH(maxUint);
    }

    function getMeshTokenBalance() public view returns (uint256) {
        return IERC20(MESH).balanceOf(address(this));
    }

    function swapMeshToUSDC() public {
        uint256 _amount = IERC20(MESH).balanceOf(address(this));
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = MESH;
        path[1] = USDC;
        meshRouter.swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function approveMeshTokensForStaking() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        IERC20 meshToken = IERC20(MESH);
        IERC20 usdcToken = IERC20(USDC);

        meshToken.approve(iMESH, maxUint);
        usdcToken.approve(iUSDC, maxUint);
    }

    function approveMeshTokensForSwapping() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        IERC20 meshToken = IERC20(MESH);
        IERC20 usdtToken = IERC20(USDT);
        IERC20 usdcToken = IERC20(USDC);
        meshToken.approve(meshSwapRouter, maxUint);
        usdtToken.approve(meshSwapRouter, maxUint);
        usdcToken.approve(meshSwapRouter, maxUint);
    }

    //// aave

    function stakeETHAave() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approve weth
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        approveWeth(WrappedTokenGatewayV3, maxUint);

        aaveContract.depositETH{value: msg.value}(
            aaveLendingPool,
            address(this),
            0
        );
        values[msg.sender] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit StakedAave(msg.sender, msg.value);
    }

    function updateAave(address _aave) public onlyOwner {
        _aaveContract = _aave;
        aaveContract = IWETHGateway(_aave);
    }

    function updateAaveWETH(address _aaveWETH) public onlyOwner {
        aEthWETH = _aaveWETH;
        aEthWETHcontract = IERC20(aEthWETH);
    }

    function updateManager(address _bitsManager) public onlyOwner {
        bitsManager = _bitsManager;
    }

    function updateAaveLendingPool(address _aaveLendingPool) public onlyOwner {
        aaveLendingPool = _aaveLendingPool;
    }

    function unstakeETHAave() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        aaveContract.withdrawETH(aaveLendingPool, maxUint, address(this));
    }

    function approveWMATIC(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    function approveWeth(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    /// balances

    function getUSDCBalance() public view returns (uint256) {
        return IERC20(USDC).balanceOf(address(this));
    }

    function getWMaticBalance() public view returns (uint256) {
        return IERC20(wMatic).balanceOf(address(this));
    }

    function getAaveBalance() public view returns (uint256) {
        return IERC20(aEthWETH).balanceOf(address(this));
    }

    function getMeshBalance() public view returns (uint256) {
        return IERC20(MESH).balanceOf(address(this));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getStakedBalance() public view returns (uint256) {
        return userStakedAmount[msg.sender];
    }

    function getStakedBalanceMesh() public view returns (uint256) {
        return userStakedAmountMesh[msg.sender];
    }
}