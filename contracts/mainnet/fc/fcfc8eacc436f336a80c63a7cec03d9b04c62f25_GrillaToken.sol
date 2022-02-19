// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./JungleSerum.sol";
import "./CyberGorillasStaking.sol";

/*
   ______      __              ______           _ ____          
  / ____/_  __/ /_  ___  _____/ ____/___  _____(_) / /___ ______
 / /   / / / / __ \/ _ \/ ___/ / __/ __ \/ ___/ / / / __ `/ ___/
/ /___/ /_/ / /_/ /  __/ /  / /_/ / /_/ / /  / / / / /_/ (__  ) 
\____/\__, /_.___/\___/_/   \____/\____/_/  /_/_/_/\__,_/____/  
     /____/                                                     

*/

/// @title Grilla Token
/// @author delta devs (https://twitter.com/deltadevelopers)
contract GrillaToken is ERC20, Ownable {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted by `buyOffChainUtility` function.
    /// @dev Event logging when utility has been purchased.
    /// @param sender Address of purchaser.
    /// @param itemId Item identifier tied to utility.
    event UtilityPurchase(address indexed sender, uint256 indexed itemId);

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice An instance of the JungleSerum contract.
    JungleSerum serumContract;

    /// @notice Retrieves price tied to specific utility item ID.
    mapping(uint256 => uint256) utilityPrices;

    /// @notice Returns true if address is authorized to make stake function calls.
    mapping(address => bool) authorizedStakingContracts;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC20("GRILLA", "GRILLA", 18) {}

    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to mint GRILLA.
    /// @param account The address which will receive the minted amount.
    /// @param amount The amount of tokens to mint.
    function ownerMint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /// @notice Allows authorized staking contracts to mint GRILLA.
    /// @param account The address which will receive the minted amount.
    /// @param amount The amount of tokens to mint.
    function stakerMint(address account, uint256 amount) public {
        require(
            authorizedStakingContracts[msg.sender],
            "Request only valid from staking contract"
        );
        _mint(account, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        CONTRACT SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to authorize a contract to stake.
    /// @param staker The address to authorize.
    function addStakingContract(address staker) public onlyOwner {
        authorizedStakingContracts[staker] = true;
    }

    /// @notice Allows the contract deployer to unauthorize a contract to stake.
    /// @param staker The address to remove authority from.
    function removeStakingContract(address staker) public onlyOwner {
        authorizedStakingContracts[staker] = false;
    }

    /// @notice Sets the address of the JungleSerum contract.
    /// @param serumContractAddress The address of the JungleSerum contract.
    function setSerumContract(address serumContractAddress) public onlyOwner {
        serumContract = JungleSerum(serumContractAddress);
    }

    /*///////////////////////////////////////////////////////////////
                        UTILITY PURCHASING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Purchase JungleSerum.
    function buySerum() public {
        transfer(address(serumContract), serumContract.serumPrice());
        serumContract.mint(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                    OFFCHAIN UTILITY PURCHASING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the price of a specific utility.
    /// @param itemId The identifier of the utility item.
    /// @return The price of a specific utility.
    function getUtilityPrice(uint256 itemId) public view returns (uint256) {
        return utilityPrices[itemId];
    }

    /// @notice Allows the contract deployer to add off-chain utility data.
    /// @param itemId The identifier of the utility item.
    /// @param itemPrice The price of the utility item.
    function addOffchainUtility(uint256 itemId, uint256 itemPrice)
        public
        onlyOwner
    {
        utilityPrices[itemId] = itemPrice;
    }

    /// @notice Allows the contract deployer to remove off-chain utility data.
    /// @param itemId The identifier of the utility item.
    function deleteUtilityPrice(uint256 itemId) public onlyOwner {
        delete utilityPrices[itemId];
    }

    /// @notice Allows the contract deployer to add off-chain utility data for multiple items.
    /// @param items List of multiple utility item identifiers.
    /// @param prices List of multiple utility item prices.
    function uploadUtilityPrices(
        uint256[] memory items,
        uint256[] memory prices
    ) public onlyOwner {
        for (uint256 i = 0; i < items.length; i++) {
            utilityPrices[items[i]] = prices[i];
        }
    }

    /// @notice Buy the requested off chain utility.
    /// @param itemId The identifier of the utility item.
    function buyOffchainUtility(uint256 itemId) public {
        require(utilityPrices[itemId] > 0, "Invalid utility id");
        transfer(address(serumContract), utilityPrices[itemId]);
        emit UtilityPurchase(msg.sender, itemId);
    }
}