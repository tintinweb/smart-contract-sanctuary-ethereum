// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ITapiocaOFT.sol";
import "./interfaces/IStargateRouter.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

//
//                 .(%%%%%%%%%%%%*       *
//             #%%%%%%%%%%%%%%%%%%%%*  ####*
//          #%%%%%%%%%%%%%%%%%%%%%#  /####
//       ,%%%%%%%%%%%%%%%%%%%%%%%   ####.  %
//                                #####
//                              #####
//   #####%#####              *####*  ####%#####*
//  (#########(              #####     ##########.
//  ##########             #####.      .##########
//                       ,####/
//                      #####
//  %%%%%%%%%%        (####.           *%%%%%%%%%#
//  .%%%%%%%%%%     *####(            .%%%%%%%%%%
//   *%%%%%%%%%%   #####             #%%%%%%%%%%
//               (####.
//      ,((((  ,####(          /(((((((((((((
//        *,  #####  ,(((((((((((((((((((((
//          (####   ((((((((((((((((((((/
//         ####*  (((((((((((((((((((
//                     ,**//*,.

/// Transfers tokens to other layers through Stargate
contract Balancer is Owned {
    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice current OFT => chain => destination OFT
    /// @dev chain ids (https://stargateprotocol.gitbook.io/stargate/developers/chain-ids):
    ///         - Ethereum: 101
    ///         - BNB: 102
    ///         - Avalanche: 106
    ///         - Polygon: 109
    ///         - Arbitrum: 110
    ///         - Optimism: 111
    ///         - Fantom: 112
    ///         - Metis: 151
    ///     pool ids https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    mapping(address => mapping(uint16 => OFTData)) public connectedOFTs;

    struct OFTData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        address dstOft;
        uint256 rebalanceable;
    }

    IStargateRouter immutable routerETH;
    IStargateRouter immutable router;

    uint256 private constant SLIPPAGE_PRECISION = 1e5;

    // ************************ //
    // *** EVENTS FUNCTIONS *** //
    // ************************ //
    event ConnectedChainUpdated(
        address indexed _srcOft,
        uint16 _dstChainId,
        address indexed _dstOft
    );
    event Rebalanced(
        address indexed _srcOft,
        uint16 _dstChainId,
        uint256 _slippage,
        uint256 _amount,
        bool _isNative
    );
    event RebalanceAmountUpdated(
        address _srcOft,
        uint16 _dstChainId,
        uint256 _amount,
        uint256 _totalAmount
    );

    // ************************ //
    // *** ERRORS FUNCTIONS *** //
    // ************************ //
    error RouterNotValid();
    error ExceedsBalance();
    error DestinationNotValid();
    error SlippageNotValid();
    error FeeAmountNotSet();
    error PoolInfoRequired();
    error RebalanceAmountNotSet();
    error DestinationOftNotValid();

    // *************************** //
    // *** MODIFIERS FUNCTIONS *** //
    // *************************** //
    modifier onlyValidDestination(address _srcOft, uint16 _dstChainId) {
        if (connectedOFTs[_srcOft][_dstChainId].dstOft == address(0))
            revert DestinationNotValid();
        _;
    }

    modifier onlyValidSlippage(uint256 _slippage) {
        if (_slippage >= 1e5) revert SlippageNotValid();
        _;
    }

    constructor(
        address _routerETH,
        address _router,
        address _owner
    ) Owned(_owner) {
        if (_router == address(0)) revert RouterNotValid();
        if (_routerETH == address(0)) revert RouterNotValid();
        routerETH = IStargateRouter(_routerETH);
        router = IStargateRouter(_router);
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    function checker(
        address payable _srcOft,
        uint16 _dstChainId
    ) external view returns (bool canExec, bytes memory execPayload) {
        bytes memory ercData;
        if (ITapiocaOFT(_srcOft).isNative()) {
            ercData = abi.encode(
                connectedOFTs[_srcOft][_dstChainId].srcPoolId,
                connectedOFTs[_srcOft][_dstChainId].dstPoolId
            );
        }

        canExec = connectedOFTs[_srcOft][_dstChainId].rebalanceable > 0;
        execPayload = abi.encodeCall(
            Balancer.rebalance,
            (
                _srcOft,
                _dstChainId,
                1e3, //1% slippage
                connectedOFTs[_srcOft][_dstChainId].rebalanceable,
                ercData
            )
        );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    function rebalance(
        address payable _srcOft,
        uint16 _dstChainId,
        uint256 _slippage,
        uint256 _amount,
        bytes memory _ercData
    )
        external
        payable
        onlyOwner
        onlyValidDestination(_srcOft, _dstChainId)
        onlyValidSlippage(_slippage)
    {
        if (connectedOFTs[_srcOft][_dstChainId].rebalanceable < _amount)
            revert RebalanceAmountNotSet();

        //check if OFT is still valid
        if (
            !_isValidOft(
                _srcOft,
                connectedOFTs[_srcOft][_dstChainId].dstOft,
                _dstChainId
            )
        ) revert DestinationOftNotValid();

        //extract
        ITapiocaOFT(_srcOft).extractUnderlying(_amount);

        //send
        bool _isNative = ITapiocaOFT(_srcOft).isNative();
        if (_isNative) {
            if (msg.value <= _amount) revert FeeAmountNotSet();
            _sendNative(_srcOft, _amount, _dstChainId, _slippage);
        } else {
            if (msg.value == 0) revert FeeAmountNotSet();
            _sendToken(_srcOft, _amount, _dstChainId, _slippage, _ercData);
        }

        connectedOFTs[_srcOft][_dstChainId].rebalanceable -= _amount;
        emit Rebalanced(_srcOft, _dstChainId, _slippage, _amount, _isNative);
    }

    function initConnectedOFT(
        address _srcOft,
        uint16 _dstChainId,
        address _dstOft,
        bytes memory _ercData
    ) external onlyOwner {
        bool isNative = ITapiocaOFT(_srcOft).isNative();
        if (!isNative && _ercData.length == 0) revert PoolInfoRequired();
        if (!_isValidOft(_srcOft, _dstOft, _dstChainId))
            revert DestinationOftNotValid();

        (uint256 _srcPoolId, uint256 _dstPoolId) = abi.decode(
            _ercData,
            (uint256, uint256)
        );

        OFTData memory oftData = OFTData({
            srcPoolId: _srcPoolId,
            dstPoolId: _dstPoolId,
            dstOft: _dstOft,
            rebalanceable: 0
        });

        connectedOFTs[_srcOft][_dstChainId] = oftData;
        emit ConnectedChainUpdated(_srcOft, _dstChainId, _dstOft);
    }

    function addRebalanceAmount(
        address _srcOft,
        uint16 _dstChainId,
        uint256 _amount
    ) external onlyValidDestination(_srcOft, _dstChainId) onlyOwner {
        connectedOFTs[_srcOft][_dstChainId].rebalanceable += _amount;
        emit RebalanceAmountUpdated(
            _srcOft,
            _dstChainId,
            _amount,
            connectedOFTs[_srcOft][_dstChainId].rebalanceable
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //

    function _isValidOft(
        address _srcOft,
        address _dstOft,
        uint16 _dstChainId
    ) private view returns (bool) {
        bytes memory trustedRemotePath = abi.encodePacked(_dstOft, _srcOft);
        return
            ITapiocaOFT(_srcOft).isTrustedRemote(
                _dstChainId,
                trustedRemotePath
            );
    }

    function _sendNative(
        address payable _oft,
        uint256 _amount,
        uint16 _dstChainId,
        uint256 _slippage
    ) private {
        if (address(this).balance < _amount) revert ExceedsBalance();

        routerETH.swapETH(
            _dstChainId,
            _oft, //refund
            abi.encodePacked(connectedOFTs[_oft][_dstChainId].dstOft),
            _amount,
            _computeMinAmount(_amount, _slippage)
        );
    }

    function _sendToken(
        address payable _oft,
        uint256 _amount,
        uint16 _dstChainId,
        uint256 _slippage,
        bytes memory _data
    ) private {
        if (ITapiocaOFT(_oft).erc20().balanceOf(address(this)) < _amount)
            revert ExceedsBalance();

        (uint256 _srcPoolId, uint256 _dstPoolId) = abi.decode(
            _data,
            (uint256, uint256)
        );

        IStargateRouter.lzTxObj memory _lzTxParams = IStargateRouterBase
            .lzTxObj({
                dstGasForCall: 0,
                dstNativeAmount: msg.value,
                dstNativeAddr: abi.encode(
                    connectedOFTs[_oft][_dstChainId].dstOft
                )
            });

        ITapiocaOFT(_oft).erc20().approve(address(router), _amount);
        router.swap(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            _oft, //refund,
            _amount,
            _computeMinAmount(_amount, _slippage),
            _lzTxParams,
            _lzTxParams.dstNativeAddr,
            "0x"
        );
    }

    function _computeMinAmount(
        uint256 _amount,
        uint256 _slippage
    ) private pure returns (uint256) {
        return _amount - ((_amount * _slippage) / SLIPPAGE_PRECISION);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStargateRouterBase {
    //for Router
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

interface IStargateRouter is IStargateRouterBase {
    //for RouterETH
    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITapiocaOFT {
    function totalFees() external view returns (uint256);

    function erc20() external view returns (IERC20);

    function hostChainID() external view returns (uint256);

    function wrappedAmount(uint256 _amount) external view returns (uint256);

    function wrap(address _toAddress, uint256 _amount) external;

    function wrapNative(address _toAddress) external payable;

    function harvestFees() external;

    function unwrap(address _toAddress, uint256 _amount) external;

    function isHostChain() external view returns (bool);

    function balanceOf(address _holder) external view returns (uint256);

    function isNative() external view returns (bool);

    function extractUnderlying(uint256 _amount) external;

    function approve(address _spender, uint256 _amount) external returns (bool);

    function isTrustedRemote(
        uint16 _lzChainId,
        bytes calldata _path
    ) external view returns (bool);
}