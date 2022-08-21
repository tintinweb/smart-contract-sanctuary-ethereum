// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Data/Data.sol";
import "../../IntresetModel/InterestModel.sol";

import "../../Core/Contracts/Manager.sol";

// import "../../RewardManager/Contract/RewardManager.sol";

contract ETHMarket {
    // address payable Owner;

    string marketName;
    uint256 marketID;

    uint256 constant unifiedPoint = 10**18;
    uint256 unifiedTokenDecimal;
    uint256 underlyingTokenDecimal;

    MarketData DataStorageContract;
    InterestModel InterestModelContract;

    Manager ManagerContract;

    // RewardManager RewardManagerContract;

    // modifier OnlyOwner() {
    //     require(msg.sender == Owner, "OnlyOwner");
    //     _;
    // }

    // modifier OnlyManagerContract() {
    //     require(msg.sender == address(ManagerContract), "OnlyManagerContract");
    //     _;
    // }

    constructor() {
        // Owner = payable(msg.sender);
    }

    // function setRewardManagerContract(address _RewardManagerContract)
    //     external
    //     returns (bool)
    // {
    //     RewardManagerContract = RewardManager(_RewardManagerContract);
    //     return true;
    // }

    function setManagerContract(address _ManagerContract)
        external
        returns (bool)
    {
        ManagerContract = Manager(_ManagerContract);
        return true;
    }

    function setDataStorageContract(address _DataStorageContract)
        external
        returns (bool)
    {
        DataStorageContract = MarketData(_DataStorageContract);
        return true;
    }

    function setInterestModelContract(address _InterestModelContract)
        external
        returns (bool)
    {
        InterestModelContract = InterestModel(_InterestModelContract);
        return true;
    }

    function setMarketName(string memory _marketName) external returns (bool) {
        marketName = _marketName;
        return true;
    }

    function setMarketID(uint256 _marketID) external returns (bool) {
        marketID = _marketID;
        return true;
    }

    // deposit function in platform
    function deposit(uint256 _amountToDeposit) external payable returns (bool) {
        // get user address as payable
        address payable _userAddress = payable(msg.sender);

        // require amount to deposit is more than 0 to stop wasting gas;
        require(
            _amountToDeposit > 0 && msg.value > 0,
            "You have to deposit more than 0 amount"
        );
        // require input is same as msg.value;
        require(
            msg.value == _amountToDeposit,
            "MSG value should be same as input value"
        );

        // calculate intreset params for user and market
        ManagerContract.applyInterestHandlers(_userAddress, marketID);

        // update amount to user and market data
        DataStorageContract.addDepositAmount(_userAddress, _amountToDeposit);

        return true;
    }

    function repay(uint256 _amountToRepay) external payable returns (bool) {
        address payable _userAddress = payable(msg.sender);

        require(_amountToRepay > 0);
        require(msg.value == _amountToRepay);

        // RewardManagerContract.updateRewardManagerData(_userAddress);
        _updateUserMarketInterest(_userAddress);

        ManagerContract.applyInterestHandlers(_userAddress, marketID);

        uint256 userBorrowAmount = DataStorageContract.getUserBorrowAmount(
            _userAddress
        );

        if (userBorrowAmount < _amountToRepay) {
            _amountToRepay = userBorrowAmount;
        }

        DataStorageContract.subBorrowAmount(_userAddress, _amountToRepay);
        return true;
    }

    function withdraw(uint256 _amountToWithdraw) external returns (bool) {
        address payable _userAddress = payable(msg.sender);

        uint256 userLiquidityAmount;
        uint256 userCollateralizableAmount;
        uint256 price;
        (
            userLiquidityAmount,
            userCollateralizableAmount,
            ,
            ,
            ,
            price
        ) = ManagerContract.applyInterestHandlers(_userAddress, marketID);

        require(
            unifiedMul(_amountToWithdraw, price) <=
                DataStorageContract.getMarketLimitOfAction()
        );

        uint256 adjustedAmount = _getUserMaxAmountToWithdrawInWithdrawFunc(
            _userAddress,
            _amountToWithdraw,
            userCollateralizableAmount
        );

        DataStorageContract.subDepositAmount(_userAddress, adjustedAmount);

        _userAddress.transfer(adjustedAmount);

        return true;
    }

    function borrow(uint256 _amountToBorrow) external returns (bool) {
        address payable _userAddress = payable(msg.sender);

        uint256 userLiquidityAmount;
        uint256 userCollateralizableAmount;
        uint256 price;
        (
            userLiquidityAmount,
            userCollateralizableAmount,
            ,
            ,
            ,
            price
        ) = ManagerContract.applyInterestHandlers(_userAddress, marketID);

        require(
            unifiedMul(_amountToBorrow, price) <=
                DataStorageContract.getMarketLimitOfAction()
        );

        uint256 adjustedAmount = _getUserMaxAmountToBorrowInBorrowFunc(
            _amountToBorrow,
            userLiquidityAmount
        );

        DataStorageContract.addBorrowAmount(_userAddress, adjustedAmount);

        _userAddress.transfer(adjustedAmount);

        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////// APPLY INTEREST
    /// in this process, we we get connected to intreset model contract;
    /// we will calc delta blocks ! last time platform get updated ;
    /// and with this delta blocks we update and calc our exchange rate, global exchange rate; action exchange rate; user exchange rate;
    /// we will calc Annual Borrow/Deposit Interest Rate with total deposit and total borrow;
    // we will delta params with user deposit and borrow balance;

    // update user and market intreset params;
    function updateUserMarketInterest(address payable _userAddress)
        external
        returns (uint256, uint256)
    {
        return _updateUserMarketInterest(_userAddress);
    }

    // update user and market intreset params;
    function _updateUserMarketInterest(address payable _userAddress)
        internal
        returns (uint256, uint256)
    {
        // check if user is new , to ser user access and update user deposit and borrow exchange rate with global exchange rate;
        _checkIfUserIsNew(_userAddress);
        // this is function to know and get information about how many blocks, platform is not updated !
        _checkIfThisIsFirstAction();
        return _getUpdatedInterestParams(_userAddress);
    }

    function _checkIfUserIsNew(address payable _userAddress)
        internal
        returns (bool)
    {
        // check user access on platform;
        if (DataStorageContract.getUserIsAccessed(_userAddress)) {
            return false;
        }

        // if user is new we set user access to true;
        DataStorageContract.setUserAccessed(_userAddress, true);

        // get global exchange rate for deposit and borrow from platform;
        (uint256 gDEXR, uint256 gBEXR) = DataStorageContract
            .getGlDepositBorrowEXR();
        // set exchange rate to user;
        DataStorageContract.updateUserEXR(_userAddress, gDEXR, gBEXR);
        return true;
    }

    // this is function to know and get information about how many blocks, platform is not updated !
    // we use this delta blocks to update uur exhcnage rate;
    function _checkIfThisIsFirstAction() internal returns (bool) {
        uint256 _LastTimeBlockUpdated = DataStorageContract
            .getLastTimeBlockUpdated();
        uint256 _currentBlock = block.number;
        uint256 _deltaBlock = sub(_currentBlock, _LastTimeBlockUpdated);

        if (_deltaBlock > 0) {
            DataStorageContract.updateBlocks(_currentBlock, _deltaBlock);
            DataStorageContract.syncActionGlobalEXR();
            return true;
        }

        return false;
    }

    // this is how we update intreset model of our box ; :)
    function _getUpdatedInterestParams(address payable _userAddress)
        internal
        returns (uint256, uint256)
    {
        // get updated intreset params from intreset model contract / this is for user !
        // there is delta amount between deposit and borrow for user ?
        bool _depositIsNegative;
        uint256 _depositDeltaAmount;
        uint256 _glDepositEXR;

        bool _borrowIsNegative;
        uint256 _borrowDeltaAmount;
        uint256 _glBorrowEXR;
        (
            _depositIsNegative,
            _depositDeltaAmount,
            _glDepositEXR,
            _borrowIsNegative,
            _borrowDeltaAmount,
            _glBorrowEXR
        ) = InterestModelContract.getUpdatedInterestParams(
            _userAddress,
            address(DataStorageContract),
            false
        );

        // update user exchange rates with new global exchange rates;
        DataStorageContract.updateUserEXR(
            _userAddress,
            _glDepositEXR,
            _glBorrowEXR
        );

        return
            _interestGetAndUpdate(
                _userAddress,
                _depositIsNegative,
                _depositDeltaAmount,
                _borrowIsNegative,
                _borrowDeltaAmount
            );
    }

    function _interestGetAndUpdate(
        address payable _userAddress,
        bool _depositIsNegative,
        uint256 _depositDeltaAmount,
        bool _borrowIsNegative,
        uint256 _borrowDeltaAmount
    ) internal returns (uint256, uint256) {
        // in this function we get current and saved market data and user data about deposit and borrow;
        uint256 _totalDepositAmount;
        uint256 _userDepositAmount;
        uint256 _totalBorrowAmount;
        uint256 _userBorrowAmount;

        // now we update this data by new delta and negative params;
        (
            _totalDepositAmount,
            _userDepositAmount,
            _totalBorrowAmount,
            _userBorrowAmount
        ) = _getUpdatedInterestAmounts(
            _userAddress,
            _depositIsNegative,
            _depositDeltaAmount,
            _borrowIsNegative,
            _borrowDeltaAmount
        );

        // after calc new data , we update market and user amount ! new deposit and borrow data;
        DataStorageContract.updateAmounts(
            _userAddress,
            _totalDepositAmount,
            _totalBorrowAmount,
            _userDepositAmount,
            _userBorrowAmount
        );

        return (_userDepositAmount, _userBorrowAmount);
    }

    function _getUpdatedInterestAmounts(
        address payable _userAddress,
        bool _depositIsNegative,
        uint256 _depositDeltaAmount,
        bool _borrowIsNegative,
        uint256 _borrowDeltaAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // get current amount for user and market !
        uint256 _totalDepositAmount;
        uint256 _userDepositAmount;
        uint256 _totalBorrowAmount;
        uint256 _userBorrowAmount;
        (
            _totalDepositAmount,
            _totalBorrowAmount,
            _userDepositAmount,
            _userBorrowAmount
        ) = DataStorageContract.getAmounts(_userAddress);

        // by condition if there is delta amount for data , we make update and return new data;
        if (_depositIsNegative) {
            _totalDepositAmount = sub(_totalDepositAmount, _depositDeltaAmount);
            _userDepositAmount = sub(_userDepositAmount, _depositDeltaAmount);
        } else {
            _totalDepositAmount = add(_totalDepositAmount, _depositDeltaAmount);
            _userDepositAmount = add(_userDepositAmount, _depositDeltaAmount);
        }

        if (_borrowIsNegative) {
            _totalBorrowAmount = sub(_totalBorrowAmount, _borrowDeltaAmount);
            _userBorrowAmount = sub(_userBorrowAmount, _borrowDeltaAmount);
        } else {
            _totalBorrowAmount = add(_totalBorrowAmount, _borrowDeltaAmount);
            _userBorrowAmount = add(_userBorrowAmount, _borrowDeltaAmount);
        }

        return (
            _totalDepositAmount,
            _userDepositAmount,
            _totalBorrowAmount,
            _userBorrowAmount
        );
    }

    function getUpdatedInterestAmountsForUser(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return _getUpdatedInterestAmountsForUser(_userAddress);
    }

    // update intreset params and get updated data for user !
    function _getUpdatedInterestAmountsForUser(address payable _userAddress)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _totalDepositAmount;
        uint256 _userDepositAmount;
        uint256 _totalBorrowAmount;
        uint256 _userBorrowAmount;
        (
            _totalDepositAmount,
            _userDepositAmount,
            _totalBorrowAmount,
            _userBorrowAmount
        ) = _calcAmountWithInterest(_userAddress);

        return (_userDepositAmount, _userBorrowAmount);
    }

    // update intreset params and get updated data for market !
    function _getUpdatedInterestAmountsForMarket(address payable _userAddress)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _totalDepositAmount;
        uint256 _userDepositAmount;
        uint256 _totalBorrowAmount;
        uint256 _userBorrowAmount;
        (
            _totalDepositAmount,
            _userDepositAmount,
            _totalBorrowAmount,
            _userBorrowAmount
        ) = _calcAmountWithInterest(_userAddress);

        return (_totalDepositAmount, _totalBorrowAmount);
    }

    // get updated intreset params and get updated data for user and market !
    function _calcAmountWithInterest(address payable _userAddress)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        bool _depositIsNegative;
        uint256 _depositDeltaAmount;
        uint256 _glDepositEXR;

        bool _borrowIsNegative;
        uint256 _borrowDeltaAmount;
        uint256 _glBorrowEXR;

        (
            _depositIsNegative,
            _depositDeltaAmount,
            _glDepositEXR,
            _borrowIsNegative,
            _borrowDeltaAmount,
            _glBorrowEXR
        ) = InterestModelContract.getUpdatedInterestParams(
            _userAddress,
            address(DataStorageContract),
            false
        );

        return
            _getUpdatedInterestAmounts(
                _userAddress,
                _depositIsNegative,
                _depositDeltaAmount,
                _borrowIsNegative,
                _borrowDeltaAmount
            );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////// USER MAX ACTIONS

    // BORROW //////////////////////////////////////////////

    // how much user can borrow from platform ? we use this func in front !
    function getUserMaxAmountToBorrow(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return _getUserMaxAmountToBorrow(_userAddress);
    }

    // how much user can borrow from platform ?
    function _getUserMaxAmountToBorrow(address payable _userAddress)
        internal
        view
        returns (uint256)
    {
        // get free liquidityDeposit of user with correct decimals and struct !
        uint256 _marketLiquidityLimit = _getMarketLIQAfterInterestUpdateWithLimit(
                _userAddress
            );

        // now make some calc in manager contract ! we get how many asset user can borrow based on free liq of user !
        uint256 _howMuchUserCanBorrow = ManagerContract.getHowMuchUserCanBorrow(
            _userAddress,
            marketID
        );

        // main free to borrow is _howMuchUserCanBorrow;
        uint256 _freeToBorrow = _howMuchUserCanBorrow;
        if (_marketLiquidityLimit < _freeToBorrow) {
            _freeToBorrow = _marketLiquidityLimit;
        }

        return _freeToBorrow;
    }

    // we use this function in our platform !
    function _getUserMaxAmountToBorrowInBorrowFunc(
        uint256 _requestedToBorrow,
        uint256 _userLiq
    ) internal view returns (uint256) {
        // market liq limit is total dep * liqlim (1 ether or 1 * 10 ** 18) - total borr !
        uint256 _marketLiquidityLimit = _getMarketLiquidityWithLimit();

        uint256 _freeToBorrow = _requestedToBorrow;

        if (_freeToBorrow > _marketLiquidityLimit) {
            _freeToBorrow = _marketLiquidityLimit;
        }

        if (_freeToBorrow > _userLiq) {
            _freeToBorrow = _userLiq;
        }

        return _freeToBorrow;
    }

    // WITHDRAW //////////////////////////////////////////////

    function getUserMaxAmountToWithdraw(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return _getUserMaxAmountToWithdraw(_userAddress);
    }

    function _getUserMaxAmountToWithdraw(address payable _userAddress)
        internal
        view
        returns (uint256)
    {
        // for get user withdrawable amount ! we should first update user and market intreset params and data !
        uint256 _userUpdatedDepositAmountWithInterest;
        uint256 _userUpdatedBorrowAmountWithInterest;

        // we first make update in intreset params for user and market and them we user user data;
        (
            _userUpdatedDepositAmountWithInterest,
            _userUpdatedBorrowAmountWithInterest
        ) = _getUpdatedInterestAmountsForUser(_userAddress);

        // for get user withdrawable amount ! we should first update user and market intreset params and data !
        // we first make update in intreset params for user and market and them we user market data;
        uint256 _marketLIQAfterInterestUpdate = _getMarketLIQAfterInterestUpdate(
                _userAddress
            );

        uint256 _userFreeToWithdraw = ManagerContract.getUserFreeToWithdraw(
            _userAddress,
            marketID
        );

        uint256 _freeToWithdraw = _userUpdatedDepositAmountWithInterest;

        if (_freeToWithdraw > _userFreeToWithdraw) {
            _freeToWithdraw = _userFreeToWithdraw;
        }

        if (_freeToWithdraw > _marketLIQAfterInterestUpdate) {
            _freeToWithdraw = _marketLIQAfterInterestUpdate;
        }

        return _freeToWithdraw;
    }

    function _getUserMaxAmountToWithdrawInWithdrawFunc(
        address payable _userAddress,
        uint256 _requestedToWithdraw,
        uint256 _userWithdrawableAmount
    ) internal view returns (uint256) {
        // we get user deposit from market data contract;
        uint256 _userDeposit = DataStorageContract.getUserDepositAmount(
            _userAddress
        );

        // we get market liq >>> total dep - total borrow
        uint256 _marketLiq = _getMarketLiquidity();

        // user is free to with his user deposit;
        uint256 _freeToWithdraw = _userDeposit;

        // this is amount that user asked !
        if (_freeToWithdraw > _requestedToWithdraw) {
            _freeToWithdraw = _requestedToWithdraw;
        }

        // this is amount that we got from manager contract and it's withdrawable
        if (_freeToWithdraw > _userWithdrawableAmount) {
            _freeToWithdraw = _userWithdrawableAmount;
        }

        // this free liq in market
        if (_freeToWithdraw > _marketLiq) {
            _freeToWithdraw = _marketLiq;
        }

        return _freeToWithdraw;
    }

    // REPAY //////////////////////////////////////////////

    function getUserMaxAmountToRepay(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        uint256 _userDepositAmountAfterInterestUpdate;
        uint256 _userBorrowAmountAfterInterestUpdate;
        (
            _userDepositAmountAfterInterestUpdate,
            _userBorrowAmountAfterInterestUpdate
        ) = _getUpdatedInterestAmountsForUser(_userAddress);

        return _userBorrowAmountAfterInterestUpdate;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////// MARKET TOOLS

    function getUpdatedMarketSIRAndBIR()
        external
        view
        returns (uint256, uint256)
    {
        uint256 _totalDepositAmount = DataStorageContract
            .getMarketDepositTotalAmount();
        uint256 _totalBorrowAmount = DataStorageContract
            .getMarketBorrowTotalAmount();

        return
            InterestModelContract.getSIRBIR(
                _totalDepositAmount,
                _totalBorrowAmount
            );
    }

    function getMarketLIQAfterInterestUpdate(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return _getMarketLIQAfterInterestUpdate(_userAddress);
    }

    function _getMarketLIQAfterInterestUpdate(address payable _userAddress)
        internal
        view
        returns (uint256)
    {
        // first we get market total balance for deposit and borrow after update intreset params for user and market in intresetModel contract;
        uint256 _totalDepositAmount;
        uint256 _totalBorrowAmount;
        (
            _totalDepositAmount,
            _totalBorrowAmount
        ) = _getUpdatedInterestAmountsForMarket(_userAddress);

        // now deposit amount should be more than 0 and more than borrow amount;
        if (_totalDepositAmount == 0) {
            return 0;
        }

        if (_totalDepositAmount < _totalBorrowAmount) {
            return 0;
        }

        // now we return D-B
        return sub(_totalDepositAmount, _totalBorrowAmount);
    }

    // in this function we make calc for return how much user can borrow
    function _getMarketLIQAfterInterestUpdateWithLimit(
        address payable _userAddress
    ) internal view returns (uint256) {
        // we get user total deposit and borrow from data contract
        uint256 _totalDepositAmount;
        uint256 _totalBorrowAmount;
        (
            _totalDepositAmount,
            _totalBorrowAmount
        ) = _getUpdatedInterestAmountsForMarket(_userAddress);

        // if user deposit is 0; so user can't borrow any amount and we will return 0 !
        if (_totalDepositAmount == 0) {
            return 0;
        }

        // we get liquidityDeposit , it's user deposit amount mul start point or 1 * 10 ** 18; for get correct uint with correct decimals !
        uint256 liquidityDeposit = unifiedMul(
            _totalDepositAmount,
            DataStorageContract.getMarketLiquidityLimit()
        );

        // if userdeposit is < borrow so user can't borrow any money and again we will return 0;
        if (liquidityDeposit < _totalBorrowAmount) {
            return 0;
        }

        // now we return liq amount sub total borrow ! for example 10 - 0 ! is 10 ! this is free liquidity of user;
        return sub(liquidityDeposit, _totalBorrowAmount);
    }

    // we use this function to get delta between deposit and borrow !
    function _getMarketLiquidity() internal view returns (uint256) {
        uint256 _totalDepositAmount = DataStorageContract
            .getMarketDepositTotalAmount();
        uint256 _totalBorrowAmount = DataStorageContract
            .getMarketBorrowTotalAmount();

        // if deposit in market is 0; we return 0;
        if (_totalDepositAmount == 0) {
            return 0;
        }

        // if deposit is < borrow / calc is wrong and we should return 0;
        if (_totalDepositAmount < _totalBorrowAmount) {
            return 0;
        }

        return sub(_totalDepositAmount, _totalBorrowAmount);
    }

    // this is similarly to _getMarketLiquidity, but here we use MarketLiquidityLimit to get currect number of free liq ! total deposit * 10 ** 18;
    function _getMarketLiquidityWithLimit() internal view returns (uint256) {
        uint256 _totalDepositAmount = DataStorageContract
            .getMarketDepositTotalAmount();
        uint256 _totalBorrowAmount = DataStorageContract
            .getMarketBorrowTotalAmount();

        if (_totalDepositAmount == 0) {
            return 0;
        }

        uint256 liquidityDeposit = unifiedMul(
            _totalDepositAmount,
            DataStorageContract.getMarketLiquidityLimit()
        );

        if (liquidityDeposit < _totalBorrowAmount) {
            return 0;
        }

        return sub(liquidityDeposit, _totalBorrowAmount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////// INTERFACE FUNCTIONS

    function getMarketMarginCallLimit() external view returns (uint256) {
        return DataStorageContract.getMarketMarginCallLimit();
    }

    function getMarketBorrowLimit() external view returns (uint256) {
        return DataStorageContract.getMarketBorrowLimit();
    }

    function getAmounts(address payable _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return DataStorageContract.getAmounts(_userAddress);
    }

    function getUserAmount(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        uint256 depositAmount = DataStorageContract.getUserDepositAmount(
            _userAddress
        );
        uint256 borrowAmount = DataStorageContract.getUserBorrowAmount(
            _userAddress
        );

        return (depositAmount, borrowAmount);
    }

    function getUserDepositAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return DataStorageContract.getUserDepositAmount(_userAddress);
    }

    function getUserBorrowAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return DataStorageContract.getUserBorrowAmount(_userAddress);
    }

    function getMarketDepositTotalAmount() external view returns (uint256) {
        return DataStorageContract.getMarketDepositTotalAmount();
    }

    function getMarketBorrowTotalAmount() external view returns (uint256) {
        return DataStorageContract.getMarketBorrowTotalAmount();
    }

    // function updateRewardPerBlock(uint256 _rewardPerBlock)
    //     external
    //     OnlyManagerContract
    //     returns (bool)
    // {
    //     return RewardManagerContract.updateRewardPerBlock(_rewardPerBlock);
    // }

    // function updateRewardManagerData(address payable _userAddress)
    //     external
    //     returns (bool)
    // {
    //     return RewardManagerContract.updateRewardManagerData(_userAddress);
    // }

    // function getUpdatedUserRewardAmount(address payable _userAddress)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     return RewardManagerContract.getUpdatedUserRewardAmount(_userAddress);
    // }

    // function claimRewardAmountUser(address payable userAddr)
    //     external
    //     returns (uint256)
    // {
    //     return RewardManagerContract.claimRewardAmountUser(userAddr);
    // }

    /* ******************* Safe Math ******************* */
    // from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
    // Subject to the MIT license.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "sub overflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "div by zero");
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "mod by zero");
    }

    function _sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require((c / a) == b, "mul overflow");
        return c;
    }

    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function _mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, unifiedPoint), b, "unified div by zero");
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
    }

    function signedAdd(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            ((b >= 0) && (c >= a)) || ((b < 0) && (c < a)),
            "SignedSafeMath: addition overflow"
        );
        return c;
    }

    function signedSub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            ((b >= 0) && (c <= a)) || ((b < 0) && (c > a)),
            "SignedSafeMath: subtraction overflow"
        );
        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MarketData {
    // address payable Owner;

    address MarketContract;
    address InterestModelContract;

    uint256 lastTimeBlockUpdated;
    uint256 inactiveBlocks;

    uint256 acDepositEXR;
    uint256 acBorrowEXR;

    uint256 glDepositEXR;
    uint256 glBorrowEXR;

    uint256 marketDepositTotalAmount;
    uint256 marketBorrowTotalAmount;

    uint256 constant startPoint = 10**18;
    uint256 public liquidityLimit = startPoint;
    uint256 public limitOfAction = 100000 * startPoint;

    struct MarketInterestModel {
        uint256 _marketBorrowLimit;
        uint256 _marketMarginCallLimit;
        uint256 _marketMinInterestRate;
        uint256 _marketLiquiditySen;
    }
    MarketInterestModel MarketInterestModelInstance;

    struct UserModel {
        bool _userIsAccessed;
        uint256 _userDepositAmount;
        uint256 _userBorrowAmount;
        uint256 _userDepositEXR;
        uint256 _userBorrowEXR;
    }
    mapping(address => UserModel) UserModelMapping;

    // modifier OnlyOwner() {
    //     require(msg.sender == Owner, "OnlyOwner");
    //     _;
    // }

    // modifier OnlyMyContracts() {
    //     address msgSender = msg.sender;
    //     require(
    //         (msgSender == MarketContract) ||
    //             (msgSender == InterestModelContract) ||
    //             (msgSender == Owner)
    //     );
    //     _;
    // }

    constructor(
        uint256 _borrowLimit,
        uint256 _marginCallLimit,
        uint256 _minimumInterestRate,
        uint256 _liquiditySensitivity
    ) {
        // Owner = payable(msg.sender);

        _initializeEXR();

        MarketInterestModel
            memory _MarketInterestModel = MarketInterestModelInstance;

        _MarketInterestModel._marketBorrowLimit = _borrowLimit;
        _MarketInterestModel._marketMarginCallLimit = _marginCallLimit;
        _MarketInterestModel._marketMinInterestRate = _minimumInterestRate;
        _MarketInterestModel._marketLiquiditySen = _liquiditySensitivity;
        MarketInterestModelInstance = _MarketInterestModel;
    }

    function _initializeEXR() internal {
        uint256 currectBlockNumber = block.number;
        acDepositEXR = startPoint;
        acBorrowEXR = startPoint;
        glDepositEXR = startPoint;
        glBorrowEXR = startPoint;
        lastTimeBlockUpdated = currectBlockNumber - 1;
        inactiveBlocks = lastTimeBlockUpdated;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// SETTER FUNCTIONS

    function setMarketContract(address _MarketContract)
        external
        returns (bool)
    {
        MarketContract = _MarketContract;
        return true;
    }

    function setInterestModelContract(address _InterestModelContract)
        external
        returns (bool)
    {
        InterestModelContract = _InterestModelContract;
        return true;
    }

    function setupNewUser(address payable _userAddress)
        external
        returns (bool)
    {
        UserModelMapping[_userAddress]._userIsAccessed = true;
        UserModelMapping[_userAddress]._userDepositAmount = startPoint;
        UserModelMapping[_userAddress]._userBorrowAmount = startPoint;

        return true;
    }

    function setUserAccessed(address payable _userAddress, bool _isAccess)
        external
        returns (bool)
    {
        UserModelMapping[_userAddress]._userIsAccessed = _isAccess;

        return true;
    }

    function updateAmounts(
        address payable _userAddress,
        uint256 _marketDepositTotalAmount,
        uint256 _marketBorrowTotalAmount,
        uint256 _userDepositAmount,
        uint256 _userBorrowAmount
    ) external returns (bool) {
        marketDepositTotalAmount = _marketDepositTotalAmount;
        marketBorrowTotalAmount = _marketBorrowTotalAmount;
        UserModelMapping[_userAddress]._userDepositAmount = _userDepositAmount;
        UserModelMapping[_userAddress]._userBorrowAmount = _userBorrowAmount;

        return true;
    }

    function addAmountToTotalDeposit(uint256 _amountToAdd)
        external
        returns (bool)
    {
        marketDepositTotalAmount = add(marketDepositTotalAmount, _amountToAdd);

        return true;
    }

    function subAmountToTotalDeposit(uint256 _amountToSub)
        external
        returns (bool)
    {
        marketDepositTotalAmount = sub(marketDepositTotalAmount, _amountToSub);

        return true;
    }

    function addAmountToTotalBorrow(uint256 _amountToAdd)
        external
        returns (bool)
    {
        marketBorrowTotalAmount = add(marketBorrowTotalAmount, _amountToAdd);

        return true;
    }

    function subAmountToTotalBorrow(uint256 _amountToSub)
        external
        returns (bool)
    {
        marketBorrowTotalAmount = sub(marketBorrowTotalAmount, _amountToSub);

        return true;
    }

    function addAmountToUserDeposit(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        UserModelMapping[_userAddress]._userDepositAmount = add(
            UserModelMapping[_userAddress]._userDepositAmount,
            _amountToAdd
        );

        return true;
    }

    function subAmountToUserDeposit(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        UserModelMapping[_userAddress]._userDepositAmount = sub(
            UserModelMapping[_userAddress]._userDepositAmount,
            _amountToSub
        );

        return true;
    }

    function addAmountToUserBorrow(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        UserModelMapping[_userAddress]._userBorrowAmount = add(
            UserModelMapping[_userAddress]._userBorrowAmount,
            _amountToAdd
        );

        return true;
    }

    function subAmountToUserBorrow(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        UserModelMapping[_userAddress]._userBorrowAmount = sub(
            UserModelMapping[_userAddress]._userBorrowAmount,
            _amountToSub
        );

        return true;
    }

    function addDepositAmount(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        marketDepositTotalAmount = add(marketDepositTotalAmount, _amountToAdd);

        UserModelMapping[_userAddress]._userDepositAmount = add(
            UserModelMapping[_userAddress]._userDepositAmount,
            _amountToAdd
        );

        return true;
    }

    function subDepositAmount(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        marketDepositTotalAmount = sub(marketDepositTotalAmount, _amountToSub);

        UserModelMapping[_userAddress]._userDepositAmount = sub(
            UserModelMapping[_userAddress]._userDepositAmount,
            _amountToSub
        );

        return true;
    }

    function addBorrowAmount(address payable _userAddress, uint256 _amountToAdd)
        external
        returns (bool)
    {
        marketBorrowTotalAmount = add(marketBorrowTotalAmount, _amountToAdd);

        UserModelMapping[_userAddress]._userBorrowAmount = add(
            UserModelMapping[_userAddress]._userBorrowAmount,
            _amountToAdd
        );

        return true;
    }

    function subBorrowAmount(address payable _userAddress, uint256 _amountToSub)
        external
        returns (bool)
    {
        marketBorrowTotalAmount = sub(marketBorrowTotalAmount, _amountToSub);

        UserModelMapping[_userAddress]._userBorrowAmount = sub(
            UserModelMapping[_userAddress]._userBorrowAmount,
            _amountToSub
        );

        return true;
    }

    function updateBlocks(
        uint256 _lastTimeBlockUpdated,
        uint256 _inactiveBlocks
    ) external returns (bool) {
        lastTimeBlockUpdated = _lastTimeBlockUpdated;
        inactiveBlocks = _inactiveBlocks;

        return true;
    }

    function setLastTimeBlockUpdated(uint256 _lastTimeBlockUpdated)
        external
        returns (bool)
    {
        lastTimeBlockUpdated = _lastTimeBlockUpdated;

        return true;
    }

    function setInactiveBlocks(uint256 _inactiveBlocks)
        external
        returns (bool)
    {
        inactiveBlocks = _inactiveBlocks;

        return true;
    }

    function syncActionGlobalEXR() external returns (bool) {
        acDepositEXR = glDepositEXR;
        acBorrowEXR = glBorrowEXR;

        return true;
    }

    function updateActionEXR(uint256 _acDepositEXR, uint256 _acBorrowEXR)
        external
        returns (bool)
    {
        acDepositEXR = _acDepositEXR;
        acBorrowEXR = _acBorrowEXR;

        return true;
    }

    function updateUserGlobalEXR(
        address payable _userAddress,
        uint256 _glDepositEXR,
        uint256 _glBorrowEXR
    ) external returns (bool) {
        glDepositEXR = _glDepositEXR;
        glBorrowEXR = _glBorrowEXR;

        UserModelMapping[_userAddress]._userDepositEXR = _glDepositEXR;
        UserModelMapping[_userAddress]._userBorrowEXR = _glBorrowEXR;

        return true;
    }

    function updateUserEXR(
        address payable _userAddress,
        uint256 _userDepositEXR,
        uint256 _userBorrowEXR
    ) external returns (bool) {
        UserModelMapping[_userAddress]._userDepositEXR = _userDepositEXR;
        UserModelMapping[_userAddress]._userBorrowEXR = _userBorrowEXR;

        return true;
    }

    function setMarketBorrowLimit(uint256 _marketBorrowLimit)
        external
        returns (bool)
    {
        MarketInterestModelInstance._marketBorrowLimit = _marketBorrowLimit;

        return true;
    }

    function setMarketMarginCallLimit(uint256 _marketMarginCallLimit)
        external
        returns (bool)
    {
        MarketInterestModelInstance
            ._marketMarginCallLimit = _marketMarginCallLimit;

        return true;
    }

    function setMinimumInterestRate(uint256 _marketMinInterestRate)
        external
        returns (bool)
    {
        MarketInterestModelInstance
            ._marketMinInterestRate = _marketMinInterestRate;

        return true;
    }

    function setMarketLiquiditySensitivity(uint256 _marketLiquiditySen)
        external
        returns (bool)
    {
        MarketInterestModelInstance._marketLiquiditySen = _marketLiquiditySen;

        return true;
    }

    function setLimitOfAction(uint256 _limitOfAction) external returns (bool) {
        limitOfAction = _limitOfAction;
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// GETTER FUNCTIONS

    function getMarketAmounts() external view returns (uint256, uint256) {
        return (marketDepositTotalAmount, marketBorrowTotalAmount);
    }

    function getUserAmounts(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            UserModelMapping[_userAddress]._userDepositAmount,
            UserModelMapping[_userAddress]._userBorrowAmount
        );
    }

    function getAmounts(address payable _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            marketDepositTotalAmount,
            marketBorrowTotalAmount,
            UserModelMapping[_userAddress]._userDepositAmount,
            UserModelMapping[_userAddress]._userBorrowAmount
        );
    }

    function getUserEXR(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            UserModelMapping[_userAddress]._userDepositEXR,
            UserModelMapping[_userAddress]._userBorrowEXR
        );
    }

    function getActionEXR() external view returns (uint256, uint256) {
        return (acDepositEXR, acBorrowEXR);
    }

    function getGlBorrowEXR() external view returns (uint256) {
        return glBorrowEXR;
    }

    function getGlDepositEXR() external view returns (uint256) {
        return glDepositEXR;
    }

    function getGlDepositBorrowEXR() external view returns (uint256, uint256) {
        return (glDepositEXR, glBorrowEXR);
    }

    function getMarketDepositTotalAmount() external view returns (uint256) {
        return marketDepositTotalAmount;
    }

    function getMarketBorrowTotalAmount() external view returns (uint256) {
        return marketBorrowTotalAmount;
    }

    function getUserDepositAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return UserModelMapping[_userAddress]._userDepositAmount;
    }

    function getUserBorrowAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return UserModelMapping[_userAddress]._userBorrowAmount;
    }

    function getUserIsAccessed(address payable _userAddress)
        external
        view
        returns (bool)
    {
        return UserModelMapping[_userAddress]._userIsAccessed;
    }

    function getLastTimeBlockUpdated() external view returns (uint256) {
        return lastTimeBlockUpdated;
    }

    function getInactiveBlocks() external view returns (uint256) {
        return inactiveBlocks;
    }

    function getMarketLimits() external view returns (uint256, uint256) {
        return (
            MarketInterestModelInstance._marketBorrowLimit,
            MarketInterestModelInstance._marketMarginCallLimit
        );
    }

    function getMarketBorrowLimit() external view returns (uint256) {
        return MarketInterestModelInstance._marketBorrowLimit;
    }

    function getMarketMarginCallLimit() external view returns (uint256) {
        return MarketInterestModelInstance._marketMarginCallLimit;
    }

    function getMarketMinimumInterestRate() external view returns (uint256) {
        return MarketInterestModelInstance._marketMinInterestRate;
    }

    function getMarketLiquiditySensitivity() external view returns (uint256) {
        return MarketInterestModelInstance._marketLiquiditySen;
    }

    function getMarketLiquidityLimit() external view returns (uint256) {
        return liquidityLimit;
    }

    function getMarketLimitOfAction() external view returns (uint256) {
        return limitOfAction;
    }

    /* ******************* Safe Math ******************* */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "sub overflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "div by zero");
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "mod by zero");
    }

    function _sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require((c / a) == b, "mul overflow");
        return c;
    }

    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function _mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, startPoint), b, "unified div by zero");
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), startPoint, "unified mul by zero");
    }

    function signedAdd(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            ((b >= 0) && (c >= a)) || ((b < 0) && (c < a)),
            "SignedSafeMath: addition overflow"
        );
        return c;
    }

    function signedSub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            ((b >= 0) && (c <= a)) || ((b < 0) && (c > a)),
            "SignedSafeMath: subtraction overflow"
        );
        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Utils/Utils/SafeMath.sol";
