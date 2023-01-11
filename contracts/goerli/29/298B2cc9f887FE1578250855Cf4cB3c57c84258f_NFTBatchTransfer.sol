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

    function totalSupply() external view returns (uint256 supply);
}

contract NFTBatchTransfer {
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTANTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    address public constant NOUNS_DAO =
        0xBFa0c9B831599405dCFF9aC3232387354Bbd1514;

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    // Number of allowed NFTs receiver address can transfer
    mapping(address => mapping(address => uint256)) public allowanceFor;

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

    /// @notice Calculate the first NFT token ID owned by Nouns DAO
    /// @dev Will revert NotEnoughOwned() if Nouns DAO has no balance
    /// @return startId The first token ID owned by Nouns DAO
    function getStartId(ERC721Like NFT) public view returns (uint256 startId) {
        if (NFT.balanceOf(NOUNS_DAO) == 0) {
            revert NotEnoughOwned();
        }

        for (startId = 0; startId < NFT.totalSupply(); startId++) {
            try NFT.ownerOf(startId) returns (address owner) {
                if (owner != NOUNS_DAO) continue;
                break;
            } catch {}
        }
    }

    /// @notice Calculate the first NFT token ID owned by Nouns DAO and the maximum batch amount possible from this ID for a receiver
    /// @dev Will revert:
    /// - NotEnoughOwned() if Nouns DAO has no balance
    /// - NotEnoughAllowance() if receiver has no allowance
    /// @param receiver Address to calculate maximum batch amount
    /// @return startId The first token ID owned by Nouns DAO
    /// @return amount The maximum batch amount from the startId for this receiver
    function getStartIdAndBatchAmount(ERC721Like NFT, address receiver)
        public
        view
        returns (uint256 startId, uint256 amount)
    {
        if (allowanceFor[address(NFT)][receiver] == 0) {
            revert NotEnoughAllowance();
        }

        startId = getStartId(NFT);

        uint256 maxAmount = _min(
            allowanceFor[address(NFT)][receiver],
            NFT.balanceOf(NOUNS_DAO)
        );

        // If we get this far, Nouns DAO owns at least 1 NFT
        for (amount = 1; amount < maxAmount; amount++) {
            try NFT.ownerOf(startId + amount) returns (address owner) {
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

    /// @notice Add an allowance for receiver address to batch send an amount of NFTs
    /// @param receiver Address to allow
    /// @param amount Batch amount allowed
    function addAllowance(ERC721Like NFT, address receiver, uint256 amount)
        external
        onlyNounsDAO
    {
        allowanceFor[address(NFT)][receiver] += amount;
    }

    /// @notice Removes all allowance for the receiver address
    /// @param receiver Address to disallow
    function disallow(ERC721Like NFT, address receiver) external onlyNounsDAO {
        delete allowanceFor[address(NFT)][receiver];
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      receiver FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Send `msg.sender` a batch `amount` of NFTs from `startId.` Use `getStartIdAndBatchAmount(address)` to determine these values
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the batch token transfer
    /// @param amount The batch amount of NFTs to be transfered
    function claimNFTs(ERC721Like NFT, uint256 startId, uint256 amount) public {
        _subtractFromAllowanceOrRevert(NFT, amount);

        for (uint256 i; i < amount; i++) {
            NFT.transferFrom(NOUNS_DAO, msg.sender, startId + i);
        }
    }

    /// @notice Sends a `recipient` NFTs. Use `getStartId()` to determine the `startId`
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the token transfer
    /// @param recipient Address to receive NFTs
    function sendNFTs(ERC721Like NFT, uint256 startId, address recipient) public {
        _subtractFromAllowanceOrRevert(NFT, 1);

        NFT.transferFrom(NOUNS_DAO, recipient, startId);
    }

    /// @notice Sends a group of `recipients` NFTs. Use `getStartId()` to determine the `startId`
    /// @dev See `_subtractFromAllowanceOrRevert(uint256)` for revert cases
    /// @param startId The starting ID of the token transfer
    /// @param recipients Addresses to receive NFTs
    function sendManyNFTs(ERC721Like NFT, uint256 startId, address[] calldata recipients)
        public
    {
        uint256 amount = recipients.length;
        _subtractFromAllowanceOrRevert(NFT,amount);

        for (uint256 i; i < amount; i++) {
            NFT.transferFrom(NOUNS_DAO, recipients[i], startId + i);
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
    function _subtractFromAllowanceOrRevert(ERC721Like NFT, uint256 amount) internal {
        uint256 allowance = allowanceFor[address(NFT)][msg.sender];

        if (amount > allowance) {
            revert NotEnoughAllowance();
        }

        if (amount > NFT.balanceOf(NOUNS_DAO)) {
            revert NotEnoughOwned();
        }

        allowanceFor[address(NFT)][msg.sender] = allowance - amount;
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