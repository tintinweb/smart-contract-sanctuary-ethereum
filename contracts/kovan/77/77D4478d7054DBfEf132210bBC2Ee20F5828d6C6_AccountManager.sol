// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./dependencies/openzeppelin/Ownable.sol";
import "./interface/IAuthCenter.sol";
import "./interface/IAccount.sol";
// import "hardhat/console.sol";

contract AccountManager is Ownable {
    // totally account count
    uint256 accountCount;

    // id -> Account
    mapping(string => address) accountBook;

    // Account -> id
    mapping(address => string) idBook;

    // account template
    address public accountTemplate;

    address public authCenter;

    bool flag;

    event CreateAccount(string id, address account);
    event UpdateAccountTemplate(address preTemp, address accountTemplate);
    event SetAuthCenter(address preAuthCenter, address authCenter);

    modifier onlyAccess() {
        IAuthCenter(authCenter).ensureAccountManagerAccess(_msgSender());
        _;
    }

    function init(address _template, address _authCenter) external {
        require(!flag, "BYDEFI: already initialized!");
        super.initialize();
        accountTemplate = _template;
        authCenter = _authCenter;
        flag = true;
    }

    function updateAccountTemplate(address _newTemplate) external onlyOwner {
        require(_newTemplate != address(0), "BYDEFI: _newTemplate should not be 0");
        address preTemp = accountTemplate;
        accountTemplate = _newTemplate;

        emit UpdateAccountTemplate(preTemp, accountTemplate);
    }

    function setAuthCenter(address _authCenter) external onlyOwner {
        address pre = authCenter;
        authCenter = _authCenter;
        emit SetAuthCenter(pre, _authCenter);
    }

    function createAccount(string memory id) external onlyAccess returns (address _account) {
        require(bytes(id).length != 0, "BYDEFI: Invalid id!");
        require(accountBook[id] == address(0), "BYDEFI: account exist");

        _account = cloneAccountProxy(accountTemplate);
        require(_account != address(0), "BYDEFI: cloneAccountProxy failed!");
        IAccount(_account).init(authCenter);

        accountBook[id] = _account;
        unchecked {
            accountCount++;
        }
        idBook[_account] = id;

        emit CreateAccount(id, _account);
    }

    function getAccount(string memory id) external view returns (address _account) {
        _account = accountBook[id];
    }

    function isAccount(address _address) external view returns (bool res, string memory id) {
        id = idBook[_address];
        if (bytes(id).length != 0) {
            res = true;
        }
    }

    function getAccountCount() external view returns (uint256) {
        return accountCount;
    }

    function cloneAccountProxy(address _template) internal returns (address accountAddress) {
        bytes20 targetBytes = bytes20(_template);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            accountAddress := create(0, clone, 0x37)
        }
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";
// import "hardhat/console.sol";

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
    function initialize() internal virtual {
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
        // console.log("owner():", owner());
        // console.log("msgSender:", _msgSender());
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

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
pragma solidity ^0.8.0;

interface IAuthCenter {
    function ensureAccountAccess(address _caller) external view;
    function ensureFundsProviderPullAccess(address _caller) external view;
    function ensureFundsProviderRebalanceAccess(address _caller) external view;
    function ensureOperatorAccess(address _caller) external view;
    function ensureAccountManagerAccess(address _caller) external view;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccount {
    function init(address _authCenter) external;
    
    function getBalance(address[] memory _tokens) external view returns (uint256, uint256[] memory);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external returns (uint256 _amt);

    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);
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