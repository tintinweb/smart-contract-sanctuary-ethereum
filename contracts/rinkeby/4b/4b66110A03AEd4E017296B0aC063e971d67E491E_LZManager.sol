//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

import "./LZManagerAdmin.sol";
import "../satellite/pToken/PTokenMessageHandler.sol";

import "../interfaces/IHelper.sol";
import "./interfaces/ILayerZeroManager.sol";
import "../util/CommonModifiers.sol";

contract LZManager is ILayerZeroManager, LZManagerAdmin, CommonModifiers {
    constructor(
        address _layerZeroEndpoint,
        address _loanAgent,
        uint16 _cid
    ) {
        owner = msg.sender;
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        loanAgent = ILoanAgent(_loanAgent);
        cid = _cid;
    }

    function lzSend(
        uint16 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        address _zroPaymentAddr,
        bytes memory _adapterParams
    ) public payable override onlyAuth {
        // if srcChain == dstChain, process the send directly instead of through LZ
        layerZeroEndpoint.send{value: msg.value}(
            _dstChainId, // destination LayerZero chainId
            abi.encodePacked(_destination), // send to this address on the destination
            params, // bytes payload
            _refundAddress, // refund address
            _zroPaymentAddr, // future parameter
            _adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _fromAddress,
        uint64, /* _nonce */
        bytes memory _payload
    ) external override onlyLZ onlySrc(_srcChainId, _fromAddress) nonReentrant {
        //require(masterState); // master state must be defined to receive
        IHelper.Selector selector;
        assembly {
            selector := mload(add(_payload, 0x20))
        }

        if (IHelper.Selector.MASTER_DEPOSIT == selector) {
            // ! Workaround for deep stack issue, pass payload directly
            masterState.masterDeposit(
                _payload,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_REDEEM_ALLOWED == selector) {
            (, address _pToken, address _user, uint256 _newAmount) = abi.decode(
                _payload,
                (uint8, address, address, uint256)
            );

            masterState.redeemAllowed(_user, _pToken, _srcChainId, _newAmount);
        } else if (IHelper.Selector.FB_REDEEM == selector) {
            ( , address _pToken,
                address _redeemer,
                uint256 _redeemAmount
            ) = abi.decode(_payload, (uint8, address, address, uint256));

            PTokenMessageHandler(_pToken).completeRedeem(
                _redeemer,
                _redeemAmount
            );
        } else if (IHelper.Selector.MASTER_REPAY == selector) {
            // ! Workaround for deep stack issue, pass payload directly
            masterState.masterRepay(
                _payload,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_BORROW_ALLOWED == selector) {
            (, address _user, uint256 _borrowAmount) = abi.decode(
                _payload,
                (uint8, address, uint256)
            );

            masterState.borrowAllowed(_user, _srcChainId, _borrowAmount);
        } else if (IHelper.Selector.FB_BORROW == selector) {
            ( , address _user,
                uint256 _newAmount
            ) = abi.decode(_payload, (uint8, address, uint256));

            loanAgent.borrowApproved(_user, _newAmount);
        } else if (IHelper.Selector.SATELLITE_LIQUIDATE_BORROW == selector) {
            ( , address borrower,
                address liquidator,
                uint256 seizeTokens,
                address pTokenCollateral
            ) = abi.decode(
                _payload,
                (uint8, address, address, uint256, address)
            );

            PTokenMessageHandler(pTokenCollateral).seize(
                liquidator,
                borrower,
                seizeTokens
            );
        } else if (IHelper.Selector.MASTER_TRANSFER_ALLOWED == selector) {
            masterState.transferAllowed(_payload, _srcChainId);
            // TODO: ^This was to avoid 'Stack too deep'. Consider adding a payload parser or similar
        } else if (IHelper.Selector.FB_COMPLETE_TRANSFER == selector) {
            ( , address _pToken,
                address _spender,
                address _user,
                address _dst,
                uint256 _amount
            ) = abi.decode(
                _payload,
                (uint8, address, address, address, address, uint256)
            );

            PTokenMessageHandler(_pToken).completeTransfer(
                _spender,
                _user,
                _dst,
                _amount
            );
        }

        // assembly {
        //     function deposit(payload, scid) {
        //         let x := mload(0x40)
        //         // sig
        //         mstore(x, MASTER_DEPOSIT)
        //         // store caller address
        //         let cal := mload(payload)
        //         mstore(add(x, 0x04), mload(add(payload, cal)))
        //         // store ptoken address
        //         let ptl := mload(add(payload, 2))
        //         mstore(add(x, add(0x04, cal)), mload(add(add(payload, 0x02), mload(add(payload, 0x02)))))
        //         let os := add(0x04, add(cal, ptl))
        //         // store chainId
        //         mstore(add(x, os), scid)
        //         // store pAmount
        //         // NOTE: Right now this is hard coded to be slot 4 and 5
        //         // undefined behaviour occurs if ptl or os is greater than 32
        //         // Can address ever be greater than 32 bytes long?
        //         mstore(add(x, add(os, 0x02)), mload(add(payload, 0x04)))
        //         mstore(add(x, add(os, 0x22)), mload(add(payload, 0x05)))

        //         if iszero(call(gas(), sload(masterState.slot), 0, x, add(os, 0x42), 0, 0)) {
        //             returndatacopy(0, 0, returndatasize())
        //             revert(0, returndatasize())
        //         }
        //     }

        //     function withdraw() {}
        //     function etc() {}

        //     let selector := shl(0xF8, add(_payload, 0x20))

        //     /// @dev: See ../Interfaces/IHelper.sol -> Selector {  }
        //     switch selector
        //     case 0 {
        //         deposit(_payload, _srcChainId)
        //     }
        //     case 1 {
        //         withdraw()
        //     }
        //     case 2 {
        //         etc()
        //     }
        //     default {
        //         // revert as invalid selector
        //     }
        // }
    }

    fallback() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    /// @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    /// @param _dstChainId - the destination chain identifier
    /// @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    /// @param _payload - a custom bytes payload to send to the destination contract
    /// @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    /// @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    /// @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /// @notice used by the messaging library to publish verified payload
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source contract (as bytes) at the source chain
    /// @param _dstAddress - the address on destination chain
    /// @param _nonce - the unbound message ordering nonce
    /// @param _gasLimit - the gas limit for external contract execution
    /// @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    /// @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    /// @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    /// @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    /// @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    /// @param _dstChainId - the destination chain identifier
    /// @param _userApplication - the user app address on this EVM chain
    /// @param _payload - the custom message to send over LayerZero
    /// @param _payInZRO - if false, user app pays the protocol fee in native token
    /// @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    /// @notice the interface to retry failed message on this Endpoint destination
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    /// @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    /// @notice query if any STORED payload (message blocking) at the endpoint.
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    /// @notice query if the _libraryAddress is valid for sending msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the _libraryAddress is valid for receiving msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the non-reentrancy guard for send() is on
    /// @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    /// @notice query if the non-reentrancy guard for receive() is on
    /// @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    /// @notice get the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _userApplication - the contract address of the user application
    /// @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    /// @notice get the send() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    /// @notice get the lzReceive() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LZManagerModifiers.sol";

abstract contract LZManagerAdmin is LZManagerStorage, LZManagerModifiers {
    function disown(address overtaker) public onlyOwner {
        owner = overtaker;
    }

    function _setSrc(
        uint16 srcChain,
        bytes calldata _oldSrcAddr,
        bytes calldata _newSrcAddr /* onlyOwner */
    ) internal {
        require(
            keccak256(srcContracts[srcChain]) == keccak256(_oldSrcAddr),
            "Mismatch on old contract"
        );
        srcContracts[srcChain] = _newSrcAddr;
    }

    function setSrc(
        uint16 srcChain,
        bytes calldata _oldSrcAddr,
        bytes calldata _newSrcAddr
    ) public onlyOwner {
        _setSrc(srcChain, _oldSrcAddr, _newSrcAddr);
    }

    function setManySrc(
        uint16[] calldata srcChain,
        bytes[] calldata _oldSrcAddr,
        bytes[] calldata _newSrcAddr
    ) public onlyOwner {
        require(
            srcChain.length == _oldSrcAddr.length &&
                _oldSrcAddr.length == _newSrcAddr.length,
            "Bad lengths"
        );
        for (uint16 i; i < srcChain.length; i++) {
            _setSrc(srcChain[i], _oldSrcAddr[i], _newSrcAddr[i]);
        }
    }

    function _changeAuth(address contractAddr, bool status)
        internal
    /* onlyOwner */
    {
        authContracts[contractAddr] = status;
    }

    function changeAuth(address contractAddr, bool status) public onlyOwner {
        _changeAuth(contractAddr, status);
    }

    function changeManyAuth(
        address[] calldata contractAddr,
        bool[] calldata status
    ) public onlyOwner {
        require(contractAddr.length == status.length, "Mismatch len");
        for (uint8 i; i < contractAddr.length; i++) {
            _changeAuth(contractAddr[i], status[i]);
        }
    }

    function setMasterState(address _masterState) public onlyOwner {
        masterState = MasterMessageHandler(_masterState);
    }

    function addSrc(uint16 srcChain, address _newSrcAddr) public onlyOwner() {
        srcContracts[srcChain] = abi.encodePacked(_newSrcAddr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "./PTokenStorage.sol";
import "./PTokenInternals.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract PTokenMessageHandler is
    IPToken,
    PTokenModifiers,
    PTokenEvents,
    CommonModifiers
{
    function _redeemAllowed(
        address user,
        uint256 redeemAmount
    ) internal virtual override {
        bytes memory payload = abi.encode(
            IHelper.MRedeemAllowed(
                IHelper.Selector.MASTER_REDEEM_ALLOWED,
                address(this),
                user,
                redeemAmount
            )
        );

        middleLayer.lzSend{value: msg.value}(
            masterCID,
            abi.encodePacked(masterMiddleLayer), // send to this address on the destination
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0), // future parameter
            new bytes(0) // adapterParams (see "Advanced Features")
        );
    }

    function _sendMint(
        uint256 mintTokens
    ) internal virtual override {
        bytes memory payload = abi.encode(IHelper.MDeposit({
            selector: IHelper.Selector.MASTER_DEPOSIT,
            user: msg.sender,
            pToken: address(this),
            previousAmount: accountTokens[msg.sender],
            amountIncreased: mintTokens
        }));
        middleLayer.lzSend{ value: msg.value }(
            masterCID,
            abi.encodePacked(masterMiddleLayer),
            payload,
            payable(msg.sender),
            address(0),
            new bytes(0)
        );
    }

    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal virtual override {
        require(src != dst, "BAD_INPUT | SELF_TRANSFER_NOT_ALLOWED");
        require(tokens < accountTokens[src], "Requested amount too high");

        bytes memory payload = abi.encode(
            IHelper.MTransferAllowed(
                uint8(IHelper.Selector.MASTER_TRANSFER_ALLOWED),
                address(this),
                spender,
                src,
                dst,
                tokens
            )
        );

        middleLayer.lzSend{value: msg.value}(
            masterCID,
            abi.encodePacked(masterMiddleLayer), // send to this address on the destination
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0x0), // future parameter
            new bytes(0) // adapterParams (see "Advanced Features")
        );

        // satelliteRiskEngine.transferAllowed(
        //     address(this),
        //     spender,
        //     src,
        //     dst,
        //     tokens
        // );

        emit TransferInitiated(src, dst, tokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of pTokens to seize
     */
    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) public nonReentrant onlyMid() {
        uint256 protocolSeizeTokens = (seizeTokens * protocolSeizeShare) / 1e8;
        uint256 protocolSeizeAmount = _exchangeRateStored() * protocolSeizeTokens;
        uint256 liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        totalReserves += protocolSeizeAmount;
        totalSupply -= protocolSeizeTokens;
        accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
        accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
        emit Transfer(borrower, address(this), protocolSeizeTokens);
        emit ReservesAdded(
            address(this),
            protocolSeizeAmount,
            totalReserves
        );

        /* We call the defense hook */
        // unused function
        // comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);
    }

    // TODO: Only Middle layer
    function completeRedeem(
        address redeemer,
        uint256 redeemTokens
    ) public onlyMid() {
        // /* Verify market's block number equals current block number */
        // NOTE: Why was this check removed?
        // if (accrualBlockNumber != getBlockNumber()) {
        //     return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
        // }

        /*
        * We calculate the new total supply and redeemer balance, checking for underflow:
        *  totalSupplyNew = totalSupply - redeemTokens
        *  accountTokensNew = accountTokens[redeemer] - redeemTokens
        */
        require(totalSupply >= redeemTokens, "INSUFFICIENT_LIQUIDITY");
        uint256 totalSupplyNew = totalSupply - redeemTokens;

        require(
            accountTokens[redeemer] >= redeemTokens,
            "Trying to redeem too much"
        );
        uint256 accountTokensNew = accountTokens[redeemer] - redeemTokens;

        // TODO: make sure we cannot exploit this by having an exchange rate difference in redeem and complete redeem functions
        uint256 exchangeRate = _exchangeRateStored();

        uint256 redeemAmount = (exchangeRate * redeemTokens) / 10**decimals;

        /* Fail gracefully if protocol has insufficient cash */
        require(
            _getCashPrior() >= redeemAmount,
            "TOKEN_INSUFFICIENT_CASH | REDEEM_TRANSFER_OUT_NOT_POSSIBLE"
        );

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
        * We invoke doTransferOut for the redeemer and the redeemAmount.
        *  Note: The pToken must handle variations between ERC-20 and ETH underlying.
        *  On success, the pToken has redeemAmount less of cash.
        *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        */
        _doTransferOut(redeemer, redeemAmount);

        /* We write previously calculated values into storage */
        totalSupply = totalSupplyNew;
        accountTokens[redeemer] = accountTokensNew;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens);

        // TODO: Figure out why this was necessary
        // /* We call the defense hook */
        // riskEngine.redeemVerify(
        //   address(this),
        //   redeemer,
        //   vars.redeemAmount,
        //   vars.redeemTokens
        // );
    }

    function completeTransfer(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) public onlyMid() {
        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = spender == src
            ? type(uint256).max
            : transferAllowances[src][spender];

        /* Do the calculations, checking for {under,over}flow */
        uint256 allowanceNew;
        uint256 srpTokensNew;
        uint256 dstTokensNew;

        require(startingAllowance >= tokens, "Not enough allowance");
        allowanceNew = startingAllowance - tokens;

        require(accountTokens[src] >= tokens, "Not enough tokens");
        srpTokensNew = accountTokens[src] - tokens;

        dstTokensNew = accountTokens[dst] + tokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srpTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        emit Transfer(src, dst, tokens);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER
    }

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 prevAmount;
        uint256 amountRepaid;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract ILayerZeroManager {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function lzSend(
        uint16 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        address _zroPaymentAddr,
        bytes memory _adapterParams /* onlyAuth() */
    ) external payable virtual;

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _fromAddress,
        uint64 _nonce,
        bytes memory _payload /* onlyLZ() onlySrc(_srcChainId, _fromAddress) */
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract CommonModifiers {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal _notEntered;

    constructor() {
        _notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface ILayerZeroUserApplicationConfig {
    /// @notice set the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _configType - type of configuration. every messaging library has its own convention.
    /// @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    /// @notice set the send() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    /// @notice set the lzReceive() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    /// @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    /// @param _srcChainId - the chainId of the source chain
    /// @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LZManagerStorage.sol";

abstract contract LZManagerModifiers is LZManagerStorage {
    modifier onlyLZ() {
        require(msg.sender == address(layerZeroEndpoint), "Only LZ");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlySrc(uint16 srcChain, bytes calldata srcAddr) {
        require(
            keccak256(srcContracts[srcChain]) == keccak256(srcAddr),
            "Unauthorized contract"
        );
        _;
    }

    modifier onlyAuth() {
        require(authContracts[msg.sender], "Unauthorized caller");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ILayerZeroEndpoint.sol";
// import "../master/interfaces/IMaster.sol";
import "../master/MasterMessageHandler.sol";
import "../satellite/loanAgent/interfaces/ILoanAgent.sol";

abstract contract LZManagerStorage {
    ILayerZeroEndpoint internal layerZeroEndpoint;
    MasterMessageHandler internal masterState;
    ILoanAgent internal loanAgent;
    address internal riskEngine;
    uint16 internal cid;

    bytes4 internal constant MASTER_DEPOSIT = 0x00000000;
    bytes4 internal constant MASTER_WITHDRAW = 0x00000000;
    bytes4 internal constant FB_WITHDRAW = 0x00000000;

    address internal owner;

    // routers to call to on other chain ids
    mapping(uint16 => bytes) internal srcContracts;
    // addresses allowed to send messages to other chains
    mapping(address => bool) internal authContracts;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "../interfaces/IHelper.sol";

import "./interfaces/IMaster.sol";
import "./MasterModifiers.sol";
import "./MasterEvents.sol";

abstract contract MasterMessageHandler is IMaster, MasterModifiers, MasterEvents {
    function satelliteLiquidateBorrow(
        uint16 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual override {
        bytes memory payload = abi.encode(
            IHelper.SLiquidateBorrow(
                IHelper.Selector.SATELLITE_LIQUIDATE_BORROW,
                borrower,
                liquidator,
                seizeTokens,
                pTokenCollateral
            )
        );

        middleLayer.lzSend{value: msg.value}(
            chainId,
            dstContractLookup[chainId], // send to this address on the destination
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0x0), // future parameter
            bytes("") // adapterParams (see "Advanced Features")
        );
    }

    // pass in the erc20 prevBalance, newBalance
    /// @dev Update the collateral balance for the given arguments
    /// @notice This will come from the satellite chain- the approve models
    function masterDeposit(
        bytes memory payload,
        uint16 chainId
    ) public onlyMid() {
        (   ,
            address user,
            address pToken,
            uint256 prevAmount,
            uint256 amountDeposited
        ) = abi.decode(payload, (uint8, address, address, uint256, uint256));

        if (collateralBalances[chainId][user][pToken] != prevAmount) {
            // fallback to satellite to report failure
        }

        emit CollateralBalanceAdded(
            user,
            chainId,
            collateralBalances[chainId][user][pToken],
            collateralBalances[chainId][user][pToken] + amountDeposited
        );
        collateralBalances[chainId][user][pToken] += amountDeposited;

        // fallback to satellite to report receipt
    }

    function borrowAllowed(
        address user,
        uint16 chainId,
        uint256 borrowAmount
    ) public payable onlyMid {
        // TODO: liquidity calculation
        _accrueUserInterest(user);
        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            user,
            address(0),
            0,
            borrowAmount
        );

        bytes memory payload = abi.encode(IHelper.FBBorrow(
            IHelper.Selector.FB_BORROW,
            user,
            borrowAmount
        ));

        //if approved, update the balance and fire off a return message
        if (shortfall == 0) {
            (uint256 _accountBorrows, ) = _borrowBalanceStored(user);

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accountBorrows[user].principal = _accountBorrows + borrowAmount;
            accountBorrows[user].interestIndex = borrowIndex;
            totalBorrows = totalBorrows + borrowAmount;

            loansOutstanding[user][chainId] += borrowAmount;
            totalBorrows += borrowAmount;
            interest[user].interestIndex = borrowIndex;

            middleLayer.lzSend{ value: msg.value }(
                chainId,
                dstContractLookup[chainId], // send to this address on the destination
                payload, // bytes payload
                payable(msg.sender), // refund address
                address(0x0), // future parameter
                bytes("") // adapterParams (see "Advanced Features")
            );
        } else {
            // middleLayer.lzSend{ value: msg.value }(
            //   chainId,
            //   dstContractLookup[chainId], // send to this address on the destination
            //   payload, // bytes payload
            //   payable(msg.sender), // refund address
            //   address(0x0), // future parameter
            //   bytes("") // adapterParams (see "Advanced Features")
            // );
        }
    }

    function masterRepay(
        bytes memory payload,
        uint16 chainId
    ) public onlyMid() {
        ( , address borrower,
            uint256 prevAmount,
            uint256 amountRepaid
        ) = abi.decode(payload, (uint8, address, uint256, uint256));

        if (loansOutstanding[borrower][chainId] == prevAmount
         || loansOutstanding[borrower][chainId] < amountRepaid
        ) {
            // fallback to satellite to report failure
        }

        _accrueUserInterest(borrower);

        loansOutstanding[borrower][chainId] -= amountRepaid;

        // fallback to satellite to report receipt
    }

    function redeemAllowed(
        address user,
        address pToken,
        uint16 chainId,
        uint256 redeemAmount
    ) public payable onlyMid {
        //calculate hypothetical liquidity for the user
        //make sure we also check that the redeem isn't more than what's deposited
        // bool approved = true;

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            user,
            pToken,
            redeemAmount,
            0
        );

        bytes memory payload = abi.encode(
            IHelper.FBRedeem(
                IHelper.Selector.FB_REDEEM,
                pToken,
                user,
                redeemAmount
            )
        );

        //if approved, update the balance and fire off a return message
        if (shortfall == 0) {
            collateralBalances[chainId][user][pToken] -= redeemAmount;

            middleLayer.lzSend{value: msg.value}(
                chainId,
                dstContractLookup[chainId], // send to this address on the destination
                payload, // bytes payload
                payable(msg.sender), // refund address
                address(0x0), // future parameter
                bytes("") // adapterParams (see "Advanced Features")
            );
        } else {
            middleLayer.lzSend{value: msg.value}(
                chainId,
                dstContractLookup[chainId], // send to this address on the destination
                payload, // bytes payload
                payable(msg.sender), // refund address
                address(0x0), // future parameter
                bytes("") // adapterParams (see "Advanced Features")
            );
        }
    }

    function transferAllowed(bytes memory params, uint16 chainId)
        public
        payable
        onlyMid
    {
        (
            ,
            address pToken,
            address spender,
            address user,
            address dst,
            uint256 amount
        ) = abi.decode(
                params,
                (uint8, address, address, address, address, uint256)
            );

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            user,
            pToken,
            0,
            0
        );

        bytes memory payload = abi.encode(
            IHelper.FBCompleteTransfer(
                uint8(IHelper.Selector.FB_COMPLETE_TRANSFER),
                pToken,
                spender,
                user, // src
                dst,
                amount // tokens
            )
        );

        if (shortfall == 0) {
            collateralBalances[chainId][user][pToken] -= amount;
            collateralBalances[chainId][dst][pToken] += amount;

            middleLayer.lzSend{value: msg.value}(
                chainId,
                dstContractLookup[chainId], // send to this address on the destination
                payload, // bytes payload
                payable(msg.sender), // refund address
                address(0x0), // future parameter
                bytes("") // adapterParams (see "Advanced Features")
            );
        } else {
            // TODO: shortfall > 0
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// import "../../PUSD.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "../../PToken/interfaces/IPToken.sol";

import "../LoanAgentStorage.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function borrow(uint256 borrowAmount) public virtual;

    // function completeBorrow(
    //     address borrower,
    //     uint borrowAmount
    // ) public virtual;

    function repayBorrow(uint256 repayAmount) public virtual returns (bool);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        public
        virtual
        returns (bool);

    function borrowBalanceStored(address account)
        public
        view
        virtual
        returns (uint256);

    // function accrueInterest() public virtual;
    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal virtual returns (uint256);

    function _borrow(uint256 borrowAmount) internal virtual;

    function _sendBorrow(address user, uint256 amount) internal virtual;

    function borrowApproved(address borrower, uint256 borrowAmount)
        public
        virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../MasterStorage.sol";

abstract contract IMaster is MasterStorage {
    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function _borrowBalanceStored(address account)
        internal
        view
        virtual
        returns (uint256, uint256);

    function _accrueInterest() internal virtual;

    function _accrueUserInterest(address user)
        internal
        virtual
        returns (uint256);

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _addToMarket(
        address token,
        uint16 chainId,
        address borrower
    ) internal virtual returns (bool);

    /**
     * @notice Get a snapshot of the account's balance, and the cached exchange rate
     * @dev This is used by risk engine to more efficiently perform liquidity checks.
     * @param user Address of the account to snapshot
     * @param chainId metadata of the ptoken
     * @param token metadata of the ptoken
     * @return (possible error, token balance, exchange rate)
     */
    function _getAccountSnapshot(
        address user,
        uint16 chainId,
        address token
    ) internal view virtual returns (uint256, uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the PToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return (calculated exchange rate scaled by 1e18)
     */
    function _exchangeRateStored() internal view virtual returns (uint256);

    function _getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) internal view virtual returns (uint256, uint256);

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this pToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function _liquidateBorrow(
        address pTokenCollateral,
        address borrower,
        uint16 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint16 chainId,
        uint256 actualRepayAmount
    ) internal view virtual returns (uint256);

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint16 chainId,
        uint256 repayAmount
    ) internal view virtual returns (bool);

    function satelliteLiquidateBorrow(
        uint16 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MasterStorage.sol";

abstract contract MasterModifiers is MasterStorage {
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(
            ILayerZeroManager(msg.sender) == middleLayer,
            "ONLY_MIDDLE_LAYER"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract MasterEvents {
    event CollateralBalanceAdded(
        address indexed user,
        uint16 chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event CollateralChanged(
        address indexed user,
        uint16 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanAdded(
        address indexed user,
        uint16 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanChanged(
        address indexed user,
        uint16 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanRepaid(
        address indexed user,
        uint16 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    /// @notice Emitted when an account enters a deposit market
    event MarketEntered(uint16 chainId, address token, address borrower);

    event ReceiveFromChain(uint16 _srcChainId, address _fromAddress);

    /// @notice Event emitted when a borrow is liquidated
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// TODO: Change this import to somewhere else probably
import "../satellite/interfaces/IPriceOracle.sol";
import "../middleLayer/interfaces/ILayerZeroManager.sol";

abstract contract MasterStorage {
    mapping(uint16 => bytes) public dstContractLookup; // a map of the connected contracts

    address internal owner;

    ILayerZeroManager internal middleLayer;

    address internal pusd;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex; // TODO - needs initialized

    uint256 internal liquidityIncentive = 5e6; // 5%
    uint256 internal closeFactor = 50e6; // 50%
    uint256 internal collateralFactor = 80e6; // 80%
    uint256 internal protocolSeizeShare = 1e6; // 1%

    uint256 internal totalReserves;
    uint256 internal totalSupply;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint256 internal constant borrowRateMax = 0.0005e16;

    // chainid => user => token => token balance
    mapping(uint16 => mapping(address => mapping(address => uint256)))
        public collateralBalances;

    // user => chainId => token balance
    mapping(address => mapping(uint16 => uint256)) public loansOutstanding;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        uint256 collateralFactor;
        mapping(address => bool) accountMembership;
        //InterestRateModel interestRateModel_,
        //InitialCollateralRatioModel, /*initialCollateralRatioModel_*/
        uint256 initialExchangeRate;
        string name;
        string symbol;
        uint8 decimals;
        address underlying;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // chain => ptoken address => market
    mapping(uint16 => mapping(address => Market)) public markets;

    struct InterestSnapshot {
        uint256 interestAccrued;
        uint256 interestIndex;
    }
    // user => interest index
    mapping(address => InterestSnapshot) public interest;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /// @notice A list of all deposit markets
    CollateralMarket[] public allMarkets;

    struct CollateralMarket {
        uint16 chainId;
        address token;
        uint8 decimals;
    }

    uint16[] public chains;

    // user => interest index
    mapping(address => CollateralMarket[]) public accountAssets;

    IPriceOracle internal oracle;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../pToken/interfaces/IPToken.sol";
// import "../loanAgent/interfaces/ILoanAgent.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address pToken) external view returns (uint256);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param loanAgent The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(address loanAgent)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../interestRateModel/InterestRateModel.sol";
import "../../initialCollateralRatioModel/InitialCollateralRatioModel.sol";

import "../PTokenStorage.sol";

abstract contract IPToken is PTokenStorage {//is IERC20 {
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _doTransferIn(
        address from,
        uint256 amount
    ) internal virtual returns (uint256);

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function _getCashPrior() internal virtual view returns (uint256);

    /**
     * @notice User redeems pTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of pTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming pTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function _redeemFresh(
        address payable redeemer,
        uint256 redeemTokensIn,
        uint256 redeemAmountIn
    ) internal virtual;

    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * @notice Calculates the exchange rate from the underlying to the PToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return (calculated exchange rate scaled by 1e18)
     */
    function _exchangeRateStored() internal virtual view returns (uint256);

    function _sendMint(uint256 mintTokens) internal virtual;

    function _redeemAllowed(
        address user,
        uint256 redeemAmount
    ) internal virtual;

    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {InitialCollateralRatioModel} from "../initialCollateralRatioModel/InitialCollateralRatioModel.sol";
import "./InterestRateModelStorage.sol";

/**
 * @title Prime's InterestRateModel Interface
 */
contract InterestRateModel is InterestRateModelStorage {

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    constructor() {
        admin = msg.sender;
        //this represents 2.5e16 or 2.5% interest rate per year
        //need to divide APR by number of blocks per year
        //5e16 = 5%
        uint256 borrowInterestRatePerYear = 25e15;
        //6400 blocks per day * 365 days
        blocksPerYear = 2336000;
        //2.5% APR divided by blocks per year
        borrowInterestRatePerBlock = borrowInterestRatePerYear / blocksPerYear;
        //6 decimal precision for 0.995
        pusdPrice = 995e3;
        //APR increment/decrement when price is under/over peg
        uint256 basisPointsTickSizePerYear = 1e14;
        basisPointsTickSize = basisPointsTickSizePerYear / blocksPerYear;

        uint256 basisPointsUpperTickPerYear = 5e16;
        basisPointsUpperTick = basisPointsUpperTickPerYear / blocksPerYear;

        basisPointsLowerTick = 0;

        observationPeriod = 0;
    }

    /**
     * @notice Calculates the current borrow interest rate per block
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    //simple bump function
    //what was the price an hour...where is it now
    //twap time horizon
    //has it been enough time
    // have a snapshot of price and block time
    // how long ago was that snapshot taken
    // an hour ago or longer increase or decrease the rate
    // replace the one in storage
    function getBorrowRate() external view returns (uint256) {
        return borrowInterestRatePerBlock;
    }

    function getPusdPrice() external view returns (uint256) {
        return pusdPrice;
    }

    function setBorrowRate() external returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastObservationTimestamp;

        //setBorrowRate if enough time has elapsed
        if (elapsedTime <= observationPeriod) {
            return borrowInterestRatePerBlock;
        }
        uint256 priorBorrowInterestRatePerBlock = borrowInterestRatePerBlock;
        // 1.00
        if (pusdPrice > 1e6) {
            //1e18 = 100%
            //5e16 =   5%
            if (borrowInterestRatePerBlock < basisPointsUpperTick)
                //decrease 10 basis points if the price is high
                borrowInterestRatePerBlock -= basisPointsTickSize;
        } else if (pusdPrice < 1e6) {
            if (
                borrowInterestRatePerBlock * blocksPerYear >=
                basisPointsTickSize
            )
                //increase 10 basis points if the price is low
                borrowInterestRatePerBlock += basisPointsTickSize;
        }
        lastObservationTimestamp = block.timestamp;
        return priorBorrowInterestRatePerBlock;
    }

    //one basis point equals 0.01% or 1e14; 10 is 0.1% or 1e15
    //increase 10 basis points if the price is low
    //decrease 10 basis points if the price is high
    //cap between 0% and 5%

    function setPusdPrice(uint256 price) external onlyAdmin {
        _setPusdPrice(price);
    }

    //TODO: this is a placeholder function for experimentation
    function _setPusdPrice(uint256 price) internal onlyAdmin {
        pusdPrice = price;
    }

    function setBasisPointsTickSize(uint256 _basisPointsTickSize)
        external
        onlyAdmin
    {
        basisPointsTickSize = _basisPointsTickSize;
    }

    function setBasisPointsUpperTick(uint256 _basisPointsUpperTick)
        external
        onlyAdmin
    {
        basisPointsUpperTick = _basisPointsUpperTick;
    }

    function setBasisPointsLowerTick(uint256 _basisPointsLowerTick)
        external
        onlyAdmin
    {
        basisPointsLowerTick = _basisPointsLowerTick;
    }

    /**
        prior borrow rate
        prior observation time
        prior PUSD price
        PUSD price
        prior estimation of the demand curve
        probably some other things, tbd
     */

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactor The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    //not sure we need this
    //function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external virtual view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./InitialCollateralRatioModelStorage.sol";

/**
 * @title Prime's InitialCollateralRatioModel Interface
 */
contract InitialCollateralRatioModel is InitialCollateralRatioModelStorage {

    event AssetLtvRatioUpdated(address asset, uint256 ltvRatio);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    // TODO: will be used for LTV lookup by collateral later
    constructor(
        uint256 _pusdPrice,
        address[] memory _assets,
        uint256[] memory _ltvRatios
    ) {
        admin = msg.sender;
        _setRequiredLTVRatios(_assets, _ltvRatios);
        pusdPrice = _pusdPrice;
        pusdPriceCeiling = 1e6;
        pusdPriceFloor = 99e4;
    }

    function getRequiredCollateralRatio(address asset)
        external
        view
        returns (
            //pusdPrice - assume 6 decimals
            //maxLtvRatio //how much decimal precision do we want here? starting with 6 decimals
            //this value should come from an array passed into the constructor
            //returns 18 decimals of precision
            uint256
        )
    {
        uint256 _pusdPrice = _getPusdPrice();
        //price >= 1.00
        if (_pusdPrice >= pusdPriceCeiling) {
            return ltvRatios[asset];
        }
        //price <= 0.99
        else if (_pusdPrice <= pusdPriceFloor) {
            return 0;
        } else {
            uint256 priceDelta = _pusdPrice - pusdPriceFloor;
            return (priceDelta * ltvRatios[asset]) / 1e4;
        }
    }

    function getPusdPrice() external view onlyAdmin returns (uint256) {
        return pusdPrice;
    }

    function _getPusdPrice() internal view onlyAdmin returns (uint256) {
        return pusdPrice;
    }

    function setPusdPrice(uint256 price) external onlyAdmin {
        pusdPrice = price;
    }

    function setPusdPriceCeiling(uint256 price) external onlyAdmin {
        pusdPriceCeiling = price;
    }

    function setPusdPriceFloor(uint256 price) external onlyAdmin {
        pusdPriceFloor = price;
    }

    function setRequiredLTVRatios(
        address[] memory _assets,
        uint256[] memory _ltvRatios
    ) external onlyAdmin {
        _setRequiredLTVRatios(_assets, _ltvRatios);
    }

    function _setRequiredLTVRatios(
        address[] memory _assets,
        uint256[] memory _ltvRatios
    ) internal onlyAdmin {
        require(
            _assets.length == _ltvRatios.length,
            "ERROR: Length mismatch between 'assets' and 'assetLtvRatios'"
        );
        for (uint256 i = 0; i < _assets.length; i++) {
            ltvRatios[_assets[i]] = _ltvRatios[i];
            emit AssetLtvRatioUpdated(_assets[i], _ltvRatios[i]);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../middleLayer/interfaces/ILayerZeroManager.sol";
//NOTE: needs an interface
import "../interestRateModel/InterestRateModel.sol";
//NOTE: needs an interface
import "../initialCollateralRatioModel/InitialCollateralRatioModel.sol";

abstract contract PTokenStorage {
    address internal owner;
    uint16 internal masterCID;
    address internal masterMiddleLayer;

    ILayerZeroManager internal middleLayer;
    /**
    * @notice Total number of tokens in circulation
    */
    uint256 public totalSupply;

    /**
    * @notice Indicator that this is a PToken contract (for inspection)
    */
    bool public constant isPToken = true;

    /**
    * @notice EIP-20 token for this PToken
    */
    address public underlying;

    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address payable public pendingAdmin;

    /**
    * @notice Model which tells what the current interest rate should be
    */
    InterestRateModel public interestRateModel;

    /**
    * @notice Model which tells whether a user may withdraw collateral or take on additional debt
    */
    InitialCollateralRatioModel public initialCollateralRatioModel;

    /**
    * @notice Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
    */
    uint256 internal initialExchangeRate;

    /**
    * @notice Block number that interest was last accrued at
    */
    uint256 public accrualBlockNumber;

    /**
    * @notice Total amount of reserves of the underlying held in this market
    */
    uint256 public totalReserves;

    /**
    * @notice EIP-20 token decimals for this token
    */
    uint8 public decimals;

    /**
    * @notice Official record of token balances for each account
    */
    mapping(address => uint256) internal accountTokens;

    /**
    * @notice Approved token transfer amounts on behalf of others
    */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
    * @notice Share of seized collateral that is added to reserves
    */
    // TODO: Have this value passed by master chain
    // ? To allow for ease of updates
    uint256 public constant protocolSeizeShare = 1e6; //1%
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract InterestRateModelStorage {
    // @notice use block.timestamp to calculate interest rate in the future
    bool public constant IS_INTEREST_RATE_MODEL = true;

    address public admin;
    uint256 public pusdPrice;

    //a value from 0% to 100%
    //user would be liq'd after one block at 100% borrow interest rate (i.e. 1e18)
    uint256 public borrowInterestRatePerBlock;
    uint256 public basisPointsTickSize;
    uint256 public basisPointsUpperTick;
    uint256 public basisPointsLowerTick;
    uint256 public lastObservationTimestamp;
    uint256 public observationPeriod;
    uint256 public blocksPerYear;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract InitialCollateralRatioModelStorage {
    /// @notice future consideration to have custom max LTV ratios
    bool public constant isInitialCollateralRatioModel = true;

    address public admin;

    uint256 public pusdPrice;
    uint256 public pusdPriceCeiling;
    uint256 public pusdPriceFloor;

    mapping(address => uint256) internal ltvRatios;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../middleLayer/interfaces/ILayerZeroManager.sol";

abstract contract LoanAgentStorage {
    address internal owner;

    address internal PUSD;

    ILayerZeroManager internal middleLayer;

    uint16 internal masterCID;
    address internal masterMiddleLayer;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactor;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Interest rate model
     */
    address public interestRateModel;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex; // TODO - needs initialized

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint256 internal constant borrowRateMax = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint256 internal constant reserveFactorMax = 1e18;

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => uint256) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves - need to decide if we want this here or on PToken
     */
    uint256 public constant PROTOCOL_SEIZE_SHARE = 2.8e16; //2.8%
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IPToken.sol";
import "./interfaces/IERC20.sol";

abstract contract PTokenInternals is IPToken {
    function _doTransferIn(
        address from,
        uint256 amount
    ) internal virtual override returns (uint256) {
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getCashPrior() internal virtual override view returns (uint256) {
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }

    function _redeemFresh(
        address payable redeemer,
        uint256 redeemTokensIn,
        uint256 redeemAmountIn
    ) internal virtual override {
        require(redeemAmountIn > 0, "REDEEM_AMOUNT_NON_ZERO");
        require(
            redeemTokensIn == 0 || redeemAmountIn == 0,
            "one of redeemTokensIn or redeemAmountIn must be zero"
        );

        uint256 redeemTokens;
        uint256 redeemAmount;

        uint256 exchangeRate = _exchangeRateStored();

        if (redeemTokensIn > 0) {
            /*
            * We calculate the exchange rate and the amount of underlying to be redeemed:
            *  redeemTokens = redeemTokensIn
            *  redeemAmount = redeemTokensIn x exchangeRateCurrent
            */
            redeemTokens = redeemTokensIn;
            redeemAmount = (exchangeRate * redeemTokensIn) / 10**decimals;
        } else {
            /*
            * We get the current exchange rate and calculate the amount to be redeemed:
            *  redeemTokens = redeemAmountIn / exchangeRate
            *  redeemAmount = redeemAmountIn
            */

            redeemTokens = (redeemAmountIn * 10**decimals) / exchangeRate;
            redeemAmount = redeemAmountIn;
        }

        _redeemAllowed(redeemer, redeemTokens);
    }

    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual override {
        IERC20 token = IERC20(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    function _exchangeRateStored() internal virtual override view returns (uint256) {
        // this is where the tests are failing
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
            * If there are no tokens minted:
            *  exchangeRate = initialExchangeRate
            */
            return initialExchangeRate;
        } else {
            /*
            * Otherwise:
            *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
            */
            uint256 totalCash = _getCashPrior();
            uint256 cashPlusBorrowsMinusReserves;
            uint256 exchangeRate;

            cashPlusBorrowsMinusReserves = totalCash - totalReserves;

            exchangeRate = (totalCash * 10**decimals) / _totalSupply;
            return exchangeRate;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./PTokenStorage.sol";

abstract contract PTokenModifiers is PTokenStorage {
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../interestRateModel/InterestRateModel.sol";

abstract contract PTokenEvents {
    /**
    * @notice Event emitted when interest is accrued
    */
    // event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
    * @notice Event emitted when tokens are minted
    */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
    * @notice Event emitted when tokens are redeemed
    */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
    * @notice Event emitted when a borrow is liquidated
    */
    // event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /*** Admin Events ***/

    /**
    * @notice Event emitted when pendingAdmin is changed
    */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
    * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
    */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
    * @notice Event emitted when interestRateModel is changed
    */
    event NewMarketInterestRateModel(
        InterestRateModel oldInterestRateModel,
        InterestRateModel newInterestRateModel
    );

    /**
    * @notice Event emitted when the reserve factor is changed
    */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    /**
    * @notice Event emitted when the reserves are added
    */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
    * @notice Event emitted when the reserves are reduced
    */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
    * @notice Failure event
    */
    event TokenFailure(uint256 error, uint256 info, uint256 detail);

    /**
     * @notice EIP20 TransferInitiated event
     */
    event TransferInitiated(
        address indexed from,
        address indexed to,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * FUNCTIONS ONLY INTERFACE
 */
abstract contract IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external virtual view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external virtual returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external virtual view returns (uint256);

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
    function approve(address spender, uint256 amount) external virtual returns (bool);

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
    ) external virtual returns (bool);
}