// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyContracts.sol";

contract Proxy is Ownable, ProxyContracts {

    string constant BASE_CURRENCY_SYMBOL = "ETH";
    uint constant BASE_CURRENCY_DECIMALS = 18;

    uint constant FEE = 1000; // 0.1%
    uint constant FEE_MUL = 1;
    uint constant MIN_FEE = 1;

    struct Deposit {
        string hash;
        address from;
        string symbol;
        uint amount;
        bytes data;
    }

    Deposit[] public deposits;

    event DepositAddedEvent(string hash, address from, string symbol, uint amount, bytes data);
    event DepositExecEvent(string hash, address from, address to, string symbol, uint amount, bytes data);

    /**
     * Add coins
     */
    function addCoins() public payable {
        
    }

    /**
     * Add deposit
     */
    function addDeposit(string memory hash, address sender, uint amount, bytes calldata data) public onlyOwner {
        addDepositData(hash, sender, BASE_CURRENCY_SYMBOL, amount, data);
    }

    /**
     * Add token deposit
     */
    function addTokenDeposit(string memory hash, address sender, string memory symbol, uint amount, bytes calldata data) public onlyOwner {
        addDepositData(hash, sender, symbol, amount, data);
    }

    /**
     * Add deposit data record
     */
    function addDepositData(string memory hash, address from, string memory symbol, uint amount, bytes calldata data) internal {
        bool _elementExists = false;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) == keccak256(bytes(hash))) {
                _elementExists = true;
                break;
            }
        }

        require(!_elementExists, "Deposit already exists");

        deposits.push(Deposit({
            hash: hash,
            from: from,
            symbol: symbol,
            amount: amount,
            data: data
        }));
        emit DepositAddedEvent(hash, from, symbol, amount, data);
    }

    /**
     * Exec deposits
     */
    function execDeposit(string memory hash, address to) public onlyOwner {
        int index = -1;
        bool isSended = false;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) != keccak256(bytes(hash))) {
                continue;
            }

            index = int(i);

            delete deposits[i];

            uint fee = element.amount / FEE * FEE_MUL;
            fee = fee < MIN_FEE ? MIN_FEE : fee;
            uint resultAmount = element.amount - fee;

            if (keccak256(bytes(element.symbol)) == keccak256(bytes(BASE_CURRENCY_SYMBOL))) {
                sendCoins(to, resultAmount, element.data);
            } else {
                sendTokens(getContractAddress(element.symbol), to, resultAmount, element.data);
            }

            emit DepositExecEvent(hash, element.from, to, element.symbol, element.amount, element.data);

            isSended = true;

            break;
        }

        require(isSended, "Deposit not sended");

        if (index >= 0) {
            for (uint i = uint(index); i < deposits.length - 1; i++) {
                deposits[i] = deposits[i + 1];
            }

            deposits.pop();
        }
    }

    /**
     * Delete deposit by hash
     */
    function delDepositByHash(string memory hash) public onlyOwner {
        int index = -1;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.hash)) == keccak256(bytes(hash))) {
                index = int(i);
                break;
            }

        }

        require(index >= 0, "Deposit by hash not found");

        delete deposits[uint(index)];
        for (uint i = uint(index); i < deposits.length - 1; i++) {
            deposits[i] = deposits[i + 1];
        }

        deposits.pop();
    }

    /**
     * Send coins
     */
    function sendCoins(address to, uint amount, bytes memory data) internal onlyOwner {
        require(address(this).balance >= amount, "Balance not enough");
        (bool success, ) = to.call{value: amount}(data);
        require(success, "Transfer not sended");
    }

    /**
     * Send tokens
     */
    function sendTokens(address contractAddress, address to, uint amount, bytes memory data) internal onlyOwner {
        (bool success, bytes memory result) = contractAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");
        require(abi.decode(result, (uint256)) >= amount, "Not enough tokens");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        (success, ) = to.call(data);
        require(success, "transfer data request failed");
    }


    /**
     * =================
     * Withdrawal logic
     * =================
     */

    address constant DEFAULT_ADDRESS = 0x0000000000000000000000000000000000000000;

    event TokenBalanceEvent(uint amount, string symbol);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(string memory symbol) public returns(uint) {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        (bool success, bytes memory result) = contractAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");

        uint256 amount = abi.decode(result, (uint256));

        emit TokenBalanceEvent(amount, symbol);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) public onlyOwner {
        uint _balance = address(this).balance;
        require(_balance >= amount, "Balance not enough");
        to.transfer(amount);
    }

    /**
     * Transfer tokens
     */
    function transferToken(string memory symbol, address to, uint amount) public onlyOwner {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        uint _balance = getTokenBalance(symbol);
        require(_balance >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");
    }

    /**
     * Withdrawal comission coins (excluding deposites)
     */
    function withdrawal(address payable to, uint amount) public onlyOwner {
        uint depositesSum = 0;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.symbol)) == keccak256(bytes(BASE_CURRENCY_SYMBOL))) {
                depositesSum += element.amount;
            }
        }

        uint _balance = address(this).balance;
        uint _resultBalance = _balance - depositesSum;
        require(_resultBalance >= amount, "Balance not enough");
        to.transfer(amount);
    }

    /**
     * Withdrawal comission tokens (excluding deposites)
     */
    function withdrawalToken(string memory symbol, address to, uint amount) public onlyOwner {
        address contractAddress = getContractAddress(symbol);
        require(contractAddress != DEFAULT_ADDRESS, "Contract address not found");

        uint depositesSum = 0;
        for (uint i = 0; i < deposits.length; i++) {
            Deposit memory element = deposits[i];
            if (keccak256(bytes(element.symbol)) == keccak256(bytes(symbol))) {
                depositesSum += element.amount;
            }
        }

        uint _balance = getTokenBalance(symbol);
        uint _resultBalance = _balance - depositesSum;
        require(_resultBalance >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProxyContracts is Ownable {

    mapping (string => address) internal contracts;

    function addContract(string memory symbol, address contractAddress) public onlyOwner {
        require(contracts[symbol] == 0x0000000000000000000000000000000000000000, "Token contract alredy exists");
        contracts[symbol] = contractAddress;
    }

    function delContract(string memory symbol) public onlyOwner {
        delete contracts[symbol];
    }

    function getContractAddress(string memory symbol) public view returns(address) {
        return contracts[symbol];
    }
}