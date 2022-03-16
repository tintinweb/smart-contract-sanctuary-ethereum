/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

/*
    *Telegram: https://t.me/passtheloot_official
    *Website: https://Ethloot.io

    *Custom Contract and dApps created by FairTokenProject. Visit app.fairtokenproject.com to hire FTP for your next project.

    * Using FTPAntiBot
        - FTPAntiBot is a contract as a service (CaaS). Ward off harmful bots automatically.
        - Learn more at https://fairtokenproject.com
    */
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.11; 
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
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
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
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            return c;
        }
    }
    contract Ownable is Context {
        address private m_Owner;
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        constructor () {
            address msgSender = _msgSender();
            m_Owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
        }
        function owner() public view returns (address) {
            return m_Owner;
        }
        function transferOwnership(address _newOwner) public virtual onlyOwner {
            emit OwnershipTransferred(m_Owner, _newOwner);
            m_Owner = _newOwner;
        }
        modifier onlyOwner() {
            require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
            _;
        }                                                                                           
    }                                                                                 
    interface IUniswapV2Factory {                                                         
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }
    interface IUniswapV2Router02 {
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
        function factory() external pure returns (address);
        function WETH() external pure returns (address);
        function addLiquidityETH(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    }
    interface IWETH {
        function deposit() external payable;
    }
    interface FTPAntiBot {
        function scanAddress(address _sender, address _recipient, address _safeAddress, address _origin) external returns (bool);
        function registerBlock(address _recipient, address _sender, address _origin) external;
    }
    contract PASSTHELOOT is IERC20, Ownable {
        using SafeMath for uint256;
        uint256 private constant TOTAL_SUPPLY = 69000 * 10**18;
        string private m_Name = "Pass the Loot";
        string private m_Symbol = "LOOT";
        uint8 private m_Decimals = 18;
        address private m_UniswapV2Pair;
        address private m_Controller;
        address payable private m_MarketingWallet;
        IUniswapV2Router02 private m_UniswapV2Router;

        uint256 private m_TxLimit  = TOTAL_SUPPLY.div(400);
        uint256 private m_WalletLimit = TOTAL_SUPPLY.div(80);

        bool private m_Liquidity = false;
        FTPAntiBot private AntiBot;
        address private m_AntibotSvcAddress = 0x2d2230185B24aF94FeEba779CA11Ff6f96d17e6D; //Double check address

        mapping (address => bool) private m_ExcludedAddresses;
        mapping (address => uint256) private m_Balances;
        mapping (uint256 => uint256) private m_RaffleTaxAmountVotes;
        mapping (uint256 => uint256) private m_LargestTaxAmountVotes;
        mapping (uint256 => uint256) private m_IntervalVote;
        mapping (uint256 => mapping (address => uint256)) private m_BuyerId;
        mapping (uint256 => mapping (address => uint256)) private m_VoterIdx;
        mapping (address => mapping (address => uint256)) private m_Allowances;
        mapping (uint256 => mapping (uint256 => uint256)) private m_GenericVote;
        mapping (address => uint256) m_Earnings;
        uint256 private m_Launched;
        uint256 private pMax = 100000;
        uint256 private m_RoundStart;
        uint256 private m_Interval = 900;
        uint256 private m_RaffleTax = 3000;
        uint256 private m_LargestBuyerTax = 2000;
        uint256 private m_GenericIdx = 0;
        uint256 private m_MarketingTax = 3000;
        uint256 private m_Round;
        uint256 private m_DAOmin = TOTAL_SUPPLY.div(1000);
        uint256 private m_VoteCycle = 1;
        uint256 private m_TotalWinnings;
        bool private m_AntiBot = false;
        address[] private m_Winners;
        uint256[] private m_Winnings;

        struct Buyer {
            address addr;
            uint256 amount;
            bool eligible;
        }
        struct Vote {
            uint256 interval;
            uint256 raffleTax;
            uint256 biggestTax;
            uint256 generic;
        }
        struct GameState {
            uint256 round; // default 1
            uint256 gameInterval; // default 15min
            uint256 raffleTax; // default 3%
            uint256 biggestBuyerTax; // default 2%
        }
        mapping (uint256 => Buyer[]) private m_Raffle;
        mapping (uint256 => Vote[]) private m_Voters;
        
        receive() external payable {}

        constructor () {
            m_Launched = block.timestamp.add(69 days);
            AntiBot = FTPAntiBot(m_AntibotSvcAddress);
            m_Controller = msg.sender;
            m_MarketingWallet = payable(msg.sender);

            m_Winners.push(address(0));
            m_Winnings.push(0);
            m_Raffle[0].push(Buyer(address(0),0,false));
            m_Voters[m_VoteCycle].push(Vote(0,0,0,0));

            m_Balances[address(this)] = TOTAL_SUPPLY;
            m_ExcludedAddresses[owner()] = true;
            m_ExcludedAddresses[address(this)] = true;
            emit Transfer(address(0), address(this), TOTAL_SUPPLY);
        }
        function name() public view returns (string memory) {
            return m_Name;
        }
        function symbol() public view returns (string memory) {
            return m_Symbol;
        }
        function decimals() public view returns (uint8) {
            return m_Decimals;
        }
        function totalSupply() public pure override returns (uint256) {
            return TOTAL_SUPPLY;
        }
        function balanceOf(address _account) public view override returns (uint256) {
            return m_Balances[_account];
        }
        function transfer(address _recipient, uint256 _amount) public override returns (bool) {
            _transfer(_msgSender(), _recipient, _amount);
            return true;
        }
        function allowance(address _owner, address _spender) public view override returns (uint256) {
            return m_Allowances[_owner][_spender];
        }
        function approve(address _spender, uint256 _amount) public override returns (bool) {
            _approve(_msgSender(), _spender, _amount);
            return true;
        }
        function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
            _transfer(_sender, _recipient, _amount);
            _approve(_sender, _msgSender(), m_Allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
        function _isBuy(address _sender) private view returns (bool) {
            return _sender == m_UniswapV2Pair;
        }
        function _isSell(address _recipient) private view returns (bool) {
            return _recipient == m_UniswapV2Pair;
        }
        function _trader(address _sender, address _recipient) private view returns (bool) {
            return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        }
        function _isExchangeTransfer(address _sender, address _recipient) private view returns (bool) {
            return _sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair;
        }
        function _txRestricted(address _sender, address _recipient) private view returns (bool) {
            return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
        }
        function _walletCapped(address _recipient) private view returns (bool) {
            return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
        }
        function _checkTX() private view returns (uint256){
            if(block.timestamp <= m_Launched.add(15 minutes))
                return TOTAL_SUPPLY.div(400);
            else
                return TOTAL_SUPPLY;
        }
        function _approve(address _owner, address _spender, uint256 _amount) private {
            require(_owner != address(0), "ERC20: approve from the zero address");
            require(_spender != address(0), "ERC20: approve to the zero address");
            m_Allowances[_owner][_spender] = _amount;
            emit Approval(_owner, _spender, _amount);
        }
        function _transfer(address _sender, address _recipient, uint256 _amount) private {
            require(_sender != address(0), "ERC20: transfer from the zero address");
            require(_amount > 0, "Transfer amount must be greater than zero");
            
            if(m_AntiBot && _isExchangeTransfer(_sender, _recipient)) {
                require(!AntiBot.scanAddress(_sender, _recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");  
                AntiBot.registerBlock(_sender, _recipient, tx.origin);
            }
            
            if(_walletCapped(_recipient))
                require(balanceOf(_recipient) < m_WalletLimit);
            
            uint256 _taxes = 0;            
            if (_trader(_sender, _recipient)) {
                _taxes = _amount.div(pMax.div(_getTaxDenominator()));
                require(block.timestamp >= m_Launched);
                if (_txRestricted(_sender, _recipient))
                    require(_amount <= _checkTX());
            }
            _updateBalances(_sender, _recipient, _amount, _taxes);
        }
        function _updateBalances(address _sender, address _recipient, uint256 _amount, uint256 _taxes) private {
            uint256 _netAmount = _amount.sub(_taxes);
            _updateDAO(_sender, _amount);

            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_netAmount);
            m_Balances[address(this)] = m_Balances[address(this)].add(_taxes);

            if(_isBuy(_sender))
                _trackBuy(_recipient, _netAmount);
            else if(_isSell(_recipient))
                _trackSell(_sender);
            else{
                _trackSell(_sender);
                _trackBuy(_recipient, _netAmount);
            }
            emit Transfer(_sender, _recipient, _netAmount);
        }
        function addLiquidity() external onlyOwner() {
            require(!m_Liquidity,"Liquidity already added.");
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            m_UniswapV2Router = _uniswapV2Router;
            _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
            m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
            IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
            m_Liquidity = true;
        }
        function launch(uint256 _timer) external onlyOwner() {
            m_Launched = block.timestamp.add(_timer);
            m_AntiBot = true;
            m_Round = 1;
            m_RoundStart = m_Launched;
            m_Raffle[m_Round].push(Buyer(address(0),0,false));
        }
        function _updateDAO(address _sender, uint256 _amount) private {
            uint256 _senderBal = balanceOf(_sender);
            if(_sender != m_UniswapV2Pair && _sender != address(this)){
                if(_senderBal > m_DAOmin){
                    if(_senderBal.sub(_amount) < m_DAOmin){
                        _cleanVotes(_sender);
                    }
                }
            }
        }
        function _cleanVotes(address _sender) private {
            if(m_VoterIdx[m_VoteCycle][msg.sender] != 0){
                delete m_Voters[m_VoteCycle][m_VoterIdx[m_VoteCycle][_sender]];
                m_VoterIdx[m_VoteCycle][msg.sender] = 0;
            }
        }
        function _trackBuy(address _recipient,uint256 _amount) private {
            if(m_BuyerId[m_Round][_recipient] != 0){                           
                m_Raffle[m_Round][m_BuyerId[m_Round][_recipient]].amount += _amount;    
            }
            else{
                m_Raffle[m_Round].push(Buyer(_recipient, _amount, true));
                m_BuyerId[m_Round][_recipient] = m_Raffle[m_Round].length - 1;
            }
        }
        function _trackSell(address _sender) private {
            if(m_BuyerId[m_Round][_sender] != 0)
                m_Raffle[m_Round][m_BuyerId[m_Round][_sender]].eligible = false;
            else{
                m_Raffle[m_Round].push(Buyer(_sender, 0, false));
                m_BuyerId[m_Round][_sender] = m_Raffle[m_Round].length - 1;
            }
        }
        function _swapTokensForETH(uint256 _amount) private {
            address[] memory _path = new address[](2);
            _path[0] = address(this);
            _path[1] = m_UniswapV2Router.WETH();
            _approve(address(this), address(m_UniswapV2Router), _amount);
            m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amount,
                0,
                _path,
                address(this),
                block.timestamp
            );
        }
        function _disperseETH(address[] memory _winners, address _specialWinner, uint256 _invalid) private {
            uint256 _bal = address(this).balance;
            if(_invalid == 0){
                uint256 _denom = _getTaxDenominator();  
                uint256 _marketingShare = _bal.mul(m_MarketingTax).div(_denom);
                uint256 _share = _bal.mul(m_RaffleTax).div(_denom).div(_winners.length);
                uint256 _largestShare = _bal.mul(m_LargestBuyerTax).div(_denom).div(_winners.length);

                if (_marketingShare > 0) {
                    m_MarketingWallet.transfer(_marketingShare);
                    _bal = _bal.sub(_marketingShare);
                }
                m_TotalWinnings += _bal;
                if(_share > 0){
                    for(uint256 i=0; i<_winners.length; i++){                      
                        if(_share > address(this).balance) 
                            _share = address(this).balance;                   
                        if(m_Raffle[m_Round][m_BuyerId[m_Round][_winners[i]]].eligible){
                            m_Winners.push(_winners[i]);
                            m_Winnings.push(_share);
                            m_Earnings[_winners[i]] += _share;
                            payable(_winners[i]).transfer(_share);
                        }
                        _bal = _bal.sub(_share);
                    }            
                }
                if(_specialWinner != address(0) && _largestShare > 0){   
                    if(_largestShare > address(this).balance) 
                        _largestShare = address(this).balance;                
                    if(m_Raffle[m_Round][m_BuyerId[m_Round][_specialWinner]].eligible){
                        m_Winners.push(_specialWinner);
                        m_Winnings.push(_bal);
                        m_Earnings[_specialWinner] += _bal;                    
                        payable(_specialWinner).transfer(_bal);
                    }
                }
            }
            else
                m_MarketingWallet.transfer(_bal.div(_invalid));
        }
        function _getTaxDenominator() private view returns (uint256) {
            uint256 _ret = m_MarketingTax;
            _ret += m_LargestBuyerTax;
            _ret += m_RaffleTax;
            return _ret;
        }
        function _applyRoundSettings(uint256 _raffleTax, uint256 _biggestTax, uint256 _interval) private {
            if(m_RaffleTax != _raffleTax)
                m_RaffleTax = _raffleTax;
            if(m_LargestBuyerTax != _biggestTax)
                m_LargestBuyerTax = _biggestTax;
            if(m_Interval != _interval)
                m_Interval = _interval;
        }
        function updateMarketingTax(uint256 _value) external onlyOwner() {
            m_MarketingTax = _value;
        }
        function viewWinners() external view returns (address[] memory, uint256[] memory) {
            return (m_Winners, m_Winnings);
        }
        function earningsOf(address _address) external view returns (uint256) {
            return m_Earnings[_address];
        }
        function vote(uint256 _raffle, uint256 _biggest, uint256 _interval) external {
            require(balanceOf(msg.sender) >= m_DAOmin);
            require(_raffle >= 1000);
            require(_raffle <= 7000);
            require(_biggest >= 0);
            require(_biggest <= 7000);
            require(_interval >= 900);
            require(_interval <= 86400);
            if(m_VoterIdx[m_VoteCycle][msg.sender] == 0){
                m_Voters[m_VoteCycle].push(Vote(_interval, _raffle, _biggest, 0));
                m_VoterIdx[m_VoteCycle][msg.sender] = m_Voters[m_VoteCycle].length - 1;
            }
            else{
                m_Voters[m_VoteCycle][m_VoterIdx[m_VoteCycle][msg.sender]].raffleTax = _raffle;
                m_Voters[m_VoteCycle][m_VoterIdx[m_VoteCycle][msg.sender]].biggestTax = _biggest;
                m_Voters[m_VoteCycle][m_VoterIdx[m_VoteCycle][msg.sender]].interval = _interval;
            }

        }
        function voteForGeneric(uint256 _value) external {
            require(balanceOf(msg.sender) >= m_DAOmin);
            if(m_VoterIdx[m_VoteCycle][msg.sender] == 0){
                m_Voters[m_VoteCycle].push(Vote(0, 0, 0, _value));
                m_VoterIdx[m_VoteCycle][msg.sender] = m_Voters[m_VoteCycle].length - 1;
            }
            else
                m_Voters[m_VoteCycle][m_VoterIdx[m_VoteCycle][msg.sender]].generic = _value;
        }        
        function getVotes() external view returns (Vote[] memory) {
            return m_Voters[m_VoteCycle];
        }       
        function getBuyers() external view returns (Buyer[] memory, Buyer[] memory) {
            return (m_Raffle[m_Round-1], m_Raffle[m_Round]);
        }        
        function getGameState() external view returns (GameState memory) {
            return GameState(m_Round,m_Interval,m_RaffleTax,m_LargestBuyerTax);
        } 
        function resetGame(address[] memory _winners, address _specialWinner, uint256 _raffleTax, uint256 _biggestTax, uint256 _interval, uint256 _cycle, uint256 _invalid) external {
            require(msg.sender == m_Controller);
            uint256 _bal = balanceOf(address(this));
            _swapTokensForETH(_bal);
            _disperseETH(_winners, _specialWinner, _invalid);           
            _applyRoundSettings(_raffleTax, _biggestTax, _interval); 
            m_Round += 1;
            m_RoundStart = block.timestamp;
            m_Raffle[m_Round].push(Buyer(address(0), 0, false));
            if (_cycle != m_VoteCycle)
                m_Voters[_cycle].push(Vote(0,0,0,0));
            m_VoteCycle = _cycle;
        }
        function getTotalWinnings() external view returns (uint256){
            return m_TotalWinnings;
        }
        function emergencyReclaim() external onlyOwner() {
            m_MarketingWallet.transfer(address(this).balance);
        }
        function toggleAntibot() external onlyOwner() {
            if(m_AntiBot){
                m_AntiBot = false;
                return;
            }
            m_AntiBot = true;
        }
        function addTaxWhitelist(address _address) external onlyOwner() {
            m_ExcludedAddresses[_address] = true;
        }
        function remTaxWhitelist(address _address) external onlyOwner() {
            m_ExcludedAddresses[_address] = false;
        }
        function adjustWalletCap(uint256 _factor) external onlyOwner(){
            m_WalletLimit = TOTAL_SUPPLY.div(_factor);
        }
    }