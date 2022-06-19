// SPDX-License-Identifier: MIT

/**
* Create By ASSA Team.
* Airdrop for ASSA token
* 
*
*/

pragma solidity 0.8.6;

import "./SafeMath.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract ASSALockedToken is Ownable {

    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    
    event AddTokentoLockedPoolEvent(address tokenAddress, address ownerLocked, uint256 endTime, uint256 amountToken);
    event AddTimeOfLockedEvent(address tokenAddress, address ownerLocked, uint256 additionalTime, uint256 amountToken);
    event WithdrawTokenofFree(address tokenAddress, address ownerLocked, uint256 amountToken, uint256 withdrawTime);
    event MakeFreeTokensEvent(address tokenAddress, address ownerLocked, uint256 amountToken, uint256 timeFreeTokens);

    struct InfoLocked{
        uint256 startTime;
        uint256 endTime;
        uint256 amountLockedTokens;
        uint256 amountFreeTokens;
    }
    
    mapping (address => mapping (address => InfoLocked)) EachInfoLocked;
    mapping (address => mapping(address => bool)) AllPairOfAddress;
    mapping (address => uint256) public NumberOfLockedAddress;


    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor() {
    }


    function AddTokentoLockedPool(uint256 endTime, address tokenContract, uint256 amount) public notContract returns(uint256, uint256){
        IERC20 itoken = IERC20(address(tokenContract));
        require(amount > 0 , "The value must be greater than 0");
        require(endTime > block.timestamp, "Time must be longer than the present");
        uint256 allowance = itoken.allowance(msg.sender , address(this));
        require(allowance >= amount, "Check the token allowance");
        return _AddTokentoLockedPool(endTime, itoken, amount);
    }


    function _AddTokentoLockedPool(uint256 _endTime, IERC20 _itoken, uint256 _amount) private returns(uint256, uint256){
        address _Aitoken = address(_itoken);
        uint256 balancebefore = _itoken.balanceOf(address(this));
        _itoken.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 balanceafter = _itoken.balanceOf(address(this));
        _amount = balanceafter - balancebefore ;

        if(!AllPairOfAddress[msg.sender][_Aitoken]){
            NumberOfLockedAddress[msg.sender]++;
            AllPairOfAddress[msg.sender][_Aitoken] = true;
            EachInfoLocked[msg.sender][_Aitoken] = InfoLocked(block.timestamp, _endTime, _amount, 0);
        }else{
            //
            EachInfoLocked[msg.sender][_Aitoken].amountLockedTokens = (EachInfoLocked[msg.sender][_Aitoken].amountLockedTokens).add(_amount);
        }
        
        emit AddTokentoLockedPoolEvent(_Aitoken, msg.sender,_endTime, _amount);
        return (_endTime,_amount);

    }

    function AddTimeOfLocked(address tokenContract, uint256 additionalTime, uint256 amount) public notContract returns(uint256,uint256){
        require(AllPairOfAddress[msg.sender][tokenContract], "Locked Not Exist");
        require(additionalTime > block.timestamp, "You Can't Set it Now");
        require(additionalTime > EachInfoLocked[msg.sender][tokenContract].endTime, "You Can Set Time After End");
        require(amount > 0, "The value must be greater than 0");
        require(amount <= EachInfoLocked[msg.sender][tokenContract].amountLockedTokens , "Must be less than the locked value");
        return _AddTimeOfLocked(tokenContract, additionalTime, amount);

    }

    function _AddTimeOfLocked(address _tokenContract, uint256 _additionalTime, uint256 _amount) private returns(uint256,uint256){
        EachInfoLocked[msg.sender][_tokenContract].endTime = _additionalTime;
        EachInfoLocked[msg.sender][_tokenContract].amountFreeTokens = EachInfoLocked[msg.sender][_tokenContract].amountLockedTokens.sub(_amount);
        EachInfoLocked[msg.sender][_tokenContract].amountLockedTokens = _amount;

        emit AddTimeOfLockedEvent(_tokenContract, msg.sender, _additionalTime, _amount);
        return (_additionalTime, _amount);
    }

    function WithdrawTokenFreeOnTime(address tokenAddress, uint256 amount) public notContract returns(address, uint256, bool){
        require(amount > 0, "The value must be greater than 0");
        require(AllPairOfAddress[msg.sender][tokenAddress], "Locked Not Exist");
        require(EachInfoLocked[msg.sender][tokenAddress].amountFreeTokens >= amount, "Not Enough Free Token in Locked");
        require(block.timestamp >= EachInfoLocked[msg.sender][tokenAddress].endTime ,"Time is Not End");
        return _WithdrawTokenFreeOnTime(tokenAddress, amount);
    }

    function _WithdrawTokenFreeOnTime(address _tokenAddress, uint256 _amount) private returns(address, uint256, bool){
        IERC20 itoken = IERC20(_tokenAddress);
        itoken.safeTransfer(msg.sender, _amount);
        EachInfoLocked[msg.sender][_tokenAddress].amountFreeTokens = (EachInfoLocked[msg.sender][_tokenAddress].amountFreeTokens).sub(_amount);
        emit WithdrawTokenofFree(_tokenAddress, msg.sender, _amount, block.timestamp);
        return (_tokenAddress, _amount, true);
    }

    function MakeFreeTokens(address tokenCont, uint256 amount) public returns(address, uint256){
        require(amount > 0, "The value must be greater than 0");
        require(AllPairOfAddress[msg.sender][tokenCont] , "Locked Not Exist");
        require(block.timestamp > EachInfoLocked[msg.sender][tokenCont].endTime, "Time is Not End");
        require(EachInfoLocked[msg.sender][tokenCont].amountLockedTokens > 0, "Locked Pool is Zero Tokens");
        require(amount <= EachInfoLocked[msg.sender][tokenCont].amountLockedTokens, "Must be less than the locked value");
        return _MakeFreeTokens(tokenCont, amount);
    }

    function _MakeFreeTokens(address _tokenCont, uint256 _amount) private returns(address, uint256){
        EachInfoLocked[msg.sender][_tokenCont].amountFreeTokens = (EachInfoLocked[msg.sender][_tokenCont].amountFreeTokens).add(_amount);
        EachInfoLocked[msg.sender][_tokenCont].amountLockedTokens = (EachInfoLocked[msg.sender][_tokenCont].amountLockedTokens).sub(_amount);
        emit MakeFreeTokensEvent(_tokenCont, msg.sender, _amount, block.timestamp);
        return (_tokenCont, _amount);
    }

    function HowMuchIsFreeOnLocked(address ownerLocked, address tokenContract) public view returns(uint256){
        return EachInfoLocked[ownerLocked][tokenContract].amountFreeTokens;
    }

    function HowMuchIsLockedOnLocke(address ownerLocked, address tokenContract) public view returns(uint256){
        return EachInfoLocked[ownerLocked][tokenContract].amountLockedTokens;
    }

    function WhenIsEndedLocked(address ownerLocked, address tokenContract) public view returns(uint256){
        return EachInfoLocked[ownerLocked][tokenContract].endTime;
    }

    function StartLockedTime(address ownerLocked, address tokenContract) public view returns(uint256){
        return EachInfoLocked[ownerLocked][tokenContract].startTime;
    }

    function TokenisExist(address ownerLocked, address tokenContract) public view returns(bool){
        return AllPairOfAddress[ownerLocked][tokenContract];
    }

     /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
     function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}