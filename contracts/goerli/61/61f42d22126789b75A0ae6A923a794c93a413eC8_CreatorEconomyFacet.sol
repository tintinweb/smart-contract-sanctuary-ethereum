// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../storage/AppStorage.sol";

contract CreatorEconomyFacet {
    AppStorage s;

    event DonationDeposited(address donator, address creator, uint256 amount, uint256 date);

    event RevenueWithdraw(address creator, uint256 amount, uint256 date);

    /**
     * @dev Deposit donation/tip into the Contract and links msg.value to Creator.revenue and Creator.totalAmountCollected
     * @param _creatorAddress of a Creator to deposit msg.value
     *
     * @notice Creators can't deposit funds
     */
    function depositDonation(address _creatorAddress) public payable {
        require(msg.sender != address(0));

        Creator storage creator = s.creators[_creatorAddress];
        require(creator.wallet != msg.sender, "Not Creator: Creators are not allowed to do this for themselves");
        require(address(this).balance >= msg.value, "Balance: Insufficient balance");
        creator.donations.push(msg.value);
        creator.supporters.push(msg.sender);
        creator.revenue = creator.revenue + msg.value;
        creator.totalAmountCollected = creator.totalAmountCollected + msg.value;
        s.totalFundsCollected + msg.value;
        emit DonationDeposited(msg.sender, creator.wallet, msg.value, block.timestamp);
    }

    /**
     * @dev Withdraw Revenue of a Creator (while paying the platformFee)
     * @param _amount – amount of funds to be withdrawn
     */
    function withdrawRevenue(uint256 _amount) public payable {
        require(msg.sender != address(0));

        Creator storage creator = s.creators[msg.sender];
        require(msg.sender == creator.wallet, "Creator: You are not a creator");
        require(address(this).balance >= msg.value, "Balance: Insufficient balance");
        uint256 fee = (_amount * s.platformFee) / 100;
        uint256 amount = _amount - fee;

        (bool payFee, ) = payable(s.platformFeeRecipient).call{value: fee}("");
        require(payFee);
        s.totalFeesCollected + fee;
        (bool withdraw, ) = payable(msg.sender).call{value: amount}("");
        require(withdraw);

        creator.revenue = creator.revenue - _amount;
        emit RevenueWithdraw(msg.sender, _amount, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev the Creator struct
 * @param wallet – creator's wallet
 * @param id – creator's id
 * @param rating – creator's rating on the platform
 * @param revenue – amount of funds to be withdrawn
 * @param totalAmountCollected – a counter for all the funds collected my a Creator
 * @param donations – donations/tips received by a Creator
 * @param supporters – addresses of those who donated/tipped a Creator
 * @param rated – addresses who rated a Creator
 *
 * @notice ONLY ONE Creator per wallet address
 */

struct Creator {
    address wallet;
    uint256 id;
    uint256 rating;
    uint256 revenue;
    uint256 totalAmountCollected;
    uint256[] donations;
    address[] supporters;
    address[] rated;
}

/**
 * @dev the AppStorage struct is responsible for storing the app's state and general data
 * @param version – version of the app
 * @param paused – a state of the contract
 * @param creatorsIDS – a counter for creators IDs
 * @param totalFundsCollected – a counter for all the funds aggregated by Creators
 * @param totalFeesCollected  – a counter for the fees collected by the platforms
 * @param platformFee – a percentage of a fee to be held back
 * @param platformFeeRecipient – fees colector
 * @param owner – owner of the platform
 * @param creators – a registry for Creators' addresses
 * @param existingCreators – a registry to check against if a wallet has already initiated a Creator
 */
struct AppStorage {
    string version;
    bool paused;
    uint256 creatorsIDs;
    uint256 totalFundsCollected;
    uint256 totalFeesCollected;
    uint256 platformFee;
    address platformFeeRecipient;
    address owner;
    mapping(address => Creator) creators;
    mapping(address => bool) existingCreators;
}