import "../Markets/Data/Data.sol";

contract InterestModel {
    using SafeMath for uint256;

    MarketData marketDataStorage;

    address payable Owner;

    uint256 blocksPerYear;
    uint256 constant startPoint = 10**18;

    uint256 marketMinRate;
    uint256 marketBasicSen;
    uint256 marketJPoint;
    uint256 marketJSen;
    uint256 marketSpreadPoint;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    struct userInterestModel {
        uint256 SIR;
        uint256 BIR;
        uint256 depositTotalAmount;
        uint256 borrowTotalAmount;
        uint256 userDepositAmount;
        uint256 userBorrowAmount;
        uint256 deltaDepositAmount;
        uint256 deltaBorrowAmount;
        uint256 globalDepositEXR;
        uint256 globalBorrowEXR;
        uint256 userDepositEXR;
        uint256 userBorrowEXR;
        uint256 actionDepositEXR;
        uint256 actionBorrowEXR;
        uint256 deltaDepositEXR;
        uint256 deltaBorrowEXR;
        bool depositNegativeFlag;
        bool borrowNegativeFlag;
    }

    constructor(
        uint256 _marketMinRate,
        uint256 _marketJPoint,
        uint256 _marketBasicSen,
        uint256 _marketJSen,
        uint256 _marketSpreadPoint
    ) {
        Owner = payable(msg.sender);
        marketMinRate = _marketMinRate;
        marketBasicSen = _marketBasicSen;
        marketJPoint = _marketJPoint;
        marketJSen = _marketJSen;
        marketSpreadPoint = _marketSpreadPoint;
    }

    // get last updated intreset params for user account and market;
    function getUpdatedInterestParams(
        address payable _userAddress,
        address _marketDataAddress,
        bool _isView
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        if (_isView) {
            return _viewUpdatedInterestParams(_userAddress, _marketDataAddress);
        } else {
            return _updateInterestParams(_userAddress, _marketDataAddress);
        }
    }

    function viewUpdatedInterestParams(
        address payable _userAddress,
        address _marketDataAddress
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        return _viewUpdatedInterestParams(_userAddress, _marketDataAddress);
    }

    function _viewUpdatedInterestParams(
        address payable _userAddress,
        address _marketDataAddress
    )
        internal
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        // create contract instance from given market id; DATA contract
        MarketData _marketDataStorage = MarketData(_marketDataAddress);

        // get current block number;
        uint256 currentBlockNumber = block.number;
        // get last time / block that match market get updated;
        uint256 LastTimeBlockUpdated = _marketDataStorage
            .getLastTimeBlockUpdated();

        // calc delta block; how many blocks market is not updated;
        uint256 _DeltaBlocks = currentBlockNumber.sub(LastTimeBlockUpdated);

        // now get deposit and borrow action exchange rate ! we updated this on every deposit action !
        uint256 _DepositActionEXR;
        uint256 _BorrowActionEXR;

        (_DepositActionEXR, _BorrowActionEXR) = _marketDataStorage
            .getActionEXR();

        // noew calc intreset params and return data;
        return
            _calcInterestModelForUser(
                _userAddress,
                _marketDataAddress,
                _DeltaBlocks,
                _DepositActionEXR,
                _BorrowActionEXR
            );
    }

    // update data for user account in given market;
    function _updateInterestParams(
        address payable _userAddress,
        address _marketDataAddress
    )
        internal
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        MarketData _marketDataStorage = MarketData(_marketDataAddress);

        uint256 _DeltaBlock = _marketDataStorage.getInactiveBlocks();

        (
            uint256 _DepositActionEXR,
            uint256 _BorrowActionEXR
        ) = _marketDataStorage.getActionEXR();

        return
            _calcInterestModelForUser(
                _userAddress,
                _marketDataAddress,
                _DeltaBlock,
                _DepositActionEXR,
                _BorrowActionEXR
            );
    }

    // game is happening here :)
    function _calcInterestModelForUser(
        address payable _userAddress,
        address _marketDataAddress,
        uint256 _Delta,
        uint256 _DepositEXR,
        uint256 _BorrowEXR
    )
        internal
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        // create memory model from intreset model;
        userInterestModel memory _userInterestModel;
        // create contract instance from given market address; data contract;
        MarketData _marketDataStorage = MarketData(_marketDataAddress);

        // get all balance details for market and user from data contract;
        (
            _userInterestModel.depositTotalAmount,
            _userInterestModel.borrowTotalAmount,
            _userInterestModel.userDepositAmount,
            _userInterestModel.userBorrowAmount
        ) = _marketDataStorage.getAmounts(_userAddress);

        // get user exchange rate from data contract/ we set this on deposit action;
        (
            _userInterestModel.userDepositEXR,
            _userInterestModel.userBorrowEXR
        ) = _marketDataStorage.getUserEXR(_userAddress);

        // calc Annual Deposit / Borrow Interest Rate
        (_userInterestModel.SIR, _userInterestModel.BIR) = _getSIRandBIRonBlock(
            _userInterestModel.depositTotalAmount,
            _userInterestModel.borrowTotalAmount
        );

        // *** DEPOSIT
        // calc new global exchange rate;
        _userInterestModel.globalDepositEXR = _getNewDepositGlobalEXR(
            _DepositEXR,
            _userInterestModel.SIR,
            _Delta
        );

        // calc delta amount !
        (
            _userInterestModel.depositNegativeFlag,
            _userInterestModel.deltaDepositAmount
        ) = _getNewDeltaRate(
            _userInterestModel.userDepositAmount,
            _userInterestModel.userDepositEXR,
            _userInterestModel.globalDepositEXR
        );

        // *** BORROW
        _userInterestModel.globalBorrowEXR = _getNewDepositGlobalEXR(
            _BorrowEXR,
            _userInterestModel.BIR,
            _Delta
        );

        (
            _userInterestModel.borrowNegativeFlag,
            _userInterestModel.deltaBorrowAmount
        ) = _getNewDeltaRate(
            _userInterestModel.userBorrowAmount,
            _userInterestModel.userBorrowEXR,
            _userInterestModel.globalBorrowEXR
        );

        return (
            _userInterestModel.depositNegativeFlag,
            _userInterestModel.deltaDepositAmount,
            _userInterestModel.globalDepositEXR,
            _userInterestModel.borrowNegativeFlag,
            _userInterestModel.deltaBorrowAmount,
            _userInterestModel.globalBorrowEXR
        );
    }

    // calc Annual Deposit / Borrow Interest Rate
    function getSIRBIR(uint256 _depositTotalAmount, uint256 _borrowTotalAmount)
        external
        view
        returns (uint256, uint256)
    {
        return _getSIRandBIRonBlock(_depositTotalAmount, _borrowTotalAmount);
    }

    function _getSIRandBIRonBlock(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal view returns (uint256, uint256) {
        uint256 _SIR;
        uint256 _BIR;

        //calc Annual Deposit / Borrow Interest Rate
        (_SIR, _BIR) = _getSIRandBIR(_depositTotalAmount, _borrowTotalAmount);

        // calc Deposit / Borrow Interest Rate / Block
        uint256 _finalSIR = _SIR / blocksPerYear;
        uint256 _finalBIR = _BIR / blocksPerYear;

        return (_finalSIR, _finalBIR);
    }

    function _getSIRandBIR(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal view returns (uint256, uint256) {
        // calc market Utilization Rate ==> Borrow / Deposit  + Borrow
        uint256 _marketRate = _getMarketRate(
            _depositTotalAmount,
            _borrowTotalAmount
        );

        uint256 _BIR;

        // Annual Borrow Interest Rate = minimum intreset rate + _marketRate * marketBasicSen
        if (_marketRate < marketJPoint) {
            _BIR = _marketRate.unifiedMul(marketBasicSen).add(marketMinRate);
        } else {
            _BIR = marketMinRate
                .add(marketJPoint.unifiedMul(marketBasicSen))
                .add(_marketRate.sub(marketJPoint).unifiedMul(marketJSen));
        }

        // Annual Deposit Interest Rate = BIR * _marketRate
        uint256 _SIR = _marketRate.unifiedMul(_BIR).unifiedMul(
            marketSpreadPoint
        );
        return (_SIR, _BIR);
    }

    // calc market Utilization Rate ==> Borrow / Deposit  + Borrow
    function _getMarketRate(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal pure returns (uint256) {
        if ((_depositTotalAmount == 0) && (_borrowTotalAmount == 0)) {
            return 0;
        }

        return _borrowTotalAmount.unifiedDiv(_depositTotalAmount);
    }

    function _getNewDepositGlobalEXR(
        uint256 _DepositActionEXR,
        uint256 _userInterestModelSIR,
        uint256 _Delta
    ) internal pure returns (uint256) {
        return
            _userInterestModelSIR.mul(_Delta).add(startPoint).unifiedMul(
                _DepositActionEXR
            );
    }

    function _getNewDeltaRate(
        uint256 _userAmount,
        uint256 _userEXR,
        uint256 _globalEXR
    ) internal pure returns (bool, uint256) {
        uint256 _DeltaEXR;
        uint256 _DeltaAmount;
        bool _negativeFlag;

        if (_userAmount != 0) {
            (_negativeFlag, _DeltaEXR) = _getDeltaEXR(_globalEXR, _userEXR);
            _DeltaAmount = _userAmount.unifiedMul(_DeltaEXR);
        }

        return (_negativeFlag, _DeltaAmount);
    }

    function _getDeltaEXR(uint256 _globalEXR, uint256 _userEXR)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 EXR = _globalEXR.unifiedDiv(_userEXR);
        if (EXR >= startPoint) {
            return (false, EXR.sub(startPoint));
        }

        return (true, startPoint.sub(EXR));
    }

    function setBlocksPerYear(uint256 _blocksPerYear)
        external
        OnlyOwner
        returns (bool)
    {
        blocksPerYear = _blocksPerYear;
        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Data/Data.sol";
import "../../Utils/Oracle/oracleProxy.sol";
import "../../Markets/Interface/MarketInterface.sol";
import "../../Utils/Utils/SafeMath.sol";

import "../../Utils/Tokens/standardIERC20.sol";

contract Manager {
    using SafeMath for uint256;

    //myAnswer
    uint256 public getAnswer;

    // address public Owner;

    ManagerData ManagerDataStorageContract;
    oracleProxy OracleContract;

    // standardIERC20 PersisToken;

    struct UserModelAssets {
        uint256 depositAssetSum;
        uint256 borrowAssetSum;
        uint256 marginCallLimitSum;
        uint256 depositAssetBorrowLimitSum;
        uint256 depositAsset;
        uint256 borrowAsset;
        uint256 price;
        uint256 callerPrice;
        uint256 depositAmount;
        uint256 borrowAmount;
        uint256 borrowLimit;
        uint256 marginCallLimit;
        uint256 callerBorrowLimit;
        uint256 userBorrowableAsset;
        uint256 withdrawableAsset;
    }

    mapping(address => UserModelAssets) _UserModelAssetsMapping;

    uint256 public marketsLength;

    // modifier OnlyOwner() {
    //     require(msg.sender == Owner, "OnlyOwner");
    //     _;
    // }

    constructor() {
        // PersisToken = standardIERC20(_PersisToken);
        // Owner = msg.sender;
    }

    function setOracleContract(address _OracleContract)
        external
        returns (bool)
    {
        OracleContract = oracleProxy(_OracleContract);
        return true;
    }

    function setManagerDataStorageContract(address _ManagerDataStorageContract)
        external
        returns (bool)
    {
        ManagerDataStorageContract = ManagerData(_ManagerDataStorageContract);
        return true;
    }

    function registerNewHandler(uint256 _marketID, address _marketAddress)
        external
        returns (bool)
    {
        return _registerNewHandler(_marketID, _marketAddress);
    }

    function _registerNewHandler(uint256 _marketID, address _marketAddress)
        internal
        returns (bool)
    {
        ManagerDataStorageContract.registerNewMarketInCore(
            _marketID,
            _marketAddress
        );
        marketsLength = marketsLength + 1;
        return true;
    }

    function applyInterestHandlers(
        address payable _userAddress,
        uint256 _marketID
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // create memory model from user model
        UserModelAssets memory _UserModelAssets;

        // create 2 var support and address for market
        bool _Support;
        address _Address;

        // make loop over all markets
        for (uint256 ID; ID < marketsLength; ID++) {
            // check support and address from manager data storage
            (_Support, _Address) = ManagerDataStorageContract.getMarketInfo(ID);

            // if market with this id is supporting
            if (_Support) {
                // create market instance
                MarketInterface _HandlerContract = MarketInterface(_Address);

                // _HandlerContract.updateRewardManagerData(_userAddress);

                // get user deposit and borrow from market
                (
                    _UserModelAssets.depositAmount,
                    _UserModelAssets.borrowAmount
                ) = _HandlerContract.updateUserMarketInterest(_userAddress);

                // get market details , what is margin call limit and borrow limit;
                _UserModelAssets.borrowLimit = _HandlerContract
                    .getMarketBorrowLimit();
                _UserModelAssets.marginCallLimit = _HandlerContract
                    .getMarketMarginCallLimit();

                // if current id for loop is math ID;
                if (ID == _marketID) {
                    // get price of asset;
                    _UserModelAssets.price = OracleContract.getTokenPrice(ID);
                    // set caller price for now
                    _UserModelAssets.callerPrice = _UserModelAssets.price;
                    // set borrow limit for now
                    _UserModelAssets.callerBorrowLimit = _UserModelAssets
                        .borrowLimit;
                }

                // if user has deposit
                if (
                    _UserModelAssets.depositAmount > 0 ||
                    _UserModelAssets.borrowAmount > 0
                ) {
                    // get price for other markets
                    if (ID != _marketID) {
                        _UserModelAssets.price = OracleContract.getTokenPrice(
                            ID
                        );
                    }

                    // if user deposit is more than 0;
                    if (_UserModelAssets.depositAmount > 0) {
                        // we mul deposit to asset price !
                        _UserModelAssets.depositAsset = _UserModelAssets
                            .depositAmount
                            .unifiedMul(_UserModelAssets.price);

                        // now calc asset borrow limit SUM ! how much user can borrow for all markets ! in $
                        _UserModelAssets
                            .depositAssetBorrowLimitSum = _UserModelAssets
                            .depositAssetBorrowLimitSum
                            .add(
                                _UserModelAssets.depositAsset.unifiedMul(
                                    _UserModelAssets.borrowLimit
                                )
                            );

                        // now get margin call limit SUM for user in all markets in $
                        _UserModelAssets.marginCallLimitSum = _UserModelAssets
                            .marginCallLimitSum
                            .add(
                                _UserModelAssets.depositAsset.unifiedMul(
                                    _UserModelAssets.marginCallLimit
                                )
                            );

                        // and this is deposit of user in all markets in $
                        _UserModelAssets.depositAssetSum = _UserModelAssets
                            .depositAssetSum
                            .add(_UserModelAssets.depositAsset);
                    }

                    // now if user borrow is more than 0 , we calc borrow sum in $ for user in all markets
                    // borrow amount * price
                    if (_UserModelAssets.borrowAmount > 0) {
                        _UserModelAssets.borrowAsset = _UserModelAssets
                            .borrowAmount
                            .unifiedMul(_UserModelAssets.price);
                        // borrow sum
                        _UserModelAssets.borrowAssetSum = _UserModelAssets
                            .borrowAssetSum
                            .add(_UserModelAssets.borrowAsset);
                    }
                }
            }
        }

        if (
            // if user can borrow ! and has liq to borrow more assets
            _UserModelAssets.depositAssetBorrowLimitSum >
            _UserModelAssets.borrowAssetSum
        ) {
            // we calc borrowable by sub already borrowd (borrowAssetSum) from depositAssetBorrowLimitSum
            _UserModelAssets.userBorrowableAsset = _UserModelAssets
                .depositAssetBorrowLimitSum
                .sub(_UserModelAssets.borrowAssetSum);

            // now after get user deposit $ user borrowable $ user borrowed $/ how much user can withdraw from platform?
            _UserModelAssets.withdrawableAsset = _UserModelAssets
                .depositAssetBorrowLimitSum
                .sub(_UserModelAssets.borrowAssetSum)
                .unifiedDiv(_UserModelAssets.callerBorrowLimit);
        }

        return (
            _UserModelAssets.userBorrowableAsset.unifiedDiv(
                _UserModelAssets.callerPrice
            ),
            _UserModelAssets.withdrawableAsset.unifiedDiv(
                _UserModelAssets.callerPrice
            ),
            _UserModelAssets.marginCallLimitSum,
            _UserModelAssets.depositAssetSum,
            _UserModelAssets.borrowAssetSum,
            _UserModelAssets.callerPrice
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////// Av.. Liquidity

    function getHowMuchUserCanBorrow(
        address payable _userAddress,
        uint256 _marketID
    ) external view returns (uint256) {
        // get user total deposit amount and user total borrow ! from all markets ! $ value ***
        uint256 _userTotalDepositAssets;
        uint256 _userTotalBorrowAssets;

        (
            _userTotalDepositAssets,
            _userTotalBorrowAssets
        ) = _getUserUpdatedParamsFromAllMarkets(_userAddress);

        // if $ value of deposit / user / is 0 , user can't borrow anythig ! so we return 0;
        if (_userTotalDepositAssets == 0) {
            return 0;
        }

        // now if $ value user deposit is more that $ value borrow user; we should make sub ! x - y = z ! z is free liq
        // now we make div on z (free liq) and $ price of this market ! for example z / 1$ dai or z / 1000$ eth;
        if (_userTotalDepositAssets > _userTotalBorrowAssets) {
            return
                _userTotalDepositAssets.sub(_userTotalBorrowAssets).unifiedDiv(
                    _getUpdatedMarketTokenPrice(_marketID)
                );
        } else {
            return 0;
        }
    }

    // this function is useful to get see how much user can borrow ! and how much is borrowed ! is $ value
    function getUserUpdatedParamsFromAllMarkets(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return _getUserUpdatedParamsFromAllMarkets(_userAddress);
    }

    function _getUserUpdatedParamsFromAllMarkets(address payable _userAddress)
        internal
        view
        returns (uint256, uint256)
    {
        // make var for total deposit and borrow ! this is $ value
        uint256 _userTotalDepositAssets;
        uint256 _userTotalBorrowAssets;

        // make loop over all markets;
        for (uint256 ID; ID < marketsLength; ID++) {
            // if id of market is supporting!
            if (ManagerDataStorageContract.getMarketSupport(ID)) {
                // get user deposit  and user borrow ; this is $ value
                uint256 _userDepositAsset;
                uint256 _userBorrowAsset;

                (
                    _userDepositAsset,
                    _userBorrowAsset
                ) = _getUpdatedInterestAmountsForUser(_userAddress, ID);

                // what is borrow limit for this market ! this is 7- % of user deposit liq;
                uint256 _marketBorrowLimit = _getMarketBorrowLimit(ID);
                // now we make mul between user deposit and market borrow limit ! for example 10$ * 70 % !
                uint256 _userDepositWithLimit = _userDepositAsset.unifiedMul(
                    _marketBorrowLimit
                );

                // we have var total deposit $ / this is $ value of deposit user in all markets; we will add _userDepositWithLimit to this var;
                // we don't need $ value of all deposit liq / we need $ value of deposit $ * borrow lim !
                _userTotalDepositAssets = _userTotalDepositAssets.add(
                    _userDepositWithLimit
                );

                // this is borrow $ value of user across all markets;
                _userTotalBorrowAssets = _userTotalBorrowAssets.add(
                    _userBorrowAsset
                );
            } else {
                continue;
            }
        }

        // at the end we will return total $ value of deposit and borrow;
        return (_userTotalDepositAssets, _userTotalBorrowAssets);
    }

    function getUpdatedInterestAmountsForUser(
        address payable _userAddress,
        uint256 _marketID
    ) external view returns (uint256, uint256) {
        return _getUpdatedInterestAmountsForUser(_userAddress, _marketID);
    }

    function _getUpdatedInterestAmountsForUser(
        address payable _userAddress,
        uint256 _marketID
    ) internal view returns (uint256, uint256) {
        // here in this function we get deposit $ and borrow $ of user !
        // get market price from chain link ;
        uint256 _marketTokenPrice = _getUpdatedMarketTokenPrice(_marketID);

        // create contract instance of market !
        MarketInterface _MarketInterface = MarketInterface(
            ManagerDataStorageContract.getMarketAddress(_marketID)
        );

        // get deposit amount and borrow amount;
        uint256 _userDepositAmount;
        uint256 _userBorrowAmount;

        (_userDepositAmount, _userBorrowAmount) = _MarketInterface
            .getUpdatedInterestAmountsForUser(_userAddress);

        // deposit $ = deposit amount * market price;
        uint256 _userDepositAssets = _userDepositAmount.unifiedMul(
            _marketTokenPrice
        );
        // borrow $ = borrow amount * market price;
        uint256 _userBorrowAssets = _userBorrowAmount.unifiedMul(
            _marketTokenPrice
        );

        // now return $ value of deposit and borrow of user from match market ;
        return (_userDepositAssets, _userBorrowAssets);
    }

    function getUserLimitsFromAllMarkets(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        uint256 _userBorrowLimitFromAllMarkets;
        uint256 _userMarginCallLimitLevel;
        (
            _userBorrowLimitFromAllMarkets,
            _userMarginCallLimitLevel
        ) = _getUserLimitsFromAllMarkets(_userAddress);
        return (_userBorrowLimitFromAllMarkets, _userMarginCallLimitLevel);
    }

    function _getUserLimitsFromAllMarkets(address payable _userAddress)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _userBorrowLimitFromAllMarkets;
        uint256 _userMarginCallLimitLevel;
        for (uint256 ID; ID < marketsLength; ID++) {
            if (ManagerDataStorageContract.getMarketSupport(ID)) {
                uint256 _userDepositForMarket;
                uint256 _userBorrowForMarket;
                (
                    _userDepositForMarket,
                    _userBorrowForMarket
                ) = _getUpdatedInterestAmountsForUser(_userAddress, ID);
                uint256 _borrowLimit = _getMarketBorrowLimit(ID);
                uint256 _marginCallLimit = _getMarketMarginCallLevel(ID);
                uint256 _userBorrowLimitAsset = _userDepositForMarket
                    .unifiedMul(_borrowLimit);
                uint256 userMarginCallLimitAsset = _userDepositForMarket
                    .unifiedMul(_marginCallLimit);
                _userBorrowLimitFromAllMarkets = _userBorrowLimitFromAllMarkets
                    .add(_userBorrowLimitAsset);
                _userMarginCallLimitLevel = _userMarginCallLimitLevel.add(
                    userMarginCallLimitAsset
                );
            } else {
                continue;
            }
        }

        return (_userBorrowLimitFromAllMarkets, _userMarginCallLimitLevel);
    }

    // here we give match market id; manager will make loop on all markets and get user free liq of user in $;
    function getUserFreeToWithdraw(
        address payable _userAddress,
        uint256 _marketID
    ) external view returns (uint256) {
        // this is total $ that user borrowed from market;
        uint256 _totalUserBorrowAssets;

        uint256 _userDepositAssetsAfterBorrowLimit;
        // user deposit $ value
        uint256 _userDepositAssets;
        // user borrow $ value;
        uint256 _userBorrowAssets;

        // we have to loop over all markets;
        for (uint256 ID; ID < marketsLength; ID++) {
            // if market with this id is supporting !
            if (ManagerDataStorageContract.getMarketSupport(ID)) {
                // we get $ value of deposit and borrow after make update in intreset param;
                (
                    _userDepositAssets,
                    _userBorrowAssets
                ) = _getUpdatedInterestAmountsForUser(_userAddress, ID);

                // we update total borrow $ value;
                _totalUserBorrowAssets = _totalUserBorrowAssets.add(
                    _userBorrowAssets
                );

                // now we multiply user deposit $ value to match market borrow lim! and add them to variable;
                _userDepositAssetsAfterBorrowLimit = _userDepositAssetsAfterBorrowLimit
                    .add(
                        _userDepositAssets.unifiedMul(_getMarketBorrowLimit(ID))
                    );
            }
        }

        if (_userDepositAssetsAfterBorrowLimit > _totalUserBorrowAssets) {
            return
                _userDepositAssetsAfterBorrowLimit
                    .sub(_totalUserBorrowAssets)
                    .unifiedDiv(_getMarketBorrowLimit(_marketID))
                    .unifiedDiv(_getUpdatedMarketTokenPrice(_marketID));
        }
        return 0;
    }

    // function updateRewardManager(address payable _userAddress)
    //     external
    //     returns (bool)
    // {
    //     if (_updateRewardParams()) {
    //         return _calcRewardParams(_userAddress);
    //     }

    //     return false;
    // }

    // function _updateRewardParams() internal returns (bool) {
    //     uint256 _currentBlockNumber = block.number;

    //     uint256 _deltaForBlocks = _currentBlockNumber -
    //         ManagerDataStorageContract.getLastTimeRewardParamsUpdated();

    //     ManagerDataStorageContract.setLastTimeRewardParamsUpdated(
    //         _currentBlockNumber
    //     );

    //     if (_deltaForBlocks == 0) {
    //         return false;
    //     }

    //     uint256 _rewardPerBlock = ManagerDataStorageContract
    //         .getcoreRewardPerBlock();
    //     uint256 _rewardDecrement = ManagerDataStorageContract
    //         .getcoreRewardDecrement();
    //     uint256 _rewardTotalAmount = ManagerDataStorageContract
    //         .getcoreTotalRewardAmounts();

    //     uint256 _timeToFinishReward = _rewardPerBlock.unifiedDiv(
    //         _rewardDecrement
    //     );

    //     if (_timeToFinishReward >= _deltaForBlocks.mul(SafeMath.unifiedPoint)) {
    //         _timeToFinishReward = _timeToFinishReward.sub(
    //             _deltaForBlocks.mul(SafeMath.unifiedPoint)
    //         );
    //     } else {
    //         return _updateRewardParamsInDataStorage(0, _rewardDecrement, 0);
    //     }

    //     if (_rewardTotalAmount >= _rewardPerBlock.mul(_deltaForBlocks)) {
    //         _rewardTotalAmount =
    //             _rewardTotalAmount -
    //             _rewardPerBlock.mul(_deltaForBlocks);
    //     } else {
    //         return _updateRewardParamsInDataStorage(0, _rewardDecrement, 0);
    //     }

    //     _rewardPerBlock = _rewardTotalAmount.mul(2).unifiedDiv(
    //         _timeToFinishReward.add(SafeMath.unifiedPoint)
    //     );
    //     /* To incentivze the update operation, the operator get paid with the
    // 	reward token */
    //     return
    //         _updateRewardParamsInDataStorage(
    //             _rewardPerBlock,
    //             _rewardDecrement,
    //             _rewardTotalAmount
    //         );
    // }

    // function _updateRewardParamsInDataStorage(
    //     uint256 _rewardPerBlock,
    //     uint256 _dcrement,
    //     uint256 _total
    // ) internal returns (bool) {
    //     ManagerDataStorageContract.setCoreRewardPerBlock(_rewardPerBlock);
    //     ManagerDataStorageContract.setCoreRewardDecrement(_dcrement);
    //     ManagerDataStorageContract.setCoreTotalRewardAmounts(_total);
    //     return true;
    // }

    // function _calcRewardParams(address payable _userAddress)
    //     internal
    //     returns (bool)
    // {
    //     uint256[] memory handlerAlphaRateBaseAsset = new uint256[](
    //         marketsLength
    //     );

    //     uint256 handlerID;
    //     uint256 alphaRateBaseGlobalAssetSum;

    //     for (uint256 ID = 1; ID <= marketsLength; ID++) {
    //         handlerAlphaRateBaseAsset[handlerID + 1] = _getAlphaBaseAsset(
    //             handlerID + 1
    //         );
    //         alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(
    //             handlerAlphaRateBaseAsset[handlerID + 1]
    //         );
    //     }

    //     handlerID = 0;

    //     for (uint256 ID = 1; ID <= marketsLength; ID++) {
    //         MarketInterface _MarketInterface = MarketInterface(
    //             ManagerDataStorageContract.getMarketAddress(ID)
    //         );

    //         _MarketInterface.updateRewardManagerData(_userAddress);

    //         _MarketInterface.updateRewardPerBlock(
    //             ManagerDataStorageContract.getcoreRewardPerBlock().unifiedMul(
    //                 handlerAlphaRateBaseAsset[handlerID + 1].unifiedDiv(
    //                     alphaRateBaseGlobalAssetSum
    //                 )
    //             )
    //         );
    //     }

    //     return true;
    // }

    // function _getAlphaBaseAsset(uint256 _handlerID)
    //     internal
    //     view
    //     returns (uint256)
    // {
    //     MarketInterface _MarketContract = MarketInterface(
    //         ManagerDataStorageContract.getMarketAddress(_handlerID)
    //     );

    //     uint256 _depositAmount = _MarketContract.getMarketDepositTotalAmount();
    //     uint256 _borrowAmount = _MarketContract.getMarketBorrowTotalAmount();

    //     uint256 _alpha = ManagerDataStorageContract.getAlphaRate();
    //     uint256 _price = _getUpdatedMarketTokenPrice(_handlerID);
    //     return
    //         _calcAlphaBaseAmount(_alpha, _depositAmount, _borrowAmount)
    //             .unifiedMul(_price);
    // }

    // function _calcAlphaBaseAmount(
    //     uint256 _alpha,
    //     uint256 _depositAmount,
    //     uint256 _borrowAmount
    // ) internal pure returns (uint256) {
    //     return
    //         _depositAmount.unifiedMul(_alpha).add(
    //             _borrowAmount.unifiedMul(SafeMath.unifiedPoint.sub(_alpha))
    //         );
    // }

    // function rewardClaimAll(address payable userAddr) external returns (bool) {
    //     uint256 claimAmountSum;
    //     for (uint256 ID = 1; ID <= marketsLength; ID++) {
    //         MarketInterface _MarketInterface = MarketInterface(
    //             ManagerDataStorageContract.getMarketAddress(ID)
    //         );

    //         _MarketInterface.updateRewardManagerData(userAddr);

    //         claimAmountSum = claimAmountSum.add(
    //             _MarketInterface.claimRewardAmountUser(userAddr)
    //         );
    //     }

    //     PersisToken.transfer(userAddr, claimAmountSum);

    //     return true;
    // }

    // function getUpdatedUserRewardAmount(address payable userAddr)
    //     external
    //     view
    //     returns (uint256)
    // {
    //     uint256 UpdatedUserRewardAmount;
    //     for (uint256 ID = 1; ID <= marketsLength; ID++) {
    //         MarketInterface _MarketInterface = MarketInterface(
    //             ManagerDataStorageContract.getMarketAddress(ID)
    //         );

    //         UpdatedUserRewardAmount = UpdatedUserRewardAmount.add(
    //             _MarketInterface.getUpdatedUserRewardAmount(userAddr)
    //         );
    //     }

    //     return UpdatedUserRewardAmount;
    // }

    // ////////////////////////////////////////////////////////////////////////////////////////////////////////// MANAGER TOOLS

    function getUpdatedMarketTokenPrice(uint256 _marketID)
        external
        view
        returns (uint256)
    {
        return _getUpdatedMarketTokenPrice(_marketID);
    }

    function _getUpdatedMarketTokenPrice(uint256 _marketID)
        internal
        view
        returns (uint256)
    {
        return (OracleContract.getTokenPrice(_marketID));
    }

    function getMarketMarginCallLevel(uint256 _marketID)
        external
        view
        returns (uint256)
    {
        return _getMarketMarginCallLevel(_marketID);
    }

    function _getMarketMarginCallLevel(uint256 _marketID)
        internal
        view
        returns (uint256)
    {
        MarketInterface _MarketInterface = MarketInterface(
            ManagerDataStorageContract.getMarketAddress(_marketID)
        );

        return _MarketInterface.getMarketMarginCallLimit();
    }

    function getMarketBorrowLimit(uint256 _marketID)
        external
        view
        returns (uint256)
    {
        return _getMarketBorrowLimit(_marketID);
    }

    function _getMarketBorrowLimit(uint256 _marketID)
        internal
        view
        returns (uint256)
    {
        MarketInterface _MarketInterface = MarketInterface(
            ManagerDataStorageContract.getMarketAddress(_marketID)
        );

        return _MarketInterface.getMarketBorrowLimit();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

/**
 * @title BiFi's safe-math Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
library SafeMath {
    uint256 internal constant unifiedPoint = 10**18;

    /******************** Safe Math********************/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "a");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "s");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "d");
    }

    function _sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require((c / a) == b, "m");
        return c;
    }

    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, unifiedPoint), b, "d");
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), unifiedPoint, "m");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ManagerData {
    address payable Owner;

    address ManagerContractAddress;
    address liquidationManagerContractAddress;

    uint256 lastTimeRewardParamsUpdated;

    struct MarketModel {
        address _marketAddress;
        bool _marketSupport;
        bool _marketExist;
    }
    mapping(uint256 => MarketModel) MarketModelMapping;

    uint256 coreRewardPerBlock;
    uint256 coreRewardDecrement;
    uint256 coreTotalRewardAmounts;

    uint256 alphaRate;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    modifier OnlyManagerContract() {
        require(msg.sender == ManagerContractAddress, "OnlyManagerContract");
        _;
    }

    constructor() {
        Owner = payable(msg.sender);

        coreRewardPerBlock = 0x478291c1a0e982c98;
        coreRewardDecrement = 0x7ba42eb3bfc;
        coreTotalRewardAmounts = (4 * 100000000) * (10**18);

        lastTimeRewardParamsUpdated = block.number;

        alphaRate = 2 * (10**17);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// SETTER FUNCTIONS

    function setManagerContractAddress(address _ManagerContractAddress)
        external
        OnlyOwner
        returns (bool)
    {
        ManagerContractAddress = _ManagerContractAddress;
        return true;
    }

    function setLiquidationManagerContractAddress(
        address _liquidationManagerContractAddress
    ) external OnlyOwner returns (bool) {
        liquidationManagerContractAddress = _liquidationManagerContractAddress;
        return true;
    }

    function setCoreRewardPerBlock(uint256 _coreRewardPerBlock)
        external
        OnlyManagerContract
        returns (bool)
    {
        coreRewardPerBlock = _coreRewardPerBlock;

        return true;
    }

    function setCoreRewardDecrement(uint256 _coreRewardDecrement)
        external
        OnlyManagerContract
        returns (bool)
    {
        coreRewardDecrement = _coreRewardDecrement;
        return true;
    }

    function setCoreTotalRewardAmounts(uint256 _coreTotalRewardAmounts)
        external
        OnlyManagerContract
        returns (bool)
    {
        coreTotalRewardAmounts = _coreTotalRewardAmounts;
        return true;
    }

    function setAlphaRate(uint256 _alphaRate) external returns (bool) {
        alphaRate = _alphaRate;
        return true;
    }

    function registerNewMarketInCore(uint256 _marketID, address _marketAddress)
        external
        OnlyManagerContract
        returns (bool)
    {
        MarketModel memory _MarketModel;
        _MarketModel._marketAddress = _marketAddress;
        _MarketModel._marketExist = true;
        _MarketModel._marketSupport = true;

        MarketModelMapping[_marketID] = _MarketModel;

        return true;
    }

    function updateMarketAddress(uint256 _marketID, address _marketAddress)
        external
        OnlyManagerContract
        returns (bool)
    {
        MarketModelMapping[_marketID]._marketAddress = _marketAddress;
        return true;
    }

    function updateMarketExist(uint256 _marketID, bool _exist)
        external
        OnlyManagerContract
        returns (bool)
    {
        MarketModelMapping[_marketID]._marketExist = _exist;
        return true;
    }

    function updateMarketSupport(uint256 _marketID, bool _support)
        external
        OnlyManagerContract
        returns (bool)
    {
        MarketModelMapping[_marketID]._marketSupport = _support;
        return true;
    }

    function setLastTimeRewardParamsUpdated(
        uint256 _lastTimeRewardParamsUpdated
    ) external returns (bool) {
        lastTimeRewardParamsUpdated = _lastTimeRewardParamsUpdated;
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// GETTERS FUNCTIONS

    function getcoreRewardPerBlock() external view returns (uint256) {
        return coreRewardPerBlock;
    }

    function getcoreRewardDecrement() external view returns (uint256) {
        return coreRewardDecrement;
    }

    function getcoreTotalRewardAmounts() external view returns (uint256) {
        return coreTotalRewardAmounts;
    }

    function getMarketInfo(uint256 _marketID)
        external
        view
        returns (bool, address)
    {
        return (
            MarketModelMapping[_marketID]._marketSupport,
            MarketModelMapping[_marketID]._marketAddress
        );
    }

    function getMarketAddress(uint256 _marketID)
        external
        view
        returns (address)
    {
        return MarketModelMapping[_marketID]._marketAddress;
    }

    function getMarketExist(uint256 _marketID) external view returns (bool) {
        return MarketModelMapping[_marketID]._marketExist;
    }

    function getMarketSupport(uint256 _marketID) external view returns (bool) {
        return MarketModelMapping[_marketID]._marketSupport;
    }

    function getAlphaRate() external view returns (uint256) {
        return alphaRate;
    }

    function getLastTimeRewardParamsUpdated() external view returns (uint256) {
        return lastTimeRewardParamsUpdated;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./OracleInterface.sol";

contract oracleProxy {
    address payable owner;

    mapping(uint256 => Oracle) oracle;

    struct Oracle {
        OracleInterface feed;
        uint256 feedUnderlyingPoint;
        bool needPriceConvert;
        uint256 priceConvertID;
    }

    uint256 constant unifiedPoint = 10**18;
    uint256 constant defaultUnderlyingPoint = 8;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address ethOracle) {
        owner = payable(msg.sender);
        _setOracleFeed(0, ethOracle, 8, false, 0);
    }

    function _setOracleFeed(
        uint256 tokenID,
        address feedAddr,
        uint256 decimals,
        bool needPriceConvert,
        uint256 priceConvertID
    ) internal returns (bool) {
        Oracle memory _oracle;
        _oracle.feed = OracleInterface(feedAddr);

        _oracle.feedUnderlyingPoint = (10**decimals);

        _oracle.needPriceConvert = needPriceConvert;

        _oracle.priceConvertID = priceConvertID;

        oracle[tokenID] = _oracle;
        return true;
    }

    function getTokenPrice(uint256 tokenID) external view returns (uint256) {
        Oracle memory _oracle = oracle[tokenID];
        // _oracle.feed.latestAnswer();
        uint256 underlyingPrice = uint256(_oracle.feed.getLatestPrice());

        uint256 unifiedPrice = _convertPriceToUnified(
            underlyingPrice,
            _oracle.feedUnderlyingPoint
        );

        if (_oracle.needPriceConvert) {
            _oracle = oracle[_oracle.priceConvertID];
            uint256 convertFeedUnderlyingPrice = uint256(
                _oracle.feed.getLatestPrice()
            );
            uint256 convertPrice = _convertPriceToUnified(
                convertFeedUnderlyingPrice,
                oracle[2].feedUnderlyingPoint
            );
            unifiedPrice = unifiedMul(unifiedPrice, convertPrice);
        }

        require(unifiedPrice != 0);
        return unifiedPrice;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function _convertPriceToUnified(uint256 price, uint256 feedUnderlyingPoint)
        internal
        pure
        returns (uint256)
    {
        return div(mul(price, unifiedPoint), feedUnderlyingPoint);
    }

    /* **************** safeMath **************** */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "div by zero");
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require((c / a) == b, "mul overflow");
        return c;
    }

    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface MarketInterface {
    function updateUserMarketInterest(address payable _userAddress)
        external
        returns (uint256, uint256);

    function getUpdatedInterestAmountsForUser(address payable _userAddress)
        external
        view
        returns (uint256, uint256);

    function getMarketMarginCallLimit() external view returns (uint256);

    function getMarketBorrowLimit() external view returns (uint256);

    function getAmounts(address payable _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getUserAmount(address payable _userAddress)
        external
        view
        returns (uint256, uint256);

    function getUserDepositAmount(address payable _userAddress)
        external
        view
        returns (uint256);

    function getUserBorrowAmount(address payable _userAddress)
        external
        view
        returns (uint256);

    function getMarketDepositTotalAmount() external view returns (uint256);

    function getMarketBorrowTotalAmount() external view returns (uint256);

    function updateRewardPerBlock(uint256 _rewardPerBlock)
        external
        returns (bool);

    function updateRewardManagerData(address payable _userAddress)
        external
        returns (bool);

    function getUpdatedUserRewardAmount(address payable _userAddress)
        external
        view
        returns (uint256);

    function claimRewardAmountUser(address payable userAddr)
        external
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface standardIERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface OracleInterface {
    function getLatestPrice() external view returns (int256);
}