/*
 * This file is part of the contracts written for artèQ Investment Fund (https://arteq.io).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]>
///
/// @notice Use at your own risk
contract arteQArtDrop is ERC721URIStorage, IERC2981 {

    string private constant DEFAULT_TOKEN_URI = "DEFAULT_TOKEN_URI";

    uint256 public constant MAX_NR_TOKENS_PER_ACCOUNT = 5;
    uint256 public constant MAX_RESERVATIONS_COUNT = 10000;

    int256 public constant LOCKED_STAGE = 0;
    int256 public constant WHITELISTING_STAGE = 2;
    int256 public constant RESERVATION_STAGE = 3;
    int256 public constant DISTRIBUTION_STAGE = 4;

    // Counter for token IDs
    uint256 private _tokenIdCounter;

    // Counter for pre-minted token IDs
    uint256 private _preMintedTokenIdCounter;

    // number of tokens owned by the contract
    uint256 _contractBalance;

    address private _adminContract;

    // in wei
    uint256 private _pricePerToken;
    // in wei
    uint256 private _serviceFee;

    string private _defaultTokenURI;

    address _royaltyWallet;
    uint256 _royaltyPercentage;

    // The current art drop stage. It can have the following values:
    //
    //   0: Locked / Read-only mode
    //   2: Selection of the registered wallets (whitelisting)
    //   3: Reservation / Purchase stage
    //   4: Distribution of the tokens / Drop stage
    //
    // * 1 is missing from the above list. That's to keep the off-chain
    //   and on-chain states in sync.
    // * Only admin accounts with a quorum of votes can change the
    //   current stage.
    // * Some functions only work in certain stages.
    // * When the 4th stage (last stage) is finished, the contract
    //   will be put back into locked mode (stage 0).
    // * Admins can only advance/retreat the current stage by movements of +1 or -1.
    int256 private _stage;

    // A mapping from the whitelisted addresses to the maximum number of tokens they can obtain
    mapping(address => uint256) _whitelistedAccounts;

    // Counts the number of whitelisted accounts
    uint256 _whitelistedAccountsCounter;

    // Counts the number of reserved tokens
    uint256 _reservedTokensCounter;

    // Enabled reservations without a need to be whitelisted
    bool _canReserveWithoutBeingWhitelisted;

    // An operator which is allowed to perform certain operations such as adding whitelisted
    // accounts, removing them, or doing the token reservation for credit card payments. These
    // accounts can only be defined by a quorom of votes among admins.
    mapping(address => uint256) _operators;

    event WhitelistedAccountAdded(address doer, address account, uint256 maxNrOfTokensToObtain);
    event WhitelistedAccountRemoved(address doer, address account);
    event PricePerTokenChanged(address doer, uint256 adminTaskId, uint256 oldValue, uint256 newValue);
    event ServiceFeeChanged(address doer, uint256 adminTaskId, uint256 oldValue, uint256 newValue);
    event StageChanged(address doer, uint256 adminTaskId, int256 oldValue, int256 newValue);
    event OperatorAdded(address doer, uint256 adminTaskId, address toBeOperatorAccount);
    event OperatorRemoved(address doer, uint256 adminTaskId, address toBeRemovedOperatorAccount);
    event DefaultTokenURIChanged(address doer, uint256 adminTaskId, string newValue);
    event TokensReserved(address doer, address target, uint256 nrOfTokensToReserve);
    event Deposited(address doer, uint256 priceOfTokens, uint256 serviceFee, uint256 totalValue);
    event Returned(address doer, address target, uint256 returnedValue);
    event Withdrawn(address doer, address target, uint256 amount);
    event TokenURIChanged(address doer, uint256 tokenId, string newValue);
    event GenesisTokenURIChanged(address doer, uint256 adminTaskId, string newValue);
    event RoyaltyWalletChanged(address doer, uint256 adminTaskId, address newRoyaltyWallet);
    event RoyaltyPercentageChanged(address doer, uint256 adminTaskId, uint256 newRoyaltyPercentage);
    event CanReserveWithoutBeingWhitelistedChanged(address doer, uint256 adminTaskId, bool newValue);

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    modifier onlyLockedStage() {
        require(_stage == LOCKED_STAGE, "arteQArtDrop: only callable in locked stage");
        _;
    }

    modifier onlyWhitelistingStage() {
        require(_stage == WHITELISTING_STAGE, "arteQArtDrop: only callable in whitelisting stage");
        _;
    }

    modifier onlyReservationStage() {
        require(_stage == RESERVATION_STAGE, "arteQArtDrop: only callable in reservation stage");
        _;
    }

    modifier onlyReservationAndDistributionStages() {
        require(_stage == RESERVATION_STAGE || _stage == DISTRIBUTION_STAGE, "arteQArtDrop: only callable in reservation and distribution stage");
        _;
    }

    modifier onlyDistributionStage() {
        require(_stage == DISTRIBUTION_STAGE, "arteQArtDrop: only callable in distribution stage");
        _;
    }

    modifier onlyWhenNotLocked() {
        require(_stage > 1, "arteQArtDrop: only callable in not-locked stages");
        _;
    }

    modifier onlyWhenNotInReservationStage() {
        require(_stage != RESERVATION_STAGE, "arteQArtDrop: only callable in a non-reservation stage");
        _;
    }

    modifier onlyOperator() {
        require(_operators[msg.sender] > 0, "arteQArtDrop: not an operator account");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor(
        address adminContract,
        string memory name,
        string memory symbol,
        uint256 initialPricePerToken,
        uint256 initialServiceFee,
        string memory initialDefaultTokenURI,
        string memory initialGenesisTokenURI
    ) ERC721(name, symbol) {

        require(adminContract != address(0), "arteQArtDrop: admin contract cannot be zero");
        require(adminContract.code.length > 0, "arteQArtDrop: non-contract account for admin contract");
        require(initialPricePerToken > 0, "arteQArtDrop: zero initial price per token");
        require(bytes(initialDefaultTokenURI).length > 0, "arteQArtDrop: invalid default token uri");
        require(bytes(initialGenesisTokenURI).length > 0, "arteQArtDrop: invalid genesis token uri");

        _adminContract = adminContract;

        _pricePerToken = initialPricePerToken;
        emit PricePerTokenChanged(msg.sender, 0, 0, _pricePerToken);

        _serviceFee = initialServiceFee;
        emit ServiceFeeChanged(msg.sender, 0, 0, _serviceFee);

        _defaultTokenURI = initialDefaultTokenURI;
        emit DefaultTokenURIChanged(msg.sender, 0, _defaultTokenURI);

        _tokenIdCounter = 1;
        _preMintedTokenIdCounter = 1;
        _contractBalance = 0;

        _whitelistedAccountsCounter = 0;
        _reservedTokensCounter = 0;

        // Contract is locked/read-only by default.
        _stage = 0;
        emit StageChanged(msg.sender, 0, 0, _stage);

        // Mint genesis token. Contract will be the eternal owner of the genesis token.
        _mint(address(0), address(this), 0);
        _setTokenURI(0, initialGenesisTokenURI);
        _contractBalance += 1;
        emit GenesisTokenURIChanged(msg.sender, 0, initialGenesisTokenURI);

        _royaltyWallet = address(this);
        emit RoyaltyWalletChanged(msg.sender, 0, _royaltyWallet);

        _royaltyPercentage = 10;
        emit RoyaltyPercentageChanged(msg.sender, 0, _royaltyPercentage);

        _canReserveWithoutBeingWhitelisted = false;
        emit CanReserveWithoutBeingWhitelistedChanged(msg.sender, 0, _canReserveWithoutBeingWhitelisted);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_exists(tokenId)) {
            string memory tokenURIValue = super.tokenURI(tokenId);
            if (keccak256(bytes(tokenURIValue)) == keccak256(bytes(DEFAULT_TOKEN_URI))) {
                return _defaultTokenURI;
            }
            return tokenURIValue;
        }
        if (tokenId >= 1 && tokenId < _preMintedTokenIdCounter) {
            return _defaultTokenURI;
        }
        revert("arteQArtDrop: token id does not exist");
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (_exists(tokenId)) {
            return super.ownerOf(tokenId);
        }
        if (tokenId >= 1 && tokenId < _preMintedTokenIdCounter) {
            return address(this);
        }
        revert("arteQArtDrop: token is does not exist");
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(this)) {
            return _contractBalance;
        }
        return super.balanceOf(owner);
    }

    function preMint(uint256 nr) external
      onlyOperator {
        for (uint256 i = 0; i < nr; i++) {
            require(_preMintedTokenIdCounter <= MAX_RESERVATIONS_COUNT, "arteQArtDrop: cannot pre-mint more");
            emit Transfer(address(0), address(this), _preMintedTokenIdCounter);
            _preMintedTokenIdCounter += 1;
        }
        _contractBalance += nr;
    }

    function pricePerToken() external view returns (uint256) {
        return _pricePerToken;
    }

    function serviceFee() external view returns (uint256) {
        return _serviceFee;
    }

    function defaultTokenURI() external view returns (string memory) {
        return _defaultTokenURI;
    }

    function nrPreMintedTokens() external view returns (uint256) {
        return _preMintedTokenIdCounter - 1;
    }

    function stage() external view returns (int256) {
        return _stage;
    }

    function royaltyPercentage() external view returns (uint256) {
        return _royaltyPercentage;
    }

    function royaltyWallet() external view returns (address) {
        return _royaltyWallet;
    }

    function nrOfWhitelistedAccounts() external view returns (uint256) {
        return _whitelistedAccountsCounter;
    }

    function nrOfReservedTokens() external view returns (uint256) {
        return _reservedTokensCounter;
    }

    function canReserveWithoutBeingWhitelisted() external view returns (bool) {
        return _canReserveWithoutBeingWhitelisted;
    }

    function setPricePerToken(uint256 adminTaskId, uint256 newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(newValue > 0, "arteQArtDrop: new price cannot be zero");
        uint256 oldValue = _pricePerToken;
        _pricePerToken = newValue;
        emit PricePerTokenChanged(msg.sender, adminTaskId, oldValue, _pricePerToken);
    }

    function setServiceFee(uint256 adminTaskId, uint256 newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(newValue > 0, "arteQArtDrop: new price cannot be zero");
        uint256 oldValue = _serviceFee;
        _serviceFee = newValue;
        emit ServiceFeeChanged(msg.sender, adminTaskId, oldValue, _serviceFee);
    }

    function setDefaultTokenURI(uint256 adminTaskId, string memory newValue) external
      onlyWhenNotLocked
      onlyWhenNotInReservationStage
      adminApprovalRequired(adminTaskId) {
        require(bytes(newValue).length > 0, "arteQArtDrop: empty string");
        _defaultTokenURI = newValue;
        emit DefaultTokenURIChanged(msg.sender, adminTaskId, _defaultTokenURI);
    }

    function setGenesisTokenURI(uint256 adminTaskId, string memory newValue) external
      onlyLockedStage
      adminApprovalRequired(adminTaskId) {
        require(bytes(newValue).length > 0, "arteQArtDrop: empty string");
        _setTokenURI(0, newValue);
        emit GenesisTokenURIChanged(msg.sender, adminTaskId, newValue);
    }

    function setRoyaltyWallet(uint256 adminTaskId, address newRoyaltyWallet) external
      adminApprovalRequired(adminTaskId) {
        require(newRoyaltyWallet != address(0), "arteQArtDrop: invalid royalty wallet");
        _royaltyWallet = newRoyaltyWallet;
        emit RoyaltyWalletChanged(msg.sender, adminTaskId, newRoyaltyWallet);
    }

    function setRoyaltyPercentage(uint256 adminTaskId, uint256 newRoyaltyPercentage) external
      adminApprovalRequired(adminTaskId) {
        require(newRoyaltyPercentage >= 0 && newRoyaltyPercentage <= 75, "arteQArtDrop: invalid royalty percentage");
        _royaltyPercentage = newRoyaltyPercentage;
        emit RoyaltyPercentageChanged(msg.sender, adminTaskId, newRoyaltyPercentage);
    }

    function setCanReserveWithoutBeingWhitelisted(uint256 adminTaskId, bool newValue) external
      adminApprovalRequired(adminTaskId) {
        _canReserveWithoutBeingWhitelisted = newValue;
        emit CanReserveWithoutBeingWhitelistedChanged(msg.sender, adminTaskId, newValue);
    }

    function retreatStage(uint256 adminTaskId) external
      adminApprovalRequired(adminTaskId) {
        int256 oldStage = _stage;
        _stage -= 1;
        if (_stage == -1) {
            _stage = 4;
        } else if (_stage == 1) {
            _stage = 0;
        }
        emit StageChanged(msg.sender, adminTaskId, oldStage, _stage);
    }

    function advanceStage(uint256 adminTaskId) external
      adminApprovalRequired(adminTaskId) {
        int256 oldStage = _stage;
        _stage += 1;
        if (_stage == 5) {
            _stage = 0;
        } else if (_stage == 1) {
            _stage = 2;
        }
        emit StageChanged(msg.sender, adminTaskId, oldStage, _stage);
    }

    function addOperator(uint256 adminTaskId, address toBeOperatorAccount) external
      adminApprovalRequired(adminTaskId) {
        require(toBeOperatorAccount != address(0), "arteQArtDrop: cannot set zero as operator");
        require(_operators[toBeOperatorAccount] == 0, "arteQArtDrop: already an operator");
        _operators[toBeOperatorAccount] = 1;
        emit OperatorAdded(msg.sender, adminTaskId, toBeOperatorAccount);
    }

    function removeOperator(uint256 adminTaskId, address toBeRemovedOperatorAccount) external
      adminApprovalRequired(adminTaskId) {
        require(toBeRemovedOperatorAccount != address(0), "arteQArtDrop: cannot remove zero as operator");
        require(_operators[toBeRemovedOperatorAccount] == 1, "arteQArtDrop: not an operator");
        _operators[toBeRemovedOperatorAccount] = 0;
        emit OperatorRemoved(msg.sender, adminTaskId, toBeRemovedOperatorAccount);
    }

    function isOperator(address account) external view returns(bool) {
        return _operators[account] == 1;
    }

    function addToWhitelistedAccounts(
      address[] memory accounts,
      uint[] memory listOfMaxNrOfTokensToObtain
    ) external
      onlyOperator
      onlyWhitelistingStage {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        require(listOfMaxNrOfTokensToObtain.length > 0, "arteQArtDrop: zero length");
        require(accounts.length == listOfMaxNrOfTokensToObtain.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 maxNrOfTokensToObtain = listOfMaxNrOfTokensToObtain[i];

            require(account != address(0), "arteQArtDrop: cannot whitelist zero address");
            require(maxNrOfTokensToObtain >= 1 && maxNrOfTokensToObtain <= MAX_NR_TOKENS_PER_ACCOUNT,
                "arteQArtDrop: invalid nr of tokens to obtain");
            require(account.code.length == 0, "arteQArtDrop: cannot whitelist a contract");
            require(_whitelistedAccounts[account] == 0, "arteQArtDrop: already whitelisted");

            _whitelistedAccounts[account] = maxNrOfTokensToObtain;
            _whitelistedAccountsCounter += 1;

            emit WhitelistedAccountAdded(msg.sender, account, maxNrOfTokensToObtain);
        }
    }

    function removeFromWhitelistedAccounts(address[] memory accounts) external
      onlyOperator
      onlyWhitelistingStage {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(account != address(0), "arteQArtDrop: cannot remove zero address");
            require(_whitelistedAccounts[account] > 0, "arteQArtDrop: account is not whitelisted");

            _whitelistedAccounts[account] = 0;
            _whitelistedAccountsCounter -= 1;

            emit WhitelistedAccountRemoved(msg.sender, account);
        }
    }

    function whitelistedNrOfTokens(address account) external view returns (uint256) {
        if (!_canReserveWithoutBeingWhitelisted) {
            return _whitelistedAccounts[account];
        }
        if (_whitelistedAccounts[account] == 0) {
            return MAX_NR_TOKENS_PER_ACCOUNT;
        }
        return _whitelistedAccounts[account];
    }

    // Only callable by a whitelisted account
    //
    // * Account must have sent enough ETH to cover the price of all tokens + service fee
    // * Account cannot reserve more than what has been whitelisted for
    function reserveTokens(uint256 nrOfTokensToReserve) external payable
      onlyReservationAndDistributionStages {
        require(msg.value > 0, "arteQArtDrop: zero funds");
        require(nrOfTokensToReserve > 0, "arteQArtDrop: zero tokens to reserve");

        if (_canReserveWithoutBeingWhitelisted && _whitelistedAccounts[msg.sender] == 0) {
            _whitelistedAccounts[msg.sender] = 5;
        }

        require(_whitelistedAccounts[msg.sender] > 0, "arteQArtDrop: not a whitelisted account");
        require(nrOfTokensToReserve <= _whitelistedAccounts[msg.sender],
              "arteQArtDrop: exceeding the reservation allowance");
        require((_reservedTokensCounter + nrOfTokensToReserve) <= MAX_RESERVATIONS_COUNT,
                "arteQArtDrop: exceeding max number of reservations");

        // Handle payments
        uint256 priceOfTokens = nrOfTokensToReserve * _pricePerToken;
        uint256 priceToPay = priceOfTokens + _serviceFee;
        require(msg.value >= priceToPay, "arteQArtDrop: insufficient funds");
        uint256 remainder = msg.value - priceToPay;
        if (remainder > 0) {
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            require(success, "arteQArtDrop: failed to send the remainder");
            emit Returned(msg.sender, msg.sender, remainder);
        }
        emit Deposited(msg.sender, priceOfTokens, _serviceFee, priceToPay);

        _reserveTokens(msg.sender, nrOfTokensToReserve);
    }

    // This method is called by an operator to complete the reservation of fiat payments
    // such as credit card, iDeal, etc.
    function reserveTokensForAccounts(
      address[] memory accounts,
      uint256[] memory listOfNrOfTokensToReserve
    ) external
      onlyOperator
      onlyReservationAndDistributionStages {
        require(accounts.length > 0, "arteQArtDrop: zero length");
        require(listOfNrOfTokensToReserve.length > 0, "arteQArtDrop: zero length");
        require(accounts.length == listOfNrOfTokensToReserve.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 nrOfTokensToReserve = listOfNrOfTokensToReserve[i];

            require(account != address(0), "arteQArtDrop: cannot be zero address");

            if (_canReserveWithoutBeingWhitelisted && _whitelistedAccounts[account] == 0) {
                _whitelistedAccounts[account] = 5;
            }

            require(_whitelistedAccounts[account] > 0, "arteQArtDrop: not a whitelisted account");
            require(nrOfTokensToReserve <= _whitelistedAccounts[account],
                  "arteQArtDrop: exceeding the reservation allowance");

            _reserveTokens(account, nrOfTokensToReserve);
        }
    }

    function updateTokenURIs(uint256[] memory tokenIds, string[] memory newTokenURIs) external
      onlyOperator
      onlyDistributionStage {
        require(tokenIds.length > 0, "arteQArtDrop: zero length");
        require(newTokenURIs.length > 0, "arteQArtDrop: zero length");
        require(tokenIds.length == newTokenURIs.length, "arteQArtDrop: different lengths");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            string memory newTokenURI = newTokenURIs[i];

            require(tokenId > 0, "arteQArtDrop: cannot alter genesis token");
            require(bytes(newTokenURI).length > 0, "arteQArtDrop: empty string");

            _setTokenURI(tokenId, newTokenURI);
            emit TokenURIChanged(msg.sender, tokenId, newTokenURI);
        }
    }

    function transferTo(address target, uint256 amount) external
      onlyOperator {
        require(target != address(0), "arteQArtDrop: target cannot be zero");
        require(amount > 0, "arteQArtDrop: cannot transfer zero");
        require(amount <= address(this).balance, "arteQArtDrop: transfer more than balance");

        (bool success, ) = target.call{value: amount}(new bytes(0));
        require(success, "arteQArtDrop: failed to transfer");

        emit Withdrawn(msg.sender, target, amount);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view virtual override returns (address, uint256) {
        uint256 royalty = (salePrice * _royaltyPercentage) / 100;
        return (_royaltyWallet, royalty);
    }

    function _reserveTokens(address target, uint256 nrOfTokensToReserve) internal {
        for (uint256 i = 1; i <= nrOfTokensToReserve; i++) {
            uint256 newTokenId = _tokenIdCounter;
            _mint(address(this), target, newTokenId);
            _setTokenURI(newTokenId, DEFAULT_TOKEN_URI);
            _tokenIdCounter += 1;
            require(_reservedTokensCounter <= MAX_RESERVATIONS_COUNT,
                    "arteQArtDrop: exceeding max number of reservations");
            _reservedTokensCounter += 1;
        }
        if ((_contractBalance - 1) > nrOfTokensToReserve) {
            _contractBalance -= nrOfTokensToReserve;
        } else {
            _contractBalance = 1; // eventually, the contract must only own the genesis token
        }
        require(_contractBalance >= 1, "arteQArtDrop: contract balance went below 1");
        _whitelistedAccounts[target] -= nrOfTokensToReserve;
        require(_whitelistedAccounts[target] >= 0, "arteQArtDrop: should not happen");
        emit TokensReserved(msg.sender, target, nrOfTokensToReserve);
    }

    receive() external payable {
        revert("arteQArtDrop: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQArtDrop: cannot accept ether");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.0;

import "./ERC721.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: 2B has modified the original code to cover its needs as
  * part of artèQ Investment Fund ecosystem
  *
  * @dev ERC721 token with storage based token URI management.
  */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: 2B has modified the original code to cover its needs as
  * part of artèQ Investment Fund ecosystem
  *
  * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
  * the Metadata extension, but not including the Enumerable extension, which is available separately as
  * {ERC721Enumerable}.
  */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(address(0), to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address from, address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(from, to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
/// @title The interface for finalizing tasks. Mainly used by artèQ contracts to
/// perform administrative tasks in conjuction with admin contract.
interface IarteQTaskFinalizer {

    event TaskFinalized(address finalizer, address origin, uint256 taskId);

    function finalizeTask(address origin, uint256 taskId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}