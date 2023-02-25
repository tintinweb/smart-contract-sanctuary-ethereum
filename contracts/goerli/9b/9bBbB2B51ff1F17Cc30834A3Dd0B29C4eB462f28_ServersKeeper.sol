// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import {BaseServer} from "./BaseServer.sol";

interface IEnceladus {
    function pendingNvls(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract ServersKeeper is Ownable, KeeperCompatibleInterface {
    IEnceladus internal immutable enceladus;

    uint256 public minTimePeriod;

    address[] internal servers;
    mapping(address => uint256) public lastHarvestAndBridge;

    constructor(address _enceladus, uint256 _minTimePeriod) {
        enceladus = IEnceladus(_enceladus);
        minTimePeriod = _minTimePeriod;
    }

    ///@notice Set the array of servers to be checked by the keeper
    function setServers(address[] calldata _servers) external onlyOwner {
        for (uint256 i = 0; i < _servers.length; ) {
            lastHarvestAndBridge[_servers[i]] = block.timestamp;

            unchecked {
                i += 1;
            }
        }
        servers = _servers;
    }

    function setMinTimePeriod(uint256 newMinTimePeriod) external onlyOwner {
        minTimePeriod = newMinTimePeriod;
    }

    ///@notice View function checked by the keeper on every block
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 length = servers.length;
        for (uint256 i = 0; i < length; i++) {
            address server = servers[i];
            if (
                lastHarvestAndBridge[server] + minTimePeriod <
                block.timestamp &&
                enceladus.pendingNvls(BaseServer(server).pid(), server) > 0
            ) {
                return (true, abi.encode(server));
            }
        }
    }

    ///@notice Function executed by the keeper if checkUpKeep returns true
    function performUpkeep(bytes calldata performData) external {
        address server = abi.decode(performData, (address));
        if (
            lastHarvestAndBridge[server] + minTimePeriod < block.timestamp &&
            enceladus.pendingNvls(BaseServer(server).pid(), server) > 0
        ) {
            BaseServer(server).harvestAndBridge();
            lastHarvestAndBridge[server] = block.timestamp;
        }
    }

    ///@notice Servers array getter
    function getServers() external view returns (address[] memory) {
        return servers;
    }
}

// SPDX-License-Identifier: MIT
// NEVELLUS BASE-SERVER CONTRACT FOR TESTNET

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEnceladus {
    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
    function bridge() external;
}

abstract contract BaseServer is Ownable {
    IEnceladus public constant enceladus =
        IEnceladus(0xde6006F056c3835A7139a4b494466E6b199a5FB2);
    IERC20 public constant nvls =
        IERC20(0xd61Da82Da6ebcAC294fd6FD292f024de14593540);

    uint256 public immutable pid;

    address public immutable dione;

    address public bridgeAdapter;

    event Harvested(uint256 indexed pid);
    event Withdrawn(uint256 indexed pid, uint256 indexed amount);
    event Deposited(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnNvls(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnDummyToken(uint256 indexed pid);
    event BridgeUpdated(address indexed newBridgeAdapter);

    constructor(uint256 _pid, address _dione) {
        pid = _pid;
        dione = _dione;
        bridgeAdapter = address(this);
    }

    function harvestAndBridge() public {
        enceladus.withdraw(pid, 0);
        bridge();
        emit Harvested(pid);
    }

    function withdraw() public onlyOwner {
        enceladus.withdraw(pid, 1);
        emit Withdrawn(pid, 1);
    }

    function deposit(address token) public onlyOwner {
        IERC20(token).approve(address(enceladus), 1);
        enceladus.deposit(pid, 1);
        emit Deposited(pid, 1);
    }

    function withdrawNevellusToken(address recipient) public onlyOwner {
        uint256 nvlsBalance = nvls.balanceOf(address(this));
        nvls.transfer(recipient, nvlsBalance);
        emit WithdrawnNvls(pid, nvlsBalance);
    }

    function withdrawDummyToken(address token, address recipient)
        public
        onlyOwner
    {
        IERC20(token).transfer(recipient, 1);
        emit WithdrawnDummyToken(pid);
    }

    function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
        require(newBridgeAdapter != address(0), "zero address");
        bridgeAdapter = newBridgeAdapter;
        emit BridgeUpdated(newBridgeAdapter);
    }

    function bridge() public {
        if (bridgeAdapter == address(this)) {
            _bridge();
        } else {
            uint256 nvlsBalance = nvls.balanceOf(address(this));
            nvls.transfer(bridgeAdapter, nvlsBalance);
            IBridgeAdapter(bridgeAdapter).bridge();
        }
    }

    function _bridge() internal virtual;
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