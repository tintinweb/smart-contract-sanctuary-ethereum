// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./interface/IInterestRateModel.sol";
import "./interface/IXToken.sol";
import "./interface/IP2Controller.sol";
import "./interface/IERC20.sol";
import "./Exponential.sol";
import "./library/SafeERC20.sol";
import "./XTokenStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract XToken is XTokenStorage, Exponential, Initializable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**event */
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed minter, uint256 mintAmount, uint256 mintTokens, uint256 accountTokensAmount, uint256 exchageRate);
    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 accountTokensAmount, uint256 exchageRate);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event RepayBorrow(uint256 orderId, address borrower, address payer, uint256 repayAmount, uint256 orderBorrowBalance, uint256 totalBorrows);
    event LiquidateBorrow(uint256 orderId, address indexed borrower, address indexed liquidator, uint256 liquidatePrice);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);

    function initialize(
        uint256 _initialExchangeRate,
        address _controller,
        address _initialInterestRateModel,
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        initialExchangeRate = _initialExchangeRate;
        controller = IP2Controller(_controller);
        interestRateModel = IInterestRateModel(_initialInterestRateModel);
        require(interestRateModel.isInterestRateModel(), "not an interestratemodel contract address.");
        admin = payable(msg.sender);
        underlying = _underlying;
        accrualBlockNumber = getBlockNumber();
        borrowIndex = ONE;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _notEntered = true;
    }


    function doTransferIn(address account, uint256 amount) internal returns (uint256){
        if(underlying == ADDRESS_ETH){
            require(msg.value >= amount, "ETH value not enough");
            if (msg.value > amount){
                uint256 changeAmount = msg.value.sub(amount);
                (bool result, ) = account.call{value: changeAmount,gas: transferEthGasCost}("");
                require(result, "Transfer of ETH failed");
            }

        }else{
            require(msg.value == 0, "ERC20 don't accecpt ETH");

            uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
            IERC20(underlying).safeTransferFrom(account, address(this), amount);
            uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

            require(balanceAfter - balanceBefore == amount,"TransferIn amount not valid");
        }

        totalCash = totalCash.add(amount);
        return amount;
    }

    function doTransferOut(address payable account, uint256 amount) internal {
        if (underlying == ADDRESS_ETH) {
            (bool result, ) = account.call{value: amount, gas: transferEthGasCost}("");
            require(result, "Transfer of ETH failed");
        } else {
            IERC20(underlying).safeTransfer(account, amount);
        }

        totalCash = totalCash.sub(amount);
    }

    receive() external payable {
        accrueInterest();
        mintInternal(msg.sender, msg.value);
    }

    function mint(uint256 amount) external payable{
        accrueInterest();
        mintInternal(msg.sender, amount);
    }

    struct MintLocalVars {
        uint256 exchangeRate;
        uint256 mintTokens;
        uint256 totalSupplyNew;
        uint256 accountTokensNew;
        uint256 actualMintAmount;
    }

    function mintInternal(address minter, uint256 amount) internal nonReentrant {

        controller.mintAllowed(address(this), minter, amount);

        require(accrualBlockNumber == getBlockNumber(), "blocknumber check fails");

        MintLocalVars memory vars;
        vars.exchangeRate = exchangeRateStoredInternal();

        vars.actualMintAmount = doTransferIn(minter, amount);

        vars.mintTokens = divScalarByExpTruncate(vars.actualMintAmount, vars.exchangeRate);
        vars.totalSupplyNew = addExp(totalSupply, vars.mintTokens);
        vars.accountTokensNew = addExp(accountTokens[minter], vars.mintTokens);

        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        controller.mintVerify(address(this), minter);

        emit Mint(minter, vars.actualMintAmount, vars.mintTokens,vars.accountTokensNew, vars.exchangeRate);
        emit Transfer(address(0), minter, vars.mintTokens);
    }

    function redeem(uint256 redeemTokens) external{
        accrueInterest();
        redeemInternal(payable(msg.sender), redeemTokens, 0);
    }

    function redeemUnderlying(uint256 redeemAmounts) external{
        accrueInterest();
        redeemInternal(payable(msg.sender), 0, redeemAmounts);
    }

    struct RedeemLocalVars {
        uint256 exchangeRate;
        uint256 redeemTokens;
        uint256 redeemAmount;
        uint256 totalSupplyNew;
        uint256 accountTokensNew;
    }

    /**
    * redeemTokensIn: xToken amount
    * redeemAmountIn: underlying assets amount
    */
    function redeemInternal(address payable redeemer, uint256 redeemTokensIn, uint256 redeemAmountIn) internal nonReentrant {

        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn should be 0");

        RedeemLocalVars memory vars;
        vars.exchangeRate = exchangeRateStoredInternal();

        if (redeemTokensIn > 0 ){
            vars.redeemTokens = redeemTokensIn;
            vars.redeemAmount = mulScalarTruncate(vars.exchangeRate, redeemTokensIn);
        }else {
            vars.redeemTokens = divScalarByExpTruncate(redeemAmountIn,vars.exchangeRate);
            vars.redeemAmount = redeemAmountIn;
        }

        controller.redeemAllowed(address(this), redeemer, vars.redeemTokens, vars.redeemAmount);

        require(accrualBlockNumber == getBlockNumber(), "blocknumber check fails");

        vars.totalSupplyNew = totalSupply.sub(vars.redeemTokens);
        vars.accountTokensNew = accountTokens[redeemer].sub(vars.redeemTokens);

        require(getCashPrior() >= vars.redeemAmount, "insufficient balance of underlying asset");

        doTransferOut(redeemer, vars.redeemAmount);

        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        controller.redeemVerify(address(this), redeemer);

        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens, vars.accountTokensNew, vars.exchangeRate);
        emit Transfer(redeemer, address(0), vars.redeemTokens);
    }

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external{
        require(msg.sender == borrower || tx.origin == borrower, "borrower is wrong");
        accrueInterest();
        borrowInternal(orderId, borrower, borrowAmount);
    }

    struct BorrowLocalVars {
        uint256 orderBorrows;
        uint256 orderBorrowsNew;
        uint256 totalBorrowsNew;
    }

    function borrowInternal(uint256 orderId, address payable borrower, uint256 borrowAmount) internal nonReentrant{
        
        controller.borrowAllowed(address(this), orderId, borrower, borrowAmount);

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        
        require(getCashPrior() >= borrowAmount, "insufficient balance of underlying asset");

        BorrowLocalVars memory vars;

        vars.orderBorrows = borrowBalanceStoredInternal(orderId);
        vars.orderBorrowsNew = addExp(vars.orderBorrows, borrowAmount);
        vars.totalBorrowsNew = addExp(totalBorrows, borrowAmount);
        
        doTransferOut(borrower, borrowAmount);

        orderBorrows[orderId].principal = vars.orderBorrowsNew;
        orderBorrows[orderId].interestIndex = borrowIndex;

        totalBorrows = vars.totalBorrowsNew;

        controller.borrowVerify(orderId, address(this), borrower);

        emit Borrow(orderId, borrower, borrowAmount, vars.orderBorrowsNew, vars.totalBorrowsNew);
    }

    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable{
        accrueInterest();
        repayBorrowInternal(orderId, borrower, msg.sender, repayAmount);
    }

    struct RepayBorrowLocalVars {
        uint256 repayAmount;
        uint256 borrowerIndex;
        uint256 orderBorrows;
        uint256 orderBorrowsNew;
        uint256 totalBorrowsNew;
        uint256 actualRepayAmount;
    }

    function repayBorrowInternal(uint256 orderId, address borrower, address payer, uint256 repayAmount) internal returns(uint256){

        controller.repayBorrowAllowed(address(this), orderId, borrower, payer, repayAmount);

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        
        RepayBorrowLocalVars memory vars;

        vars.borrowerIndex = orderBorrows[orderId].interestIndex;
        vars.orderBorrows = borrowBalanceStoredInternal(orderId);

        if (repayAmount == type(uint256).max) {
            vars.repayAmount = vars.orderBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

        require(vars.orderBorrows >= vars.actualRepayAmount, "invalid repay amount");
        vars.orderBorrowsNew = vars.orderBorrows.sub(vars.actualRepayAmount);

        if (totalBorrows < vars.actualRepayAmount) {
            vars.totalBorrowsNew = 0;
        } else {
            vars.totalBorrowsNew = totalBorrows.sub(vars.actualRepayAmount);
        }

        orderBorrows[orderId].principal = vars.orderBorrowsNew;
        orderBorrows[orderId].interestIndex = borrowIndex;

        totalBorrows = vars.totalBorrowsNew;

        controller.repayBorrowVerify(address(this), orderId, borrower, payer, vars.actualRepayAmount);

        emit RepayBorrow(orderId, borrower, payer, vars.actualRepayAmount, vars.orderBorrowsNew, totalBorrows);

        return vars.actualRepayAmount;
    }

    function repayBorrowAndClaim(uint256 orderId, address borrower) external nonReentrant payable{
        require(msg.sender == borrower || tx.origin == borrower, "borrower is wrong");
        accrueInterest();
        repayBorrowAndClaimInternal(orderId, borrower, msg.sender);
    }

    function repayBorrowAndClaimInternal(uint256 orderId, address borrower, address payer) internal{
        repayBorrowInternal(orderId, borrower, payer, type(uint256).max);
        controller.repayBorrowAndClaimVerify(address(this), orderId);
    }

    function liquidateBorrow(uint256 orderId, address borrower) external nonReentrant payable{
        accrueInterest();
        liquidateBorrowInternal(orderId, borrower, msg.sender);
    }
    
    function liquidateBorrowInternal(uint256 orderId, address borrower, address liquidator) internal returns(uint256){
        controller.liquidateBorrowAllowed(address(this), orderId, borrower, liquidator);
        
        require(accrualBlockNumber == getBlockNumber(),"block number check fails");

        uint256 _repayAmount = repayBorrowInternal(orderId, borrower, liquidator, type(uint256).max);

        LiquidateState storage _state = liquidatedOrders[orderId];
        _state.liquidated = true;
        _state.liquidator = msg.sender;
        _state.liquidatedPrice = _repayAmount;

        controller.liquidateBorrowVerify(address(this), orderId, borrower, liquidator, _repayAmount);

        emit LiquidateBorrow(orderId, borrower, liquidator, _repayAmount);
        return _repayAmount;
    }

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256){
        LiquidateState storage _state = liquidatedOrders[orderId];
        return (_state.liquidated, _state.liquidator, _state.liquidatedPrice);
    }

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256){
        accrueInterest();
        return borrowBalanceStoredInternal(orderId);
    }

    function borrowBalanceStored(uint256 orderId) external view returns (uint256){
        return borrowBalanceStoredInternal(orderId);
    }

    function borrowBalanceStoredInternal(uint256 orderId) internal view returns (uint256){
        BorrowSnapshot storage borrowSnapshot = orderBorrows[orderId];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        return mulExp(borrowSnapshot.principal, divExp(borrowIndex, borrowSnapshot.interestIndex));
    }

    function exchangeRateCurrent() public returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    function exchangeRateStored() public view returns (uint256) {
        return exchangeRateStoredInternal();
    }

    function exchangeRateStoredInternal() internal view returns (uint256) {
        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            return initialExchangeRate;
        } else {
            uint256 _totalCash = getCashPrior();
            uint256 cashPlusBorrowsMinusReserves = subExp(addExp(_totalCash, totalBorrows),totalReserves);

            uint256 exchangeRate = getDiv(cashPlusBorrowsMinusReserves, _totalSupply);
            return exchangeRate;
        }
    }

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function getCashPrior() internal view returns (uint256) {
        return totalCash;
    }

    function accrueInterest() public {
        uint256 currentBlockNumber =  getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return;
        }

        uint256 cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        uint256 borrowRate = interestRateModel.getBorrowRate(cashPrior,borrowsPrior,reservesPrior);
        
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);

        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 totalBorrowsNew;
        uint256 totalReservesNew;
        uint256 borrowIndexNew;

        simpleInterestFactor = mulScalar(borrowRate, blockDelta);

        interestAccumulated = divExp(mulExp(simpleInterestFactor, borrowsPrior),expScale);

        totalBorrowsNew = addExp(interestAccumulated, borrowsPrior);

        totalReservesNew = addExp(divExp(mulExp(reserveFactor, interestAccumulated), expScale),reservesPrior);

        borrowIndexNew = addExp(divExp(mulExp(simpleInterestFactor, borrowIndexPrior), expScale),borrowIndexPrior);

        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        borrowRate = interestRateModel.getBorrowRate(cashPrior,totalBorrows,totalReserves);
       
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");
    }

    function accrueInterestReadOnly() public view returns(uint256, uint256, uint256){
        uint256 currentBlockNumber =  getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return (totalBorrows, totalReserves, borrowIndex);
        }

        uint256 cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        uint256 borrowRate = interestRateModel.getBorrowRate(cashPrior,borrowsPrior,reservesPrior);
        
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);

        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 totalBorrowsNew;
        uint256 totalReservesNew;
        uint256 borrowIndexNew;

        simpleInterestFactor = mulScalar(borrowRate, blockDelta);

        interestAccumulated = divExp(mulExp(simpleInterestFactor, borrowsPrior), expScale);

        totalBorrowsNew = addExp(interestAccumulated, borrowsPrior);

        totalReservesNew = addExp(divExp(mulExp(reserveFactor, interestAccumulated), expScale),reservesPrior);

        borrowIndexNew = addExp(divExp(mulExp(simpleInterestFactor, borrowIndexPrior), expScale),borrowIndexPrior);

        return (totalBorrowsNew, totalReservesNew, borrowIndexNew);
    }

    function getSupplyed(uint256 amount) external view returns(uint256){
        (uint256 totalBorrows, uint256 totalReserves,) = accrueInterestReadOnly();
        uint256 exchangeRate;
        if (totalSupply == 0) {
            exchangeRate = initialExchangeRate;
        } else {
            uint256 cashPlusBorrowsMinusReserves = subExp(addExp(getCashPrior(), totalBorrows), totalReserves);
            exchangeRate = getDiv(cashPlusBorrowsMinusReserves, totalSupply);
        }
        return mulScalarTruncate(exchangeRate, amount);
    }

    function getBorrowed(uint256 orderId) external view returns (uint256){
        (, , uint256 borrowIndexTemp) = accrueInterestReadOnly();
        BorrowSnapshot storage borrowSnapshot = orderBorrows[orderId];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }
        uint256 currentDebt = mulExp(borrowSnapshot.principal, divExp(borrowIndexTemp, borrowSnapshot.interestIndex));
        return currentDebt;
    }

    function getBorrowApy() external view returns(uint256){
        return interestRateModel.getBorrowRate(getCashPrior() , totalBorrows, totalReserves).mul(interestRateModel.blocksPerYear());
    }

    function getSupplyApy() external view returns(uint256){
        return interestRateModel.getSupplyRate(getCashPrior() , totalBorrows, totalReserves, reserveFactor).mul(interestRateModel.blocksPerYear());
    }

    function balanceOfUnderlying(address owner) external returns (uint256) {
        uint256 exchangeRate = exchangeRateCurrent();
        uint256 balance = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        return balance;
    }

    //================ ERC20 standand function ================
    function allowance(address owner, address spender) external view returns (uint256){
        return transferAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        return transferTokens(msg.sender, sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool){
        return transferTokens(msg.sender, msg.sender, recipient, amount);
    }

    function transferTokens(address spender, address src, address dst, uint256 tokens) internal returns (bool) {
        controller.transferAllowed(address(this), src, dst, tokens);
        require(src != dst, "Cannot transfer to self");

        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        uint256 allowanceNew = startingAllowance.sub(tokens);

        accountTokens[src] = accountTokens[src].sub(tokens);
        accountTokens[dst] = accountTokens[dst].add(tokens);

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        controller.transferVerify(address(this), src, dst);

        emit Transfer(src, dst, tokens);

        return true;
    }

    function balanceOf(address owner) external view  returns (uint256) {
        return accountTokens[owner];
    }

    //================ admin ================

    function setPendingAdmin(address payable newPendingAdmin) external onlyAdmin{
        
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function setController(address _controller) external onlyAdmin {
        controller = IP2Controller(_controller);
    }

    function setReserveFactor(uint256 newReserveFactor) external onlyAdmin {
        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(newReserveFactor < reserveFactorMax, "new reserveFactor too lardge");

        reserveFactor = newReserveFactor;
    }

    function reduceReserves(uint256 reduceAmount) external onlyAdmin {

        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(reduceAmount <= getCashPrior(), "insufficient balance of underlying asset");
        require(reduceAmount <= totalReserves, "invalid reduce amount");

        totalReserves = totalReserves.sub(reduceAmount);
        doTransferOut(admin, reduceAmount);
    }

    function setInterestRateModel(IInterestRateModel newInterestRateModel) external onlyAdmin {
        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(newInterestRateModel.isInterestRateModel(), "invalid interestRateModel");

        interestRateModel = newInterestRateModel;
    }

    function setTransferEthGasCost(uint256 _transferEthGasCost) external onlyAdmin {
        transferEthGasCost = _transferEthGasCost;
    }

    //================ modifier ================
     modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "require admin auth");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IInterestRateModel {

    function blocksPerYear() external view returns (uint256); 

    function isInterestRateModel() external returns(bool);

    function getBorrowRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash, 
        uint256 borrows, 
        uint256 reserves, 
        uint256 reserveFactor) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./IERC20.sol";
import "./IInterestRateModel.sol";

interface IXToken is IERC20 {

    function balanceOfUnderlying(address owner) external returns (uint256);

    function mint(uint256 amount) external payable;
    function redeem(uint256 redeemTokens) external;
    function redeemUnderlying(uint256 redeemAmounts) external;

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external;
    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable;
    function liquidateBorrow(uint256 orderId, address borrower) external payable;

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256); 

    function accrueInterest() external;

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256);
    function borrowBalanceStored(uint256 orderId) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns(address);
    function totalBorrows() external view returns(uint256);
    function totalCash() external view returns (uint256);
    function totalReserves() external view returns (uint256);

    /**admin function **/
    function setPendingAdmin(address payable newPendingAdmin) external;
    function acceptAdmin() external;
    function setReserveFactor(uint256 newReserveFactor) external;
    function reduceReserves(uint256 reduceAmount) external;
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;
    function setTransferEthGasCost(uint256 _transferEthGasCost) external;

    /**event */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IP2Controller {

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external;

    function mintVerify(address xToken, address account) external;

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external;

    function redeemVerify(address xToken, address redeemer) external;
    
    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external;

    function borrowVerify(uint256 orderId, address xToken, address borrower) external;

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external;

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external;

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external;
    
    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external;

    function transferVerify(address xToken, address src, address dst) external;

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256);

    // admin function

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external;

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external;

    function setPriceOracle(address _oracle) external;

    function setXNFT(address _xNFT) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function decimals() external view returns (uint8);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./library/SafeMath.sol";

