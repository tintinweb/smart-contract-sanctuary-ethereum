/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


contract ENOTSELIM_1 is Ownable {
    mapping(uint8 => bytes32) keccakAnswers;

    mapping(uint8 => bool) public solved;
    mapping(address => bool) public whitelist;
    mapping(uint8 => address) public solvers;
    uint8 public solvedCount;

    event AnswerSolved(address indexed solver, uint8 indexed questionIdx);
    event MilestonePassed();

    constructor() {
        solvedCount = 0;
        keccakAnswers[1] = 0xb1924011660117aaa57b08b4533f4ac7eb64fb5aefede6e4594f25fe2e8af87f;
        keccakAnswers[2] = 0xe8f2cef572bae876dd80b8896da385c88fd34feddf999904642b461fd24cc037;
        keccakAnswers[3] = 0x25bf0f1a8a24226507603fa5654c3fee89a4d355ee699ccf2479f1a57324aabe;
        keccakAnswers[4] = 0x415cc70f4c6f73d2575fc52a3ee4f3468e1363dc72ec1ddab7b6cd99a4307ef8;
        keccakAnswers[5] = 0x2ff3ba4b0181a7f718b45d7eba988939219049c1c58b8d00db2da70a12064206;
        keccakAnswers[6] = 0x970e1c3b2e7ddbe48ba9497005b5ba57d20b5a42bc6033311a06e048930d37ee;
        keccakAnswers[7] = 0xa332f9baed8d9345aca639213a66b3c813dd5d8145ac7c95b5090324ab7139e6;
        keccakAnswers[8] = 0x639aad46fb15b5b7636d70022600312ac5dbb0dbb8b0d25dc364ae330473a3a7;
        keccakAnswers[9] = 0x0c1740d62ef01849610274332a463b833d4bb8c1cab110cccfc0001a9a0eef37;
        keccakAnswers[10] = 0xea47cbb1228b54ca1d86e3319af5a926a3bc13765dc573515bd551e10c5d78c9;
    }

    function hashKeccak(string memory _text) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text));
    }

    function sendToCheck(uint8 _questionIdx, string memory _ans) public {
        require(whitelist[msg.sender] != true, "Wallet already whitelisted");
        require(solved[_questionIdx] == false, "Enigma already solved");
        require(hashKeccak(_ans) == keccakAnswers[_questionIdx], "Wrong answer");
        whitelist[msg.sender] = true;
        solved[_questionIdx] = true;
        solvedCount = solvedCount + 1;
        solvers[_questionIdx] = msg.sender;

        emit AnswerSolved(msg.sender, _questionIdx);
        if(solvedCount == 10) {
            emit MilestonePassed();
        }
    }

    function check(uint8 _questionIdx, string memory _ans) public view returns (bool) {
        require(whitelist[msg.sender] != true, "Wallet already whitelisted");
        require(solved[_questionIdx] == false, "Enigma already solved");

        return hashKeccak(_ans) == keccakAnswers[_questionIdx];
    }

    function setAnswer(uint8 _questionIdx, bytes32 _keccakAnswer) external onlyOwner {
        keccakAnswers[_questionIdx] = _keccakAnswer;
    }

    function setSolved(uint8 _questionIdx, bool _solved) external onlyOwner {
        solved[_questionIdx] = _solved;
    }

    function isSolved(uint8 _questionIdx) public view returns (bool) {
        return solved[_questionIdx];
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return whitelist[_addr];
    }

    function getSolver(uint8 _questionIdx) public view returns (address) {
        return solvers[_questionIdx];
    }
}