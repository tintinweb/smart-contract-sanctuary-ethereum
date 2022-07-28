// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Claimable.sol";
import "./utils/ImmutableOwnable.sol";

// When called `drink`, it sends tokens to the `_to`
// As a prerequisite, it shall get enough tokens on the balance
contract ZkpFaucet is Claimable, ImmutableOwnable {
    address public immutable token;
    uint256 public cupSize;
    uint256 public tokenPrice;
    uint256 public maxAmountToPay;
    uint256 public maxDrinkCount;

    // @notice  store the whitelisted addresses who can drink
    mapping(address => bool) public whitelistedAddresses;
    // @notice store the number of times each user has drank
    mapping(address => uint256) public drinkCount;

    // @notice enabling/disabling check for whitelisted addresses
    bool public restrictToWhitelisted;
    // @notice enabling/disabling check for requests count
    bool public restrictToMaxDrinkCount;

    constructor(
        address _owner,
        address _token,
        uint256 _tokenPrice,
        uint256 _maxAmountToPay,
        uint256 _cupSize,
        uint256 _maxDrinkCount
    ) ImmutableOwnable(_owner) {
        require(_cupSize > 0, "invalid cup size");
        require(_token != address(0), "invalid token address");

        token = _token;
        tokenPrice = _tokenPrice;
        cupSize = _cupSize;
        maxAmountToPay = _maxAmountToPay;
        maxDrinkCount = _maxDrinkCount;
    }

    /**
     * @notice if restrictToWhitelisted is true, then
     * check if the sender is whitelisted
     */
    modifier onlyWhitelisted(address _address) {
        require(
            !restrictToWhitelisted || isWhitelisted(_address),
            "Not whitelisted"
        );
        _;
    }

    /**
     * @notice if restrictToMaxDrinkCount is true, then
     * check if the sender is already received token
     */
    modifier checkDrinkCount(address _address) {
        require(
            !restrictToMaxDrinkCount || isAllowedToDrink(_address),
            "Too much drink count"
        );
        _;
    }

    /**
     * @notice if token price is more than 0, then
     * check the value
     */
    modifier validatePrice() {
        require(msg.value <= maxAmountToPay, "High value");
        require(msg.value >= tokenPrice, "Low value");
        _;
    }

    /**
     * @notice return true if the address is whitelisted, otherwise false
     * @dev it helps when contract is restricted to whitelisted addresses
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistedAddresses[_account];
    }

    /**
     * @notice return true if the user request counts are
     * less than or equal to maxDrinkCount, otherwise retuens false
     * @dev it helps when contract is restricted to requests count.
     */
    function isAllowedToDrink(address _account) public view returns (bool) {
        return drinkCount[_account] < maxDrinkCount;
    }

    /**
     * @notice send tokens to `_to`
     * @param _to the receiver addresss
     * @dev if restrictToWhitelisted is true, then check if the
     * sender is whitelisted.
     * if the restrictToMaxReq is true, then check if the
     * sender is already received token.
     */
    function drink(address _to)
        external
        payable
        validatePrice
        onlyWhitelisted(msg.sender)
        checkDrinkCount(_to)
    {
        drinkCount[_to]++;

        safeTransfer(token, _to, getCupSize(msg.value));
    }

    function getCupSize(uint256 _amountToPay) public view returns (uint256) {
        return tokenPrice > 0 ? _amountToPay / tokenPrice : cupSize;
    }

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    // Owner functions
    /**
     * @notice toggle restrictToWhitelisted
     */
    function toggleRestrictToWhitelisted() external onlyOwner {
        restrictToWhitelisted = !restrictToWhitelisted;
    }

    /**
     * @notice toggle restrictToMaxReq
     */
    function toggleRestrictToMaxDrinkCount() external onlyOwner {
        restrictToMaxDrinkCount = !restrictToMaxDrinkCount;
    }

    /**
     * @notice Add multiple addresses to the whitelisted list
     * @param _whitelistedAddresses array of addresses to be added
     * @param _whitelisted array of boolen values to be mapped to the addresses
     */
    function addWhitelistedMultiple(
        address[] calldata _whitelistedAddresses,
        bool[] calldata _whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < _whitelistedAddresses.length; ) {
            whitelistedAddresses[_whitelistedAddresses[i]] = _whitelisted[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice update the amount that can be received by users
     * @param _cupSize the amount that can be received by users
     */
    function updateCupSize(uint256 _cupSize) external onlyOwner {
        require(_cupSize > 0, "invalid size");
        cupSize = _cupSize;
    }

    /**
     * @notice update the token price.
     * @param _tokenPrice the price of each token
     */
    function updateTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * @notice update the token price.
     * @param _maxDrinkCount the maximum number of times the
     * drink function can be called
     */
    function updateMaxDrinkCount(uint256 _maxDrinkCount) external onlyOwner {
        require(_maxDrinkCount > 0, "invalid max request count");
        maxDrinkCount = _maxDrinkCount;
    }

    function claimErc20(
        address _claimedToken,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "recipient cannot be 0");

        _claimErc20(_claimedToken, _to, _amount);
    }

    function claimNative(address _to) external onlyOwner {
        require(_to != address(0), "recipient cannot be 0");

        (bool sent, ) = _to.call{ value: address(this).balance }(""); // solhint-disable-line avoid-low-level-calls
        require(sent, "Failed to send native");
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens from this contract.
 */
contract Claimable {
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "claimErc20: TRANSFER_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}