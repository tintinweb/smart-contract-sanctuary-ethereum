// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _createInitialSupply(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol"; 

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Interfaces/IUniswapV2Factory.sol";
import "./Interfaces/IUniswapV2Router02.sol";


contract ZIKO is ERC20 {

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

     address public owner;


    struct UserInfo {
        uint256 lastAquireTime;
        uint256 taxableAmount;
    }

    bool private inSwapAndLiquify;

    bool public swapAndLiquifyEnabled = true;

    bool public enableEarlySellTax = true;

    uint256 public maxSellTransactionAmount = 1000000 * (10**18);
    uint256 public maxBuyTransactionAmount = 10000 * (10**18);
    uint256 public swapTokensAtAmount = 1000 * (10**18);
    uint256 public maxWalletToken = 10000 * (10**18);

    uint256 private buyTotalFees = 0;
    uint256 public sellTotalFees = 0;
    uint256 public earlySellTotalFee = 20;

    // auto burn fee
    uint256 public burnFee = 0;
    address public deadWallet;
    

    // distribute the collected tax percentage wise
    uint256 public liquidityPercent = 75; // 33% of total collected tax
    uint256 public marketingPercent = 15; // 34% of total collected tax
    uint256 public devPercent = 10; // 33% of total collected tax


    address payable public marketingWallet;
    address payable public devWallet;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;


    mapping (address => UserInfo) private _userInfo;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensIntoLiqudity,
        uint256 ethReceived
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("Ziko Inu", "ZIKO", 18) {

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // v2 router address
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

       // _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        owner = msg.sender;
    //  excludeFromFees(owner, true);
      //  excludeFromFees(marketingWallet, true);
      //  excludeFromFees(devWallet, true);
      //  excludeFromFees(address(this), true);
        
        /*
            an internal function that is only called here,
            and CANNOT be called ever again
        */
        _createInitialSupply(owner, 1000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "KCoin: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "KCoin: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
   
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "KCoin: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
   
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function transfer(address from, address to, uint256 amount) internal 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(automatedMarketMakerPairs[from] && (!_isExcludedFromFees[from]) && (!_isExcludedFromFees[to])) {
            require(amount <= maxBuyTransactionAmount, "amount exceeds the maxBuyTransactionAmount.");
            uint256 contractBalanceRecepient = balanceOf[to];
            require(contractBalanceRecepient + amount <= maxWalletToken,"Exceeds maximum wallet token amount.");
            
            
        }

        if(automatedMarketMakerPairs[to] && (!_isExcludedFromFees[from]) && (!_isExcludedFromFees[to])) {
            require(amount <= maxSellTransactionAmount, "amount exceeds the maxSellTransactionAmount.");
        }
        

    	uint256 contractTokenBalance = balanceOf[address(this)];
        
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
       
        if(
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            automatedMarketMakerPairs[to] && 
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = swapTokensAtAmount;
            swapAndLiquify(contractTokenBalance);
        }

        uint256 fees = 0;
        uint256 burnShare = 0;
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(automatedMarketMakerPairs[from] || (!_isExcludedFromFees[from]) && (!_isExcludedFromFees[to])) {
            uint256 _totalFees = buyTotalFees;
            uint256 currentTime = block.timestamp; 
            UserInfo storage userTo = _userInfo[to];
            uint256 lastAquireTime = userTo.lastAquireTime;
            if(currentTime - lastAquireTime <= 24 hours) {
                userTo.lastAquireTime = currentTime;                
            }
            if (automatedMarketMakerPairs[to]) {
                UserInfo storage userFrom = _userInfo[msg.sender];   
                uint256 span = block.timestamp-userFrom.lastAquireTime;
                if(enableEarlySellTax && span <= 24 hours) {
                    _totalFees = earlySellTotalFee;
                }
                else if(!enableEarlySellTax) {
                    _totalFees = sellTotalFees;
                }
            }

            fees = amount * (_totalFees/100);
            burnShare = amount * (burnFee/100);
            if(fees > 0) {
                super.transferFrom(from, address(this), fees);
            }

            if(burnShare > 0) {
                super.transferFrom(from, deadWallet, burnShare);
            }

            amount = amount - (fees + burnShare);
        }

        super.transferFrom(from, to, amount);

    }

     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensForLiquidity = (contractTokenBalance * liquidityPercent)/100;
        // split the Liquidity token balance into halves
        uint256 half = tokensForLiquidity/2;
        uint256 otherHalf = tokensForLiquidity-half;
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        // swap and Send  Eth to marketing, dev wallets
        swapTokensForEth(contractTokenBalance - tokensForLiquidity);
        marketingWallet.transfer(address(this).balance * marketingPercent / (marketingPercent + devPercent));
        devWallet.transfer(address(this).balance);
        emit SwapAndLiquify(half, newBalance); 
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(allowance[address(this)][address(uniswapV2Router)] < tokenAmount) {
          approve(address(this), ~uint256(0));
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );
        
    }

    function setMaxSellTransaction(uint256 _maxSellTxAmount) public onlyOwner {
        maxSellTransactionAmount = _maxSellTxAmount;
        require(maxSellTransactionAmount>totalSupply / 1000, "value is too low");
    }
    
    function setMaxBuyTransaction(uint256 _maxBuyTxAmount) public onlyOwner {
        maxBuyTransactionAmount = _maxBuyTxAmount;
        require(maxBuyTransactionAmount>totalSupply / 1000, "value is too low");
    }

    function setSwapTokensAtAmouunt(uint256 _newAmount) public onlyOwner {
        swapTokensAtAmount = _newAmount;
    }

    function setMarketingWallet(address payable wallet) public onlyOwner {
        marketingWallet = wallet;
    }

    function setDevWallet(address payable wallet) public onlyOwner {
        devWallet = wallet;
    }

    function updateBuyTotalTax(uint256 _buyTotalFees) public onlyOwner {
        buyTotalFees = _buyTotalFees;
        require(buyTotalFees <= 10, "Fee too high");
    }

   function updateSellTotalTax(uint256 _sellTotalFees) public onlyOwner {
        sellTotalFees = _sellTotalFees;
        require(sellTotalFees <= 10, "Fee too high");
    }

    function updateEarlySellTotalTax(uint256 _earlySellTotalFee) public onlyOwner {
        earlySellTotalFee = _earlySellTotalFee;
        require(earlySellTotalFee <= 20, "Fee too high");
    }

    function updateTaxDistributionPercentage(uint256 _liquidityPercent, uint256 _marketingPercent, uint256 _devPercent) public onlyOwner {
        require(_liquidityPercent + (_marketingPercent) + (_devPercent) == 100, "total percentage must be equal to 100");
        liquidityPercent = _liquidityPercent;
        marketingPercent = _marketingPercent;
        devPercent = _devPercent;  
    }

    function setEarlySellTax(bool onoff) external onlyOwner  {
        enableEarlySellTax = onoff;
    }

    function setAutoBurn(uint256 _burnFee) external onlyOwner  {
        require(_burnFee <= 5, "value too high");
        burnFee = _burnFee;
    }

    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken;
        require(maxWalletToken>totalSupply / 1000, "value is too low");
  	}

    function setWallets(address payable _marketing, address payable _dev, address _dead) external onlyOwner {
        marketingWallet =  _marketing;
        devWallet = _dev;
        deadWallet = _dead;

    }

}