contract Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant halfExpScale = expScale / 2;

    using SafeMath for uint256;

    function getExp(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function getDiv(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function addExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.add(b);
    }

    function subExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.sub(b);
    }

    function mulExp(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 doubleScaledProduct = a.mul(b);

        uint256 doubleScaledProductWithHalfScale = halfExpScale.add(
            doubleScaledProduct
        );

        return doubleScaledProductWithHalfScale.div(expScale);
    }

    function divExp(uint256 a, uint256 b) public pure returns (uint256) {
        return getDiv(a, b);
    }

    function mulExp3(
        uint256 a,
        uint256 b,
        uint256 c
    ) external pure returns (uint256) {
        return mulExp(mulExp(a, b), c);
    }

    function mulScalar(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256 scaled)
    {
        scaled = a.mul(scalar);
    }

    function mulScalarTruncate(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256)
    {
        uint256 product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalarTruncateAddUInt(
        uint256 a,
        uint256 scalar,
        uint256 addend
    ) external pure returns (uint256) {
        uint256 product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    function divScalarByExpTruncate(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 numerator = expScale.mul(scalar);
        return getExp(numerator, divisor);
    }

    function divScalar(uint256 a, uint256 scalar)
        external
        pure
        returns (uint256)
    {
        return a.div(scalar);
    }

    function truncate(uint256 exp) public pure returns (uint256) {
        return exp.div(expScale);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../interface/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./interface/IInterestRateModel.sol";
import "./interface/IP2Controller.sol";

contract ERC20Storage{

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping (address => mapping (address => uint256)) internal transferAllowances;

    mapping (address => uint256) internal accountTokens;
}

contract XTokenStorage is ERC20Storage {
    
    uint256 internal constant borrowRateMax = 0.0005e16;

    uint256 internal constant reserveFactorMax = 1e18;

    address payable public admin;
    
    address payable public pendingAdmin;

    bool internal _notEntered;

    IInterestRateModel public interestRateModel;

    uint256 internal initialExchangeRate;

    uint256 public reserveFactor;

    uint256 public totalBorrows;

    uint256 public totalReserves;

    uint256 public borrowIndex;

    uint256 public accrualBlockNumber;

    uint256 public totalCash;

    IP2Controller public controller;

    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    //order id => borrow snapshot
    mapping(uint256 => BorrowSnapshot) public orderBorrows;
    // orderId => liquidated or not

    struct LiquidateState{
        bool liquidated;
        address liquidator;
        uint256 liquidatedPrice;
    }
    mapping(uint256 => LiquidateState) public liquidatedOrders;

    address public underlying;

    address internal constant ADDRESS_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 public constant ONE = 1e18;

    uint256 public transferEthGasCost;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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