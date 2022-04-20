// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDaoDepositManager.sol";
import "./interfaces/IModuleBase.sol";

/**
 * @title                   PrimeDeals Deal Manager
 * @notice                  Smart contract to serve as the manager
                            for the PrimeDeals architecture
 */
contract DealManager is Ownable {
    /// Address of the current implementation of the
    /// DaoDepositManager
    address public daoDepositManagerImplementation;
    /// Address of the ETH wrapping contract
    address public immutable weth;
    /// Address DAO => address DaoDepositManager of the DAO
    mapping(address => address) public daoDepositManager;
    /// module address => true/false
    mapping(address => bool) public isModule;

    /**
     * @notice                      This event is emitted when a DaoDepositManager is created
     * @param dao                   DAO address to which the DaoDepositManager is linked
     * @param daoDepositManager     Newly created DaoDepositManager contract address
     */
    event DaoDepositManagerCreated(
        address indexed dao,
        address indexed daoDepositManager
    );

    /**
     * @notice                      Constructor
     * @param _daoDepositManager    The address of the DaoDepositManager implementation
     */
    constructor(address _daoDepositManager, address _weth) {
        require(
            _daoDepositManager != address(0) &&
                _daoDepositManager != address(this),
            "DealManager: Error 100"
        );
        require(
            _weth != address(0) && _weth != address(this),
            "DealManager: Error 100"
        );
        daoDepositManagerImplementation = _daoDepositManager;
        weth = _weth;
    }

    /**
     * @notice                      Sets a new address for the DaoDepositManager implementation
     * @param _newImplementation    The new address of the DaoDepositManager
     */
    function setDaoDepositManagerImplementation(address _newImplementation)
        external
        onlyOwner
    {
        // solhint-disable-next-line reason-string
        require(
            _newImplementation != address(0) &&
                _newImplementation != address(this),
            "DealManager: Error 100"
        );
        daoDepositManagerImplementation = _newImplementation;
    }

    /**
     * @notice                  Activates a new Deals module
     * @param _moduleAddress    The address of a Deals module
     */
    function activateModule(address _moduleAddress) external onlyOwner {
        require(
            _moduleAddress != address(0) && _moduleAddress != address(this),
            "DealManager: Error 100"
        );
        require(
            IModuleBase(_moduleAddress).dealManager() == address(this),
            "DealManager: Error 260"
        );

        isModule[_moduleAddress] = true;
    }

    /**
     * @notice                  Deactivates a Deals module
     * @param _moduleAddress    The address of a Deals module
     */
    function deactivateModule(address _moduleAddress) external onlyOwner {
        require(
            _moduleAddress != address(0) && _moduleAddress != address(this),
            "DealManager: Error 100"
        );

        isModule[_moduleAddress] = false;
    }

    /**
     * @notice              Creates a DaoDepositManager for a DAO
     * @param _dao          Address of the DAO for the DaoDepositContract
     */
    function createDaoDepositManager(address _dao) public {
        require(
            _dao != address(0) && _dao != address(this),
            "DealManager: Error 100"
        );
        require(
            daoDepositManager[_dao] == address(0),
            "DealManager: Error 001"
        );
        require(
            daoDepositManagerImplementation != address(0),
            "DealManager: Error 261"
        );
        address newContract = Clones.clone(daoDepositManagerImplementation);
        IDaoDepositManager(newContract).initialize(_dao);
        require(
            IDaoDepositManager(newContract).dealManager() == address(this),
            "DealManager: Error 260"
        );
        daoDepositManager[_dao] = newContract;
        emit DaoDepositManagerCreated(_dao, newContract);
    }

    /**
     * @notice              Returns whether a DAO already has a DaoDepositManager
     * @param _dao          DAO address for which to check for an existing DaoDepositManger
     * @return bool         A bool flag indicating whether a DaoDepositManager contract exists
     */
    function hasDaoDepositManager(address _dao) external view returns (bool) {
        return getDaoDepositManager(_dao) != address(0) ? true : false;
    }

    /**
     * @notice              Returns the DaoDepositManager of a DAO
     * @param _dao          DAO address for which to return the DaoDepositManger
     * @return address      Address of the DaoDepositManager associated with the _dao
     */
    function getDaoDepositManager(address _dao) public view returns (address) {
        return daoDepositManager[_dao];
    }

    /**
     * @notice              Returns if the address is a Deals module
     * @param _address      Address to check if it is a Deals module
     * @return bool         A bool flag indicating whether the _address is a Deals module
     */
    function addressIsModule(address _address) external view returns (bool) {
        return isModule[_address];
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity ^0.8.9;

interface IDaoDepositManager {
    function dealManager() external returns (address);

    function initialize(address _dao) external;

    function migrateBaseContract(address _newDaoDepositManager) external;

    function deposit(
        address _dealModule,
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external payable;

    function multipleDeposits(
        address _dealModule,
        uint32 _dealId,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external payable;

    function registerDeposit(
        address _dealModule,
        uint32 _dealId,
        address _token
    ) external;

    function registerDeposits(
        address _dealModule,
        uint32 _dealId,
        address[] calldata _tokens
    ) external;

    function withdraw(
        address _dealModule,
        uint32 _dealId,
        uint32 _depositId,
        address _sender
    )
        external
        returns (
            address,
            address,
            uint256
        );

    function sendToModule(
        uint32 _dealId,
        address _token,
        uint256 _amount
    ) external;

    function startVesting(
        uint32 _dealId,
        address _token,
        uint256 _amount,
        uint32 _vestingCliff,
        uint32 _vestingDuration
    ) external payable;

    function claimVestings() external;

    function verifyBalance(address _token) external view;

    function getDeposit(
        address _dealModule,
        uint32 _dealId,
        uint32 _depositId
    )
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function getAvailableDealBalance(
        address _dealModule,
        uint32 _dealId,
        address _token
    ) external view returns (uint256);

    function getTotalDepositCount(address _dealModule, uint32 _dealId)
        external
        view
        returns (uint256);

    function getWithdrawableAmountOfDepositor(
        address _dealModule,
        uint32 _dealId,
        address _user,
        address _token
    ) external view returns (uint256);

    function getBalance(address _token) external view returns (uint256);

    function getVestedBalance(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IModuleBase {
    function moduleIdentifier() external view returns (bytes32);

    function dealManager() external view returns (address);

    function hasDealExpired(uint32 _dealId) external view returns (bool);
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