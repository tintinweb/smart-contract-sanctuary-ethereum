/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external returns (uint256);

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getWETHAddress() external view returns (address);
}

interface IAToken {
    function balanceOf(address account) external view returns (uint256);
}

interface ILendingPool {
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

contract Acorn {
    event Deposit(address user, uint256 amount, uint256 balance);
    event Withdraw(address user, uint256 amount, uint256 balance);
    event UpdatedBalance(address user, uint256 balance);
    event WithdrawFromAave(address user, uint256 amount);
    event CollectFee(address user, uint256 fee);
    event DepositToAave(address user, uint256 amount);

    mapping(address => uint256) public balances;
    mapping(address => uint256) internal atokenBalances;
    uint256 internal treasury;
    address internal owner;
    address internal lendingPoolAddress;
    address internal wEthAddress;
    uint256 public constant FEE_PERCENTAGE = 1000; // 0.1%
    uint16 public constant REFERRAL_CODE = 0;

    // fallback functions, more info here: https://ethereum.stackexchange.com/questions/81994/what-is-the-receive-keyword-in-solidity
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    // TODO: Decide what admin operations we need
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _lendingPoolAddress, address _wETHAddress) {
        owner = msg.sender;
        lendingPoolAddress = _lendingPoolAddress;
        wEthAddress = _wETHAddress;
    }

    function deposit() public payable {
        uint256 amount = msg.value;
        uint256 fee = amount / FEE_PERCENTAGE;
        treasury += fee;
        emit CollectFee(msg.sender, fee);
        uint256 depositAmount = amount - fee;
        balances[msg.sender] += depositAmount;
        emit Deposit(msg.sender, depositAmount, balances[msg.sender]);
    }

    function withdraw(uint256 amount) public {
        require(msg.sender != address(0x0));
        require(amount <= balances[msg.sender], "not enough balance");
        withdrawFromAave(amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount, balances[msg.sender]);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function sendToAave() public payable {
        // msg.value used directly since fee's should be deducted prior this would be called within deposit
        // 0 used as temporary test referral code
        require(msg.sender != address(0x0));
        IWETHGateway(lendingPoolAddress).depositETH(
            lendingPoolAddress,
            address(this),
            REFERRAL_CODE
        );
        emit DepositToAave(msg.sender, balances[msg.sender]);
    }

    function withdrawFromAave(uint256 amount) internal {
        require(msg.sender != address(0x0));
        updateBalanceFromAave(calculateAaveYield());
        IWETHGateway(lendingPoolAddress).withdrawETH(
            lendingPoolAddress,
            amount,
            address(this)
        );
        emit WithdrawFromAave(msg.sender, balances[msg.sender]);
    }

    function calculateAaveYield() internal view returns (uint256) {
        IAToken aWETH = IAToken(
            ILendingPool(lendingPoolAddress)
                .getReserveData(wEthAddress)
                .aTokenAddress
        );

        uint256 contractBalanceWithoutFees = address(this).balance - treasury;
        uint256 totalYield = aWETH.balanceOf(address(this)) -
            contractBalanceWithoutFees;
        uint256 userFractionalShare = balances[msg.sender] /
            contractBalanceWithoutFees;
        uint256 userYield = totalYield * userFractionalShare;

        return userYield;
    }

    function updateBalanceFromAave(uint256 yield) internal {
        require(msg.sender != address(0x0));
        balances[msg.sender] += yield;
        emit UpdatedBalance(msg.sender, balances[msg.sender]);
    }
}

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}