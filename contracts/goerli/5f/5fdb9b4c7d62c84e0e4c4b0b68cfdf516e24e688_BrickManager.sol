// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./BrickExchange.sol";
import "./IBrickToken.sol";
import "./IBrickNft.sol";
import "./IBrickExchange.sol";
import "./RBAC.sol";

contract BrickManager is RBAC {

    uint256 constant BRICKLAYER_PRICE = 1;
    uint256 constant BROCKER_PRICE = 2;
    uint256 constant DEVELOPER_PRICE = 3;
    uint256 constant STAKE_TIME = 1 hours;
    uint256 constant PIXELS_MAX = 400;

    struct NftInfo {
        uint256 tokenId;
        address owner;
        uint8 nftType;
        uint256 capacity;
        uint256 balance;
        string uri;
    }

    struct Substake {
        uint256 stakeId;
        uint256 timeStamp;
        uint256 amount;
    }

    IBrickToken brickToken;
    IBrickNft brickNft;
    IBrickExchange exchange;

    address payable treasury;
    uint256 _stakesCounter;

    mapping (uint256 => uint8) _nftType;
    mapping(uint256 => uint256) private _nftBalances;
    mapping(uint256 => uint256) _stakedAmount;
    mapping(uint256 => uint256[]) _pixels; // occupied pixels for every nft
    mapping(uint256 => bool) _tapestry;
    mapping(uint256 => Substake[]) _substakes;

    event TokensAquired(address buyer, address withToken, uint256 tokenAmount, uint256 brickAmount);
    event NftAquired(address buyer, address withToken, uint256 tokenAmount, uint256 tokenId);
    event Deposit(address from, uint256 to, uint256 amount);
    event Withdraw(uint256 from, address to, uint256 amount);

    modifier onlyNftOwner(uint256 tokenId) {
        require (msg.sender == brickNft.ownerOf(tokenId), "You are not the owner of this Nft");
        _;
    }

    constructor(address treasury_) {
        treasury = payable(treasury_);
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    function setBrick(address brickToken_, address brickNft_, address exchange_) external onlyAdmin {
        brickToken = IBrickToken(brickToken_);
        brickNft = IBrickNft(brickNft_);
        exchange = IBrickExchange(exchange_);
    }

    function getBrickToken() public view returns (address) {
        return address(brickToken);
    }

    function getBrickNft() public view returns (address) {
        return address(brickNft);
    }

    function getTokenBalance(address user) public view returns (uint256) {
        return brickToken.balanceOf(user);
    }

    function getNftBalance(uint256 tokenId) public view returns (uint256) {
        return _nftBalances[tokenId];
    }

    function getNftPrice(uint8 nftType) public pure returns (uint256) {
        if (nftType == 1) {
            return BRICKLAYER_PRICE;
        } else if (nftType == 2) {
            return BROCKER_PRICE;
        } else if (nftType == 3) {
            return DEVELOPER_PRICE;
        } else {
            revert("BrickNft: Nft type is not supported");
        }
    }

    function getNftInfo(uint256 tokenId) public view returns (NftInfo memory) {
        NftInfo memory nft;
        nft.tokenId = tokenId;
        nft.owner = brickNft.ownerOf(tokenId);
        nft.nftType = _nftType[tokenId];
        nft.capacity = 2 * getNftPrice(nft.nftType);
        nft.balance = _nftBalances[tokenId];
        nft.uri = brickNft.getUri(tokenId);
        return nft;
    }

    function getNftList(address owner) public view returns (NftInfo[] memory){
        uint256 balance = brickNft.balanceOf(owner);
        NftInfo[] memory list = new NftInfo[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = brickNft.tokenOfOwnerByIndex(owner, i);
            NftInfo memory nft = getNftInfo(tokenId);
            list[i] = nft;
        }
        return list;
    }

    function getRateFromOracle(address tokenAddress) public view returns (int256, uint8) {
        return exchange.getRateFromOracle(tokenAddress);
    }

    function calculateBricAmount(address tokenAddress, uint256 amount) public view returns (uint256) {
        return exchange.calculateBricAmount(tokenAddress, amount);
    }

    function calculateTokenAmount(address tokenAddress, uint256 amount) public view returns (uint256, uint8) {
        return exchange.calculateTokenAmount(tokenAddress, amount);
    }

    // =============== Trading Part ===================

    function buyToken(address tokenAddress, uint256 amount, uint256 minBrickAllowed) public onlyRegistered {
        IERC20Metadata token = IERC20Metadata(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token Transfer: your allowance level is too low");
        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= amount, "Token Transfer: your balance is too low");
        uint256 bricAmount = exchange.calculateBricAmount(tokenAddress, amount);
        require (bricAmount > 0, "Cant buy zero bricks");
        require(bricAmount >= minBrickAllowed, "Resulting BRIC amount is below the slippage level");
        brickToken.mint(msg.sender, bricAmount);
        token.transferFrom(msg.sender, treasury, amount);
        emit TokensAquired(msg.sender, tokenAddress, amount, bricAmount);
    }

    function buyTokenWithEther(uint256 minBrickAllowed) public payable onlyRegistered {
        uint256 value = msg.value;
        uint256 bricAmount = exchange.calculateBricAmount(address(0), value);
        require (bricAmount > 0, "Cant buy zero bricks");
        require(bricAmount >= minBrickAllowed, "Resulting BRIC amount is below the slippage level");
        brickToken.mint(msg.sender, bricAmount);
        treasury.transfer((value));
        emit TokensAquired(msg.sender, address(0), value, bricAmount);
    }

    function buyNft(address tokenAddress, uint256 amount, uint8 nftType, string memory uri) public onlyRegistered {
        IERC20Metadata token = IERC20Metadata(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 nftPrice = getNftPrice(nftType);
        (uint256 tokenAmount,) = exchange.calculateTokenAmount(tokenAddress, nftPrice);
        require (amount >= tokenAmount, "Token Transfer: your balance is too low");
        require (allowance >= tokenAmount, "Token Transfer: your allowance level is too low");
        uint256 tokenId = brickNft.mint(msg.sender, uri);
        _nftType[tokenId] = nftType;
        brickToken.mint(msg.sender, nftPrice);
        brickToken.deposit(msg.sender, nftPrice);
        _nftBalances[tokenId] = nftPrice;
        token.transferFrom(msg.sender, treasury, amount);
        emit NftAquired(msg.sender, tokenAddress, amount, tokenId);
    }

    function buyNftWithEther(uint8 nftType, string memory uri) public payable onlyRegistered {
        uint256 value = msg.value;
        uint256 nftPrice = getNftPrice(nftType);
        uint256 bricAmount = exchange.calculateBricAmount(address(0), value);
        require(bricAmount >= nftPrice, "BrickNft: Not enought Ether to buy this NFT");
        uint256 tokenId = brickNft.mint(msg.sender, uri);
        _nftType[tokenId] = nftType;
        brickToken.mint(msg.sender, nftPrice);
        brickToken.deposit(msg.sender, nftPrice);
        _nftBalances[tokenId] = nftPrice;
        treasury.transfer((value)); // Implement cashback
        emit NftAquired(msg.sender, address(0), value, tokenId);
    }

    // =============== Token Transfer Part ===================

    function deposit(uint256 to, uint256 amount) external onlyNftOwner(to) {
        brickToken.deposit(msg.sender, amount);
        // brickNft.deposit(to, amount);
        uint8 nftType = _nftType[to];
        uint256 capacity = 2 * getNftPrice(nftType);
        require (_nftBalances[to] + amount <= capacity, "BrickNft: resulting amount of token on Nft balance is over its capacity");
        _nftBalances[to] += amount;
        emit Deposit(msg.sender, to, amount);
    }
    
    function withdraw(uint256 from, uint256 amount) external onlyNftOwner(from) {
        require (getUnstakedAmount(from) >= amount, "BrickNft: insufficient Nft balance");
        _nftBalances[from] -= amount;
        brickToken.withdraw(msg.sender, amount);
        emit Withdraw(from, msg.sender, amount);
    }

    // =============== Staking Part ===================

    function getStakedAmount(uint256 tokenId) public view returns (uint256) {
        return _stakedAmount[tokenId];
    }

    function getUnstakedAmount(uint256 tokenId) public view returns (uint256) {
        return _nftBalances[tokenId] - _stakedAmount[tokenId];
    }
    
    function getStakedPixels(uint256 tokenId) public view returns (uint256[] memory) {
        uint256[] storage list = _pixels[tokenId];
        return list;
    }

    function getSubstakes(uint256 tokenId) public view returns (Substake[] memory) {
        Substake[] storage list = _substakes[tokenId];
        return list;
    }

    // Function doesnt check if unstakedAmount >= amount
    function getRequiredPixelNumber(uint256 tokenId, uint256 amount) public view returns (uint256) {
        uint256 pixelNumber = (amount + _stakedAmount[tokenId] - 1) / (2 * BRICKLAYER_PRICE) + 1;
        uint256[] storage pixels = _pixels[tokenId];
        return pixelNumber - pixels.length;
    }

    function showAllOccupiedPixels() public view returns(bool[] memory) {
        bool[] memory list = new bool[](PIXELS_MAX);
        for (uint i = 1; i <= PIXELS_MAX; i++) {
            list[i-1] = _tapestry[i];
        }
        return list;
    }
    
    function stake(uint256 tokenId, uint256 amount, uint256[] calldata newPixels) external onlyNftOwner(tokenId) {
        uint256 unstakedAmount = _nftBalances[tokenId] - _stakedAmount[tokenId];
        require(amount <= unstakedAmount, "Staked amount exceeds your balance");
        require(amount > 0, "You cant stake zero brick tokens");
        uint256 pixelNumber = (amount + _stakedAmount[tokenId] - 1) / (2 * BRICKLAYER_PRICE) + 1;
        uint256[] storage pixels = _pixels[tokenId];
        require(pixels.length + newPixels.length == pixelNumber, "Wrong number of new pixels");

        _stakedAmount[tokenId] += amount;
        for (uint256 i = 0; i < newPixels.length; i++) {
            uint256 currentPixel = newPixels[i];
            require(_tapestry[currentPixel] == false, "This pixel is already occupied");
            pixels.push(currentPixel);
            _tapestry[currentPixel] = true;
        }
        _stakesCounter++;
        Substake memory sub = Substake(_stakesCounter, block.timestamp, amount);
        Substake[] storage list = _substakes[tokenId];
        list.push(sub);
    }

    function revoke(uint256 tokenId, uint256 stakeId) external onlyNftOwner(tokenId) {
        Substake[] storage list = _substakes[tokenId];
        uint256 stakeNumber = 0;
        for (uint i = 0; i < list.length; i++) {
            if (list[i].stakeId == stakeId) {
                stakeNumber = i + 1;
                break;
            }
        }
        require (stakeNumber != 0, "No such stake for given Nft");
        stakeNumber--;
        uint256 timeStamp = list[stakeNumber].timeStamp;
        require (timeStamp + STAKE_TIME <= block.timestamp, "This stake cant be revoked at this time");
        uint256 amount = list[stakeNumber].amount;
        amount = _stakedAmount[tokenId] - amount;
        _stakedAmount[tokenId] = amount;
        uint256 pixels = amount == 0 ? 0 : (amount - 1) / (2 * BRICKLAYER_PRICE) + 1;
        uint256[] storage pixelsList = _pixels[tokenId];
        pixels = pixelsList.length - pixels;
        for (uint i = 0; i < pixels; i++) {
            pixelsList.pop();
        }
        if (stakeNumber == list.length - 1) {
            list.pop();
        } else {
            Substake memory last = list[list.length - 1];
            list[stakeNumber] = last;
            list.pop();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./RBClient.sol";

contract BrickExchange is RBClient {

    uint256 constant ORACLE_UPDATE_TIME = 365 days;
    uint8 constant BRICK_DECIMALS = 0;
    mapping (address => address) oracles;

    constructor(address rbac_) RBClient(rbac_) {}
    
    function setOracle(address token_, address oracle_) public onlyAdmin {
        require (oracle_ != address(0x0), "Oracle address can't be zero address");
        oracles[token_] = oracle_;
    }

    function removeOracle(address token_) public onlyAdmin {
        if (oracles[token_] != address(0x0)) {
            oracles[token_] = address(0x0);
        }
    }

    function getOracle(address _token) view public returns (address) {
        return oracles[_token];
    }

    function getRateFromOracle(address tokenAddress) public view returns (int256, uint8) {
        
        require(oracles[tokenAddress] != address(0), "This cryptocurrency is not accepted for payment");
        
        AggregatorV3Interface oracle = AggregatorV3Interface(oracles[tokenAddress]);

        (, int256 answer,, uint256 oracleTimestamp,) = oracle.latestRoundData();
        
        uint256 blockTimestamp = block.timestamp;
        require(blockTimestamp - oracleTimestamp < ORACLE_UPDATE_TIME, "Price feed is too old");
        uint8 oracleDecimals = oracle.decimals();

        require(answer > 0, "Price feed is corrupted");
        return (answer, oracleDecimals);
    }

    function calculateBricAmount(address tokenAddress, uint256 amount) public view returns (uint256) {

        (int256 answer, uint8 oracleDecimals) = getRateFromOracle(tokenAddress);

        // TODO: reduce operations
        uint256 brickAmount = amount * uint256(answer) * 10 ** BRICK_DECIMALS;
        if (tokenAddress != address(0)) {
            brickAmount /= (10 ** (oracleDecimals + IERC20Metadata(tokenAddress).decimals()));
        } else {
            brickAmount /= (10 ** (oracleDecimals + 18));
        }

        return brickAmount;
    }

    function calculateTokenAmount(address tokenAddress, uint256 amount) public view returns (uint256, uint8) {

        (int256 answer, uint8 oracleDecimals) = getRateFromOracle(tokenAddress);

        // TODO: reduce operations
        uint8 tokenDecimals;
        if (tokenAddress != address(0)) {
            tokenDecimals = IERC20Metadata(tokenAddress).decimals();
        } else {
            tokenDecimals = 18;
        }
        uint256 tokenAmount = amount * (10 ** (oracleDecimals + tokenDecimals));
        tokenAmount /= (uint256(answer) * 10 ** BRICK_DECIMALS);

        return (tokenAmount, tokenDecimals);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBrickToken is IERC20, IERC20Metadata {
    
    function deposit(address from, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./RBClient.sol";

interface IBrickNft is IERC721Enumerable {

    function getNftBalance(uint256 tokenId) external view returns (uint256);
    function getNftType(uint256 tokenId) external view returns (uint8);
    function getUri(uint256 tokenId) external view returns (string memory);
    function getNftCapacity(uint8 nftType) external pure returns (uint256);
    function deposit(uint256 to, uint256 amount) external;
    function withdraw(uint256 from, uint256 amount) external;
    function mint(address owner, string memory uri) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBrickExchange {

    function setOracle(address token_, address oracle_) external;
    function removeOracle(address token_) external;
    function getOracle(address _token) view external;
    function getRateFromOracle(address tokenAddress) external view returns (int256, uint8);
    function calculateBricAmount(address tokenAddress, uint256 amount) external view returns (uint256);
    function calculateTokenAmount(address tokenAddress, uint256 amount) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RBAC is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant KYC_ROLE = keccak256('KYC');
    bytes32 public constant REGISTERED_ROLE = keccak256('REGISTERED');

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTERED_ROLE, KYC_ROLE);
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "This account doesn't have admin rights");
        _;
    }

    modifier onlyRegistered {
        require(hasRole(REGISTERED_ROLE, msg.sender), "This account is not registered");
        _;
    }

    function getHashDigest(string memory role_) pure public returns (bytes32) {
        return keccak256(bytes(role_));
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";

contract RBClient {
    
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant REGISTERED_ROLE = keccak256('REGISTERED');
    IAccessControl rbac;
    
    constructor (address rbac_) {
        rbac = IAccessControl(rbac_);
    }

    modifier onlyManager {
        require(msg.sender == address(rbac), "Caller is not the Manager Contract");
        _;
    }

    modifier onlyAdmin {
        require(rbac.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "This account doesn't have admin rights");
        _;
    }
    
    modifier onlyMinter {
        require(rbac.hasRole(MINTER_ROLE, msg.sender), "This account doesn't have rights to mint tokens");
        _;
    }

    modifier onlyRegistered {
        require(rbac.hasRole(REGISTERED_ROLE, msg.sender), "This account is not registered");
        _;
    }

    function setRBAC(address rbac_) public onlyAdmin {
        rbac = IAccessControl(rbac_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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