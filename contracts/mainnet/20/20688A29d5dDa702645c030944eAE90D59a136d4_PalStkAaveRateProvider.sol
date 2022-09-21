//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                               

pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT

interface IRateProvider {
    function getRate() external view returns (uint256);
}

// PalPool Minimal Interface
interface IPalPool {

    function palToken() external view returns(address);

    function exchangeRateStored() external view returns(uint256);
    function exchangeRateCurrent() external returns(uint256);

    function borrowRatePerBlock() external view returns(uint256);

    function underlyingBalance() external view returns(uint256);

    function accrualBlockNumber() external view returns(uint256);

    function totalBorrowed() external view returns(uint256);
    function totalReserve() external view returns(uint256);

    function reserveFactor() external view returns(uint256);

}

interface IPalToken {

    function totalSupply() external view returns(uint256);

}

// Paladin Controller Minimal Interface
interface IPaladinController {
    
    function palTokenToPalPool(address palToken) external view returns(address);
}

/** @title RateProvider for palStkAave (used in Balancer's Metastable Pools) */
/// @author Paladin
contract PalStkAaveRateProvider is IRateProvider {

    /** @dev 1e18 mantissa used for calculations */
    uint256 internal constant MANTISSA_SCALE = 1e18;

    uint internal constant poolInitialExchangeRate = 1e18;

    IPalPool public immutable palStkAavePool;

    constructor(IPalPool _palStkAavePool) {
        palStkAavePool = _palStkAavePool;
    }

    /**
     * @return the value of palStkAAVE in terms of stkAAVE (where 1 stkAAVE redeems 1 AAVE in the Aave Safety Module)
     */
    function getRate() external view override returns (uint256) {
        uint256 _lastAccrualBlock = palStkAavePool.accrualBlockNumber();
        if(_lastAccrualBlock == block.number) return palStkAavePool.exchangeRateStored();

        uint256 _totalSupply = IPalToken(palStkAavePool.palToken()).totalSupply();

        uint256 _oldCash = palStkAavePool.underlyingBalance();
        uint256 _oldBorrowed = palStkAavePool.totalBorrowed();
        uint256 _oldReserve = palStkAavePool.totalReserve();

        uint256 _reserveFactor = palStkAavePool.reserveFactor();

        uint256 _borrowRate = palStkAavePool.borrowRatePerBlock();

        uint256 _accumulatedInterests = ((_borrowRate * (block.number - _lastAccrualBlock)) * _oldBorrowed) / MANTISSA_SCALE;

        uint256 _newBorrowed = _oldBorrowed + _accumulatedInterests;
        uint256 _newReserve = _oldReserve + ((_accumulatedInterests * _reserveFactor) / MANTISSA_SCALE);

        return _totalSupply == 0
            ? poolInitialExchangeRate
            : ((_oldCash + _newBorrowed + _newReserve) * MANTISSA_SCALE) / _totalSupply;

    }

}