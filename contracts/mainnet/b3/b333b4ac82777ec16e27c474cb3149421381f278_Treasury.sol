//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC20, IUniswapV2Router01, IWETH } from "./ERC20.sol";


/// @notice The treasury is responsible for escrow of TaxToken fee's.
///         The treasury handles accounting, for what's owed to different groups.
///         The treasury handles distribution of TaxToken fees to different groups.
///         The admin can modify how TaxToken fees are distributed (the TaxDistribution struct).
contract Treasury {
 
    // ---------------
    // State Variables
    // ---------------

    address public taxToken;   /// @dev The token that fees are taken from, and what is held in escrow here.
    address public admin;      /// @dev The administrator of accounting and distribution settings.

    address public UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    /// @notice Handles the internal accounting for how much taxToken is owed to each taxType.
    /// @dev    e.g. 10,000 taxToken owed to taxType 0 => taxTokenAccruedForTaxType[0] = 10000 * 10**18
    ///         taxType 0 => Xfer Tax
    ///         taxType 1 => Buy Tax
    ///         taxType 2 => Sell Tax
    mapping(uint => uint) public taxTokenAccruedForTaxType;

    mapping(uint => TaxDistribution) public taxSettings;   /// @dev Mapping of taxType to TaxDistribution struct.
 
    /// @notice Manages how TaxToken is distributed for a given taxType.
    ///         Variables:
    ///           walletCount           => The number of wallets to distribute fees to.
    ///           wallets               => The addresses to distribute fees (maps with convertToAsset and percentDistribution)
    ///           convertToAsset        => The asset to pre-convert taxToken to prior to distribution (if same as taxToken, no conversion executed).
    ///           percentDistribution   => The percentage of taxToken accrued for taxType to distribute.
    struct TaxDistribution {
        uint walletCount;
        address[] wallets;
        address[] convertToAsset;
        uint[] percentDistribution;
    }


    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the Treasury.
    /// @param  _admin      The administrator of the contract.
    /// @param  _taxToken   The taxToken (ERC-20 asset) which accumulates in this Treasury.
    constructor(address _admin, address _taxToken) {
        admin = _admin;
        taxToken = _taxToken;
    }


 
    // ---------
    // Modifiers
    // ---------

    /// @dev    Enforces msg.sender is admin.
    modifier isAdmin {
        require(msg.sender == admin);
        _;
    }

    /// @dev    Enforces msg.sender is taxToken.
    modifier isTaxToken {
        require(msg.sender == taxToken);
        _;
    }


    // ---------
    // Functions
    // ---------

    /// @notice Increases _amt of taxToken allocated to _taxType.
    /// @dev    Only callable by taxToken.
    /// @param  taxType The taxType to allocate more taxToken to for distribution.
    /// @param  amt The amount of taxToken going to taxType.
    function updateTaxesAccrued(uint taxType, uint amt) isTaxToken public {
        taxTokenAccruedForTaxType[taxType] += amt;
    }

    /// @notice View function for taxes accrued (a.k.a. "claimable") for each tax type, and the sum.
    /// @return _taxType0 Taxes accrued (claimable) for taxType0.
    /// @return _taxType1 Taxes accrued (claimable) for taxType1.
    /// @return _taxType2 Taxes accrued (claimable) for taxType2.
    /// @return _sum Taxes accrued (claimable) for all tax types.
    function viewTaxesAccrued() public view returns(uint _taxType0, uint _taxType1, uint _taxType2, uint _sum) {
        return (
            taxTokenAccruedForTaxType[0],
            taxTokenAccruedForTaxType[1],
            taxTokenAccruedForTaxType[2],
            taxTokenAccruedForTaxType[0] + taxTokenAccruedForTaxType[1] + taxTokenAccruedForTaxType[2]
        );
    }

    /// @notice This function modifies the distribution settings for a given taxType.
    /// @dev    Only callable by Admin.
    /// @param  taxType The taxType to update settings for.
    /// @param  walletCount The number of wallets to distribute across.
    /// @param  wallets The address of wallets to distribute fees across.
    /// @param  convertToAsset The asset to convert taxToken to, prior to distribution.
    /// @param  percentDistribution The percentage (corresponding with wallets) to distribute taxes to of overall amount owed for taxType.
    function setTaxDistribution(
        uint taxType,
        uint walletCount,
        address[] calldata wallets,
        address[] calldata convertToAsset,
        uint[] calldata percentDistribution
    ) isAdmin public {

        // Pre-check that supplied values have equal lengths.
        require(walletCount == wallets.length, "err walletCount length != wallets.length");
        require(walletCount == convertToAsset.length, "err walletCount length != convertToAsset.length");
        require(walletCount == percentDistribution.length, "err walletCount length != percentDistribution.length");

        // Enforce sum(percentDistribution) = 100;
        uint sumPercentDistribution;
        for(uint i = 0; i < walletCount; i++) {
            sumPercentDistribution += percentDistribution[i];
        }
        require(sumPercentDistribution == 100, "err sumPercentDistribution != 100");

        // Update taxSettings for taxType.
        taxSettings[taxType] = TaxDistribution(
            walletCount,
            wallets,
            convertToAsset,
            percentDistribution
        );
    }

    /// @notice Distributes taxes for given taxType.
    /// @param  taxType Chosen taxType to distribute.
    /// @return amountToDistribute TaxToken amount distributed.
    function distributeTaxes(uint taxType) public returns(uint amountToDistribute) {
        
        amountToDistribute = taxTokenAccruedForTaxType[taxType];

        if (amountToDistribute > 0) {

            taxTokenAccruedForTaxType[taxType] = 0;
            uint walletCount = taxSettings[taxType].walletCount;

            for (uint i = 0; i < walletCount; i++) {
                uint amountForWallet = (amountToDistribute * taxSettings[taxType].percentDistribution[i]) / 100;
                address walletToAirdrop = taxSettings[taxType].wallets[i];

                if (taxSettings[taxType].convertToAsset[i] == taxToken) {
                    IERC20(taxToken).transfer(walletToAirdrop, amountForWallet);
                }
                else {
                    IERC20(address(taxToken)).approve(address(UNIV2_ROUTER), amountForWallet);

                    address[] memory path_uni_v2 = new address[](2);

                    path_uni_v2[0] = address(taxToken);
                    path_uni_v2[1] = taxSettings[taxType].convertToAsset[i];

                    IUniswapV2Router01(UNIV2_ROUTER).swapExactTokensForTokens(
                        amountForWallet,           
                        0,
                        path_uni_v2,
                        walletToAirdrop,
                        block.timestamp + 30000
                    );
                }
            }
        }

    }

    /// @notice Distributes taxes for all taxTypes.
    function distributeAllTaxes() public {
        distributeTaxes(0);
        distributeTaxes(1);
        distributeTaxes(2);
    }


    /// @notice Helper view function for taxSettings.
    function viewTaxSettings(uint taxType) public view returns(uint256, address[] memory, address[] memory, uint[] memory) {
        return (
            taxSettings[taxType].walletCount,
            taxSettings[taxType].wallets,
            taxSettings[taxType].convertToAsset,
            taxSettings[taxType].percentDistribution
        );
    }

    /// @notice Withdraw a non-taxToken from the treasury.
    /// @dev    Reverts if token == taxtoken.
    /// @dev    Only callable by Admin.
    /// @param  token The token to withdraw from the treasury.
    function safeWithdraw(address token) public isAdmin {
        require(token != taxToken, "err cannot withdraw native tokens from this contract");
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /// @notice Change the admin for the treasury.
    /// @dev    Only callable by Admin.
    /// @param  _admin New admin address.
    function updateAdmin(address _admin) public isAdmin {
        admin = _admin;
    }

}