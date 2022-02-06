/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/ContractB.sol

contract ContractB is Ownable {
        address public contractA;

        // token => user => amount
        mapping(address => mapping(address => uint256)) public tokenToUserDeposit;

        event ContractASet(address newContractA);
        event DepositRecorded(address token, address user, uint256 amount);

        function setContractA(address _contractA) 
        external
        onlyOwner
    {
        require(
            _contractA != address(0),
            "ContractA::setContractA: _contractA cannot be zero"
        );

        contractA = _contractA;
        emit ContractASet(_contractA);
    }

        function recordDeposit(
                address _user,
                address _token,
                uint256 _amount
        )
                external
                onlyOwnerOrContractA
        {
                require(
                        _user != address(0)
                        && _token != address(0),
                        "ContractB::recordDeposit: invalid function parameters."

                );

                tokenToUserDeposit[_token][_user] += _amount;

                emit DepositRecorded(_token, _user, _amount);
        }

        function _onlyOwnerOrContractA() private view {
                require(
                        msg.sender == owner()
                        || msg.sender == contractA,
                        "ContractB::onlyOwnerOrContractA: invalid caller."
                );
        }

        modifier onlyOwnerOrContractA {
                _onlyOwnerOrContractA();
                _;
        }
}