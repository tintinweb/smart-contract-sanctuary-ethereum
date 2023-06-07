// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./WiseCore.sol";
import "./PoolManager.sol";
import "./FlashloanHub/FlashMaker.sol";

contract WiseLending is WiseCore, FlashMaker, PoolManager {

    receive()
        external
        payable
    {
        if (msg.sender == WETH_ADDRESS) {
            return;
        }

        payable(lendingMaster).transfer(
            msg.value
        );
    }

    /**
     * @dev Runs the LASA algorithm aka
     * Lending Automated Scaling Algorithm
     * and updates pools
    */
    modifier syncPool(
        address _poolToken
    ) {
        _syncPoolBeforeCodeExecution(
            _poolToken
        );
        _;
        _syncPoolAfterCodeExecution(
            _poolToken
        );
    }

    constructor(
        address _lendingMaster,
        address _governance,
        address _wiseOracleHubAddress,
        address _eventHandler,
        address _nftContract,
        address _wethContract
    )
        DeclarationsWiseLending(
            _lendingMaster,
            _governance,
            _wiseOracleHubAddress,
            _eventHandler,
            _nftContract,
            _wethContract
        )
    {}

    function _syncPoolBeforeCodeExecution(
        address _poolToken
    )
        private
    {
        if (veryfiedIsolationPool[msg.sender] == false) {
            _cleanUp(
                _poolToken
            );

            _updatePseudoTotalAmounts(
                _poolToken
            );
        }
    }

    function _syncPoolAfterCodeExecution(
        address _poolToken
    )
        private
    {
        _newBorrowRate(
            _poolToken
        );

        _emitEvent(
            abi.encodePacked(
                uint8(14),
                _poolToken,
                block.timestamp
            )
        );
    }

    function approveBorrow(
        uint256 _nftId,
        address _spender,
        address _poolToken,
        uint256 _amount
    )
        external
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        allowanceBorrow[_nftId][_poolToken][_spender] = _amount;

        _emitEvent(
            abi.encodePacked(
                uint8(13),
                msg.sender,
                _spender,
                _poolToken,
                _amount,
                block.timestamp
            )
        );
    }

    function approveWithdraw(
        uint256 _nftId,
        address _spender,
        address _poolToken,
        uint256 _amount
    )
        external
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        allowanceWithdraw[_nftId][_poolToken][_spender] = _amount;

        _emitEvent(
            abi.encodePacked(
                uint8(12),
                msg.sender,
                _spender,
                _poolToken,
                _amount,
                block.timestamp
            )
        );
    }

    function collateralizeDeposit(
        uint256 _nftId,
        address _poolToken
    )
        external
    {
        WISE_SECURITY.checksCollateralizeDeposit(
            _nftId,
            msg.sender,
            _poolToken
        );

        _updateCollateralize(
            _nftId,
            _poolToken,
            msg.sender,
            true
        );
    }

    function decollateralizeDeposit(
        uint256 _nftId,
        address _poolToken
    )
        external
        syncPool(_poolToken)
        prepareAssociatedTokens(_nftId, _poolToken)
    {
        WISE_SECURITY.checksDecollateralizeDeposit(
            _nftId,
            msg.sender,
            _poolToken
        );

        _updateCollateralize(
            _nftId,
            _poolToken,
            msg.sender,
            false
        );

        WISE_SECURITY.checkBorrowLimit(
            _nftId,
            _poolToken,
            0
        );
    }

    function solelyDepositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        public
        syncPool(_poolToken)
    {
        WISE_SECURITY.checksDeposit(
            _nftId,
            msg.sender,
            _poolToken,
            _amount
        );

        _increasePositionMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _increaseTotalBareToken(
            _poolToken,
            _amount
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        ); // For lending

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );

        _emitEvent(
            abi.encodePacked(
                uint8(1),
                _nftId,
                msg.sender,
                _poolToken,
                _amount,
                block.timestamp
            )
        );
    }

    // lets remove this :)
    // this can still be included (now we have enough space)
    /*function depositExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares,
        bool _collateralState
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 tokenAmount = cashoutAmount(
            _poolToken,
            _shares
        );

        _handleDeposit(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: tokenAmount,
                _shareAmount: _shares,
                _state: _collateralState,
                _eventId: uint8(0)
            }
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            tokenAmount
        );

        return tokenAmount;
    }*/

    // -----------------------------------------------
    // --------------- Deposit Functions -------------
    //------------------------------------------------

    function depositExactAmountETH(
        uint256 _nftId,
        bool _collateralState
    )
        public
        payable
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        uint256 value = msg.value;

        uint256 shareAmount = calculateLendingShares(
            WETH_ADDRESS,
            value
        );

        _handleDeposit(
            {
                _caller: msg.sender,
                _poolToken: WETH_ADDRESS,
                _nftId: _nftId,
                _amount: value,
                _shareAmount: shareAmount,
                _state: _collateralState,
                _eventId: uint8(0)
            }
        );

        _wrapETH(
            value
        );

        return shareAmount;
    }

    function depositExactAmountETHMint(
        bool _collateralState
    )
        external
        payable
        returns (uint256 shareAmount)
    {
        uint256 nftId = POSITION_NFT.mintPositionForUser(
            msg.sender
        );

        return depositExactAmountETH(
            nftId,
            _collateralState
        );
    }

    function depositExactAmountMint(
        address _poolToken,
        uint256 _amount,
        bool _collateralState
    )
        external
        returns (uint256 shares)
    {
        uint256 nftId = POSITION_NFT.mintPositionForUser(
            msg.sender
        );

        return depositExactAmount(
            nftId,
            _poolToken,
            _amount,
            _collateralState
        );
    }

    function depositExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount,
        bool _collateralState
    )
        public
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 shareAmount = calculateLendingShares(
            _poolToken,
            _amount
        );

        _handleDeposit(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: _amount,
                _shareAmount: shareAmount,
                _state: _collateralState,
                _eventId: uint8(0)
            }
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );

        return shareAmount;
    }

    // ------------------------------------------------
    // --------------- Withdraw Functions -------------
    //-------------------------------------------------

    function withdrawExactAmountETH(
        uint256 _nftId,
        uint256 _amount
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 withdrawShares = calculateLendingShares(
            WETH_ADDRESS,
            _amount
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: WETH_ADDRESS,
                _nftId: _nftId,
                _amount: _amount,
                _shares: withdrawShares
            }
        );

        _unwrapETH(
            _amount
        );

        payable(msg.sender).transfer(
            _amount
        );

        return withdrawShares;
    }

    function withdrawExactSharesETH(
        uint256 _nftId,
        uint256 _shares
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 withdrawAmount = cashoutAmount(
            WETH_ADDRESS,
            _shares
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: WETH_ADDRESS,
                _nftId: _nftId,
                _amount: withdrawAmount,
                _shares: _shares
            }
        );

        _unwrapETH(
            withdrawAmount
        );

        payable(msg.sender).transfer(
            withdrawAmount
        );

        return withdrawAmount;
    }

    function withdrawExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 withdrawShares = calculateLendingShares(
            _poolToken,
            _amount
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: _amount,
                _shares: withdrawShares
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return withdrawShares;
    }

    function solelyWithdrawExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        _handleSolelyWithdraw(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: _amount,
                _nftId: _nftId,
                _eventId: uint8(4)
            }
        );
    }

    function solelyWithdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
    {
        _reduceAllowance(
            allowanceWithdraw,
            _nftId,
            _poolToken,
            msg.sender,
            _amount
        );

        _handleSolelyWithdraw(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: _amount,
                _nftId: _nftId,
                _eventId: uint8(5)
            }
        );
    }

    function withdrawOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        _reduceAllowance(
            allowanceWithdraw,
            _nftId,
            _poolToken,
            msg.sender,
            _amount
        );

        uint256 withdrawShares = calculateLendingShares(
            _poolToken,
            _amount
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: _amount,
                _shares: withdrawShares
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return withdrawShares;
    }

    function withdrawExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 withdrawAmount = cashoutAmount(
            _poolToken,
            _shares
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: withdrawAmount,
                _shares: _shares
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    function withdrawOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 withdrawAmount = cashoutAmount(
            _poolToken,
            _shares
        );

        _reduceAllowance(
            allowanceWithdraw,
            _nftId,
            _poolToken,
            msg.sender,
            withdrawAmount
        );

        _coreWithdrawToken(
            {
                _caller: msg.sender,
                _poolToken: _poolToken,
                _nftId: _nftId,
                _amount: withdrawAmount,
                _shares: _shares
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    // ----------------------------------------------
    // --------------- Borrow Functions -------------
    //-----------------------------------------------

    function borrowExactAmountETH(
        uint256 _nftId,
        uint256 _amount
    )
        external
        syncPool(WETH_ADDRESS)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 shares = calculateBorrowShares(
            WETH_ADDRESS,
            _amount
        );

        _handleBorrow(
            {
                _nftId: _nftId,
                _caller: msg.sender,
                _poolToken: WETH_ADDRESS,
                _amount: _amount,
                _shares: shares,
                _eventId: uint8(6)
            }
        );

        _unwrapETH(
            _amount
        );

        payable(msg.sender).transfer(
            _amount
        );

        return shares;
    }

    function borrowExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        // @TODO: this is duplicate with borrowOnBehalfExactAmount
        // we need to extract duplicate logic into internal function
        // so we reuse same code through calling one internal function
        // and not duplicating same lines of code
        uint256 shares = calculateBorrowShares(
            _poolToken,
            _amount
        );

        _handleBorrow(
            {
                _nftId: _nftId,
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: _amount,
                _shares: shares,
                _eventId: uint8(6)
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return shares;
    }

    function borrowOnBehalfExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        _reduceAllowance(
            allowanceBorrow,
            _nftId,
            _poolToken,
            msg.sender,
            _amount
        );

        // @TODO: this is duplicate with borrowExactAmount
        // we need to extract duplicate logic into internal function
        // so we reuse same code through calling one internal function
        // and not duplicating same lines of code
        uint256 shares = calculateBorrowShares(
            _poolToken,
            _amount
        );

        _handleBorrow(
            {
                _nftId: _nftId,
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: _amount,
                _shares: shares,
                _eventId: uint8(7)
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            _amount
        );

        return shares;
    }

    /*
    function borrowExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftId,
            msg.sender
        );

        uint256 borrowAmount = paybackAmount(
            _poolToken,
            _shares
        );

        _handleBorrow(
            {
                _nftId: _nftId,
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: borrowAmount,
                _shares: _shares,
                _eventId: uint8(6)
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            borrowAmount
        );

        return borrowAmount;
    }*/

    /*
    function borrowOnBehalfExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        syncPool(_poolToken)
        returns (uint256)
    {
        uint256 borrowAmount = paybackAmount(
            _poolToken,
            _shares
        );

        _reduceAllowance(
            allowanceBorrow,
            _nftId,
            _poolToken,
            msg.sender,
            borrowAmount
        );

        _handleBorrow(
            {
                _nftId: _nftId,
                _caller: msg.sender,
                _poolToken: _poolToken,
                _amount: borrowAmount,
                _shares: _shares,
                _eventId: uint8(7)
            }
        );

        _safeTransfer(
            _poolToken,
            msg.sender,
            borrowAmount
        );

        return borrowAmount;
    }*/

    // ----------------------------------------------
    // --------------- Payback Functions ------------
    //-----------------------------------------------

    function paybackExactAmountETH(
        uint256 _nftId
    )
        external
        payable
        returns (uint256)
    {
        uint256 ethSent = msg.value;

        WISE_SECURITY.checkPositionLocked(
            _nftId,
            msg.sender
        );

        uint256 maxBorrowShares = getPositionBorrowShares(
            _nftId,
            WETH_ADDRESS
        );

        uint256 maxPaybackAmount = paybackAmount(
            WETH_ADDRESS,
            maxBorrowShares
        );

        uint256 paybackShares = calculateBorrowShares(
            WETH_ADDRESS,
            ethSent
        );

        uint256 refundAmount = msg.value > maxPaybackAmount
            ? ethSent - maxPaybackAmount
            : 0;

        if (refundAmount > 0) {
            payable(msg.sender).transfer(
                refundAmount
            );

            paybackShares = maxBorrowShares;
        }

        uint256 requiredAmount = ethSent
            - refundAmount;

        _handlePayback(
            {
                _poolToken: WETH_ADDRESS,
                _caller: msg.sender,
                _amount: requiredAmount,
                _shares: paybackShares,
                _nftId: _nftId,
                _eventId: uint8(8)
            }
        );

        _wrapETH(
            requiredAmount
        );

        return paybackShares;
    }

    function paybackExactAmount(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        public
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkPositionLocked(
            _nftId,
            msg.sender
        );

        uint256 paybackShares = calculateBorrowShares(
            _poolToken,
            _amount
        );

        _handlePayback(
            {
                _poolToken: _poolToken,
                _caller: msg.sender,
                _amount: _amount,
                _shares: paybackShares,
                _nftId: _nftId,
                _eventId: uint8(8)
            }
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            _amount
        );

        return paybackShares;
    }

    function paybackExactShares(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        public
        syncPool(_poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkPositionLocked(
            _nftId,
            msg.sender
        );

        uint256 paybackAmount = paybackAmount(
            _poolToken,
            _shares
        );

        _handlePayback(
            {
                _poolToken: _poolToken,
                _caller: msg.sender,
                _amount: paybackAmount,
                _shares: _shares,
                _nftId: _nftId,
                _eventId: uint8(8)
            }
        );

        _safeTransferFrom(
            _poolToken,
            msg.sender,
            address(this),
            paybackAmount
        );

        return paybackAmount;
    }

    function paybackExactLendingShares(
        uint256 _nftIdCaller,
        uint256 _nftIdReceiver,
        address _poolToken,
        uint256 _lendingShares
    )
        public
        syncPool(_poolToken)
        prepareAssociatedTokens(_nftIdCaller, _poolToken)
        returns (uint256)
    {
        WISE_SECURITY.checkOwnerPosition(
            _nftIdCaller,
            msg.sender
        );

        uint256 tokenAmount = cashoutAmount(
            _poolToken,
            _lendingShares
        );

        uint256 nftIdCaller = _nftIdCaller;
        address poolToken = _poolToken;

        WISE_SECURITY.checkPaybackLendingShares(
            _nftIdReceiver,
            _nftIdCaller,
            msg.sender,
            poolToken,
            tokenAmount
        );

        _corePaybackLendingShares(
            poolToken,
            tokenAmount,
            _lendingShares,
            _nftIdCaller,
            _nftIdReceiver
        );

        if (getPositionBorrowShares(_nftIdReceiver, poolToken) == 0) {
            _removePositionData(
                _nftIdReceiver,
                _poolToken,
                getPositionBorrowTokenLength,
                getPositionBorrowTokenByIndex,
                _deleteLastPositionBorrowData,
                false
            );
        }

        _emitEvent(
            abi.encodePacked(   //def event ändern
                uint8(9),
                nftIdCaller,
                msg.sender,
                poolToken,
                tokenAmount,
                _lendingShares,
                block.timestamp
            )
        );

        return tokenAmount;
    }

    function syncManually(
        address _poolToken
    )
        external
        syncPool(_poolToken)
    {
        // maybe can add some event
    }

    function registrationIsolationPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
    {
        WISE_SECURITY.checksRegistrationIsolationPool(
            _nftId,
            msg.sender,
            _isolationPool
        );

        _setIsolationPoolMappings(
            {
                _registerAndLock: true,
                _isolationPool: _isolationPool,
                _nftId: _nftId
            }
        );
    }

    function unregisterIsolationPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
    {
        WISE_SECURITY.checkUnregister(
            _nftId,
            msg.sender
        );

        _setIsolationPoolMappings(
            {
                _registerAndLock: false,
                _isolationPool: _isolationPool,
                _nftId: _nftId
            }
        );
    }

    function setVeryfiedIsolationPool(
        address _isolationPool
    )
        external
    {
        WISE_SECURITY.checkOnlyMaster(
            msg.sender
        );

        veryfiedIsolationPool[_isolationPool] = true;

        _emitEvent(
            abi.encodePacked(
                uint8(15),
                _isolationPool,
                block.timestamp
            )
        );
    }
}

pragma solidity =0.8.19;

// SPDX-License-Identifier: -- WISE --

import "../InterfaceHub/IFlash.sol";
import "../InterfaceHub/IERC20.sol";

error LengthMissmatch();
error CallbackFailed();
error NotAuthorized();

contract FlashMaker {

    bytes32 public constant CALLBACK_SUCCESS = 0xf51a74cb268a8f727edf953ddacc8f280294844b89df00cd2e0ae537e4b981d3;

    address public masterAddress;
    mapping(address => uint256) public tokenFees;

    constructor() {
        masterAddress = msg.sender;
    }

    function adjustFees(
        address _tokenAddress,
        uint256 _feeValue
    )
        external
    {
        if (masterAddress != msg.sender) {
            revert NotAuthorized();
        }

        tokenFees[_tokenAddress] = _feeValue;
    }

    function maxFlashLoan(
        IERC20 _flashMaker
    )
        external
        view
        returns (uint256 result)
    {
        result = _flashMaker.balanceOf(
            address(this)
        );
    }

    function flashFee(
        address _token,
        uint256 _amount
    )
        public
        view
        returns (uint256 result)
    {
        result = _amount
            * tokenFees[_token]
            / 1000000;
    }

    function flashLoan(
        IFlashBorrower _receiver,
        IERC20[] memory _flashMaker,
        address[] memory _tokenList,
        uint256[] memory _amountList,
        bytes[] calldata _data
    )
        external
        returns (bool)
    {
        if (_tokenList.length !=_amountList.length) {
            revert LengthMissmatch();
        }

        if (_tokenList.length != _flashMaker.length) {
            revert LengthMissmatch();
        }

        uint256 lengthIndex = _tokenList.length;

        uint256[] memory feeList = new uint256[](lengthIndex);

        for (uint256 i = 0; i < lengthIndex; i++) {
            _flashMaker[i].transfer(
                address(_receiver),
                _amountList[i]
            );

            feeList[i] = flashFee(
                _tokenList[i],
                _amountList[i]
            );
        }

        if (_receiver.onFlashLoan(msg.sender, _tokenList, _amountList, feeList, _data) !=
            CALLBACK_SUCCESS) {
                revert CallbackFailed();
        }

        for (uint256 i = 0; i < lengthIndex; i++) {
            _flashMaker[i].transferFrom(
                address(_receiver),
                address(this),
                _amountList[i] + feeList[i]
            );
        }

        return true;
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./Babylonian.sol";
import './DeclarationsWiseLending.sol';

abstract contract PoolManager is DeclarationsWiseLending {

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    function _onlyGovernance()
        private
        view
    {
        if (msg.sender == governance) {
            return;
        }

        revert InvalidCaller();
    }

    struct createPoolStruct {
        bool allowBorrow;
        address poolToken;
        address curvePool;
        address curveMetaPool;
        address[] underlyingPoolTokens;
        curveSwapStruct curveSecuritySwaps;
        uint256 poolMulFactor;
        uint256 poolCollFactor;
        uint256 maxDepositAmount;
        uint256 borrowPercentageCap;
    }

    //We should nail down exactly what parameters should be tweakable for pool creation, or pool modification by governance
    //Collateralizion is turned off for any new pool from governance until master turns it on
    function createPool(
        createPoolStruct memory _params
    )
        external
        onlyGovernance
    {
        if (timestampsPoolData[_params.poolToken].timeStamp > 0) {
            revert AlreadyCreated();
        }

        // Calculating lower bound for the pole
        uint256 staticMinPole = PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _params.poolMulFactor
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for the pole
        uint256 staticMaxPole = PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _params.poolMulFactor
                    * PRECISION_FACTOR_E36
                    / LOWER_BOUND_MAX_RATE
            );

        // Calculating fraction for algorithm step
        uint256 staticDeltaPole = (staticMaxPole - staticMinPole)
            / NORMALISATION_FACTOR;

        uint256 timeNow = block.timestamp;
        maxDepositValueToken[_params.poolToken] = _params.maxDepositAmount;

        FEE_MANAGER.addPoolTokenAddress(
            _params.poolToken
        );

        globalPoolData[_params.poolToken] = GlobalPoolEntry({
            totalPool: 0,
            utilization: 0,
            totalBareToken: 0,
            poolFee: 20 * PRECISION_FACTOR_E16
        });

        // Setting start value as mean of min and max value
        uint256 startValuePole = (staticMaxPole + staticMinPole) / 2 ;

        // Rates Pool Data
        borrowRatesData[_params.poolToken] = BorrowRatesEntry({
            pole: startValuePole,
            deltaPole: staticDeltaPole,
            minPole: staticMinPole,
            maxPole: staticMaxPole,
            multiplicativFactor: _params.poolMulFactor
        });

        // Borrow Pool Data
        borrowPoolData[_params.poolToken] = BorrowPoolEntry({
            allowBorrow: _params.allowBorrow,
            pseudoTotalBorrowAmount: 1,
            borrowPercentageCap: _params.borrowPercentageCap,
            totalBorrowShares: 1,
            borrowRate: 0
        });

        // Algorithm Pool Data
        algorithmData[_params.poolToken] = AlgorithmEntry({
            bestPole: startValuePole,
            maxValue: 0,
            previousValue: 0,
            increasePole: false
        });

        _prepareNewPool(
            _params.poolToken
        );

        // Lending Pool Data
        lendingPoolData[_params.poolToken] = LendingPoolEntry({
            pseudoTotalPool: 1,
            totalDepositShares: 1,
            collateralFactor: _params.poolCollFactor
        });

        // Timestamp Pool Data
        timestampsPoolData[_params.poolToken] = TimestampsPoolEntry({
            timeStamp: timeNow,
            timeStampScaling: timeNow
        });

        IERC20(_params.poolToken).approve(
            address(WISE_LIQUIDATION),
            UINT256_MAX
        );

        if (_params.curvePool > ZERO_ADDRESS) {
            _prepareCurvePools(
                _params.poolToken,
                _params.curvePool,
                _params.curveMetaPool,
                _params.underlyingPoolTokens,
                _params.curveSecuritySwaps
            );
        }

        _emitEvent(
            abi.encodePacked(
                uint8(17),
                _params.allowBorrow,
                _params.poolToken,
                _params.curvePool,
                _params.curveMetaPool,
                _params.poolMulFactor,
                _params.poolCollFactor,
                _params.maxDepositAmount,
                _params.borrowPercentageCap,
                block.timestamp
            )
        );
    }

    function _prepareCurvePools(
        address _poolToken,
        address _curvePool,
        address _curveMetaPool,
        address[] memory _underlyingPoolTokens,
        curveSwapStruct memory _curveSwapStruct
    )
        internal
    {
        WISE_SECURITY.prepareCurvePools(
            _poolToken,
            _curvePool,
            _curveMetaPool,
            _curveSwapStruct
        );

        WISE_SECURITY.setUnderlyingPoolTokensFromPoolToken(
            _poolToken,
            _underlyingPoolTokens
        );
    }

    function _prepareNewPool(
        address _poolToken
    )
        internal
        returns (uint256)
    {
        uint256 fetchBalance = IERC20(_poolToken).balanceOf(
            address(this)
        );

        if (fetchBalance == 0) {
            return 0;
        }

        IERC20(_poolToken).transfer(
            lendingMaster,
            fetchBalance
        );

        return fetchBalance;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "./MainHelper.sol";

abstract contract WiseCore is MainHelper {

    modifier prepareAssociatedTokens(
        uint256 _nftId,
        address _poolToken
    ) {
        _prepareAssociatedTokens(
            _nftId,
            _poolToken
        );
        _;
    }

    function _prepareAssociatedTokens(
        uint256 _nftId,
        address _poolToken
    )
        private
    {
        if (veryfiedIsolationPool[msg.sender] == false) {

            _preparationCollaterals(
                _nftId,
                _poolToken
            );

            _preparationBorrows(
                _nftId,
                _poolToken
            );
        }
    }

    function _coreDepositTokens(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount,
        uint256 _share
    )
        internal
    {
        WISE_SECURITY.checksDeposit(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _updatePositionLendingDeposit(
            _nftId,
            _poolToken,
            _share
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            _share,
            _increaseTotalPool,
            _increasePseudoTotalPool,
            _increaseTotalDepositShares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        );
    }

    function _coreWithdrawToken(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
        prepareAssociatedTokens(
            _nftId,
            _poolToken
        )
    {
        WISE_SECURITY.checksWithdraw(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _coreWithdrawBare(
            _poolToken,
            _nftId,
            _amount,
            _shares
        );

        _emitEvent(
            abi.encodePacked(
                uint8(2),
                _caller,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            )
        );
    }

    function _handlePayback(
        address _poolToken,
        address _caller,
        uint256 _amount,
        uint256 _shares,
        uint256 _nftId,
        uint8 _eventId
    )
        internal
    {
        _corePayback(
            _poolToken,
            _nftId,
            _amount,
            _shares
        );

        _emitEvent(
            abi.encodePacked(
                _eventId,
                _nftId,
                _caller,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            )
        );
    }

    function _handleBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        uint8 _eventId
    )
        internal
    {
        _coreBorrowTokens(
            _nftId,
            _caller,
            _poolToken,
            _amount,
            _shares
        );

        _emitEvent(
            abi.encodePacked(
                _eventId,
                _nftId,
                _caller,
                _poolToken,
                _amount,
                _shares,
                block.timestamp
            )
        );
    }

    function _handleDeposit(
        address _caller,
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shareAmount,
        bool _state,
        uint8 _eventId
    )
        internal
    {
        _coreDepositTokens(
            _nftId,
            _caller,
            _poolToken,
            _amount,
            _shareAmount
        );

        if (userLendingData[_nftId][_poolToken].collaterized == false) {
            userLendingData[_nftId][_poolToken].collaterized = _state;
        }

        _emitEvent(
            abi.encodePacked(
                _eventId,
                _caller,
                _poolToken,
                _nftId,
                _amount,
                _shareAmount,
                block.timestamp
            )
        );
    }

    function _handleSolelyWithdraw(
        address _caller,
        address _poolToken,
        uint256 _amount,
        uint256 _nftId,
        uint8 _eventId
    )
        internal
    {
        _coreSolelyWithdrawOnBehalf(
            _caller,
            _poolToken,
            _nftId,
            _amount
        );

        _safeTransfer(
            _poolToken,
            _caller,
            _amount
        );

        _emitEvent(
            abi.encodePacked(
                _eventId,
                _nftId,
                _caller,
                _poolToken,
                _amount,
                block.timestamp
            )
        );
    }

    function coreWithdrawLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external
        onlyLiquidation
    {
        _coreWithdrawBare(
            _poolToken,
            _nftId,
            _amount,
            _shares
        );
    }

    function _coreWithdrawBare(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _decreaseTotalPool,
            _decreasePseudoTotalPool,
            _decreaseTotalDepositShares
        );

        _updatePositionLendingDataWithdraw(
            _nftId,
            _poolToken,
            _shares
        );

        _removeLendingTokenDataIfNotEmpty(
            _nftId,
            _poolToken
        );
    }

    function _coreBorrowTokens(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount,
        uint256 _shares
    )
        internal
        prepareAssociatedTokens(
            _nftId,
            _poolToken
        )
    {
        WISE_SECURITY.checksBorrow(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increasePseudoTotalBorrowAmount,
            _decreaseTotalPool,
            _increaseTotalBorrowShares
        );

        _increasePositionMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionBorrow,
            positionBorrowTokenData
        );
    }

    function _corePayback(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        internal
    {
        _updatePoolStorage(
            _poolToken,
            _amount,
            _shares,
            _increaseTotalPool,
            _decreasePseudoTotalBorrowAmount,
            _decreaseTotalBorrowShares
        );

        _decreasePositionMappingValue(
            userBorrowShares,
            _nftId,
            _poolToken,
            _shares
        );

        if (getPositionBorrowShares(_nftId, _poolToken) == 0) {
            _removePositionData(
                _nftId,
                _poolToken,
                getPositionBorrowTokenLength,
                getPositionBorrowTokenByIndex,
                _deleteLastPositionBorrowData,
                false
            );
        }
    }

    function corePaybackLiquidation(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external
        onlyLiquidation
    {
        _corePayback(
            _poolToken,
            _nftId,
            _amount,
            _shares
        );
    }

    function corePaybackFeeMananger(
        address _poolToken,
        uint256 _nftId,
        uint256 _amount,
        uint256 _shares
    )
        external
        onlyFeeManager
    {
        _corePayback(
            _poolToken,
            _nftId,
            _amount,
            _shares
        );
    }

    function _coreSolelyWithdrawOnBehalf(
        address _caller,
        address _poolToken,
        uint256 _nftId,
        uint256 _amount
    )
        internal
    {
        WISE_SECURITY.checksSolelyWithdraw(
            _nftId,
            _caller,
            _poolToken,
            _amount
        );

        _decreasePositionMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );

        _decreaseTotalBareToken(
            _poolToken,
            _amount
        );

        _removeLendingTokenDataIfNotEmpty(
            _nftId,
            _poolToken
        );
    }

    function _corePaybackLendingShares(
        address _poolToken,
        uint256 _tokenAmount,
        uint256 _lendingShares,
        uint256 _nftIdCaller,
        uint256 _nftIdReceiver
    )
        internal
    {
        uint256 borrowShareEquivalent = _borrowShareEquivalent(
            _poolToken,
            _lendingShares
        );

        _updatePoolStorage(
            _poolToken,
            _tokenAmount,
            _lendingShares,
            _decreasePseudoTotalPool,
            _decreasePseudoTotalBorrowAmount,
            _decreaseTotalDepositShares
        );

        _updatePositionLendingDataWithdraw(
            _nftIdCaller,
            _poolToken,
            _lendingShares
        );

        _decreaseTotalBorrowShares(
            _poolToken,
            borrowShareEquivalent
        );

        _decreasePositionMappingValue(
            userBorrowShares,
            _nftIdReceiver,
            _poolToken,
            borrowShareEquivalent
        );
    }
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./WiseLowLevelHelper.sol";

abstract contract MainHelper is WiseLowLevelHelper, TransferHelper {

    // ------------------------------
    // HIGHER INTERNAL-VIEW FUNCTIONS
    // ------------------------------

    function calculateLendingShares(
        address _poolToken,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        return _amount
            * getTotalDepositShares(_poolToken)
            / getPseudoTotalPool(_poolToken);
    }

    function calculateBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        return _amount
            * getTotalBorrowShares(_poolToken)
            / getPseudoTotalBorrowAmount(_poolToken);
    }

    function cashoutAmount(
        address _poolToken,
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * getPseudoTotalPool(_poolToken)
            / getTotalDepositShares(_poolToken);
    }

    function paybackAmount(
        address _poolToken,
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * getPseudoTotalBorrowAmount(_poolToken)
            / getTotalBorrowShares(_poolToken);
    }

    // -----------------------------
    // HIGHER-INTERNAL-SET FUNCTIONS
    // -----------------------------

    function _getValueUtilization(
        address _poolToken
    )
        internal
        view
        returns (uint256)
    {
        if (getTotalPool(_poolToken) >= getPseudoTotalPool(_poolToken)) {
            return 0;
        }

        return PRECISION_FACTOR_E18 - (PRECISION_FACTOR_E18
            * getTotalPool(_poolToken)
            / getPseudoTotalPool(_poolToken)
        );
    }

    function _updateUtilization(
        address _poolToken
    )
        internal
    {
        globalPoolData[_poolToken].utilization = _getValueUtilization(
            _poolToken
        );
    }

    function _checkCleanUp(
        uint256 _amountContract,
        uint256 _totalPool,
        uint256 _bareAmount
    )
        internal
        pure
        returns (bool)
    {
        return _bareAmount + _totalPool >= _amountContract;
    }

    function _cleanUp(
        address _poolToken
    )
        internal
    {
        uint256 amountContract = IERC20(_poolToken).balanceOf(
            address(this)
        );

        uint256 totalPool = getTotalPool(
            _poolToken
        );

        uint256 bareToken = globalPoolData[_poolToken].totalBareToken;

        if (_checkCleanUp(amountContract, totalPool, bareToken)) {
            return;
        }

        uint256 diff = amountContract - (
            totalPool + bareToken
        );

        _increaseTotalAndPseudoTotalPool(
            _poolToken,
            diff
        );
    }

    function preparePool(
        address _poolToken
    )
        isolationOrFeeManager
        external
    {
        _preparePool(
            _poolToken
        );
    }

    function _preparePool(
        address _poolToken
    )
        internal
    {
        _cleanUp(
            _poolToken
        );

        _updatePseudoTotalAmounts(
            _poolToken
        );

        _newBorrowRate(
            _poolToken
        );

        WISE_SECURITY.curveSecurityCheck(
            _poolToken
        );
    }

    function _preparationBorrows(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        _prepareTokens(
            _poolToken,
            positionBorrowTokenData[_nftId]
        );
    }

    function _preparationCollaterals(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        _prepareTokens(
            _poolToken,
            positionLendingTokenData[_nftId]
        );
    }

    function _setIsolationPoolMappings(
        bool _registerAndLock,
        address _isolationPool,
        uint256 _nftId
    )
        internal
    {
        positionLocked[_nftId] = _registerAndLock;
        isolationPoolRegistered[_nftId][_isolationPool] = _registerAndLock;

        _emitEvent(
            abi.encodePacked(
                uint8(16),
                msg.sender,
                _isolationPool,
                _registerAndLock,
                block.timestamp
            )
        );
    }

    function _prepareTokens(
        address _poolToken,
        address[] memory tokens
    )
        internal
    {
        address currentAddress;

        for (uint8 i = 0; i < tokens.length; i++) {

            currentAddress = tokens[i];

            if (currentAddress == _poolToken) {
                continue;
            }

            _preparePool(
                currentAddress
            );
        }
    }

    function _updatePseudoTotalAmounts(
        address _poolToken
    )
        internal
    {
        uint256 currentTime = block.timestamp;

        uint256 rate = borrowPoolData[_poolToken].borrowRate
            * getPseudoTotalBorrowAmount(_poolToken)
            / PRECISION_FACTOR_E18
            / ONE_YEAR;

        uint256 amountInterest = rate
            * (currentTime - _getTimeStamp(_poolToken));

        uint256 feeAmount = amountInterest
            * globalPoolData[_poolToken].poolFee
            / PRECISION_FACTOR_E18;

        _increasePseudoTotalBorrowAmount(
            _poolToken,
            amountInterest
        );

        _increasePseudoTotalPool(
            _poolToken,
            amountInterest
        );

        if (feeAmount == 0) return;

        uint256 feeShares = feeAmount
            * getTotalDepositShares(_poolToken)
            / (getPseudoTotalPool(_poolToken) - feeAmount);

        _updatePositionLendingDeposit(
            POSITION_ID_FEE_MANAGER,
            _poolToken,
            feeShares
        );

        _increaseTotalDepositShares(
            _poolToken,
            feeShares
        );

        _setTimeStamp(
            _poolToken,
            currentTime
        );
    }

    function _updatePositionLendingDeposit(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares += _shares;
    }

    function _updateCollateralize(
        uint256 _nftId,
        address _poolToken,
        address _caller,
        bool _allow
    )
        internal
    {
        userLendingData[_nftId][_poolToken].collaterized = _allow;

        _emitEvent(
            abi.encodePacked(
                _allow
                    ? uint8(10)
                    : uint8(11),
                _caller,
                _poolToken,
                block.timestamp
            )
        );
    }

    function increaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        onlyLiquidation
    {
        _updatePositionLendingDeposit(
            _nftId,
            _poolToken,
            _shares
        );
    }

    // consider rename _decreaseSomething
    function _updatePositionLendingDataWithdraw(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        internal
    {
        userLendingData[_nftId][_poolToken].shares -= _shares;
    }

    function decreaseLendingSharesLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _shares
    )
        external
        onlyLiquidation
    {
        _updatePositionLendingDataWithdraw(
            _nftId,
            _poolToken,
            _shares
        );
    }

    function addPositionLendingTokenDataLiquidation(
        uint256 _nftId,
        address _poolToken
    )
        external
        onlyLiquidation
    {
        _addPositionTokenData(
            _nftId,
            _poolToken,
            hashMapPositionLending,
            positionLendingTokenData
        ); // For lending
    }

    function _addPositionTokenData(
        uint256 _nftId,
        address _poolToken,
        mapping(bytes32 => bool) storage hashMap,
        mapping(uint256 => address[]) storage userTokenData
    )
        internal
    {
        bytes32 hashData = _getHash(_nftId, _poolToken);

        if (hashMap[hashData] == true) {
            return;
        }

        hashMap[hashData] = true;
        userTokenData[_nftId].push(_poolToken);
    }

    function _getHash(
        uint256 _nftId,
        address _poolToken
        // uint256 _shareAmount <-- explore this idea
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _nftId,
                _poolToken
                // _shareAmount
            )
        );
    }

    // review this!!;
    // consider checking idea of using only base currency (USD only) - new contract
/*    function _removeUserLendingTokenData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        uint256 length = getPositionLendingTokenLength(
            _nftId
        );

        if (length == 1) {

            _deleteLastPositionLendingData(
                _nftId,
                _poolToken
            );

            return;
        }

        uint8 index;
        uint256 endPosition = length - 1;

        while (index < length) {

            if (getPositionLendingTokenByIndex(_nftId, index) != _poolToken) {

                index += 1;

                continue;
            }

            positionLendingTokenData[_nftId][index] = getPositionLendingTokenByIndex(
                _nftId,
                endPosition
            );

            _deleteLastPositionLendingData(
                _nftId,
                _poolToken
            );

            break;
        }
    }*/

    function _removePositionData(
        uint256 _nftId,
        address _poolToken,
        function(uint256) view returns (uint256) _getPositionTokenLength,
        function(uint256, uint256) view returns (address) _getPositionTokenByIndex,
        function(uint256, address) internal _deleteLastPositionData,
        bool isLending
    )
        internal
    {
        uint256 length = _getPositionTokenLength(_nftId);

        if (length == 1) {
            _deleteLastPositionData(_nftId, _poolToken);
            return;
        }

        uint8 index;
        uint256 endPosition = length - 1;

        while (index < length) {
            if (_getPositionTokenByIndex(_nftId, index) != _poolToken) {
                index += 1;
                continue;
            }

            isLending
                ? positionLendingTokenData[_nftId][index] = _getPositionTokenByIndex(_nftId, endPosition)
                : positionBorrowTokenData[_nftId][index] = _getPositionTokenByIndex(_nftId, endPosition);

            _deleteLastPositionData(
                _nftId,
                _poolToken
            );
            break;
        }
    }

/*    function _removeUserBorrowTokenData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        uint256 length = getPositionBorrowTokenLength(
            _nftId
        );

        if (length == 1) {

            _deleteLastPositionBorrowData(
                _nftId,
                _poolToken
            );

            return;
        }

        uint8 index;
        uint256 endPosition = length - 1;

        while (index < length) {

            if (getPositionBorrowTokenByIndex(_nftId, index) != _poolToken) {

                index += 1;

                continue;
            }

            positionBorrowTokenData[_nftId][index] = getPositionBorrowTokenByIndex(
                _nftId,
                endPosition
            );

            _deleteLastPositionBorrowData(
                _nftId,
                _poolToken
            );

            break;
        }
    }*/

    function _deleteLastPositionLendingData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        positionLendingTokenData[_nftId].pop();
        hashMapPositionLending[_getHash(_nftId, _poolToken)] = false;
    }

    function _deleteLastPositionBorrowData(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        positionBorrowTokenData[_nftId].pop();
        hashMapPositionBorrow[_getHash(_nftId, _poolToken)] = false;
    }

    function getCollateralState(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].collaterized;
    }

    function _borrowShareEquivalent(
        address _poolToken,
        uint256 _lendingShares
    )
        internal
        view
        returns (uint256)
    {
        return _lendingShares
            * getPseudoTotalPool(_poolToken)
            * getTotalBorrowShares(_poolToken)
            / getTotalDepositShares(_poolToken)
            / getPseudoTotalBorrowAmount(_poolToken);
    }

    function curveSecurityCheck(
        address _poolAddress
    )
        isolationOrFeeManager
        external
    {
        _curveSecurityCheck(
            _poolAddress
        );
    }

    function _curveSecurityCheck(
        address _poolAddress
    )
        internal
    {
        WISE_SECURITY.curveSecurityCheck(
            _poolAddress
        );
    }

    function checkLendingDataEmpty(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (bool)
    {
        return userLendingData[_nftId][_poolToken].shares == 0
            && positionPureCollateralAmount[_nftId][_poolToken] == 0;
    }

    function _calculateNewBorrowRate(
        address _poolToken
    )
        internal
    {
        uint256 pole = borrowRatesData[_poolToken].pole;

        uint256 utilization = globalPoolData[_poolToken].utilization;

        uint256 baseDivider = pole
            * (pole - utilization);

        _setBorrowRate(
            _poolToken,
            borrowRatesData[_poolToken].multiplicativFactor
                * PRECISION_FACTOR_E18
                * utilization
                / baseDivider
        );
    }

    function _newBorrowRate(
        address _poolToken
    )
        internal
    {
        _updateUtilization(
            _poolToken
        );

        _calculateNewBorrowRate(
            _poolToken
        );

        if (_aboveThreshold(_poolToken) == true) {
            _scalingAlgorithm(
                _poolToken
            );
        }
    }

    function _aboveThreshold(
        address _poolToken
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp - _getTimeStampScaling(_poolToken) >= THREE_HOURS;
    }

    /**
     * @dev function that tries to maximise totalDepositShares of the pool. Reacting to negative and positive
     * feedback by changing the resonance factor of the pool. Method similar to one parameter monte carlo methods
     */
    function _scalingAlgorithm(
        address _poolToken
    )
        internal
    {
        uint256 totalShares = getTotalDepositShares(
            _poolToken
        );

        if (algorithmData[_poolToken].maxValue <= totalShares) {

            _newMaxPoolShares(
                _poolToken,
                totalShares
            );

            _saveUp(
                _poolToken,
                totalShares
            );

            return;
        }

        _resonanceOutcome(_poolToken, totalShares) == true
            ? _resetResonanceFactor(_poolToken, totalShares)
            : _updateResonanceFactor(_poolToken, totalShares);

        _saveUp(
            _poolToken,
            totalShares
        );
    }

    /**
     * @dev sets the new max value in shares and saves the corresponding resonance factor.
     */
    function _newMaxPoolShares(
        address _poolToken,
        uint256 _shareValue
    )
        internal
    {
        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _setBestPole(
            _poolToken,
            borrowRatesData[_poolToken].pole
        );
    }

    function _saveUp(
        address _poolToken,
        uint256 _shareValue
    )
        internal
    {
        _setPreviousValue(
            _poolToken,
            _shareValue
        );

        _setTimeStampScaling(
            _poolToken,
            block.timestamp
        );
    }

    /**
     * @dev returns bool to determine if resonance factor needs to be reset to last best value.
     */
    function _resonanceOutcome(
        address _poolToken,
        uint256 _shareValue
    )
        internal
        view
        returns (bool)
    {
        return _shareValue < THRESHOLD_RESET_RESONANCE_FACTOR
            * algorithmData[_poolToken].maxValue
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev resettets resonance factor to old best value when system evolves into too bad state.
     * sets current totalDepositShares amount to new maxPoolShares to exclude eternal loops and that
     * unorganic peaks do not set maxPoolShares forever
     */
    function _resetResonanceFactor(
        address _poolToken,
        uint256 _shareValue
    )
        internal
    {
        _setPole(
            _poolToken,
            algorithmData[_poolToken].bestPole
        );

        _setMaxValue(
            _poolToken,
            _shareValue
        );

        _revertDirectionSteppingState(
            _poolToken
        );
    }

    /**
     * @dev reverts the flag for stepping direction from scaling algorithm
     */
    function _revertDirectionSteppingState(
        address _poolToken
    )
        internal
    {
        _setIncreasePole(
            _poolToken,
            !algorithmData[_poolToken].increasePole
        );
    }

    /**
     * @dev function combining all possible stepping scenarios. Depending
     * how share values has changed compared to last time
     */
    function _updateResonanceFactor(
        address _poolToken,
        uint256 _shareValues
    )
        internal
    {
        _shareValues < THRESHOLD_SWITCH_DIRECTION * algorithmData[_poolToken].previousValue / PRECISION_FACTOR_E18
            ? _reversedChangingResonanceFactor(_poolToken)
            : _changingResonanceFactor(_poolToken);
    }

    /**
     * @dev does a revert stepping and swaps stepping state in opposite flag
     */
    function _reversedChangingResonanceFactor(
        address _poolToken
    )
        internal
    {
        algorithmData[_poolToken].increasePole
            ? _decreaseResonanceFactor(_poolToken)
            : _increaseResonanceFactor(_poolToken);

        _revertDirectionSteppingState(
            _poolToken
        );
    }

    /**
     * @dev increasing or decresing resonance factor depending on flag value
    */
    function _changingResonanceFactor(
        address _poolToken
    )
        internal
    {
        algorithmData[_poolToken].increasePole
            ? _increaseResonanceFactor(_poolToken)
            : _decreaseResonanceFactor(_poolToken);
    }

    /**
     * @dev stepping function increasing the
     * resonance factor depending on the time
     * past in the last time interval.
     * Checks if current resonance factor is bigger than max value.
     * If this is the case sets current value to maximal value
     */
    function _increaseResonanceFactor(
        address _poolToken
    )
        internal
    {
        BorrowRatesEntry memory borrowData = borrowRatesData[
            _poolToken
        ];

        uint256 delta = (block.timestamp - _getTimeStampScaling(_poolToken))
            * borrowData.deltaPole;

        uint256 sum = borrowData.pole
            + delta;

        uint256 setValue = sum > borrowData.maxPole
            ? borrowData.maxPole
            : sum;

        _setPole(
            _poolToken,
            setValue
        );
    }

    /**
     * @dev stepping function decresing the resonance factor depending on the time past in the last
     * time interval. Checks if current resonance factor undergoes the min value. If this is the case
     * sets current value to minimal value
     */
    function _decreaseResonanceFactor(
        address _poolToken
    )
        internal
    {
        uint256 minValue = borrowRatesData[_poolToken].minPole;

        uint256 delta = borrowRatesData[_poolToken].deltaPole
            * (block.timestamp - _getTimeStampScaling(_poolToken));

        uint256 sub = borrowRatesData[_poolToken].pole > delta
            ? borrowRatesData[_poolToken].pole - delta
            : 0;

        uint256 setValue = sub < minValue
            ? minValue
            : sub;

        _setPole(
            _poolToken,
            setValue
        );
    }

    function _removeLendingTokenDataIfNotEmpty(
        uint256 _nftId,
        address _poolToken
    )
        internal
    {
        if (_nftId == 0) {
            return;
        }

        if (checkLendingDataEmpty(_nftId, _poolToken) == false) {
            return;
        }

        _removePositionData(
            _nftId,
            _poolToken,
            getPositionLendingTokenLength,
            getPositionLendingTokenByIndex,
            _deleteLastPositionLendingData,
            true
        );
    }

    function _updatePoolStorage(
        address _poolToken,
        uint256 _amount,
        uint256 _shares,
        function(address, uint256) functionAmountA,
        function(address, uint256) functionAmountB,
        function(address, uint256) functionSharesA
    )
        internal
    {
        functionAmountA(
            _poolToken,
            _amount
        );

        functionAmountB(
            _poolToken,
            _amount
        );

        functionSharesA(
            _poolToken,
            _shares
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "./InterfaceHub/IWETH.sol";
import "./InterfaceHub/IFeeManager.sol";
import "./InterfaceHub/IPositionNFTs.sol";
import "./InterfaceHub/IWiseSecurity.sol";
import "./InterfaceHub/IWiseLiquidation.sol";
import "./InterfaceHub/IWiseOracleHub.sol";
import "./InterfaceHub/IEventHandler.sol";

import "./TransferHub/TransferHelper.sol";

error AlreadyCreated();
error InvalidCaller();

contract DeclarationsWiseLending {

    constructor(
        address _lendingMaster,
        address _governance,
        address _wiseOracleHubAddress,
        address _eventHandler,
        address _nftContract,
        address _wethContract
    )
    {
        lendingMaster = _lendingMaster;
        governance = _governance;

        WETH_ADDRESS = _wethContract;

        WETH = IWETH(
            _wethContract
        );

        WISE_ORACLE = IWiseOracleHub(
            _wiseOracleHubAddress
        );

        POSITION_NFT = IPositionNFTs(
            _nftContract
        );

        eventHandler = IEventHandler(
            _eventHandler
        );

        eventHandler.setWiseLending(
            address(this)
        );
    }

    function setSecurity(
        address _wiseSecurity
    )
        external
    {
        // @TODO: add onlyAdmin or something
        require(
            address(WISE_SECURITY) == ZERO_ADDRESS,
            "DeclarationsWiseLending: ALREADY_SET"
        );

        WISE_SECURITY = IWiseSecurity(
            _wiseSecurity
        );

        FEE_MANAGER = IFeeManager(
            WISE_SECURITY.FEE_MANAGER()
        );

        POSITION_ID_FEE_MANAGER = FEE_MANAGER.FEE_MASTER_NFT_ID();

        WISE_LIQUIDATION = IWiseLiquidation(
            WISE_SECURITY.WISE_LIQUIDATION()
        );
    }

    function _emitEvent(
        bytes memory _data
    )
        internal
    {
        eventHandler.emitEvent(
            _data
        );
    }

    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }

    address public governance;
    address public lendingMaster;

    IEventHandler public immutable eventHandler;

    // uint256 public immutable POSITION_ID_FEE_MANAGER;
    uint256 POSITION_ID_FEE_MANAGER;

    // IWiseLiquidation public immutable WISE_LIQUIDATION;
    IWiseLiquidation public WISE_LIQUIDATION;

    // IFeeManager public immutable FEE_MANAGER;
    IFeeManager public FEE_MANAGER;

    // IWiseSecurity public immutable WISE_SECURITY;
    IWiseSecurity public WISE_SECURITY;

    IWiseOracleHub public immutable WISE_ORACLE;
    IPositionNFTs public immutable POSITION_NFT;

    struct LendingEntry {
        uint256 shares;
        bool collaterized;
    }

    struct BorrowRatesEntry {
        uint256 pole;
        uint256 deltaPole;
        uint256 minPole;
        uint256 maxPole;
        uint256 multiplicativFactor;
    }

    struct AlgorithmEntry {
        uint256 bestPole;
        uint256 maxValue;
        uint256 previousValue;
        bool increasePole;
    }

    struct GlobalPoolEntry {
        uint256 totalPool;
        uint256 utilization;
        uint256 totalBareToken;
        uint256 poolFee;
    }

    struct LendingPoolEntry {
        uint256 pseudoTotalPool;
        uint256 totalDepositShares;
        uint256 collateralFactor;
    }

    struct BorrowPoolEntry {
        bool allowBorrow;
        uint256 pseudoTotalBorrowAmount;
        uint256 borrowPercentageCap;
        uint256 totalBorrowShares;
        uint256 borrowRate;
    }

    struct TimestampsPoolEntry {
        uint256 timeStamp;
        uint256 timeStampScaling;
    }

    // User mappings ------------------------------------------

    // open question:
    // decide about positionLendingTokenData/positionBorrowTokenData
    // and userBorrowData/userLendingData

    // see when not to loop through (introduce if -> return);
    mapping(uint256 => address[]) public positionLendingTokenData;
    mapping(uint256 => address[]) public positionBorrowTokenData;

    // mapping (address => mapping(address => uint256)) public userBorrowData;
    // @TODO: renames
    mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
    mapping(uint256 => mapping(address => LendingEntry)) public userLendingData;
    mapping(uint256 => mapping(address => uint256)) public positionPureCollateralAmount;

    mapping(uint256 => mapping(address => mapping(address => uint256))) public allowanceBorrow;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public allowanceWithdraw;
    mapping(address => uint256) public maxDepositValueToken;

    // Struct mappings -------------------------------------
    mapping(address => BorrowRatesEntry) public borrowRatesData;
    mapping(address => AlgorithmEntry) public algorithmData;
    mapping(address => GlobalPoolEntry) public globalPoolData;
    mapping(address => LendingPoolEntry) public lendingPoolData;
    mapping(address => BorrowPoolEntry) public borrowPoolData;
    mapping(address => TimestampsPoolEntry) public timestampsPoolData;

    // Bool mappings --------------------------------------
    mapping(uint256 => bool) public positionLocked;
    mapping(address => bool) public veryfiedIsolationPool;
    mapping(uint256 => mapping(address => bool)) public isolationPoolRegistered;

    // Hash mappings ---------------------------
    mapping(bytes32 => bool) hashMapPositionBorrow;
    mapping(bytes32 => bool) hashMapPositionLending;

    address constant ZERO_ADDRESS = address(0);

    IWETH immutable WETH;
    address immutable WETH_ADDRESS;

    // PRECISION FACTORS ------------------------------------
    uint256 constant PRECISION_FACTOR_E16 = 0.01 ether;
    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant PRECISION_FACTOR_E36 = PRECISION_FACTOR_E18 * PRECISION_FACTOR_E18;

    // TIME CONSTANTS --------------------------------------
    uint256 constant ONE_YEAR = 52 weeks;
    uint256 constant THREE_HOURS = 10800;

    // SCALING ALGORITHM CONSTANTS -------------------------
    uint256 constant THRESHOLD_RESET_RESONANCE_FACTOR = 75 * PRECISION_FACTOR_E16;
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90 * PRECISION_FACTOR_E16;

    // Two months in seconds:
    // Norming change in resonanz factor that it steps from min to max value
    // within two month (if nothing changes)
    uint256 constant NORMALISATION_FACTOR = 4838400;
    uint256 constant UPPER_BOUND_MAX_RATE = 500 * PRECISION_FACTOR_E16;
    uint256 constant LOWER_BOUND_MAX_RATE = 150 * PRECISION_FACTOR_E16;

    // AAVE PARAMERTERS -------------------------------------
    uint256 constant UINT256_MAX = type(uint256).max;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.19;

library Babylonian {

    function sqrt(
        uint256 x
    )
        internal
        pure
        returns (uint256)
    {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external;
        // returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IFlashBorrower {

    function onFlashLoan(
        address _initiator,
        address[] memory _tokenList,
        uint256[] memory _amountList,
        uint256[] memory feeList,
        bytes[] calldata _data
    )
        external
        returns (bytes32);
}

interface IFlashLender {

    function maxFlashLoan(
        address _tokenAddress
    )
        external
        view
        returns (uint256);

    function flashFee(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        view
        returns (uint256);

    function flashLoan(
        IFlashBorrower _receiver,
        address[] memory _tokenList,
        uint256[] memory _amountList,
        bytes[] calldata _data
    )
        external
        returns (bool);
}

// SPDX-License-Identifier: -- WISE --
pragma solidity =0.8.19;

import "./DeclarationsWiseLending.sol";

abstract contract WiseLowLevelHelper is DeclarationsWiseLending {

    modifier onlyLiquidation() {
        _onlyLiquidation();
        _;
    }

    modifier onlyFeeManager() {
        _onlyFeeManager();
        _;
    }

    modifier isolationOrFeeManager() {
        _isolationOrFeeManager();
        _;
    }

    function _isolationOrFeeManager()
        private
        view
    {
        if (msg.sender == address(FEE_MANAGER)) {
            return;
        }

        if (msg.sender == address(WISE_LIQUIDATION)) {
            return;
        }

        if (veryfiedIsolationPool[msg.sender] == true) {
            return;
        }

        revert InvalidCaller();
    }

    function _onlyFeeManager()
        private
        view
    {
        if (msg.sender == address(FEE_MANAGER)) {
            return;
        }

        revert InvalidCaller();
    }

    function _onlyLiquidation()
        private
        view
    {
        if (msg.sender == address(WISE_LIQUIDATION)) {
            return;
        }

        revert InvalidCaller();
    }

    function getTotalPool(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return globalPoolData[_poolToken].totalPool;
    }

    function getPseudoTotalPool(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return lendingPoolData[_poolToken].pseudoTotalPool;
    }

    function getTotalBareToken(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return globalPoolData[_poolToken].totalBareToken;
    }

    function getPseudoTotalBorrowAmount(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return borrowPoolData[_poolToken].pseudoTotalBorrowAmount;
    }

    function getTotalDepositShares(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return lendingPoolData[_poolToken].totalDepositShares;
    }

    function getTotalBorrowShares(
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return borrowPoolData[_poolToken].totalBorrowShares;
    }

    function getPositionLendingShares(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return userLendingData[_nftId][_poolToken].shares;
    }

    function getPositionBorrowShares(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return userBorrowShares[_nftId][_poolToken];
    }

    function getPureCollateralAmount(
        uint256 _nftId,
        address _poolToken
    )
        public
        view
        returns (uint256)
    {
        return positionPureCollateralAmount[_nftId][_poolToken];
    }

    // -----------------------------
    // BASIC INTERNAL-VIEW FUNCTIONS
    // -----------------------------

    function _getTimeStamp(
        address _poolToken
    )
        internal
        view
        returns (uint256)
    {
        return timestampsPoolData[_poolToken].timeStamp;
    }

    function _getTimeStampScaling(
        address _poolToken
    )
        internal
        view
        returns (uint256)
    {
        return timestampsPoolData[_poolToken].timeStampScaling;
    }

    function getPositionLendingTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        public
        view
        returns (address)
    {
        return positionLendingTokenData[_nftId][_index];
    }

    function getPositionLendingTokenLength(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return positionLendingTokenData[_nftId].length;
    }

    function getPositionBorrowTokenByIndex(
        uint256 _nftId,
        uint256 _index
    )
        public
        view
        returns (address)
    {
        return positionBorrowTokenData[_nftId][_index];
    }

    function getPositionBorrowTokenLength(
        uint256 _nftId
    )
        public
        view
        returns (uint256)
    {
        return positionBorrowTokenData[_nftId].length;
    }

    // -----------------------------
    // BASIC INTERNAL-SET FUNCTIONS
    // -----------------------------

    function _setMaxValue(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        algorithmData[_poolToken].maxValue = _value;
    }

    function _setPreviousValue(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        algorithmData[_poolToken].previousValue = _value;
    }

    function _setBestPole(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        algorithmData[_poolToken].bestPole = _value;
    }

    function _setIncreasePole(
        address _poolToken,
        bool _state
    )
        internal
    {
        algorithmData[_poolToken].increasePole = _state;
    }

    function _setPole(
        address _poolToken,
        uint256 _value
    )
        internal
    {
        borrowRatesData[_poolToken].pole = _value;
    }

    function _increaseTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalPool += _amount;
    }

    function _decreaseTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalPool -= _amount;
    }

    function _increaseTotalDepositShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].totalDepositShares += _amount;
    }

    function _decreaseTotalDepositShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].totalDepositShares -= _amount;
    }

    function _increasePseudoTotalBorrowAmount(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].pseudoTotalBorrowAmount += _amount;
    }

    function _decreasePseudoTotalBorrowAmount(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].pseudoTotalBorrowAmount -= _amount;
    }

    function _increaseTotalBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].totalBorrowShares += _amount;
    }

    function _decreaseTotalBorrowShares(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].totalBorrowShares -= _amount;
    }

    function _increasePseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].pseudoTotalPool += _amount;
    }

    function _decreasePseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        lendingPoolData[_poolToken].pseudoTotalPool -= _amount;
    }

    function _setBorrowRate(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        borrowPoolData[_poolToken].borrowRate = _amount;
    }

    function _setTimeStamp(
        address _poolToken,
        uint256 _time
    )
        internal
    {
        timestampsPoolData[_poolToken].timeStamp = _time;
    }

    function _setTimeStampScaling(
        address _poolToken,
        uint256 _time
    )
        internal
    {
        timestampsPoolData[_poolToken].timeStampScaling = _time;
    }

    function _increaseTotalBareToken(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalBareToken += _amount;
    }

    function _decreaseTotalBareToken(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        globalPoolData[_poolToken].totalBareToken -= _amount;
    }

    function _reduceAllowance(
        mapping(uint256 => mapping(address => mapping(address => uint256))) storage allowanceMapping,
        uint256 _nftIdUser,
        address _poolToken,
        address _spender,
        uint256 _amount
    )
        internal
    {
        if (allowanceMapping[_nftIdUser][_poolToken][_spender] != UINT256_MAX) {
            allowanceMapping[_nftIdUser][_poolToken][_spender] -= _amount;
        }
    }

    function _decreasePositionMappingValue(
        mapping(uint256 => mapping(address => uint256)) storage userMapping,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        userMapping[_nftId][_poolToken] -= _amount;
    }

    function _increasePositionMappingValue(
        mapping(uint256 => mapping(address => uint256)) storage userMapping,
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        userMapping[_nftId][_poolToken] += _amount;
    }

    function decreaseCollateralLiquidation(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        onlyLiquidation
    {
        _decreasePositionMappingValue(
            positionPureCollateralAmount,
            _nftId,
            _poolToken,
            _amount
        );
    }

    function decreaseTotalBareTokenLiquidation(
        address _poolToken,
        uint256 _amount
    )
        external
        onlyLiquidation
    {
        _decreaseTotalBareToken(
            _poolToken,
            _amount
        );
    }

    function _increaseTotalAndPseudoTotalPool(
        address _poolToken,
        uint256 _amount
    )
        internal
    {
        _increasePseudoTotalPool(
            _poolToken,
            _amount
        );

        _increaseTotalPool(
            _poolToken,
            _amount
        );
    }

    function setPoolFee(
        address _poolToken,
        uint256 _newFee
    )
        external
        onlyFeeManager
    {
        globalPoolData[_poolToken].poolFee = _newFee;
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

import "../InterfaceHub/IERC20.sol";

contract TransferHelper {

    /**
     * @dev
     * Allows to execute transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transfer.selector,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        IERC20 token = IERC20(
            _token
        );

        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Helper function to do the token call
     */
    function _callOptionalReturn(
        address _token,
        bytes memory _data
    )
        private
    {
        (
            bool success,
            bytes memory returndata
        ) = _token.call(_data);

        require(
            success,
            "TransferHelper: CALL_FAILED"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(
                    returndata,
                    (bool)
                ),
                "TransferHelper: OPERATION_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

interface IEventHandler {

    function emitEvent(
        bytes memory _data
    )
        external;

    function setWiseLending(
        address _wiseLending
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IWiseOracleHub {

    function getTokensFromUSD(
        address _tokenAddress,
        uint256 _usdValue
    )
        external
        view
        returns (uint256);

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);

    function chainLinkIsDead(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    function getTokenUSDFiat(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IWiseLiquidation {

    function coreLiquidationIsolationPools(
        uint256 _nftId,
        uint256 _nftIdLiquidator,
        address _caller,
        address _tokenToPayback,
        address _tokenToRecieve,
        uint256 _paybackAmount,
        uint256 _shareAmountToPay
    )
        external
        returns (uint256 reveiveAmount);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

struct curveSwapStruct {
    uint256 curvePoolTokenIndexFrom;
    uint256 curvePoolTokenIndexTo;
    uint256 curveMetaPoolTokenIndexFrom;
    uint256 curveMetaPoolTokenIndexTo;
    uint256 curvePoolSwapAmount;
    uint256 curveMetaPoolSwapAmount;
}

interface IWiseSecurity {

    function checkBadDebt(
        uint256 _nftId
    )
        external;

    function getCollateralOfTokenUSD(
        uint256 _nftId,
        address _poolToken
    )
        external
        view
        returns (uint256);

    function checksLiquidation(
        uint256 _nftIdLiquidate,
        address _caller,
        address _tokenToPayback,
        uint256 _shareAmountToPay
    )
        external
        view;

    function onlyIsolationPool(
        address _poolAddress
    )
        external
        view;

    function overallUSDBorrow(
        uint256 _nftId
    )
        external
        view
        returns (uint256);

    function overallUSDCollateralsBare(
        uint256 _nftId
    )
        external
        view
        returns (uint256 amount);

    function checkRegisteredForPool(
        uint256 _nftId,
        address _isolationPool
    )
        external
        view;

    function FEE_MANAGER()
        external
        returns (address);

    function WISE_LIQUIDATION()
        external
        returns (address);

    function curveSecurityCheck(
        address _poolAddress
    )
        external;

    function prepareCurvePools(
        address _poolToken,
        address _curvePool,
        address _curveMetaPool,
        curveSwapStruct memory _curveSwapStruct
    )
        external;

    function setUnderlyingPoolTokensFromPoolToken(
        address _poolToken,
        address[] memory _underlyingTokens
    )
        external;

    function checksDeposit(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksBorrow(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksSolelyWithdraw(
        uint256 _nftId,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkOwnerPosition(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checksCollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolAddress
    )
        external
        view;

    function checksDecollateralizeDeposit(
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken
    )
        external
        view;

    function checkBorrowLimit(
        uint256 _nftId,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checkPositionLocked(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkPaybackLendingShares(
        uint256 _nftIdReceiver,
        uint256 _nftIdCaller,
        address _caller,
        address _poolToken,
        uint256 _amount
    )
        external
        view;

    function checksRegistrationIsolationPool(
        uint256 _nftId,
        address _caller,
        address _isolationPool
    )
        external
        view;

    function checkUnregister(
        uint256 _nftId,
        address _caller
    )
        external
        view;

    function checkOnlyMaster(
        address _caller
    )
        external
        view;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IPositionNFTs {

    function ownerOf(
        uint256 _nftId
    )
        external
        view
        returns (address);

    function getOwner(
        uint256 _nftId
    )
        external
        view
        returns (address);


    function totalSupply()
        external
        view
        returns (uint256);

    function mintPosition()
        external;

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        view
        returns (uint256);

    function mintPositionForUser(
        address _user
    )
        external
        returns (uint256);
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

interface IFeeManager {

    function setBadDebtUserLiquidation(
        uint256 _nftId,
        uint256 _amount
    )
        external;

    function increaseTotalBadDebtLiquidation(
        uint256 _amount
    )
        external;

    function FEE_MASTER_NFT_ID()
        external
        returns (uint256);

    function addPoolTokenAddress(
        address _poolToken
    )
        external;
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.19;

// import "./IERC20.sol";

interface IWETH {

    function deposit()
        external
        payable;

    function withdraw(
        uint256
    )
        external;
}