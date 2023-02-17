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

pragma solidity ^0.8.13;

interface IRobotTxt {
    error NotOwner();
    error ZeroValue();
    error ZeroAddress();
    error LicenseNotRegistered();
    error AlreadyWhitelisted();
    error NotWhitelisted();

    event LicenseSet(address indexed _by, address indexed _for, string _licenseUri, string _info);
    event LicenseRemoved(address indexed _by, address indexed _for);
    event ContractWhitelisted(address indexed owner, address indexed contractAddress);
    event ContractDelisted(address indexed owner, address indexed contractAddress);

    struct LicenseData {
        string uri;
        string info;
    }

    function setDefaultLicense(address _for, string memory _licenseUri, string memory _info) external;
    function getOwnerLicenseCount(address owner) external view returns (uint256);
    function whitelistOwnerContract(address owner, address contractAddress) external;
    function delistOwnerContract(address owner, address contractAddress) external;
}

// SPDX-License-Identifier: MIT
/**
 *  ██████╗  ██████╗ ██████╗  ██████╗ ████████╗███████╗           ████████╗██╗  ██╗████████╗
 *  ██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝           ╚══██╔══╝╚██╗██╔╝╚══██╔══╝
 *  ██████╔╝██║   ██║██████╔╝██║   ██║   ██║   ███████╗              ██║    ╚███╔╝    ██║
 *  ██╔══██╗██║   ██║██╔══██╗██║   ██║   ██║   ╚════██║              ██║    ██╔██╗    ██║
 *  ██║  ██║╚██████╔╝██████╔╝╚██████╔╝   ██║   ███████║    ██╗       ██║   ██╔╝ ██╗   ██║
 *  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝    ╚═╝       ╚═╝   ╚═╝  ╚═╝   ╚═╝
 *
 * A robots.txt file tells search engine crawlers which URLs the crawler can access on your site.
 * In web3, we can use this robots-txt registry contract to let aggregators anyone else that scape the the blockchain and IPFs
 * know what default rights we are giving them regarding our content.
 *
 * How this works:
 * -------------------
 * You can set a default license uri and info  for any address
 * of a contract that has an "owner()" function that returns your address.
 * When yo udo this, you get a special ROBOT token that you can use to remove the license later (and then it gets burned)
 *
 * call setDefaultLicense(address _for, string _licenseUri, string info) to set a license _for your address or a contract you own.
 * call licenseOf(address _address) to get the license and info for an address. if none is set, it will return an empty string.
 *
 * by Roy Osherove, Niv Mimran
 */
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts//access/Ownable.sol";
import "./token/IRobot.sol";
import "./IRobotTxt.sol";
// import "forge-std/console.sol";
//forge console

contract RobotTxt is IRobotTxt, Ownable {
    IRobot public robot;
    mapping(address => LicenseData) public licenseOf;
    mapping(address => address[]) public ownerLicenses;
    mapping(address => address) public contractAddressToOwnerAllowList;
    uint256 public totalLicenseCount;

    modifier senderMustBeOwnerOf(address _owned) {
        if (_owned == address(0)) revert ZeroAddress();
        bool isAllowListed = contractAddressToOwnerAllowList[_owned] == msg.sender;
        bool isOwnableOwner; // false by default

        try Ownable(_owned).owner() returns (address contractOwner) {
            if (msg.sender == contractOwner) {
                isOwnableOwner = true;
            }
        } catch { // no error handling in `catch`?
        }
        require(isOwnableOwner || isAllowListed, "Sender must be owner of the address");
        _;
    }

    /// @param robotAddress address of the legato robot token contract
    constructor(address robotAddress) {
        if (robotAddress == address(0)) revert ZeroAddress();
        robot = IRobot(robotAddress);
    }

    /// @notice registers a new license URI _for a license owned by the license owner
    /// @param _for the address of the license to register
    /// @param _licenseUri the URI of the licens10
    /// @param _info the URI of the license info
    function setDefaultLicense(address _for, string memory _licenseUri, string memory _info)
        public
        senderMustBeOwnerOf(_for)
    {
        if (bytes(_licenseUri).length == 0) revert ZeroValue();
        LicenseData memory licenseData = licenseOf[_for];

        if (bytes(licenseData.uri).length == 0) {
            robot.mint(msg.sender);
            ++totalLicenseCount;
            ownerLicenses[msg.sender].push(_for);
        }

        // licenseOf[_for] = LicenseData(_licenseUri, _info);
        licenseOf[_for].uri = _licenseUri;
        licenseOf[_for].info = _info;

        emit LicenseSet(msg.sender, _for, _licenseUri, _info);
    }

    /// @notice returns a license count for a given owner
    /// @param _owner the owner of the licenses
    /// @return licenseCount
    function getOwnerLicenseCount(address _owner) external view returns (uint256) {
        return ownerLicenses[_owner].length;
    }

    /// @notice remove a license URI _for a license owned by the license owner
    /// @param _for the address of the license to register
    function removeDefaultLicense(address _for) public senderMustBeOwnerOf(_for) {
        LicenseData memory licenseData = licenseOf[_for];
        if (bytes(licenseData.uri).length == 0) {
            revert LicenseNotRegistered();
        }

        delete licenseOf[_for];

        address[] memory licenses = ownerLicenses[msg.sender];
        delete ownerLicenses[msg.sender];

        uint256 length = licenses.length;
        for (uint256 i; i < length;) {
            if (licenses[i] != _for) {
                ownerLicenses[msg.sender].push(licenses[i]);
            }
            unchecked {
                ++i;
            }
        }

        robot.burn(msg.sender);
        --totalLicenseCount;

        emit LicenseRemoved(msg.sender, _for);
    }

    function whitelistOwnerContract(address _owner, address _contractAddress) external onlyOwner {
        if (_owner == address(0) || _contractAddress == address(0)) revert ZeroAddress();
        if (contractAddressToOwnerAllowList[_contractAddress] == _owner) revert AlreadyWhitelisted();
        contractAddressToOwnerAllowList[_contractAddress] = _owner;
        emit ContractWhitelisted(_owner, _contractAddress);
    }

    function delistOwnerContract(address _owner, address _contractAddress) external onlyOwner {
        if (_owner == address(0) || _contractAddress == address(0)) revert ZeroAddress();
        if (contractAddressToOwnerAllowList[_contractAddress] != _owner) revert NotWhitelisted();
        delete contractAddressToOwnerAllowList[_contractAddress];
        emit ContractDelisted(_owner, _contractAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRobot {
    error ZeroAddress();
    error SameAddress();
    error NotRobotTxt();
    error NotTransferable();

    event RobotTxtUpdated(address indexed robotTxt);

    function mint(address to) external;
    function burn(address from) external;
    function setRobotTxt(address newRobotTxt) external;
}