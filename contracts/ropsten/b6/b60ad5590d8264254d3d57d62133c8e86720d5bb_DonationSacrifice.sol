//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC1155{
    function burnBatch(address, uint256[] memory, uint256[] memory) external;
}

/// @title A Donation contract that allows users to gain more secondary coins by burnin nft
contract DonationSacrifice is Ownable {
    IERC1155 public multiplierToken;
    address[] public donators;
    mapping(uint256 => bool) public allowedIdsToBurnTogether;
    mapping(uint256 => uint256) private multipliers;

    event Donation(address indexed _from, uint256[] depostedIds, uint256 indexed depostAmount);

    /// @param _erc1155MultiplierTokenAddress takes an address of burning token (deploying address should have ownership of contract)
    /// @param _multipliers takes an array with multipliers multiplies by 100 , f.e. 6 -> 600 , orders matters!
    /// @param _allowedIdsToBurnTogether describes what tokens can be burn together to get some special multiplier (currenty multiplier of all of id's included)
    constructor(
            address _erc1155MultiplierTokenAddress, 
            uint256[] memory _multipliers, 
            uint256[] memory _allowedIdsToBurnTogether
            ) 
        {

        for(uint256 i; i < _multipliers.length; i++) {
            multipliers[i] = _multipliers[i];
        }
        for(uint256 i; i < _allowedIdsToBurnTogether.length; i++) {
            allowedIdsToBurnTogether[_allowedIdsToBurnTogether[i]] = true;
        }
        multiplierToken = IERC1155(_erc1155MultiplierTokenAddress);
        
    }

    /// @param idsToBurn - array of ids of nft which are going to burn
    /// @notice function should be given an array of length of zero, one or three, otherwise the function will revert
    function donate(uint256[] memory idsToBurn) public payable { 
        require(msg.value > 0, "No ether sent");
        uint256[] memory amountToBurn = new uint256[](idsToBurn.length);

        if(idsToBurn.length == 0) {
            emit Donation(msg.sender, idsToBurn, msg.value);
        } else if(idsToBurn.length == 1) {
            amountToBurn[0] = idsToBurn[0];
            multiplierToken.burnBatch(msg.sender, idsToBurn, amountToBurn);
            emit Donation(msg.sender, idsToBurn, msg.value * multipliers[idsToBurn[0]] / 100);
        } else if(idsToBurn.length == 3) {
            require(idsToBurn[0] != idsToBurn[1] && idsToBurn[0] != idsToBurn[2], "Paramets can't be the same");

            for(uint256 i; i < idsToBurn.length; i++) {
                amountToBurn[i] = 1;
                require(allowedIdsToBurnTogether[idsToBurn[i]] == true, "The provided ids can't be burned together");
            }
            multiplierToken.burnBatch(msg.sender, idsToBurn, amountToBurn);
            emit Donation(msg.sender, idsToBurn, msg.value * 300 / 100); // hardcoded value
        } else {
            revert("Wrong multiplier ID"); 
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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