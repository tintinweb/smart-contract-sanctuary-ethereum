//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { Swapper } from "./interfaces/Swapper.sol";
import { IStargateReceiver, IStargateRouter } from "./interfaces/IStargate.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
}

contract SgBridge is Ownable, IStargateReceiver {

    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "SgBridge/not-authorized");
        _;
    }

    modifier live {
        require(alive != 0, "SgBridge/not-live");
        _;
    }

    event Bridge(address indexed user, uint16 indexed chainId, uint256 amount);
    event BridgeSuccess(address indexed user, uint16 indexed srcChainId, address dstChain, uint256 amount);

    uint256 public alive;

    Swapper public swapper;
    IStargateRouter public router;

    struct Destination {
        address receiveContract;
        uint256 destinationPool;
    }

    mapping(uint16 => Destination) public supportedDestinations; //destination stargate_chainId => Destination struct
    mapping(address => uint256) public poolIds; // token address => Stargate poolIds for token

    constructor(address swapper_, address router_) {
        swapper = Swapper(swapper_);
        router = IStargateRouter(router_);

        alive = 1;
        wards[msg.sender] = 1;
    }

    function stop() external auth {
        alive = 0;
    }

    function run() external auth {
        alive = 1;
    }

    // Add stargate pool here. See this table: https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setStargatePoolId(address token, uint256 poolId) external auth {
        poolIds[token] = poolId;
        IERC20(token).approve(address(router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function setSwapper(address swapper_) external auth {
        swapper = Swapper(swapper_);
    }

    // Set destination.
    // Chain id is here:https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    // Receiver is this contract deployed on the other chain
    // PoolId is picked from here https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    function setSupportedDestination(uint16 destChainId, address receiver, uint256 destPoolId) external auth {
        supportedDestinations[destChainId] = Destination(receiver, destPoolId);
    }

    function isTokenSupported(address token) public view returns(bool) {
        if (token == address(0x0) || //TODO
            poolIds[token] != 0) {
            return true;
        }
        return swapper.isTokenSupported(token);
    }

    function createPayload(address destAddress, address destToken) private returns(bytes memory) {
        bytes memory data;
        {
            data = abi.encode(destAddress, destToken);
        }
        return data;
    }

    function getLzParams(address destinationAddress) private pure returns(IStargateRouter.lzTxObj memory) {
        return IStargateRouter.lzTxObj({
            dstGasForCall: 500000,       // extra gas, if calling smart contract,
            dstNativeAmount: 0,     // amount of dust dropped in destination wallet
//            dstNativeAddr: abi.encodePacked(destinationAddress) // destination wallet for dust
            dstNativeAddr: "0x" // destination wallet for dust
        });
    }

    function estimateGasFee(address token,
        uint16 destChainId,
        address destinationAddress) public view returns (uint256, uint256) {

        Destination memory destSgBridge = supportedDestinations[destChainId];
        require(destSgBridge.receiveContract != address(0), "SgBridge/chain-not-supported");

        return router.quoteLayerZeroFee(
            destChainId,
            1, //SWAP
            abi.encodePacked(destSgBridge.receiveContract, token),
            abi.encodePacked(destinationAddress),
            getLzParams(destinationAddress)
        );
    }

    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken) external live payable {
        require(isTokenSupported(token), "SgBridge/token-not-supported");
        Destination memory destination = supportedDestinations[destChainId];
        require(destination.receiveContract != address(0), "SgBridge/chain-not-supported");

        if (token != address(0x0)) {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        uint256 usdtAmount = amount;
        uint256 srcPoolId = poolIds[token];
        if (srcPoolId == 0) { //There are no stargate pool for this token => swap on DEX
            if (token == address(0x0)) {
//                console.log("Value in bridge:" , amount);
                usdtAmount = swapper.toBridgeAsset{value: amount}(token, 0);
            } else {
                usdtAmount = swapper.toBridgeAsset(token, amount);
            }
            srcPoolId = poolIds[swapper.bridgeAsset()];
        }

//        console.log("USDT amount is: ", usdtAmount);

        bytes memory payload = createPayload(destinationAddress, destinationToken);
        router.swap{value:msg.value}(
            destChainId,
            srcPoolId,
            destination.destinationPool,
            payable(msg.sender),
            usdtAmount,
            0,//usdtAmount - 10000000000000000000, FIXME!!!
            getLzParams(destinationAddress),
            abi.encodePacked(destination.receiveContract),
            payload
        );

        emit Bridge(msg.sender, destChainId, amount);
    }

    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint _nonce,
        address _token,
        uint amountLD,
        bytes memory payload) override external {
        require(msg.sender == address(router), "SgBridge/only stargate router can call sgReceive!");

        (address _tokenOut, address _toAddr) = abi.decode(payload, (address, address));

//        uint256 quoteAmount = swapper.fromBridgeAsset(_token, _tokenOut, amountLD, _toAddr);
        IERC20(_token).transferFrom(address(this), _toAddr, amountLD);

        // FIXME: Only for EVM chains
//        address srcAddress = abi.decode(_srcAddress, (address));
//        emit BridgeSuccess(srcAddress, _chainId, _tokenOut, quoteAmount);
//        emit BridgeSuccess(srcAddress, _chainId, _tokenOut, amountLD);
        emit BridgeSuccess(msg.sender, _chainId, _tokenOut, amountLD);
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
pragma solidity ^0.8.0;

interface Swapper {
    function bridgeAsset() external view returns (address);
    function setBridgeAsset(address token) external;

    function toBridgeAsset(address token, uint256 amount) external payable returns (uint256);
    function fromBridgeAsset(address bridgeToken, address token, uint256 amount, address receiver) external returns (uint256);
    function isTokenSupported(address token) external view returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

interface IStargateRouter {
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

    // Router.sol method to get the value for swap()
    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
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