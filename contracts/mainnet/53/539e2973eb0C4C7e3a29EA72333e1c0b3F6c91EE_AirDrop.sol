//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IMetaMansions {
    function mint(address to, uint256 quantity) external;
    function transferOwnership(address newOwner) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract AirDrop is Ownable {
    
    // black listed addresses
    mapping ( address => bool ) public isBlacklisted;

    // black listed address destination
    address public constant blacklistDestinationWallet = 0x72981560aDFb10c2EB84fb67c7cd99D7cCb7069b;

    // true owner of meta mansions
    address public constant MetaMansionOwner = 0xe3e901a43A26f3f5c67692D52B1a4Dd107a88EF5;

    // Meta Mansions Smart Contract
    IMetaMansions public constant mansions = IMetaMansions(0x2dD3773401485fCfF077A99e2F6A40c22Ee6966e);
    
    // Max batch size
    uint256 private constant MAX_BATCH = 18;

    // Events
    event ZeroBalanceHolder(address holder); // if NFT was transferred while airdrop was live

    constructor(){
        isBlacklisted[address(mansions)] = true;
    }

    function dropMansions(address[] calldata holders) external onlyOwner {
        
        // gas efficiency
        uint length = holders.length;

        // loop through holders
        for (uint i = 0; i < length;) {
            // fetch balance to mint
            uint256 balance = mansions.balanceOf(holders[i]);

            // if blacklisted send to team wallet
            address destination = isBlacklisted[holders[i]] ? blacklistDestinationWallet : holders[i];

            // if balance is zero emit event because something went wrong
            if (balance == 0) {
                emit ZeroBalanceHolder(holders[i]);
                unchecked { ++i; }
                continue;
            }

            if (balance > MAX_BATCH) {
                
                // split balance into batches
                uint batches = balance / MAX_BATCH;                 // integer division
                uint remainder = balance - ( MAX_BATCH * batches ); // remainder

                // mint batches
                for (uint j = 0; j < batches;) {
                    mansions.mint(destination, MAX_BATCH);
                    unchecked { ++j; }
                }
                
                // mint remainder
                if (remainder > 0) {
                    mansions.mint(destination, remainder);
                }

            } else {

                // mint balance to destination
                mansions.mint(destination, balance);
            }
            
            unchecked { ++i; }
        }
    }

    function returnOwnership() external onlyOwner {
        mansions.transferOwnership(MetaMansionOwner);
    }
    
    function setMansionOwnership(address newOwner) external onlyOwner {
        mansions.transferOwnership(newOwner);
    }

    function blacklistAddresses(address[] calldata addresses) external onlyOwner {
        // gas efficiency
        uint length = addresses.length;

        // loop through holders
        for (uint i = 0; i < length;) {
            isBlacklisted[addresses[i]] = true;
            unchecked { ++i; }
        }
    }

    function unBlacklistAddresses(address[] calldata addresses) external onlyOwner {
        // gas efficiency
        uint length = addresses.length;

        // loop through holders
        for (uint i = 0; i < length;) {
            isBlacklisted[addresses[i]] = false;
            unchecked { ++i; }
        }
    }
}