/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMController.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract serves as a connecting bridge to all system-relevant contracts. And is used as an interface in the relevant contracts.
/// @dev You can look at the controller similar to a proxy pattern. But here upgrades will only be possible with the agreement of the Dao.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

contract NFMController {
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Controller;
    address private _Owner;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of NFM
    /*
    Important NFM Addresses to be whitelisted on Controller
    NFM Adresses
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _NFM;                                     //ERC20 Contract
    address private _Timer;                                    //Timer Contract
    address private _Pad;                                       //Pump and Dump Contract
    address private _Minting;                                  //Minting Contract
    address private _Burning;                                 //Burning Contract
    address private _Exchange;                             //NFM DEX Contract
    address private _Treasury;                               //NFM Treasury Contract
    address private _Distribute;                              //Principals Distribution Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of UNISWAPV2,...
    /*
    Important UNISWAP Addresses to be whitelisted on Controller 
    UNISWAP Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _UV2Pool;                                   //UniswapV2 Contract
    address private _Swap;                                        //Swap Contract
    address private _AddLiquidity;                              //AddLiquidity Contract
    address private _ExtraBonus;                               //Bonus Contract
    address private _BuyBack;                                   //BuyBack Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of DAO,...
    /*
    Important DAO Addresses to be whitelisted on Controller 
    DAO Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _AFT;                                           //ERC20 Contract
    address private _DaoGovernance;                       //Governance Logic Contract
    address private _Contributor;                               //Contributors Contract
    address private _DaoReserveERC20;                 //Dao ERC20 Treasury Contract
    address private _DaoReserveETH;                     //Dao Matic Treasury Contract
    address private _DaoPulling;                               //Governance Pulling Contract
    address private _DaoContributorPulling;             //Contributor Pulling Contract
    address private _DaoNFMPulling;                       //NFM Pulling Contract
    address private _DaoTotalPulling;                       //Final Pulling Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of Lottery
    /*
    Important Lottery Addresses to be whitelisted on Controller
    Lottery Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Lottery;                                       //Lottery Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of NFT,...
    /*
    Important NFT Addresses to be whitelisted on Controller
    NFT Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _NFTFactory;                                //NFT Factory Contract
    address private _NFTTreasuryERC20;                  //ERC20 Treasury Contract
    address private _NFTTreasuryETH;                       //MATIC Treasury Contract
    address private _NFTPools;                                   //NFT Staking Pools Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of Staking
    /*
    Important Staking Addresses to be whitelisted on Controller
    Staking Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _NFMStaking;                                    //NFM Staking
    address private _NFMStakingTreasuryERC20;          //ERC20 Treasury of Stake Contract
    address private _NFMStakingTreasuryETH;               //MATIC Treasury of Stake Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //Integrated Logic of DEX
    /*
    Important DEX Addresses to be whitelisted on Controller
    DEX Adresses
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _DexExchange;                                           //DEX Contract
    address private _DexExchangeAsk;                                     //DEX Ask Contract 
    address private _DexExchangeBid;                                      //DEX Bid Contract
    address private _DexExchangeReserveERC20;                  //ERC20 Treasury of DEX Contract
    address private _DexExchangeReserveETH;                       //MATIC Treasury of DEX Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    Integrated Logic IDO
    Important IDO Addresses To be whitelisted on Controller
    IDO ADRESSES */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _IDOPool;                                                   //IDO Launchpad (Factory) Contract
    address private _IDOExchange;                                           //IDO DEX Contract
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    CONTROLLER => INTERFACE = FULL RIGHTS (Can interact with all Functions, are excluded from Fees and PAD).
    0x0000000000000000000000000000000000000000 => PARTNER INTERFACE = MEDIUM RIGHTS (Can only interact with permited functions)
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => mapping(address => bool)) public _whitelisted;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //modifier
    //Ownership is later passed to the Dao.
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    * SETTER FUNCTIONS
    */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_checkWLSC(address root, address client) returns (bool);
    This function checks the rights of the interacting address
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addWLSC(address root, address client) returns (bool);
    This function adds new addresses and their rights.
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addWLSC(address root, address client)
        public
        onlyOwner
        returns (bool)
    {
        _whitelisted[root][client] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_changeWLSC(address root, address client) returns (bool);
    This function changes the rights for a specific address
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _changeWLSC(address root, address client)
        public
        onlyOwner
        returns (bool)
    {
        _whitelisted[root][client] = false;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addNFM(address nfm) returns (bool);
    This function adds the NFM interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFM(address nfm) public onlyOwner returns (bool) {
        _NFM = nfm;
        _whitelisted[_Controller][nfm] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addContributor(address contributor) returns (bool);
    This function adds the Contributor interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addContributor(address contributor)
        public
        onlyOwner
        returns (bool)
    {
        _Contributor = contributor;
        _whitelisted[_Controller][contributor] = true;
        return true;
    }
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addExtraBonus(address extrabonus, address buyback) returns (bool);
    This function adds the Bonus and BuyBack interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addTimer(address timer) returns (bool);
    This function adds the Timer interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addTimer(address timer) public onlyOwner returns (bool) {
        _Timer = timer;
        _whitelisted[_Controller][timer] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addPad(address pad) returns (bool);
    This function adds the PAD interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addPad(address pad) public onlyOwner returns (bool) {
        _Pad = pad;
        _whitelisted[_Controller][pad] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addMinting(address minting) returns (bool);
    This function adds the Minting interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addMinting(address minting) public onlyOwner returns (bool) {
        _Minting = minting;
        _whitelisted[_Controller][minting] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addBurning(address burning) returns (bool);
    This function adds the Burning interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addBurning(address burning) public onlyOwner returns (bool) {
        _Burning = burning;
        _whitelisted[_Controller][burning] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addSwap(address USwap) returns (bool);
    This function adds the Swap interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addSwap(address USwap) public onlyOwner returns (bool) {
        _Swap = USwap;
        _whitelisted[_Controller][USwap] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addUV2Pool(address UV2Pool) returns (bool);
    This function adds the Uniswap interface and its permissions
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addUV2Pool(address UV2Pool) public onlyOwner returns (bool) {
        _UV2Pool = UV2Pool;
        _whitelisted[_Controller][UV2Pool] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addLiquidity(address ULiquidity) returns (bool);
    This function adds the AddLiquidity interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addLiquidity(address ULiquidity) public onlyOwner returns (bool) {
        _AddLiquidity = ULiquidity;
        _whitelisted[_Controller][ULiquidity] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addExchange(address NFMExchange) returns (bool);
    This function adds the NFM-Dex interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addExchange(address NFMExchange) public onlyOwner returns (bool) {
        _Exchange = NFMExchange;
        _whitelisted[_Controller][NFMExchange] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDistribute(address NFMDistribute) returns (bool);
    This function adds the Distribution interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDistribute(address NFMDistribute)
        public
        onlyOwner
        returns (bool)
    {
        _Distribute = NFMDistribute;
        _whitelisted[_Controller][NFMDistribute] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addTreasury(address treasury) returns (bool);
    This function adds the Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addTreasury(address treasury) public onlyOwner returns (bool) {
        _Treasury = treasury;
        _whitelisted[_Controller][treasury] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addGovernance(address governance) returns (bool);
    This function adds the Governance interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addGovernance(address governance)
        public
        onlyOwner
        returns (bool)
    {
        _DaoGovernance = governance;
        _whitelisted[_Controller][governance] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoReserveERC20(address DaoReserveERC20) returns (bool);
    This function adds the ERC20 Dao Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoReserveERC20(address DaoReserveERC20)
        public
        onlyOwner
        returns (bool)
    {
        _DaoReserveERC20 = DaoReserveERC20;
        _whitelisted[_Controller][DaoReserveERC20] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoReserveETH(address DaoReserveETH) returns (bool);
    This function adds the MATIC Dao Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoReserveETH(address DaoReserveETH)
        public
        onlyOwner
        returns (bool)
    {
        _DaoReserveETH = DaoReserveETH;
        _whitelisted[_Controller][DaoReserveETH] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoPulling(address DaoPulling) returns (bool);
    This function adds the Dao Pulling (LEVEL1) interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoPulling(address DaoPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoPulling = DaoPulling;
        _whitelisted[_Controller][DaoPulling] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoContributorPulling(address DaoContributorPulling) returns (bool);
    This function adds the Dao Contributor Pulling (LEVEL 2) interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoContributorPulling(address DaoContributorPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoContributorPulling = DaoContributorPulling;
        _whitelisted[_Controller][DaoContributorPulling] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoNFMPulling(address DaoNFMPulling) returns (bool);
    This function adds the Dao NFM Pulling (LEVEL 3) interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoNFMPulling(address DaoNFMPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoNFMPulling = DaoNFMPulling;
        _whitelisted[_Controller][DaoNFMPulling] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addDaoTotalPulling(address DaoTotalPulling) returns (bool);
    This function adds the Dao Total Pulling interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDaoTotalPulling(address DaoTotalPulling)
        public
        onlyOwner
        returns (bool)
    {
        _DaoTotalPulling = DaoTotalPulling;
        _whitelisted[_Controller][DaoTotalPulling] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addLottery(address Lottery) returns (bool);
    This function adds the Lottery interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addLottery(address Lottery) public onlyOwner returns (bool) {
        _Lottery = Lottery;
        _whitelisted[_Controller][Lottery] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addNFTFactory(address NFTFactory) returns (bool);
    This function adds the NFT Factory interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFTFactory(address NFTFactory)
        public
        onlyOwner
        returns (bool)
    {
        _NFTFactory = NFTFactory;
        _whitelisted[_Controller][NFTFactory] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFTTreasuryERC20(address NFTTreasuryERC20) returns (bool);
    This function adds the ERC20 NFT Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFTTreasuryERC20(address NFTTreasuryERC20)
        public
        onlyOwner
        returns (bool)
    {
        _NFTTreasuryERC20 = NFTTreasuryERC20;
        _whitelisted[_Controller][NFTTreasuryERC20] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFTTreasuryETH(address NFTTreasuryETH) returns (bool);
    This function adds the MATIC NFT Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFTTreasuryETH(address NFTTreasuryETH)
        public
        onlyOwner
        returns (bool)
    {
        _NFTTreasuryETH = NFTTreasuryETH;
        _whitelisted[_Controller][NFTTreasuryETH] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFTTreasuryETH(address NFTTreasuryETH) returns (bool);
    This function adds the MATIC NFT Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFTPools(address NFTPools) public onlyOwner returns (bool) {
        _NFTPools = NFTPools;
        _whitelisted[_Controller][NFTPools] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFMStaking(address NFMStaking) returns (bool);
    This function adds the NFM Staking interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFMStaking(address NFMStaking)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStaking = NFMStaking;
        _whitelisted[_Controller][NFMStaking] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFMStakingTreasuryERC20(address NFMStakingTreasuryERC20) returns (bool);
    This function adds the ERC20 Staking Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFMStakingTreasuryERC20(address NFMStakingTreasuryERC20)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStakingTreasuryERC20 = NFMStakingTreasuryERC20;
        _whitelisted[_Controller][NFMStakingTreasuryERC20] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addNFMStakingTreasuryETH(address NFMStakingTreasuryETH) returns (bool);
    This function adds the MATIC Staking Treasury interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addNFMStakingTreasuryETH(address NFMStakingTreasuryETH)
        public
        onlyOwner
        returns (bool)
    {
        _NFMStakingTreasuryETH = NFMStakingTreasuryETH;
        _whitelisted[_Controller][NFMStakingTreasuryETH] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addDexExchange(address DexExchange) returns (bool);
    This function adds the DexExchange interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDexExchange(address DexExchange)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchange = DexExchange;
        _whitelisted[_Controller][DexExchange] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addDexExchangeAsk(address DexExchangeAsk) returns (bool);
    This function adds the DexExchangeAsk interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDexExchangeAsk(address DexExchangeAsk)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeAsk = DexExchangeAsk;
        _whitelisted[_Controller][DexExchangeAsk] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addDexExchangeBid(address DexExchangeBid) returns (bool);
    This function adds the DexExchangeBid interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDexExchangeBid(address DexExchangeBid)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeBid = DexExchangeBid;
        _whitelisted[_Controller][DexExchangeBid] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addDexExchangeReserveERC20(address DexExchangeReserveERC20) returns (bool);
    This function adds the DexExchangeReserveERC20 interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDexExchangeReserveERC20(address DexExchangeReserveERC20)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeReserveERC20 = DexExchangeReserveERC20;
        _whitelisted[_Controller][DexExchangeReserveERC20] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addDexExchangeReserveETH(address DexExchangeReserveETH) returns (bool);
    This function adds the DexExchangeReserveMATIC interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addDexExchangeReserveETH(address DexExchangeReserveETH)
        public
        onlyOwner
        returns (bool)
    {
        _DexExchangeReserveETH = DexExchangeReserveETH;
        _whitelisted[_Controller][DexExchangeReserveETH] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addAFT(address AFT) returns (bool);
    This function adds the AFT interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addAFT(address AFT) public onlyOwner returns (bool) {
        _AFT = AFT;
        _whitelisted[_Controller][AFT] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addIDOPool(address IDOPool) returns (bool);
    This function adds the IDO Launchpad interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addIDOPool(address IDOPool) public onlyOwner returns (bool) {
        _IDOPool = IDOPool;
        _whitelisted[_Controller][IDOPool] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _addIDOExchange(address IDOExchange) returns (bool);
    This function adds the IDOExchange interface and its permissions
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addIDOExchange(address IDOExchange)
        public
        onlyOwner
        returns (bool)
    {
        _IDOExchange = IDOExchange;
        _whitelisted[_Controller][IDOExchange] = true;
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    * GETTER FUNCTIONS
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getController() returns (address);
    This function returns Controller address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getController() public view returns (address) {
        return _Controller;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getOwner() returns (address);
    This function returns Owner address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getOwner() public view returns (address) {
        return _Owner;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFM() returns (address);
    This function returns NFM address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFM() public view returns (address) {
        return _NFM;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getTimer() returns (address);
    This function returns Timer address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getTimer() public view returns (address) {
        return _Timer;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getPad() returns (address);
    This function returns PAD address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getPad() public view returns (address) {
        return _Pad;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getBonusBuyBack() returns (address,address);
    This function returns Bonus and BuyBack address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getBonusBuyBack()
        public
        view
        returns (address Bonus, address Buyback)
    {
        return (_ExtraBonus, _BuyBack);
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getMinting() returns (address);
    This function returns Minting address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getMinting() public view returns (address) {
        return _Minting;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getContributor() returns (address);
    This function returns Contributor address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getContributor() public view returns (address) {
        return _Contributor;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getBurning() returns (address);
    This function returns Burning address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getBurning() public view returns (address) {
        return _Burning;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getSwap() returns (address);
    This function returns Swap address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getSwap() public view returns (address) {
        return _Swap;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getLiquidity() returns (address);
    This function returns AddLiquidity address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getLiquidity() public view returns (address) {
        return _AddLiquidity;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getUV2Pool() returns (address);
    This function returns UniswapV2 address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getUV2Pool() public view returns (address) {
        return _UV2Pool;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getExchange() returns (address);
    This function returns NFM Exchange address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getExchange() public view returns (address) {
        return _Exchange;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDistribute() returns (address);
    This function returns Distribute address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDistribute() public view returns (address) {
        return _Distribute;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getTreasury() returns (address);
    This function returns Treasury address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getTreasury() public view returns (address) {
        return _Treasury;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getGovernance() returns (address);
    This function returns Dao Governance address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getGovernance() public view returns (address) {
        return _DaoGovernance;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoReserveERC20() returns (address);
    This function returns DaoReserveERC20 address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoReserveERC20() public view returns (address) {
        return _DaoReserveERC20;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoReserveETH() returns (address);
    This function returns DaoReserveMATIC address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoReserveETH() public view returns (address) {
        return _DaoReserveETH;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoPulling() returns (address);
    This function returns Dao Pulling address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoPulling() public view returns (address) {
        return _DaoPulling;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoContributorPulling() returns (address);
    This function returns Dao Contributor Pulling address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoContributorPulling() public view returns (address) {
        return _DaoContributorPulling;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoNFMPulling() returns (address);
    This function returns Dao NFM Pulling address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoNFMPulling() public view returns (address) {
        return _DaoNFMPulling;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDaoTotalPulling() returns (address);
    This function returns Dao Total Pulling address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDaoTotalPulling() public view returns (address) {
        return _DaoTotalPulling;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getLottery() returns (address);
    This function returns Lottery address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getLottery() public view returns (address) {
        return _Lottery;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFTFactory() returns (address);
    This function returns NFT Factory address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFTFactory() public view returns (address) {
        return _NFTFactory;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFTTreasuryERC20() returns (address);
    This function returns NFTTreasuryERC20 address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFTTreasuryERC20() public view returns (address) {
        return _NFTTreasuryERC20;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFTTreasuryETH() returns (address);
    This function returns NFTTreasuryMATIC address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFTTreasuryETH() public view returns (address) {
        return _NFTTreasuryETH;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFTPools() returns (address);
    This function returns NFTPools address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFTPools() public view returns (address) {
        return _NFTPools;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFMStaking() returns (address);
    This function returns NFMStaking address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFMStaking() public view returns (address) {
        return _NFMStaking;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFMStakingTreasuryERC20() returns (address);
    This function returns NFMStakingTreasuryERC20 address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFMStakingTreasuryERC20() public view returns (address) {
        return _NFMStakingTreasuryERC20;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getNFMStakingTreasuryETH() returns (address);
    This function returns NFMStakingTreasuryMATIC address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getNFMStakingTreasuryETH() public view returns (address) {
        return _NFMStakingTreasuryETH;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDexExchange() returns (address);
    This function returns DexExchange address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDexExchange() public view returns (address) {
        return _DexExchange;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDexExchangeAsk() returns (address);
    This function returns DexExchangeAsk address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDexExchangeAsk() public view returns (address) {
        return _DexExchangeAsk;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDexExchangeBid() returns (address);
    This function returns DexExchangeBid address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDexExchangeBid() public view returns (address) {
        return _DexExchangeBid;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDexExchangeReserveERC20() returns (address);
    This function returns DexExchangeReserveERC20 address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDexExchangeReserveERC20() public view returns (address) {
        return _DexExchangeReserveERC20;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getDexExchangeReserveETH() returns (address);
    This function returns DexExchangeReserveMATIC address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDexExchangeReserveETH() public view returns (address) {
        return _DexExchangeReserveETH;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getAFT() returns (address);
    This function returns AFT address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getAFT() public view returns (address) {
        return _AFT;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getIDOPool() returns (address);
    This function returns IDOPool address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getIDOPool() public view returns (address) {
        return _IDOPool;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ _getIDOExchange() returns (address);
    This function returns IDOExchange address
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getIDOExchange() public view returns (address) {
        return _IDOExchange;
    }
}