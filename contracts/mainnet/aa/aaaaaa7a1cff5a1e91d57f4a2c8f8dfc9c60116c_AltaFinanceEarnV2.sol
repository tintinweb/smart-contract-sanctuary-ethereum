//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./EarnBase.sol";

/// @title Alta Finance EarnV2
/// @author Alta Finance Team
/// @notice This contract is a lending protocol where consumers lend crypto assets and earn stable yields secured by real estate.
contract AltaFinanceEarnV2 is EarnBase {
    /// ALTA token
    IERC20Metadata public ALTA;

    /// Address of wallet to receive funds
    address public feeAddress;

    /// Percent of offer amount transferred to Alta Finance as a service fee (100 = 10%)
    uint256 public transferFee; // 100 = 10%

    /// amount of alta to stake to reach tier 1
    uint256 public tier1Amount;
    /// amount of alta to stake to reach tier 2
    uint256 public tier2Amount;

    /// multiplier for contracts that reach tier 1
    uint256 public immutable tier1Multiplier = 1150; // 1150 = 1.15x
    /// multiplier for contracts that reach tier 2
    uint256 public immutable tier2Multiplier = 1300; // 1250 = 1.25x

    address safeAddress;
    address immutable treasury = 0x087183a411770a645A96cf2e31fA69Ab89e22F5E;

    /// Boolean variable to guard against multiple initialization attempts
    bool initiated;

    /// @param owner Address of the contract owner
    /// @param earnContractId index of earn contract in earnContracts
    event ContractOpened(address indexed owner, uint256 indexed earnContractId);

    /// @param owner Address of the contract owner
    /// @param earnContractId index of earn contract in earnContracts
    event ContractClosed(address indexed owner, uint256 indexed earnContractId);

    /// @param previousOwner Address of the previous contract owner
    /// @param newOwner Address of the new contract owner
    /// @param earnContractId Index of earn contract in earnContracts
    event ContractSold(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 indexed earnContractId
    );

    /// @param owner Address of the contract owner
    /// @param earnContractId Index of earn contract in earnContracts
    /// @param token Address of the token redeemed
    /// @param tokenAmount Amount of token redeemed
    /// @param altaAmount Amount of ALTA redeemed
    event Redemption(
        address indexed owner,
        uint256 indexed earnContractId,
        address token,
        uint256 tokenAmount,
        uint256 altaAmount
    );

    /// @param buyer Address of the buyer
    /// @param offerId Index of offer in offers
    event ContractOffer(address indexed buyer, uint256 indexed offerId);

    /// @param earnContractId Index of earn contract in earnContracts
    event ContractListed(uint256 indexed earnContractId);

    /// @param earnContractId Index of earn contract in earnContracts
    event ContractListingRemoved(uint256 indexed earnContractId);

    constructor() {
        _transferOwnership(treasury);
    }

    enum ContractStatus {
        OPEN,
        CLOSED,
        FORSALE
    }

    enum Tier {
        TIER0,
        TIER1,
        TIER2
    }

    struct EarnTerm {
        uint128 time; // Time Locked (in Days);
        uint64 interestRate; // Base APR (simple interest) (1000 = 10%)
        uint64 altaRatio; // ALTA ratio (1000 = 10%)
        bool open; // True if open, False if closed
    }

    struct EarnContract {
        address owner; // Contract Owner Address
        uint256 termIndex; // Index of Earn Term
        uint256 startTime; // Unix Epoch time started
        uint256 contractLength; // length of contract in seconds
        address token; // Token Address
        uint256 lentAmount; // Amount of token lent
        uint256 altaStaked; // Amount of ALTA staked
        uint256 baseTokenPaid; // Base Interest Paid
        uint256 altaPaid; // ALTA Interest Paid
        Tier tier; // TIER0, TIER1, TIER2
        ContractStatus status; // Open, Closed, or ForSale
    }

    struct Offer {
        address buyer; // Buyer Address
        address to; // Address of Contract Owner
        uint256 earnContractId; // Earn Contract Id
        uint256 amount; // ALTA Amount
        bool accepted; // Accepted - false if pending
    }

    EarnTerm[] public earnTerms;
    EarnContract[] public earnContracts;
    Offer[] public offers;
    mapping(address => bool) public acceptedAssets;

    /// @return An array of type EarnContract
    function getAllEarnContracts() public view returns (EarnContract[] memory) {
        return earnContracts;
    }

    /// @return An array of type EarnTerm
    function getAllEarnTerms() public view returns (EarnTerm[] memory) {
        return earnTerms;
    }

    /// @return An array of type Offer
    function getAllOffers() public view returns (Offer[] memory) {
        return offers;
    }

    /// Sends erc20 token to Alta Treasury Address and creates a contract with EarnContract[_id] terms for user.
    /// @param _earnTermsId Index of the earn term in earnTerms
    /// @param _amount Amount of token to be lent
    /// @param _token Token Address
    /// @param _altaStake Amount of Alta to stake in contract
    function openContract(
        uint256 _earnTermsId,
        uint256 _amount,
        IERC20Metadata _token,
        uint256 _altaStake
    ) public whenNotPaused {
        require(_amount > 0, "Token amount must be greater than zero");

        EarnTerm memory earnTerm = earnTerms[_earnTermsId];
        require(earnTerm.open, "Earn Term must be open");

        require(acceptedAssets[address(_token)], "Token not accepted");

        // User needs to first approve the token to be spent
        require(
            _token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient Tokens"
        );

        _token.transferFrom(msg.sender, address(this), _amount);

        if (_altaStake > 0) {
            ALTA.transferFrom(msg.sender, address(this), _altaStake);
        }

        Tier tier = getTier(_altaStake);

        // Convert time of earnTerm from days to seconds
        uint256 earnSeconds = earnTerm.time * 1 days;

        _createContract(
            _earnTermsId,
            earnSeconds,
            address(_token),
            _amount,
            _altaStake,
            tier
        );
    }

    /// @notice Redeem the currrent base token + ALTA interest available for the contract
    /// @param _earnContractId Index of earn contract in earnContracts
    function redeem(uint256 _earnContractId) public {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(earnContract.owner == msg.sender);
        (uint256 baseTokenAmount, uint256 altaAmount) = redeemableValue(
            _earnContractId
        );
        earnContract.baseTokenPaid += baseTokenAmount;
        earnContract.altaPaid += altaAmount;

        if (
            block.timestamp >=
            earnContract.startTime + earnContract.contractLength
        ) {
            _closeContract(_earnContractId);
        }
        emit Redemption(
            msg.sender,
            _earnContractId,
            earnContract.token,
            baseTokenAmount,
            altaAmount
        );
        IERC20Metadata Token = IERC20Metadata(earnContract.token);
        Token.transfer(msg.sender, baseTokenAmount);
        ALTA.transfer(msg.sender, altaAmount);
    }

    /// @notice Redeem the tokens availabe for all earn contracts owned by the sender (gas savings)
    function redeemAll() public {
        uint256 length = earnContracts.length; // gas optimization
        EarnContract[] memory _contracts = earnContracts; // gas optimization
        for (uint256 i = 0; i < length; i++) {
            if (_contracts[i].owner == msg.sender) {
                redeem(i);
            }
        }
    }

    /// @dev Calculate the currrent base token + ALTA available for the contract
    /// @param _earnContractId Index of earn contract in earnContracts
    /// @return baseTokenAmount Base token amount
    /// @return altaAmount ALTA amount
    function redeemableValue(uint256 _earnContractId)
        public
        view
        returns (uint256 baseTokenAmount, uint256 altaAmount)
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        EarnTerm memory earnTerm = earnTerms[earnContract.termIndex];
        IERC20Metadata Token = IERC20Metadata(earnContract.token);

        uint256 timeOpen = block.timestamp -
            earnContracts[_earnContractId].startTime;

        uint256 interestRate = getInterestRate(
            earnTerm.interestRate,
            earnContract.tier
        );

        if (timeOpen <= earnContract.contractLength) {
            // Just interest
            baseTokenAmount =
                (earnContract.lentAmount * interestRate * timeOpen) /
                365 days /
                10000;

            // Calculate the total amount of alta rewards accrued
            altaAmount = (((((earnContract.lentAmount * (10**ALTA.decimals())) /
                (10**Token.decimals())) * earnTerm.altaRatio) / 10000) * timeOpen / earnContract.contractLength);
        } else {
            // Calculate the total amount of base token to be paid out (principal + interest)
            uint256 baseRegInterest = ((earnContract.lentAmount *
                interestRate *
                earnContract.contractLength) /
                365 days /
                10000);

            baseTokenAmount = baseRegInterest + earnContract.lentAmount;

            // Calculate the total amount of alta rewards accrued + staked amount
            altaAmount = ((((earnContract.lentAmount * (10**ALTA.decimals())) /
                (10**Token.decimals())) * earnTerm.altaRatio) / 10000) + earnContract.altaStaked;
        }

        baseTokenAmount = baseTokenAmount - earnContract.baseTokenPaid;
        altaAmount = altaAmount - earnContract.altaPaid;
        return (baseTokenAmount, altaAmount);
    }

    /// @dev Calculate the currrent base token + ALTA available for the contract
    /// @param _earnContractId Index of earn contract in earnContracts
    /// @return baseTokenAmount Base token amount
    /// @return altaAmount ALTA amount
    function redeemableValue(uint256 _earnContractId, uint256 _time)
        public
        view
        returns (uint256 baseTokenAmount, uint256 altaAmount)
    {
        require(_time >= earnContracts[_earnContractId].startTime);
        EarnContract memory earnContract = earnContracts[_earnContractId];
        EarnTerm memory earnTerm = earnTerms[earnContract.termIndex];
        IERC20Metadata Token = IERC20Metadata(earnContract.token);

        uint256 timeOpen = _time - earnContracts[_earnContractId].startTime;

        uint256 interestRate = getInterestRate(
            earnTerm.interestRate,
            earnContract.tier
        );

        if (timeOpen <= earnContract.contractLength) {
            // Just interest
            baseTokenAmount =
                (earnContract.lentAmount * interestRate * timeOpen) /
                365 days /
                10000;

            // Calculate the total amount of alta rewards accrued
            altaAmount = (((((earnContract.lentAmount * (10**ALTA.decimals())) /
                (10**Token.decimals())) * earnTerm.altaRatio) / 10000) * timeOpen / earnContract.contractLength);
        } else {
            // Calculate the total amount of base token to be paid out (principal + interest)
            uint256 baseRegInterest = ((earnContract.lentAmount *
                interestRate *
                earnContract.contractLength) /
                365 days /
                10000);

            baseTokenAmount = baseRegInterest + earnContract.lentAmount;

            // Calculate the total amount of alta rewards accrued + staked amount
            altaAmount = ((((earnContract.lentAmount * (10**ALTA.decimals())) /
                (10**Token.decimals())) * earnTerm.altaRatio) / 10000) + earnContract.altaStaked;
        }

        baseTokenAmount = baseTokenAmount - earnContract.baseTokenPaid;
        altaAmount = altaAmount - earnContract.altaPaid; 
        return (baseTokenAmount, altaAmount);
    }

    /// @notice Lists the associated earn contract for sale on the market
    /// @param _earnContractId Index of earn contract in earnContracts
    function putSale(uint256 _earnContractId) external whenNotPaused {
        require(
            msg.sender == earnContracts[_earnContractId].owner,
            "Msg.sender is not the owner"
        );
        earnContracts[_earnContractId].status = ContractStatus.FORSALE;
        emit ContractListed(_earnContractId);
    }

    /// @notice Submits an offer for an earn contract listed on the market
    /// @dev User must sign an approval transaction for first. ALTA.approve(address(this), _amount);
    /// @param _earnContractId Index of earn contract in earnContracts
    /// @param _amount Amount of base token offered
    function makeOffer(uint256 _earnContractId, uint256 _amount)
        external
        whenNotPaused
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(
            earnContract.status == ContractStatus.FORSALE,
            "Contract not for sale"
        );
        require(msg.sender != earnContract.owner, "Cannot make offer on own contract");

        Offer memory offer = Offer(
            msg.sender, // buyer
            earnContract.owner, // to
            _earnContractId, // earnContractId
            _amount, // amount
            false // accepted
        );

        offers.push(offer);
        uint256 offerId = offers.length - 1;

        IERC20Metadata(earnContract.token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        emit ContractOffer(msg.sender, offerId);
    }

    /// @notice Transfers the offer amount to the owner of the earn contract and transfers ownership of the contract to the buyer
    /// @param _offerId Index of offer in Offers
    function acceptOffer(uint256 _offerId) external whenNotPaused {
        Offer memory offer = offers[_offerId];
        uint256 earnContractId = offer.earnContractId;
        EarnContract memory earnContract = earnContracts[earnContractId];

        require(
            msg.sender == earnContract.owner,
            "Msg.sender is not the owner"
        );

        uint256 fee = (offer.amount * transferFee) / 1000;

        if (fee > 0) {
            IERC20Metadata(earnContract.token).transfer(feeAddress, fee);
            offer.amount = offer.amount - fee;
        }
        IERC20Metadata(earnContract.token).transfer(offer.to, offer.amount);

        offers[_offerId].accepted = true;

        emit ContractSold(offer.to, offer.buyer, earnContractId);
        earnContracts[earnContractId].owner = offer.buyer;

        _removeContractFromMarket(earnContractId);
    }

    /// @notice Remove Contract From Market
    /// @param _earnContractId Index of earn contract in earnContracts
    function removeContractFromMarket(uint256 _earnContractId) external {
        require(
            msg.sender == earnContracts[_earnContractId].owner,
            "Msg.sender is not the owner"
        );
        _removeContractFromMarket(_earnContractId);
    }

    /// @notice Sends offer funds back to buyer and removes the offer from the array
    /// @param _offerId Index of offer in Offers
    function removeOffer(uint256 _offerId) external {
        Offer memory offer = offers[_offerId];
        require(msg.sender == offer.buyer, "Msg.sender is not the buyer");
        EarnContract memory earnContract = earnContracts[offer.earnContractId];
        IERC20Metadata(earnContract.token).transfer(offer.buyer, offer.amount);

        _removeOffer(_offerId);
    }

    /// @param _interestRate Base interest rate before tier multipliers
    /// @param _tier Tier of the contract
    function getInterestRate(uint256 _interestRate, Tier _tier)
        public
        pure
        returns (uint256)
    {
        if (_tier == Tier.TIER0) {
            return _interestRate;
        } else if (_tier == Tier.TIER1) {
            return ((_interestRate * tier1Multiplier) / 1000);
        } else {
            return ((_interestRate * tier2Multiplier) / 1000);
        }
    }

    /// @param _ALTA Address of ALTA Token contract
    /// @param _feeAddress Address of wallet to recieve loan funds
    function init(
        IERC20Metadata _ALTA,
        address _feeAddress
    ) external onlyOwner {
        require(!initiated, "Contract already initiated");
        ALTA = _ALTA;
        feeAddress = _feeAddress;
        transferFee = 3; // 3 = .3%
        tier1Amount = 10000 * (10**ALTA.decimals()); // 10,000 ALTA
        tier2Amount = 100000 * (10**ALTA.decimals()); // 100,000 ALTA
        initiated = true;
    }

    /// @param _time Length of the contract in days
    /// @param _interestRate Base interest rate (1000 = 10%)
    /// @param _altaRatio Interest rate for ALTA (1000 = 10%)
    /// @dev Add an earn term with 8 parameters
    function addTerm(
        uint128 _time,
        uint64 _interestRate,
        uint64 _altaRatio
    ) public onlyOwner {
        earnTerms.push(EarnTerm(_time, _interestRate, _altaRatio, true));
    }

    /// @param _earnTermsId index of the earn term in earnTerms
    function closeTerm(uint256 _earnTermsId) public onlyOwner {
        require(_earnTermsId < earnTerms.length);
        earnTerms[_earnTermsId].open = false;
    }

    /// @param _earnTermsId index of the earn term in earnTerms
    function openTerm(uint256 _earnTermsId) public onlyOwner {
        require(_earnTermsId < earnTerms.length);
        earnTerms[_earnTermsId].open = true;
    }

    /// @notice Close the contract flagged wallet for AML compliance. Owner will receive principal with no interest.
    /// @param _earnContractId Index of earn contract in earnContracts
    function closeContractAmlCheck(uint256 _earnContractId) external onlyOwner {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(block.timestamp <= earnContract.startTime + 7 days);
        IERC20Metadata Token = IERC20Metadata(earnContract.token);
        _closeContract(_earnContractId);
        Token.transfer(msg.sender, earnContract.lentAmount);
    }

    /// Set the transfer fee rate for contracts sold on the market place
    /// @param _transferFee Percent of accepted earn contract offer to be sent to Alta wallet
    function setTransferFee(uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
    }

    /// @notice Set the safe address for the contract
    /// @param _safeAddress Address of the safe contract
    function setSafeAddress(address _safeAddress) external onlyOwner {
        safeAddress = _safeAddress;
        _transferOwnership(_safeAddress);
    }

    /// @notice Set ALTA ERC20 token address
    /// @param _ALTA Address of ALTA Token contract
    function setAltaAddress(address _ALTA) external onlyOwner {
        ALTA = IERC20Metadata(_ALTA);
    }

    /// @notice Set the feeAddress
    /// @param _feeAddress Wallet address to recieve loan funds
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0));
        feeAddress = _feeAddress;
    }

    /// @param _tier1Amount Amount of ALTA staked to be considered Tier 1
    /// @param _tier2Amount Amount of ALTA staked to be considered Tier 2
    function setStakeAmounts(uint256 _tier1Amount, uint256 _tier2Amount)
        external
        onlyOwner
    {
        tier1Amount = _tier1Amount;
        tier2Amount = _tier2Amount;
    }

    /// @param _asset Address of token to be updated
    /// @param _accepted True if the token is accepted, false otherwise
    function updateAsset(address _asset, bool _accepted) external onlyOwner {
        acceptedAssets[_asset] = _accepted;
    }

    /// @param _assets Array of token addresses to be updated
    /// @param _accepted True if the token is accepted, false otherwise
    function updateAssets(address[] memory _assets, bool _accepted) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            acceptedAssets[_assets[i]] = _accepted;
        }
    }

    /// @param _earnTermsId Index of the earn term in earnTerms
    /// @param _earnSeconds Length of the contract in seconds
    /// @param _lentAmount Amount of token lent
    function _createContract(
        uint256 _earnTermsId,
        uint256 _earnSeconds,
        address _token,
        uint256 _lentAmount,
        uint256 _altaStake,
        Tier tier
    ) internal {
        EarnContract memory earnContract = EarnContract(
            msg.sender, // owner
            _earnTermsId, // termIndex
            block.timestamp, // startTime
            _earnSeconds, //contractLength,
            _token, // token
            _lentAmount, // lentAmount
            _altaStake, // altaStaked
            0, // baseTokenPaid
            0, // altaPaid
            tier, // tier
            ContractStatus.OPEN
        );

        earnContracts.push(earnContract);
        uint256 id = earnContracts.length - 1;
        emit ContractOpened(msg.sender, id);
    }

    /// @param _earnContractId index of earn contract in earnContracts
    function _closeContract(uint256 _earnContractId) internal {
        require(
            earnContracts[_earnContractId].status != ContractStatus.CLOSED,
            "Contract is already closed"
        );
        require(
            _earnContractId < earnContracts.length,
            "Contract does not exist"
        );
        EarnContract memory earnContract = earnContracts[_earnContractId];
        address owner = earnContract.owner;
        emit ContractClosed(owner, _earnContractId);

        _removeAllContractOffers(_earnContractId);
        earnContracts[_earnContractId].status = ContractStatus.CLOSED;
    }

    /// @param _offerId Index of offer in Offers
    function _removeOffer(uint256 _offerId) internal {
        require(_offerId < offers.length, "Offer ID longer than array length");

        if (offers.length > 1) {
            offers[_offerId] = offers[offers.length - 1];
        }
        offers.pop();
    }

    /// @notice Removes all contracts offers and sets the status flag back to open
    /// @param _earnContractId Index of earn contract in earnContracts
    function _removeContractFromMarket(uint256 _earnContractId) internal {
        earnContracts[_earnContractId].status = ContractStatus.OPEN;
        _removeAllContractOffers(_earnContractId);
        emit ContractListingRemoved(_earnContractId);
    }

    /// @notice Sends all offer funds for an earn contract back to the buyer and removes them arrays and mappings
    /// @param _earnContractId Index of earn contract in earnContracts
    function _removeAllContractOffers(uint256 _earnContractId) internal {
        uint256 length = offers.length; // gas optimization
        Offer[] memory _offers = offers; // gas optimization
        if (length > 0) {
            for (uint256 i = length; i > 0; i--) {
                uint256 offerId = i - 1;
                if (_offers[offerId].earnContractId == _earnContractId) {
                    if (!_offers[offerId].accepted) {
                        IERC20Metadata(
                            earnContracts[_offers[offerId].earnContractId].token
                        ).transfer(_offers[offerId].buyer, _offers[offerId].amount);
                    }
                    _removeOffer(offerId);
                }
            }
        }
    }

    /// @param _altaStaked Amount of ALTA staked to the contract
    function getTier(uint256 _altaStaked) internal view returns (Tier) {
        if (_altaStaked < tier1Amount) {
            return Tier.TIER0;
        } else if (_altaStaked < tier2Amount) {
            return Tier.TIER1;
        } else {
            return Tier.TIER2;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EarnBase is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Withdrawal(address indexed sender, uint256 amount);
    event Received(address, uint);

    ///
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @param _token - token to be withdrawn
     * @param _to - address to withdraw to
     * @param _amount - amount of token to withdraw
     */
    function withdrawToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) public onlyOwner nonReentrant {
        require(_token.balanceOf(address(this)) >= _amount, "Not enough token");
        SafeERC20.safeTransfer(_token, _to, _amount);
        emit Withdrawal(_to, _amount);
    }

    /**
     * @param _to address of transfer recipient
     * @param _amount amount of ether to be transferred
     */
    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint256 _amount) public onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}