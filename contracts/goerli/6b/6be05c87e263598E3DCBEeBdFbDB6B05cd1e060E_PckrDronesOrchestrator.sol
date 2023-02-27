// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PckrDronesInterface.sol";
import "./HpprsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PckrDronesOrchestrator is Ownable {
    uint256 public dronesMintPrice = 0.05 ether;
    uint256 public dronesPreMintPrice = 0.04 ether;
    uint256 public tradeStart = 1677596400;
    uint256 public premintStart = 1677682800;
    uint256 public premintEnd = 1677682740;
    uint256 public mintStart = 1677769200;

    uint256 public maxPreMintsPerWallet = 2;
    uint256 public maxMintsPerTransaction = 10;

    address public secret = 0x9c01B4EE5f92f9E3839cf017650921C0B9Cb0DBf;

    PckrDronesInterface public drones = PckrDronesInterface(0x372f10f66915ADA9E838755a5130b049aB96A3F3);
    HpprsInterface public hpprs = HpprsInterface(0x1DEdd6Ae35F030387a4DE0719E56eCBDeBEbEe0C);

    mapping(address => uint) public walletsPreMints;

    event Mint(address owner, uint256 tokenAmount);
    event Trade(address owner, uint256 tokenAmount);

    function setSettings(
        address _drones,
        address _hpprs,
        address _secret,
        uint256 _dronesPreMintPrice,
        uint256 _dronesMintPrice,
        uint256 _maxPreMintsPerWallet,
        uint256 _maxMintsPerTransaction,
        uint256 _tradeStart,
        uint256 _premintStart,
        uint256 _premintEnd,
        uint256 _mintStart
    ) external onlyOwner {
        hpprs = HpprsInterface(_hpprs);
        drones = PckrDronesInterface(_drones);
        secret = _secret;
        dronesMintPrice = _dronesMintPrice;
        dronesPreMintPrice = _dronesPreMintPrice;
        maxPreMintsPerWallet = _maxPreMintsPerWallet;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        tradeStart = _tradeStart;
        premintStart = _premintStart;
        premintEnd = _premintEnd;
        mintStart = _mintStart;
    }

    function setTimers(
        uint256 _tradeStart,
        uint256 _premintStart,
        uint256 _premintEnd,
        uint256 _mintStart) external onlyOwner {
        tradeStart = _tradeStart;
        premintStart = _premintStart;
        premintEnd = _premintEnd;
        mintStart = _mintStart;
    }

    function setSalePrices(uint256 _dronesPreMintPrice, uint256 _dronesMintPrice) external onlyOwner {
        dronesPreMintPrice = _dronesPreMintPrice;
        dronesMintPrice = _dronesMintPrice;
    }

    function preMintDrone(uint256 tokenAmount, bytes calldata signature) external payable {
        require(block.timestamp >= premintStart && block.timestamp <= premintEnd, "Presale is closed");
        require(tokenAmount + walletsPreMints[msg.sender] <= maxPreMintsPerWallet, "Cannot exceed max premint");
        require(msg.value == tokenAmount * dronesPreMintPrice, "Wrong ETH amount");
        require(
            _verifyHashSignature(keccak256(abi.encode(msg.sender)), signature),
            "Signature is invalid"
        );

        walletsPreMints[msg.sender] += tokenAmount;
        emit Mint(msg.sender, tokenAmount);
        drones.airdrop(msg.sender, tokenAmount);
    }

    function mintDrone(uint256 tokenAmount) external payable {
        require(block.timestamp >= mintStart, "Mint is closed");
        require(msg.value == tokenAmount * dronesMintPrice, "Wrong ETH amount");
        require(tokenAmount <= maxMintsPerTransaction, "Limit per transaction");

        emit Mint(msg.sender, tokenAmount);
        drones.airdrop(msg.sender, tokenAmount);
    }

    function tradeDrone(uint256[] calldata hpprsIds) external {
        require(block.timestamp >= tradeStart, "Trade is closed");

        for (uint256 i = 0; i < hpprsIds.length; i++) {
            require(hpprs.ownerOf(hpprsIds[i]) == msg.sender, "Not HPPR owner");
            hpprs.burn(hpprsIds[i]);
        }

        emit Trade(msg.sender, hpprsIds.length * 2);
        drones.airdrop(msg.sender, hpprsIds.length * 2);
    }

    function withdraw() external onlyOwner {
        payable(0x0dC32097292F37962A653B2AEd4e92BA370Ce7c6).transfer(address(this).balance);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature) internal view returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}

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

pragma solidity ^0.8.0;

interface HpprsInterface {
    function burn(uint256) external;
    function ownerOf(uint256) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PckrDronesInterface {
    function airdrop(address receiver, uint256 amount) external;
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