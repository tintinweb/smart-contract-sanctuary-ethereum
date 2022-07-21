// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ForeMarket.sol";
import "./verifiers/IForeVerifiers.sol";
import "./config/IProtocolConfig.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ForeMarkets is ERC721, ERC721Burnable {
    using Strings for uint256;

    error MarketAlreadyExists();

    event MarketCreated(
        address indexed creator,
        bytes32 marketHash,
        address market,
        uint256 marketIdx
    );

    /// @notice Init creatin code
    /// @dev Needed to calculate market address
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(ForeMarket).creationCode));

    /// @notice ForeToken
    IERC20Burnable public immutable foreToken;

    /// @notice Protocol Config
    IProtocolConfig public immutable config;

    /// @notice ForeVerifiers
    IForeVerifiers public immutable foreVerifiers;

    /// @notice Market address for hash (ipfs hash without first 2 bytes)
    mapping(bytes32 => address) public market;

    /// @notice True if address is ForeMarket
    mapping(address => bool) public isForeMarket;

    /// @notice All markets array
    address[] public allMarkets;

    /// @param cfg Protocol Config address
    constructor(IProtocolConfig cfg) ERC721("Fore Markets", "MFORE") {
        config = cfg;
        foreToken = IERC20Burnable(cfg.foreToken());
        foreVerifiers = IForeVerifiers(cfg.foreVerifiers());
    }

    /// @notice Returns base uri
    function _baseURI() internal pure override returns (string memory) {
        return "https://markets.api.foreprotocol.io/market/";
    }

    /// @notice Returns token uri for existing token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId < allMarkets.length, "Non minted token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /// @notice Returns true if Address is ForeOperator
    /// @dev ForeOperators: ForeMarkets(as factory), ForeMarket contracts and marketplace
    function isForeOperator(address addr) external view returns (bool) {
        return (addr != address(0) &&
            (addr == address(this) ||
                isForeMarket[addr] ||
                addr == config.marketplace()));
    }

    /// @dev Allow tokens to be used by market contracts
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (isForeMarket[operator]) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Returns length of all markets array / nft height
    function allMarketLength() external view returns (uint256) {
        return allMarkets.length;
    }

    /// @notice Mints Verifier Nft (ForeVerifier)
    /// @param receiver receiver address
    function mintVerifier(address receiver) external {
        uint256 mintPrice = config.verifierMintPrice();
        foreToken.transferFrom(msg.sender, address(foreVerifiers), mintPrice);
        foreVerifiers.mintWithPower(receiver, mintPrice);
    }

    /// @notice Buys additional power (ForeVerifier)
    /// @param id token id
    /// @param amount amount to buy
    function buyPower(uint256 id, uint256 amount) external {
        require(
            foreVerifiers.powerOf(id) + amount <= config.verifierMintPrice(),
            "ForeFactory: Buy limit reached"
        );
        foreToken.transferFrom(msg.sender, address(foreVerifiers), amount);
        foreVerifiers.increasePower(id, amount);
    }

    /// @notice Creates Market
    /// @param marketHash market hash
    /// @param receiver market creator nft receiver
    /// @param amountA initial prediction for side A
    /// @param amountB initial prediction for side B
    /// @param endPredictionTimestamp End predictions unix timestamp
    /// @param startVerificationTimestamp Start Verification unix timestamp
    /// @return createdMarket Address of created market
    function createMarket(
        bytes32 marketHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp
    ) external returns (address createdMarket) {
        if (market[marketHash] != address(0)) {
            revert MarketAlreadyExists();
        }

        if (endPredictionTimestamp > startVerificationTimestamp) {
            revert("ForeMarkets: Date error");
        }

        uint256 creationFee = config.marketCreationPrice();
        if (creationFee != 0) {
            foreToken.burnFrom(msg.sender, creationFee);
        }

        bytes memory bytecode = type(ForeMarket).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(marketHash));
        assembly {
            createdMarket := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
            if iszero(extcodesize(createdMarket)) {
                revert(0, 0)
            }
        }

        uint256 amountSum = amountA + amountB;
        if (amountSum != 0) {
            foreToken.transferFrom(msg.sender, createdMarket, amountSum);
        }

        uint256 marketIdx = allMarkets.length;
        ForeMarket(createdMarket).initialize(
            marketHash,
            receiver,
            amountA,
            amountB,
            endPredictionTimestamp,
            startVerificationTimestamp,
            uint64(marketIdx)
        );

        market[marketHash] = createdMarket;
        isForeMarket[createdMarket] = true;

        _mint(receiver, marketIdx);
        emit MarketCreated(msg.sender, marketHash, createdMarket, marketIdx);

        allMarkets.push(createdMarket);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IForeMarkets.sol";
