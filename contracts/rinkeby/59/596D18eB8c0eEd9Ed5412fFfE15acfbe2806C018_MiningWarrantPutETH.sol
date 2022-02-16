// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Warrant.sol";

contract MiningWarrantPutETH is Warrant {
    constructor(address hive) Warrant(hive) {

    }

    function profitCurveL(uint256 /*x*/) pure external returns (uint256 y) {
        return 0;
    }

    function profitCurveS(uint256 /*x*/) pure external returns (uint256 y) {
        return 0;
    }


    function processingWaitingPayout(IWarrant.FullDealInfo storage dealInfo) internal returns (IWarrant.FullDealInfo storage) {
        IWarrant.CollectedHistory memory c = collectDataFromHistoryByLongShort(dealInfo, dealInfo.dateOrderCreation, dealInfo.dateDeliveryExpirationSideS);

        //todo
        //IWarrant.Settings memory s = _warrantSettings[dealInfo.warrantSettingsID];
        address temp = hub.getRegisteredAddress(_warrantID, "GHsOracle");
        require(temp != address(0), "Warrant: Wrong Oracle address");
        IGHsOracle oracle = IGHsOracle(temp);
        uint256 oracleAmount = oracle.getGHsAmount(block.timestamp);
        require(oracleAmount > 0, "Warrant: Oracle cannot provide the value");

        if (c.paymentShort.amount >= oracleAmount) {
            require(keccak256(abi.encode(c.depositLong.coin)) == keccak256(abi.encode(c.depositShort.coin)), "Ouch");
            temp = hub.getRegisteredAddress(_warrantID, c.depositLong.coin);
            require(temp != address(0), "Warrant: Wrong Deposit address");
            IDeposit deposit = IDeposit(temp);
            try deposit.updateBalance(dealInfo.warrantID, dealInfo.dealID, c.addressLong, 0, c.addressShort, c.depositLong.amount + c.depositShort.amount) {
            } catch Error(string memory reason) {
                revert(reason);
            }

            // require(s.coinPaymentL == s.coinPaymentS);
            temp = hub.getRegisteredAddress(_warrantID, c.paymentShort.coin);
            require(temp != address(0), "Warrant: Wrong Deposit address");
            deposit = IDeposit(temp);
            try deposit.updateBalance(dealInfo.warrantID, dealInfo.dealID, c.addressLong, oracleAmount, c.addressShort, c.paymentShort.amount - oracleAmount) {
            } catch Error(string memory reason) {
                revert(reason);
            }

            hub.setWithdrawAllowed(dealInfo.warrantID, dealInfo.dealID, true);
            dealInfo.status = IWarrant.DEAL_STATE.Completed;
        } else if (dealInfo.dateDeliveryExpirationSideS <= block.timestamp) {
            // payout fail
            require(keccak256(abi.encode(c.depositLong.coin)) == keccak256(abi.encode(c.depositShort.coin)), "Ouch");
            temp = hub.getRegisteredAddress(_warrantID, c.depositLong.coin);
            require(temp != address(0), "Warrant: Wrong Deposit address");
            IDeposit deposit = IDeposit(temp);
            try deposit.updateBalance(dealInfo.warrantID, dealInfo.dealID, c.addressLong, c.depositLong.amount + c.depositShort.amount, c.addressShort, 0) {
            } catch Error(string memory reason) {
                revert(reason);
            }

            hub.setWithdrawAllowed(dealInfo.warrantID, dealInfo.dealID, true);
            dealInfo.status = IWarrant.DEAL_STATE.Completed;
        }

        return dealInfo;
    }

    function processing(uint256 dealID) external {
        IWarrant.FullDealInfo storage dealInfo = _deals[dealID];
        require(dealInfo.dealID != 0, "Warrant: Wrong dealID");

        if (dealInfo.status == IWarrant.DEAL_STATE.Created && dealInfo.dateOrderExpiration <= block.timestamp) {
            dealInfo.status = IWarrant.DEAL_STATE.Canceled;
            hub.setWithdrawAllowed(dealInfo.warrantID, dealID, true);
        }

        if (dealInfo.status == IWarrant.DEAL_STATE.Accepted && dealInfo.dateStart <= block.timestamp) {
            dealInfo.status = IWarrant.DEAL_STATE.Working;
        }

        if (dealInfo.status == IWarrant.DEAL_STATE.Working && dealInfo.dateExpiration <= block.timestamp) {
            dealInfo.status = IWarrant.DEAL_STATE.WaitingPayout;
        }

        if (dealInfo.status == IWarrant.DEAL_STATE.WaitingPayout) {
            dealInfo = processingWaitingPayout(dealInfo);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IHiVHub.sol";
import "./IWarrant.sol";
import "./IGHsOracle.sol";
import "./IDeposit.sol";

abstract contract Warrant is IWarrant {
    using SafeMath for uint256;

    // warrantSettingsID => struct
    mapping(uint256 => IWarrant.Settings) internal _warrantSettings;
    // dealID => struct
    mapping(uint256 => IWarrant.FullDealInfo) internal _deals;
    // dealID => user, timestamp, depositKey, amount
    mapping(uint256 => IWarrant.HistoryRecord[]) internal _history;
    IWarrant.BasicSettings internal _basic;

    uint256 internal _warrantID;

    IHiVHub internal hub;

    constructor(address hive) {
        //, IWarrant.BasicSettings memory basic
        hub = IHiVHub(hive);
    }

    function setHub(address _hub) external {
        require(msg.sender == address(hub), "Warrant: Wrong sender");
        require(_hub != address(0), "Warrant: Hub can not be empty");

        hub = IHiVHub(_hub);
    }

    function setBasicSettings(IWarrant.BasicSettings memory basic) external {
        _basic = basic;
    }

    function setWarrantID(uint256 warrantID) external {
        // We check warrantID uniqueness in Hub
        require(
            msg.sender == address(hub),
            "Warrant: Only Hub can set this value"
        );
        _warrantID = warrantID;
    }

    function getDealInfo(uint256 dealID)
        external
        view
        returns (IWarrant.FullDealInfo memory)
    {
        return _deals[dealID];
    }

    function createWarrantSettings(IWarrant.Settings memory s)
        external
        returns (uint256)
    {
        //TODO Anyone can do it?
        uint256 settingID = hub.register(
            _warrantID,
            "settings",
            "",
            address(this),
            true
        );
        _warrantSettings[settingID] = s;
        emit CreateSettings(address(this), msg.sender, settingID);
        return settingID;
    }

    function getWarrantSettings(uint256 warrantSettingsID)
        external
        view
        returns (IWarrant.Settings memory)
    {
        return _warrantSettings[warrantSettingsID];
    }

    function processPosition(
        IWarrant.FullDealInfo storage dealInfo,
        IWarrant.Settings memory s,
        uint256 amount,
        IWarrant.POSITION position
    ) internal returns (address) {
        address deposit;

        if (position == IWarrant.POSITION.Long) {
            deposit = hub.getRegisteredAddress(
                dealInfo.warrantID,
                s.coinDepositL
            );
            dealInfo.depositLAmount = amount;
            if (!_basic.isStepL) {
                //TODO check this logic
                require(
                    dealInfo.dealSettings.depositLPercent <=
                        dealInfo.depositLAmount.mul(1e18).div(
                            dealInfo
                                .dealSettings
                                .price
                                .mul(dealInfo.dealSettings.count)
                                .div(1e18)
                        ),
                    "Warrant: Deposit amount is too small"
                );
            }
        } else {
            deposit = hub.getRegisteredAddress(
                dealInfo.warrantID,
                s.coinDepositS
            );
            dealInfo.depositSAmount = amount;
            if (!_basic.isStepS) {
                //TODO check this logic
                require(
                    dealInfo.dealSettings.depositSPercent <=
                        dealInfo.depositSAmount.mul(1e18).div(
                            dealInfo
                                .dealSettings
                                .price
                                .mul(dealInfo.dealSettings.count)
                                .div(1e18)
                        ),
                    "Warrant: Deposit amount is too small"
                );
            }
        }

        return deposit;
    }

    function newDeal(
        address sender,
        uint256 warrantSettingsID,
        DealBasicSettings memory dealSettings,
        uint256 amount
    ) external returns (uint256) {
        IWarrant.Settings memory s = _warrantSettings[warrantSettingsID];
        require(s.period != 0, "Warrant: Wrong warrantSettingsID");

        uint256 dealID = hub.register(
            _warrantID,
            "deal",
            "",
            address(this),
            true
        );

        //TODO set correct values
        IWarrant.FullDealInfo memory dealInfo = IWarrant.FullDealInfo(
            _warrantID, //warrantID
            warrantSettingsID, //warrantSettingsID
            dealID, //dealID
            dealSettings, //dealSettings
            sender, // makerAddress
            address(0), // takerAddress
            IWarrant.DEAL_STATE.Created, // status
            0, // oracleAmount;
            0, // depositLAmount;
            0, // depositSAmount;
            0, // depositMax;
            dealSettings.depositLPercent == dealSettings.depositSPercent, // isSymmetrical;
            block.timestamp, // dateOrderCreation;
            block.timestamp + dealSettings.periodOrderExpiration, // dateOrderExpiration;
            0, // dateTake;
            0, // dateStart;
            0, // dateExpiration;
            0, // dateOracle;
            0, // dateDeliveryExpirationSideL;
            0, // dateDeliveryExpirationSideS;
            0, // payoutL;
            0, // payoutS;
            0, // resultL;
            0 // resultS;
        );

        _deals[dealID] = dealInfo;

        address deposit = processPosition(
            _deals[dealID],
            s,
            amount,
            dealSettings.makerPosition
        );
        require(
            msg.sender == deposit,
            "Warrant: Only Deposit can create new deal"
        );

        hub.setWithdrawAllowed(_warrantID, dealID, false); //TODO do we need this?
        if (dealInfo.dealSettings.makerPosition == IWarrant.POSITION.Long) {
            _history[dealID].push(
                IWarrant.HistoryRecord(
                    sender,
                    block.timestamp,
                    s.coinDepositL,
                    amount
                )
            );
        } else {
            _history[dealID].push(
                IWarrant.HistoryRecord(
                    sender,
                    block.timestamp,
                    s.coinDepositS,
                    amount
                )
            );
        }

        return dealID;
    }

    function takeDeal(
        address sender,
        uint256 dealID,
        uint256 amount
    ) external {
        IWarrant.FullDealInfo storage dealInfo = _deals[dealID];
        require(dealInfo.dealID != 0, "Warrant: Wrong dealID"); // Here we check if dealInfo exists
        require(sender != dealInfo.makerAddress, "Warrant: Wrong sender");
        IWarrant.Settings memory s = _warrantSettings[
            dealInfo.warrantSettingsID
        ];
        require(
            dealInfo.status == IWarrant.DEAL_STATE.Created,
            "Warrant: Deal must have status Created"
        );

        address deposit;
        if (dealInfo.dealSettings.makerPosition == IWarrant.POSITION.Long) {
            deposit = processPosition(
                dealInfo,
                s,
                amount,
                IWarrant.POSITION.Short
            );
        } else {
            deposit = processPosition(
                dealInfo,
                s,
                amount,
                IWarrant.POSITION.Long
            );
        }
        require(msg.sender == deposit, "Warrant: Only Deposit can take deal");
        require(
            dealInfo.dateOrderExpiration > block.timestamp,
            "Warrant: Too late"
        );

        dealInfo.takerAddress = sender;
        dealInfo.dateTake = block.timestamp;
        dealInfo.dateStart =
            dealInfo.dateOrderCreation +
            dealInfo.dealSettings.periodOrderExpiration;
        dealInfo.dateExpiration = dealInfo.dateStart + s.period;
        dealInfo.dateDeliveryExpirationSideL =
            dealInfo.dateExpiration +
            s.periodDeliverySideL;
        dealInfo.dateDeliveryExpirationSideS =
            dealInfo.dateExpiration +
            s.periodDeliverySideS;
        dealInfo.status = IWarrant.DEAL_STATE.Accepted;

        if (dealInfo.dealSettings.makerPosition == IWarrant.POSITION.Long) {
            _history[dealID].push(
                IWarrant.HistoryRecord(
                    sender,
                    block.timestamp,
                    s.coinDepositL,
                    amount
                )
            );
        } else {
            _history[dealID].push(
                IWarrant.HistoryRecord(
                    sender,
                    block.timestamp,
                    s.coinDepositS,
                    amount
                )
            );
        }
    }

    function cancelDeal(address sender, uint256 dealID) external {
        IWarrant.FullDealInfo storage dealInfo = _deals[dealID];
        require(dealInfo.dealID != 0, "Warrant: Wrong dealID");
        IWarrant.Settings memory s = _warrantSettings[
            dealInfo.warrantSettingsID
        ];

        address deposit;

        if (sender == dealInfo.makerAddress) {
            if (
                sender == dealInfo.makerAddress &&
                dealInfo.dealSettings.makerPosition == IWarrant.POSITION.Long
            ) {
                deposit = hub.getRegisteredAddress(
                    dealInfo.warrantID,
                    s.coinDepositL
                );
            } else {
                deposit = hub.getRegisteredAddress(
                    dealInfo.warrantID,
                    s.coinDepositS
                );
            }
        } else {
            revert("Warrant: Wrong sender");
        }

        require(
            msg.sender == deposit,
            "Warrant: Only Deposit can cancel the deal"
        );
        require(
            dealInfo.status == IWarrant.DEAL_STATE.Created,
            "Warrant: Wrong deal status"
        );
        dealInfo.status = IWarrant.DEAL_STATE.Canceled;
        hub.setWithdrawAllowed(dealInfo.warrantID, dealID, true);
    }

    function addDepositHistory(
        uint256 dealID,
        address sender,
        uint256 timestamp,
        string memory coin,
        uint256 amount
    ) external {
        IWarrant.FullDealInfo storage dealInfo = _deals[dealID];
        require(dealInfo.dealID != 0, "Warrant: Wrong dealID");
        require(
            sender == dealInfo.makerAddress || sender == dealInfo.takerAddress,
            "Warrant: Wrong sender"
        );

        IWarrant.Settings memory s = _warrantSettings[
            dealInfo.warrantSettingsID
        ];
        address deposit1 = hub.getRegisteredAddress(
            dealInfo.warrantID,
            s.coinDepositL
        );
        address deposit2 = hub.getRegisteredAddress(
            dealInfo.warrantID,
            s.coinDepositS
        );
        address deposit3 = hub.getRegisteredAddress(
            dealInfo.warrantID,
            s.coinPaymentL
        );
        address deposit4 = hub.getRegisteredAddress(
            dealInfo.warrantID,
            s.coinPaymentS
        );
        require(
            msg.sender == deposit1 ||
                msg.sender == deposit2 ||
                msg.sender == deposit3 ||
                msg.sender == deposit4,
            "Warrant: Only Deposit can top up the deal"
        );

        _history[dealID].push(
            IWarrant.HistoryRecord(sender, timestamp, coin, amount)
        );
    }

    function getDepositHistory(uint256 dealID)
        external
        view
        returns (IWarrant.HistoryRecord[] memory)
    {
        return _history[dealID];
    }

    function collectDataFromHistoryByLongShort(
        IWarrant.FullDealInfo storage dealInfo,
        uint256 dateStart,
        uint256 dateEnd
    ) internal view returns (IWarrant.CollectedHistory memory) {
        IWarrant.Settings memory s = _warrantSettings[
            dealInfo.warrantSettingsID
        ];
        IWarrant.HistoryRecord[] memory history = _history[dealInfo.dealID];
        IWarrant.CollectedHistory memory c = IWarrant.CollectedHistory(
            IWarrant.DepositRecord(s.coinDepositL, 0),
            IWarrant.DepositRecord(s.coinDepositS, 0),
            IWarrant.DepositRecord(s.coinPaymentL, 0),
            IWarrant.DepositRecord(s.coinPaymentS, 0),
            address(0),
            address(0)
        );
        if (dealInfo.dealSettings.makerPosition == IWarrant.POSITION.Long) {
            c.addressLong = dealInfo.makerAddress;
            c.addressShort = dealInfo.takerAddress;
        } else {
            c.addressLong = dealInfo.takerAddress;
            c.addressShort = dealInfo.makerAddress;
        }

        for (uint256 i = 0; i < history.length; i++) {
            if (
                history[i].timestamp >= dateStart &&
                history[i].timestamp <= dateEnd
            ) {
                if (history[i].sender == c.addressLong) {
                    if (
                        keccak256(abi.encode(history[i].coin)) ==
                        keccak256(abi.encode(c.depositLong.coin))
                    ) {
                        c.depositLong.amount = c.depositLong.amount.add(
                            history[i].amount
                        );
                    } else if (
                        keccak256(abi.encode(history[i].coin)) ==
                        keccak256(abi.encode(c.paymentLong.coin))
                    ) {
                        c.paymentLong.amount = c.paymentLong.amount.add(
                            history[i].amount
                        );
                    }
                }
                if (history[i].sender == c.addressShort) {
                    if (
                        keccak256(abi.encode(history[i].coin)) ==
                        keccak256(abi.encode(c.depositShort.coin))
                    ) {
                        c.depositShort.amount = c.depositShort.amount.add(
                            history[i].amount
                        );
                    } else if (
                        keccak256(abi.encode(history[i].coin)) ==
                        keccak256(abi.encode(c.paymentShort.coin))
                    ) {
                        c.paymentShort.amount = c.paymentShort.amount.add(
                            history[i].amount
                        );
                    }
                }
            }
        }

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWarrant {
    event CreateSettings(address indexed warrant, address indexed sender, uint256 settingsID);

    enum DEAL_STATE {Created, Accepted, Working, WaitingPayout, Completed, Canceled}
    enum SIDE {Maker, Taker}
    enum POSITION {Short, Long}

    struct BasicSettings {
        string deliveryType;
        uint256[] basePointsList;
        bool isStepL;
        bool isStepS;
        bool hasProfitCurveL;
        bool hasProfitCurveS;
    }

    struct Settings {
        string underlyingAsset; // not used
        string coinUnderlyingAssetAxis; // not used
        string coinOfContract; // not used
        string coinDepositL;
        string coinDepositS;
        string coinPaymentL;
        string coinPaymentS;
        uint256 period;
        uint256 periodDeliverySideL;
        uint256 periodDeliverySideS;
    }

    struct DealBasicSettings {
        uint256 price;
        uint256 count;
        uint256 depositLPercent; // 100% = 1e18
        uint256 depositSPercent;
        uint256 periodOrderExpiration;
        POSITION makerPosition;
        bool isStandard;
    }

    struct FullDealInfo {
        uint256 warrantID;
        uint256 warrantSettingsID;
        uint256 dealID;
        DealBasicSettings dealSettings;
        address makerAddress;
        address takerAddress;
        DEAL_STATE status;

        uint256 oracleAmount;
        uint256 depositLAmount;
        uint256 depositSAmount;
        uint256 depositMax;
        bool isSymmetrical;
        uint256 dateOrderCreation;
        uint256 dateOrderExpiration;
        uint256 dateTake;
        uint256 dateStart;
        uint256 dateExpiration;
        uint256 dateOracle;
        uint256 dateDeliveryExpirationSideL;
        uint256 dateDeliveryExpirationSideS;
        uint256 payoutL;
        uint256 payoutS;
        uint256 resultL;
        uint256 resultS;
    }
//  1,1,4,30000000000000000000,1000000000000000000,1000000000000000000,150000000000000000,604800,1,true,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,1,0,30000000000000000000,4500000000000000000,0,false,1644859708,1645464508,1644860066,1645464508,1645464808,0,1645465408,1645465408,0,0,0,0

    struct HistoryRecord {
        address sender;
        uint256 timestamp;
        string coin;
        uint256 amount;
    }

    struct DepositRecord {
        string coin;
        uint256 amount;
    }

    struct CollectedHistory {
        IWarrant.DepositRecord depositLong;
        IWarrant.DepositRecord depositShort;
        IWarrant.DepositRecord paymentLong;
        IWarrant.DepositRecord paymentShort;
        address addressLong;
        address addressShort;
    }

    function getWarrantSettings(uint256 warrantSettingsID) view external returns (IWarrant.Settings memory);

    function newDeal(address sender, uint256 warrantSettingsID, DealBasicSettings memory sealSettings, uint256 amount) external returns(uint256);

    function takeDeal(address sender, uint256 dealID, uint256 amount) external;

    function getDealInfo(uint256 dealID) view external returns (IWarrant.FullDealInfo memory);

    function setWarrantID(uint256 warrantID) external;

    function profitCurveL(uint256 x) view external returns (uint256 y);

    function profitCurveS(uint256 x) view external returns (uint256 y);

    function processing(uint256 dealID) external;

    function addDepositHistory(uint256 dealID, address sender, uint256 timestamp, string memory coin, uint256 amount) external;

    function cancelDeal(address sender, uint256 dealID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IHiVHub {
    struct RegisteredObject {
        string key;
        string comment;
        uint256 warrantID;
        address value;
        bool status;
    }
    function registerWarrant(uint256 warrantID, address warrant) external;
    function getWarrant(uint256 warrantID) external returns(address);
    function register(uint256 warrantID, string memory key, string memory comment, address warrant, bool status) external returns(uint256);
    function getRegister(uint256 dealID) external returns(IHiVHub.RegisteredObject memory);
    function registerAddress(uint256 warrantID, string memory key, address object) external;
    function getRegisteredAddress(uint256 warrantID, string memory key) view external returns (address);
    function isWithdrawAllowed(uint256 warrantID, uint256 dealID) view external returns (bool);
    function setWithdrawAllowed(uint256 warrantID, uint256 dealID, bool allow) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGHsOracle {
    // function alignTimestamp(uint256 timestamp, uint256 step) pure internal returns (uint256);
    function getGHsAmount(uint256 timestamp) view external returns (uint256);
    function getGHsAmountByInterval(uint256 timestamp1, uint256 timestamp2) view external returns (uint256);
    function setGHsAmount(uint256 price, uint256 timestamp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IWarrant.sol";

interface IDeposit {
    event DepositEvent(address indexed sender, uint256 amount);
    event DealDepositEvent(address indexed sender, uint256 warrantID, uint256 dealID, uint256 amount, bytes32 key);
    event DealCancelEvent(address indexed sender, uint256 warrantID, uint256 dealID, uint256 amount, bytes32 key);
    event DealWithdrawEvent(address indexed sender, uint256 warrantID, uint256 dealID, uint256 amount, bytes32 key);
    event WithdrawEvent(address indexed sender, uint256 amount);

    function getTokenAddress() view external returns (address);
    function depositToMakeDeal(uint256 warrantID, uint256 warrantSettingsID, IWarrant.DealBasicSettings memory dealSettings, uint256 amount) external payable;
    function depositToTakeDeal(uint256 warrantID, uint256 dealID, uint256 amount) external payable;
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 warrantID, uint256 dealID) external;
    function updateBalance(uint256 warrantID, uint256 dealID, address addr1, uint256 amount1, address addr2, uint256 amount2) external;
    function getBalanceByDeal(uint256 warrantID, uint256 dealID, address sender) view external returns (uint256);
    function getBalanceByUser(address sender) view external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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