/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Caution. We assume all failed transfers cause reverts and ignore the returned bool.
interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface IOracle {
    function getPrice(address,uint) external returns (uint);
    function viewPrice(address,uint) external view returns (uint);
}

interface IEscrow {
    function initialize(IERC20 _token, address beneficiary) external;
    function onDeposit() external;
    function pay(address recipient, uint amount) external;
    function balance() external view returns (uint);
}

interface IDolaBorrowingRights {
    function onBorrow(address user, uint additionalDebt) external;
    function onRepay(address user, uint repaidDebt) external;
    function onForceReplenish(address user, address replenisher, uint amount, uint replenisherReward) external;
    function balanceOf(address user) external view returns (uint);
    function deficitOf(address user) external view returns (uint);
    function replenishmentPriceBps() external view returns (uint);
}

interface IBorrowController {
    function borrowAllowed(address msgSender, address borrower, uint amount) external returns (bool);
    function onRepay(uint amount) external;
}

contract Market {

    address public gov;
    address public lender;
    address public pauseGuardian;
    address public immutable escrowImplementation;
    IDolaBorrowingRights public immutable dbr;
    IBorrowController public borrowController;
    IERC20 public immutable dola = IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    IERC20 public immutable collateral;
    IOracle public oracle;
    uint public collateralFactorBps;
    uint public replenishmentIncentiveBps;
    uint public liquidationIncentiveBps;
    uint public liquidationFeeBps;
    uint public liquidationFactorBps = 5000; // 50% by default
    bool immutable callOnDepositCallback;
    bool public borrowPaused;
    uint public totalDebt;
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping (address => IEscrow) public escrows; // user => escrow
    mapping (address => uint) public debts; // user => debt
    mapping(address => uint256) public nonces; // user => nonce

    constructor (
        address _gov,
        address _lender,
        address _pauseGuardian,
        address _escrowImplementation,
        IDolaBorrowingRights _dbr,
        IERC20 _collateral,
        IOracle _oracle,
        uint _collateralFactorBps,
        uint _replenishmentIncentiveBps,
        uint _liquidationIncentiveBps,
        bool _callOnDepositCallback
    ) {
        require(_collateralFactorBps < 10000, "Invalid collateral factor");
        require(_liquidationIncentiveBps > 0 && _liquidationIncentiveBps < 10000, "Invalid liquidation incentive");
        require(_replenishmentIncentiveBps < 10000, "Replenishment incentive must be less than 100%");
        gov = _gov;
        lender = _lender;
        pauseGuardian = _pauseGuardian;
        escrowImplementation = _escrowImplementation;
        dbr = _dbr;
        collateral = _collateral;
        oracle = _oracle;
        collateralFactorBps = _collateralFactorBps;
        replenishmentIncentiveBps = _replenishmentIncentiveBps;
        liquidationIncentiveBps = _liquidationIncentiveBps;
        callOnDepositCallback = _callOnDepositCallback;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
        if(collateralFactorBps > 0){
            uint unsafeLiquidationIncentive = (10000 - collateralFactorBps) * (liquidationFeeBps + 10000) / collateralFactorBps;
            require(liquidationIncentiveBps < unsafeLiquidationIncentive,  "Liquidation param allow profitable self liquidation");
        }
    }
    
    modifier onlyGov {
        require(msg.sender == gov, "Only gov can call this function");
        _;
    }

    modifier liquidationParamChecker {
        _;
        if(collateralFactorBps > 0){
            uint unsafeLiquidationIncentive = (10000 - collateralFactorBps) * (liquidationFeeBps + 10000) / collateralFactorBps;
            require(liquidationIncentiveBps < unsafeLiquidationIncentive,  "New liquidation param allow profitable self liquidation");
        }
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("DBR MARKET")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
    @notice sets the oracle to a new oracle. Only callable by governance.
    @param _oracle The new oracle conforming to the IOracle interface.
    */
    function setOracle(IOracle _oracle) public onlyGov { oracle = _oracle; }

    /**
    @notice sets the borrow controller to a new borrow controller. Only callable by governance.
    @param _borrowController The new borrow controller conforming to the IBorrowController interface.
    */
    function setBorrowController(IBorrowController _borrowController) public onlyGov { borrowController = _borrowController; }

    /**
    @notice sets the address of governance. Only callable by governance.
    @param _gov Address of the new governance.
    */
    function setGov(address _gov) public onlyGov { gov = _gov; }

    /**
    @notice sets the lender to a new lender. The lender is allowed to recall dola from the contract. Only callable by governance.
    @param _lender Address of the new lender.
    */
    function setLender(address _lender) public onlyGov { lender = _lender; }

    /**
    @notice sets the pause guardian. The pause guardian can pause borrowing. Only callable by governance.
    @param _pauseGuardian Address of the new pauseGuardian.
    */
    function setPauseGuardian(address _pauseGuardian) public onlyGov { pauseGuardian = _pauseGuardian; }
    
    /**
    @notice sets the Collateral Factor requirement of the market as measured in basis points. 1 = 0.01%. Only callable by governance.
    @dev Collateral factor mus be set below 100%
    @param _collateralFactorBps The new collateral factor as measured in basis points. 
    */
    function setCollateralFactorBps(uint _collateralFactorBps) public onlyGov liquidationParamChecker {
        require(_collateralFactorBps < 10000, "Invalid collateral factor");
        collateralFactorBps = _collateralFactorBps;
    }
    
    /**
    @notice sets the Liquidation Factor of the market as denoted in basis points.
     The liquidation Factor denotes the maximum amount of debt that can be liquidated in basis points.
     At 5000, 50% of of a borrower's underwater debt can be liquidated. Only callable by governance.
    @dev Must be set between 1 and 10000.
    @param _liquidationFactorBps The new liquidation factor in basis points. 1 = 0.01%/
    */
    function setLiquidationFactorBps(uint _liquidationFactorBps) public onlyGov {
        require(_liquidationFactorBps > 0 && _liquidationFactorBps <= 10000, "Invalid liquidation factor");
        liquidationFactorBps = _liquidationFactorBps;
    }

    /**
    @notice sets the Replenishment Incentive of the market as denoted in basis points.
     The Replenishment Incentive is the percentage paid out to replenishers on a successful forceReplenish call, denoted in basis points.
    @dev Must be set between 1 and 10000.
    @param _replenishmentIncentiveBps The new replenishment incentive set in basis points. 1 = 0.01%
    */
    function setReplenismentIncentiveBps(uint _replenishmentIncentiveBps) public onlyGov {
        require(_replenishmentIncentiveBps > 0 && _replenishmentIncentiveBps < 10000, "Invalid replenishment incentive");
        replenishmentIncentiveBps = _replenishmentIncentiveBps;
    }

    /**
    @notice sets the Liquidation Incentive of the market as denoted in basis points.
     The Liquidation Incentive is the percentage paid out to liquidators of a borrower's debt when successfully liquidated.
    @dev Must be set between 0 and 10000 - liquidation fee.
    @param _liquidationIncentiveBps The new liqudation incentive set in basis points. 1 = 0.01% 
    */
    function setLiquidationIncentiveBps(uint _liquidationIncentiveBps) public onlyGov liquidationParamChecker {
        require(_liquidationIncentiveBps > 0 && _liquidationIncentiveBps + liquidationFeeBps < 10000, "Invalid liquidation incentive");
        liquidationIncentiveBps = _liquidationIncentiveBps;
    }

    /**
    @notice sets the Liquidation Fee of the market as denoted in basis points.
     The Liquidation Fee is the percentage paid out to governance of a borrower's debt when successfully liquidated.
    @dev Must be set between 0 and 10000 - liquidation factor.
    @param _liquidationFeeBps The new liquidation fee set in basis points. 1 = 0.01%
    */
    function setLiquidationFeeBps(uint _liquidationFeeBps) public onlyGov liquidationParamChecker {
        require(_liquidationFeeBps > 0 && _liquidationFeeBps + liquidationIncentiveBps < 10000, "Invalid liquidation fee");
        liquidationFeeBps = _liquidationFeeBps;
    }

    /**
    @notice Recalls amount of DOLA to the lender.
    @param amount The amount od DOLA to recall to the the lender.
    */
    function recall(uint amount) public {
        require(msg.sender == lender, "Only lender can recall");
        dola.transfer(msg.sender, amount);
    }

    /**
    @notice Pauses or unpauses borrowing for the market. Only gov can unpause a market, while gov and pauseGuardian can pause it.
    @param _value Boolean representing the state pause state of borrows. true = paused, false = unpaused.
    */
    function pauseBorrows(bool _value) public {
        if(_value) {
            require(msg.sender == pauseGuardian || msg.sender == gov, "Only pause guardian or governance can pause");
        } else {
            require(msg.sender == gov, "Only governance can unpause");
        }
        borrowPaused = _value;
    }

    /**
    @notice Internal function for creating an escrow for users to deposit collateral in.
    @dev Uses create2 and minimal proxies to create the escrow at a deterministic address
    @param user The address of the user to create an escrow for.
    */
    function createEscrow(address user) internal returns (IEscrow instance) {
        address implementation = escrowImplementation;
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, user)
        }
        require(instance != IEscrow(address(0)), "ERC1167: create2 failed");
        emit CreateEscrow(user, address(instance));
    }

    /**
    @notice Internal function for getting the escrow of a user.
    @dev If the escrow doesn't exist, an escrow contract is deployed.
    @param user The address of the user owning the escrow.
    */
    function getEscrow(address user) internal returns (IEscrow) {
        if(escrows[user] != IEscrow(address(0))) return escrows[user];
        IEscrow escrow = createEscrow(user);
        escrow.initialize(collateral, user);
        escrows[user] = escrow;
        return escrow;
    }

    /**
    @notice Deposit amount of collateral into escrow
    @dev Will deposit the amount into the escrow contract.
    @param amount Amount of collateral token to deposit.
    */
    function deposit(uint amount) public {
        deposit(msg.sender, amount);
    }

    /**
    @notice Deposit and borrow in a single transaction.
    @param amountDeposit Amount of collateral token to deposit into escrow.
    @param amountBorrow Amount of DOLA to borrow.
    */
    function depositAndBorrow(uint amountDeposit, uint amountBorrow) public {
        deposit(amountDeposit);
        borrow(amountBorrow);
    }

    /**
    @notice Deposit amount of collateral into escrow on behalf of msg.sender
    @dev Will deposit the amount into the escrow contract.
    @param user User to deposit on behalf of.
    @param amount Amount of collateral token to deposit.
    */
    function deposit(address user, uint amount) public {
        IEscrow escrow = getEscrow(user);
        collateral.transferFrom(msg.sender, address(escrow), amount);
        if(callOnDepositCallback) {
            escrow.onDeposit();
        }
        emit Deposit(user, amount);
    }

    /**
    @notice View function for predicting the deterministic escrow address of a user.
    @dev Only use deposit() function for deposits and NOT the predicted escrow address unless you know what you're doing
    @param user Address of the user owning the escrow.
    */
    function predictEscrow(address user) public view returns (IEscrow predicted) {
        address implementation = escrowImplementation;
        address deployer = address(this);
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), user)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
    @notice View function for getting the dollar value of the user's collateral in escrow for the market.
    @param user Address of the user.
    */
    function getCollateralValue(address user) public view returns (uint) {
        IEscrow escrow = predictEscrow(user);
        uint collateralBalance = escrow.balance();
        return collateralBalance * oracle.viewPrice(address(collateral), collateralFactorBps) / 1 ether;
    }

    /**
    @notice Internal function for getting the dollar value of the user's collateral in escrow for the market.
    @dev Updates the lowest price comparisons of the pessimistic oracle
    @param user Address of the user.
    */
    function getCollateralValueInternal(address user) internal returns (uint) {
        IEscrow escrow = predictEscrow(user);
        uint collateralBalance = escrow.balance();
        return collateralBalance * oracle.getPrice(address(collateral), collateralFactorBps) / 1 ether;
    }

    /**
    @notice View function for getting the credit limit of a user.
    @dev To calculate the available credit, subtract user debt from credit limit.
    @param user Address of the user.
    */
    function getCreditLimit(address user) public view returns (uint) {
        uint collateralValue = getCollateralValue(user);
        return collateralValue * collateralFactorBps / 10000;
    }

    /**
    @notice Internal function for getting the credit limit of a user.
    @dev To calculate the available credit, subtract user debt from credit limit. Updates the pessimistic oracle.
    @param user Address of the user.
    */
    function getCreditLimitInternal(address user) internal returns (uint) {
        uint collateralValue = getCollateralValueInternal(user);
        return collateralValue * collateralFactorBps / 10000;
    }
    /**
    @notice Internal function for getting the withdrawal limit of a user.
     The withdrawal limit is how much collateral a user can withdraw before their loan would be underwater. Updates the pessimistic oracle.
    @param user Address of the user.
    */
    function getWithdrawalLimitInternal(address user) internal returns (uint) {
        IEscrow escrow = predictEscrow(user);
        uint collateralBalance = escrow.balance();
        if(collateralBalance == 0) return 0;
        uint debt = debts[user];
        if(debt == 0) return collateralBalance;
        if(collateralFactorBps == 0) return 0;
        uint minimumCollateral = debt * 1 ether / oracle.getPrice(address(collateral), collateralFactorBps) * 10000 / collateralFactorBps;
        if(collateralBalance <= minimumCollateral) return 0;
        return collateralBalance - minimumCollateral;
    }

    /**
    @notice View function for getting the withdrawal limit of a user.
     The withdrawal limit is how much collateral a user can withdraw before their loan would be underwater.
    @param user Address of the user.
    */
    function getWithdrawalLimit(address user) public view returns (uint) {
        IEscrow escrow = predictEscrow(user);
        uint collateralBalance = escrow.balance();
        if(collateralBalance == 0) return 0;
        uint debt = debts[user];
        if(debt == 0) return collateralBalance;
        if(collateralFactorBps == 0) return 0;
        uint minimumCollateral = debt * 1 ether / oracle.viewPrice(address(collateral), collateralFactorBps) * 10000 / collateralFactorBps;
        if(collateralBalance <= minimumCollateral) return 0;
        return collateralBalance - minimumCollateral;
    }

    /**
    @notice Internal function for borrowing DOLA against collateral.
    @dev This internal function is shared between the borrow and borrowOnBehalf function
    @param borrower The address of the borrower that debt will be accrued to.
    @param to The address that will receive the borrowed DOLA
    @param amount The amount of DOLA to be borrowed
    */
    function borrowInternal(address borrower, address to, uint amount) internal {
        require(!borrowPaused, "Borrowing is paused");
        if(borrowController != IBorrowController(address(0))) {
            require(borrowController.borrowAllowed(msg.sender, borrower, amount), "Denied by borrow controller");
        }
        uint credit = getCreditLimitInternal(borrower);
        debts[borrower] += amount;
        require(credit >= debts[borrower], "Exceeded credit limit");
        totalDebt += amount;
        dbr.onBorrow(borrower, amount);
        dola.transfer(to, amount);
        emit Borrow(borrower, amount);
    }

    /**
    @notice Function for borrowing DOLA.
    @dev Will borrow to msg.sender
    @param amount The amount of DOLA to be borrowed.
    */
    function borrow(uint amount) public {
        borrowInternal(msg.sender, msg.sender, amount);
    }

    /**
    @notice Function for using a signed message to borrow on behalf of an address owning an escrow with collateral.
    @dev Signed messaged can be invalidated by incrementing the nonce. Will always borrow to the msg.sender.
    @param from The address of the user being borrowed from
    @param amount The amount to be borrowed
    @param deadline Timestamp after which the signed message will be invalid
    @param v The v param of the ECDSA signature
    @param r The r param of the ECDSA signature
    @param s The s param of the ECDSA signature
    */
    function borrowOnBehalf(address from, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "BorrowOnBehalf(address caller,address from,uint256 amount,uint256 nonce,uint256 deadline)"
                                ),
                                msg.sender,
                                from,
                                amount,
                                nonces[from]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
            require(recoveredAddress != address(0) && recoveredAddress == from, "INVALID_SIGNER");
            borrowInternal(from, msg.sender, amount);
        }
    }

    /**
    @notice Internal function for withdrawing from the escrow
    @dev The internal function is shared by the withdraw function and withdrawOnBehalf function
    @param from The address owning the escrow to withdraw from.
    @param to The address receiving the tokens
    @param amount The amount being withdrawn.
    */
    function withdrawInternal(address from, address to, uint amount) internal {
        uint limit = getWithdrawalLimitInternal(from);
        require(limit >= amount, "Insufficient withdrawal limit");
        require(dbr.deficitOf(from) == 0, "Can't withdraw with DBR deficit");
        IEscrow escrow = getEscrow(from);
        escrow.pay(to, amount);
        emit Withdraw(from, to, amount);
    }

    /**
    @notice Function for withdrawing to msg.sender.
    @param amount Amount to withdraw.
    */
    function withdraw(uint amount) public {
        withdrawInternal(msg.sender, msg.sender, amount);
    }

    /**
    @notice Function for using a signed message to withdraw on behalf of an address owning an escrow with collateral.
    @dev Signed messaged can be invalidated by incrementing the nonce. Will always withdraw to the msg.sender.
    @param from The address of the user owning the escrow being withdrawn from
    @param amount The amount to be withdrawn
    @param deadline Timestamp after which the signed message will be invalid
    @param v The v param of the ECDSA signature
    @param r The r param of the ECDSA signature
    @param s The s param of the ECDSA signature
    */
    function withdrawOnBehalf(address from, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "WithdrawOnBehalf(address caller,address from,uint256 amount,uint256 nonce,uint256 deadline)"
                                ),
                                msg.sender,
                                from,
                                amount,
                                nonces[from]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
            require(recoveredAddress != address(0) && recoveredAddress == from, "INVALID_SIGNER");
            withdrawInternal(from, msg.sender, amount);
        }
    }

    /**
    @notice Function for incrementing the nonce of the msg.sender, making their latest signed message unusable.
    */
    function invalidateNonce() public {
        nonces[msg.sender]++;
    }
    
    /**
    @notice Function for repaying debt on behalf of user. Debt must be repaid in DOLA.
    @dev If the user has a DBR deficit, they risk initial debt being accrued by forced replenishments.
    @param user Address of the user whose debt is being repaid
    @param amount DOLA amount to be repaid. If set to max uint debt will be repaid in full.
    */
    function repay(address user, uint amount) public {
        uint debt = debts[user];
        if(amount == type(uint).max){
            amount = debt;
        }
        require(debt >= amount, "Repayment greater than debt");
        debts[user] -= amount;
        totalDebt -= amount;
        dbr.onRepay(user, amount);
        if(address(borrowController) != address(0)){
            borrowController.onRepay(amount);
        }
        dola.transferFrom(msg.sender, address(this), amount);
        emit Repay(user, msg.sender, amount);
    }

    /**
    @notice Bundles repayment and withdrawal into a single function call.
    @param repayAmount Amount of DOLA to be repaid
    @param withdrawAmount Amount of underlying to be withdrawn from the escrow
    */
    function repayAndWithdraw(uint repayAmount, uint withdrawAmount) public {
        repay(msg.sender, repayAmount);
        withdraw(withdrawAmount);
    }

    /**
    @notice Function for forcing a user to replenish their DBR deficit at a pre-determined price.
     The replenishment will accrue additional DOLA debt.
     On a successful call, the caller will be paid a replenishment incentive.
    @dev The function will only top the user back up to 0, meaning that the user will have a DBR deficit again in the next block.
    @param user The address of the user being forced to replenish DBR
    @param amount The amount of DBR the user will be replenished.
    */
    function forceReplenish(address user, uint amount) public {
        uint deficit = dbr.deficitOf(user);
        require(deficit > 0, "No DBR deficit");
        require(deficit >= amount, "Amount > deficit");
        uint replenishmentCost = amount * dbr.replenishmentPriceBps() / 10000;
        uint replenisherReward = replenishmentCost * replenishmentIncentiveBps / 10000;
        debts[user] += replenishmentCost;
        uint collateralValue = getCollateralValueInternal(user) * (10000 - liquidationIncentiveBps - liquidationFeeBps) / 10000;
        require(collateralValue >= debts[user], "Exceeded collateral value");
        totalDebt += replenishmentCost;
        dbr.onForceReplenish(user, msg.sender, amount, replenisherReward);
        dola.transfer(msg.sender, replenisherReward);
    }
    /**
    @notice Function for forcing a user to replenish all of their DBR deficit at a pre-determined price.
     The replenishment will accrue additional DOLA debt.
     On a successful call, the caller will be paid a replenishment incentive.
    @dev The function will only top the user back up to 0, meaning that the user will have a DBR deficit again in the next block.
    @param user The address of the user being forced to replenish DBR
    */
    function forceReplenishAll(address user) public {
        uint deficit = dbr.deficitOf(user);
        forceReplenish(user, deficit);
    }

    /**
    @notice Function for liquidating a user's under water debt. Debt is under water when the value of a user's debt is above their collateral factor.
    @param user The user to be liquidated
    @param repaidDebt Th amount of user user debt to liquidate.
    */
    function liquidate(address user, uint repaidDebt) public {
        require(repaidDebt > 0, "Must repay positive debt");
        uint debt = debts[user];
        require(getCreditLimitInternal(user) < debt, "User debt is healthy");
        require(repaidDebt <= debt * liquidationFactorBps / 10000, "Exceeded liquidation factor");
        uint price = oracle.getPrice(address(collateral), collateralFactorBps);
        uint liquidatorReward = repaidDebt * 1 ether / price;
        liquidatorReward += liquidatorReward * liquidationIncentiveBps / 10000;
        debts[user] -= repaidDebt;
        totalDebt -= repaidDebt;
        dbr.onRepay(user, repaidDebt);
        dola.transferFrom(msg.sender, address(this), repaidDebt);
        IEscrow escrow = predictEscrow(user);
        escrow.pay(msg.sender, liquidatorReward);
        if(liquidationFeeBps > 0) {
            uint liquidationFee = repaidDebt * 1 ether / price * liquidationFeeBps / 10000;
            uint balance = escrow.balance();
            if(balance >= liquidationFee) {
                escrow.pay(gov, liquidationFee);
            } else if(balance > 0) {
                escrow.pay(gov, balance);
            }
        }
        emit Liquidate(user, msg.sender, repaidDebt, liquidatorReward);
    }
    
    event Deposit(address indexed account, uint amount);
    event Borrow(address indexed account, uint amount);
    event Withdraw(address indexed account, address indexed to, uint amount);
    event Repay(address indexed account, address indexed repayer, uint amount);
    event Liquidate(address indexed account, address indexed liquidator, uint repaidDebt, uint liquidatorReward);
    event CreateEscrow(address indexed user, address escrow);
}