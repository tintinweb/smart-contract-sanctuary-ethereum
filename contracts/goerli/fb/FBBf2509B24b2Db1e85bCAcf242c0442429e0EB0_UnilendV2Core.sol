// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./lib/utils/Address.sol";
import "./lib/utils/math/SafeMath.sol";

import "./lib/token/ERC20/IERC20.sol";
import "./lib/token/ERC20/extensions/IERC20Metadata.sol";
import "./lib/token/ERC20/utils/SafeERC20.sol";
import "./lib/security/ReentrancyGuard.sol";



/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Unilend fee IFlashLoanReceiver.
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

interface IUnilendV2Oracle {
    function getAssetPrice(address token0, address token1, uint amount) external view returns (uint256);
}

interface IUnilendV2Position {
    function newPosition(address _pool, address _recipient) external returns (uint nftID);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getNftId(address _pool, address _user) external view returns (uint nftID);
}


interface IUnilendV2Pool {
    function setLTV(uint8 _number) external;
    function setLB(uint8 _number) external;
    function setRF(uint8 _number) external;
    function setInterestRateAddress(address _address) external;
    function accrueInterest() external;

    function lend(uint _nftID, int amount) external returns(uint);
    function redeem(uint _nftID, int tok_amount, address _receiver) external returns(int);
    function redeemUnderlying(uint _nftID, int amount, address _receiver) external returns(int);
    function borrow(uint _nftID, int amount, address payable _recipient) external;
    function repay(uint _nftID, int amount, address payer) external returns(int);
    function liquidate(uint _nftID, int amount, address _receiver, uint _toNftID) external returns(int);
    function liquidateMulti(uint[] calldata _nftIDs, int[] calldata amount, address _receiver, uint _toNftID) external returns(int);
    
    function processFlashLoan(address _receiver, int _amount) external;
    function transferFlashLoanProtocolFee(address _distributorAddress, address _token, uint256 _amount) external;
    function init(address _token0, address _token1, address _interestRate, uint8 _ltv, uint8 _lb, uint8 _rf) external;
    
    function getLTV() external view returns (uint);
    function getLB() external view returns (uint);
    function getRF() external view returns (uint);
    
    function userBalanceOftoken0(uint _nftID) external view returns (uint _lendBalance0, uint _borrowBalance0);
    function userBalanceOftoken1(uint _nftID) external view returns (uint _lendBalance1, uint _borrowBalance1);
    function userBalanceOftokens(uint _nftID) external view returns (uint _lendBalance0, uint _borrowBalance0, uint _lendBalance1, uint _borrowBalance1);
    function userSharesOftoken0(uint _nftID) external view returns (uint _lendShare0, uint _borrowShare0);
    function userSharesOftoken1(uint _nftID) external view returns (uint _lendShare1, uint _borrowShare1);
    function userSharesOftokens(uint _nftID) external view returns (uint _lendShare0, uint _borrowShare0, uint _lendShare1, uint _borrowShare1);
    function userHealthFactor(uint _nftID) external view returns (uint256 _healthFactor0, uint256 _healthFactor1);

    function getAvailableLiquidity0() external view returns (uint _available);
    function getAvailableLiquidity1() external view returns (uint _available);
}






