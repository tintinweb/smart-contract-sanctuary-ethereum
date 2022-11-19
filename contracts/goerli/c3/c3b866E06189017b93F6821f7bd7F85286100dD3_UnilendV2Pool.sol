// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./lib/utils/math/SafeMath.sol";
import "./lib/token/ERC20/utils/SafeERC20.sol";
import "./lib/security/ReentrancyGuard.sol";
import "./lib/utils/Counters.sol";


library MathEx {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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


contract UnilendV2library {
    using SafeMath for uint256;
    
    function priceScaled(uint _price) internal pure returns (uint){
        uint256 _length = 0;
        uint256 tempI = _price;
        while (tempI != 0) { tempI = tempI/10; _length++; }

        _length = _length.sub(3);
        return (_price.div(10**_length)).mul(10**_length);
    }
    
    function calculateShare(uint _totalShares, uint _totalAmount, uint _amount) internal pure returns (uint){
        if(_totalShares == 0){
            return MathEx.sqrt(_amount.mul( _amount )).sub(10**3);
        } else {
            return (_amount).mul( _totalShares ).div( _totalAmount );
        }
    }
    
    function getShareValue(uint _totalAmount, uint _totalSupply, uint _amount) internal pure returns (uint){
        return ( _amount.mul(_totalAmount) ).div( _totalSupply );
    }
    
    function getShareByValue(uint _totalAmount, uint _totalSupply, uint _valueAmount) internal pure returns (uint){
        return ( _valueAmount.mul(_totalSupply) ).div( _totalAmount );
    }
    
    function calculateInterest(uint _principal, uint _rate, uint _duration) internal pure returns (uint){
        return _principal.mul( _rate.mul(_duration) ).div(10**20);
    }
}


contract UnilendV2transfer {
    using SafeERC20 for IERC20;

    address public token0;
    address public token1;
    address payable public core;

    modifier onlyCore {
        require(
            core == msg.sender,
            "Not Permitted"
        );
        _;
    }

    /**
    * @dev transfers to the user a specific amount from the reserve.
    * @param _reserve the address of the reserve where the transfer is happening
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _reserve, address payable _user, uint256 _amount) internal {
        require(_user != address(0), "UnilendV1: USER ZERO ADDRESS");
        
        IERC20(_reserve).safeTransfer(_user, _amount);
    }
}


interface IUnilendV2Core {
    function getOraclePrice(address _token0, address _token1, uint _amount) external view returns(uint);
}

interface IUnilendV2InterestRateModel {
    function getCurrentInterestRate(uint totalBorrow, uint availableBorrow) external pure returns (uint);
}



contract UnilendV2Pool is UnilendV2library, UnilendV2transfer {
    using SafeMath for uint256;
    
    bool initialized;
    address public interestRateAddress;
    uint public lastUpdated;

    uint8 ltv;  // loan to value
    uint8 lb;   // liquidation bonus
    uint8 rf;   // reserve factor
    uint64 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    tM public token0Data;
    tM public token1Data;
    mapping(uint => pM) public positionData;
    
    struct pM {
        uint token0lendShare;
        uint token1lendShare;
        uint token0borrowShare;
        uint token1borrowShare;
    }
    
    struct tM {
        uint totalLendShare;
        uint totalBorrowShare;
        uint totalBorrow;
    }
    


    // /**
    // * @dev emitted on lend
    // * @param _positionID the id of position NFT
    // * @param _amount the amount to be deposited for token
    // * @param _timestamp the timestamp of the action
    // **/
    event Lend( address indexed _asset, uint256 indexed _positionID, uint256 _amount, uint256 _token_amount );
    event Redeem( address indexed _asset, uint256 indexed _positionID, uint256 _token_amount, uint256 _amount );
    event InterestUpdate( uint256 _newRate0, uint256 _newRate1, uint256 totalBorrows0, uint256 totalBorrows1 );
    event Borrow( address indexed _asset, uint256 indexed _positionID, uint256 _amount, uint256 totalBorrows, address _recipient );
    event RepayBorrow( address indexed _asset, uint256 indexed _positionID, uint256 _amount, uint256 totalBorrows, address _payer );
    event LiquidateBorrow( address indexed _asset, uint256 indexed _positionID, uint256 indexed _toPositionID, uint repayAmount, uint seizeTokens );
    event LiquidationPriceUpdate( uint256 indexed _positionID, uint256 _price, uint256 _last_price, uint256 _amount );

    event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);
    event NewLTV(uint oldLTV, uint newLTV);
    event NewLB(uint oldLB, uint newLB);
    event NewRF(uint oldRF, uint newRF);


    constructor() {
        core = payable(msg.sender);
    }
    
    function init(
        address _token0, 
        address _token1,
        address _interestRate,
        uint8 _ltv,
        uint8 _lb,
        uint8 _rf
    ) external {
        require(!initialized, "UnilendV2: POOL ALREADY INIT");

        initialized = true;
        
        token0 = _token0;
        token1 = _token1;
        interestRateAddress = _interestRate;
        core = payable(msg.sender);
        
        ltv = _ltv;
        lb = _lb;
        rf = _rf;
    }
    
    
    function getLTV() external view returns (uint) { return ltv; }
    function getLB() external view returns (uint) { return lb; }
    function getRF() external view returns (uint) { return rf; }
    
    function checkHealthFactorLtv(uint _nftID) internal view {
        (uint256 _healthFactor0, uint256 _healthFactor1) = userHealthFactorLtv(_nftID);
        require(_healthFactor0 > HEALTH_FACTOR_LIQUIDATION_THRESHOLD, "Low Ltv HealthFactor0");
        require(_healthFactor1 > HEALTH_FACTOR_LIQUIDATION_THRESHOLD, "Low Ltv HealthFactor1");
    }

    function getInterestRate(uint _totalBorrow, uint _availableBorrow) public view returns (uint) {
        return IUnilendV2InterestRateModel(interestRateAddress).getCurrentInterestRate(_totalBorrow, _availableBorrow);
    }
    
    function getAvailableLiquidity0() public view returns (uint _available) {
        tM memory _tm0 = token0Data;

        uint totalBorrow = _tm0.totalBorrow;
        uint totalLiq = totalBorrow.add( IERC20(token0).balanceOf(address(this)) );
        uint maxAvail = ( totalLiq.mul( uint(100).sub(rf) ) ).div(100);

        if(maxAvail > totalBorrow){
            _available = maxAvail.sub(totalBorrow);
        }
    }
    
    function getAvailableLiquidity1() public view returns (uint _available) {
        tM memory _tm1 = token1Data;

        uint totalBorrow = _tm1.totalBorrow;
        uint totalLiq = totalBorrow.add( IERC20(token1).balanceOf(address(this)) );
        uint maxAvail = ( totalLiq.mul( uint(100).sub(rf) ) ).div(100);

        if(maxAvail > totalBorrow){
            _available = maxAvail.sub(totalBorrow);
        }
    }

    function userHealthFactorLtv(uint _nftID) public view returns (uint256 _healthFactor0, uint256 _healthFactor1) {
        (uint _lendBalance0, uint _borrowBalance0) = userBalanceOftoken0(_nftID);
        (uint _lendBalance1, uint _borrowBalance1) = userBalanceOftoken1(_nftID);
        
        if (_borrowBalance0 == 0){
            _healthFactor0 = type(uint256).max;
        } 
        else {
            uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token1, token0, _lendBalance1);
            _healthFactor0 = (collateralBalance.mul(ltv).mul(1e18).div(100)).div(_borrowBalance0);
        }
        
        
        if (_borrowBalance1 == 0){
            _healthFactor1 = type(uint256).max;
        } 
        else {
            uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token0, token1, _lendBalance0);
            _healthFactor1 = (collateralBalance.mul(ltv).mul(1e18).div(100)).div(_borrowBalance1);
        }
        
    }

    function userHealthFactor(uint _nftID) public view returns (uint256 _healthFactor0, uint256 _healthFactor1) {
        (uint _lendBalance0, uint _borrowBalance0) = userBalanceOftoken0(_nftID);
        (uint _lendBalance1, uint _borrowBalance1) = userBalanceOftoken1(_nftID);
        
        if (_borrowBalance0 == 0){
            _healthFactor0 = type(uint256).max;
        } 
        else {
            uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token1, token0, _lendBalance1);
            _healthFactor0 = (collateralBalance.mul(uint(100).sub(lb)).mul(1e18).div(100)).div(_borrowBalance0);
        }
        
        
        if (_borrowBalance1 == 0){
            _healthFactor1 = type(uint256).max;
        } 
        else {
            uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token0, token1, _lendBalance0);
            _healthFactor1 = (collateralBalance.mul(uint(100).sub(lb)).mul(1e18).div(100)).div(_borrowBalance1);
        }
        
    }
    
    function userBalanceOftoken0(uint _nftID) public view returns (uint _lendBalance0, uint _borrowBalance0) {
        pM memory _positionMt = positionData[_nftID];
        tM memory _tm0 = token0Data;
        
        uint _totalBorrow = _tm0.totalBorrow;
        if(block.number > lastUpdated){
            uint interestRate0 = getInterestRate(_tm0.totalBorrow, getAvailableLiquidity0());
            _totalBorrow = _totalBorrow.add( calculateInterest(_tm0.totalBorrow, interestRate0, (block.number - lastUpdated)) );
        }
        
        if(_positionMt.token0lendShare > 0){
            uint tokenBalance0 = IERC20(token0).balanceOf(address(this));
            uint _totTokenBalance0 = tokenBalance0.add(_totalBorrow);
            _lendBalance0 = getShareValue(_totTokenBalance0, _tm0.totalLendShare, _positionMt.token0lendShare);
        }
        
        if(_positionMt.token0borrowShare > 0){
            _borrowBalance0 = getShareValue( _totalBorrow, _tm0.totalBorrowShare, _positionMt.token0borrowShare);
        }
    }
    
    function userBalanceOftoken1(uint _nftID) public view returns (uint _lendBalance1, uint _borrowBalance1) {
        pM memory _positionMt = positionData[_nftID];
        tM memory _tm1 = token1Data;
        
        uint _totalBorrow = _tm1.totalBorrow;
        if(block.number > lastUpdated){
            uint interestRate1 = getInterestRate(_tm1.totalBorrow, getAvailableLiquidity1());
            _totalBorrow = _totalBorrow.add( calculateInterest(_tm1.totalBorrow, interestRate1, (block.number - lastUpdated)) );
        }
        
        if(_positionMt.token1lendShare > 0){
            uint tokenBalance1 = IERC20(token1).balanceOf(address(this));
            uint _totTokenBalance1 = tokenBalance1.add(_totalBorrow);
            _lendBalance1 = getShareValue(_totTokenBalance1, _tm1.totalLendShare, _positionMt.token1lendShare);
        }
        
        if(_positionMt.token1borrowShare > 0){
            _borrowBalance1 = getShareValue( _totalBorrow, _tm1.totalBorrowShare, _positionMt.token1borrowShare);
        }
    }

    function userBalanceOftokens(uint _nftID) public view returns (uint _lendBalance0, uint _borrowBalance0, uint _lendBalance1, uint _borrowBalance1) {
        (_lendBalance0, _borrowBalance0) = userBalanceOftoken0(_nftID);
        (_lendBalance1, _borrowBalance1) = userBalanceOftoken1(_nftID);
    }

    function userSharesOftoken0(uint _nftID) public view returns (uint _lendShare0, uint _borrowShare0) {
        pM memory _positionMt = positionData[_nftID];

        return (_positionMt.token0lendShare, _positionMt.token0borrowShare);
    }

    function userSharesOftoken1(uint _nftID) public view returns (uint _lendShare1, uint _borrowShare1) {
        pM memory _positionMt = positionData[_nftID];

        return (_positionMt.token1lendShare, _positionMt.token1borrowShare);
    }

    function userSharesOftokens(uint _nftID) public view returns (uint _lendShare0, uint _borrowShare0, uint _lendShare1, uint _borrowShare1) {
        pM memory _positionMt = positionData[_nftID];

        return (_positionMt.token0lendShare, _positionMt.token0borrowShare, _positionMt.token1lendShare, _positionMt.token1borrowShare);
    }

    function poolData() external view returns (
        uint _totalLendShare0, 
        uint _totalBorrowShare0, 
        uint _totalBorrow0,
        uint _totalBalance0, 
        uint _totalAvailableLiquidity0, 
        uint _totalLendShare1, 
        uint _totalBorrowShare1, 
        uint _totalBorrow1,
        uint _totalBalance1, 
        uint _totalAvailableLiquidity1
    ) {
        tM storage _tm0 = token0Data;
        tM storage _tm1 = token1Data;

        return (
            _tm0.totalLendShare, 
            _tm0.totalBorrowShare, 
            _tm0.totalBorrow,
            IERC20(token0).balanceOf(address(this)),
            getAvailableLiquidity0(),
            _tm1.totalLendShare, 
            _tm1.totalBorrowShare, 
            _tm1.totalBorrow,
            IERC20(token1).balanceOf(address(this)),
            getAvailableLiquidity1()
        );
    }




    function setInterestRateAddress(address _address) public onlyCore {
        emit NewMarketInterestRateModel(interestRateAddress, _address);
        interestRateAddress = _address;
    }

    function setLTV(uint8 _number) public onlyCore {
        emit NewLTV(ltv, _number);
        ltv = _number;
    }

    function setLB(uint8 _number) public onlyCore {
        emit NewLB(lb, _number);
        lb = _number;
    }

    function setRF(uint8 _number) public onlyCore {
        emit NewRF(rf, _number);
        rf = _number;
    }
    
    function accrueInterest() public {
        uint remainingBlocks = block.number - lastUpdated;
        
        if(remainingBlocks > 0){
            tM storage _tm0 = token0Data;
            tM storage _tm1 = token1Data;

            uint interestRate0 = getInterestRate(_tm0.totalBorrow, getAvailableLiquidity0());
            uint interestRate1 = getInterestRate(_tm1.totalBorrow, getAvailableLiquidity1());

            _tm0.totalBorrow = _tm0.totalBorrow.add( calculateInterest(_tm0.totalBorrow, interestRate0, remainingBlocks) );
            _tm1.totalBorrow = _tm1.totalBorrow.add( calculateInterest(_tm1.totalBorrow, interestRate1, remainingBlocks) );
            
            lastUpdated = block.number;

            emit InterestUpdate(interestRate0, interestRate1, _tm0.totalBorrow, _tm1.totalBorrow);
        }
    }

    function transferFlashLoanProtocolFee(address _distributorAddress, address _token, uint256 _amount) external onlyCore {
        transferToUser(_token, payable(_distributorAddress), _amount);
    }
    
    function processFlashLoan(address _receiver, int _amount) external onlyCore {
        accrueInterest();

        //transfer funds to the receiver
        if(_amount < 0){
            transferToUser(token0, payable(_receiver), uint(-_amount));
        } 
        
        if(_amount > 0){
            transferToUser(token1, payable(_receiver), uint(_amount));
        } 
    }
    
    function _mintLPposition(uint _nftID, uint tok_amount0, uint tok_amount1) internal {
        pM storage _positionMt = positionData[_nftID];
        
        if(tok_amount0 > 0){
            tM storage _tm0 = token0Data;
            
            _positionMt.token0lendShare = _positionMt.token0lendShare.add(tok_amount0);
            _tm0.totalLendShare = _tm0.totalLendShare.add(tok_amount0);
        }
        
        if(tok_amount1 > 0){
            tM storage _tm1 = token1Data;
            
            _positionMt.token1lendShare = _positionMt.token1lendShare.add(tok_amount1);
            _tm1.totalLendShare = _tm1.totalLendShare.add(tok_amount1);
        }
    }
    
    
    function _burnLPposition(uint _nftID, uint tok_amount0, uint tok_amount1) internal {
        pM storage _positionMt = positionData[_nftID];
        
        if(tok_amount0 > 0){
            tM storage _tm0 = token0Data;
            
            _positionMt.token0lendShare = _positionMt.token0lendShare.sub(tok_amount0);
            _tm0.totalLendShare = _tm0.totalLendShare.sub(tok_amount0);
        }
        
        if(tok_amount1 > 0){
            tM storage _tm1 = token1Data;
            
            _positionMt.token1lendShare = _positionMt.token1lendShare.sub(tok_amount1);
            _tm1.totalLendShare = _tm1.totalLendShare.sub(tok_amount1);
        }
    }
    
    
    function _mintBposition(uint _nftID, uint tok_amount0, uint tok_amount1) internal {
        pM storage _positionMt = positionData[_nftID];
        
        if(tok_amount0 > 0){
            tM storage _tm0 = token0Data;
            
            _positionMt.token0borrowShare = _positionMt.token0borrowShare.add(tok_amount0);
            _tm0.totalBorrowShare = _tm0.totalBorrowShare.add(tok_amount0);
        }
        
        if(tok_amount1 > 0){
            tM storage _tm1 = token1Data;
            
            _positionMt.token1borrowShare = _positionMt.token1borrowShare.add(tok_amount1);
            _tm1.totalBorrowShare = _tm1.totalBorrowShare.add(tok_amount1);
        }
    }
    
    
    function _burnBposition(uint _nftID, uint tok_amount0, uint tok_amount1) internal {
        pM storage _positionMt = positionData[_nftID];
        
        if(tok_amount0 > 0){
            tM storage _tm0 = token0Data;
            
            _positionMt.token0borrowShare = _positionMt.token0borrowShare.sub(tok_amount0);
            _tm0.totalBorrowShare = _tm0.totalBorrowShare.sub(tok_amount0);
        }
        
        if(tok_amount1 > 0){
            tM storage _tm1 = token1Data;
            
            _positionMt.token1borrowShare = _positionMt.token1borrowShare.sub(tok_amount1);
            _tm1.totalBorrowShare = _tm1.totalBorrowShare.sub(tok_amount1);
        }
    }
    
    
    // --------
    
    
    function lend(uint _nftID, int amount) external onlyCore returns(uint) {
        uint ntokens0; uint ntokens1;
        
        if(amount < 0){
            tM storage _tm0 = token0Data;
            
            uint tokenBalance0 = IERC20(token0).balanceOf(address(this));
            uint _totTokenBalance0 = tokenBalance0.add(_tm0.totalBorrow);
            ntokens0 = calculateShare(_tm0.totalLendShare, _totTokenBalance0.sub(uint(-amount)), uint(-amount));
            if(_tm0.totalLendShare == 0){
                _mintLPposition(0, 10**3, 0);
            }
            require(ntokens0 > 0, 'Insufficient Liquidity Minted');

            emit Lend(token0, _nftID, uint(-amount), ntokens0);
        }
        
        if(amount > 0){
            tM storage _tm1 = token1Data;
            
            uint tokenBalance1 = IERC20(token1).balanceOf(address(this));
            uint _totTokenBalance1 = tokenBalance1.add(_tm1.totalBorrow);
            ntokens1 = calculateShare(_tm1.totalLendShare, _totTokenBalance1.sub(uint(amount)), uint(amount));
            if(_tm1.totalLendShare == 0){
                _mintLPposition(0, 0, 10**3);
            }
            require(ntokens1 > 0, 'Insufficient Liquidity Minted');

            emit Lend(token1, _nftID, uint(amount), ntokens1);
        }
        
        _mintLPposition(_nftID, ntokens0, ntokens1);

        return 0;
    }
    
    
    function redeem(uint _nftID, int tok_amount, address _receiver) external onlyCore returns(int _amount) {
        accrueInterest();
        
        pM storage _positionMt = positionData[_nftID];
        
        if(tok_amount < 0){
            require(_positionMt.token0lendShare >= uint(-tok_amount), "Balance Exceeds Requested");
            
            tM storage _tm0 = token0Data;
            
            uint tokenBalance0 = IERC20(token0).balanceOf(address(this));
            uint _totTokenBalance0 = tokenBalance0.add(_tm0.totalBorrow);
            uint poolAmount = getShareValue(_totTokenBalance0, _tm0.totalLendShare, uint(-tok_amount));
            
            _amount = -int(poolAmount);

            require(tokenBalance0 >= poolAmount, "Not enough Liquidity");
            
            _burnLPposition(_nftID, uint(-tok_amount), 0);

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token0, payable(_receiver), poolAmount);

            emit Redeem(token0, _nftID, uint(-tok_amount), poolAmount);
        }
        
        if(tok_amount > 0){
            require(_positionMt.token1lendShare >= uint(tok_amount), "Balance Exceeds Requested");
            
            tM storage _tm1 = token1Data;
            
            uint tokenBalance1 = IERC20(token1).balanceOf(address(this));
            uint _totTokenBalance1 = tokenBalance1.add(_tm1.totalBorrow);
            uint poolAmount = getShareValue(_totTokenBalance1, _tm1.totalLendShare, uint(tok_amount));
            
            _amount = int(poolAmount);

            require(tokenBalance1 >= poolAmount, "Not enough Liquidity");
            
            _burnLPposition(_nftID, 0, uint(tok_amount));

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token1, payable(_receiver), poolAmount);

            emit Redeem(token1, _nftID, uint(tok_amount), poolAmount);
        }

    }
    
    
    function redeemUnderlying(uint _nftID, int _amount, address _receiver) external onlyCore returns(int rtAmount) {
        accrueInterest();
        
        pM storage _positionMt = positionData[_nftID];
        
        if(_amount < 0){
            tM storage _tm0 = token0Data;
            
            uint tokenBalance0 = IERC20(token0).balanceOf(address(this));
            uint _totTokenBalance0 = tokenBalance0.add(_tm0.totalBorrow);
            uint tok_amount0 = getShareByValue(_totTokenBalance0, _tm0.totalLendShare, uint(-_amount));
            
            require(tok_amount0 > 0, 'Insufficient Liquidity Burned');
            require(_positionMt.token0lendShare >= tok_amount0, "Balance Exceeds Requested");
            require(tokenBalance0 >= uint(-_amount), "Not enough Liquidity");
            
            _burnLPposition(_nftID, tok_amount0, 0);

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token0, payable(_receiver), uint(-_amount));
            
            rtAmount = -int(tok_amount0);

            emit Redeem(token0, _nftID, tok_amount0, uint(-_amount));
        }
        
        if(_amount > 0){
            tM storage _tm1 = token1Data;
            
            uint tokenBalance1 = IERC20(token1).balanceOf(address(this));
            uint _totTokenBalance1 = tokenBalance1.add(_tm1.totalBorrow);
            uint tok_amount1 = getShareByValue(_totTokenBalance1, _tm1.totalLendShare, uint(_amount));
            
            require(tok_amount1 > 0, 'Insufficient Liquidity Burned');
            require(_positionMt.token1lendShare >= tok_amount1, "Balance Exceeds Requested");
            require(tokenBalance1 >= uint(_amount), "Not enough Liquidity");
            
            _burnLPposition(_nftID, 0, tok_amount1);

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token1, payable(_receiver), uint(_amount));
            
            rtAmount = int(tok_amount1);

            emit Redeem(token1, _nftID, tok_amount1, uint(_amount));
        }

    }
    
    
    function borrow(uint _nftID, int amount, address payable _recipient) external onlyCore {
        accrueInterest();

        if(amount < 0){
            tM storage _tm0 = token0Data;
            
            uint ntokens0 = calculateShare(_tm0.totalBorrowShare, _tm0.totalBorrow, uint(-amount));
            if(_tm0.totalBorrowShare == 0){
                _mintBposition(0, 10**3, 0);
            }
            require(ntokens0 > 0, 'Insufficient Borrow0 Liquidity Minted');
            
            _mintBposition(_nftID, ntokens0, 0);
            
            _tm0.totalBorrow = _tm0.totalBorrow.add(uint(-amount));

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token0, payable(_recipient), uint(-amount));

            emit Borrow(token0, _nftID, uint(-amount), _tm0.totalBorrow, _recipient);
        }
        
        if(amount > 0){
            tM storage _tm1 = token1Data;
            
            uint ntokens1 = calculateShare(_tm1.totalBorrowShare, _tm1.totalBorrow, uint(amount));
            if(_tm1.totalBorrowShare == 0){
                _mintBposition(0, 0, 10**3);
            }
            require(ntokens1 > 0, 'Insufficient Borrow1 Liquidity Minted');
            
            _mintBposition(_nftID, 0, ntokens1);
            
            _tm1.totalBorrow = _tm1.totalBorrow.add(uint(amount));

            // check if _healthFactorLtv > 1
            checkHealthFactorLtv(_nftID);
            
            transferToUser(token1, payable(_recipient), uint(amount));

            emit Borrow(token1, _nftID, uint(amount), _tm1.totalBorrow, _recipient);
        }

    }
    
    
    function repay(uint _nftID, int amount, address _payer) external onlyCore returns(int _rAmount) {
        accrueInterest();

        pM storage _positionMt = positionData[_nftID];
        
        if(amount < 0){
            tM storage _tm0 = token0Data;
            
            uint _totalBorrow = _tm0.totalBorrow;
            uint _totalLiability = getShareValue( _totalBorrow, _tm0.totalBorrowShare, _positionMt.token0borrowShare ) ;
            
            if(uint(-amount) > _totalLiability){
                amount = -int(_totalLiability);
                
                _burnBposition(_nftID, _positionMt.token0borrowShare, 0);
                
                _tm0.totalBorrow = _tm0.totalBorrow.sub(_totalLiability);
            } 
            else {
                uint amountToShare = getShareByValue( _totalBorrow, _tm0.totalBorrowShare, uint(-amount) );
                
                _burnBposition(_nftID, amountToShare, 0);
                
                _tm0.totalBorrow = _tm0.totalBorrow.sub(uint(-amount));
            }
            
            _rAmount = amount;

            emit RepayBorrow(token0, _nftID, uint(-amount), _tm0.totalBorrow, _payer);
        }
        
        if(amount > 0){
            tM storage _tm1 = token1Data;
            
            uint _totalBorrow = _tm1.totalBorrow;
            uint _totalLiability = getShareValue( _totalBorrow, _tm1.totalBorrowShare, _positionMt.token1borrowShare) ;
            
            if(uint(amount) > _totalLiability){
                amount = int(_totalLiability);
                
                _burnBposition(_nftID, 0, _positionMt.token1borrowShare);
                
                _tm1.totalBorrow = _tm1.totalBorrow.sub(_totalLiability);
            } 
            else {
                uint amountToShare = getShareByValue( _totalBorrow, _tm1.totalBorrowShare, uint(amount) );
                
                _burnBposition(_nftID, 0, amountToShare);
                
                _tm1.totalBorrow = _tm1.totalBorrow.sub(uint(amount));
            }
            
            _rAmount = amount;

            emit RepayBorrow(token1, _nftID, uint(amount), _tm1.totalBorrow, _payer);
        }

    }



    function liquidateInternal(uint _nftID, int amount, uint _toNftID) internal returns(int liquidatedAmount, int totReceiveAmount)  {
        accrueInterest();

        tM storage _tm0 = token0Data;
        tM storage _tm1 = token1Data;

        if(amount < 0){
            
            (, uint _borrowBalance0) = userBalanceOftoken0(_nftID);
            (uint _lendBalance1, ) = userBalanceOftoken1(_nftID);
            
            uint _healthFactor = type(uint256).max;
            if (_borrowBalance0 > 0){
                uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token1, token0, _lendBalance1);
                _healthFactor = (collateralBalance.mul(uint(100).sub(lb)).mul(1e18).div(100)).div(_borrowBalance0);
            }
            
            if(_healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD){
                uint procAmountIN;
                uint recAmountIN;
                if(_borrowBalance0 <= uint(-amount)){
                    procAmountIN = _borrowBalance0;
                    recAmountIN = _lendBalance1;
                } 
                else {
                    procAmountIN = uint(-amount);
                    recAmountIN = (_lendBalance1.mul( procAmountIN )).div(_borrowBalance0);
                }


                uint amountToShare0 = getShareByValue( _tm0.totalBorrow, _tm0.totalBorrowShare, procAmountIN );
                _burnBposition(_nftID, amountToShare0, 0);
                _tm0.totalBorrow = _tm0.totalBorrow.sub(procAmountIN); // remove borrow amount

                
                uint _totTokenBalance1 =  IERC20(token1).balanceOf(address(this)).add(_tm1.totalBorrow);
                uint amountToShare1 = getShareByValue( _totTokenBalance1, _tm1.totalLendShare, recAmountIN );
                _burnLPposition(_nftID, 0, amountToShare1);

                if(_toNftID > 0){
                    _mintLPposition(_toNftID, 0, amountToShare1);
                }

                // tot amount to be deposit from liquidator
                liquidatedAmount = -int(procAmountIN);
                totReceiveAmount = int(recAmountIN);


                if(liquidatedAmount < 0){
                    emit LiquidateBorrow(token0, _nftID, _toNftID, uint(-liquidatedAmount), recAmountIN);
                }

            }
        }


        if(amount > 0){

            (uint _lendBalance0, ) = userBalanceOftoken0(_nftID);
            (, uint _borrowBalance1) = userBalanceOftoken1(_nftID);
            
            uint _healthFactor = type(uint256).max;
            if (_borrowBalance1 > 0){
                uint collateralBalance = IUnilendV2Core(core).getOraclePrice(token0, token1, _lendBalance0);
                _healthFactor = (collateralBalance.mul(uint(100).sub(lb)).mul(1e18).div(100)).div(_borrowBalance1);
            }
            
            if(_healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD){
                uint procAmountIN;
                uint recAmountIN;
                if(_borrowBalance1 <= uint(amount)){
                    procAmountIN = _borrowBalance1;
                    recAmountIN = _lendBalance0;
                } 
                else {
                    procAmountIN = uint(amount);
                    recAmountIN = (_lendBalance0.mul( procAmountIN )).div(_borrowBalance1);
                }


                uint amountToShare1 = getShareByValue( _tm1.totalBorrow, _tm1.totalBorrowShare, procAmountIN );
                _burnBposition(_nftID, 0, amountToShare1);
                _tm1.totalBorrow = _tm1.totalBorrow.sub(procAmountIN); // remove borrow amount

                
                uint _totTokenBalance0 =  IERC20(token0).balanceOf(address(this)).add(_tm0.totalBorrow);
                uint amountToShare0 = getShareByValue( _totTokenBalance0, _tm0.totalLendShare, recAmountIN );
                _burnLPposition(_nftID, amountToShare0, 0);

                if(_toNftID > 0){
                    _mintLPposition(_toNftID, amountToShare0, 0);
                }


                // tot liquidated amount to be deposit from liquidator
                liquidatedAmount = int(procAmountIN);
                totReceiveAmount = -int(recAmountIN);
                

                if(liquidatedAmount > 0){
                    emit LiquidateBorrow(token1, _nftID, _toNftID, uint(liquidatedAmount), recAmountIN);
                }

            }
        }
        
    }


    function liquidate(uint _nftID, int amount, address _receiver, uint _toNftID) external onlyCore returns(int liquidatedAmount)  {
        accrueInterest();
        
        int recAmountIN;
        (liquidatedAmount, recAmountIN) = liquidateInternal(_nftID, amount, _toNftID);

        if(_toNftID == 0){
            if(recAmountIN < 0){
                transferToUser(token0, payable(_receiver), uint(-recAmountIN));
            }

            if(recAmountIN > 0){
                transferToUser(token1, payable(_receiver), uint(recAmountIN));
            }
        }
        
    }


    function liquidateMulti(uint[] calldata _nftIDs, int[] calldata amounts, address _receiver, uint _toNftID) external onlyCore returns(int liquidatedAmountTotal)  {
        accrueInterest();
        
        int liquidatedAmount;
        int recAmountIN;
        int recAmountINtotal;

        for (uint i=0; i<_nftIDs.length; i++) {
        
            (liquidatedAmount, recAmountIN) = liquidateInternal(_nftIDs[i], amounts[i], _toNftID);

            liquidatedAmountTotal = liquidatedAmountTotal + liquidatedAmount;
            recAmountINtotal = recAmountINtotal + recAmountIN;
        }


        if(_toNftID == 0){
            if(recAmountINtotal < 0){
                transferToUser(token0, payable(_receiver), uint(-recAmountINtotal));
            }

            if(recAmountINtotal > 0){
                transferToUser(token1, payable(_receiver), uint(recAmountINtotal));
            }
        }

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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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