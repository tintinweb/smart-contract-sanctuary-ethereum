/*
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || |      __      | || |    ______    | || |  _________   | || |  _________   | || |  ____  ____  | |
| |  |_   _ \    | || |     /  \     | || |  .' ___  |   | || | |_   ___  |  | || | |  _   _  |  | || | |_   ||   _| | |
| |    | |_) |   | || |    / /\ \    | || | / .'   \_|   | || |   | |_  \_|  | || | |_/ | | \_|  | || |   | |__| |   | |
| |    |  __'.   | || |   / ____ \   | || | | |    ____  | || |   |  _|  _   | || |     | |      | || |   |  __  |   | |
| |   _| |__) |  | || | _/ /    \ \_ | || | \ `.___]  _| | || |  _| |___/ |  | || |    _| |_     | || |  _| |  | |_  | |
| |  |_______/   | || ||____|  |____|| || |  `._____.'   | || | |_________|  | || |   |_____|    | || | |____||____| | |
| |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// interface IUniFactory   : Interface of Uniswap Router

interface IUniFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// interface IUniRouter  : Interface of Uniswap

interface IUniRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 _liquedity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// interface IERC20 : IERC20 Token Interface which would be used in calling token contract
interface IERC20 {
    function totalSupply() external view returns (uint256); //Total Supply of Token

    function decimals() external view returns (uint8); // Decimal of TOken

    function symbol() external view returns (string memory); // Symbol of Token

    function name() external view returns (string memory); // Name of Token

    function balanceOf(address account) external view returns (uint256); // Balance of TOken

    //Transfer token from one address to another

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Get allowance to the spacific users

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    // Give approval to spend token to another addresses

    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer token from one address to another

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //Trasfer Event
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Approval Event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// This contract helps to add Owners
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// Interface IRewardDistributor : Interface that is used by  Reward Distributor

interface IRewardDistributor {
    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    // function depositEth() external payable;

    function process(uint256 gas) external;

    function claimReward(address _user) external;

    function getPaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function getUnpaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function totalDistributed() external view returns (uint256);

    function minEth() external view returns (uint256);
}

// RewardDistributor : It distributes reward amoung holders

contract RewardDistributor is IRewardDistributor {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IUniRouter public router;

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 days;
    uint256 public _minEth = 56000000000000000;
    uint256 public minDistribution;

    uint256 currentIndex;

    bool initialized;
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        _token = msg.sender;
        router = IUniRouter(_router);
    }

    receive() external payable {
        depositEth(msg.value);
    }

    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(
        address shareholder,
        uint256 amount
    ) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeReward(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
    }

    function depositEth(uint256 amount) internal {
        totalRewards = totalRewards.add(amount);
        rewardsPerShare = rewardsPerShare.add(
            rewardsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    // function for chaniging the eth|Contract balance to claim reward
    function _setMinEThContractBalance(uint256 _ethAmount) public onlyToken {
        _minEth = _ethAmount;
    }

    function minEth() public view returns (uint256) {
        return _minEth;
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeReward(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(
        address shareholder
    ) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    //This function distribute the amounts
    function distributeReward(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeRewards(
                shares[shareholder].amount
            );
        }
    }

    function claimReward(address _user) external {
        if (address(this).balance >= _minEth) {
            distributeReward(_user);
        }
    }

    function getPaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalRewards = getCumulativeRewards(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalRewards <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalRewards.sub(shareholderTotalExcluded);
    }

    function getCumulativeRewards(
        uint256 share
    ) internal view returns (uint256) {
        return share.mul(rewardsPerShare).div(rewardsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function _withdrawTokenFunds(
        address _reciverAddress,
        uint256 _amount
    ) public onlyToken {
        payable(_reciverAddress).transfer(_amount);
    }
}

// main contract of Token
contract BagETH is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "BagETH"; // Name
    string private constant _symbol = "GET"; // Symbol
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 200_000_000 * 10 ** _decimals; //Token Decimals

    uint256 maxTxnLimit;
    uint256 maxHoldLimit;

    IUniRouter public router; //Router
    address public uniPair; //Pair

    uint256 public totalBuyFee = 3_00; //Total Buy Fee
    uint256 public totalSellFee = 3_00; //Total Sell Fee
    uint256 public feeDivider = 100_00; // Fee deniminator

    RewardDistributor public distributor;
    uint256 public distributorGas = 50000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRewardExempt;
    mapping(address => bool) public _isExcludedFromMaxTxn;
    mapping(address => bool) public _isExcludedMaxHolding;

    bool public enableSwap = true;
    uint256 public swapLimit = 50000 * (10 ** _decimals);
    uint256 public minTokenHoldingForReward;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountEth, uint256 amountBOG);

    // intializing the addresses

    constructor() {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        minTokenHoldingForReward = 50000 * 10 ** 18;
        maxTxnLimit = 2000000 * 10 ** 18;
        maxHoldLimit = 600000000 * 10 ** 18;
        router = IUniRouter(_router);
        uniPair = IUniFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        distributor = new RewardDistributor(_router);

        isRewardExempt[uniPair] = true;
        isRewardExempt[
            address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279)
        ] = true;
        isRewardExempt[address(this)] = true;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279)] = true;
        isFeeExempt[address(this)] = true;

        _isExcludedFromMaxTxn[
            address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279)
        ] = true;
        _isExcludedFromMaxTxn[uniPair] = true;
        _isExcludedFromMaxTxn[address(this)] = true;
        _isExcludedFromMaxTxn[address(router)] = true;

        _isExcludedMaxHolding[address(this)] = true;
        _isExcludedMaxHolding[
            address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279)
        ] = true;
        _isExcludedMaxHolding[address(router)] = true;
        _isExcludedMaxHolding[uniPair] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(uniPair)] = _totalSupply;
        _balances[
            address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279)
        ] = _totalSupply;
        emit Transfer(
            address(0),
            address(0xB9694d9d3E964f89b55eb45704D9D7e2BA6B7279),
            _totalSupply
        );
    }

    receive() external payable {}

    // totalSupply() : Shows total Supply of token

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    //decimals() : Shows decimals of token

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    // symbol() : Shows symbol of function

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    // name() : Shows name of Token

    function name() external pure override returns (string memory) {
        return _name;
    }

    // balanceOf() : Shows balance of the spacific user

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //allowance()  : Shows allowance of the address from another address

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    // approve() : This function gives allowance of token from one address to another address
    //  ****     : Allowance is checked in TransferFrom() function.

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // approveMax() : approves the token amount to the spender that is maximum amount of token

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    // transfer() : Transfers tokens  to another address

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    // transferFrom() : Transfers token from one address to another address by utilizing allowance

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    // _transfer() :   called by external transfer and transferFrom function

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!_isExcludedMaxHolding[recipient]) {
            require(
                amount.add(balanceOf(recipient)) <= maxHoldLimit,
                "Max hold limit exceeds"
            );
        }
        if (
            !_isExcludedFromMaxTxn[sender] && !_isExcludedFromMaxTxn[recipient]
        ) {
            require(amount <= maxTxnLimit, "BigBuy: max txn limit exceeds");
        }
        if (inSwap) {
            return _simpleTransfer(sender, recipient, amount);
        }

        if (shouldSwap()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != uniPair && recipient != uniPair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == uniPair) {
                feeAmount = amount.mul(totalBuyFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
            }
            if (recipient == uniPair) {
                feeAmount = amount.mul(totalSellFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isRewardExempt[sender]) {
            if ((balanceOf(sender)) >= minTokenHoldingForReward) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            } else {
                try distributor.setShare(sender, 0) {} catch {}
            }
        }
        if (!isRewardExempt[recipient]) {
            if ((balanceOf(recipient)) >= minTokenHoldingForReward) {
                try
                    distributor.setShare(recipient, _balances[recipient])
                {} catch {}
            } else {
                try distributor.setShare(recipient, 0) {} catch {}
            }
        }
        if (address(distributor).balance >= distributor.minEth()) {
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // _simpleTransfer() : Transfer basic token account to account

    function _simpleTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    //shouldSwap() : To check swap should be done or not

    function shouldSwap() internal view returns (bool) {
        return (msg.sender != uniPair &&
            !inSwap &&
            enableSwap &&
            _balances[address(this)] >= swapLimit);
    }

    //Swapback() : To swap and liqufy the token

    function swapBack() internal swapping {
        uint256 totalFee = balanceOf(address(this));
        if (totalFee > 0) {
            _allowances[address(this)][address(router)] = _totalSupply;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                totalFee,
                0,
                path,
                address(distributor),
                block.timestamp
            );
        }
    }

    // claimReward() : Function that claims divident manually

    function claimReward() external {
        distributor.claimReward(msg.sender);
    }

    // getPaidReward() :Function shows paid Rewards of the user

    function getPaidReward(address shareholder) public view returns (uint256) {
        return distributor.getPaidEarnings(shareholder);
    }

    // getUnpaidReward() : Function shows unpaid rewards of the user

    function getUnpaidReward(
        address shareholder
    ) external view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }

    // getTotalDistributedReward(): Shows total distributed Reward

    function getTotalDistributedReward() external view returns (uint256) {
        return distributor.totalDistributed();
    }

    function setMinEThContractBalance(uint256 _ethAmount) public onlyOwner {
        distributor._setMinEThContractBalance(_ethAmount);
    }

    function checkMinEth() public view returns (uint256) {
        return distributor.minEth();
    }

    function MinTokenHoldingForReward(
        uint256 _minTokenHoldingForReward
    ) public onlyOwner {
        minTokenHoldingForReward = _minTokenHoldingForReward;
    }

    // setFeeExempt() : Function that Set Holders Fee Exempt
    //   ***          : It add user in fee exempt user list
    //   ***          : Owner & Authoized user Can set this

    function setFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    // setRewardExempt() : Set Holders Reward Exempt
    //      ***          : Function that add user in reward exempt user list
    //      ***          : Owner & Authoized user Can set this

    function setRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != uniPair);
        isRewardExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }
}

// Library used to perfoem math operations
library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}