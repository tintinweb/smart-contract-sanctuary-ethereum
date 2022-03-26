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
        uint32[] calldata _datetime,
        uint16[] calldata _ratio_d2
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
    
    function createVesting(address, uint32[] calldata, uint16[] calldata) external returns (address);
    
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./IFixedCreator.sol";

contract FixedVesting{
    bool private initialized;
    bool public isPaused;

    uint8 public vestingLength;
    uint128 public sold;
    
    address public owner = tx.origin;
    address[] public buyers;

    address public token;
    address public immutable creator = msg.sender;

    struct Detail{
        uint32 datetime;
        uint16 ratio_d2;
    }

    struct Bought{
        uint16 buyerIndex;
        uint128 purchased;
        uint16 completed_d2; // in percent
        uint128 claimed;
    }
    
    mapping(address => Bought) public invoice;
    mapping(uint8 => Detail) public vesting;
    
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
        uint32[] calldata _datetime,
        uint16[] calldata _ratio_d2
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
    function vestingRunning() public view returns(uint8){
        for(uint8 i=1; i<=vestingLength; i++){
            if( (vesting[i].datetime <= block.timestamp && block.timestamp <= vesting[i+1].datetime) ||
                (i == vestingLength && block.timestamp >= vesting[i].datetime)
            ) return i;
        }
    }

    /**
     * @dev Get running in percent
     */
    function running_d2() public view returns(uint16 total){
        if(vestingRunning() == 0){
            total = 0;
        } else{
            for(uint8 i=1; i<=vestingRunning(); i++){
                total += vesting[i].ratio_d2;
            }
        }
    }

    /**
     * @dev Token claim
     */
    function claimToken() public {
        require(!isPaused && vestingRunning() > 0 && token != address(0) && IERC20(token).balanceOf(address(this)) > 0, "!started");
        require(invoice[msg.sender].purchased > 0, "!buyer");
        require(invoice[msg.sender].completed_d2 < running_d2(), "claimed");
        
        uint128 amountToClaim;
        if(invoice[msg.sender].completed_d2 == 0){
            amountToClaim = (invoice[msg.sender].purchased * running_d2()) / 10000;
        } else{
            amountToClaim = ((invoice[msg.sender].claimed * running_d2()) / invoice[msg.sender].completed_d2) - invoice[msg.sender].claimed;
        }
        
        invoice[msg.sender].completed_d2 = running_d2();
        invoice[msg.sender].claimed += amountToClaim;

        TransferHelper.safeTransfer(address(token), msg.sender, amountToClaim);        
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function _setToken(address _token) private {
        require(_token != address(0) && token != _token, "!good");
        token = _token;
    }

    /**
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function _newVesting(
        uint32[] calldata _datetime,
        uint16[] calldata _ratio_d2
    ) private {
        require(_datetime.length == _ratio_d2.length, "!good");

        for(uint8 i=vestingLength+1; i<=vestingLength+_datetime.length; i++){
            vesting[i] = Detail(_datetime[i-1], _ratio_d2[i-1]);
        }

        vestingLength += uint8(_datetime.length);
    }

    /**
     * @dev Insert new buyers & purchases
     * @param _buyer Buyer address
     * @param _purchased Buyer purchase
     */
    function newBuyers(address[] calldata _buyer, uint128[] calldata _purchased) public onlyOwner {
        require(_buyer.length == _purchased.length, "!good");

        for(uint16 i=0; i<=_buyer.length; i++){
            if(_buyer[i] == address(0) || _purchased[i] == 0) continue;

            if(invoice[_buyer[i]].purchased == 0){
                buyers.push(_buyer[i]);
                invoice[_buyer[i]].buyerIndex = uint16(buyers.length - 1);
            }
            
            invoice[_buyer[i]].purchased += _purchased[i];
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

        for(uint16 i=0; i<=_oldBuyer.length; i++){
            if( invoice[_oldBuyer[i]].purchased == 0 ||
                _oldBuyer[i] == address(0) ||
                _newBuyer[i] == address(0)) continue;

            uint16 indexToReplace = invoice[_oldBuyer[i]].buyerIndex;
            buyers[indexToReplace] = _newBuyer[i];

            invoice[_newBuyer[i]].buyerIndex = indexToReplace;
            invoice[_newBuyer[i]].purchased = invoice[_oldBuyer[i]].purchased;
            invoice[_newBuyer[i]].completed_d2 = invoice[_oldBuyer[i]].completed_d2;
            invoice[_newBuyer[i]].claimed = invoice[_oldBuyer[i]].claimed;

            delete invoice[_oldBuyer[i]];
        }
    }

    /**
     * @dev Remove buyers
     * @param _buyer Buyer address
     */
    function removeBuyers(address[] calldata _buyer) external onlyOwner {
        require(buyers.length > 0, "!good");
        for(uint16 i=0; i<=_buyer.length; i++){
            if(invoice[_buyer[i]].purchased == 0 || _buyer[i] == address(0)) continue;

            sold -= invoice[_buyer[i]].purchased;

            uint indexToRemove = invoice[_buyer[i]].buyerIndex;
            address addressToRemove = buyers[buyers.length-1];
            
            buyers[indexToRemove] = addressToRemove;
            invoice[addressToRemove].buyerIndex = uint16(indexToRemove);

            buyers.pop();
            delete invoice[_buyer[i]];
        }
    }
    
    /**
     * @dev Update buyers purchase
     * @param _buyer Buyer address
     * @param _newPurchased new purchased
     */
    function updatePurchases(address[] calldata _buyer, uint128[] calldata _newPurchased) external onlyOwner {
        require(_buyer.length == _newPurchased.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<=_buyer.length; i++){
            if( invoice[_buyer[i]].purchased == 0 ||
                invoice[_buyer[i]].completed_d2 > 0 ||
                _buyer[i] == address(0) ||
                _newPurchased[i] == 0) continue;
            
            sold = sold - invoice[_buyer[i]].purchased + _newPurchased[i];
            invoice[_buyer[i]].purchased = _newPurchased[i];
        }
    }

    /**
     * @dev Update vestings datetime
     * @param _vestingRound Vesting round
     * @param _newDatetime new datetime in epoch
     */
    function updateDatetimes(uint8[] calldata _vestingRound, uint32[] calldata _newDatetime) external onlyOwner {
        require(_vestingRound.length == _newDatetime.length, "!good");

        for(uint8 i=0; i<=_vestingRound.length; i++){
            if( _vestingRound[i] > vestingLength ||
                vestingRunning() > _vestingRound[i]) continue;
            vesting[_vestingRound[i]].datetime = _newDatetime[i];
        }
    }

    /**
     * @dev Update vestings ratio
     * @param _vestingRound Vesting round
     * @param _newRatio_d2 New ratio in percent (decimal 2)
     */
    function updateRatios(uint8[] calldata _vestingRound, uint16[] calldata _newRatio_d2) external onlyOwner {
        require(_vestingRound.length == _newRatio_d2.length, "!good");

        for(uint8 i=0; i<=_vestingRound.length; i++){
            if(_vestingRound[i] > vestingLength ||
                vestingRunning() > _vestingRound[i]) continue;
            vesting[_vestingRound[i]].ratio_d2 = _newRatio_d2[i];
        }
    }

    /**
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function newVesting(
        uint32[] calldata _datetime,
        uint16[] calldata _ratio_d2
    ) public onlyOwner {
        _newVesting(_datetime, _ratio_d2);
    }

    /**
     * @dev Emergency condition to withdraw token
     * @param _target Target address
     */
    function emergencyWithdraw(address _target) public onlyOwner {
        require(_target != address(0), "!good");
        
        TransferHelper.safeTransfer(address(token), _target, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function setToken(address _token) public onlyOwner {
        _setToken(_token);
    }
    
    /**
     * @dev Pause vesting activity
     */
    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0) && _newOwner != owner, "Ownership incorrect");
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