/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth is Context {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be owner
     */
    modifier onlyOwner() {
        require(_msgSender() == owner, "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract $SOCIAL is Context, IERC20, Auth, EIP712 {
    string private constant NAME = "SocialDAO";
    string private constant SYMBOL = "$SOCIAL";
    uint8 private constant DECIMALS = 9;
    mapping(address => uint256) private _rOwned;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant MAX_SUPPLY = 1e12 * 1e9; // 1T Supply
    uint256 private constant R_MAX = (MAX - (MAX % MAX_SUPPLY));
    
    // for DAO
    uint256 public constant AMOUNT_DAO_PERC = 20;
    // for staking
    uint256 public constant AMOUNT_STAKING_PERC = 10;
    // for liquidity providers
    uint256 public constant AMOUNT_LP_PERC = 20;

    uint256 private _tTotal = (MAX_SUPPLY/100) * (AMOUNT_DAO_PERC + AMOUNT_STAKING_PERC + AMOUNT_LP_PERC);
    uint256 private _rTotal = (R_MAX/100) * (AMOUNT_DAO_PERC + AMOUNT_STAKING_PERC + AMOUNT_LP_PERC);

    bool private inSwap = false;
    bool private _startTxn;
    uint32 private _initialBlocks;
    uint104 private swapLimit = uint104(MAX_SUPPLY / 1000);
    uint104 private _tOwnedBurnAddress;

    uint256 private constant STAKING_BLOCKS_COUNT = 6450 * 5; //5 days

    struct Airdrop {
        uint128 blockNo;
        uint128 amount;
    }

    mapping(address => Airdrop) private _airdrop;

    mapping(bytes32 => bool) private _claimedHash;

    struct FeeBreakdown {
        uint256 tTransferAmount;
        uint256 tMaintenance;
        uint256 tReflection;
    }
    
    struct Fee {
        uint64 buyMaintenanceFee;
        uint64 buyReflectionFee;
        
        uint64 sellMaintenanceFee;
        uint64 sellReflectionFee;
    }

    Fee private _buySellFee = Fee(8,2,8,2);
    
    address payable private _maintenanceAddress;
    address private _csigner;

    address payable constant private BURN_ADDRESS = payable(0x000000000000000000000000000000000000dEaD);
    
    IUniswapV2Router02 private immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    address private immutable WETH;

    bytes32 private constant AIRDROP_CALL_HASH_TYPE = keccak256("airdrop(address receiver,uint256 amount)");
    
    constructor(address addrDAO, address addrStaking, address addrLP, address maintainer, address signer) Auth(_msgSender()) EIP712(SYMBOL, "1") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), MAX_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), MAX);

        _maintenanceAddress = payable(maintainer);
        
        //Initial distribution
        _rOwned[addrDAO] = (R_MAX/100) * AMOUNT_DAO_PERC;
        _rOwned[addrStaking] = (R_MAX/100) * AMOUNT_STAKING_PERC;
        _rOwned[addrLP] = (R_MAX/100) * AMOUNT_LP_PERC;

        _isExcludedFromFee[addrDAO] = true;
        _isExcludedFromFee[addrStaking] = true;
        _isExcludedFromFee[addrLP] = true;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[maintainer] = true;

        _csigner = signer;
        emit Transfer(address(0), addrDAO, MAX_SUPPLY * AMOUNT_DAO_PERC / 100);
        emit Transfer(address(0), addrStaking, MAX_SUPPLY * AMOUNT_STAKING_PERC / 100);
        emit Transfer(address(0), addrLP, MAX_SUPPLY * AMOUNT_LP_PERC / 100);
    }

    function name() override external pure returns (string memory) {return NAME;}
    function symbol() override external pure returns (string memory) {return SYMBOL;}
    function decimals() override external pure returns (uint8) {return DECIMALS;}
    function totalSupply() external view override returns (uint256) {return _tTotal;}
    function balanceOf(address account) external view override returns (uint256) {return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount/currentRate;
    }
    
    function getFee(bool initialBlocks) internal view returns (Fee memory) {
        return initialBlocks ? Fee(99,0,99,0) : _buySellFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0), "ERC20: transfer involving the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_startTxn || _isExcludedFromFee[to] || _isExcludedFromFee[from], "Transfers not allowed");

        Fee memory currentFee;
            
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            currentFee = getFee(block.number <= _initialBlocks);
        } else if (!inSwap && from != uniswapV2Pair && !_isExcludedFromFee[from]) { //sells, transfers (except for buys)
            currentFee = getFee(block.number <= _initialBlocks);

            if (swapLimit > 0 && tokenFromReflection(_rOwned[address(this)]) > swapLimit) {
                _convertTokensForFee(swapLimit);
            }
            
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) _distributeFee(contractETHBalance);
        }

        _tokenTransfer(from, to, amount, currentFee);
    }

    function _convertTokensForFee(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, _maintenanceAddress, block.timestamp);
    }

    function _distributeFee(uint256 amount) private {
        _maintenanceAddress.transfer(amount);
    }

    function startTxn(uint32 initialBlocks) external onlyOwner {
        require(!_startTxn && initialBlocks < 100, "Already started or block count too long");
        _startTxn = true;
        _initialBlocks = uint32(block.number) + initialBlocks;
    }

    function triggerSwap(uint256 perc) external onlyOwner {
        _convertTokensForFee(tokenFromReflection(_rOwned[address(this)]) * perc / 100);
    }
    
    function collectFee() external onlyOwner {
        _distributeFee(address(this).balance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, Fee memory currentFee) private {
        if (sender == uniswapV2Pair){
            _transferStandardBuy(sender, recipient, amount, currentFee);
        }
        else {
            _transferStandardSell(sender, recipient, amount, currentFee);
        }
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount, Fee memory currentFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 rMaintenance) = _getValuesBuy(tAmount, currentFee);
        
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _rOwned[address(this)] += rMaintenance;
        _rTotal -= rReflection;

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandardSell(address sender, address recipient, uint256 tAmount, Fee memory currentFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 rMaintenance) = _getValuesSell(tAmount, currentFee);

        Airdrop memory airdrop = _airdrop[sender];
        uint256 rOwnedSender = _rOwned[sender];

        if (airdrop.blockNo > block.number) {
            require(rAmount <= 
                rOwnedSender - airdrop.amount * ((airdrop.blockNo - block.number) * (rAmount / tAmount) / STAKING_BLOCKS_COUNT), "Tokens locked for staking");
        }

        _rOwned[sender] = rOwnedSender - rAmount;
        _rOwned[recipient] += rTransferAmount;
        _rOwned[address(this)] += rMaintenance;

        if (recipient == BURN_ADDRESS) {
            _tOwnedBurnAddress += uint104(tTransferAmount);
        }

        _rTotal -= rReflection;

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _getValuesBuy(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256) {
        FeeBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tMaintenance, buyFees.tReflection) = _getTValues(tAmount, currentFee.buyMaintenanceFee, currentFee.buyReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 rMaintenance) = _getRValues(tAmount, buyFees.tMaintenance, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, rMaintenance);
    }

    function _getValuesSell(uint256 tAmount, Fee memory currentFee) private view returns (uint256, uint256, uint256, uint256, uint256) {
        FeeBreakdown memory sellFees;
        (sellFees.tTransferAmount, sellFees.tMaintenance, sellFees.tReflection) = _getTValues(tAmount, currentFee.sellMaintenanceFee, currentFee.sellReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 rMaintenance) = _getRValues(tAmount, sellFees.tMaintenance, sellFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, sellFees.tTransferAmount, rMaintenance);
    }

    function _getTValues(uint256 tAmount, uint256 maintenanceFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256) {
        uint256 tMaintenance = tAmount * maintenanceFee / 100;
        uint256 tReflection = tAmount * reflectionFee / 100;
        uint256 tTransferAmount = tAmount - tMaintenance - tReflection;
        return (tTransferAmount, tMaintenance, tReflection);
    }

    function _getRValues(uint256 tAmount, uint256 tMaintenance, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rMaintenance = tMaintenance * currentRate;
        uint256 rReflection = tReflection * currentRate;
        uint256 rTransferAmount = rAmount - rMaintenance - rReflection;
        return (rAmount, rTransferAmount, rReflection, rMaintenance);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        uint256 rOwnedBurnAddress = _rOwned[BURN_ADDRESS];
        uint256 tOwnedBurnAddress = _tOwnedBurnAddress;

        if (rOwnedBurnAddress > rSupply || 
            tOwnedBurnAddress > tSupply || 
            (rSupply / tSupply) > (rSupply - rOwnedBurnAddress) 
        ) return (rSupply, tSupply);

        return (rSupply - rOwnedBurnAddress, tSupply - tOwnedBurnAddress);
    }

    function setIsExcludedFromFee(address account, bool toggle) external onlyOwner {
        _isExcludedFromFee[account] = toggle;
    }
        
    function updateSwapLimit(uint104 amount) external onlyOwner {
        swapLimit = amount;
    }
    
    function updateFeeReceiver(address payable maintenanceAddress) external onlyOwner {
        _maintenanceAddress = maintenanceAddress;
        _isExcludedFromFee[maintenanceAddress] = true;
    }

    function updateSigner(address signer) external onlyOwner {
        _csigner = signer;
    }

    receive() external payable {}

    function updateTaxes(Fee memory fees) external onlyOwner {
        require((fees.buyMaintenanceFee + fees.buyReflectionFee < 20) && 
            (fees.sellMaintenanceFee + fees.sellReflectionFee < 20), "Fees must be less than 20%");
        _buySellFee = fees;
    }
    
    function recoverStuckTokens(address addr, uint256 amount) external onlyOwner {
        IERC20(addr).transfer(_msgSender(), amount);
    }

    function airdropCollectedByAddress(address account) public view returns (Airdrop memory) {
        return _airdrop[account];
    }

    function airdropCollectedByHash(bytes32 hash) public view returns (bool) {
        return _claimedHash[hash];
    }

    function claim(bytes32 hash, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(!_claimedHash[hash] && _airdrop[_msgSender()].blockNo == 0, "$SOCIAL: Claimed");
        uint256 claimAmount = amount * (10 ** DECIMALS);
        require(_tTotal + claimAmount <= MAX_SUPPLY, "$SOCIAL: Exceed max supply");
 
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", 
            _hashTypedDataV4(keccak256(abi.encode(AIRDROP_CALL_HASH_TYPE, hash, _msgSender(), amount)))
        ));
        require(ecrecover(digest, v, r, s) == _csigner, "$SOCIAL: Invalid signer");
        
        _airdropTokens(hash, _msgSender(), uint128(claimAmount));
    }

    function _airdropTokens(bytes32 hash, address account, uint128 amount) internal virtual {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 rMaintenance) = _getValuesBuy(amount, _buySellFee);

        _airdrop[account].blockNo = uint128(block.number + STAKING_BLOCKS_COUNT);
        _airdrop[account].amount = uint128(tTransferAmount);
        _claimedHash[hash] = true;

        _tTotal += amount;
        _rOwned[address(this)] += rMaintenance;
        _rTotal = _rTotal + rAmount - rReflection;
        _rOwned[account] += rTransferAmount;
        
        emit Transfer(address(0), account, tTransferAmount);
    }

    function vestedTokens(address account) public view returns (uint256 tokenBalance, uint256 tTokenVested, uint256 vestingBlocks) {
        Airdrop memory airdrop = _airdrop[account];
        tokenBalance = tokenFromReflection(_rOwned[account]);
        tTokenVested = tokenBalance;
        vestingBlocks = 0;

        if (airdrop.blockNo > block.number) {
            uint256 rTokenVested = _rOwned[account] - airdrop.amount * (((airdrop.blockNo - block.number) * _getRate()) / STAKING_BLOCKS_COUNT);
            tTokenVested = tokenFromReflection(rTokenVested);
            vestingBlocks = airdrop.blockNo - block.number;
        }

        return (tokenBalance, tTokenVested, vestingBlocks);
    }
}