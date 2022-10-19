/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool approved) external;
}

contract NounsVisionBatchTransfer {
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTANTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    ERC721Like public constant NOUNS_VISION =
        ERC721Like(0xd8e6b954f7d3F42570D3B0adB516f2868729eC4D);

    address public constant NOUNS_DAO =
        0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    // Number of allowed Nouns Vision Glasses receiver address can transfer
    mapping(address => uint256) public allowanceFor;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERRORS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    error NotNounsDAO();
    error NotEnoughOwned();
    error NotEnoughAllowance();

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      MODIFIERS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    modifier onlyNounsDAO() {
        if (msg.sender != NOUNS_DAO) revert NotNounsDAO();
        _;
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Calculate the first Nouns Vision Glasses token ID owned by Nouns DAO
    /// @dev Will revert NotEnoughOwned() if Nouns DAO has no balance
    /// @return startId The first token ID owned by Nouns DAO
    function getStartId() public view returns (uint256 startId) {
        if (NOUNS_VISION.balanceOf(NOUNS_DAO) == 0) {
            revert NotEnoughOwned();
        }

        // Nouns DAO was sent 500 Nouns Vision Glasses starting at token ID 751
        for (startId = 751; startId <= 1250; startId++) {
            try NOUNS_VISION.ownerOf(startId) returns (address owner) {
                if (owner != NOUNS_DAO) continue;
                break;
            } catch {}
        }
    }

    /// @notice Calculate the first Nouns Vision Glasses token ID owned by Nouns DAO and the maximum batch amount possible from this ID for a receiver
    /// @dev Will revert:
    /// - NotEnoughOwned() if Nouns DAO has no balance
    /// - NotEnoughAllowance() if receiver has no allowance
    /// @param receiver Address to calculate maximum batch amount
    /// @return startId The first token ID owned by Nouns DAO
    /// @return amount The maximum batch amount from the startId for this receiver
    function getStartIdAndBatchAmount(address receiver)
        public
        view
        returns (uint256 startId, uint256 amount)
    {
        if (allowanceFor[receiver] == 0) {
            revert NotEnoughAllowance();
        }

        startId = getStartId();

        uint256 maxAmount = _min(
            allowanceFor[receiver],
            NOUNS_VISION.balanceOf(NOUNS_DAO)
        );

        // If we get this far, Nouns DAO owns at least 1 Nouns Vision Glasses
        for (amount = 1; amount < maxAmount; amount++) {
            try NOUNS_VISION.ownerOf(startId + amount) returns (address owner) {
                if (owner != NOUNS_DAO) break;
            } catch {
                break;
            }
        }
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      OWNER FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Add an allowance for receiver address to batch send an amount of Nouns Vision Glasses
    /// @param receiver Address to allow
    /// @param amount Batch amount allowed
    function addAllowance(address receiver, uint256 amount)
        external
        onlyNounsDAO
    {
        allowanceFor[receiver] += amount;
    }

    /// @notice Removes all allowance for the receiver address
    /// @param receiver Address to disallow
    function disallow(address receiver) external onlyNounsDAO {
        delete allowanceFor[receiver];
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      receiver FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Send `msg.sender` a batch `amount` of Nouns Vision Glasses from `startId.` Use `getStartIdAndBatchAmount(address)` to determine these values
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the batch token transfer
    /// @param amount The batch amount of Glasses to be transfered
    function claimGlasses(uint256 startId, uint256 amount) public {
        _subtractFromAllowanceOrRevert(amount);

        for (uint256 i; i < amount; i++) {
            NOUNS_VISION.transferFrom(NOUNS_DAO, msg.sender, startId + i);
        }
    }

    /// @notice Sends a `recipient` Nouns Vision Glasses. Use `getStartId()` to determine the `startId`
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the token transfer
    /// @param recipient Address to receive Nouns Vision Glasses
    function sendGlasses(uint256 startId, address recipient) public {
        _subtractFromAllowanceOrRevert(1);

        NOUNS_VISION.transferFrom(NOUNS_DAO, recipient, startId);
    }

    /// @notice Sends a group of `recipients` Nouns Vision Glasses. Use `getStartId()` to determine the `startId`
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the token transfer
    /// @param recipients Addresses to receive Nouns Vision Glasses
    function sendManyGlasses(uint256 startId, address[] calldata recipients)
        public
    {
        uint256 amount = recipients.length;
        _subtractFromAllowanceOrRevert(amount);

        for (uint256 i; i < amount; i++) {
            NOUNS_VISION.transferFrom(NOUNS_DAO, recipients[i], startId + i);
        }
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Checks `msg.sender` allowance against an amount and either subtracts or reverts
    /// @dev Will revert:
    /// - NotEnoughAllowance(): `msg.sender` has not been granted enough allowance
    /// - NotEnoughOwned(): Nouns DAO balance is less than the amount
    /// @param amount Amount that should be removed from `msg.sender` allowance
    function _subtractFromAllowanceOrRevert(uint256 amount) internal {
        uint256 allowance = allowanceFor[msg.sender];

        if (amount > allowance) {
            revert NotEnoughAllowance();
        }

        if (amount > NOUNS_VISION.balanceOf(NOUNS_DAO)) {
            revert NotEnoughOwned();
        }

        allowanceFor[msg.sender] = allowance - amount;
    }

    /// @notice Returns the smaller of two numbers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}