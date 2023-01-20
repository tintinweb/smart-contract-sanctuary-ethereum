// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IpenguPins.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
                         %@@@@*  @@@  *#####
                   &@@@@@@@@ ,@@@@@@@@@  #########
              ,@@@@@@@@  #                  %. @@@@@@@
           &@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@ [email protected]@@@@@@@
         @@@@@@@@@@@. @@@@@@@@@@@@ @@@@@@@@@@@@@  @@@@@@@@@@
       ####       @  @@@@@@@@@@@@@ @@@@@@@@@@@@@@.       .&@@@
     ########. @@@@@@@@@@ @@@@@%#///#%@@@@@@ @@@@@@@@@@@  @@@@@.
    ########  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@. @@@@@@
   ######### @@@@@@@@@@@ &@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@  @@@@@@
  %@@(       ,@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@,      &@
  @@@# @@@@@@@@@@@@ ,#####*                 . ,@@@@  %@@@@@@@@@@@@@@/
  @@@  @@@@@@@@@@@@ ##############  @@@@@@@@@@@@ ,@@@@.   @@@&  @@@@@@..#
  @@@ &@@@@@@@@@@@@ ##############  @@@@@@@@@@ @@@@@@@@@@@&   @@@@@@@@ #####
  @@@ @@@@@@@@@@@@@ ##############  @@@@@@@@ *@@@@@@@@@@  @@@. @@@@@@ ########
  @@        %@@@@@@ ##############  @@@@@@@ @@@@@@@@@@@ @@@@@@@ @@@&@ ####### /
  &&@@@@@  @@@@@@@@@@&*                    @@@@@@@@@@# @@@@@@@  &&&&&&& ##  @@@
  &&&&&@@  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@* @@@    [email protected]% @@@@@@ &&&&&&&&&&& @@@@@@
  @&&&&&&  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@@ @@@    &&&&&&&&&&&&& @@@@@
      &&&  &@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@ @@@@@@    . #&&&&&&&& @@@@/
   (((  &&       /@@@@@* @@@@@@@@@@@@@@@,[email protected]@@@@@@@@ @@@@@& &&&&& &&&&&&     @@@
   (((* &&&&&&&&&/ @@@@@@@@@@@@@@@ @@@@@ .   [email protected]@@@@ @@@@@  &&&&& &&&&&&&& @@@@@
   (((( &&&&&&&&&/ &&&@@@@@@@@@@@@ @@@@@  ######### %@@@@  &&&&& &&&&&&&& @@@@@
     (( &&&&&&&&&/ &&&&&&&@@@@@@@@ @@@@@% ######### @@@@@%          &&&&& @@@.
           .&&&&&/ &&&&&&&&&&&&&&@ @@@@@@ ######### @@@@@@
                                           ######## @@@@@@
*/

/**
 * @title Intermediary contract for dropping pengupins
 * @author Pudgy Penguins Penguineering Team (davidbailey.eth, Lorenzo)
 */
contract Intermediary is Ownable {
    // ========================================
    //     EVENT & ERROR DEFINITIONS
    // ========================================

    error AddressAlreadySet();
    error InvalidAddress();
    error NotAnAdmin();
    error MaximumAllowanceExceeded();

    // ========================================
    //     VARIABLE DEFINITIONS
    // ========================================

    bool private pengupinsAddressSet = false;
    IpenguPins public pengupins;

    mapping(address => mapping(uint256 => uint256)) public adminAllowance;

    // ========================================
    //    CONSTRUCTOR AND CORE FUNCTIONS
    // ========================================

    constructor() {}

    /**
     * @notice Drops airdrop tokens to a list of holders
     * @param _id token ID to be received
     * @param _holders list of addresses to receive tokens
     * @dev only nominated admins or contract owner can call this function
     */
    function airdropPenguPin(
        uint256 _id,
        address[] calldata _holders
    ) external {
        if (msg.sender != owner()) {
            if (adminAllowance[msg.sender][_id] < _holders.length)
                revert MaximumAllowanceExceeded();

            adminAllowance[msg.sender][_id] -= _holders.length;
        }
        pengupins.airdropPenguPin(_id, _holders);
    }

    // ========================================
    //     OWNER FUNCTIONS
    // ========================================

    // Function that allows the contract owner to nominate an admin
    /**
     * @notice Adds an admin to the contract
     * @param _newAdmin address of the admin to be added
     * @param _tokenId token ID that the admin can airdrop
     * @param _amount amount of tokens that the admin can airdrop
     */
    function addAdminForTokenId(
        address _newAdmin,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        if (_newAdmin == address(0)) revert InvalidAddress();
        adminAllowance[_newAdmin][_tokenId] = _amount;
    }

    /**
     * @notice Removes an admin from the contract
     * @param _oldAdmin address of the admin to be removed
     * @param _tokenId token ID that the admin can airdrop
     */
    function removeAdminForTokenId(
        address _oldAdmin,
        uint256 _tokenId
    ) external onlyOwner {
        if (adminAllowance[_oldAdmin][_tokenId] == 0) revert NotAnAdmin();
        adminAllowance[_oldAdmin][_tokenId] = 0;
    }

    /**
     * @notice Burns a token with the given ID from holder's address
     * @param _holder address of the token holder
     * @param _id token ID to be burned
     */
    function adminBurnPenguPin(
        address _holder,
        uint256 _id
    ) external onlyOwner {
        pengupins.adminBurnPenguPin(_holder, _id);
    }

    /**
     * @notice Pauses the pengupin contract
     */
    function pause() public onlyOwner {
        pengupins.pause();
    }

    /**
     * @notice Unpauses the pengupin contract
     */
    function unpause() public onlyOwner {
        pengupins.unpause();
    }

    /**
     * @notice Sets the address of the pengupins contract
     * @param _pengupinsAddress address of the pengupins contract
     */
    function setPengupinsAddress(address _pengupinsAddress) external onlyOwner {
        if (pengupinsAddressSet) revert AddressAlreadySet();
        if (_pengupinsAddress == address(0)) revert InvalidAddress();
        pengupinsAddressSet = true;
        pengupins = IpenguPins(_pengupinsAddress);
    }

    /**
     * @notice Transfers ownership of the pengupins contract
     * @param _newOwner address of the new owner
     */
    function transferOwnershipOfPengupins(
        address _newOwner
    ) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidAddress();
        pengupins.transferOwnership(_newOwner);
    }

    /**
     * @notice Sets the base URI of the pengupins contract
     * @param _base base URI of the pengupins contract
     * @param _suffix suffix URI of the pengupins contract
     */
    function setURI(
        string calldata _base,
        string calldata _suffix
    ) external onlyOwner {
        pengupins.setURI(_base, _suffix);
    }

    /**
     * @notice Updates the version of the signature that the pengupin contract uses
     * @param _newVersion new version of the signature
     */
    function updateSignVersion(string calldata _newVersion) external onlyOwner {
        pengupins.updateSignVersion(_newVersion);
    }

    /**
     * @notice Updates the wallet that the pengupin contract uses to verify signatures
     * @param _newSignerWallet address of the new wallet
     */
    function updateSignerWallet(address _newSignerWallet) external onlyOwner {
        pengupins.updateSignerWallet(_newSignerWallet);
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

interface IpenguPins {
    function airdropPenguPin(uint256 id, address[] calldata holders) external;

    function claimPenguPinToWallet(
        address receiverWallet,
        uint256 id,
        uint256 nonce,
        bytes memory signature
    ) external;

    function burnTruePengu(uint256 id) external;

    function adminBurnPenguPin(address holder, uint256 id) external;

    function uri(uint256 id) external view returns (string memory);

    function setURI(string calldata _base, string calldata _suffix) external;

    function pause() external;

    function unpause() external;

    function claimPaused() external view;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function updateSignVersion(string calldata signVersion_) external;

    function updateSignerWallet(address signerWallet_) external;
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