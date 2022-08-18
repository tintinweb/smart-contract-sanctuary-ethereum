// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IDeCommasStrategyRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ActionPool is Ownable {

    address public dcRouter;
    address public relayer;

    // use this only _polygonActionPoolAddress address in Polygon Network
    modifier onlyRelayer() {
        require(relayer == _msgSender(), "DeCommasRouter: caller is not _actionPool");
        _;
    }

    constructor(address _deCommasRouter, address _relayer) {
        dcRouter = _deCommasRouter;
        relayer = _relayer;
    }


    function bridgeToVault(uint256 amount,
                            address destinationToken,
                            address vaultAddress,
                            uint16 vaultLZId,
                            address token) external onlyRelayer() {
         IDeCommasStrategyRouter(dcRouter).bridge(token, amount, vaultLZId, vaultAddress, destinationToken);
    }


    /*
    @param _funcSignature - function in destination Vault, e.g. "borrow(bytes)"
    @param _targetTransactionData - {address destinationVault,
                                    uint16 lzDestinationChainID,
                                    payload for destination vault's function,
                                    e.g. address token, uint256 amount, bool typeOfPosition}
    */
    function adjustPositionToVault(uint256 strategyId,
                                    string memory _funcSignature,
                                    bytes memory _targetTransactionData) external onlyRelayer() {
        (address targetVault, uint16 destinationChainId, bytes memory _actionData) = abi.decode(_targetTransactionData,
                                                                                            (address, uint16, bytes));
        IDeCommasStrategyRouter(dcRouter).adjustPosition(strategyId,
                                                        destinationChainId,
                                                        targetVault,
                                                        _funcSignature,
                                                        _actionData);
    }


    function depositFundsForUserInRouter(address user,
                                        uint256 strategyID,
                                        uint256 strategyTVL) external onlyRelayer() {
         IDeCommasStrategyRouter(dcRouter).withdrawOrdersToUser(user, strategyID, strategyTVL);
    }


    function setRouterAddress(address _new) external onlyOwner {
        dcRouter = _new;
    }


    function setRelayerAddress(address _new) external onlyOwner {
        relayer = _new;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IDeCommasStrategyRouter {

    function deposit(uint256 strategyId, uint256 stableAmount) external;


    function withdraw(uint256 strategyId, uint256 deTokenAmount) external ;


    function withdrawOrdersToUser(address user, uint256 strategyId, uint256 tvl) external;


    function startStrategyList(uint256 strategyId) external;


    function stopStrategyList(uint256 strategyId) external;


    function bridge(address nativeStableToken,
                    uint256 stableAmount,
                    uint16 vaultLZId,
                    address vaultAddress,
                    address destinationStableToken) external;


    function adjustPosition(uint256 strategyId,
                            uint16 vaultLZId,
                            address vault1,
                            string memory func,
                            bytes memory _actionData) external payable;


    function setRemote(uint16 _chainId, bytes calldata _remoteAddress) external;


    function getDeCommasRegister() external view returns(address);


    function isDeCommasActionStrategy(uint256 strategyId) external view returns(bool);


    function getNativeChainId() external view returns(uint16) ;


    function getNativeLZEndpoint() external view returns(address);


    function getNativeSGBridge() external view returns(address);


    function getStrategyInfo(uint256 strategyId) external view returns(bool status,
                                                                        uint16 sgId1Vault,
                                                                        uint16 sgId2Vault);


    function getUserShares(address user, uint256 strategyId) external view returns(uint256);


    function getPendingTokensToWithdraw(address user, uint256 strategyId) external view returns(uint256);


    function totalSupply(uint256 strategyId) external view returns(uint256);
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