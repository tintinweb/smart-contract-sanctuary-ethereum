// SPDX-License-Identifier: GPL-3.0
// uni -> stable -> uni scheme

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MetaRouteStructs.sol";
import "./MetaRouterGateway.sol";
import "../../utils/RevertMessageParser.sol";

/**
 * @title MetaRouterV3
 * @notice Users must give approve on their tokens to `MetaRoutetGateway` contract,
 * not to `MetaRouter` contract.
 */
contract MetaRouter is Context {
    MetaRouterGateway public immutable metaRouterGateway;

    constructor() {
        metaRouterGateway = new MetaRouterGateway(address(this));
    }

    /**
     * @notice Method that starts the Meta Routing
     * @dev external + internal swap for burn scheme, only external for synth scheme
     * @dev calls the next method on the other side
     * @param _metarouteTransaction metaRoute offchain transaction data
     */
    function metaRoute(
        MetaRouteStructs.MetaRouteTransaction calldata _metarouteTransaction
    ) external payable {
        uint256 approvedTokensLength = _metarouteTransaction.approvedTokens.length;

        if (!_metarouteTransaction.nativeIn) {
            metaRouterGateway.claimTokens(
                _metarouteTransaction.approvedTokens[0],
                _msgSender(),
                _metarouteTransaction.amount
            );
        }

        uint256 secondSwapAmountIn = _metarouteTransaction.amount;
        if (_metarouteTransaction.firstSwapCalldata.length != 0) {
            if (!_metarouteTransaction.nativeIn) {
                _lazyApprove(
                    _metarouteTransaction.approvedTokens[0],
                    _metarouteTransaction.firstDexRouter,
                    _metarouteTransaction.amount
                );
            }

            require(
                _metarouteTransaction.firstDexRouter != address(metaRouterGateway),
                "MetaRouter: invalid first router"
            );

            (bool firstSwapSuccess, bytes memory swapData) = _metarouteTransaction.firstDexRouter.call{value: msg.value}(
                _metarouteTransaction.firstSwapCalldata
            );

            if (!firstSwapSuccess) {
                revert(RevertMessageParser.getRevertMessage(swapData, "MetaRouter: first swap failed"));
            }

            secondSwapAmountIn = IERC20(_metarouteTransaction.approvedTokens[1]).balanceOf(address(this));
        }

        uint256 finalSwapAmountIn = secondSwapAmountIn;
        if (_metarouteTransaction.secondSwapCalldata.length != 0) {
            bytes memory secondSwapCalldata = _metarouteTransaction.secondSwapCalldata;

            assembly {
                mstore(add(secondSwapCalldata, 100), secondSwapAmountIn)
            }

            _lazyApprove(
                _metarouteTransaction.approvedTokens[approvedTokensLength - 2],
                _metarouteTransaction.secondDexRouter,
                secondSwapAmountIn
            );

            require(
                _metarouteTransaction.secondDexRouter != address(metaRouterGateway),
                "MetaRouter: invalid second router"
            );

            (bool secondSwapSuccess, bytes memory swapData) = _metarouteTransaction.secondDexRouter.call(secondSwapCalldata);

            if (!secondSwapSuccess) {
                revert(RevertMessageParser.getRevertMessage(swapData, "MetaRouter: second swap failed"));
            }

            finalSwapAmountIn = IERC20(
                _metarouteTransaction.approvedTokens[approvedTokensLength - 1]
            ).balanceOf(address(this));
        }

        _lazyApprove(
            _metarouteTransaction.approvedTokens[approvedTokensLength - 1],
            _metarouteTransaction.relayRecipient,
            finalSwapAmountIn
        );

        bytes memory otherSideCalldata = _metarouteTransaction.otherSideCalldata;
        assembly {
            mstore(add(otherSideCalldata, 100), finalSwapAmountIn)
        }

        require(
            _metarouteTransaction.relayRecipient != address(metaRouterGateway),
            "MetaRouter: invalid recipient"
        );

        (bool otherSideCallSuccess, bytes memory data) = _metarouteTransaction.relayRecipient.call(otherSideCalldata);

        if (!otherSideCallSuccess) {
            revert(RevertMessageParser.getRevertMessage(data, "MetaRouter: other side call failed"));
        }
    }

    /**
     * @notice Implements an external call on some contract
     * @dev called by Portal in metaUnsynthesize() method
     * @param _token address of token
     * @param _amount amount of _token
     * @param _receiveSide contract on which call will take place
     * @param _calldata encoded method to call
     * @param _offset shift to patch the amount to calldata
     */
    function externalCall(
        address _token,
        uint256 _amount,
        address _receiveSide,
        bytes calldata _calldata,
        uint256 _offset
    ) external {
        (bool success, bytes memory data) = _externalCall(_token, _amount, _receiveSide, _calldata, _offset);

        if (!success) {
            revert(RevertMessageParser.getRevertMessage(data, "MetaRouter: external call failed"));
        }
    }

    /**
     * @notice Implements an internal swap on stable router and final method call
     * @dev called by Synthesis in metaMint() method
     * @param _metaMintTransaction metaMint offchain transaction data
     */
    function metaMintSwap(
        MetaRouteStructs.MetaMintTransaction calldata _metaMintTransaction
    ) external {
        address finalCallToken = _metaMintTransaction.swapTokens[0];
        if (_metaMintTransaction.secondSwapCalldata.length != 0) {
            // internal swap
            (bool internalSwapSuccess, bytes memory internalSwapData) = _externalCall(
                _metaMintTransaction.swapTokens[0],
                _metaMintTransaction.amount,
                _metaMintTransaction.secondDexRouter,
                _metaMintTransaction.secondSwapCalldata,
                100
            );

            if (!internalSwapSuccess) {
                revert(RevertMessageParser.getRevertMessage(internalSwapData, "MetaRouter: internal swap failed"));
            }

            uint256 internalSwapReturnAmount = IERC20(_metaMintTransaction.swapTokens[1]).balanceOf(address(this));

            // exit without external call
            if (_metaMintTransaction.swapTokens.length == 2) {
                TransferHelper.safeTransfer(
                    _metaMintTransaction.swapTokens[1],
                    _metaMintTransaction.to,
                    internalSwapReturnAmount
                );
                return;
            }

            finalCallToken = _metaMintTransaction.swapTokens[1];
        }
        uint256 finalAmountIn = IERC20(finalCallToken).balanceOf(address(this));
        // external call
        (bool finalSuccess, bytes memory finalData) = _externalCall(
            finalCallToken,
            finalAmountIn,
            _metaMintTransaction.finalReceiveSide,
            _metaMintTransaction.finalCalldata,
            _metaMintTransaction.finalOffset
        );

        if (!finalSuccess) {
            revert(RevertMessageParser.getRevertMessage(finalData, "MetaRouter: final call failed"));
        }

        uint256 externalCallAmountOut = IERC20(_metaMintTransaction.swapTokens[_metaMintTransaction.swapTokens.length - 1]).balanceOf(address(this));
        if (externalCallAmountOut != 0) {
            TransferHelper.safeTransfer(
                _metaMintTransaction.swapTokens[_metaMintTransaction.swapTokens.length - 1],
                _metaMintTransaction.to,
                externalCallAmountOut
            );
        }
    }

    /**
     * @notice Implements call of some operation with token
     * @dev Internal function used in metaMintSwap() and externalCall()
     * @param _token token address
     * @param _amount amount of _token
     * @param _receiveSide address of contract on which method will be called
     * @param _calldata encoded method call
     * @param _offset shift to patch the _amount to calldata
     */
    function _externalCall(
        address _token,
        uint256 _amount,
        address _receiveSide,
        bytes memory _calldata,
        uint256 _offset
    ) internal returns (bool success, bytes memory data) {
        require(_receiveSide != address(metaRouterGateway), "MetaRouter: invalid receiveSide");

        _lazyApprove(_token, _receiveSide, _amount);

        assembly {
            mstore(add(_calldata, _offset), _amount)
        }

        (success, data) = _receiveSide.call(_calldata);
    }

    /**
     * @notice Implements approve
     * @dev Internal function used to approve the token spending
     * @param _token token address
     * @param _to address to approve
     * @param _amount amount for which approve will be given
     */
    function _lazyApprove(address _token, address _to, uint256 _amount) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            TransferHelper.safeApprove(_token, _to, type(uint256).max);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library MetaRouteStructs {
    struct MetaBurnTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address syntCaller;
        address finalReceiveSide;
        address sToken;
        bytes finalCallData;
        uint256 finalOffset;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address revertableAddress;
        uint256 chainID;
        bytes32 clientID;
    }

    struct MetaMintTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        bytes32 externalID;
        address tokenReal;
        uint256 chainID;
        address to;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
    }

    struct MetaRouteTransaction {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        uint256 amount;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
    }

    struct MetaSynthesizeTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rtoken;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address syntCaller;
        uint256 chainID;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
        address revertableAddress;
        bytes32 clientID;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @title MetaRouterGateway
 * @notice During the `metaRoute` transaction `MetaRouter` (only) claims user's tokens
 * from `MetaRoutetGateway` contract and then operates with them.
 */
contract MetaRouterGateway {
    address public immutable metaRouter;

    modifier onlyMetarouter() {
        require(metaRouter == msg.sender, "Symb: caller is not the metarouter");
        _;
    }

    constructor(address _metaRouter) {
        metaRouter = _metaRouter;
    }

    function claimTokens(
        address _token,
        address _from,
        uint256 _amount
    ) external onlyMetarouter {
        TransferHelper.safeTransferFrom(_token, _from, metaRouter, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library RevertMessageParser {
    function getRevertMessage(bytes memory _data, string memory _defaultMessage) internal pure returns (string memory) {
        // If the _data length is less than 68, then the transaction failed silently (without a revert message)
        if (_data.length < 68) return _defaultMessage;

        assembly {
            // Slice the sighash
            _data := add(_data, 0x04)
        }
        return abi.decode(_data, (string));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}