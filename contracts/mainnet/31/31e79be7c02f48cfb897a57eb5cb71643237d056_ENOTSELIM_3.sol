/**
 *Submitted for verification at Etherscan.io on 2022-08-12
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


contract ENOTSELIM_3 is Ownable {
    mapping(uint8 => bytes32) keccakAnswers;

    mapping(uint8 => bool) public solved;
    mapping(address => bool) public whitelist;
    mapping(uint8 => address) public solvers;
    uint8 public solvedCount;

    event AnswerSolved(address indexed solver, uint8 indexed questionIdx);
    event MilestonePassed();

    constructor() {
        solvedCount = 0;
        keccakAnswers[1] = 0x2f663dc6f3d2fe8652a67396ef5b8c9d5bdc1d035849aee484f0a331ee0bfd93;
        keccakAnswers[2] = 0xe20d8a8e23de7e4a78cc7cf658a2a70d9040aadaa3d4a8fcff33832d09a1f343;
        keccakAnswers[3] = 0x66b44b8ad477dbecade0b6e1151d234ed97cb4877bd4331915a6a5203f9177c1;
        keccakAnswers[4] = 0x0cb3c0c7080fdb4fbb2088dca3794442e08bcc695044c8867dad68c61f2a84d8;
        keccakAnswers[5] = 0x55e8e101943468ff18759e8434ed9813ab0e15400acdc7e793315ade8c58c223;
        keccakAnswers[6] = 0xe715732f1ef8fa251bf852ba25b19a358c6d9928a70b6cee5140e191f6ddafbb;
        keccakAnswers[7] = 0xc89338d15c69ac1d20d96c8aed2235924d63c99d41d4c0dc8d1e3d370a6a3904;
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