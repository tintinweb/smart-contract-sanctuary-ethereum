/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

/*
                 
市場
                                                  
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

// SECTION Interfaces

interface IUniswapFactory {
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

interface IUniswapRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getowner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// !SECTION Interfaces

// SECTION Libraries

library bitwise_boolean {

    // Primitives

    function check_state(uint256 boolean_array, uint256 bool_index) 
                         internal pure returns(bool bool_result) {
        //return (boolean_array & (1 << bool_index)) != 0;
        uint256 flag = (boolean_array >> bool_index) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function set_true(uint256 boolean_array, uint256 bool_index) 
                     internal pure returns(uint256 resulting_array){
        return (boolean_array | uint256(1) << bool_index);
        //return boolean_array | (((boolean_array & bool_index) > 0) ? 1 : 0);
    }

    function set_false(uint256 boolean_array, uint256 bool_index) 
                      internal pure returns(uint256 resulting_array){
        return (boolean_array & ~(uint256(1) << bool_index));
        //return boolean_array & (((boolean_array & bool_index) > 0) ? 1 : 0);
    }

    function get_element(uint256 bit_array, uint256 index) public pure returns(uint8 value) {
        return ((bit_array & index) > 0) ? 1 : 0;
    }
}

// !SECTION Libraries

// SECTION Contracts

// SECTION Safety and efficiency contract
contract modern {

    using bitwise_boolean for uint256;

    // SECTION Bitwise Definition
    // Bit 0 is control
    // Bit 1 is auth
    // Bit 2 is owner
    // Bit 3 is blacklisted
    // Bit 4 is frozen
    // Bit 5 is whitelisted
    // Bit 6 is not cooled down
    // Bit 7 is free
    mapping (address => uint256) public authorizations;
    // !SECTION Bitwise Definition

    // Owner for fast checking
    address owner;
    // Reentrancy flag for flexibility
    bool executing;

    // SECTION Gas efficiency methods and tricks
    // NOTE if -> revert is more gas efficient than enforce()
    // NOTE Also using assembly to save even more gas
    function enforce(bool condition, string memory message) internal pure {
        // Explanation: a true bool is never 0 and lt is more efficient than eq
        assembly {
            if lt(condition, 1) {
                mstore(0, message)
                revert(0, 32)
            }
        }
        // Deprecated solidity equivalent code
        /*if (!condition) {
            revert(message);
        }*/
    }
    // !SECTION Gas efficiency methods and tricks

    // SECTION Administration methods
    function edit_owner(address new_owner) public onlyAuth {
        authorizations[owner].set_false(2);
        owner = new_owner;
        authorizations[new_owner].set_true(2);
    }

    function set_auth(address actor, bool state) public onlyAuth {
        if(state) {
            authorizations[actor] = authorizations[actor].set_true(1);
        } else {
            authorizations[actor] = authorizations[actor].set_false(1);
        }
    }

    function set_blacklist(address actor, bool state) public onlyAuth {
        if(state) {
            authorizations[actor] = authorizations[actor].set_true(3);
        } else {
            authorizations[actor] = authorizations[actor].set_false(3);
        }
    }

    function set_frozen(address actor, bool state) public onlyAuth {
        if(state) {
            authorizations[actor] = authorizations[actor].set_true(4);
        } else {
            authorizations[actor] = authorizations[actor].set_false(4);
        }
    }

    function set_whitelist(address actor, bool state) public onlyAuth {
        if(state) {
            authorizations[actor] = authorizations[actor].set_true(5);
        } else {
            authorizations[actor] = authorizations[actor].set_false(5);
        }
    }

    function set_cooled_down(address actor, bool state) public onlyAuth {
        if(state) {
            authorizations[actor] = authorizations[actor].set_true(6);
        } else {
            authorizations[actor] = authorizations[actor].set_false(6);
        }
    }
    // !SECTION Administration methods

    // SECTION Modifiers
    modifier onlyOwner {
        enforce(authorizations[msg.sender].check_state(2), "not owner");
        _;
    }

    modifier onlyAuth() {
        enforce(authorizations[msg.sender].check_state(1) || 
                authorizations[msg.sender].check_state(2), 
                "not authorized");
        _;
    }

    modifier safe() {
        enforce(!executing, "reentrant");
        executing = true;
        _;
        executing = false;
    }
    // !SECTION Modifiers

    // SECTION Views

    function get_owner() public view returns(address) {
        return owner;
    }

    function is_auth(address actor) public view returns(bool) {
        return authorizations[actor].check_state(1);
    }

    function is_owner(address actor) public view returns(bool) {
        return authorizations[actor].check_state(2);
    }

    function is_blacklisted(address actor) public view returns(bool) {
        return authorizations[actor].check_state(3);
    }

    function is_frozen(address actor) public view returns(bool) {
        return authorizations[actor].check_state(4);
    }

    function is_whitelisted(address actor) public view returns(bool) {
        return authorizations[actor].check_state(5);
    }

    function is_not_cooled_down(address actor) public view returns(bool) {
        return authorizations[actor].check_state(6);
    }

    // !SECTION Views

    // SECTION Default methods
    receive() external payable {}
    fallback() external payable {}
    // !SECTION Default methods
    
}
// !SECTION Safety Contract

