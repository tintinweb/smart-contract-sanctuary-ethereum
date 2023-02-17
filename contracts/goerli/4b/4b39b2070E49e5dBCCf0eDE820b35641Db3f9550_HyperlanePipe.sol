// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import {Router} from "./Router.sol";
import {TypeCasts} from "./TypeCasts.sol";
import {Message} from "./Message.sol";
import "./AuthAdmin.sol";

interface d2OLike {
    function decreaseAllowanceAdmin(address owner, address spender, uint256 subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint256 supply);
    function burn(address,uint256) external;
    function mintAndDelay(address,uint256) external;
    function mint(address,uint256) external;
}

/**
 * @title Hyperlane Token that extends the ERC20 token standard to enable native interchain transfers.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract HyperlanePipe is Router, AuthAdmin("HyperlanePipe", msg.sender) {
    using TypeCasts for bytes32;
    using Message for bytes;

    /**
     * @notice Gas amount to use for destination chain processing
     */
    uint256 internal gasAmount;

    // Origin chain -> recipient address -> nonce -> amount
    mapping (uint32 => mapping(bytes32 => mapping(uint256 => uint256))) failedMessages;

    address public d2OContract;
    address public treasury;
    uint256 public nonce;
    uint256 public teleportFee; // [ray]

    event FailedTransferRemote(uint32 indexed origin, bytes32 indexed recipient, uint256 nonce, uint256 amount);
    event SentTransferRemote(uint32 indexed destination, bytes32 indexed recipient, uint256 amount);
    event ReceivedTransferRemote(uint32 indexed origin, bytes32 indexed recipient, uint256 amout);
    event SetTeleportFee(uint256 teleportFee);

    /**
     * @notice Initializes the Hyperlane router, ERC20 metadata, and mints initial supply to deployer.
     * @param _mailbox The address of the mailbox contract.
     * @param _interchainGasPaymaster The address of the interchain gas paymaster contract.
     * @param _d2OContract d2o contract address
     * @param _gasAmount default gas amount to send to destination chain
     */
    function initialize(
        address _mailbox,
        address _interchainGasPaymaster,
        address _d2OContract, 
        uint256 _gasAmount,
        address _treasury
    ) external initializer {
        require(_mailbox != address(0) 
        && _interchainGasPaymaster != address(0) 
        && _d2OContract != address(0), 
        "d2OConnectorHyperlane/invalid address");

        _transferOwnership(msg.sender);
        __HyperlaneConnectionClient_initialize(
            _mailbox,
            _interchainGasPaymaster
        );

        gasAmount = _gasAmount;
        d2OContract = _d2OContract;
        treasury = _treasury;
    }

    //
    // --- Maths ---
    //
    uint256 constant RAY = 10 ** 27;
    // Can only be used sensibly with the following combination of units:
    // - `_wadmul(wad, ray) -> wad`
    function _wadmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }

    function setTreasury(address _treasury) external auth {
        require(_treasury != address(0x0), "d2OConnectorLZ/Can't be zero address");
        treasury = _treasury;
    }

    function setTeleportFee(uint256 _teleportFee) external auth {
        require(_teleportFee < RAY, "d2OConnectorLZ/Fees must be less than 100%");
        teleportFee = _teleportFee;
        emit SetTeleportFee(teleportFee);
    }

    /**
     * @notice Transfers `_amount` of tokens from `msg.sender` to `_recipient` on the `_destination` chain.
     * @dev Burns `_amount` of tokens from `msg.sender` on the origin chain and dispatches
     *      message to the `destination` chain to mint `_amount` of tokens to `recipient`.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _destination The identifier of the destination chain.
     * @param _recipient The address of the recipient on the destination chain.
     * @param _amount The amount of tokens to be sent to the remote recipient.
     */
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) external payable alive {
        require(_amount > 0, "d2OConnectorHyperlane/Amount cannot be zero");
        require(_recipient != bytes32(""), "d2OConnectorHyperlane/Recipient address cannot be blank");
        d2OLike(d2OContract).burn(msg.sender, _amount);
        _dispatchWithGas(
            _destination,
            Message.format(_recipient, _amount, bytes("")),
            gasAmount,
            msg.value,
            msg.sender
        );
        emit SentTransferRemote(_destination, _recipient, _amount);
    }

    /**
     * @dev Mints tokens to recipient when router receives transfer message.
     * @dev Emits `ReceivedTransferRemote` event on the destination chain.
     * @param _origin The identifier of the origin chain.
     * @param _message The encoded remote transfer message containing the recipient address and amount.
     */
    function _handle(
        uint32 _origin,
        bytes32,
        bytes calldata _message
    ) internal override alive {

        bytes32 recipient   = _message.recipient();
        uint256 amount      = _message.amount();
        uint256 feeAmount   = _wadmul(amount, teleportFee); // wadmul(wad * ray) = wad
        amount             -= feeAmount;

        d2OLike(d2OContract).mint(treasury, feeAmount);
        try d2OLike(d2OContract).mintAndDelay(recipient.bytes32ToAddress(), amount) {
            emit ReceivedTransferRemote(_origin, recipient, amount);
        } catch {
            failedMessages[_origin][recipient][nonce] = amount;
            emit FailedTransferRemote(_origin, recipient, nonce, amount);
        }
        nonce++;
    }

    /**
     * @dev Retries previous failed mints.
     * @dev Emits `ReceivedTransferRemote` event on the destination chain.
     * @param _origin The identifier of the origin chain.
     * @param _recipient The address of the recipient on receiving chain.
     */
    function retry(uint32 _origin, bytes32 _recipient, uint256 _nonce) external alive {
        uint256 amount = failedMessages[_origin][_recipient][_nonce];
        require(amount > 0, "d2OConnectorHyperlane/Amount must be greater than 0 to retry");

        try d2OLike(d2OContract).mintAndDelay(_recipient.bytes32ToAddress(), amount) {
            delete failedMessages[_origin][_recipient][_nonce];
            emit ReceivedTransferRemote(_origin, _recipient, amount);
        } catch {
            emit FailedTransferRemote(_origin, _recipient, nonce, amount);
        }
    }

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router) external override auth {
        _enrollRemoteRouter(_domain, _router);
    }
}