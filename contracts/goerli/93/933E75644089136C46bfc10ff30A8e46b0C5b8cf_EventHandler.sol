// SPDX-License-Identifier: WISE

import "./EventHelper.sol";

pragma solidity =0.8.19;

error NotWiseLending();
error NotSelf();
error AlreadySet();

contract EventHandler is EventHelper {

    receive()
        external
        payable
    {
        // maybe some event
        // maybe some default action
    }

    event FundsDeposited(
        uint256 indexed nftId,
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyDeposited(
        address indexed user,
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawnOnBehalf(
        address indexed user,
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsSolelyWithdrawnOnBehalf(
        address indexed user,
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed borrower,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowedOnBehalf(
        address indexed borrower,
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed user,
        address indexed caller,
        address indexed token,
        uint256 totalPayment,
        uint256 totalPaymentShares,
        uint256 timestamp
    );

    event FundsReturnedWithLendingShares(
        address indexed user,
        address indexed caller,
        address indexed token,
        uint256 totalPayment,
        uint256 totalPaymentShares,
        uint256 timestamp
    );

    event CollateralizeDeposit(
        address user,
        address token,
        uint256 timestamp
    );

    event DecollateralizeDeposit(
        address user,
        address token,
        uint256 timestamp
    );

    event ApproveWithdraw(
        address indexed user,
        address indexed spender,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event ApproveBorrow(
        address indexed user,
        address indexed spender,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event PoolSynced(
        address pool,
        uint256 timestamp
    );

    event IsolationPoolVeryfied(
        address isolationContractAddress,
        uint256 timestamp
    );

    event RegisteredForIsolationPool(
        address indexed user,
        address indexed isolationContractAddress,
        bool indexed registration,
        uint256 timestamp
    );

    event PoolCreated(
        bool borrowAllowed,
        address indexed poolToken,
        address indexed curvePool,
        address curveMetaPool,
        uint256 mulFactor,
        uint256 indexed poolCollFactor,
        uint256 maxDepositAmount,
        uint256 borrowPercentageCap,
        uint256 timestamp
    );

    mapping (uint8 => bytes4) selectors;

    address public wiseLending;

    constructor() {
        selectors[0] = this.fundsDeposited.selector;
        selectors[1] = this.fundsSolelyDeposited.selector;
        selectors[2] = this.fundsWithdrawn.selector;
        selectors[3] = this.fundsWithdrawnOnBehalf.selector;
        selectors[4] = this.fundsSolelyWithdrawn.selector;
        selectors[5] = this.fundsSolelyWithdrawnOnBehalf.selector;
        selectors[6] = this.fundsBorrowed.selector;
        selectors[7] = this.fundsBorrowedOnBehalf.selector;
        selectors[8] = this.fundsReturned.selector;
        selectors[9] = this.fundsReturnedWithLendingShares.selector;
        selectors[10] = this.collateralizeDeposit.selector;
        selectors[11] = this.decollateralizeDeposit.selector;
        selectors[12] = this.approveWithdraw.selector;
        selectors[13] = this.approveBorrow.selector;
        selectors[14] = this.poolSynced.selector;
        selectors[15] = this.isolationPoolVeryfied.selector;
        selectors[16] = this.registeredForIsolationPool.selector;
        selectors[17] = this.poolCreated.selector;
    }

    modifier onlyWiseLending() {
        if (msg.sender != wiseLending) {
            revert NotWiseLending();
        }
        _;
    }

    modifier onlySelf() {
        _onlySelf();
        _;
    }

    function _onlySelf()
        private
        view
    {
        if (msg.sender != address(this)) {
            revert NotSelf();
        }
    }

    function setWiseLending(
        address _wiseLending
    )
        external
    {
        if (wiseLending > address(0)) {
            revert AlreadySet();
        }
        wiseLending = _wiseLending;
    }

    function emitEvent(
        bytes memory _data
    )
        onlyWiseLending
        external
    {
        uint8 eventType;

        assembly {
            eventType := mload(add(_data, 1))
        }

        (
            bool success,
            bytes memory callback
        ) = address(this).call(
            abi.encodeWithSelector(
                selectors[eventType],
                _data
            )
        );
    }

    function decodeTesting(
        bytes memory _data
    )
        external
        pure
        returns (address)
    {
        uint8 eventType;
        address addr;

        assembly {
            eventType := mload(add(_data, 1))
            addr := mload(add(_data, 21))
        }
        return addr;
    }

    function poolCreated(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            bool borrowAllowed,
            address poolToken,
            address curvePool,
            address curveMetaPool,
            uint256 mulFactor,
            uint256 poolCollFactor,
            uint256 maxDepositAmount,
            uint256 borrowPercentageCap,
            uint256 timestamp
        ) = _getBAAAUUUUU(
            _data
        );

        emit PoolCreated(
            borrowAllowed,
            poolToken,
            curvePool,
            curveMetaPool,
            mulFactor,
            poolCollFactor,
            maxDepositAmount,
            borrowPercentageCap,
            timestamp
        );
    }

    function fundsDeposited(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address callerAddress,
            address token,
            uint256 nftId,
            uint256 amount,
            uint256 shares,
            uint256 eventTimeStamp
        ) = (
            _getAAUUUU(
                _data
            )
        );

        emit FundsDeposited(
            nftId,
            callerAddress,
            token,
            amount,
            shares,
            eventTimeStamp
        );
    }

    function fundsSolelyDeposited(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address callerAddress,
            address token,
            uint256 amount,
            uint256 eventTimeStamp
        ) = (
            _getAAAUU(
                _data
            )
        );

        emit FundsSolelyDeposited(
            user,
            callerAddress,
            token,
            amount,
            eventTimeStamp
        );
    }

    function fundsWithdrawn(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address token,
            uint256 amount,
            uint256 shares,
            uint256 eventTimeStamp
        ) = (
            _getAAUUU(
                _data
            )
        );

        emit FundsWithdrawn(
            user,
            token,
            amount,
            shares,
            eventTimeStamp
        );
    }

    function fundsWithdrawnOnBehalf(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address callerAddress,
            address token,
            uint256 amount,
            uint256 shares,
            uint256 eventTimeStamp
        ) = (
            _getAAAUUU(
                _data
            )
        );

        emit FundsWithdrawnOnBehalf(
            user,
            callerAddress,
            token,
            amount,
            shares,
            eventTimeStamp
        );
    }

    function fundsSolelyWithdrawn(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address token,
            uint256 amount,
            uint256 eventTimeStamp
        ) = (
            _getAAUU(
                _data
            )
        );

        emit FundsSolelyWithdrawn(
            user,
            token,
            amount,
            eventTimeStamp
        );
    }

    function fundsSolelyWithdrawnOnBehalf(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address callerAddress,
            address token,
            uint256 amount,
            uint256 eventTimeStamp
        ) = (
            _getAAAUU(
                _data
            )
        );

        emit FundsSolelyWithdrawnOnBehalf(
            user,
            callerAddress,
            token,
            amount,
            eventTimeStamp
        );
    }

    function fundsBorrowed(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address borrower,
            address token,
            uint256 amount,
            uint256 shares,
            uint256 eventTimeStamp
        ) = (
            _getAAUUU(
                _data
            )
        );

        emit FundsBorrowed(
            borrower,
            token,
            amount,
            shares,
            eventTimeStamp
        );
    }

    function fundsBorrowedOnBehalf(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address borrower,
            address callerAddress,
            address token,
            uint256 amount,
            uint256 shares,
            uint256 eventTimeStamp
        ) = (
            _getAAAUUU(
                _data
            )
        );

        emit FundsBorrowedOnBehalf(
            borrower,
            callerAddress,
            token,
            amount,
            shares,
            eventTimeStamp
        );
    }

    function fundsReturned(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address callerAddress,
            address token,
            uint256 totalPayment,
            uint256 totalPaymentShares,
            uint256 eventTimeStamp
        ) = (
            _getAAAUUU(
                _data
            )
        );

        emit FundsReturned(
            user,
            callerAddress,
            token,
            totalPayment,
            totalPaymentShares,
            eventTimeStamp
        );
    }

    function fundsReturnedWithLendingShares(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address callerAddress,
            address token,
            uint256 totalPayment,
            uint256 totalPaymentShares,
            uint256 eventTimeStamp
        ) = (
            _getAAAUUU(
                _data
            )
        );

        emit FundsReturnedWithLendingShares(
            user,
            callerAddress,
            token,
            totalPayment,
            totalPaymentShares,
            eventTimeStamp
        );
    }

    function collateralizeDeposit(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address token,
            uint256 eventTimeStamp
        ) = (
            _getAAU(
                _data
            )
        );

        emit CollateralizeDeposit(
            user,
            token,
            eventTimeStamp
        );
    }

    function decollateralizeDeposit(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address token,
            uint256 eventTimeStamp
        ) = (
            _getAAU(
                _data
            )
        );

        emit DecollateralizeDeposit(
            user,
            token,
            eventTimeStamp
        );
    }

    function approveWithdraw(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address spender,
            address token,
            uint256 amount,
            uint256 eventTimeStamp
        ) = (
            _getAAAUU(
                _data
            )
        );

        emit ApproveWithdraw(
            user,
            spender,
            token,
            amount,
            eventTimeStamp
        );
    }

    function approveBorrow(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address spender,
            address token,
            uint256 amount,
            uint256 eventTimeStamp
        ) = (
            _getAAAUU(
                _data
            )
        );

        emit ApproveBorrow(
            user,
            spender,
            token,
            amount,
            eventTimeStamp
        );
    }

    function poolSynced(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address pool,
            uint256 eventTimeStamp
        ) = (
            _getAU(
                _data
            )
        );

        emit PoolSynced(
            pool,
            eventTimeStamp
        );
    }

    function isolationPoolVeryfied(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address isolationContractAddress,
            uint256 eventTimeStamp
        ) = (
            _getAU(
                _data
            )
        );

        emit IsolationPoolVeryfied(
            isolationContractAddress,
            eventTimeStamp
        );
    }

    function registeredForIsolationPool(
        bytes memory _data
    )
        onlySelf
        external
    {
        (
            uint8 eventType,
            address user,
            address isolationContractAddress,
            bool registration,
            uint256 eventTimeStamp
        ) = (
            _getAABU(
                _data
            )
        );

        emit RegisteredForIsolationPool(
            user,
            isolationContractAddress,
            registration,
            eventTimeStamp
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

contract EventHelper {

    function _getBAUUUUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            bool boolA,
            address addressA,
            uint256 valueA,
            uint256 valueB,
            uint256 valueC,
            uint256 valueD,
            uint256 valueE
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            boolA := mload(add(_data, 2))
            addressA := mload(add(_data, 22))
            valueA := mload(add(_data, 54))
            valueB := mload(add(_data, 86))
            valueC := mload(add(_data, 118))
            valueD := mload(add(_data, 150))
            valueE := mload(add(_data, 182))
        }
    }

    function _getBAAAUUUUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            bool boolA,
            address addressA,
            address addressB,
            address addressC,
            uint256 valueA,
            uint256 valueB,
            uint256 valueC,
            uint256 valueD,
            uint256 valueE
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            boolA := mload(add(_data, 2))
            addressA := mload(add(_data, 22))
            addressB := mload(add(_data, 42))
            addressC := mload(add(_data, 62))
            valueA := mload(add(_data, 94))
            valueB := mload(add(_data, 158))
            valueC := mload(add(_data, 190))
            valueD := mload(add(_data, 222))
            valueE := mload(add(_data, 254))
        }
    }

    function _getAAUUUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            uint256 valueA,
            uint256 valueB,
            uint256 valueC,
            uint256 valueD
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            valueA := mload(add(_data, 73))
            valueB := mload(add(_data, 105))
            valueC := mload(add(_data, 137))
            valueD := mload(add(_data, 160))
        }
    }

    function _getAAAUUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            address addressC,
            uint256 valueA,
            uint256 valueB,
            uint256 valueC
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            addressC := mload(add(_data, 61))
            valueA := mload(add(_data, 93))
            valueB := mload(add(_data, 125))
            valueC := mload(add(_data, 157))
        }
    }

    function _getAAAUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            address addressC,
            uint256 valueA,
            uint256 valueB
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            addressC := mload(add(_data, 61))
            valueA := mload(add(_data, 93))
            valueB := mload(add(_data, 125))
        }
    }

    function _getAAUUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            uint256 valueA,
            uint256 valueB,
            uint256 valueC
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            valueA := mload(add(_data, 73))
            valueB := mload(add(_data, 105))
            valueC := mload(add(_data, 137))
        }
    }

    function _getAU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            uint256 valueA
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            valueA := mload(add(_data, 53))
        }
    }

    function _getAAU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            uint256 valueA
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            valueA := mload(add(_data, 73))
        }
    }

    function _getAAUU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            uint256 valueA,
            uint256 valueB
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            valueA := mload(add(_data, 73))
            valueB := mload(add(_data, 105))
        }
    }

    function _getAABU(
        bytes memory _data
    )
        internal
        pure
        returns (
            uint8 eventType,
            address addressA,
            address addressB,
            bool boolA,
            uint256 valueB
        )
    {
        assembly {
            eventType := mload(add(_data, 1))
            addressA := mload(add(_data, 21))
            addressB := mload(add(_data, 41))
            boolA := mload(add(_data, 42))
            valueB := mload(add(_data, 74))
        }
    }
}