contract UnilendV2Core is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public governor;
    address public defaultInterestRate;
    address public poolMasterAddress;
    address payable public distributorAddress;
    address public oracleAddress;
    address public positionsAddress;
    
    uint public poolLength;
    
    uint256 private FLASHLOAN_FEE_TOTAL = 5;
    uint256 private FLASHLOAN_FEE_PROTOCOL = 3000;


    uint8 private default_LTV = 70;
    uint8 private default_LB = 10;
    uint8 private default_RF = 10;


    
    mapping(address => mapping(address => address)) public getPool;
    mapping(address => poolTokens) private Pool;
    
    struct poolTokens {
        address token0;
        address token1;
    }
    
    
    constructor(address _poolMasterAddress) {
        require(_poolMasterAddress != address(0), "UnilendV2: ZERO ADDRESS");
        governor = msg.sender;
        poolMasterAddress = _poolMasterAddress;
    }
    
    
    event PoolCreated(address indexed token0, address indexed token1, address pool, uint);
    
    
    /**
    * @dev emitted when a flashloan is executed
    * @param _target the address of the flashLoanReceiver
    * @param _reserve the address of the reserve
    * @param _amount the amount requested
    * @param _totalFee the total fee on the amount
    * @param _protocolFee the part of the fee for the protocol
    * @param _timestamp the timestamp of the action
    **/
    event FlashLoan(
        address indexed _target,
        address indexed _reserve,
        int _amount,
        uint256 _totalFee,
        uint256 _protocolFee,
        uint256 _timestamp
    );
    
    event NewDefaultMarketConfig(uint8 _ltv, uint8 _lb, uint8 _rf);
    event NewDefaultInterestRateAddress(address indexed _address);
    event NewGovernorAddress(address indexed _address);
    event NewPositionAddress(address indexed _address);
    event NewOracleAddress(address indexed _address);
    
    
    modifier onlyGovernor {
        require(
            governor == msg.sender,
            "The caller must be a governor"
        );
        _;
    }
    
    /**
    * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
    * is not zero.
    * @param _amount the amount provided
    **/
    modifier onlyAmountNotZero(int _amount) {
        require(_amount != 0, "Amount must not be 0");
        _;
    }
    
    receive() payable external {}
    
    /**
    * @dev returns the fee applied to a flashloan and the portion to redirect to the protocol, in basis points.
    **/
    function getFlashLoanFeesInBips() public view returns (uint256, uint256) {
        return (FLASHLOAN_FEE_TOTAL, FLASHLOAN_FEE_PROTOCOL);
    }
    
    
    function getOraclePrice(address _token0, address _token1, uint _amount) public view returns(uint){
        return IUnilendV2Oracle(oracleAddress).getAssetPrice(_token1, _token0, _amount);
    }
    

    function getPoolLTV(address _pool) public view returns (uint _ltv) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            _ltv = IUnilendV2Pool(_pool).getLTV();
        }
    }

    function getPoolTokens(address _pool) public view returns (address, address) {
        poolTokens memory pt = Pool[_pool];
        return (pt.token0, pt.token1);
    }

    function getPoolByTokens(address _token0, address _token1) public view returns (address) {
        return getPool[_token0][_token1];
    }
    
    
    function balanceOfUserToken0(address _pool, address _address) external view returns (uint _lendBalance0, uint _borrowBalance0) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendBalance0, _borrowBalance0) = IUnilendV2Pool(_pool).userBalanceOftoken0(_nftID);
            }
        }
    }
    

    function balanceOfUserToken1(address _pool, address _address) external view returns (uint _lendBalance1, uint _borrowBalance1) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendBalance1, _borrowBalance1) = IUnilendV2Pool(_pool).userBalanceOftoken1(_nftID);
            }
        }
    }
    
    function balanceOfUserTokens(address _pool, address _address) external view returns (uint _lendBalance0, uint _borrowBalance0, uint _lendBalance1, uint _borrowBalance1) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendBalance0, _borrowBalance0, _lendBalance1, _borrowBalance1) = IUnilendV2Pool(_pool).userBalanceOftokens(_nftID);
            }
        }
    }
    
    
    function shareOfUserToken0(address _pool, address _address) external view returns (uint _lendShare0, uint _borrowShare0) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendShare0, _borrowShare0) = IUnilendV2Pool(_pool).userSharesOftoken0(_nftID);
            }
        }
    }
    

    function shareOfUserToken1(address _pool, address _address) external view returns (uint _lendShare1, uint _borrowShare1) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendShare1, _borrowShare1) = IUnilendV2Pool(_pool).userSharesOftoken1(_nftID);
            }
        }
    }
    

    function shareOfUserTokens(address _pool, address _address) external view returns (uint _lendShare0, uint _borrowShare0, uint _lendShare1, uint _borrowShare1) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_lendShare0, _borrowShare0, _lendShare1, _borrowShare1) = IUnilendV2Pool(_pool).userSharesOftokens(_nftID);
            }
        }
    }
    

    function getUserHealthFactor(address _pool, address _address) external view returns (uint _healthFactor0, uint _healthFactor1) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _address);
            if(_nftID > 0){
                (_healthFactor0, _healthFactor1) = IUnilendV2Pool(_pool).userHealthFactor(_nftID);
            }
        }
    }


    function getPoolAvailableLiquidity(address _pool) external view returns (uint _token0Liquidity, uint _token1Liquidity) {
        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            _token0Liquidity = IUnilendV2Pool(_pool).getAvailableLiquidity0();
            _token1Liquidity = IUnilendV2Pool(_pool).getAvailableLiquidity1();
        }
    }
    




    function setDefaultMarketConfig(uint8 _ltv, uint8 _lb, uint8 _rf) external onlyGovernor {
        require(_ltv > 0 && _ltv < 99, "UnilendV2: INVALID RANGE");
        require(_lb > 0 && _lb < (100-_ltv), "UnilendV2: INVALID RANGE");
        require(_rf > 0 && _rf < 90, "UnilendV2: INVALID RANGE");
        
        default_LTV = _ltv;
        default_LB = _lb;
        default_RF = _rf;

        emit NewDefaultMarketConfig(_ltv, _lb, _rf); 
    }

    
    function setPoolLTV(address _pool, uint8 _number) external onlyGovernor {
        require(_number > 0 && _number < 99, "UnilendV2: INVALID RANGE");

        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            IUnilendV2Pool(_pool).setLTV(_number);
        }
    }
    
    function setPoolLB(address _pool, uint8 _number) external onlyGovernor {
        require(_number > 0 && _number < 99, "UnilendV2: INVALID RANGE");

        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            IUnilendV2Pool(_pool).setLB(_number);
        }
    }
    
    function setPoolRF(address _pool, uint8 _number) external onlyGovernor {
        require(_number > 0 && _number < 99, "UnilendV2: INVALID RANGE");

        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            IUnilendV2Pool(_pool).setRF(_number);
        }
    }

    function setPoolInterestRateAddress(address _pool, address _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");

        (address _token0, ) = getPoolTokens(_pool);
        if(_token0 != address(0)){
            IUnilendV2Pool(_pool).setInterestRateAddress(_address);
        }
    }

    function setDefaultInterestRateAddress(address _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");
        defaultInterestRate = _address;

        emit NewDefaultInterestRateAddress(_address); 
    }


    /**
    * @dev set new admin for contract.
    * @param _address the address of new governor
    **/
    function setGovernor(address _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");
        governor = _address;

        emit NewGovernorAddress(_address); 
    }
    
    function setPositionAddress(address _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");
        require(positionsAddress == address(0), "UnilendV2: Position Address Already Set");
        positionsAddress = _address;

        emit NewPositionAddress(_address); 
    }
    
    /**
    * @dev set new oracle address.
    * @param _address new address
    **/
    function setOracleAddress(address _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");
        oracleAddress = _address;

        emit NewOracleAddress(_address); 
    }
    
    /**
    * @dev set new distributor address.
    * @param _address new address
    **/
    function setDistributorAddress(address payable _address) external onlyGovernor {
        require(_address != address(0), "UnilendV2: ZERO ADDRESS");
        distributorAddress = _address;
    }
    
    /**
    * @dev set new flash loan fees.
    * @param _newFeeTotal total fee
    * @param _newFeeProtocol protocol fee
    **/
    function setFlashLoanFeesInBips(uint _newFeeTotal, uint _newFeeProtocol) external onlyGovernor returns (bool) {
        require(_newFeeTotal > 0 && _newFeeTotal < 10000, "UnilendV1: INVALID TOTAL FEE RANGE");
        require(_newFeeProtocol > 0 && _newFeeProtocol < 10000, "UnilendV1: INVALID PROTOCOL FEE RANGE");
        
        FLASHLOAN_FEE_TOTAL = _newFeeTotal;
        FLASHLOAN_FEE_PROTOCOL = _newFeeProtocol;
        
        return true;
    }
    
    
    function transferFlashLoanProtocolFeeInternal(address _pool, address _token, uint256 _amount) internal {
        if(distributorAddress != address(0)){
            IUnilendV2Pool(_pool).transferFlashLoanProtocolFee(distributorAddress, _token, _amount);
        }
    }
    
    
    /**
    * @dev allows smartcontracts to access the liquidity of the pool within one transaction,
    * as long as the amount taken plus a fee is returned. NOTE There are security concerns for developers of flashloan receiver contracts
    * that must be kept into consideration.
    * @param _receiver The address of the contract receiving the funds. The receiver should implement the IFlashLoanReceiver interface.
    * @param _pool the address of the principal reserve pool
    * @param _amount the amount requested for this flashloan
    **/
    function flashLoan(address _receiver, address _pool, int _amount, bytes calldata _params)
        external
        nonReentrant
    {
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');
        
        address _reserve = _amount < 0 ? _token0 : _token1;
        uint _amountU =  _amount < 0 ? uint(-_amount) : uint(_amount);

        //check that the reserve has enough available liquidity
        uint256 availableLiquidityBefore = IERC20(_reserve).balanceOf(_pool);
        
        require(
            availableLiquidityBefore >= _amountU,
            "There is not enough liquidity available to borrow"
        );

        (uint256 totalFeeBips, uint256 protocolFeeBips) = getFlashLoanFeesInBips();
        //calculate amount fee
        uint256 amountFee = _amountU.mul(totalFeeBips).div(10000);

        //protocol fee is the part of the amountFee reserved for the protocol - the rest goes to depositors
        uint256 protocolFee = amountFee.mul(protocolFeeBips).div(10000);
        require(
            amountFee > 0 && protocolFee > 0,
            "The requested amount is too small for a flashLoan."
        );
        
        IUnilendV2Pool(_pool).processFlashLoan(_receiver, _amount);
        
        IFlashLoanReceiver(_receiver).executeOperation(_reserve, _amountU, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = IERC20(_reserve).balanceOf(_pool);

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
        
        transferFlashLoanProtocolFeeInternal(_pool, _reserve, protocolFee);

        // solium-disable-next-line
        emit FlashLoan(_receiver, _reserve, _amount, amountFee, protocolFee, block.timestamp);
    }
    
    

    
    
    /**
    * @dev deposits The underlying asset into the reserve.
    * @param _pool the address of the pool
    * @param _amount the amount to be deposited
    **/
    function lend(address _pool, int _amount) external onlyAmountNotZero(_amount) nonReentrant returns(uint mintedTokens) {
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, msg.sender);
        if(_nftID == 0){
            _nftID = IUnilendV2Position(positionsAddress).newPosition(_pool, msg.sender);
        }

        address _reserve = _amount < 0 ? _token0 : _token1;
        mintedTokens = iLend(_pool, _reserve, _amount, _nftID);
    }
    
    function iLend(address _pool, address _token, int _amount, uint _nftID) internal returns(uint mintedTokens) {
        address _user = msg.sender;
        IUnilendV2Pool(_pool).accrueInterest();
        
        if(_amount < 0){
            uint reserveBalance = IERC20(_token).balanceOf(_pool);
            IERC20(_token).safeTransferFrom(_user, _pool, uint(-_amount));
            _amount = -int( ( IERC20(_token).balanceOf(_pool) ).sub(reserveBalance) );
        }
        
        if(_amount > 0){
            uint reserveBalance = IERC20(_token).balanceOf(_pool);
            IERC20(_token).safeTransferFrom(_user, _pool, uint(_amount));
            _amount = int( ( IERC20(_token).balanceOf(_pool) ).sub(reserveBalance) );
        }

        mintedTokens = IUnilendV2Pool(_pool).lend(_nftID, _amount);
    }
    
    
    /**
    * @dev Redeems the uTokens for underlying assets.
    * @param _pool the address of the pool
    * @param _token_amount the amount to be redeemed
    **/
    function redeem(address _pool, int _token_amount, address _receiver) external nonReentrant returns(int redeemTokens) {
        (address _token0, ) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, msg.sender);
        require(_nftID > 0, 'UnilendV2: POSITION NOT FOUND');
        
        redeemTokens = IUnilendV2Pool(_pool).redeem(_nftID, _token_amount, _receiver);
    }
    
    /**
    * @dev Redeems the underlying amount of assets.
    * @param _pool the address of the pool
    * @param _amount the amount to be redeemed
    **/
    function redeemUnderlying(address _pool, int _amount, address _receiver) external onlyAmountNotZero(_amount) nonReentrant returns(int _token_amount){
        (address _token0, ) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, msg.sender);
        require(_nftID > 0, 'UnilendV2: POSITION NOT FOUND');
        
        _token_amount = IUnilendV2Pool(_pool).redeemUnderlying(_nftID, _amount, _receiver);
    }
    
    
    
    function borrow(address _pool, int _amount, uint _collateral_amount, address payable _recipient) external onlyAmountNotZero(_amount) nonReentrant {
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');
        
        IUnilendV2Pool _poolContract = IUnilendV2Pool(_pool);
        address _user = msg.sender;

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _user);
        if(_nftID == 0){
            _nftID = IUnilendV2Position(positionsAddress).newPosition(_pool, _user);
        }
        
        if(_amount < 0){
            require(
                _poolContract.getAvailableLiquidity0() >= uint(-_amount),
                "There is not enough liquidity0 available to borrow"
            );
            
            // lend collateral 
            if(_collateral_amount > 0){
                iLend(_pool, _token1, int(_collateral_amount), _nftID);
            }
        }
        
        
        if(_amount > 0){
            require(
                _poolContract.getAvailableLiquidity1() >= uint(_amount),
                "There is not enough liquidity1 available to borrow"
            );
            
            // lend collateral 
            if(_collateral_amount > 0){
                iLend(_pool, _token0, -int(_collateral_amount), _nftID);
            }
        }
        
        _poolContract.borrow(_nftID, _amount, _recipient);
    }
    
    
    function repay(address _pool, int _amount, address _for) external onlyAmountNotZero(_amount) nonReentrant returns (int _retAmount) {
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');
        
        IUnilendV2Pool _poolContract = IUnilendV2Pool(_pool);
        address _user = msg.sender;

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _for);
        require(_nftID > 0, 'UnilendV2: POSITION NOT FOUND');
        
        _retAmount = _poolContract.repay(_nftID, _amount, _user);
        
        if(_retAmount < 0){
            IERC20(_token0).safeTransferFrom(_user, _pool, uint(-_retAmount));
        }
        
        if(_retAmount > 0){
            IERC20(_token1).safeTransferFrom(_user, _pool, uint(_retAmount));
        }
    }
    
    
    
    
    function liquidate(address _pool, address _for, int _amount, address _receiver, bool uPosition) external onlyAmountNotZero(_amount) nonReentrant returns(int payAmount) {
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');
        
        IUnilendV2Pool _poolContract = IUnilendV2Pool(_pool);
        address _user = msg.sender;

        uint _nftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _for);
        require(_nftID > 0, 'UnilendV2: POSITION NOT FOUND');

        if(uPosition){
            uint _toNftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _receiver);
            if(_toNftID == 0){
                _toNftID = IUnilendV2Position(positionsAddress).newPosition(_pool, _receiver);
            }

            payAmount = _poolContract.liquidate(_nftID, _amount, _receiver, _toNftID);
        } 
        else {
            payAmount = _poolContract.liquidate(_nftID, _amount, _receiver, 0);
        }
        

        if(payAmount < 0){
            IERC20(_token0).safeTransferFrom(_user, _pool, uint(-payAmount));
        }
        
        if(payAmount > 0){
            IERC20(_token1).safeTransferFrom(_user, _pool, uint(payAmount));
        }
    }

    
    function liquidateMulti(address _pool, uint[] calldata _nftIDs, int[] calldata _amounts, address _receiver, bool uPosition) external nonReentrant returns (int payAmount){
        (address _token0, address _token1) = getPoolTokens(_pool);
        require(_token0 != address(0), 'UnilendV2: POOL NOT FOUND');
        require(_nftIDs.length == _amounts.length, 'UnilendV2: INVALID ARRAY LENGTH');
        
        IUnilendV2Pool _poolContract = IUnilendV2Pool(_pool);
        address _user = msg.sender;

        if(uPosition){
            uint _toNftID = IUnilendV2Position(positionsAddress).getNftId(_pool, _receiver);
            if(_toNftID == 0){
                _toNftID = IUnilendV2Position(positionsAddress).newPosition(_pool, _receiver);
            }

            payAmount = _poolContract.liquidateMulti(_nftIDs, _amounts, _receiver, _toNftID);
        } 
        else {
            payAmount = _poolContract.liquidateMulti(_nftIDs, _amounts, _receiver, 0);
        }

        if(payAmount < 0){
            IERC20(_token0).safeTransferFrom(_user, _pool, uint(-payAmount));
        }
        
        if(payAmount > 0){
            IERC20(_token1).safeTransferFrom(_user, _pool, uint(payAmount));
        }
    }
    
    
    
    /**
    * @dev Creates pool for assets.
    * This function is executed by the overlying uToken contract.
    * @param _tokenA the address of the token0
    * @param _tokenB the address of the token1
    **/
    function createPool(address _tokenA, address _tokenB) public returns (address) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        require(_tokenA != address(0), 'UnilendV2: ZERO ADDRESS');
        require(_tokenA != _tokenB, 'UnilendV2: IDENTICAL ADDRESSES');
        require(getPool[token0][token1] == address(0), 'UnilendV2: POOL ALREADY CREATED');
        
        address _poolNft;
        bytes20 targetBytes = bytes20(poolMasterAddress);

        require(IERC20Metadata(token0).totalSupply() > 0, 'UnilendV2: INVALID ERC20 TOKEN');
        require(IERC20Metadata(token1).totalSupply() > 0, 'UnilendV2: INVALID ERC20 TOKEN');

        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _poolNft := create(0, clone, 0x37)
        }
        
        address _poolAddress = address(_poolNft);
        
        IUnilendV2Pool(_poolAddress).init(token0, token1, defaultInterestRate, default_LTV, default_LB, default_RF);
        
        poolTokens storage pt = Pool[_poolAddress];
        pt.token0 = token0;
        pt.token1 = token1;
        
        getPool[token0][token1] = _poolAddress;
        getPool[token1][token0] = _poolAddress; // populate mapping in the reverse direction
        
        poolLength++;
        
        emit PoolCreated(token0, token1, _poolAddress, poolLength);
        
        return _poolAddress;
    }
    
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}