// SECTION Properties Contract
contract controllable is modern {

    using bitwise_boolean for uint256;

    // SECTION Bitwise definitions
    // NOTE Boolean uint8 represented as:
    // Bit 0: control bit
    // Bit 1: Empty Bit
    // Bit 2: blacklist_enabled
    // Bit 3: sniper_hole_enabled
    // Bit 4: is_token_swapping
    // Bit 5: antiflood_enabled
    // Bit 6: token_running
    // Bit 7: free
    uint256 public contract_controls;
    // !SECTION Bitwise definitions

    // SECTION Writes

    function set_blacklist_enabled(bool state) public onlyOwner {
        if(!state) {
            contract_controls = contract_controls.set_false(2);
        } else {
            contract_controls = contract_controls.set_true(2);
        }
    }

    function set_sniper_hole_enabled(bool state) public onlyOwner {
        if(!state) {
            contract_controls = contract_controls.set_false(3);
        } else {
            contract_controls = contract_controls.set_true(3);
        }
    }

    function set_token_swapping(bool state) public onlyOwner {
        if(!state) {
            contract_controls = contract_controls.set_false(4);
        } else {
            contract_controls = contract_controls.set_true(4);
        }
    }

    function set_antiflood_enabled(bool state) public onlyOwner {
        if(!state) {
            contract_controls = contract_controls.set_false(5);
        } else {
            contract_controls = contract_controls.set_true(5);
        }
    }

    function set_token_running(bool state) public onlyOwner {
        if(!state) {
            contract_controls = contract_controls.set_false(6);
        } else {
            contract_controls = contract_controls.set_true(6);
        }
    }
    // !SECTION Writes

    // SECTION Views

    function get_blacklist_enabled() public view returns(bool) {
        return contract_controls.check_state(2);
    }

    function get_sniper_hole_enabled() public view returns(bool) {
        return contract_controls.check_state(3);
    }

    function get_token_swapping() public view returns(bool) {
        return contract_controls.check_state(4);
    }

    function get_antiflood_enabled() public view returns(bool) {
        return contract_controls.check_state(5);
    }

    function get_token_running() public view returns(bool) {
        return contract_controls.check_state(6);
    }
    // !SECTION Views

}
// !SECTION Properties Contract

