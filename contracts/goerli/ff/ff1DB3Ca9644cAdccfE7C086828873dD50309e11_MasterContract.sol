// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./reduced_interfaces/BAPGenesisInterface.sol";
import "./reduced_interfaces/BAPMethaneInterface.sol";
import "./reduced_interfaces/BAPUtilitiesInterface.sol";
import "./reduced_interfaces/BAPTeenBullsInterface.sol";
import "./reduced_interfaces/BAPOrchestratorInterfaceV2.sol";

contract MasterContract is Ownable {
    BAPMethaneInterface public bapMeth;
    BAPUtilitiesInterface public bapUtilities;
    BAPTeenBullsInterface public bapTeenBulls;

    mapping(address => bool) public isAuthorized;

    constructor(
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls
    ) {
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    // METH functions

    function claim(address to, uint256 amount) external onlyAuthorized {
        bapMeth.claim(to, amount);
    }

    function pay(uint256 payment, uint256 fee) external onlyAuthorized {
        bapMeth.pay(payment, fee);
    }

    // Teens functions

    function airdrop(address to, uint256 amount) external onlyAuthorized {
        bapTeenBulls.airdrop(to, amount);
    }

    function burnTeenBull(uint256 tokenId) external onlyAuthorized {
        bapTeenBulls.burnTeenBull(tokenId);
    }

    // Utilities functions

    function burn(uint256 id, uint256 amount) external onlyAuthorized {
        bapUtilities.burn(id, amount);
    }

    function airdrop(
        address to,
        uint256 amount,
        uint256 id
    ) external onlyAuthorized {
        bapUtilities.airdrop(to, amount, id);
    }

    // Ownable

    function setAuthorized(address operator, bool status) external onlyOwner {
        isAuthorized[operator] = status;
    }

    function transferOwnershipExternalContract(
        address _contract,
        address _newOwner
    ) external onlyOwner {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    function setMethaneContract(address _newAddress) external onlyOwner {
        bapMeth = BAPMethaneInterface(_newAddress);
    }

    function setUtilitiesContract(address _newAddress) external onlyOwner {
        bapUtilities = BAPUtilitiesInterface(_newAddress);
    }

    function setTeenBullsContract(address _newAddress) external onlyOwner {
        bapTeenBulls = BAPTeenBullsInterface(_newAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function burn(uint256, uint256) external;

    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function transferOwnership(address) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
    function generateTeenBull() external;

    function generateMergerOrb() external;

    function ownerOf(uint256) external view returns (address);

    function burnTeenBull(uint256) external;

    function airdrop(address, uint256) external;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterfaceV2 {
    function prevClaimed(uint256) external returns (bool);

    function totalClaimed(uint256) external view returns (uint256);

    function bullLastClaim(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPMethaneInterface {
    function claim(address, uint256) external;

    function pay(uint256, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPGenesisInterface {
    function minted() external view returns (uint256);

    function mintingDatetime(uint256) external view returns (uint256);

    function updateBullBreedings(uint256) external;

    function ownerOf(uint256) external view returns (address);

    function breedings(uint256) external view returns (uint256);

    function maxBreedings() external view returns (uint256);

    function generateGodBull() external;

    function refund(address, uint256) external payable;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function genesisTimestamp() external view returns (uint256);
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