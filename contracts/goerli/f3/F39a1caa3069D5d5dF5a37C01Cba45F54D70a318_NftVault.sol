// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMerchant.sol";
import "./interfaces/INftVault.sol";

import "./libs/IterableAddressMap.sol";
import "./libs/IterableLock.sol";
import "./libs/UniversalERC20.sol";

contract NftVault is Ownable, INftVault, ReentrancyGuard {
    using IterableLock for ItLock;
    using IterableAddressMap for ItAddressMap;
    using UniversalERC20 for IERC20;

    bool private _canWithdraw = false;
    mapping(address => mapping(uint256 => bool)) private _withdrawDenyList;

    /// @notice total balance for each tokens
    mapping(address => uint256) private _balancePerToken;

    /// @notice ERC20 token balance for each key NFT
    /// NftContractAddress => NftTokenId => ERC20 Token => balance
    mapping(address => mapping(uint256 => mapping(address => ItLock)))
        private _balances;
    mapping(address => mapping(uint256 => ItAddressMap)) private _lockedTokens;

    /// @notice account white list to deposit
    mapping(address => bool) private _accountDepositWL;

    /// @notice token white list to deposit
    mapping(address => bool) private _tokenDepositWL;

    /// @notice deposit fee percentage. denominator 10000
    uint16 private _depositFee = 500;
    /// @notice max deposit fee 10%
    uint16 public constant MAX_DEPOSIT_FEE = 1000;
    /// @notice withdraw fee percentage. denominator 10000
    uint16 private _withdrawFee = 200;
    /// @notice max withdraw fee 10%
    uint16 public constant MAX_WITHDRAW_FEE = 1000;
    /// @notice Array limit in the batch deposit function
    uint256 private _batchDepositLimit = 100;

    /// @notice deposit fee receive wallet address
    address payable private _depositTreasury;
    /// @notice withdraw fee receive wallet address
    address payable private _withdrawTreasury;

    event Deposited(
        address nftAddress,
        uint256 nftTokenId,
        address token,
        uint256 amount,
        uint256 unlockAt
    );
    event Withdrawn(
        address nftAddress,
        uint256 nftTokenId,
        address token,
        uint256 amount,
        address indexed recipient
    );
    event PaymentMade(
        address nftAddress,
        uint256 nftTokenId,
        address token,
        uint256 amountPaid,
        uint256 amountFromVault,
        string paymentId
    );
    event RecoverWrongToken(address token, uint256 amount);

    /// @notice Constructor function with deposit / withdraw treasury addresses
    constructor(
        address payable depositTreasury_,
        address payable withdrawTreasury_
    ) {
        require(
            depositTreasury_ != address(0) && withdrawTreasury_ != address(0),
            "Invalid treasury"
        );
        _depositTreasury = depositTreasury_;
        _withdrawTreasury = withdrawTreasury_;
    }

    /// @notice Return tokens locked in this nft token id
    /// @param nftAddress_ NFT contract address to fetch
    /// @param nftTokenId_ NFT Token ID to fetch
    /// @return tokens Token list locked in this nft token id
    function lockedTokens(address nftAddress_, uint256 nftTokenId_)
        external
        view
        override
        returns (address[] memory tokens)
    {
        return _lockedTokens[nftAddress_][nftTokenId_].keys;
    }

    /// @notice View locked data of nft token id + locked token
    /// @param nftAddress_ NFT contract address
    /// @param nftTokenId_ NFT token ID
    /// @param token_ Locked token
    /// @return unlockDates Array of lock end dates
    /// @return amounts Array of locked amounts
    function viewLock(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_
    )
        external
        view
        returns (uint256[] memory unlockDates, uint256[] memory amounts)
    {
        ItLock storage itLock = _balances[nftAddress_][nftTokenId_][token_];
        unlockDates = new uint256[](0);
        amounts = new uint256[](0);
        if (_lockedTokens[nftAddress_][nftTokenId_].contains(token_)) {
            unlockDates = itLock.keys;
            amounts = new uint256[](unlockDates.length);
            for (uint256 i = 0; i < unlockDates.length; i++) {
                amounts[i] = itLock.data[unlockDates[i]];
            }
        }
    }

    /**
     * @notice check all token balances of key NFT
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT token ID
     * @param balanceType_ Type to fetch balance: unlocked only(0) / locked only(1) / all (2)
     * @return tokens token list that of key NFT
     * @return balances balance list of key NFT
     */
    function balanceOf(
        address nftAddress_,
        uint256 nftTokenId_,
        uint8 balanceType_
    )
        public
        view
        override
        returns (address[] memory tokens, uint256[] memory balances)
    {
        tokens = _lockedTokens[nftAddress_][nftTokenId_].keys;
        balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokens[i];
            balances[i] = balanceOf(
                nftAddress_,
                nftTokenId_,
                tokens[i],
                balanceType_
            );
        }
    }

    /**
     * @notice check specified token balance of key NFT
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT token ID
     * @param balanceType_ Type to fetch balance: unlocked only(0) / locked only(1) / all (2)
     * @return balance token balance of key NFT
     */
    function balanceOf(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint8 balanceType_
    ) public view override returns (uint256 balance) {
        ItLock storage itLock = _balances[nftAddress_][nftTokenId_][token_];
        uint256 curTime = block.timestamp;
        for (uint256 i = 0; i < itLock.keys.length; i++) {
            if (balanceType_ == 0 && itLock.keys[i] <= curTime) {
                // Add unlocked balance only
                balance += itLock.data[itLock.keys[i]];
            } else if (balanceType_ == 1 && itLock.keys[i] > curTime) {
                // Add locked balance only
                balance += itLock.data[itLock.keys[i]];
            } else if (balanceType_ == 2) {
                // Add all balance
                balance += itLock.data[itLock.keys[i]];
            }
        }
    }

    /// @notice Return total balance of the token deposited for nfts
    /// @param token_ Token address
    function balanceOf(address token_) external view returns (uint256) {
        return _balancePerToken[token_];
    }

    /**
     * @notice deposit to vault
     * allow from Slash Extension Contract only
     * Supported NFT is ERC721 only
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT contract token ID
     * @param token_ ERC20 token contract address to deposit
     * @param amount_ deposit amount
     * @param unlockAt_ the time until the deposited token is locked
     */
    function deposit(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint256 amount_,
        uint256 unlockAt_
    ) external payable override {
        uint256 txTokenAmount = _deposit(
            nftAddress_,
            nftTokenId_,
            token_,
            amount_,
            unlockAt_
        );
        if (IERC20(token_).isETH())
            IERC20(token_).universalTransferFrom(
                msg.sender,
                address(this),
                txTokenAmount
            );
    }

    /**
     * @notice batch deposit to vault
     * allow from Slash Extension Contract only
     * Supported NFT is ERC721 only
     * @param nftAddresses_ key NFT contract addresses
     * @param nftTokenIds_ key NFT contract token IDs
     * @param token_ ERC20 token contract address to deposit
     * @param amounts_ deposit amounts
     * @param unlockAts_ the time until the deposited tokens are locked
     */
    function batchDeposit(
        address[] memory nftAddresses_,
        uint256[] memory nftTokenIds_,
        address token_,
        uint256[] memory amounts_,
        uint256[] memory unlockAts_
    ) external payable override {
        require(nftAddresses_.length <= _batchDepositLimit, "Too big array");
        uint256 txTokenAmount = 0;
        for (uint256 i = 0; i < nftAddresses_.length; i++) {
            txTokenAmount += _deposit(
                nftAddresses_[i],
                nftTokenIds_[i],
                token_,
                amounts_[i],
                unlockAts_[i]
            );
        }
        if (IERC20(token_).isETH())
            IERC20(token_).universalTransferFrom(
                msg.sender,
                address(this),
                txTokenAmount
            );
    }

    /// @notice Handle deposit process per each request
    /// @return :deposit amount + fee amount, this is for handling batch ETH deposit
    function _deposit(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint256 amount_,
        uint256 unlockAt_
    ) internal nonReentrant returns (uint256) {
        IERC721 nft = IERC721(nftAddress_);
        require(nft.supportsInterface(0x80ac58cd), "it's not ERC721");
        updateLock(nftAddress_, nftTokenId_, token_);

        bool whitelisted = _accountDepositWL[msg.sender] ||
            _tokenDepositWL[token_];
        uint256 feeAmount = 0;
        // Deposit fee is applied for the account which is not whitelisted and the tokenis not whitelisted
        if (!whitelisted) feeAmount = (amount_ * _depositFee) / 10000;

        uint256 balanceBefore = IERC20(token_).universalBalanceOf(
            address(this)
        );

        // In case of ETH, handled after returned from this function, because of batch deposit
        if (!IERC20(token_).isETH())
            IERC20(token_).universalTransferFrom(
                msg.sender,
                address(this),
                amount_ + feeAmount
            );

        // Fee is transferred to the deposit fee wallet
        if (!whitelisted)
            IERC20(token_).universalTransfer(_depositTreasury, feeAmount);

        uint256 deposited = IERC20(token_).isETH()
            ? amount_
            : IERC20(token_).universalBalanceOf(address(this)) - balanceBefore;

        ItLock storage itLock = _balances[nftAddress_][nftTokenId_][token_];
        ItAddressMap storage itAddressMap = _lockedTokens[nftAddress_][
            nftTokenId_
        ];
        itLock.insert(unlockAt_, deposited);
        itAddressMap.insert(token_);
        _balancePerToken[token_] += deposited;

        emit Deposited(nftAddress_, nftTokenId_, token_, deposited, unlockAt_);

        return amount_ + feeAmount;
    }

    /// @notice Check if the lock time expired for the deposits and unlock the avaiable.
    function updateLock(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_
    ) internal {
        ItLock storage itLock = _balances[nftAddress_][nftTokenId_][token_];
        itLock.removeExpired(block.timestamp);
    }

    /**
     * @notice withdraw ERC20 token from NftVault contract
     * msg.sender should own key NFT
     * recipient is msg.sender
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT token ID
     * @param token_ withdraw token contract address
     * @param amount_ withdraw amount
     */
    function withdraw(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint256 amount_
    ) external override {
        _withdraw(nftAddress_, nftTokenId_, token_, amount_, msg.sender);
    }

    /**
     * @notice withdraw ERC20 token from NftVault contract
     * msg.sender should own key NFT
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT token ID
     * @param token_ withdraw token contract address
     * @param amount_ withdraw amount
     * @param recipient_ recipient
     */
    function withdraw(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint256 amount_,
        address recipient_
    ) external override {
        _withdraw(nftAddress_, nftTokenId_, token_, amount_, recipient_);
    }

    function _withdraw(
        address nftAddress_,
        uint256 nftTokenId_,
        address token_,
        uint256 amount_,
        address recipient_
    ) internal {
        require(canWithdraw(nftAddress_, nftTokenId_), "cannot withdraw");
        require(_isOwned(nftAddress_, nftTokenId_), "you are not own this NFT");
        updateLock(nftAddress_, nftTokenId_, token_);
        ItLock storage itLock = _balances[nftAddress_][nftTokenId_][token_];

        require(
            itLock.data[IterableLock.BASE_KEY] >= amount_, // Unlocked amount should be more than withdraw amount
            "Not available amount"
        );

        uint256 fee = 0;
        if (_withdrawFee > 0) {
            fee = (amount_ * _withdrawFee) / 10000;
        }

        IERC20(token_).universalTransfer(_withdrawTreasury, fee);
        IERC20(token_).universalTransfer(recipient_, amount_ - fee);

        itLock.remove(IterableLock.BASE_KEY, amount_);
        // If this token does not have amount left per this nft id, remove it from lockedTokens list
        if (itLock.empty())
            _lockedTokens[nftAddress_][nftTokenId_].remove(token_);

        _balancePerToken[token_] -= amount_;

        emit Withdrawn(nftAddress_, nftTokenId_, token_, amount_, recipient_);
    }

    /**
     * @notice payment using SlashProtocol
     * flow:
     * 1. transfer payingToken from payer to vault if insufficient balance
     * 2. call submitTransaction on Slash
     * @param info_ payment info
     * @return txNumber Transaction number
     */
    function payment(PaymentInfo memory info_)
        external
        payable
        override
        returns (bytes16 txNumber)
    {
        require(
            _isOwned(info_.nftAddress, info_.nftTokenId),
            "you are not NFT owner"
        );
        updateLock(info_.nftAddress, info_.nftTokenId, info_.payingToken);
        /// Fee amount from the merchant contract
        (uint256 taxFeeAmount, uint256 donationFeeAmount) = IMerchant(
            info_.slashContract
        ).getFeeAmount(info_.requiredAmountOut, info_.feePath, info_.reserved);
        ItLock storage itLock = _balances[info_.nftAddress][info_.nftTokenId][
            info_.payingToken
        ];

        // Amount paid from valut to make payment in slash protocol
        uint256 amountPaidFromVault = 0;
        // Amount to be passed to msg.value, at least fee amount (plus more needed amount in case of ETH payingToken)
        uint256 msgValue = taxFeeAmount + donationFeeAmount;
        // Unlocked balance in the vault for this nft + token
        uint256 unlockedBalance = itLock.data[IterableLock.BASE_KEY];
        /// Transfer more amount from msg.sender when unlocked balance less than paying amount
        /// It should be failed when there is not enough amount or not approved in the user account
        if (info_.amountIn > unlockedBalance) {
            amountPaidFromVault = unlockedBalance;
            if (IERC20(info_.payingToken).isETH()) {
                // Add to msgValue in case of ETH paying
                msgValue += info_.amountIn - amountPaidFromVault;
            } else {
                IERC20(info_.payingToken).universalTransferFrom(
                    msg.sender,
                    address(this),
                    info_.amountIn - amountPaidFromVault
                );
            }
        } else {
            amountPaidFromVault = info_.amountIn;
        }

        itLock.remove(IterableLock.BASE_KEY, amountPaidFromVault);
        _balancePerToken[info_.payingToken] -= amountPaidFromVault;
        // If this token does not have amount left per this nft id, remove it from lockedTokens list
        if (itLock.empty())
            _lockedTokens[info_.nftAddress][info_.nftTokenId].remove(
                info_.payingToken
            );

        // ETH should be transferred at least for the fee amount, so this function should be called always
        // in case of ETH paying, msgValue includes more required amount as well, see above
        UniversalERC20.ETH_ADDRESS.universalTransferFrom(
            msg.sender,
            address(this),
            msgValue
        );

        // Submit transaction to slash protocol
        IERC20(info_.payingToken).universalApprove(
            info_.slashContract,
            info_.amountIn
        );

        txNumber = submitSlashPayment(taxFeeAmount + donationFeeAmount, info_);

        emit PaymentMade(
            info_.nftAddress,
            info_.nftTokenId,
            info_.payingToken,
            info_.amountIn,
            amountPaidFromVault,
            info_.paymentId
        );
    }

    function submitSlashPayment(uint256 feeAmount_, PaymentInfo memory info_)
        private
        returns (bytes16 txNumber)
    {
        txNumber = IMerchant(info_.slashContract).submitTransaction{
            value: IERC20(info_.payingToken).isETH()
                ? info_.amountIn + feeAmount_
                : feeAmount_
        }( // fee amount, plus amountIn in case of ETH paying
            info_.payingToken,
            info_.amountIn,
            info_.requiredAmountOut,
            info_.path,
            info_.feePath,
            info_.paymentId,
            info_.optional,
            info_.reserved
        );
    }

    /**
     * @notice check sender owned key NFT or not
     * @param nftAddress_ key NFT contract address
     * @param nftTokenId_ key NFT token ID
     * @return owned sender owned key NFT: true
     */
    function _isOwned(address nftAddress_, uint256 nftTokenId_)
        internal
        view
        returns (bool owned)
    {
        IERC721 nft = IERC721(nftAddress_);
        require(nft.supportsInterface(0x80ac58cd), "it's not ERC721");
        owned = nft.ownerOf(nftTokenId_) == msg.sender;
    }

    /**
     * @notice recover wrong token
     * owner can withdraw token nobady own
     * @param token_ withdraw token contract address
     */
    function recoverWrongToken(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).universalBalanceOf(address(this));
        /// @notice It should be failed when users' deposited amount is same as total balance
        uint256 withdrawable = balance - _balancePerToken[token_];

        IERC20(token_).universalTransfer(msg.sender, withdrawable);

        emit RecoverWrongToken(token_, withdrawable);
    }

    /// @notice Update limit of the array in the batch deposit function
    /// @dev Only owner is allowed to call this function
    function updateBatchDepositLimit(uint256 limit_) external onlyOwner {
        _batchDepositLimit = limit_;
    }

    function batchDepositLimit() external view returns (uint256) {
        return _batchDepositLimit;
    }

    /**
     * @notice Whitelist account for the deposit
     * @param account_ from address (contract / wallet)
     * @param permit_ pay deposit tax fee or not
     */
    function whitelistAccountDeposit(address account_, bool permit_)
        external
        onlyOwner
    {
        require(account_ != address(0), "invalid address");
        require(permit_ != _accountDepositWL[account_], "not changed");
        _accountDepositWL[account_] = permit_;
    }

    function accountDepositWhitelisted(address account_)
        external
        view
        returns (bool)
    {
        return _accountDepositWL[account_];
    }

    /**
     * @notice Whitelist token for the deposit
     * @param token_ token address to be whitelisted
     * @param permit_ whitelist or not
     */
    function whitelistTokenDeposit(address token_, bool permit_)
        external
        onlyOwner
    {
        require(permit_ != _tokenDepositWL[token_], "not changed");
        _tokenDepositWL[token_] = permit_;
    }

    function tokenDepositWhitelisted(address token_)
        external
        view
        returns (bool)
    {
        return _tokenDepositWL[token_];
    }

    /**
     * @notice update treasury wallet to receive deposit fee
     * @param wallet_ fee receive address
     */
    function updateDepositTreasury(address payable wallet_) external onlyOwner {
        require(wallet_ != address(0), "invalid address");
        _depositTreasury = wallet_;
    }

    function depositTreasury() external view returns (address payable) {
        return _depositTreasury;
    }

    /**
     * @notice update deposit fee percentage
     * @param fee_ deposit fee percentage (denominator 10000)
     * up to 1000 (10%)
     */
    function updateDepositFee(uint16 fee_) external onlyOwner {
        require(fee_ <= MAX_DEPOSIT_FEE, "up to 10%");
        _depositFee = fee_;
    }

    function depositFee() external view returns (uint16) {
        return _depositFee;
    }

    /**
     * @notice update treasury wallet to receive withdraw fee
     * @param wallet_ fee receive address
     */
    function updateWithdrawTreasury(address payable wallet_)
        external
        onlyOwner
    {
        require(wallet_ != address(0), "invalid address");
        _withdrawTreasury = wallet_;
    }

    function withdrawTreasury() external view returns (address payable) {
        return _withdrawTreasury;
    }

    /**
     * @notice update withdraw fee percentage
     * @param fee_ withdraw fee percentage (denominator 10000)
     * up to 1000 (10%)
     */
    function updateWithdrawFee(uint16 fee_) external onlyOwner {
        require(fee_ <= MAX_WITHDRAW_FEE, "up to 10%");
        _withdrawFee = fee_;
    }

    function withdrawFee() external view returns (uint16) {
        return _withdrawFee;
    }

    /**
     * @notice Enable / disable withdraw globally
     * @param canWithdraw_ use can withdraw or not
     */
    function enableWithdraw(bool canWithdraw_) external onlyOwner {
        require(_canWithdraw != canWithdraw_, "not changed");
        _canWithdraw = canWithdraw_;
    }

    /**
     * @notice Enable / disable withdraw for indivisual nft token
     * @param nftAddress_ NFT address
     * @param tokenId_ Token id
     * @param canWithdraw_ enable / disable flag
     */
    function enableWithdraw(
        address nftAddress_,
        uint256 tokenId_,
        bool canWithdraw_
    ) external onlyOwner {
        require(
            _withdrawDenyList[nftAddress_][tokenId_] == canWithdraw_,
            "not changed"
        );
        _withdrawDenyList[nftAddress_][tokenId_] = !canWithdraw_;
    }

    /**
     * @notice Batch enable / disable withdraw for indivisual nft token
     * @param nftAddresses_ NFT addresses
     * @param tokenIds_ Token id
     * @param canWithdraw_ enable / disable flag
     */
    function enableWithdraw(
        address[] memory nftAddresses_,
        uint256[] memory tokenIds_,
        bool canWithdraw_
    ) external onlyOwner {
        for (uint256 i = 0; i < nftAddresses_.length; i++) {
            _withdrawDenyList[nftAddresses_[i]][tokenIds_[i]] = !canWithdraw_;
        }
    }

    /// @notice Check global withdraw permission
    function canWithdraw() external view returns (bool) {
        return _canWithdraw;
    }

    /// @notice Check withdraw permission for the nft token
    function canWithdraw(address nftAddress_, uint256 tokenId_)
        public
        view
        returns (bool)
    {
        return _canWithdraw && !_withdrawDenyList[nftAddress_][tokenId_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ItAddressMap {
    // address => index
    mapping(address => uint256) indexs;
    // array of address
    address[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableAddressMap {
    function insert(ItAddressMap storage self, address key) internal {
        uint256 keyIndex = self.indexs[key];
        if (keyIndex > 0) return;
        else {
            self.indexs[key] = self.keys.length + 1;
            self.keys.push(key);
            return;
        }
    }

    function remove(ItAddressMap storage self, address key) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return;
        address lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.indexs[key];
        self.keys.pop();
    }

    function contains(ItAddressMap storage self, address key)
        internal
        view
        returns (bool)
    {
        return self.indexs[key] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftVault {
    /**
     * @notice Payment Info structure to call payment function
     * @param nftAddress_ paying NFT Address
     * @param nftTokenId_ paying NFT Token ID
     * @param slashContract_ merchant contract to pay
     * @param payingToken_ paying Token Address
     * @param amountIn_ payment amount by paying token
     * @param requiredAmountOut_ payment amount by receive token
     * @param path_ swap path / paying token to receive token
     * @param feePath_ swap path / paying token to native token
     * @param paymentId_ payment id, this param will pass to merchant (if merchant received by contract)
     * @param optional_: optional data, this param will pass to merchant (if merchant received by contract)
     * @param reserved_: reserved parameter
     */
    struct PaymentInfo {
        address nftAddress;
        uint256 nftTokenId;
        address slashContract;
        address payingToken;
        uint256 amountIn;
        uint256 requiredAmountOut;
        address[] path;
        address[] feePath;
        string paymentId;
        string optional;
        bytes reserved; /** reserved */
    }

    /// @notice Return tokens locked in this nft token id
    /// @param nftAddress_ NFT contract address to fetch
    /// @param nftTokenId_ NFT Token ID to fetch
    /// @return tokens Token list locked in this nft token id
    function lockedTokens(address nftAddress_, uint256 nftTokenId_)
        external
        view
        returns (address[] memory tokens);

    /**
     * @notice check all token balances of key NFT
     * @param _nftAddress key NFT contract address
     * @param _nftTokenId key NFT token ID
     * @param balanceType_ Type to fetch balance: unlocked only(0) / locked only(1) / all (2)
     * @return tokens token list that of key NFT
     * @return balances balance list of key NFT
     */
    function balanceOf(
        address _nftAddress,
        uint256 _nftTokenId,
        uint8 balanceType_
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory balances);

    /**
     * @notice check specified token balance of key NFT
     * @param _nftAddress key NFT contract address
     * @param _nftTokenId key NFT token ID
     * @param balanceType_ Type to fetch balance: unlocked only(0) / locked only(1) / all (2)
     * @return balance token balance of key NFT
     */
    function balanceOf(
        address _nftAddress,
        uint256 _nftTokenId,
        address _token,
        uint8 balanceType_
    ) external view returns (uint256 balance);

    /**
     * @notice deposit to vault
     * allow from Slash Extension Contract only
     * Supported NFT is ERC721 only
     * @param _nftAddress key NFT contract address
     * @param _nftTokenId key NFT contract token ID
     * @param _token ERC20 token contract address to deposit
     * @param _amount deposit amount
     * @param _unlockAt the time until the deposited token is locked
     */
    function deposit(
        address _nftAddress,
        uint256 _nftTokenId,
        address _token,
        uint256 _amount,
        uint256 _unlockAt
    ) external payable;

    /**
     * @notice batch deposit to vault
     * allow from Slash Extension Contract only
     * Supported NFT is ERC721 only
     * @param _nftAddresses key NFT contract addresses
     * @param _nftTokenIds key NFT contract token IDs
     * @param _token ERC20 token contract address to deposit
     * @param _amounts deposit amounts
     * @param _unlockAts the time until the deposited tokens are locked
     */
    function batchDeposit(
        address[] memory _nftAddresses,
        uint256[] memory _nftTokenIds,
        address _token,
        uint256[] memory _amounts,
        uint256[] memory _unlockAts
    ) external payable;

    /**
     * @notice withdraw ERC20 token from NftVault contract
     * msg.sender should own key NFT
     * recipient is msg.sender
     * @param _nftAddress key NFT contract address
     * @param _nftTokenId key NFT token ID
     * @param _token withdraw token contract address
     * @param _amount withdraw amount
     */
    function withdraw(
        address _nftAddress,
        uint256 _nftTokenId,
        address _token,
        uint256 _amount
    ) external;

    /**
     * @notice withdraw ERC20 token from NftVault contract
     * msg.sender should own key NFT
     * @param _nftAddress key NFT contract address
     * @param _nftTokenId key NFT token ID
     * @param _token withdraw token contract address
     * @param _amount withdraw amount
     * @param _recipient recipient
     */
    function withdraw(
        address _nftAddress,
        uint256 _nftTokenId,
        address _token,
        uint256 _amount,
        address _recipient
    ) external;

    /**
     * @notice payment using SlashProtocol
     * @param info_ payment info
     * @return txNumber Transaction number
     */
    function payment(PaymentInfo memory info_)
        external
        payable
        returns (bytes16 txNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ItLock {
    // unlock time => amount
    mapping(uint256 => uint256) data;
    // unlock time => index
    mapping(uint256 => uint256) indexs;
    // array of unlock time
    uint256[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableLock {
    /// @notice Max 5 locks can be stored
    uint256 public constant MAX_LOCK_COUNT = 5;
    /// @notice The key for storing unlocked data
    uint256 public constant BASE_KEY = 0;

    function insert(
        ItLock storage self,
        uint256 key,
        uint256 value
    ) internal {
        if (key <= block.timestamp) key = BASE_KEY; // For the expired key, we set it as BASE_KEY
        // We should always keep key 0 at the first position of the key array
        if (key != BASE_KEY && self.keys.length == 0) {
            self.keys.push(BASE_KEY);
            self.indexs[BASE_KEY] = 1;
        }

        uint256 keyIndex = self.indexs[key];
        self.data[key] += value; // value is added to the existing unlock time
        if (keyIndex > 0) return;
        // When the key not exists, add it
        self.indexs[key] = self.keys.length + 1;
        self.keys.push(key);
        require(self.keys.length <= MAX_LOCK_COUNT, "Too many locks");
    }

    function update(
        ItLock storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 keyIndex = self.indexs[key];
        if (keyIndex == 0) return;
        self.data[key] = value; // value is updated for the existing unlock time
    }

    /// @notice Remove amount from the key
    function remove(
        ItLock storage self,
        uint256 key,
        uint256 amount
    ) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return; // If the key not exists, just return
        self.data[key] -= amount;
        // If BASE_KEY or amount is still remained, return
        if (key == BASE_KEY || self.data[key] > 0) return;

        // If no amount, then remove this key
        uint256 lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.indexs[key];
        self.keys.pop();
    }

    /// @notice Remove all expired keys, and add value to the key 0
    function removeExpired(ItLock storage self, uint256 criteria) internal {
        for (uint256 i = self.keys.length; i > 1; i--) {
            // We do not check key 0 which stores unlocked data
            // Iterate from the last key
            uint256 key = self.keys[i - 1];
            if (key > criteria) continue; // Skip for the non-expired keys

            // First replace expired key with the last key, and then remove expired one
            uint256 lastKey = self.keys[self.keys.length - 1];
            if (key != lastKey) {
                self.keys[i - 1] = lastKey;
                self.indexs[lastKey] = i;
            }
            self.data[BASE_KEY] += self.data[key]; // The data of the expired key is added to the key 0's
            delete self.data[key];
            delete self.indexs[key];
            self.keys.pop();
        }
    }

    function empty(ItLock storage self) internal view returns (bool) {
        return self.keys.length == 1 && self.data[BASE_KEY] == 0;
    }

    function contains(ItLock storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.indexs[key] > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMerchant {
    function submitTransaction(
        address payingToken,
        uint256 amountIn,
        uint256 requiredAmountOut,
        address[] memory path,
        address[] memory feePath,
        string memory paymentId,
        string memory optional,
        bytes memory reserved /** reserved */
    ) external payable returns (bytes16 txNumber);

    function getFeeAmount(
        uint256 amountOut,
        address[] memory feePath,
        bytes memory reserved /** reserved */
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// File: contracts/UniversalERC20.sol
/**
 * @notice Library for wrapping ERC20 token and ETH
 * @dev It uses msg.sender directly so only use in normal contract, not in GSN-like contract
 */
library UniversalERC20 {
    using SafeERC20 for IERC20;

    IERC20 internal constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 internal constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            (bool sent, ) = payable(address(uint160(to))).call{value: amount}(
                ""
            );
            require(sent, "Send ETH failed");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(
                from == msg.sender && msg.value >= amount,
                "Wrong usage of ETH.universalTransferFrom()"
            );
            if (to != address(this)) {
                (bool sent, ) = payable(address(uint160(to))).call{
                    value: amount
                }("");
                require(sent, "Send ETH failed");
            }
            if (msg.value > amount) {
                // refund redundant amount
                (bool sent, ) = payable(msg.sender).call{
                    value: msg.value - amount
                }("");
                require(sent, "Send-back ETH failed");
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(
        IERC20 token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                (bool sent, ) = payable(msg.sender).call{
                    value: msg.value - amount
                }("");
                require(sent, "Send-back ETH failed");
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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

    constructor () {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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