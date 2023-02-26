pragma solidity 0.6.4;

import "WagerIt.sol";

contract WagerItFactory {
    event WagerCreated(address newContract);

    address factoryOwner;

    constructor() public {
        factoryOwner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return factoryOwner;
    }

    function createMyWager(
        string memory _resultOption1,
        string memory _resultOption2
    ) public returns (WagerIt) {
        WagerIt wagerIt = new WagerIt(
            _resultOption1,
            _resultOption2,
            msg.sender
        );
        emit WagerCreated(address(wagerIt));

        return wagerIt;
    }
}

pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "atm.sol";

contract WagerIt is ATM, Ownable {
    struct Wager {
        string name;
        address add;
        uint256 amount;
        Result resultWager;
    }

    struct Result {
        string name;
        uint256 totalWageredAmount;
    }

    event NewWager(address add, uint256 amount, Result resultBet);

    Wager[] wagers;
    Result[] results;

    address wagerOwner;
    uint256 public totalWageredMoney = 0;

    mapping(address => uint256) public wagersPerAddress;

    constructor(
        string memory _result1,
        string memory _result2,
        address _owner
    ) public payable {
        wagerOwner = _owner;

        results.push(Result(_result1, 0));
        results.push(Result(_result2, 0));
    }

    function getOwner() public view returns (address) {
        return wagerOwner;
    }

    function createResult(string memory _name) public {
        results.push(Result(_name, 0));
    }

    function getTotalWageredAmount(uint256 _resultId)
        public
        view
        returns (uint256)
    {
        return results[_resultId].totalWageredAmount;
    }

    function createWager(string memory _name, uint256 _resultId)
        public
        payable
    {
        require(msg.sender != wagerOwner, "owner can't make a wager");
        require(
            wagersPerAddress[msg.sender] == 0,
            "you have already placed a wager"
        );
        /*
        require(msg.value > 0.01 ether, "Wager More");
        */
        deposit();

        wagers.push(Wager(_name, msg.sender, msg.value, results[_resultId]));

        if (_resultId == 0) {
            results[0].totalWageredAmount += msg.value;
        }
        if (_resultId == 1) {
            results[1].totalWageredAmount += msg.value;
        }

        wagersPerAddress[msg.sender]++;

        totalWageredMoney += msg.value;

        emit NewWager(msg.sender, msg.value, results[_resultId]);
    }

    function resultWinDistribution(uint256 _resultId) public payable onlyOwner {
        uint256 div;

        if (_resultId == 0) {
            for (uint256 i = 0; i < wagers.length; i++) {
                if (
                    keccak256(abi.encodePacked((wagers[i].resultWager.name))) ==
                    keccak256(abi.encodePacked("result1"))
                ) {
                    address payable receiver = payable(wagers[i].add);

                    div =
                        (wagers[i].amount *
                            (10000 +
                                ((getTotalWageredAmount(1) * 10000) /
                                    getTotalWageredAmount(0)))) /
                        10000;

                    (bool sent, bytes memory data) = receiver.call{value: div}(
                        ""
                    );
                    require(sent, "Failed to send Ether");
                }
            }
        } else {
            for (uint256 i = 0; i < wagers.length; i++) {
                if (
                    keccak256(abi.encodePacked((wagers[i].resultWager.name))) ==
                    keccak256(abi.encodePacked("result2"))
                ) {
                    address payable receiver = payable(wagers[i].add);
                    div =
                        (wagers[i].amount *
                            (10000 +
                                ((getTotalWageredAmount(0) * 10000) /
                                    getTotalWageredAmount(1)))) /
                        10000;

                    (bool sent, bytes memory data) = receiver.call{value: div}(
                        ""
                    );
                    require(sent, "Failed to send Ether");
                }
            }
        }

        totalWageredMoney = 0;
        results[0].totalWageredAmount = 0;
        results[1].totalWageredAmount = 0;

        for (uint256 i = 0; i < wagers.length; i++) {
            wagersPerAddress[wagers[i].add] = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.4;

contract ATM {
    mapping(address => uint256) public balances;

    event Deposit(address sender, uint256 amount);
    event Withdrawal(address receiver, uint256 amount);

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
    }

    function depositInEth(uint256 amount) public payable {
        emit Deposit(msg.sender, amount * 1000000000000000000);
        balances[msg.sender] += amount * 1000000000000000000;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient funds");
        emit Withdrawal(msg.sender, amount);
        balances[msg.sender] -= amount;
    }
}