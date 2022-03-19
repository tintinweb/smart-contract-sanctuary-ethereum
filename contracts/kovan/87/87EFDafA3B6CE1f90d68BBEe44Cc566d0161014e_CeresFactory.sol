// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ICeresFactory.sol";
import "./interface/ICeresCreator.sol";
import "./interface/IOracle.sol";
import "./common/Ownable.sol";

contract CeresFactory is ICeresFactory, Ownable {

    address public override getBank;
    address public override getReward;
    uint256 public stakingCount;
    address[] public tokens;
    address[] public override volTokens;
    mapping(address => TokenInfo) public tokenInfo;
    mapping(address => bool) public override isValidStaking;
    ICeresCreator public creator;

    modifier tokenAdded(address token) {
        require(tokenInfo[token].tokenAddress != address(0), "Token is not added");
        _;
    }

    constructor(address _owner, address _creator) Ownable(_owner) {
        creator = ICeresCreator(_creator);
    }

    /* ---------- Views ---------- */
    function getTokens() external view override returns (address[] memory){
        return tokens;
    }

    function getTokensLength() external view override returns (uint256){
        return tokens.length;
    }

    function getVolTokensLength() external view override returns (uint256){
        return volTokens.length;
    }

    function getTokenInfo(address token) external view override returns (TokenInfo memory){
        return tokenInfo[token];
    }

    function getStaking(address token) external view override returns (address) {
        return tokenInfo[token].stakingAddress;
    }

    function getOracle(address token) external view override returns (address) {
        return tokenInfo[token].oracleAddress;
    }

    function getQuoteToken() external view returns (address) {
        return creator.quoteToken();
    }

    function isStakingRewards(address staking) external view override returns (bool) {
        return tokenInfo[staking].isStakingRewards;
    }

    function isStakingMineable(address staking) external view override returns (bool) {
        return tokenInfo[staking].isStakingMineable;
    }

    function getTokenPrice(address token) external view override returns (uint256) {
        return IOracle(tokenInfo[token].oracleAddress).getPrice();
    }

    function getValidStakings() external view override returns (address[] memory _stakings){
        _stakings = new address[](stakingCount);

        uint256 index = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address staking = tokenInfo[tokens[i]].stakingAddress;
            if (staking != address(0)) {
                _stakings[index] = staking;
                index++;
            }
        }
        return _stakings;
    }

    /* ---------- RAA ---------- */
    function createStaking(address token, bool ifCreateOracle) external override returns (address staking, address oracle){

        require(tokenInfo[token].tokenAddress == address(0), "Staking already created!");

        staking = creator.createStaking(token);
        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].stakingAddress = staking;

        if (ifCreateOracle) {
            oracle = createOracle(token);
            tokenInfo[token].oracleAddress = oracle;
        }

        tokens.push(token);
        stakingCount++;
        isValidStaking[staking] = true;
    }

    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle)
        external override returns (address staking, address oracle){

        require(tokenInfo[token].tokenAddress == address(0), "Staking already created!");

        staking = creator.createStaking(token);

        // create pair, add liquidity
        IERC20(token).transferFrom(msg.sender, address(creator), tokenAmount);
        IERC20(creator.quoteToken()).transferFrom(msg.sender, address(creator), quoteAmount);
        creator.addLiquidity(token, tokenAmount, quoteAmount, msg.sender);

        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].stakingAddress = staking;

        if (ifCreateOracle) {
            oracle = createOracle(token);
            tokenInfo[token].oracleAddress = oracle;
        }

        tokens.push(token);
        stakingCount++;
        isValidStaking[staking] = true;
    }

    function createOracle(address token) public override returns (address oracle) {
        require(tokenInfo[token].oracleAddress == address(0), "Oracle already created!");

        oracle = creator.createOracle(token);
        tokenInfo[token].oracleAddress = oracle;
    }

    /* ---------- Functions ---------- */
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool isStakingRewards,
        bool isStakingMineable) external override onlyOwner {

        require(tokenInfo[token].tokenAddress == address(0), "Staking already added!");
        require(token != address(0) && staking != address(0), "Staking parameters can not be zero address!");
        require(tokenType > 0, "Token type must be bigger than zero!");

        _beforeTypeChange(token, tokenType);

        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].tokenType = tokenType;
        tokenInfo[token].stakingAddress = staking;
        tokenInfo[token].isStakingRewards = isStakingRewards;
        tokenInfo[token].isStakingMineable = isStakingMineable;
        tokens.push(token);

        if (oracle != address(0))
            tokenInfo[token].oracleAddress = oracle;

        stakingCount ++;
        isValidStaking[staking] = true;
    }

    function removeStaking(address token, address staking) external override onlyOwner {
        isValidStaking[staking] = false;
        if (tokenInfo[token].stakingAddress == staking)
            tokenInfo[token].stakingAddress = address(0);
        stakingCount--;
    }
    
    function updateOracles(address[] memory tokens) external override {
        for (uint256 i = 0; i < tokens.length; i++)
            updateOracle(tokens[i]);
    }

    function updateOracle(address token) public override {
        address oracle = tokenInfo[token].oracleAddress;
        if (IOracle(oracle).updatable())
            IOracle(oracle).update();
    }

    /* ---------- Settings ---------- */
    function setBank(address _bank) external override onlyOwner {
        getBank = _bank;
    }

    function setCreator(address _creator) external override onlyOwner {
        creator = ICeresCreator(_creator);
    }

    function setReward(address _reward) external override onlyOwner {
        getReward = _reward;
    }

    function setTokenType(address _token, uint256 _tokenType) external override onlyOwner tokenAdded(_token) {
        _beforeTypeChange(_token, _tokenType);
        tokenInfo[_token].tokenType = _tokenType;
    }

    function setStaking(address _token, address _staking) external override onlyOwner tokenAdded(_token) {
        isValidStaking[tokenInfo[_token].stakingAddress] = false;
        isValidStaking[_staking] = true;
        tokenInfo[_token].stakingAddress = _staking;
    }

    function setOracle(address _token, address _oracle) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].oracleAddress = _oracle;
    }

    function setIsStakingRewards(address _token, bool _isStakingRewards) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].isStakingRewards = _isStakingRewards;
    }

    function setIsStakingMineable(address _token, bool _isStakingMineable) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].isStakingMineable = _isStakingMineable;
    }
    
    // records vol address before type change every time
    function _beforeTypeChange(address _token, uint256 _tokenType) internal {

        uint256 oldType = tokenInfo[_token].tokenType;
        if (_tokenType != 4 && oldType != 4)
            return;

        if (oldType != 4 && _tokenType == 4) // add
            volTokens.push(_token);

        if (oldType == 4 && _tokenType != 4) {// delete
            for (uint256 i = 0; i < volTokens.length; i++) {
                if (volTokens[i] == _token)
                    delete volTokens[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _owner_) {
        _setOwner(_owner_);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only Owner!");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresCreator {
    
    /* ---------- Views ---------- */
    function quoteToken() external view returns (address);

    /* ---------- Functions ---------- */
    function createStaking(address token) external returns (address);
    function createOracle(address token) external returns (address);
    function addLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address tokenAddress;
        uint256 tokenType; // 1: asc, 2: crs, 3: col, 4: vol;
        address stakingAddress;
        address oracleAddress;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function getBank() external view returns (address);
    function getReward() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getOracle(address token) external view returns (address);
    function isValidStaking(address sender) external view returns (bool);
    function volTokens(uint256 index) external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getVolTokensLength() external view returns (uint256);
    function getValidStakings() external view returns (address[] memory);
    function getTokenPrice(address token) external view returns(uint256);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);

    /* ---------- Functions ---------- */
    function setBank(address newAddress) external;
    function setReward(address newReward) external;
    function setCreator(address creator) external;
    function setTokenType(address token, uint256 tokenType) external;
    function setStaking(address token, address staking) external;
    function setOracle(address token, address oracle) external;
    function setIsStakingRewards(address token, bool isStakingRewards) external;
    function setIsStakingMineable(address token, bool isStakingMineable) external;
    function updateOracles(address[] memory tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool isStakingRewards, bool isStakingMineable) external;
    function removeStaking(address token, address staking) external;

    /* ---------- RRA ---------- */
    function createStaking(address token, bool ifCreateOracle) external returns (address staking, address oracle);
    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle) external returns (address staking, address oracle);
    function createOracle(address token) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracle {

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function getPrice() external view returns (uint256);
    function updatable() external view returns (bool);

    /* ---------- Functions ---------- */
    function update() external;
}