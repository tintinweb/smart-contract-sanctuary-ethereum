pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//  _ __   ___ _   _ _ __ ___  _ __   __| | __ _  ___
// | '_ \ / _ \ | | | '__/ _ \| '_ \ / _` |/ _` |/ _ \
// | | | |  __/ |_| | | | (_) | | | | (_| | (_| | (_) |
// |_| |_|\___|\__,_|_|  \___/|_| |_|\__,_|\__,_|\___/

// Inspired by the Miso crowsdale
// https://github.com/chefgonpachi/MISO/
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// Made for neurondao.io
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0
// ---------------------------------------------------------------------

import "./OpenZeppelin/ReentrancyGuard.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/utils/MerkleProof.sol";
import "./Utils/SafeTransfer.sol";
import "./Utils/BoringBatchable.sol";
import "./Utils/BoringERC20.sol";
import "./Utils/BoringMath.sol";
import "./interfaces/IPointList.sol";
import "./interfaces/IDaoMarket.sol";

contract CrowdsaleWhiteList is
    IDaoMarket,
    Ownable,
    BoringBatchable,
    SafeTransfer,
    ReentrancyGuard
{
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringMath64 for uint64;
    using BoringERC20 for IERC20;

    // @notice The placeholder ETH address.
    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // @notice The decimals of the auction token.
    uint256 private constant AUCTION_TOKEN_DECIMAL_PLACES = 18;
    uint256 private constant AUCTION_TOKEN_DECIMALS =
        10**AUCTION_TOKEN_DECIMAL_PLACES;

    /**
     * @notice rate - How many token units a buyer gets per token or wei.
     * The rate is the conversion between wei and the smallest and indivisible token unit.
     * So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
     * 1 wei will give you 1 unit, or 0.001 TOK.
     */
    // @notice goal - Minimum amount of funds to be raised in weis or tokens.
    struct MarketPrice {
        uint128 rate;
        uint128 goal;
    }
    MarketPrice public marketPrice;

    // @notice Starting time of crowdsale.
    // @notice Ending time of crowdsale.
    // @notice Total number of tokens to sell.
    struct MarketInfo {
        uint64 startTime;
        uint64 endTime;
        uint128 totalTokens;
    }
    MarketInfo public marketInfo;

    // @notice Amount of wei raised.
    // @notice Whether crowdsale has been initialized or not.
    // @notice Whether crowdsale has been finalized or not.
    struct MarketStatus {
        uint128 commitmentsTotal;
        bool finalized;
        bool usePointList;
    }
    MarketStatus public marketStatus;

    // @notice The token being sold.
    address public auctionToken;
    // @notice Address where funds are collected.
    address payable public wallet;
    // @notice The currency the crowdsale accepts for payment. Can be ETH or token address.
    address public paymentCurrency;
    // @notice Address that manages auction approvals.
    address public pointList;

    // @notice used to validate whitelists
    bytes32 public merkleRoot;

    // @notice The commited amount of accounts.
    mapping(address => uint256) public commitments;
    // @notice Amount of tokens to claim per address.
    mapping(address => uint256) public claimed;

    // @notice Event for updating auction times.  Needs to be before auction starts.
    event AuctionTimeUpdated(uint256 startTime, uint256 endTime);
    // @notice Event for updating auction prices. Needs to be before auction starts.
    event AuctionPriceUpdated(uint256 rate, uint256 goal);
    // @notice Event for updating auction wallet. Needs to be before auction starts.
    event AuctionWalletUpdated(address wallet);

    // @notice Event for adding a commitment.
    event AddedCommitment(address addr, uint256 commitment);

    // @notice Event for finalization of the crowdsale
    event AuctionFinalized();
    // @notice Event for cancellation of the auction.
    event AuctionCancelled();

    /**
     * @notice Initializes main contract variables and transfers funds for the sale.
     * @dev Init function.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _admin Address that can finalize auction.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     */
    function initCrowdsale(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) public {
        require(
            _endTime < 10000000000,
            "Crowdsale: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _startTime >= block.timestamp,
            "Crowdsale: start time is before current time"
        );
        require(
            _endTime > _startTime,
            "Crowdsale: start time is not before end time"
        );
        require(_rate > 0, "Crowdsale: rate is 0");
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(_admin != address(0), "Crowdsale: admin is the zero address");
        require(_totalTokens > 0, "Crowdsale: total tokens is 0");
        require(_goal > 0, "Crowdsale: goal is 0");
        require(
            IERC20(_token).decimals() == AUCTION_TOKEN_DECIMAL_PLACES,
            "Crowdsale: Token does not have 18 decimals"
        );
        if (_paymentCurrency != ETH_ADDRESS) {
            require(
                IERC20(_paymentCurrency).decimals() > 0,
                "Crowdsale: Payment currency is not ERC20"
            );
        }

        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);
        marketInfo.totalTokens = BoringMath.to128(_totalTokens);

        auctionToken = _token;
        paymentCurrency = _paymentCurrency;
        wallet = _wallet;

        _setList(_pointList);

        require(
            _getTokenAmount(_goal) <= _totalTokens,
            "Crowdsale: goal should be equal to or lower than total tokens"
        );

        _safeTransferFrom(_token, _funder, _totalTokens);
    }

    //--------------------------------------------------------
    // Commit to buying tokens!
    //--------------------------------------------------------

    receive() external payable {
        revertBecauseUserDidNotProvideAgreement();
    }

    /**
     * @dev Attribution to the awesome delta.financial contracts
     */
    function marketParticipationAgreement()
        public
        pure
        returns (string memory)
    {
        return
            "I understand that I am interacting with a smart contract. I understand that tokens commited are subject to the token issuer and local laws where applicable. I reviewed code of the smart contract and understand it fully. I agree to not hold developers or other people associated with the project liable for any losses or misunderstandings";
    }

    /**
     * @dev Not using modifiers is a purposeful choice for code readability.
     */
    function revertBecauseUserDidNotProvideAgreement() internal pure {
        revert(
            "No agreement provided, please review the smart contract before interacting with it"
        );
    }

    /**
     * @notice Checks the amount of ETH to commit and adds the commitment. Refunds the buyer if commit is too high.
     * @dev low level token purchase with ETH ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it should not be called by
     * another `nonReentrant` function.
     * @param _beneficiary Recipient of the token purchase.
     */
    function commitEth(
        address payable _beneficiary,
        bytes32[] calldata merkleProof,
        bool readAndAgreedToMarketParticipationAgreement
    ) public payable nonReentrant isValidMerkleProof(merkleProof, merkleRoot) {
        require(
            paymentCurrency == ETH_ADDRESS,
            "Crowdsale: Payment currency is not ETH"
        );
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }

        // @dev Get ETH able to be committed.
        uint256 ethToTransfer = calculateCommitment(msg.value);

        // @dev Accept ETH Payments.
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_beneficiary, ethToTransfer);
        }

        // @dev Return any ETH to be refunded.
        if (ethToRefund > 0) {
            _beneficiary.transfer(ethToRefund);
        }

        // @notice Revert if commitmentsTotal exceeds the balance
        require(
            marketStatus.commitmentsTotal <= address(this).balance,
            "CrowdSale: The committed ETH exceeds the balance"
        );
    }

    /**
     * @notice Buy Tokens by commiting approved ERC20 tokens to this contract address.
     * @param _amount Amount of tokens to commit.
     */
    function commitTokens(
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bool readAndAgreedToMarketParticipationAgreement
    ) public isValidMerkleProof(merkleProof, merkleRoot) {
        commitTokensFrom(
            msg.sender,
            _amount,
            readAndAgreedToMarketParticipationAgreement
        );
    }

    /**
     * @notice Checks how much is user able to commit and processes that commitment.
     * @dev Users must approve contract prior to committing tokens to auction.
     * @param _from User ERC20 address.
     * @param _amount Amount of approved ERC20 tokens.
     */
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) public nonReentrant {
        require(
            address(paymentCurrency) != ETH_ADDRESS,
            "Crowdsale: Payment currency is not a token"
        );
        if (readAndAgreedToMarketParticipationAgreement == false) {
            revertBecauseUserDidNotProvideAgreement();
        }
        uint256 tokensToTransfer = calculateCommitment(_amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, msg.sender, tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
        }
    }

    /**
     * @notice Checks if the commitment does not exceed the goal of this sale.
     * @param _commitment Number of tokens to be commited.
     * @return committed The amount able to be purchased during a sale.
     */
    function calculateCommitment(uint256 _commitment)
        public
        view
        returns (uint256 committed)
    {
        uint256 tokens = _getTokenAmount(_commitment);
        uint256 tokensCommited = _getTokenAmount(
            uint256(marketStatus.commitmentsTotal)
        );
        if (tokensCommited.add(tokens) > uint256(marketInfo.totalTokens)) {
            return
                _getTokenPrice(
                    uint256(marketInfo.totalTokens).sub(tokensCommited)
                );
        }
        return _commitment;
    }

    /**
     * @notice Updates commitment of the buyer and the amount raised, emits an event.
     * @param _addr Recipient of the token purchase.
     * @param _commitment Value in wei or token involved in the purchase.
     */
    function _addCommitment(address _addr, uint256 _commitment) internal {
        require(
            block.timestamp >= uint256(marketInfo.startTime) &&
                block.timestamp <= uint256(marketInfo.endTime),
            "Crowdsale: outside auction hours"
        );
        require(
            _addr != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(!marketStatus.finalized, "CrowdSale: Auction is finalized");
        uint256 newCommitment = commitments[_addr].add(_commitment);
        if (marketStatus.usePointList) {
            require(IPointList(pointList).hasPoints(_addr, newCommitment));
        }

        commitments[_addr] = newCommitment;

        // @dev Update state.
        marketStatus.commitmentsTotal = BoringMath.to128(
            uint256(marketStatus.commitmentsTotal).add(_commitment)
        );

        emit AddedCommitment(_addr, _commitment);
    }

    function withdrawTokens() public {
        withdrawTokens(msg.sender);
    }

    /**
     * @notice Withdraws bought tokens, or returns commitment if the sale is unsuccessful.
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address payable beneficiary) public nonReentrant {
        if (auctionSuccessful()) {
            require(marketStatus.finalized, "Crowdsale: not finalized");
            // @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(beneficiary);
            require(tokensToClaim > 0, "Crowdsale: no tokens to claim");
            claimed[beneficiary] = claimed[beneficiary].add(tokensToClaim);
            _safeTokenPayment(auctionToken, beneficiary, tokensToClaim);
        } else {
            // @dev Auction did not meet reserve price.
            // @dev Return committed funds back to user.
            require(
                block.timestamp > uint256(marketInfo.endTime),
                "Crowdsale: auction has not finished yet"
            );
            uint256 accountBalance = commitments[beneficiary];
            commitments[beneficiary] = 0; // Stop multiple withdrawals and free some gas
            _safeTokenPayment(paymentCurrency, beneficiary, accountBalance);
        }
    }

    /**
     * @notice Adjusts users commitment depending on amount already claimed and unclaimed tokens left.
     * @return claimerCommitment How many tokens the user is able to claim.
     */
    function tokensClaimable(address _user)
        public
        view
        returns (uint256 claimerCommitment)
    {
        uint256 unclaimedTokens = IERC20(auctionToken).balanceOf(address(this));
        claimerCommitment = _getTokenAmount(commitments[_user]);
        claimerCommitment = claimerCommitment.sub(claimed[_user]);

        if (claimerCommitment > unclaimedTokens) {
            claimerCommitment = unclaimedTokens;
        }
    }

    //--------------------------------------------------------
    // Finalize Auction
    //--------------------------------------------------------

    /**
     * @notice Manually finalizes the Crowdsale.
     * @dev Must be called after crowdsale ends, to do some extra finalization work.
     * Calls the contracts finalization function.
     */
    function finalize() public nonReentrant onlyOwner {
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        MarketInfo storage info = marketInfo;
        require(info.totalTokens > 0, "Not initialized");
        require(auctionEnded(), "Crowdsale: Has not finished yet");

        if (auctionSuccessful()) {
            // @dev Successful auction
            // @dev Transfer contributed tokens to wallet.
            _safeTokenPayment(
                paymentCurrency,
                wallet,
                uint256(status.commitmentsTotal)
            );
            // @dev Transfer unsold tokens to wallet.
            uint256 soldTokens = _getTokenAmount(
                uint256(status.commitmentsTotal)
            );
            uint256 unsoldTokens = uint256(info.totalTokens).sub(soldTokens);
            if (unsoldTokens > 0) {
                _safeTokenPayment(auctionToken, wallet, unsoldTokens);
            }
        } else {
            // @dev Failed auction
            // @dev Return auction tokens back to wallet.
            _safeTokenPayment(auctionToken, wallet, uint256(info.totalTokens));
        }

        status.finalized = true;

        emit AuctionFinalized();
    }

    /**
     * @notice Cancel Auction
     * @dev Admin can cancel the auction before it starts
     */
    function cancelAuction() public nonReentrant onlyOwner {
        MarketStatus storage status = marketStatus;
        require(!status.finalized, "Crowdsale: already finalized");
        require(
            uint256(status.commitmentsTotal) == 0,
            "Crowdsale: Funds already raised"
        );

        _safeTokenPayment(
            auctionToken,
            wallet,
            uint256(marketInfo.totalTokens)
        );

        status.finalized = true;
        emit AuctionCancelled();
    }

    function tokenPrice() public view returns (uint256) {
        return uint256(marketPrice.rate);
    }

    function _getTokenPrice(uint256 _amount) internal view returns (uint256) {
        return
            _amount.mul(uint256(marketPrice.rate)).div(AUCTION_TOKEN_DECIMALS);
    }

    function getTokenAmount(uint256 _amount) public view returns (uint256) {
        return _getTokenAmount(_amount);
    }

    /**
     * @notice Calculates the number of tokens to purchase.
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _amount Value in wei or token to be converted into tokens.
     * @return tokenAmount Number of tokens that can be purchased with the specified amount.
     */
    function _getTokenAmount(uint256 _amount) internal view returns (uint256) {
        return
            _amount.mul(AUCTION_TOKEN_DECIMALS).div(uint256(marketPrice.rate));
    }

    /**
     * @notice Checks if the sale is open.
     * @return isOpen True if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return
            block.timestamp >= uint256(marketInfo.startTime) &&
            block.timestamp <= uint256(marketInfo.endTime);
    }

    /**
     * @notice Checks if the sale minimum amount was raised.
     * @return auctionSuccessful True if the commitmentsTotal is equal or higher than goal.
     */
    function auctionSuccessful() public view returns (bool) {
        return
            uint256(marketStatus.commitmentsTotal) >= uint256(marketPrice.goal);
    }

    /**
     * @notice Checks if the sale has ended.
     * @return auctionEnded True if sold out or time has ended.
     */
    function auctionEnded() public view returns (bool) {
        return
            block.timestamp > uint256(marketInfo.endTime) ||
            _getTokenAmount(uint256(marketStatus.commitmentsTotal) + 1) >=
            uint256(marketInfo.totalTokens);
    }

    /**
     * @notice Checks if the sale has been finalised.
     * @return bool True if sale has been finalised.
     */
    function finalized() public view returns (bool) {
        return marketStatus.finalized;
    }

    /**
     * @return True if 7 days have passed since the end of the auction
     */
    function finalizeTimeExpired() public view returns (bool) {
        return uint256(marketInfo.endTime) + 7 days < block.timestamp;
    }

    //--------------------------------------------------------
    // Point Lists
    //--------------------------------------------------------

    function setList(address _list) external onlyOwner {
        _setList(_list);
    }

    function enableList(bool _status) external onlyOwner {
        marketStatus.usePointList = _status;
    }

    function _setList(address _pointList) private {
        if (_pointList != address(0)) {
            pointList = _pointList;
            marketStatus.usePointList = true;
        }
    }

    //--------------------------------------------------------
    // Setter Functions
    //--------------------------------------------------------

    /**
     * @notice Admin can set start and end time through this function.
     * @param _startTime Auction start time.
     * @param _endTime Auction end time.
     */
    function setAuctionTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _startTime < 10000000000,
            "Crowdsale: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _endTime < 10000000000,
            "Crowdsale: enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _startTime >= block.timestamp,
            "Crowdsale: start time is before current time"
        );
        require(
            _endTime > _startTime,
            "Crowdsale: end time must be older than start price"
        );

        require(
            marketStatus.commitmentsTotal == 0,
            "Crowdsale: auction cannot have already started"
        );

        marketInfo.startTime = BoringMath.to64(_startTime);
        marketInfo.endTime = BoringMath.to64(_endTime);

        emit AuctionTimeUpdated(_startTime, _endTime);
    }

    /**
     * @notice Admin can set auction price through this function.
     * @param _rate Price per token.
     * @param _goal Minimum amount raised and goal for the auction.
     */
    function setAuctionPrice(uint256 _rate, uint256 _goal) external onlyOwner {
        require(_goal > 0, "Crowdsale: goal is 0");
        require(_rate > 0, "Crowdsale: rate is 0");
        require(
            marketStatus.commitmentsTotal == 0,
            "Crowdsale: auction cannot have already started"
        );
        marketPrice.rate = BoringMath.to128(_rate);
        marketPrice.goal = BoringMath.to128(_goal);
        require(
            _getTokenAmount(_goal) <= uint256(marketInfo.totalTokens),
            "Crowdsale: minimum target exceeds hard cap"
        );

        emit AuctionPriceUpdated(_rate, _goal);
    }

    /**
     * @notice Admin can set the auction wallet through this function.
     * @param _wallet Auction wallet is where funds will be sent.
     */
    function setAuctionWallet(address payable _wallet) external onlyOwner {
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        wallet = _wallet;

        emit AuctionWalletUpdated(_wallet);
    }

    //--------------------------------------------------------
    // Market Launchers
    //--------------------------------------------------------

    function init(bytes calldata _data) external payable override {}

    /**
     * @notice Decodes and hands Crowdsale data to the initCrowdsale function.
     * @param _data Encoded data for initialization.
     */
    function initMarket(bytes calldata _data) public override {
        (
            address _funder,
            address _token,
            address _paymentCurrency,
            uint256 _totalTokens,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            uint256 _goal,
            address _admin,
            address _pointList,
            address payable _wallet
        ) = abi.decode(
                _data,
                (
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    address,
                    address
                )
            );

        initCrowdsale(
            _funder,
            _token,
            _paymentCurrency,
            _totalTokens,
            _startTime,
            _endTime,
            _rate,
            _goal,
            _admin,
            _pointList,
            _wallet
        );
    }

    /**
     * @notice Collects data to initialize the crowd sale.
     * @param _funder The address that funds the token for crowdsale.
     * @param _token Address of the token being sold.
     * @param _paymentCurrency The currency the crowdsale accepts for payment. Can be ETH or token address.
     * @param _totalTokens The total number of tokens to sell in crowdsale.
     * @param _startTime Crowdsale start time.
     * @param _endTime Crowdsale end time.
     * @param _rate Number of token units a buyer gets per wei or token.
     * @param _goal Minimum amount of funds to be raised in weis or tokens.
     * @param _admin Address that can finalize crowdsale.
     * @param _pointList Address that will manage auction approvals.
     * @param _wallet Address where collected funds will be forwarded to.
     * @return _data All the data in bytes format.
     */
    function getCrowdsaleInitData(
        address _funder,
        address _token,
        address _paymentCurrency,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        address _admin,
        address _pointList,
        address payable _wallet
    ) external pure returns (bytes memory _data) {
        return
            abi.encode(
                _funder,
                _token,
                _paymentCurrency,
                _totalTokens,
                _startTime,
                _endTime,
                _rate,
                _goal,
                _admin,
                _pointList,
                _wallet
            );
    }

    function getBaseInformation()
        external
        view
        returns (
            address,
            uint64,
            uint64,
            bool
        )
    {
        return (
            auctionToken,
            marketInfo.startTime,
            marketInfo.endTime,
            marketStatus.finalized
        );
    }

    function getTotalTokens() external view returns (uint256) {
        return uint256(marketInfo.totalTokens);
    }

    //--------------------------------------------------------
    // Merkle Proof
    //--------------------------------------------------------

    /**
     * @notice validates merkleProof
     * @param _merkleProof User's merkle proof.
     * @param _root Merkle root.
     */
    modifier isValidMerkleProof(
        bytes32[] calldata _merkleProof,
        bytes32 _root
    ) {
        require(
            MerkleProof.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    /**
     * @notice set whitelist merkle root
     * @param _merkleRoot Merkle root.
     */
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.6.12;

import "./utils/Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.6.12;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity 0.6.12;

contract SafeTransfer {
    address private constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to, _amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }

    /// @dev Transfer helper from UniswapV2 Router
    function _safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
     * Im trying to make it a habit to put external calls last (reentrancy)
     * You can put this in an internal function if you like.
     */
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal virtual {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto

import "./BoringERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
    /// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results)
    {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}

pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "BoringMath: Div zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to16(uint256 a) internal pure returns (uint16 c) {
        require(a <= uint16(-1), "BoringMath: uint16 Overflow");
        c = uint16(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath16 {
    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

pragma solidity 0.6.12;

// ----------------------------------------------------------------------------
// White List interface
// ----------------------------------------------------------------------------

interface IPointList {
    function isInList(address account) external view returns (bool);

    function hasPoints(address account, uint256 amount)
        external
        view
        returns (bool);

    function setPoints(address[] memory accounts, uint256[] memory amounts)
        external;
}

pragma solidity 0.6.12;

interface IDaoMarket {
    function init(bytes calldata data) external payable;

    function initMarket(bytes calldata data) external;
}

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}