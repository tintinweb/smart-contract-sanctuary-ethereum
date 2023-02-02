// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./MeshPools.sol";

interface MeshGateway {
    function depositETH() external payable;

    function depositToken(uint256 amount) external;

    function withdrawETH(uint256 withdrawAmount) external;
}

interface IERC20 {
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

contract bWallet {
    address public owner;
    uint256 public nonce;
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    event Replayed(address, uint256, uint256 fee);
    event FeeIncoming(address, uint256 finalAmt, uint256 fee);
    event StakedMesh(address, uint256 amount, address token, address pool);
    event StakedMeshMatic(address, uint256 amount);
    event StakedAave(address, uint256);
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;
    // map user staked erc20 address  and amount staked
    mapping(address => mapping(address => uint256))
        public userStakedAmountERC20;

    address public bitsManager = 0x07f899CA879Ba85376D710fE448B88aF53049067;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public iUSDCcontract;
    address public aaveLendingPool = 0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;
    address public iUSDC = 0x590Cd248e16466F747e74D4cfa6C48f597059704;
    address public aEthWETH = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;
    address public iWMatic = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf;
    address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public meshToken = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a;
    address public meshSwapRouter = 0x10f4A785F458Bc144e3706575924889954946639;
    address public oTONPool = 0xE6c511Ed7549Cc1d6C1b23126D1653588C1C71bA;
    address public oTOn = 0x4B96dBf8f42C8c296573933a6616dcAfb80Ca461;

    address public WrappedTokenGatewayV3 =
        0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
    uint256 public bitsValue;
    uint256 public totalFee;
    uint256 public feez = 85;
    IWETHGateway public aaveContract;
    MeshGateway public meshContract;

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

    constructor(address _owner) payable {
        owner = _owner;
        _aaveContract = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
        aaveContract = IWETHGateway(_aaveContract);

        aEthWETHcontract = IERC20(aEthWETH);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function depositETHAave() public payable {
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

    function stakeMeshswaMatic() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approv wmatic
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        approveWMATIC(iWMatic, maxUint);

        meshContract.depositETH{value: msg.value}();
        values[msg.sender] = msg.value;
        userStakedAmountMesh[msg.sender] += msg.value;
        emit StakedMeshMatic(msg.sender, msg.value);
    }

    function stakeMeshERC20(
        uint256 amount,
        address token,
        address pool
    ) public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        IERC20(token).approve(pool, maxUint);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userStakedAmountERC20[msg.sender][token] += amount;
        meshContract = MeshGateway(pool);
        meshContract.depositToken(amount);
        emit StakedMesh(msg.sender, amount, token, pool);
    }

    function updateFee(uint256 _feez) public onlyManager {
        feez = _feez;
    }

    function withdrawETHAave() public {
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

    function withdrawETHMesh() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        meshContract.withdrawETH(maxUint);
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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyManager {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }

    function destroy(address payable recipient) public onlyManager {
        selfdestruct(recipient);
    }

    function Stake(address payable _addr, bytes memory data) public payable {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );

        emit Staked(_addr, msg.value, data);

        require(success, string(returnData));
    }

    function BitsStaking(address payable _addr, bytes memory data)
        external
        payable
    {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );
        calls[_addr] = data;
        values[_addr] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit Staked(_addr, msg.value, data);
        require(success, string(returnData));
    }

    function unStake(address _aave, bytes memory data) external {
        (bool success, bytes memory returnData) = _aave.call(data);
        require(success, string(returnData));
    }

    function approveERC20Mesh(address _token, address pool) public {
        IERC20 token = IERC20(_token);
        token.approve(
            pool,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function approveERC20Aave(address _token) public {
        IERC20 token = IERC20(_token);
        token.approve(
            aaveLendingPool,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
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

    function SplitItERC20(address _token, uint256 _staked) public {
        IERC20 token = IERC20(_token);
        uint256 feeValue = token.balanceOf(address(this)) - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        userStakedAmountERC20[msg.sender][_token] = 0;
        token.transfer(msg.sender, finalAmount);
        token.transfer(address(bitsManager), fee);
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MeshswapPools {
    
    
address MESH=0x6dBADf2a3e53885076f1D30B6198e560830cb4Bb; // token 
address iMESH=0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a; // pool
 
address WMATIC=0xb880e6AdE8709969B9FD2501820e052581aC29Cf; // token 
address iWMATIC=0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // pool
 
address WETH=0x865824C7ddF5a7486fe048bbBa2425D9c1F4903D; // token 
address iWETH=0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // pool
 
address WBTC=0xAf304d0371Ac4CB628aA7e7F0Ae46ddde1ECE1C0; // token 
address iWBTC=0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; // pool
 
address USDC=0x590Cd248e16466F747e74D4cfa6C48f597059704; // token 
address iUSDC=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // pool
 
address DAI=0xbE068B517e869f59778B3a8303DF2B8c13E05d06; // token 
address iDAI=0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // pool
 
address USDT=0x782D7eC740d997445D62e4463ce64C67c7484497; // token 
address iUSDT=0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // pool
 
address oXRP=0xd84b86F415a251D30e5a42411D0c1149c181fF74; // token 
address ioXRP=0xCc2a9051E904916047c26C90f41c000D4f273456; // pool
 
address oKLAY=0xB8578ffcECAac5df649bFBe8861Aea8c7803353A; // token 
address ioKLAY=0x0A02D33031917d836Bd7Af02F9f7F6c74d67805F; // pool
 
address oKSP=0x0426858446eE2A1D9D26C32CD24f4F9C54d174AC; // token 
address ioKSP=0x3D3B92Fe0B4c26b74F8fF13A32dD764F4DFD8b51; // pool
 
address oORC=0xeEe82264F10BB68E313599b47D6fbF2EAd7fbc4d; // token 
address ioORC=0x12c9FFE6538f20A982FD4D17912f0ca00fA82D30; // pool
 
address oMATIC=0x29bFE37F639582bDa68567De97d485c7c41E5E34; // token 
address ioMATIC=0x3f364853F01D32d581fc9734110B21C77AeEA024; // pool
 
address MaticX=0x00C3e7978Ede802d7ce6c6EfFfB4F05A4a806FD3; // token 
address iMaticX=0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6; // pool
 
address oTON=0xE6c511Ed7549Cc1d6C1b23126D1653588C1C71bA; // token 
address ioTON=0x4B96dBf8f42C8c296573933a6616dcAfb80Ca461; // pool
 
address BUSD=0x0E60e45b8083Ac694e3A5D863862Be67AbdaEcE7; // token 
address iBUSD=0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39; // pool


}