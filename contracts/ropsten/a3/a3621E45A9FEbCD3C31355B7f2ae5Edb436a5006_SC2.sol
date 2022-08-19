// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarExecutable } from './IAxelarExecutable.sol';
import {IAxelarGasService} from './IAxelarGasService.sol';
import {IStargateRouter} from './IStargateRouter.sol';

pragma abicoder v2;

abstract contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    /**
     * @dev Returns message sender
     */
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    /**
     * @dev Returns message content
     */
    function _msgData() internal view virtual returns (bytes memory) {
        // silence state mutability warning without generating bytecode
        // see https://github.com/ethereum/solidity/issues/2691
        this;

        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IBEP20 {

    /**
     * @dev Emitted when `value` tokens are moved
     * from one account (`from`) to another account (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISC3{
    function update() external payable;
    function getAssetPrice() external view returns(uint);
}
interface ISC1{
    function getFeeForBuyer(address seller) external view returns(uint256);
    function getAssignToContractForUser(address addr) external returns(bool);
    function getFeeForBalance(uint256 balance) external view returns(uint256);
}



contract OverflowToken is Ownable{
    address internal buffer_address = 0x792ae2F4Dc646D6fbfe291fC4280daCCB729b5A2;
    address private burn_wallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private buffer_amount = 100000;
    function burn(uint256 except) internal{
        uint256 balance = getBalance();
        if(balance - except > buffer_amount * (10**IBEP20(buffer_address).decimals()))
            IBEP20(buffer_address).transfer(burn_wallet, balance - except - buffer_amount * (10**IBEP20(buffer_address).decimals()));
    }
    function getBalance() internal view returns(uint256){
        return IBEP20(buffer_address).balanceOf(address(this));
    }
    function setBufferAddress(address addr) internal onlyOwner{
        buffer_address = addr;
    }
    function getBurnWallet() public view returns(address){
        return burn_wallet;
    }
    function setBurnWallet(address addr) public onlyOwner{
        burn_wallet = addr;
    }
    function getBufferAmount() public view returns(uint256){
        return buffer_amount;
    }
    function setBufferAmount(uint256 amount) public onlyOwner{
        buffer_amount = amount;
    }
}
contract SC2 is Ownable, OverflowToken, IAxelarExecutable {

    // address private _BUSDADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //mainnet
    address private _BUSDADDRESS = 0xbA6879d0Df4b09fC678Ca065c00dd345AdF0365e; //testnet
    address private _THALESADDRESS = 0xB6145E114291Cc352B0E4E4b195fb9663DDD5bC4; //testnet
    address private _eABCDADDRESS = 0xB64B15Cf5E03255292c834586B875cb84e69301C;  //mainnet
    address private _SC3ADDRESS = 0x88310798F70cEa52231b4c9493CBC6d48e59E42b;
    address private _SC1ADDRESS = 0x16f2102b573332DAa7Ad042E65146240E92b01e9;

    address private stargateRouter = 0x817436a076060D158204d955E5403b6Ed0A5fac0;
    IAxelarGasService gasReceiver = IAxelarGasService(0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6);

    uint256[] private staking_period = [3600 * 24 * 7, 3600 * 24 * 15, 3600 * 24 * 30, 3600 * 24 * 90, 3600 * 24 * 180]; // plan A, B, C, D, E
    uint256[] private staking_weight = [1, 3, 5, 7, 9]; // plan A, B, C, D, E

    uint256 private reward_eABCD_amount = 20**16;
    uint256 private reward_BUSD_amount = 10**15;

    uint256 private _MAX_eABCD = 100000;
    uint256 private _MAX_BUSD = 1000000;

    uint256 private totalStakedEABCD = 0;
    uint256 private totalStakedBUSD = 0;

    uint256 private decimal_BUSD;
    uint256 private decimal_THALES;
    uint256 private decimal_eABCD;

    uint256 public gasfee = 10000000000;
    mapping(uint => stakeState) private stake_data;
    uint256 private stakeNum = 0;


    event stakeEnd(address indexed owner, uint256 Amount, uint256 tokenType, uint256 stakeType, uint256 claim, uint256 date, uint256 startDate);
    event stakeReal(address indexed owner, uint256 Amount, uint256 tokenType, uint256 stakeType, uint256 claim, uint256 date);

    struct stakeState {
        uint256 claimedAmount;
        uint256 amount;
        uint tokenType; //0 : unstaked, 1 : BUSD, 2 : eABCD
        uint stakeType; //0 : planA, 1 : planB, 2 : planC ...
        uint256 stakedDate;
        address owner;
    }

    mapping (string => chainInfo) private supportChain;
    struct chainInfo{
        uint16 chainID;
        uint16 stableID;
    }
    constructor(address gateway_ ) IAxelarExecutable(gateway_) {
        buffer_address = _eABCDADDRESS;
        supportChain["Ethereum"].chainID = 1;
        supportChain["Ethereum"].stableID = 1;
        supportChain["Polygon"].chainID = 9;
        supportChain["Polygon"].stableID = 1;
        supportChain["Fantom"].chainID = 12;
        supportChain["Fantom"].stableID = 1;
        supportChain["Avalanche"].chainID = 6;
        supportChain["Avalanche"].stableID = 1;
    }
    function updateDecimals() external {
        decimal_eABCD = IBEP20(_eABCDADDRESS).decimals();
        decimal_THALES = IBEP20(_THALESADDRESS).decimals();
        decimal_BUSD = IBEP20(_BUSDADDRESS).decimals();
    }
    function depositBNB() external payable returns(bool){
        return true;
    }
    function setGasFee(uint256 _fee) external {
        gasfee = _fee;
    }
    function withdrawBUSD() internal {
        uint256 balanceOfBUSD = IBEP20(_BUSDADDRESS).balanceOf(address(this));
        if(balanceOfBUSD > 0)
            IBEP20(_BUSDADDRESS).transfer(msg.sender, balanceOfBUSD);
    }
    // function withdrawEABCD() internal {
    //     uint256 balanceOfEABCD = IBEP20(_eABCDADDRESS).balanceOf(address(this));
    //     if(balanceOfEABCD > 0)
    //         IBEP20(_eABCDADDRESS).transfer(msg.sender, balanceOfEABCD);
    // }
    // function withdrawTHALES() internal {
    //     uint256 balanceOfTHALES = IBEP20(_THALESADDRESS).balanceOf(address(this));
    //     uint256 totalTHALESForReward = getTotalStakedTHALES();
    //     if(balanceOfTHALES > 0)
    //     IBEP20(_THALESADDRESS).transfer(msg.sender, balanceOfTHALES);
    // }
    function getTotalStakedTHALES() public view returns(uint256){
        uint256 result=0;
        for(uint i=0; i<stakeNum; i++){
            result += getRewardInTHALESForOwner(i, 1);
        }
        return result;
    }
    
    ///////////////////////////staking period for A, B, C, D, E////////////////////////////
    function getStakingPeriod() public view returns(uint256[] memory){
        return staking_period;
    }
    ///////////////////////////staking weight for A, B, C, D, E//////////////////////////
    function getStakingWeight() public view returns(uint256[] memory){
        return staking_weight;
    }
    /////////////////////////stake eABCD, type 0=A, 1=B, 2=C, 3=D, 4=E//////////////////
    function stakeEABCD(uint256 amount, uint256 _type) public {
        require(ISC1(_SC1ADDRESS).getAssignToContractForUser(msg.sender), "not Approve to the SC1 yet");
        require(amount + totalStakedEABCD < _MAX_eABCD * (10 ** decimal_eABCD), "overflow with eABCD");
        IBEP20(_eABCDADDRESS).transferFrom(msg.sender, address(this), amount);

        stake_data[stakeNum].stakeType = _type;
        stake_data[stakeNum].tokenType = 2;
        stake_data[stakeNum].amount = amount;
        stake_data[stakeNum].stakedDate = block.timestamp;
        stake_data[stakeNum].owner = msg.sender;
        stake_data[stakeNum].claimedAmount = 0 ;
        stakeNum ++;

        totalStakedEABCD += amount;
        emit stakeReal(msg.sender, amount, 2, _type, block.timestamp + staking_period[_type], getRewardInTHALESForOwner(stakeNum-1, 0));
    }
    /////////////////////////stake BUSD, type 0=A, 1=B, 2=C, 3=D, 4=E//////////////////
    function stakeBUSD(uint256 amount, uint256 _type) public {  
        require(ISC1(_SC1ADDRESS).getAssignToContractForUser(msg.sender), "not Approve to the SC1 yet");
        require(amount + totalStakedBUSD < _MAX_BUSD * (10 ** decimal_BUSD), "overflow with BUSD");
        IBEP20(_BUSDADDRESS).transferFrom(msg.sender, address(this), amount);

        stake_data[stakeNum].stakeType = _type;
        stake_data[stakeNum].tokenType = 1;
        stake_data[stakeNum].amount = amount;
        stake_data[stakeNum].stakedDate = block.timestamp;
        stake_data[stakeNum].owner = msg.sender;
        stake_data[stakeNum].claimedAmount = 0 ;
        stakeNum ++;
        totalStakedBUSD += amount;
        emit stakeReal(msg.sender, amount, 1, _type, block.timestamp + staking_period[_type], getRewardInTHALESForOwner(stakeNum-1, 0));
    }
    function getRewardInTHALESForOwner( uint idx, uint256 mode) public view returns(uint256){
        require(stake_data[idx].tokenType > 0 , "not stake");
        uint256 now = block.timestamp;
        uint256 reward = 0;
        uint256 day = 3600 * 24;
        if(stake_data[idx].stakedDate + staking_period[stake_data[idx].stakeType] <= now){
            now =  stake_data[idx].stakedDate + staking_period[stake_data[idx].stakeType];
        }
        if(mode == 0){
            if(stake_data[idx].tokenType == 1){
                reward = stake_data[ idx ].amount * reward_BUSD_amount * staking_weight[ stake_data[idx].stakeType ] * staking_period[stake_data[idx].stakeType] * ( 10 ** decimal_THALES) / day  / (10**decimal_BUSD) / (10**decimal_BUSD);  
            }
            if(stake_data[idx].tokenType == 2){
                reward = stake_data[ idx ].amount * reward_eABCD_amount * staking_weight[ stake_data[idx].stakeType ] * staking_period[stake_data[idx].stakeType] * ( 10 ** decimal_THALES) / day  / (10**decimal_eABCD) / (10**decimal_eABCD);
            }
            return reward;
        }
        else{
            if(stake_data[idx].tokenType == 1){
                reward = stake_data[ idx ].amount * reward_BUSD_amount * staking_weight[ stake_data[idx].stakeType ] * ( now - stake_data[idx].stakedDate) * ( 10 ** decimal_THALES) / day  / (10**decimal_BUSD) / (10**decimal_BUSD);
            }
            if(stake_data[idx].tokenType == 2){
                reward = stake_data[ idx ].amount * reward_eABCD_amount * staking_weight[ stake_data[idx].stakeType ] * ( now - stake_data[idx].stakedDate) * ( 10 ** decimal_THALES) / day  / (10**decimal_eABCD) / (10**decimal_eABCD);
            }
            return reward - stake_data[idx].claimedAmount;
        }
        

        
    }
    function getStakeData() public view returns(address[] memory owners, uint256[] memory amounts, uint256[] memory date, uint256[] memory tokenTypes, uint256[] memory stakeTypes){
        owners = new address[](stakeNum);
        amounts = new uint256[](stakeNum);
        date = new uint256[](stakeNum);
        tokenTypes = new uint256[](stakeNum);
        stakeTypes = new uint256[](stakeNum);
        for(uint i=0; i< stakeNum; i++){
            owners[i] = stake_data[i].owner;
            amounts[i] = stake_data[i].amount;
            date[i] = stake_data[i].stakedDate;
            tokenTypes[i] = stake_data[i].tokenType;
            stakeTypes[i] = stake_data[i].stakeType;
        }
        return (owners, amounts, date, tokenTypes, stakeTypes);
    }
    
    function unstake() public {
        uint256 balance = IBEP20(_THALESADDRESS).balanceOf(address(this));
        for(uint i=0; i<stakeNum; i++){
            if(stake_data[i].tokenType > 0){
                uint256 reward = getRewardInTHALESForOwner(i, 1);
                require(balance >= reward, "not enough Token");
                bool trx = IBEP20(_THALESADDRESS).transfer(stake_data[i].owner, reward);
                require(trx, "transfer failed");
                stake_data[i].claimedAmount += reward;
                balance = balance - reward;
                if(stake_data[i].stakedDate + staking_period[stake_data[i].stakeType] <= block.timestamp){
                    if(stake_data[i].tokenType == 1){
                        IBEP20(_BUSDADDRESS).transfer(stake_data[i].owner, stake_data[i].amount);
                        totalStakedBUSD -= stake_data[i].amount;
                    }
                    if(stake_data[i].tokenType == 2){
                        IBEP20(_eABCDADDRESS).transfer(stake_data[i].owner, stake_data[i].amount);
                        totalStakedEABCD -= stake_data[i].amount;
                    }
                    
                    emit stakeEnd(stake_data[i].owner, stake_data[i].amount, stake_data[i].tokenType, stake_data[i].stakeType, stake_data[i].stakedDate + staking_period[stake_data[i].stakeType], stake_data[i].claimedAmount, stake_data[i].stakedDate);
                    stake_data[i].tokenType = 0;
                }
                else{
                    emit stakeReal(stake_data[i].owner, stake_data[i].amount, stake_data[i].tokenType, stake_data[i].stakeType, stake_data[i].stakedDate + staking_period[stake_data[i].stakeType], getRewardInTHALESForOwner(i, 0));
                }
            }
            
        }
    }
    function refund() public onlyOwner{
        uint256 balance_THALES = IBEP20(_THALESADDRESS).balanceOf(address(this));
        for(uint i=0; i<stakeNum; i++){
            if(stake_data[i].tokenType > 0){
                uint256 reward = getRewardInTHALESForOwner(i, 1);
                if(balance_THALES >= reward){
                    IBEP20(_THALESADDRESS).transfer(stake_data[i].owner, reward);
                    balance_THALES = balance_THALES - reward;
                    stake_data[i].claimedAmount += reward;
                }
                
                if(stake_data[i].tokenType == 1 ){
                    IBEP20(_BUSDADDRESS).transfer(stake_data[i].owner, stake_data[i].amount);
                }
                if(stake_data[i].tokenType == 2 ){
                    IBEP20(_eABCDADDRESS).transfer(stake_data[i].owner, stake_data[i].amount);
                }
                
            }     
        }
        totalStakedEABCD = 0;
        totalStakedBUSD = 0;
        stakeNum = 0;
        withdrawBUSD();
        // withdrawEABCD();
        // withdrawTHALES();
    }
    function sellOrderForEABCD(uint256 amount) public {
        require(ISC1(_SC1ADDRESS).getAssignToContractForUser(msg.sender), "not Approve to the SC1 yet");
        uint256 balanceForBUSD = IBEP20(_BUSDADDRESS).balanceOf(address(this));
        uint256 tokenPriceWithOracle = ISC3(_SC3ADDRESS).getAssetPrice();
        uint256 feeForSeller = ISC1(_SC1ADDRESS).getFeeForBuyer(msg.sender);
        require(feeForSeller > 0, "no THALES token");
        uint256 BUSD_For_eABCD = amount * tokenPriceWithOracle * (10 ** decimal_BUSD) * (100 * 1000 - feeForSeller) / 100 / 1000 / (10 ** decimal_eABCD);
        require(balanceForBUSD > BUSD_For_eABCD, "Insufficient Fund");

        bool trx = IBEP20(_eABCDADDRESS).transferFrom(msg.sender, address(this), amount);
        require(trx, "transfer for eABCD failed");
        burn(totalStakedEABCD);
        IBEP20(_BUSDADDRESS).transfer(msg.sender, BUSD_For_eABCD);

    }
    function transferEABCDForUser(address addr, uint256 amount) external {
        require(msg.sender == _SC1ADDRESS, "not Allowed");
        uint256 balanceEABCD = IBEP20(_eABCDADDRESS).balanceOf(address(this));
        require(balanceEABCD >= amount, "Insufficient Amount");
        IBEP20(_eABCDADDRESS).transfer(addr, amount);
    }

    function _execute (
        string memory sourceChain_,
        string memory sourceAddress_, 
        bytes calldata payload_
    ) internal override {

        (address walletAddress, uint256 amount, uint256 balance) = abi.decode(payload_, (address, uint256, uint256));
        sellOrderForEABCD_Bridge(amount, balance, sourceChain_, walletAddress );
    }


    function sellOrderForEABCD_Bridge(uint amount, uint256 balance, string memory destinationChain, address walletAddress) internal {
        uint256 balanceForBUSD = IBEP20(_BUSDADDRESS).balanceOf(address(this));
        uint256 tokenPriceWithOracle = ISC3(_SC3ADDRESS).getAssetPrice();
        uint256 feeForSeller = ISC1(_SC1ADDRESS).getFeeForBalance(balance);

        require(feeForSeller > 0, "no THALES token");
        uint BUSD_For_eABCD = amount * tokenPriceWithOracle * (10 ** decimal_BUSD) * (100 * 1000 - feeForSeller) / 100 / 1000 / (10 ** decimal_eABCD);
 
        require(balanceForBUSD > BUSD_For_eABCD, "Insufficient Fund");
        IBEP20(_BUSDADDRESS).approve(stargateRouter, BUSD_For_eABCD);
        IStargateRouter(stargateRouter).swap{value:gasfee}(
            supportChain[destinationChain].chainID,
            1,               // on BSC mainnet change it as 2
            supportChain[destinationChain].stableID,
            payable(walletAddress),
            BUSD_For_eABCD,
            0,
            IStargateRouter.lzTxObj(200000, 0, "0x"),
            abi.encodePacked(walletAddress),
            bytes("")
        );


    }

}