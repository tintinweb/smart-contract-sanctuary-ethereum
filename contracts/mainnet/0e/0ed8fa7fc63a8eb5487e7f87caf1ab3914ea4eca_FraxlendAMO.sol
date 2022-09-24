// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== FraxlendAMO ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Drake Evans: https://github.com/DrakeEvans
// Travis Moore: https://github.com/FortisFortuna
// Dennis: https://github.com/denett

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFraxAMOMinter.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IFraxlendPairDeployer.sol";
import "./interfaces/IFraxlendPairHelper.sol";
import "./interfaces/IFraxUnifiedFarm_ERC20.sol";

contract FraxlendAMO is Ownable {
    /* ============================================= STATE VARIABLES ==================================================== */

    // Fraxlend pairs with FRAX as asset
    address[] public pairsArray;
    mapping(address => bool) public pairsInitialized;
    mapping(address => uint256) public pairsMaxAllocation;
    mapping(address => uint256) public pairsMintedFrax;
    mapping(address => uint256) public pairsProfitTaken;

    // Fraxlend pairs with FRAX as collateral
    address[] public borrowPairsArray;
    mapping(address => bool) public borrowPairsInitialized;
    mapping(address => uint256) public borrowPairsMaxCollateral;
    mapping(address => uint256) public borrowPairsMaxLTV;
    mapping(address => uint256) public borrowPairsCollateralFrax;

    // Constants (ERC20)
    IFrax public immutable FRAX;

    // Addresses COnfig
    address public operatorAddress;
    IFraxAMOMinter public amoMinter;
    IFraxlendPairDeployer public fraxlendPairDeployer;
    IFraxlendPairHelper public fraxlendPairHelper;

    // Settings
    uint256 public constant PRICE_PRECISION = 1e6;

    /* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param amoMinterAddress_ AMO minter address
    /// @param operatorAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairDeployerAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairHelperAddress_ address of FraxlendPairHelper
    /// @param fraxAddress_ address of FraxlendPairDeployer
    constructor(
        address amoMinterAddress_,
        address operatorAddress_,
        address fraxlendPairDeployerAddress_,
        address fraxlendPairHelperAddress_,
        address fraxAddress_
    ) Ownable() {
        amoMinter = IFraxAMOMinter(amoMinterAddress_);

        operatorAddress = operatorAddress_;

        fraxlendPairDeployer = IFraxlendPairDeployer(fraxlendPairDeployerAddress_);

        fraxlendPairHelper = IFraxlendPairHelper(fraxlendPairHelperAddress_);

        FRAX = IFrax(fraxAddress_);

        emit StartAMO(amoMinterAddress_, operatorAddress_, fraxlendPairDeployerAddress_, fraxlendPairHelperAddress_);
    }

    /* ================================================ MODIFIERS ======================================================= */

    modifier onlyByOwnerOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not owner or operator");
        _;
    }

    modifier onlyByMinter() {
        require(msg.sender == address(amoMinter), "Not minter");
        _;
    }

    modifier approvedPair(address _pair) {
        require(pairsMaxAllocation[_pair] > 0, "Pair not approved for allocation");
        _;
    }

    modifier onBudget(address _pair) {
        _;
        require(
            pairsMaxAllocation[_pair] >= pairsMintedFrax[_pair],
            "Over allocation budget"
        );
    }

    modifier approvedBorrowPair(address _pair) {
        require(borrowPairsMaxCollateral[_pair] > 0, "Pair not approved for borrow");
        _;
    }

    modifier borrowOnBudget(address _pair) {
        _;
        require(
            borrowPairsMaxCollateral[_pair] >= borrowPairsCollateralFrax[_pair],
            "Over collateral budget"
        );
    }

    modifier borrowOnLTV(address _pair) {
        _;
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pair);
        uint256 _exchangeRate = fraxlendPairHelper.previewUpdateExchangeRate(_pair);
        (uint256 _LTV_PRECISION, , , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
        uint256 _borrowShare = _fraxlendPair.userBorrowShares(address(this));
        (uint256 _borrowAmount, , ) = fraxlendPairHelper.toBorrowAmount(_pair, _borrowShare, block.timestamp, block.number, false);
        uint256 _collateralAmount = _fraxlendPair.userCollateralBalance(address(this));
        require(_EXCHANGE_PRECISION > 0, "EXCHANGE_PRECISION is zero.");
        require(_collateralAmount > 0, "Collateral amount is zero.");
        uint256 _ltv = (((_borrowAmount * _exchangeRate) / _EXCHANGE_PRECISION) * _LTV_PRECISION) / _collateralAmount;
        require(_ltv <= borrowPairsMaxLTV[_pair], "Max LTV limit for borrowing");
    }

    /* ================================================== EVENTS ======================================================== */

    /// @notice The ```StartAMO``` event fires when the AMO deploy
    /// @param amoMinterAddress_ AMO minter address
    /// @param operatorAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairDeployerAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairHelperAddress_ address of FraxlendPairHelper
    event StartAMO(address amoMinterAddress_, address operatorAddress_, address fraxlendPairDeployerAddress_, address fraxlendPairHelperAddress_); 

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOMinter``` event fires when the AMO Minter is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOMinter(address _oldAddress, address _newAddress);

    /// @notice The ```SetFraxlendPairHelper``` event fires when the FraxlendPairHelper is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetFraxlendPairHelper(address _oldAddress, address _newAddress);

    /// @notice The ```SetFraxlendPairDeployer``` event fires when the FraxlendPairDeployer is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetFraxlendPairDeployer(address _oldAddress, address _newAddress);

    /// @notice The ```SetPair``` event fires when a pair is added to AMO
    /// @param _pairAddress The pair address
    /// @param _maxAllocation Max allowed allocation of AMO into the pair 
    event SetPair(address _pairAddress, uint256 _maxAllocation);

    /// @notice The ```SetBorrowPair``` event fires when a pair is added to AMO for borrowing
    /// @param _pairAddress The pair address
    /// @param _maxCollateralAllocation Max allowed collateral allocation of AMO into the pair 
    /// @param _maxLTV Max allowed LTV for AMO for borrow position 
    event SetBorrowPair(address _pairAddress, uint256 _maxCollateralAllocation, uint256 _maxLTV);

    /// @notice The ```DepositToPair``` event fires when a deposit happen to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Deposited FRAX amount
    /// @param _shares Deposited shares
    event DepositToPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```WithdrawFromPair``` event fires when a withdrawal happen from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Withdrawn FRAX amount
    /// @param _shares Withdrawn shares
    event WithdrawFromPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```AddCollateral``` event fires when collateral add to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Collateral FRAX amount
    event AddCollateral(address _pairAddress, uint256 _amount);

    /// @notice The ```RemoveCollateral``` event fires when collateral remove from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Collateral FRAX amount
    event RemoveCollateral(address _pairAddress, uint256 _amount);

    /// @notice The ```BorrowFromPair``` event fires when a borrow happen from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Borrowed asset amount
    /// @param _shares Borrowed asset shares
    event BorrowFromPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```RepayToPair``` event fires when a repay happen to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Repay borrowed asset amount
    /// @param _shares Repay borrowed asset shares
    event RepayToPair(address _pairAddress, uint256 _amount, uint256 _shares);


    /* =================================================== VIEWS ======================================================== */
    
    /// @notice Show allocations of FraxlendAMO in FRAX
    /// @return _allocations : [Unallocated FRAX, Lent FRAX, Used as Collateral FRAX, Total FRAX]
    function showAllocations() public view returns (uint256[4] memory _allocations) {
        // Note: All numbers given are in FRAX unless otherwise indicated
        
        // Unallocated FRAX
        _allocations[0] = FRAX.balanceOf(address(this));
        
        // Allocated FRAX (FRAX in Fraxlend Pairs)
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            IFraxlendPair _fraxlendPair = IFraxlendPair(_pairsArray[i]);
            uint256 _shares = _fraxlendPair.balanceOf(address(this));
            (uint256 _amount, , ) = fraxlendPairHelper.toAssetAmount(_pairsArray[i], _shares, block.timestamp, block.number, false);

            _allocations[1] += _amount;
        }


        // FRAX used as collateral in Fraxlend Pairs
        address[] memory _borrowPairsArray = borrowPairsArray;
        for (uint256 i = 0; i < _borrowPairsArray.length; i++) {
            IFraxlendPair _fraxlendPair = IFraxlendPair(_borrowPairsArray[i]);
            uint256 _amount = _fraxlendPair.userCollateralBalance(address(this));
            _allocations[2] += _amount;
        }
        // Total FRAX possessed in various forms
        uint256 sumFrax = _allocations[0] + _allocations[1] + _allocations[2];
        _allocations[3] = sumFrax;
    }

    /// @notice Show allocations of FraxlendAMO into Fraxlend pair in FRAX
    /// @param _pairAddress Address of FraxlendPair
    /// @return _allocations :[Minted FRAX into the pair, Current AMO owned FRAX in pair, AMO FRAX Profit Taken from pair, CR of FRAX in pair, CR Precision]
    function showPairAccounting(address _pairAddress) public view returns (uint256[5] memory _allocations) {
        // All numbers given are in FRAX unless otherwise indicated
        _allocations[0] = pairsMintedFrax[_pairAddress];
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        uint256 _shares = _fraxlendPair.balanceOf(address(this));
        (uint256 _assetAmount,, ) = fraxlendPairHelper.toAssetAmount(_pairAddress, _shares, block.timestamp, block.number, false);
        _allocations[1] = _assetAmount;
        _allocations[2] = pairsProfitTaken[_pairAddress];
         
        // Calculate Pair CR (CR related items are not in FRAX)
        (uint128 _totalAssetAmount, , uint128 _totalBorrowAmount, , uint256 _totalCollateral) = fraxlendPairHelper.getPairAccounting(_pairAddress);
        uint256 _exchangeRate = fraxlendPairHelper.previewUpdateExchangeRate(_pairAddress);
        (uint256 _LTV_PRECISION, , , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
        if (_totalCollateral > 0 && _totalAssetAmount > 0 && _totalBorrowAmount > 0) {
            uint256 _borrowedLTV = (((_totalBorrowAmount * _exchangeRate) / _EXCHANGE_PRECISION) * _LTV_PRECISION) / _totalCollateral;
            _allocations[3] = ((((_totalBorrowAmount * _LTV_PRECISION) / _borrowedLTV)) * _LTV_PRECISION) / _totalAssetAmount;
        } else {
            _allocations[3] = 0; 
        }
        _allocations[4] = _LTV_PRECISION;
    }

    /// @notice Show borrow pairs accounting in FRAX
    /// @param _pairAddress Address of borrow FraxlendPair
    /// @return _allocations :[ Minted FRAX into the pair, Current AMO owned FRAX in pair, Current AMO owned Asset, Current AMO borrowed amount pair ]
    function showBorrowPairAccounting(address _pairAddress) public view returns (uint256[4] memory _allocations) {
        // All numbers given are in FRAX unless otherwise stated
        _allocations[0] = borrowPairsCollateralFrax[_pairAddress];
        IFraxlendPair fraxlendPair = IFraxlendPair(_pairAddress);
        _allocations[1] = fraxlendPair.userCollateralBalance(address(this));
        IERC20 _asset = IERC20(fraxlendPair.asset());
        // Asset related items are not in FRAX
        uint256 _totalAssetBalance = _asset.balanceOf(address(this));
        _allocations[2] = _totalAssetBalance;
        uint256 borrowShare = fraxlendPair.userBorrowShares(address(this));
        ( uint256 _borrowAmount ,,) = fraxlendPairHelper.toBorrowAmount(_pairAddress, borrowShare, block.timestamp, block.number, false);
        _allocations[3] = _borrowAmount;
    }

    /// @notice total FRAX balance
    /// @return fraxValE18 FRAX value
    /// @return collatValE18 FRAX collateral value
    function dollarBalances() public view returns (uint256 fraxValE18, uint256 collatValE18) {
        fraxValE18 = showAllocations()[3];
        collatValE18 = (fraxValE18 * FRAX.global_collateral_ratio()) / (PRICE_PRECISION);
    }

    /// @notice Backwards compatibility
    /// @return FRAX minted balance of the FraxlendAMO
    function mintedBalance() public view returns (int256) {
        return amoMinter.frax_mint_balances(address(this));
    }

/* =============================================== PAIR FUNCTIONS =================================================== */
    
    /// @notice accrue Interest of a FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    function accrueInterestFraxlendPair(address _pairAddress) public onlyByOwnerOperator {
        IFraxlendPair(_pairAddress).addInterest();
    }

    /// @notice  accrue Interest of all whitelisted FraxlendPairs
    function accrueInterestAllFraxlendPair() external onlyByOwnerOperator {
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            if (pairsInitialized[_pairsArray[i]]) {
                accrueInterestFraxlendPair(_pairsArray[i]);
            }
        }
        address[] memory _borrowPairsArray = borrowPairsArray;
        for (uint256 i = 0; i < _borrowPairsArray.length; i++) {
            if (pairsInitialized[_borrowPairsArray[i]]) {
                accrueInterestFraxlendPair(_borrowPairsArray[i]);
            }
        }
    }

    /// @notice Add new FraxlendPair with FRAX as asset address to list
    /// @param _pairAddress Address of FraxlendPair
    /// @param _maxAllocation Max Allocation amount for FraxlendPair
    function setPair(
        address _pairAddress,
        uint256 _maxAllocation
    ) public onlyOwner {
        require(address(IFraxlendPair(_pairAddress).asset()) == address(FRAX), "Pair asset is not FRAX");
        pairsMaxAllocation[_pairAddress] = _maxAllocation;
        
        if (pairsInitialized[_pairAddress] == false) {
            pairsInitialized[_pairAddress] = true;
            pairsArray.push(_pairAddress);
        }
        emit SetPair(_pairAddress, _maxAllocation);
    }

    /// @notice Add new FraxlendPair with FRAX as collateral address to list
    /// @param _pairAddress Address of FraxlendPair
    /// @param _maxCollateral Max Collateral amount for borrowing from FraxlendPair
    /// @param _maxLTV Max LTV for borrowing from FraxlendPair 
    function setBorrowPair(
        address _pairAddress,
        uint256 _maxCollateral,
        uint256 _maxLTV
    ) public onlyOwner {
        require(address(IFraxlendPair(_pairAddress).collateralContract()) == address(FRAX), "Pair collateral is not FRAX");
        borrowPairsMaxCollateral[_pairAddress] = _maxCollateral;
        borrowPairsMaxLTV[_pairAddress] = _maxLTV;
        if (borrowPairsInitialized[_pairAddress] == false) {
            borrowPairsInitialized[_pairAddress] = true;
            borrowPairsArray.push(_pairAddress);
        }
        emit SetBorrowPair(_pairAddress, _maxCollateral, _maxLTV);
    }

/* ============================================= LENDING FUNCTIONS ================================================== */

    /// @notice Function to deposit FRAX to specific FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited
    function depositToPair(address _pairAddress, uint256 _fraxAmount)
        public
        approvedPair(_pairAddress)
        onBudget(_pairAddress)
        onlyByOwnerOperator
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        FRAX.approve(_pairAddress, _fraxAmount);
        uint256 _shares = _fraxlendPair.deposit(_fraxAmount, address(this));
        pairsMintedFrax[_pairAddress] += _fraxAmount;

        emit DepositToPair(_pairAddress, _fraxAmount, _shares);
    }

    /// @notice Function to withdraw FRAX from specific FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _shares shares to be withdrawed
    function withdrawFromPair(address _pairAddress, uint256 _shares) public onlyByOwnerOperator returns (uint256 _amountWithdrawn) {      
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        
        // Calculate current amount balance
        uint256 _currentBalanceShares = _fraxlendPair.balanceOf(address(this));
        (uint256 _currentBalanceAmount,,) = fraxlendPairHelper.toAssetAmount(_pairAddress, _currentBalanceShares, block.timestamp, block.number, false);
        
        // Withdraw amount
        _amountWithdrawn = _fraxlendPair.redeem(_shares, address(this), address(this));

        // Effects
        if (pairsMintedFrax[_pairAddress] < _currentBalanceAmount) {
            uint256 _profit = _currentBalanceAmount - pairsMintedFrax[_pairAddress];
            if (_profit > _amountWithdrawn) {
                pairsProfitTaken[_pairAddress] = pairsProfitTaken[_pairAddress] + _amountWithdrawn;
            } else {
                pairsProfitTaken[_pairAddress] = pairsProfitTaken[_pairAddress] + _profit;
                pairsMintedFrax[_pairAddress] = pairsMintedFrax[_pairAddress] - (_amountWithdrawn - _profit);
            }
        } else {
            pairsMintedFrax[_pairAddress] = pairsMintedFrax[_pairAddress] - _amountWithdrawn;
        }
        emit WithdrawFromPair(_pairAddress, _amountWithdrawn, _shares);
    }

    /// @notice Function to withdraw FRAX from all FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    function withdrawMaxFromPair(address _pairAddress) public onlyByOwnerOperator returns (uint256 _amountWithdrawn) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        uint256 _shares = _fraxlendPair.balanceOf(address(this));
        if (_shares == 0) {
            return 0;
        }
        _fraxlendPair.addInterest();
        (uint128 _totalAssetAmount, ) = _fraxlendPair.totalAsset();
        (uint128 _totalBorrowAmount, ) = _fraxlendPair.totalBorrow();  
        uint256 _availableAmount = _totalAssetAmount - _totalBorrowAmount;
        uint256 _availableShares = _fraxlendPair.toAssetShares(_availableAmount,false);
        if (_shares <= _availableShares) {
            _amountWithdrawn = withdrawFromPair(_pairAddress, _shares);
        } else {
            _amountWithdrawn = withdrawFromPair(_pairAddress, _availableShares);
        }
    }
    
    /// @notice Function to withdraw FRAX from all FraxlendPair
    function withdrawMaxFromAllPairs() public onlyByOwnerOperator {
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            withdrawMaxFromPair(_pairsArray[i]);
        }
    }

    /* ============================================ BORROWING FUNCTIONS ================================================= */

    /// @notice Function to deposit FRAX to specific FraxlendPair as collateral and borrow another token
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited as collateral
    /// @param _borrowAmount Amount of asset to be borrowed
    function openBorrowPosition(
        address _pairAddress,
        uint256 _fraxAmount,
        uint256 _borrowAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) borrowOnLTV(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair fraxlendPair = IFraxlendPair(_pairAddress);
        require(FRAX.balanceOf(address(this)) >= _fraxAmount, "AMO funds too low");
    
        FRAX.approve(_pairAddress, _fraxAmount);
        uint256 _shares = fraxlendPair.borrowAsset(_borrowAmount, _fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] += _fraxAmount;

        emit AddCollateral(_pairAddress, _fraxAmount);
        emit BorrowFromPair(_pairAddress, _borrowAmount, _shares);
    }

    /// @notice Function to deposit FRAX to specific FraxlendPair as collateral
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited as collateral
    function addCollateralToPair(
        address _pairAddress,
        uint256 _fraxAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        require(FRAX.balanceOf(address(this)) >= _fraxAmount, "AMO funds too low");
        emit AddCollateral(_pairAddress, _fraxAmount);

        FRAX.approve(_pairAddress, _fraxAmount);
        _fraxlendPair.addCollateral(_fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] += _fraxAmount;
    }

    /// @notice Function to remove FRAX from specific FraxlendPair collateral
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be removed from collateral
    function removeCollateralFromPair(
        address _pairAddress,
        uint256 _fraxAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) borrowOnLTV(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        require(borrowPairsCollateralFrax[_pairAddress] >= _fraxAmount, "AMO collateral too low");
        emit RemoveCollateral(_pairAddress, _fraxAmount);

        _fraxlendPair.removeCollateral(_fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] -= _fraxAmount;
    }
    
    /// @notice Function to repay loan on FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _shares The number of Borrow Shares which will be repaid by the call
    function repayBorrowPosition(
        address _pairAddress,
        uint256 _shares
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        IERC20 _asset = IERC20(_fraxlendPair.asset());
        _fraxlendPair.addInterest();
        uint256 _amount = _fraxlendPair.toBorrowAmount(_shares, true);
        _asset.approve(_pairAddress, _amount);
        uint256 _finalAmount = _fraxlendPair.repayAsset(_shares, address(this));

        emit RepayToPair(_pairAddress, _finalAmount, _shares);
    }
    
    /// @notice Function to repay loan on FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _swapperAddress The address of the whitelisted swapper to use for token swaps
    /// @param _collateralToSwap The amount of Collateral Tokens to swap for Asset Tokens
    /// @param _amountAssetOutMin The minimum amount of Asset Tokens to receive during the swap
    /// @param _path An array containing the addresses of ERC20 tokens to swap.  Adheres to UniV2 style path params.
    function repayBorrowPositionWithCollateral(
        address _pairAddress,
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] calldata _path
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator returns (uint256 _amountAssetOut){
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        _amountAssetOut = _fraxlendPair.repayAssetWithCollateral(_swapperAddress, _collateralToSwap, _amountAssetOutMin, _path);
        uint256 _sharesOut = _fraxlendPair.toBorrowShares(_amountAssetOut, false);
        emit RepayToPair(_pairAddress, _amountAssetOut, _sharesOut);
    }

    /* ============================================ BURNS AND GIVEBACKS ================================================= */

    /// @notice Burn unneeded or excess FRAX. Goes through the minter
    /// @param _fraxAmount Amount of FRAX to burn
    function burnFRAX(uint256 _fraxAmount) public onlyOwner {
        FRAX.approve(address(amoMinter), _fraxAmount);
        amoMinter.burnFraxFromAMO(_fraxAmount);
    }

    /// @notice recoverERC20 recovering ERC20 tokens 
    /// @param _tokenAddress address of ERC20 token
    /// @param _tokenAmount amount to be withdrawn
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        SafeERC20.safeTransfer(token, msg.sender, _tokenAmount);
    }

    /* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Change the FRAX Minter
    /// @param _newAmoMinterAddress FRAX AMO minter
    function setAMOMinter(address _newAmoMinterAddress) external onlyOwner {
        emit SetAMOMinter(address(amoMinter), _newAmoMinterAddress);
        amoMinter = IFraxAMOMinter(_newAmoMinterAddress);
    }

    /// @notice Change the FraxlendPairHelper
    /// @param _newFraxlendPairHelperAddress FraxlendPairHelper Address
    function setFraxlendPairHelper(address _newFraxlendPairHelperAddress) external onlyOwner {
        emit SetFraxlendPairHelper(address(fraxlendPairHelper), _newFraxlendPairHelperAddress);
        fraxlendPairHelper = IFraxlendPairHelper(_newFraxlendPairHelperAddress);

    }

    /// @notice Change the FraxlendDeployer
    /// @param _newFraxlendPairDeployerAddress FRAX AMO minter
    function setFraxlendPairDeployer(address _newFraxlendPairDeployerAddress) external onlyOwner {
        emit SetFraxlendPairDeployer(address(fraxlendPairDeployer), _newFraxlendPairDeployerAddress);
        fraxlendPairDeployer = IFraxlendPairDeployer(_newFraxlendPairDeployerAddress);
    }


    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);
        operatorAddress = _newOperatorAddress;
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);
        return (success, result);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// MAY need to be updated
interface IFraxAMOMinter {
  function FRAX() external view returns(address);
  function FXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnFraxFromAMO(uint256 frax_amount) external;
  function burnFxsFromAMO(uint256 fxs_amount) external;
  function col_idx() external view returns(uint256);
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 frax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function fraxDollarBalanceStored() external view returns(uint256);
  function fraxTrackedAMO(address amo_address) external view returns(int256);
  function fraxTrackedGlobal() external view returns(int256);
  function frax_mint_balances(address) external view returns(int256);
  function frax_mint_cap() external view returns(int256);
  function frax_mint_sum() external view returns(int256);
  function fxs_mint_balances(address) external view returns(int256);
  function fxs_mint_cap() external view returns(int256);
  function fxs_mint_sum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function min_cr() external view returns(uint256);
  function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
  function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 frax_amount) external;
  function old_pool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setFraxMintCap(uint256 _frax_mint_cap) external;
  function setFraxPool(address _pool_address) external;
  function setFxsMintCap(uint256 _fxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IFraxlendPair {
  function CIRCUIT_BREAKER_ADDRESS (  ) external view returns ( address );
  function COMPTROLLER_ADDRESS (  ) external view returns ( address );
  function DEPLOYER_ADDRESS (  ) external view returns ( address );
  function FRAXLEND_WHITELIST_ADDRESS (  ) external view returns ( address );
  function TIME_LOCK_ADDRESS (  ) external view returns ( address );
  function addCollateral ( uint256 _collateralAmount, address _borrower ) external;
  function addInterest (  ) external returns ( uint256 _interestEarned, uint256 _feesAmount, uint256 _feesShare, uint64 _newRate );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function approvedBorrowers ( address ) external view returns ( bool );
  function approvedLenders ( address ) external view returns ( bool );
  function asset (  ) external view returns ( address );
  function balanceOf ( address account ) external view returns ( uint256 );
  function borrowAsset ( uint256 _borrowAmount, uint256 _collateralAmount, address _receiver ) external returns ( uint256 _shares );
  function borrowerWhitelistActive (  ) external view returns ( bool );
  function changeFee ( uint32 _newFee ) external;
  function cleanLiquidationFee (  ) external view returns ( uint256 );
  function collateralContract (  ) external view returns ( address );
  function currentRateInfo (  ) external view returns ( uint64 lastBlock, uint64 feeToProtocolRate, uint64 lastTimestamp, uint64 ratePerSec );
  function decimals (  ) external pure returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function deposit ( uint256 _amount, address _receiver ) external returns ( uint256 _sharesReceived );
  function dirtyLiquidationFee (  ) external view returns ( uint256 );
  function exchangeRateInfo (  ) external view returns ( uint32 lastTimestamp, uint224 exchangeRate );
  function getConstants (  ) external pure returns ( uint256 _LTV_PRECISION, uint256 _LIQ_PRECISION, uint256 _UTIL_PREC, uint256 _FEE_PRECISION, uint256 _EXCHANGE_PRECISION, uint64 _DEFAULT_INT, uint16 _DEFAULT_PROTOCOL_FEE, uint256 _MAX_PROTOCOL_FEE );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function initialize ( string calldata _name, address[] calldata _approvedBorrowers, address[] calldata _approvedLenders, bytes calldata _rateInitCallData ) external;
  function lenderWhitelistActive (  ) external view returns ( bool );
  function leveragedPosition ( address _swapperAddress, uint256 _borrowAmount, uint256 _initialCollateralAmount, uint256 _amountCollateralOutMin, address[] memory _path ) external returns ( uint256 _totalCollateralBalance );
  function liquidate ( uint128 _sharesToLiquidate, uint256 _deadline, address _borrower ) external returns ( uint256 _collateralForLiquidator );
  function maturityDate (  ) external view returns ( uint256 );
  function maxLTV (  ) external view returns ( uint256 );
  function name (  ) external view returns ( string memory);
  function oracleDivide (  ) external view returns ( address );
  function oracleMultiply (  ) external view returns ( address );
  function oracleNormalization (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function penaltyRate (  ) external view returns ( uint256 );
  function rateContract (  ) external view returns ( address );
  function rateInitCallData (  ) external view returns ( bytes memory );
  function redeem ( uint256 _shares, address _receiver, address _owner ) external returns ( uint256 _amountToReturn );
  function removeCollateral ( uint256 _collateralAmount, address _receiver ) external;
  function renounceOwnership (  ) external;
  function repayAsset ( uint256 _shares, address _borrower ) external returns ( uint256 _amountToRepay );
  function repayAssetWithCollateral ( address _swapperAddress, uint256 _collateralToSwap, uint256 _amountAssetOutMin, address[] calldata _path ) external returns ( uint256 _amountAssetOut );
  function setApprovedBorrowers ( address[] calldata _borrowers, bool _approval ) external;
  function setApprovedLenders ( address[] calldata _lenders, bool _approval ) external;
  function setSwapper ( address _swapper, bool _approval ) external;
  function setTimeLock ( address _newAddress ) external;
  function swappers ( address ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function toBorrowAmount ( uint256 _shares, bool _roundUp ) external view returns ( uint256 );
  function toBorrowShares ( uint256 _amount, bool _roundUp ) external view returns ( uint256 );
  function toAssetAmount ( uint256 _shares, bool _roundUp ) external view returns ( uint256 );
  function toAssetShares ( uint256 _amount, bool _roundUp ) external view returns ( uint256 );
  function totalAsset (  ) external view returns ( uint128 amount, uint128 shares );
  function totalBorrow (  ) external view returns ( uint128 amount, uint128 shares );
  function totalCollateral (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function unpause (  ) external;
  function updateExchangeRate (  ) external returns ( uint256 _exchangeRate );
  function userBorrowShares ( address ) external view returns ( uint256 );
  function userCollateralBalance ( address ) external view returns ( uint256 );
  function version (  ) external view returns ( string memory );
  function withdrawFees ( uint128 _shares, address _recipient ) external returns ( uint256 _amountToTransfer );
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IFraxlendPairDeployer {
  function CIRCUIT_BREAKER_ADDRESS (  ) external view returns ( address );
  function COMPTROLLER_ADDRESS (  ) external view returns ( address );
  function DEFAULT_LIQ_FEE (  ) external view returns ( uint256 );
  function DEFAULT_MAX_LTV (  ) external view returns ( uint256 );
  function GLOBAL_MAX_LTV (  ) external view returns ( uint256 );
  function TIME_LOCK_ADDRESS (  ) external view returns ( address );
  function deploy ( bytes memory _configData ) external returns ( address _pairAddress );
  function deployCustom ( string memory _name, bytes memory _configData, uint256 _maxLTV, uint256 _liquidationFee, uint256 _maturityDate, uint256 _penaltyRate, address[] memory _approvedBorrowers, address[] memory _approvedLenders ) external returns ( address _pairAddress );
  function deployedPairCustomStatusByAddress ( address ) external view returns ( bool );
  function deployedPairsArray ( uint256 ) external view returns ( string memory );
  function deployedPairsByName ( string memory ) external view returns ( address );
  function deployedPairsBySalt ( bytes32 ) external view returns ( address );
  function deployedPairsLength (  ) external view returns ( uint256 );
  function getAllPairAddresses (  ) external view returns ( address[] memory );
  function getCustomStatuses ( address[] calldata _addresses ) external view returns ( address[] memory _pairCustomStatuses );
  function globalPause ( address[] memory _addresses ) external returns ( address[] memory _updatedAddresses );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setCreationCode ( bytes calldata _creationCode ) external;
  function transferOwnership ( address newOwner ) external;
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.6.11;

interface IFraxlendPairHelper {
    struct ImmutablesAddressBool {
        bool _borrowerWhitelistActive;
        bool _lenderWhitelistActive;
        address _assetContract;
        address _collateralContract;
        address _oracleMultiply;
        address _oracleDivide;
        address _rateContract;
        address _DEPLOYER_CONTRACT;
        address _COMPTROLLER_ADDRESS;
        address _FRAXLEND_WHITELIST;
    }

    struct ImmutablesUint256 {
        uint256 _oracleNormalization;
        uint256 _maxLTV;
        uint256 _liquidationFee;
        uint256 _maturityDate;
        uint256 _penaltyRate;
    }

    function getImmutableAddressBool(address _fraxlendPairAddress) external view returns (ImmutablesAddressBool memory);

    function getImmutableUint256(address _fraxlendPairAddress) external view returns (ImmutablesUint256 memory);

    function getPairAccounting(address _fraxlendPairAddress)
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        );

    function getUserSnapshot(address _fraxlendPairAddress, address _address)
        external
        view
        returns (
            uint256 _userAssetShares,
            uint256 _userBorrowShares,
            uint256 _userCollateralBalance
        );

    function previewLiquidatePure(
        address _fraxlendPairAddress,
        uint128 _sharesToLiquidate,
        address _borrower
    )
        external
        view
        returns (
            uint128 _amountLiquidatorToRepay,
            uint256 _collateralForLiquidator,
            uint128 _sharesToSocialize,
            uint128 _amountToSocialize
        );

    function previewRateInterest(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    ) external view returns (uint256 _interestEarned, uint256 _newRate);

    function previewRateInterestFees(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    )
        external
        view
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            uint256 _newRate
        );

    function previewTotalAsset(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    ) external view returns (uint128 _amount, uint128 _shares);

    function previewTotalBorrow(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    ) external view returns (uint128 _amount, uint128 _shares);

    function previewUpdateExchangeRate(address _fraxlendPairAddress) external view returns (uint256 _exchangeRate);

    function toAssetAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    )
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalAmount,
            uint256 _totalShares
        );

    function toAssetShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    )
        external
        view
        returns (
            uint256 _shares,
            uint256 _totalAmount,
            uint256 _totalShares
        );

    function toBorrowAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    )
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalAmount,
            uint256 _totalShares
        );

    function toBorrowShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    )
        external
        view
        returns (
            uint256 _shares,
            uint256 _totalAmount,
            uint256 _totalShares
        );

    function version() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IFraxUnifiedFarm_ERC20 {
  function acceptOwnership (  ) external;
  function calcCurCombinedWeight ( address account ) external view returns ( uint256 old_combined_weight, uint256 new_vefxs_multiplier, uint256 new_combined_weight );
  function calcCurrLockMultiplier ( address account, uint256 stake_idx ) external view returns ( uint256 midpoint_lock_multiplier );
  function changeTokenManager ( address reward_token_address, address new_manager_address ) external;
  function combinedWeightOf ( address account ) external view returns ( uint256 );
  function curvePool (  ) external view returns ( address );
  function earned ( address account ) external view returns ( uint256[] memory new_earned );
  function fraxPerLPStored (  ) external view returns ( uint256 );
  function fraxPerLPToken (  ) external view returns ( uint256 );
  function getAllRewardTokens (  ) external view returns ( address[] memory );
  function getProxyFor ( address addr ) external view returns ( address );
  function getReward ( address destination_address ) external returns ( uint256[] memory );
  function getReward2 ( address destination_address, bool claim_extra_too ) external returns ( uint256[] memory );
  function getRewardExtraLogic ( address destination_address ) external;
  function getRewardForDuration (  ) external view returns ( uint256[] memory rewards_per_duration_arr );
  function isTokenManagerFor ( address caller_addr, address reward_token_addr ) external view returns ( bool );
  function lastRewardClaimTime ( address ) external view returns ( uint256 );
  function lastUpdateTime (  ) external view returns ( uint256 );
  function lockAdditional ( bytes32 kek_id, uint256 addl_liq ) external;
  function lockLonger ( bytes32 kek_id, uint256 new_ending_ts ) external;
  function lockMultiplier ( uint256 secs ) external view returns ( uint256 );
  function lock_max_multiplier (  ) external view returns ( uint256 );
  function lock_time_for_max_multiplier (  ) external view returns ( uint256 );
  function lock_time_min (  ) external view returns ( uint256 );
  function lockedLiquidityOf ( address account ) external view returns ( uint256 );
  function lockedStakes ( address, uint256 ) external view returns ( bytes32 kek_id, uint256 start_timestamp, uint256 liquidity, uint256 ending_timestamp, uint256 lock_multiplier );
  function lockedStakesOf ( address account ) external view returns ( bytes[] memory);
  function lockedStakesOfLength ( address account ) external view returns ( uint256 );
  function maxLPForMaxBoost ( address account ) external view returns ( uint256 );
  function minVeFXSForMaxBoost ( address account ) external view returns ( uint256 );
  function minVeFXSForMaxBoostProxy ( address proxy_address ) external view returns ( uint256 );
  function nominateNewOwner ( address _owner ) external;
  function nominatedOwner (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function periodFinish (  ) external view returns ( uint256 );
  function proxyStakedFrax ( address proxy_address ) external view returns ( uint256 );
  function proxyToggleStaker ( address staker_address ) external;
  function proxy_lp_balances ( address ) external view returns ( uint256 );
  function recoverERC20 ( address tokenAddress, uint256 tokenAmount ) external;
  function rewardManagers ( address ) external view returns ( address );
  function rewardRates ( uint256 token_idx ) external view returns ( uint256 rwd_rate );
  function rewardTokenAddrToIdx ( address ) external view returns ( uint256 );
  function rewardsDuration (  ) external view returns ( uint256 );
  function rewardsPerToken (  ) external view returns ( uint256[] memory newRewardsPerTokenStored );
  function setMiscVariables ( uint256[6] memory _misc_vars ) external;
  function setPauses ( bool _stakingPaused, bool _withdrawalsPaused, bool _rewardsCollectionPaused ) external;
  function setRewardVars ( address reward_token_address, uint256 _new_rate, address _gauge_controller_address, address _rewards_distributor_address ) external;
  function stakeLocked ( uint256 liquidity, uint256 secs ) external returns ( bytes32 );
  function stakerSetVeFXSProxy ( address proxy_address ) external;
  function staker_designated_proxies ( address ) external view returns ( address );
  function stakesUnlocked (  ) external view returns ( bool );
  function stakingToken (  ) external view returns ( address );
  function sync (  ) external;
  function sync_gauge_weights ( bool force_update ) external;
  function toggleValidVeFXSProxy ( address _proxy_addr ) external;
  function totalCombinedWeight (  ) external view returns ( uint256 );
  function totalLiquidityLocked (  ) external view returns ( uint256 );
  function unlockStakes (  ) external;
  function updateRewardAndBalance ( address account, bool sync_too ) external;
  function userStakedFrax ( address account ) external view returns ( uint256 );
  function veFXSMultiplier ( address account ) external view returns ( uint256 vefxs_multiplier );
  function vefxs_boost_scale_factor (  ) external view returns ( uint256 );
  function vefxs_max_multiplier (  ) external view returns ( uint256 );
  function vefxs_per_frax_for_max_boost (  ) external view returns ( uint256 );
  function withdrawLocked ( bytes32 kek_id, address destination_address ) external returns ( uint256 );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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