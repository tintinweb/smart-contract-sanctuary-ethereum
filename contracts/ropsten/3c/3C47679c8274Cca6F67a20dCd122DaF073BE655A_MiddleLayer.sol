//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerAdmin.sol";
import "../satellite/pToken/PTokenMessageHandler.sol";

import "../interfaces/IHelper.sol";
import "./interfaces/IMiddleLayer.sol";
import "../util/CommonModifiers.sol";

contract MiddleLayer is IMiddleLayer, MiddleLayerAdmin, CommonModifiers {
    constructor(uint256 newChainId) {
        owner = msg.sender;
        cid = newChainId;
    }

    event MessageSent (
        uint256 _dstChainId,
        bytes params,
        address _refundAddress,
        address fallbackAddress
    );

    event MessageReceived(
        uint256 _srcChainId,
        bytes payload
    );

/*
    function autoRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) external view returns (
        uint256 estimatedGas,
        uint256 estimatedArrival,
        uint256 route
    ) {
        (   uint256[] memory _estimatedGas,
            uint256[] memory _estimatedArrival
        ) = _checkRoute(
            _dstChainId,
            _destination,
            params,
            _refundAddress,
            _adapterParams
        );

        // determine which route is best and return those estimates along with the route id
    }

    function checkRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) external view returns (
        uint256[] memory estimatedGas,
        uint256[] memory estimatedArrival
    ) {
        return _checkRoute(
            _dstChainId,
            _destination,
            params,
            _refundAddress,
            _adapterParams
        );
    }

    function _checkRoute(
        uint256 _dstChainId,
        bytes memory _destination,
        bytes memory params,
        address payable _refundAddress,
        bytes memory _adapterParams
    ) internal view returns (
        uint256[] memory estimatedGas,
        uint256[] memory estimatedArrival
    ) {

    }
*/

    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable override onlyAuth() {
        // if thisChain == dstChain, process the send directly instead of through router

        emit MessageSent (
            _dstChainId,
            params,
            _refundAddress,
            fallbackAddress
        );

        if (fallbackAddress == address(0)) {
            uint256 hash = uint256(keccak256(abi.encodePacked(params, block.timestamp, _dstChainId)));
            // This prng is safe as its not logic reliant, and produces a safe output given the routing protocol that is chosen is not offline
            // slither-disable-next-line weak-prng
            routes[hash % routes.length].msend{value: msg.value}(
                _dstChainId, // destination LayerZero chainId
                params, // bytes payload
                _refundAddress // refund address
            );
            return;
        }
        IRoute(fallbackAddress).msend{value:msg.value}(
            _dstChainId,
            params,
            _refundAddress
        );
    }

    // slither-disable-next-line assembly
    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external override onlyRoute() {
        IHelper.Selector selector;
        bytes32 metadata;
        assembly {
            metadata := mload(add(payload, 0x20))
            selector := mload(add(payload, 0x40))
        }

        emit MessageReceived(
            _srcChainId,
            payload
        );

        if (IHelper.Selector.MASTER_DEPOSIT == selector) {
            // slither-disable-next-line all
            IHelper.MDeposit memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
            }

            masterState.masterDeposit(
                params,
                metadata,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_REDEEM_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MRedeemAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            masterState.redeemAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_REDEEM == selector) {
            // slither-disable-next-line all
            IHelper.FBRedeem memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            PTokenMessageHandler(params.pToken).completeRedeem(
                params,
                metadata
            );
        } else if (IHelper.Selector.MASTER_REPAY == selector) {
            // slither-disable-next-line all
            IHelper.MRepay memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
            }

            masterState.masterRepay(
                params,
                metadata,
                _srcChainId
            );
        } else if (IHelper.Selector.MASTER_BORROW_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MBorrowAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }

            masterState.borrowAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.FBBorrow memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }

            loanAgent.borrowApproved(
                params,
                metadata
            );
        } else if (IHelper.Selector.SATELLITE_LIQUIDATE_BORROW == selector) {
            // slither-disable-next-line all
            IHelper.SLiquidateBorrow memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
            }

            PTokenMessageHandler(params.pTokenCollateral).seize(
                params,
                metadata
            );
        } else if (IHelper.Selector.MASTER_TRANSFER_ALLOWED == selector) {
            // slither-disable-next-line all
            IHelper.MTransferAllowed memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
                mstore(add(params, 0xa0), mload(add(payload, 0xe0)))
            }

            masterState.transferAllowed(
                params,
                metadata,
                _srcChainId,
                msg.sender
            );
        } else if (IHelper.Selector.FB_COMPLETE_TRANSFER == selector) {
            // slither-disable-next-line all
            IHelper.FBCompleteTransfer memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
                mstore(add(params, 0x60), mload(add(payload, 0xa0)))
                mstore(add(params, 0x80), mload(add(payload, 0xc0)))
                mstore(add(params, 0xa0), mload(add(payload, 0xe0)))
            }

            PTokenMessageHandler(params.pToken).completeTransfer(
                params,
                metadata
            );
        } else if (IHelper.Selector.PUSD_BRIDGE == selector) {
            // slither-disable-next-line all
            IHelper.PUSDBridge memory params;
            assembly {
                mstore(add(params, 0x20), mload(add(payload, 0x60)))
                mstore(add(params, 0x40), mload(add(payload, 0x80)))
            }
            pusd.mintFromChain(
                params,
                metadata,
                _srcChainId
            );
        }
    }

    fallback() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerModifiers.sol";