import "./verifiers/IForeVerifiers.sol";
import "./config/IProtocolConfig.sol";
import "./config/IMarketConfig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/MarketLib.sol";

contract ForeMarket {
    /// @notice Market hash (ipfs hash without first 2 bytes)
    bytes32 public marketHash;

    /// @notice Market token id
    uint256 internal _tokenId;

    /// @notice Factory (ForeMarkets)
    IForeMarkets public factory;

    /// @notice Protocol config
    IProtocolConfig public protocolConfig;

    /// @notice Market config
    IMarketConfig public marketConfig;

    /// @notice Verifiers NFT
    IForeVerifiers public foreVerifiers;

    /// @notice Fore Token
    IERC20Burnable public foreToken;

    /// @notice Market info
    MarketLib.Market internal _market;

    /// @notice Positive result predictions amount of address
    mapping(address => uint256) public predictionsA;

    /// @notice Negative result predictions amount of address
    mapping(address => uint256) public predictionsB;

    /// @notice Is prediction reward withdrawn for address
    mapping(address => bool) public predictionWithdrawn;

    /// @notice Verification info for verificatioon id
    MarketLib.Verification[] public verifications;

    bytes32 public disputeMessage;

    /// @notice Verification array size
    function verificationHeight() external view returns (uint256) {
        return verifications.length;
    }

    constructor() {
        factory = IForeMarkets(msg.sender);
    }

    /// @notice Returns market info
    function marketInfo() external view returns(MarketLib.Market memory){
        return _market;
    }

    /// @notice Initialization function
    /// @param mHash _market hash
    /// @param receiver _market creator nft receiver
    /// @param amountA initial prediction for side A
    /// @param amountB initial prediction for side B
    /// @param endPredictionTimestamp End Prediction Timestamp
    /// @param startVerificationTimestamp Start Verification Timestamp
    /// @param tokenId _market creator token id (ForeMarkets)
    /// @dev Possible to call only via the factory
    function initialize(
        bytes32 mHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint64 tokenId
    ) external {
        if (msg.sender != address(factory)) {
            revert("ForeMarket: Only Factory");
        }

        protocolConfig = IProtocolConfig(factory.config());
        marketConfig = IMarketConfig(protocolConfig.marketConfig());
        foreToken = IERC20Burnable(factory.foreToken());
        foreVerifiers = IForeVerifiers(factory.foreVerifiers());

        marketHash = mHash;
        MarketLib.init(
            _market,
            predictionsA,
            predictionsB,
            receiver,
            amountA,
            amountB,
            endPredictionTimestamp,
            startVerificationTimestamp,
            tokenId
        );
    }

    /// @notice Add new prediction
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    function predict(uint256 amount, bool side) external {
        foreToken.transferFrom(msg.sender, address(this), amount);
        MarketLib.predict(
            _market,
            predictionsA,
            predictionsB,
            amount,
            side,
            msg.sender
        );
    }

    ///@notice Stakes nft token for the privilege of being a verifier
    ///@param tokenId ForeVerifiers nft id
    function stakeForPrivilege(uint64 tokenId) external {
        foreVerifiers.transferFrom(msg.sender, address(this), tokenId);
        MarketLib.stakeForPrivilege(
            _market,
            msg.sender,
            foreVerifiers.powerOf(tokenId),
            protocolConfig.verifierMintPrice(),
            tokenId
        );
    }

    ///@notice Doing new verification
    ///@param tokenId vNFT token id
    ///@param side side of verification
    function verify(uint256 tokenId, bool side) external {
        if(
            foreVerifiers.ownerOf(tokenId)!= msg.sender){
            revert ("ForeMarket: Incorrect owner");
        }

        (uint256 verificationPeriod, uint256 disputePeriod) = marketConfig
            .periods();

        foreVerifiers.transferFrom(msg.sender, address(this), tokenId);

        MarketLib.verify(
            _market,
            verifications,
            msg.sender,
            verificationPeriod,
            disputePeriod,
            foreVerifiers.powerOf(tokenId),
            tokenId,
            side
        );
    }

    /// @notice Doing verification for privilege staked vNFT
    /// @param side Side of verification
    function privilegeVerify(bool side) external {
        MarketLib.privilegeVerify(
            _market,
            verifications,
            marketConfig.verificationPeriod(),
            msg.sender,
            foreVerifiers.powerOf(_market.privilegeNftId),
            side
        );
    }

    /// @notice Opens dispute
    function openDispute(bytes32 messageHash) external {
        (
            uint256 disputePrice,
            uint256 disputePeriod,
            uint256 verificationPeriod,
            ,
            ,
            ,
            ,

        ) = marketConfig.config();
        foreToken.transferFrom(msg.sender, address(this), disputePrice);
        disputeMessage = messageHash;
        MarketLib.openDispute(
            _market,
            disputePeriod,
            verificationPeriod,
            msg.sender
        );
    }

    ///@notice Resolves Dispute
    ///@param result Dipsute result type
    ///@dev Only HighGuard
    function resolveDispute(MarketLib.ResultType result) external {
        address highGuard = protocolConfig.highGuard();
        address receiver = MarketLib.resolveDispute(
            _market,
            result,
            highGuard,
            msg.sender
        );
        foreToken.transfer(receiver, marketConfig.disputePrice());
        _closeMarket(result);
    }


    ///@dev Closes market
    ///@param result Market close result type
    ///Is not best optimized becouse of deep stack
    function _closeMarket(MarketLib.ResultType result) private {
        (uint256 burnFee, uint256 foundationFee, , , ) = marketConfig.fees();

        (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toRevenue,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        ) = MarketLib.closeMarket(
                _market,
                burnFee,
                marketConfig.verificationFee(),
                marketConfig.revenueFee(),
                foundationFee,
                result
            );
        if (toBurn != 0) {
            foreToken.burn(toBurn);
        }
        if (toFoundation != 0) {
            foreToken.transfer(protocolConfig.foundationWallet(), toFoundation);
        }
        if (toRevenue != 0) {
            foreToken.transfer(protocolConfig.revenueWallet(), toRevenue);
        }
        if (toHighGuard != 0) {
            foreToken.transfer(protocolConfig.highGuard(), toHighGuard);
        }
        if (toDisputeCreator != 0) {
            foreToken.transfer(disputeCreator, toDisputeCreator);
        }
    }

    ///@notice Closes _market
    function closeMarket() external {
        MarketLib.Market memory m = _market;
        (uint256 verificationPeriod, uint256 disputePeriod) = marketConfig
            .periods();
        MarketLib.beforeClosingCheck(m, verificationPeriod, disputePeriod);
        _closeMarket(MarketLib.calculateMarketResult(m));
    }

    ///@notice Returns prediction reward in ForeToken
    ///@dev Returns full available amount to withdraw(Deposited fund + reward of winnings - Protocol fees)
    ///@param predictor Predictior address
    ///@return 0 Amount to withdraw
    function calculatePredictionReward(address predictor)
        external
        view
        returns (uint256)
    {
        MarketLib.Market memory m = _market;
        return (
            MarketLib.calculatePredictionReward(
                m,
                predictionsA[predictor],
                predictionsB[predictor],
                marketConfig.feesSum()
            )
        );
    }

    ///@notice Withdraw prediction rewards
    ///@dev predictor Predictor Address
    ///@param predictor Predictor address
    function withdrawPredictionReward(address predictor) external {
        MarketLib.Market memory m = _market;
        uint256 toWithdraw = MarketLib.withdrawPredictionReward(
            m,
            marketConfig.feesSum(),
            predictionWithdrawn,
            predictionsA[predictor],
            predictionsB[predictor],
            predictor
        );
        foreToken.transfer(predictor, toWithdraw);
    }

    ///@notice Withdrawss Verification Reward
    ///@param verificationId Id of verification
    function withdrawVerificationReward(uint256 verificationId) external {
        MarketLib.Market memory m = _market;
        MarketLib.Verification memory v = verifications[verificationId];
        uint256 power = foreVerifiers.powerOf(
            verifications[verificationId].tokenId
        );
        (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        ) = MarketLib.withdrawVerificationReward(
                m,
                v,
                power,
                marketConfig.verificationFee()
            );
        verifications[verificationId].withdrawn = true;
        if (toVerifier != 0) {
            foreVerifiers.increasePower(v.tokenId, toVerifier);
            foreToken.transferFrom(
                address(this),
                address(foreVerifiers),
                toVerifier
            );
        }
        if (toDisputeCreator != 0) {
            foreVerifiers.decreasePower(
                v.tokenId,
                toDisputeCreator + toHighGuard
            );
            foreToken.transferFrom(
                address(this),
                m.disputeCreator,
                toDisputeCreator
            );
            foreToken.transferFrom(
                address(this),
                protocolConfig.highGuard(),
                toHighGuard
            );
        }

        if (vNftBurn) {
            foreVerifiers.burn(v.tokenId);
        } else {
            foreVerifiers.transferFrom(address(this), v.verifier, v.tokenId);
        }
    }

    ///@notice Manually Extend Verification Time
    function extendVerificationTime() external{
        (uint256 verificationPeriod, uint256 disputePeriod) = marketConfig
            .periods();
        MarketLib.extendVerificationTime(_market, verificationPeriod, disputePeriod);
    }

    ///@notice Withdraw unsuded privilegeNFT
    function withdrarwUnusedPrivilegeNFT() external{
        MarketLib.Market memory m = _market;
        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }

        if (m.privilegeNftStaker == address(0)) {
            revert ("PrivilegeNftNotExist");
        }
        uint256 fee = foreVerifiers.powerOf(m.privilegeNftId) / 10;
        foreVerifiers.decreasePower(
            m.privilegeNftId,
            fee
        );
        foreToken.burnFrom(address(foreVerifiers), fee);
        foreVerifiers.transferFrom(address(this), m.privilegeNftStaker, m.privilegeNftId);
    }

    ///@notice Withdraw Market Creators Reward
    function marketCreatorFeeWithdraw() external {
        MarketLib.Market memory m = _market;
        uint256 tokenId = _tokenId;

        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }

        factory.transferFrom(msg.sender, address(this), tokenId);
        factory.burn(tokenId);

        uint256 toWithdraw = ((m.sideA + m.sideB) *
            marketConfig.marketCreatorFee()) / 10000;
        foreToken.transfer(msg.sender, toWithdraw);

        emit MarketLib.WithdrawReward(msg.sender, 3, toWithdraw);
    }
}

interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeVerifiers is IERC721{
    function decreasePower(uint256 id, uint256 amount) external;

    function factory() external view returns (address);

    function height() external view returns (uint256);

    function increasePower(uint256 id, uint256 amount) external;

    function mintWithPower(address to, uint256 amount) external;

    function initialPowerOf(uint256 id) external view returns(uint256);

    function powerOf(uint256 id) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IProtocolConfig {
    function marketConfig() external view returns (address);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function foundationWallet() external view returns (address);

    function highGuard() external view returns (address);

    function marketplace() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function revenueWallet() external view returns (address);

    function verifierMintPrice() external view returns (uint256);

    function marketCreationPrice() external view returns (uint256);

    function addresses() external view returns(address, address, address, address, address, address, address);

    function roleAddresses() external view returns(address, address, address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IForeMarkets is IERC721 {
    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function allMarketLength() external view returns (uint256);

    function allMarkets(uint256) external view returns (address);

    function burn(uint256 tokenId) external;

    function buyPower(uint256 id, uint256 amount) external;

    function config() external view returns (address);

    function createMarket(
        bytes32 marketHash,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint256 endPredictionTimestamp,
        uint256 startVerificationTimestamp
    ) external returns (address market);

    function foreToken() external view returns (address);

    function foreVerifiers() external view returns (address);

    function isForeMarket(address market) external view returns (bool);

    function isForeOperator(address addr) external view returns (bool);

    function mintVerifier(address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMarketConfig {
    function burnFee() external view returns (uint256);

    function config()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
    );

    function fees()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
    );

    function periods()
        external
        view
        returns (
            uint256,
            uint256
    );

    function disputePeriod() external view returns (uint256);

    function disputePrice() external view returns (uint256);

    function feesSum() external view returns (uint256);

    function foundationFee() external view returns (uint256);

    function marketCreatorFee() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function verificationFee() external view returns (uint256);

    function verificationPeriod() external view returns (uint32);
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
pragma solidity ^0.8.7;

library MarketLib {
    ///EVENTS
    event MarketInitialized(uint256 marketId);
    event OpenDispute(address indexed creator);
    event CloseMarket(MarketLib.ResultType result);
    event Verify(
        address indexed verifier,
        uint256 power,
        uint256 verificationId,
        uint256 tokenId,
        bool side
    );
    event PrivilegeStake(
        address indexed staker,
        uint256 power,
        uint256 tokenId
    );
    event WithdrawReward(
        address indexed receiver,
        uint256 indexed rewardType,
        uint256 amount
    );
    event Predict(address indexed sender, bool side, uint256 amount);

    //STRUCTS
    /// @notice Market closing types
    enum ResultType {
        NULL,
        AWON,
        BWON,
        DRAW
    }

    struct Verification {
        /// @notice Address of verifier
        address verifier;
        /// @notice Verficaton power
        uint256 power;
        /// @notice Token id used for verification
        uint256 tokenId;
        /// @notice Verification side (true - positive / false - negative)
        bool side;
        /// @notice Is reward + staked token withdrawn
        bool withdrawn;
    }

    struct Market {
        /// @notice Predctioons token pool for positive result
        uint256 sideA;
        /// @notice Predictions token pool for negative result
        uint256 sideB;
        /// @notice Verification power for positive result
        uint256 verifiedA;
        /// @notice Verification power for positive result
        uint256 verifiedB;
        /// @notice Reserved for privilege verifier
        uint256 reserved;
        /// @notice Address of staker
        address privilegeNftStaker;
        /// @notice Dispute Creator address
        address disputeCreator;
        /// @notice End predictions unix timestamp
        uint64 endPredictionTimestamp;
        /// @notice Start verifications unix timestamp
        uint64 startVerificationTimestamp;
        /// @notice Nft id (ForeVerifiers)
        uint64 privilegeNftId;
        /// @notice Market result
        ResultType result;
        /// @notice Wrong result confirmed by HG
        bool confirmed;
        /// @notice Dispute solved by HG
        bool solved;
        /// @notice If verification period was extended
        bool extended;
    }

    /// FUNCTIONS
    /// @dev Checks if one side of the market is fully verified
    /// @param m Market info
    /// @return 0 true if verified
    function _isVerified(Market memory m) internal pure returns (bool) {
        return m.sideA <= m.verifiedB || m.sideB <= m.verifiedA;
    }

    /// @notice Checks if one side of the market is fully verified
    /// @param m Market info
    /// @return 0 true if verified
    function isVerified(Market memory m) external pure returns (bool) {
        return _isVerified(m);
    }

    /// @notice Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function maxAmountToVerifyForSide(Market memory m, bool side)
        external
        pure
        returns (uint256)
    {
        return (_maxAmountToVerifyForSide(m, side));
    }

    /// @dev Returns the maximum value(power) available for verification for side
    /// @param m Market info
    /// @param side Side of market (true/false)
    /// @return 0 Maximum amount to verify for side
    function _maxAmountToVerifyForSide(Market memory m, bool side)
        internal
        pure
        returns (uint256)
    {
        if (_isVerified(m)) {
            return 0;
        }

        if (side) {
            return m.sideB - m.verifiedA - m.reserved;
        } else {
            return m.sideA - m.verifiedB - m.reserved;
        }
    }

    ///@dev Returns prediction reward in ForeToken
    ///@param m Market Info
    ///@param pA Prediction contribution for side A
    ///@param pA Prediction contribution for side B
    ///@param feesSum Sum of all fees im perc
    ///@return toWithdraw amount to withdraw
    function calculatePredictionReward(
        Market memory m,
        uint256 pA,
        uint256 pB,
        uint256 feesSum
    ) internal pure returns (uint256 toWithdraw) {
        uint256 fullMarketSize = m.sideA + m.sideB;
        uint256 _marketSubFee = fullMarketSize -
            (fullMarketSize * feesSum) /
            10000;
        if (m.result == MarketLib.ResultType.DRAW) {
            toWithdraw = (_marketSubFee * (pA + pB)) / fullMarketSize;
        } else if (m.result == MarketLib.ResultType.AWON) {
            toWithdraw = (_marketSubFee * pA) / m.sideA;
        } else if (m.result == MarketLib.ResultType.BWON) {
            toWithdraw = (_marketSubFee * pB) / m.sideB;
        }
    }

    ///@notice Stakes nft token for the privilege of being a verifier
    ///@param market Market storage
    ///@param verifier Verifier
    ///@param nftPower Power of vNFT
    ///@param tokenId ForeVerifiers nft id
    function stakeForPrivilege(
        Market storage market,
        address verifier,
        uint256 nftPower,
        uint256 mintPrice,
        uint64 tokenId
    ) external {
        if(market.privilegeNftStaker != address(0)){
            revert ("PrivilegeNftAlreadyExist");
        }
        if (block.timestamp > market.startVerificationTimestamp) {
            revert ("VerificationAlreadyStarted");
        }
        if (nftPower < mintPrice) {
            revert ("PowerMustBeGreaterThanMintPrice");
        }

        market.privilegeNftStaker = verifier;
        market.privilegeNftId = tokenId;
        market.reserved = nftPower;

        emit PrivilegeStake(verifier, nftPower, tokenId);
    }

    ///@notice Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function calculateMarketResult(Market memory m)
        external
        pure
        returns (ResultType)
    {
        return _calculateMarketResult(m);
    }

    ///@dev Calculates Result for market
    ///@param m Market Info
    ///@return 0 Type of result
    function _calculateMarketResult(Market memory m)
        internal
        pure
        returns (ResultType)
    {
        if (m.verifiedA == m.verifiedB) {
            return ResultType.DRAW;
        } else if (m.verifiedA > m.verifiedB) {
            return ResultType.AWON;
        } else {
            return ResultType.BWON;
        }
    }

    /// @notice initiates market
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param receiver Init prediction(s) creator
    /// @param amountA Init size of side A
    /// @param amountB Init size of side B
    /// @param endPredictionTimestamp End Prediction Unix Timestamp
    /// @param startVerificationTimestamp Start Verification Unix Timestamp
    /// @param tokenId mNFT token id
    function init(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        address receiver,
        uint256 amountA,
        uint256 amountB,
        uint64 endPredictionTimestamp,
        uint64 startVerificationTimestamp,
        uint256 tokenId
    ) external {
        market.endPredictionTimestamp = endPredictionTimestamp;
        market.startVerificationTimestamp = startVerificationTimestamp;
        if (amountA != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountA,
                true,
                receiver
            );
        }
        if (amountB != 0) {
            _predict(
                market,
                predictionsA,
                predictionsB,
                amountB,
                false,
                receiver
            );
        }

        emit MarketInitialized(tokenId);
    }

    /// @notice Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) external {
        _predict(market, predictionsA, predictionsB, amount, side, receiver);
    }

    /// @dev Add new prediction
    /// @param market Market storage
    /// @param predictionsA Storage of predictionsA
    /// @param predictionsB Storage of predictionsB
    /// @param amount Amount of ForeToken
    /// @param side Predicition side (true - positive result, false - negative result)
    /// @param receiver Prediction creator
    function _predict(
        Market storage market,
        mapping(address => uint256) storage predictionsA,
        mapping(address => uint256) storage predictionsB,
        uint256 amount,
        bool side,
        address receiver
    ) internal {
        if (amount == 0) {
            revert ("AmountCantBeZero");
        }

        MarketLib.Market memory m = market;

        if (block.timestamp >= m.endPredictionTimestamp) {
            revert ("PredictionPeriodIsAlreadyClosed");
        }

        if (side) {
            market.sideA += amount;
            predictionsA[receiver] += amount;
        } else {
            market.sideB += amount;
            predictionsB[receiver] += amount;
        }

        emit Predict(receiver, side, amount);
    }

    /// @dev Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function _verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) internal {
        MarketLib.Market memory m = market;
        if (block.timestamp < m.startVerificationTimestamp) {
            revert ("VerificationHasNotStartedYet");
        }
        uint256 verificationEndTime = m.startVerificationTimestamp +
            verificationPeriod;
        if (block.timestamp > verificationEndTime) {
            revert ("VerificationAlreadyClosed");
        }

        if (side) {
            market.verifiedA += power;
        } else {
            market.verifiedB += power;
        }

        uint256 verifyId = verifications.length;

        verifications.push(Verification(verifier, power, tokenId, side, false));

        emit Verify(verifier, verifyId, power, tokenId, side);
    }

    /// @notice Verifies the side with maximum available power
    /// @param market Market storage
    /// @param verifications Verifications array storage
    /// @param verifier Verification creator
    /// @param verificationPeriod Verification Period is sec
    /// @param power Power of vNFT
    /// @param tokenId vNFT token id
    /// @param side Marketd side (true - positive / false - negative);
    function verify(
        Market storage market,
        Verification[] storage verifications,
        address verifier,
        uint256 verificationPeriod,
        uint256 disputePeriod,
        uint256 power,
        uint256 tokenId,
        bool side
    ) external {
        MarketLib.Market memory m = market;
        if(_isVerificationPeriodExtensionAvailable(m)){
            _extendVerificationTime(market, verificationPeriod, disputePeriod);
        }
        uint256 powerAvailable = _maxAmountToVerifyForSide(m, side);
        if (powerAvailable == 0) {
            revert ("MarketIsFullyVerified");
        }
        if (power > powerAvailable) {
            power = powerAvailable;
        }
        _verify(
            market,
            verifications,
            verifier,
            verificationPeriod,
            power,
            tokenId,
            side
        );
    }

    /// @notice Opens a dispute
    /// @param market Market storage
    /// @param disputePeriod Dispute period in seconds
    /// @param verificationPeriod Verification Period in seconds
    /// @param creator Dispute creator
    function openDispute(
        Market storage market,
        uint256 disputePeriod,
        uint256 verificationPeriod,
        address creator
    ) external {
        Market memory m = market;

        if (m.result != ResultType.NULL) {
            revert ("MarketIsClosed");
        }

        if (_isVerificationPeriodExtensionAvailable(m)) {
            revert ("VerifcationPeriodExtensionAvailable");
        }

        if (
            block.timestamp <
            m.startVerificationTimestamp + verificationPeriod &&
            !_isVerified(m)
        ) {
            revert ("DisputePeriodIsNotStartedYet");
        }

        if (
            block.timestamp >=
            m.startVerificationTimestamp + verificationPeriod + disputePeriod
        ) {
            revert ("DisputePeriodIsEnded");
        }

        if (m.disputeCreator != address(0)) {
            revert ("DisputeAlreadyExists");
        }

        market.disputeCreator = creator;
        emit OpenDispute(creator);
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param result Result type
    /// @param highGuard High Guard address
    /// @param requester Function rerquester address
    /// @return receiverAddress Address receives dispute creration tokens
    function resolveDispute(
        Market storage market,
        MarketLib.ResultType result,
        address highGuard,
        address requester
    ) external returns (address receiverAddress) {
        if (highGuard != requester) {
            revert ("HighGuardOnly");
        }
        if (result == MarketLib.ResultType.NULL) {
            revert ("ResultCantBeNull");
        }
        MarketLib.Market memory m = market;
        if (m.disputeCreator == address(0)) {
            revert ("DisputePeriodIsNotStartedYet");
        }

        if (m.solved) {
            revert ("DisputeAlreadySolved");
        }

        market.solved = true;

        if (_calculateMarketResult(m) != result) {
            market.confirmed = true;
            return (m.disputeCreator);
        } else {
            return (requester);
        }
    }

    /// @notice Resolves a dispute
    /// @param market Market storage
    /// @param burnFee Burn fee
    /// @param verificationFee Verification Fee
    /// @param revenueFee Revenue Fee
    /// @param foundationFee Foundation Fee
    /// @param result Result type
    /// @return toBurn Token to burn
    /// @return toFoundation Token to foundation
    /// @return toRevenue Token to revenue
    /// @return toHighGuard Token to HG
    /// @return toDisputeCreator Token to dispute creator
    /// @return disputeCreator Dispute creator address
    function closeMarket(
        Market storage market,
        uint256 burnFee,
        uint256 verificationFee,
        uint256 revenueFee,
        uint256 foundationFee,
        MarketLib.ResultType result
    )
        external
        returns (
            uint256 toBurn,
            uint256 toFoundation,
            uint256 toRevenue,
            uint256 toHighGuard,
            uint256 toDisputeCreator,
            address disputeCreator
        )
    {
        market.result = result;
        Market memory m = market;

        uint256 fullMarketSize = m.sideA + m.sideB;
        toBurn = (fullMarketSize * burnFee) / 10000;
        uint256 toVerifiers = (fullMarketSize * verificationFee) / 10000;
        toRevenue = (fullMarketSize * revenueFee) / 10000;
        toFoundation = (fullMarketSize * foundationFee) / 10000;
        if (
            m.result == MarketLib.ResultType.DRAW &&
            m.disputeCreator != address(0) &&
            !m.confirmed
        ) {
            // draw with dispute rejected - result set to draw
            toBurn += toVerifiers / 2;
            toHighGuard = toVerifiers / 2;
        } else if (m.result == MarketLib.ResultType.DRAW && m.confirmed) {
            // dispute confirmed - result set to dra
            toHighGuard = toVerifiers / 2;
            toDisputeCreator = toVerifiers - toHighGuard;
            disputeCreator = m.disputeCreator;
        }

        emit CloseMarket(m.result);
    }

    /// @notice Check market status before closing
    /// @param m Market info
    /// @param verificationPeriod Verification Period
    /// @param disputePeriod Dispute Period
    function beforeClosingCheck(
        Market memory m,
        uint256 verificationPeriod,
        uint256 disputePeriod
    ) external view {
        if (m.result != MarketLib.ResultType.NULL) {
            revert ("MarketIsClosed");
        }

        if (m.disputeCreator != address(0)) {
            revert ("DisputeNotSolvedYet");
        }

        uint256 disputePeriodEnds = m.startVerificationTimestamp +
            verificationPeriod +
            disputePeriod;
        if (block.timestamp < disputePeriodEnds) {
            revert ("DisputePeriodIsNotEndedYet");
        }
    }

    /// @notice Withdraws Prediction Reward
    /// @param m Market info
    /// @param feesSum Sum of all fees
    /// @param predictionWithdrawn Storage of withdraw statuses
    /// @param predictionsA PredictionsA of predictor
    /// @param predictionsB PredictionsB of predictor
    /// @param predictor Predictor address
    /// @return 0 Amount to withdraw(transfer)
    function withdrawPredictionReward(
        Market memory m,
        uint256 feesSum,
        mapping(address => bool) storage predictionWithdrawn,
        uint256 predictionsA,
        uint256 predictionsB,
        address predictor
    ) external returns (uint256) {
        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }
        if (predictionWithdrawn[predictor]) {
            revert ("AlreadyWithdrawn");
        }

        predictionWithdrawn[predictor] = true;

        uint256 toWithdraw = calculatePredictionReward(
            m,
            predictionsA,
            predictionsB,
            feesSum
        );
        if (toWithdraw == 0) {
            revert ("NothingToWithdraw");
        }

        emit WithdrawReward(predictor, 1, toWithdraw);

        return toWithdraw;
    }

    /// @notice Withdraws Verification Reward
    /// @param m Market info
    /// @param v Verification info
    /// @param power Power of vNFT used for verification
    /// @param verificationFee Verification Fee
    /// @return toVerifier Amount of tokens for verifier
    /// @return toDisputeCreator Amount of tokens for dispute creator
    /// @return toHighGuard Amount of tokens for HG
    /// @return vNftBurn If vNFT need to be burned
    function withdrawVerificationReward(
        Market memory m,
        Verification memory v,
        uint256 power,
        uint256 verificationFee
    )
        external
        returns (
            uint256 toVerifier,
            uint256 toDisputeCreator,
            uint256 toHighGuard,
            bool vNftBurn
        )
    {
        if (m.result == MarketLib.ResultType.NULL) {
            revert ("MarketIsNotClosedYet");
        }

        if (v.withdrawn) {
            revert ("AlreadyWithdrawn");
        }

        if (m.result == MarketLib.ResultType.DRAW) {
            // draw - withdraw verifier token
            return (0, 0, 0, false);
        }

        uint256 verificatorsFees = ((m.sideA + m.sideB) * verificationFee) /
            10000;
        if (v.side == (m.result == MarketLib.ResultType.AWON)) {
            // verifier voted properly
            uint256 reward = (v.power * verificatorsFees) /
                (v.side ? m.verifiedA : m.verifiedB);
            emit WithdrawReward(v.verifier, 2, reward);
            return (reward, 0, 0, false);
        } else {
            // verifier voted wrong
            if (m.confirmed) {
                toDisputeCreator = power / 2;
                toHighGuard = power - toDisputeCreator;
            }
            return (0, toDisputeCreator, toHighGuard, true);
        }
    }

    /// @dev Is verification period can be extended
    /// @param m Market info
    /// @return available true if available
    function _isVerificationPeriodExtensionAvailable(Market memory m)
        internal
        pure
        returns (bool available)
    {
        if (
            (m.reserved != 0) && ((m.reserved >= m.sideA) || (m.reserved >= m.sideB)) && (!m.extended)
        ) {
            available = true;
        }
    }

    /// @notice Is verification period can be extended
    /// @param m Market info
    /// @return available true if available
    function isVerificationPeriodExtensionAvailable(Market memory m)
        public
        pure
        returns (bool available)
    {
        return(_isVerificationPeriodExtensionAvailable(m));
    }

    /// @dev Is verification period can be extended
    /// @param market Market storage
    /// @param verificationPeriod Verification Period
    /// @param disputePeriod Dispute Period
    function extendVerificationTime(Market storage market, uint256 verificationPeriod, uint256 disputePeriod) external {
        _extendVerificationTime(market, verificationPeriod, disputePeriod);
    }

    /// @dev Is verification period can be extended
    /// @param market Market storage
    /// @param verificationPeriod Verification Period
    /// @param disputePeriod Dispute Period
    function _extendVerificationTime(
        Market storage market,
        uint256 verificationPeriod,
        uint256 disputePeriod
    ) internal {
        Market memory m = market;

        if (_isVerified(m)) {
            revert ("MarketIsFullyVerified");
        }

        if (m.reserved != 0) {
            revert ("NothingReserved");
        }

        if (
            block.timestamp < m.startVerificationTimestamp + verificationPeriod
        ) {
            revert ("DisputePeriodIsNotStartedYet");
        }

        if (
            block.timestamp >=
            m.startVerificationTimestamp + verificationPeriod + disputePeriod
        ) {
            revert ("DisputePeriodIsEnded");
        }

        if (!_isVerificationPeriodExtensionAvailable(m)) {
            revert ("VerifcationPeriodExtensionUnavailable");
        }

        market.startVerificationTimestamp =
            m.startVerificationTimestamp +
            uint64(verificationPeriod);
        market.reserved = 0;
    }

    /// @notice Privilege Verify
    /// @param market Market Storage
    /// @param verifications Verifications array storage
    /// @param verificationPeriod Verification Period
    /// @param requester Requester address
    /// @param power Power of vNFT
    /// @param side Side of verification
    function privilegeVerify(
        Market storage market,
        Verification[] storage verifications,
        uint256 verificationPeriod,
        address requester,
        uint256 power,
        bool side
    ) external {
        MarketLib.Market memory m = market;
        if (m.privilegeNftStaker != requester) {
            revert ("IncorrectOwner");
        }
        if (m.reserved == 0) {
            revert ("PrivilegeCanVerifyOnce");
        }

        market.reserved = 0;
        market.privilegeNftStaker = address(0);

        _verify(
            market,
            verifications,
            requester,
            verificationPeriod,
            power,
            m.privilegeNftId,
            side
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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