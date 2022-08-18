/**
 *Submitted for verification at Etherscan.io on 2022-08-18
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


contract ENOTSELIM_4 is Ownable {
    mapping(uint8 => bytes32) keccakAnswers;

    mapping(uint8 => bool) public solved;
    mapping(address => bool) public whitelist;
    mapping(uint8 => address) public solvers;
    uint8 public solvedCount;

    event AnswerSolved(address indexed solver, uint8 indexed questionIdx);
    event MilestonePassed();

    constructor() {
        solvedCount = 0;

        keccakAnswers[1] = 0x2c83f0e0903e5f6884aec36f31586824f6650d1c6d1cdcc8cc00b876e877fcd1;
        keccakAnswers[2] = 0xc83aaeece4682cb3458dea3f6ffadded90648ca2ad36465b02c2722e720d9b87;
        keccakAnswers[3] = 0x6f5a8914fd76c466f1d7710bd4b2e801d01bd7a123263a2974e9ea7e97f2ee57;
        keccakAnswers[4] = 0x0fd7e2a7edc02192ca6cd428cd06e1150a1f2f45801ea4bb9cd9276dfc43a8f4;
        keccakAnswers[5] = 0x27536be0ba1cee82a924a1fd47bccd1dd265c783ad6f060d17fc87df52320532;
        keccakAnswers[6] = 0xa4bd90cf66356e062897cfd99660b8fafd89b1fcc76374479c74bea1ee420960;
        keccakAnswers[7] = 0x43e9aee86b980e8ac03b68eb63a949ed358cea0fc06e4026d838cfaeda73f191;
        keccakAnswers[8] = 0xcc4cafde437e0388c3343c30824b5d3a34e378c33f04ce5f1c5646a3c5606f15;
        keccakAnswers[9] = 0x9bd12e5f92e104b478fd6110b1f4cf4ed16a1e8f2f706b83931db8766bf2d149;
        keccakAnswers[10] = 0x522c0d3e724ac25c1d63569b6593dcab675197779876fd402f3f02faac41beae;
        keccakAnswers[11] = 0xa75ea3377c31d506a3a912873f1cfa042430d92ed7944fd68cd9ed5aebe54c4c;
        keccakAnswers[12] = 0x31666b75bbed6d08aa258c14aa7983841c3d39b134914aff8e65f0f76dc8dbae;
        keccakAnswers[13] = 0x346d8091515a01e9e1bcb28268befac08c03cd7c71d5146fb7176bf09f3e9c11;
        keccakAnswers[14] = 0x9e1ac5154e316d8c02044cc13565c57bdf1479e6192d501ed1aad6f1483a32f1;
        keccakAnswers[15] = 0x42c100b2326b80acba5bf5a6823f8a7239e6edc96a4343ffaee426a0d1b4a785;
        keccakAnswers[16] = 0x88508108044483908bb0222f2600cd9f4e21156fe1ecb8b93e71b90ac08b1ffb;
        keccakAnswers[17] = 0x7a66b2f34d68864a9cfe529b930b7f4d7acc09c5b8b9f61f3c95e5d6fb9823bf;
        keccakAnswers[18] = 0x20d91956bdc2681957e73940c4a11e475669410f2827196289cc12899dbdc023;
        keccakAnswers[19] = 0x6dd901120fc4186518c09d3138c24bcbe8dea4c75843b72dd7fdda4da81e72cb;
        keccakAnswers[20] = 0x26d66b75ae581bb8b3da5d56be37b0d0b4caed2d6907b9129953f5d85e656da8;
        keccakAnswers[21] = 0x9b22f3ad63e08c58fbae17a355b3a44a802f6486be5e5f420fdc544b68c28833;
        keccakAnswers[22] = 0xbbb74c1591a33ea43e3a16464a60d9617484abb2543de42f6cb6751eb7750156;
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
        if(solvedCount == 22) {
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