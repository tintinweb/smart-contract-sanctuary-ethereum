//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./IELONphantStaking.sol";

/**
 * Hat tip to --
 * ELONphant Funding Receiver
 * Will Allocate Funding To Different Sources
 * Contract Developed By DeFi Mark (MoonMark)
 * Thanks for sharing great code!
 */
contract ELONphantFundingReceiver {
    
    using Address for address;
    
    // Farming Manager
    address public farm;
    address public stake;
    address public multisig;
    address public foundation;
    // ELONphant
    address public constant ELONphant = 0xB7E29bD8A0D34d9eb41FC654eA1C6633ed59DD64;
    
    // allocation to farm + stake + multisig
    uint256 public farmFee;
    uint256 public stakeFee;
    uint256 public multisigFee;
    uint256 public foundationFee;
    
    // ownership
    address public _master;
    modifier onlyMaster(){require(_master == msg.sender, 'Sender Not Master'); _;}
    
    constructor() {
    
        _master = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        multisig = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        farm = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        stake = 0x3Bc217cbBB234F5fe0D04A94C9dEf13bED1E423D;
        foundation = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        stakeFee = 15;
        farmFee = 50;
        foundationFee = 30;
        multisigFee = 5;

    }
    
    event SetFarm(address farm);
    event SetStaker(address staker);
    event SetMultisig(address multisig);
    event SetFoundation(address foundation);
    event SetFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent, uint256 foundationPercent);
    event Withdrawal(uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    // MASTER 
    
    function setFarm(address _farm) external onlyMaster {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyMaster {
        stake = _stake;
        emit SetStaker(_stake);
    }
     function setFoundation(address _foundation) external onlyMaster {
        foundation = _foundation;

        emit SetFoundation(_foundation);
    }
    function setMultisig(address _multisig) external onlyMaster {
        multisig = _multisig;
        emit SetMultisig(_multisig);
    }
    
    function setFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent, uint256 foundationPercent) external onlyMaster {
        farmFee = farmPercentage;
        stakeFee = stakePercent;
        multisigFee = multisigPercent;
        foundationFee = foundationPercent;
        emit SetFundPercents(farmPercentage, stakePercent, multisigPercent,foundationPercent);
    }
    
    function manualWithdraw(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(_master, bal);
        emit Withdrawal(bal);
    }
    
    function ETHWithdrawal() external onlyMaster returns (bool s){
        uint256 bal = address(this).balance;
        require(bal > 0);
        (s,) = payable(_master).call{value: bal}("");
        emit Withdrawal(bal);
    }
    
    function transferMaster(address newMaster) external onlyMaster {
        _master = newMaster;
        emit OwnershipTransferred(newMaster);
    }
    
    
    // ONLY APPROVED
    
    function distribute() external {
        _distributeYield();
    }

    // PRIVATE
    
    function _distributeYield() private {
        
        uint256 ELONphantBal = IERC20(ELONphant).balanceOf(address(this));
        
        uint256 farmBal = (ELONphantBal * farmFee) / 10**2;
        uint256 sigBal = (ELONphantBal * multisigFee) / 10**2;
        uint256 stakeBal = ELONphantBal - (farmBal + sigBal);
        uint256 foundationBal = (ELONphantBal * foundationFee) / 10**2;

        if (farmBal > 0 && farm != address(0)) {
            IERC20(ELONphant).approve(farm, farmBal);
            IELONphantStaking(farm).deposit(farmBal);
        }
        
        if (stakeBal > 0 && stake != address(0)) {
            IERC20(ELONphant).approve(stake, stakeBal);
            IELONphantStaking(stake).deposit(stakeBal);
        }
        
        if (sigBal > 0 && multisig != address(0)) {
            IERC20(ELONphant).transfer(multisig, sigBal);
        }

        if (foundationBal > 0 && foundation != address(0)) {
            IERC20(ELONphant).approve(foundation, foundationBal);
            IELONphantStaking(foundation).deposit(foundationBal);
            
        }
    }
    
    receive() external payable {
        (bool s,) = payable(ELONphant).call{value: msg.value}("");
        require(s, 'Failure on Token Purchase');
        _distributeYield();
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Exempt Surge Interface
 */
interface IELONphantStaking {
    function deposit(uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

}