/**
 *Submitted for verification at Etherscan.io on 2022-08-08
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


contract ENOTSELIM_2 is Ownable {
    mapping(uint8 => bytes32) keccakAnswers;

    mapping(uint8 => bool) public solved;
    mapping(address => bool) public whitelist;
    mapping(uint8 => address) public solvers;
    uint8 public solvedCount;

    event AnswerSolved(address indexed solver, uint8 indexed questionIdx);
    event MilestonePassed();

    constructor() {
        solvedCount = 0;
        keccakAnswers[1] = 0xa1c879b0284e72931b8cd098e080355084a332f82e911af96b3055fa2035b7e8;
        keccakAnswers[2] = 0xa8aebbef8199fc8003b38d578e0eb4a43809f2a0f5f398cb104f5f15e5c3abd6;
        keccakAnswers[3] = 0xb7ff452c0f83cc6b587392314a72d0c6fa7277bbf6f0a587e06a357012d13eca;
        keccakAnswers[4] = 0x4ca61667a6086c915d0bf1b542abd171bdf676d52eed640e514e984beed3fefe;
        keccakAnswers[5] = 0xd68236c310abddc76b6b8d631b26b2ad43c7d96b8950adf01e22de94596df95b;
        keccakAnswers[6] = 0x0915491d1295d78435fd4729d2b33c9ee705452346c48e80b3e5ed3ceaaf362e;
        keccakAnswers[7] = 0x4e701ff48cddd8d9ae76d4abc76fdf8142996b98a55d862e7a02c126a31586e6;
        keccakAnswers[8] = 0x481c88b3ddb5e29ec0c05600ad5b80a693bfd3e8da005e1a13ad86b0c6ebe171;
        keccakAnswers[9] = 0xa489ebf01d7882192d59b67968bdd78dfbb123b97c81f225ce693a47bdcb6a3d;
        keccakAnswers[10] = 0xe4b8199c7c2dccd9de547cd6b40bf57f4472f33d1861c86508b923454fbf3e21;
        keccakAnswers[11] = 0xae72c67fd774104ffa81c8e3565edfcb9f7a8e69ce63d1c86ba572d7802d8b70;
        keccakAnswers[12] = 0xd94a9a1fc130a6c35b57e7792c2f65fbd49298f1a6d8885283969840ac7023b7;
        keccakAnswers[13] = 0x9ee54a5a9c33b0d12ad1844ccea6d28bfa9ef5d462e612ff7453751356be80db;
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