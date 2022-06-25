// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IFixedCreator.sol";
import "./FixedVesting.sol";

contract FixedCreator is IFixedCreator{
    address[] public override allVestings; // all vestings created
    
    address public override owner = msg.sender;
    
    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    /**
     * @dev Get total number of vestings created
     */
    function allVestingsLength() public override view returns (uint) {
        return allVestings.length;
    }
    
    /**
     * @dev Create new vesting to distribute token
     * @param _token Token project address
     * @param _datetime Vesting datetime in epoch
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function createVesting(
        address _token,
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) public override onlyOwner returns(address vesting){
        vesting = address(new FixedVesting());

        allVestings.push(vesting);
        
        FixedVesting(vesting).initialize(
            _token,
            _datetime,
            _ratio_d2
        );
        
        emit VestingCreated(vesting, allVestings.length - 1);
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0) && _newOwner != owner, "!good");
        owner = _newOwner;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFixedCreator{
    event VestingCreated(address indexed vesting, uint index);
    
    function owner() external  view returns (address);
    
    function allVestingsLength() external view returns(uint);
    
    function allVestings(uint) external view returns(address);
    
    function createVesting(address, uint128[] calldata, uint128[] calldata) external returns (address);
    
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./IFixedCreator.sol";

contract FixedVesting{
    address public immutable creator = msg.sender;
    address public owner = tx.origin;

    bool private initialized;
    bool public isPaused;

    uint128 public vestingLength;
    uint128 public sold;
    
    address public token;

    address[] public buyers;

    struct Detail{
        uint128 datetime;
        uint128 ratio_d2;
    }

    struct Bought{
        uint128 buyerIndex;
        uint128 purchased;
        uint128 completed_d2; // in percent (2 decimal)
        uint128 claimed;
    }
    
    mapping(address => Bought) public invoice;
    mapping(uint128 => Detail) public vesting;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    /**
     * @dev Initialize vesting token distribution
     * @param _token Token project address
     * @param _datetime Vesting datetime in epoch
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function initialize(
        address _token,
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) external {
        require(!initialized, "Initialized");
        require(msg.sender == creator, "!creator");

        _setToken(_token);
        _newVesting(_datetime, _ratio_d2);
        
        initialized = true;
    }

    /**
     * @dev Get length of buyer
     */
    function getBuyerLength() external view returns (uint){
        return buyers.length;
    }

    /**
     * @dev Get vesting runnning
     */
    function vestingRunning() public view returns(uint128 round, uint128 totalPercent_d2){
        uint128 vestingSize = vestingLength;
        uint128 total;
        for(uint128 i=1; i<=vestingSize; i++){
            Detail memory temp = vesting[i];
            total += temp.ratio_d2;
            
            if( (temp.datetime <= block.timestamp && block.timestamp <= vesting[i+1].datetime) ||
                (i == vestingSize && block.timestamp >= temp.datetime)
            ){
                round = i;
                totalPercent_d2 = total;
                break;
            }
        }
    }

    /**
     * @dev Token claim
     */
    function claimToken() external {
        (uint128 round, uint128 totalPercent_d2) = vestingRunning();
        Bought memory temp = invoice[msg.sender];

        require(!isPaused && round > 0 && token != address(0), "!started");
        require(temp.purchased > 0, "!buyer");
        require(temp.completed_d2 < totalPercent_d2, "claimed");
        
        uint128 amountToClaim;
        if(temp.completed_d2 == 0){
            amountToClaim = (temp.purchased * totalPercent_d2) / 10000;
        } else{
            amountToClaim = ((temp.claimed * totalPercent_d2) / temp.completed_d2) - temp.claimed;
        }

        require(IERC20(token).balanceOf(address(this)) >= amountToClaim && amountToClaim > 0, "insufficient");
        
        invoice[msg.sender].completed_d2 = totalPercent_d2;
        invoice[msg.sender].claimed = temp.claimed + amountToClaim;

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
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function _newVesting(
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) private {
        require(_datetime.length == _ratio_d2.length, "!good");

        uint128 vestingSize = vestingLength;
        for(uint128 i=0; i<_datetime.length; i++){
            if(i != _datetime.length-1) require(_datetime[i] < _datetime[i+1], "!good");
            vestingSize += 1;
            vesting[vestingSize] = Detail(_datetime[i], _ratio_d2[i]);
        }

        vestingLength = vestingSize;
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
                invoice[_buyer[i]].buyerIndex = uint128(buyers.length - 1);
            }
            
            invoice[_buyer[i]].purchased = temp.purchased + _purchased[i];
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

            address addressToMove = buyers[buyers.length-1];
            
            buyers[temp.buyerIndex] = addressToMove;
            invoice[addressToMove].buyerIndex = temp.buyerIndex;

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
                temp.completed_d2 > 0 ||
                _buyer[i] == address(0) ||
                _newPurchased[i] == 0) continue;
            
            sold = sold - temp.purchased + _newPurchased[i];
            invoice[_buyer[i]].purchased = _newPurchased[i];
        }
    }

    /**
     * @dev Update vestings datetime
     * @param _vestingRound Vesting round
     * @param _newDatetime new datetime in epoch
     */
    function updateVestingDatetimes(uint128[] calldata _vestingRound, uint128[] calldata _newDatetime) external onlyOwner {
        require(_vestingRound.length == _newDatetime.length, "!good");

        (uint128 round, ) = vestingRunning();
        uint128 vestingSize = vestingLength;

        for(uint128 i=0; i<_vestingRound.length; i++){
            if( _vestingRound[i] > vestingSize ||
                round >= _vestingRound[i]) continue;

            vesting[_vestingRound[i]].datetime = _newDatetime[i];
        }
    }

    /**
     * @dev Update vestings ratio
     * @param _vestingRound Vesting round
     * @param _newRatio_d2 New ratio in percent (decimal 2)
     */
    function updateVestingRatios(uint128[] calldata _vestingRound, uint128[] calldata _newRatio_d2) external onlyOwner {
        require(_vestingRound.length == _newRatio_d2.length, "!good");

        (uint128 round, ) = vestingRunning();
        uint128 vestingSize = vestingLength;

        for(uint128 i=0; i<_vestingRound.length; i++){
            if(_vestingRound[i] > vestingSize ||
                round >= _vestingRound[i]) continue;

            vesting[_vestingRound[i]].ratio_d2 = _newRatio_d2[i];
        }
    }

    /**
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function newVesting(
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) external onlyOwner {
        _newVesting(_datetime, _ratio_d2);
    }

    /**
     * @dev Remove last vesting round
     */
    function removeLastVestingRound() external onlyOwner {
        uint128 vestingSizeTarget = vestingLength-1;

        delete vesting[vestingSizeTarget];

        vestingLength = vestingSizeTarget;
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