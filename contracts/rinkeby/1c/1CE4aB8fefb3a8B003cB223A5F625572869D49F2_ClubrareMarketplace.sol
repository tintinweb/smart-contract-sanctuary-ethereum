//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/IERC2981Royalties.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IClubrareMarketPlace.sol";
import "./interfaces/IStake.sol";
import "./interfaces/ILPStake.sol";
import "./interfaces/IEscrow.sol";
import "./interfaces/IToken.sol";

/**
 * @title ClubrareMarketplace contract
 * @author Ajitesh Mishra
 * @notice NFT marketplace contract for Digital and Physical NFTs Clubrare.
 */
contract ClubrareMarketplace is
    IClubrareMarketplace,
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // Contract Name
    string public constant name = "Clubrare Marketplace";
    //Contract Version
    string public constant version = "1.0.1";

    // NOTE: these hashes are derived and verified in the constructor.
    //EIP712 Domain Type Hash
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    //Contract Name hash
    bytes32 private constant _NAME_HASH = 0xf555e867deda96ada315d27dde8710b83dfc4e2f5c9e0876ef5793912dd34009;
    //Contract Version Hash
    bytes32 private constant _VERSION_HASH = 0xfc7f6d936935ae6385924f29da7af79e941070dafe46831a51595892abc1b97a;
    //Order Struct Hash
    bytes32 private constant _ORDER_TYPEHASH = 0x29c732f875480354fdc02ecd923e393d66811f096349b62a7c0891f1588d33b4;
    //Derived Domain Separtor Hash Variable for EIP712 Domain Seprator
    bytes32 public DOMAIN_SEPARATOR;

    /* Chain id */
    //To be delete before mainnet
    uint16 public constant CHAIN_ID = 4;

    /* Fee denomiator that can be used to calculate %. 100% = 10000 */
    uint16 public constant FEE_DENOMINATOR = 10000;

    /* Trading fee of marketplace */
    uint16 public TRADE_FEE;

    /* Reward fee of MPWR Staking */
    uint16 public STAKE_FEE;

    /* Reward fee of LP Staking */
    uint16 public LP_STAKE_FEE;

    //TREASURY_WALLET to manage admin royalties and sell fee
    address private TREASURY_WALLET;
    // WETH Contract Address
    address public WETHAddress;
    //MPWR Staking Address
    address public StakeAddress;
    //LPStaking address
    address public LPStakeAddress;
    //Escrow Contract Interface
    IEscrow escrow;

    /* Blacklisted addresses */
    mapping(address => bool) public blacklist;

    mapping(address => bool) public adminContracts;

    /* Admins addresses */
    mapping(address => bool) public admins;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Allowed ERC20 Payment tokens */
    mapping(address => bool) public allowedPaymenTokens;

    //Order Nonce For Seller
    mapping(address => CountersUpgradeable.Counter) private _orderNonces;

    //Bid Nonce For Seller
    mapping(address => CountersUpgradeable.Counter) private _bidderNonces;

    function initialize(
        uint16 _tradefee,
        uint16 _stakereward,
        uint16 _lpreward,
        address _stakeAddress,
        address _lpStakeAddress,
        address _wethAddress,
        address _escrowAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(name, version);
        require(keccak256(bytes(name)) == _NAME_HASH);
        require(keccak256(bytes(version)) == _VERSION_HASH);
        require(
            keccak256(
                "Order(address seller,"
                "address contractAddress,"
                "uint256 royaltyFee,"
                "address royaltyReceiver,"
                "address paymentToken,"
                "uint256 basePrice,"
                "uint256 listingTime,"
                "uint256 expirationTime,"
                "uint256 nonce,"
                "uint256 tokenId,"
                "uint8 orderType,"
                "string uri,"
                "string objId)"
            ) == _ORDER_TYPEHASH
        );
        DOMAIN_SEPARATOR = _domainSeparatorV4();
        TRADE_FEE = _tradefee;
        STAKE_FEE = _stakereward;
        LP_STAKE_FEE = _lpreward;
        StakeAddress = _stakeAddress;
        LPStakeAddress = _lpStakeAddress;
        WETHAddress = _wethAddress;
        escrow = IEscrow(_escrowAddress);
    }

    function getCurrentOrderNonce(address owner) public view returns (uint256) {
        return _orderNonces[owner].current();
    }

    function getCurrentBidderNonce(address owner) public view returns (uint256) {
        return _bidderNonces[owner].current();
    }

    // =================== Owner operations ===================

    /**
     * @dev Pause trading
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause trading
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev update Params to update Contructor values
     */
    function updateParams(
        uint16 _tradefee,
        uint16 _stakereward,
        uint16 _lpreward,
        address _stakeAddress,
        address _lpStakeAddress
    ) external onlyOwner {
        TRADE_FEE = _tradefee;
        STAKE_FEE = _stakereward;
        LP_STAKE_FEE = _lpreward;
        StakeAddress = _stakeAddress;
        LPStakeAddress = _lpStakeAddress;
    }

    function setTresuaryWallet(address _tresaury) external onlyOwner {
        TREASURY_WALLET = _tresaury;
    }

    /**
     * @dev Set Trade fee of marketplace
     */
    function setTradeFee(uint16 _fee) external onlyOwner {
        TRADE_FEE = _fee;
        emit SetTradeFee(_fee);
    }

    /**
     * @dev Blacklist addresses to disable their trading
     */
    function excludeAddresses(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklist[_users[i]] = true;
            emit BlacklistUser(_users[i]);
        }
    }

    /**
     * @dev Add payment tokens to trade
     */
    function addPaymentTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedPaymenTokens[_tokens[i]] = true;
            emit AllowedPaymentToken(_tokens[i]);
        }
    }

    function addAdminContract(address[] calldata _tokenAddress) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            adminContracts[_tokenAddress[i]] = true;
        }
    }

    function addAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    modifier adminAndOwnerOnly(address contractAddress, uint256 tokenId) {
        require(
            admins[msg.sender] || (msg.sender == IERC721Upgradeable(contractAddress).ownerOf(tokenId)),
            "AdminManager: admin and owner only."
        );
        _;
    }

    modifier isAllowedToken(address contractAddress) {
        require(allowedPaymenTokens[contractAddress], "Invalid Payment token");
        _;
    }

    modifier isNotBlacklisted(address user) {
        require(!blacklist[user], "Access Denied");
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "zero value");
        _;
    }

    modifier onlySeller(Order calldata order) {
        require(verifySeller(order), "Not a seller");
        _;
    }

    modifier onlyApproved(
        address contractAddress,
        uint256 tokenId,
        address seller
    ) {
        if (tokenId > 0) {
            require(
                (address(this) == IERC721Upgradeable(contractAddress).getApproved(tokenId) ||
                    IERC721Upgradeable(contractAddress).isApprovedForAll(seller, address(this))),
                "Token id not approved"
            );
        }
        _;
    }

    function buy(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        Order calldata order
    )
        public
        payable
        whenNotPaused
        nonReentrant
        isAllowedToken(order.paymentToken)
        isNotBlacklisted(msg.sender)
        onlyApproved(contractAddress, tokenId, order.seller)
    {
        (bytes32 digest, address signer) = _verifyOrderSig(order);
        bool isToken = order.paymentToken == address(0) ? false : true;
        uint256 paid = isToken ? amount : msg.value;
        require(paid > 0, "invalid amount");
        require(validateOrder(digest, order, order.signature, paid), "Invalid Order");
        Order calldata _order = order;
        INFT nftContract = INFT(contractAddress);
        uint256 _tokenId = _order.tokenId;
        if (_tokenId == 0) {
            // mint if not Minted
            bool isAdminContract = adminContracts[_order.contractAddress];
            bool isAdmin = admins[signer];
            _tokenId = (isAdminContract && isAdmin)
                ? _adminMint(_order.contractAddress, _order.uri, _order.royaltyFee)
                : nftContract.safeMint(_order.seller, _order.uri, _order.royaltyReceiver, _order.royaltyFee);
        }

        uint256 earning = settlement(nftContract, _tokenId, paid, msg.sender, _order);

        uint256 id;

        if (_order.orderType == Type.Escrow) {
            id = escrow.createOrder(
                _tokenId,
                earning,
                _order.paymentToken,
                _order.contractAddress,
                _order.seller,
                msg.sender
            );
        }
        emit Buy(
            msg.sender,
            _order.seller,
            _order.contractAddress,
            _tokenId,
            earning,
            block.timestamp,
            _order.paymentToken,
            id,
            _order.objId
        );
    }

    function acceptOffer(
        Order calldata order,
        Bid calldata bid,
        address buyer,
        uint256 _amount
    )
        external
        whenNotPaused
        nonReentrant
        onlySeller(order)
        isAllowedToken(order.paymentToken)
        isNotBlacklisted(msg.sender)
        onlyApproved(order.contractAddress, order.tokenId, order.seller)
    {
        (bytes32 digest, address signer) = _verifyOrderSig(order);
        Order calldata _order = order;
        Bid calldata _bid = bid;
        uint256 amt = _amount;
        address taker = buyer;
        require(amt>0,"invalid amount");
        require(validateBid(_bid,taker,amt),"invalid bid");
        require(validateOrder(digest, _order, _order.signature, amt),"invalid order");
        INFT nftContract = INFT(_order.contractAddress);
        uint256 _tokenId = _order.tokenId;

        if (_tokenId == 0) {
            // mint if not Minted
            bool isAdminContract = adminContracts[_order.contractAddress];
            bool isAdmin = admins[signer];
            _tokenId = (isAdminContract && isAdmin)
                ? _adminMint(_order.contractAddress, _order.uri, _order.royaltyFee)
                : nftContract.safeMint(msg.sender, _order.uri, _order.royaltyReceiver, _order.royaltyFee);
        }

        uint256 sellerEarning = settlement(nftContract, _tokenId, amt, taker, _order);

        emit AcceptOffer(
            taker,
            msg.sender,
            _order.contractAddress,
            _tokenId,
            sellerEarning,
            block.timestamp,
            _order.paymentToken,
            _order.objId
        );
    }

    function settlement(
        INFT nftContract,
        uint256 _tokenId,
        uint256 amt,
        address taker,
        Order calldata _order
    ) internal returns (uint256) {
        (address creator, uint256 royaltyAmt) = checkRoyalties(
            nftContract,
            _tokenId,
            amt,
            _order.contractAddress,
            msg.sender
        );
        uint256 sellerEarning = _chargeAndSplit(
            (amt - royaltyAmt),
            taker,
            _order.paymentToken,
            royaltyAmt,
            creator
        );
        _executeExchange(_order, _order.seller, taker, sellerEarning, _tokenId);
        return sellerEarning;
    }

    function InvalidateSignedOrder(Order calldata order) external whenNotPaused nonReentrant {
        (bytes32 digest, address signer) = _verifyOrderSig(order);
        require(msg.sender == signer, "Not a signer");
        cancelledOrFinalized[digest] = true;
        _orderNonces[signer].increment();
        emit CancelOrder(
            order.seller,
            order.contractAddress,
            order.tokenId,
            order.basePrice,
            block.timestamp,
            order.paymentToken,
            order.objId
        );
    }

    //Bulk cancel Order
    function InvalidateSignedBulkOrder(Order[] calldata _order) external whenNotPaused nonReentrant {
        address _signer;
        for (uint256 i; i < _order.length; i++) {
            Order calldata order = _order[i];
            (bytes32 digest, address signer) = _verifyOrderSig(order);
            require(msg.sender == signer, "Not a signer");
            _signer = signer;
            cancelledOrFinalized[digest] = true;
            emit CancelOrder(
                order.seller,
                order.contractAddress,
                order.tokenId,
                order.basePrice,
                block.timestamp,
                order.paymentToken,
                order.objId
            );
        }
        _orderNonces[_signer].increment();
    }

    function InvalidateSignedBid(Bid calldata bid) external whenNotPaused nonReentrant {
        (bytes32 digest, address signer) = _verifyBidSig(bid);
        require(msg.sender == signer, "Not a signer");
        cancelledOrFinalized[digest] = true;
        _bidderNonces[signer].increment();
        emit CancelBid(
            bid.bidder,
            bid.seller,
            bid.contractAddress,
            bid.tokenId,
            bid.bidAmount,
            block.timestamp,
            bid.paymentToken,
            bid.objId,
            bid.bidId
        );
    }

    function withdrawETH(address admin) external onlyOwner {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawWETH(address admin) external onlyOwner {
        IWETH weth = IWETH(WETHAddress);
        uint256 amount = weth.balanceOf(address(this));
        weth.transferFrom(address(this), admin, amount);
    }

    function _executeExchange(
        Order calldata order,
        address seller,
        address buyer,
        uint256 _amount,
        uint256 _tokenId
    ) internal {
        _invalidateSignedOrder(order.contractAddress, _tokenId, order);
        bool isToken = order.paymentToken == address(0) ? false : true;
        if (order.orderType != Type.Escrow) {
            address _seller = adminContracts[order.contractAddress] && admins[seller] ? address(this) : order.seller;
            IERC721Upgradeable(order.contractAddress).transferFrom(_seller, buyer, _tokenId);
            isToken
                ? IERC20Upgradeable(order.paymentToken).safeTransferFrom(buyer, _seller, _amount)
                : payable(_seller).transfer(_amount);
        } else {
            IERC721Upgradeable(order.contractAddress).safeTransferFrom(seller, address(escrow), _tokenId);
            isToken
                ? IERC20Upgradeable(order.paymentToken).safeTransferFrom(buyer, address(escrow), _amount)
                : payable(address(escrow)).transfer(_amount);
        }
    }

    function _invalidateSignedOrder(
        address contractAddress,
        uint256 _tokenId,
        Order calldata order
    ) internal {
        (bytes32 digest, address signer) = _verifyOrderSig(order);
        bool isMinted = _isMinted(contractAddress, _tokenId);
        require(
            !isMinted || signer == IERC721Upgradeable(contractAddress).ownerOf(_tokenId),
            "not minted or not an owner"
        );
        cancelledOrFinalized[digest] = true;
        _orderNonces[signer].increment();
    }

    function _invalidateSignedBid(address bidder, Bid calldata bid) internal {
        (bytes32 digest, address signer) = _verifyBidSig(bid);
        require(bidder == signer, "not a signer");
        cancelledOrFinalized[digest] = true;
        _bidderNonces[signer].increment();
    }

    function checkRoyalties(
        INFT nft,
        uint256 tokenId,
        uint256 amount,
        address contractAddress,
        address _sender
    ) internal view returns (address, uint256) {
        try nft.royaltyInfo(tokenId, amount) returns (address royaltyReceiver, uint256 royaltyAmt) {
            return (royaltyReceiver, royaltyAmt);
        } catch {
            if (adminContracts[contractAddress]) {
                IToken token = IToken(contractAddress);
                uint256 royalities = token.royalities(tokenId);
                address creator = admins[_sender] ? address(this) : token.creators(tokenId);
                uint256 royalty = (royalities * amount) / 10000;
                return (creator, royalty);
            }

            return (address(0), 0);
        }
    }

    function _adminMint(
        address contractAddress,
        string calldata uri,
        uint256 royality
    ) internal returns (uint256 tokenId) {
        IToken token = IToken(contractAddress);
        token.safeMint(uri, royality);
        return 0;
    }

    function _isMinted(address contractAddress, uint256 tokenId) internal view returns (bool) {
        try IERC721Upgradeable(contractAddress).ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function _chargeAndSplit(
        uint256 _amount,
        address user,
        address _erc20Token,
        uint256 royaltyValue,
        address royaltyReceiver
    ) internal returns (uint256) {
        uint256 plaformFee = (TRADE_FEE * _amount) / FEE_DENOMINATOR;
        uint256 stakingSplit = (STAKE_FEE * _amount) / FEE_DENOMINATOR;
        uint256 lpSplit = (LP_STAKE_FEE * _amount) / FEE_DENOMINATOR;

        IWETH weth = IWETH(WETHAddress);
        if (_erc20Token == address(0)) {
            payable(royaltyReceiver).transfer(royaltyValue);
            weth.deposit{ value: (stakingSplit + lpSplit) }();
        } else {
            require(weth.allowance(user, address(this)) >= _amount, "Insufficient spent allowance ");
            weth.transferFrom(user, royaltyReceiver, royaltyValue);
            weth.transferFrom(user, address(this), plaformFee + stakingSplit + lpSplit);
        }

        if (stakingSplit > 0) {
            weth.approve(address(StakeAddress), stakingSplit);
            IStake stake = IStake(StakeAddress);
            stake.receiveWETHFee(stakingSplit);
        }
        if (lpSplit > 0) {
            weth.approve(address(LPStakeAddress), lpSplit);
            ILPStake lpStake = ILPStake(LPStakeAddress);
            lpStake.receiveWETHFee(lpSplit);
        }
        emit Reckon(
            plaformFee,
            StakeAddress,
            stakingSplit,
            LPStakeAddress,
            lpSplit,
            _erc20Token,
            royaltyValue,
            royaltyReceiver
        );
        return _amount - (plaformFee + stakingSplit + lpSplit);
    }

    /**
     * @notice This function is used to add address of admins
     * @dev Fuction take address type argument
     * @param admin The account address of admin
     */
    function addAdmin(address admin) public onlyOwner {
        require(!admins[admin], "admin already in list");
        admins[admin] = true;
        emit AdminAdded(admin, block.timestamp);
    }

    /**
     * @notice This function is used to get list of all address of admins
     * @dev This Fuction is not take any argument
     * @param admin The account address of admin
     */
    function removeAdmin(address admin) public onlyOwner {
        require(admins[admin], "not a admin");
        admins[admin] = false;
        emit AdminRemoved(admin, block.timestamp);
    }

    /**
     * @notice This function is used to burn the apporved NFTToken to
     * certain admin address which was allowed by super admin the owner of Admin Manager
     * @dev This Fuction is take two arguments address of contract and tokenId of NFT
     * @param collection tokenId The contract address of NFT contract and tokenId of NFT
     */
    function burnNFT(address collection, uint256 tokenId) public adminAndOwnerOnly(collection, tokenId) {
        INFT nftContract = INFT(collection);

        string memory tokenURI = nftContract.tokenURI(tokenId);
        require(nftContract.getApproved(tokenId) == address(this), "Token not approve for burn");
        nftContract.burn(tokenId);
        emit NFTBurned(collection, tokenId, msg.sender, block.timestamp, tokenURI);
    }

    function verifySeller(Order calldata order) internal view returns (bool) {
        (, address signer) = _verifyOrderSig(order);
        return msg.sender == signer;
    }

    // =================== Validators ===================

    function _verifyOrderSig(Order calldata order) public view returns (bytes32, address) {
        bytes32 digest = hashToSign(order);
        address signer = ECDSAUpgradeable.recover(digest, order.signature);
        return (digest, signer);
    }

    function _verifyBidSig(Bid calldata bid) public view returns (bytes32, address) {
        bytes32 digest = hashToSign(bid);
        address signer = ECDSAUpgradeable.recover(digest, bid.signature);
        return (digest, signer);
    }

    
    function validateBid(
        Bid calldata bid,
        address buyer,
        uint amount
    ) internal view returns (bool validated) {
        (, address _buyer) = _verifyBidSig(bid);
        if (_buyer != buyer) {
            return false;
        }
        if (amount != bid.bidAmount) 
        {
            return false;
        }
        return true;
        
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(
        bytes32 hash,
        Order memory order,
        bytes calldata sig,
        uint256 amount
    ) internal view returns (bool validated) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover 
        evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order, amount)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            
            return false;
        }

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);

        /* Prevent signature malleability and non-standard v values. */
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        if (v != 27 && v != 28) {
            return false;
        }

        /* recover via ECDSA, signed by seller (already verified as non-zero). */
        if (ecrecover(hash, v, r, s) == order.seller) {
            return true;
        }
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order, uint256 amount) internal pure returns (bool) {
        /* Order must have a maker. */
        if (order.seller == address(0)) {
            return false;
        }

        if (order.basePrice < amount) {
            return false;
        }

        if (order.contractAddress == address(0)) {
            return false;
        }

        return true;
    }

    // =================== Internal Hash Operators ===================

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param _order Order to hash
     * @return hash Hash of order
     */
    function hashOrder(Order memory _order) public pure returns (bytes32 hash) {
        bytes memory array = abi.encode(
            _ORDER_TYPEHASH,
            _order.seller,
            _order.contractAddress,
            _order.royaltyFee,
            _order.royaltyReceiver,
            _order.paymentToken,
            _order.basePrice,
            _order.listingTime,
            _order.expirationTime,
            _order.nonce,
            _order.tokenId,
            _order.orderType,
            keccak256(bytes(_order.uri)),
            keccak256(bytes(_order.objId))
        );
        hash = keccak256(array);
        return hash;
    }

    /**
     * @dev Hash an bid, returning the canonical EIP-712 order hash without the domain separator
     * @param _bid Bid to hash
     * @return hash Hash of bid
     */
    function hashBid(Bid memory _bid) public pure returns (bytes32 hash) {
        bytes memory array = abi.encode(
            keccak256(
                "Bid(address seller,"
                "address bidder,"
                "address contractAddress,"
                "address paymentToken,"
                "uint256 bidAmount,"
                "uint256 bidTime,"
                "uint256 expirationTime,"
                "uint256 nonce,"
                "uint256 tokenId,"
                "string objId)"
            ),
            _bid.seller,
            _bid.bidder,
            _bid.contractAddress,
            _bid.paymentToken,
            _bid.bidAmount,
            _bid.bidTime,
            _bid.expirationTime,
            _bid.nonce,
            _bid.tokenId,
            keccak256(bytes(_bid.objId))
        );
        hash = keccak256(array);
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashOrder(order)));
    }

    /**
     * @dev Hash an Bid, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param bid Bid to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Bid memory bid) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashBid(bid)));
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library CountersUpgradeable {
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

//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IERC2981Royalties.sol";

interface INFT is IERC721Upgradeable, IERC2981Royalties {
    function safeMint(
        address to,
        string memory uri,
        address creator,
        uint256 value
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setRoyalties(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) external;

    function approve(address to, uint256 tokenId) external;

    function tokenURI(uint256 tokenId) external returns (string memory);

    function burn(uint256 tokenId) external;
}

//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function approve(address spender, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IClubrareMarketplace {
    struct Order {
        /* Order maker address. */
        address seller;
        /* contract Address */
        address contractAddress;
        /* Collection Royalty Fee. */
        uint256 royaltyFee;
        /* Royalty receiver once order is completed */
        address royaltyReceiver;
        /* Token used to pay for the order. Only WETH for now */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order nonce, used to prevent duplicate. */
        uint256 nonce;
        /* Token Id */
        uint256 tokenId;
        /* Order type Physical or Digital */
        Type orderType;
        /* Signature */
        bytes signature;
        /* metadata URI for Minting*/
        string uri;
        /* Obj Id for internal mapping */
        string objId;
    }

    struct Bid {
        /* Order Seller address. */
        address seller;
        /* Order Buyer address. */
        address bidder;
        /* contract Address */
        address contractAddress;
        /* Token used to pay for the order. Only WETH for now */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 bidAmount;
        /* Listing timestamp. */
        uint256 bidTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order nonce, used to prevent duplicate. */
        uint256 nonce;
        /* Token Id */
        uint256 tokenId;
        /*signature*/
        bytes signature;
        /* Obj Id for internal mapping */
        string objId;
        /* Bid Id for internal mapping */
        string bidId;
    }

    /**
     * Type: Digital or Physical.
     */
    enum Type {
        Digital,
        Physical,
        Escrow
    }

    event Buy(
        address buyer,
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 time,
        address paymentToken,
        uint256 orderId,
        string objId
    );
    event AcceptOffer(
        address buyer,
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 time,
        address paymentToken,
        string objId
    );

    event CancelOrder(
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 time,
        address paymentToken,
        string objId
    );

    event CancelBid(
        address bidder,
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 time,
        address paymentToken,
        string objId,
        string bidId
    );

    event Reckon(
        uint256 platformFee,
        address StakeAddress,
        uint256 stakingSplit,
        address LPStakeAddress,
        uint256 lpSplit,
        address _erc20Token,
        uint256 royaltyValue,
        address royaltyReceiver
    );

    event AdminRemoved(address admin, uint256 time);
    event AdminAdded(address admin, uint256 time);

    event NFTBurned(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed admin,
        uint256 time,
        string tokenURI
    );

    event SetTradeFee(uint256 tradeFee);
    event BlacklistUser(address user);
    event AllowedPaymentToken(address token);
}

//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IStake {
    function receiveWETHFee(uint256 amount) external;
}

//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILPStake {
    function receiveWETHFee(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEscrow {
    function createOrder(
        uint256 _tokenId,
        uint256 _amount,
        address _erc20Address,
        address _tokenAddress,
        address _buyer,
        address _seller
    ) external payable returns (uint256);

    function Shipped(uint256 _orderId, uint256 _trackingId) external;

    function Received(uint256 _orderId, uint256 _trackingId) external;

    function claimPayout(uint256 _orderId, uint256 _trackingId) external;

    function cancelOrder(uint256 _orderId, uint256 _trackingId) external;

    function claimRefund(uint256 _orderId, uint256 _trackingId) external;

    function raiseDispute(uint256 _orderId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IToken {
    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

    function safeMint(string memory uri, uint256 value) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 tokenId) external;

    function mint(string calldata _tokenURI, uint256 _royality) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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