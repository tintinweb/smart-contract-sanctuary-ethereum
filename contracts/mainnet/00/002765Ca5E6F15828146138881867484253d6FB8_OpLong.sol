// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";
import {ProtocolAaveV2Interface} from "../protocol/interface/IProtocolAaveV2.sol";
import {ProtocolERC20Interface} from "../protocol/interface/IProtocolERC20.sol";
import {OperationCenterInterface} from "../interfaces/IOperationCenter.sol";
import {AccountCenterInterface} from "../interfaces/IAccountCenter.sol";
import {EventCenterLeveragePositionInterface} from "../interfaces/IEventCenterLeveragePosition.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ProtocolCenterInterface {
    function getProtocol(string memory protocolName)
        external
        view
        returns (address protocol);
}

interface ConnectorAaveV2Interface {
    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable;
}

interface ConnectorCenterInterface {
    function getConnector(string calldata connectorNames)
        external
        view
        returns (bool, address);
}

interface EventCenterInterface {
    function emitAddMarginEvent(
        address collateralToken,
        uint256 amountCollateralToken
    ) external;
}

struct Token {
    address token;
    string symbol;
}

interface TokenCenterInterface {
    function listLongToken() external view returns (Token[] memory tokenList);

    function isLongable(address token) external view returns (bool longable);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata _spells
    ) external returns (bool);
}