abstract contract MiddleLayerAdmin is MiddleLayerStorage, MiddleLayerModifiers {
    event ChangeOwner(
        address newOwner
    );

    function changeOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        owner = newOwner;
        emit ChangeOwner(newOwner);
    }

    function _changeAuth(
        address contractAddr,
        bool status
    ) internal {
        require(contractAddr != address(0), "NON_ZEROADDRESS");
        authContracts[contractAddr] = status;
    }

    function changeAuth(address contractAddr, bool status) external onlyOwner() {
        _changeAuth(contractAddr, status);
    }

    function changeManyAuth(
        address[] calldata contractAddr,
        bool[] calldata status
    ) external onlyOwner() {
        require(contractAddr.length == status.length, "Mismatch len");
        // slither-disable-next-line uninitialized-local
        for (uint8 i; i < contractAddr.length; i++) {
            _changeAuth(contractAddr[i], status[i]);
        }
    }

    function setMasterState(address newMasterState) external onlyOwner() {
        require(newMasterState != address(0), "NON_ZEROADDRESS");
        masterState = MasterMessageHandler(newMasterState);
    }

    function setLoanAgent(address newLoanAgent) external onlyOwner() {
        require(newLoanAgent != address(0), "NON_ZEROADDRESS");
        loanAgent = ILoanAgent(newLoanAgent);
    }

    function setPUSD(address newPUSD) external onlyOwner() {
        require(newPUSD != address(0), "NON_ZEROADDRESS");
        pusd = PUSDMessageHandler(newPUSD);
    }

    function addRoute(IRoute newRoute) external onlyOwner() {
        require(address(newRoute) != address(0), "NON_ZEROADDRESS");
        routes.push(newRoute);
        authRoutes[address(newRoute)] = true;
    }

    // slither-disable-next-line costly-loop
    function removeRoute(IRoute fallbackAddressToRemove) external onlyOwner() {
        // slither-disable-next-line uninitialized-local
        for (uint i; i < routes.length; i++) {
            if (routes[i] == fallbackAddressToRemove) {
                // swap the route to remove with the last item
                routes[i] = routes[routes.length-1];
                // pop the last item
                routes.pop();

                authRoutes[address(fallbackAddressToRemove)] = false;
                return;
            }
        }
        revert("ROUTE_NOT_FOUND");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";
import "./PTokenInternals.sol";
import "./PTokenModifiers.sol";
import "./PTokenEvents.sol";
import "../../interfaces/IHelper.sol";
import "./interfaces/IPTokenMessageHandler.sol";
import "../../util/CommonModifiers.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PTokenMessageHandler is
    IPTokenInternals,
    IERC20,
    IPTokenMessageHandler,
    PTokenModifiers,
    PTokenEvents,
    CommonModifiers
{
    // slither-disable-next-line assembly
    function _redeemAllowed(
        address user,
        uint256 redeemAmount
    ) internal virtual override {
        require(redeemAmount > 0, "REDEEM_AMOUNT_NON_ZERO");
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MRedeemAllowed(
                IHelper.Selector.MASTER_REDEEM_ALLOWED,
                address(this),
                user,
                redeemAmount
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            masterCID,
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0)
        );

        emit RedeemSent(
            user,
            address(this),
            accountTokens[msg.sender],
            redeemAmount
        );
    }

    // slither-disable-next-line assembly
    function _sendMint(
        uint256 mintTokens
    ) internal virtual override {

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MDeposit({
                selector: IHelper.Selector.MASTER_DEPOSIT,
                user: msg.sender,
                pToken: address(this),
                previousAmount: accountTokens[msg.sender],
                amountIncreased: mintTokens
            })
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{ value: msg.value }(
            masterCID,
            payload,
            payable(msg.sender),
            address(0)
        );

        emit MintSent(
            uint8(IHelper.Selector.MASTER_DEPOSIT),
            msg.sender,
            address(this),
            accountTokens[msg.sender],
            mintTokens
        );
    }

    // slither-disable-next-line assembly
    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal virtual override {
        require(src != dst, "BAD_INPUT | SELF_TRANSFER_NOT_ALLOWED");
        require(tokens < accountTokens[src], "Requested amount too high");

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.MTransferAllowed(
                uint8(IHelper.Selector.MASTER_TRANSFER_ALLOWED),
                address(this),
                spender,
                src,
                dst,
                tokens
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            masterCID,
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0)
        );

        emit TransferInitiated(src, dst, tokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer pToken and not a parameter.
     */
    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external override nonReentrant onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        accountTokens[params.borrower] = accountTokens[params.borrower] - params.seizeTokens;
        _doTransferOut(params.liquidator, params.seizeTokens);

        emit Transfer(params.borrower, params.liquidator, params.seizeTokens);
        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

    }

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external override onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;
        // /* Verify market's block number equals current block number */

        /*
        * We calculate the new total supply and redeemer balance, checking for underflow:
        *  totalSupplyNew = totalSupply - redeemTokens
        *  accountTokensNew = accountTokens[redeemer] - redeemTokens
        */
        require(_totalSupply >= params.redeemAmount, "INSUFFICIENT_LIQUIDITY");

        require(
            accountTokens[params.user] >= params.redeemAmount,
            "Trying to redeem too much"
        );

        // TODO: make sure we cannot exploit this by having an exchange rate difference in redeem and complete redeem functions

        /* Fail gracefully if protocol has insufficient cash */
        require(
            _getCashPrior() >= params.redeemAmount,
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
        _doTransferOut(params.user, params.redeemAmount);

        _totalSupply -= params.redeemAmount;
        accountTokens[params.user] -= params.redeemAmount;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(params.user, address(this), params.redeemAmount);
        emit Redeem(params.user, params.redeemAmount, params.redeemAmount);

        // TODO: Figure out why this was necessary
        // /* We call the defense hook */
        // riskEngine.redeemVerify(
        //   address(this),
        //   redeemer,
        //   vars.redeemAmount,
        //   vars.redeemTokens
        // );

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");
    }

    function completeTransfer(
        IHelper.FBCompleteTransfer memory params,
        bytes32 metadata
    ) external override onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = params.spender == params.src
            ? type(uint256).max
            : transferAllowances[params.src][params.spender];

        require(startingAllowance >= params.tokens, "Not enough allowance");

        require(accountTokens[params.src] >= params.tokens, "Not enough tokens");

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[params.src] -= params.tokens;
        accountTokens[params.dst] += params.tokens;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint256).max) {
            transferAllowances[params.src][params.spender] -= params.tokens;
        }

        emit Transfer(params.src, params.dst, params.tokens);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

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
        FB_COMPLETE_TRANSFER,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

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

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonModifiers {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal notEntered;

    constructor() {
        notEntered = true;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        require(notEntered, "re-entered");
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MiddleLayerStorage.sol";

abstract contract MiddleLayerModifiers is MiddleLayerStorage {
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyAuth() {
        require(authContracts[msg.sender], "Unauthorized caller");
        _;
    }

    modifier onlyRoute() {
        require(authRoutes[msg.sender], "Unauthorized caller");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../master/MasterMessageHandler.sol";
import "../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "../satellite/pusd/PUSDMessageHandler.sol";
import "./routes/interfaces/IRoute.sol";

abstract contract MiddleLayerStorage {
    MasterMessageHandler internal masterState;
    ILoanAgent internal loanAgent;
    PUSDMessageHandler internal pusd;

    uint256 internal cid;

    address internal owner;

    IRoute[] internal routes;

    // addresses allowed to send messages to other chains
    mapping(address => bool) internal authContracts;

    // routes allowed to receive messages
    mapping(address => bool) authRoutes;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IHelper.sol";

import "./interfaces/IMaster.sol";
import "./MasterModifiers.sol";
import "./MasterEvents.sol";

abstract contract MasterMessageHandler is IMaster, MasterModifiers, MasterEvents {
    // slither-disable-next-line assembly
    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual override {
        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.SLiquidateBorrow(
                IHelper.Selector.SATELLITE_LIQUIDATE_BORROW,
                borrower,
                liquidator,
                seizeTokens,
                pTokenCollateral
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        middleLayer.msend{value: msg.value}(
            chainId,
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0)
        );
    }

    // pass in the erc20 prevBalance, newBalance
    /// @dev Update the collateral balance for the given arguments
    /// @notice This will come from the satellite chain- the approve models
    function masterDeposit(
        IHelper.MDeposit memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        if (collateralBalances[chainId][params.user][params.pToken] != params.previousAmount) {
            // fallback to satellite to report failure
        }

        if (collateralBalances[chainId][params.user][params.pToken] == 0) {
            _addToMarket(params.pToken, chainId, params.user);
        }

        collateralBalances[chainId][params.user][params.pToken] += params.amountIncreased;
        markets[chainId][params.pToken].totalSupply += params.amountIncreased;

        emit CollateralBalanceAdded(
            params.user,
            chainId,
            collateralBalances[chainId][params.user][params.pToken],
            collateralBalances[chainId][params.user][params.pToken]
        );

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

        // fallback to satellite to report receipt
    }

    // slither-disable-next-line assembly
    function borrowAllowed(
        IHelper.MBorrowAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        // TODO: liquidity calculation
        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            address(0),
            0,
            params.borrowAmount
        );

        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            (uint256 _accountBorrows, ) = _borrowBalanceStored(params.user);

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            accountBorrows[params.user].principal = _accountBorrows + params.borrowAmount;
            accountBorrows[params.user].interestIndex = borrowIndex;

            loansOutstanding[params.user][chainId] += params.borrowAmount;
            totalBorrows += params.borrowAmount;

            bytes memory payload = abi.encode(
                uint256(0),
                IHelper.FBBorrow(
                    IHelper.Selector.FB_BORROW,
                    params.user,
                    params.borrowAmount
                )
            );

            bytes32 _metadata = ecc.preRegMsg(payload, params.user);
            assembly {
                mstore(add(payload, 0x20), _metadata)
            }

            middleLayer.msend{ value: msg.value }(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                fallbackAddress
            );

            require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

            emit LoanApproved(params.borrowAmount, accountBorrows[params.user].principal, totalBorrows);
        } else {
            emit LoanRejection(shortfall);
            // middleLayer.msend{ value: msg.value }(
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
        IHelper.MRepay memory params,
        bytes32 metadata,
        uint256 chainId
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        if (loansOutstanding[params.borrower][chainId] < params.amountRepaid
        ) {
            // TODO: fallback to satellite to report failure
        }
        (uint256 _accountBorrows,) = _borrowBalanceStored(params.borrower);

        loansOutstanding[params.borrower][chainId] -= params.amountRepaid;
        totalBorrows -= params.amountRepaid;
        accountBorrows[params.borrower].principal = _accountBorrows - params.amountRepaid;

        _accrueInterest();

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

        emit RepayBorrowMaster(loansOutstanding[params.borrower][chainId], totalBorrows, accountBorrows[params.borrower].principal);

        // TODO: fallback to satellite to report receipt
    }

    // slither-disable-next-line assembly
    function redeemAllowed(
        IHelper.MRedeemAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) external payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _accrueInterest();

        //calculate hypothetical liquidity for the user
        //make sure we also check that the redeem isn't more than what's deposited
        // bool approved = true;

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            params.amount,
            0
        );

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.FBRedeem(
                IHelper.Selector.FB_REDEEM,
                params.pToken,
                params.user,
                params.amount
            )
        );

        bytes32 _metadata = ecc.preRegMsg(payload, params.user);
        assembly {
            mstore(add(payload, 0x20), _metadata)
        }

        //if approved, update the balance and fire off a return message
        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            markets[chainId][params.pToken].totalSupply -= params.amount;

            require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                fallbackAddress
            );
            
            emit RedeemAllowed(collateralBalances[chainId][params.user][params.pToken], markets[chainId][params.pToken].totalSupply);

        } else {
            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                fallbackAddress
            );

            emit RedeemRejection(shortfall);
        }
    }

    // slither-disable-next-line assembly
    function transferAllowed(
        IHelper.MTransferAllowed memory params,
        bytes32 metadata,
        uint256 chainId,
        address fallbackAddress
    ) public payable onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _accrueInterest();

        (, uint256 shortfall) = _getHypotheticalAccountLiquidity(
            params.user,
            params.pToken,
            0,
            0
        );

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.FBCompleteTransfer(
                uint8(IHelper.Selector.FB_COMPLETE_TRANSFER),
                params.pToken,
                params.spender,
                params.user, // src
                params.dst,
                params.amount // tokens
            )
        );

        bytes32 _metadata = ecc.preRegMsg(payload, params.user);
        assembly {
            mstore(add(payload, 0x20), _metadata)
        }

        // slither-disable-next-line incorrect-equality
        if (shortfall == 0) {
            collateralBalances[chainId][params.user][params.pToken] -= params.amount;
            collateralBalances[chainId][params.dst][params.pToken] += params.amount;

            require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

            middleLayer.msend{value: msg.value}(
                chainId,
                payload, // bytes payload
                payable(msg.sender), // refund address
                fallbackAddress
            );
        } else {
            // TODO: shortfall > 0
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function initialize(address eccAddress) external virtual;

    function borrow(uint256 borrowAmount) external payable virtual;

    // function completeBorrow(
    //     address borrower,
    //     uint borrowAmount
    // ) external virtual;

    function repayBorrow(uint256 repayAmount) external payable virtual returns (bool);

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable virtual returns (bool);

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable virtual;

    function setPUSD(address newPUSD) external virtual;

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./PUSDStorage.sol";
import "./PUSDAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract PUSDMessageHandler is
    PUSDStorage,
    PUSDAdmin,
    ERC20Burnable,
    CommonModifiers
{
    // slither-disable-next-line assembly
    function _sendTokensToChain(
        uint256 _dstChainId,
        address receiver,
        uint256 amount
    ) internal {
        require(msg.sender == receiver, "X_CHAIN_ADDRESS_MUST_MATCH");
        require(!paused, "PUSD_TRANSFERS_PAUSED");

        uint256 _chainId = chainId;

        require(_dstChainId != _chainId, "DIFFERENT_CHAIN_REQUIRED");

        bytes memory payload = abi.encode(
            uint256(0),
            IHelper.PUSDBridge(
                uint8(IHelper.Selector.PUSD_BRIDGE),
                receiver,
                amount
            )
        );

        bytes32 metadata = ecc.preRegMsg(payload, msg.sender);
        assembly {
            mstore(add(payload, 0x20), metadata)
        }

        // burn senders PUSD locally
        _burn(msg.sender, amount);

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            address(0)
        );

        emit SentToChain(_chainId, _dstChainId, receiver, amount);
    }

    function mintFromChain(
        IHelper.PUSDBridge memory params,
        bytes32 metadata,
        uint256 srcChain
    ) external onlyMid() {
        if (!ecc.preProcessingValidation(abi.encode(params), metadata)) return;

        _mint(params.minter, params.amount);

        require(ecc.flagMsgValidated(abi.encode(params), metadata), "FMV");

        emit ReceiveFromChain(srcChain, params.minter, params.amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoute {
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

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

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param token The market to enter
     * @param chainId The chainId
     * @param borrower The address of the account to modify
     */
    function _addToMarket(
        address token,
        uint256 chainId,
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
        uint256 chainId,
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
    ) internal virtual returns (uint256, uint256);

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
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function _liquidateCalculateSeizeTokens(
        address pTokenCollateral,
        uint256 chainId,
        uint256 actualRepayAmount
    ) internal view virtual returns (uint256);

    function _liquidateBorrowAllowed(
        address pTokenCollateral,
        address borrower,
        uint256 chainId,
        uint256 repayAmount
    ) internal virtual returns (bool);

    function satelliteLiquidateBorrow(
        uint256 chainId,
        address borrower,
        address liquidator,
        uint256 seizeTokens,
        address pTokenCollateral
    ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MasterStorage.sol";

abstract contract MasterModifiers is MasterStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(
            IMiddleLayer(msg.sender) == middleLayer,
            "ONLY_MIDDLE_LAYER"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract MasterEvents {
    event CollateralBalanceAdded(
        address indexed user,
        uint256 chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event CollateralChanged(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanAdded(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanChanged(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    event LoanRepaid(
        address indexed user,
        uint256 indexed chainId,
        uint256 prevAmount,
        uint256 newAmount
    );

    /// @notice Emitted when an account enters a deposit market
    event MarketEntered(uint256 chainId, address token, address borrower);

    event ReceiveFromChain(uint256 _srcChainId, address _fromAddress);

    /// @notice Event emitted when a borrow is liquidated
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    // Master Admin Events

    event AddChain(uint256 chainId);

    event ChangeOwner(address newOwner);

    event ChangeMiddleLayer(address oldMid, address newMid);

    event MarketListed(address token);

    event ChangeLiqIncentive(uint256 newLiqIncentive);

    event ChangeCloseFactor(uint256 newCloseFactor);

    event ChangeCollateralFactor(uint256 newCollateralFactor);

    event ChangeProtocolSeizeShare(uint256 newProtocolSeizeShare);

    event SetPUSD(address newPUSD);

    event LoanApproved(uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    event LoanRejection(uint256 shortfall);

    event AccountLiquidity(uint256 collateral, uint256 borrowPlusEffects);

    event RepayBorrowMaster(uint256 loanOutstanding, uint256 totalBorrows, uint256 accountBorrows);

    event RedeemAllowed(uint256 collateralBalanceNew, uint256 totalSupply);

    event RedeemRejection(uint256 shortfall);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: Change this import to somewhere else probably
import "../master/oracle/interfaces/IPTokenOracle.sol";
import "../middleLayer/interfaces/IMiddleLayer.sol";
import "../ecc/interfaces/IECC.sol";

abstract contract MasterStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
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
    * @notice Total amount of reserves of the underlying held in this market
    */
    uint256 public totalReserves;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex; // TODO - needs initialized

    uint256 public liquidityIncentive = 5e6; // 5%
    uint256 public closeFactor = 50e6; // 50%
    uint256 public collateralFactor = 80e6; // 80%
    uint256 public protocolSeizeShare = 5e6; // 5%
    uint256 public reserveFactor = 80e6; // 80%

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    // slither-disable-next-line unused-state
    uint256 internal constant BORROW_RATE_MAX = 0.0005e16;

    // chainid => user => token => token balance
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public collateralBalances;

    // user => chainId => token balance
    mapping(address => mapping(uint256 => uint256)) public loansOutstanding;

    struct Market {
        uint256 collateralFactor;
        uint256 initialExchangeRate;
        uint256 totalSupply;
        string name; // 256
        string symbol; // 256
        address underlying; // 20
        bool isListed; // 8
        uint8 decimals;
        mapping(address => bool) accountMembership;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // chain => ptoken address => market
    mapping(uint256 => mapping(address => Market)) public markets;

    struct InterestSnapshot {
        uint256 interestAccrued;
        uint256 interestIndex;
    }

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
    mapping(address => BorrowSnapshot) public accountBorrows;

    /// @notice A list of all deposit markets
    CollateralMarket[] public allMarkets;

    struct CollateralMarket {
        address token;
        uint256 chainId;
        uint8 decimals;
    }
    // user => interest index
    mapping(address => CollateralMarket[]) public accountAssets;

    uint256[] public chains;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../../satellite/pToken/interfaces/IPToken.sol";
import "../../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPTokenOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(IERC20 pToken) external view returns (uint256);

    /**
     * @notice Get the underlying borrow price of a pToken asset
     * @param loanAgent The loanAgent associated with the pToken
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(ILoanAgent loanAgent) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IPToken {

    function mint(uint256 amount) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount) external virtual payable;


    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;

    function changeOwner(address payable _newOwner) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    // slither-disable-next-line unused-state
    address internal PUSD;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    uint256 public borrowIndex;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract PUSDStorage {
    address internal admin;

    IMiddleLayer internal middleLayer;
    IECC internal ecc;

    address internal treasuryAddress;
    address internal loanAgentAddress;
    uint256 internal chainId;
    bool internal paused;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPUSD.sol";
import "./PUSDModifiers.sol";
import "./PUSDEvents.sol";

abstract contract PUSDAdmin is IPUSD, PUSDModifiers, PUSDEvents, Ownable {

    function setLoanAgent(
        address newLoanAgent
    ) external onlyOwner() {
        require(newLoanAgent != address(0), "NON_ZEROADDRESS");
        loanAgentAddress = newLoanAgent;

        emit SetLoanAgent(newLoanAgent);
    }

    function setOwner(
        address newOwner
    ) external onlyOwner() {
        require(newOwner != address(0), "NON_ZEROADDRESS");
        admin = newOwner;

        emit SetOwner(newOwner);
    }

    function setTreasury(
        address newTreasury
    ) external onlyOwner() {
        require(newTreasury != address(0), "NON_ZEROADDRESS");
        treasuryAddress = newTreasury;

        emit SetTreasury(newTreasury);
    }

    function setMiddleLayer(
        address newMiddleLayer
    ) external onlyOwner() {
        require(newMiddleLayer != address(0), "NON_ZEROADDRESS");
        middleLayer = IMiddleLayer(newMiddleLayer);

        emit SetMiddleLayer(newMiddleLayer);
    }

    function pauseSendTokens(
        bool newPauseStatus
    ) external onlyOwner() {
        paused = newPauseStatus;
        emit Paused(newPauseStatus);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPUSD {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PUSDStorage.sol";

abstract contract PUSDModifiers is PUSDStorage {

    modifier onlyPermissioned() {
        require(
            msg.sender == treasuryAddress ||
            msg.sender == loanAgentAddress ||
            msg.sender == admin, // FIXME: Remove
            "Unauthorized minter"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract PUSDEvents {
    /**
     * @notice Event emitted when contract is paused
     */
    event Paused(bool isPaused);

    /**
     * @notice Event emitted when PUSD is sent cross-chain
     */
    event SentToChain(
        uint256 srcChainId,
        uint256 destChainId,
        address toAddress,
        uint256 amount
    );

    /**
     * @notice Event emitted when PUSD is received cross-chain
     */
    event ReceiveFromChain(
        uint256 srcChainId,
        address toAddress,
        uint256 amount
    );

    event SetLoanAgent(
        address loanAgentAddress
    );

    event SetOwner(
        address owner
    );

    event SetTreasury(
        address treasuryAddress
    );

    event SetMiddleLayer(
        address lzManager
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";
import "../../master/irm/interfaces/IIRM.sol";
import "../../master/crm/interfaces/ICRM.sol";

abstract contract PTokenStorage {
    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

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
    // Currently not in use, may add in future
    // address payable public pendingAdmin;

    /**
    * @notice Model which tells what the current interest rate should be
    */
    IIRM public interestRateModel;

    /**
    * @notice Model which tells whether a user may withdraw collateral or take on additional debt
    */
    ICRM public initialCollateralRatioModel;

    /**
    * @notice EIP-20 token decimals for this token
    */
    uint8 public decimals;

    /**
    * @notice Official record of token balances for each account
    */
    // slither-disable-next-line unused-state
    mapping(address => uint256) internal accountTokens;

    /**
    * @notice Approved token transfer amounts on behalf of others
    */
    // slither-disable-next-line unused-state
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    // slither-disable-next-line unused-state
    uint256 internal _totalSupply;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IPTokenInternals.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract PTokenInternals is IPTokenInternals, IERC20 {

    // slither-disable-next-line assembly
    function _doTransferIn(
        address from,
        uint256 amount
    ) internal virtual override returns (uint256) {
        address pTokenContract = address(this);
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(pTokenContract);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(from, pTokenContract, amount);

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
        uint256 balanceAfter = IERC20(underlying).balanceOf(pTokenContract);
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getCashPrior() internal virtual override view returns (uint256) {
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }

    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        uint256 amount
    ) internal virtual override {
        IERC20 token = IERC20(underlying);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PTokenStorage.sol";

abstract contract PTokenModifiers is PTokenStorage {
    modifier onlyOwner() {
        require(msg.sender == admin, "ONLY_OWNER");
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MIDDLE_LAYER");
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../master/irm/interfaces/IIRM.sol";

abstract contract PTokenEvents {
    /**
    * @notice Event emitted when interest is accrued
    */
    // event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
    * @notice Event emitted when tokens are minted
    */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    
    event MintSent(
        uint8 selector,
        address minter,
        address pToken,
        uint256 accountTokens,
        uint256 mintTokens
    );

    /**
    * @notice Event emitted when tokens are redeemed
    */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event RedeemSent(
        address minter,
        address pToken,
        uint256 accountTokens,
        uint256 redeemAmount
    );

    /**
    * @notice Event emitted when a borrow is liquidated
    */
    // event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /*** Admin Events ***/

    /**
    * @notice Event emitted when pendingAdmin is changed
    */
    // Currently not in use, may use in future
    // event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
    * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
    */
    // Currently not in use, may use in future
    // event NewAdmin(address oldAdmin, address newAdmin);

    /**
    * @notice Event emitted when interestRateModel is changed
    */
    event NewMarketIIRM(
        IIRM oldIIRM,
        IIRM newIIRM
    );

    /**
    * @notice Event emitted when the reserve factor is changed
    */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

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

    event SetMidLayer(
        address middleLayer
    );

    event SetMasterCID(
        uint256 cid
    );

    event ChangeOwner(
        address newOwner
    );

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../../interfaces/IHelper.sol";

abstract contract IPTokenMessageHandler {

    function completeTransfer(
        IHelper.FBCompleteTransfer memory params,
        bytes32 metadata
    ) external virtual;

    function completeRedeem(
        IHelper.FBRedeem memory params,
        bytes32 metadata
    ) external virtual;

    function seize(
        IHelper.SLiquidateBorrow memory params,
        bytes32 metadata
    ) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IIRM {

    function getBasisPointsTickSize() external returns (uint256 tickSize);
    function getBasisPointsUpperTick() external returns (uint256 tick);
    function getBasisPointsLowerTick() external returns (uint256 tick);
    function setBasisPointsTickSize(uint256 price) external returns (uint256 tickSize);
    function setBasisPointsUpperTick(uint256 upperTick) external returns (uint256 tick);
    function setBasisPointsLowerTick(uint256 lowerTick) external returns (uint256 tick);
    function setPusdLowerTargetPrice(uint256 lowerPrice) external returns (uint256 price);
    function setPusdUpperTargetPrice(uint256 upperPrice) external returns (uint256 price);
    function getBorrowRate() external returns (uint256 rate);
    function setBorrowRate() external returns (uint256 rate);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICRM {

    event CollateralRatioModelUpdated(address asset, address collateralRatioModel);
    event AssetLtvRatioUpdated(address asset, uint256 ltvRatio);

    function getCollateralRatioModel(address asset) external returns (address model);
    function getCurrentMaxLtvRatios(address[] calldata assets) external returns (uint256[] memory ratios);
    function getCurrentMaxLtvRatio(address asset) external returns (uint256 ratio);
    function setPusdPriceCeiling(uint256 price) external returns (uint256 ceiling);
    function setPusdPriceFloor(uint256 price) external returns (uint256 floor);
    function setAbsMaxLtvRatios(address[] memory assets, uint256[] memory _maxLtvRatios) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../PTokenStorage.sol";

abstract contract IPTokenInternals is PTokenStorage {//is IERC20 {

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