// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./ILinearCreator.sol";

contract LinearVesting{
    address public immutable creator = msg.sender;
    address public owner = tx.origin;
    
    bool private initialized;
    bool public isPaused;

    uint32 public tgeRatio_d2;
    uint32 public tgeDatetime;
    uint32 public startLinear;
    uint32 public endLinear;
    uint128 public sold;
    
    address public token;

    address[] public buyers;

    struct Bought{
        uint128 purchased;
        uint128 linearPerSecond;
        uint128 claimed;
        uint64 lastClaimed;
        uint64 buyerIndex;
    }
    
    mapping(address => Bought) public invoice;
    mapping(address => bool) public tgeClaimed;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    /**
     * @dev Initialize vesting token distribution
     * @param _token Token project address
     * @param _tgeDatetime TGE datetime in epoch
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function initialize(
        address _token,
        uint32 _tgeDatetime,
        uint32 _tgeRatio_d2,
        uint32[2] calldata _startEndLinearDatetime
    ) external {
        require(!initialized, "Initialized");
        require(msg.sender == creator, "!creator");

        _setToken(_token);
        if(_tgeDatetime > 0 && _tgeRatio_d2 > 0){
            _setTgeDatetime(_tgeDatetime);
            _setTgeRatio(_tgeRatio_d2);
        }
        _setStartEndLinearDatetime(_startEndLinearDatetime);

        initialized = true;
    }

    /**
     * @dev Get length of buyer
     */
    function getBuyerLength() external view returns (uint){
        return buyers.length;
    }

    /**
     * @dev Get linear started status
     */
    function linearStarted() public view returns(bool){
        return (startLinear < block.timestamp) ? true : false;
    }

    /**
     * @dev Token claim
     */
    function claimToken() external {
        require(!isPaused && tgeDatetime <= block.timestamp && token != address(0), "!started");

        Bought memory temp = invoice[msg.sender];
        bool tgeStatus = tgeClaimed[msg.sender];
        bool linearStatus = linearStarted();

        require(temp.purchased > 0 && temp.lastClaimed <= endLinear, "!good");
        
        if( tgeDatetime > 0 && tgeStatus && !linearStatus ||
            tgeDatetime == 0 && !linearStatus
        ) revert("wait");

        uint128 amountToClaim;
        if(tgeDatetime > 0 && !tgeStatus){
            amountToClaim = (temp.purchased * tgeRatio_d2) / 10000;
            tgeClaimed[msg.sender] = true;
        }

        if(linearStatus){
            if (temp.lastClaimed < startLinear && block.timestamp >= endLinear){
                amountToClaim += (temp.purchased * (10000 - tgeRatio_d2)) / 10000;
            } else{
                uint64 lastClaimed = temp.lastClaimed < startLinear ? startLinear : temp.lastClaimed;
                uint64 claimNow = block.timestamp >= endLinear ? endLinear : uint64(block.timestamp);
                amountToClaim += uint128((claimNow - lastClaimed) * temp.linearPerSecond);
            }
        }

        require(IERC20(token).balanceOf(address(this)) >= amountToClaim && amountToClaim > 0, "insufficient");
        
        invoice[msg.sender].claimed = temp.claimed + amountToClaim;
        invoice[msg.sender].lastClaimed = uint64(block.timestamp);

        TransferHelper.safeTransfer(address(token), msg.sender, amountToClaim);        
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function _setToken(address _token) private {
        token = _token;
    }

    /**
     * @dev Set TGE datetime
     * @param _tgeDatetime TGE datetime in epoch
     */
    function _setTgeDatetime(uint32 _tgeDatetime) private {
        tgeDatetime = _tgeDatetime;
    }

    /**
     * @dev Set TGE ratio
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     */
    function _setTgeRatio(uint32 _tgeRatio_d2) private {
        tgeRatio_d2 = _tgeRatio_d2;
    }

    /**
     * @dev Set start & end linear datetime
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function _setStartEndLinearDatetime(uint32[2] calldata _startEndLinearDatetime) private {
        if(startLinear > 0) require(block.timestamp < startLinear, "!good");
        require(block.timestamp < _startEndLinearDatetime[0] &&
                _startEndLinearDatetime[0] < _startEndLinearDatetime[1], "!good");

        startLinear = _startEndLinearDatetime[0];
        endLinear = _startEndLinearDatetime[1];
    }

    /**
     * @dev Insert new buyers & purchases
     * @param _buyer Buyer address
     * @param _purchased Buyer purchase
     */
    function newBuyers(address[] calldata _buyer, uint128[] calldata _purchased) external onlyOwner {
        require(_buyer.length == _purchased.length, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            if(_buyer[i] == address(0) || _purchased[i] == 0) continue;

            Bought memory temp = invoice[_buyer[i]];

            if(temp.purchased == 0){
                buyers.push(_buyer[i]);
                invoice[_buyer[i]].buyerIndex = uint64(buyers.length - 1);
            }

            invoice[_buyer[i]].purchased = temp.purchased + _purchased[i];
            invoice[_buyer[i]].linearPerSecond = ((invoice[_buyer[i]].purchased * (10000 - tgeRatio_d2)) / 10000) / (endLinear - startLinear);
            sold += _purchased[i];
        }
    }

    /**
     * @dev Replace buyers address
     * @param _oldBuyer Old address
     * @param _newBuyer New purchase
     */
    function replaceBuyers(address[] calldata _oldBuyer, address[] calldata _newBuyer) external onlyOwner {
        require(_oldBuyer.length == _newBuyer.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_oldBuyer.length; i++){
            Bought memory temp = invoice[_oldBuyer[i]];

            if( temp.purchased == 0 ||
                _oldBuyer[i] == address(0) ||
                _newBuyer[i] == address(0)
            ) continue;

            buyers[temp.buyerIndex] = _newBuyer[i];

            invoice[_newBuyer[i]] = temp;

            delete invoice[_oldBuyer[i]];
        }
    }

    /**
     * @dev Remove buyers
     * @param _buyer Buyer address
     */
    function removeBuyers(address[] calldata _buyer) external onlyOwner {
        require(buyers.length > 0, "!good");
        for(uint16 i=0; i<_buyer.length; i++){
            Bought memory temp = invoice[_buyer[i]];
            
            if(temp.purchased == 0 || _buyer[i] == address(0)) continue;

            sold -= temp.purchased;

            address addressToRemove = buyers[buyers.length-1];
            
            buyers[temp.buyerIndex] = addressToRemove;
            invoice[addressToRemove].buyerIndex = uint64(temp.buyerIndex);

            buyers.pop();
            delete invoice[_buyer[i]];
        }
    }
    
    /**
     * @dev Replace buyers purchase
     * @param _buyer Buyer address
     * @param _newPurchased new purchased
     */
    function replacePurchases(address[] calldata _buyer, uint128[] calldata _newPurchased) external onlyOwner {
        require(_buyer.length == _newPurchased.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            Bought memory temp = invoice[_buyer[i]];

            if( temp.purchased == 0 ||
                temp.claimed > 0 ||
                _buyer[i] == address(0) ||
                _newPurchased[i] == 0) continue;
            
            sold = sold - temp.purchased + _newPurchased[i];
            invoice[_buyer[i]].purchased = _newPurchased[i];
            invoice[_buyer[i]].linearPerSecond = ((invoice[_buyer[i]].purchased * (10000 - tgeRatio_d2)) / 10000) / (endLinear - startLinear);
        }
    }

    /**
     * @dev Set TGE datetime
     * @param _tgeDatetime TGE datetime in epoch
     */
    function setTgeDatetime(uint32 _tgeDatetime) external onlyOwner {
        _setTgeDatetime(_tgeDatetime);
    }

    /**
     * @dev Set TGE ratio
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     */
    function setTgeRatio(uint32 _tgeRatio_d2) external onlyOwner {
        _setTgeRatio(_tgeRatio_d2);
    }

    /**
     * @dev Set start & end linear datetime
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function setStartEndLinearDatetime(uint32[2] calldata _startEndLinearDatetime) external onlyOwner {
        _setStartEndLinearDatetime(_startEndLinearDatetime);
    }

    /**
     * @dev Emergency condition to withdraw token
     * @param _target Target address
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address _target, uint128 _amount) external onlyOwner {
        require(_target != address(0), "!good");
        
        uint128 contractBalance = uint128(IERC20(token).balanceOf(address(this)));
        if(_amount > contractBalance) _amount = contractBalance;

        TransferHelper.safeTransfer(address(token), _target, _amount);
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function setToken(address _token) external onlyOwner {
        _setToken(_token);
    }
    
    /**
     * @dev Pause vesting activity
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "!good");
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILinearCreator{
    event VestingCreated(address indexed vesting, uint index);
    
    function owner() external  view returns (address);
    
    function allVestingsLength() external view returns(uint);
    
    function allVestings(uint) external view returns(address);
    
    function createVesting(address, uint32, uint32, uint32[2] calldata) external returns (address);
    
    function transferOwnership(address) external;
}