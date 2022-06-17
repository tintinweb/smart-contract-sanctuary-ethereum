/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

contract NFTISMUSController {
    //Fixed Addresses
    /*
    COIN
    CONTROLLER
    OWNER = MSG.SENDER
     */
    address private _Controller;
    address private _Owner;
    //Splited Coin Logic
    /*
    NFM Logic
    PAD
    MINTING
    TIMERS
    BURNING
    UV2 Integrations
    ExtraBonus on ETH,USDT,USDC,WETH,WBTC
     */
    address private _NFM; //X
    address private _Timer; //X
    address private _Pad; //X
    address private _Minting; //X
    address private _Burning; //--
    address private _Exchange; //X
    address private _Treasury; //--
    address private _Distribute; //--
    //Integrated Logic of UNISWAPV2,...
    /*
    Important Addresses to be whitelisted on Controller of 
    the the project
    UNISWAP Adresses
     */
    address private _UV2Pool; //X
    address private _Swap; //--
    address private _AddLiquidity; //--
    address private _ExtraBonus; //--
    address private _BuyBack; //--
    //Integrated Logic of DAO,...
    /*
    Important Addresses to be whitelisted on Controller of 
    the 2nd Part of the project
    DAO Adresses
     */
    address private _AFT; //--
    address private _DaoGovernance; //--
    address private _Contributor; //--
    address private _DaoReserveERC20; //--
    address private _DaoReserveETH; //--
    address private _DaoPulling; //--
    address private _DaoContributorPulling; //--
    address private _DaoNFMPulling; //--
    address private _DaoTotalPulling; //--
    //Integrated Logic of Lottery
    /*
    Important Addresses to be whitelisted on Controller of 
    the 2nd Part of the project
    Lottery Adresses
     */
    address private _Lottery; //--
    //Integrated Logic of NFT,...
    /*
    Important Addresses to be whitelisted on Controller of 
    the 2nd Part of the project
    NFT Adresses
     */
    address private _NFTFactory; //--
    address private _NFTTreasuryERC20; //--
    address private _NFTTreasuryETH; //--
    address private _NFTPools; //--
    //Integrated Logic of Staking
    /*
    Important Addresses to be whitelisted on Controller of 
    the 2nd Part of the project
    Staking Adresses
     */
    address private _NFMStaking; //--
    address private _NFMStakingTreasuryERC20; //--
    address private _NFMStakingTreasuryETH; //--
    //Integrated Logic of DEX
    /*
    Important Addresses to be whitelisted on Controller of 
    the 2nd Part of the project
    DEX Adresses
     */
    address private _DexExchange; //--
    address private _DexExchangeAsk; //--
    address private _DexExchangeBid; //--
    address private _DexExchangeReserveERC20; //--
    address private _DexExchangeReserveETH; //--
    /*
    Integrated Logic IDO
    Important Addresses To be whitelisted on Controller
    IDO ADRESSES */
    address private _IDOPool; //--
    address private _IDOExchange; //--
    mapping(address => mapping(address => bool)) public _whitelisted;
    //modifier
    modifier onlyOwner() {
        require(msg.sender == _Owner && msg.sender != address(0), "oO");
        _;
    }

    constructor() {
        _Owner = msg.sender;
        _whitelisted[address(this)][msg.sender] = true;
        _Controller = address(this);
        _whitelisted[address(this)][_Controller] = true;
    }

    function _checkWLSC(address root, address client)
        public
        view
        returns (bool)
    {
        if (_whitelisted[root][client] == true) {
            return true;
        } else {
            return false;
        }
    }

    function _addWLSC(address root, address client)
        public
        onlyOwner
        returns (bool)
    {
        _whitelisted[root][client] = true;
        return true;
    }

    function _changeWLSC(address root, address client)
        public
        onlyOwner
        returns (bool)
    {
        _whitelisted[root][client] = false;
        return true;
    }

    function _addNFM(address nfm) public onlyOwner returns (bool) {
        _NFM = nfm;
        _whitelisted[_Controller][nfm] = true;
        return true;
    }

    function _addContributor(address contributor)
        public
        onlyOwner
        returns (bool)
    {
        _Contributor = contributor;
        _whitelisted[_Controller][contributor] = true;
        return true;
    }

    function _addExtraBonus(address extrabonus, address buyback)
        public
        onlyOwner
        returns (bool)
    {
        _ExtraBonus = extrabonus;
        _BuyBack = buyback;
        _whitelisted[_Controller][extrabonus] = true;
        _whitelisted[_Controller][buyback] = true;
        return true;
    }

    function _addTimer(address timer) public onlyOwner returns (bool) {
        _Timer = timer;
        _whitelisted[_Controller][timer] = true;
        return true;
    }

    function _addPad(address pad) public onlyOwner returns (bool) {
        _Pad = pad;
        _whitelisted[_Controller][pad] = true;
        return true;
    }

    function _addMinting(address minting) public onlyOwner returns (bool) {
        _Minting = minting;
        _whitelisted[_Controller][minting] = true;
        return true;
    }

    function _addBurning(address burning) public onlyOwner returns (bool) {
        _Burning = burning;
        _whitelisted[_Controller][burning] = true;
        return true;
    }

    function _addSwap(address USwap) public onlyOwner returns (bool) {
        _Swap = USwap;
        _whitelisted[_Controller][USwap] = true;
        return true;
    }

    function _addUV2Pool(address UV2Pool) public onlyOwner returns (bool) {
        _UV2Pool = UV2Pool;
        _whitelisted[_Controller][UV2Pool] = true;
        return true;
    }

    function _addLiquidity(address ULiquidity) public onlyOwner returns (bool) {
        _AddLiquidity = ULiquidity;
        _whitelisted[_Controller][ULiquidity] = true;
        return true;
    }

    function _addExchange(address NFMExchange) public onlyOwner returns (bool) {
        _Exchange = NFMExchange;
        _whitelisted[_Controller][NFMExchange] = true;
        return true;
    }

    function _addDistribute(address NFMDistribute)
        public
        onlyOwner
        returns (bool)
    {
        _Distribute = NFMDistribute;
        _whitelisted[_Controller][NFMDistribute] = true;
        return true;
    }

    function _addTreasury(address treasury) public onlyOwner returns (bool) {
        _Treasury = treasury;
        _whitelisted[_Controller][treasury] = true;
        return true;
    }

    function _addGovernance(address governance)
        public
        onlyOwner
        returns (bool)
    {
        _DaoGovernance = governance;
        _whitelisted[_Controller][governance] = true;
        return true;
    }

    function _addDaoReserveERC20(address DaoReserveERC20)
        public
        onlyOwner
        returns (bool)
    {
        _DaoReserveERC20 = DaoReserveERC20;
        _whitelisted[_Controller][DaoReserveERC20] = true;
        return true;
    }

    function _addDaoReserveETH(address DaoReserveETH)
        public
        onlyOwner
        returns (bool)
    {
        _DaoReserveETH = DaoReserveETH;
        _whitelisted[_Controller][DaoReserveETH] = true;
        return true;
    }

    function _addDaoPulling(address DaoPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoPulling = DaoPulling;
        _whitelisted[_Controller][DaoPulling] = true;
        return true;
    }

    function _addDaoContributorPulling(address DaoContributorPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoContributorPulling = DaoContributorPulling;
        _whitelisted[_Controller][DaoContributorPulling] = true;
        return true;
    }

    function _addDaoNFMPulling(address DaoNFMPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoNFMPulling = DaoNFMPulling;
        _whitelisted[_Controller][DaoNFMPulling] = true;
        return true;
    }

    function _addDaoTotalPulling(address DaoTotalPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoTotalPulling = DaoTotalPulling;
        _whitelisted[_Controller][DaoTotalPulling] = true;
        return true;
    }

    function _addLottery(address Lottery) public onlyOwner returns (bool) {
        _Lottery = Lottery;
        _whitelisted[_Controller][Lottery] = true;
        return true;
    }

    function _addNFTFactory(address NFTFactory)
        public
        onlyOwner
        returns (bool)
    {
        _NFTFactory = NFTFactory;
        _whitelisted[_Controller][NFTFactory] = true;
        return true;
    }

    function _addNFTTreasuryERC20(address NFTTreasuryERC20)
        public
        onlyOwner
        returns (bool)
    {
        _NFTTreasuryERC20 = NFTTreasuryERC20;
        _whitelisted[_Controller][NFTTreasuryERC20] = true;
        return true;
    }

    function _addNFTTreasuryETH(address NFTTreasuryETH)
        public
        onlyOwner
        returns (bool)
    {
        _NFTTreasuryETH = NFTTreasuryETH;
        _whitelisted[_Controller][NFTTreasuryETH] = true;
        return true;
    }

    function _addNFTPools(address NFTPools) public onlyOwner returns (bool) {
        _NFTPools = NFTPools;
        _whitelisted[_Controller][NFTPools] = true;
        return true;
    }

    function _addNFMStaking(address NFMStaking)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStaking = NFMStaking;
        _whitelisted[_Controller][NFMStaking] = true;
        return true;
    }

    function _addNFMStakingTreasuryERC20(address NFMStakingTreasuryERC20)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStakingTreasuryERC20 = NFMStakingTreasuryERC20;
        _whitelisted[_Controller][NFMStakingTreasuryERC20] = true;
        return true;
    }

    function _addNFMStakingTreasuryETH(address NFMStakingTreasuryETH)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStakingTreasuryETH = NFMStakingTreasuryETH;
        _whitelisted[_Controller][NFMStakingTreasuryETH] = true;
        return true;
    }

    function _addDexExchange(address DexExchange)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchange = DexExchange;
        _whitelisted[_Controller][DexExchange] = true;
        return true;
    }

    function _addDexExchangeAsk(address DexExchangeAsk)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeAsk = DexExchangeAsk;
        _whitelisted[_Controller][DexExchangeAsk] = true;
        return true;
    }

    function _addDexExchangeBid(address DexExchangeBid)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeBid = DexExchangeBid;
        _whitelisted[_Controller][DexExchangeBid] = true;
        return true;
    }

    function _addDexExchangeReserveERC20(address DexExchangeReserveERC20)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeReserveERC20 = DexExchangeReserveERC20;
        _whitelisted[_Controller][DexExchangeReserveERC20] = true;
        return true;
    }

    function _addDexExchangeReserveETH(address DexExchangeReserveETH)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeReserveETH = DexExchangeReserveETH;
        _whitelisted[_Controller][DexExchangeReserveETH] = true;
        return true;
    }

    function _addAFT(address AFT) public onlyOwner returns (bool) {
        _AFT = AFT;
        _whitelisted[_Controller][AFT] = true;
        return true;
    }

    function _addIDOPool(address IDOPool) public onlyOwner returns (bool) {
        _IDOPool = IDOPool;
        _whitelisted[_Controller][IDOPool] = true;
        return true;
    }

    function _addIDOExchange(address IDOExchange)
        public
        onlyOwner
        returns (bool)
    {
        _IDOExchange = IDOExchange;
        _whitelisted[_Controller][IDOExchange] = true;
        return true;
    }

    /////////GET
    function _getController() public view returns (address) {
        return _Controller;
    }

    function _getOwner() public view returns (address) {
        return _Owner;
    }

    function _getNFM() public view returns (address) {
        return _NFM;
    }

    function _getTimer() public view returns (address) {
        return _Timer;
    }

    function _getPad() public view returns (address) {
        return _Pad;
    }

    function _getBonusBuyBack()
        public
        view
        returns (address Bonus, address Buyback)
    {
        return (_ExtraBonus, _BuyBack);
    }

    function _getMinting() public view returns (address) {
        return _Minting;
    }

    function _getContributor() public view returns (address) {
        return _Contributor;
    }

    function _getBurning() public view returns (address) {
        return _Burning;
    }

    function _getSwap() public view returns (address) {
        return _Swap;
    }

    function _getLiquidity() public view returns (address) {
        return _AddLiquidity;
    }

    function _getUV2Pool() public view returns (address) {
        return _UV2Pool;
    }

    function _getExchange() public view returns (address) {
        return _Exchange;
    }

    function _getDistribute() public view returns (address) {
        return _Distribute;
    }

    function _getTreasury() public view returns (address) {
        return _Treasury;
    }

    function _getGovernance() public view returns (address) {
        return _DaoGovernance;
    }

    function _getDaoReserveERC20() public view returns (address) {
        return _DaoReserveERC20;
    }

    function _getDaoReserveETH() public view returns (address) {
        return _DaoReserveETH;
    }

    function _getDaoPulling() public view returns (address) {
        return _DaoPulling;
    }

    function _getDaoContributorPulling() public view returns (address) {
        return _DaoContributorPulling;
    }

    function _getDaoNFMPulling() public view returns (address) {
        return _DaoNFMPulling;
    }

    function _getDaoTotalPulling() public view returns (address) {
        return _DaoTotalPulling;
    }

    function _getLottery() public view returns (address) {
        return _Lottery;
    }

    function _getNFTFactory() public view returns (address) {
        return _NFTFactory;
    }

    function _getNFTTreasuryERC20() public view returns (address) {
        return _NFTTreasuryERC20;
    }

    function _getNFTTreasuryETH() public view returns (address) {
        return _NFTTreasuryETH;
    }

    function _getNFTPools() public view returns (address) {
        return _NFTPools;
    }

    function _getNFMStaking() public view returns (address) {
        return _NFMStaking;
    }

    function _getNFMStakingTreasuryERC20() public view returns (address) {
        return _NFMStakingTreasuryERC20;
    }

    function _getNFMStakingTreasuryETH() public view returns (address) {
        return _NFMStakingTreasuryETH;
    }

    function _getDexExchange() public view returns (address) {
        return _DexExchange;
    }

    function _getDexExchangeAsk() public view returns (address) {
        return _DexExchangeAsk;
    }

    function _getDexExchangeBid() public view returns (address) {
        return _DexExchangeBid;
    }

    function _getDexExchangeReserveERC20() public view returns (address) {
        return _DexExchangeReserveERC20;
    }

    function _getDexExchangeReserveETH() public view returns (address) {
        return _DexExchangeReserveETH;
    }

    function _getAFT() public view returns (address) {
        return _AFT;
    }

    function _getIDOPool() public view returns (address) {
        return _IDOPool;
    }

    function _getIDOExchange() public view returns (address) {
        return _IDOExchange;
    }
}