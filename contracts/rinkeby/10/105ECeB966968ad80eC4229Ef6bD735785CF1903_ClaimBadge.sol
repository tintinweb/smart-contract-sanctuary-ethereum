// SPDX-License-Identifier: MIT

/**                                                               
 *******************************************************************************
 * Claim contract
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "../lib/sharkz/Adminable.sol";

interface IClaimable {
    function claimMint(address soulContract, uint256 soulTokenId) external;
}

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IOwnerOf {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ClaimBadge is Adminable {
    IClaimable public targetContract;

    constructor () {}

    function setTarget (address _contract) external onlyAdmin {
        targetContract = IClaimable(_contract);
    }

    function claim(address soulContract, uint256 soulTokenId) 
        external 
        callerIsUser 
        callerIsSoulOwner(soulContract, soulTokenId)
    {
        require(targetContract != IClaimable(address(0)), 'Target contract is the zero address');
        targetContract.claimMint(soulContract, soulTokenId);
    }

    // Caller must not be an wallet account
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller should not be a contract");
        _;
    }

    // Caller must be `Soul` token owner
    modifier callerIsSoulOwner(address soulContract, uint256 soulTokenId) {
        require(soulContract != address(0), "Soul contract is the zero address");

        address soulOwnerAddress;
        try IOwnerOf(soulContract).ownerOf(soulTokenId) returns (address ownerAddress) {
            if (ownerAddress != address(0)) {
                soulOwnerAddress = ownerAddress;
            }
        } catch (bytes memory) {}
        require(msg.sender == soulOwnerAddress && soulOwnerAddress != address(0), "Caller is not Soul token owner");
        _;
    }

    /**
     * @dev Returns whether an address is NFT owner
     */
    function _isExternalTokenOwner(address _contract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi
 *
 */
pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract Adminable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // add the first admin with contract creator
    constructor() {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }
}