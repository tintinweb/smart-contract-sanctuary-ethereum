// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/IOptiSwap.sol";

contract OptiSwap is Ownable, IOptiSwap {
    address public immutable override weth;

    mapping(address => address) getBridge;
    address[] public override bridgeFromTokens;

    DexInfo[] dexList;
    mapping(address => bool) public override getDexEnabled;

    constructor(address _weth) {
        weth = _weth;
    }

    function getBridgeToken(address _token) external view override returns (address bridgeToken) {
        bridgeToken = getBridge[_token];
        if (bridgeToken == address(0)) {
            bridgeToken = weth;
        }
    }

    function bridgeFromTokensLength() external view override returns (uint256) {
        return bridgeFromTokens.length;
    }

    function addBridgeToken(address _token, address _bridgeToken) public override onlyOwner {
        require(_token != weth, "OptiSwap: INVALID_TOKEN_WETH");
        require(_token != _bridgeToken, "OptiSwap: INVALID_BRIDGE_TOKEN_SAME");
        require(_bridgeToken != address(0), "OptiSwap: INVALID_BRIDGE_TOKEN_ZERO");
        require(_bridgeToken.code.length > 0, "OptiSwap: INVALID_BRIDGE_TOKEN");
        require(getBridge[_bridgeToken] != _token, "OptiSwap: INVALID_BRIDGE_LOOP");
        if (getBridge[_token] == address(0)) {
            bridgeFromTokens.push(_token);
        }
        getBridge[_token] = _bridgeToken;
    }

    function addBridgeTokenBulk(TokenBridge[] calldata _tokenBridgeList) external override onlyOwner {
        uint256 count = _tokenBridgeList.length;
        require(count > 0, "EMPTY_LIST");
        for (uint256 i = 0; i < count; i++) {
            addBridgeToken(_tokenBridgeList[i].token, _tokenBridgeList[i].bridgeToken);
        }
    }

    function addDex(address _dex, address _handler) public override onlyOwner {
        require(!getDexEnabled[_dex], "OptiSwap: DEX_ALREADY_ENABLED");
        dexList.push(DexInfo({dex: _dex, handler: _handler}));
        getDexEnabled[_dex] = true;
    }

    function addDexBulk(DexInfo[] calldata _dexList) external override onlyOwner {
        uint256 count = _dexList.length;
        require(count > 0, "EMPTY_LIST");
        for (uint256 i = 0; i < count; i++) {
            addDex(_dexList[i].dex, _dexList[i].handler);
        }
    }

    function indexOfDex(address _dex) public view override returns (uint256 index) {
        for (uint256 i = 0; i < dexList.length; i++) {
            if (dexList[i].dex == _dex) {
                return i;
            }
        }
        require(false, "OptiSwap: DEX_NOT_FOUND");
    }

    function removeDex(address _dex) external override onlyOwner {
        require(getDexEnabled[_dex], "OptiSwap: DEX_NOT_ENABLED");
        uint256 index = indexOfDex(_dex);
        DexInfo memory last = dexList[dexList.length - 1];
        dexList[index] = last;
        dexList.pop();
        delete getDexEnabled[_dex];
    }

    function dexListLength() external view override returns (uint256) {
        return dexList.length;
    }

    function getDexInfo(uint256 index) external view override returns (address dex, address handler) {
        dex = dexList[index].dex;
        handler = dexList[index].handler;
    }

    function getBestAmountOut(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view override returns (address pair, uint256 amountOut) {
        uint256 dexCount = dexList.length;
        for (uint256 dexIndex = 0; dexIndex < dexCount; dexIndex++) {
            DexInfo storage dexInfo = dexList[dexIndex];
            try IDexHandler(dexInfo.handler).getAmountOut(dexInfo.dex, _amountIn, _tokenIn, _tokenOut) returns (address dexPair, uint256 dexAmountOut) {
                if (dexPair == address(0)) {
                    continue;
                }
                if (dexAmountOut > amountOut) {
                    pair = dexPair;
                    amountOut = dexAmountOut;
                }
            } catch {
                continue;
            }
        }
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IDexHandler {
    function getAmountOut(
        address _dex,
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (address pair, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOptiSwap {
    function weth() external view returns (address);

    function bridgeFromTokens(uint256 index) external view returns (address token);

    function bridgeFromTokensLength() external view returns (uint256);

    function getBridgeToken(address _token) external view returns (address bridgeToken);

    function addBridgeToken(address _token, address _bridgeToken) external;

    struct TokenBridge {
        address token;
        address bridgeToken;
    }

    function addBridgeTokenBulk(TokenBridge[] calldata _tokenBridgeList) external;

    function getDexInfo(uint256 index) external view returns (address dex, address handler);

    function dexListLength() external view returns (uint256);

    function indexOfDex(address _dex) external view returns (uint256);

    function getDexEnabled(address _dex) external view returns (bool);

    struct DexInfo {
        address dex; // Factory or Router
        address handler; // DexHandler
    }

    function addDex(address _dex, address _handler) external;

    function addDexBulk(DexInfo[] calldata _dexList) external;

    function removeDex(address _dex) external;

    function getBestAmountOut(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (address pair, uint256 amountOut);
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