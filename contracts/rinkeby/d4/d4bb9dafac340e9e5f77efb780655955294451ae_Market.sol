// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./IVault.sol";
import "./Detector.sol";
import "./RentaFiSVG.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Detailed {
    function symbol() external view returns (string memory);
}

contract Market is ERC721, ERC721Burnable, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Detector for address;
    Counters.Counter private totalLended;
    Counters.Counter private totalRented;

    constructor() ERC721("RentaFi Yield NFT", "RentaFi-YN") {}

    event Listed(uint256 indexed lockId, address indexed lender, Lend lend);
    event Rented(uint256 indexed rentId, address indexed renter, uint256 lockId, Rent rent);
    event Canceled(uint256 indexed lockId);

    uint256 private constant E5 = 1e5;
    uint256 public protocolAdminFeeRatio = 10 * 1000;
    uint256 public reservationLimits = 10 days;

    // lockId => LendRent
    mapping(uint256 => LendRent) public lendRent;
    // lockId => privateAddress
    mapping(uint256 => address) public privateList;
    // vaultAddress => allowed
    mapping(address => bool) public vaultWhiteList;
    address[] internal vaults;

    // lockId => paymentToken =>lenderBenefit
    mapping(uint256 => mapping(address => uint256)) public lenderBenefit;
    // vaultAddress => paymentToken =>collectionOwnerBenefit
    mapping(address => mapping(address => uint256)) public collectionOwnerBenefit;
    // paymentToken => protocolAdminBenefit
    mapping(address => uint256) public protocolAdminBenefit;
    address[] private paymentTokens;

    // For frontend
    mapping(address => uint256[]) internal lenderLockIds; // lender => lockId[]
    mapping(address => uint256[]) internal renterLockIds; // renter => lockId[]
    mapping(address => uint256[]) internal vaultLockIds; // vault => lockId[]
    mapping(address => mapping(uint256 => uint256[])) internal tokensLockId; // collectionAddress, tokenId => lockId

    enum LockIdTarget {
        Lender,
        Renter,
        Vault,
        Token
    }

    enum ListType {
        Public,
        Private,
        Event
    }

    enum PaymentMethod {
        OneTime,
        Loan,
        BNPL,
        Subscription
    }

    /*
     * Market only returns data for listings
     * Original NFT is in the Vault contract
     */
    struct Lend {
        uint256 lockStartTime;
        uint256 lockExpireTime;
        uint256 minRentalDuration; // days
        uint256 maxRentalDuration; // days
        uint256 dailyRentalPrice; // wei
        uint256 tokenId;
        uint256 amount; // for ERC1155
        address vault;
        address paymentToken;
        address lender;
        ListType listType;
        PaymentMethod paymentMethod;
    }

    struct Rent {
        address renterAddress;
        uint256 rentId;
        uint256 rentalStartTime;
        uint256 rentalExpireTime;
        uint256 amount;
    }

    struct LendRent {
        Lend lend;
        Rent[] rent;
    }

    modifier onlyLender(uint256 _lockId) {
        require(lendRent[_lockId].lend.lender == _msgSender(), "You are not Lender");
        _;
    }

    modifier onlyCollectionOwner(address _vaultAddress) {
        // CollectionOwner is the person who deployed the Vault from the Factory
        require(_msgSender() == IVault(_vaultAddress).collectionOwner(), "onlyCollectionOwner");
        _;
    }

    modifier onlyProtocolAdmin() {
        require(owner() == _msgSender(), "onlyProtocolAdmin");
        _;
    }

    modifier onlyONftOwner(uint256 _lockId) {
        require(IVault(lendRent[_lockId].lend.vault).ownerOf(_lockId) == _msgSender(), "onlyONftOwner");
        _;
    }

    modifier onlyYNftOwner(uint256 _lockId) {
        require(ownerOf(_lockId) == _msgSender(), "onlyYNftOwner");
        _;
    }

    modifier onlyBeforeLock(uint256 _lockId) {
        require(
            lendRent[_lockId].lend.lockStartTime == lendRent[_lockId].lend.lockExpireTime ||
                lendRent[_lockId].rent.length == 0,
            "onlyBeforeLock"
        );
        _;
    }

    modifier onlyAfterLockExpired(uint256 _lockId) {
        require(block.timestamp > lendRent[_lockId].lend.lockExpireTime, "onlyAfterLockExpired");
        _;
    }

    modifier onlyNotRentaled(uint256 _lockId) {
        Rent[] storage _rents = lendRent[_lockId].rent;
        for (uint256 i = 0; i < _rents.length; i++) _deleteLockId(renterLockIds, _rents[i].renterAddress, _lockId);
        _deleteExpiredRent(_rents);
        require(_rents.length == 0, "onlyNotRentaled");
        _;
    }

    //@params _tokenId: if you do not use tokenId it could be Zero.
    function getLockIds(LockIdTarget _target, address _address, uint256 _tokenId) external view returns (uint256[] memory) {
        if (_target == LockIdTarget.Lender) return lenderLockIds[_address];
        if (_target == LockIdTarget.Renter) return renterLockIds[_address];
        if (_target == LockIdTarget.Vault) return vaultLockIds[_address];
        if (_target == LockIdTarget.Token) return tokensLockId[_address][_tokenId];
        revert();
    }

    function _addLockId(
        mapping(address => uint256[]) storage _map,
        address _target,
        uint256 _lockId
    ) internal {
        uint256[] storage _lockIds = _map[_target];
        bool _exists = false;
        for (uint256 i = 0; i < _lockIds.length; i++) {
            if (_lockIds[i] == _lockId) {
                _exists = true;
                break;
            }
        }
        if (!_exists) _lockIds.push(_lockId);
    }

    function _deleteLockId(
        mapping(address => uint256[]) storage _map,
        address _target,
        uint256 _lockId
    ) internal {
        uint256[] storage _lockIds = _map[_target];
        for (uint256 i = 0; i < _lockIds.length; i++) {
            if (_lockIds[i] == _lockId) {
                if (i != _lockIds.length - 1) {
                    _lockIds[i] = _lockIds[_lockIds.length - 1];
                }
                _lockIds.pop();
                break;
            }
        }
    }

    function _deleteExpiredRent(Rent[] storage _rents) internal {
        for (uint256 i = 1; i <= _rents.length; i++) {
            if (_rents[i - 1].rentalExpireTime < block.timestamp) {
                if (_rents[_rents.length - 1].rentalExpireTime >= block.timestamp) {
                    _rents[i - 1] = _rents[_rents.length - 1];
                } else {
                    i--;
                }
                _rents.pop();
            }
        }
    }

    function _isPaymentTokenAllowed(address _vaultAddress, address _paymentToken) internal view returns (bool) {
        bool _allowed = false;
        address[] memory _paymentTokens = IVault(_vaultAddress).getPaymentTokens();
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            if (_paymentTokens[i] == _paymentToken) {
                _allowed = true;
                break;
            }
        }
        return _allowed;
    }

    function setReservationLimit(uint256 _days) public onlyProtocolAdmin {
        reservationLimits = _days * 1 days;
    }

    function setVaultWhiteList(address _vaultAddress, bool allowed) external onlyProtocolAdmin {
        if (allowed) {
            vaultWhiteList[_vaultAddress] = allowed;
        } else {
            delete vaultWhiteList[_vaultAddress];
        }
        bool _exists = false;
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == _vaultAddress) {
                _exists = true;
                break;
            }
        }
        if (!_exists) vaults.push(_vaultAddress);
    }

    function setProtocolAdminFeeRatio(uint256 _protocolAdminFeeRatio) external onlyProtocolAdmin {
        bool _exceeds = false;
        for (uint256 i = 0; i < vaults.length; i++) {
            if (IVault(vaults[i]).collectionOwnerFeeRatio() + _protocolAdminFeeRatio > 100 * 1000) {
                _exceeds = true;
                break;
            }
        }
        require(!_exceeds, "total Fee is over 100%");
        protocolAdminFeeRatio = _protocolAdminFeeRatio;
    }

    // Getters that are set automatically do not return arrays in the structure, so this must be specified explicitly
    function getLendRent(uint256 _lockId) external view returns (LendRent memory) {
        return lendRent[_lockId];
    }

    // Deposit the NFT into an escrow contract.
    function mintAndCreateList(
        uint256 _tokenId, // ID of the NFT you wish to loan out
        uint256 _lockDuration, // days
        uint256 _minRentalDuration, // days
        uint256 _maxRentalDuration, // days
        uint256 _amount, // token amount (only in the case of ERC1155)
        uint256 _dailyRentalPrice,
        address _privateAddress,
        address _vaultAddress, //The Vault address corresponding to the collection you wish to loan out
        address _paymentToken,
        PaymentMethod _paymentMethod
    ) external nonReentrant whenNotPaused {
        require(_amount > 0, "amount must not be zero");
        require(_lockDuration == 0 || _lockDuration >= _minRentalDuration, "lockDuration < minRentalDuration");
        require(_lockDuration == 0 || _maxRentalDuration <= _lockDuration, "maxRentalDuration > lockDuration");
        require(_minRentalDuration <= _maxRentalDuration, "minRentalDuration > maxRentalDuration");

        require(vaultWhiteList[_vaultAddress], "Vault should be whitelisted");
        require(IVault(_vaultAddress).tokenIdAllowed(_tokenId), "This tokenId is not allowed to lend");
        require(IVault(_vaultAddress).minPrices(_paymentToken) <= _dailyRentalPrice, "dailyRentalPrice < minPrice");
        require(IVault(_vaultAddress).minDuration() <= _minRentalDuration * 1 days, "minRentalDuration < minDuration");
        require(IVault(_vaultAddress).maxDuration() >= _maxRentalDuration * 1 days, "maxRentalDuration > maxDuration");

        require(_isPaymentTokenAllowed(_vaultAddress, _paymentToken), "This Payment Token is not allowed");

        // ICollection(IVault(_vaultAddress).originalCollection()).setApprovalForAll(address(this), true);
        totalLended.increment();
        uint256 _lockId = totalLended.current();

        // mintAndCreatePrivateList
        // Equivalent to this description: privateList[_lockId] = _privateAddress;
        if (_privateAddress != address(0)) privateList[_lockId] = _privateAddress;

        _createList(
            _lockId,
            _tokenId,
            _lockDuration,
            _minRentalDuration,
            _maxRentalDuration,
            _amount,
            _dailyRentalPrice,
            _vaultAddress,
            _paymentToken,
            _paymentMethod
        );

        // To avoid error below, mint NFTs after creating the list
        // CompilerError: Stack too deep, try removing local variables.
        _mintNft(_lockId, _lockDuration);
    }

    function cancel(uint256 _lockId) external onlyLender(_lockId) onlyBeforeLock(_lockId) onlyNotRentaled(_lockId) {
        if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime) burn(_lockId); // burn yNFT
        _redeemNFT(_lockId); // burn oNFT and redeem original token
        emit Canceled(_lockId);
    }

    // Burn oNFT to execute an internal function that redeems the original NFT
    function claimNFT(uint256 _lockId)
        external
        onlyONftOwner(_lockId)
        onlyAfterLockExpired(_lockId)
        onlyNotRentaled(_lockId)
    {
        _redeemNFT(_lockId);
    }

    //for Lender
    function claimFee(uint256 _lockId) external onlyYNftOwner(_lockId) onlyAfterLockExpired(_lockId) {
        address[] memory _allowedPaymentTokens = IVault(lendRent[_lockId].lend.vault).getPaymentTokens();
        for (uint256 i = 0; i < _allowedPaymentTokens.length; i++) {
            uint256 _sendAmount = lenderBenefit[_lockId][_allowedPaymentTokens[i]];
            if (_allowedPaymentTokens[i] == address(0)) {
                payable(_msgSender()).transfer(_sendAmount);
            } else {
                IERC20(_allowedPaymentTokens[i]).safeTransfer(_msgSender(), _sendAmount);
            }
            delete lenderBenefit[_lockId][_allowedPaymentTokens[i]];
        }
        if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime) burn(_lockId); // burn yNFT
    }

    // for Collection Owner
    function claimRoyalty(address _vaultAddress) external onlyCollectionOwner(_vaultAddress) {
        address[] memory _allowedPaymentTokens = IVault(_vaultAddress).getPaymentTokens();
        for (uint256 i = 0; i < _allowedPaymentTokens.length; i++) {
            uint256 _sendAmount = collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
            if (_allowedPaymentTokens[i] == address(0)) {
                payable(_msgSender()).transfer(_sendAmount);
            } else {
                IERC20(_allowedPaymentTokens[i]).safeTransfer(_msgSender(), _sendAmount);
            }
            delete collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
        }
    }

    //for Protocol Admin
    function claimProtocolFee() external onlyProtocolAdmin {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            uint256 _sendAmount = protocolAdminBenefit[paymentTokens[i]];
            if (paymentTokens[i] == address(0)) {
                payable(_msgSender()).transfer(_sendAmount);
            } else {
                IERC20(paymentTokens[i]).safeTransfer(_msgSender(), _sendAmount);
            }
            delete protocolAdminBenefit[paymentTokens[i]];
        }
    }

    // Lending process: On the vault side, process whether to send originalNFT or wrapNFT as mint.
    function rent(
        uint256 _lockId,
        uint256 _rentalStartTimestamp, // If zero, rent now
        uint256 _rentalDurationByDay,
        uint256 _amount
    ) external payable nonReentrant whenNotPaused {

        require(_rentalStartTimestamp < (block.timestamp + reservationLimits), "Reservation smaller 10days");

        Lend memory _lend = lendRent[_lockId].lend;

        // Verify executor for private listing
        if (_lend.listType == ListType.Private) require(_msgSender() == privateList[_lockId], "invalid renter");

        _calcFee(_lend.vault, _lockId, _rentalDurationByDay, _amount);

        (uint256 _rentalStartTime, uint256 _rentalExpireTime) = _calcDutaion(
            _rentalStartTimestamp,
            _rentalDurationByDay,
            _lend
        );

        totalRented.increment();
        uint256 _rentId = totalRented.current();

        Rent memory _rent = Rent({
            renterAddress: _msgSender(),
            rentId: _rentId,
            rentalStartTime: _rentalStartTime,
            rentalExpireTime: _rentalExpireTime,
            amount: _amount
        });

        _updateRent(_lend.vault, _lockId, _lend, _rent);
        _addLockId(renterLockIds, _msgSender(), _lockId);

        // Pseudo Transfer WrappedNFT (if it starts later, only booking)
        IVault(_lend.vault).mintWNft(_msgSender(), _rentalStartTime, _rentalExpireTime, _lockId);

        // TODO: if booking, emit Booked?
        emit Rented(_rentId, _msgSender(), _lockId, _rent);
    }

    function activate(uint256 _lockId, uint256 _rentId) external {
        IVault(lendRent[_lockId].lend.vault).activate(_rentId, _lockId, _msgSender());
    }

    function tokenURI(uint256 _lockId) public view override returns (string memory) {
        require(_exists(_lockId), "ERC721Metadata: URI query for nonexistent token");

        // CHANGE STATE
        Lend memory _lend = lendRent[_lockId].lend;

        string memory _tokenSymbol = "MATIC";
        if (_lend.paymentToken != address(0)) _tokenSymbol = IERC20Detailed(_lend.paymentToken).symbol();
        string memory _name = IVault(_lend.vault).name();

        bytes memory json = RentaFiSVG.getYieldSVG(
            _lockId,
            _lend.tokenId,
            lenderBenefit[_lockId][_lend.paymentToken],
            _lend.lockStartTime,
            _lend.lockExpireTime,
            IVault(_lend.vault).originalCollection(),
            _name,
            _tokenSymbol
        );
        string memory _tokenURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));

        return _tokenURI;
    }

    function _calcDutaion(
        uint256 _rentalStartTimestamp,
        uint256 _rentalDurationByDay,
        Lend memory _lend
    ) internal view returns (uint256, uint256) {
        uint256 _rentalStartTime = block.timestamp;
        // For Reservation
        if (_rentalStartTimestamp != 0) {
            require(_rentalStartTimestamp > block.timestamp, "rentalStartTime should be now or later");
            _rentalStartTime = _rentalStartTimestamp;
        }

        // Arguments are passed in days, so they are converted to seconds
        uint256 _rentalExpireTime = _rentalStartTime + (_rentalDurationByDay * 86400); //SafeMath.add(_rentalStartTime, SafeMath.mul(_rentalDurationByDay, 86400));

        // Check to see if the number of days or date conditions set by lend are met.
        require(
            _rentalExpireTime < _lend.lockExpireTime || _lend.lockExpireTime - _lend.lockStartTime == 0,
            "Rental expire time after Lock expire time"
        );
        require(
            _lend.minRentalDuration <= _rentalDurationByDay && _rentalDurationByDay <= _lend.maxRentalDuration,
            "Rental duration is out of range"
        );
        return (_rentalStartTime, _rentalExpireTime);
    }

    function _calcFee(
        address _vaultAddress,
        uint256 _lockId,
        uint256 _rentalDurationByDay,
        uint256 _amount
    ) internal {
        /*
         * If the amount is greater than 1 in ERC721,
         * the renter will only pay more than necessary,
         * so we do not revert here to save on gas costs.
         */
        Lend memory _lend = lendRent[_lockId].lend;

        uint256 _rentalPrice = (_lend.dailyRentalPrice / _lend.amount) * _amount;
        uint256 _rentalFee = _rentalPrice * _rentalDurationByDay;
        uint256 _adminFee = (_rentalFee * protocolAdminFeeRatio) / E5;
        uint256 _collectionOwnerFee = (_rentalFee * IVault(_vaultAddress).collectionOwnerFeeRatio()) / E5;
        address _paymentToken = _lend.paymentToken;
        if (_lend.lockStartTime < _lend.lockExpireTime)
            // If the lockDuration is Zero, fee is sent to lender this time
            lenderBenefit[_lockId][_paymentToken] += _rentalFee - _adminFee - _collectionOwnerFee;
        collectionOwnerBenefit[_vaultAddress][_paymentToken] += _collectionOwnerFee;
        protocolAdminBenefit[_paymentToken] += _adminFee;

        if (_paymentToken == address(0)) {
            // Native token
            require(msg.value >= _rentalFee, "not enough value");
            // If the lockDuration is Zero, send _rentalFee to the lender now
            if (_lend.lockStartTime == _lend.lockExpireTime) payable(_lend.lender).transfer(_rentalFee);
            payable(msg.sender).transfer(msg.value - _rentalFee);
        } else {
            require(IERC20(_paymentToken).balanceOf(_msgSender()) >= _rentalFee, "not enough balance");
            if (_lend.lockStartTime == _lend.lockExpireTime) {
                IERC20(_paymentToken).safeTransferFrom(_msgSender(), address(_lend.lender), _rentalFee);
            } else {
                IERC20(_paymentToken).safeTransferFrom(_msgSender(), address(this), _rentalFee);
            }
        }
    }

    function _updateRent(
        address _vaultAddress,
        uint256 _lockId,
        Lend memory _lend,
        Rent memory _rent
    ) internal {
        address _originalNftAddress = IVault(_vaultAddress).originalCollection();
        Rent[] storage _rents = lendRent[_lockId].rent;

        _deleteExpiredRent(_rents);

        // ERC721 availability
        if (_originalNftAddress.is721()) {
            // Check for rental availability
            for (uint256 i = 0; i < _rents.length; i++) {
                // Periods A-B and C-D overlap only if C<=B and A<=D
                require(
                    _rents[i].rentalStartTime > _rent.rentalExpireTime ||
                        _rent.rentalStartTime > _rents[i].rentalExpireTime,
                    "Already rented"
                );
            }
        }

        // ERC1155 availability
        if (_originalNftAddress.is1155()) {
            // Confirmation of the number of tokens remaining available for rent
            uint256 _rentaled = 0;
            for (uint256 i = 0; i < _rents.length; i++) {
                // Counting rent amount with overlapping periods
                if (
                    _rents[i].rentalStartTime < _rent.rentalExpireTime &&
                    _rent.rentalStartTime < _rents[i].rentalExpireTime
                ) _rentaled += _rents[i].amount;
            }
            uint256 _remain = _lend.amount - _rentaled;
            // Check for rental availability
            require(_rent.amount <= _remain, "Not enough rentable tokens");
        }

        // Push new rent
        _rents.push(_rent);
    }

    function _mintNft(uint256 _lockId, uint256 _lockDuration) internal {
        _mintONft(_lockId);
        // Mint the yNFT to match the mint of the oNFT
        if (_lockDuration != 0) _mintYNft(_lockId);
    }

    // Deposit the original NFT to the Vault
    // Receive oNFT minted instead
    function _mintONft(uint256 _lockId) internal {
        address _vaultAddress = lendRent[_lockId].lend.vault;
        uint256 _tokenId = lendRent[_lockId].lend.tokenId;
        uint256 _amount = lendRent[_lockId].lend.amount;
        // Process the NFT to deposit it in the vault
        // Send and mint the NFT after confirming that the owner of the NFT is executing
        // Get the address of the original NFT
        address _originalNftAddress = IVault(_vaultAddress).originalCollection();

        if (_originalNftAddress.is721()) {
            require(_amount == 1, "ERC721 amount must be 1");
            // identify the owner of the original NFT
            address _holder = IERC721(_originalNftAddress).ownerOf(_tokenId);
            // Verify that you are the owner
            require(_msgSender() == _holder, "not owner address");
        }

        if (_originalNftAddress.is1155()) {
            require(
                lendRent[_lockId].lend.dailyRentalPrice % _amount == 0,
                "dailyRentalFee must be divisible by amount"
            );
            uint256 _balance = IERC1155(_originalNftAddress).balanceOf(_msgSender(), _tokenId);
            require(_balance >= _amount, "not enough tokens");
        }

        // NFT sent to vault (= locked)
        _safeTransferBundle(_originalNftAddress, _msgSender(), _vaultAddress, _tokenId, _amount);
        // Minting oNft from Vault.
        IVault(_vaultAddress).mintONft(_lockId);
    }

    // Mint the yNFT instead of listing it on the market
    function _mintYNft(uint256 _lockId) internal {
        _safeMint(_msgSender(), _lockId);
    }

    // The part that actually creates the lending board
    function _createList(
        uint256 _lockId, // Unique number for each loan
        uint256 _tokenId,
        uint256 _lockDuration,
        uint256 _minRentalDuration,
        uint256 _maxRentalDuration,
        uint256 _amount,
        uint256 _dailyRentalPrice,
        address _vaultAddress,
        address _paymentToken,
        PaymentMethod _paymentMethod
    ) internal {
        // By the time you get here, the deposit process has been completed and the o/yNFT has been issued.

        ListType _listType = ListType.Public;
        if (privateList[_lockId] != address(0)) _listType = ListType.Private;

        uint256 _lockExpiredTime = block.timestamp + (_lockDuration * 86400); //SafeMath.add(block.timestamp, SafeMath.mul(_lockDuration, 86400));
        LendRent storage _lendRent = lendRent[_lockId];

        _lendRent.lend = Lend({
            lockStartTime: block.timestamp,
            lockExpireTime: _lockExpiredTime,
            minRentalDuration: _minRentalDuration,
            maxRentalDuration: _maxRentalDuration,
            dailyRentalPrice: _dailyRentalPrice,
            tokenId: _tokenId,
            amount: _amount,
            vault: _vaultAddress,
            lender: _msgSender(),
            paymentToken: _paymentToken,
            listType: _listType,
            paymentMethod: _paymentMethod
        });

        //for frontend
        _addLockId(lenderLockIds, _msgSender(), _lockId);
        _addLockId(vaultLockIds, _vaultAddress, _lockId);
        //TODO テストコード
        tokensLockId[
            IVault(_vaultAddress).originalCollection()
        ][_tokenId].push(_lockId);
        //テストコードここまで

        // Add payment token to the list for claiming ProtocolAdminFee
        bool _alreadyExists = false;
        for (uint256 i = 0; i < paymentTokens.length; i++) if (paymentTokens[i] == _paymentToken) _alreadyExists = true;
        if (!_alreadyExists) paymentTokens.push(_paymentToken);

        emit Listed(_lockId, _msgSender(), _lendRent.lend);
    }

    // Redeem NFTs deposited in the Vault by Burning oNFTs
    function _redeemNFT(uint256 _lockId) internal {
        // Redeem NFTs deposited in the vault. wrapped NFTs are released on the vault side.
        address _vaultAddress = lendRent[_lockId].lend.vault;
        IVault(_vaultAddress).redeem(_lockId);
        IVault(_vaultAddress).burn(_lockId);
        _clearStorages(_lockId);
    }

    function _clearStorages(uint256 _lockId) internal {
        _deleteLockId(lenderLockIds, lendRent[_lockId].lend.lender, _lockId);
        _deleteLockId(vaultLockIds, lendRent[_lockId].lend.vault, _lockId);
        
        //TODO テストコード
        uint256[] storage _lockIds = tokensLockId[
            IVault(lendRent[_lockId].lend.vault).originalCollection()
        ][lendRent[_lockId].lend.tokenId];

        for (uint256 i = 0; i < _lockIds.length; i++) {
            if (_lockIds[i] == _lockId) {
                if (i != _lockIds.length - 1) {
                    _lockIds[i] = _lockIds[_lockIds.length - 1];
                }
                _lockIds.pop();
                break;
            }
        }
        //テストコードここまで

        // The following processes have already been executed in onlyNotRentaled
        Rent[] memory _rents = lendRent[_lockId].rent;
        for (uint256 i = 0; i < _rents.length; i++) _deleteLockId(renterLockIds, _rents[i].renterAddress, _lockId);

        delete lendRent[_lockId];
        delete privateList[_lockId];
    }

    function _safeTransferBundle(
        address _originalNftAddress,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        if (_originalNftAddress.is1155()) {
            IERC1155(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId, _amount, "");
        } else if (_originalNftAddress.is721()) {
            IERC721(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId, "");
        }
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC4907/IERC4907.sol";

library Detector {
    function is721(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC1155).interfaceId);
    }

    function is4907(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC4907).interfaceId);
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IVault {
    function factoryContract() external view returns (address);

    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);

    function approve(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function mintONft(uint256 lockId) external;

    function mintWNft(
        address renter,
        uint256 starts,
        uint256 expires,
        uint256 lockId
    ) external;

    function activate(
        uint256 _rentId,
        uint256 _lockId,
        address renter
    ) external;

    function originalCollection() external view returns (address);

    function redeem(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function collectionOwner() external view returns (address);

    function collectionOwnerFeeRatio() external view returns (uint256);

    function tokenIdAllowed(uint256 tokenId) external view returns (bool);

    function getPaymentTokens() external view returns (address[] memory);

    function setMinPrices(uint256[] memory minPrices, address[] memory paymentTokens) external;

    function minPrices(address paymentToken) external view returns (uint256);

    function minDuration() external view returns (uint256);

    function maxDuration() external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library RentaFiSVG {
    function weiToEther(uint256 num) public pure returns (string memory) {
        if (num == 0) return "0.0";
        bytes memory b = bytes(Strings.toString(num));
        uint256 n = b.length;
        if (n < 19) for (uint i = 0; i < 19 - n; i++) b = abi.encodePacked("0", b);
        n = b.length;
        uint256 k = 18;
        for (uint i = n - 1; i > n - 18; i--) {
            if (b[i] != "0") break;
            k--;
        }
        uint256 m = n - 18 + k + 1;
        bytes memory a = new bytes(m);
        for (uint256 i = 0; i < k; i++) a[m - 1 - i] = b[n - 19 + k - i];
        a[m - k - 1] = ".";
        for (uint256 i = 0; i < n - 18; i++) a[m - k - 2 - i] = b[n - 19 - i];
        return string(a);
    }

    function getYieldSVG(
        uint256 _lockId,
        uint256 _tokenId,
        uint256 _benefit,
        uint256 _lockStartTime,
        uint256 _lockExpireTime,
        address _collection,
        string memory _name,
        string memory _tokenSymbol
    ) public pure returns (bytes memory) {
        string memory parsed = weiToEther(_benefit);
        string memory svg = string(
            abi.encodePacked(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='16' font-weight='400'><tspan x='28' y='40'>Yield NFT</tspan><tspan x='420' y='170'>",
                    _tokenSymbol,
                    "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='135'>Claimable Funds</tspan></text><text fill='#5A6480' font-family='Inter' font-size='16' font-weight='900' text-anchor='end'><tspan x='415' y='170'>",
                    parsed,
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='900'><tspan x='28' y='270'>"
                ),
                abi.encodePacked(
                    _name,
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='283'>",
                    Strings.toHexString(uint256(uint160(_collection)), 20),
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='270'>#",
                    Strings.toString(_tokenId),
                    "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
                )
            )
        );

        bytes memory json = abi.encodePacked(
            '{"name": "yieldNFT #',
            Strings.toString(_lockId),
            ' - RentaFi", "description": "YieldNFT represents Rental Fee deposited by Borrower in a RentaFi Escrow. The owner of this NFT can claim rental fee after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
            Strings.toString(_lockStartTime),
            '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
            Strings.toString(_lockExpireTime),
            '"},{"trait_type":"FeeAmount", "value":"',
            parsed,
            '"}]}'
        );

        return json;
    }

    function getOwnershipSVG(
        uint256 _lockId,
        uint256 _tokenId,
        uint256 _lockStartTime,
        uint256 _lockExpireTime,
        address _collection,
        string memory _name
    ) public pure returns (bytes memory) {
        string memory svg = string(
            abi.encodePacked(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='16' font-weight='400'><tspan x='28' y='40'>Ownership NFT</tspan><tspan x='250' y='270'>Until Unlock</tspan><tspan x='430' y='270'>Day</tspan></text><text fill='#5A6480' font-family='Inter' font-size='32' font-weight='900'><tspan x='28' y='150'>",
                    _name,
                    "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900' text-anchor='end'><tspan x='425' y='270'>",
                    Strings.toString((_lockExpireTime - _lockStartTime) / 1 days)
                ),
                abi.encodePacked(
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='170'>",
                    Strings.toHexString(uint256(uint160(_collection)), 20),
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='185'>",
                    Strings.toString(_tokenId),
                    "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
                )
            )
        );

        bytes memory json = abi.encodePacked(
            '{"name": "OwnershipNFT #',
            Strings.toString(_lockId),
            ' - RentaFi", "description": "OwnershipNFT represents Original NFT locked in a RentaFi Escrow. The owner of this NFT can claim original NFT after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
            Strings.toString(_lockStartTime),
            '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
            Strings.toString(_lockExpireTime),
            '"}]}'
        );

        return json;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity =0.8.13;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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