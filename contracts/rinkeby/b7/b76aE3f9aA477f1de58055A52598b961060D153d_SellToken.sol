// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract SellToken is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public PROJECT_FEE = 0.001 ether;
    uint256 public TOTAL_AMOUNT = 10000 * 10**12 * 10**18;

    uint256 public WAS_SALE;
    uint256 public PANCAKE_PRICE;
    uint256 public TIME_STEP = 0;
    uint256 public PERCENT_COM = 10;

    address payable public saleWallet;

    struct User {
        address owner;
        address refferer;
        uint256 totalBuy;
        uint256 lastBuy;
        uint256 totalRef;
        uint256 totalAmountRef;
    }

    mapping(address => User) internal users;
    mapping(address => uint256) tokenHolders;

    uint256 public START_TIME;
    uint256 public END_TIME;
    IERC20 public SALE_TOKEN;
    IERC20 public BUY_TOKEN;
    uint256 public MIN_SALE;

    event FeePayed(address indexed user, uint256 totalAmount);
    event TokenPurchase(address indexed purchaser, uint256 amount);
    event RefCom(address indexed purchaser, address refferer, uint256 amount);

    constructor(
        address payable _saleWallet,
        address _saleToken,
        address _buyToken
    ) {
        saleWallet = _saleWallet;
        PANCAKE_PRICE = 0.00000000557487 ether;
        MIN_SALE = 50 ether;
    }

    function setFeeSale(uint256 _fee) public onlyOwner {
        PROJECT_FEE = _fee;
    }

    function setSaleToken(address _address) public onlyOwner {
        SALE_TOKEN = IERC20(_address);
    }

    function setBuyToken(address _address) public onlyOwner {
        BUY_TOKEN = IERC20(_address);
    }

    function setTotalAmount(uint256 _slot) public onlyOwner {
        TOTAL_AMOUNT = _slot;
    }

    function setSaleWallet(address payable _wallet) public onlyOwner {
        saleWallet = _wallet;
    }

    function setStartSale(uint256 time) public onlyOwner {
        START_TIME = time;
    }

    function setEndSale(uint256 time) public onlyOwner {
        END_TIME = time;
    }

    function setPancakePrice(uint256 price) public onlyOwner {
        PANCAKE_PRICE = price;
    }

    function setMinSale(uint256 _minSale) public onlyOwner {
        MIN_SALE = _minSale;
    }

    /**
     * @dev buyToken
     */
    function buyToken(uint256 _amountBuyToken, address refferer)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        _buy(_msgSender(), _amountBuyToken, refferer);
    }

    function getPrice(uint256 _amountBuyToken) public view returns (uint256) {
        return _amountBuyToken.div(PANCAKE_PRICE.mul(80).div(100)).mul(10**18);
    }

    /**
     * @dev _buy
     */
    function _buy(
        address _beneficiary,
        uint256 _amountBuyToken,
        address _refferer
    ) internal {
        User storage user = users[_beneficiary];
        uint256 _amount = getPrice(_amountBuyToken);
        require(_amountBuyToken >= MIN_SALE, "not enough min sale");
        require(msg.value == PROJECT_FEE, "Required: Must be paid fee to buy");
        require(
            BUY_TOKEN.allowance(msg.sender, address(this)) >= _amountBuyToken,
            "Token allowance too low"
        );
        WAS_SALE = WAS_SALE.add(_amount);
        BUY_TOKEN.transferFrom(_msgSender(), saleWallet, _amountBuyToken);
        require(WAS_SALE <= TOTAL_AMOUNT, "Required: Not engough slot to buy");
        if (_refferer != address(0) && _refferer != _msgSender()) {
            User storage userRef = users[_refferer];
            require(userRef.totalBuy > 0, "Required: Refferer muste be buy");
            uint256 amountRef = _amount.mul(PERCENT_COM).div(100);
            SALE_TOKEN.transfer(userRef.owner, amountRef);
            userRef.totalAmountRef = userRef.totalAmountRef.add(amountRef);
            emit RefCom(_beneficiary, _refferer, amountRef);
            if(user.refferer == address(0)) {
                user.refferer = _refferer;
            }
            userRef.totalRef = userRef.totalRef.add(1);
        }
        tokenHolders[_beneficiary] = tokenHolders[_beneficiary].add(
            _amount
        );
        // update state
        user.owner = _beneficiary;
        user.totalBuy = user.totalBuy.add(_amount);
        user.lastBuy = block.timestamp;

        _deliverTokens(_beneficiary, _amount);
        emit TokenPurchase(_beneficiary, _amount);
        emit FeePayed(_beneficiary, PROJECT_FEE);
    }

     /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        saleWallet.transfer(msg.value);
        SALE_TOKEN.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}