// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../AccessUnitControl/contracts/AbstractAccessUnitControl.sol";

contract AccessUnitControl is AbstractAccessUnitControl {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbstractAccessUnitControl is Ownable {
    mapping(address => uint256) private s_mapAccessAllowedAddresses; //holds address and allowed nr of allowed elements to be minted by this address
    address[] private s_addedAddresses; //holds all added addresses
    address s_handshakeContract; //used for feedback of minted tokens

    function linkHandshakeContract(address _handshakeContract)
        public
        virtual
        onlyOwner
    {
        require(_handshakeContract != address(0), "invalid address");
        s_handshakeContract = _handshakeContract;
    }

    function addAddressToAccessAllowed(
        address _addressToBeAdded,
        uint256 _nrOfAllowedElements
    ) public virtual onlyOwner {
        require(_addressToBeAdded != address(0), "invalid address");
        require(_nrOfAllowedElements > 0, "nr of allowed elements <= 0");
        require(
            s_mapAccessAllowedAddresses[_addressToBeAdded] !=
                _nrOfAllowedElements,
            "data already added"
        );
        if (s_mapAccessAllowedAddresses[_addressToBeAdded] == 0) {
            //address not yet added
            s_addedAddresses.push(_addressToBeAdded);
        }
        s_mapAccessAllowedAddresses[_addressToBeAdded] = _nrOfAllowedElements; //set nr of allowed elements to be minted by this address
    }

    function isAccessGranted(address _adressToBeChecked)
        public
        view
        virtual
        returns (bool)
    {
        require(_adressToBeChecked != address(0), "invalid address");
        if (s_mapAccessAllowedAddresses[_adressToBeChecked] > 0) {
            //so this address would be able to mint tokens, now we check if he already did
            require(
                s_handshakeContract != address(0),
                "handshakeContract not set"
            );
            //call other contract functions
            hadshakeContractImpl handshakeContract = hadshakeContractImpl(
                s_handshakeContract
            );
            if (
                handshakeContract.balanceOf(_adressToBeChecked) <
                s_mapAccessAllowedAddresses[_adressToBeChecked]
            ) {
                return (true);
            }
        }
    }

    function getNrOfAllowedElementsPerAddress(address _adressToBeChecked)
        public
        view
        virtual
        returns (uint256)
    {
        return (s_mapAccessAllowedAddresses[_adressToBeChecked]);
    }

    function getRemainingNrOfElementsPerAddress(address _adressToBeChecked)
        public
        view
        virtual
        returns (uint256)
    {
        require(_adressToBeChecked != address(0), "null address given");
        require(
            s_handshakeContract != address(0),
            "handshakecontract unlinked"
        );
        hadshakeContractImpl handshakeContract = hadshakeContractImpl(
            s_handshakeContract
        );
        return (s_mapAccessAllowedAddresses[_adressToBeChecked] -
            handshakeContract.balanceOf(_adressToBeChecked));
    }

    function removeAdressFromMapping(address _adressToBeRemoved)
        public
        virtual
        onlyOwner
    {
        require(_adressToBeRemoved != address(0), "null address given");
        delete s_mapAccessAllowedAddresses[_adressToBeRemoved];
    }

    function getCurrentNrOfElementsInMapping()
        public
        view
        virtual
        returns (uint256)
    {
        return (s_addedAddresses.length);
    }

    function removeAllFromAccessAllowed() public virtual onlyOwner {
        uint256 nrOfDeletesNeeded = s_addedAddresses.length;
        for (uint256 i; i < nrOfDeletesNeeded; i++) {
            removeAddressFromAccessAllowed(s_addedAddresses[0]); //refer always deleting first element, because wer reduce array after this call
        }
        delete s_addedAddresses;
    }

    function removeAddressFromAccessAllowed(address _addressToRemove)
        public
        virtual
        onlyOwner
    {
        require(_addressToRemove != address(0), "null address given");
        require(
            s_mapAccessAllowedAddresses[_addressToRemove] > 0,
            "address not found"
        );
        for (uint256 i; i < s_addedAddresses.length; i++) {
            if (s_addedAddresses[i] == _addressToRemove) {
                removeAdressFromMapping(_addressToRemove); //remove from mapping
                removeAddressByIndex(i);
                break;
            }
        }
    }

    function getArrayOfAddresses()
        public
        view
        virtual
        returns (address[] memory)
    {
        return s_addedAddresses;
    }

    function removeAddressByIndex(uint256 _indexToRemove) private {
        require(
            _indexToRemove <= s_addedAddresses.length ||
                s_addedAddresses.length > 0,
            "index out of range"
        );
        if (_indexToRemove == s_addedAddresses.length - 1) {
            s_addedAddresses.pop();
        } else {
            s_addedAddresses[_indexToRemove] = s_addedAddresses[
                s_addedAddresses.length - 1
            ];
            s_addedAddresses.pop();
        }
    }
}

abstract contract hadshakeContractImpl {
    function balanceOf(address owner) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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