/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PrivateSale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256[]) public _contributions;
    mapping(address => uint256) public _initialTimestamp;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endPrivateSale;
    uint256 public availableTokens;
    bool public startRefund = false;
    uint256 public refundStartDate;

    event TokensPurchased(
        address purchaser,
        address beneficiary,
        uint256 value,
        uint256 amount
    );
    event Refund(address recipient, uint256 amount);

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token
    ) {
        require(rate > 0, "Private-Sale: rate is 0");
        require(wallet != address(0), "Private-Sale: wallet is the zero address");
        require(
            address(token) != address(0),
            "Private-Sale: token is the zero address"
        );

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    receive() external payable {
        if (endPrivateSale > 0 && block.timestamp < endPrivateSale) {
            buyTokens(_msgSender());
        } else {
            endPrivateSale = 0;
            revert("Private-Sale is closed");
        }
    }

    //Start Private-Sale
    function startPrivateSale(
        uint256 endDate
    ) external onlyOwner icoNotActive {
        startRefund = false;
        refundStartDate = 0;
        availableTokens = _token.balanceOf(address(this));
        require(endDate > block.timestamp, "duration should be > 0");
        require(availableTokens > 0, "availableTokens must be > 0");
        endPrivateSale = endDate;
        _weiRaised = 0;
    }

    function stopPrivateSale() external onlyOwner icoActive {
        endPrivateSale = 0;
        _forwardFunds();
    }

    //Private-Sale
    function buyTokens(address beneficiary)
        public
        payable
        nonReentrant
        icoActive
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokens = availableTokens - tokens;
        for (uint i = 0; i < 8; i++) {
            _contributions[beneficiary].push(weiAmount.div(8));
        }
        _initialTimestamp[beneficiary] = block.timestamp;
        // _contributions[beneficiary] = _contributions[beneficiary].add(
        //     weiAmount
        // );
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Private-sale: weiAmount is 0");
        require((_weiRaised + weiAmount) <= availableTokens, "Hard Cap reached");
        this;
    }

    function claimTokens() external icoNotActive {
        require(startRefund == false);
        uint256 month = getMonth(msg.sender);
        uint256 _tempAmt = 0;
        for(uint i = 0; i <= month; i++) {
            _tempAmt += _contributions[msg.sender][i];
            _contributions[msg.sender][i] = 0;
        }
        uint256 tokensAmt = _getTokenAmount(_tempAmt);
        // _contributions[msg.sender][0] = 0;
        _token.transfer(msg.sender, tokensAmt);
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        require(weiAmount > 0, "Amount is 0");
        return weiAmount.mul(_rate);
        // return weiAmount.mul(_rate).div(10**18);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function withdraw() external onlyOwner icoNotActive {
        require(
            startRefund == false || (refundStartDate + 3 days) < block.timestamp
        );
        require(address(this).balance > 0, "Contract has no money");
        _wallet.transfer(address(this).balance);
    }

    function checkContribution(address addr) public view returns (uint256) {
        uint256 tempAmt = 0;
        for(uint i = 0; i < 8; i++) {
            tempAmt += _contributions[addr][i];
        }
        return tempAmt;
    }

    function setRate(uint256 newRate) external onlyOwner icoNotActive {
        _rate = newRate;
    }

    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive {
        availableTokens = amount;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function setWalletReceiver(address payable newWallet) external onlyOwner {
        _wallet = newWallet;
    }

    function takeTokens(IERC20 tokenAddress) public onlyOwner icoNotActive {
        IERC20 tokenERC20 = tokenAddress;
        uint256 tokenAmt = tokenERC20.balanceOf(address(this));
        require(tokenAmt > 0, "ERC-20 balance is 0");
        tokenERC20.transfer(_wallet, tokenAmt);
    }

    function refundMe() public icoNotActive {
        require(startRefund == true, "no refund available");
        uint256 amount = 0;
        for(uint i = 0; i < 8; i++) {
            amount += _contributions[msg.sender][i];
        }
        if (address(this).balance >= amount) {
            for(uint i = 0; i < 8; i++) {
                _contributions[msg.sender][i] = 0;
            }
            // _contributions[msg.sender] = 0;
            if (amount > 0) {
                address payable recipient = payable(msg.sender);
                recipient.transfer(amount);
                emit Refund(msg.sender, amount);
            }
        }
    }

    // Calculate which month into the claim are
    function getMonth(address addr) internal view returns (uint256) {
        uint256 current = block.timestamp;
        return current.sub(_initialTimestamp[addr]).div(30 days);
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    modifier icoActive() {
        require(
            endPrivateSale > 0 && block.timestamp < endPrivateSale && availableTokens > 0,
            "ICO must be active"
        );
        _;
    }

    modifier icoNotActive() {
        require(endPrivateSale < block.timestamp, "ICO should not be active");
        _;
    }
}