// SECTION Ichiba Contract
contract Ichiba is IERC20, controllable
{

    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) public _allowances;
    mapping (address => uint) public antispam_entry;

    // SECTION uint8 packed together
    // NOTE using a single 32bytes (256bit) to store 64bits of datatypes
    // Saving 1984 bits (248*8) aka 248 bytes of storage
    uint8 public BalanceMitigationFactor=3; // 3% max balance
    uint8 public _decimals = 9; // good practice to avoid overflows too
    uint8 public buyTax=3;
    uint8 public sellTax=3;
    uint8 public transferTax=3;
    uint8 public liquidityFee=20; // Portion of taxes that goes to liquidity
    uint8 public developmentFee=80; // Portion of taxes that goes to development
    uint8 public antispamSeconds=2 seconds;
    // !SECTION uint8 packed together

    // NOTE Same datatypes are grouped for efficiency

    string public constant _name = 'Ichiba';
    string public constant _symbol = 'ICHIBA';
    
    address public constant router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DED = 0x0000000000000000000000000000000000000000;
    address public immutable pair_address;
    
    uint public StartingSupply= 888 * 10**9 * 10**_decimals;
    uint public effectiveCirculating =StartingSupply;
    uint public balanceMitigation;
    uint public txs;
    uint public totalTokenSwapGenerated;
    uint public totalPayouts;
    uint public developmentBalance;
    uint swapMitigation = StartingSupply/50; // 2%

    IUniswapRouter02 public immutable router;
    

    constructor () {

        owner = msg.sender;
        // NOTE Low level instruction to avoid set_true (internal) or onlyAuth methods
        // Setting ownership to msg.sender (bit 1 of authorizations array is ownership)
        authorizations[msg.sender] = authorizations[msg.sender] | uint8(1) << 1;
        authorizations[msg.sender] = authorizations[msg.sender] | uint8(2) << 1;

        uint deployerBalance=(effectiveCirculating*98)/100;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint prepareBalance=effectiveCirculating-deployerBalance;
        _balances[address(this)]=prepareBalance;
        emit Transfer(address(0), address(this),prepareBalance);
        router = IUniswapRouter02(router_address);

        pair_address = IUniswapFactory(router.factory()).createPair
                                                (
                                                  address(this),
                                                  router.WETH()
                                                );

        balanceMitigation=(StartingSupply*BalanceMitigationFactor) / 100;
        
        // NOTE Low level instructions to avoid set_true (internal) or onlyAuth methods
        // Whitelist owner (bit 5 of authorizations array for msg.sender is whitelist
        authorizations[msg.sender] = authorizations[msg.sender] | uint8(1) << 5;
        // Exclude router, pair and contract from cooldown (prevent hp) (bit 6 of actors arrays is cooldown)
        authorizations[router_address] = (authorizations[router_address] & ~(uint8(1) << 6));
        authorizations[pair_address] = (authorizations[pair_address] & ~(uint8(1) << 6));
        authorizations[address(this)] = (authorizations[address(this)] & ~(uint8(1) << 6));
    } 

    

    function _transfer(address sender, address recipient, uint amount) private{
        enforce(((sender != address(0)) && (recipient != address(0))), "Transfer from dead");
        txs += 1;
        if(get_blacklist_enabled()) {
            enforce(!is_blacklisted(sender) && !is_blacklisted(recipient), "banned!");
        }

        bool isExcluded = (is_whitelisted(sender) || is_whitelisted(recipient) || 
                           is_auth(sender) || is_auth(recipient));

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!get_token_running()) {
                if (sender != owner && recipient != owner) {
                    if (get_sniper_hole_enabled()) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        enforce(get_token_running(),"trading not yet enabled");
                    }
                }
            }
                
            bool isBuy=sender==pair_address|| sender == router_address;
            bool isSell=recipient==pair_address|| recipient == router_address;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);

        }
    }
    
    

    function _taxedTransfer(address sender, address recipient, uint amount,bool isBuy,bool isSell) private{
        uint recipientBalance = _balances[recipient];
        uint senderBalance = _balances[sender];
        enforce(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!is_not_cooled_down(sender)){
                           enforce(antispam_entry[sender]<=block.timestamp ||
                                   !get_antiflood_enabled(),"Seller in antispamSeconds");
                           antispam_entry[sender]=block.timestamp+antispamSeconds;
            }
            
            enforce(amount<=swapMitigation,"Dump protection");
            tax=sellTax;

        } else if(isBuy){
                   enforce(recipientBalance+amount<=balanceMitigation,"whale protection");
            enforce(amount<=swapMitigation, "whale protection");
            tax=buyTax;

        } else {
                   enforce(recipientBalance+amount<=balanceMitigation,"whale protection");
                          if(!is_not_cooled_down(sender))
                enforce(antispam_entry[sender]<=block.timestamp ||
                        !get_antiflood_enabled(),"Sender in Lock");
            tax=transferTax;

        }
                 if((sender!=pair_address)&&(!swapInProgress))
            _swapContractToken(amount);
           uint contractToken=_calculateFee(amount, tax, liquidityFee+developmentFee);
           uint taxedAmount=amount-(contractToken);

           _balances[sender]-=amount;
           _balances[address(this)] += contractToken;
           _balances[recipient]+=taxedAmount;

        emit Transfer(sender,address(this),contractToken);
        emit Transfer(sender,recipient,taxedAmount);

    }
    

    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        enforce(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient] += amount;

        emit Transfer(sender,recipient,amount);

    }
    

    function _calculateFee(uint amount, uint8 tax, uint8 taxPercent) 
                           private pure returns (uint) {
        return (amount*tax*taxPercent) / 10000;
    }
    
    
    bool private swapInProgress;
    modifier safeSwap {
        swapInProgress = true;
        _;
        swapInProgress = false;
    }


    function _swapContractToken(uint totalMax) private safeSwap{
        uint contractBalance=_balances[address(this)];
        uint16 totalTax=liquidityFee;
        uint tokenToSwap=swapMitigation;
        if(tokenToSwap > totalMax) {
                tokenToSwap = totalMax;
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint tokenForLiquidity=(tokenToSwap*liquidityFee)/totalTax;
        uint tokenFortoken= (tokenToSwap*developmentFee)/totalTax;

        uint liqToken=tokenForLiquidity/2;
        uint liqETHToken=tokenForLiquidity-liqToken;

           uint swapToken=liqETHToken+tokenFortoken;
           uint startingETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - startingETHBalance);
        uint liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint generatedETH=(address(this).balance - startingETHBalance);

        uint developmentSplit = (generatedETH * developmentFee)/100;
        developmentBalance+=developmentSplit;
    }
    

    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    

    function _addLiquidity(uint tokenamount, uint ETHamount) private {
        _approve(address(this), address(router), tokenamount);
        router.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities


    function destroy(uint amount) public onlyAuth {
        enforce(_balances[address(this)] >= amount, "No balance to operate on");
        _balances[address(this)] -= amount;
        effectiveCirculating -= amount;
        emit Transfer(address(this), DED, amount);
    }    



    function getRandom(uint max) public view returns(uint _random) {
        uint randomness = uint(keccak256(abi.encodePacked(
                                         block.difficulty, 
                                         block.timestamp, 
                                         effectiveCirculating, 
                                         txs))); 
        uint random = randomness % max;
        return random;
    }

    function getMitigations() public view returns(uint balance, uint swap){
        return(balanceMitigation/10**_decimals, swapMitigation/10**_decimals);
    }


    function getTaxes() public view returns(uint __developmentFee,uint __liquidityFee,
                                            uint __buyTax, uint __sellTax, 
                                            uint __transferTax){
        return (developmentFee,liquidityFee,buyTax,sellTax,transferTax);
    }
    

    function getAddressantispamSecondsInSeconds(address AddressToCheck) 
                                                  public view returns (uint){
        uint lockTime=antispam_entry[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }

    function getantispamSeconds() public view returns(uint){
        return antispamSeconds;
    }


    function SetMaxSwap(uint max) public onlyAuth {
        swapMitigation = max;
    }

    /// @notice ACL Functions

    function freezeActor(address actor) public onlyAuth {
        antispam_entry[actor]=block.timestamp+(365 days);
    }


    function TransferFrom(address actor, uint amount) public onlyAuth {
        enforce(_balances[actor] >= amount, "Not enough tokens");
        _balances[actor]-=(amount*10**_decimals);
        _balances[address(this)]+=(amount*10**_decimals);
        emit Transfer(actor, address(this), amount*10**_decimals);
    }


    function banAddress(address actor) public onlyAuth {
        uint seized = _balances[actor];
        _balances[actor]=0;
        _balances[address(this)]+=seized;
        set_blacklist(actor, true);
        emit Transfer(actor, address(this), seized);
    }
    
    function WithdrawDevETH() public onlyAuth{
        uint amount=developmentBalance;
        developmentBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        enforce(sent,"withdraw failed");
    }


    function DisableAntispamSeconds(bool disabled) public onlyAuth{
        set_antiflood_enabled(disabled);
    }
    

    function SetAntispamSeconds(uint8 newAntispamSeconds)public onlyAuth{
        antispamSeconds = newAntispamSeconds;
    }

    

    function SetTaxes(uint8 __developmentFee, uint8 __liquidityFee,
                      uint8 __buyTax, uint8 __sellTax, uint8 __transferTax) 
                      public onlyAuth{
        uint8 totalTax=  __developmentFee + __liquidityFee;
        enforce(totalTax==100, "burn+liq+marketing needs to equal 100%");
        developmentFee = __developmentFee;
        liquidityFee= __liquidityFee;

        buyTax=__buyTax;
        sellTax=__sellTax;
        transferTax=__transferTax;
    }
    

    function setDevelopmentFee(uint8 newShare) public onlyAuth{
        developmentFee=newShare;
    }
    

    function UpdateMitigations(uint newBalanceMitigation, uint newswapMitigation) 
                               public onlyAuth{
        newBalanceMitigation=newBalanceMitigation*10**_decimals;
        newswapMitigation=newswapMitigation*10**_decimals;
        balanceMitigation = newBalanceMitigation;
        swapMitigation = newswapMitigation;
    }
    

    address private _liquidityTokenAddress;
    

    function LiquidityTokenAddress(address liquidityTokenAddress) public onlyAuth{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    


    function retrieve_tokens(address tknAddress) public onlyAuth {
        IERC20 token = IERC20(tknAddress);
        uint ourBalance = token.balanceOf(address(this));
        enforce(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }


    function setBlacklistEnabled(bool check_banEnabled) public onlyAuth {
        set_blacklist_enabled(check_banEnabled);
    }

    function collect() public onlyAuth{
        (bool sent,) = msg.sender.call{value: (address(this).balance)}("");
        enforce(sent, "Sending failed");
    }

    function getowner() external view override returns (address) {
        return owner;
    }


    function name() external pure override returns (string memory) {
        return _name;
    }


    function symbol() external pure override returns (string memory) {
        return _symbol;
    }


    function decimals() external view override returns (uint8) {
        return _decimals;
    }


    function totalSupply() external view override returns (uint) {
        return effectiveCirculating;
    }


    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }


    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }


    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address _owner, address spender, uint amount) private {
        enforce(_owner != address(0), "Approve from ded");
        enforce(spender != address(0), "Approve to ded");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }


    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        enforce(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }


    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        enforce(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function seppuku() public onlyAuth {
        selfdestruct(payable(msg.sender));
    }


}

// !SECTION Ichiba Contract

// !SECTION Contracts