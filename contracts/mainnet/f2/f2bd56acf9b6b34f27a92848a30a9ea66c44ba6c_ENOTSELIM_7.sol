/**
 *Submitted for verification at Etherscan.io on 2022-09-06
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


contract ENOTSELIM_7 is Ownable {
    mapping(uint8 => bytes32) keccakAnswers;

    mapping(uint8 => bool) public solved;
    mapping(address => bool) public whitelist;
    mapping(uint8 => address) public solvers;
    uint8 public solvedCount;

    event AnswerSolved(address indexed solver, uint8 indexed questionIdx);
    event MilestonePassed();

    constructor() {
        solvedCount = 0;
        keccakAnswers[1] = 0xc162469c13e9be46edb3d505b604b45100194a04c826d2f4a55f3ab391fb8267;
        keccakAnswers[2] = 0x8195895c51eb4219ee3c49e5f211211065674a1207c0d5c7d3e39e3c9a29561e;
        keccakAnswers[3] = 0x66e6418c60f96f70f5343a6bfca32fd0e5ff8bc25e74fc3119285243efff203d;
        keccakAnswers[4] = 0x8386e15bd14e0b5a99cfe0ab387e20559c00f67abc524cd2ecab45e8acc68497;
        keccakAnswers[5] = 0x01a5393d6cd730ba41e0940db2829b1daf9177928b30cb1856e9995425ca1826;
        keccakAnswers[6] = 0x57643a01c09eeb013bfd3f526e89f0c50f3cec1115139f416d3636ad8275a2f0;
        keccakAnswers[7] = 0x46dc43466ab837c182e6aaa37f00efabd197bf27b7c033cf52580c6a9f9bc2af;
        keccakAnswers[8] = 0x6f7de94c82adbcca5349e4659bbab7cbde2741b50417173bbc9b7f37857386cd;
        keccakAnswers[9] = 0x20df53475fd7b7020074adf58069aab4290d483e50796a3eb7a312b08e0a21c0;
        keccakAnswers[10] = 0xd303b493726236eb9d881bd161d3e686df723c71782dc0139ad20f46b90ea416;
        keccakAnswers[11] = 0xb4924f9621c82fa54c5bdd7e3136102ba62b7f0298d1969f885c851282c20ae0;
        keccakAnswers[12] = 0xfa196c9a6160312d9c35170b9dbfd752cfb48aebbb544ac6d764578df1ea0b3b;
        keccakAnswers[13] = 0xc59aa9deb35dab68505df64bd245df16adfb1ef3476cd4944f6801d94e4ccff1;
        keccakAnswers[14] = 0x32b4cf2f50b4bbc186a01277e95f5d17d1bae5dd8684f42080edf9ef3c77e445;
        keccakAnswers[15] = 0x9406392e84f2c6146421317825fd370e79c6cc97b48b392afaa363cb0b0fcb5e;
        keccakAnswers[16] = 0xfb268b741e454f557be912bbcdc13200543ddb31da9c5337fa8a8983671b4307;
        keccakAnswers[17] = 0x51a3690d92b931303ac3dd5a1aba4befaafa8a50d78bc2960d409fcf38c8b8db;
        keccakAnswers[18] = 0x065856b771aebfc7c2a838d22238f5cebb799db915353ffe5bb4f93a8718c85f;
        keccakAnswers[19] = 0x6ff78402d2a907ee727843274b9b3fb7dc6d2d6ed95913ba4bcafcd404763021;
        keccakAnswers[20] = 0x54c80de7e611b57d6d38523e3c0c59a6a3e72cddf62c95cf51a204e52c1a86ad;
        keccakAnswers[21] = 0xe268679650e00ed6f8e7bd31e884de72f1ccaead0a98cae5e5cefc95a1670fee;
        keccakAnswers[22] = 0x605d46f6e82c08372429c8618e603bd469c68c07b0ade7e0b3d0aab40bbd5000;
        keccakAnswers[23] = 0x2b01c9b0c6e3caaa2077e0e3b6ea502914308e7e80752a8147ab58e70db5bda2;
        keccakAnswers[24] = 0xe63cbc382f97013265fa4ca7f5858e09fea018a23e8b49640101143c3f36dc8c;
        keccakAnswers[25] = 0x4d0a6f0508e0c85a8e6338fe89d2eec213617589ffa368cb81e97affe94c968f;
        keccakAnswers[26] = 0xf8234b39bf3758c193e7ce34f813b6312ca47034672d75203fd02a32907c510c;
        keccakAnswers[27] = 0xa740df618a5688e1e8d614d2ffe44f9c767e99ef55144ac42f641648b7778a43;
        keccakAnswers[28] = 0x7cca6151a69f95792dd5949f54419f65a1a6809b2197fe53b36267048ef90ef9;
        keccakAnswers[29] = 0xf43eaee2dd9797b8918e573f8d65f1cdceda07e42fe21425d485497e6cf3b9ed;
        keccakAnswers[30] = 0x9c11d838b1db4eecdbc6d72be9295ad2cd3dbafdc6dec07247a37aa91225bccc;
        keccakAnswers[31] = 0xcfd8fe90b4baf19b917b609021dec174bc6ca59c3443ecaafe4391fccfb23e2a;
        keccakAnswers[32] = 0x9c28c0e7f24473b02f05ded2aef7a9890c81a46c38fb26b940624dbb4dd591dd;
        keccakAnswers[33] = 0xd35cfabcb71555e1417ec8f9be9fc5baa71913ecc8589a54f85ffd8440b67ad3;
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
        if(solvedCount == 33) {
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