contract OpLong is OpCommon {
    using SafeERC20 for IERC20;

    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable lender;
    address public immutable opCenterAddress;
    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    AaveLendingPoolProviderInterface internal constant aaveProvider =
        AaveLendingPoolProviderInterface(
            0x88757f2f99175387aB4C6a4b3067c77A695b0349
        );

    constructor(address _opCenterAddress, address _lender) {
        lender = _lender;
        opCenterAddress = _opCenterAddress;
    }

    function openLong(
        address leverageToken,
        address targetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        bool _isLongable = TokenCenterInterface(
            OperationCenterInterface(opCenterAddress).tokenCenterAddress()
        ).isLongable(targetToken);
        require(
            _isLongable,
            "CHFY: target token not support to do longleverage"
        );

        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        (bool success, ) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("ERC20").delegatecall(
                abi.encodeWithSignature(
                    "push(address,uint256)",
                    leverageToken,
                    amountLeverageToken
                )
            );

        require(success == true, "CHFRY: push coin fail");

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

        operation = 1;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function closeLong(
        address leverageToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth{
        require(
            rateMode == 1 || rateMode == 2,
            "CHFRY: rateMode should be 1 or 2"
        );

        bool isLastPosition = true;

        bool success;
        bytes memory _data;
        Token[] memory tokenList = TokenCenterInterface(
            OperationCenterInterface(opCenterAddress).tokenCenterAddress()
        ).listLongToken();

        for (uint256 i = 0; i < tokenList.length; i++) {
            if (
                tokenList[i].token != targetToken &&
                tokenList[i].token != address(0)
            ) {
                (success, _data) = ProtocolCenterInterface(
                    OperationCenterInterface(opCenterAddress)
                        .protocolCenterAddress()
                ).getProtocol("AAVEV2").delegatecall(
                        abi.encodeWithSignature(
                            "getCollateralBalance(address)",
                            tokenList[i].token
                        )
                    );

                require(
                    success == true,
                    "CHFRY: call AAVEV2 protocol getCollateralBalance fail 2"
                );
                if (abi.decode(_data, (uint256)) != 0) {
                    isLastPosition = false;
                    break;
                }
            }
        }

        (success, _data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getPaybackBalance(address,uint256)",
                    leverageToken,
                    2
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getPaybackBalance fail"
        );

        uint256 amountLeverageTokenBorrow = abi.decode(_data, (uint256));

        if (
            isLastPosition == true ||
            (amountFlashLoan > amountLeverageTokenBorrow)
        ) {
            amountFlashLoan = amountLeverageTokenBorrow;
        }

        uint8 operation;
        bytes memory arguments;
        bytes memory data;

        operation = 2;

        arguments = abi.encode(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountFlashLoan,
            isLastPosition,
            unitAmt,
            rateMode
        );

        data = abi.encode(operation, arguments);
        _flash(leverageToken, amountFlashLoan, data);
    }

    function cleanLong(
        address leverageToken,
        address targetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) public payable onlyAuth {

        (bool success, bytes memory _data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getCollateralBalance(address)",
                    targetToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getCollateralBalance fail 1"
        );

        uint256 amountTargetToken = abi.decode(_data, (uint256));

        closeLong(
            leverageToken,
            targetToken,
            amountTargetToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );
    }

    function repay(address paybackToken) external payable onlyAuth {
        bool success;
        bytes memory data;
        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getPaybackBalance(address,uint256)",
                    paybackToken,
                    2
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getPaybackBalance fail"
        );

        uint256 amountPaybackToken = abi.decode(data, (uint256));

        if (amountPaybackToken > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "push(address,uint256)",
                        paybackToken,
                        amountPaybackToken
                    )
                );

            require(success == true, "CHFRY: push token fail");

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "paybackToken(address,uint256,uint256)",
                        paybackToken,
                        amountPaybackToken,
                        2
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 paybackToken fail");
            EventCenterLeveragePositionInterface(
                OperationCenterInterface(opCenterAddress).eventCenterAddress()
            ).emitRepayEvent(paybackToken, amountPaybackToken);
        }
    }

    function withdraw(address collateralToken) external payable onlyAuth{
        bool success;
        bytes memory data;

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "getCollateralBalance(address)",
                    collateralToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol getCollateralBalance of leverageToken fail "
        );

        if (abi.decode(data, (uint256)) > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "withdrawToken(address,uint256)",
                        collateralToken,
                        type(uint256).max
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 withdrawToken fail 2");

            uint256 amountWithDraw = abi.decode(data, (uint256));

            address EOA = AccountCenterInterface(accountCenter).getEOA(
                address(this)
            );

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        collateralToken,
                        amountWithDraw,
                        EOA
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
            EventCenterLeveragePositionInterface(
                OperationCenterInterface(opCenterAddress).eventCenterAddress()
            ).emitWithDrawEvent(collateralToken, amountWithDraw);
        }
    }

    function addMargin(address collateralToken, uint256 amountCollateralToken)
        external
        payable
        onlyAuth
    {

        (bool success, bytes memory data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("ERC20").delegatecall(
                abi.encodeWithSignature(
                    "push(address,uint256)",
                    collateralToken,
                    amountCollateralToken
                )
            );

        require(success == true, "CHFRY: push token fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    collateralToken,
                    amountCollateralToken
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol depositToken fail"
        );

        EventCenterInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitAddMarginEvent(collateralToken, amountCollateralToken);
    }

    function _flash(
        address token,
        uint256 amount,
        bytes memory data
    ) internal {

        uint256 allowance = IERC20(token).allowance(
            address(this),
            address(lender)
        );
        
        uint256 fee = IERC3156FlashLender(lender).flashFee(token, amount);

        (bool notOverflow, uint256 repayment) = SafeMath.tryAdd(amount, fee);
        require(notOverflow == true, "CHFRY: overflow");

        (notOverflow, allowance) = SafeMath.tryAdd(allowance, repayment);
        require(notOverflow == true, "CHFRY: overflow");

        IERC20(token).approve(address(lender), allowance);

        IERC3156FlashLender(lender).flashLoan(
            address(this),
            token,
            amount,
            data
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable returns (bytes32) {
        require(msg.sender == address(lender), "onFlashLoan: Untrusted lender");

        require(
            initiator == address(this),
            "onFlashLoan: Untrusted loan initiator"
        );

        uint8 operation;
        bytes memory arguments;

        flashInitiator = initiator;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;

        (operation, arguments) = abi.decode(data, (uint8, bytes));

        if (operation == uint8(1)) {
            handleOpenLong(arguments);
        } else if (operation == uint8(2)) {
            handleCloseLong(arguments);
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitUseFlashLoanForLeverageEvent(token, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function handleOpenLong(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 pay;

        bool success;
        bytes memory data;

        (
            address leverageToken,
            address targetToken,
            uint256 amountLeverageToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256)
            );

        (notOverflow, pay) = SafeMath.tryAdd(
            amountLeverageToken,
            amountFlashLoan
        );

        require(notOverflow == true, "CHFRY: overflow 1");

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (notOverflow, _temp) = SafeMath.trySub(pay, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 2");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    targetToken,
                    leverageToken,
                    _temp,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 sellToken fail");

        uint256 buyAmount = abi.decode(data, (uint256));

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    targetToken,
                    buyAmount
                )
            );

        require(success == true, "CHFRY: call AAVEV2 depositToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "borrowToken(address,uint256,uint256)",
                    leverageToken,
                    amountFlashLoan,
                    rateMode
                )
            );
        require(success == true, "CHFRY: call AAVEV2 borrowToken fail");

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitOpenLongLeverageEvent(
                leverageToken,
                targetToken,
                pay,
                buyAmount,
                amountLeverageToken,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleCloseLong(bytes memory arguments) internal {
        uint256 _temp;
        uint256 gain;
        bool notOverflow;
        bool success;
        bytes memory data;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountFlashLoan,
            bool isLastPosition,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, bool, uint256, uint256)
            );

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        if (amountFlashLoan > 0) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "paybackToken(address,uint256,uint256)",
                        leverageToken,
                        amountFlashLoan,
                        rateMode
                    )
                );
            require(success == true, "CHFRY: call AAVEV2 paybackToken fail");
        }

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "withdrawToken(address,uint256)",
                    targetToken,
                    amountTargetToken
                )
            );

        require(success == true, "CHFRY: call AAVEV2 withdrawToken fail 1");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    leverageToken,
                    targetToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 protocol fail");

        gain = abi.decode(data, (uint256));

        (notOverflow, gain) = SafeMath.trySub(gain, flashLoanFee);

        require(notOverflow == true, "CHFRY: gain not cover flashLoanFee");

        if (isLastPosition == true) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("AAVEV2").delegatecall(
                    abi.encodeWithSignature(
                        "getCollateralBalance(address)",
                        leverageToken
                    )
                );

            require(
                success == true,
                "CHFRY: call AAVEV2 protocol getCollateralBalance of leverageToken fail "
            );

            if (abi.decode(data, (uint256)) > 0) {
                (success, data) = ProtocolCenterInterface(
                    OperationCenterInterface(opCenterAddress)
                        .protocolCenterAddress()
                ).getProtocol("AAVEV2").delegatecall(
                        abi.encodeWithSignature(
                            "withdrawToken(address,uint256)",
                            leverageToken,
                            type(uint256).max
                        )
                    );
                require(
                    success == true,
                    "CHFRY: call AAVEV2 withdrawToken fail 2"
                );

                uint256 amountWithDraw = abi.decode(data, (uint256));

                EventCenterLeveragePositionInterface(
                    OperationCenterInterface(opCenterAddress)
                        .eventCenterAddress()
                ).emitRemoveMarginEvent(leverageToken, amountWithDraw);

                (notOverflow, _temp) = SafeMath.tryAdd(gain, amountWithDraw);
                require(notOverflow == true, "CHFRY: overflow");

                (notOverflow, _temp) = SafeMath.trySub(_temp, amountFlashLoan);

                require(notOverflow == true, "CHFRY: gain not cover flashloan");
            } else {
                (notOverflow, _temp) = SafeMath.trySub(gain, amountFlashLoan);
                require(notOverflow == true, "CHFRY: gain not cover flashloan");
            }
        } else {
            (notOverflow, _temp) = SafeMath.trySub(gain, amountFlashLoan);
            require(notOverflow == true, "CHFRY: gain not cover flashloan");
        }

        if (_temp > uint256(0)) {
            address EOA = AccountCenterInterface(accountCenter).getEOA(
                address(this)
            );

            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        EOA
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitCloseLongLeverageEvent(
                leverageToken,
                targetToken,
                gain,
                amountTargetToken,
                amountFlashLoan,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function getUserAccountData()
        internal
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        (
            totalCollateralETH,
            totalDebtETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = aave.getUserAccountData(address(this));
    }
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface AaveInterface {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function setUserUseReserveAsCollateral(
        address _asset,
        bool _useAsCollateral
    ) external;

    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    address internal accountCenter;

    receive() external payable {}

    modifier onlyAuth() {
        require(_auth[msg.sender], "CHFRY: Permission Denied");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolAaveV2Interface {
    function depositToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function withdrawToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function borrowToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function paybackToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function enableTokenCollateral(address[] calldata tokens) external payable;

    function swapTokenBorrowRateMode(address token, uint256 rateMode)
        external
        payable;

    function getPaybackBalance(address token, uint256 rateMode)
        external
        view
        returns (uint256);

    function getCollateralBalance(address token)
        external
        view
        returns (uint256 bal);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolERC20Interface {
    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external payable returns (uint256 _amt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OperationCenterInterface {
    function eventCenterAddress() external view returns (address);
    function connectorCenterAddress() external view returns (address);
    function tokenCenterAddress() external view returns (address);
    function protocolCenterAddress() external view returns (address);
    function getOpCodeAddress(bytes4 _sig) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account)
        external
        view
        returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface EventCenterLeveragePositionInterface {
    // function emitCreateAccountEvent(address EOA, address account) external;

    function epochRound() external view returns (uint256);

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external;

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external;

    function emitRemoveMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external;

    function startEpoch(uint256 _rewardAmount) external;

    function isInRewardEpoch() external view returns (bool);

    function emitWithDrawEvent(address token, uint256 amount) external;

    function emitRepayEvent(address token, uint256 amount) external;

    function emitReleasePositionRewardEvent(
        address owner,
        uint256 epochRound,
        bytes32 merkelRoot
    ) external;

    function emitClaimPositionRewardEvent(
        address EOA,
        uint256 epochRound,
        uint256 amount
    ) external;

    function emitClaimOpenAccountRewardEvent(
        address EOA,
        address account,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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